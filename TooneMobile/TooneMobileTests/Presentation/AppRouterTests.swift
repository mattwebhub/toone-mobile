import XCTest
@testable import TooneMobile

@MainActor
final class AppRouterTests: XCTestCase {

    private var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Default Tab Is Chat

    func test_init_defaultTab_isChat() {
        XCTAssertEqual(sut.selectedTab, .chat)
    }

    func test_init_isConnected_isFalse() {
        XCTAssertFalse(sut.isConnected)
    }

    func test_init_showConnectionSheet_isFalse() {
        XCTAssertFalse(sut.showConnectionSheet)
    }

    // MARK: - Tab Switching

    func test_selectedTab_switchToAgents_updatesTab() {
        // Act
        sut.selectedTab = .agents

        // Assert
        XCTAssertEqual(sut.selectedTab, .agents)
    }

    func test_selectedTab_switchToProject_updatesTab() {
        // Act
        sut.selectedTab = .project

        // Assert
        XCTAssertEqual(sut.selectedTab, .project)
    }

    func test_selectedTab_switchToSettings_updatesTab() {
        // Act
        sut.selectedTab = .settings

        // Assert
        XCTAssertEqual(sut.selectedTab, .settings)
    }

    func test_switchToChat_setsTabToChat() {
        // Arrange
        sut.selectedTab = .settings

        // Act
        sut.switchToChat()

        // Assert
        XCTAssertEqual(sut.selectedTab, .chat)
    }

    func test_switchToAgent_setsTabToChat() {
        // Arrange
        sut.selectedTab = .agents

        // Act
        sut.switchToAgent("agent-1")

        // Assert
        XCTAssertEqual(sut.selectedTab, .chat)
    }

    // MARK: - Connection State Tracking

    func test_isConnected_canBeSetToTrue() {
        // Act
        sut.isConnected = true

        // Assert
        XCTAssertTrue(sut.isConnected)
    }

    func test_isConnected_canBeToggledBackToFalse() {
        // Arrange
        sut.isConnected = true

        // Act
        sut.isConnected = false

        // Assert
        XCTAssertFalse(sut.isConnected)
    }

    func test_presentConnectionSheet_setsShowConnectionSheetToTrue() {
        // Act
        sut.presentConnectionSheet()

        // Assert
        XCTAssertTrue(sut.showConnectionSheet)
    }

    func test_dismissConnectionSheet_setsShowConnectionSheetToFalse() {
        // Arrange
        sut.showConnectionSheet = true

        // Act
        sut.dismissConnectionSheet()

        // Assert
        XCTAssertFalse(sut.showConnectionSheet)
    }

    func test_presentAndDismissConnectionSheet_roundTrip() {
        // Arrange & Act
        sut.presentConnectionSheet()
        XCTAssertTrue(sut.showConnectionSheet)

        sut.dismissConnectionSheet()

        // Assert
        XCTAssertFalse(sut.showConnectionSheet)
    }

    // MARK: - AppTab Properties

    func test_appTab_chatTitle_isChat() {
        XCTAssertEqual(AppTab.chat.title, "Chat")
    }

    func test_appTab_agentsTitle_isAgents() {
        XCTAssertEqual(AppTab.agents.title, "Agents")
    }

    func test_appTab_projectTitle_isProject() {
        XCTAssertEqual(AppTab.project.title, "Project")
    }

    func test_appTab_settingsTitle_isSettings() {
        XCTAssertEqual(AppTab.settings.title, "Settings")
    }

    func test_appTab_allCases_containsFourTabs() {
        XCTAssertEqual(AppTab.allCases.count, 4)
    }

    func test_appTab_id_equalsRawValue() {
        for tab in AppTab.allCases {
            XCTAssertEqual(tab.id, tab.rawValue)
        }
    }

    func test_appTab_icon_isNotEmpty() {
        for tab in AppTab.allCases {
            XCTAssertFalse(tab.icon.isEmpty, "Icon for \(tab) should not be empty")
        }
    }
}
