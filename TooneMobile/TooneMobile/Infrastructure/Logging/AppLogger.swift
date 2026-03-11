import os
import Foundation

// MARK: - AppLogger

final class AppLogger: Sendable {
    static let shared = AppLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.toone.mobile"

    private let generalLog: Logger
    private let networkLog: Logger
    private let tunnelLog: Logger
    private let uiLog: Logger

    init() {
        generalLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.toone.mobile", category: "general")
        networkLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.toone.mobile", category: "network")
        tunnelLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.toone.mobile", category: "tunnel")
        uiLog = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.toone.mobile", category: "ui")
    }

    // MARK: - Public API

    func info(_ message: String, category: LogCategory = .general) {
        logger(for: category).info("\(message, privacy: .private)")
    }

    func debug(_ message: String, category: LogCategory = .general) {
        logger(for: category).debug("\(message, privacy: .private)")
    }

    func warning(_ message: String, category: LogCategory = .general) {
        logger(for: category).warning("\(message, privacy: .public)")
    }

    func error(_ message: String, category: LogCategory = .general) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    // MARK: - LogCategory

    enum LogCategory: Sendable {
        case general
        case network
        case tunnel
        case ui
    }

    // MARK: - Private

    private func logger(for category: LogCategory) -> Logger {
        switch category {
        case .general:
            return generalLog
        case .network:
            return networkLog
        case .tunnel:
            return tunnelLog
        case .ui:
            return uiLog
        }
    }
}
