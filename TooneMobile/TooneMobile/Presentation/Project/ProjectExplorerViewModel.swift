import Foundation

// MARK: - Project Explorer View Model

@Observable @MainActor
final class ProjectExplorerViewModel {
    var rootFile: ProjectFile?
    var expandedPaths: Set<String> = []
    var selectedFile: ProjectFile?
    var fileContent: String?
    var isLoading: Bool = false
    var isLoadingContent: Bool = false
    var errorMessage: String?
    var showFileContent: Bool = false

    private let browseProjectUseCase: BrowseProjectUseCase

    // MARK: - Init

    init(browseProjectUseCase: BrowseProjectUseCase) {
        self.browseProjectUseCase = browseProjectUseCase
    }

    // MARK: - Computed Properties

    var projectName: String {
        rootFile?.name ?? "Project"
    }

    var hasProject: Bool {
        rootFile != nil
    }

    // MARK: - Actions

    func loadFileTree() async {
        isLoading = true
        errorMessage = nil

        do {
            rootFile = try await browseProjectUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleExpand(path: String) {
        if expandedPaths.contains(path) {
            expandedPaths.remove(path)
        } else {
            expandedPaths.insert(path)
        }
    }

    func selectFile(_ file: ProjectFile) async {
        guard !file.isDirectory else {
            toggleExpand(path: file.path)
            return
        }

        selectedFile = file
        isLoadingContent = true
        fileContent = nil

        do {
            fileContent = try await browseProjectUseCase.readFile(path: file.path)
            showFileContent = true
        } catch {
            errorMessage = "Could not read file: \(error.localizedDescription)"
        }

        isLoadingContent = false
    }

    func closeFileContent() {
        showFileContent = false
        selectedFile = nil
        fileContent = nil
    }

    func observeProjectUpdates() async {
        for await updatedRoot in browseProjectUseCase.projectUpdates() {
            rootFile = updatedRoot
        }
    }
}
