import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @Environment(ConnectionViewModel.self) private var connectionVM

    var body: some View {
        Group {
            if isConnected {
                MainTabView(router: router)
            } else {
                ConnectionView(viewModel: connectionVM)
            }
        }
        .animation(.easeInOut, value: isConnected)
    }

    private var isConnected: Bool {
        if case .connected = connectionVM.connectionStatus {
            return true
        }
        return false
    }
}
