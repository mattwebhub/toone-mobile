import SwiftUI

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let isDestructive: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isDestructive = isDestructive
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.IconSize.small))
                }

                Text(title)
                    .font(AppTypography.UI.button)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(OceanDepth.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
    }

    // MARK: - Computed Properties

    private var foregroundColor: Color {
        isDestructive ? OceanDepth.error : OceanDepth.textSecondary
    }

    private var borderColor: Color {
        isDestructive ? OceanDepth.error.opacity(0.3) : OceanDepth.separator
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: DesignTokens.Spacing.md) {
            SecondaryButton("Cancel", icon: "xmark") {}
            SecondaryButton("Disconnect", icon: "bolt.slash", isDestructive: true) {}
        }
        .padding(DesignTokens.Spacing.md)
    }
}
