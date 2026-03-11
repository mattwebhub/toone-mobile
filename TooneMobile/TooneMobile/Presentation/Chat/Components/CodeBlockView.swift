import SwiftUI

// MARK: - Code Block View

struct CodeBlockView: View {
    let content: CodeBlockContent

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with language label and copy button
            header

            // Code content
            codeContent
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                .stroke(OceanDepth.codeBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if let language = content.language, !language.isEmpty {
                Text(language.lowercased())
                    .font(.system(size: AppTypography.Size.xxs, weight: .medium, design: .monospaced))
                    .foregroundStyle(OceanDepth.textTertiary)
            }

            Spacer()

            Button {
                copyCode()
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: AppTypography.Size.xxs))

                    Text(isCopied ? "Copied" : "Copy")
                        .font(.system(size: AppTypography.Size.xxs))
                }
                .foregroundStyle(isCopied ? OceanDepth.success : OceanDepth.textTertiary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs + 2)
        .background(OceanDepth.separator.opacity(0.3))
    }

    // MARK: - Code Content

    private var codeContent: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(content.code)
                .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                .foregroundStyle(OceanDepth.textPrimary)
                .textSelection(.enabled)
                .padding(DesignTokens.Spacing.sm)
        }
        .background(OceanDepth.codeBackground)
    }

    // MARK: - Actions

    private func copyCode() {
        UIPasteboard.general.string = content.code
        isCopied = true

        // Auto-clear clipboard after 60 seconds for security
        let copiedCode = content.code
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(60))
            if UIPasteboard.general.string == copiedCode {
                UIPasteboard.general.string = ""
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}
