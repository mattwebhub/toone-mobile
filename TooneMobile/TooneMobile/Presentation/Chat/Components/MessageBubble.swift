import SwiftUI

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: Message

    @State private var showCopyConfirmation = false

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
            if isUserMessage {
                Spacer(minLength: bubbleInset)
            }

            VStack(alignment: alignment, spacing: DesignTokens.Spacing.xs) {
                // Message content
                bubbleContent
                    .padding(DesignTokens.Spacing.md)
                    .background(backgroundColor)
                    .clipShape(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                    )
                    .contextMenu {
                        copyButton
                    }

                // Timestamp and status
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(formattedTimestamp)
                        .font(AppTypography.Chat.timestamp)
                        .foregroundStyle(OceanDepth.textTertiary)

                    if message.status == .sending {
                        Image(systemName: "clock")
                            .font(.system(size: AppTypography.Size.xxxs))
                            .foregroundStyle(OceanDepth.textTertiary)
                    } else if message.status == .failed {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: AppTypography.Size.xxxs))
                            .foregroundStyle(OceanDepth.error)
                    }
                }
            }

            if !isUserMessage {
                Spacer(minLength: bubbleInset)
            }
        }
    }

    // MARK: - Bubble Content

    private var bubbleContent: some View {
        RichMessageView(contents: message.content)
    }

    // MARK: - Context Menu

    private var copyButton: some View {
        Button {
            let text = message.content.compactMap { content -> String? in
                switch content {
                case .text(let textContent):
                    return textContent.text
                case .codeBlock(let codeContent):
                    return codeContent.code
                default:
                    return nil
                }
            }.joined(separator: "\n")

            UIPasteboard.general.string = text
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
    }

    // MARK: - Computed Properties

    private var isUserMessage: Bool {
        message.role == .user
    }

    private var alignment: HorizontalAlignment {
        isUserMessage ? .trailing : .leading
    }

    private var backgroundColor: Color {
        isUserMessage ? OceanDepth.userBubble : OceanDepth.assistantBubble
    }

    private var bubbleInset: CGFloat {
        UIScreen.main.bounds.width * (1.0 - DesignTokens.Layout.messageBubbleMaxWidth)
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}
