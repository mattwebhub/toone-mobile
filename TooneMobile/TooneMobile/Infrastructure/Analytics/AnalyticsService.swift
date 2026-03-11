import Foundation

// MARK: - AnalyticsService

final class AnalyticsService: Sendable {
    private let isEnabled: Bool

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func track(event: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        // Future: send to analytics backend
    }
}
