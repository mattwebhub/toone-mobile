import Foundation

// MARK: - AppConfiguration

struct AppConfiguration: Sendable {
    let defaultPort: Int = 9877
    let tunnelProtocolVersion: String = "1.0"
    let reconnectMaxAttempts: Int = 10
    let reconnectBaseDelay: TimeInterval = 1.0
    let reconnectMaxDelay: TimeInterval = 30.0
    let pingInterval: TimeInterval = 15.0
    let messagesCacheLimit: Int = 1000
    let appVersion: String
    let buildNumber: String

    init() {
        appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
