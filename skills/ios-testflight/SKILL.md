---
name: ios-testflight
description: Archive, upload, and distribute via TestFlight. Manages beta groups, testers, and feedback collection. Includes pre-flight checks before upload.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

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
