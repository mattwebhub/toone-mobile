import SwiftUI

// MARK: - App Typography

enum AppTypography {

    // MARK: - Size Scale

    enum Size {
        static let xxxs: CGFloat = 10
        static let xxs: CGFloat = 11
        static let xs: CGFloat = 12
        static let sm: CGFloat = 13
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 18
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 24
        static let display: CGFloat = 32
        static let hero: CGFloat = 48
    }

    // MARK: - Chat Typography

    enum Chat {
        static let message = Font.system(size: Size.md)
        static let timestamp = Font.system(size: Size.xxs)
        static let username = Font.system(size: Size.sm, weight: .semibold)
    }

    // MARK: - Panel Typography

    enum Panel {
        static let title = Font.system(size: Size.lg, weight: .semibold)
        static let subtitle = Font.system(size: Size.sm)
    }

    // MARK: - UI Typography

    enum UI {
        static let button = Font.system(size: Size.sm, weight: .medium)
        static let badge = Font.system(size: Size.xxs, weight: .semibold)
        static let caption = Font.system(size: Size.xs)
        static let body = Font.system(size: Size.md)
        static let headline = Font.system(size: Size.lg, weight: .semibold)
    }
}
