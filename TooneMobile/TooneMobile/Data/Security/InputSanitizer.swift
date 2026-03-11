import Foundation

// MARK: - InputSanitizer

/// Utility for sanitizing and validating user input before it is sent over the tunnel.
enum InputSanitizer {

    // MARK: - Text Sanitization

    /// Sanitize a text string by truncating to `maxLength` and stripping
    /// control characters (except newline and tab).
    static func sanitizeText(_ text: String, maxLength: Int = 100_000) -> String {
        let truncated = String(text.prefix(maxLength))
        return truncated.unicodeScalars
            .filter { scalar in
                // Allow newline (\n), carriage return (\r), and tab (\t)
                if scalar == "\n" || scalar == "\r" || scalar == "\t" {
                    return true
                }
                // Strip other control characters (C0 and C1 ranges)
                if CharacterSet.controlCharacters.contains(scalar) {
                    return false
                }
                return true
            }
            .map { String($0) }
            .joined()
    }

    // MARK: - URL Validation

    /// Validate that a URL string is safe for loading images.
    /// Allows HTTPS universally, and HTTP only for local/private IP addresses.
    /// Rejects `file://`, `javascript://`, `data://`, and other unsafe schemes.
    static func isValidImageURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              let host = url.host else {
            return false
        }

        // Reject unsafe schemes
        let blockedSchemes: Set<String> = ["file", "javascript", "data", "ftp"]
        if blockedSchemes.contains(scheme) {
            return false
        }

        // HTTPS is always allowed
        if scheme == "https" {
            return true
        }

        // HTTP is only allowed for local/private IPs
        if scheme == "http" {
            return isLocalOrPrivateIP(host)
        }

        return false
    }

    // MARK: - Host Validation

    /// Validate that a string is a valid hostname or IP address.
    static func isValidHost(_ host: String) -> Bool {
        guard !host.isEmpty else { return false }

        // Check for valid IPv4 address
        if isValidIPv4(host) {
            return true
        }

        // Check for valid IPv6 address (may be in brackets)
        let ipv6 = host.hasPrefix("[") && host.hasSuffix("]")
            ? String(host.dropFirst().dropLast())
            : host
        if isValidIPv6(ipv6) {
            return true
        }

        // Check for valid hostname (RFC 1123)
        let hostnamePattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$"#
        return host.range(of: hostnamePattern, options: .regularExpression) != nil
    }

    // MARK: - Port Validation

    /// Validate that a string represents a valid port number (1-65535).
    static func isValidPort(_ port: String) -> Bool {
        guard let portNumber = Int(port),
              portNumber >= 1,
              portNumber <= 65535 else {
            return false
        }
        return true
    }

    // MARK: - Payload Depth Limiting

    /// Recursively limit the nesting depth of a JSON-like value.
    /// Returns `NSNull()` for values beyond `maxDepth`.
    static func limitPayloadDepth(_ value: Any, maxDepth: Int = 50, currentDepth: Int = 0) -> Any {
        guard currentDepth < maxDepth else {
            return NSNull()
        }

        if let array = value as? [Any] {
            return array.map { limitPayloadDepth($0, maxDepth: maxDepth, currentDepth: currentDepth + 1) }
        }

        if let dict = value as? [String: Any] {
            return dict.mapValues { limitPayloadDepth($0, maxDepth: maxDepth, currentDepth: currentDepth + 1) }
        }

        // Scalar values pass through unchanged
        return value
    }

    // MARK: - Private Helpers

    private static func isValidIPv4(_ string: String) -> Bool {
        var addr = in_addr()
        return inet_pton(AF_INET, string, &addr) == 1
    }

    private static func isValidIPv6(_ string: String) -> Bool {
        var addr = in6_addr()
        return inet_pton(AF_INET6, string, &addr) == 1
    }

    /// Check whether a host is a local or private IP address.
    private static func isLocalOrPrivateIP(_ host: String) -> Bool {
        // Localhost
        if host == "localhost" || host == "127.0.0.1" || host == "::1" {
            return true
        }

        // Check common private IP ranges
        guard isValidIPv4(host) else {
            return false
        }

        let components = host.split(separator: ".").compactMap { Int($0) }
        guard components.count == 4 else { return false }

        // 10.0.0.0/8
        if components[0] == 10 {
            return true
        }

        // 172.16.0.0/12
        if components[0] == 172, (16...31).contains(components[1]) {
            return true
        }

        // 192.168.0.0/16
        if components[0] == 192, components[1] == 168 {
            return true
        }

        // 169.254.0.0/16 (link-local)
        if components[0] == 169, components[1] == 254 {
            return true
        }

        return false
    }
}
