# Apple Framework Matrix

Complete reference for Apple frameworks used in iOS app development. Use this as a starting point — always verify current APIs and deprecation status via context7 before recommending.

## How to Use This File

Before recommending any framework:
1. Use context7 `resolve-library-id` for the framework documentation
2. Query the resolved library for the specific API you plan to recommend
3. Verify the API exists in the target iOS version
4. Check for deprecation notices — never recommend deprecated APIs when modern replacements exist
5. If context7 doesn't have the framework, note this and recommend based on this reference + training data

---

## Framework Matrix

| Framework | Info.plist Keys | Entitlements | Privacy Manifest | Latest API (verify via context7) | Deprecated (avoid) | Min iOS |
|---|---|---|---|---|---|---|
| **CoreLocation** | `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` | — | Location data | `CLMonitor`, `CLLocationUpdate.liveUpdates` | `CLLocationManager.startMonitoring(for:)` (legacy geofencing), `startUpdatingLocation` for continuous use | 17.0 for CLMonitor |
| **PhotosUI** | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` | — | Photos/Videos | `PHPickerViewController`, `PhotosPicker` (SwiftUI) | `UIImagePickerController` | 16.0 for PhotosPicker |
| **HealthKit** | `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` | `com.apple.developer.healthkit` | Health & Fitness | `HKHealthStore` async/await APIs, `HKStatisticsQuery`, `HKStatisticsCollectionQuery` | Completion-handler variants of all HealthKit queries | 16.0 for async |
| **WidgetKit** | — | App Group (`com.apple.security.application-groups`) | — | `AppIntentTimelineProvider`, interactive widgets (`Button`, `Toggle`), `WidgetFamily.accessory*` | `IntentTimelineProvider` (replaced by AppIntentTimelineProvider) | 17.0 for interactive |
| **ActivityKit** | — | `com.apple.developer.live-activities` | — | `Activity<Attributes>`, `ActivityContent`, `ActivityUIDynamicIslandScene` | — | 16.1 |
| **SwiftData** | — | — | — | `@Model`, `ModelContainer`, `ModelConfiguration`, `#Predicate`, `@Query` | Core Data (for new projects — use SwiftData) | 17.0 |
| **CloudKit** | — | `com.apple.developer.icloud-container-identifiers`, `com.apple.developer.icloud-services` | — | `CKSyncEngine` | `NSPersistentCloudKitContainer` (still functional but less flexible) | 17.0 for CKSyncEngine |
| **StoreKit** | — | `com.apple.developer.in-app-payments` | — | `Product`, `Transaction`, `SubscriptionStoreView`, `StoreView`, `ProductView` | Original StoreKit (SK1) — use StoreKit 2 | 17.0 for SubscriptionStoreView |
| **CoreML** | — | — | — | `MLModel`, `MLModelConfiguration`, on-device inference | — | 15.0 |
| **MapKit** | `NSLocationWhenInUseUsageDescription` (if showing user location) | — | Location (if user location shown) | `Map` SwiftUI view, `MapContentBuilder`, `MapCameraPosition`, `Marker`, `Annotation` | `MKMapView` UIKit wrapping for new SwiftUI projects | 17.0 for full SwiftUI Map |
| **UserNotifications** | — | — | — | `UNUserNotificationCenter`, provisional authorization (`UNAuthorizationOptions.provisional`), `UNNotificationContentExtension` | `UILocalNotification` (removed) | 15.0 |
| **EventKit** | `NSCalendarsUsageDescription`, `NSRemindersFullAccessUsageDescription` | — | Calendar events / Reminders | `EKEventStore.requestFullAccessToEvents(completion:)`, `EKEventStore.requestFullAccessToReminders(completion:)` | `EKEventStore.requestAccess(to:completion:)` (deprecated iOS 17) | 17.0 for new API |
| **AVFoundation** | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` | — | Camera, Microphone | `AVCaptureSession`, `AVCaptureDeviceDiscoverySession`, `AVAssetWriter` | — | 15.0 |
| **MusicKit** | `NSAppleMusicUsageDescription` | `com.apple.developer.musickit` | — | `MusicAuthorization`, `MusicCatalogSearchRequest`, `ApplicationMusicPlayer` | — | 15.0 |
| **BackgroundTasks** | `UIBackgroundModes` (for types), `BGTaskSchedulerPermittedIdentifiers` | — | — | `BGTaskScheduler`, `BGAppRefreshTask`, `BGProcessingTask` | `beginBackgroundTask(withName:)` for long tasks | 15.0 |
| **AppIntents** | — | — | — | `AppIntent`, `AppShortcutsProvider`, `AppEntity`, `EntityQuery`, `IntentParameter`, `FocusFilterIntent` | SiriKit Intents (`.intentdefinition` files) | 16.0 |
| **CoreSpotlight** | — | — | — | `CSSearchableItem`, `CSSearchableIndex`, `CSSearchableAttributeSet` | — | 15.0 |
| **Contacts** | `NSContactsUsageDescription` | — | Contact Info | `CNContactStore` with `enumerateContacts(with:)` async patterns | — | 15.0 |
| **CoreMotion** | `NSMotionUsageDescription` | — | Motion & Fitness | `CMMotionManager`, `CMPedometer` | — | 15.0 |
| **LocalAuthentication** | `NSFaceIDUsageDescription` | — | — | `LAContext`, `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, ...)` with fallback to passcode | — | 15.0 |
| **Vision** | — | — | — | `VNRecognizeTextRequest`, `VNClassifyImageRequest`, `VNDetectFaceRectanglesRequest`, `ImageAnalyzer` (VisionKit) | — | 16.0 for VisionKit ImageAnalyzer |
| **NearbyInteraction** | `NSNearbyInteractionUsageDescription` | — | — | `NISession`, `NINearbyPeerConfiguration` | — | 15.0 |
| **GameKit** | — | `com.apple.developer.game-center` | — | `GKLocalPlayer`, `GKLeaderboard`, `GKAchievement`, `GKMatchmaker` | — | 15.0 |
| **CallKit** | — | — | — | `CXProvider`, `CXCallController`, `CXCallUpdate` | — | 15.0 |
| **WeatherKit** | — | `com.apple.developer.weatherkit` | — | `WeatherService.shared.weather(for:)`, `Weather`, `HourWeather`, `DayWeather` | — | 16.0 |
| **CoreHaptics** | — | — | — | `CHHapticEngine`, `CHHapticPattern`, `CHHapticEvent` | `UIImpactFeedbackGenerator` for simple haptics (still fine), CoreHaptics for custom patterns | 13.0 |
| **PushToTalk** | — | `com.apple.developer.push-to-talk` | — | `PTChannelManager` | — | 16.0 |

---

## Info.plist Keys Quick Reference

Keys that require a value before submission. Missing any of these causes immediate App Store rejection.

| Key | Framework | Required When |
|---|---|---|
| `NSCameraUsageDescription` | AVFoundation / PhotosUI | App accesses camera |
| `NSPhotoLibraryUsageDescription` | PhotosUI | App reads from photo library |
| `NSPhotoLibraryAddUsageDescription` | PhotosUI | App saves to photo library (can be separate from read) |
| `NSLocationWhenInUseUsageDescription` | CoreLocation | Any location access while in foreground |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | CoreLocation | Background location access |
| `NSHealthShareUsageDescription` | HealthKit | Reading health data |
| `NSHealthUpdateUsageDescription` | HealthKit | Writing health data |
| `NSContactsUsageDescription` | Contacts | Any contacts access |
| `NSCalendarsUsageDescription` | EventKit | Calendar read/write |
| `NSRemindersFullAccessUsageDescription` | EventKit | Reminders read/write |
| `NSMicrophoneUsageDescription` | AVFoundation | Any microphone access |
| `NSMotionUsageDescription` | CoreMotion | Accelerometer/gyroscope |
| `NSFaceIDUsageDescription` | LocalAuthentication | Face ID authentication |
| `NSAppleMusicUsageDescription` | MusicKit | Apple Music access |
| `NSNearbyInteractionUsageDescription` | NearbyInteraction | UWB ranging |
| `NSBluetoothAlwaysUsageDescription` | CoreBluetooth | Bluetooth (if applicable) |
| `BGTaskSchedulerPermittedIdentifiers` | BackgroundTasks | Background task identifiers (array of strings) |
| `UIBackgroundModes` | BackgroundTasks / AVFoundation | Background execution types |

---

## Entitlements Quick Reference

Entitlements must be configured in the Xcode project AND requested from Apple (some require provisioning profile configuration).

| Entitlement | Framework | Notes |
|---|---|---|
| `com.apple.developer.healthkit` | HealthKit | Requires HealthKit capability in provisioning |
| `com.apple.developer.healthkit.background-delivery` | HealthKit | Background HealthKit updates |
| `com.apple.developer.live-activities` | ActivityKit | Live Activities in Dynamic Island |
| `com.apple.developer.icloud-container-identifiers` | CloudKit | Requires iCloud capability |
| `com.apple.developer.icloud-services` | CloudKit | Values: `CloudKit` and/or `CloudDocuments` |
| `com.apple.developer.in-app-payments` | StoreKit | Merchant IDs for Apple Pay |
| `com.apple.developer.musickit` | MusicKit | Apple Music access |
| `com.apple.developer.game-center` | GameKit | Game Center features |
| `com.apple.developer.weatherkit` | WeatherKit | WeatherKit API access |
| `com.apple.developer.push-to-talk` | PushToTalk | Push-to-talk channel |
| `com.apple.security.application-groups` | WidgetKit / App Groups | Shared container between app and extensions |

---

## Privacy Manifest Implications

Apps using required-reason APIs must include a `PrivacyInfo.xcprivacy` manifest declaring which APIs are used and why.

**Required-reason API categories:**

| API Category | Common Usage | Required Reason Code |
|---|---|---|
| `UserDefaults` | Settings, state persistence | `CA92.1` (app functionality) |
| File timestamp APIs | Checking cache freshness | Various |
| System boot time | Performance measurement | Various |
| Disk space APIs | Storage warnings | Various |
| Active keyboard APIs | Detecting keyboard presence | Various |

**Data collection declaration:**

If your app collects any of the following, declare it in the privacy manifest:
- Location data → declare under `NSPrivacyCollectedDataTypes`
- Health data → declare
- Photos/Videos → declare
- Contact info → declare
- Usage data (analytics) → declare

**Linked vs not linked to identity:** Data linked to a user's identity (stored with account, uploaded to server) requires a stronger privacy declaration than data stored only on device.
