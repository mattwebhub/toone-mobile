import Foundation
import Security
import CryptoKit

// MARK: - PairedDevice

/// Represents a desktop device that has been paired with this mobile client.
public struct PairedDevice: Codable, Sendable, Equatable {
    public let host: String
    public let port: Int
    public let certificateFingerprint: String
    public let role: ConnectionRole
    public let pairedAt: Date
    public var lastConnectedAt: Date?

    public init(
        host: String,
        port: Int,
        certificateFingerprint: String,
        role: ConnectionRole,
        pairedAt: Date,
        lastConnectedAt: Date? = nil
    ) {
        self.host = host
        self.port = port
        self.certificateFingerprint = certificateFingerprint
        self.role = role
        self.pairedAt = pairedAt
        self.lastConnectedAt = lastConnectedAt
    }
}

// MARK: - SecurityManager

/// Manages certificate pinning, paired device storage, and TLS validation.
/// All operations are actor-isolated for thread safety.
actor SecurityManager {

    // MARK: - Constants

    private static let keychainService = "com.toone.mobile.paired-devices"
    private static let keychainAccount = "paired-devices-list"

    // MARK: - Paired Device Storage

    /// Store a paired device in the Keychain, replacing any existing entry for the same host.
    func storePairedDevice(_ device: PairedDevice) {
        var devices = loadDevicesFromKeychain()
        devices.removeAll { $0.host == device.host }
        devices.append(device)
        saveDevicesToKeychain(devices)
    }

    /// Retrieve a paired device for the given host, if one exists.
    func getPairedDevice(forHost host: String) -> PairedDevice? {
        let devices = loadDevicesFromKeychain()
        return devices.first { $0.host == host }
    }

    /// Remove a paired device for the given host from the Keychain.
    func removePairedDevice(forHost host: String) {
        var devices = loadDevicesFromKeychain()
        devices.removeAll { $0.host == host }
        saveDevicesToKeychain(devices)
    }

    /// List all paired devices stored in the Keychain.
    func listPairedDevices() -> [PairedDevice] {
        loadDevicesFromKeychain()
    }

    // MARK: - Certificate Validation

    /// Validate a server certificate against the expected pinned fingerprint.
    /// Returns `true` if the certificate's SHA-256 fingerprint matches the expected value.
    func validateCertificate(_ trust: SecTrust, expectedFingerprint: String) -> Bool {
        guard let fingerprint = extractFingerprint(from: trust) else {
            return false
        }
        return fingerprint.lowercased() == expectedFingerprint.lowercased()
    }

    /// Extract the SHA-256 fingerprint from the leaf certificate in a trust object.
    func extractFingerprint(from trust: SecTrust) -> String? {
        guard SecTrustGetCertificateCount(trust) > 0,
              let certificate = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leafCert = certificate.first else {
            return nil
        }

        let certData = SecCertificateCopyData(leafCert) as Data
        let hash = SHA256.hash(data: certData)
        return hash.map { String(format: "%02x", $0) }.joined(separator: ":")
    }

    // MARK: - Keychain Helpers

    private func loadDevicesFromKeychain() -> [PairedDevice] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecurityManager.keychainService,
            kSecAttrAccount as String: SecurityManager.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PairedDevice].self, from: data)) ?? []
    }

    private func saveDevicesToKeychain(_ devices: [PairedDevice]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(devices) else { return }

        // Try to update existing item first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecurityManager.keychainService,
            kSecAttrAccount as String: SecurityManager.keychainAccount
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item doesn't exist yet, add it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    /// Delete all paired device data from the Keychain.
    func clearAllPairedDevices() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: SecurityManager.keychainService,
            kSecAttrAccount as String: SecurityManager.keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
