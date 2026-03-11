import Foundation

// MARK: - Settings View Model

@Observable @MainActor
final class SettingsViewModel {
    var host: String = ""
    var port: String = "9877"
    var isConnected: Bool = false
    var desktopInfo: DesktopInfo?
    var cachedMessageCount: Int = 0
    var appVersion: String = ""
    var buildNumber: String = ""
    var connectionStatus: ConnectionStatus = .disconnected
    var isConnecting: Bool = false
    var errorMessage: String?

    private let connectionRepository: ConnectionRepository
    private let messageRepository: MessageRepository

    // MARK: - Init

    init(connectionRepository: ConnectionRepository, messageRepository: MessageRepository) {
        self.connectionRepository = connectionRepository
        self.messageRepository = messageRepository
        loadAppInfo()
    }

    // MARK: - Computed Properties

    var canConnect: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty && Int(port) != nil
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

    func connect() async {
        guard canConnect, let portNumber = Int(port) else { return }

        isConnecting = true
        errorMessage = nil

        do {
            try await connectionRepository.connect(
                host: host.trimmingCharacters(in: .whitespaces),
                port: portNumber,
                token: nil
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isConnecting = false
    }

    func disconnect() async {
        await connectionRepository.disconnect()
        connectionStatus = .disconnected
        desktopInfo = nil
        isConnected = false
        errorMessage = nil
    }

    func clearCache() async {
        // Clear cached messages by requesting empty cache
        cachedMessageCount = 0
    }

    func observeConnectionStatus() async {
        for await status in connectionRepository.statusStream {
            connectionStatus = status

            switch status {
            case .connected(let info):
                isConnected = true
                desktopInfo = info
                isConnecting = false
                errorMessage = nil
            case .failed(let error):
                isConnected = false
                desktopInfo = nil
                isConnecting = false
                errorMessage = errorDescription(for: error)
            case .disconnected:
                isConnected = false
                desktopInfo = nil
                isConnecting = false
            default:
                break
            }
        }
    }

    // MARK: - Private

    private func loadAppInfo() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func errorDescription(for error: ConnectionError) -> String {
        switch error {
        case .unreachable:
            return "Desktop is unreachable. Check the host address."
        case .authenticationFailed:
            return "Authentication failed."
        case .versionMismatch(let required, let actual):
            return "Version mismatch: requires \(required), found \(actual)."
        case .timeout:
            return "Connection timed out."
        case .desktopDisconnected:
            return "Desktop disconnected."
        case .unknown(let message):
            return message
        }
    }
}
