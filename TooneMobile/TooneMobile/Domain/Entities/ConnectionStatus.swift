import Foundation

// MARK: - ConnectionStatus

public enum ConnectionStatus: Sendable, Equatable {
    case disconnected
    case discovering
    case connecting(host: String, port: Int)
    case authenticating
    case syncing
    case connected(DesktopInfo)
    case reconnecting(attempt: Int, maxAttempts: Int)
    case failed(ConnectionError)
}

// MARK: - DesktopInfo

public struct DesktopInfo: Sendable, Equatable {
    public let hostname: String
    public let version: String
    public let workspaceName: String?
    public let role: ConnectionRole

    public init(hostname: String, version: String, workspaceName: String?, role: ConnectionRole = .viewer) {
        self.hostname = hostname
        self.version = version
        self.workspaceName = workspaceName
        self.role = role
    }
}

// MARK: - ConnectionError

public enum ConnectionError: Error, Sendable, Equatable {
    case unreachable
    case authenticationFailed
    case versionMismatch(required: String, actual: String)
    case timeout
    case desktopDisconnected
    case unknown(String)
}
