import SwiftData
import Foundation

// MARK: - CachedSession

/// SwiftData model for offline caching of sessions.
@Model
final class CachedSession {
    @Attribute(.unique) var sessionId: String
    var agentId: String
    var agentName: String
    var startedAt: Date
    var lastInteractionAt: Date
    var messageCount: Int
    var lastMessagePreview: String?
    var isArchived: Bool
    var desktopHost: String

    init(
        sessionId: String,
        agentId: String,
        agentName: String,
        startedAt: Date,
        lastInteractionAt: Date,
        messageCount: Int,
        lastMessagePreview: String?,
        isArchived: Bool,
        desktopHost: String
    ) {
        self.sessionId = sessionId
        self.agentId = agentId
        self.agentName = agentName
        self.startedAt = startedAt
        self.lastInteractionAt = lastInteractionAt
        self.messageCount = messageCount
        self.lastMessagePreview = lastMessagePreview
        self.isArchived = isArchived
        self.desktopHost = desktopHost
    }
}
