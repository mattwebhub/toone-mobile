import SwiftUI

// MARK: - Search Field

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    init(_ placeholder: String = "Search...", text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignTokens.IconSize.small))
                .foregroundStyle(OceanDepth.textTertiary)

            TextField(placeholder, text: $text)
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundStyle(OceanDepth.textTertiary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm + 2)
        .background(OceanDepth.subtleSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .stroke(OceanDepth.separator.opacity(0.5), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: DesignTokens.Spacing.md) {
            SearchField(text: .constant(""))
            SearchField("Find agents...", text: .constant("marketing"))
        }
        .padding(DesignTokens.Spacing.md)
    }
}
