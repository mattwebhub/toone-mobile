import Foundation

// MARK: - Agent List View Model

@Observable @MainActor
final class AgentListViewModel {
    var departments: [Department] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var selectedAgent: Agent?
    var connectionRole: ConnectionRole = .viewer
    var errorMessage: String?

    private let listAgentsUseCase: ListAgentsUseCase
    private let switchAgentUseCase: SwitchAgentUseCase

    // MARK: - Init

    init(listAgentsUseCase: ListAgentsUseCase, switchAgentUseCase: SwitchAgentUseCase) {
        self.listAgentsUseCase = listAgentsUseCase
        self.switchAgentUseCase = switchAgentUseCase
    }

    // MARK: - Computed Properties

    var filteredDepartments: [Department] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return departments
        }

        let query = searchQuery.lowercased()
        return departments.compactMap { department in
            let matchingAgents = department.agents.filter { agent in
                agent.name.lowercased().contains(query)
                    || agent.description.lowercased().contains(query)
                    || agent.capabilities.contains { $0.lowercased().contains(query) }
            }

            guard !matchingAgents.isEmpty else { return nil }

            return Department(
                id: department.id,
                name: department.name,
                agents: matchingAgents
            )
        }
    }

    var hasAgents: Bool {
        !departments.isEmpty
    }

    var canSwitchAgents: Bool {
        connectionRole.canSwitchAgents
    }

    // MARK: - Actions

    func loadAgents() async {
        isLoading = true
        errorMessage = nil

        do {
            departments = try await listAgentsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func switchToAgent(_ agent: Agent) async {
        guard connectionRole.canSwitchAgents else { return }
        do {
            let session = try await switchAgentUseCase.execute(agentId: agent.id)
            var updatedAgent = agent
            updatedAgent.sessionId = session.id
            selectedAgent = updatedAgent
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeAgentUpdates() async {
        for await updatedDepartments in listAgentsUseCase.agentUpdates() {
            departments = updatedDepartments
        }
    }
}
