import Foundation

// MARK: - RemoteAgentRepository

/// Data layer implementation of AgentRepository that fetches agents via the tunnel
/// and subscribes to agent update notifications.
final class RemoteAgentRepository: AgentRepository, @unchecked Sendable {

    // MARK: - Properties

    private let tunnelClient: TunnelClient
    private let logger: AppLogger

    // MARK: - Init

    init(tunnelClient: TunnelClient, logger: AppLogger) {
        self.tunnelClient = tunnelClient
        self.logger = logger
    }

    // MARK: - List Agents

    func listAgents() async throws -> [Department] {
        let response = try await tunnelClient.send(method: .agentList)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        let departments = DepartmentMapper.mapFromResponse(response)
        logger.debug("Fetched \(departments.count) departments", category: .tunnel)
        return departments
    }

    // MARK: - Switch Agent

    func switchAgent(agentId: String) async throws -> Session {
        let params: [String: AnyCodable] = [
            "agentId": AnyCodable(string: agentId)
        ]

        let response = try await tunnelClient.send(method: .agentSwitch, params: params)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        let session = SessionMapper.mapFromResponse(response)
        logger.info("Switched to agent \(agentId), session \(session.id)", category: .tunnel)
        return session
    }

    // MARK: - Agent Updates

    func agentUpdates() -> AsyncStream<[Department]> {
        AsyncStream { continuation in
            Task {
                await tunnelClient.onNotification(method: .stateSubscribe) { notification in
                    let departments = DepartmentMapper.mapFromNotification(notification)
                    if !departments.isEmpty {
                        continuation.yield(departments)
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
