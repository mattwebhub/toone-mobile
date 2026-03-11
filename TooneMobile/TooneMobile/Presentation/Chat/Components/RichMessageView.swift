import SwiftUI

// MARK: - Rich Message View

struct RichMessageView: View {
    let contents: [MessageContent]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            ForEach(contents) { content in
                contentView(for: content)
            }
        }
    }

    // MARK: - Content Rendering

    @ViewBuilder
    private func contentView(for content: MessageContent) -> some View {
        switch content {
        case .text(let textContent):
            textView(textContent)

        case .codeBlock(let codeContent):
            CodeBlockView(content: codeContent)

        case .toolCall(let toolCallContent):
            ToolCallView(content: toolCallContent)

        case .toolResult(let resultContent):
            toolResultView(resultContent)

        case .image(let imageContent):
            imageView(imageContent)
        }
    }

    // MARK: - Text Content

    private func textView(_ content: TextContent) -> some View {
        Text(LocalizedStringKey(content.text))
            .font(AppTypography.Chat.message)
            .foregroundStyle(OceanDepth.textPrimary)
            .textSelection(.enabled)
    }

    // MARK: - Tool Result

    private func toolResultView(_ content: ToolResultContent) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(
                    systemName: content.isError
                        ? "xmark.circle.fill" : "checkmark.circle.fill"
                )
                .foregroundStyle(content.isError ? OceanDepth.error : OceanDepth.success)
                .font(.system(size: DesignTokens.IconSize.small))

                Text("Result")
                    .font(AppTypography.Chat.username)
                    .foregroundStyle(OceanDepth.textSecondary)
            }

            if !content.content.isEmpty {
                Text(content.content)
                    .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                    .foregroundStyle(
                        content.isError ? OceanDepth.error : OceanDepth.textSecondary
                    )
                    .lineLimit(5)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OceanDepth.subtleSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
    }

    // MARK: - Image Content

    private func imageView(_ content: ImageContent) -> some View {
        AsyncImage(url: URL(string: content.url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(height: 150)

            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                    )

            case .failure:
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .foregroundStyle(OceanDepth.textTertiary)
                    Text(content.altText ?? "Image failed to load")
                        .font(AppTypography.UI.caption)
                        .foregroundStyle(OceanDepth.textTertiary)
                }

            @unknown default:
                EmptyView()
            }
        }
    }
}
