import XCTest
@testable import TooneMobile

final class SendMessageUseCaseTests: XCTestCase {

    private var mockMessageRepo: MockMessageRepository!
    private var mockConnectionRepo: MockConnectionRepository!
    private var sut: SendMessageUseCase!

    override func setUp() {
        super.setUp()
        mockMessageRepo = MockMessageRepository()
        mockConnectionRepo = MockConnectionRepository()
        sut = SendMessageUseCase(
            messageRepository: mockMessageRepo,
            connectionRepository: mockConnectionRepo
        )
    }

    override func tearDown() {
        mockMessageRepo = nil
        mockConnectionRepo = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Send Valid Message Returns Message

    func test_execute_validContent_sendsMessageAndReturnsIt() async throws {
        // Arrange
        let expectedMessage = Message(
            id: "msg-1",
            role: .user,
            timestamp: Date(),
            content: [.text(TextContent(text: "Hello"))],
            status: .completed,
            sessionId: "session-1"
        )
        mockMessageRepo.sendMessageResult = expectedMessage

        // Act
        let result = try await sut.execute(
            content: "Hello",
            agentId: "agent-1",
            sessionId: "session-1"
        )

        // Assert
        XCTAssertEqual(result.id, "msg-1")
        XCTAssertEqual(result.role, .user)
        XCTAssertEqual(mockMessageRepo.sendMessageCallCount, 1)
        XCTAssertEqual(mockMessageRepo.sendMessageLastContent, "Hello")
        XCTAssertEqual(mockMessageRepo.sendMessageLastAgentId, "agent-1")
        XCTAssertEqual(mockMessageRepo.sendMessageLastSessionId, "session-1")
    }

    func test_execute_contentWithWhitespace_trimsBeforeSending() async throws {
        // Act
        _ = try await sut.execute(
            content: "  Hello World  ",
            agentId: "agent-1",
            sessionId: nil
        )

        // Assert
        XCTAssertEqual(mockMessageRepo.sendMessageLastContent, "Hello World")
    }

    // MARK: - Empty Message Content Throws Validation Error

    func test_execute_emptyContent_throwsEmptyContentError() async {
        do {
            _ = try await sut.execute(
                content: "",
                agentId: "agent-1",
                sessionId: nil
            )
            XCTFail("Expected SendMessageError.emptyContent to be thrown")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .emptyContent)
        }

        XCTAssertEqual(mockMessageRepo.sendMessageCallCount, 0,
                        "Repository should not be called for empty content")
    }

    func test_execute_whitespaceOnlyContent_throwsEmptyContentError() async {
        do {
            _ = try await sut.execute(
                content: "   \n\t  ",
                agentId: "agent-1",
                sessionId: nil
            )
            XCTFail("Expected SendMessageError.emptyContent to be thrown")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .emptyContent)
        }
    }

    func test_execute_emptyAgentId_throwsEmptyAgentIdError() async {
        do {
            _ = try await sut.execute(
                content: "Hello",
                agentId: "",
                sessionId: nil
            )
            XCTFail("Expected SendMessageError.emptyAgentId to be thrown")
        } catch {
            XCTAssertEqual(error as? SendMessageError, .emptyAgentId)
        }

        XCTAssertEqual(mockMessageRepo.sendMessageCallCount, 0,
                        "Repository should not be called for empty agent ID")
    }

    // MARK: - Message Gets Correct Role and Timestamp

    func test_execute_validMessage_returnsMessageWithCorrectRoleAndTimestamp() async throws {
        // Arrange
        let now = Date()
        let expectedMessage = Message(
            id: "msg-2",
            role: .user,
            timestamp: now,
            content: [.text(TextContent(text: "Test"))],
            status: .completed,
            sessionId: "s1"
        )
        mockMessageRepo.sendMessageResult = expectedMessage

        // Act
        let result = try await sut.execute(
            content: "Test",
            agentId: "agent-1",
            sessionId: "s1"
        )

        // Assert
        XCTAssertEqual(result.role, .user)
        XCTAssertEqual(result.timestamp, now)
    }

    // MARK: - Message Stream

    func test_messageStream_returnsStreamFromRepository() async {
        // Arrange
        let expectedMessages = [
            Message(
                id: "m1", role: .assistant, timestamp: Date(),
                content: [.text(TextContent(text: "Hi"))],
                status: .streaming, sessionId: "s1"
            ),
            Message(
                id: "m2", role: .assistant, timestamp: Date(),
                content: [.text(TextContent(text: "Hello there"))],
                status: .completed, sessionId: "s1"
            )
        ]
        mockMessageRepo.stubbedStreamMessages = expectedMessages

        // Act
        let stream = sut.messageStream(sessionId: "s1")
        var received: [Message] = []
        for await message in stream {
            received.append(message)
        }

        // Assert
        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].id, "m1")
        XCTAssertEqual(received[1].id, "m2")
    }

    // MARK: - Cached Messages

    func test_cachedMessages_returnsCachedMessagesFromRepository() async {
        // Arrange
        let cached = [
            Message(
                id: "c1", role: .user, timestamp: Date(),
                content: [.text(TextContent(text: "cached"))],
                status: .completed, sessionId: "s1"
            )
        ]
        mockMessageRepo.stubbedCachedMessages = cached

        // Act
        let result = await sut.cachedMessages(sessionId: "s1")

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "c1")
        XCTAssertEqual(mockMessageRepo.cachedMessagesCallCount, 1)
    }
}
