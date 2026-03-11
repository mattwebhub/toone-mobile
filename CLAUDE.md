# Toone Mobile

## Project Overview
iOS companion app for Toone Desktop. Acts as a remote control/chat interface that tunnels to a running toone-desktop instance via WebSocket. Built in Swift/SwiftUI with Clean Architecture.

## Architecture
- **Clean Architecture**: Domain → Data → Presentation → Infrastructure
- **MVVM** in presentation layer with `@Observable` ViewModels
- **Swift Concurrency**: async/await, Actors, AsyncStream throughout
- **SwiftData** for offline message caching
- **Design System**: Ocean Depth dark theme matching toone-desktop

## Project Structure
```
TooneMobile/
├── App/           # Entry point, DI container
├── Domain/        # Entities, UseCases, Repository protocols (PURE Swift)
├── Data/          # Network (tunnel), persistence, repository implementations
├── Presentation/  # SwiftUI views, ViewModels, DesignSystem
├── Infrastructure/# Logging, analytics, configuration
└── Resources/     # Assets, localization, Info.plist
```

## Key Rules
- Domain layer has ZERO framework imports (no SwiftUI, no UIKit)
- All external communication goes through repository protocols
- ViewModels are `@Observable @MainActor` classes
- Use `AsyncStream` for real-time data (message streaming, connection status)
- Tunnel protocol is JSON-RPC 2.0 over WebSocket
- Design tokens must match toone-desktop values exactly
- All public APIs must have unit tests
- No force unwraps. No implicitly unwrapped optionals except IBOutlet.

## Commands
- Build: `xcodebuild -project TooneMobile/TooneMobile.xcodeproj -scheme TooneMobile -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Test: `xcodebuild -project TooneMobile/TooneMobile.xcodeproj -scheme TooneMobile -destination 'platform=iOS Simulator,name=iPhone 16' test`
- Lint: `swiftlint lint --config .swiftlint.yml` (if installed)

## Conventions
- File naming: PascalCase for types, matching filename to primary type
- One type per file (exceptions: small related types)
- Protocol files named `{Name}Protocol.swift` or `{Name}Repository.swift`
- Test files named `{TypeName}Tests.swift`
- Use `// MARK: -` for section organization within files
- Prefer `guard` for early returns
- Use `Result` type for error handling at boundaries
- Async functions throw typed errors, not generic `Error`

## Dependencies (SPM)
- swift-markdown-ui (MarkdownUI) — Markdown rendering
- Highlightr — Syntax highlighting for code blocks (future)

## Deployment
- iOS 17.0+ minimum
- iPhone-only (optimized for mobile form factor)
- Xcode 16+, Swift 6.0

## Related Projects
- toone-desktop: `/Users/matheusparanhos/Projects/toone/apps/toone-desktop/` (reference only, do NOT modify)
- toone monorepo: `/Users/matheusparanhos/Projects/toone/` (reference only, do NOT modify)
