import SwiftUI

// MARK: - Agent Card

struct AgentCard: View {
    let agent: Agent
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Agent info
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(agent.name)
                            .font(AppTypography.Chat.username)
                            .foregroundStyle(OceanDepth.textPrimary)

                        if isSelected {
                            activeIndicator
                        }
                    }

                    Text(agent.description)
                        .font(AppTypography.UI.caption)
                        .foregroundStyle(OceanDepth.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Capabilities
                    if !agent.capabilities.isEmpty {
                        capabilitiesBadges
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: AppTypography.Size.xs))
                    .foregroundStyle(OceanDepth.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.Layout.agentCardHeight)
            .background(
                isSelected
                    ? OceanDepth.selectedBackground
                    : OceanDepth.elevatedSurface
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.5)
                            : OceanDepth.separator.opacity(0.3),
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Indicator

    private var activeIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Circle()
                .fill(OceanDepth.success)
                .frame(
                    width: DesignTokens.Layout.statusIndicatorSize,
                    height: DesignTokens.Layout.statusIndicatorSize
                )

            Text("Active")
                .font(AppTypography.UI.badge)
                .foregroundStyle(OceanDepth.success)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background(OceanDepth.success.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Capabilities Badges

    private var capabilitiesBadges: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(agent.capabilities.prefix(4), id: \.self) { capability in
                    Text(capability)
                        .font(AppTypography.UI.badge)
                        .foregroundStyle(OceanDepth.textTertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(OceanDepth.subtleSurface)
                        .clipShape(Capsule())
                }

                if agent.capabilities.count > 4 {
                    Text("+\(agent.capabilities.count - 4)")
                        .font(AppTypography.UI.badge)
                        .foregroundStyle(OceanDepth.textTertiary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(OceanDepth.subtleSurface)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: DesignTokens.Spacing.md) {
            AgentCard(
                agent: Agent(
                    id: "1",
                    name: "Code Assistant",
                    description: "Helps with coding tasks, reviews, and debugging.",
                    departmentId: "eng",
                    capabilities: ["Swift", "Python", "Code Review", "Debugging", "Testing"],
                    routineNames: [],
                    greeting: nil,
                    isSystem: false
                ),
                isSelected: true
            ) {}

            AgentCard(
                agent: Agent(
                    id: "2",
                    name: "Content Writer",
                    description: "Creates marketing copy and documentation.",
                    departmentId: "mkt",
                    capabilities: ["Copywriting", "Docs"],
                    routineNames: [],
                    greeting: nil,
                    isSystem: false
                ),
                isSelected: false
            ) {}
        }
        .padding(DesignTokens.Spacing.md)
    }
}
