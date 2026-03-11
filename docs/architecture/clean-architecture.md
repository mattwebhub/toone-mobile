# Toone Mobile -- Clean Architecture Guide

**Version:** 1.0
**Last Updated:** 2026-03-11
**Status:** Draft

---

## 1. Overview

Toone Mobile follows Clean Architecture principles as described by Robert C. Martin, adapted for Swift and iOS conventions. The application is divided into four concentric layers, each with clear responsibilities and strict dependency rules.

```
                    +---------------------+
                    |    Presentation     |
                    |  (SwiftUI + MVVM)   |
                    +----------+----------+
                               |
                    +----------v----------+
                    |       Domain        |
                    | (Entities, UseCases) |
                    +----------+----------+
                               ^
                    +----------+----------+
                    |        Data         |
                    | (Tunnel, Repos, DB) |
                    +----------+----------+
                               |
                    +----------v----------+
                    |   Infrastructure    |
                    | (Logging, Config)   |
                    +---------------------+
```

### The Dependency Rule

- Source code dependencies must point **inward** only.
- The Domain layer knows nothing about Data, Presentation, or Infrastructure.
- The Data layer implements protocols defined in Domain.
- The Presentation layer depends on Domain (use cases, entities) but never directly on Data.
- Infrastructure provides cross-cutting concerns and is accessed through protocols.

---

## 2. Domain Layer

The Domain layer is the heart of the application. It contains business logic, entity definitions, and protocol declarations for repositories and services. It has **zero external dependencies** -- no UIKit, no SwiftUI, no third-party frameworks.

### 2.1 Entities

Entities represent the core business objects. They are plain Swift types (structs or classes) with value semantics where possible.

```swift
// Domain/Entities/Message.swift

struct Message: Identifiable, Equatable, Sendable {
    let id: String
    let sessionID: String
    let role: MessageRole
    let content: MessageContent
    let timestamp: Date
    let metadata: MessageMetadata?

    enum MessageRole: String, Sendable {
        case user
        case assistant
        case system
    }
}

struct MessageContent: Equatable, Sendable {
    let text: String
    let toolCalls: [ToolCall]
    let attachments: [Attachment]

    static func text(_ text: String) -> MessageContent {
        MessageContent(text: text, toolCalls: [], attachments: [])
    }
}
```

```swift
// Domain/Entities/Agent.swift

struct Agent: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let departmentID: String
    let role: String
    let systemPrompt: String
    let isActive: Bool
}
```

```swift
// Domain/Entities/Session.swift

struct Session: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let agentID: String
    let createdAt: Date
    let lastActivityAt: Date
    let messageCount: Int
    let isArchived: Bool
}
```

```swift
// Domain/Entities/Project.swift

struct ProjectNode: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let path: String
    let type: NodeType
    let children: [ProjectNode]

    enum NodeType: String, Sendable {
        case file
        case directory
    }
}
```

```swift
// Domain/Entities/Department.swift

struct Department: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let description: String
    let agentIDs: [String]
}
```

### 2.2 Use Cases

Each use case encapsulates a single business operation. Use cases are classes or structs that depend only on repository and service protocols.

```swift
// Domain/UseCases/SendMessageUseCase.swift

protocol SendMessageUseCaseProtocol: Sendable {
    func execute(content: String, sessionID: String) async throws -> AsyncStream<MessageStreamEvent>
}

final class SendMessageUseCase: SendMessageUseCaseProtocol, Sendable {
    private let chatRepository: ChatRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol

    init(
        chatRepository: ChatRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.chatRepository = chatRepository
        self.sessionRepository = sessionRepository
    }

    func execute(content: String, sessionID: String) async throws -> AsyncStream<MessageStreamEvent> {
        // Validate session exists and is active
        guard let session = try await sessionRepository.getSession(id: sessionID) else {
            throw DomainError.sessionNotFound(sessionID)
        }
        guard !session.isArchived else {
            throw DomainError.sessionArchived(sessionID)
        }

        // Delegate to repository (which sends through tunnel)
        return try await chatRepository.sendMessage(content: content, sessionID: sessionID)
    }
}
```

```swift
// Domain/UseCases/SyncStateUseCase.swift

protocol SyncStateUseCaseProtocol: Sendable {
    func execute() async throws -> AppState
    func observeChanges() -> AsyncStream<StateChange>
}

final class SyncStateUseCase: SyncStateUseCaseProtocol, Sendable {
    private let stateRepository: StateRepositoryProtocol

    init(stateRepository: StateRepositoryProtocol) {
        self.stateRepository = stateRepository
    }

    func execute() async throws -> AppState {
        return try await stateRepository.performFullSync()
    }

    func observeChanges() -> AsyncStream<StateChange> {
        return stateRepository.subscribeToChanges()
    }
}
```

**Naming convention:** Use cases are named as `VerbNounUseCase` (e.g., `SendMessageUseCase`, `ListAgentsUseCase`, `ArchiveSessionUseCase`).

### Catalogue of Use Cases

| Use Case | Description |
|----------|-------------|
| `SendMessageUseCase` | Send a chat message through the tunnel and return a stream of response events |
| `SyncStateUseCase` | Perform full state synchronization and subscribe to incremental updates |
| `ListAgentsUseCase` | Retrieve the list of available agents with their department associations |
| `SwitchAgentUseCase` | Change the active agent for the current session |
| `ListSessionsUseCase` | Retrieve session history with filtering and sorting |
| `ArchiveSessionUseCase` | Archive a session (soft delete) |
| `RestoreSessionUseCase` | Restore an archived session |
| `GetProjectTreeUseCase` | Fetch the project file tree from the desktop |
| `ReadProjectFileUseCase` | Read a file's contents from the desktop project (read-only) |
| `ConnectToDesktopUseCase` | Initiate tunnel connection via QR code or manual IP |
| `AnswerQuestionUseCase` | Respond to a question posed by the AI during a tool call |

### 2.3 Repository Protocols

Repository protocols define the data access contracts. They live in Domain so that the Data layer can implement them without creating an inward dependency.

```swift
// Domain/Repositories/ChatRepositoryProtocol.swift

protocol ChatRepositoryProtocol: Sendable {
    func sendMessage(content: String, sessionID: String) async throws -> AsyncStream<MessageStreamEvent>
    func getMessages(sessionID: String, limit: Int, before: Date?) async throws -> [Message]
    func answerQuestion(questionID: String, answer: String) async throws
}
```

```swift
// Domain/Repositories/SessionRepositoryProtocol.swift

protocol SessionRepositoryProtocol: Sendable {
    func getSession(id: String) async throws -> Session?
    func listSessions(filter: SessionFilter) async throws -> [Session]
    func archiveSession(id: String) async throws
    func restoreSession(id: String) async throws
}
```

```swift
// Domain/Repositories/StateRepositoryProtocol.swift

protocol StateRepositoryProtocol: Sendable {
    func performFullSync() async throws -> AppState
    func subscribeToChanges() -> AsyncStream<StateChange>
}
```

```swift
// Domain/Repositories/ProjectRepositoryProtocol.swift

protocol ProjectRepositoryProtocol: Sendable {
    func getTree() async throws -> ProjectNode
    func readFile(path: String) async throws -> FileContent
}
```

```swift
// Domain/Repositories/AgentRepositoryProtocol.swift

protocol AgentRepositoryProtocol: Sendable {
    func listAgents() async throws -> [Agent]
    func switchAgent(id: String) async throws -> Agent
}
```

### 2.4 Service Protocols

Service protocols define cross-cutting operations that don't fit neatly into a single repository.

```swift
// Domain/Services/ConnectionServiceProtocol.swift

protocol ConnectionServiceProtocol: Sendable {
    var connectionState: AsyncStream<ConnectionState> { get }
    func connect(to endpoint: TunnelEndpoint) async throws
    func disconnect() async
}
```

### 2.5 Domain Errors

```swift
// Domain/Errors/DomainError.swift

enum DomainError: Error, Equatable, Sendable {
    case sessionNotFound(String)
    case sessionArchived(String)
    case agentNotFound(String)
    case notConnected
    case connectionFailed(String)
    case unauthorized
    case fileNotFound(String)
    case syncFailed(String)
}
```

---

## 3. Data Layer

The Data layer implements the repository protocols from Domain. It manages the tunnel client, local persistence, and DTO mapping.

### 3.1 Tunnel Client

The tunnel client is the central networking component. It manages the WebSocket connection and provides a typed API over JSON-RPC 2.0.

```swift
// Data/Tunnel/TunnelClient.swift

actor TunnelClient {
    private let webSocket: URLSessionWebSocketTask
    private var pendingRequests: [String: CheckedContinuation<JSONRPCResponse, Error>]
    private var notificationHandlers: [String: (JSONRPCNotification) -> Void]

    func send<Request: Encodable, Response: Decodable>(
        method: String,
        params: Request
    ) async throws -> Response {
        let id = UUID().uuidString
        let request = JSONRPCRequest(id: id, method: method, params: params)
        // ... encode, send, await response
    }

    func subscribe(
        method: String,
        handler: @escaping @Sendable (JSONRPCNotification) -> Void
    ) {
        notificationHandlers[method] = handler
    }
}
```

See [Tunnel Protocol Specification](tunnel-protocol.md) for the complete protocol definition.

### 3.2 Repository Implementations

Each repository implementation bridges between the Domain protocol and the tunnel client (or local persistence).

```swift
// Data/Repositories/ChatRepository.swift

final class ChatRepository: ChatRepositoryProtocol, Sendable {
    private let tunnelClient: TunnelClient
    private let messageCache: MessageCacheProtocol

    init(tunnelClient: TunnelClient, messageCache: MessageCacheProtocol) {
        self.tunnelClient = tunnelClient
        self.messageCache = messageCache
    }

    func sendMessage(content: String, sessionID: String) async throws -> AsyncStream<MessageStreamEvent> {
        let request = ChatSendRequest(content: content, sessionID: sessionID)

        // Send via tunnel
        let response: ChatSendResponse = try await tunnelClient.send(
            method: "chat.sendMessage",
            params: request
        )

        // Return stream of events from tunnel notifications
        return AsyncStream { continuation in
            tunnelClient.subscribe(method: "chat.messageStream") { notification in
                if let event = try? notification.decode(MessageStreamEvent.self) {
                    continuation.yield(event)
                    if event.isComplete {
                        continuation.finish()
                    }
                }
            }
        }
    }

    func getMessages(sessionID: String, limit: Int, before: Date?) async throws -> [Message] {
        // Try cache first
        if let cached = try await messageCache.getMessages(sessionID: sessionID, limit: limit, before: before),
           !cached.isEmpty {
            return cached
        }

        // Fetch from desktop via tunnel
        let dtos: [MessageDTO] = try await tunnelClient.send(
            method: "chat.getMessages",
            params: ChatGetMessagesRequest(sessionID: sessionID, limit: limit, before: before)
        )

        let messages = dtos.map(MessageMapper.toDomain)

        // Cache for offline access
        try await messageCache.store(messages: messages)

        return messages
    }

    func answerQuestion(questionID: String, answer: String) async throws {
        let request = ChatAnswerRequest(questionID: questionID, answer: answer)
        let _: EmptyResponse = try await tunnelClient.send(
            method: "chat.answerQuestion",
            params: request
        )
    }
}
```

### 3.3 Persistence (SwiftData)

SwiftData models mirror domain entities for offline caching. They are **separate** from domain entities to maintain the layer boundary.

```swift
// Data/Persistence/Models/CachedMessage.swift

@Model
final class CachedMessage {
    @Attribute(.unique) var id: String
    var sessionID: String
    var role: String
    var textContent: String
    var timestamp: Date
    var isSynced: Bool

    init(id: String, sessionID: String, role: String, textContent: String, timestamp: Date) {
        self.id = id
        self.sessionID = sessionID
        self.role = role
        self.textContent = textContent
        self.timestamp = timestamp
        self.isSynced = true
    }
}
```

```swift
// Data/Persistence/Models/CachedSession.swift

@Model
final class CachedSession {
    @Attribute(.unique) var id: String
    var title: String
    var agentID: String
    var createdAt: Date
    var lastActivityAt: Date
    var messageCount: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade)
    var messages: [CachedMessage]
}
```

### 3.4 DTO Mappers

Mappers translate between DTOs (Data Transfer Objects from JSON-RPC), persistence models, and domain entities. This prevents serialization concerns from leaking into the domain.

```swift
// Data/Mappers/MessageMapper.swift

enum MessageMapper {
    static func toDomain(_ dto: MessageDTO) -> Message {
        Message(
            id: dto.id,
            sessionID: dto.sessionID,
            role: Message.MessageRole(rawValue: dto.role) ?? .system,
            content: .text(dto.content),
            timestamp: dto.timestamp,
            metadata: dto.metadata.map { MetadataMapper.toDomain($0) }
        )
    }

    static func toDomain(_ cached: CachedMessage) -> Message {
        Message(
            id: cached.id,
            sessionID: cached.sessionID,
            role: Message.MessageRole(rawValue: cached.role) ?? .system,
            content: .text(cached.textContent),
            timestamp: cached.timestamp,
            metadata: nil
        )
    }

    static func toCache(_ entity: Message) -> CachedMessage {
        CachedMessage(
            id: entity.id,
            sessionID: entity.sessionID,
            role: entity.role.rawValue,
            textContent: entity.content.text,
            timestamp: entity.timestamp
        )
    }
}
```

---

## 4. Presentation Layer

The Presentation layer contains all SwiftUI views, view models, the design system, and navigation logic.

### 4.1 MVVM Pattern

Every screen has a corresponding ViewModel conforming to `@Observable`. ViewModels depend on use cases from the Domain layer.

```swift
// Presentation/Chat/ChatViewModel.swift

@Observable
final class ChatViewModel {
    private(set) var messages: [Message] = []
    private(set) var isStreaming: Bool = false
    private(set) var error: DomainError?
    var inputText: String = ""

    private let sendMessage: SendMessageUseCaseProtocol
    private let listMessages: ListMessagesUseCaseProtocol
    private var streamTask: Task<Void, Never>?

    init(
        sendMessage: SendMessageUseCaseProtocol,
        listMessages: ListMessagesUseCaseProtocol
    ) {
        self.sendMessage = sendMessage
        self.listMessages = listMessages
    }

    func send() {
        let content = inputText
        inputText = ""
        isStreaming = true
        error = nil

        streamTask = Task {
            do {
                let stream = try await sendMessage.execute(content: content, sessionID: currentSessionID)
                for await event in stream {
                    handleStreamEvent(event)
                }
            } catch let domainError as DomainError {
                self.error = domainError
            } catch {
                self.error = .connectionFailed(error.localizedDescription)
            }
            isStreaming = false
        }
    }

    func loadMessages() async {
        do {
            messages = try await listMessages.execute(sessionID: currentSessionID, limit: 50, before: nil)
        } catch {
            self.error = .syncFailed(error.localizedDescription)
        }
    }

    private func handleStreamEvent(_ event: MessageStreamEvent) {
        switch event {
        case .textDelta(let delta):
            appendToLastAssistantMessage(delta)
        case .toolCall(let call):
            appendToolCall(call)
        case .complete(let message):
            finalizeMessage(message)
        case .error(let reason):
            self.error = .connectionFailed(reason)
        }
    }
}
```

### 4.2 View Structure

Views are thin -- they observe the ViewModel and render state. Business logic and data transformation live in the ViewModel.

```swift
// Presentation/Chat/ChatView.swift

struct ChatView: View {
    @State private var viewModel: ChatViewModel

    init(viewModel: ChatViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputBar
        }
        .task {
            await viewModel.loadMessages()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private var inputBar: some View {
        ChatInputBar(
            text: $viewModel.inputText,
            isStreaming: viewModel.isStreaming,
            onSend: { viewModel.send() }
        )
    }
}
```

### 4.3 Navigation

Navigation uses `NavigationStack` with a typed path and a central coordinator.

```swift
// Presentation/Navigation/AppRouter.swift

@Observable
final class AppRouter {
    var chatPath = NavigationPath()
    var selectedTab: AppTab = .chat

    enum AppTab: Hashable {
        case chat
        case project
        case agents
        case sessions
        case settings
    }

    func navigateTo(_ destination: ChatDestination) {
        chatPath.append(destination)
    }

    func popToRoot() {
        chatPath = NavigationPath()
    }
}
```

### 4.4 Design System

The design system is a standalone module within the Presentation layer. See [Design System](design-system.md) for the full specification.

---

## 5. Infrastructure Layer

The Infrastructure layer provides cross-cutting concerns that support all other layers.

### 5.1 Logging

```swift
// Infrastructure/Logging/Logger.swift

import OSLog

enum LogCategory: String {
    case tunnel = "Tunnel"
    case ui = "UI"
    case data = "Data"
    case lifecycle = "Lifecycle"
}

struct AppLogger {
    private let logger: os.Logger

    init(category: LogCategory) {
        self.logger = os.Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.toone.mobile",
            category: category.rawValue
        )
    }

    func debug(_ message: String) { logger.debug("\(message, privacy: .public)") }
    func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    func warning(_ message: String) { logger.warning("\(message, privacy: .public)") }
    func error(_ message: String) { logger.error("\(message, privacy: .public)") }
}
```

### 5.2 Configuration

```swift
// Infrastructure/Configuration/AppConfiguration.swift

struct AppConfiguration: Sendable {
    let tunnelPort: Int
    let reconnectMaxAttempts: Int
    let reconnectBaseDelay: TimeInterval
    let cacheMaxMessages: Int
    let keepAliveInterval: TimeInterval

    static let `default` = AppConfiguration(
        tunnelPort: 9876,
        reconnectMaxAttempts: 10,
        reconnectBaseDelay: 1.0,
        cacheMaxMessages: 1000,
        keepAliveInterval: 30.0
    )
}
```

### 5.3 Security (Keychain)

```swift
// Infrastructure/Security/KeychainService.swift

protocol KeychainServiceProtocol: Sendable {
    func store(key: String, data: Data) throws
    func retrieve(key: String) throws -> Data?
    func delete(key: String) throws
}
```

Auth tokens, connection secrets, and device identifiers are stored exclusively in the Keychain, never in UserDefaults or files.

---

## 6. Dependency Injection

Toone Mobile uses **manual dependency injection** via a composition root. No DI framework is required. The `DependencyContainer` is created at app launch and provides all instances.

```swift
// App/DependencyContainer.swift

@MainActor
final class DependencyContainer {
    // Infrastructure
    private lazy var configuration = AppConfiguration.default
    private lazy var keychainService: KeychainServiceProtocol = KeychainService()

    // Data
    private lazy var tunnelClient = TunnelClient(configuration: configuration)
    private lazy var messageCache: MessageCacheProtocol = SwiftDataMessageCache(modelContainer: modelContainer)
    private lazy var modelContainer: ModelContainer = {
        try! ModelContainer(for: CachedMessage.self, CachedSession.self)
    }()

    // Repositories
    private lazy var chatRepository: ChatRepositoryProtocol = ChatRepository(
        tunnelClient: tunnelClient,
        messageCache: messageCache
    )
    private lazy var sessionRepository: SessionRepositoryProtocol = SessionRepository(
        tunnelClient: tunnelClient
    )
    private lazy var agentRepository: AgentRepositoryProtocol = AgentRepository(
        tunnelClient: tunnelClient
    )
    private lazy var projectRepository: ProjectRepositoryProtocol = ProjectRepository(
        tunnelClient: tunnelClient
    )
    private lazy var stateRepository: StateRepositoryProtocol = StateRepository(
        tunnelClient: tunnelClient,
        messageCache: messageCache
    )

    // Use Cases
    private lazy var sendMessageUseCase: SendMessageUseCaseProtocol = SendMessageUseCase(
        chatRepository: chatRepository,
        sessionRepository: sessionRepository
    )

    // ViewModels
    func makeChatViewModel() -> ChatViewModel {
        ChatViewModel(
            sendMessage: sendMessageUseCase,
            listMessages: ListMessagesUseCase(chatRepository: chatRepository)
        )
    }

    func makeProjectViewModel() -> ProjectViewModel {
        ProjectViewModel(
            getProjectTree: GetProjectTreeUseCase(projectRepository: projectRepository),
            readFile: ReadProjectFileUseCase(projectRepository: projectRepository)
        )
    }

    func makeAgentsViewModel() -> AgentsViewModel {
        AgentsViewModel(
            listAgents: ListAgentsUseCase(agentRepository: agentRepository),
            switchAgent: SwitchAgentUseCase(agentRepository: agentRepository)
        )
    }

    func makeSessionsViewModel() -> SessionsViewModel {
        SessionsViewModel(
            listSessions: ListSessionsUseCase(sessionRepository: sessionRepository),
            archiveSession: ArchiveSessionUseCase(sessionRepository: sessionRepository),
            restoreSession: RestoreSessionUseCase(sessionRepository: sessionRepository)
        )
    }
}
```

### Why Manual DI?

- **Compile-time safety:** All dependencies are resolved at compile time. Missing dependencies cause build errors, not runtime crashes.
- **Transparency:** The dependency graph is explicit and readable in one file.
- **No magic:** No property wrappers, no runtime reflection, no framework lock-in.
- **Testability:** In tests, create a `TestDependencyContainer` that injects mocks.

---

## 7. Testing Strategy

| Layer | Test Type | Dependencies |
|-------|-----------|--------------|
| Domain | Unit tests | No mocks needed (pure logic) |
| Data | Unit tests | Mock TunnelClient, mock persistence |
| Presentation | Unit tests for ViewModels | Mock use cases |
| Infrastructure | Unit tests | Mock Keychain, mock network monitor |
| Integration | Integration tests | Real WebSocket to test tunnel |

### Testing Domain Layer

Domain use cases depend only on protocols, so tests inject simple mock implementations:

```swift
final class SendMessageUseCaseTests: XCTestCase {
    func test_execute_withArchivedSession_throwsError() async {
        let mockChat = MockChatRepository()
        let mockSession = MockSessionRepository()
        mockSession.stubSession = Session(/* ... isArchived: true */)

        let sut = SendMessageUseCase(chatRepository: mockChat, sessionRepository: mockSession)

        do {
            _ = try await sut.execute(content: "hello", sessionID: "s1")
            XCTFail("Expected error")
        } catch DomainError.sessionArchived {
            // Expected
        }
    }
}
```

---

## 8. Package / Module Boundaries

For a single-target app, the layers are enforced by **directory convention** and code review. As the codebase grows, each layer can be extracted into a Swift Package:

```
TooneApp/
  Package.swift
  Sources/
    TooneDomain/          (library)
    TooneData/            (library, depends on TooneDomain)
    ToonePresentation/    (library, depends on TooneDomain)
    TooneInfrastructure/  (library)
    TooneApp/             (executable, composes all)
```

This modular structure enables:
- Independent compilation and caching
- Enforced dependency rules via package manifests
- Reuse of Domain in other targets (e.g., widget extension)
