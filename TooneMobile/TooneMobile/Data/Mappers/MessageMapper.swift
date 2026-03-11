import Foundation

// MARK: - MessageMapper

/// Maps between Message JSON-RPC responses/notifications, Domain entities, and persistence models.
enum MessageMapper {

    // MARK: - Response -> Domain

    /// Parse a Message from a JSON-RPC response result.
    static func mapFromResponse(_ response: JSONRPCResponse) -> Message {
        let dict = response.result?.dictionaryValue ?? [:]
        return mapMessage(from: dict)
    }

    // MARK: - Notification -> Domain

    /// Parse a Message from a JSON-RPC notification.
    static func mapFromNotification(_ notification: JSONRPCNotification) -> Message? {
        guard let dict = notification.params?.dictionaryValue else { return nil }
        return mapMessage(from: dict)
    }

    // MARK: - AnyCodable -> Domain

    /// Parse a Message from an AnyCodable dictionary.
    static func mapFromAnyCodable(_ value: AnyCodable?) -> Message? {
        guard let dict = value?.dictionaryValue else { return nil }
        return mapMessage(from: dict)
    }

    // MARK: - Domain -> DTO

    static func toDTO(_ message: Message) -> MessageDTO {
        let formatter = ISO8601DateFormatter()
        return MessageDTO(
            id: message.id,
            role: message.role.rawValue,
            timestamp: formatter.string(from: message.timestamp),
            content: message.content.map { contentToDTO($0) },
            status: message.status.rawValue,
            sessionId: message.sessionId,
            isAudioMessage: message.isAudioMessage
        )
    }

    // MARK: - DTO -> Domain

    static func toDomain(_ dto: MessageDTO) -> Message {
        let role = MessageRole(rawValue: dto.role) ?? .assistant
        let status = MessageStatus(rawValue: dto.status) ?? .completed
        let timestamp = ISO8601DateFormatter().date(from: dto.timestamp) ?? Date()
        let content = dto.content.map { contentToDomain($0) }

        return Message(
            id: dto.id,
            role: role,
            timestamp: timestamp,
            content: content,
            status: status,
            sessionId: dto.sessionId,
            isAudioMessage: dto.isAudioMessage ?? false
        )
    }

    // MARK: - Cache -> Domain

    /// Convert a CachedMessage from SwiftData back to a Domain Message.
    static func fromCached(_ cached: CachedMessage) -> Message? {
        guard let role = MessageRole(rawValue: cached.role),
              let status = MessageStatus(rawValue: cached.status) else {
            return nil
        }

        let contentDTOs = (try? JSONDecoder().decode([MessageContentDTO].self, from: cached.contentJSON)) ?? []
        let content = contentDTOs.map { contentToDomain($0) }

        return Message(
            id: cached.messageId,
            role: role,
            timestamp: cached.timestamp,
            content: content,
            status: status,
            sessionId: cached.sessionId
        )
    }

    /// Convert a Domain Message to a CachedMessage for SwiftData persistence.
    static func toCached(_ message: Message, desktopHost: String) -> CachedMessage {
        let contentData = (try? JSONEncoder().encode(message.content.map { contentToDTO($0) })) ?? Data()
        return CachedMessage(
            messageId: message.id,
            role: message.role.rawValue,
            contentJSON: contentData,
            status: message.status.rawValue,
            sessionId: message.sessionId,
            timestamp: message.timestamp,
            desktopHost: desktopHost
        )
    }

    // MARK: - Private Helpers

    private static func mapMessage(from dict: [String: AnyCodable]) -> Message {
        let id = dict["id"]?.stringValue ?? UUID().uuidString
        let role = MessageRole(rawValue: dict["role"]?.stringValue ?? "assistant") ?? .assistant
        let status = MessageStatus(rawValue: dict["status"]?.stringValue ?? "completed") ?? .completed
        let timestamp = dict["timestamp"]?.stringValue.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let sessionId = dict["sessionId"]?.stringValue
        let isAudio = dict["isAudioMessage"]?.boolValue ?? false

        // Parse content: can be an array of content blocks or a single string.
        let content: [MessageContent]
        if let contentArray = dict["content"]?.arrayValue {
            content = contentArray.compactMap { contentFromAnyCodable($0) }
        } else if let text = dict["content"]?.stringValue {
            content = [.text(TextContent(text: text))]
        } else {
            content = []
        }

        return Message(
            id: id,
            role: role,
            timestamp: timestamp,
            content: content,
            status: status,
            sessionId: sessionId,
            isAudioMessage: isAudio
        )
    }

    private static func contentFromAnyCodable(_ value: AnyCodable) -> MessageContent? {
        guard let dict = value.dictionaryValue,
              let type = dict["type"]?.stringValue else {
            // Fallback: if it's a plain string, treat as text.
            if let text = value.stringValue {
                return .text(TextContent(text: text))
            }
            return nil
        }

        switch type {
        case "text":
            guard let text = dict["text"]?.stringValue else { return nil }
            return .text(TextContent(text: text))
        case "codeBlock":
            guard let id = dict["id"]?.stringValue,
                  let code = dict["code"]?.stringValue else { return nil }
            return .codeBlock(CodeBlockContent(id: id, language: dict["language"]?.stringValue, code: code))
        case "toolCall":
            guard let id = dict["id"]?.stringValue,
                  let name = dict["name"]?.stringValue else { return nil }
            let status = dict["status"]?.stringValue.flatMap { ToolCallStatus(rawValue: $0) } ?? .pending
            return .toolCall(ToolCallContent(id: id, name: name, status: status, input: dict["input"]?.stringValue))
        case "toolResult":
            guard let id = dict["id"]?.stringValue,
                  let toolCallId = dict["toolCallId"]?.stringValue,
                  let resultContent = dict["content"]?.stringValue else { return nil }
            return .toolResult(ToolResultContent(id: id, toolCallId: toolCallId, content: resultContent, isError: dict["isError"]?.boolValue ?? false))
        case "image":
            guard let id = dict["id"]?.stringValue,
                  let url = dict["url"]?.stringValue else { return nil }
            return .image(ImageContent(id: id, url: url, altText: dict["altText"]?.stringValue))
        default:
            return nil
        }
    }

    private static func contentToDomain(_ dto: MessageContentDTO) -> MessageContent {
        switch dto {
        case .text(let text):
            return .text(TextContent(text: text.text))
        case .codeBlock(let block):
            return .codeBlock(CodeBlockContent(id: block.id, language: block.language, code: block.code))
        case .toolCall(let call):
            let status = ToolCallStatus(rawValue: call.status) ?? .pending
            return .toolCall(ToolCallContent(id: call.id, name: call.name, status: status, input: call.input))
        case .toolResult(let result):
            return .toolResult(ToolResultContent(id: result.id, toolCallId: result.toolCallId, content: result.content, isError: result.isError))
        case .image(let image):
            return .image(ImageContent(id: image.id, url: image.url, altText: image.altText))
        }
    }

    private static func contentToDTO(_ content: MessageContent) -> MessageContentDTO {
        switch content {
        case .text(let text):
            return .text(TextContentDTO(text: text.text))
        case .codeBlock(let block):
            return .codeBlock(CodeBlockContentDTO(id: block.id, language: block.language, code: block.code))
        case .toolCall(let call):
            return .toolCall(ToolCallContentDTO(id: call.id, name: call.name, status: call.status.rawValue, input: call.input))
        case .toolResult(let result):
            return .toolResult(ToolResultContentDTO(id: result.id, toolCallId: result.toolCallId, content: result.content, isError: result.isError))
        case .image(let image):
            return .image(ImageContentDTO(id: image.id, url: image.url, altText: image.altText))
        }
    }
}
