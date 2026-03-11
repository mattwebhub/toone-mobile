import Foundation

// MARK: - MessageDTO

/// Data transfer object for messages received from the JSON-RPC tunnel.
struct MessageDTO: Codable, Sendable {
    let id: String
    let role: String
    let timestamp: String
    let content: [MessageContentDTO]
    let status: String
    let sessionId: String?
    let isAudioMessage: Bool?
}

// MARK: - MessageContentDTO

/// Data transfer object for message content blocks.
enum MessageContentDTO: Codable, Sendable {
    case text(TextContentDTO)
    case codeBlock(CodeBlockContentDTO)
    case toolCall(ToolCallContentDTO)
    case toolResult(ToolResultContentDTO)
    case image(ImageContentDTO)

    // MARK: - Coding Keys

    private enum CodingKeys: String, CodingKey {
        case type
    }

    private enum ContentType: String, Codable {
        case text
        case codeBlock
        case toolCall
        case toolResult
        case image
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        let singleContainer = try decoder.singleValueContainer()

        switch type {
        case .text:
            self = .text(try singleContainer.decode(TextContentDTO.self))
        case .codeBlock:
            self = .codeBlock(try singleContainer.decode(CodeBlockContentDTO.self))
        case .toolCall:
            self = .toolCall(try singleContainer.decode(ToolCallContentDTO.self))
        case .toolResult:
            self = .toolResult(try singleContainer.decode(ToolResultContentDTO.self))
        case .image:
            self = .image(try singleContainer.decode(ImageContentDTO.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let dto):
            try container.encode(dto)
        case .codeBlock(let dto):
            try container.encode(dto)
        case .toolCall(let dto):
            try container.encode(dto)
        case .toolResult(let dto):
            try container.encode(dto)
        case .image(let dto):
            try container.encode(dto)
        }
    }
}

// MARK: - Content DTOs

struct TextContentDTO: Codable, Sendable {
    let type: String
    let text: String

    init(text: String) {
        self.type = "text"
        self.text = text
    }
}

struct CodeBlockContentDTO: Codable, Sendable {
    let type: String
    let id: String
    let language: String?
    let code: String

    init(id: String, language: String?, code: String) {
        self.type = "codeBlock"
        self.id = id
        self.language = language
        self.code = code
    }
}

struct ToolCallContentDTO: Codable, Sendable {
    let type: String
    let id: String
    let name: String
    let status: String
    let input: String?

    init(id: String, name: String, status: String, input: String?) {
        self.type = "toolCall"
        self.id = id
        self.name = name
        self.status = status
        self.input = input
    }
}

struct ToolResultContentDTO: Codable, Sendable {
    let type: String
    let id: String
    let toolCallId: String
    let content: String
    let isError: Bool

    init(id: String, toolCallId: String, content: String, isError: Bool) {
        self.type = "toolResult"
        self.id = id
        self.toolCallId = toolCallId
        self.content = content
        self.isError = isError
    }
}

struct ImageContentDTO: Codable, Sendable {
    let type: String
    let id: String
    let url: String
    let altText: String?

    init(id: String, url: String, altText: String?) {
        self.type = "image"
        self.id = id
        self.url = url
        self.altText = altText
    }
}

// MARK: - Send Message Request

/// Parameters for sending a message via the tunnel.
struct SendMessageParams: Codable, Sendable {
    let text: String
    let sessionId: String?
    let agentId: String?
    let isAudioMessage: Bool

    init(text: String, sessionId: String? = nil, agentId: String? = nil, isAudioMessage: Bool = false) {
        self.text = text
        self.sessionId = sessionId
        self.agentId = agentId
        self.isAudioMessage = isAudioMessage
    }
}

// MARK: - Answer Question Request

/// Parameters for answering a question prompt from the desktop.
struct AnswerQuestionParams: Codable, Sendable {
    let questionId: String
    let answer: String
}

// MARK: - Message Stream Event

/// A streaming event received via notification during message generation.
struct MessageStreamEvent: Codable, Sendable {
    let messageId: String
    let delta: MessageContentDTO?
    let status: String?
    let sessionId: String?
}
