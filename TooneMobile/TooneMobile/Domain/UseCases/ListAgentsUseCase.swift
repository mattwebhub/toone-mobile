import Foundation

// MARK: - ListAgentsUseCase

struct ListAgentsUseCase {

    private let agentRepository: AgentRepository

    init(agentRepository: AgentRepository) {
        self.agentRepository = agentRepository
    }

    // MARK: - Execute

    func execute() async throws -> [Department] {
        try await agentRepository.listAgents()
    }

    // MARK: - Updates

    func agentUpdates() -> AsyncStream<[Department]> {
        agentRepository.agentUpdates()
    }
}
