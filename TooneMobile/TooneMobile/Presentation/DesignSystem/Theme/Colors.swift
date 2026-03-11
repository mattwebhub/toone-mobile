import SwiftUI

// MARK: - Ocean Depth Color Palette

enum OceanDepth {

    // MARK: - Backgrounds

    static let darkBase = Color(red: 0.078, green: 0.086, blue: 0.118)
    static let elevatedSurface = Color(red: 0.118, green: 0.133, blue: 0.188)
    static let subtleSurface = Color(red: 0.145, green: 0.165, blue: 0.220)
    static let separator = Color(red: 0.196, green: 0.220, blue: 0.282)

    // MARK: - Text

    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.70)
    static let textTertiary = Color.white.opacity(0.45)

    // MARK: - Chat Bubbles

    static let userBubble = Color.accentColor.opacity(0.15)
    static let assistantBubble = elevatedSurface

    // MARK: - Interactive

    static let hoverBackground = Color.white.opacity(0.10)
    static let selectedBackground = Color.white.opacity(0.15)

    // MARK: - Code

    static let codeBackground = subtleSurface
    static let codeBorder = separator.opacity(0.5)

    // MARK: - Status

    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
}
