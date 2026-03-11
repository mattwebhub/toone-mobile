import Foundation
@testable import TooneMobile

final class MockProjectRepository: ProjectRepository, @unchecked Sendable {

    // MARK: - Call Tracking

    var fileTreeCallCount = 0
    var readFileCallCount = 0
    var readFileLastPath: String?
    var projectUpdatesCallCount = 0

    // MARK: - Stubbed Results

    var stubbedFileTree: ProjectFile?
    var fileTreeError: Error?
    var stubbedFileContent: String = ""
    var readFileError: Error?
    var stubbedProjectUpdates: [ProjectFile] = []

    // MARK: - ProjectRepository

    func fileTree() async throws -> ProjectFile {
        fileTreeCallCount += 1
        if let error = fileTreeError {
            throw error
        }
        if let tree = stubbedFileTree {
            return tree
        }
        return ProjectFile(
            id: "root",
            name: "project",
            path: "/",
            isDirectory: true,
            children: nil,
            size: nil,
            modifiedAt: nil
        )
    }

    func readFile(path: String) async throws -> String {
        readFileCallCount += 1
        readFileLastPath = path
        if let error = readFileError {
            throw error
        }
        return stubbedFileContent
    }

    func projectUpdates() -> AsyncStream<ProjectFile> {
        projectUpdatesCallCount += 1
        let updates = stubbedProjectUpdates
        return AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }
    }
}
