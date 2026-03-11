import Foundation

// MARK: - MessageRole

public enum MessageRole: String, Sendable, Codable {
    case user
    case assistant
    case system
    case toolResult
}

// MARK: - MessageStatus

public enum MessageStatus: String, Sendable, Codable {
    case sending
    case streaming
    case completed
    case failed
}

// MARK: - Message

public struct Message: Identifiable, Sendable, Equatable {
    public let id: String
    public let role: MessageRole
    public let timestamp: Date
    public var content: [MessageContent]
    public var status: MessageStatus
    public let sessionId: String?
    public var isAudioMessage: Bool

    public init(
        id: String,
        role: MessageRole,
        timestamp: Date,
        content: [MessageContent],
        status: MessageStatus,
        sessionId: String?,
        isAudioMessage: Bool = false
    ) {
        self.id = id
        self.role = role
        self.timestamp = timestamp
        self.content = content
        self.status = status
        self.sessionId = sessionId
        self.isAudioMessage = isAudioMessage
    }
}
