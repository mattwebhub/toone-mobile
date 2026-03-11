# ADR-002: WebSocket Tunnel with JSON-RPC 2.0

**Date:** 2026-03-11
**Status:** Accepted
**Deciders:** Toone Mobile Team

---

## Context

Toone Mobile needs a communication protocol to connect to a running Toone Desktop instance. The protocol must support:

1. **Bidirectional communication.** The mobile app sends commands (send message, list agents) and the desktop pushes events (AI response stream, state changes).
2. **Streaming.** AI responses are generated incrementally and must be displayed in real-time as they arrive.
3. **Structured RPC.** The app needs a well-defined set of methods with typed request/response schemas.
4. **Low latency.** Chat interactions should feel immediate.
5. **Offline resilience.** The protocol must support reconnection with state reconciliation.

Toone Desktop already runs a WebSocket server on port 9876 for the BrowserBridge feature. This existing infrastructure provides a natural extension point.

We evaluated the following protocol options:

1. **REST API (HTTP).** Request/response over HTTP. Simple and well-understood. However, it does not support server-initiated push or streaming without long-polling or SSE (Server-Sent Events). SSE is unidirectional (server-to-client only). Polling introduces latency and wasted bandwidth.

2. **gRPC.** Efficient binary protocol with streaming support and strong typing via Protocol Buffers. However, gRPC requires HTTP/2 transport, which is harder to set up on a local network without proper TLS infrastructure. It also requires code generation tooling and is heavier than needed for this use case.

3. **WebSocket with custom protocol.** Raw WebSocket with a custom message format. Maximum flexibility but requires designing framing, error handling, and method dispatch from scratch. Easy to get wrong.

4. **WebSocket with JSON-RPC 2.0.** WebSocket for transport with JSON-RPC 2.0 for message framing. Combines the bidirectional nature of WebSocket with a standardized RPC format that includes request/response correlation, error handling, and notifications (server-to-client push without a request).

5. **MQTT.** Lightweight publish-subscribe protocol. Good for IoT scenarios but adds a broker dependency and is not a natural fit for RPC-style interactions.

## Decision

We adopt **WebSocket** as the transport layer and **JSON-RPC 2.0** as the message protocol.

### Key Design Choices

**Transport: WebSocket**
- Full-duplex communication over a single TCP connection.
- Toone Desktop already has a WebSocket server (BrowserBridge) on port 9876.
- iOS provides a native `URLSessionWebSocketTask` API with automatic TLS support.
- Efficient for long-lived connections with minimal overhead per message.

**Protocol: JSON-RPC 2.0**
- Industry standard (RFC, not a draft) with clear semantics for requests, responses, errors, and notifications.
- Request/response correlation via the `id` field.
- Notifications (no `id`) enable server-to-client push for streaming events.
- JSON is human-readable, simplifying debugging during development.
- No code generation required -- standard `Codable` in Swift.
- Extensible: new methods can be added without protocol version changes.

**Method Namespacing**
Methods are namespaced with dot notation: `auth.handshake`, `chat.sendMessage`, `project.tree`. This provides logical grouping and reduces naming collisions.

**Streaming via Notifications**
Long-running operations (AI response generation) use a hybrid approach:
1. The client sends a request (`chat.sendMessage`) and receives an immediate response with a `streamID`.
2. The server sends a series of notifications (`chat.messageStream`) tagged with the `streamID`.
3. A final notification with `event: "complete"` signals the stream end.

This avoids the complexity of multiplexed streaming protocols while maintaining JSON-RPC 2.0 compatibility.

## Consequences

### Positive

- **Reuses existing infrastructure.** The desktop's WebSocket server on port 9876 is extended rather than replaced.
- **Native iOS support.** `URLSessionWebSocketTask` handles connection management, TLS, and background task integration without third-party dependencies.
- **Debuggability.** JSON messages can be logged, inspected, and replayed during development. Network debugging tools (Proxyman, Charles) can inspect traffic.
- **Standardized error handling.** JSON-RPC 2.0 defines error codes and structure, reducing ad-hoc error format decisions.
- **Bidirectional by nature.** Server-initiated notifications enable real-time state updates and streaming without polling.
- **Low barrier to entry.** JSON-RPC 2.0 is simple to implement. No code generation, no schema compilation, no custom framing.

### Negative

- **JSON overhead.** JSON is more verbose than binary formats (Protocol Buffers, MessagePack). For this use case, message sizes are small (text content, metadata) so the overhead is negligible.
- **No built-in schema enforcement.** Unlike gRPC with `.proto` files, JSON-RPC does not enforce request/response schemas at the protocol level. Schema compliance must be enforced through shared documentation and client/server validation.
- **Single connection point of failure.** All communication flows through one WebSocket connection. If it drops, all operations are affected. Mitigated by automatic reconnection with exponential backoff.
- **No built-in multiplexing.** JSON-RPC 2.0 does not define multiplexed streams. Our `streamID` convention provides this capability but is not part of the standard.

### Mitigations

- Define comprehensive method documentation with request/response schemas (see `tunnel-protocol.md`).
- Implement schema validation in both client and server for development builds.
- Use `streamID` correlation to handle concurrent streams over the single connection.
- Implement robust reconnection logic with state reconciliation.

## Alternatives Considered

| Alternative | Rejection Reason |
|-------------|-----------------|
| REST + SSE | SSE is server-to-client only; requires two connections; no native WebSocket reuse |
| gRPC | Requires HTTP/2 setup, code generation tooling, heavier than needed |
| Custom WebSocket protocol | Higher risk of design errors; reinvents solved problems |
| MQTT | Requires a broker; publish-subscribe model is not ideal for RPC |
| Raw TCP sockets | No iOS high-level API; must handle framing, TLS, and reconnection manually |
