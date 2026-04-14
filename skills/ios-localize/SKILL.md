---
name: ios-localize
description: Internationalize your iOS app — extract hardcoded strings into String Catalogs, audit date/number formatting for locale safety, generate translations, verify RTL layouts via simulator screenshots. Ties into ios-store-listing for locale-specific metadata.
disable-model-invocation: true
argument-hint: "[locale codes, e.g. es ja fr]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# iOS Localize — Internationalization Specialist

Fully internationalize your iOS app: extract hardcoded strings, audit locale-unsafe formatting, generate translations, and verify RTL layouts.

## Process

### Step 1: Audit Hardcoded Strings

Scan all SwiftUI and Swift files for hardcoded user-facing strings:

**Patterns to detect:**
```swift
// Hardcoded — must extract
Text("Welcome back")
Text("Settings")
.navigationTitle("Profile")
Button("Save Changes") { }
Label("Notifications", systemImage: "bell")
.alert("Are you sure?", ...)
throw UserError("Invalid input")

// Already localized — skip
Text("welcome_back")  // key-based
Text(LocalizedStringKey("Settings"))
NSLocalizedString("profile_title", comment: "...")
String(localized: "notifications_title")
```

Grep patterns:
```bash
# Find Text() with string literals (not keys)
grep -rn 'Text("[A-Z]' --include="*.swift"
grep -rn 'Text("[a-z]' --include="*.swift"
# Find navigationTitle with literals
grep -rn 'navigationTitle("' --include="*.swift"
# Find Button labels
grep -rn 'Button("' --include="*.swift"
```

Report a list of all files + line numbers with hardcoded strings before proceeding.

### Step 2: Extract into String Catalog

Generate or update the `Localizable.xcstrings` String Catalog:

**String catalog format (JSON):**
```json
{
  "sourceLanguage": "en",
  "strings": {
    "welcome_back": {
      "comment": "Greeting shown on home screen after user returns",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Welcome back"
          }
        }
      }
    },
    "items_count %lld": {
      "comment": "Count of items in list",
      "localizations": {
        "en": {
          "variations": {
            "plural": {
              "one": { "stringUnit": { "state": "translated", "value": "%lld item" } },
              "other": { "stringUnit": { "state": "translated", "value": "%lld items" } }
            }
          }
        }
      }
    }
  },
  "version": "1.0"
}
```

**Key naming convention:**
- Use snake_case: `settings_title`, `save_button_label`
- For parameterized strings: `items_count %lld`, `welcome_user %@`
- For plurals: include format specifier in key and use `variations.plural`

**Update source files:** Replace `Text("Welcome back")` with `Text("welcome_back")` using `LocalizedStringKey`.

### Step 3: Audit Locale-Unsafe Formatting

Scan for formatting patterns that break in non-English locales:

**Dates — must use `FormatStyle`:**
```swift
// UNSAFE — always shows English
let formatter = DateFormatter()
formatter.dateFormat = "MMM d, yyyy"
label.text = formatter.string(from: date)

// SAFE — adapts to user's locale
Text(date, format: .dateTime.month(.abbreviated).day().year())
Text(date.formatted(.dateTime.month(.wide).day()))
```

**Numbers — must use `FormatStyle`:**
```swift
// UNSAFE — always uses period decimal separator
let text = "\(price)"
let text = String(format: "%.2f", price)

// SAFE — uses locale's separator (comma in Europe)
Text(price, format: .currency(code: "USD"))
Text(number, format: .number.precision(.fractionLength(2)))
```

**Grep patterns to flag:**
```bash
grep -rn 'dateFormat\s*=' --include="*.swift"
grep -rn 'String(format:' --include="*.swift"
grep -rn 'DateFormatter()' --include="*.swift"
```

Report each finding with the file, line, and suggested replacement.

### Step 4: Translate (if locales specified)

If `$ARGUMENTS` contains locale codes (e.g., `es ja fr ar`):

For each locale, add a localization block to every string in the catalog:

```json
"welcome_back": {
  "localizations": {
    "en": { "stringUnit": { "state": "translated", "value": "Welcome back" } },
    "es": { "stringUnit": { "state": "translated", "value": "Bienvenido de nuevo" } },
    "ja": { "stringUnit": { "state": "translated", "value": "おかえりなさい" } },
    "fr": { "stringUnit": { "state": "translated", "value": "Content de vous revoir" } }
  }
}
```

Generate translations using knowledge of the target locales. Flag strings that are:
- Culturally sensitive (greetings, idioms, humor) — mark as `"state": "needs_review"`
- Highly app-specific or brand names — keep untranslated
- Plurals — ensure all plural categories for the locale are covered (e.g., Arabic has 6 plural forms)

### Step 5: Verify RTL Layouts

If Arabic (`ar`) or Hebrew (`he`) is included in the target locales:

1. Launch iOS Simulator in the target RTL locale:
```bash
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl spawn booted defaults write -g AppleLanguages '["ar"]'
xcrun simctl spawn booted defaults write -g AppleLocale ar_AE
# Then launch the app and take screenshots via simulator
```

2. Check for RTL layout issues:
- Text leading/trailing edges reversed
- HStack children in wrong order (use `HStack` with `environment(\.layoutDirection, .rightToLeft)` in previews)
- Images with directional arrows (use `flipsForRightToLeftLayoutDirection` for SF Symbols)
- Custom drawing code with hardcoded x-offsets

3. Verify SwiftUI handles RTL automatically:
- `HStack` — reverses automatically
- `.leading`/`.trailing` frame alignment — reverses automatically
- `Text` — right-aligned automatically
- `List` — swipe actions flip automatically

Flag any custom layout code that uses hardcoded leading/trailing coordinates.

### Step 6: Generate App Store Locale Files

Create locale-specific listing metadata:
```
appstore/listing-es.json
appstore/listing-ja.json
appstore/listing-fr.json
```

```json
{
  "locale": "es",
  "name": "AppName",
  "subtitle": "Tagline in Spanish",
  "description": "Full App Store description in Spanish...",
  "keywords": "keyword1, keyword2, keyword3",
  "promotional_text": "Current promotional text in Spanish",
  "whats_new": "What's new in this version in Spanish"
}
```

These files feed into `ios-store-listing` for localized App Store submissions.

### Step 7: Integrate with Project

If creating a new String Catalog (not updating existing):

1. Add `Localizable.xcstrings` to the main app target in `project.yml`:
```yaml
sources:
  - path: Resources/Localizable.xcstrings
```

2. Run `xcodegen generate` to update the project

3. Verify the catalog appears in Xcode's localization editor:
```bash
xcodebuild -project *.xcodeproj -importLocalizations -localizationPath /tmp/verify.xcloc
```

### Step 8: Commit

```bash
git add Resources/Localizable.xcstrings appstore/ {modified source files}
git commit -m "feat(i18n): add String Catalog, extract {N} strings, add {locales} translations"
```

## Summary Report

After completing all steps, report:
- Number of hardcoded strings found and extracted
- Number of locale-unsafe formatting patterns fixed
- Locales added with translation count
- RTL issues found (if RTL locale targeted)
- Files modified
