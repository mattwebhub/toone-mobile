# Toone Mobile -- Data Flow Documentation

**Version:** 1.0
**Last Updated:** 2026-03-11
**Status:** Draft

---

## 1. Overview

This document describes the data flows within Toone Mobile. Because the mobile app is a thin client that delegates all AI processing and file operations to Toone Desktop, every significant data flow involves the WebSocket tunnel. The app also maintains a local cache for offline resilience.

### Key Principle

Data flows in Toone Mobile follow a **unidirectional pattern** within the presentation layer:

```
User Action -> ViewModel -> Use Case -> Repository -> Tunnel/Cache
                  ^                                        |
                  |________ State Update _________________|
```

---

## 2. Connection Flow

### 2.1 Initial Pairing

```
+--------+         +--------+         +--------+         +--------+
|  User  |         | Mobile |         | Camera |         |Desktop |
+---+----+         +---+----+         +---+----+         +---+----+
    |                   |                  |                   |
    | 1. Tap "Connect"  |                  |                   |
    |------------------>|                  |                   |
    |                   |                  |                   |
    |                   | 2. Open camera   |                   |
    |                   |----------------->|                   |
    |                   |                  |                   |
    | 3. Scan QR code   |                  |                   |
    |------------------>|                  |                   |
    |                   |                  |                   |
    |                   | 4. Parse QR payload (host, port,     |
    |                   |    pairingToken, tls)                |
    |                   |                  |                   |
    |                   | 5. WebSocket CONNECT                 |
    |                   |----------------------------------------->|
    |                   |                  |                   |
    |                   | 6. auth.handshake (pairingToken)     |
    |                   |----------------------------------------->|
    |                   |                  |                   |
    |                   | 7. Response (sessionToken, config)   |
    |                   |<-----------------------------------------|
    |                   |                  |                   |
    |                   | 8. Store token   |                   |
    |                   |    in Keychain   |                   |
    |                   |                  |                   |
    |                   | 9. state.sync    |                   |
    |                   |----------------------------------------->|
    |                   |                  |                   |
    |                   | 10. Full state snapshot               |
    |                   |<-----------------------------------------|
    |                   |                  |                   |
    |                   | 11. Cache state locally              |
    |                   |                  |                   |
    |                   | 12. state.subscribe                  |
    |                   |----------------------------------------->|
    |                   |                  |                   |
    | 13. Show Chat UI  |                  |                   |
    |<------------------|                  |                   |
    |                   |                  |                   |
```

### 2.2 Manual IP Entry (Alternative)

```
1. User taps "Enter IP Manually"
2. User types desktop IP address (e.g., 192.168.1.42)
3. Mobile attempts WebSocket connection to ws(s)://<ip>:9876/toone/mobile
4. If connection succeeds, desktop generates a one-time challenge code
5. Desktop displays the challenge code on screen
6. User enters challenge code on mobile
7. Mobile sends auth.handshake with challenge as pairingToken
8. Flow continues from step 7 above
```

### 2.3 Reconnection

```
1. WebSocket connection drops (network change, sleep, etc.)
2. TunnelClient detects disconnection
3. ConnectionViewModel updates state to .reconnecting
4. Exponential backoff timer starts
5. Attempt WebSocket reconnect
6. Send auth.verify with stored sessionToken
7a. If token valid:
    - Send state.sync with lastSyncTimestamp for incremental sync
    - Merge server changes with local cache
    - Resume state.subscribe
    - Update UI with any new data
7b. If token expired:
    - Full re-authentication (user may need to re-pair)
    - Full state.sync
8. ConnectionViewModel updates state to .connected
```

---

## 3. Message Flow

### 3.1 Sending a Message

This is the primary data flow in the application.

```
+--------+    +-----------+    +-----------+    +----------+    +----------+    +----------+
|  User  |    | ChatView  |    | ChatVM    |    | SendMsg  |    | ChatRepo |    | Desktop  |
|        |    |           |    |           |    | UseCase  |    |          |    |          |
+---+----+    +-----+-----+    +-----+-----+    +----+-----+    +----+-----+    +----+-----+
    |               |               |                |               |               |
    | 1. Type msg   |               |                |               |               |
    |   + tap Send  |               |                |               |               |
    |-------------->|               |                |               |               |
    |               |               |                |               |               |
    |               | 2. Bind       |                |               |               |
    |               |   inputText   |                |               |               |
    |               |   -> send()   |                |               |               |
    |               |-------------->|                |               |               |
    |               |               |                |               |               |
    |               |               | 3. Clear       |               |               |
    |               |               |    input,      |               |               |
    |               |               |    set         |               |               |
    |               |               |    isStreaming  |               |               |
    |               |               |                |               |               |
    |               |               | 4. execute()   |               |               |
    |               |               |--------------->|               |               |
    |               |               |                |               |               |
    |               |               |                | 5. Validate   |               |
    |               |               |                |    session    |               |
    |               |               |                |               |               |
    |               |               |                | 6. sendMsg()  |               |
    |               |               |                |-------------->|               |
    |               |               |                |               |               |
    |               |               |                |               | 7. JSON-RPC   |
    |               |               |                |               |  chat.send    |
    |               |               |                |               |  Message      |
    |               |               |                |               |-------------->|
    |               |               |                |               |               |
    |               |               |                |               | 8. Response   |
    |               |               |                |               |  (streamID)   |
    |               |               |                |               |<--------------|
    |               |               |                |               |               |
    |               |               |                | 9. Return     |               |
    |               |               |                |  AsyncStream  |               |
    |               |               |                |<--------------|               |
    |               |               |                |               |               |
    |               |               | 10. for await  |               |               |
    |               |               |     event      |               |               |
    |               |               |<---------------|               |               |
    |               |               |                |               |               |
    |               |               |                |               | 11. textDelta |
    |               |               |                |               |  notifications|
    |               |               |                |               |<--------------|
    |               |               |                |               |               |
    |               |               | 12. Append     |               |               |
    |               |               |     text to    |               |               |
    |               |               |     messages[] |               |               |
    |               |               |                |               |               |
    |               | 13. @Observable                |               |               |
    |               |     triggers                   |               |               |
    |               |     re-render                  |               |               |
    |               |<--------------|                |               |               |
    |               |               |                |               |               |
    | 14. See       |               |                |               |               |
    |   streaming   |               |                |               |               |
    |   text        |               |                |               |               |
    |<--------------|               |                |               |               |
    |               |               |                |               |               |
    |               |               |                |               | 15. complete  |
    |               |               |                |               |  notification |
    |               |               |                |               |<--------------|
    |               |               |                |               |               |
    |               |               | 16. Finalize   |               |               |
    |               |               |     message,   |               |               |
    |               |               |     cache it   |               |               |
    |               |               |                |               |               |
```

### 3.2 Message Stream Event Handling

```swift
// Pseudocode for stream event processing

for await event in stream {
    switch event {
    case .textDelta(let delta):
        // Append delta to the last assistant message in the array
        // @Observable triggers view re-render immediately
        // UI scrolls to bottom

    case .toolCallStart(let call):
        // Append a ToolCallIndicator to the message
        // Shows "Running readFile..." with a spinner

    case .toolCallComplete(let result):
        // Update the ToolCallIndicator with result summary
        // Remove spinner, show completion state

    case .questionAsked(let question):
        // Present an inline question prompt
        // User types answer, calls chat.answerQuestion
        // Stream continues after answer

    case .complete(let finalMessage):
        // Replace streamed content with final message
        // Cache message to SwiftData
        // Set isStreaming = false

    case .error(let error):
        // Display error inline in the chat
        // Set isStreaming = false
        // Offer retry option
    }
}
```

### 3.3 Tool Call Display

When the AI invokes tools, the mobile app shows a compact inline indicator:

```
+--------------------------------------------------+
| [icon] Reading file: /src/main.swift...          |
+--------------------------------------------------+
           |
           v  (after completion)
+--------------------------------------------------+
| [checkmark] Read 42 lines from /src/main.swift  |
+--------------------------------------------------+
```

The mobile app does not show tool call details (file diffs, terminal output). It shows only the tool name and a brief summary.

---

## 4. State Synchronization

### 4.1 Full Sync (Initial)

Performed on first connection and after extended disconnection.

```
Mobile                                    Desktop
  |                                          |
  |  state.sync { lastSyncTimestamp: null }   |
  |----------------------------------------->|
  |                                          |
  |  Response: {                             |
  |    syncType: "full",                     |
  |    state: {                              |
  |      agents: [...],                      |
  |      departments: [...],                 |
  |      sessions: [...],                    |
  |      activeSession: {...},               |
  |      project: {...}                      |
  |    }                                     |
  |  }                                       |
  |<-----------------------------------------|
  |                                          |
  |  1. Clear local cache                    |
  |  2. Store all entities in SwiftData      |
  |  3. Update ViewModels                    |
  |  4. Record syncTimestamp                 |
  |                                          |
```

### 4.2 Incremental Sync (Reconnection)

Performed when reconnecting after a brief disconnection.

```
Mobile                                    Desktop
  |                                          |
  |  state.sync {                            |
  |    lastSyncTimestamp: "2026-03-11T14:30"  |
  |  }                                       |
  |----------------------------------------->|
  |                                          |
  |  Response: {                             |
  |    syncType: "incremental",              |
  |    state: {                              |
  |      sessions: [                         |
  |        { id: "s1", changes: {...} }      |
  |      ],                                  |
  |      deletions: ["s-old"]                |
  |    }                                     |
  |  }                                       |
  |<-----------------------------------------|
  |                                          |
  |  1. Merge changes into local cache       |
  |  2. Apply deletions                      |
  |  3. Update affected ViewModels           |
  |  4. Record new syncTimestamp             |
  |                                          |
```

### 4.3 Real-Time Updates (Steady State)

During normal operation, the server pushes state changes as notifications.

```
Mobile                                    Desktop
  |                                          |
  |  (steady state, subscribed)              |
  |                                          |
  |           state.sessionUpdated           |
  |  { sessionID: "s1",                     |
  |    changes: { messageCount: 26 } }       |
  |<-----------------------------------------|
  |                                          |
  |  1. Find session in cache               |
  |  2. Apply changes                        |
  |  3. SessionsViewModel auto-updates       |
  |                                          |
  |           state.agentChanged             |
  |  { agentID: "a2" }                      |
  |<-----------------------------------------|
  |                                          |
  |  1. Update active agent in cache         |
  |  2. ChatViewModel reflects new agent     |
  |                                          |
```

### 4.4 Conflict Resolution

Because the mobile app is primarily a **read-only** view of desktop state, true conflicts are rare. The conflict resolution strategy is:

| Scenario | Resolution |
|----------|------------|
| Session updated on desktop while mobile is disconnected | Desktop wins (server-authoritative) |
| Message sent from mobile while reconnecting | Queue locally, send on reconnect |
| Agent switched on desktop while mobile shows different agent | Desktop state takes precedence; mobile updates |
| Session archived on desktop while mobile views it | Show "session archived" notice; navigate away |

**The desktop is always the source of truth.** The mobile cache is a local replica that can be fully rebuilt from the desktop at any time.

---

## 5. Offline Behavior

### 5.1 Cached Data (Available Offline)

| Data | Cached? | Staleness Tolerance |
|------|---------|---------------------|
| Recent messages (last 1000 per session) | Yes | Read-only; shown with "offline" indicator |
| Session list | Yes | May be stale; refreshed on reconnect |
| Agent list | Yes | May be stale; refreshed on reconnect |
| Department structure | Yes | May be stale; refreshed on reconnect |
| Project tree (last snapshot) | Yes | May be stale; refreshed on reconnect |
| File contents | No | Fetched on demand only |
| Active AI stream | No | Cannot function offline |

### 5.2 Offline Message Queue

When the user attempts to send a message while disconnected:

```
1. User taps Send
2. ChatViewModel detects ConnectionState.disconnected
3. Message is stored locally with status = .pendingSync
4. UI shows the message with a "queued" indicator (clock icon)
5. On reconnection:
   a. Retrieve all pendingSync messages
   b. Send each via chat.sendMessage in order
   c. Update status to .synced
   d. Stream responses as normal
6. If reconnection fails permanently:
   a. Messages remain in local queue
   b. User can manually retry or discard
```

### 5.3 Cache Lifecycle

```
App Launch
    |
    v
+-------------------+
| Load cached state |
| from SwiftData    |
+--------+----------+
         |
         v
+-------------------+     Yes    +-----------------+
| Connected to      |---------->| Perform          |
| desktop?          |           | state.sync       |
+--------+----------+           +--------+---------+
         |                               |
         | No                            v
         v                      +-----------------+
+-------------------+           | Update cache    |
| Show cached data  |           | with fresh data |
| with offline      |           +-----------------+
| indicator         |
+-------------------+
```

### 5.4 Cache Eviction

| Rule | Threshold | Action |
|------|-----------|--------|
| Total cached messages | > 5000 | Remove oldest messages (FIFO) |
| Archived session messages | After 30 days | Remove from cache |
| Cache database size | > 50 MB | Aggressive pruning of oldest data |
| On successful full sync | -- | Replace all cached data with fresh state |

---

## 6. Error Handling Patterns

### 6.1 Error Classification

```swift
enum AppError {
    case tunnel(TunnelError)      // Connection/protocol issues
    case domain(DomainError)      // Business rule violations
    case persistence(PersistenceError) // Local database issues
    case unknown(Error)           // Unexpected errors
}

enum TunnelError {
    case connectionFailed(reason: String)
    case authenticationFailed
    case tokenExpired
    case timeout
    case serverError(code: Int, message: String)
    case disconnected
}
```

### 6.2 Error Propagation

```
Tunnel Error
    |
    v
Repository catches -> maps to DomainError
    |
    v
Use Case propagates (or handles silently)
    |
    v
ViewModel catches -> sets error state
    |
    v
View displays error UI (banner, inline, or alert)
```

### 6.3 Error UI Patterns

| Error Type | UI Treatment |
|------------|-------------|
| Connection lost | Persistent banner at top with "Reconnecting..." |
| Auth expired | Modal alert with "Re-pair" button |
| AI provider error | Inline message in chat with retry button |
| Rate limited | Inline message with countdown timer |
| Session not found | Navigate to session list, show toast |
| File not found | Inline error in file viewer |
| Network timeout | Retry button on affected view |

### 6.4 Retry Strategy

```swift
// Automatic retry for transient errors
func withRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?
    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            if !isRetryable(error) { throw error }
            try await Task.sleep(for: .seconds(delay * Double(attempt + 1)))
        }
    }
    throw lastError!
}

func isRetryable(_ error: Error) -> Bool {
    switch error {
    case let tunnelError as TunnelError:
        switch tunnelError {
        case .timeout, .disconnected: return true
        case .authenticationFailed, .tokenExpired: return false
        case .serverError(let code, _): return code >= 5000
        default: return false
        }
    default:
        return false
    }
}
```

---

## 7. Data Flow Diagrams Summary

### Complete System Data Flow

```
+------------------------------------------------------------------+
|                        TOONE MOBILE                               |
|                                                                   |
|  +-------------+     +------------+     +-------------------+     |
|  |  SwiftUI    |<--->| ViewModels |<--->|    Use Cases      |     |
|  |  Views      |     | @Observable|     | (Domain Layer)    |     |
|  +-------------+     +------------+     +--------+----------+     |
|                                                  |                |
|                                         +--------v----------+     |
|                                         |   Repositories    |     |
|                                         | (Data Layer)      |     |
|                                         +---+----------+----+     |
|                                             |          |          |
|                              +--------------+    +-----v------+   |
|                              |                   |            |   |
|                    +---------v--------+    +-----v------+     |   |
|                    |  Tunnel Client   |    | SwiftData  |     |   |
|                    |  (WebSocket)     |    | Cache      |     |   |
|                    +--------+---------+    +------------+     |   |
|                             |                                 |   |
+-----------------------------|---------------------------------+   |
                              |                                     |
                    +---------v---------+                            |
                    |  TOONE DESKTOP    |                            |
                    |  (WebSocket :9876)|                            |
                    |                   |                            |
                    |  AI CLI Process   |                            |
                    |  Project Files    |                            |
                    |  Browser Bridge   |                            |
                    +-------------------+                            |
```

### Data Ownership

| Data | Owner | Mobile Role |
|------|-------|-------------|
| Messages | Desktop | Read/write (send new, read history) |
| Sessions | Desktop | Read/write (archive, restore) |
| Agents | Desktop | Read-only (list, select) |
| Departments | Desktop | Read-only |
| Project tree | Desktop | Read-only |
| File contents | Desktop | Read-only |
| AI responses | Desktop | Read-only (display streamed content) |
| Connection tokens | Mobile Keychain | Read/write |
| Cached state | Mobile SwiftData | Read/write (local replica) |
| Pending messages | Mobile SwiftData | Read/write (offline queue) |
