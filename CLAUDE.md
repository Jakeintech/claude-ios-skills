## iOS Development Standards

These rules apply to all iOS projects. Non-negotiable.

### Project Setup
- Always use xcodegen (`project.yml`) to manage projects. Never edit .xcodeproj manually.
- iOS 18+ minimum deployment target for new apps. SwiftUI app lifecycle (`@main App`).
- `Shared/` directory for code linked across multiple targets (app, widget, extensions). Models, services, settings, data, and rendering live here.
- App Groups (`group.com.<team>.shared`) for widget/extension data sharing via UserDefaults.
- Swift 6 language mode. Strict concurrency checking enabled.

### SwiftUI & State
- `@Observable` macro for all state objects. Never use `ObservableObject`/`@Published`.
- Central `AppState` injected via `.environment()`. No singletons except `UserSettings.shared` (App Group requirement).
- async/await and actors for concurrency. `@MainActor` on all UI-bound types. No Combine unless bridging legacy APIs.

### Design & UI
- iOS 26 Liquid Glass for navigation-layer elements only (toolbars, tab bars, floating buttons). Never apply glass to content.
- `.glassEffect(.regular)` for standard controls, `.glassEffect(.clear)` for overlays on media. Never glass-on-glass.
- SF Symbols exclusively — never emojis in UI. Correct symbol weight and scale for context.
- Apple Human Interface Guidelines compliance: 44pt minimum touch targets, safe area respect, standard navigation patterns.
- Accessibility from day one: VoiceOver labels on all interactive elements, Dynamic Type support, minimum 4.5:1 contrast ratio.

### Testing
- Swift Testing framework (`@Test`, `#expect`, `#require`). Not XCTest.
- Test naming: `testMethodName_condition_expectedResult()`.
- Tags for categorization: `@Test(.tags(.model))`, `@Test(.tags(.service))`.

### Code Style
- Apple naming conventions: camelCase properties, PascalCase types, descriptive names.
- No external dependencies unless explicitly approved by the user. All Apple frameworks.
- No Combine for new code. No ObservableObject. No XCTest. No UIKit unless wrapping in UIViewRepresentable.
