# Conceive & Develop Expansion — Hive Mind PRD + Domain Skills

**Date:** 2026-04-14
**Status:** Approved
**Goal:** Add 6 new skills (ios-prd, ios-data-model, ios-widget, ios-docs, ios-localize, ios-ci) and enhance 2 existing skills (ios-code-review, ios-design-review) to complete the toolkit from 13 to 19 skills — covering the full lifecycle from raw idea to post-launch operations.

---

## Problem

The current 13 skills cover Develop → Prepare → Ship → Operate, but the **Conceive** phase is completely missing. There's no skill that takes a raw idea and produces a buildable PRD with Apple framework recommendations, data model design, and epic breakdown. Additionally, several iOS-specific domains (widgets, data modeling, documentation, localization, CI/CD) are complex enough to warrant dedicated skills rather than generic "build a feature" knowledge.

## Architecture Overview

### The Hive Mind Pattern

The centerpiece skill (`ios-prd`) uses a multi-agent hive mind architecture: instead of one agent trying to be an expert in everything, it dispatches 5 specialized analyst agents in parallel, each examining the raw idea from their domain. Their independent outputs converge into a unified PRD through synthesis and cross-review.

### Knowledge Layer

Every skill that touches Apple frameworks carries two types of knowledge:
1. **Static reference files** — things that change slowly (Info.plist keys, entitlement names, permission string patterns, privacy API categories)
2. **Live documentation fetching** — instructions to use context7 MCP to pull current Apple docs before making framework decisions

---

## New Skill 1: `ios-prd` — Hive Mind Product Intelligence Engine

**File:** `skills/ios-prd/SKILL.md`
**Supporting files:**
- `skills/ios-prd/patterns.md` — Product pattern detector (15 patterns → Apple integrations)
- `skills/ios-prd/frameworks.md` — Complete Apple framework matrix (permissions, entitlements, privacy, APIs)
- `skills/ios-prd/permissions.md` — Usage description string guide (approved patterns per permission)
- `skills/ios-prd/agents/product-strategist.md` — Analyst prompt
- `skills/ios-prd/agents/platform-engineer.md` — Analyst prompt
- `skills/ios-prd/agents/design-analyst.md` — Analyst prompt
- `skills/ios-prd/agents/data-architect.md` — Analyst prompt
- `skills/ios-prd/agents/growth-compliance.md` — Analyst prompt

**Invocation:** `/ios-prd "Golden Hour: sunrise/sunset widgets, daily photo capture..."`

### Phase 1: Parse & Dispatch

1. Parse the raw idea into a structured brief
2. Dispatch 5 analyst agents in parallel, each receiving:
   - The raw idea + structured brief
   - Their specific analyst prompt (what to analyze, what to output)
   - The `patterns.md` reference
   - The `frameworks.md` reference
   - Instructions to use context7 MCP to fetch current Apple docs for any framework they recommend

**The 5 Analysts:**

*(Each analyst runs as a subagent via the Agent tool. The Product Strategist uses `general-purpose` type for web search access. Others use `general-purpose` for context7 access.)*

**Product Strategist:**
- Identifies: core value proposition, user personas, user journeys, market positioning
- Performs blue ocean analysis: what do competing apps do? What do they ALL miss? Where's the uncontested market space?
- Web searches for existing apps in the category — identifies their strengths, weaknesses, and the gap this app fills
- Feature engineers: "Given the core concept, what adjacent problems could this solve that nobody's addressing?"
- Thinks entrepreneurially: what's the unfair advantage? What makes this defensible? What's the 10x better experience?
- Outputs: North Star statement, hard boundaries (what this app is NOT), soft boundaries, pillars, epic breakdown with build order, competitive landscape summary, blue ocean opportunities, feature engineering recommendations
- Thinks about: retention loops, daily engagement patterns, what makes this app unique, what users would pay for, what creates word-of-mouth

For Golden Hour example, this agent would discover:
- Competing apps just show sunrise/sunset times (commodity data)
- None combine capture + community + personal tracking
- Blue ocean: "your personal golden hour journal" — not a utility, a ritual
- Feature engineering: weather-quality prediction ("tonight's sunset will be spectacular"), streak-based engagement, monthly recap videos auto-generated from daily captures, "golden hour score" based on clarity/clouds/location

**Platform Engineer:**
- Identifies: which Apple frameworks are needed, which platform integrations fit
- Uses `patterns.md` to detect: time-bounded events → Live Activities, Dynamic Island; daily rituals → Shortcuts, Focus Filters; photo capture → EXIF, Spotlight, Share Extension; location → CLMonitor, geofences; etc.
- Outputs: framework matrix with specific APIs (not just "CoreLocation" but "CLMonitor with CLCircularGeographicCondition"), Info.plist keys, entitlements, privacy manifest implications, iOS version requirements
- Fetches current docs via context7 for every recommended framework
- Also outputs: "Considered & Rejected" — integrations that were evaluated but don't fit, with reasoning

**Design Analyst:**
- Identifies: key screens, navigation flow, design identity
- Outputs: screen inventory (which screens, rough purpose), navigation pattern (TabView, NavigationStack, etc.), design identity suggestions (color palette mood, typography feel, icon style), which screens are high-impact vs low-impact (for ios-design-review)
- Thinks about: progressive disclosure, gesture patterns, widget appearances

**Data Architect:**
- Identifies: entities, relationships, persistence strategy
- Outputs: SwiftData `@Model` schema (entity names, properties, relationship types), persistence strategy (on-device only vs CloudKit sync), migration plan for v2, query patterns for common views, photo metadata schema if applicable
- Thinks about: what data syncs, what stays local, conflict resolution strategy

**Growth & Compliance:**
- Identifies: monetization model, permissions needed, App Store compliance, growth loops
- Outputs: pricing strategy (free, freemium, subscription, one-time), which features gate behind premium, every permission with proper usage description string, age rating assessment, export compliance determination, privacy nutrition label draft, growth loop design
- Thinks about: App Store Review Guidelines risks, what could get rejected, what drives organic growth (share moments, referral hooks, widget virality), ASO keywords that match the blue ocean positioning
- Feature engineers monetization: what features are naturally premium (not just gated free features)? What creates genuine upgrade motivation?

For Golden Hour example: free tier gets capture + basic widgets, premium gets monthly recap video generation, weather-quality predictions, unlimited community submissions, advanced EXIF analytics

### Phase 2: Synthesis

The orchestrator (the ios-prd skill itself) merges all 5 outputs:

1. **Deduplicate** — multiple agents may identify the same integration (e.g., both Platform Engineer and Design Analyst mention widgets)
2. **Cross-reference** — Platform Engineer recommends CoreLocation → Growth & Compliance verifies permission strings are specified; Data Architect proposes CloudKit → Platform Engineer confirms CKSyncEngine availability
3. **Resolve conflicts** — Design Analyst wants feature X, Platform Engineer says infeasible in target iOS version → decide and document why
4. **Produce unified draft PRD**

### Phase 3: Cross-Review

Dispatch a review round where each analyst validates the merged PRD:
- Platform Engineer verifies Design Analyst's screen flows are technically feasible
- Growth & Compliance verifies every framework has proper permissions declared
- Product Strategist verifies nothing violates the hard boundaries
- Data Architect verifies the schema supports all the features
- Design Analyst verifies the screen inventory is complete for the feature set

Conflicts from cross-review are resolved and the PRD is finalized.

### Phase 4: Output

Present the complete PRD to the user with:

**Section A: Product Vision**
- North Star
- Hard boundaries, soft boundaries
- Pillars
- Design identity

**Section B: Technical Architecture**
- Framework matrix (framework, API, Info.plist, entitlement, privacy, iOS version)
- Platform integrations (core features + autonomously identified, with reasoning)
- Considered & rejected (with reasoning)

**Section C: Data Model**
- Entity diagram
- SwiftData schema
- Persistence strategy
- Sync strategy (if applicable)

**Section D: Epic Breakdown**
- Numbered epics with build order
- Each epic tagged with: skill handoff (ios-widget, ios-data-model, or ios-tdd), frameworks involved, complexity estimate

**Section E: Compliance**
- All permissions with usage description strings
- Privacy manifest declarations
- Age rating assessment
- Export compliance determination

**Section F: Monetization**
- Pricing model
- Feature gating (free vs premium)

### Phase 5: Handoff

On user approval:
1. Generate `docs/product-vision/00-product-bounds.md` (pre-filled brand book)
2. Generate `docs/product-vision/SDLC-WORKFLOW.md` (pre-filled with epics)
3. Generate data model spec for `ios-data-model` to consume
4. Generate widget spec for `ios-widget` to consume
5. Generate framework/entitlement requirements for `project.yml`
6. Instruct user: "Run `/ios-scaffold AppName` to create the project."

### Reference Files

**`patterns.md` — Product Pattern Detector:**

15 patterns, each mapping to Apple platform integrations:

1. **Time-bounded event** → Live Activities, Dynamic Island, StandBy, Watch complication, Action Button, countdown notifications
2. **Daily ritual / habit** → Shortcuts, Focus Filters, HealthKit correlation, Calendar integration, streaks, daily widgets
3. **Photo/media capture** → EXIF metadata extraction, CoreSpotlight indexing, Share extension, photo widgets, map view, time-lapse/recap generation, PhotosUI PHPicker
4. **Location-dependent** → CLMonitor geofences, timezone awareness, altitude adjustment, weather correlation, map visualization, location-aware notifications
5. **Community/social** → CloudKit public database, content moderation (Vision framework), rate limiting, reporting system, featured curation
6. **Content consumption** → Spotlight search, Handoff, SharePlay, AirDrop sharing, Universal Links
7. **Health/wellness** → HealthKit read/write, mindfulness minutes, activity suggestions, workout sessions
8. **Commerce/premium** → StoreKit 2 (Product, Transaction), subscription management, paywall, feature gating, receipt validation
9. **Personalization/ML** → CoreML on-device models, Create ML training, preference learning, adaptive UI
10. **Real-time data** → WebSocket/URLSession streams, background refresh, push notifications, server-sent events
11. **Calendar/scheduling** → EventKit, date-sensitive content, reminders integration, time zone handling
12. **Audio/music** → MusicKit, AVAudioEngine, Now Playing integration, AirPlay, audio session categories
13. **Messaging/communication** → Messages extension, CallKit, notification actions, rich notifications
14. **Gamification** → achievements, streaks, leaderboards (GameKit optional), progression systems
15. **Accessibility-first** → VoiceOver custom actions, audio descriptions, haptic patterns, assistive touch

Each pattern includes: what signals detect it, which integrations to evaluate, complexity per integration, which epic it typically belongs to.

**`frameworks.md` — Apple Framework Matrix:**

Complete reference for every major Apple framework:

| Framework | Info.plist Keys | Entitlements | Privacy Manifest | Latest API (fetch via context7) | Deprecated (avoid) |
|-----------|----------------|-------------|------------------|---------------------------------|---------------------|
| CoreLocation | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` | — | Location data | `CLMonitor`, `CLLocationUpdate.liveUpdates` | `CLLocationManager.startMonitoring(for:)` |
| PhotosUI | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` | — | Photos/Videos | `PHPickerViewController`, `PhotosPicker` SwiftUI | `UIImagePickerController` |
| HealthKit | `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` | `com.apple.developer.healthkit` | Health & Fitness | `HKHealthStore` async/await, `HKStatisticsQuery` | Completion-handler variants |
| WidgetKit | — | App Group | — | `AppIntentTimelineProvider`, interactive widgets | `IntentTimelineProvider` |
| ActivityKit | — | `com.apple.developer.live-activities` | — | `Activity<Attributes>`, `ActivityContent` | — |
| SwiftData | — | — | — | `@Model`, `ModelContainer`, `#Predicate` | Core Data (for new projects) |
| CloudKit | — | `com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services` | — | `CKSyncEngine` | `NSPersistentCloudKitContainer` |
| StoreKit | — | `com.apple.developer.in-app-payments` | — | `Product`, `Transaction`, `SubscriptionStoreView` | Original StoreKit |
| CoreML | — | — | — | `MLModel`, `CreateML` | — |
| MapKit | `NSLocationWhenInUseUsageDescription` | — | Location | `Map` SwiftUI, `MapContentBuilder` | `MKMapView` wrapping |
| UserNotifications | — | — | — | `UNUserNotificationCenter`, provisional auth | `UILocalNotification` |
| EventKit | `NSCalendarsUsageDescription`, `NSRemindersFullAccessUsageDescription` | — | Calendar/Reminders | `EKEventStore.requestFullAccessToEvents` | `requestAccess(to:)` |
| AVFoundation | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` | — | Camera/Microphone | `AVCaptureSession`, `DiscoverySession` | — |
| MusicKit | `NSAppleMusicUsageDescription` | `com.apple.developer.musickit` | — | `MusicAuthorization`, `MusicCatalogSearchRequest` | — |
| BackgroundTasks | — | Background Modes | — | `BGTaskScheduler`, `BGAppRefreshTask` | `beginBackgroundTask` |
| AppIntents | — | — | — | `AppIntent`, `AppShortcutsProvider`, `AppEntity` | SiriKit Intents |
| CoreSpotlight | — | — | — | `CSSearchableItem`, `CSSearchableIndex` | — |
| Contacts | `NSContactsUsageDescription` | — | Contact Info | `CNContactStore` async | — |
| CoreMotion | `NSMotionUsageDescription` | — | — | `CMMotionManager` | — |
| LocalAuthentication | `NSFaceIDUsageDescription` | — | — | `LAContext`, biometric with fallback | — |
| Vision | — | — | — | `VNRecognizeTextRequest`, `VNClassifyImageRequest` | — |
| NearbyInteraction | `NSNearbyInteractionUsageDescription` | — | — | `NISession` | — |
| GameKit | — | `com.apple.developer.game-center` | — | `GKLocalPlayer`, `GKLeaderboard` | — |
| CallKit | — | — | — | `CXProvider`, `CXCallController` | — |
| PushToTalk | — | `com.apple.developer.push-to-talk` | — | `PTChannelManager` | — |
| WeatherKit | — | `com.apple.developer.weatherkit` | — | `WeatherService.shared.weather(for:)` | — |

Each row also carries: minimum iOS version, typical use case, and instruction to verify via context7.

**`permissions.md` — Usage Description String Guide:**

```
Rules:
- Start with the app name
- State the specific feature that uses the permission
- Explain the user benefit
- Keep under 2 sentences
- No technical jargon

Patterns that get approved:

Camera:
  "{AppName} uses your camera to [specific feature]."
  Example: "GoldenHour uses your camera to capture daily sunrise and sunset photos."

Location When In Use:
  "{AppName} uses your location to [specific feature]."
  Example: "GoldenHour uses your location to calculate accurate sunrise and sunset times for your area."

Location Always:
  "{AppName} uses your location in the background to [specific feature benefiting user]."
  Example: "GoldenHour uses your location in the background to notify you 30 minutes before golden hour begins at your current location."

Photos Read:
  "{AppName} accesses your photo library to [specific feature]."
  Example: "GoldenHour accesses your photo library to display your golden hour captures in monthly recap galleries."

Photos Add:
  "{AppName} saves [what] to your photo library."
  Example: "GoldenHour saves your golden hour photos to your photo library."

Health Read:
  "{AppName} reads your [specific health data] to [specific feature]."
  Example: "GoldenHour reads your activity data to suggest golden hour walks when your step count is low."

Contacts:
  "{AppName} accesses your contacts to [specific feature]."

Calendar:
  "{AppName} reads your calendar to [specific feature]."

Microphone:
  "{AppName} uses your microphone to [specific feature]."

Face ID:
  "{AppName} uses Face ID to [specific feature]."

Motion:
  "{AppName} uses motion data to [specific feature]."

Music:
  "{AppName} accesses Apple Music to [specific feature]."

Nearby Interaction:
  "{AppName} uses nearby interaction to [specific feature]."
```

**context7 integration instructions (embedded in each analyst prompt):**

```
Before recommending any Apple framework:
1. Use context7 resolve-library-id for the framework documentation
2. Query the resolved library for the specific API you plan to recommend
3. Verify the API exists in the target iOS version
4. Check for deprecation notices — never recommend deprecated APIs when modern replacements exist
5. If context7 doesn't have the framework, note this and recommend based on reference files + training data
```

---

## New Skill 2: `ios-data-model`

**File:** `skills/ios-data-model/SKILL.md`
**Supporting file:** `skills/ios-data-model/swiftdata.md`

**Invocation:** `/ios-data-model` (user-invoked, or auto-invoked from ios-prd handoff)

### Process

1. Read data model specification from PRD output (or analyze CLAUDE.md + brand book if no PRD)
2. Fetch current SwiftData documentation via context7 MCP
3. Design `@Model` classes:
   - Entity names, properties with types
   - Relationships (`@Relationship` with delete rules)
   - Indexes for common query patterns
   - `@Attribute(.unique)` for natural keys
   - `@Transient` for computed/cached properties
4. Design `ModelContainer` configuration:
   - Schema versioning
   - Store location (App Group for widget sharing)
   - CloudKit container ID (if sync needed)
5. Design migration strategy:
   - Lightweight migration path for additive changes
   - Custom migration plan for breaking changes
   - Version enum tracking schema evolution
6. Generate test fixtures with realistic sample data
7. Follow TDD: write model tests first, then `@Model` implementations
8. Commit

### Reference: `swiftdata.md`

- `@Model` class patterns with proper relationship types
- `ModelContainer` configuration for App Groups
- `#Predicate` and `FetchDescriptor` query patterns
- CloudKit field type restrictions (no optionals in synced models, no unique constraints with CloudKit)
- Migration patterns: `SchemaMigrationPlan`, `MigrationStage`
- Performance: batch operations, prefetching, denormalization strategies

---

## New Skill 3: `ios-widget`

**File:** `skills/ios-widget/SKILL.md`
**Supporting file:** `skills/ios-widget/widgetkit.md`

**Invocation:** `/ios-widget "countdown to golden hour"` (user-invoked, or from PRD)

### Process

1. Read widget specification from PRD or user description
2. Fetch current WidgetKit documentation via context7 MCP
3. Determine provider type:
   - `AppIntentTimelineProvider` for configurable widgets (user picks which data to show)
   - `TimelineProvider` for static widgets (one configuration)
4. Design timeline entry with required data fields
5. Generate timeline provider with proper refresh strategy:
   - For time-sensitive (countdown): entries at key intervals, `.after(date)` reload policy
   - For data-driven (photo of the day): entry per day, `.atEnd` reload policy
   - Respect refresh budget — document how many reloads the system allows
6. Generate widget views for each size family:
   - `.systemSmall` — single glanceable info
   - `.systemMedium` — more detail or interaction
   - `.systemLarge` — full content
   - `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline` — lock screen
7. Set up App Group data sharing between app and widget:
   - Shared `UserDefaults(suiteName:)` for lightweight data
   - Shared `ModelContainer` for SwiftData access
8. Add interactive elements if iOS 17+: `Button`, `Toggle` via App Intents
9. Test timeline generation logic via TDD
10. Commit

### Reference: `widgetkit.md`

- Size specifications per widget family (points and expected content density)
- Timeline refresh budget constraints (system-managed, ~15-60 reloads/day)
- App Group patterns for data sharing
- `AppIntentTimelineProvider` vs `TimelineProvider` decision tree
- Interactive widget patterns (Button, Toggle, App Intent handlers)
- Live Activities overlap — when to use widget vs Live Activity
- StandBy mode support
- Widget previews for Xcode canvas

---

## New Skill 4: `ios-docs`

**File:** `skills/ios-docs/SKILL.md`

**Invocation:** `/ios-docs` or `/ios-docs architecture` or `/ios-docs changelog`

### What It Generates

**Architecture overview (`docs/architecture.md`):**
- Component diagram (Mermaid syntax, renders on GitHub)
- Data flow between components
- Dependency map (what imports what)
- Target structure diagram (from project.yml)

**API reference (`docs/api-reference.md`):**
- Public types, their purpose, key properties and methods
- Organized by module/directory (Shared/Models, Shared/Services, etc.)
- Generated from source code scanning

**CHANGELOG (`CHANGELOG.md`):**
- Generated from git tags and commit messages
- Grouped by version: Added, Changed, Fixed, Removed
- Follows Keep a Changelog format

**Project CLAUDE.md updates:**
- Detects new components not yet documented in CLAUDE.md
- Proposes additions to Core Components section
- Updates build commands if targets changed

### Drift Detection

Compares current code structure against existing documentation:
- New public types not in API reference → flag
- Removed types still documented → flag
- New directories not in architecture overview → flag
- Reports drift and auto-fixes on confirmation

---

## New Skill 5: `ios-localize`

**File:** `skills/ios-localize/SKILL.md`

**Invocation:** `/ios-localize` or `/ios-localize es ja fr`

### Process

1. **Extract:** Scan all SwiftUI files for hardcoded strings (Text("..."), LocalizedStringKey patterns, alert messages, button labels)
2. **Catalog:** Generate or update `.xcstrings` String Catalog with proper keys
3. **Audit formatting:** Check all date/number/currency formatting uses locale-safe APIs:
   - `Date.FormatStyle` instead of hardcoded date formatters
   - `Decimal.FormatStyle` instead of string interpolation for numbers
   - Flag any `DateFormatter` with hardcoded format strings
4. **Translate (if languages specified):** Generate translated string catalogs for requested locales
5. **Verify RTL:** If RTL language included (Arabic, Hebrew), capture simulator screenshots in that locale via iOS Simulator MCP and check layout
6. **Store metadata:** Generate locale-specific `appstore/listing-{locale}.json` files for App Store listing (ties into `ios-store-listing`)
7. **Integrate:** Add string catalog to project via `project.yml`, run `xcodegen generate`

---

## New Skill 6: `ios-ci`

**File:** `skills/ios-ci/SKILL.md`

**Invocation:** `/ios-ci` (user-invoked, one-time setup)

### Process

1. Detect repo hosting (GitHub, GitLab, Bitbucket)
2. Read `project.yml` for scheme name and test targets
3. Generate CI workflow:

**GitHub Actions (`.github/workflows/build-test.yml`):**
```yaml
name: Build & Test
on:
  push:
    branches: [main, dev, 'epic/**']
  pull_request:
    branches: [main, dev]

jobs:
  build-test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Install xcodegen
        run: brew install xcodegen
      - name: Generate project
        run: xcodegen generate
      - name: Build
        run: xcodebuild build -project *.xcodeproj -scheme $SCHEME -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
      - name: Test
        run: xcodebuild test -project *.xcodeproj -scheme $SCHEME -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Tag-triggered TestFlight upload (`.github/workflows/testflight.yml`):**
- Triggers on `v*` tags
- Archives, exports IPA, uploads via `asc`
- Requires App Store Connect API key as GitHub secret

4. Configure derived data caching for faster builds
5. Add build badge to README
6. Recommend branch protection rules

---

## Enhanced Skill: `ios-code-review`

**New file:** `skills/ios-code-review/performance.md`

Added reference for performance review:
- Main thread blocking: detect synchronous work on `@MainActor` types
- Memory audit: retain cycle patterns in closures, `Task` cancellation
- Photo pipeline: check for unbounded image loading, thumbnail generation
- Widget efficiency: timeline entry count, data fetching in `getTimeline`
- Energy: background task duration, location update frequency, unnecessary network calls
- Instruments tips: which Instruments template to use for common issues

---

## Enhanced Skill: `ios-design-review`

**Updated file:** `skills/ios-design-review/reference.md`

Added deeper accessibility section:
- Full VoiceOver navigation audit (reading order, grouping, custom actions, announcements)
- Accessibility Inspector integration (command to launch, what to check)
- Color blindness simulation (protanopia, deuteranopia, tritanopia)
- Reduced Motion: verify all animations respect `UIAccessibility.isReduceMotionEnabled`
- Reduced Transparency: verify glass effects degrade gracefully
- Minimum text size: no text below 11pt, all text supports Dynamic Type
- Switch Control compatibility

---

## Complete Toolkit: 19 Skills

### By Phase

| Phase | # | Skills |
|-------|---|--------|
| **Conceive** | 1 | `ios-prd` (hive mind) |
| **Develop** | 8 | `ios-scaffold`, `ios-data-model`, `ios-widget`, `ios-tdd`, `ios-design-review`, `ios-code-review`, `ios-iterate`, `ios-docs` |
| **Prepare** | 4 | `ios-app-icon`, `ios-screenshots`, `ios-store-listing`, `ios-privacy` |
| **Ship** | 2 | `ios-testflight`, `ios-submit` |
| **Operate** | 2 | `ios-review-response`, `ios-version-update` |
| **Infrastructure** | 2 | `ios-localize`, `ios-ci` |
| **Total** | **19** | |

### Full E2E Pipeline

```
Raw idea → /ios-prd (hive mind: 5 analysts → synthesis → cross-review → PRD)
  │
  ├─ CONCEIVE outputs: brand book, architecture, data model spec, epics, permissions
  │
  ├─ /ios-scaffold AppName (pre-filled from PRD)
  ├─ /ios-data-model (SwiftData schema from PRD spec)
  ├─ /ios-widget (WidgetKit from PRD spec)
  │
  ├─ DEVELOP: ios-tdd + ios-design-review + ios-iterate + ios-code-review
  │
  ├─ /ios-docs (architecture, API reference, CHANGELOG)
  ├─ /ios-localize (string catalogs, formatting audit)
  ├─ /ios-ci (GitHub Actions pipeline)
  │
  ├─ /ios-app-icon → /ios-screenshots → /ios-store-listing → /ios-privacy
  ├─ /ios-testflight → /ios-submit
  │
  └─ /ios-version-update → loops back to DEVELOP
```

### Dependency Map

| Skill | Depends On | Feeds Into |
|-------|-----------|------------|
| `ios-prd` | Raw idea + context7 | scaffold, data-model, widget, privacy |
| `ios-scaffold` | PRD output | All develop skills |
| `ios-data-model` | PRD data spec | tdd, widget (shared data) |
| `ios-widget` | PRD widget spec, data-model | design-review, screenshots |
| `ios-tdd` | Any feature work | code-review |
| `ios-design-review` | Built UI | iterate |
| `ios-code-review` | Changed code | testflight |
| `ios-iterate` | User feedback | design-review |
| `ios-docs` | Project state | version-update |
| `ios-localize` | Hardcoded strings | store-listing, screenshots |
| `ios-ci` | Project config | testflight |
| `ios-app-icon` | Brand book | submit |
| `ios-screenshots` | Running app | submit |
| `ios-store-listing` | Brand book, git log | submit |
| `ios-privacy` | Code scan | submit |
| `ios-testflight` | Built archive | submit |
| `ios-submit` | All prepare skills | review-response |
| `ios-review-response` | Rejection details | submit (resubmission) |
| `ios-version-update` | Git history | testflight |

---

## References

- [Hive Mind Intelligence Architecture](https://github.com/ruvnet/ruflo/wiki/Hive-Mind-Intelligence) — Multi-agent swarm pattern
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) — Parallel agent orchestration
- [Claude Code Sub-Agent Patterns](https://claudefa.st/blog/guide/agents/sub-agent-best-practices) — Parallel vs sequential dispatch
- [Apple Developer Documentation](https://developer.apple.com/documentation/) — Framework references
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — Compliance requirements
- [context7 MCP](https://github.com/upstash/context7) — Live documentation fetching
