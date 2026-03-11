import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.8)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: DesignTokens.IconSize.small))
                }

                Text(title)
                    .font(AppTypography.UI.button)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: DesignTokens.Spacing.md) {
            PrimaryButton("Connect", icon: "link") {}
            PrimaryButton("Loading...", isLoading: true) {}
        }
        .padding(DesignTokens.Spacing.md)
    }
}
