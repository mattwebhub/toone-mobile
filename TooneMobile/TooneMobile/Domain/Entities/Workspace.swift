import Foundation

// MARK: - Workspace

public struct Workspace: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let projectPath: String?
    public var isActive: Bool

    public init(id: String, name: String, projectPath: String?, isActive: Bool) {
        self.id = id
        self.name = name
        self.projectPath = projectPath
        self.isActive = isActive
    }
}
