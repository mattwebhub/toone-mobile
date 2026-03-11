import SwiftData
import Foundation

// MARK: - AppContainer

@MainActor
final class AppContainer {

    // MARK: - Infrastructure

    let modelContainer: ModelContainer
    let logger: AppLogger
    let analytics: AnalyticsService
    let configuration: AppConfiguration

    // MARK: - Network

    let tunnelClient: TunnelClient
    let connectionManager: ConnectionManager

    // MARK: - Repositories

    let connectionRepository: ConnectionRepository
    let messageRepository: MessageRepository
    let agentRepository: AgentRepository
    let sessionRepository: SessionRepository
    let projectRepository: ProjectRepository

    // MARK: - Use Cases

    let connectUseCase: ConnectToDesktopUseCase
    let sendMessageUseCase: SendMessageUseCase
    let listAgentsUseCase: ListAgentsUseCase
    let switchAgentUseCase: SwitchAgentUseCase
    let browseProjectUseCase: BrowseProjectUseCase
    let manageSessionsUseCase: ManageSessionsUseCase

    // MARK: - ViewModels (shared)

    let appRouter: AppRouter
    let connectionViewModel: ConnectionViewModel

    // MARK: - Init

    init() {
        // -- Infrastructure --
        logger = AppLogger()
        analytics = AnalyticsService(isEnabled: false)
        configuration = AppConfiguration()

        do {
            modelContainer = try PersistenceConfiguration.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }

        // -- Network --
        tunnelClient = TunnelClient()
        connectionManager = ConnectionManager(tunnelClient: tunnelClient)

        // -- Repositories --
        connectionRepository = RemoteConnectionRepository(
            connectionManager: connectionManager,
            tunnelClient: tunnelClient,
            logger: logger
        )

        messageRepository = RemoteMessageRepository(
            tunnelClient: tunnelClient,
            logger: logger,
            cacheLimit: configuration.messagesCacheLimit,
            modelContainer: modelContainer
        )

        agentRepository = RemoteAgentRepository(
            tunnelClient: tunnelClient,
            logger: logger
        )

        sessionRepository = RemoteSessionRepository(
            tunnelClient: tunnelClient,
            logger: logger,
            modelContainer: modelContainer
        )

        projectRepository = RemoteProjectRepository(
            tunnelClient: tunnelClient,
            logger: logger
        )

        // -- Use Cases --
        connectUseCase = ConnectToDesktopUseCase(connectionRepository: connectionRepository)
        sendMessageUseCase = SendMessageUseCase(
            messageRepository: messageRepository,
            connectionRepository: connectionRepository
        )
        listAgentsUseCase = ListAgentsUseCase(agentRepository: agentRepository)
        switchAgentUseCase = SwitchAgentUseCase(agentRepository: agentRepository)
        browseProjectUseCase = BrowseProjectUseCase(projectRepository: projectRepository)
        manageSessionsUseCase = ManageSessionsUseCase(sessionRepository: sessionRepository)

        // -- ViewModels --
        appRouter = AppRouter()
        connectionViewModel = ConnectionViewModel(connectionRepository: connectionRepository)
    }
}
