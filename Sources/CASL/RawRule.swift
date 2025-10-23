// RawRule.swift
// Serializable rule representation for JSON encoding/decoding

import Foundation

/// Serializable representation of an authorization rule
///
/// RawRule is the portable format for rules, suitable for JSON encoding/decoding.
/// It can represent single or multiple actions/subjects using StringOrArray.
///
/// Example JSON:
/// ```json
/// {
///   "action": "read",
///   "subject": "BlogPost",
///   "conditions": { "authorId": "123" },
///   "fields": ["title", "content"],
///   "inverted": false
/// }
/// ```
public struct RawRule: Codable, Equatable, Sendable {
    /// Action or array of actions
    public let action: StringOrArray

    /// Optional subject or array of subjects
    public let subject: StringOrArray?

    /// Optional conditions dictionary (MongoDB-style query)
    public let conditions: [String: AnyCodable]?

    /// Optional field or array of fields
    public let fields: StringOrArray?

    /// Optional inverted flag (defaults to false if omitted)
    public let inverted: Bool?

    /// Optional reason string documenting why this rule exists
    public let reason: String?

    // MARK: - Initialization

    /// Create a raw rule with all parameters
    public init(
        action: StringOrArray,
        subject: StringOrArray? = nil,
        conditions: [String: AnyCodable]? = nil,
        fields: StringOrArray? = nil,
        inverted: Bool? = nil,
        reason: String? = nil
    ) {
        self.action = action
        self.subject = subject
        self.conditions = conditions
        self.fields = fields
        self.inverted = inverted
        self.reason = reason
    }

    /// Create a simple raw rule with single action/subject
    ///
    /// Convenience initializer for the common case of single string values.
    public init(
        action: String,
        subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        inverted: Bool = false,
        reason: String? = nil
    ) {
        self.action = .single(action)
        self.subject = .single(subject)
        self.conditions = conditions
        self.fields = fields.map { StringOrArray($0) }
        self.inverted = inverted
        self.reason = reason
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case action
        case subject
        case conditions
        case fields
        case inverted
        case reason
    }

    // MARK: - Codable Conformance

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        action = try container.decode(StringOrArray.self, forKey: .action)
        subject = try? container.decode(StringOrArray.self, forKey: .subject)
        conditions = try? container.decode([String: AnyCodable].self, forKey: .conditions)
        fields = try? container.decode(StringOrArray.self, forKey: .fields)
        inverted = try? container.decode(Bool.self, forKey: .inverted)
        reason = try? container.decode(String.self, forKey: .reason)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(action, forKey: .action)

        if let subject = subject {
            try container.encode(subject, forKey: .subject)
        }

        if let conditions = conditions {
            try container.encode(conditions, forKey: .conditions)
        }

        if let fields = fields {
            try container.encode(fields, forKey: .fields)
        }

        if let inverted = inverted {
            try container.encode(inverted, forKey: .inverted)
        }

        if let reason = reason {
            try container.encode(reason, forKey: .reason)
        }
    }
}

// MARK: - Expansion to Multiple Rules

extension RawRule {
    /// Expand this RawRule to multiple Rule instances
    ///
    /// Handles cartesian product of arrays:
    /// - Single action + single subject → 1 rule
    /// - Array actions + single subject → N rules (one per action)
    /// - Single action + array subjects → M rules (one per subject)
    /// - Array actions + array subjects → N×M rules
    ///
    /// Note: This method will be used when converting RawRule to Rule
    /// in the full implementation.
    internal func expandToMultiple() -> [(action: String, subject: String?)] {
        let actions = action.values
        let subjects: [String?] = subject?.values ?? [nil]

        var expanded: [(String, String?)] = []

        for action in actions {
            for subject in subjects {
                expanded.append((action, subject))
            }
        }

        return expanded
    }
}
