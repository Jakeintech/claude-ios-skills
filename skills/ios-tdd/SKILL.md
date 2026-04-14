---
name: ios-tdd
description: Test-driven development for iOS using Swift Testing framework. Auto-invoked when implementing features. Write failing test first, then implement, then refactor.
user-invocable: false
allowed-tools: Bash(*) Read Edit Write Glob Grep
paths: "**/*.swift"
---

# iOS Test-Driven Development

When implementing any feature or fixing any bug in an iOS project, follow this TDD cycle.

## Framework: Swift Testing

Use Swift Testing exclusively. Never XCTest.

```swift
import Testing
@testable import AppName

struct FeatureTests {
    @Test(.tags(.model))
    func methodName_condition_expectedResult() {
        // Arrange
        let sut = SystemUnderTest()

        // Act
        let result = sut.method()

        // Assert
        #expect(result == expected)
    }
}
```

## The Cycle

### 1. Write the Failing Test

Before writing any implementation code:
- Create a test in the appropriate test file (or create a new test file)
- Name it: `func testMethodName_condition_expectedResult()`
- Tag it: `@Test(.tags(.model))`, `@Test(.tags(.service))`, or `@Test(.tags(.view))`
- Use `#expect` for assertions, `#require` for preconditions that should abort
- The test MUST reference the type or method you're about to create

### 2. Verify It Fails

Run the test and confirm it fails for the RIGHT reason:
- Compilation error because the type/method doesn't exist yet: correct
- Runtime failure because the logic isn't implemented: correct
- Failure for an unrelated reason: investigate before continuing

Build and test command:
```bash
xcodebuild test -project *.xcodeproj -scheme * -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:*Tests
```

### 3. Write Minimal Implementation

Write ONLY enough code to make the failing test pass:
- Do not add extra functionality
- Do not add error handling for cases not covered by tests
- Do not refactor yet
- If you need a new file, add it to the appropriate directory and update project.yml if needed

### 4. Verify It Passes

Run the test again. It must pass. If it doesn't, fix the implementation (not the test) until it does.

### 5. Refactor

Now that tests are green, clean up:
- Extract duplicated code
- Rename for clarity
- Simplify logic
- Run ALL tests after refactoring to confirm nothing broke

### 6. Commit

Commit after each green cycle:
```bash
git add -A
git commit -m "feat: description of what was implemented"
```

## Tag Definitions

Standard tags for all iOS projects:
```swift
extension Tag {
    @Tag static var model: Self      // Data models, state objects
    @Tag static var service: Self    // Services, managers, network
    @Tag static var view: Self       // View logic, view models
    @Tag static var integration: Self // Cross-component tests
}
```

## Testing Patterns for iOS

**Testing @Observable state:**
```swift
@Test(.tags(.model))
func appState_initialState_hasDefaults() {
    let settings = UserSettings(defaults: UserDefaults(suiteName: nil))
    let state = AppState(settings: settings)
    #expect(state.settings === settings)
}
```

**Testing async operations:**
```swift
@Test(.tags(.service))
func service_fetchData_returnsExpected() async throws {
    let service = MyService()
    let result = try await service.fetch()
    #expect(result.count > 0)
}
```

**Testing with #require (precondition that aborts):**
```swift
@Test(.tags(.model))
func collection_firstItem_existsAndMatchesExpected() throws {
    let items = try #require(collection.items.first)
    #expect(items.name == "Expected")
}
```
