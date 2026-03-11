import Foundation
@testable import TooneMobile

// MARK: - MockMessageRepository

final class MockMessageRepository: MessageRepository, @unchecked Sendable {

    // MARK: - Call Tracking

    var sendMessageCallCount = 0
    var sendMessageLastContent: String?
    var sendMessageLastAgentId: String?
    var sendMessageLastSessionId: String?
    var answerQuestionCallCount = 0
    var answerQuestionLastQuestionId: String?
    var answerQuestionLastAnswer: String?
    var cachedMessagesCallCount = 0
    var messageStreamCallCount = 0

    // MARK: - Stubbed Results

    var sendMessageResult: Message?
    var sendMessageError: Error?
    var stubbedMessages: [Message] = []
    var stubbedStreamMessages: [Message] = []
    var answerQuestionError: Error?
    var stubbedCachedMessages: [Message] = []

    // MARK: - MessageRepository

    func sendMessage(content: String, agentId: String, sessionId: String?) async throws -> Message {
        sendMessageCallCount += 1
        sendMessageLastContent = content
        sendMessageLastAgentId = agentId
        sendMessageLastSessionId = sessionId
        if let error = sendMessageError {
            throw error
        }
        if let result = sendMessageResult {
            return result
        }
        return Message(
            id: UUID().uuidString,
            role: .user,
            timestamp: Date(),
            content: [.text(TextContent(text: content))],
            status: .completed,
            sessionId: sessionId
        )
    }

    func messageStream(sessionId: String) -> AsyncStream<Message> {
        messageStreamCallCount += 1
        let messages = stubbedStreamMessages
        return AsyncStream { continuation in
            for message in messages {
                continuation.yield(message)
            }
            continuation.finish()
        }
    }

    func answerQuestion(questionId: String, answer: String) async throws {
        answerQuestionCallCount += 1
        answerQuestionLastQuestionId = questionId
        answerQuestionLastAnswer = answer
        if let error = answerQuestionError {
            throw error
        }
    }

    func cachedMessages(sessionId: String) async -> [Message] {
        cachedMessagesCallCount += 1
        return stubbedCachedMessages
    }
}
