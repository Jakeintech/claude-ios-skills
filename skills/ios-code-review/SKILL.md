---
name: ios-code-review
description: Review iOS code against Swift/SwiftUI best practices. Checks memory management, concurrency safety, @Observable patterns, xcodegen consistency, and runs build + tests. Use before commits or PRs.
disable-model-invocation: true
allowed-tools: Bash(*) Read Glob Grep
---

# iOS Code Review

Review current changes against iOS development standards.

## Process

### 1. Gather Changes

```bash
git diff --name-only HEAD
git diff --cached --name-only
```

Focus only on changed `.swift` files and `project.yml`.

### 2. Check Each Category

Review every changed Swift file for these issues:

**Memory Management:**
- Closures capturing `self` without `[weak self]` where the closure outlives the scope
- Strong reference cycles between objects (delegate patterns without `weak`)
- Tasks not being cancelled in `deinit` or `.onDisappear`

**Concurrency Safety (Swift 6):**
- `@MainActor` on all types that touch UI (Views, AppState, ViewModels)
- No synchronous blocking calls on `@MainActor` types
- `Sendable` conformance on types passed across actor boundaries
- No data races: mutable state protected by actors or proper isolation

**@Observable Patterns:**
- No `ObservableObject` or `@Published` — must use `@Observable`
- No `@ObservedObject` or `@StateObject` — use `@State` for owned, `@Environment` for injected
- `AppState` injected via `.environment()`, not passed as init parameter
- `UserSettings` accessed via `.shared` singleton (App Group requirement)

**SwiftUI Best Practices:**
- No force unwraps (`!`) in view code
- No heavy computation in `body` — derived state should be computed properties or use `.task`
- Proper use of `@State` vs `@Environment` vs `@Binding`
- `.task` instead of `.onAppear` for async work

**xcodegen Consistency:**
- If new files were added, verify they're in directories covered by `project.yml` sources
- If new targets or frameworks needed, `project.yml` must be updated
- Run `xcodegen generate` if project.yml was modified

**Apple HIG Compliance (in view files only):**
- SF Symbols used instead of emojis
- 44pt minimum touch targets
- Dynamic Type support (no hardcoded font sizes without `.dynamicTypeSize` modifier)

### 3. Build & Test

```bash
xcodebuild build -project *.xcodeproj -scheme * -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -project *.xcodeproj -scheme * -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:*Tests
```

### 4. Report

Group findings by severity:

**BLOCKER** — Must fix before commit:
- Data races, memory leaks, crashes, build failures, test failures

**WARNING** — Should fix:
- ObservableObject usage, missing weak self, missing accessibility labels

**SUGGESTION** — Nice to have:
- Naming improvements, minor pattern deviations

Format:
```
[SEVERITY] Category: Description
  File: path/to/file.swift:line
  Fix: what to change
```

If no issues found, report: "Code review passed. Build green, tests green, no issues found."

## Performance Review

For performance-sensitive code (photo processing, widget timelines, background tasks), load the additional checklist from [performance.md](performance.md).
