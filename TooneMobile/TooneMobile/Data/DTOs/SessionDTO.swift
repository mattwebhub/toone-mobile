import Foundation

// MARK: - SessionDTO

/// Data transfer object for sessions received from the JSON-RPC tunnel.
struct SessionDTO: Codable, Sendable {
    let id: String
    let agentId: String
    let agentName: String?
    let startedAt: String
    let lastInteractionAt: String?
    let messageCount: Int?
    let lastMessagePreview: String?
    let isArchived: Bool?
}

// MARK: - Session List Result

/// The result payload for the session.list RPC method.
struct SessionListResult: Codable, Sendable {
    let sessions: [SessionDTO]
}

// MARK: - Session Archive Request

/// Parameters for archiving a session via the tunnel.
struct SessionArchiveParams: Codable, Sendable {
    let sessionId: String
}

// MARK: - Session Restore Request

/// Parameters for restoring an archived session via the tunnel.
struct SessionRestoreParams: Codable, Sendable {
    let sessionId: String
}

// MARK: - Session Update Event

/// A notification payload when session state changes on the desktop.
struct SessionUpdateEvent: Codable, Sendable {
    let sessionId: String
    let event: String // "created", "updated", "archived", "restored"
    let session: SessionDTO?
}
