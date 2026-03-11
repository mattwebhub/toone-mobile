import Foundation

// MARK: - TunnelClient

/// WebSocket-based JSON-RPC 2.0 tunnel client for communicating with toone-desktop.
/// All operations are actor-isolated for thread safety.
actor TunnelClient {

    // MARK: - Properties

    private var webSocket: URLSessionWebSocketTask?
    private let session: URLSession
    private var pendingRequests: [String: CheckedContinuation<JSONRPCResponse, Error>] = [:]
    private var notificationHandlers: [String: @Sendable (JSONRPCNotification) -> Void] = [:]
    private var statusContinuation: AsyncStream<ConnectionStatus>.Continuation?
    private var requestCounter: Int = 0
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var currentHost: String?
    private var currentPort: Int?

    private static let requestTimeoutSeconds: TimeInterval = 30
    private static let pingIntervalSeconds: TimeInterval = 15

    // MARK: - Status Stream

    private(set) var currentStatus: ConnectionStatus = .disconnected

    /// An asynchronous stream that emits connection status changes.
    lazy var statusStream: AsyncStream<ConnectionStatus> = {
        AsyncStream { continuation in
            self.statusContinuation = continuation
            continuation.yield(self.currentStatus)
        }
    }()

    // MARK: - Init

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Connection

    /// Connect to the toone-desktop WebSocket server.
    func connect(host: String, port: Int) async throws {
        guard currentStatus == .disconnected || isReconnecting else {
            return
        }

        currentHost = host
        currentPort = port
        updateStatus(.connecting(host: host, port: port))

        guard let url = URL(string: "ws://\(host):\(port)/tunnel") else {
            throw TunnelError.connectionFailed("Invalid URL: ws://\(host):\(port)/tunnel")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let task = session.webSocketTask(with: request)
        task.resume()

        webSocket = task
        updateStatus(.authenticating)

        startReceiving()
        startPingLoop()
    }

    /// Disconnect from the WebSocket server and cancel all pending work.
    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        pingTask?.cancel()
        pingTask = nil

        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil

        cancelAllPendingRequests(with: TunnelError.notConnected)
        updateStatus(.disconnected)
    }

    // MARK: - Sending Requests

    /// Send a JSON-RPC request and wait for the corresponding response.
    func send(method: TunnelMethod, params: (any Encodable)? = nil) async throws -> JSONRPCResponse {
        guard let webSocket else {
            throw TunnelError.notConnected
        }

        let requestId = nextRequestId()
        let rpcParams: AnyCodable? = try params.map { try AnyCodable.from($0) }

        let request = JSONRPCRequest(method: method.rawValue, params: rpcParams, id: requestId)
        let data = try JSONEncoder().encode(request)

        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocket.send(message)

        return try await withCheckedThrowingContinuation { continuation in
            pendingRequests[requestId] = continuation

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(TunnelClient.requestTimeoutSeconds * 1_000_000_000))
                await self?.timeoutRequest(id: requestId)
            }
        }
    }

    // MARK: - Notifications

    /// Register a handler for incoming JSON-RPC notifications of the given method.
    func onNotification(method: TunnelMethod, handler: @escaping @Sendable (JSONRPCNotification) -> Void) {
        notificationHandlers[method.rawValue] = handler
    }

    /// Remove the notification handler for the given method.
    func removeNotificationHandler(for method: TunnelMethod) {
        notificationHandlers.removeValue(forKey: method.rawValue)
    }

    // MARK: - Receiving

    private func startReceiving() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.receiveMessages()
        }
    }

    private func receiveMessages() async {
        guard let webSocket else { return }

        while !Task.isCancelled {
            do {
                let message = try await webSocket.receive()
                switch message {
                case .data(let data):
                    handleMessage(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        handleMessage(data)
                    }
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    handleDisconnection()
                }
                return
            }
        }
    }

    private func handleMessage(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let response = try? decoder.decode(JSONRPCResponse.self, from: data),
           let id = response.id,
           let continuation = pendingRequests.removeValue(forKey: id) {
            continuation.resume(returning: response)
            return
        }

        if let notification = try? decoder.decode(JSONRPCNotification.self, from: data) {
            let method = notification.method
            if let handler = notificationHandlers[method] {
                handler(notification)
            }
            return
        }
    }

    // MARK: - Ping/Pong

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(TunnelClient.pingIntervalSeconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await self?.sendPing()
            }
        }
    }

    private func sendPing() {
        webSocket?.sendPing { [weak self] error in
            if error != nil {
                Task { await self?.handleDisconnection() }
            }
        }
    }

    // MARK: - Reconnection

    private var isReconnecting: Bool {
        if case .reconnecting = currentStatus { return true }
        return false
    }

    private func handleDisconnection() {
        webSocket?.cancel(with: .abnormalClosure, reason: nil)
        webSocket = nil

        receiveTask?.cancel()
        receiveTask = nil
        pingTask?.cancel()
        pingTask = nil

        cancelAllPendingRequests(with: TunnelError.notConnected)
        updateStatus(.failed(.desktopDisconnected))
    }

    // MARK: - Helpers

    private func nextRequestId() -> String {
        requestCounter += 1
        return "req_\(requestCounter)"
    }

    private func timeoutRequest(id: String) {
        if let continuation = pendingRequests.removeValue(forKey: id) {
            continuation.resume(throwing: TunnelError.requestTimeout)
        }
    }

    private func cancelAllPendingRequests(with error: Error) {
        let pending = pendingRequests
        pendingRequests.removeAll()
        for (_, continuation) in pending {
            continuation.resume(throwing: error)
        }
    }

    private func updateStatus(_ status: ConnectionStatus) {
        currentStatus = status
        statusContinuation?.yield(status)
    }
}
