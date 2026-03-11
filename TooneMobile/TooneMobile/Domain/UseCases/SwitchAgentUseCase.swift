import Foundation

// MARK: - SwitchAgentError

enum SwitchAgentError: Error, Sendable {
    case emptyAgentId
}

// MARK: - SwitchAgentUseCase

struct SwitchAgentUseCase {

    private let agentRepository: AgentRepository

    init(agentRepository: AgentRepository) {
        self.agentRepository = agentRepository
    }

    // MARK: - Execute

    func execute(agentId: String) async throws -> Session {
        guard !agentId.isEmpty else {
            throw SwitchAgentError.emptyAgentId
        }

        return try await agentRepository.switchAgent(agentId: agentId)
    }
}
