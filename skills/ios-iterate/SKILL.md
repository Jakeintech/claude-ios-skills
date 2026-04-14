---
name: ios-iterate
description: Rapid design iteration loop. Takes a screenshot, applies your feedback, rebuilds, runs autonomous design review, and shows before/after. Use when you want to refine UI with natural language feedback.
disable-model-invocation: true
argument-hint: "[feedback]"
allowed-tools: Bash(*) Read Edit Write Glob Grep
---

# iOS Design Iteration

Rapidly iterate on the current UI based on user feedback.

## Input

User feedback via `$ARGUMENTS`. Examples:
- "make the tab bar more prominent"
- "increase spacing between cards"
- "the header feels too heavy"
- "add a floating action button"

## Process

### 1. Capture Before State

- Ensure the simulator is running with the app deployed
- Take a screenshot of the CURRENT state — this is the "before"
- Save or note the screenshot for comparison

### 2. Identify Files to Change

Based on the feedback:
- Find the relevant SwiftUI view files (use Grep/Glob to locate)
- Read the current implementation
- Identify specific changes needed to address the feedback

### 3. Apply Changes

- Edit the SwiftUI files to implement the feedback
- Keep changes minimal and focused on the feedback
- Maintain existing patterns and conventions

### 4. Rebuild & Re-screenshot

- Build the app: `xcodebuild build -project *.xcodeproj -scheme * -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- If build fails, fix compilation errors and rebuild
- Take a new screenshot — this is the "after"

### 5. Autonomous Design Review

Invoke the ios-design-review skill on the result:
- If it finds issues, apply fixes and re-screenshot
- Loop up to 3 times
- If still failing after 3 iterations, stop and report to user

### 6. Present Results

Show the user:
- What feedback was applied
- What files were changed
- The before and after screenshots
- Any design review findings that were auto-fixed
- Any remaining issues that need user input
