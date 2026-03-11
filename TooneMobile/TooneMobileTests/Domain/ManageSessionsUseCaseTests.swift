import XCTest
@testable import TooneMobile

final class ManageSessionsUseCaseTests: XCTestCase {

    private var mockSessionRepo: MockSessionRepository!
    private var sut: ManageSessionsUseCase!

    override func setUp() {
        super.setUp()
        mockSessionRepo = MockSessionRepository()
        sut = ManageSessionsUseCase(sessionRepository: mockSessionRepo)
    }

    override func tearDown() {
        mockSessionRepo = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - List Sessions

    func test_execute_withSessions_returnsAllSessions() async throws {
        // Arrange
        let now = Date()
        let sessions = [
            Session(
                id: "s1", agentId: "a1", agentName: "Agent A",
                startedAt: now, lastInteractionAt: now,
                messageCount: 5, lastMessagePreview: "Hello",
                isArchived: false
            ),
            Session(
                id: "s2", agentId: "a2", agentName: "Agent B",
                startedAt: now, lastInteractionAt: now,
                messageCount: 10, lastMessagePreview: "Goodbye",
                isArchived: true
            )
        ]
        mockSessionRepo.stubbedSessions = sessions

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "s1")
        XCTAssertEqual(result[0].agentName, "Agent A")
        XCTAssertEqual(result[0].messageCount, 5)
        XCTAssertEqual(result[1].id, "s2")
        XCTAssertTrue(result[1].isArchived)
        XCTAssertEqual(mockSessionRepo.listSessionsCallCount, 1)
    }

    func test_execute_withNoSessions_returnsEmptyArray() async throws {
        // Arrange
        mockSessionRepo.stubbedSessions = []

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockSessionRepo.listSessionsError = ConnectionError.unreachable

        // Act & Assert
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .unreachable)
        }
    }

    // MARK: - Archive Session

    func test_archiveSession_validId_callsRepository() async throws {
        // Act
        try await sut.archiveSession(id: "s1")

        // Assert
        XCTAssertEqual(mockSessionRepo.archiveSessionCallCount, 1)
        XCTAssertEqual(mockSessionRepo.archiveSessionLastId, "s1")
    }

    func test_archiveSession_emptyId_throwsEmptySessionIdError() async {
        // Act & Assert
        do {
            try await sut.archiveSession(id: "")
            XCTFail("Expected ManageSessionsError.emptySessionId to be thrown")
        } catch {
            XCTAssertEqual(error as? ManageSessionsError, .emptySessionId)
        }

        XCTAssertEqual(mockSessionRepo.archiveSessionCallCount, 0,
                        "Repository should not be called with an empty session ID")
    }

    func test_archiveSession_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockSessionRepo.archiveSessionError = ConnectionError.timeout

        // Act & Assert
        do {
            try await sut.archiveSession(id: "s1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .timeout)
        }
    }

    // MARK: - Restore Session

    func test_restoreSession_validId_returnsRestoredSession() async throws {
        // Arrange
        let now = Date()
        let session = Session(
            id: "s1", agentId: "a1", agentName: "Agent A",
            startedAt: now, lastInteractionAt: now,
            messageCount: 3, lastMessagePreview: "Last message",
            isArchived: false
        )
        mockSessionRepo.restoreSessionResult = session

        // Act
        let result = try await sut.restoreSession(id: "s1")

        // Assert
        XCTAssertEqual(result.id, "s1")
        XCTAssertEqual(result.agentName, "Agent A")
        XCTAssertFalse(result.isArchived)
        XCTAssertEqual(mockSessionRepo.restoreSessionCallCount, 1)
        XCTAssertEqual(mockSessionRepo.restoreSessionLastId, "s1")
    }

    func test_restoreSession_emptyId_throwsEmptySessionIdError() async {
        // Act & Assert
        do {
            _ = try await sut.restoreSession(id: "")
            XCTFail("Expected ManageSessionsError.emptySessionId to be thrown")
        } catch {
            XCTAssertEqual(error as? ManageSessionsError, .emptySessionId)
        }

        XCTAssertEqual(mockSessionRepo.restoreSessionCallCount, 0,
                        "Repository should not be called with an empty session ID")
    }

    func test_restoreSession_whenRepositoryThrows_propagatesError() async {
        // Arrange
        mockSessionRepo.restoreSessionError = ConnectionError.desktopDisconnected

        // Act & Assert
        do {
            _ = try await sut.restoreSession(id: "s1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? ConnectionError, .desktopDisconnected)
        }
    }

    // MARK: - Session Updates

    func test_sessionUpdates_returnsStreamFromRepository() async {
        // Arrange
        let now = Date()
        let batch1 = [
            Session(id: "s1", agentId: "a1", agentName: "Agent A",
                    startedAt: now, lastInteractionAt: now,
                    messageCount: 1, lastMessagePreview: nil, isArchived: false)
        ]
        let batch2 = [
            Session(id: "s1", agentId: "a1", agentName: "Agent A",
                    startedAt: now, lastInteractionAt: now,
                    messageCount: 2, lastMessagePreview: "New", isArchived: false),
            Session(id: "s2", agentId: "a2", agentName: "Agent B",
                    startedAt: now, lastInteractionAt: now,
                    messageCount: 0, lastMessagePreview: nil, isArchived: false)
        ]
        mockSessionRepo.stubbedSessionUpdates = [batch1, batch2]

        // Act
        let stream = sut.sessionUpdates()
        var received: [[Session]] = []
        for await update in stream {
            received.append(update)
        }

        // Assert
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].count, 1)
        XCTAssertEqual(received[1].count, 2)
        XCTAssertEqual(mockSessionRepo.sessionUpdatesCallCount, 1)
    }
}
