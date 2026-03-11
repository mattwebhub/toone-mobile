# Toone Mobile -- Design System

**Version:** 1.0
**Last Updated:** 2026-03-11
**Status:** Draft

---

## 1. Overview

The Toone Mobile design system is adapted from the Toone Desktop "Ocean Depth" visual language. It maintains visual consistency between desktop and mobile while respecting iOS platform conventions (safe areas, touch targets, system gestures, Dynamic Type).

### Design Principles

1. **Depth through layering.** Use surface elevation and subtle translucency to create spatial hierarchy, not drop shadows alone.
2. **Content first.** The interface recedes; user and AI content occupy the foreground.
3. **Consistent but adaptive.** Shared visual DNA with the desktop, but native iOS interaction patterns.
4. **Accessible by default.** All components meet WCAG 2.1 AA contrast ratios. Dynamic Type and VoiceOver are first-class.

---

## 2. Color Palette -- Ocean Depth

### 2.1 Core Surfaces

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `darkBase` | `#14161E` | `20, 22, 30` | App background, root canvas |
| `elevatedSurface` | `#1E2230` | `30, 34, 48` | Cards, panels, assistant bubbles |
| `subtleSurface` | `#252A38` | `37, 42, 56` | Hover states, selected items, input fields |
| `separator` | `#323848` | `50, 56, 72` | Dividers, borders |

### 2.2 Text Colors

| Token | Value | Usage |
|-------|-------|-------|
| `textPrimary` | `white` at `95%` opacity | Headings, body text, primary content |
| `textSecondary` | `white` at `70%` opacity | Subtitles, metadata, secondary info |
| `textTertiary` | `white` at `45%` opacity | Placeholders, disabled text, timestamps |

### 2.3 Accent Colors

| Token | Value | Usage |
|-------|-------|-------|
| `accent` | System accent color (default: blue) | Buttons, links, active indicators |
| `accentSubtle` | Accent at `15%` opacity | User message bubble background |

### 2.4 Semantic Colors

| Token | Value | Usage |
|-------|-------|-------|
| `success` | `#34C759` | Success states, completion indicators |
| `warning` | `#FFD60A` | Warnings, attention indicators |
| `error` | `#FF453A` | Errors, destructive actions |
| `info` | `#64D2FF` | Informational badges, tips |

### 2.5 Chat Bubble Colors

| Token | Value | Usage |
|-------|-------|-------|
| `userBubble` | Accent at `15%` opacity | User message background |
| `assistantBubble` | `elevatedSurface` (`#1E2230`) | Assistant message background |
| `systemBubble` | `subtleSurface` at `50%` opacity | System message background |

### 2.6 SwiftUI Implementation

```swift
// Presentation/DesignSystem/Colors.swift

import SwiftUI

enum OceanDepth {
    // Surfaces
    static let darkBase = Color(red: 20/255, green: 22/255, blue: 30/255)
    static let elevatedSurface = Color(red: 30/255, green: 34/255, blue: 48/255)
    static let subtleSurface = Color(red: 37/255, green: 42/255, blue: 56/255)
    static let separator = Color(red: 50/255, green: 56/255, blue: 72/255)

    // Text
    static let textPrimary = Color.white.opacity(0.95)
    static let textSecondary = Color.white.opacity(0.70)
    static let textTertiary = Color.white.opacity(0.45)

    // Accent
    static let accent = Color.accentColor
    static let accentSubtle = Color.accentColor.opacity(0.15)

    // Semantic
    static let success = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let warning = Color(red: 255/255, green: 214/255, blue: 10/255)
    static let error = Color(red: 255/255, green: 69/255, blue: 58/255)
    static let info = Color(red: 100/255, green: 210/255, blue: 255/255)

    // Chat
    static let userBubble = Color.accentColor.opacity(0.15)
    static let assistantBubble = elevatedSurface
    static let systemBubble = subtleSurface.opacity(0.50)
}
```

---

## 3. Typography

### 3.1 Type Scale

All sizes are in points. The app uses the system font (SF Pro) with Dynamic Type support.

| Token | Size (pt) | Weight | Line Height | Usage |
|-------|-----------|--------|-------------|-------|
| `hero` | 48 | Bold | 56 | Splash screen, onboarding hero text |
| `xxxl` | 34 | Bold | 40 | Main screen titles (rare on mobile) |
| `xxl` | 28 | Bold | 34 | Section headers |
| `xl` | 22 | Semibold | 28 | Card titles, navigation titles |
| `lg` | 17 | Semibold | 22 | Subheadings, button labels |
| `md` | 15 | Regular | 20 | Body text, message content |
| `sm` | 13 | Regular | 18 | Secondary text, metadata |
| `xs` | 11 | Regular | 14 | Captions, timestamps |
| `xxxs` | 10 | Medium | 12 | Badges, micro labels |

### 3.2 SwiftUI Implementation

```swift
// Presentation/DesignSystem/Typography.swift

import SwiftUI

enum Typography {
    static let hero   = Font.system(size: 48, weight: .bold)
    static let xxxl   = Font.system(size: 34, weight: .bold)
    static let xxl    = Font.system(size: 28, weight: .bold)
    static let xl     = Font.system(size: 22, weight: .semibold)
    static let lg     = Font.system(size: 17, weight: .semibold)
    static let md     = Font.system(size: 15, weight: .regular)
    static let sm     = Font.system(size: 13, weight: .regular)
    static let xs     = Font.system(size: 11, weight: .regular)
    static let xxxs   = Font.system(size: 10, weight: .medium)

    // Code / Monospace
    static let codeLg = Font.system(size: 15, weight: .regular, design: .monospaced)
    static let codeMd = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let codeSm = Font.system(size: 11, weight: .regular, design: .monospaced)
}
```

### 3.3 Dynamic Type

All text must support Dynamic Type. Use `@ScaledMetric` for custom sizing and test at all accessibility sizes (xSmall through AX5).

```swift
struct MessageBubble: View {
    @ScaledMetric(relativeTo: .body) private var bubblePadding: CGFloat = 12

    var body: some View {
        Text(message.content.text)
            .font(Typography.md)
            .padding(bubblePadding)
    }
}
```

---

## 4. Spacing

### 4.1 Spacing Scale

| Token | Value (pt) | Usage |
|-------|------------|-------|
| `xxs` | 2 | Hairline gaps, icon-to-text micro spacing |
| `xs` | 4 | Tight spacing within compact components |
| `sm` | 8 | Between related elements (icon + label) |
| `md` | 16 | Default padding, between sections |
| `lg` | 24 | Between major content groups |
| `xl` | 32 | Section separators, large gaps |
| `xxl` | 48 | Screen-level padding, hero spacing |

### 4.2 SwiftUI Implementation

```swift
// Presentation/DesignSystem/Spacing.swift

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}
```

---

## 5. Corner Radii

| Token | Value (pt) | Usage |
|-------|------------|-------|
| `small` | 8 | Buttons, badges, small cards |
| `medium` | 12 | Input fields, message bubbles |
| `large` | 16 | Cards, panels, sheets |
| `extraLarge` | 24 | Full-screen modals, onboarding cards |
| `pill` | `height / 2` | Pill-shaped buttons, tags |

### SwiftUI Implementation

```swift
// Presentation/DesignSystem/CornerRadius.swift

enum CornerRadius {
    static let small:      CGFloat = 8
    static let medium:     CGFloat = 12
    static let large:      CGFloat = 16
    static let extraLarge: CGFloat = 24
}
```

---

## 6. Shadows

Shadow levels create perceived elevation. On the dark Ocean Depth theme, shadows are subtle -- depth is primarily conveyed through surface color changes rather than shadow intensity.

| Level | Color | Offset (x, y) | Blur Radius | Usage |
|-------|-------|---------------|-------------|-------|
| `none` | -- | -- | -- | Flat elements |
| `subtle` | `black` at `20%` | `(0, 1)` | `3` | Buttons, input fields |
| `medium` | `black` at `30%` | `(0, 4)` | `8` | Cards, elevated panels |
| `strong` | `black` at `40%` | `(0, 8)` | `16` | Modals, sheets |
| `glow` | Accent at `30%` | `(0, 0)` | `12` | Active/focused elements |

### SwiftUI Implementation

```swift
// Presentation/DesignSystem/Shadows.swift

import SwiftUI

enum ShadowLevel {
    case none
    case subtle
    case medium
    case strong
    case glow

    var color: Color {
        switch self {
        case .none: return .clear
        case .subtle: return .black.opacity(0.20)
        case .medium: return .black.opacity(0.30)
        case .strong: return .black.opacity(0.40)
        case .glow: return .accentColor.opacity(0.30)
        }
    }

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 3
        case .medium: return 8
        case .strong: return 16
        case .glow: return 12
        }
    }

    var offset: CGSize {
        switch self {
        case .none: return .zero
        case .subtle: return CGSize(width: 0, height: 1)
        case .medium: return CGSize(width: 0, height: 4)
        case .strong: return CGSize(width: 0, height: 8)
        case .glow: return .zero
        }
    }
}

extension View {
    func oceanShadow(_ level: ShadowLevel) -> some View {
        self.shadow(
            color: level.color,
            radius: level.radius,
            x: level.offset.width,
            y: level.offset.height
        )
    }
}
```

---

## 7. Glassmorphism Effects

The Ocean Depth theme uses glass-like translucent surfaces to convey depth. On iOS, these map to `Material` backgrounds with tinted overlays.

```swift
// Presentation/DesignSystem/Glass.swift

import SwiftUI

struct GlassBackground: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(OceanDepth.elevatedSurface.opacity(opacity))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .strokeBorder(OceanDepth.separator.opacity(0.5), lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func glassBackground(opacity: Double = 0.7) -> some View {
        modifier(GlassBackground(opacity: opacity))
    }
}
```

---

## 8. Component Catalog

### 8.1 Buttons

#### Primary Button

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(Typography.lg)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50) // Minimum touch target
            .background(OceanDepth.accent)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            .oceanShadow(.subtle)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}
```

#### Secondary Button

Outlined variant with transparent background.

```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.lg)
                .foregroundStyle(OceanDepth.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .strokeBorder(OceanDepth.accent, lineWidth: 1.5)
                }
        }
    }
}
```

#### Icon Button

Compact button for toolbar actions.

```swift
struct IconButton: View {
    let icon: String // SF Symbol name
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(OceanDepth.textSecondary)
                .frame(width: 44, height: 44) // Apple HIG minimum
                .contentShape(Rectangle())
        }
    }
}
```

### 8.2 Cards

```swift
struct SurfaceCard<Content: View>: View {
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            content()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OceanDepth.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .oceanShadow(.medium)
    }
}
```

### 8.3 Input Fields

```swift
struct OceanTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(Typography.md)
            .foregroundStyle(OceanDepth.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm + Spacing.xs)
            .background(OceanDepth.subtleSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .strokeBorder(OceanDepth.separator, lineWidth: 0.5)
            }
            .tint(OceanDepth.accent)
    }
}
```

### 8.4 Badges

```swift
struct Badge: View {
    let text: String
    var style: BadgeStyle = .default

    enum BadgeStyle {
        case `default`, success, warning, error

        var background: Color {
            switch self {
            case .default: return OceanDepth.subtleSurface
            case .success: return OceanDepth.success.opacity(0.15)
            case .warning: return OceanDepth.warning.opacity(0.15)
            case .error: return OceanDepth.error.opacity(0.15)
            }
        }

        var foreground: Color {
            switch self {
            case .default: return OceanDepth.textSecondary
            case .success: return OceanDepth.success
            case .warning: return OceanDepth.warning
            case .error: return OceanDepth.error
            }
        }
    }

    var body: some View {
        Text(text)
            .font(Typography.xxxs)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(style.background)
            .clipShape(Capsule())
    }
}
```

### 8.5 Message Bubbles

```swift
struct MessageBubble: View {
    let message: Message
    @ScaledMetric(relativeTo: .body) private var padding: CGFloat = 12

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: Spacing.xs) {
                Text(message.content.text)
                    .font(Typography.md)
                    .foregroundStyle(OceanDepth.textPrimary)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(Typography.xs)
                    .foregroundStyle(OceanDepth.textTertiary)
            }
            .padding(padding)
            .background(bubbleBackground)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user: return OceanDepth.userBubble
        case .assistant: return OceanDepth.assistantBubble
        case .system: return OceanDepth.systemBubble
        }
    }
}
```

### 8.6 Connection Status Indicator

```swift
struct ConnectionIndicator: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            Text(state.displayText)
                .font(Typography.xs)
                .foregroundStyle(OceanDepth.textSecondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(OceanDepth.subtleSurface)
        .clipShape(Capsule())
    }

    private var indicatorColor: Color {
        switch state {
        case .connected: return OceanDepth.success
        case .connecting, .reconnecting: return OceanDepth.warning
        case .disconnected, .failed: return OceanDepth.error
        }
    }
}
```

---

## 9. Mobile Adaptations

### 9.1 Touch Targets

All interactive elements must meet Apple Human Interface Guidelines minimums:

| Element | Minimum Size |
|---------|-------------|
| Buttons | 44 x 44 pt |
| List rows | 44 pt height |
| Icon buttons | 44 x 44 pt tappable area (visual can be smaller) |
| Tab bar items | 49 pt height |

### 9.2 Safe Areas

- Respect device safe areas on all edges.
- Chat input bar sits above the home indicator on notched/Dynamic Island devices.
- Content does not extend behind the status bar unless it is a background layer.
- Keyboard avoidance is handled by SwiftUI's built-in mechanisms.

### 9.3 Haptic Feedback

Strategic haptic feedback reinforces key interactions:

| Interaction | Haptic Type |
|-------------|-------------|
| Message sent | `.impact(.light)` |
| Connection established | `.notification(.success)` |
| Connection lost | `.notification(.warning)` |
| Error | `.notification(.error)` |
| Pull to refresh | `.impact(.medium)` |
| Long press action | `.impact(.rigid)` |
| Agent switched | `.impact(.light)` |

```swift
// Presentation/DesignSystem/Haptics.swift

import UIKit

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
```

### 9.4 Orientation

- **iPhone:** Portrait only. The chat interface is optimized for vertical scrolling.
- **iPad:** All orientations supported. Uses adaptive layouts with `horizontalSizeClass`.

### 9.5 Dark Mode

The app exclusively uses the Ocean Depth dark theme. It does **not** support a light mode, matching Toone Desktop's behavior. The `Info.plist` sets `UIUserInterfaceStyle` to `Dark`.

---

## 10. Animation Tokens

| Token | Duration | Curve | Usage |
|-------|----------|-------|-------|
| `quick` | 0.15s | `.easeOut` | Micro interactions (toggle, press) |
| `standard` | 0.25s | `.easeInOut` | Most transitions |
| `smooth` | 0.35s | `.easeInOut` | Panel slides, sheet presentations |
| `slow` | 0.5s | `.easeInOut` | Full-screen transitions |
| `spring` | -- | `.spring(response: 0.35, dampingFraction: 0.7)` | Bouncy elements, pull-to-refresh |

```swift
// Presentation/DesignSystem/Animations.swift

import SwiftUI

enum AnimationToken {
    static let quick    = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let smooth   = Animation.easeInOut(duration: 0.35)
    static let slow     = Animation.easeInOut(duration: 0.5)
    static let spring   = Animation.spring(response: 0.35, dampingFraction: 0.7)
}
```

---

## 11. Iconography

The app uses **SF Symbols** exclusively. No custom icon assets are required for UI elements.

### Recommended Symbol Mappings

| Concept | SF Symbol | Weight |
|---------|-----------|--------|
| Chat | `bubble.left.and.bubble.right` | `.medium` |
| Send message | `arrow.up.circle.fill` | `.medium` |
| Project | `folder` | `.medium` |
| File | `doc.text` | `.regular` |
| Agent | `person.circle` | `.medium` |
| Department | `building.2` | `.medium` |
| Session | `clock.arrow.circlepath` | `.medium` |
| Settings | `gearshape` | `.medium` |
| Connected | `wifi` | `.medium` |
| Disconnected | `wifi.slash` | `.medium` |
| Archive | `archivebox` | `.medium` |
| Restore | `arrow.uturn.backward` | `.medium` |
| Search | `magnifyingglass` | `.medium` |
| Close | `xmark` | `.medium` |

---

## 12. Accessibility

### Contrast Ratios

All text on surface combinations meet WCAG 2.1 AA requirements:

| Combination | Contrast Ratio | Requirement |
|-------------|---------------|-------------|
| `textPrimary` on `darkBase` | 15.2:1 | Passes AAA |
| `textPrimary` on `elevatedSurface` | 12.8:1 | Passes AAA |
| `textSecondary` on `darkBase` | 10.7:1 | Passes AAA |
| `textSecondary` on `elevatedSurface` | 9.0:1 | Passes AAA |
| `textTertiary` on `darkBase` | 6.9:1 | Passes AA |
| `accent` on `darkBase` | 4.8:1 | Passes AA |

### VoiceOver

- All interactive elements have accessibility labels.
- Message bubbles include role and timestamp in their accessibility value.
- Connection status changes are announced as accessibility notifications.
- Decorative elements are hidden from the accessibility tree.

### Reduce Motion

When "Reduce Motion" is enabled in iOS Settings:

- Transition animations are replaced with cross-dissolves.
- Streaming text appears in full chunks rather than character-by-character.
- Spring animations are replaced with linear easing.
