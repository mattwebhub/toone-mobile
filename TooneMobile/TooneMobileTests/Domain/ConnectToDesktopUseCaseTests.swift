import XCTest
@testable import TooneMobile

final class ConnectToDesktopUseCaseTests: XCTestCase {

    private var mockConnectionRepo: MockConnectionRepository!
    private var sut: ConnectToDesktopUseCase!

    override func setUp() {
        super.setUp()
        mockConnectionRepo = MockConnectionRepository()
        sut = ConnectToDesktopUseCase(connectionRepository: mockConnectionRepo)
    }

    override func tearDown() {
        mockConnectionRepo = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Successful Connection

    func test_execute_validHostAndPort_connectsAndReturnsStatusStream() async throws {
        // Arrange
        let desktopInfo = DesktopInfo(hostname: "MacBook", version: "1.0", workspaceName: "MyProject")
        mockConnectionRepo.statusStreamValues = [
            .discovering,
            .connecting(host: "192.168.1.10", port: 9877),
            .connected(desktopInfo)
        ]

        // Act
        let stream = try await sut.execute(host: "192.168.1.10", port: 9877, token: nil)

        // Assert
        XCTAssertTrue(mockConnectionRepo.connectCalled)
        XCTAssertEqual(mockConnectionRepo.connectHost, "192.168.1.10")
        XCTAssertEqual(mockConnectionRepo.connectPort, 9877)

        var statuses: [ConnectionStatus] = []
        for await status in stream {
            statuses.append(status)
        }

        XCTAssertEqual(statuses.count, 3)
        XCTAssertEqual(statuses[0], .discovering)
        XCTAssertEqual(statuses[1], .connecting(host: "192.168.1.10", port: 9877))
        XCTAssertEqual(statuses[2], .connected(desktopInfo))
    }

    // MARK: - Connection Failure

    func test_execute_repositoryThrows_propagatesError() async {
        // Arrange
        mockConnectionRepo.shouldThrowOnConnect = true

        // Act & Assert
        do {
            _ = try await sut.execute(host: "192.168.1.10", port: 9877, token: nil)
            XCTFail("Expected ConnectionError.unreachable to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }
    }

    // MARK: - Empty Host Validation

    func test_execute_emptyHost_throwsUnreachableError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(host: "", port: 9877, token: nil)
            XCTFail("Expected ConnectionError.unreachable to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }

        XCTAssertFalse(mockConnectionRepo.connectCalled,
                        "Repository should not be called with an empty host")
    }

    // MARK: - Invalid Port Validation

    func test_execute_zeroPort_throwsUnreachableError() async {
        do {
            _ = try await sut.execute(host: "192.168.1.10", port: 0, token: nil)
            XCTFail("Expected ConnectionError.unreachable to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }

        XCTAssertFalse(mockConnectionRepo.connectCalled)
    }

    func test_execute_negativePort_throwsUnreachableError() async {
        do {
            _ = try await sut.execute(host: "192.168.1.10", port: -1, token: nil)
            XCTFail("Expected ConnectionError.unreachable to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }
    }

    func test_execute_portAbove65535_throwsUnreachableError() async {
        do {
            _ = try await sut.execute(host: "192.168.1.10", port: 70000, token: nil)
            XCTFail("Expected ConnectionError.unreachable to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }
    }

    // MARK: - Status Stream Propagation

    func test_execute_statusStreamPropagation_receivesAllStatuses() async throws {
        // Arrange
        mockConnectionRepo.statusStreamValues = [
            .disconnected,
            .discovering,
            .connecting(host: "10.0.0.1", port: 9877),
            .authenticating,
            .syncing,
            .connected(DesktopInfo(hostname: "Mac", version: "2.0", workspaceName: nil))
        ]

        // Act
        let stream = try await sut.execute(host: "10.0.0.1", port: 9877, token: "token")

        var received: [ConnectionStatus] = []
        for await status in stream {
            received.append(status)
        }

        // Assert
        XCTAssertEqual(received.count, 6)
        XCTAssertEqual(received[0], .disconnected)
        XCTAssertEqual(received[3], .authenticating)
        XCTAssertEqual(received[4], .syncing)
    }

    // MARK: - Disconnect

    func test_disconnect_callsRepositoryDisconnect() async {
        await sut.disconnect()

        XCTAssertTrue(mockConnectionRepo.disconnectCalled)
    }

    // MARK: - Ping

    func test_ping_returnsLatencyFromRepository() async throws {
        mockConnectionRepo.pingResult = 0.042

        let latency = try await sut.ping()

        XCTAssertEqual(latency, 0.042)
    }
}
