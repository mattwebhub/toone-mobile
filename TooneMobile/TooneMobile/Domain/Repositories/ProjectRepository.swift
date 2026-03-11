import Foundation

// MARK: - ProjectRepository

public protocol ProjectRepository: Sendable {
    func fileTree() async throws -> ProjectFile
    func readFile(path: String) async throws -> String
    func projectUpdates() -> AsyncStream<ProjectFile>
}
