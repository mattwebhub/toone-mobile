import Foundation

// MARK: - AgentDTO

/// Data transfer object for agents received from the JSON-RPC tunnel.
struct AgentDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let departmentId: String
    let capabilities: [String]?
    let routineNames: [String]?
    let greeting: String?
    let isSystem: Bool?
    let sessionId: String?
}

// MARK: - DepartmentDTO

/// Data transfer object for departments received from the JSON-RPC tunnel.
struct DepartmentDTO: Codable, Sendable {
    let id: String
    let name: String
    let agents: [AgentDTO]?
}

// MARK: - Agent List Response

/// The result payload for the agent.list RPC method.
struct AgentListResult: Codable, Sendable {
    let departments: [DepartmentDTO]
    let activeAgentId: String?
}

// MARK: - Switch Agent Request

/// Parameters for switching the active agent via the tunnel.
struct SwitchAgentParams: Codable, Sendable {
    let agentId: String
}

// MARK: - Agent Update Event

/// A notification payload when agent state changes on the desktop.
struct AgentUpdateEvent: Codable, Sendable {
    let agentId: String
    let sessionId: String?
    let event: String // "switched", "updated", "sessionCreated"
}
