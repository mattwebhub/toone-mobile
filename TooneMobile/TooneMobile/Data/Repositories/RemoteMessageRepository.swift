import Foundation
import SwiftData

// MARK: - RemoteMessageRepository

/// Data layer implementation of MessageRepository that sends messages via the tunnel,
/// receives streaming responses via notifications, and caches messages locally with SwiftData.
final class RemoteMessageRepository: MessageRepository, @unchecked Sendable {

    // MARK: - Properties

    private let tunnelClient: TunnelClient
    private let logger: AppLogger
    private let cacheLimit: Int
    private let modelContainer: ModelContainer?
    private let desktopHost: String

    // MARK: - Init

    init(
        tunnelClient: TunnelClient,
        logger: AppLogger,
        cacheLimit: Int,
        modelContainer: ModelContainer? = nil,
        desktopHost: String = ""
    ) {
        self.tunnelClient = tunnelClient
        self.logger = logger
        self.cacheLimit = cacheLimit
        self.modelContainer = modelContainer
        self.desktopHost = desktopHost
    }

    // MARK: - Send Message

    func sendMessage(content: String, agentId: String, sessionId: String?) async throws -> Message {
        let params: [String: AnyCodable] = [
            "content": AnyCodable(string: content),
            "agentId": AnyCodable(string: agentId),
            "sessionId": sessionId.map { AnyCodable(string: $0) } ?? AnyCodable.null
        ]

        let response = try await tunnelClient.send(method: .chatSendMessage, params: params)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        let message = MessageMapper.mapFromResponse(response)
        logger.debug("Message sent: \(message.id)", category: .tunnel)

        await cacheMessage(message)
        return message
    }

    // MARK: - Message Stream

    func messageStream(sessionId: String) -> AsyncStream<Message> {
        AsyncStream { continuation in
            Task {
                await tunnelClient.onNotification(method: .chatMessageStream) { [weak self] notification in
                    if let message = MessageMapper.mapFromNotification(notification) {
                        continuation.yield(message)

                        if let self {
                            Task { await self.cacheMessage(message) }
                        }
                    }
                }

                await tunnelClient.onNotification(method: .chatMessageComplete) { [weak self] notification in
                    if let message = MessageMapper.mapFromNotification(notification) {
                        continuation.yield(message)

                        if let self {
                            Task { await self.cacheMessage(message) }
                        }
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    Task { [weak self] in
                        guard let self else { return }
                        await self.tunnelClient.removeNotificationHandler(for: .chatMessageStream)
                        await self.tunnelClient.removeNotificationHandler(for: .chatMessageComplete)
                    }
                }
            }
        }
    }

    // MARK: - Answer Question

    func answerQuestion(questionId: String, answer: String) async throws {
        let params: [String: AnyCodable] = [
            "questionId": AnyCodable(string: questionId),
            "answer": AnyCodable(string: answer)
        ]

        let response = try await tunnelClient.send(method: .chatAnswerQuestion, params: params)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }
    }

    // MARK: - Cached Messages

    func cachedMessages(sessionId: String) async -> [Message] {
        guard let modelContainer else { return [] }
        return await getCachedMessages(sessionId: sessionId, container: modelContainer)
    }

    // MARK: - Caching Helpers

    @MainActor
    private func cacheMessage(_ message: Message) {
        guard let modelContainer else { return }
        let context = modelContainer.mainContext
        let cached = MessageMapper.toCached(message, desktopHost: desktopHost)
        context.insert(cached)
        try? context.save()
    }

    @MainActor
    private func getCachedMessages(sessionId: String, container: ModelContainer) -> [Message] {
        let context = container.mainContext
        let host = desktopHost
        let predicate = #Predicate<CachedMessage> { cached in
            cached.sessionId == sessionId && cached.desktopHost == host
        }
        let descriptor = FetchDescriptor<CachedMessage>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )

        guard let cachedMessages = try? context.fetch(descriptor) else {
            return []
        }

        return cachedMessages.compactMap { MessageMapper.fromCached($0) }
    }
}
