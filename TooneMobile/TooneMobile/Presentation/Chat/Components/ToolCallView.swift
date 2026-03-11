import SwiftUI

// MARK: - Tool Call View

struct ToolCallView: View {
    let content: ToolCallContent

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsible header
            header

            // Expandable input details
            if isExpanded, let input = content.input, !input.isEmpty {
                expandedContent(input: input)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .stroke(OceanDepth.separator.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Header

    private var header: some View {
        Button {
            withAnimation(.spring(
                response: DesignTokens.Animation.springResponse,
                dampingFraction: DesignTokens.Animation.springDamping
            )) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                statusIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(content.name)
                        .font(AppTypography.Chat.username)
                        .foregroundStyle(OceanDepth.textPrimary)

                    Text(statusLabel)
                        .font(AppTypography.UI.caption)
                        .foregroundStyle(statusColor)
                }

                Spacer()

                if content.input != nil {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: AppTypography.Size.xxs))
                        .foregroundStyle(OceanDepth.textTertiary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .frame(minHeight: DesignTokens.Layout.toolCallHeaderHeight)
        }
        .background(OceanDepth.subtleSurface.opacity(0.5))
    }

    // MARK: - Expanded Content

    private func expandedContent(input: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(input)
                .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                .foregroundStyle(OceanDepth.textSecondary)
                .textSelection(.enabled)
                .padding(DesignTokens.Spacing.sm)
        }
        .background(OceanDepth.codeBackground)
        .frame(maxHeight: 200)
    }

    // MARK: - Status Helpers

    @ViewBuilder
    private var statusIcon: some View {
        switch content.status {
        case .pending:
            Image(systemName: "clock")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(OceanDepth.textTertiary)

        case .executing:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .tint(Color.accentColor)

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(OceanDepth.success)

        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(OceanDepth.error)
        }
    }

    private var statusLabel: String {
        switch content.status {
        case .pending: return "Pending"
        case .executing: return "Executing..."
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    private var statusColor: Color {
        switch content.status {
        case .pending: return OceanDepth.textTertiary
        case .executing: return Color.accentColor
        case .completed: return OceanDepth.success
        case .failed: return OceanDepth.error
        }
    }
}
