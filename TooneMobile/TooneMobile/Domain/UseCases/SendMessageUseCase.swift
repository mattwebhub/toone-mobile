import Foundation

// MARK: - SendMessageError

enum SendMessageError: Error, Sendable {
    case emptyContent
    case emptyAgentId
}

// MARK: - SendMessageUseCase

struct SendMessageUseCase {

    private let messageRepository: MessageRepository
    private let connectionRepository: ConnectionRepository

    init(messageRepository: MessageRepository, connectionRepository: ConnectionRepository) {
        self.messageRepository = messageRepository
        self.connectionRepository = connectionRepository
    }

    // MARK: - Execute

    func execute(content: String, agentId: String, sessionId: String?) async throws -> Message {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SendMessageError.emptyContent
        }
        guard !agentId.isEmpty else {
            throw SendMessageError.emptyAgentId
        }

        return try await messageRepository.sendMessage(
            content: trimmed,
            agentId: agentId,
            sessionId: sessionId
        )
    }

    // MARK: - Stream

    func messageStream(sessionId: String) -> AsyncStream<Message> {
        messageRepository.messageStream(sessionId: sessionId)
    }

    // MARK: - Cached Messages

    func cachedMessages(sessionId: String) async -> [Message] {
        await messageRepository.cachedMessages(sessionId: sessionId)
    }
}
