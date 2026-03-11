import Foundation

// MARK: - Settings View Model

@Observable @MainActor
final class SettingsViewModel {
    var connectionStatus: ConnectionStatus = .disconnected
    var desktopInfo: DesktopInfo?
    var host: String = ""
    var port: String = "9877"
    var showDisconnectConfirmation: Bool = false
    var cacheCleared: Bool = false
    var appVersion: String = "1.0.0"

    private let connectionRepository: ConnectionRepository

    // MARK: - Init

    init(connectionRepository: ConnectionRepository) {
        self.connectionRepository = connectionRepository
    }

    // MARK: - Computed Properties

    var isConnected: Bool {
        if case .connected = connectionStatus { return true }
        return false
    }

    var connectionStatusText: String {
        switch connectionStatus {
        case .disconnected:
            return "Not connected"
        case .discovering:
            return "Searching..."
        case .connecting(let host, let port):
            return "Connecting to \(host):\(port)..."
        case .authenticating:
            return "Authenticating..."
        case .syncing:
            return "Syncing..."
        case .connected(let info):
            return "Connected to \(info.hostname)"
        case .reconnecting(let attempt, let maxAttempts):
            return "Reconnecting (\(attempt)/\(maxAttempts))..."
        case .failed:
            return "Connection failed"
        }
    }

    var statusBadgeType: StatusBadge.Status {
        switch connectionStatus {
        case .disconnected: return .disconnected
        case .discovering, .connecting, .authenticating, .syncing: return .connecting
        case .connected: return .connected
        case .reconnecting: return .connecting
        case .failed: return .error
        }
    }

    // MARK: - Actions

    func disconnect() async {
        await connectionRepository.disconnect()
        connectionStatus = .disconnected
        desktopInfo = nil
    }

    func clearCache() {
        // Placeholder: will clear cached messages and state
        cacheCleared = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            cacheCleared = false
        }
    }

    func observeConnectionStatus() async {
        for await status in connectionRepository.statusStream {
            connectionStatus = status

            if case .connected(let info) = status {
                desktopInfo = info
            }
        }
    }
}
