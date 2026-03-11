import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ConnectionViewModel.self) private var connectionVM

    var body: some View {
        Group {
            if connectionVM.isConnected {
                MainTabView()
            } else {
                ConnectionView()
            }
        }
        .animation(.easeInOut, value: connectionVM.isConnected)
    }
}
