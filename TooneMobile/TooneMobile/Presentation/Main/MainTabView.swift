import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            chatTab
            agentsTab
            projectTab
            settingsTab
        }
        .tint(Color.accentColor)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    // MARK: - Tabs

    private var chatTab: some View {
        ChatView()
            .tabItem {
                Label(AppTab.chat.title, systemImage: AppTab.chat.icon)
            }
            .tag(AppTab.chat)
    }

    private var agentsTab: some View {
        AgentListView()
            .tabItem {
                Label(AppTab.agents.title, systemImage: AppTab.agents.icon)
            }
            .tag(AppTab.agents)
    }

    private var projectTab: some View {
        ProjectExplorerView()
            .tabItem {
                Label(AppTab.project.title, systemImage: AppTab.project.icon)
            }
            .tag(AppTab.project)
    }

    private var settingsTab: some View {
        SettingsView()
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
            }
            .tag(AppTab.settings)
    }

    // MARK: - Tab Bar Appearance

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = UIColor(OceanDepth.darkBase)
        appearance.shadowColor = UIColor(OceanDepth.separator)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(OceanDepth.textTertiary)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.tintColor
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(OceanDepth.textTertiary)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Preview

#Preview {
    MainTabView(router: AppRouter())
}
