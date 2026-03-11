import Foundation

// MARK: - MessageRepository

public protocol MessageRepository: Sendable {
    func sendMessage(content: String, agentId: String, sessionId: String?) async throws -> Message
    func messageStream(sessionId: String) -> AsyncStream<Message>
    func answerQuestion(questionId: String, answer: String) async throws
    func cachedMessages(sessionId: String) async -> [Message]
}
