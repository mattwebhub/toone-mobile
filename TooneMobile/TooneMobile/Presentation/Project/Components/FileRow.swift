import SwiftUI

// MARK: - File Row

struct FileRow: View {
    let file: ProjectFile
    let depth: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Indentation
                if depth > 0 {
                    Spacer()
                        .frame(width: CGFloat(depth) * DesignTokens.Spacing.lg)
                }

                // Expand chevron for directories
                if file.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: AppTypography.Size.xxxs, weight: .semibold))
                        .foregroundStyle(OceanDepth.textTertiary)
                        .frame(width: DesignTokens.IconSize.small)
                } else {
                    Spacer()
                        .frame(width: DesignTokens.IconSize.small)
                }

                // File/folder icon
                Image(systemName: iconName)
                    .font(.system(size: DesignTokens.IconSize.small))
                    .foregroundStyle(iconColor)

                // File name
                Text(file.name)
                    .font(AppTypography.UI.body)
                    .foregroundStyle(OceanDepth.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                // File size
                if !file.isDirectory, let size = file.size {
                    Text(formattedSize(size))
                        .font(AppTypography.UI.badge)
                        .foregroundStyle(OceanDepth.textTertiary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(height: DesignTokens.Layout.fileRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            isExpanded && file.isDirectory
                ? OceanDepth.hoverBackground
                : Color.clear
        )
    }

    // MARK: - Icon

    private var iconName: String {
        if file.isDirectory {
            return isExpanded ? "folder.fill" : "folder.fill"
        }

        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift", "kt", "java", "py", "js", "ts", "rb", "go", "rs", "c", "cpp", "h", "m":
            return "doc.text"
        case "json", "yaml", "yml", "xml", "plist", "toml":
            return "doc.badge.gearshape"
        case "md", "txt", "rtf":
            return "doc.plaintext"
        case "png", "jpg", "jpeg", "gif", "svg", "webp", "ico":
            return "photo"
        case "pdf":
            return "doc.richtext"
        case "zip", "tar", "gz", "rar":
            return "doc.zipper"
        case "mp3", "wav", "aac", "flac":
            return "music.note"
        case "mp4", "mov", "avi", "mkv":
            return "film"
        case "xcodeproj", "xcworkspace":
            return "hammer"
        case "gitignore", "dockerignore":
            return "eye.slash"
        default:
            return "doc"
        }
    }

    private var iconColor: Color {
        if file.isDirectory {
            return Color.accentColor
        }

        let ext = (file.name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift":
            return .orange
        case "js", "ts":
            return .yellow
        case "py":
            return .blue
        case "json", "yaml", "yml", "xml", "plist":
            return .purple
        case "md", "txt":
            return OceanDepth.textSecondary
        case "png", "jpg", "jpeg", "gif", "svg":
            return .green
        default:
            return OceanDepth.textTertiary
        }
    }

    // MARK: - Helpers

    private func formattedSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        VStack(spacing: 0) {
            FileRow(
                file: ProjectFile(
                    id: "1",
                    name: "Sources",
                    path: "/Sources",
                    isDirectory: true,
                    children: [],
                    size: nil,
                    modifiedAt: nil
                ),
                depth: 0,
                isExpanded: true,
                onTap: {}
            )

            FileRow(
                file: ProjectFile(
                    id: "2",
                    name: "ContentView.swift",
                    path: "/Sources/ContentView.swift",
                    isDirectory: false,
                    children: nil,
                    size: 2048,
                    modifiedAt: nil
                ),
                depth: 1,
                isExpanded: false,
                onTap: {}
            )

            FileRow(
                file: ProjectFile(
                    id: "3",
                    name: "package.json",
                    path: "/package.json",
                    isDirectory: false,
                    children: nil,
                    size: 512,
                    modifiedAt: nil
                ),
                depth: 0,
                isExpanded: false,
                onTap: {}
            )

            FileRow(
                file: ProjectFile(
                    id: "4",
                    name: "screenshot.png",
                    path: "/screenshot.png",
                    isDirectory: false,
                    children: nil,
                    size: 1048576,
                    modifiedAt: nil
                ),
                depth: 0,
                isExpanded: false,
                onTap: {}
            )
        }
    }
}
