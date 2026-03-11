import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @State var viewModel: SettingsViewModel?

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if let viewModel {
                    settingsContent(viewModel: viewModel)
                } else {
                    disconnectedPlaceholder
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Settings Content

    private func settingsContent(viewModel: SettingsViewModel) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                connectionSection(viewModel: viewModel)
                desktopInfoSection(viewModel: viewModel)
                cacheSection(viewModel: viewModel)
                aboutSection(viewModel: viewModel)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .task { await viewModel.observeConnectionStatus() }
        .alert(
            "Disconnect",
            isPresented: Binding(
                get: { viewModel.showDisconnectConfirmation },
                set: { viewModel.showDisconnectConfirmation = $0 }
            )
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect", role: .destructive) {
                Task { await viewModel.disconnect() }
            }
        } message: {
            Text("Are you sure you want to disconnect from the desktop?")
        }
    }

    // MARK: - Connection Section

    private func connectionSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Connection", icon: "link")

                HStack {
                    Text("Status")
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textSecondary)

                    Spacer()

                    StatusBadge(viewModel.statusBadgeType)
                }

                HStack {
                    Text("Host")
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textSecondary)

                    Spacer()

                    Text(viewModel.host.isEmpty ? "Not set" : viewModel.host)
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textPrimary)
                }

                HStack {
                    Text("Port")
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textSecondary)

                    Spacer()

                    Text(viewModel.port)
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textPrimary)
                }

                if viewModel.isConnected {
                    SecondaryButton("Disconnect", icon: "bolt.slash", isDestructive: true) {
                        viewModel.showDisconnectConfirmation = true
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Desktop Info Section

    @ViewBuilder
    private func desktopInfoSection(viewModel: SettingsViewModel) -> some View {
        if let info = viewModel.desktopInfo {
            GlassCard {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    sectionHeader("Desktop", icon: "desktopcomputer")

                    infoRow("Hostname", value: info.hostname)
                    infoRow("Version", value: info.version)

                    if let workspace = info.workspaceName {
                        infoRow("Workspace", value: workspace)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Cache Section

    private func cacheSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Cache", icon: "internaldrive")

                Text("Clear cached messages and session data stored on this device.")
                    .font(AppTypography.UI.caption)
                    .foregroundStyle(OceanDepth.textSecondary)

                SecondaryButton(
                    viewModel.cacheCleared ? "Cache Cleared" : "Clear Cache",
                    icon: viewModel.cacheCleared ? "checkmark" : "trash"
                ) {
                    viewModel.clearCache()
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - About Section

    private func aboutSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("About", icon: "info.circle")

                infoRow("App Version", value: viewModel.appVersion)
                infoRow("Platform", value: "iOS")

                Text("Toone Mobile is a companion app for Toone Desktop. It connects to your desktop instance via a secure tunnel to provide mobile access to your AI agents.")
                    .font(AppTypography.UI.caption)
                    .foregroundStyle(OceanDepth.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Disconnected Placeholder

    private var disconnectedPlaceholder: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                GlassCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        sectionHeader("Connection", icon: "link")

                        HStack {
                            Text("Status")
                                .font(AppTypography.UI.body)
                                .foregroundStyle(OceanDepth.textSecondary)
                            Spacer()
                            StatusBadge(.disconnected)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        sectionHeader("About", icon: "info.circle")
                        infoRow("App Version", value: "1.0.0")
                        infoRow("Platform", value: "iOS")
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(AppTypography.Panel.title)
                .foregroundStyle(OceanDepth.textPrimary)
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)

            Spacer()

            Text(value)
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
