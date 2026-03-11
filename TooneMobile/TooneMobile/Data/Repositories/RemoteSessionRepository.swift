import Foundation
import SwiftData

// MARK: - RemoteSessionRepository

/// Data layer implementation of SessionRepository that manages sessions via the tunnel
/// and caches them locally with SwiftData.
final class RemoteSessionRepository: SessionRepository, @unchecked Sendable {

    // MARK: - Properties

    private let tunnelClient: TunnelClient
    private let logger: AppLogger
    private let analytics: AnalyticsService?
    private let modelContainer: ModelContainer?
    private let desktopHost: String

    // MARK: - Init

    init(
        tunnelClient: TunnelClient,
        logger: AppLogger,
        modelContainer: ModelContainer? = nil,
        desktopHost: String = "",
        analytics: AnalyticsService? = nil
    ) {
        self.tunnelClient = tunnelClient
        self.logger = logger
        self.analytics = analytics
        self.modelContainer = modelContainer
        self.desktopHost = desktopHost
    }

    // MARK: - List Sessions

    func listSessions() async throws -> [Session] {
        do {
            let response = try await tunnelClient.send(method: .sessionList)

            if let rpcError = response.error {
                throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
            }

            let sessions = SessionMapper.mapArrayFromResponse(response)
            logger.debug("Fetched \(sessions.count) sessions", category: .tunnel)

            // Cache sessions.
            for session in sessions {
                await cacheSession(session)
            }

            return sessions
        } catch {
            // Fallback to cached sessions on failure.
            logger.warning("Failed to fetch sessions, using cache: \(error)", category: .network)
            let cached = await getCachedSessions()
            if !cached.isEmpty {
                analytics?.trackCacheHit(type: "session", count: cached.count)
            }
            return cached
        }
    }

    // MARK: - Archive Session

    func archiveSession(id: String) async throws {
        let params: [String: AnyCodable] = ["sessionId": AnyCodable(string: id)]
        let response = try await tunnelClient.send(method: .sessionArchive, params: params)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        logger.info("Archived session \(id)", category: .tunnel)
    }

    // MARK: - Restore Session

    func restoreSession(id: String) async throws -> Session {
        let params: [String: AnyCodable] = ["sessionId": AnyCodable(string: id)]
        let response = try await tunnelClient.send(method: .sessionRestore, params: params)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        let session = SessionMapper.mapFromResponse(response)
        logger.info("Restored session \(id)", category: .tunnel)
        return session
    }

    // MARK: - Session Updates

    func sessionUpdates() -> AsyncStream<[Session]> {
        AsyncStream { continuation in
            Task {
                await tunnelClient.onNotification(method: .stateSubscribe) { notification in
                    let sessions = SessionMapper.mapArrayFromNotification(notification)
                    if !sessions.isEmpty {
                        continuation.yield(sessions)
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

    // MARK: - Caching Helpers

    @MainActor
    private func cacheSession(_ session: Session) {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        let cached = CachedSession(
            sessionId: session.id,
            agentId: session.agentId,
            agentName: session.agentName,
            startedAt: session.startedAt,
            lastInteractionAt: session.lastInteractionAt,
            messageCount: session.messageCount,
            lastMessagePreview: session.lastMessagePreview,
            isArchived: session.isArchived,
            desktopHost: desktopHost
        )
        context.insert(cached)
        try? context.save()
        analytics?.trackCacheWrite(type: "session")
    }

    @MainActor
    private func getCachedSessions() -> [Session] {
        guard let modelContainer else { return [] }
        let context = modelContainer.mainContext
        let host = desktopHost
        let predicate = #Predicate<CachedSession> { cached in
            cached.desktopHost == host
        }
        let descriptor = FetchDescriptor<CachedSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastInteractionAt, order: .reverse)]
        )

        guard let cachedSessions = try? context.fetch(descriptor) else {
            return []
        }

        return cachedSessions.map { cached in
            Session(
                id: cached.sessionId,
                agentId: cached.agentId,
                agentName: cached.agentName,
                startedAt: cached.startedAt,
                lastInteractionAt: cached.lastInteractionAt,
                messageCount: cached.messageCount,
                lastMessagePreview: cached.lastMessagePreview,
                isArchived: cached.isArchived
            )
        }
    }
}
