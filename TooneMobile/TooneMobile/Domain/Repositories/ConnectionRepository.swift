import Foundation

// MARK: - ConnectionRepository

public protocol ConnectionRepository: Sendable {
    var statusStream: AsyncStream<ConnectionStatus> { get }
    func connect(host: String, port: Int, token: String?) async throws
    func disconnect() async
    func ping() async throws -> TimeInterval
}
