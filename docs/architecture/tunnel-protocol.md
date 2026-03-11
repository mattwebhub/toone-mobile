# Toone Mobile -- Tunnel Protocol Specification

**Version:** 1.0
**Last Updated:** 2026-03-11
**Status:** Draft

---

## 1. Overview

The Toone Tunnel Protocol enables bidirectional communication between Toone Mobile and a running Toone Desktop instance. It uses **JSON-RPC 2.0** over a **WebSocket** connection. The desktop acts as the server; the mobile app acts as the client.

### Design Principles

- **Thin client:** The mobile app sends commands and receives state; all AI processing happens on the desktop.
- **Stream-friendly:** Long-running operations (AI responses) use JSON-RPC notifications to stream incremental data.
- **Offline-tolerant:** The protocol supports reconnection with state reconciliation.
- **Secure by default:** TLS encryption, token-based authentication, local network only.

---

## 2. Transport

| Property | Value |
|----------|-------|
| Transport | WebSocket (RFC 6455) |
| Default Port | 9876 |
| Path | `/toone/mobile` |
| Subprotocol | `toone-tunnel-v1` |
| Message Format | JSON (UTF-8 text frames) |
| Max Frame Size | 1 MB |
| Compression | permessage-deflate (optional) |

### URL Format

```
wss://<desktop-ip>:9876/toone/mobile
```

When TLS is not available (e.g., development on local network):

```
ws://<desktop-ip>:9876/toone/mobile
```

---

## 3. JSON-RPC 2.0 Conventions

All messages conform to the JSON-RPC 2.0 specification.

### Request

```json
{
    "jsonrpc": "2.0",
    "id": "unique-request-id",
    "method": "namespace.methodName",
    "params": { ... }
}
```

### Response (success)

```json
{
    "jsonrpc": "2.0",
    "id": "unique-request-id",
    "result": { ... }
}
```

### Response (error)

```json
{
    "jsonrpc": "2.0",
    "id": "unique-request-id",
    "error": {
        "code": -32600,
        "message": "Invalid request",
        "data": { ... }
    }
}
```

### Notification (server-to-client, no `id`)

```json
{
    "jsonrpc": "2.0",
    "method": "chat.messageStream",
    "params": { ... }
}
```

### ID Generation

Request IDs must be unique per connection session. Recommended format: UUID v4 string.

---

## 4. Connection Lifecycle

```
+--------+                                              +----------+
| Mobile |                                              | Desktop  |
+---+----+                                              +----+-----+
    |                                                        |
    |  1. WebSocket CONNECT (wss://ip:9876/toone/mobile)     |
    |------------------------------------------------------->|
    |                                                        |
    |  2. HTTP 101 Switching Protocols                       |
    |<-------------------------------------------------------|
    |                                                        |
    |  3. auth.handshake (device info, token if reconnect)   |
    |------------------------------------------------------->|
    |                                                        |
    |  4. auth.handshake response (session token, config)    |
    |<-------------------------------------------------------|
    |                                                        |
    |  5. state.sync (request full state snapshot)           |
    |------------------------------------------------------->|
    |                                                        |
    |  6. state.sync response (agents, sessions, project)    |
    |<-------------------------------------------------------|
    |                                                        |
    |  7. state.subscribe (register for change notifications)|
    |------------------------------------------------------->|
    |                                                        |
    |  8. state.subscribe response (subscription confirmed)  |
    |<-------------------------------------------------------|
    |                                                        |
    |  ---- STEADY STATE: bidirectional RPC + notifications -|
    |                                                        |
    |  N. connection.ping / pong (keep-alive every 30s)      |
    |<------------------------------------------------------>|
    |                                                        |
    |  X. WebSocket CLOSE (1000 Normal Closure)              |
    |------------------------------------------------------->|
    |                                                        |
```

### 4.1 Discovery

The mobile app discovers the desktop instance through one of two methods:

**QR Code (recommended):**
The desktop displays a QR code encoding a JSON payload:

```json
{
    "host": "192.168.1.42",
    "port": 9876,
    "path": "/toone/mobile",
    "pairingToken": "ephemeral-one-time-token",
    "tls": true
}
```

**Manual Entry:**
The user enters the desktop's IP address. The mobile app attempts to connect on port 9876.

### 4.2 Handshake

After the WebSocket connection is established, the mobile app must authenticate.

### 4.3 Steady State

During steady state, the client may send RPC requests and the server may send notifications at any time. The client should maintain a keep-alive ping every 30 seconds.

### 4.4 Disconnection

Either side may close the WebSocket with a standard close frame. The mobile app should attempt automatic reconnection using the strategy defined in Section 9.

---

## 5. Method Definitions

### 5.1 Authentication

#### `auth.handshake`

Initiates authentication. Called immediately after WebSocket connection.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "auth.handshake",
    "params": {
        "clientVersion": "1.0.0",
        "clientType": "ios",
        "deviceID": "unique-device-identifier",
        "deviceName": "Matheus's iPhone",
        "pairingToken": "ephemeral-one-time-token",
        "sessionToken": null
    }
}
```

- `pairingToken`: Required for first-time pairing (from QR code). Null on reconnect.
- `sessionToken`: Required for reconnection. Null on first pairing.

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "1",
    "result": {
        "sessionToken": "jwt-session-token",
        "tokenExpiry": "2026-03-12T10:30:00Z",
        "desktopVersion": "2.5.0",
        "desktopName": "Matheus's MacBook Pro",
        "capabilities": [
            "chat",
            "project.read",
            "agent.list",
            "agent.switch",
            "session.manage",
            "browser.status"
        ],
        "config": {
            "maxMessageLength": 100000,
            "streamBufferSize": 4096,
            "keepAliveInterval": 30
        }
    }
}
```

#### `auth.verify`

Verifies an existing session token without full re-handshake. Used on reconnection.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "2",
    "method": "auth.verify",
    "params": {
        "sessionToken": "jwt-session-token"
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "2",
    "result": {
        "valid": true,
        "tokenExpiry": "2026-03-12T10:30:00Z",
        "renewedToken": "new-jwt-if-near-expiry-or-null"
    }
}
```

---

### 5.2 State Synchronization

#### `state.sync`

Requests a full state snapshot from the desktop.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "3",
    "method": "state.sync",
    "params": {
        "lastSyncTimestamp": null,
        "include": ["agents", "sessions", "departments", "activeSession", "project"]
    }
}
```

- `lastSyncTimestamp`: If provided, the server returns only changes since this timestamp (incremental sync). Null for full sync.
- `include`: Array of state domains to include. Omit for all.

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "3",
    "result": {
        "syncTimestamp": "2026-03-11T14:30:00Z",
        "syncType": "full",
        "state": {
            "agents": [
                {
                    "id": "agent-1",
                    "name": "Content Writer",
                    "departmentID": "dept-1",
                    "role": "Creates blog posts and articles",
                    "isActive": true
                }
            ],
            "departments": [
                {
                    "id": "dept-1",
                    "name": "Content",
                    "description": "Content creation department",
                    "agentIDs": ["agent-1", "agent-2"]
                }
            ],
            "sessions": [
                {
                    "id": "session-1",
                    "title": "Blog post draft",
                    "agentID": "agent-1",
                    "createdAt": "2026-03-11T09:00:00Z",
                    "lastActivityAt": "2026-03-11T14:25:00Z",
                    "messageCount": 24,
                    "isArchived": false
                }
            ],
            "activeSession": {
                "sessionID": "session-1",
                "agentID": "agent-1"
            },
            "project": {
                "name": "my-project",
                "rootPath": "/Users/matheus/Projects/my-project"
            }
        }
    }
}
```

#### `state.subscribe`

Subscribes to real-time state change notifications.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "4",
    "method": "state.subscribe",
    "params": {
        "events": [
            "state.agentChanged",
            "state.sessionUpdated",
            "state.sessionCreated",
            "state.sessionArchived",
            "state.projectChanged",
            "state.connectionStatus"
        ]
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "4",
    "result": {
        "subscriptionID": "sub-1",
        "subscribedEvents": [
            "state.agentChanged",
            "state.sessionUpdated",
            "state.sessionCreated",
            "state.sessionArchived",
            "state.projectChanged",
            "state.connectionStatus"
        ]
    }
}
```

**Notification (server-to-client):**

```json
{
    "jsonrpc": "2.0",
    "method": "state.sessionUpdated",
    "params": {
        "subscriptionID": "sub-1",
        "timestamp": "2026-03-11T14:35:00Z",
        "data": {
            "sessionID": "session-1",
            "changes": {
                "messageCount": 26,
                "lastActivityAt": "2026-03-11T14:35:00Z"
            }
        }
    }
}
```

---

### 5.3 Chat

#### `chat.sendMessage`

Sends a user message. The AI response is delivered as a series of `chat.messageStream` notifications.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "5",
    "method": "chat.sendMessage",
    "params": {
        "sessionID": "session-1",
        "content": "Write a blog post about Swift concurrency",
        "attachments": []
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "5",
    "result": {
        "messageID": "msg-user-42",
        "streamID": "stream-7",
        "timestamp": "2026-03-11T14:36:00Z"
    }
}
```

The `streamID` correlates subsequent `chat.messageStream` notifications to this request.

#### `chat.messageStream` (notification)

Delivered by the server as the AI generates its response. Multiple notifications per `streamID`.

**Text delta:**

```json
{
    "jsonrpc": "2.0",
    "method": "chat.messageStream",
    "params": {
        "streamID": "stream-7",
        "sessionID": "session-1",
        "event": "textDelta",
        "data": {
            "delta": "Here's a comprehensive guide to "
        }
    }
}
```

**Stream complete:**

```json
{
    "jsonrpc": "2.0",
    "method": "chat.messageStream",
    "params": {
        "streamID": "stream-7",
        "sessionID": "session-1",
        "event": "complete",
        "data": {
            "messageID": "msg-asst-43",
            "totalTokens": 1250,
            "finishReason": "stop"
        }
    }
}
```

**Stream error:**

```json
{
    "jsonrpc": "2.0",
    "method": "chat.messageStream",
    "params": {
        "streamID": "stream-7",
        "sessionID": "session-1",
        "event": "error",
        "data": {
            "code": "AI_PROVIDER_ERROR",
            "message": "Rate limit exceeded. Retry after 60 seconds."
        }
    }
}
```

#### `chat.toolCall` (notification)

Delivered when the AI invokes a tool during response generation.

```json
{
    "jsonrpc": "2.0",
    "method": "chat.toolCall",
    "params": {
        "streamID": "stream-7",
        "sessionID": "session-1",
        "event": "toolCallStart",
        "data": {
            "toolCallID": "tc-1",
            "toolName": "readFile",
            "arguments": {
                "path": "/src/main.swift"
            }
        }
    }
}
```

```json
{
    "jsonrpc": "2.0",
    "method": "chat.toolCall",
    "params": {
        "streamID": "stream-7",
        "sessionID": "session-1",
        "event": "toolCallComplete",
        "data": {
            "toolCallID": "tc-1",
            "toolName": "readFile",
            "result": "success",
            "summary": "Read 42 lines from /src/main.swift"
        }
    }
}
```

#### `chat.answerQuestion`

Responds to a question from the AI (e.g., "Should I proceed with this change?").

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "6",
    "method": "chat.answerQuestion",
    "params": {
        "streamID": "stream-7",
        "questionID": "q-1",
        "answer": "Yes, proceed"
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "6",
    "result": {
        "acknowledged": true
    }
}
```

---

### 5.4 Agents

#### `agent.list`

Returns all available agents with their department associations.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "7",
    "method": "agent.list",
    "params": {}
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "7",
    "result": {
        "agents": [
            {
                "id": "agent-1",
                "name": "Content Writer",
                "departmentID": "dept-1",
                "departmentName": "Content",
                "role": "Creates blog posts and articles",
                "systemPrompt": "You are a professional content writer...",
                "isActive": true
            }
        ],
        "departments": [
            {
                "id": "dept-1",
                "name": "Content",
                "description": "Content creation department",
                "agentIDs": ["agent-1", "agent-2"]
            }
        ]
    }
}
```

#### `agent.switch`

Switches the active agent for the current or specified session.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "8",
    "method": "agent.switch",
    "params": {
        "agentID": "agent-2",
        "sessionID": "session-1"
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "8",
    "result": {
        "agent": {
            "id": "agent-2",
            "name": "Code Reviewer",
            "departmentID": "dept-2",
            "role": "Reviews code for quality and correctness",
            "isActive": true
        },
        "sessionID": "session-1"
    }
}
```

---

### 5.5 Sessions

#### `session.list`

Returns session history with optional filtering.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "9",
    "method": "session.list",
    "params": {
        "filter": {
            "isArchived": false,
            "agentID": null,
            "searchQuery": null
        },
        "sort": "lastActivityAt",
        "order": "desc",
        "limit": 50,
        "offset": 0
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "9",
    "result": {
        "sessions": [
            {
                "id": "session-1",
                "title": "Blog post draft",
                "agentID": "agent-1",
                "agentName": "Content Writer",
                "createdAt": "2026-03-11T09:00:00Z",
                "lastActivityAt": "2026-03-11T14:25:00Z",
                "messageCount": 24,
                "isArchived": false,
                "previewText": "Write a blog post about Swift concurrency..."
            }
        ],
        "total": 142,
        "hasMore": true
    }
}
```

#### `session.archive`

Archives a session (soft delete).

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "10",
    "method": "session.archive",
    "params": {
        "sessionID": "session-1"
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "10",
    "result": {
        "sessionID": "session-1",
        "archivedAt": "2026-03-11T15:00:00Z"
    }
}
```

#### `session.restore`

Restores a previously archived session.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "11",
    "method": "session.restore",
    "params": {
        "sessionID": "session-1"
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "11",
    "result": {
        "sessionID": "session-1",
        "restoredAt": "2026-03-11T15:05:00Z"
    }
}
```

---

### 5.6 Project

#### `project.tree`

Returns the project file tree. Read-only on mobile.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "12",
    "method": "project.tree",
    "params": {
        "path": "/",
        "depth": 3,
        "includeHidden": false,
        "excludePatterns": ["node_modules", ".git", ".build"]
    }
}
```

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "12",
    "result": {
        "root": {
            "name": "my-project",
            "path": "/",
            "type": "directory",
            "children": [
                {
                    "name": "Sources",
                    "path": "/Sources",
                    "type": "directory",
                    "children": [
                        {
                            "name": "main.swift",
                            "path": "/Sources/main.swift",
                            "type": "file",
                            "size": 1024,
                            "modifiedAt": "2026-03-11T10:00:00Z"
                        }
                    ]
                },
                {
                    "name": "Package.swift",
                    "path": "/Package.swift",
                    "type": "file",
                    "size": 512,
                    "modifiedAt": "2026-03-10T16:00:00Z"
                }
            ]
        },
        "totalFiles": 47,
        "totalDirectories": 12
    }
}
```

#### `project.readFile`

Reads file contents from the desktop project. Read-only.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "13",
    "method": "project.readFile",
    "params": {
        "path": "/Sources/main.swift",
        "encoding": "utf-8",
        "lineRange": null
    }
}
```

- `lineRange`: Optional `{ "start": 1, "end": 50 }` to read a subset of lines.

**Response (success):**

```json
{
    "jsonrpc": "2.0",
    "id": "13",
    "result": {
        "path": "/Sources/main.swift",
        "content": "import Foundation\n\n@main\nstruct App { ... }",
        "encoding": "utf-8",
        "totalLines": 42,
        "language": "swift",
        "size": 1024
    }
}
```

---

### 5.7 Connection Management

#### `connection.ping`

Keep-alive ping. Both client and server may initiate.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "14",
    "method": "connection.ping",
    "params": {
        "timestamp": "2026-03-11T14:30:00Z"
    }
}
```

**Response:**

```json
{
    "jsonrpc": "2.0",
    "id": "14",
    "result": {
        "timestamp": "2026-03-11T14:30:00.005Z",
        "serverTime": "2026-03-11T14:30:00.005Z"
    }
}
```

#### `connection.status`

Requests the desktop's current operational status.

**Request:**

```json
{
    "jsonrpc": "2.0",
    "id": "15",
    "method": "connection.status",
    "params": {}
}
```

**Response:**

```json
{
    "jsonrpc": "2.0",
    "id": "15",
    "result": {
        "desktopStatus": "active",
        "activeWorkspace": "my-project",
        "aiProvider": "claude",
        "aiStatus": "idle",
        "browserStatus": {
            "isOpen": true,
            "url": "https://example.com",
            "title": "Example Page"
        },
        "connectedClients": 1,
        "uptime": 3600
    }
}
```

---

## 6. Error Codes

### Standard JSON-RPC Errors

| Code | Message | Description |
|------|---------|-------------|
| -32700 | Parse error | Invalid JSON |
| -32600 | Invalid request | Missing required JSON-RPC fields |
| -32601 | Method not found | Unknown method name |
| -32602 | Invalid params | Invalid method parameters |
| -32603 | Internal error | Server-side error |

### Application-Specific Errors

| Code | Message | Description |
|------|---------|-------------|
| 1001 | Authentication failed | Invalid pairing token or session token |
| 1002 | Token expired | Session token has expired; re-authenticate |
| 1003 | Unauthorized | Insufficient capabilities for this method |
| 1004 | Device not paired | Device ID is not recognized |
| 2001 | Session not found | Requested session does not exist |
| 2002 | Session archived | Cannot send messages to an archived session |
| 2003 | Agent not found | Requested agent does not exist |
| 2004 | Agent unavailable | Agent is currently disabled |
| 3001 | File not found | Requested file path does not exist |
| 3002 | File too large | File exceeds the maximum readable size |
| 3003 | Path not allowed | Path is outside the project root |
| 4001 | AI provider error | Upstream AI provider returned an error |
| 4002 | AI rate limited | AI provider rate limit exceeded |
| 4003 | AI busy | Another AI request is already in progress |
| 5001 | Sync conflict | State sync encountered a conflict |
| 5002 | Sync timeout | State sync did not complete in time |

---

## 7. Notification Events Summary

| Notification Method | Direction | Description |
|---------------------|-----------|-------------|
| `chat.messageStream` | Server -> Client | Streamed AI response events |
| `chat.toolCall` | Server -> Client | Tool call start/complete during AI response |
| `chat.questionAsked` | Server -> Client | AI is asking the user a question |
| `state.agentChanged` | Server -> Client | Active agent was changed (from desktop) |
| `state.sessionUpdated` | Server -> Client | Session metadata changed |
| `state.sessionCreated` | Server -> Client | New session was created (from desktop) |
| `state.sessionArchived` | Server -> Client | Session was archived (from desktop) |
| `state.projectChanged` | Server -> Client | Project tree or active project changed |
| `state.connectionStatus` | Server -> Client | Desktop status changed (AI busy, browser open) |

---

## 8. Message Stream Events

The `chat.messageStream` notification carries an `event` field that can be one of:

| Event | Description | Data Fields |
|-------|-------------|-------------|
| `textDelta` | Incremental text from the AI | `delta` (string) |
| `toolCallStart` | AI invoked a tool | `toolCallID`, `toolName`, `arguments` |
| `toolCallComplete` | Tool execution finished | `toolCallID`, `result`, `summary` |
| `questionAsked` | AI is asking a question | `questionID`, `question`, `options` |
| `complete` | Stream finished successfully | `messageID`, `totalTokens`, `finishReason` |
| `error` | Stream encountered an error | `code`, `message` |

---

## 9. Reconnection Strategy

The mobile app implements exponential backoff with jitter for reconnection.

### Algorithm

```
attempt = 0
maxAttempts = 10
baseDelay = 1.0 seconds
maxDelay = 60.0 seconds

while attempt < maxAttempts:
    delay = min(baseDelay * (2 ^ attempt), maxDelay)
    jitter = random(0, delay * 0.3)
    wait(delay + jitter)

    try connect()
    if success:
        // Send auth.verify with stored session token
        // If token valid: send state.sync with lastSyncTimestamp
        // If token expired: full re-authentication
        break

    attempt += 1

if attempt >= maxAttempts:
    // Notify user, offer manual retry
```

### Reconnection Behavior

| Scenario | Action |
|----------|--------|
| Network lost briefly (< 30s) | Automatic reconnect, incremental sync |
| Network lost extended (30s - 5min) | Automatic reconnect, full sync |
| Token expired during disconnect | Full re-authentication |
| Desktop restarted | Full re-authentication + full sync |
| Max attempts exceeded | Show error, offer manual retry |
| App backgrounded | Disconnect after 5 minutes, reconnect on foreground |

### State Reconciliation on Reconnect

1. Send `auth.verify` with stored session token.
2. If valid, send `state.sync` with `lastSyncTimestamp`.
3. Server returns incremental changes since that timestamp.
4. Client merges changes with locally cached state.
5. Resume `state.subscribe` for real-time updates.

---

## 10. Security Considerations

### 10.1 Transport Security

- **TLS required** for connections outside `localhost` / `127.0.0.1`.
- The desktop generates a self-signed certificate on first run. The mobile app performs certificate pinning after initial pairing.
- For local development, plain `ws://` is permitted on `127.0.0.1` and link-local addresses only.

### 10.2 Authentication

- **Pairing tokens** are ephemeral, single-use, and expire after 5 minutes. They are displayed on the desktop (QR code) and transmitted once during `auth.handshake`.
- **Session tokens** are JWTs signed by the desktop's private key. They contain the device ID, capabilities, and expiry.
- Session tokens are stored in the iOS Keychain, never in UserDefaults or on disk.
- Token rotation: the server may issue a `renewedToken` in `auth.verify` responses when the current token is within 20% of its TTL.

### 10.3 Authorization

Each paired device has a capability set defined during handshake. The server enforces capabilities per method:

| Capability | Methods Allowed |
|------------|-----------------|
| `chat` | `chat.*` |
| `project.read` | `project.tree`, `project.readFile` |
| `agent.list` | `agent.list` |
| `agent.switch` | `agent.switch` |
| `session.manage` | `session.*` |
| `browser.status` | `connection.status` (browser fields) |

### 10.4 Local-Only Default

By default, the desktop only accepts WebSocket connections from the local network (private IP ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, and `127.0.0.0/8`). Remote access requires explicit opt-in with mandatory TLS and a strong pairing token.

### 10.5 Rate Limiting

The server enforces per-client rate limits:

| Method Pattern | Limit |
|---------------|-------|
| `chat.sendMessage` | 10 requests / minute |
| `project.readFile` | 60 requests / minute |
| `connection.ping` | 4 requests / minute |
| All others | 30 requests / minute |

---

## 11. Versioning

The protocol version is communicated during `auth.handshake` via the WebSocket subprotocol header (`toone-tunnel-v1`).

### Backward Compatibility

- Minor additions (new optional fields, new notification types) do not change the version.
- Breaking changes (removed fields, changed semantics) increment the version.
- The server should support the current and previous protocol version simultaneously.
- The client should ignore unknown fields and unknown notification methods gracefully.
