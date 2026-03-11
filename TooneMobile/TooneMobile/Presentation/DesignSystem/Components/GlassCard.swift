import SwiftUI

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat

    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial)
            .background(OceanDepth.elevatedSurface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(OceanDepth.separator.opacity(0.3), lineWidth: 0.5)
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Glass Card")
                    .font(AppTypography.UI.headline)
                    .foregroundStyle(OceanDepth.textPrimary)

                Text("A glassmorphism card component")
                    .font(AppTypography.UI.body)
                    .foregroundStyle(OceanDepth.textSecondary)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .padding(DesignTokens.Spacing.md)
    }
}
