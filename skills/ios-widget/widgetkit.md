# WidgetKit Reference

Quick-reference for WidgetKit patterns. Always verify current API via context7 before use — WidgetKit evolves significantly between iOS versions.

---

## Widget Size Specifications

| Family | Points (w×h) | Typical Content |
|--------|-------------|-----------------|
| `systemSmall` | 158×158 | Single stat, icon + number, countdown |
| `systemMedium` | 338×158 | 2-column layout, short list (2-3 items) |
| `systemLarge` | 338×354 | Full list (5-6 items), rich content |
| `systemExtraLarge` (iPad only) | 715×354 | Dashboard layout |
| `accessoryCircular` | ~44pt diameter | Gauge, progress ring, icon+number |
| `accessoryRectangular` | ~157×52pt | 2-3 lines of text, small chart |
| `accessoryInline` | ~288×18pt | Icon + single line of text |

**Text minimums:**
- Never use text smaller than 11pt in any widget
- Use `minimumScaleFactor` for dynamic type resistance
- Lock screen accessories must be legible at arm's length

---

## Provider Types

### AppIntentTimelineProvider (configurable — prefer this)

```swift
struct MyProvider: AppIntentTimelineProvider {
    typealias Intent = MyConfigIntent  // Defines what user can configure
    typealias Entry = MyEntry
    
    func placeholder(in context: Context) -> MyEntry { ... }
    func snapshot(for configuration: MyConfigIntent, in context: Context) async -> MyEntry { ... }
    func timeline(for configuration: MyConfigIntent, in context: Context) async -> Timeline<MyEntry> { ... }
}
```

Use when: user can pick which data source, category, or item to display.

### TimelineProvider (static — no user configuration)

```swift
struct MyProvider: TimelineProvider {
    typealias Entry = MyEntry
    
    func placeholder(in context: Context) -> MyEntry { ... }
    func getSnapshot(in context: Context, completion: @escaping (MyEntry) -> Void) { ... }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MyEntry>) -> Void) { ... }
}
```

Use when: widget always shows the same type of content (e.g., "quote of the day" with no per-instance configuration).

**Decision:** If in doubt, use `AppIntentTimelineProvider` — it provides a configuration UI for free even if you only have one option now.

---

## Reload Policies

```swift
// Reload at a specific future time — for time-sensitive content
Timeline(entries: [entry], policy: .after(nextRefreshDate))

// Reload after the last entry's date passes — for scheduled content
Timeline(entries: multipleEntries, policy: .atEnd)

// Never auto-reload — app will signal manually
Timeline(entries: [entry], policy: .never)
```

**Refresh budget:**
- The system provides approximately 40-70 reloads per widget per day
- Budget is dynamically adjusted based on how often the user views the widget
- Frequently-viewed widgets get more reloads; unseen widgets get fewer
- Reloads requested beyond budget are silently deferred — never rely on exact timing
- Design all content to degrade gracefully when slightly stale

**From the main app, signal a refresh:**
```swift
import WidgetKit
WidgetCenter.shared.reloadTimelines(ofKind: "MyWidgetKind")
WidgetCenter.shared.reloadAllTimelines()  // Use sparingly
```

---

## App Group Data Sharing

### Lightweight Data (UserDefaults)

```swift
// Main app — write
let defaults = UserDefaults(suiteName: "group.com.yourapp.shared")!
let data = try JSONEncoder().encode(myModel)
defaults.set(data, forKey: "widgetSnapshot")
WidgetCenter.shared.reloadTimelines(ofKind: "MyWidget")

// Widget provider — read
let defaults = UserDefaults(suiteName: "group.com.yourapp.shared")!
if let data = defaults.data(forKey: "widgetSnapshot"),
   let snapshot = try? JSONDecoder().decode(MyModel.self, from: data) {
    // Use snapshot
}
```

Best for: small, infrequently-updated structs. Keep under 1 MB.

### SwiftData Shared Container

```swift
// Same configuration used in both app and widget targets
static func makeSharedContainer() throws -> ModelContainer {
    let groupURL = FileManager.default
        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.shared")!
        .appendingPathComponent("data.sqlite")
    let config = ModelConfiguration(url: groupURL)
    return try ModelContainer(for: Item.self, configurations: [config])
}
```

Best for: structured data the widget queries directly. See `ios-data-model/swiftdata.md` for full patterns.

**Warning:** Create the `ModelContainer` once and reuse it — don't create a new container per timeline refresh. Instantiate at widget bundle level if possible.

---

## Interactive Widgets (iOS 17+)

```swift
// 1. Define an AppIntent for the action
struct ToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Item"
    
    @Parameter(title: "Item ID") var itemID: String
    
    func perform() async throws -> some IntentResult {
        // Perform action on shared data store
        let container = try makeSharedContainer()
        let context = ModelContext(container)
        // ... update data
        try context.save()
        return .result()
    }
}

// 2. Use Button or Toggle in widget view
Button(intent: ToggleItemIntent(itemID: entry.id)) {
    Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle")
}

Toggle(isOn: entry.isEnabled, intent: ToggleIntent(itemID: entry.id)) {
    Text(entry.title)
}
.toggleStyle(.switch)
```

**Constraints:**
- Requires iOS 17+ — wrap in `#available(iOS 17, *)`
- Widget view reloads automatically after intent completes
- No `.sheet`, `.alert`, or navigation — actions must be self-contained
- Maximum 1 deep link + interactive elements combination per widget view

---

## AppIntentTimelineProvider vs Live Activity

| Scenario | Use |
|----------|-----|
| Persistent home screen info | WidgetKit widget |
| Real-time event in progress (delivery, game, workout) | Live Activity + Dynamic Island |
| Updates every few minutes | Widget with `.after` reload policy |
| Updates every few seconds | Live Activity (widgets can't do this) |
| User dismissed = gone | Live Activity |
| User places on home screen = always there | Widget |

---

## StandBy Mode

Widgets displayed in StandBy (iPhone on charger in landscape) use `.systemSmall` or `.accessoryCircular` families. The system enlarges them — design at native size, the system handles scaling.

Enable explicit StandBy support:
```swift
.contentMarginsDisabled()  // Optional: remove default margins for full-bleed designs
```

---

## Widget Configuration AppIntent

```swift
struct MyConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description = IntentDescription("Choose what to display.")
    
    @Parameter(title: "Category", default: .all)
    var category: CategoryOption
    
    @Parameter(title: "Show Subtitle", default: true)
    var showSubtitle: Bool
}

enum CategoryOption: String, AppEnum {
    case all, work, personal
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .all: "All",
        .work: "Work",
        .personal: "Personal"
    ]
}
```

---

## Previews in Xcode Canvas

```swift
#Preview(as: .systemMedium) {
    MyWidget()
} timeline: {
    MyEntry(date: .now, title: "Preview Title", subtitle: "Preview Subtitle")
    MyEntry(date: .now.addingTimeInterval(3600), title: "Next Hour", subtitle: "Updated")
}
```

Preview all families in a single preview file — catch layout issues before running on device.

---

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Network call in `getTimeline` | Fetch data in main app, cache in App Group; read cache in provider |
| New `ModelContainer` per refresh | Create container once at widget bundle level |
| Text below 11pt | Use `minimumScaleFactor` or remove text at small sizes |
| Missing `.containerBackground` | Required in iOS 17+ — widget renders with black background without it |
| Using `IntentTimelineProvider` | Superseded by `AppIntentTimelineProvider` — use the new API |
| Expecting exact reload timing | System defers beyond budget — use `.after` with grace period built in |
| Large image data in TimelineEntry | Store image in App Group file, pass URL in entry, load in view with `AsyncImage` or cached `Image` |
