import Foundation

// MARK: - Connection View Model

@Observable @MainActor
final class ConnectionViewModel {
    var host: String = ""
    var port: String = "9877"
    var connectionStatus: ConnectionStatus = .disconnected
    var isConnecting: Bool = false
    var errorMessage: String?

    private let connectionRepository: ConnectionRepository

    // MARK: - Init

    init(connectionRepository: ConnectionRepository) {
        self.connectionRepository = connectionRepository
    }

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(port) != nil
    }

    var statusDescription: String {
        switch connectionStatus {
        case .disconnected:
            return "Not connected"
        case .discovering:
            return "Searching for desktop..."
        case .connecting(let host, let port):
            return "Connecting to \(host):\(port)..."
        case .authenticating:
            return "Authenticating..."
        case .syncing:
            return "Syncing state..."
        case .connected(let info):
            return "Connected to \(info.hostname)"
        case .reconnecting(let attempt, let maxAttempts):
            return "Reconnecting (\(attempt)/\(maxAttempts))..."
        case .failed(let error):
            return errorDescription(for: error)
        }
    }

    // MARK: - Actions

    func connect() async {
        guard isFormValid, let portNumber = Int(port) else { return }

        isConnecting = true
        errorMessage = nil
        connectionStatus = .connecting(host: host, port: portNumber)

        do {
            try await connectionRepository.connect(
                host: host.trimmingCharacters(in: .whitespaces),
                port: portNumber,
                token: nil
            )
        } catch {
            errorMessage = error.localizedDescription
            connectionStatus = .failed(.unknown(error.localizedDescription))
        }

        isConnecting = false
    }

    func disconnect() async {
        await connectionRepository.disconnect()
        connectionStatus = .disconnected
        errorMessage = nil
    }

    func observeStatus() async {
        for await status in connectionRepository.statusStream {
            connectionStatus = status
            switch status {
            case .connected:
                isConnecting = false
                errorMessage = nil
            case .failed(let error):
                isConnecting = false
                errorMessage = errorDescription(for: error)
            default:
                break
            }
        }
    }

    // MARK: - Private

    private func errorDescription(for error: ConnectionError) -> String {
        switch error {
        case .unreachable:
            return "Desktop is unreachable. Check the host address."
        case .authenticationFailed:
            return "Authentication failed. Check your credentials."
        case .versionMismatch(let required, let actual):
            return "Version mismatch: requires \(required), found \(actual)."
        case .timeout:
            return "Connection timed out. Try again."
        case .desktopDisconnected:
            return "Desktop disconnected unexpectedly."
        case .unknown(let message):
            return message
        }
    }
}
