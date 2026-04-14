# Performance Review Reference

Additional checks for ios-code-review when reviewing performance-sensitive code.

## Main Thread Blocking

Detect synchronous work on `@MainActor` types:
- `Thread.sleep` or `usleep` on main actor
- Synchronous network calls (URLSession without async)
- Heavy computation in SwiftUI `body` property
- File I/O without `.task` or background actor
- Image decoding/resizing in view code

## Memory Audit

**Retain cycles in closures:**
- Closures stored as properties that capture `self` without `[weak self]`
- Timer callbacks, NotificationCenter observers, KVO without weak references
- `Task` closures that capture `self` — check if task is cancelled in `deinit`

**Large allocations:**
- Loading full-resolution images without downsampling (`UIImage(named:)` for large photos)
- Unbounded arrays growing without limits
- Caching without eviction policy

## Photo Pipeline

If the app processes photos:
- Thumbnail generation using `CGImageSourceCreateThumbnailAtIndex` (not full decode + resize)
- `preparingThumbnail(of:)` for async thumbnail generation
- Memory-mapped file access for large images
- Batch processing with autorelease pools

## Widget Efficiency

- Timeline entry count: don't generate more entries than needed
- Data fetching in `getTimeline`: use cached data when possible
- Shared `ModelContainer` via App Group (don't create new containers per refresh)
- Avoid network calls in timeline provider (use background app refresh to update data)

## Energy Efficiency

- Location updates: use `CLMonitor` (event-based) not `startUpdatingLocation` (continuous)
- Background tasks: respect `BGTaskScheduler` time limits
- Network: batch requests, use background URLSession for large transfers
- Animations: pause when app is backgrounded

## Instruments Tips

| Issue | Instruments Template |
|-------|---------------------|
| Slow UI / hitches | Time Profiler + Animation Hitches |
| Memory leaks | Leaks |
| Memory growth | Allocations |
| Energy drain | Energy Log |
| Network efficiency | Network |
| Core Data / SwiftData | Core Data |
| Widget timeline | WidgetKit Simulator |
