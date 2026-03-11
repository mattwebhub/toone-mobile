import SwiftUI

// MARK: - Chat Input View

struct ChatInputView: View {
    @Binding var text: String
    let isEnabled: Bool
    let isProcessing: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(OceanDepth.separator)

            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
                // Text input
                textField

                // Send button
                sendButton
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(OceanDepth.darkBase)
        }
    }

    // MARK: - Text Field

    private var textField: some View {
        TextField("Message...", text: $text, axis: .vertical)
            .font(AppTypography.UI.body)
            .foregroundStyle(OceanDepth.textPrimary)
            .lineLimit(1...6)
            .focused($isFocused)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(OceanDepth.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.extraLarge)
                    .stroke(
                        isFocused ? Color.accentColor.opacity(0.5) : OceanDepth.separator.opacity(0.5),
                        lineWidth: 0.5
                    )
            )
            .disabled(!isEnabled && !isProcessing)
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            onSend()
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(canSend ? Color.accentColor : OceanDepth.textTertiary)
        }
        .disabled(!canSend)
        .animation(.easeInOut(duration: 0.15), value: canSend)
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack {
            Spacer()
            ChatInputView(
                text: .constant("Hello, how are you?"),
                isEnabled: true,
                isProcessing: false
            ) {}
        }
    }
}
