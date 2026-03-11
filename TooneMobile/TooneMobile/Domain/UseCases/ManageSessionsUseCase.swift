import Foundation

// MARK: - ManageSessionsError

enum ManageSessionsError: Error, Sendable {
    case emptySessionId
}

// MARK: - ManageSessionsUseCase

struct ManageSessionsUseCase {

    private let sessionRepository: SessionRepository

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - List

    func execute() async throws -> [Session] {
        try await sessionRepository.listSessions()
    }

    // MARK: - Archive

    func archiveSession(id: String) async throws {
        guard !id.isEmpty else {
            throw ManageSessionsError.emptySessionId
        }

        try await sessionRepository.archiveSession(id: id)
    }

    // MARK: - Restore

    func restoreSession(id: String) async throws -> Session {
        guard !id.isEmpty else {
            throw ManageSessionsError.emptySessionId
        }

        return try await sessionRepository.restoreSession(id: id)
    }

    // MARK: - Updates

    func sessionUpdates() -> AsyncStream<[Session]> {
        sessionRepository.sessionUpdates()
    }
}
