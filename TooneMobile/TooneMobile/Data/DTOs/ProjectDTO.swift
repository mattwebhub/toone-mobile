import Foundation

// MARK: - ProjectFileDTO

/// Data transfer object for project tree nodes received from the JSON-RPC tunnel.
struct ProjectFileDTO: Codable, Sendable {
    let name: String
    let path: String
    let isDirectory: Bool
    let children: [ProjectFileDTO]?
    let size: Int?
    let language: String?
}

// MARK: - Project Tree Result

/// The result payload for the project.tree RPC method.
struct ProjectTreeResult: Codable, Sendable {
    let root: ProjectFileDTO
}

// MARK: - Read File Request

/// Parameters for reading a file's content via the tunnel.
struct ReadFileParams: Codable, Sendable {
    let path: String
    let maxLines: Int?

    init(path: String, maxLines: Int? = nil) {
        self.path = path
        self.maxLines = maxLines
    }
}

// MARK: - Read File Result

/// The result payload for the project.readFile RPC method.
struct ReadFileResult: Codable, Sendable {
    let path: String
    let content: String
    let language: String?
    let lineCount: Int?
    let truncated: Bool?
}
