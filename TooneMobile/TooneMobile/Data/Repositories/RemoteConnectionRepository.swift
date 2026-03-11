import Foundation

// MARK: - RemoteConnectionRepository

/// Data layer implementation of ConnectionRepository that communicates
/// with toone-desktop via the WebSocket tunnel.
final class RemoteConnectionRepository: ConnectionRepository, @unchecked Sendable {

    // MARK: - Properties

    private let connectionManager: ConnectionManager
    private let tunnelClient: TunnelClient
    private let logger: AppLogger

    // MARK: - Init

    init(connectionManager: ConnectionManager, tunnelClient: TunnelClient, logger: AppLogger) {
        self.connectionManager = connectionManager
        self.tunnelClient = tunnelClient
        self.logger = logger
    }

    // MARK: - ConnectionRepository

    var statusStream: AsyncStream<ConnectionStatus> {
        AsyncStream { continuation in
            Task {
                let stream = await tunnelClient.statusStream
                for await tunnelStatus in stream {
                    continuation.yield(tunnelStatus)
                }
                continuation.finish()
            }
        }
    }

    func connect(host: String, port: Int, token: String?) async throws {
        logger.info("Connecting to \(host):\(port)", category: .network)
        try await connectionManager.connect(host: host, port: port, token: token)
    }

    func disconnect() async {
        logger.info("Disconnecting from desktop", category: .network)
        await connectionManager.disconnect()
    }

    func ping() async throws -> TimeInterval {
        let start = Date()
        _ = try await tunnelClient.send(method: .connectionPing)
        return Date().timeIntervalSince(start)
    }
}
