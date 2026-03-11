import Foundation

// MARK: - ConnectionManager

/// Higher-level connection orchestrator that manages authentication, initial sync,
/// and automatic reconnection with exponential backoff.
actor ConnectionManager {

    // MARK: - Properties

    private let tunnelClient: TunnelClient
    private let securityManager: SecurityManager?
    private var authToken: String?
    private var reconnectTask: Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?
    private var currentHost: String?
    private var currentPort: Int?

    private static let maxReconnectAttempts = 10
    private static let baseReconnectDelay: TimeInterval = 1.0
    private static let maxReconnectDelay: TimeInterval = 60.0

    // MARK: - Init

    init(tunnelClient: TunnelClient, securityManager: SecurityManager? = nil) {
        self.tunnelClient = tunnelClient
        self.securityManager = securityManager
    }

    // MARK: - Connection

    /// Connect to the desktop, perform handshake, and start monitoring.
    /// Returns the DesktopInfo from the handshake for the caller to use.
    @discardableResult
    func connect(host: String, port: Int, token: String?) async throws -> DesktopInfo {
        currentHost = host
        currentPort = port
        authToken = token

        try await tunnelClient.connect(host: host, port: port)
        let info = try await handshake(host: host, token: token)

        startConnectionMonitor()
        return info
    }

    /// Disconnect from the desktop and stop reconnection attempts.
    func disconnect() async {
        reconnectTask?.cancel()
        reconnectTask = nil
        monitorTask?.cancel()
        monitorTask = nil
        await tunnelClient.disconnect()
    }

    // MARK: - Handshake

    /// Perform the initial authentication handshake with the desktop.
    func handshake(host: String, token: String?) async throws -> DesktopInfo {
        var params: [String: AnyCodable] = [
            "clientType": "mobile-ios",
            "protocolVersion": "1.0"
        ]
        if let token {
            params["token"] = AnyCodable(string: token)
        }

        let response = try await tunnelClient.send(
            method: .authHandshake,
            params: params
        )

        if let rpcError = response.error {
            throw TunnelError.authenticationFailed(rpcError.message)
        }

        guard let result = response.result?.dictionaryValue else {
            throw TunnelError.invalidResponse
        }

        let roleString = result["role"]?.stringValue ?? "viewer"
        let role = ConnectionRole(rawValue: roleString) ?? .viewer

        let info = DesktopInfo(
            hostname: host,
            version: result["version"]?.stringValue ?? "unknown",
            workspaceName: result["workspaceName"]?.stringValue ?? result["projectName"]?.stringValue,
            role: role
        )

        // Store paired device info if security manager is available
        if let securityManager, let port = currentPort {
            let device = PairedDevice(
                host: host,
                port: port,
                certificateFingerprint: result["certificateFingerprint"]?.stringValue ?? "",
                role: role,
                pairedAt: Date(),
                lastConnectedAt: Date()
            )
            await securityManager.storePairedDevice(device)
        }

        return info
    }

    // MARK: - Initial Sync

    /// Perform the initial state synchronization after connecting.
    func initialSync() async throws -> SyncState {
        let response = try await tunnelClient.send(method: .stateSync)

        if let rpcError = response.error {
            throw TunnelError.rpcError(code: rpcError.code, message: rpcError.message)
        }

        guard let result = response.result?.dictionaryValue else {
            throw TunnelError.invalidResponse
        }

        let departments = DepartmentMapper.mapFromAnyCodableArray(result["departments"])
        let sessions = SessionMapper.mapFromAnyCodableArray(result["sessions"])
        let activeAgentId = result["activeAgentId"]?.stringValue
        let projectTree = ProjectFileMapper.mapFromAnyCodable(result["projectTree"])

        return SyncState(
            departments: departments,
            sessions: sessions,
            activeAgentId: activeAgentId,
            projectTree: projectTree
        )
    }

    // MARK: - Reconnection

    private func startConnectionMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            guard let self else { return }
            let stream = await tunnelClient.statusStream
            for await status in stream {
                guard !Task.isCancelled else { return }
                if case .failed = status {
                    await self.startReconnection()
                }
            }
        }
    }

    private func startReconnection() {
        guard reconnectTask == nil || reconnectTask?.isCancelled == true else { return }

        reconnectTask = Task { [weak self] in
            guard let self else { return }

            for attempt in 1...ConnectionManager.maxReconnectAttempts {
                guard !Task.isCancelled else { return }

                let delay = min(
                    ConnectionManager.baseReconnectDelay * pow(2.0, Double(attempt - 1)),
                    ConnectionManager.maxReconnectDelay
                )

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                guard !Task.isCancelled else { return }

                guard let host = await self.currentHost,
                      let port = await self.currentPort else {
                    return
                }

                do {
                    try await self.tunnelClient.connect(host: host, port: port)
                    _ = try await self.handshake(host: host, token: await self.authToken)
                    return
                } catch {
                    continue
                }
            }
        }
    }
}

// MARK: - SyncState

struct SyncState: Sendable {
    let departments: [Department]
    let sessions: [Session]
    let activeAgentId: String?
    let projectTree: ProjectFile?
}
