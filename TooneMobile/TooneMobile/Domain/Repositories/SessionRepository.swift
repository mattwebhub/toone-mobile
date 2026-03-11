import Foundation

// MARK: - SessionRepository

public protocol SessionRepository: Sendable {
    func listSessions() async throws -> [Session]
    func archiveSession(id: String) async throws
    func restoreSession(id: String) async throws -> Session
    func sessionUpdates() -> AsyncStream<[Session]>
}
