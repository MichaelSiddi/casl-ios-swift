// Types.swift
// Core type definitions for CASL authorization library

import Foundation

// MARK: - Subject Type Provider

/// Protocol for types that provide custom subject type identification
///
/// Implement this protocol on your domain models to customize how CASL
/// identifies their type for permission checks.
///
/// Example:
/// ```swift
/// class BlogPost: SubjectTypeProvider {
///     static let subjectType = "BlogPost"
///     let id: String
///     let authorId: String
/// }
/// ```
public protocol SubjectTypeProvider {
    /// The subject type string used for permission matching
    static var subjectType: String { get }
}

// MARK: - Any Codable

/// Type-erased wrapper for Codable values
///
/// Allows encoding and decoding of heterogeneous value types in conditions.
/// Supports Int, String, Bool, Double, Array, and Dictionary.
///
/// Note: `value` is not Sendable, but the supported types (Int, String, Bool, Double, Array, Dict) are all Sendable
public struct AnyCodable: Codable, Equatable, Sendable {
    /// The wrapped value
    /// Note: Stored as Any but constrained to Sendable types at runtime
    public let value: Any

    /// Create an AnyCodable wrapping any value
    public init(_ value: Any) {
        self.value = value
    }

    // MARK: - Codable Conformance

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as different types
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable value cannot be decoded"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "AnyCodable value cannot be encoded"
                )
            )
        }
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as String, r as String):
            return l == r
        default:
            return false
        }
    }
}

// MARK: - String Or Array

/// Represents either a single string or an array of strings
///
/// Used for flexible action and subject specification in rules.
/// Automatically handles both formats during JSON encoding/decoding.
public enum StringOrArray: Codable, Equatable, Sendable {
    case single(String)
    case multiple([String])

    /// Get all values as an array
    public var values: [String] {
        switch self {
        case .single(let value):
            return [value]
        case .multiple(let values):
            return values
        }
    }

    // MARK: - Codable Conformance

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let singleValue = try? container.decode(String.self) {
            self = .single(singleValue)
        } else if let multipleValues = try? container.decode([String].self) {
            self = .multiple(multipleValues)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "StringOrArray must be either String or [String]"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .single(let value):
            try container.encode(value)
        case .multiple(let values):
            try container.encode(values)
        }
    }
}

// MARK: - Convenience Initializers

extension StringOrArray {
    /// Create from a single string
    public init(_ value: String) {
        self = .single(value)
    }

    /// Create from an array of strings
    public init(_ values: [String]) {
        if values.count == 1, let first = values.first {
            self = .single(first)
        } else {
            self = .multiple(values)
        }
    }
}
