import SwiftUI

// MARK: - Glass Effect Modifier

struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var borderOpacity: Double

    init(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        opacity: Double = 0.8,
        borderOpacity: Double = 0.3
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
        self.borderOpacity = borderOpacity
    }

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(OceanDepth.elevatedSurface.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(OceanDepth.separator.opacity(borderOpacity), lineWidth: 0.5)
            )
    }
}

// MARK: - View Extension

extension View {
    func glassEffect(
        cornerRadius: CGFloat = DesignTokens.CornerRadius.medium,
        opacity: Double = 0.8,
        borderOpacity: Double = 0.3
    ) -> some View {
        modifier(
            GlassEffect(
                cornerRadius: cornerRadius,
                opacity: opacity,
                borderOpacity: borderOpacity
            )
        )
    }
}
