# Toone Mobile

iOS companion app for [Toone Desktop](https://github.com/mattwebhub/toone). Acts as a remote control and chat interface that tunnels to a running toone-desktop instance via WebSocket.

## Overview

Toone Mobile brings the core Toone experience to your phone. Instead of running AI locally, it connects to your desktop instance and provides:

- **Chat Interface** — Full AI chat with rich message rendering (markdown, code blocks, tool calls)
- **Agent Management** — Browse departments, switch agents, manage sessions
- **Project Explorer** — Read-only file tree browsing of your desktop project
- **Session History** — View and restore archived chat sessions

## Architecture

Built with **Clean Architecture** principles for maintainability and testability:

```
+--------------------------------------------------+
|                  Presentation                     |
|  SwiftUI Views | ViewModels | Design System       |
+--------------------------------------------------+
|                     Domain                        |
|  Entities | Use Cases | Repository Protocols       |
+--------------------------------------------------+
|                      Data                         |
|  Tunnel Client | Repositories | Persistence        |
+--------------------------------------------------+
|                  Infrastructure                   |
|  Logging | Analytics | Configuration               |
+--------------------------------------------------+
```

### Tunnel Protocol

Communication with toone-desktop uses **JSON-RPC 2.0 over WebSocket**:

```
iPhone                          Mac (toone-desktop)
  |                                    |
  |--- WebSocket Connect ------------->|
  |<-- auth.handshake ----------------|
  |--- state.sync ------------------->|
  |<-- Full state (agents, sessions) -|
  |                                    |
  |--- chat.sendMessage ------------->|
  |<-- chat.messageStream (stream) ---|
  |<-- chat.toolCall (notification) --|
  |<-- chat.messageComplete ----------|
```

### Design Language

Shares the **Ocean Depth** dark theme with toone-desktop:
- Deep dark backgrounds (#14161E base)
- Glassmorphism effects
- Consistent typography scale
- Same color tokens and spacing system

## Requirements

- iOS 17.0+
- Xcode 16+
- Swift 6.0
- A running toone-desktop instance on the same network

## Getting Started

1. Clone the repository
2. Open `TooneMobile/TooneMobile.xcodeproj` in Xcode (or generate with `xcodegen`)
3. Build and run on simulator or device
4. Enter your desktop's IP address and port to connect

## Project Structure

```
TooneMobile/
├── TooneMobile/
│   ├── App/              # Entry point, DI container
│   ├── Domain/           # Pure Swift entities, use cases, protocols
│   ├── Data/             # Network tunnel, repositories, persistence
│   ├── Presentation/     # SwiftUI views, ViewModels, design system
│   ├── Infrastructure/   # Logging, analytics, configuration
│   └── Resources/        # Assets, localization
├── TooneMobileTests/     # Unit tests
└── project.yml           # XcodeGen specification
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
