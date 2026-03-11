import Foundation
@testable import TooneMobile

// MARK: - MockAgentRepository

final class MockAgentRepository: AgentRepository, @unchecked Sendable {

    // MARK: - Call Tracking

    var listAgentsCallCount = 0
    var switchAgentCallCount = 0
    var switchAgentLastId: String?
    var agentUpdatesCallCount = 0

    // MARK: - Stubbed Results

    var stubbedDepartments: [Department] = []
    var listAgentsError: Error?
    var switchAgentResult: Session?
    var switchAgentError: Error?
    var stubbedAgentUpdates: [[Department]] = []

    // MARK: - AgentRepository

    func listAgents() async throws -> [Department] {
        listAgentsCallCount += 1
        if let error = listAgentsError {
            throw error
        }
        return stubbedDepartments
    }

    func switchAgent(agentId: String) async throws -> Session {
        switchAgentCallCount += 1
        switchAgentLastId = agentId
        if let error = switchAgentError {
            throw error
        }
        if let result = switchAgentResult {
            return result
        }
        return Session(
            id: UUID().uuidString,
            agentId: agentId,
            agentName: "Test Agent",
            startedAt: Date(),
            lastInteractionAt: Date(),
            messageCount: 0,
            lastMessagePreview: nil,
            isArchived: false
        )
    }

    func agentUpdates() -> AsyncStream<[Department]> {
        agentUpdatesCallCount += 1
        let updates = stubbedAgentUpdates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}
