import SwiftUI

// MARK: - File Row

struct FileRow: View {
    let file: ProjectFile
    let isExpanded: Bool
    let indentLevel: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Indent
                if indentLevel > 0 {
                    Spacer()
                        .frame(width: CGFloat(indentLevel) * DesignTokens.Spacing.md)
                }

                // Folder chevron or spacer
                if file.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: AppTypography.Size.xxs, weight: .medium))
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

                Spacer()

                // File size (for files only)
                if !file.isDirectory, let size = file.size {
                    Text(formattedSize(size))
                        .font(AppTypography.Chat.timestamp)
                        .foregroundStyle(OceanDepth.textTertiary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .frame(height: DesignTokens.Layout.fileRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon

    private var iconName: String {
        if file.isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        }
        return fileIcon(for: file.name)
    }

    private var iconColor: Color {
        if file.isDirectory {
            return Color.accentColor
        }
        return fileIconColor(for: file.name)
    }

    // MARK: - File Type Helpers

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "ts", "jsx", "tsx": return "doc.text"
        case "json": return "curlybraces"
        case "md", "txt": return "doc.plaintext"
        case "html", "css": return "globe"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "py": return "doc.text"
        case "yml", "yaml", "toml": return "gearshape"
        case "sh", "zsh", "bash": return "terminal"
        default: return "doc"
        }
    }

    private func fileIconColor(for name: String) -> Color {
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "js", "jsx": return .yellow
        case "ts", "tsx": return .blue
        case "json": return .green
        case "md", "txt": return OceanDepth.textSecondary
        case "html": return .orange
        case "css": return .blue
        case "py": return .green
        case "png", "jpg", "jpeg", "gif", "svg": return .purple
        default: return OceanDepth.textTertiary
        }
    }

    // MARK: - Size Formatting

    private func formattedSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}
