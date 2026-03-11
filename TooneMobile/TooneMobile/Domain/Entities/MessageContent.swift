import Foundation

// MARK: - MessageContent

public enum MessageContent: Sendable, Equatable, Identifiable {
    case text(TextContent)
    case codeBlock(CodeBlockContent)
    case toolCall(ToolCallContent)
    case toolResult(ToolResultContent)
    case image(ImageContent)

    public var id: String {
        switch self {
        case .text(let content):
            return content.text.hashValue.description
        case .codeBlock(let content):
            return content.id
        case .toolCall(let content):
            return content.id
        case .toolResult(let content):
            return content.id
        case .image(let content):
            return content.id
        }
    }
}

// MARK: - TextContent

public struct TextContent: Sendable, Equatable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

// MARK: - CodeBlockContent

public struct CodeBlockContent: Sendable, Equatable, Identifiable {
    public let id: String
    public let language: String?
    public let code: String

    public init(id: String, language: String?, code: String) {
        self.id = id
        self.language = language
        self.code = code
    }
}

// MARK: - ToolCallContent

public struct ToolCallContent: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let status: ToolCallStatus
    public let input: String?

    public init(id: String, name: String, status: ToolCallStatus, input: String?) {
        self.id = id
        self.name = name
        self.status = status
        self.input = input
    }
}

// MARK: - ToolCallStatus

public enum ToolCallStatus: String, Sendable, Codable, Equatable {
    case pending
    case executing
    case completed
    case failed
}

// MARK: - ToolResultContent

public struct ToolResultContent: Sendable, Equatable, Identifiable {
    public let id: String
    public let toolCallId: String
    public let content: String
    public let isError: Bool

    public init(id: String, toolCallId: String, content: String, isError: Bool) {
        self.id = id
        self.toolCallId = toolCallId
        self.content = content
        self.isError = isError
    }
}

// MARK: - ImageContent

public struct ImageContent: Sendable, Equatable, Identifiable {
    public let id: String
    public let url: String
    public let altText: String?

    public init(id: String, url: String, altText: String?) {
        self.id = id
        self.url = url
        self.altText = altText
    }
}
