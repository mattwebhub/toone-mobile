import Foundation

// MARK: - Agent

public struct Agent: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let departmentId: String
    public let capabilities: [String]
    public let routineNames: [String]
    public let greeting: String?
    public let isSystem: Bool
    public var sessionId: String?

    public init(
        id: String,
        name: String,
        description: String,
        departmentId: String,
        capabilities: [String],
        routineNames: [String],
        greeting: String?,
        isSystem: Bool,
        sessionId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.departmentId = departmentId
        self.capabilities = capabilities
        self.routineNames = routineNames
        self.greeting = greeting
        self.isSystem = isSystem
        self.sessionId = sessionId
    }
}
