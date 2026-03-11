import Foundation

// MARK: - ConnectToDesktopUseCase

struct ConnectToDesktopUseCase {

    private let connectionRepository: ConnectionRepository

    init(connectionRepository: ConnectionRepository) {
        self.connectionRepository = connectionRepository
    }

    // MARK: - Execute

    func execute(host: String, port: Int, token: String?) async throws -> AsyncStream<ConnectionStatus> {
        guard !host.isEmpty else {
            throw ConnectionError.unreachable
        }
        guard port > 0, port <= 65535 else {
            throw ConnectionError.unreachable
        }

        try await connectionRepository.connect(host: host, port: port, token: token)
        return connectionRepository.statusStream
    }

    // MARK: - Disconnect

    func disconnect() async {
        await connectionRepository.disconnect()
    }

    // MARK: - Ping

    func ping() async throws -> TimeInterval {
        try await connectionRepository.ping()
    }
}
