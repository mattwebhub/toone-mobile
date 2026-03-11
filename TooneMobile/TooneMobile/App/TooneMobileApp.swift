import SwiftUI
import SwiftData

@main
struct TooneMobileApp: App {
    private let container: AppContainer
    @State private var showSplash = true

    init() {
        self.container = AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    RootView()
                        .environment(container.appRouter)
                        .environment(container.connectionViewModel)
                        .transition(.opacity)
                }
            }
            .modelContainer(container.modelContainer)
            .preferredColorScheme(.dark)
        }
    }
}
