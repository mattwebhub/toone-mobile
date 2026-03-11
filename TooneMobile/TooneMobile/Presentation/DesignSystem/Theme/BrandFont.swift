import SwiftUI

// MARK: - Brand Font

enum BrandFont {
    static let pixelRegular = "10Pixel-Regular"
    static let pixelBold = "10Pixel-Bold"
    static let pixelThin = "10Pixel-Thin"

    static func pixel(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .semibold, .heavy, .black:
            return .custom(pixelBold, size: size)
        case .thin, .ultraLight, .light:
            return .custom(pixelThin, size: size)
        default:
            return .custom(pixelRegular, size: size)
        }
    }
}
