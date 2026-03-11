import SwiftUI

// MARK: - Status Badge

struct StatusBadge: View {
    let status: StatusBadge.Status
    let label: String?

    init(_ status: Status, label: String? = nil) {
        self.status = status
        self.label = label
    }

    // MARK: - Status Type

    enum Status {
        case connected
        case connecting
        case disconnected
        case processing
        case error

        var color: Color {
            switch self {
            case .connected: return OceanDepth.success
            case .connecting: return OceanDepth.warning
            case .disconnected: return OceanDepth.textTertiary
            case .processing: return Color.accentColor
            case .error: return OceanDepth.error
            }
        }

        var icon: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .connecting: return "arrow.triangle.2.circlepath"
            case .disconnected: return "circle.slash"
            case .processing: return "gearshape.2.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }

        var defaultLabel: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting"
            case .disconnected: return "Disconnected"
            case .processing: return "Processing"
            case .error: return "Error"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if status == .connecting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .tint(status.color)
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: AppTypography.Size.xxs))
                    .foregroundStyle(status.color)
            }

            Text(label ?? status.defaultLabel)
                .font(AppTypography.UI.badge)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: DesignTokens.Spacing.md) {
            StatusBadge(.connected)
            StatusBadge(.connecting)
            StatusBadge(.disconnected)
            StatusBadge(.processing, label: "Thinking...")
            StatusBadge(.error, label: "Connection lost")
        }
    }
}
