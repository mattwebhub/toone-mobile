import Foundation

// MARK: - BrowseProjectError

enum BrowseProjectError: Error, Sendable {
    case emptyPath
}

// MARK: - BrowseProjectUseCase

struct BrowseProjectUseCase {

    private let projectRepository: ProjectRepository

    init(projectRepository: ProjectRepository) {
        self.projectRepository = projectRepository
    }

    // MARK: - File Tree

    func execute() async throws -> ProjectFile {
        try await projectRepository.fileTree()
    }

    // MARK: - Read File

    func readFile(path: String) async throws -> String {
        guard !path.isEmpty else {
            throw BrowseProjectError.emptyPath
        }

        return try await projectRepository.readFile(path: path)
    }

    // MARK: - Updates

    func projectUpdates() -> AsyncStream<ProjectFile> {
        projectRepository.projectUpdates()
    }
}
