import Foundation

// MARK: - Session

public struct Session: Identifiable, Sendable, Equatable {
    public let id: String
    public let agentId: String
    public let agentName: String
    public let startedAt: Date
    public var lastInteractionAt: Date
    public var messageCount: Int
    public var lastMessagePreview: String?
    public var isArchived: Bool

    public init(
        id: String,
        agentId: String,
        agentName: String,
        startedAt: Date,
        lastInteractionAt: Date,
        messageCount: Int,
        lastMessagePreview: String?,
        isArchived: Bool
    ) {
        self.id = id
        self.agentId = agentId
        self.agentName = agentName
        self.startedAt = startedAt
        self.lastInteractionAt = lastInteractionAt
        self.messageCount = messageCount
        self.lastMessagePreview = lastMessagePreview
        self.isArchived = isArchived
    }
}
