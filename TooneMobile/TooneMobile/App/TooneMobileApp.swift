import SwiftUI
import SwiftData

@main
struct TooneMobileApp: App {
    private let container: AppContainer

    init() {
        self.container = AppContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container.appRouter)
                .environment(container.connectionViewModel)
                .modelContainer(container.modelContainer)
                .preferredColorScheme(.dark)
        }
    }
}
