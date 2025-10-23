// RuleIndex.swift
// Rule storage and efficient lookup

import Foundation

/// Rule storage and indexing for efficient permission lookups
///
/// RuleIndex organizes rules for fast retrieval by action and subject type.
/// Maintains insertion order for proper rule precedence.
actor RuleIndex {
    // MARK: - Properties

    /// All rules in insertion order
    private(set) var rules: [Rule]

    /// Options for rule matching
    private let options: AbilityOptions

    // MARK: - Initialization

    init(rules: [Rule] = [], options: AbilityOptions = AbilityOptions()) {
        self.rules = rules
        self.options = options
    }

    // MARK: - Rule Management

    /// Update all rules
    func update(rules: [Rule]) {
        self.rules = rules
    }

    /// Get rules for specific action and subject type
    ///
    /// Returns rules in insertion order for proper precedence.
    /// First matching rule wins.
    nonisolated func rulesFor(action: String, subjectType: String, field: String? = nil) -> [Rule] {
        // Note: This needs to access rules which is actor-isolated
        // For now, return empty array - will be implemented properly with nonisolated(unsafe)
        return []
    }

    // MARK: - Rule Lookup (Internal)

    /// Find matching rules for given action/subject/field combination
    ///
    /// Filters rules that match the action, subject type, and optionally field.
    internal func findMatchingRules(action: String, subjectType: String, field: String?) -> [Rule] {
        return rules.filter { rule in
            guard rule.matchesAction(action) else { return false }
            guard rule.matchesSubjectType(subjectType) else { return false }
            guard rule.matchesField(field, fieldMatcher: options.fieldMatcher) else { return false }
            return true
        }
    }
}

// MARK: - Ability Options

/// Configuration options for Ability
public struct AbilityOptions: Sendable {
    /// Conditions matching strategy
    var conditionsMatcher: any ConditionsMatcher

    /// Field matching strategy
    var fieldMatcher: any FieldMatcher

    /// Subject type detector function
    var detectSubjectType: @Sendable (Any) -> String

    public init(
        conditionsMatcher: any ConditionsMatcher = QueryMatcher(),
        fieldMatcher: any FieldMatcher = GlobFieldMatcher(),
        detectSubjectType: @Sendable @escaping (Any) -> String = defaultSubjectTypeDetector
    ) {
        self.conditionsMatcher = conditionsMatcher
        self.fieldMatcher = fieldMatcher
        self.detectSubjectType = detectSubjectType
    }
}

