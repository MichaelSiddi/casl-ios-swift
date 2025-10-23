// Rule.swift
// Authorization rule with matching logic

import Foundation

/// Represents a single authorization rule
///
/// A rule defines whether an action is allowed or denied on a subject,
/// optionally with conditions and field restrictions.
public struct Rule: Sendable, Equatable {
    // MARK: - Properties

    /// Action this rule applies to (e.g., "read", "update", "manage")
    public let action: String

    /// Subject type this rule applies to (e.g., "BlogPost", "all")
    public let subject: String

    /// Optional conditions dictionary for attribute-based matching
    public let conditions: [String: AnyCodable]?

    /// Optional field restrictions
    public let fields: [String]?

    /// Whether this is a deny rule (true = cannot, false = can)
    public let inverted: Bool

    /// Optional reason explaining why this rule exists
    public let reason: String?

    // MARK: - Initialization

    public init(
        action: String,
        subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        inverted: Bool = false,
        reason: String? = nil
    ) {
        self.action = action
        self.subject = subject
        self.conditions = conditions
        self.fields = fields
        self.inverted = inverted
        self.reason = reason
    }

    // MARK: - Matching Logic

    /// Check if this rule matches the given action
    ///
    /// Supports wildcard "manage" action that matches any action
    public func matchesAction(_ action: String) -> Bool {
        // "manage" is a special wildcard that matches all actions
        if self.action == "manage" {
            return true
        }

        return self.action == action
    }

    /// Check if this rule matches the given subject type
    ///
    /// Supports wildcard "all" subject that matches any subject
    public func matchesSubjectType(_ subjectType: String) -> Bool {
        // "all" is a special wildcard that matches all subjects
        if self.subject == "all" {
            return true
        }

        return self.subject == subjectType
    }

    /// Check if this rule matches the given field
    ///
    /// If no field restrictions exist, all fields match.
    /// If field restrictions exist, the field must match one of the patterns.
    public func matchesField(_ field: String?, fieldMatcher: FieldMatcher) -> Bool {
        // If no field parameter provided, we're not doing field-level checking
        guard let field = field else {
            return true
        }

        // If no field restrictions, all fields are allowed
        guard let fields = fields else {
            return true
        }

        // Check if field matches any pattern
        return fieldMatcher.matches(field: field, patterns: fields)
    }

    /// Check if this rule's conditions match the given subject instance
    ///
    /// If no conditions exist, the rule always matches.
    /// Uses QueryMatcher to evaluate MongoDB-style conditions.
    public func matchesConditions(_ subject: Any?, conditionsMatcher: ConditionsMatcher? = nil) -> Bool {
        // If no conditions, rule always matches
        guard let conditions = conditions else {
            return true
        }

        // If no subject provided, can't evaluate conditions
        guard let subject = subject else {
            return false
        }

        // Use provided matcher or default QueryMatcher
        let matcher = conditionsMatcher ?? QueryMatcher()
        return matcher.matches(subject, conditions: conditions)
    }
}
