import Foundation

// MARK: - AgentRepository

public protocol AgentRepository: Sendable {
    func listAgents() async throws -> [Department]
    func switchAgent(agentId: String) async throws -> Session
    func agentUpdates() -> AsyncStream<[Department]>
}
