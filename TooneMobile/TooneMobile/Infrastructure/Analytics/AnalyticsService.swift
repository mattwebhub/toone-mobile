import Foundation
import os

// MARK: - Analytics Event

struct AnalyticsEvent: Sendable {
    let name: String
    let properties: [String: String]
    let timestamp: Date

    init(name: String, properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
        self.timestamp = Date()
    }
}

// MARK: - Performance Metric

struct PerformanceMetric: Sendable {
    let name: String
    let duration: TimeInterval
    let properties: [String: String]
    let timestamp: Date

    init(name: String, duration: TimeInterval, properties: [String: String] = [:]) {
        self.name = name
        self.duration = duration
        self.properties = properties
        self.timestamp = Date()
    }
}

// MARK: - Analytics Service

final class AnalyticsService: Sendable {
    let isEnabled: Bool
    private let signposter: OSSignposter
    private let logger: os.Logger

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
        self.signposter = OSSignposter(subsystem: "com.toone.mobile", category: "Performance")
        self.logger = os.Logger(subsystem: "com.toone.mobile", category: "Analytics")
    }

    // MARK: - Event Tracking

    func track(event: String, properties: [String: String] = [:]) {
        guard isEnabled else { return }
        logger.info("[\(event, privacy: .private)] \(properties.description, privacy: .private)")
    }

    // MARK: - Performance Tracking

    /// Start a signpost interval for Instruments profiling.
    /// Returns a state object to pass to `endInterval`.
    func beginInterval(_ name: StaticString) -> OSSignpostIntervalState {
        signposter.beginInterval(name)
    }

    /// End a signpost interval started with `beginInterval`.
    func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
        signposter.endInterval(name, state)
    }

    /// Measure an async operation's duration and track it.
    func measure<T: Sendable>(
        _ name: String,
        properties: [String: String] = [:],
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        let start = ContinuousClock.now
        let result = try await operation()
        let elapsed = start.duration(to: ContinuousClock.now)
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18

        trackMetric(PerformanceMetric(name: name, duration: seconds, properties: properties))
        return result
    }

    /// Record a performance metric.
    func trackMetric(_ metric: PerformanceMetric) {
        guard isEnabled else { return }

        var allProps = metric.properties
        allProps["duration_ms"] = String(format: "%.1f", metric.duration * 1000)

        logger.info("[perf:\(metric.name, privacy: .private)] \(metric.duration * 1000, format: .fixed(precision: 1), privacy: .private)ms \(allProps.description, privacy: .private)")
    }

    // MARK: - Connection Events

    func trackConnectionAttempt(host: String, port: Int) {
        track(event: "connection.attempt", properties: [
            "host_hash": String(host.hashValue),
            "port": String(port)
        ])
    }

    func trackConnectionSuccess(host: String, duration: TimeInterval) {
        track(event: "connection.success", properties: [
            "host_hash": String(host.hashValue),
            "duration_ms": String(format: "%.1f", duration * 1000)
        ])
    }

    func trackConnectionFailure(host: String, error: String) {
        track(event: "connection.failure", properties: [
            "host_hash": String(host.hashValue),
            "error": error
        ])
    }

    func trackReconnectionAttempt(attempt: Int, delay: TimeInterval) {
        track(event: "connection.reconnect", properties: [
            "attempt": String(attempt),
            "delay_ms": String(format: "%.0f", delay * 1000)
        ])
    }

    func trackReconnectionSuccess(attempt: Int, totalDuration: TimeInterval) {
        track(event: "connection.reconnect.success", properties: [
            "attempt": String(attempt),
            "total_duration_ms": String(format: "%.0f", totalDuration * 1000)
        ])
    }

    // MARK: - Message Events

    func trackMessageSent(agentId: String) {
        track(event: "message.sent", properties: [
            "agent_id_hash": String(agentId.hashValue)
        ])
    }

    func trackMessageRoundTrip(duration: TimeInterval) {
        trackMetric(PerformanceMetric(
            name: "message.roundtrip",
            duration: duration
        ))
    }

    func trackStreamingComplete(duration: TimeInterval, contentCount: Int) {
        trackMetric(PerformanceMetric(
            name: "message.streaming",
            duration: duration,
            properties: ["content_blocks": String(contentCount)]
        ))
    }

    // MARK: - Cache Events

    func trackCacheHit(type: String, count: Int) {
        track(event: "cache.hit", properties: [
            "type": type,
            "count": String(count)
        ])
    }

    func trackCacheMiss(type: String) {
        track(event: "cache.miss", properties: ["type": type])
    }

    func trackCacheWrite(type: String) {
        track(event: "cache.write", properties: ["type": type])
    }

    // MARK: - Error Events

    func trackError(category: String, error: String) {
        track(event: "error", properties: [
            "category": category,
            "error": error
        ])
    }

    // MARK: - Handshake Events

    func trackHandshakeComplete(duration: TimeInterval, role: String) {
        trackMetric(PerformanceMetric(
            name: "handshake",
            duration: duration,
            properties: ["role": role]
        ))
    }
}
