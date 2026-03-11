import SwiftUI

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable {
    case chat
    case agents
    case project
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chat: return "Chat"
        case .agents: return "Agents"
        case .project: return "Project"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .agents: return "person.3.fill"
        case .project: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - App Router

@Observable @MainActor
final class AppRouter {
    var selectedTab: AppTab = .chat
    var isConnected: Bool = false
    var showConnectionSheet: Bool = false

    // MARK: - Navigation Actions

    func switchToChat() {
        selectedTab = .chat
    }

    func switchToAgent(_ agentId: String) {
        selectedTab = .chat
    }

    func presentConnectionSheet() {
        showConnectionSheet = true
    }

    func dismissConnectionSheet() {
        showConnectionSheet = false
    }
}
