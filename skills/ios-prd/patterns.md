# Product Pattern Detector

15 patterns that map raw app concepts to Apple platform integrations. The Platform Engineer analyst uses this to detect which integrations to evaluate for any given app idea.

---

## Pattern 1: Time-Bounded Event

**Detection signals:** countdown, deadline, event start/end, expires, limited time, reminder before, "don't miss", schedule, booking

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| Live Activities (`ActivityKit`) — ongoing status in Dynamic Island and Lock Screen | Medium | v1 |
| Dynamic Island compact/expanded/minimal presentations | Medium | v1 |
| StandBy mode widget (`.systemSmall` always-on display) | Low | v1.1 |
| Watch complication (countdown on wrist) | High | v2 |
| Action Button shortcut to start/track the event | Low | v1.1 |
| Countdown notifications (`UNTimeIntervalNotificationTrigger`, `UNCalendarNotificationTrigger`) | Low | v1 |

---

## Pattern 2: Daily Ritual / Habit

**Detection signals:** daily, streak, habit, routine, check-in, every day, morning, evening, consistency, track over time, reminder

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| Shortcuts (`AppIntents`, `AppShortcutsProvider`) — "Hey Siri, log my habit" | Medium | v1.1 |
| Focus Filters (`SetFocusFilterIntent`) — different behavior during Work/Sleep Focus | Medium | v2 |
| HealthKit correlation — does the habit correlate with health metrics? | High | v2 |
| Calendar integration (`EventKit`) — block time for the ritual | Medium | v2 |
| Streak tracking — custom or GameKit achievements | Low | v1 |
| Daily widget (`.systemSmall` with today's status) | Low | v1 |

---

## Pattern 3: Photo / Media Capture

**Detection signals:** photo, camera, capture, shoot, gallery, memory, album, image, video, record, visual journal

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| EXIF metadata extraction (`CGImageSource`, `PHAsset`) — location, timestamp, camera settings | Medium | v1 |
| CoreSpotlight indexing (`CSSearchableItem`) — make captures discoverable via Spotlight | Medium | v1.1 |
| Share Extension — capture from outside the app | High | v2 |
| Photo widget showing latest capture | Low | v1 |
| Map view of where photos were taken (`MapKit`) | Medium | v1.1 |
| Time-lapse / recap generation (`AVFoundation`, `AVAssetWriter`) | High | v2 |
| `PhotosPicker` SwiftUI for library access (not `UIImagePickerController`) | Low | v1 |
| Thumbnail generation (`CGImageSourceCreateThumbnailAtIndex`) | Low | v1 |

---

## Pattern 4: Location-Dependent

**Detection signals:** location, nearby, around me, local, map, geofence, distance, arrive at, leave, when I get to, place-based

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| `CLMonitor` with `CLCircularGeographicCondition` — event-based geofencing (not continuous polling) | Medium | v1 |
| Timezone awareness (`TimeZone.current`, `TimeZone.autoupdatingCurrent`) | Low | v1 |
| Altitude adjustment (`CLLocation.altitude`) | Low | v1.1 |
| Weather correlation (`WeatherKit`) | Medium | v2 |
| Map visualization (`Map` SwiftUI, `MapContentBuilder`) | Medium | v1 |
| Location-aware notifications (trigger based on region entry/exit) | Medium | v1.1 |
| Background location (`NSLocationAlwaysAndWhenInUseUsageDescription`) — only if user benefit is clear | High | v2 |

---

## Pattern 5: Community / Social

**Detection signals:** share with others, community, public, leaderboard, submissions, featured, browse others, follow, post

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| CloudKit public database (`CKDatabase` with `.publicCloudDatabase`) | High | v2 |
| Content moderation (`Vision` framework: `VNClassifyImageRequest`) | High | v2 |
| Rate limiting (server-side or client-side submission throttle) | Medium | v2 |
| Reporting system (report abusive content flow) | Medium | v2 |
| Featured curation (editorial picks, manual or algorithmic) | Medium | v2 |
| SharePlay (`GroupActivities`) — shared experience in FaceTime | High | v3 |

---

## Pattern 6: Content Consumption

**Detection signals:** browse, read, discover, feed, articles, podcasts, videos, listen, watch, curated content, recommendations

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| Spotlight search (`CSSearchableItem`, `CSSearchableIndex`) | Low | v1.1 |
| Handoff (`NSUserActivity`) — continue reading on another device | Low | v1.1 |
| SharePlay (`GroupActivities`) — watch/listen together | High | v3 |
| AirDrop sharing (`UIActivityViewController` with custom activity) | Low | v1.1 |
| Universal Links — open app content from web links | Medium | v2 |

---

## Pattern 7: Health / Wellness

**Detection signals:** health, workout, steps, heart rate, sleep, calories, mindfulness, meditation, stress, recovery, fitness

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| HealthKit read — specific data types (steps, heart rate, sleep, HRV) | Medium | v1 |
| HealthKit write — log workouts, mindfulness minutes | Medium | v1 |
| Mindfulness minutes (`HKCategoryType(.mindfulSession)`) | Low | v1 |
| Activity suggestions based on HealthKit patterns | High | v2 |
| Workout sessions (`HKWorkoutSession`) — if tracking active workouts | High | v2 |

---

## Pattern 8: Commerce / Premium

**Detection signals:** subscription, unlock, premium, upgrade, pro, pay, purchase, free trial, IAP, feature gate

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| StoreKit 2 — `Product.products(for:)`, `Transaction.updates` async stream | Medium | v1 |
| Subscription management (`SubscriptionStoreView` SwiftUI) | Low | v1 |
| Paywall presentation (at natural upgrade moments, not paywalling core value) | Medium | v1 |
| Feature gating (check entitlement before showing premium features) | Low | v1 |
| Promotional offers and introductory pricing | Medium | v1.1 |

---

## Pattern 9: Personalization / ML

**Detection signals:** learns your preferences, adapts, personalized, recommendation, "based on your history", smart, AI, tailored, gets better over time

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| CoreML on-device model (`MLModel`) — classification, recommendation | High | v2 |
| Create ML training from user data | High | v3 |
| Preference learning from explicit signals (favorites, skips, saves) | Medium | v1.1 |
| Adaptive UI (show/hide features based on usage patterns) | Medium | v2 |

---

## Pattern 10: Real-Time Data

**Detection signals:** live, real-time, updates automatically, streaming, live score, current price, now playing, feed, ticker

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| WebSocket connection (`URLSessionWebSocketTask`) | Medium | v1 |
| Background app refresh (`BGAppRefreshTask`) — update data while backgrounded | Medium | v1 |
| Push notifications — server triggers refresh | Medium | v1.1 |
| Live Activities — real-time status in Dynamic Island | Medium | v1.1 |
| Server-sent events (`URLSession` streaming) | Medium | v2 |

---

## Pattern 11: Calendar / Scheduling

**Detection signals:** schedule, appointment, meeting, event, date-sensitive, "add to calendar", reminder, due date, deadline, recurring

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| EventKit write — add events to Calendar | Low | v1 |
| EventKit read — detect conflicts | Medium | v1.1 |
| Reminders integration (`EKReminder`) | Low | v1.1 |
| Date-sensitive content (show different content based on calendar date) | Low | v1 |
| Timezone handling (`TimeZone`, `Calendar`, locale-aware formatting) | Low | v1 |

---

## Pattern 12: Audio / Music

**Detection signals:** music, audio, sound, playlist, listen, podcast, ambient, background audio, play, track, song

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| MusicKit — Apple Music catalog access (`MusicCatalogSearchRequest`) | Medium | v1 |
| AVAudioEngine — custom audio processing or mixing | High | v2 |
| Now Playing integration (`MPNowPlayingInfoCenter`) — Lock Screen controls | Medium | v1 |
| AirPlay 2 (`AVRoutePickerView`) | Low | v1.1 |
| Audio session categories (`AVAudioSession`) — ducking, mixing | Low | v1 |

---

## Pattern 13: Messaging / Communication

**Detection signals:** send, message, notify friends, invite, share with contact, chat, group, notification to others

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| Messages extension (`MSMessagesAppViewController`) | High | v2 |
| Rich notifications with media attachments | Medium | v1 |
| Notification actions (`UNNotificationAction`) — quick reply from notification | Low | v1.1 |
| Contact picker (`CNContactPickerViewController`) — invite from contacts | Medium | v2 |

---

## Pattern 14: Gamification

**Detection signals:** points, score, level, achievement, badge, streak, leaderboard, challenge, compete, reward, unlock

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| Custom streak / achievement system (in-app, no Game Center required) | Low | v1 |
| GameKit achievements (`GKAchievement`) — only if game-like app | Medium | v2 |
| GameKit leaderboards (`GKLeaderboard`) — only if head-to-head makes sense | Medium | v2 |
| Progression systems (xp, levels, unlockable content) | Medium | v1.1 |
| Celebration moments (confetti, haptic feedback, share moment) | Low | v1 |

---

## Pattern 15: Accessibility-First

**Detection signals:** accessibility, VoiceOver, hearing impaired, visual impairment, motor impairment, assistive, inclusive design, all users

**Integrations to evaluate:**

| Integration | Complexity | Epic |
|---|---|---|
| VoiceOver custom actions (`accessibilityAction`) — non-gesture interactions | Low | v1 |
| Audio descriptions for visual content | Medium | v1 |
| Haptic patterns (`UIImpactFeedbackGenerator`, `CoreHaptics`) — convey state changes | Low | v1 |
| Dynamic Type support (`dynamicTypeSize` environment) | Low | v1 |
| Assistive Touch custom gestures | Medium | v2 |
| Reduce Motion compatibility — all animations behind `accessibilityReduceMotion` | Low | v1 |
