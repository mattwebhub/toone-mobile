# Toone Mobile -- Architecture Overview

**Version:** 1.0
**Last Updated:** 2026-03-11
**Status:** Draft

---

## 1. Introduction

Toone Mobile is an iOS companion application for Toone Desktop, the native macOS AI-powered content creation assistant. The mobile app connects to a running desktop instance over a WebSocket tunnel and provides on-the-go access to the Chat interface, Project Explorer, agent management, and session history.

Toone Mobile does **not** run AI inference locally. All AI operations are delegated to the desktop instance through the tunnel protocol, making the mobile app a lightweight, responsive client.

---

## 2. System Context

```
+-------------------------------------------------------------------+
|                        USER'S NETWORK                             |
|                                                                   |
|   +------------------+         WebSocket          +-----------+   |
|   |                  |    (JSON-RPC 2.0 / TLS)    |           |   |
|   |  Toone Mobile    | <========================> |  Toone    |   |
|   |  (iOS 17+)       |        Port 9876           |  Desktop  |   |
|   |                  |                             |  (macOS)  |   |
|   +------------------+                             +-----+-----+  |
|          |                                               |        |
|          | Displays                                      | Runs   |
|          v                                               v        |
|   +------------------+                          +--------------+  |
|   | - Chat UI        |                          | - AI CLI     |  |
|   | - Project Tree   |                          |   (Claude,   |  |
|   | - Agent List     |                          |    Codex)    |  |
|   | - Session History|                          | - Browser    |  |
|   | - Browser Status |                          |   Bridge     |  |
|   +------------------+                          | - Full UI    |  |
|                                                 +--------------+  |
+-------------------------------------------------------------------+
```

### Connection Model

1. Toone Desktop runs a WebSocket server on port 9876 (the existing BrowserBridge endpoint, extended for mobile).
2. Toone Mobile discovers the desktop instance via QR code scan or manual IP entry.
3. A persistent WebSocket connection is established with token-based authentication.
4. All AI requests, file reads, and state queries flow through this tunnel.

---

## 3. Layer Diagram (Clean Architecture)

```
+---------------------------------------------------------------+
|                     Presentation Layer                         |
|  +----------------------------------------------------------+ |
|  |  SwiftUI Views  |  ViewModels (@Observable)  | Navigation| |
|  +----------------------------------------------------------+ |
|  |  Design System  |  Components  |  Haptics  |  Animations | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
        |                     |                      |
        v                     v                      v
+---------------------------------------------------------------+
|                       Domain Layer                             |
|  +----------------------------------------------------------+ |
|  |  Entities (Message, Agent, Session, Project, Department)  | |
|  +----------------------------------------------------------+ |
|  |  Use Cases (SendMessage, SyncState, SwitchAgent, ...)     | |
|  +----------------------------------------------------------+ |
|  |  Repository Protocols  |  Service Protocols               | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
        ^                     ^                      ^
        |                     |                      |
+---------------------------------------------------------------+
|                        Data Layer                              |
|  +----------------------------------------------------------+ |
|  |  Tunnel Client (WebSocket / JSON-RPC)                     | |
|  +----------------------------------------------------------+ |
|  |  Repository Implementations                               | |
|  +----------------------------------------------------------+ |
|  |  SwiftData Persistence  |  DTO Mappers                   | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
        |                     |                      |
        v                     v                      v
+---------------------------------------------------------------+
|                    Infrastructure Layer                         |
|  +----------------------------------------------------------+ |
|  |  Logging  |  Analytics  |  Configuration  |  Keychain     | |
|  +----------------------------------------------------------+ |
|  |  Network Monitor  |  Reachability  |  App Lifecycle       | |
|  +----------------------------------------------------------+ |
+---------------------------------------------------------------+
```

### Dependency Rule

Dependencies point **inward**. The Domain layer has zero dependencies on any other layer. The Presentation and Data layers depend on Domain. Infrastructure may be referenced by Data and Presentation through protocol abstractions defined in Domain.

---

## 4. Key Architectural Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| [ADR-001](adrs/ADR-001-clean-architecture.md) | Clean Architecture with four layers | Testability, separation of concerns, long-term maintainability |
| [ADR-002](adrs/ADR-002-tunnel-protocol.md) | WebSocket tunnel with JSON-RPC 2.0 | Bidirectional streaming, structured RPC, existing BrowserBridge |
| [ADR-003](adrs/ADR-003-swiftui-only.md) | SwiftUI-only, iOS 17+ minimum | Modern declarative UI, @Observable macro, reduced complexity |
| [ADR-004](adrs/ADR-004-offline-caching.md) | SwiftData for offline caching | Native persistence, CloudKit-ready, Swift-native API |

---

## 5. Technology Choices

| Technology | Purpose | Rationale |
|------------|---------|-----------|
| Swift 5.9+ | Language | Native iOS performance, type safety, concurrency model |
| SwiftUI | UI framework | Declarative, composable, first-class Apple platform support |
| Swift Concurrency | Async operations | Structured concurrency with async/await, Actors, AsyncStream |
| @Observable (Observation framework) | State management | Eliminates boilerplate, fine-grained view updates |
| URLSessionWebSocketTask | WebSocket transport | Native API, automatic TLS, background task support |
| SwiftData | Local persistence | Swift-native ORM, automatic migrations, SwiftUI integration |
| Keychain Services | Secret storage | Secure enclave-backed storage for auth tokens |
| JSON-RPC 2.0 | Tunnel protocol | Industry standard, bidirectional, schema-friendly |
| OSLog | Structured logging | System-integrated, privacy-aware, zero-cost when disabled |

---

## 6. Module Structure

```
TooneApp/
  Domain/
    Entities/
    UseCases/
    Repositories/       (protocols only)
    Services/           (protocols only)
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

---

## 7. Quality Attributes

| Attribute | Target | Approach |
|-----------|--------|----------|
| Responsiveness | < 100ms UI response | Optimistic UI updates, background processing |
| Reliability | Graceful degradation | Offline caching, automatic reconnection |
| Security | Zero trust tunnel | TLS encryption, token rotation, Keychain storage |
| Testability | > 80% domain coverage | Protocol-based DI, isolated layers |
| Accessibility | VoiceOver complete | Semantic labels, Dynamic Type, sufficient contrast |
| Battery | Minimal drain | Efficient WebSocket keep-alive, no polling |

---

## 8. Related Documents

- [Clean Architecture Guide](clean-architecture.md)
- [Tunnel Protocol Specification](tunnel-protocol.md)
- [Design System](design-system.md)
- [Data Flow Documentation](data-flow.md)
- [Architecture Decision Records](adrs/)
