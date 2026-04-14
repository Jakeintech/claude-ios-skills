---
name: ios-version-update
description: Prepare the next app version — bump version, generate What's New, refresh screenshots if UI changed, update metadata, re-run compliance, hand off to TestFlight and submission pipeline.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

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
