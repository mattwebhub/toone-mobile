import SwiftUI

// MARK: - Session History View Model

@Observable @MainActor
final class SessionHistoryViewModel {
    var sessions: [Session] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let manageSessionsUseCase: ManageSessionsUseCase

    // MARK: - Init

    init(manageSessionsUseCase: ManageSessionsUseCase) {
        self.manageSessionsUseCase = manageSessionsUseCase
    }

    // MARK: - Computed Properties

    var activeSessions: [Session] {
        sessions
            .filter { !$0.isArchived }
            .sorted { $0.lastInteractionAt > $1.lastInteractionAt }
    }

    var archivedSessions: [Session] {
        sessions
            .filter { $0.isArchived }
            .sorted { $0.lastInteractionAt > $1.lastInteractionAt }
    }

    // MARK: - Actions

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            sessions = try await manageSessionsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func archiveSession(_ session: Session) async {
        do {
            try await manageSessionsUseCase.archiveSession(id: session.id)
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index].isArchived = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreSession(_ session: Session) async {
        do {
            let restored = try await manageSessionsUseCase.restoreSession(id: session.id)
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = restored
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func observeSessionUpdates() async {
        for await updatedSessions in manageSessionsUseCase.sessionUpdates() {
            sessions = updatedSessions
        }
    }
}

// MARK: - Session History View

struct SessionHistoryView: View {
    @State var viewModel: SessionHistoryViewModel
    let onSelectSession: (Session) -> Void

    @State private var showArchived: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    loadingState
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await viewModel.loadSessions() }
        .task { await viewModel.observeSessionUpdates() }
    }

    // MARK: - Session List

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                // Active sessions
                if !viewModel.activeSessions.isEmpty {
                    sectionHeader("Active Sessions", count: viewModel.activeSessions.count)

                    ForEach(viewModel.activeSessions) { session in
                        sessionRow(session, isArchived: false)
                    }
                }

                // Archived sessions
                if !viewModel.archivedSessions.isEmpty {
                    archivedHeader

                    if showArchived {
                        ForEach(viewModel.archivedSessions) { session in
                            sessionRow(session, isArchived: true)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .refreshable {
            await viewModel.loadSessions()
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text(title.uppercased())
                .font(AppTypography.UI.badge)
                .foregroundStyle(OceanDepth.textTertiary)

            Text("\(count)")
                .font(AppTypography.UI.badge)
                .foregroundStyle(OceanDepth.textTertiary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, 2)
                .background(OceanDepth.subtleSurface)
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .padding(.top, DesignTokens.Spacing.sm)
    }

    // MARK: - Archived Header

    private var archivedHeader: some View {
        Button {
            withAnimation(.spring(
                response: DesignTokens.Animation.springResponse,
                dampingFraction: DesignTokens.Animation.springDamping
            )) {
                showArchived.toggle()
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("ARCHIVED")
                    .font(AppTypography.UI.badge)
                    .foregroundStyle(OceanDepth.textTertiary)

                Text("\(viewModel.archivedSessions.count)")
                    .font(AppTypography.UI.badge)
                    .foregroundStyle(OceanDepth.textTertiary)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(OceanDepth.subtleSurface)
                    .clipShape(Capsule())

                Spacer()

                Image(systemName: showArchived ? "chevron.up" : "chevron.down")
                    .font(.system(size: AppTypography.Size.xxs))
                    .foregroundStyle(OceanDepth.textTertiary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.top, DesignTokens.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: Session, isArchived: Bool) -> some View {
        Button {
            onSelectSession(session)
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(session.agentName)
                            .font(AppTypography.Chat.username)
                            .foregroundStyle(OceanDepth.textPrimary)

                        Spacer()

                        Text(formattedTimestamp(session.lastInteractionAt))
                            .font(AppTypography.Chat.timestamp)
                            .foregroundStyle(OceanDepth.textTertiary)
                    }

                    if let preview = session.lastMessagePreview {
                        Text(preview)
                            .font(AppTypography.UI.caption)
                            .foregroundStyle(OceanDepth.textSecondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: AppTypography.Size.xxxs))
                            .foregroundStyle(OceanDepth.textTertiary)

                        Text("\(session.messageCount) messages")
                            .font(AppTypography.UI.badge)
                            .foregroundStyle(OceanDepth.textTertiary)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(OceanDepth.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(OceanDepth.separator.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if isArchived {
                Button {
                    Task { await viewModel.restoreSession(session) }
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
                .tint(Color.accentColor)
            } else {
                Button {
                    Task { await viewModel.archiveSession(session) }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(OceanDepth.warning)
            }
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

            Text("Loading sessions...")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("No sessions yet")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Your conversation sessions will appear here.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textTertiary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(DesignTokens.Spacing.xl)
    }

    // MARK: - Helpers

    private func formattedTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}
