import SwiftUI

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationPhase: Int = 0

    private let dotCount = 3
    private let dotSize: CGFloat = 6
    private let animationInterval: TimeInterval = 0.4

    var body: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
            dotsView
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(OceanDepth.assistantBubble)
                .clipShape(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                )

            Spacer()
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Dots

    private var dotsView: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(OceanDepth.textTertiary)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: animationPhase == index ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.3)
                            .delay(Double(index) * 0.15),
                        value: animationPhase
                    )
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationInterval, repeats: true) { _ in
            Task { @MainActor in
                animationPhase = (animationPhase + 1) % (dotCount + 1)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        OceanDepth.darkBase.ignoresSafeArea()

        TypingIndicator()
            .padding(DesignTokens.Spacing.md)
    }
}
