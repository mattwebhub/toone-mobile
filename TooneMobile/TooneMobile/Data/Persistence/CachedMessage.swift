import SwiftData
import Foundation

// MARK: - CachedMessage

/// SwiftData model for offline caching of messages.
/// Stores message content as serialized JSON to support the polymorphic MessageContent type.
@Model
final class CachedMessage {
    @Attribute(.unique) var messageId: String
    var role: String
    var contentJSON: Data
    var status: String
    var sessionId: String?
    var timestamp: Date
    var desktopHost: String

    init(
        messageId: String,
        role: String,
        contentJSON: Data,
        status: String,
        sessionId: String?,
        timestamp: Date,
        desktopHost: String
    ) {
        self.messageId = messageId
        self.role = role
        self.contentJSON = contentJSON
        self.status = status
        self.sessionId = sessionId
        self.timestamp = timestamp
        self.desktopHost = desktopHost
    }
}
