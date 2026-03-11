# ADR-004: SwiftData for Offline Message Caching

## Status

Accepted

## Date

2026-03-11

## Context

Toone Mobile communicates exclusively with a running Toone Desktop instance over a WebSocket tunnel. When the tunnel is unavailable -- due to network interruption, desktop sleep, Wi-Fi transition, or the user simply walking out of range -- the app must degrade gracefully rather than present a blank screen.

The following requirements drive the need for offline caching:

1. **Reading recent messages offline.** Users expect to review recent conversations even when the desktop is unreachable. A user who opens the app on the subway should see the messages from their last session, not an empty chat view with a "Disconnected" error.

2. **Session continuity across reconnections.** When the tunnel reconnects, the app performs an incremental `state.sync` to fetch only changes since the last sync timestamp. This requires the app to have a persisted record of its last known state, so it can request a delta rather than a full state snapshot every time.

3. **Queuing outbound messages.** If a user sends a message while disconnected, the message should be stored locally with a "pending" status and transmitted when the tunnel reconnects.

4. **Not full offline mode.** The app is a thin client. AI processing, file operations, and agent management all require a live desktop connection. Offline caching is limited to reading previously fetched data and queuing a small number of outbound messages. There is no goal of making the app fully functional offline.

We evaluated the following persistence technologies:

- **Core Data.** Apple's mature object graph and persistence framework. Extremely capable, with support for migrations, relationships, fetch request templates, and NSFetchedResultsController. However, its API surface is large, Objective-C-rooted, and requires significant boilerplate (managed object contexts, persistent store coordinators, NSManagedObject subclasses, `.xcdatamodeld` files). Integration with SwiftUI requires `@FetchRequest` wrappers that leak persistence concerns into the view layer.

- **SQLite directly (via GRDB or SQLite.swift).** Provides full SQL control and excellent performance. Third-party Swift wrappers (GRDB, SQLite.swift) offer type-safe query builders. However, adding a third-party dependency for persistence contradicts the project's preference for minimal external dependencies. Raw SQLite also requires manual migration management and has no built-in SwiftUI integration.

- **UserDefaults / Plist.** Suitable only for small amounts of unstructured data (settings, preferences). Not appropriate for storing hundreds or thousands of cached messages with relationships and query requirements.

- **File-based JSON storage.** Simple: serialize entities to JSON files. However, it does not support efficient querying (e.g., "fetch the last 50 messages for session X, ordered by timestamp"), relationships, or concurrent access. Performance degrades with data size.

- **SwiftData.** Apple's modern persistence framework, introduced in iOS 17. Built on the same SQLite backing store as Core Data, but with a Swift-native API using macros (`@Model`, `@Query`). Eliminates the boilerplate of Core Data: no `.xcdatamodeld` files, no NSManagedObject subclasses, no explicit context management for simple operations. Supports relationships, migrations, and SwiftUI integration via `@Query`. Requires iOS 17+, which aligns with our deployment target (ADR-003).

## Decision

We adopt **SwiftData** as the persistence framework for offline caching.

### Caching Strategy

The caching strategy is deliberately conservative. The mobile app is a thin client, and the desktop is the authoritative source of truth. The cache is a local replica that can be fully rebuilt from the desktop at any time.

**What is cached:**

| Data | Cache Policy | Limit |
|------|-------------|-------|
| Messages | Last N messages per session | 1,000 per session, 5,000 total |
| Session metadata | All known sessions | No limit (metadata is small) |
| Agent list | Full agent roster | No limit |
| Department structure | Full department list | No limit |
| Project tree snapshot | Last known tree structure | 1 snapshot |
| Last sync timestamp | Single value | 1 |
| Pending outbound messages | Queued until sent | No hard limit |

**What is NOT cached:**

- File contents (fetched on demand only, not stored)
- Active AI streams (cannot function offline)
- Desktop connection status history
- Authentication tokens (stored in Keychain, not SwiftData -- see Infrastructure layer)

### SwiftData Model Design

Persistence models are **separate from domain entities** to maintain the Clean Architecture layer boundary (ADR-001). SwiftData `@Model` classes live in the Data layer. Mappers translate between persistence models and domain entities.

```
Domain Entity          SwiftData Model          Mapper
--------------         ----------------         ----------------
Message           <->  CachedMessage            MessageMapper
Session           <->  CachedSession            SessionMapper
Agent             <->  CachedAgent              AgentMapper
Department        <->  CachedDepartment         DepartmentMapper
ProjectNode       <->  CachedProjectNode        ProjectNodeMapper
(pending message) <->  PendingMessage           PendingMessageMapper
```

### Cache Lifecycle

1. **App launch:** Load cached state from SwiftData. Display it immediately in the UI.
2. **Tunnel connects:** Perform `state.sync` (full or incremental). Update the SwiftData cache with fresh data. Update ViewModels.
3. **Steady state:** As new messages arrive via the tunnel, cache them in SwiftData. As state change notifications arrive, update the cache.
4. **Tunnel disconnects:** Continue displaying cached data. Mark the UI with an "offline" indicator. Queue any outbound messages locally.
5. **Tunnel reconnects:** Send `state.sync` with `lastSyncTimestamp`. Merge server changes into the cache. Transmit any queued pending messages.

### Cache Eviction Rules

| Rule | Threshold | Action |
|------|-----------|--------|
| Total cached messages | > 5,000 | Remove oldest messages (FIFO by timestamp) |
| Archived session messages | After 30 days | Remove from cache |
| Cache database size | > 50 MB | Aggressive pruning of oldest data |
| On successful full sync | -- | Replace all cached data with fresh state from desktop |

### Full Sync Behavior

When a full sync occurs (first connection or extended disconnection), the cache is cleared and rebuilt entirely from the desktop's state snapshot. This ensures the cache never diverges permanently from the source of truth.

## Consequences

### Positive

- **Swift-native API.** SwiftData uses `@Model` macros and Swift-native types. No Objective-C bridging, no `NSManagedObject` subclasses, no `.xcdatamodeld` files. The persistence models are plain Swift classes with property wrappers.
- **Less boilerplate than Core Data.** Model definitions are concise. The `ModelContainer` and `ModelContext` APIs are simpler than `NSPersistentStoreCoordinator` and `NSManagedObjectContext`. Automatic migration handles schema changes for simple cases.
- **SwiftUI integration.** The `@Query` property wrapper enables direct observation of persisted data in SwiftUI views. However, in this project we use it sparingly, preferring to route data through ViewModels and use cases to maintain the Clean Architecture layer boundary.
- **Same SQLite backing.** SwiftData uses the same SQLite storage engine as Core Data. Performance characteristics are well understood, and the data can be inspected with standard SQLite tools during development.
- **Aligned with deployment target.** SwiftData requires iOS 17+, which is our minimum deployment target (ADR-003). There is no version mismatch to manage.
- **Graceful offline experience.** Users see their recent messages and session history immediately on app launch, regardless of connectivity. The transition from cached to live data is seamless.

### Negative

- **iOS 17+ requirement.** SwiftData is not available on iOS 16 or earlier. This is already accepted by ADR-003 (iOS 17+ minimum deployment target), so it introduces no additional platform restriction.
- **SwiftData maturity.** SwiftData was introduced in iOS 17 (2023) and is less battle-tested than Core Data (2005). There are known edge cases with complex relationships, migration scenarios, and concurrency. Apple has been addressing these in iOS 17.x and iOS 18 updates.
- **Limited query expressiveness.** SwiftData's `#Predicate` macro covers common query patterns but lacks the full expressiveness of Core Data's `NSCompoundPredicate` or raw SQL. For our use case (fetching messages by session ID, sorted by timestamp, with a limit), `#Predicate` is sufficient.
- **Mapper boilerplate.** Maintaining separate domain entities and SwiftData models requires mapper code. Each entity change must be reflected in both the domain type and the persistence model. This is the same trade-off accepted in ADR-001 for maintaining layer boundaries.
- **Cache invalidation complexity.** Keeping the local cache consistent with the desktop's authoritative state requires careful handling of full syncs, incremental syncs, and real-time notifications. The "desktop is always the source of truth" rule simplifies this: in case of doubt, a full sync resolves any inconsistency.

### Mitigations

- Monitor SwiftData stability across iOS releases. If critical bugs are encountered, Core Data can be substituted at the Data layer without affecting Domain or Presentation (thanks to the repository protocol abstraction from ADR-001).
- Keep cache eviction rules conservative to prevent unbounded storage growth on the device.
- Implement a "clear cache" option in Settings for users to manually reset the local replica.
- Write integration tests that verify cache consistency across sync, reconnection, and eviction scenarios.
