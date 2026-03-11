import Foundation

// MARK: - Connection Role

/// Defines the permission level for a mobile connection to the desktop.
public enum ConnectionRole: String, Sendable, Codable, Equatable {
    case admin
    case viewer

    // MARK: - Permissions

    var canSendMessages: Bool {
        self == .admin
    }

    var canSwitchAgents: Bool {
        self == .admin
    }

    var canManageSessions: Bool {
        self == .admin
    }

    var canBrowseFiles: Bool {
        true
    }

    var canViewChat: Bool {
        true
    }
}
