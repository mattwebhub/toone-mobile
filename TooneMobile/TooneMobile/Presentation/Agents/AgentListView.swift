import SwiftUI

// MARK: - Agent List View

struct AgentListView: View {
    @State var viewModel: AgentListViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if let viewModel {
                    agentContent(viewModel: viewModel)
                } else {
                    disconnectedState
                }
            }
            .navigationTitle("Agents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Agent Content

    private func agentContent(viewModel: AgentListViewModel) -> some View {
        VStack(spacing: 0) {
            // Search bar
            SearchField("Find agents...", text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.searchQuery = $0 }
            ))
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            // Content
            if viewModel.isLoading && !viewModel.hasAgents {
                loadingState
            } else if viewModel.filteredDepartments.isEmpty {
                emptyState(hasSearch: !viewModel.searchQuery.isEmpty)
            } else {
                departmentList(viewModel: viewModel)
            }
        }
        .task { await viewModel.loadAgents() }
        .task { await viewModel.observeAgentUpdates() }
    }

    // MARK: - Department List

    private func departmentList(viewModel: AgentListViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.filteredDepartments) { department in
                    DepartmentSection(
                        department: department,
                        selectedAgent: viewModel.selectedAgent
                    ) { agent in
                        Task { await viewModel.switchToAgent(agent) }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .refreshable {
            await viewModel.loadAgents()
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

            Text("Loading agents...")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)

            Spacer()
        }
    }

    private func emptyState(hasSearch: Bool) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            Image(systemName: hasSearch ? "magnifyingglass" : "person.3")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text(hasSearch ? "No matching agents" : "No agents available")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text(
                hasSearch
                    ? "Try a different search term."
                    : "Agents will appear here once your desktop is configured."
            )
            .font(AppTypography.UI.body)
            .foregroundStyle(OceanDepth.textTertiary)
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
    }

    private var disconnectedState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "person.3")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("Not Connected")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Connect to your desktop to browse agents.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}

// MARK: - Preview

#Preview {
    AgentListView()
}
