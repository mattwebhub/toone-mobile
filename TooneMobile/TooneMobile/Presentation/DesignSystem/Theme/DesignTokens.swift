import SwiftUI

// MARK: - Design Tokens

enum DesignTokens {

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Icon Sizes

    enum IconSize {
        static let small: CGFloat = 16
        static let medium: CGFloat = 20
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
        static let hero: CGFloat = 48
    }

    // MARK: - Layout

    enum Layout {
        static let tabBarHeight: CGFloat = 49
        static let chatInputMinHeight: CGFloat = 44
        static let chatInputMaxHeight: CGFloat = 120
        static let messageBubbleMaxWidth: CGFloat = 0.80 // fraction of screen width
        static let avatarSize: CGFloat = 32
        static let statusIndicatorSize: CGFloat = 8
        static let toolCallHeaderHeight: CGFloat = 44
        static let fileRowHeight: CGFloat = 40
        static let agentCardHeight: CGFloat = 80
    }

    // MARK: - Animation

    enum Animation {
        static let defaultDuration: Double = 0.25
        static let springResponse: Double = 0.35
        static let springDamping: Double = 0.8
    }
}
