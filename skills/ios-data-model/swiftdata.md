# SwiftData Reference

Quick-reference for common SwiftData patterns. Always verify current API via context7 before use — APIs evolve between iOS versions.

---

## @Model Class Patterns

### Basic Model

```swift
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var isArchived: Bool = false
    
    init(id: UUID = UUID(), title: String, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
    }
}
```

### Relationships

```swift
@Model
final class Category {
    var name: String
    // One-to-many: cascade deletes children when category is deleted
    @Relationship(deleteRule: .cascade, inverse: \Item.category)
    var items: [Item] = []
    
    init(name: String) { self.name = name }
}

@Model
final class Item {
    var title: String
    // Many-to-one: nullify when category is deleted
    @Relationship(deleteRule: .nullify)
    var category: Category?
    
    init(title: String) { self.title = title }
}
```

Delete rules:
- `.cascade` — delete children when parent is deleted (use for owned data)
- `.nullify` — set relationship to nil when related object is deleted (use for optional associations)
- `.deny` — prevent deletion if relationship exists (use for referential integrity)
- `.noAction` — do nothing (rarely needed)

### Attributes

```swift
@Model
final class Document {
    @Attribute(.unique) var slug: String          // Unique constraint
    @Attribute(.externalStorage) var content: Data // Store large blobs outside SQLite
    @Attribute(.spotlight) var title: String       // Index for Spotlight search
    @Transient var cachedPreview: UIImage?         // Not persisted
    
    init(slug: String, title: String, content: Data) {
        self.slug = slug
        self.title = title
        self.content = content
    }
}
```

---

## ModelContainer Configuration

### Default (documents directory)

```swift
let container = try ModelContainer(for: Item.self, Category.self)
```

### App Group Shared Container (required for widget access)

```swift
let groupURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourapp.shared")!
    .appendingPathComponent("data.sqlite")

let config = ModelConfiguration(
    schema: Schema([Item.self, Category.self]),
    url: groupURL
)
let container = try ModelContainer(
    for: Schema([Item.self, Category.self]),
    configurations: [config]
)
```

### CloudKit Sync

```swift
let config = ModelConfiguration(
    schema: Schema([Item.self]),
    cloudKitDatabase: .automatic  // uses default CloudKit container
    // or: .private("iCloud.com.yourapp") for explicit container
)
```

**CloudKit restrictions — these will cause sync errors:**
- No `@Attribute(.unique)` constraints on synced models
- No non-optional relationships (all relationships must be optional for CloudKit)
- No `@Attribute(.externalStorage)` on CloudKit-synced models
- All properties must have default values (CloudKit can create partial objects)

### In-Memory (for tests)

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try ModelContainer(for: Item.self, configurations: [config])
```

---

## Versioned Schema & Migration

### Define Versioned Schemas

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Item.self] }
    
    @Model final class Item {
        var title: String
        init(title: String) { self.title = title }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Item.self] }
    
    @Model final class Item {
        var title: String
        var subtitle: String = ""  // New in v2 — has default for lightweight migration
        init(title: String, subtitle: String = "") {
            self.title = title
            self.subtitle = subtitle
        }
    }
}
```

### Migration Plan

```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] { [v1ToV2] }
    
    // Lightweight: only valid for additive changes (new optional properties, new default-value properties)
    static let v1ToV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
    
    // Custom: required for renames, type changes, data transforms
    static let v2ToV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            // Transform data after migration
            let items = try context.fetch(FetchDescriptor<SchemaV3.Item>())
            for item in items {
                item.subtitle = item.title.components(separatedBy: ":").last ?? ""
            }
            try context.save()
        }
    )
}
```

### Use Migration Plan in Container

```swift
let container = try ModelContainer(
    for: SchemaV2.Item.self,
    migrationPlan: AppMigrationPlan.self
)
```

---

## Querying: #Predicate and FetchDescriptor

### Basic Fetch

```swift
// In a SwiftUI view
@Query(sort: \Item.createdAt, order: .reverse) var items: [Item]

// In a service/manager
let descriptor = FetchDescriptor<Item>(
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
let items = try context.fetch(descriptor)
```

### Filtered Fetch

```swift
let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
var descriptor = FetchDescriptor<Item>(
    predicate: #Predicate<Item> { item in
        item.createdAt > cutoff && !item.isArchived
    },
    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
)
descriptor.fetchLimit = 50
```

### Prefetch Relationships (avoid N+1)

```swift
var descriptor = FetchDescriptor<Category>()
descriptor.prefetchRelationships = [\.items]
let categories = try context.fetch(descriptor)
// items are now prefetched — no additional queries when accessing category.items
```

### Count Without Fetching

```swift
let count = try context.fetchCount(FetchDescriptor<Item>(
    predicate: #Predicate { !$0.isArchived }
))
```

### @Query with Dynamic Predicate in SwiftUI

```swift
struct ItemListView: View {
    @State private var showArchived = false
    
    var body: some View {
        ItemList(showArchived: showArchived)
    }
}

struct ItemList: View {
    @Query var items: [Item]
    
    init(showArchived: Bool) {
        _items = Query(
            filter: #Predicate<Item> { item in
                showArchived ? true : !item.isArchived
            },
            sort: \.createdAt,
            order: .reverse
        )
    }
    
    var body: some View {
        List(items) { item in ItemRow(item: item) }
    }
}
```

---

## Performance Strategies

### Batch Operations

```swift
// Insert many items efficiently
for data in largeDataset {
    let item = Item(title: data.title)
    context.insert(item)
}
try context.save()  // Single save after all inserts
```

### Background Processing

```swift
// Use a background ModelContext for heavy operations
Task.detached(priority: .background) {
    let backgroundContext = ModelContext(container)
    // Process data...
    try backgroundContext.save()
}
```

### Denormalization for Widget Performance

Widget timeline providers have strict memory and time limits. Pre-compute and store display-ready data:

```swift
@Model
final class DailyStats {
    var date: Date
    // Denormalized: pre-computed so widget doesn't need complex queries
    var itemCount: Int
    var completionRate: Double
    var topCategoryName: String
    
    init(date: Date, itemCount: Int, completionRate: Double, topCategoryName: String) {
        self.date = date
        self.itemCount = itemCount
        self.completionRate = completionRate
        self.topCategoryName = topCategoryName
    }
}
```

Update `DailyStats` whenever items change in the main app. The widget reads only `DailyStats` — no joins, no computed queries.

### Avoid in SwiftUI Body

Never create `ModelContext` or execute fetches inside a SwiftUI `body`. Use `@Query` for declarative reactive queries, or push imperative fetches to a service layer.

---

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `@Attribute(.unique)` with CloudKit | Remove unique constraint; use app-level deduplication |
| Non-optional relationship with CloudKit | Make all relationships optional |
| Fetching in widget without App Group container | Configure shared `ModelConfiguration` with App Group URL |
| Missing `init()` | SwiftData requires explicit `init` — compiler won't synthesize |
| Mutating model in background without context | Always use `ModelContext` from the correct actor |
| Large `Data` blobs in main store | Use `@Attribute(.externalStorage)` |
| Forgot to call `context.save()` | SwiftData auto-saves on `@Environment(\.modelContext)`, but explicit saves needed for background contexts |
