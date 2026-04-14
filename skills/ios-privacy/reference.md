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
