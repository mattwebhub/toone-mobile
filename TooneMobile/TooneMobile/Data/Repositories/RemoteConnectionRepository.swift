import Foundation

// MARK: - RemoteConnectionRepository

/// Data layer implementation of ConnectionRepository that communicates
/// with toone-desktop via the WebSocket tunnel. Manages domain-level status
/// transitions including handshake-driven authentication and sync phases.
final class RemoteConnectionRepository: ConnectionRepository, @unchecked Sendable {

    // MARK: - Properties

    private let connectionManager: ConnectionManager
    private let tunnelClient: TunnelClient
    private let logger: AppLogger

    private let statusContinuation: AsyncStream<ConnectionStatus>.Continuation
    private let _statusStream: AsyncStream<ConnectionStatus>

    // MARK: - Init

    init(connectionManager: ConnectionManager, tunnelClient: TunnelClient, logger: AppLogger) {
        self.connectionManager = connectionManager
        self.tunnelClient = tunnelClient
        self.logger = logger

        // Build the domain-level status stream. Statuses are pushed explicitly
        // from connect/disconnect to ensure the full lifecycle is represented
        // (discovering -> connecting -> authenticating -> syncing -> connected).
        var continuation: AsyncStream<ConnectionStatus>.Continuation!
        _statusStream = AsyncStream { continuation = $0 }
        statusContinuation = continuation
    }

    // MARK: - ConnectionRepository

    var statusStream: AsyncStream<ConnectionStatus> {
        _statusStream
    }

    func connect(host: String, port: Int, token: String?) async throws {
        logger.info("Connecting to \(host):\(port)", category: .network)
        statusContinuation.yield(.discovering)
        statusContinuation.yield(.connecting(host: host, port: port))

        do {
            statusContinuation.yield(.authenticating)
            let info = try await connectionManager.connect(host: host, port: port, token: token)
            statusContinuation.yield(.syncing)
            statusContinuation.yield(.connected(info))
            logger.info("Connected to \(info.hostname) v\(info.version)", category: .network)
        } catch {
            let connectionError: ConnectionError
            if let tunnelError = error as? TunnelError {
                switch tunnelError {
                case .authenticationFailed:
                    connectionError = .authenticationFailed
                case .requestTimeout:
                    connectionError = .timeout
                case .notConnected, .connectionFailed:
                    connectionError = .unreachable
                default:
                    connectionError = .unknown(tunnelError.localizedDescription)
                }
            } else {
                connectionError = .unknown(error.localizedDescription)
            }
            statusContinuation.yield(.failed(connectionError))
            throw error
        }
    }

    func disconnect() async {
        logger.info("Disconnecting from desktop", category: .network)
        await connectionManager.disconnect()
        statusContinuation.yield(.disconnected)
    }

    func ping() async throws -> TimeInterval {
        let start = Date()
        _ = try await tunnelClient.send(method: .connectionPing)
        return Date().timeIntervalSince(start)
    }
}
