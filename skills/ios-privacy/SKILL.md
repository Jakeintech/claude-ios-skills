---
name: ios-privacy
description: Generate privacy manifest (PrivacyInfo.xcprivacy), App Privacy nutrition labels, export compliance, age rating questionnaire, and App Review notes. Full compliance suite for App Store submission.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

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
