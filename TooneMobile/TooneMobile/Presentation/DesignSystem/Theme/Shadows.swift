import SwiftUI

// MARK: - Shadow Definitions

enum AppShadow {

    // MARK: - Shadow Levels

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    static let subtle = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )

    static let medium = ShadowStyle(
        color: Color.black.opacity(0.25),
        radius: 8,
        x: 0,
        y: 4
    )

    static let elevated = ShadowStyle(
        color: Color.black.opacity(0.35),
        radius: 16,
        x: 0,
        y: 8
    )

    static let floating = ShadowStyle(
        color: Color.black.opacity(0.45),
        radius: 24,
        x: 0,
        y: 12
    )
}

// MARK: - View Extension

extension View {
    func appShadow(_ style: AppShadow.ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}
