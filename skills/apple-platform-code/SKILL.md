---
name: apple-platform-code
description: Use when writing, changing, building or testing Swift/SwiftUI code for iOS, iPadOS, macOS, watchOS, tvOS or visionOS — especially when adopting new SDK APIs (Liquid Glass, iOS 27), building for release/TestFlight/App Store, testing on iPhone Duo, or creating simulators.
---

# Apple Platform Code

Two Xcodes, two jobs. Everything you build, test and ship (including iPhone Duo) uses **Xcode.app**, the latest release. **Xcode-beta** serves the newest docs (Xcode MCP) and previews of the next SDK. The App Store rejects beta-built binaries, so a release command that doesn't name its Xcode is a bug.

| Path | Use for |
|---|---|
| `/Applications/Xcode.app` | Builds, tests, iPhone Duo, archives, TestFlight/App Store, merge gate |
| `/Applications/Xcode-beta.app` | Docs (Xcode MCP is pinned to it), preview of the next SDK's APIs |

## Recipe

1. **Unlock Xcode MCP.** Call `XcodeOpenWorkspace` with the project's `.xcodeproj`/`.xcworkspace` before any other Xcode MCP tool (run `xcodegen generate` first if only `project.yml` exists). Until a workspace is opened, every tool, including `DocumentationSearch`, fails with "This agent isn't approved". The first time per folder, Xcode asks the user to approve. Tell them to choose **Always**.
2. **Look up before you write.** For each API you plan to use:
   - Load the matching Apple skill: `xcode-integration:swiftui-whats-new-27`, `swiftui-specialist`, `app-intents-specialist`, `app-resizability` (any layout that must survive iPhone Duo fold/unfold or window resizing), and the accessibility specialists for UI.
   - `DocumentationSearch` for the exact signature and discussion. Quote the doc URI in your summary.
   - Availability: `curl -s https://developer.apple.com/tutorials/data/documentation/<framework>/<symbol>.json` → `metadata.platforms[].introducedAt`. Compare with the target's deployment target in `project.yml`; guard newer APIs with `if #available` / `@available`.
3. **Write the code.** Follow the repo's CLAUDE.md standards.
4. **Check it compiles** with `XcodeRefreshCodeIssuesInFile` (fast) or `BuildProject`. Use `RenderPreview` for SwiftUI views and `xcode-integration:device-interaction` for on-device verification.
5. **Gate on the release Xcode.** Always prefix it:
   ```sh
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme <S> \
     -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build test
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme <S> \
     -configuration Release -destination 'generic/platform=iOS' -archivePath build/<S>.xcarchive archive
   ```
   If `/Applications/Xcode.app` is missing, say the release build is **unverified**. Never fall back to the beta.
6. **iPhone Duo.** Xcode.app has a dedicated Duo runtime (`iOS-27-2-iPhone19-4`). Pin `OS=`, because an "iPhone Duo" simulator can also exist on the beta runtime:
   ```sh
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme <S> \
     -destination 'platform=iOS Simulator,name=iPhone Duo,OS=27.2' build test
   xcrun simctl io <udid> screenshot --display=primary duo.png   # Duo has 2 screens; --display is required
   ```
   Use the beta only to try an API that's newer than Xcode.app. Before merging, that code must still build on Xcode.app.

## Simulators

Device Hub (`DeviceHub.app`, bundled inside Xcode) is the GUI. There's no agent API, so manage simulators with `simctl` under the matching `DEVELOPER_DIR`:

```sh
xcrun simctl list devicetypes | grep -i duo
xcrun simctl list runtimes
xcrun simctl create "iPhone Duo" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo <runtime-id>
xcrun simctl delete unavailable   # after Xcode updates
```

Missing runtime: `xcodebuild -downloadPlatform iOS|watchOS|tvOS|visionOS`. Before deleting any Xcode, runtime or simulator, check running builds (`ps aux | grep -i xcode`) and repo pins (`grep -r DEVELOPER_DIR`).

## Common Mistakes

| Mistake | Fix |
|---|---|
| `xcodebuild archive` with no `DEVELOPER_DIR` | Prefix with Xcode.app (xcode-select may point to the beta) |
| `DocumentationSearch` "not approved" → give up, use memory | Call `XcodeOpenWorkspace` first |
| Writing a new API from memory | `DocumentationSearch` + availability JSON; guard below the deployment target |
| Versioned path in scripts (`Xcode-26.2.app`) | Use `/Applications/Xcode.app` |
| Apple plugin is stale after an Xcode update | `bash ~/Developer/GitHub/claude-ios-skills/scripts/sync-xcode-plugin.sh` |
