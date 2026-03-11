import XCTest
@testable import TooneMobile

final class MockConnectionRepository: ConnectionRepository, @unchecked Sendable {
    var statusStreamValues: [ConnectionStatus] = [.disconnected]
    var connectCalled = false
    var connectHost: String?
    var connectPort: Int?
    var disconnectCalled = false
    var pingResult: TimeInterval = 0.05
    var shouldThrowOnConnect = false

    var statusStream: AsyncStream<ConnectionStatus> {
        AsyncStream { continuation in
            for status in statusStreamValues {
                continuation.yield(status)
            }
            continuation.finish()
        }
    }

    func connect(host: String, port: Int, token: String?) async throws {
        connectCalled = true
        connectHost = host
        connectPort = port
        if shouldThrowOnConnect { throw ConnectionError.unreachable }
    }

    func disconnect() async { disconnectCalled = true }
    func ping() async throws -> TimeInterval { pingResult }
}
