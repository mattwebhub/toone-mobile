# Contributing to Toone Mobile

Thank you for your interest in contributing to Toone Mobile. This document provides guidelines and instructions for contributing.

## Architecture

Toone Mobile follows **Clean Architecture** with strict layer separation:

```
Domain (innermost) -> Data -> Presentation -> Infrastructure
```

Dependencies point inward only. The Domain layer has zero framework imports.

### Layer Rules

| Layer | Can Import | Cannot Import |
|-------|-----------|---------------|
| Domain | Foundation types only (Date, UUID, URL) | SwiftUI, UIKit, SwiftData, Infrastructure |
| Data | Domain, Foundation, SwiftData | SwiftUI, UIKit, Presentation |
| Presentation | Domain, SwiftUI | Data (directly), Infrastructure |
| Infrastructure | Foundation, os.log | Domain, Data, Presentation |

### File Organization

- One primary type per file
- Filename matches the primary type name
- Use `// MARK: -` for section organization
- Group related files in feature directories

## Code Style

### Swift Conventions

- Use `guard` for early returns
- Prefer `let` over `var`
- No force unwraps (`!`) except in tests
- No implicitly unwrapped optionals
- Use `async/await` over completion handlers
- Use `AsyncStream` for real-time data flows
- ViewModels are `@Observable @MainActor` classes

### Naming

- Types: PascalCase (`MessageBubble`, `TunnelClient`)
- Functions/properties: camelCase (`sendMessage()`, `isConnected`)
- Protocols: Descriptive noun (`MessageRepository`) or adjective (`Sendable`)
- Test files: `{TypeName}Tests.swift`
- Mock files: `Mock{TypeName}.swift`

### Design System

All UI must use the design system tokens from `Presentation/DesignSystem/`:
- Colors from `OceanDepth` enum
- Typography from `AppTypography` enum
- Spacing from `DesignTokens` enum
- Never use hardcoded colors or font sizes in views

## Development Setup

### Requirements

- Xcode 16+
- iOS 17.0+ deployment target
- Swift 6.0

### Building

```bash
# Generate Xcode project (if using XcodeGen)
xcodegen generate

# Build via command line
xcodebuild -project TooneMobile/TooneMobile.xcodeproj -scheme TooneMobile build

# Run tests
xcodebuild -project TooneMobile/TooneMobile.xcodeproj -scheme TooneMobile test
```

## Pull Request Process

1. Create a feature branch from `main`
2. Write code following the architecture and style guidelines
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit PR with clear description of changes

## Commit Messages

Use conventional commit format:

```
type(scope): description

feat(chat): add message streaming indicator
fix(tunnel): handle reconnection timeout
docs(arch): update tunnel protocol spec
test(domain): add SendMessageUseCase tests
refactor(data): extract message mapping logic
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`, `perf`
