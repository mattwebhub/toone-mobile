import SwiftUI

// MARK: - File Content View

struct FileContentView: View {
    let file: ProjectFile
    let content: String?
    let isLoading: Bool

    @State private var isCopied = false

    var body: some View {
        ZStack {
            OceanDepth.darkBase.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(OceanDepth.textSecondary)
            } else if let content {
                codeViewer(content: content)
            } else {
                emptyContent
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                copyButton
            }
        }
    }

    // MARK: - Code Viewer

    private func codeViewer(content: String) -> some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                let lines = content.components(separatedBy: "\n")
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .top, spacing: 0) {
                        // Line number
                        Text("\(index + 1)")
                            .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                            .foregroundStyle(OceanDepth.textTertiary)
                            .frame(width: lineNumberWidth(totalLines: lines.count), alignment: .trailing)
                            .padding(.trailing, DesignTokens.Spacing.sm)

                        // Separator
                        Rectangle()
                            .fill(OceanDepth.separator.opacity(0.3))
                            .frame(width: 0.5)
                            .padding(.trailing, DesignTokens.Spacing.sm)

                        // Line content
                        Text(line)
                            .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                            .foregroundStyle(OceanDepth.textPrimary)
                            .textSelection(.enabled)
                    }
                    .frame(height: 18)
                }
            }
            .padding(DesignTokens.Spacing.sm)
        }
        .background(OceanDepth.codeBackground)
    }

    // MARK: - Copy Button

    private var copyButton: some View {
        Button {
            if let content {
                UIPasteboard.general.string = content
                isCopied = true

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    isCopied = false
                }
            }
        } label: {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                .foregroundStyle(isCopied ? OceanDepth.success : OceanDepth.textSecondary)
        }
    }

    // MARK: - Empty Content

    private var emptyContent: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "doc")
                .font(.system(size: DesignTokens.IconSize.hero))
                .foregroundStyle(OceanDepth.textTertiary)

            Text("No content to display")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)
        }
    }

    // MARK: - Helpers

    private func lineNumberWidth(totalLines: Int) -> CGFloat {
        let digits = max(String(totalLines).count, 2)
        return CGFloat(digits) * 8 + 4
    }
}
