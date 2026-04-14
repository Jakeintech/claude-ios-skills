# Usage Description String Guide

Rules and approved patterns for every permission type. Usage description strings are reviewed by Apple during App Store submission — strings that are vague, misleading, or missing will cause rejection.

---

## Rules

1. **Start with the app name** — reviewers need to know which app is asking
2. **State the specific feature** that uses the permission — not "to improve your experience"
3. **Explain the user benefit** — what does the user get from granting this?
4. **Keep under 2 sentences** — brevity is required
5. **No technical jargon** — "location data", not "CLLocation coordinates"
6. **Never say "required"** — Apple treats this as coercive; let the benefit speak for itself
7. **Match the actual use** — requesting "always" location when you only need "when in use" causes rejection

---

## Approved Patterns by Permission Type

### Camera
`NSCameraUsageDescription`

**Pattern:** `"{AppName} uses your camera to [specific feature]."`

**Approved examples:**
- `"GoldenHour uses your camera to capture daily sunrise and sunset photos."`
- `"RecipeBox uses your camera to scan ingredient barcodes and add items to your pantry."`
- `"FitForm uses your camera to analyze your workout form and provide real-time feedback."`

**Rejected patterns:**
- `"We need camera access."` — no benefit stated
- `"Used for app features."` — vague
- `"Required for full functionality."` — coercive language

---

### Location When In Use
`NSLocationWhenInUseUsageDescription`

**Pattern:** `"{AppName} uses your location to [specific feature]."`

**Approved examples:**
- `"GoldenHour uses your location to calculate accurate sunrise and sunset times for your area."`
- `"NearMe uses your location to show restaurants and shops within walking distance."`
- `"TrailTracker uses your location to record your hiking route and calculate distance traveled."`

**Rejected patterns:**
- `"Location is used to personalize your experience."` — not specific enough
- `"To show you relevant content."` — vague

---

### Location Always (Background)
`NSLocationAlwaysAndWhenInUseUsageDescription`

**Pattern:** `"{AppName} uses your location in the background to [specific feature that benefits the user]."`

**Note:** Only request "always" if there is a genuine user benefit from background location. Apple scrutinizes this permission closely — if foreground location is sufficient, use When In Use only.

**Approved examples:**
- `"GoldenHour uses your location in the background to notify you 30 minutes before golden hour begins at your current location."`
- `"HomeAway uses your location in the background to automatically arm your home security when you leave and disarm when you return."`

**Rejected patterns:**
- Same as When In Use string — must explain *why* background is needed
- `"For location-based features."` — not specific

---

### Photos Read (Library Access)
`NSPhotoLibraryUsageDescription`

**Pattern:** `"{AppName} accesses your photo library to [specific feature]."`

**Approved examples:**
- `"GoldenHour accesses your photo library to display your golden hour captures in monthly recap galleries."`
- `"Collage accesses your photo library to let you select photos for your collage projects."`

---

### Photos Add (Save to Library)
`NSPhotoLibraryAddUsageDescription`

**Pattern:** `"{AppName} saves [what] to your photo library."`

**Note:** This can be requested separately from read access. If your app only saves (never reads), request add-only — do not request full library access.

**Approved examples:**
- `"GoldenHour saves your golden hour photos to your photo library."`
- `"Collage saves your finished collages to your photo library."`

---

### Health Read
`NSHealthShareUsageDescription`

**Pattern:** `"{AppName} reads your [specific health data types] to [specific feature]."`

**Approved examples:**
- `"GoldenHour reads your activity data to suggest golden hour walks when your step count is low."`
- `"SleepBetter reads your sleep and heart rate data to identify your optimal sleep schedule."`
- `"FitTrack reads your workout history and calorie data to personalize your fitness plan."`

**Note:** Be specific about which data types — "health data" alone is too vague.

---

### Health Write
`NSHealthUpdateUsageDescription`

**Pattern:** `"{AppName} saves [specific data] to Health to [specific feature]."`

**Approved examples:**
- `"Mindful saves your meditation sessions to Health to track your mindfulness minutes over time."`
- `"WalkMore saves your walking workouts to Health so they appear in your Activity rings."`

---

### Contacts
`NSContactsUsageDescription`

**Pattern:** `"{AppName} accesses your contacts to [specific feature]."`

**Approved examples:**
- `"SplitEasy accesses your contacts to let you add friends to expense splits."`
- `"Gifted accesses your contacts to display upcoming birthdays and suggest gift ideas."`

---

### Calendar
`NSCalendarsUsageDescription`

**Pattern:** `"{AppName} reads your calendar to [specific feature]."` or `"{AppName} adds events to your calendar to [specific feature]."`

**Approved examples:**
- `"Focus accesses your calendar to automatically apply Focus modes when you have meetings."`
- `"CountDown adds your upcoming events to your calendar so you always know what's next."`

---

### Reminders
`NSRemindersFullAccessUsageDescription`

**Pattern:** `"{AppName} accesses your reminders to [specific feature]."`

**Approved examples:**
- `"TaskMaster accesses your reminders to import and sync your to-do items in one place."`

---

### Microphone
`NSMicrophoneUsageDescription`

**Pattern:** `"{AppName} uses your microphone to [specific feature]."`

**Approved examples:**
- `"VoiceJournal uses your microphone to record your spoken journal entries."`
- `"TuneUp uses your microphone to listen to your instrument and display real-time pitch accuracy."`

---

### Face ID
`NSFaceIDUsageDescription`

**Pattern:** `"{AppName} uses Face ID to [specific feature]."`

**Approved examples:**
- `"Vault uses Face ID to protect your private notes and photos."`
- `"BankHelper uses Face ID to securely log in to your accounts without a password."`

---

### Motion (Accelerometer / Gyroscope)
`NSMotionUsageDescription`

**Pattern:** `"{AppName} uses motion data to [specific feature]."`

**Approved examples:**
- `"ShakeIt uses motion data to detect when you shake your phone to shuffle your playlist."`
- `"FormCoach uses motion data to count your repetitions and detect exercise type automatically."`

---

### Apple Music
`NSAppleMusicUsageDescription`

**Pattern:** `"{AppName} accesses Apple Music to [specific feature]."`

**Approved examples:**
- `"GoldenHour accesses Apple Music to play your golden hour playlist when sunset is near."`
- `"MoodTunes accesses Apple Music to suggest songs that match your current energy level."`

---

### Nearby Interaction (UWB)
`NSNearbyInteractionUsageDescription`

**Pattern:** `"{AppName} uses nearby interaction to [specific feature]."`

**Approved examples:**
- `"FindUs uses nearby interaction to show you the precise distance and direction to your friends."`
- `"ShareDrop uses nearby interaction to enable fast file transfers to nearby devices."`

---

## Stacking Multiple Permissions

When requesting multiple permissions, each description must be independent and complete — do not reference another permission in a description.

**Good:** Each string stands alone and explains its own specific use.

**Bad:** `"GoldenHour uses your camera and location together to geotag your photos."` — this is a camera string that mentions location. The location string must separately explain the location use case.

---

## Timing: When to Request Each Permission

| Permission | When to Request |
|---|---|
| Camera | At the moment the camera feature is first invoked |
| Photos (read) | When the user taps to browse their library |
| Photos (add) | When the user taps to save a photo |
| Location (when in use) | When the user first opens a location-dependent feature |
| Location (always) | Only after user has used and valued the when-in-use feature — explain background benefit |
| Health | When the user explicitly opts into health correlation features |
| Contacts | When the user first tries to add a contact |
| Calendar | When the user taps "Add to Calendar" for the first time |
| Notifications | After user has experienced value, before they close onboarding |
| Face ID | When setting up app lock / private vault feature |

**Never request permissions on app launch.** Users who see a permission prompt before understanding what the app does almost always deny it. Request at the moment of need, immediately preceded by a brief explanation of why it helps them.
