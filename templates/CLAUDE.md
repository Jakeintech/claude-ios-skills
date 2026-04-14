# CLAUDE.md

## Build & Test Commands

```bash
# Regenerate Xcode project (after changing project.yml)
xcodegen generate

# Build the app
xcodebuild build -project __APP_NAME__.xcodeproj -scheme __APP_NAME__ -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run unit tests
xcodebuild test -project __APP_NAME__.xcodeproj -scheme __APP_NAME__ -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:__APP_NAME__Tests

# Run all tests (unit + UI)
xcodebuild test -project __APP_NAME__.xcodeproj -scheme __APP_NAME__ -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Project Management

Uses **xcodegen** (`project.yml`) to generate `__APP_NAME__.xcodeproj`. Never edit the .xcodeproj manually — modify `project.yml` and run `xcodegen generate`.

## Architecture

**SwiftUI iOS app** (iOS 18.0+) with 4 targets: main app, widget extension, unit tests, UI tests. No external dependencies — all Apple frameworks.

### Key Patterns

- **@Observable** state management. `AppState` is the central state container injected via `.environment()`.
- **Shared/** directory linked to main app + widget targets. Models, services, settings, and data live here.
- **App Group** (`group.com.__APP_NAME_LOWER__.shared`) — shared UserDefaults between app and widget.
- **Swift Testing** framework (`@Test`, `#expect`) for all tests.
- **iOS 26 Liquid Glass** design language for navigation elements.

### Core Components

- **`AppState`** (`__APP_NAME__/App/AppState.swift`) — @Observable central state.
- **`UserSettings`** (`Shared/Settings/UserSettings.swift`) — @Observable, persists to App Group UserDefaults.

### Data Layer

_Document your data model here as it grows._

### Testing

Swift Testing framework. Tests in `__APP_NAME__Tests/`.
