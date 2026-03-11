import Foundation

// MARK: - RemoteProjectRepository

/// Data layer implementation of ProjectRepository that fetches project data via the tunnel.
final class RemoteProjectRepository: ProjectRepository, @unchecked Sendable {

    // MARK: - Properties

    private let tunnelClient: TunnelClient
    private let logger: AppLogger

    // MARK: - Init

    init(tunnelClient: TunnelClient, logger: AppLogger) {
        self.tunnelClient = tunnelClient
        self.logger = logger
    }

    // MARK: - File Tree

    func fileTree() async throws -> ProjectFile {
        let response = try await tunnelClient.send(method: .projectTree)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        let tree = ProjectFileMapper.mapFromResponse(response)
        logger.debug("Fetched project tree: \(tree.name)", category: .tunnel)
        return tree
    }

    // MARK: - Read File

    func readFile(path: String) async throws -> String {
        let params: [String: AnyCodable] = ["path": AnyCodable(string: path)]
        let response = try await tunnelClient.send(method: .projectReadFile, params: params)

        if let rpcError = response.error {
            if rpcError.code == TunnelErrorCode.fileNotFound.rawValue {
                throw TunnelError.rpcError(code: rpcError.code, message: "File not found: \(path)")
            }
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        return response.result?["content"]?.stringValue ?? ""
    }

    // MARK: - Project Updates

    func projectUpdates() -> AsyncStream<ProjectFile> {
        AsyncStream { continuation in
            Task {
                await tunnelClient.onNotification(method: .stateSubscribe) { notification in
                    if let file = ProjectFileMapper.mapFromNotification(notification) {
                        continuation.yield(file)
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    Task { [weak self] in
                        guard let self else { return }
                        await self.tunnelClient.removeNotificationHandler(for: .stateSubscribe)
                    }
                }
            }
        }
    }
}
