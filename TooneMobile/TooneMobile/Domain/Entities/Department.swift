import Foundation

// MARK: - Department

public struct Department: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let agents: [Agent]

    public init(id: String, name: String, agents: [Agent]) {
        self.id = id
        self.name = name
        self.agents = agents
    }
}
