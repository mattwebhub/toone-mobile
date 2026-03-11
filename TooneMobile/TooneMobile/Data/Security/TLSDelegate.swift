import Foundation
import CryptoKit

// MARK: - TLSDelegate

/// A URLSession delegate that performs certificate pinning for TLS connections.
/// Validates server certificates against a pinned SHA-256 fingerprint.
///
/// Supports two modes:
/// - **Pinned mode:** An expected fingerprint is provided; connections are rejected if
///   the server certificate does not match.
/// - **Pairing mode:** No fingerprint is set; connections are allowed and the server
///   certificate fingerprint is captured for the caller to store.
final class TLSDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {

    // MARK: - Properties

    private let lock = NSLock()
    private var _expectedFingerprint: String?
    private var _lastSeenFingerprint: String?

    /// The expected certificate fingerprint for pinned validation.
    /// If `nil`, operates in pairing mode (trust-on-first-use).
    var expectedFingerprint: String? {
        get { lock.withLock { _expectedFingerprint } }
        set { lock.withLock { _expectedFingerprint = newValue } }
    }

    /// The fingerprint of the last server certificate seen during a TLS handshake.
    /// Useful for capturing the fingerprint during the initial pairing flow.
    var lastSeenFingerprint: String? {
        lock.withLock { _lastSeenFingerprint }
    }

    // MARK: - Init

    /// Create a TLS delegate.
    /// - Parameter expectedFingerprint: The pinned certificate fingerprint, or `nil` for pairing mode.
    init(expectedFingerprint: String? = nil) {
        self._expectedFingerprint = expectedFingerprint
        super.init()
    }

    // MARK: - URLSessionDelegate

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Extract the leaf certificate fingerprint
        guard let fingerprint = computeFingerprint(from: serverTrust) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Store the last seen fingerprint for pairing flow
        lock.withLock {
            _lastSeenFingerprint = fingerprint
        }

        let pinned = lock.withLock { _expectedFingerprint }

        if let pinned {
            // Pinned mode: validate against expected fingerprint
            if fingerprint.lowercased() == pinned.lowercased() {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            // Pairing mode: allow connection, fingerprint is captured above
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        }
    }

    // MARK: - Fingerprint Computation

    /// Compute the SHA-256 fingerprint of the leaf certificate in a trust object.
    private func computeFingerprint(from trust: SecTrust) -> String? {
        guard SecTrustGetCertificateCount(trust) > 0,
              let chain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leafCert = chain.first else {
            return nil
        }

        let certData = SecCertificateCopyData(leafCert) as Data
        let hash = SHA256.hash(data: certData)
        return hash.map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}
