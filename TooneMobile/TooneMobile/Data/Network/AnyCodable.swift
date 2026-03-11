import Foundation

// MARK: - AnyCodable

/// A type-erased Codable wrapper that supports JSON-RPC params and results.
/// Handles String, Int, Double, Bool, Array, Dictionary, and null.
struct AnyCodable: Codable, @unchecked Sendable, Equatable {

    let value: Any

    // MARK: - Initializers

    init(_ value: Any) {
        self.value = AnyCodable.sanitize(value)
    }

    init(string: String) { self.value = string }
    init(int: Int) { self.value = int }
    init(double: Double) { self.value = double }
    init(bool: Bool) { self.value = bool }
    init(array: [AnyCodable]) { self.value = array.map(\.value) }
    init(dictionary: [String: AnyCodable]) { self.value = dictionary.mapValues(\.value) }

    static let null = AnyCodable(NSNull())

    // MARK: - Convenience Accessors

    var stringValue: String? { value as? String }
    var intValue: Int? { value as? Int }
    var doubleValue: Double? { value as? Double }
    var boolValue: Bool? { value as? Bool }

    var arrayValue: [AnyCodable]? {
        (value as? [Any])?.map { AnyCodable($0) }
    }

    var dictionaryValue: [String: AnyCodable]? {
        (value as? [String: Any])?.mapValues { AnyCodable($0) }
    }

    var isNull: Bool { value is NSNull }

    /// Subscript for dictionary-style access.
    subscript(key: String) -> AnyCodable? {
        (value as? [String: Any]).flatMap { dict in
            dict[key].map { AnyCodable($0) }
        }
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let boolVal = try? container.decode(Bool.self) {
            self.value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            self.value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            self.value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            self.value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            self.value = arrayVal.map(\.value)
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            self.value = dictVal.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let stringVal as String:
            try container.encode(stringVal)
        case let arrayVal as [Any]:
            try container.encode(arrayVal.map { AnyCodable($0) })
        case let dictVal as [String: Any]:
            try container.encode(dictVal.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "AnyCodable cannot encode value of type \(type(of: value))"
                )
            )
        }
    }

    // MARK: - Equatable

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (NSNull, NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        case let (l as [Any], r as [Any]):
            return l.map { AnyCodable($0) } == r.map { AnyCodable($0) }
        case let (l as [String: Any], r as [String: Any]):
            return l.mapValues { AnyCodable($0) } == r.mapValues { AnyCodable($0) }
        default:
            return false
        }
    }

    // MARK: - Helpers

    /// Recursively sanitize a value to ensure it uses only JSON-safe types.
    /// Includes depth and collection size limits to prevent stack overflow from malicious payloads.
    private static func sanitize(_ value: Any, depth: Int = 0) -> Any {
        guard depth < 50 else { return "<truncated>" }

        switch value {
        case let codable as AnyCodable:
            return codable.value
        case let array as [Any]:
            return array.prefix(1000).map { sanitize($0, depth: depth + 1) }
        case let dict as [String: Any]:
            let limited = Dictionary(uniqueKeysWithValues: dict.prefix(500).map { ($0.key, sanitize($0.value, depth: depth + 1)) })
            return limited
        default:
            return value
        }
    }
}

// MARK: - ExpressibleBy Literals

extension AnyCodable: ExpressibleByStringLiteral {
    init(stringLiteral value: String) { self.value = value }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) { self.value = value }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) { self.value = value }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) { self.value = value }
}

extension AnyCodable: ExpressibleByNilLiteral {
    init(nilLiteral: ()) { self.value = NSNull() }
}

extension AnyCodable: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: AnyCodable...) {
        self.value = elements.map(\.value)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (String, AnyCodable)...) {
        self.value = Dictionary(uniqueKeysWithValues: elements).mapValues(\.value)
    }
}

// MARK: - Encodable Conversion

extension AnyCodable {
    /// Create an AnyCodable from any Encodable value by round-tripping through JSON.
    static func from(_ encodable: some Encodable) throws -> AnyCodable {
        let encoder = JSONEncoder()
        let data = try encoder.encode(encodable)
        let decoder = JSONDecoder()
        return try decoder.decode(AnyCodable.self, from: data)
    }
}
