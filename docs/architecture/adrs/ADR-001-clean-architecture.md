# ADR-001: Clean Architecture

## Status

Accepted

## Date

2026-03-11

## Context

Toone Mobile is an iOS companion app for Toone Desktop that connects over a WebSocket tunnel to provide on-the-go access to Chat, Project Explorer, agent management, and session history. The mobile app does not run AI inference locally; it is a thin client that delegates all AI operations to the desktop.

This context imposes several architectural requirements:

1. **Maintainability and testability.** As an open-source project, the codebase must be approachable and verifiable by contributors who are not yet familiar with the internals. Every layer should be testable in isolation, without requiring a live desktop connection or a real device.

2. **Concurrent development by AI agents and humans.** The project is built by a mixed team of AI coding agents and human developers working in parallel. Clear layer boundaries reduce merge conflicts and allow contributors to work on the tunnel client, business logic, and UI simultaneously without stepping on each other.

3. **Independent evolution.** The tunnel protocol, persistence strategy, and UI framework may each change over the lifetime of the project. The architecture must allow swapping any of these without cascading changes through unrelated code.

4. **Open-source contribution clarity.** New contributors should be able to understand the system by reading the Domain layer first, which contains all business concepts without noise from networking, serialization, or UI framework details.

We evaluated the following approaches:

- **MVC (Model-View-Controller).** Apple's default pattern. Simple for small apps, but leads to "Massive View Controller" as features grow. Business logic becomes entangled with UI code, making unit testing difficult.
- **MVVM without explicit layers.** ViewModels separate logic from views, but without layer boundaries, networking, persistence, and business rules tend to merge into ViewModels. Testability suffers as ViewModels accumulate direct dependencies on network clients and databases.
- **The Composable Architecture (TCA).** Popular in the Swift community, with strong state management guarantees. However, it introduces a significant third-party dependency, a steep learning curve, and its opinionated state management can conflict with `@Observable`.
- **VIPER.** More granular than Clean Architecture, adding Router and Interactor layers. The Router layer is less relevant with SwiftUI's `NavigationStack`, and the additional boilerplate is excessive for an app of this scope.
- **Clean Architecture (4-layer).** Strict separation into Domain, Data, Presentation, and Infrastructure with inward-pointing dependencies. Domain contains pure business logic with no framework dependencies. Data handles tunnel communication and persistence. Presentation handles UI. Infrastructure provides cross-cutting concerns.

## Decision

We adopt **Clean Architecture** with four layers: Domain, Data, Presentation, and Infrastructure. Dependencies point inward only.

### Layer Structure

```
Presentation (SwiftUI Views + MVVM ViewModels)
    depends on -> Domain
Domain (Entities, Use Cases, Repository/Service Protocols)
    depends on -> nothing
Data (Tunnel Client, Repository Implementations, Persistence, DTO Mappers)
    implements -> Domain protocols
Infrastructure (Logging, Security, Configuration, Network Monitoring)
    consumed via -> Domain protocols
```

### Rules

1. **Domain has zero external dependencies.** No SwiftUI, no Foundation networking, no third-party packages. Only Swift standard library and Foundation value types (Date, UUID, etc.).
2. **Dependencies point inward.** Presentation and Data depend on Domain. Domain depends on neither.
3. **Cross-layer communication uses protocols.** Repositories and services are declared as protocols in Domain and implemented in Data. This is how the dependency rule is preserved while allowing data to flow outward at runtime.
4. **DTOs and persistence models are separate from domain entities.** Mappers translate between them at the Data layer boundary, preventing serialization concerns from leaking into the domain.
5. **Each use case encapsulates one business operation.** Use cases are the only entry points to domain logic from the Presentation layer.
6. **Manual dependency injection via a composition root.** No DI framework is required. A `DependencyContainer` created at app launch provides all instances with compile-time safety.

### Directory Layout

```
TooneApp/
  Domain/
    Entities/
    UseCases/
    Repositories/       (protocols only)
    Services/           (protocols only)
    Errors/
  Data/
    Tunnel/
    Repositories/       (implementations)
    Persistence/
    Mappers/
  Presentation/
    Chat/
    ProjectExplorer/
    Agents/
    Sessions/
    Settings/
    DesignSystem/
    Navigation/
  Infrastructure/
    Logging/
    Analytics/
    Configuration/
    Security/
```

## Consequences

### Positive

- **Testability.** Domain use cases can be tested with simple mock implementations of repository protocols. No networking or UI framework is needed. ViewModels can be tested by injecting mock use cases. Data repositories can be tested with a mock tunnel client.
- **Separation of concerns.** Tunnel protocol details are confined to Data. UI framework details are confined to Presentation. Business rules live only in Domain. A change in the JSON-RPC message format does not touch any ViewModel; a UI redesign does not alter business logic.
- **Parallel development.** Multiple contributors (human or AI) can work on different layers simultaneously with minimal merge conflicts, because the layers communicate only through stable protocol interfaces in the Domain layer.
- **Swappable implementations.** The persistence layer can be swapped from SwiftData to Core Data, SQLite, or an in-memory store without affecting Domain or Presentation. The tunnel transport can be changed from WebSocket to another protocol without touching business logic.
- **Onboarding clarity.** New developers can understand the system by reading the Domain layer first, which contains all business concepts (Message, Agent, Session, Project) and all operations (SendMessage, SyncState, SwitchAgent) without noise from networking or UI code.
- **Future modularization.** Each layer maps cleanly to a Swift Package, enabling enforced dependency rules at the compiler level when the codebase is mature enough to extract modules.

### Negative

- **More files and boilerplate.** Each feature requires entities, use case protocols and implementations, repository protocols and implementations, DTOs, mappers, ViewModels, and views. For simple CRUD operations, this can feel excessive compared to a flat MVVM approach.
- **Indirection via protocols.** Navigation from a ViewModel call to the actual implementation requires tracing through protocol definitions and their conformances. Debugging and code navigation are slower than in a direct-call architecture.
- **Mapper overhead.** Translating between DTOs (from JSON-RPC), persistence models (SwiftData `@Model` classes), and domain entities requires writing and maintaining mapper code. This is an intentional trade-off: the cost of mapping is lower than the cost of leaking serialization or persistence concerns into the domain.
- **Learning curve for contributors.** Developers unfamiliar with Clean Architecture need time to understand the dependency rule and layer boundaries. Code review must actively enforce these boundaries, especially the rule that Domain imports nothing from Data or Presentation.

### Mitigations

- Use Swift generics and protocol extensions to reduce repetitive boilerplate.
- Establish clear naming conventions documented in the Clean Architecture guide.
- Consider code generation for mapper boilerplate if it becomes burdensome.
- Start with directory-based layer separation; extract into Swift Packages once the codebase stabilizes.
