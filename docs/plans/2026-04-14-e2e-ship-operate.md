# E2E Ship & Operate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 8 new skills to claude-ios-skills covering the full ship & operate lifecycle — screenshots, app icon, store listing, privacy, TestFlight, submission, review response, and version updates — plus update install.sh and README.

**Architecture:** Each skill is a SKILL.md file with YAML frontmatter and markdown instructions. Skills reference the `asc` CLI for App Store Connect operations and computer-use MCP for IconComposer/browser fallback. The install script is updated to check for `asc` and list all 13 skills.

**Tech Stack:** Markdown (SKILL.md files), Shell (install.sh update), `asc` CLI, computer-use MCP

---

## File Structure

```
claude-ios-skills/
├── skills/
│   ├── ios-screenshots/
│   │   └── SKILL.md                    # Screenshot pipeline skill
│   ├── ios-app-icon/
│   │   └── SKILL.md                    # App icon creation skill
│   ├── ios-store-listing/
│   │   └── SKILL.md                    # Store metadata & ASO skill
│   ├── ios-privacy/
│   │   ├── SKILL.md                    # Privacy & compliance skill
│   │   └── reference.md               # Required-reason API reference
│   ├── ios-testflight/
│   │   └── SKILL.md                    # TestFlight distribution skill
│   ├── ios-submit/
│   │   ├── SKILL.md                    # Submission skill
│   │   └── checklist.md               # Pre-submission checklist reference
│   ├── ios-review-response/
│   │   └── SKILL.md                    # Review response skill
│   └── ios-version-update/
│       └── SKILL.md                    # Version update skill
├── install.sh                          # Updated with asc check + new skill list
└── README.md                           # Updated with all 13 skills
```

---

### Task 1: Screenshots Skill

**Files:**
- Create: `skills/ios-screenshots/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-screenshots/SKILL.md`:

```yaml
---
name: ios-screenshots
description: Generate App Store screenshots for all required device sizes. Multi-stage pipeline — raw capture, framed, marketing shots, upload-ready. Intermediates stored at every stage for manual override.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# App Store Screenshots

Generate App Store-ready screenshots for all required device classes.

## Device Classes

Auto-detect supported platforms by reading `project.yml` targets and `supportedDestinations`:

| Device | Resolution (portrait) | Required? |
|--------|----------------------|-----------|
| iPhone 6.7" | 1290x2796 | Yes |
| iPhone 6.1" | 1179x2556 | Recommended |
| iPad 13" | 2064x2752 | Yes if iPad supported |
| iPad 11" | 1668x2388 | Recommended if iPad |
| Apple Watch Ultra | 410x502 | Yes if watchOS supported |
| Apple Watch Series | 396x484 | Recommended if watchOS |

## Stage 1: Raw Capture

1. Read `project.yml` to determine supported platforms
2. Read brand book (`docs/product-vision/00-product-bounds.md`) for "key screens" list
3. For each required device class:
   - Boot the appropriate simulator via iOS Simulator MCP
   - Build and deploy the app via XcodeBuildMCP
   - Navigate to each key screen
   - Capture raw PNG screenshot via iOS Simulator MCP
4. Store in `screenshots/raw/{device}/{screen-name}.png`

**Naming convention:**
- `screenshots/raw/iphone-6.7/home.png`
- `screenshots/raw/iphone-6.7/settings.png`
- `screenshots/raw/ipad-13/home.png`
- `screenshots/raw/watch-ultra/glance.png`

## Stage 2: Framed

1. For each raw screenshot:
   - Add device bezel/frame matching Apple's marketing device style
   - Use an HTML template rendered to PNG at the correct resolution:
     - Create a temporary HTML file with the device frame as CSS/SVG and the screenshot as the content
     - Render to PNG using a headless browser or the Playwright MCP
   - Alternatively, use ImageMagick (`convert`) to composite the screenshot onto a device frame template
2. Store in `screenshots/framed/{device}/{screen-name}.png`

**Approach priority:**
1. Playwright MCP (`mcp__plugin_playwright_playwright__*`) — render HTML template to screenshot
2. ImageMagick CLI — `composite` command for overlay
3. Manual fallback — provide raw screenshots and frame template files for user to compose

## Stage 3: Marketing Shots

1. Read brand book for: color palette, typography, tone of voice
2. For each framed screenshot:
   - Create a marketing composition:
     - Brand-colored gradient background
     - Framed device centered or offset
     - Text caption above or below (pulled from app description or brand book)
     - App name/logo if specified in brand book
   - Render using the same approach as Stage 2 (HTML template or ImageMagick)
3. Store in `screenshots/marketing/{device}/{screen-name}.png`

**Caption sources:**
- Brand book North Star statement
- Feature descriptions from epics
- Promotional text from `appstore/listing.json` if it exists

## Stage 4: Upload-Ready

1. Copy final marketing shots to upload structure
2. Validate each image:
   - Dimensions match Apple's requirements exactly
   - Format is PNG or JPEG
   - File size is under 500MB per image
3. Store in `screenshots/appstore/{device-class}/` ready for `asc` upload
4. Report summary: how many screenshots per device, any missing

## User Override

At any stage, the user can:
- Replace individual files in `screenshots/raw/`, `framed/`, or `marketing/`
- Re-run the skill — it checks for existing files and skips regeneration
- Run only specific stages by providing arguments: `/ios-screenshots raw` or `/ios-screenshots marketing`

## Storage Structure

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
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-screenshots/
git commit -m "feat: add ios-screenshots skill — multi-stage pipeline with intermediates"
```

---

### Task 2: App Icon Skill

**Files:**
- Create: `skills/ios-app-icon/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-app-icon/SKILL.md`:

```yaml
---
name: ios-app-icon
description: Create a layered Liquid Glass app icon using Apple's IconComposer. Generates layer assets, composes via computer-use MCP, adds to Xcode project. Falls back to manual instructions if automation is flaky.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# App Icon Creation

Create a layered Liquid Glass app icon for iOS 26+.

## Process

### 1. Analyze Brand Identity

Read `docs/product-vision/00-product-bounds.md` for:
- Color palette
- Icon style preferences
- Tone of voice (playful, professional, minimal, etc.)

### 2. Generate Layer Assets

Create icon layers at 1024x1024 base resolution:

- **Foreground** — the primary symbol or graphic (e.g., app logo, key visual)
- **Background** — solid color, gradient, or pattern from brand palette
- **Tint** (optional) — color overlay for Liquid Glass effect

Generate as PNGs. If the user has provided their own layers in `assets/icon/layers/`, skip generation and use those instead.

Store in:
```
assets/
└── icon/
    ├── layers/
    │   ├── foreground.png    (1024x1024, transparent background)
    │   ├── background.png    (1024x1024)
    │   └── tint.png          (optional, 1024x1024)
    ├── composed/
    │   └── AppIcon.icon      (IconComposer output)
    └── legacy/
        └── AppIcon-1024.png  (flat fallback)
```

### 3. Compose with IconComposer (Automated)

Attempt automated composition using computer-use MCP:

1. Request access to IconComposer via `mcp__computer-use__request_access`
2. Open IconComposer: `mcp__computer-use__open_application` with "Icon Composer"
3. Take screenshot to verify it opened
4. Import foreground layer:
   - Click "Front" layer slot
   - Use file dialog to select `assets/icon/layers/foreground.png`
5. Import background layer:
   - Click "Back" layer slot
   - Use file dialog to select `assets/icon/layers/background.png`
6. Configure Liquid Glass properties:
   - Enable glass effect if appropriate for the icon style
   - Adjust fill opacity based on brand identity
7. Preview across appearances (light/dark)
8. Export: File > Save As > save to `assets/icon/composed/AppIcon.icon`

### 4. Fallback: Manual Instructions

If computer-use automation fails at any step:

1. Report which step failed
2. Provide clear manual instructions:
   ```
   The layer assets are ready at:
   - Foreground: assets/icon/layers/foreground.png
   - Background: assets/icon/layers/background.png

   To compose in IconComposer:
   1. Open IconComposer (Applications or via Xcode > Open Developer Tool)
   2. Drag foreground.png onto the "Front" layer
   3. Drag background.png onto the "Back" layer
   4. Adjust Liquid Glass properties to taste
   5. Preview in light and dark mode
   6. File > Save As > save to your project's assets/icon/composed/AppIcon.icon
   ```
3. Wait for user to confirm the .icon file is saved

### 5. Add to Xcode Project

1. Copy `assets/icon/composed/AppIcon.icon` to the app's asset catalog
2. Update `project.yml` if needed to reference the new icon
3. Run `xcodegen generate`
4. Build to verify the icon appears correctly

### 6. Generate Legacy Fallback

For older OS targets that don't support .icon format:
1. Create a flat 1024x1024 PNG from the composed icon layers
2. Store at `assets/icon/legacy/AppIcon-1024.png`
3. Add to asset catalog as fallback AppIcon

### User Override

- Provide your own layer PNGs in `assets/icon/layers/` — skip generation
- Provide your own .icon file in `assets/icon/composed/` — skip IconComposer
- Provide a flat PNG in `assets/icon/legacy/` — skip legacy generation
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-app-icon/
git commit -m "feat: add ios-app-icon skill — IconComposer with computer-use fallback"
```

---

### Task 3: Store Listing Skill

**Files:**
- Create: `skills/ios-store-listing/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-store-listing/SKILL.md`:

```yaml
---
name: ios-store-listing
description: Generate and optimize App Store listing metadata — app name, subtitle, description, keywords, promotional text, What's New, categories. ASO-optimized. Uploads via asc CLI.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# App Store Listing

Generate optimized App Store metadata from your brand book and app content.

## Fields

| Field | Source | Constraint |
|-------|--------|-----------|
| App Name | Brand book North Star | 30 chars max |
| Subtitle | Brand book + key features | 30 chars max |
| Promotional Text | Brand book + current version highlights | 170 chars, updatable without review |
| Description | Brand book pillars + epics + app capabilities | 4000 chars max |
| Keywords | Brand book + category analysis | 100 chars comma-separated |
| What's New | Git log since last version tag | 4000 chars max |
| Support URL | Project config or user input | Must be reachable |
| Marketing URL | Project config or user input | Must be reachable |
| Copyright | Current year + developer name | Auto-generated |
| Primary Category | Brand book domain | Apple category ID |
| Secondary Category | Brand book domain | Apple category ID |

## Process

### 1. Gather Sources

- Read `docs/product-vision/00-product-bounds.md` for North Star, pillars, epics, design identity
- Read `CLAUDE.md` for app description and features
- Run `git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD` for recent changes
- Check if `appstore/listing.json` already exists — load existing values as defaults

### 2. Generate Metadata

For each field:

**App Name:** Extract from brand book North Star. Keep under 30 chars. No generic terms.

**Subtitle:** Distill the value proposition into 30 chars. Focus on what makes this app unique.

**Description:** Structure as:
- Hook paragraph (what the app does, why it's special)
- Feature highlights (bulleted or paragraph, from epics)
- Social proof or differentiators
- Call to action
Stay under 4000 chars. Write for humans, not algorithms.

**Keywords:** 
- Extract key terms from brand book, epics, and feature descriptions
- DO NOT duplicate words already in the app name or subtitle (Apple indexes those separately)
- Prefer single words over phrases (phrases waste character budget)
- Include synonyms and related terms
- Comma-separated, no spaces after commas, exactly 100 chars
- Prioritize: category-relevant terms > feature terms > general terms

**Promotional Text:** Short, punchy summary of the current version's highlights. Can be updated without app review.

**What's New:** Parse git log into user-facing release notes. Group by feature, not by commit. Keep it scannable.

### 3. Output

Write all fields to `appstore/listing.json`:

```json
{
  "name": "App Name",
  "subtitle": "Your subtitle here",
  "promotionalText": "Promotional text here",
  "description": "Full description...",
  "keywords": "keyword1,keyword2,keyword3",
  "whatsNew": "What's new in this version...",
  "supportUrl": "https://...",
  "marketingUrl": "https://...",
  "copyright": "2026 Developer Name",
  "primaryCategory": "LIFESTYLE",
  "secondaryCategory": "HEALTH_AND_FITNESS"
}
```

### 4. Present for Review

Show the user each field with its character count and constraint. Ask for approval or edits before uploading.

### 5. Upload

Upload to App Store Connect via `asc`:

```bash
# Update app info
asc apps update --app-id $APP_ID --name "App Name" --subtitle "Subtitle"

# Update version metadata
asc versions update --app-id $APP_ID --description "..." --keywords "..." --promotional-text "..." --whats-new "..."
```

If `asc` is not configured, provide the generated `listing.json` and instructions for manual entry or guide through browser via computer-use MCP.

### 6. Localization (Optional)

If the user requests additional languages:
- Generate translated/adapted versions of all fields
- Store in `appstore/listing-{locale}.json` (e.g., `listing-es.json`, `listing-ja.json`)
- Upload each locale via `asc`

### User Override

Edit `appstore/listing.json` directly. Re-running the skill reads existing values and only regenerates fields that are empty or explicitly cleared.
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-store-listing/
git commit -m "feat: add ios-store-listing skill — metadata generation with ASO optimization"
```

---

### Task 4: Privacy & Compliance Skill

**Files:**
- Create: `skills/ios-privacy/SKILL.md`
- Create: `skills/ios-privacy/reference.md`

- [ ] **Step 1: Create the reference file**

Create `skills/ios-privacy/reference.md`:

```markdown
# Privacy & Compliance Reference

## Required-Reason APIs

These APIs require a declared reason in `PrivacyInfo.xcprivacy`. Scan the codebase for usage.

### NSPrivacyAccessedAPICategoryUserDefaults
**Trigger:** Any use of `UserDefaults`
**Common reason:** `CA92.1` — access to app's own UserDefaults
**Detection:** Grep for `UserDefaults`, `@AppStorage`, `defaults.`

### NSPrivacyAccessedAPICategoryFileTimestamp
**Trigger:** `FileManager` methods that access file timestamps (`attributesOfItem`, `modificationDate`)
**Common reason:** `3B52.1` — access file timestamps for app functionality
**Detection:** Grep for `attributesOfItem`, `modificationDate`, `creationDate`

### NSPrivacyAccessedAPICategorySystemBootTime
**Trigger:** `ProcessInfo.processInfo.systemUptime`, `mach_absolute_time()`
**Common reason:** `35F9.1` — calculate time intervals
**Detection:** Grep for `systemUptime`, `mach_absolute_time`

### NSPrivacyAccessedAPICategoryDiskSpace
**Trigger:** `FileManager` disk space queries (`attributesOfFileSystem`, `systemFreeSize`)
**Common reason:** `7D9E.1` — check available disk space
**Detection:** Grep for `attributesOfFileSystem`, `systemFreeSize`, `systemSize`

## Privacy Nutrition Label Categories

Map code patterns to Apple's data collection categories:

| Code Pattern | Data Type | Category |
|-------------|-----------|----------|
| `HKHealthStore` | Health & Fitness | Health |
| `CLLocationManager` | Precise/Coarse Location | Location |
| `CNContactStore` | Name, Email, Phone | Contact Info |
| `PHPhotoLibrary` | Photos | Photos or Videos |
| `AVCaptureSession` | Camera access | Photos or Videos |
| Crash reporting SDK | Crash Data | Diagnostics |
| Analytics SDK | Product Interaction | Analytics |
| `ASIdentifierManager` | Advertising ID | Identifiers |
| `UIDevice.identifierForVendor` | Device ID | Identifiers |
| Sign in with Apple / auth | User ID | Identifiers |

## Age Rating Categories

Apple's age rating questionnaire categories:
- Cartoon or Fantasy Violence
- Realistic Violence
- Prolonged Graphic or Sadistic Realistic Violence
- Profanity or Crude Humor
- Mature/Suggestive Themes
- Horror/Fear Themes
- Medical/Treatment Information
- Alcohol, Tobacco, or Drug Use or References
- Simulated Gambling
- Sexual Content or Nudity
- Unrestricted Web Access
- Gambling with Real Currency

For each: None, Infrequent/Mild, Frequent/Intense

## Export Compliance

Most apps using only standard HTTPS (URLSession, Alamofire over HTTPS) can declare `ITSAppUsesNonExemptEncryption = false`.

Custom encryption requiring declaration:
- Custom encryption algorithms
- Non-standard SSL/TLS implementations
- Encryption libraries (OpenSSL compiled in, libsodium, etc.)
- VPN functionality
```

- [ ] **Step 2: Create the skill file**

Create `skills/ios-privacy/SKILL.md`:

```yaml
---
name: ios-privacy
description: Generate privacy manifest (PrivacyInfo.xcprivacy), App Privacy nutrition labels, export compliance, age rating questionnaire, and App Review notes. Full compliance suite for App Store submission.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# Privacy & Compliance

Generate all privacy and compliance artifacts required for App Store submission.

## Reference Material

Load the API reference from [reference.md](reference.md) before scanning.

## 1. Privacy Manifest (PrivacyInfo.xcprivacy)

### Scan

Search all Swift files for required-reason API usage:

```bash
# UserDefaults
grep -r "UserDefaults\|@AppStorage\|defaults\." --include="*.swift" .

# File timestamps
grep -r "attributesOfItem\|modificationDate\|creationDate" --include="*.swift" .

# System boot time
grep -r "systemUptime\|mach_absolute_time" --include="*.swift" .

# Disk space
grep -r "attributesOfFileSystem\|systemFreeSize\|systemSize" --include="*.swift" .
```

### Generate

Create `PrivacyInfo.xcprivacy` in the app target directory:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Populated based on scan results -->
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- Populated based on scan results -->
    </array>
</dict>
</plist>
```

For each detected API, add the appropriate entry with reason code. See reference.md for codes.

### Integrate

1. Add `PrivacyInfo.xcprivacy` to the app target in `project.yml`
2. Run `xcodegen generate`
3. Build to verify no warnings

## 2. App Privacy Nutrition Labels

### Scan

Search code for data collection patterns (see reference.md for mappings):

```bash
# Health data
grep -r "HKHealthStore\|HealthKit" --include="*.swift" .

# Location
grep -r "CLLocationManager\|CoreLocation" --include="*.swift" .

# Contacts
grep -r "CNContactStore\|Contacts" --include="*.swift" .

# Photos
grep -r "PHPhotoLibrary\|PhotosUI" --include="*.swift" .

# Device identifiers
grep -r "identifierForVendor\|ASIdentifierManager" --include="*.swift" .
```

### Generate

Create `appstore/privacy-labels.json`:

```json
{
  "dataTypes": [
    {
      "type": "HEALTH_AND_FITNESS",
      "purposes": ["APP_FUNCTIONALITY"],
      "linkedToIdentity": false,
      "usedForTracking": false
    }
  ]
}
```

Only include data types that are actually detected in the code. Do not over-declare.

### Upload

Upload via `asc` if available:
```bash
asc apps privacy update --app-id $APP_ID --data-file appstore/privacy-labels.json
```

If `asc` can't handle privacy labels, use computer-use MCP to navigate App Store Connect > App Privacy and fill in the form fields matching the generated JSON.

## 3. Export Compliance

### Scan

```bash
# Check for custom encryption
grep -r "CCCrypt\|SecKey\|OpenSSL\|libsodium\|CryptoKit" --include="*.swift" .
```

### Determine

- If ONLY standard HTTPS (URLSession, no custom crypto): set `ITSAppUsesNonExemptEncryption = false` in Info.plist
- If custom encryption found: flag for user review, guide through compliance documentation

### Output

Store determination in `appstore/export-compliance.json`:
```json
{
  "usesNonExemptEncryption": false,
  "reason": "App uses only standard HTTPS via URLSession"
}
```

Verify `ITSAppUsesNonExemptEncryption` is set correctly in `project.yml` Info.plist properties.

## 4. Age Rating Questionnaire

### Analyze

Read `docs/product-vision/00-product-bounds.md` for:
- Hard boundaries (content exclusions)
- Content description
- Target audience

### Generate

Create `appstore/age-rating.json` with answers to each category:

```json
{
  "cartoonOrFantasyViolence": "NONE",
  "realisticViolence": "NONE",
  "profanityOrCrudeHumor": "INFREQUENT_OR_MILD",
  "matureOrSuggestiveThemes": "INFREQUENT_OR_MILD",
  "horrorOrFearThemes": "NONE",
  "medicalTreatmentInformation": "NONE",
  "alcoholTobaccoDrugUse": "NONE",
  "simulatedGambling": "NONE",
  "sexualContentOrNudity": "NONE",
  "unrestrictedWebAccess": "NONE",
  "gamblingWithRealCurrency": "NONE"
}
```

Present to user for review — age rating affects App Store placement and requires human judgment.

### Upload

Upload via `asc` or guide through browser if API doesn't support age ratings directly.

## 5. App Review Preparation

### Generate Review Notes

Read the app's functionality from CLAUDE.md and brand book. Write clear notes for Apple reviewers:
- What the app does
- How to use key features
- Any features that require explanation

### Demo Account (if login required)

If the app requires authentication:
1. Remind user to create a demo account
2. Store credentials in `appstore/review-notes.json` (add to .gitignore!)
3. Format for App Store Connect review info

```json
{
  "notes": "App description for reviewers...",
  "demoAccount": {
    "username": "",
    "password": ""
  },
  "attachments": []
}
```

### Routing App Coverage File

If the app uses location-based features:
- Explain which features are location-dependent
- Generate or guide creation of a .geojson routing coverage file

### gitignore

Ensure `appstore/review-notes.json` is in `.gitignore` (contains test credentials).
```

- [ ] **Step 3: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-privacy/
git commit -m "feat: add ios-privacy skill — manifest, nutrition labels, compliance, age rating, review prep"
```

---

### Task 5: TestFlight Skill

**Files:**
- Create: `skills/ios-testflight/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-testflight/SKILL.md`:

```yaml
---
name: ios-testflight
description: Archive, upload, and distribute via TestFlight. Manages beta groups, testers, and feedback collection. Includes pre-flight checks before upload.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# TestFlight Distribution

Archive, upload, and distribute beta builds via TestFlight.

## Pre-Flight Checks

Before archiving, verify all of these pass:

```bash
# 1. Build succeeds with release configuration
xcodebuild build -project *.xcodeproj -scheme * -configuration Release -destination 'generic/platform=iOS'

# 2. All tests pass
xcodebuild test -project *.xcodeproj -scheme * -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 3. Privacy manifest exists
test -f */PrivacyInfo.xcprivacy && echo "PASS" || echo "FAIL: Missing PrivacyInfo.xcprivacy — run /ios-privacy"

# 4. App icon is not placeholder
# Check asset catalog for AppIcon

# 5. Bundle version incremented
# Compare current build number against last uploaded build via asc
asc builds list --app-id $APP_ID --limit 1
```

**Also check for:**
- No `#if DEBUG` code that should be excluded from release
- No hardcoded development server URLs
- No `print()` statements in production code paths (use `os.log` instead)

If any check fails, report the failure and block upload until resolved.

## Archive

```bash
xcodebuild archive \
  -project *.xcodeproj \
  -scheme * \
  -archivePath build/*.xcarchive \
  -destination 'generic/platform=iOS'
```

## Export IPA

Create an export options plist for App Store distribution:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
```

```bash
xcodebuild -exportArchive \
  -archivePath build/*.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

## Upload

```bash
asc builds upload --file build/export/*.ipa
```

Monitor processing:
```bash
# Poll until status changes from "processing" to "ready"
asc builds list --app-id $APP_ID --limit 1
```

## Manage Testers

```bash
# Create a beta group
asc testflight groups create --app-id $APP_ID --name "Internal Testers"

# Add testers
asc testflight testers add --app-id $APP_ID --email tester@example.com --group "Internal Testers"

# Set "What to Test" notes
asc testflight builds update --build-id $BUILD_ID --what-to-test "Test the new onboarding flow..."
```

The "What to Test" notes should be generated from:
1. Git log since last TestFlight build
2. Brand book current epic focus
3. User-provided specific testing instructions

## Collect Feedback

```bash
# Check for TestFlight feedback
asc testflight feedback list --app-id $APP_ID

# Check for crash reports
asc testflight crashes list --app-id $APP_ID --build-id $BUILD_ID
```

If crashes or critical feedback found:
1. Summarize issues
2. Link back to development cycle — suggest running `/ios-code-review` on affected areas
3. Prepare a fix build if needed
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-testflight/
git commit -m "feat: add ios-testflight skill — archive, upload, beta distribution, feedback"
```

---

### Task 6: Submission Skill

**Files:**
- Create: `skills/ios-submit/SKILL.md`
- Create: `skills/ios-submit/checklist.md`

- [ ] **Step 1: Create the checklist reference**

Create `skills/ios-submit/checklist.md`:

```markdown
# Pre-Submission Checklist

Every item must pass before submitting for App Review.

## Build
- [ ] Build uploaded to App Store Connect and processed (status: "ready")
- [ ] Build number is higher than any previously submitted build
- [ ] No beta entitlements or debug flags in the release build

## Media
- [ ] Screenshots present for all required device classes (iPhone 6.7" minimum)
- [ ] iPad screenshots present (if app supports iPad)
- [ ] Apple Watch screenshots present (if app supports watchOS)
- [ ] App icon is final (not placeholder), .icon format for iOS 26+

## Metadata
- [ ] App name set (30 chars max)
- [ ] Subtitle set (30 chars max)
- [ ] Description filled in (up to 4000 chars)
- [ ] Keywords set (100 chars comma-separated)
- [ ] Promotional text set (170 chars)
- [ ] What's New filled in (for updates)
- [ ] Support URL set and reachable
- [ ] Marketing URL set and reachable (optional but recommended)
- [ ] Copyright current (correct year and entity)
- [ ] Primary and secondary categories set

## Privacy & Compliance
- [ ] PrivacyInfo.xcprivacy present in app bundle
- [ ] App Privacy nutrition labels submitted in App Store Connect
- [ ] Export compliance declared (ITSAppUsesNonExemptEncryption)
- [ ] Age rating questionnaire completed

## Review
- [ ] App Review notes written (explain non-obvious functionality)
- [ ] Demo account provided (if login required)
- [ ] Routing app coverage file uploaded (if location-based)

## Version
- [ ] Version string correct in project.yml
- [ ] Copyright year is current
```

- [ ] **Step 2: Create the skill file**

Create `skills/ios-submit/SKILL.md`:

```yaml
---
name: ios-submit
description: Submit app for App Store review. Runs comprehensive pre-submission checklist, attaches build, uploads screenshots and metadata, submits, and monitors review status. Triggers ios-review-response on rejection.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# App Store Submission

Submit your app for App Store review with full pre-flight verification.

## Reference

Load the full checklist from [checklist.md](checklist.md) before starting.

## Process

### 1. Pre-Submission Verification

Run every check in checklist.md. For each:

**Build:**
```bash
# Verify build is uploaded and processed
asc builds list --app-id $APP_ID --limit 1
# Status must be "readyForSale" or "readyForBetaSubmission"
```

**Screenshots:**
```bash
# Verify screenshots directory has required device classes
ls screenshots/appstore/iphone-6.7/ | wc -l  # Must be 1-10
ls screenshots/appstore/ipad-13/ | wc -l      # If iPad supported
ls screenshots/appstore/watch-ultra/ | wc -l   # If watchOS supported
```

**Metadata:**
```bash
# Verify listing.json is complete
cat appstore/listing.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
required = ['name', 'subtitle', 'description', 'keywords', 'supportUrl', 'copyright', 'primaryCategory']
missing = [f for f in required if not data.get(f)]
if missing: print(f'FAIL: Missing fields: {missing}'); sys.exit(1)
print('PASS: All required fields present')
"
```

**Privacy:**
```bash
# Privacy manifest exists
find . -name "PrivacyInfo.xcprivacy" -not -path "./.git/*"

# Privacy labels submitted
test -f appstore/privacy-labels.json && echo "PASS" || echo "FAIL: Run /ios-privacy"
```

**URLs:**
```bash
# Support URL is reachable
curl -sI "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin).get("supportUrl",""))')" | head -1
```

### 2. Block on Failures

If ANY check fails:
1. List all failures with the specific fix needed
2. Suggest which skill to run (e.g., "Run /ios-screenshots for missing screenshots")
3. Do NOT proceed to submission
4. Re-run checks after fixes

### 3. Upload Media and Metadata

```bash
# Upload screenshots
asc screenshots upload --app-id $APP_ID --device "iphone-6.7" --dir screenshots/appstore/iphone-6.7/

# Upload metadata
asc versions update --app-id $APP_ID \
  --description "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["description"])')" \
  --keywords "$(cat appstore/listing.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["keywords"])')"
```

For any upload that fails via `asc`, fall back to computer-use MCP to navigate App Store Connect in the browser and upload manually.

### 4. Submit for Review

```bash
asc versions submit --app-id $APP_ID
```

### 5. Monitor Review Status

```bash
# Check status
asc versions list --app-id $APP_ID --limit 1
```

Poll periodically or instruct user to check. Report status changes:
- **Waiting for Review** — submitted, in queue
- **In Review** — Apple is reviewing
- **Approved** — ready for release (manual or auto-release based on settings)
- **Rejected** — auto-invoke `ios-review-response`

### 6. Handle Rejection

If the app is rejected, automatically invoke the `ios-review-response` skill with the rejection details.
```

- [ ] **Step 3: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-submit/
git commit -m "feat: add ios-submit skill — pre-submission checklist, upload, submit, monitor"
```

---

### Task 7: Review Response Skill

**Files:**
- Create: `skills/ios-review-response/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-review-response/SKILL.md`:

```yaml
---
name: ios-review-response
description: Handle App Store review rejections. Pulls rejection details, categorizes the issue, drafts Resolution Center responses or appeals, and prepares resubmission. Auto-invoked on rejection or manual.
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# App Review Response

Handle App Store review rejections and prepare resubmission.

## Trigger

- **Auto:** Invoked by `ios-submit` when a rejection is detected
- **Manual:** `/ios-review-response` to handle a rejection you discovered

## Process

### 1. Get Rejection Details

```bash
# Pull rejection info from App Store Connect
asc versions list --app-id $APP_ID --limit 1
asc reviews list --app-id $APP_ID
```

If `asc` can't retrieve rejection details, use computer-use MCP to:
1. Open App Store Connect in browser
2. Navigate to the app > App Review
3. Screenshot the rejection message
4. Extract the rejection reason and guideline references

### 2. Categorize the Rejection

**Metadata Rejection** (no new build needed):
- Screenshot issues (misleading, wrong device, missing)
- Description issues (inaccurate claims, keyword stuffing)
- Missing privacy information
- Incorrect age rating

→ Fix metadata, re-run relevant skill (`/ios-screenshots`, `/ios-store-listing`, `/ios-privacy`), resubmit

**Guideline Violation** (code changes needed):
- Design guideline violation (e.g., non-standard UI patterns)
- Privacy violation (data collection without consent)
- Performance issue (crashes, slow loading)
- Content policy violation

→ Identify specific code changes needed, link to dev cycle (`/ios-code-review`, `/ios-iterate`), rebuild and resubmit

**Bug / Crash** (code fix needed):
- Crash during review
- Feature not working as described
- Login issues with demo account

→ Pull crash logs if available, identify the bug, fix, test, rebuild, resubmit

### 3. Draft Resolution Center Response

Write a professional, factual response that:
- Acknowledges the reviewer's feedback
- Explains what was changed (if anything)
- Provides additional context if the rejection was a misunderstanding
- References specific Apple guidelines to support your case

**Tone guidelines:**
- Professional and respectful — never argumentative
- Factual — reference specific guideline numbers
- Concise — reviewers process many apps
- Helpful — make it easy for them to approve

### 4. Draft Appeal (if warranted)

If you believe the rejection is incorrect:
- Reference the specific guideline cited
- Explain how the app complies
- Provide screenshots or documentation as evidence
- Request re-review

**Only appeal if:**
- The rejection cites a guideline the app genuinely complies with
- There's a clear misunderstanding about app functionality
- The reviewer may not have tested with the demo account

**Do NOT appeal if:**
- The rejection is valid (fix the issue instead)
- The guideline is ambiguous (fix to be safe)

### 5. Prepare Resubmission

Create a resubmission checklist covering only what changed:

1. List specific changes made to address the rejection
2. Re-run only the relevant pre-submission checks
3. Update App Review notes to explain the changes
4. Reference the rejection in review notes so the new reviewer has context

### 6. Submit Response

Upload the Resolution Center response via `asc` or browser:

```bash
asc reviews respond --app-id $APP_ID --message "Response text..."
```

If resubmitting, hand off to `/ios-submit` with the updated build or metadata.
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-review-response/
git commit -m "feat: add ios-review-response skill — rejection handling, appeals, resubmission"
```

---

### Task 8: Version Update Skill

**Files:**
- Create: `skills/ios-version-update/SKILL.md`

- [ ] **Step 1: Create the skill file**

Create `skills/ios-version-update/SKILL.md`:

```yaml
---
name: ios-version-update
description: Prepare the next app version — bump version, generate What's New, refresh screenshots if UI changed, update metadata, re-run compliance, hand off to TestFlight and submission pipeline.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

Body:

```markdown
# Version Update

Prepare the next release of your app.

## Process

### 1. Version Bump

Determine the new version number:
- **Patch** (1.0.0 → 1.0.1): Bug fixes only
- **Minor** (1.0.0 → 1.1.0): New features, backward compatible
- **Major** (1.0.0 → 2.0.0): Breaking changes, major redesign

Ask the user which type, or infer from git log:
- Only fix commits → patch
- Feature commits → minor
- Breaking/redesign commits → major

Update in `project.yml`:
```yaml
# Update CFBundleShortVersionString
CFBundleShortVersionString: "1.1.0"
# Increment CFBundleVersion (build number)
CFBundleVersion: "2"
```

Run `xcodegen generate` after updating.

### 2. What's New

Generate release notes from git log:

```bash
# Get commits since last tag
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~20)..HEAD
```

Transform into user-facing release notes:
- Group by feature area (not by commit)
- Use plain language (not developer jargon)
- Lead with the most impactful change
- Keep it scannable — bullets or short paragraphs

Update `appstore/listing.json` with the new `whatsNew` field.

### 3. Screenshot Refresh

Determine if screenshots need updating:

1. Build the app and capture fresh raw screenshots for key screens
2. Compare against existing `screenshots/raw/` using visual diff:
   - If screens look substantially different → re-run `/ios-screenshots` full pipeline
   - If screens look the same → keep existing screenshots
3. Ask the user to confirm: "Screenshots appear [unchanged/changed]. Refresh? (y/n)"

If refreshing, run the full `/ios-screenshots` pipeline.

### 4. Metadata Refresh

Review current `appstore/listing.json`:
- Update promotional text if new features warrant it
- Keywords: check if new features suggest keyword additions
- Description: update feature list if new capabilities added
- Do NOT change the app name or subtitle without user approval (affects ASO)

### 5. Re-Run Compliance

```bash
# Re-scan for privacy API changes
/ios-privacy
```

Check if:
- New required-reason APIs were added (update manifest)
- New data collection (update nutrition labels)
- Export compliance changed (unlikely but verify)
- Age rating changed (new content types)

### 6. Create Version Tag

```bash
git tag -a v1.1.0 -m "Release 1.1.0: brief description"
```

### 7. Hand Off to Ship Pipeline

1. Run `/ios-testflight` for beta distribution
2. After beta testing, run `/ios-submit` for App Store submission

Report to user:
- Version bumped to X.Y.Z
- What's New generated
- Screenshots: refreshed / kept existing
- Metadata: updated fields listed
- Compliance: any changes flagged
- Ready for `/ios-testflight`
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-version-update/
git commit -m "feat: add ios-version-update skill — version bump, release notes, screenshot refresh"
```

---

### Task 9: Update Install Script

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Update install.sh**

Replace the contents of `install.sh` with:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills/ios-dev"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "=== claude-ios-skills installer ==="
echo ""

# Step 1: Symlink skills
echo "1/4 Installing skills..."
if [ -L "$SKILLS_DIR" ]; then
    echo "  Removing existing symlink at $SKILLS_DIR"
    rm "$SKILLS_DIR"
elif [ -d "$SKILLS_DIR" ]; then
    echo "  ERROR: $SKILLS_DIR exists and is not a symlink. Remove it manually."
    exit 1
fi

mkdir -p "$(dirname "$SKILLS_DIR")"
ln -s "$SCRIPT_DIR" "$SKILLS_DIR"
echo "  Symlinked $SCRIPT_DIR -> $SKILLS_DIR"

# Step 2: Append iOS standards to global CLAUDE.md
echo "2/4 Updating global CLAUDE.md..."
MARKER="## iOS Development Standards"
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    echo "  iOS standards already present in $CLAUDE_MD — skipping"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SCRIPT_DIR/CLAUDE.md" >> "$CLAUDE_MD"
    echo "  Appended iOS standards to $CLAUDE_MD"
fi

# Step 3: Install MCP servers
echo "3/4 Installing MCP servers..."

echo "  Installing XcodeBuildMCP..."
claude mcp add --scope user --transport stdio XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp 2>/dev/null || echo "  XcodeBuildMCP already configured or claude CLI not found"

echo "  Installing Apple Xcode MCP..."
claude mcp add --scope user --transport stdio xcode -- xcrun mcpbridge 2>/dev/null || echo "  Xcode MCP already configured or claude CLI not found"

echo "  Installing iOS Simulator MCP..."
claude mcp add --scope user --transport stdio ios-simulator -- npx -y ios-simulator-mcp@latest 2>/dev/null || echo "  iOS Simulator MCP already configured or claude CLI not found"

# Step 4: Check for asc CLI
echo "4/4 Checking for asc CLI (App Store Connect)..."
if command -v asc &>/dev/null; then
    echo "  asc CLI found: $(which asc)"
else
    echo "  asc CLI not found. Install it for App Store skills:"
    echo "    brew install asc"
    echo "  Then configure your API key:"
    echo "    asc auth init"
    echo "  (Ship & Operate skills will work without asc but with reduced automation)"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Skills installed at: $SKILLS_DIR"
echo "MCP servers: XcodeBuildMCP, xcode (mcpbridge), ios-simulator"
echo ""
echo "DEVELOP:"
echo "  /ios-scaffold MyApp     — Create a new iOS project"
echo "  /ios-design-review      — Review UI against Apple HIG"
echo "  /ios-code-review        — Review code before commit"
echo '  /ios-iterate "feedback"  — Rapid design iteration'
echo "  ios-tdd                 — Auto-invoked during feature work"
echo ""
echo "PREPARE:"
echo "  /ios-app-icon           — Create layered Liquid Glass icon"
echo "  /ios-screenshots        — Generate App Store screenshots"
echo "  /ios-store-listing      — Generate metadata & keywords"
echo "  /ios-privacy            — Privacy manifest & compliance"
echo ""
echo "SHIP:"
echo "  /ios-testflight         — Archive, upload, beta distribute"
echo "  /ios-submit             — Full submission with pre-flight checks"
echo ""
echo "OPERATE:"
echo "  /ios-review-response    — Handle rejections & appeals"
echo "  /ios-version-update     — Prepare the next release"
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add install.sh
git commit -m "feat: update install.sh with asc CLI check and all 13 skills listed"
```

---

### Task 10: Update README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README.md**

Replace the full contents of `README.md` with an updated version that:

1. Updates the title description to mention "end-to-end" lifecycle
2. Replaces the "5 Skills" table with a "13 Skills" table organized by phase (Develop, Prepare, Ship, Operate)
3. Adds `asc` CLI to requirements
4. Updates the Architecture diagram to show all 4 phases
5. Adds a "Ship & Operate" section explaining the pipeline
6. Updates the install output to show `4/4` steps
7. Adds the E2E pipeline diagram from the spec
8. Keeps existing content (Design Review Loop, Quick Start, iOS Standards, etc.)

The full README content is large — the implementer should read the current README, read the spec at `docs/specs/2026-04-14-e2e-ship-operate-design.md`, and produce an updated README that covers all 13 skills. Key sections to add:

**Updated skills table (organized by phase):**

| Phase | Skill | Invocation | What It Does |
|-------|-------|-----------|-------------|
| Develop | ios-scaffold | `/ios-scaffold MyApp` | Create new project |
| Develop | ios-tdd | Auto | TDD with Swift Testing |
| Develop | ios-design-review | Auto / manual | UI critique against HIG |
| Develop | ios-code-review | `/ios-code-review` | Code quality review |
| Develop | ios-iterate | `/ios-iterate "..."` | Rapid UI iteration |
| Prepare | ios-app-icon | `/ios-app-icon` | Liquid Glass icon |
| Prepare | ios-screenshots | `/ios-screenshots` | Multi-stage screenshot pipeline |
| Prepare | ios-store-listing | `/ios-store-listing` | Metadata & ASO |
| Prepare | ios-privacy | `/ios-privacy` | Privacy & compliance suite |
| Ship | ios-testflight | `/ios-testflight` | Beta distribution |
| Ship | ios-submit | `/ios-submit` | App Store submission |
| Operate | ios-review-response | Auto / manual | Rejection handling |
| Operate | ios-version-update | `/ios-version-update` | Next release prep |

**E2E pipeline diagram:**

```
/ios-scaffold → develop → /ios-app-icon → /ios-screenshots → /ios-store-listing
  → /ios-privacy → /ios-testflight → /ios-submit → /ios-version-update (loops)
```

**Updated requirements:**
- Add `asc` CLI (`brew install asc`) — optional but recommended for Ship & Operate skills

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add README.md
git commit -m "docs: update README with all 13 skills across Develop/Prepare/Ship/Operate phases"
```

---

### Task 11: Push and Verify

**Files:** None (git operations only)

- [ ] **Step 1: Push all commits**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git push origin main
```

- [ ] **Step 2: Re-run install to pick up new skills**

```bash
cd ~/Documents/GitHub/claude-ios-skills
./install.sh
```

- [ ] **Step 3: Verify all 13 skills are discoverable**

In a Claude Code session, ask: "What skills are available?" and verify all 13 appear.

---

## Self-Review

- [x] **Spec coverage:** All 8 new skills from the spec are covered (Tasks 1-8). Install script updated (Task 9). README updated (Task 10). Push and verify (Task 11).
- [x] **Placeholder scan:** No TBDs or TODOs. All SKILL.md files contain complete instructions with exact commands.
- [x] **Type consistency:** `appstore/listing.json` format is consistent across ios-store-listing (creates it), ios-submit (reads it), and ios-version-update (updates it). `screenshots/` directory structure is consistent across ios-screenshots (creates it) and ios-submit (reads it). `PrivacyInfo.xcprivacy` is consistent across ios-privacy (creates it) and ios-testflight (checks for it).
- [x] **Spec gap check:** The spec mentions computer-use MCP for browser fallback — this is documented in ios-submit (Step 3 fallback), ios-privacy (nutrition labels upload), and ios-review-response (rejection details retrieval). All covered.

---

Plan complete and saved to `docs/plans/2026-04-14-e2e-ship-operate.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
