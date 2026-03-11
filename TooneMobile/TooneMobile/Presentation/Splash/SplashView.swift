import SwiftUI

// MARK: - Splash View

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var typographyOpacity: Double = 0
    @State private var typographyOffset: CGFloat = 20

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            OceanDepth.darkBase.ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                // App icon / logo
                Image("TooneTypography")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                    .opacity(typographyOpacity)
                    .offset(y: typographyOffset)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                typographyOpacity = 1
                typographyOffset = 0
            }

            // After animation completes, transition out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showContent = true
                }
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
