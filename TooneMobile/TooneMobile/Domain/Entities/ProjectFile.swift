import Foundation

// MARK: - ProjectFile

public struct ProjectFile: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let children: [ProjectFile]?
    public let size: Int?
    public let modifiedAt: Date?

    public init(
        id: String,
        name: String,
        path: String,
        isDirectory: Bool,
        children: [ProjectFile]?,
        size: Int?,
        modifiedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.children = children
        self.size = size
        self.modifiedAt = modifiedAt
    }
}
