---
name: ios-scaffold
description: Create a new iOS project with production-grade structure, xcodegen, SwiftUI, Swift Testing, App Groups, brand book, and SDLC workflow. Use when starting a new iOS app from scratch.
disable-model-invocation: true
argument-hint: "[AppName]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# iOS Project Scaffold

Create a new iOS project named `$ARGUMENTS` with full production structure.

## Prerequisites Check

Before scaffolding, verify these are installed:
- `xcodegen` — run `which xcodegen` (install: `brew install xcodegen`)
- `node` — run `which node` (needed for MCP servers)

## Steps

1. **Create project directory** at the current working directory: `./$0/`
2. **Copy and customize all templates** from `${CLAUDE_SKILL_DIR}/../../templates/`:
   - Replace all `__APP_NAME__` with the app name (PascalCase)
   - Replace all `__APP_NAME_LOWER__` with the app name (lowercase)
3. **Create directory structure:**
   ```
   $0/
   ├── $0/App/          (AppEntry.swift, AppState.swift)
   ├── $0/Views/        (ContentView moved here from AppEntry)
   ├── $0/Info.plist    (empty, xcodegen fills it)
   ├── $0/$0.entitlements
   ├── Shared/Models/
   ├── Shared/Services/
   ├── Shared/Settings/ (UserSettings.swift)
   ├── Shared/Data/
   ├── Shared/Rendering/
   ├── $0Widget/        (basic widget stub)
   ├── $0Widget/$0Widget.entitlements
   ├── $0Widget/Info.plist
   ├── $0Tests/         (InitialTests.swift)
   ├── $0Tests/Info.plist
   ├── $0UITests/       (empty, ready for UI tests)
   ├── $0UITests/Info.plist
   ├── $0/Assets.xcassets/
   ├── docs/product-vision/
   ├── CLAUDE.md
   ├── project.yml
   └── .mcp.json        (empty stub: {"mcpServers": {}})
   ```
4. **Create a basic widget stub** at `$0Widget/$0Widget.swift`:
   ```swift
   import WidgetKit
   import SwiftUI

   struct SimpleEntry: TimelineEntry {
       let date: Date
   }

   struct Provider: TimelineProvider {
       func placeholder(in context: Context) -> SimpleEntry { SimpleEntry(date: .now) }
       func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) { completion(SimpleEntry(date: .now)) }
       func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
           completion(Timeline(entries: [SimpleEntry(date: .now)], policy: .atEnd))
       }
   }

   struct $0WidgetEntryView: View {
       var entry: SimpleEntry
       var body: some View { Text("Hello") }
   }

   @main
   struct $0Widget: Widget {
       var body: some WidgetConfiguration {
           StaticConfiguration(kind: "com.$0.widget", provider: Provider()) { entry in
               $0WidgetEntryView(entry: entry)
           }
           .configurationDisplayName("$0")
           .supportedFamilies([.systemSmall, .systemMedium])
       }
   }
   ```
5. **Run `xcodegen generate`** in the project directory
6. **Run initial build** to verify: `xcodebuild build -project $0.xcodeproj -scheme $0 -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
7. **Run initial tests** to verify: `xcodebuild test -project $0.xcodeproj -scheme $0 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:$0Tests`
8. **Initialize git** and make first commit:
   ```bash
   git init
   git add -A
   git commit -m "init: scaffold $0 with xcodegen, SwiftUI, Swift Testing, App Groups"
   ```
9. **Report to user:** Show the generated structure and remind them to:
   - Fill in `docs/product-vision/00-product-bounds.md` with their app's identity
   - Set their `DEVELOPMENT_TEAM` in `project.yml`
   - Add project-specific MCP servers to `.mcp.json` if needed
