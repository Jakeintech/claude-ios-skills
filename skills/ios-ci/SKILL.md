---
name: ios-ci
description: Set up CI/CD for your iOS project — GitHub Actions or Xcode Cloud workflows for build, test, and TestFlight upload. One-time setup with branch protection and caching.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# iOS CI — CI/CD Setup

Set up a complete CI/CD pipeline for your iOS project. One-time setup that runs on every push and deploys to TestFlight on version tags.

## Process

### Step 1: Detect Repo Hosting

```bash
git remote get-url origin
```

Map to CI platform:
- `github.com` → GitHub Actions (primary)
- `gitlab.com` → GitLab CI (secondary)
- `bitbucket.org` → Bitbucket Pipelines (secondary)

If GitHub: generate both workflow files. If not GitHub: inform user and generate appropriate config.

### Step 2: Read Project Configuration

```bash
cat project.yml
```

Extract:
- App scheme name (usually the app name)
- Test target names
- Bundle identifier
- App Group identifiers (for widget targets)
- Minimum iOS version

### Step 3: Generate GitHub Actions — Build & Test

Create `.github/workflows/build-test.yml`:

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

      - name: Cache derived data
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-derived-data-${{ hashFiles('**/*.xcodeproj/project.pbxproj', 'project.yml') }}
          restore-keys: |
            ${{ runner.os }}-derived-data-

      - name: Install xcodegen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build
        run: |
          xcodebuild build \
            -project *.xcodeproj \
            -scheme ${{ env.SCHEME }} \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
            CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
        env:
          SCHEME: {SCHEME_NAME}

      - name: Test
        run: |
          xcodebuild test \
            -project *.xcodeproj \
            -scheme ${{ env.SCHEME }} \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -derivedDataPath ~/Library/Developer/Xcode/DerivedData \
            -resultBundlePath TestResults.xcresult \
            CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
        env:
          SCHEME: {SCHEME_NAME}

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: TestResults.xcresult
```

Replace `{SCHEME_NAME}` with the actual scheme name from `project.yml`.

### Step 4: Generate GitHub Actions — TestFlight Upload

Create `.github/workflows/testflight.yml`:

```yaml
name: TestFlight
on:
  push:
    tags:
      - 'v*'

jobs:
  testflight:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Install xcodegen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Set up signing certificate
        uses: apple-actions/import-codesign-certs@v3
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

      - name: Set up provisioning profile
        uses: apple-actions/download-provisioning-profiles@v3
        with:
          bundle-id: ${{ env.BUNDLE_ID }}
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
        env:
          BUNDLE_ID: {BUNDLE_ID}

      - name: Archive
        run: |
          xcodebuild archive \
            -project *.xcodeproj \
            -scheme ${{ env.SCHEME }} \
            -destination 'generic/platform=iOS' \
            -archivePath build/${{ env.SCHEME }}.xcarchive
        env:
          SCHEME: {SCHEME_NAME}

      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath build/${{ env.SCHEME }}.xcarchive \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath build/
        env:
          SCHEME: {SCHEME_NAME}

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/${{ env.SCHEME }}.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

Also create `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>{TEAM_ID}</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

### Step 5: Configure Derived Data Caching

The cache key includes the project hash so it invalidates when targets change:
```
${{ hashFiles('**/*.xcodeproj/project.pbxproj', 'project.yml') }}
```

Typical cache size: 2-4 GB. First build cold, subsequent builds warm (saves ~3-5 minutes).

### Step 6: Required GitHub Secrets

Inform the user exactly which secrets to add at `Settings > Secrets and variables > Actions`:

| Secret | How to Obtain |
|--------|--------------|
| `CERTIFICATES_P12` | Export your distribution certificate from Keychain Access as .p12, base64 encode: `base64 -i Certificates.p12` |
| `CERTIFICATES_P12_PASSWORD` | Password used when exporting the .p12 |
| `APPSTORE_ISSUER_ID` | App Store Connect > Users and Access > Keys > Issuer ID |
| `APPSTORE_KEY_ID` | App Store Connect > Keys > Key ID |
| `APPSTORE_PRIVATE_KEY` | App Store Connect > Keys > Download key (`.p8` file contents) |

### Step 7: Add Build Badge to README

Insert at the top of `README.md`:

```markdown
[![Build & Test](https://github.com/{owner}/{repo}/actions/workflows/build-test.yml/badge.svg)](https://github.com/{owner}/{repo}/actions/workflows/build-test.yml)
```

Replace `{owner}` and `{repo}` with actual values from `git remote get-url origin`.

### Step 8: Recommend Branch Protection

Print instructions for the user to set up in GitHub (`Settings > Branches > Add rule`):

```
Branch: main
Rules to enable:
  ✓ Require status checks to pass before merging
    Required checks: build-test / build-test
  ✓ Require branches to be up to date before merging
  ✓ Restrict who can push to matching branches (optional, for teams)
```

### Step 9: Xcode Cloud Alternative

If the user prefers Xcode Cloud (no secret management required):

Explain the Xcode Cloud setup (UI-based, done in Xcode):
1. `Product > Xcode Cloud > Create Workflow` in Xcode
2. Add start condition: Branch Changes (main, dev)
3. Add build action: Build
4. Add test action: Test (all test targets)
5. Add archive action: Archive (for TestFlight)
6. Add deploy action: TestFlight (select internal group)

Advantages over GitHub Actions:
- No certificate/provisioning management (handled automatically)
- Free for App Store developers (25 compute hours/month)
- Integrated with App Store Connect

Disadvantages:
- Less customizable (no arbitrary shell scripts)
- 25 hours/month limit (GitHub Actions is free for public repos, metered for private)

### Step 10: Commit

```bash
git add .github/workflows/ ExportOptions.plist README.md
git commit -m "feat(ci): add GitHub Actions build/test and TestFlight workflows"
```
