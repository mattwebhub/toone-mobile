import SwiftUI

// MARK: - Connection View

struct ConnectionView: View {
    @State var viewModel: ConnectionViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignTokens.Spacing.xl) {
                        headerSection
                        connectionForm
                        statusSection
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .navigationTitle("Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await viewModel.observeStatus()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textSecondary)

            Text("Connect to Toone Desktop")
                .font(AppTypography.UI.headline)
                .foregroundStyle(OceanDepth.textPrimary)

            Text("Enter the host and port of your Toone Desktop instance, or scan a QR code from the desktop app.")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignTokens.Spacing.xl)
    }

    // MARK: - Connection Form

    private var connectionForm: some View {
        GlassCard {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Host field
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Host")
                        .typography(.uiCaption)

                    TextField("192.168.1.100 or hostname", text: $viewModel.host)
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .padding(DesignTokens.Spacing.sm + 2)
                        .background(OceanDepth.subtleSurface)
                        .clipShape(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        )
                }

                // Port field
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Port")
                        .typography(.uiCaption)

                    TextField("9877", text: $viewModel.port)
                        .font(AppTypography.UI.body)
                        .foregroundStyle(OceanDepth.textPrimary)
                        .keyboardType(.numberPad)
                        .padding(DesignTokens.Spacing.sm + 2)
                        .background(OceanDepth.subtleSurface)
                        .clipShape(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        )
                }

                // Connect button
                PrimaryButton(
                    "Connect",
                    icon: "link",
                    isLoading: viewModel.isConnecting
                ) {
                    Task { await viewModel.connect() }
                }
                .disabled(!viewModel.isFormValid)
                .padding(.top, DesignTokens.Spacing.sm)

                // QR code scan button
                SecondaryButton("Scan QR Code", icon: "qrcode.viewfinder") {
                    // QR code scanning will be implemented later
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.errorMessage != nil || !isDisconnected {
            GlassCard {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    StatusBadge(badgeStatus)

                    Text(viewModel.statusDescription)
                        .font(AppTypography.UI.caption)
                        .foregroundStyle(OceanDepth.textSecondary)
                        .multilineTextAlignment(.center)

                    if viewModel.errorMessage != nil {
                        SecondaryButton("Try Again", icon: "arrow.clockwise") {
                            Task { await viewModel.connect() }
                        }
                    }

                    if isConnected {
                        SecondaryButton("Disconnect", icon: "bolt.slash", isDestructive: true) {
                            Task { await viewModel.disconnect() }
                        }
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }

    // MARK: - Helpers

    private var isDisconnected: Bool {
        if case .disconnected = viewModel.connectionStatus { return true }
        return false
    }

    private var isConnected: Bool {
        if case .connected = viewModel.connectionStatus { return true }
        return false
    }

    private var badgeStatus: StatusBadge.Status {
        switch viewModel.connectionStatus {
        case .disconnected: return .disconnected
        case .discovering, .connecting, .authenticating, .syncing: return .connecting
        case .connected: return .connected
        case .reconnecting: return .connecting
        case .failed: return .error
        }
    }
}
