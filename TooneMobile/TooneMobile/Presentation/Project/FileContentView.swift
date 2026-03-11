import SwiftUI

// MARK: - File Content View

struct FileContentView: View {
    let fileName: String
    let content: String
    let isLoading: Bool
    let onClose: () -> Void

    @State private var showLineNumbers: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                OceanDepth.darkBase.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else {
                    fileContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(OceanDepth.darkBase, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: fileIcon)
                            .font(.system(size: DesignTokens.IconSize.small))
                            .foregroundStyle(fileIconColor)

                        Text(fileName)
                            .font(AppTypography.Panel.title)
                            .foregroundStyle(OceanDepth.textPrimary)
                            .lineLimit(1)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: DesignTokens.IconSize.medium))
                            .foregroundStyle(OceanDepth.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showLineNumbers.toggle()
                        } label: {
                            Label(
                                showLineNumbers ? "Hide Line Numbers" : "Show Line Numbers",
                                systemImage: showLineNumbers ? "list.number" : "list.bullet"
                            )
                        }

                        Button {
                            UIPasteboard.general.string = content

                            // Auto-clear clipboard after 60 seconds for security
                            let copiedContent = content
                            Task { @MainActor in
                                try? await Task.sleep(for: .seconds(60))
                                if UIPasteboard.general.string == copiedContent {
                                    UIPasteboard.general.string = ""
                                }
                            }
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: DesignTokens.IconSize.medium))
                            .foregroundStyle(OceanDepth.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - File Content

    private var fileContent: some View {
        ScrollView([.horizontal, .vertical]) {
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                if showLineNumbers {
                    lineNumbersColumn
                }

                // Code content
                Text(content)
                    .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                    .foregroundStyle(OceanDepth.textPrimary)
                    .textSelection(.enabled)
                    .padding(DesignTokens.Spacing.sm)
            }
        }
        .background(OceanDepth.codeBackground)
    }

    // MARK: - Line Numbers

    private var lineNumbersColumn: some View {
        let lines = content.components(separatedBy: "\n")

        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                Text("\(index + 1)")
                    .font(.system(size: AppTypography.Size.xs, design: .monospaced))
                    .foregroundStyle(OceanDepth.textTertiary)
                    .frame(height: lineHeight)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(OceanDepth.subtleSurface.opacity(0.5))
        .overlay(
            Rectangle()
                .fill(OceanDepth.separator.opacity(0.3))
                .frame(width: 0.5),
            alignment: .trailing
        )
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(OceanDepth.textSecondary)
                .scaleEffect(1.2)

            Text("Loading file...")
                .font(AppTypography.UI.body)
                .foregroundStyle(OceanDepth.textSecondary)
        }
    }

    // MARK: - Helpers

    private var lineHeight: CGFloat {
        AppTypography.Size.xs * 1.5
    }

    private var fileIcon: String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "swift", "kt", "java", "py", "js", "ts", "rb", "go", "rs":
            return "doc.text"
        case "json", "yaml", "yml", "xml", "plist":
            return "doc.badge.gearshape"
        case "md", "txt":
            return "doc.plaintext"
        default:
            return "doc"
        }
    }

    private var fileIconColor: Color {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":
            return .orange
        case "js", "ts":
            return .yellow
        case "py":
            return .blue
        case "json", "yaml", "yml":
            return .purple
        default:
            return OceanDepth.textSecondary
        }
    }
}

// MARK: - Preview

#Preview {
    FileContentView(
        fileName: "ContentView.swift",
        content: """
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Hello, world!")
                }
                .padding()
            }
        }
        """,
        isLoading: false,
        onClose: {}
    )
}
