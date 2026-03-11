import Foundation

// MARK: - JSON-RPC 2.0 Base Types

struct JSONRPCRequest: Codable, Sendable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?
    let id: String

    init(method: String, params: AnyCodable? = nil, id: String) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }
}

struct JSONRPCResponse: Codable, Sendable {
    let jsonrpc: String
    let result: AnyCodable?
    let error: JSONRPCError?
    let id: String?
}

struct JSONRPCNotification: Codable, Sendable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?
}

struct JSONRPCError: Codable, Sendable {
    let code: Int
    let message: String
    let data: AnyCodable?
}

// MARK: - Tunnel Methods

enum TunnelMethod: String, Sendable {
    // Auth
    case authHandshake = "auth.handshake"
    case authVerify = "auth.verify"

    // State
    case stateSync = "state.sync"
    case stateSubscribe = "state.subscribe"

    // Chat
    case chatSendMessage = "chat.sendMessage"
    case chatMessageStream = "chat.messageStream"
    case chatToolCall = "chat.toolCall"
    case chatAnswerQuestion = "chat.answerQuestion"
    case chatMessageComplete = "chat.messageComplete"

    // Agent
    case agentList = "agent.list"
    case agentSwitch = "agent.switch"

    // Session
    case sessionList = "session.list"
    case sessionArchive = "session.archive"
    case sessionRestore = "session.restore"

    // Project
    case projectTree = "project.tree"
    case projectReadFile = "project.readFile"

    // Connection
    case connectionPing = "connection.ping"
    case connectionStatus = "connection.status"
}

// MARK: - Error Codes

enum TunnelErrorCode: Int, Sendable {
    case parseError = -32700
    case invalidRequest = -32600
    case methodNotFound = -32601
    case invalidParams = -32602
    case internalError = -32603
    // Custom codes
    case authRequired = -32000
    case authFailed = -32001
    case sessionNotFound = -32002
    case agentNotFound = -32003
    case fileNotFound = -32004
    case desktopBusy = -32005
}

// MARK: - Tunnel Error

enum TunnelError: Error, Sendable {
    case notConnected
    case connectionFailed(String)
    case authenticationFailed(String)
    case requestTimeout
    case invalidResponse
    case rpcError(code: Int, message: String)
    case encodingFailed
    case decodingFailed(String)
    case rateLimitExceeded
    case payloadTooLarge
}
