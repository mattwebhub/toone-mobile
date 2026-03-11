import SwiftUI

// MARK: - Typography Style

enum TypographyStyle {
    case chatMessage
    case chatTimestamp
    case chatUsername
    case panelTitle
    case panelSubtitle
    case uiButton
    case uiBadge
    case uiCaption
    case uiBody
    case uiHeadline

    var font: Font {
        switch self {
        case .chatMessage: return AppTypography.Chat.message
        case .chatTimestamp: return AppTypography.Chat.timestamp
        case .chatUsername: return AppTypography.Chat.username
        case .panelTitle: return AppTypography.Panel.title
        case .panelSubtitle: return AppTypography.Panel.subtitle
        case .uiButton: return AppTypography.UI.button
        case .uiBadge: return AppTypography.UI.badge
        case .uiCaption: return AppTypography.UI.caption
        case .uiBody: return AppTypography.UI.body
        case .uiHeadline: return AppTypography.UI.headline
        }
    }

    var color: Color {
        switch self {
        case .chatMessage: return OceanDepth.textPrimary
        case .chatTimestamp: return OceanDepth.textTertiary
        case .chatUsername: return OceanDepth.textPrimary
        case .panelTitle: return OceanDepth.textPrimary
        case .panelSubtitle: return OceanDepth.textSecondary
        case .uiButton: return OceanDepth.textPrimary
        case .uiBadge: return OceanDepth.textSecondary
        case .uiCaption: return OceanDepth.textTertiary
        case .uiBody: return OceanDepth.textPrimary
        case .uiHeadline: return OceanDepth.textPrimary
        }
    }
}

// MARK: - Typography Modifier

struct TypographyModifier: ViewModifier {
    let style: TypographyStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundStyle(style.color)
    }
}

// MARK: - View Extension

extension View {
    func typography(_ style: TypographyStyle) -> some View {
        modifier(TypographyModifier(style: style))
    }
}
