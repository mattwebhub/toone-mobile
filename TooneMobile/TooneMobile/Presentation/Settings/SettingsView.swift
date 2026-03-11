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
                    placeholderContent
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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

                if viewModel.isConnected {
                    desktopInfoSection(viewModel: viewModel)
                }

                cacheSection(viewModel: viewModel)
                aboutSection(viewModel: viewModel)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .task { await viewModel.observeConnectionStatus() }
    }

    // MARK: - Connection Section

    private func connectionSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Connection", icon: "link")

                // Host field
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Host")
                        .typography(.uiCaption)

                    TextField("192.168.1.100 or hostname", text: Binding(
                        get: { viewModel.host },
                        set: { viewModel.host = $0 }
                    ))
                    .font(AppTypography.UI.body)
                    .foregroundStyle(OceanDepth.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .disabled(viewModel.isConnected)
                    .padding(DesignTokens.Spacing.sm + 2)
                    .background(OceanDepth.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }

                // Port field
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Port")
                        .typography(.uiCaption)

                    TextField("9877", text: Binding(
                        get: { viewModel.port },
                        set: { viewModel.port = $0 }
                    ))
                    .font(AppTypography.UI.body)
                    .foregroundStyle(OceanDepth.textPrimary)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.isConnected)
                    .padding(DesignTokens.Spacing.sm + 2)
                    .background(OceanDepth.subtleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }

                // Status
                HStack {
                    StatusBadge(viewModel.statusBadgeType)
                    Spacer()
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.UI.caption)
                        .foregroundStyle(OceanDepth.error)
                }

                // Connect / Disconnect button
                if viewModel.isConnected {
                    SecondaryButton("Disconnect", icon: "bolt.slash", isDestructive: true) {
                        Task { await viewModel.disconnect() }
                    }
                } else {
                    PrimaryButton(
                        "Connect",
                        icon: "link",
                        isLoading: viewModel.isConnecting
                    ) {
                        Task { await viewModel.connect() }
                    }
                    .disabled(!viewModel.canConnect)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Desktop Info Section

    private func desktopInfoSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Desktop Info", icon: "desktopcomputer")

                if let info = viewModel.desktopInfo {
                    infoRow(label: "Hostname", value: info.hostname)
                    infoRow(label: "Version", value: info.version)

                    if let workspace = info.workspaceName {
                        infoRow(label: "Workspace", value: workspace)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Cache Section

    private func cacheSection(viewModel: SettingsViewModel) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                sectionHeader("Cache", icon: "internaldrive")

                infoRow(
                    label: "Cached Messages",
                    value: "\(viewModel.cachedMessageCount)"
                )

                SecondaryButton("Clear Cache", icon: "trash") {
                    Task { await viewModel.clearCache() }
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

                infoRow(label: "App Version", value: viewModel.appVersion)
                infoRow(label: "Build", value: viewModel.buildNumber)

                Divider()
                    .background(OceanDepth.separator)

                linkRow(label: "Privacy Policy", icon: "hand.raised") {
                    // Open privacy policy URL
                }

                linkRow(label: "Terms of Service", icon: "doc.text") {
                    // Open terms URL
                }

                linkRow(label: "Support", icon: "questionmark.circle") {
                    // Open support URL
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Reusable Components

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(Color.accentColor)

            Text(title)
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textPrimary)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
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

    private func linkRow(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.IconSize.small))
                    .foregroundStyle(OceanDepth.textSecondary)

                Text(label)
                    .font(AppTypography.UI.body)
                    .foregroundStyle(OceanDepth.textPrimary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: AppTypography.Size.xxs))
                    .foregroundStyle(OceanDepth.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Placeholder

    private var placeholderContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Minimal about section when no viewModel
                GlassCard {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        sectionHeader("About", icon: "info.circle")

                        infoRow(
                            label: "App Version",
                            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                        )
                        infoRow(
                            label: "Build",
                            value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                        )
                    }
                    .padding(DesignTokens.Spacing.md)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
