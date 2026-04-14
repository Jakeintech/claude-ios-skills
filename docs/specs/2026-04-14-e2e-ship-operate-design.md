# E2E Ship & Operate — Expanding claude-ios-skills

**Date:** 2026-04-14
**Status:** Approved
**Goal:** Expand the claude-ios-skills plugin from development-only (5 skills) to full end-to-end iOS lifecycle (13 skills) — covering App Store screenshots, icons, metadata, privacy, TestFlight, submission, review response, and version updates.

---

## Problem

The current toolkit covers scaffold through code review, but stops at code-complete. The full iOS lifecycle requires:
- App Store screenshots at multiple device sizes with marketing treatment
- Layered Liquid Glass app icons via IconComposer
- Optimized store listing metadata (description, keywords, promotional text)
- Privacy manifests, nutrition labels, export compliance, age ratings
- TestFlight beta distribution and feedback collection
- Full submission with pre-flight verification
- Rejection response and appeal drafting
- Version update preparation for subsequent releases

These are currently manual, repetitive, and error-prone.

## Architecture

All 8 new skills added to the existing `claude-ios-skills` monolith plugin. Same install, same repo.

### New Dependencies

**`asc` CLI (App Store Connect)**
- Install: `brew install asc`
- Auth: App Store Connect API key (issuer ID, key ID, .p8 file)
- 80+ command groups: metadata, screenshots, builds, TestFlight, submissions, analytics
- First-time setup guided by the skills that need it

**Computer-use MCP (already available)**
- Used for: IconComposer automation, App Store Connect browser fallback
- Fallback for App Store Connect tabs the API doesn't cover (Nominations, some Growth & Marketing)

**Existing MCPs (already installed):**
- XcodeBuildMCP — archiving, building
- iOS Simulator MCP — screenshot capture
- Apple Xcode MCP — project file sync

### Updated Install Script

The install script adds:
```bash
# Check for asc CLI
which asc || echo "Install asc: brew install asc"

# Directories for generated assets
# (created per-project by skills, not globally)
```

No new MCP servers needed — `asc` is a CLI tool, not an MCP server.

---

## New Skill 1: `ios-screenshots`

**Invocation:** `/ios-screenshots` (user-invoked)

### Multi-Stage Pipeline

**Stage 1: Raw Capture**
- Auto-detect supported platforms from `project.yml` targets
- Boot simulators for each required device class:
  - iPhone 6.7" (1290x2796) — required
  - iPhone 6.1" (1179x2556) — recommended
  - iPad 13" (2064x2752) — required if iPad supported
  - iPad 11" (1668x2388) — recommended if iPad supported
  - Apple Watch Ultra (410x502) — required if watchOS supported
  - Apple Watch Series (396x484) — recommended if watchOS supported
- Navigate to each key screen (reads brand book "key screens" list from `docs/product-vision/00-product-bounds.md`)
- Capture raw PNGs via iOS Simulator MCP
- Store in `screenshots/raw/{device}/{screen-name}.png`

**Stage 2: Framed**
- Add device bezels/frames around raw captures
- Match Apple's marketing device frame style
- Store in `screenshots/framed/{device}/{screen-name}.png`

**Stage 3: Marketing Shots**
- Pull from brand book: color palette, typography, tone of voice
- Add text captions above/below framed device
- Apply brand background colors/gradients
- Generate promotional banners and feature graphics
- Store in `screenshots/marketing/{device}/{screen-name}.png`

**Stage 4: Upload-Ready**
- Organize final assets by App Store Connect's expected structure
- Validate dimensions match Apple's requirements exactly
- Store in `screenshots/appstore/{device-class}/` ready for `asc` upload

### Storage Structure

```
screenshots/
├── raw/
│   ├── iphone-6.7/
│   ├── iphone-6.1/
│   ├── ipad-13/
│   ├── ipad-11/
│   ├── watch-ultra/
│   └── watch-series/
├── framed/
│   └── (same structure)
├── marketing/
│   └── (same structure)
└── appstore/
    └── (same structure, upload-ready)
```

### User Override

After any stage, the user can go into the `screenshots/` directory, swap out or edit individual images, and resume from the next stage. The skill checks for existing files and uses them instead of regenerating.

---

## New Skill 2: `ios-app-icon`

**Invocation:** `/ios-app-icon` (user-invoked)

### Process

1. **Analyze brand book** — read design identity from `docs/product-vision/00-product-bounds.md` for color palette, icon style, tone
2. **Generate layer assets** — create foreground, background, and optional tint layer PNGs at 1024x1024 base size
3. **Attempt IconComposer automation** — use computer-use MCP to:
   - Open IconComposer app
   - Import layers
   - Configure Liquid Glass properties (fill, opacity, specular highlights)
   - Preview across light/dark appearances
   - Export .icon file
4. **Fallback if computer-use is flaky** — provide prepared layers with step-by-step manual IconComposer instructions
5. **Add to Xcode** — add .icon file to asset catalog, update `project.yml` if needed, verify build
6. **Generate legacy fallback** — for older OS targets, generate flat 1024x1024 AppIcon.png

### Storage

```
assets/
└── icon/
    ├── layers/
    │   ├── foreground.png
    │   ├── background.png
    │   └── tint.png (optional)
    ├── composed/
    │   └── AppIcon.icon
    └── legacy/
        └── AppIcon-1024.png
```

### User Override

Provide your own layer PNGs in `assets/icon/layers/` — the skill skips generation and just composes and integrates.

---

## New Skill 3: `ios-store-listing`

**Invocation:** `/ios-store-listing` (user-invoked)

### Fields Generated

| Field | Source | Constraint |
|-------|--------|-----------|
| App Name | Brand book North Star | 30 chars |
| Subtitle | Brand book + features | 30 chars |
| Promotional Text | Brand book + current version | 170 chars, no review needed |
| Description | Brand book pillars + epics + capabilities | 4000 chars |
| Keywords | Brand book + category analysis | 100 chars comma-separated |
| What's New | Git log since last version tag | 4000 chars |
| Support URL | Project config or user input | Must be reachable |
| Marketing URL | Project config or user input | Must be reachable |
| Copyright | Current year + developer name | Auto-generated |
| Categories | Brand book hard boundaries | Primary + secondary |

### Process

1. Read brand book, CLAUDE.md, and recent git history
2. Generate all fields as `appstore/listing.json`
3. Present to user for review and editing
4. Upload via `asc` CLI to App Store Connect
5. For localization: generate variants for additional languages, stored in `appstore/listing-{locale}.json`

### ASO Optimization

- Keywords cross-reference against app category
- Avoid duplicating words in title/subtitle (Apple indexes those separately)
- Prioritize high-relevance single words over phrases
- Competitive keyword analysis when possible

### User Override

Edit `appstore/listing.json` directly. The skill reads existing values and only regenerates cleared fields.

---

## New Skill 4: `ios-privacy`

**Invocation:** `/ios-privacy` (user-invoked)

### Five Components

**1. Privacy Manifest (`PrivacyInfo.xcprivacy`)**
- Scans Swift files for required-reason API usage:
  - `UserDefaults` → `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1)
  - `FileManager` timestamp access → `NSPrivacyAccessedAPICategoryFileTimestamp` (3B52.1)
  - `ProcessInfo.systemUptime` → `NSPrivacyAccessedAPICategorySystemBootTime` (35F9.1)
  - Disk space queries → `NSPrivacyAccessedAPICategoryDiskSpace` (7D9E.1)
- Detects tracking frameworks, declares `NSPrivacyTracking`
- Generates .xcprivacy file, adds to project via `project.yml`

**2. App Privacy Nutrition Labels**
- Scans code for data collection patterns:
  - HealthKit → Health & Fitness
  - Location services → Location
  - Analytics/crash reporting → Diagnostics
  - User accounts → Contact Info, Identifiers
- Maps to Apple's categories: collected, linked to identity, used for tracking
- Generates answers for App Store Connect privacy form
- Uploads via `asc` CLI or browser fallback via computer-use

**3. Export Compliance**
- Checks for encryption beyond standard HTTPS
- Sets `ITSAppUsesNonExemptEncryption` in Info.plist
- If custom encryption detected, guides through compliance documentation

**4. Age Rating Questionnaire**
- Reads brand book hard boundaries and content description
- Generates answers for Apple's age rating questions
- Stores at `appstore/age-rating.json`
- Uploads via `asc` or browser

**5. App Review Preparation**
- Generates review notes explaining app functionality
- If login required: reminds to create demo account, stores credentials in `appstore/review-notes.json` (gitignored)
- If special hardware/features: writes explanation for reviewers
- Generates routing app coverage file if location-based features

### Storage

```
appstore/
├── listing.json
├── age-rating.json
├── privacy-labels.json
├── review-notes.json          (gitignored)
└── export-compliance.json
```

---

## New Skill 5: `ios-testflight`

**Invocation:** `/ios-testflight` (user-invoked)

### Process

1. **Pre-flight checks:**
   - Build succeeds with release configuration
   - All tests pass
   - Privacy manifest present and valid
   - App icon present (not placeholder)
   - Bundle version/build number incremented from last upload
   - No debug code or development endpoints detected
2. **Archive** — `xcodebuild archive` via XcodeBuildMCP
3. **Export IPA** — export with App Store distribution profile
4. **Upload** — `asc builds upload`
5. **Monitor processing** — poll `asc builds list` until processing completes
6. **Manage testers:**
   - Create/manage beta groups via `asc testflight groups`
   - Add testers by email via `asc testflight testers add`
   - Set "What to Test" notes from git log or user input
7. **Collect feedback** — `asc testflight feedback` for crash reports and tester feedback
8. **Iterate** — if issues found, link back to dev cycle skills

---

## New Skill 6: `ios-submit`

**Invocation:** `/ios-submit` (user-invoked)

### Pre-Submission Checklist (all must pass)

| Check | Method |
|-------|--------|
| Build uploaded and processed | `asc builds list` — status "ready" |
| Screenshots for all required devices | Verify `screenshots/appstore/` completeness |
| App icon not placeholder | Check asset catalog |
| Store listing complete | Validate `appstore/listing.json` fields |
| Privacy manifest present | Check `PrivacyInfo.xcprivacy` in project |
| Privacy labels submitted | `asc` or browser verification |
| Age rating submitted | Verify `appstore/age-rating.json` uploaded |
| Export compliance set | Check Info.plist flag |
| Review notes prepared | Check `appstore/review-notes.json` |
| Version and copyright current | Validate strings |
| Support URL reachable | HTTP HEAD check |
| Categories set | Verify in App Store Connect |

### Submission Flow

1. Run all checks — block on any failure
2. Attach build to version via `asc`
3. Upload screenshots via `asc` if not already uploaded
4. Submit for review via `asc versions submit`
5. Monitor review status — poll via `asc versions list`
6. Notify user on status change (In Review, Approved, Rejected)
7. If rejected: auto-invoke `ios-review-response`

---

## New Skill 7: `ios-review-response`

**Invocation:** Auto on rejection, or `/ios-review-response`

### Process

1. Pull rejection details from App Store Connect via `asc`
2. Categorize rejection:
   - **Metadata issue** — fix and resubmit without new build
   - **Guideline violation** — diagnose code changes, link to dev cycle
   - **Bug/crash** — pull crash logs, invoke `ios-code-review`
3. Draft Resolution Center response — professional, factual, addresses each point
4. If appeal warranted: draft appeal text
5. Prepare resubmission checklist (only changed items)

---

## New Skill 8: `ios-version-update`

**Invocation:** `/ios-version-update` (user-invoked)

### Process

1. **What's New** — scan git log since last version tag, generate release notes
2. **Version bump** — increment version in `project.yml`, regenerate project
3. **Screenshot refresh:**
   - Diff current simulator screenshots against stored `screenshots/raw/`
   - If significant UI changes: re-run `ios-screenshots` pipeline
   - If minor changes: keep existing screenshots
4. **Metadata refresh** — update promotional text if new features warrant it
5. **Re-run compliance** — re-scan privacy manifest, update nutrition labels if data collection changed
6. **Hand off** to `ios-testflight` → `ios-submit` pipeline

---

## Updated Toolkit Overview

### Complete E2E Pipeline

```
/ios-scaffold MyApp
  │
  ├─ DEVELOP
  │   ├─ ios-tdd (auto)           — test-driven implementation
  │   ├─ ios-design-review (auto) — autonomous UI critique
  │   ├─ /ios-iterate "feedback"  — rapid design iteration
  │   └─ /ios-code-review         — pre-commit review
  │
  ├─ PREPARE
  │   ├─ /ios-app-icon            — layered Liquid Glass icon
  │   ├─ /ios-screenshots         — multi-device, multi-stage pipeline
  │   ├─ /ios-store-listing       — metadata, keywords, description
  │   └─ /ios-privacy             — manifest, labels, compliance, ratings
  │
  ├─ SHIP
  │   ├─ /ios-testflight          — archive, upload, beta test
  │   └─ /ios-submit              — verify everything, submit for review
  │
  └─ OPERATE
      ├─ ios-review-response      — handle rejections
      └─ /ios-version-update      — next release (loops back to DEVELOP)
```

### All 13 Skills

| # | Skill | Phase | Trigger |
|---|-------|-------|---------|
| 1 | `ios-scaffold` | Develop | `/ios-scaffold AppName` |
| 2 | `ios-tdd` | Develop | Auto on feature work |
| 3 | `ios-design-review` | Develop | Auto after UI build or `/ios-design-review` |
| 4 | `ios-code-review` | Develop | `/ios-code-review` |
| 5 | `ios-iterate` | Develop | `/ios-iterate "feedback"` |
| 6 | `ios-app-icon` | Prepare | `/ios-app-icon` |
| 7 | `ios-screenshots` | Prepare | `/ios-screenshots` |
| 8 | `ios-store-listing` | Prepare | `/ios-store-listing` |
| 9 | `ios-privacy` | Prepare | `/ios-privacy` |
| 10 | `ios-testflight` | Ship | `/ios-testflight` |
| 11 | `ios-submit` | Ship | `/ios-submit` |
| 12 | `ios-review-response` | Operate | Auto on rejection or `/ios-review-response` |
| 13 | `ios-version-update` | Operate | `/ios-version-update` |

### Dependencies

| Tool | Install | Used By |
|------|---------|---------|
| XcodeBuildMCP | `claude mcp add` (existing) | scaffold, tdd, design-review, code-review, iterate, testflight |
| iOS Simulator MCP | `claude mcp add` (existing) | design-review, iterate, screenshots |
| Apple Xcode MCP | `claude mcp add` (existing) | scaffold (file sync) |
| `asc` CLI | `brew install asc` (new) | store-listing, privacy, testflight, submit, review-response, version-update |
| Computer-use MCP | Already available | app-icon (IconComposer), privacy (browser fallback), submit (browser fallback) |

---

## References

- [asc CLI](https://asccli.sh/) — App Store Connect CLI, 80+ command groups
- [asc Claude Code Skills](https://github.com/rudrankriyam/app-store-connect-cli-skills) — Pre-built skills for asc
- [Apple IconComposer](https://developer.apple.com/icon-composer/) — Layered Liquid Glass icon creation
- [App Store Screenshot Specs](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) — Required sizes and formats
- [Privacy Manifest Docs](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) — PrivacyInfo.xcprivacy format
- [App Store Submission Guide](https://developer.apple.com/app-store/submitting/) — Apple's official submission docs
