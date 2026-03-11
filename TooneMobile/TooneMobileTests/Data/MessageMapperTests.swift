import XCTest
@testable import TooneMobile

final class MessageMapperTests: XCTestCase {

    // MARK: - DTO -> Domain

    func test_toDomain_withCompleteDTO_mapsAllFields() {
        // Arrange
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let dto = MessageDTO(
            id: "msg-123",
            role: "assistant",
            timestamp: timestamp,
            content: [.text(TextContentDTO(text: "Hello"))],
            status: "completed",
            sessionId: "session-abc",
            isAudioMessage: false
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(message.id, "msg-123")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.status, .completed)
        XCTAssertEqual(message.sessionId, "session-abc")
        XCTAssertFalse(message.isAudioMessage)
        XCTAssertEqual(message.content.count, 1)
        if case .text(let textContent) = message.content.first {
            XCTAssertEqual(textContent.text, "Hello")
        } else {
            XCTFail("Expected text content")
        }
    }

    func test_toDomain_withUserRole_mapsRoleCorrectly() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-u1",
            role: "user",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [.text(TextContentDTO(text: "User message"))],
            status: "completed",
            sessionId: nil,
            isAudioMessage: nil
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(message.role, .user)
    }

    func test_toDomain_withUnknownRole_defaultsToAssistant() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-x1",
            role: "unknown_role",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [.text(TextContentDTO(text: "Fallback"))],
            status: "completed",
            sessionId: nil,
            isAudioMessage: nil
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(message.role, .assistant)
    }

    func test_toDomain_withNilSessionId_mapsToNilSession() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-ns",
            role: "assistant",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [.text(TextContentDTO(text: "No session"))],
            status: "completed",
            sessionId: nil,
            isAudioMessage: nil
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertNil(message.sessionId)
    }

    func test_toDomain_withNilIsAudioMessage_defaultsToFalse() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-a1",
            role: "user",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [.text(TextContentDTO(text: "Test"))],
            status: "completed",
            sessionId: nil,
            isAudioMessage: nil
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertFalse(message.isAudioMessage)
    }

    func test_toDomain_withStreamingStatus_mapsStatusCorrectly() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-s1",
            role: "assistant",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [.text(TextContentDTO(text: "Streaming..."))],
            status: "streaming",
            sessionId: "s1",
            isAudioMessage: false
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(message.status, .streaming)
    }

    // MARK: - Handle All MessageContent Types

    func test_toDomain_textContent_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.text(TextContentDTO(text: "Hello world"))

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .text(let textContent) = content {
            XCTAssertEqual(textContent.text, "Hello world")
        } else {
            XCTFail("Expected text content")
        }
    }

    func test_toDomain_codeBlockContent_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.codeBlock(
            CodeBlockContentDTO(id: "cb-1", language: "swift", code: "print(\"hello\")")
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .codeBlock(let codeBlock) = content {
            XCTAssertEqual(codeBlock.id, "cb-1")
            XCTAssertEqual(codeBlock.language, "swift")
            XCTAssertEqual(codeBlock.code, "print(\"hello\")")
        } else {
            XCTFail("Expected codeBlock content")
        }
    }

    func test_toDomain_codeBlockContent_withNilLanguage_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.codeBlock(
            CodeBlockContentDTO(id: "cb-2", language: nil, code: "some code")
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .codeBlock(let codeBlock) = content {
            XCTAssertNil(codeBlock.language)
        } else {
            XCTFail("Expected codeBlock content")
        }
    }

    func test_toDomain_toolCallContent_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.toolCall(
            ToolCallContentDTO(id: "tc-1", name: "readFile", status: "executing", input: "{\"path\":\"/src\"}")
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .toolCall(let toolCall) = content {
            XCTAssertEqual(toolCall.id, "tc-1")
            XCTAssertEqual(toolCall.name, "readFile")
            XCTAssertEqual(toolCall.status, .executing)
            XCTAssertEqual(toolCall.input, "{\"path\":\"/src\"}")
        } else {
            XCTFail("Expected toolCall content")
        }
    }

    func test_toDomain_toolCallContent_unknownStatus_defaultsToPending() {
        // Arrange
        let contentDTO = MessageContentDTO.toolCall(
            ToolCallContentDTO(id: "tc-2", name: "tool", status: "unknown_status", input: nil)
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .toolCall(let toolCall) = content {
            XCTAssertEqual(toolCall.status, .pending)
        } else {
            XCTFail("Expected toolCall content")
        }
    }

    func test_toDomain_toolResultContent_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.toolResult(
            ToolResultContentDTO(id: "tr-1", toolCallId: "tc-1", content: "File contents here", isError: false)
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .toolResult(let toolResult) = content {
            XCTAssertEqual(toolResult.id, "tr-1")
            XCTAssertEqual(toolResult.toolCallId, "tc-1")
            XCTAssertEqual(toolResult.content, "File contents here")
            XCTAssertFalse(toolResult.isError)
        } else {
            XCTFail("Expected toolResult content")
        }
    }

    func test_toDomain_toolResultContent_withError_mapsIsErrorTrue() {
        // Arrange
        let contentDTO = MessageContentDTO.toolResult(
            ToolResultContentDTO(id: "tr-2", toolCallId: "tc-2", content: "Error occurred", isError: true)
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .toolResult(let toolResult) = content {
            XCTAssertTrue(toolResult.isError)
        } else {
            XCTFail("Expected toolResult content")
        }
    }

    func test_toDomain_imageContent_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.image(
            ImageContentDTO(id: "img-1", url: "https://example.com/image.png", altText: "A screenshot")
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .image(let imageContent) = content {
            XCTAssertEqual(imageContent.id, "img-1")
            XCTAssertEqual(imageContent.url, "https://example.com/image.png")
            XCTAssertEqual(imageContent.altText, "A screenshot")
        } else {
            XCTFail("Expected image content")
        }
    }

    func test_toDomain_imageContent_withNilAltText_mapsCorrectly() {
        // Arrange
        let contentDTO = MessageContentDTO.image(
            ImageContentDTO(id: "img-2", url: "https://example.com/image.png", altText: nil)
        )

        // Act
        let content = MessageMapper.toDomain(contentDTO)

        // Assert
        if case .image(let imageContent) = content {
            XCTAssertNil(imageContent.altText)
        } else {
            XCTFail("Expected image content")
        }
    }

    // MARK: - Domain -> DTO

    func test_toDTO_message_mapsAllFields() {
        // Arrange
        let now = Date()
        let message = Message(
            id: "msg-1",
            role: .user,
            timestamp: now,
            content: [.text(TextContent(text: "Hello"))],
            status: .completed,
            sessionId: "s1",
            isAudioMessage: true
        )

        // Act
        let dto = MessageMapper.toDTO(message)

        // Assert
        XCTAssertEqual(dto.id, "msg-1")
        XCTAssertEqual(dto.role, "user")
        XCTAssertEqual(dto.status, "completed")
        XCTAssertEqual(dto.sessionId, "s1")
        XCTAssertEqual(dto.isAudioMessage, true)
        XCTAssertEqual(dto.content.count, 1)

        let formatter = ISO8601DateFormatter()
        let expectedTimestamp = formatter.string(from: now)
        XCTAssertEqual(dto.timestamp, expectedTimestamp)
    }

    func test_toDTO_textContent_mapsCorrectly() {
        // Arrange
        let content = MessageContent.text(TextContent(text: "Hello"))

        // Act
        let dto = MessageMapper.toDTO(content)

        // Assert
        if case .text(let textDTO) = dto {
            XCTAssertEqual(textDTO.text, "Hello")
            XCTAssertEqual(textDTO.type, "text")
        } else {
            XCTFail("Expected text DTO")
        }
    }

    func test_toDTO_codeBlockContent_mapsCorrectly() {
        // Arrange
        let content = MessageContent.codeBlock(
            CodeBlockContent(id: "cb-1", language: "python", code: "print('hi')")
        )

        // Act
        let dto = MessageMapper.toDTO(content)

        // Assert
        if case .codeBlock(let codeDTO) = dto {
            XCTAssertEqual(codeDTO.id, "cb-1")
            XCTAssertEqual(codeDTO.language, "python")
            XCTAssertEqual(codeDTO.code, "print('hi')")
            XCTAssertEqual(codeDTO.type, "codeBlock")
        } else {
            XCTFail("Expected codeBlock DTO")
        }
    }

    func test_toDTO_toolCallContent_mapsCorrectly() {
        // Arrange
        let content = MessageContent.toolCall(
            ToolCallContent(id: "tc-1", name: "readFile", status: .completed, input: "{}")
        )

        // Act
        let dto = MessageMapper.toDTO(content)

        // Assert
        if case .toolCall(let toolDTO) = dto {
            XCTAssertEqual(toolDTO.id, "tc-1")
            XCTAssertEqual(toolDTO.name, "readFile")
            XCTAssertEqual(toolDTO.status, "completed")
            XCTAssertEqual(toolDTO.input, "{}")
            XCTAssertEqual(toolDTO.type, "toolCall")
        } else {
            XCTFail("Expected toolCall DTO")
        }
    }

    func test_toDTO_toolResultContent_mapsCorrectly() {
        // Arrange
        let content = MessageContent.toolResult(
            ToolResultContent(id: "tr-1", toolCallId: "tc-1", content: "Result", isError: false)
        )

        // Act
        let dto = MessageMapper.toDTO(content)

        // Assert
        if case .toolResult(let resultDTO) = dto {
            XCTAssertEqual(resultDTO.id, "tr-1")
            XCTAssertEqual(resultDTO.toolCallId, "tc-1")
            XCTAssertEqual(resultDTO.content, "Result")
            XCTAssertFalse(resultDTO.isError)
            XCTAssertEqual(resultDTO.type, "toolResult")
        } else {
            XCTFail("Expected toolResult DTO")
        }
    }

    func test_toDTO_imageContent_mapsCorrectly() {
        // Arrange
        let content = MessageContent.image(
            ImageContent(id: "img-1", url: "https://example.com/img.png", altText: "Alt")
        )

        // Act
        let dto = MessageMapper.toDTO(content)

        // Assert
        if case .image(let imgDTO) = dto {
            XCTAssertEqual(imgDTO.id, "img-1")
            XCTAssertEqual(imgDTO.url, "https://example.com/img.png")
            XCTAssertEqual(imgDTO.altText, "Alt")
            XCTAssertEqual(imgDTO.type, "image")
        } else {
            XCTFail("Expected image DTO")
        }
    }

    // MARK: - Handle Nil/Optional Fields

    func test_toDTO_message_withNilSessionId_mapsToNil() {
        // Arrange
        let message = Message(
            id: "msg-1",
            role: .assistant,
            timestamp: Date(),
            content: [],
            status: .completed,
            sessionId: nil
        )

        // Act
        let dto = MessageMapper.toDTO(message)

        // Assert
        XCTAssertNil(dto.sessionId)
    }

    func test_toDomain_multipleContentBlocks_mapsAll() {
        // Arrange
        let dto = MessageDTO(
            id: "msg-multi",
            role: "assistant",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            content: [
                .text(TextContentDTO(text: "Here is the code:")),
                .codeBlock(CodeBlockContentDTO(id: "cb-1", language: "swift", code: "let x = 1")),
                .toolCall(ToolCallContentDTO(id: "tc-1", name: "run", status: "completed", input: nil)),
                .toolResult(ToolResultContentDTO(id: "tr-1", toolCallId: "tc-1", content: "Success", isError: false)),
                .image(ImageContentDTO(id: "img-1", url: "https://example.com/img.png", altText: nil))
            ],
            status: "completed",
            sessionId: "s1",
            isAudioMessage: false
        )

        // Act
        let message = MessageMapper.toDomain(dto)

        // Assert
        XCTAssertEqual(message.content.count, 5)
    }

    // MARK: - Round-trip DTO -> Domain -> DTO

    func test_roundTrip_messageDTO_toDomainAndBack_preservesFields() {
        // Arrange
        let now = Date()
        let formatter = ISO8601DateFormatter()
        let timestampStr = formatter.string(from: now)

        let originalDTO = MessageDTO(
            id: "msg-rt",
            role: "user",
            timestamp: timestampStr,
            content: [.text(TextContentDTO(text: "Round trip"))],
            status: "sending",
            sessionId: "s-rt",
            isAudioMessage: true
        )

        // Act
        let domain = MessageMapper.toDomain(originalDTO)
        let backToDTO = MessageMapper.toDTO(domain)

        // Assert
        XCTAssertEqual(backToDTO.id, originalDTO.id)
        XCTAssertEqual(backToDTO.role, originalDTO.role)
        XCTAssertEqual(backToDTO.status, originalDTO.status)
        XCTAssertEqual(backToDTO.sessionId, originalDTO.sessionId)
        XCTAssertEqual(backToDTO.isAudioMessage, originalDTO.isAudioMessage)
        XCTAssertEqual(backToDTO.content.count, originalDTO.content.count)
    }

    // MARK: - AnyCodable -> Domain (fromAnyCodable)

    func test_fromAnyCodable_withValidDict_returnsMessage() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "id": AnyCodable(string: "msg-ac"),
            "role": AnyCodable(string: "assistant"),
            "content": AnyCodable(array: [
                AnyCodable(dictionary: [
                    "type": AnyCodable(string: "text"),
                    "text": AnyCodable(string: "Hello from AnyCodable")
                ])
            ]),
            "status": AnyCodable(string: "completed"),
            "sessionId": AnyCodable(string: "s-ac")
        ])

        // Act
        let message = MessageMapper.fromAnyCodable(value)

        // Assert
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.id, "msg-ac")
        XCTAssertEqual(message?.role, .assistant)
        XCTAssertEqual(message?.status, .completed)
        XCTAssertEqual(message?.sessionId, "s-ac")
        XCTAssertEqual(message?.content.count, 1)
    }

    func test_fromAnyCodable_withMissingId_returnsNil() {
        // Arrange
        let value = AnyCodable(dictionary: [
            "role": AnyCodable(string: "user"),
            "content": AnyCodable(string: "No id")
        ])

        // Act
        let message = MessageMapper.fromAnyCodable(value)

        // Assert
        XCTAssertNil(message)
    }
}
