# ADR-003: SwiftUI-Only with iOS 17+ Minimum

**Date:** 2026-03-11
**Status:** Accepted
**Deciders:** Toone Mobile Team

---

## Context

Toone Mobile needs a UI framework strategy. The decision has two linked dimensions:

1. **UI framework:** SwiftUI only, UIKit only, or a hybrid.
2. **Minimum iOS version:** This determines which SwiftUI APIs are available.

### UI Framework Options

**SwiftUI only:**
SwiftUI is Apple's declarative UI framework, introduced in iOS 13 and significantly matured through iOS 14-17. A SwiftUI-only approach means no UIKit view controllers, no `UIViewRepresentable` wrappers (except for capabilities with no SwiftUI equivalent), and no storyboards.

**UIKit only:**
UIKit is the imperative UI framework that has been the standard for iOS development since 2008. It is mature, well-documented, and offers complete control over every aspect of the UI. However, it requires significantly more code for equivalent functionality.

**Hybrid (SwiftUI + UIKit):**
Use SwiftUI for most views but fall back to UIKit for complex components (e.g., text editing, collection views with complex layouts). This is common in production apps today. The trade-off is increased complexity from bridging the two frameworks.

### Minimum iOS Version Options

| iOS Version | Key SwiftUI Capabilities |
|-------------|-------------------------|
| iOS 15 | AsyncImage, task modifier, searchable, swipeActions |
| iOS 16 | NavigationStack, Charts, Layout protocol, ViewThatFits |
| iOS 17 | @Observable macro, SwiftData, #Preview macro, scrollPosition, onChange(of:initial:), contentMargins, typesettingLanguage |
| iOS 18 | Mesh gradients, zoom navigation transitions, custom containers |

As of March 2026, iOS adoption data shows:
- iOS 18: ~72% of active devices
- iOS 17: ~21% of active devices
- iOS 16 and earlier: ~7% of active devices

Setting iOS 17 as the minimum covers approximately 93% of active devices.

## Decision

We adopt **SwiftUI-only** with a **minimum deployment target of iOS 17.0**.

### Rationale

**SwiftUI-only because:**

1. **@Observable macro (iOS 17).** The `@Observable` macro replaces `ObservableObject` and `@Published` with a simpler, more performant observation system. Views automatically track which properties they read and re-render only when those properties change. This eliminates the need for `@StateObject`, `@ObservedObject`, and `@EnvironmentObject` -- a significant reduction in boilerplate and cognitive load.

2. **Declarative + MVVM alignment.** SwiftUI's declarative model naturally supports MVVM. Views are pure functions of ViewModel state. This aligns cleanly with our Clean Architecture where ViewModels expose state and views render it.

3. **Codebase simplicity.** A single UI paradigm means one mental model, one set of patterns, one debugging approach. No bridging code between UIKit and SwiftUI. No `UIHostingController` or `UIViewRepresentable` ceremony.

4. **Consistency with Toone Desktop.** Toone Desktop is a native SwiftUI macOS app. Using SwiftUI on iOS allows code sharing for design system components, view modifiers, and potentially some views.

5. **Less code.** SwiftUI requires significantly fewer lines of code for equivalent UI compared to UIKit. For a companion app that primarily displays chat messages, lists, and tree views, SwiftUI's built-in components cover the vast majority of needs.

**iOS 17 minimum because:**

1. **@Observable is transformative.** The difference in code quality between `ObservableObject` (iOS 13+) and `@Observable` (iOS 17+) is substantial. It is the single most important SwiftUI improvement for MVVM architectures.

2. **SwiftData requires iOS 17.** Our offline caching strategy (ADR-004) depends on SwiftData.

3. **93% device coverage.** Dropping iOS 15-16 excludes only ~7% of devices, which are predominantly older hardware (iPhone 8 and earlier).

4. **#Preview macro.** The `#Preview` macro replaces `PreviewProvider` structs with a lightweight syntax, improving developer velocity.

5. **scrollPosition and contentMargins.** Essential for building a performant chat interface with programmatic scroll control.

### Exceptions

The following UIKit usages are permitted where SwiftUI has no native equivalent:

| UIKit API | Usage | Justification |
|-----------|-------|---------------|
| `UIImpactFeedbackGenerator` | Haptic feedback | No SwiftUI equivalent |
| `UIPasteboard` | Clipboard operations | No SwiftUI equivalent |
| `UIApplication.shared` | System-level queries | No SwiftUI equivalent |
| `AVCaptureSession` | QR code scanning | Camera access for pairing |

These are accessed through thin wrapper functions in the Infrastructure layer, not directly from views.

## Consequences

### Positive

- **Dramatically simpler state management.** `@Observable` with `@State` covers all use cases. No need to choose between `@StateObject`, `@ObservedObject`, and `@EnvironmentObject`.
- **Faster development.** Declarative UI, hot-reload previews, and less boilerplate accelerate feature development.
- **Fewer bugs.** Declarative rendering eliminates entire categories of bugs (stale state, forgotten UI updates, view lifecycle mismanagement).
- **Modern Swift patterns.** Full access to Swift Concurrency integration (`task` modifier, `AsyncStream` in views).
- **Desktop code sharing potential.** Design system tokens, view modifiers, and some components can be shared with the macOS desktop app via conditional compilation.

### Negative

- **Limited platform reach.** iOS 17 minimum excludes ~7% of devices. Users on iPhone 8 or earlier cannot use the app.
- **SwiftUI maturity gaps.** Some UIKit capabilities have no SwiftUI equivalent or have subtle behavioral differences:
  - Complex text editing (attributed strings, inline formatting)
  - Advanced keyboard management
  - Fine-grained scroll view control beyond `scrollPosition`
- **SwiftUI bugs.** SwiftUI still has framework-level bugs that can be difficult to work around without dropping to UIKit. These are mitigated by targeting iOS 17+ (the most stable SwiftUI release to date).
- **Smaller talent pool.** Some iOS developers are more comfortable with UIKit. However, SwiftUI adoption has grown substantially and this gap is narrowing.

### Mitigations

- Monitor iOS adoption statistics. If a significant user segment is excluded, consider lowering to iOS 16 with conditional `@Observable` usage.
- For any SwiftUI limitation encountered, evaluate on a case-by-case basis whether a thin `UIViewRepresentable` wrapper is acceptable.
- Invest in comprehensive SwiftUI previews for rapid iteration and visual regression testing.

## Alternatives Considered

| Alternative | Rejection Reason |
|-------------|-----------------|
| UIKit only | Higher development cost; inconsistent with desktop codebase; no `@Observable` |
| SwiftUI + UIKit hybrid | Bridging complexity; two mental models; undermines codebase simplicity |
| iOS 15 minimum | Loses `@Observable`, SwiftData, and modern navigation; significantly more boilerplate |
| iOS 16 minimum | Loses `@Observable` and SwiftData; gains only ~3% more devices |
| iOS 18 minimum | Excludes ~28% of devices; unnecessary -- iOS 17 provides all required APIs |
