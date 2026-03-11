import Foundation
@testable import TooneMobile

final class MockSessionRepository: SessionRepository, @unchecked Sendable {

    // MARK: - Call Tracking

    var listSessionsCallCount = 0
    var archiveSessionCallCount = 0
    var archiveSessionLastId: String?
    var restoreSessionCallCount = 0
    var restoreSessionLastId: String?
    var sessionUpdatesCallCount = 0

    // MARK: - Stubbed Results

    var stubbedSessions: [Session] = []
    var listSessionsError: Error?
    var archiveSessionError: Error?
    var restoreSessionResult: Session?
    var restoreSessionError: Error?
    var stubbedSessionUpdates: [[Session]] = []

    // MARK: - SessionRepository

    func listSessions() async throws -> [Session] {
        listSessionsCallCount += 1
        if let error = listSessionsError {
            throw error
        }
        return stubbedSessions
    }

    func archiveSession(id: String) async throws {
        archiveSessionCallCount += 1
        archiveSessionLastId = id
        if let error = archiveSessionError {
            throw error
        }
    }

    func restoreSession(id: String) async throws -> Session {
        restoreSessionCallCount += 1
        restoreSessionLastId = id
        if let error = restoreSessionError {
            throw error
        }
        if let result = restoreSessionResult {
            return result
        }
        return Session(
            id: id,
            agentId: "agent-1",
            agentName: "Test Agent",
            startedAt: Date(),
            lastInteractionAt: Date(),
            messageCount: 0,
            lastMessagePreview: nil,
            isArchived: false
        )
    }

    func sessionUpdates() -> AsyncStream<[Session]> {
        sessionUpdatesCallCount += 1
        let updates = stubbedSessionUpdates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}
