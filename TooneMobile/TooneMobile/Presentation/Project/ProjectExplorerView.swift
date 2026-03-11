import SwiftUI

// MARK: - Project Explorer View

struct ProjectExplorerView: View {
    @State var viewModel: ProjectExplorerViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if let viewModel {
                    projectContent(viewModel: viewModel)
                } else {
                    disconnectedState
                }
            }
            .navigationTitle("Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if let viewModel, viewModel.hasProject {
                    ToolbarItem(placement: .principal) {
                        Text(viewModel.projectName)
                            .font(AppTypography.Panel.title)
                            .foregroundStyle(OceanDepth.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Project Content

    private func projectContent(viewModel: ProjectExplorerViewModel) -> some View {
        Group {
            if viewModel.isLoading && !viewModel.hasProject {
                loadingState
            } else if let rootFile = viewModel.rootFile {
                fileTreeContent(viewModel: viewModel, rootFile: rootFile)
            } else {
                noProjectState
            }
        }
        .task { await viewModel.loadFileTree() }
        .task { await viewModel.observeProjectUpdates() }
        .sheet(isPresented: Binding(
            get: { viewModel.showFileContent },
            set: { if !$0 { viewModel.closeFileContent() } }
        )) {
            if let selectedFile = viewModel.selectedFile {
                FileContentView(
                    fileName: selectedFile.name,
                    content: viewModel.fileContent ?? "",
                    isLoading: viewModel.isLoadingContent
                ) {
                    viewModel.closeFileContent()
                }
            }
        }
    }

    // MARK: - File Tree Content

    private func fileTreeContent(viewModel: ProjectExplorerViewModel, rootFile: ProjectFile) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let children = rootFile.children {
                    FileTreeView(
                        files: children,
                        expandedPaths: viewModel.expandedPaths,
                        depth: 0
                    ) { file in
                        Task { await viewModel.selectFile(file) }
                    }
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .refreshable {
            await viewModel.loadFileTree()
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            ProgressView()
                .progressViewStyle(.circular)
                .tint(OceanDepth.textSecondary)
                .scaleEffect(1.2)

            Text("Loading project...")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)

            Spacer()
        }
    }

    private var noProjectState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            Image(systemName: "folder")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("No project open")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Open a project on your desktop to browse files here.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
    }

    private var disconnectedState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("Not Connected")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Connect to your desktop to browse project files.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    ProjectExplorerView()
}
