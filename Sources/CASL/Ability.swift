// Ability.swift
// Main interface for permission management and checking

import Foundation

/// The main authorization manager
///
/// Ability stores rules and evaluates permissions. It uses Swift actors
/// for thread-safe rule updates while allowing synchronous permission checks.
///
/// Example:
/// ```swift
/// let ability = Ability(rules: [
///     RawRule(action: "read", subject: "BlogPost"),
///     RawRule(action: "update", subject: "BlogPost", conditions: ["authorId": userId])
/// ])
///
/// if await ability.can("read", post) {
///     // Allow access
/// }
/// ```
public actor Ability: Sendable {
    // MARK: - Properties

    /// Rule index for storage and lookup
    private let ruleIndex: RuleIndex

    /// Options for matching strategies
    private let options: AbilityOptions

    // MARK: - Initialization

    /// Create an Ability with rules and options
    ///
    /// - Parameters:
    ///   - rules: Array of raw rules to initialize with
    ///   - options: Configuration options for matching strategies
    public init(rules: [RawRule], options: AbilityOptions = AbilityOptions()) {
        self.options = options

        // Convert RawRules to Rules
        let expandedRules = rules.flatMap { rawRule -> [Rule] in
            rawRule.expandToMultiple().map { (action, subject) in
                Rule(
                    action: action,
                    subject: subject ?? "all",
                    conditions: rawRule.conditions,
                    fields: rawRule.fields?.values,
                    inverted: rawRule.inverted ?? false,
                    reason: rawRule.reason
                )
            }
        }

        self.ruleIndex = RuleIndex(rules: expandedRules, options: options)
    }

    // MARK: - Permission Checking (Nonisolated for synchronous access)

    /// Check if action is permitted on subject
    ///
    /// - Parameters:
    ///   - action: The action to check (e.g., "read", "update")
    ///   - subject: The subject to check permission for (type or instance)
    ///   - field: Optional field name for field-level permissions
    /// - Returns: true if permission is granted, false otherwise
    public func can(_ action: String, _ subject: Any, field: String? = nil) async -> Bool {
        let rule = await relevantRuleFor(action, subject, field: field)

        // If no rule found, deny by default
        guard let rule = rule else {
            return false
        }

        // If rule is inverted (cannot), it denies permission
        return !rule.inverted
    }

    /// Check if action is denied on subject
    ///
    /// - Parameters:
    ///   - action: The action to check
    ///   - subject: The subject to check permission for
    ///   - field: Optional field name
    /// - Returns: true if permission is explicitly denied, false otherwise
    public func cannot(_ action: String, _ subject: Any, field: String? = nil) async -> Bool {
        return await !can(action, subject, field: field)
    }

    /// Find the relevant rule for given action/subject/field
    ///
    /// Returns the last matching rule according to rule precedence.
    /// In CASL, rules are evaluated in insertion order, and the last match wins.
    /// This means rules defined later override rules defined earlier.
    ///
    /// - Parameters:
    ///   - action: Action to find a rule for
    ///   - subject: Subject to find a rule for
    ///   - field: Optional field name
    /// - Returns: The last matching Rule, or nil if no match
    public func relevantRuleFor(
        _ action: String,
        _ subject: Any,
        field: String? = nil
    ) async -> Rule? {
        let subjectType = detectSubjectTypeSync(subject)

        // Get all rules from rule index
        let allRules = await ruleIndex.rules

        // Find last matching rule (insertion order = precedence order)
        // Rules defined later override rules defined earlier
        var matchedRule: Rule? = nil

        for rule in allRules {
            guard rule.matchesAction(action) else { continue }
            guard rule.matchesSubjectType(subjectType) else { continue }
            guard rule.matchesField(field, fieldMatcher: options.fieldMatcher) else { continue }
            guard rule.matchesConditions(subject, conditionsMatcher: options.conditionsMatcher) else { continue }

            matchedRule = rule // Keep updating to get the last match
        }

        return matchedRule
    }

    // MARK: - Rule Management (Isolated, async)

    /// Update all rules
    ///
    /// - Parameter rules: New array of raw rules
    public func update(rules: [RawRule]) async {
        let expandedRules = rules.flatMap { rawRule -> [Rule] in
            rawRule.expandToMultiple().map { (action, subject) in
                Rule(
                    action: action,
                    subject: subject ?? "all",
                    conditions: rawRule.conditions,
                    fields: rawRule.fields?.values,
                    inverted: rawRule.inverted ?? false,
                    reason: rawRule.reason
                )
            }
        }

        await ruleIndex.update(rules: expandedRules)
    }

    /// Export all rules as RawRule array for serialization
    ///
    /// - Returns: Array of RawRule instances
    public func exportRules() async -> [RawRule] {
        let allRules = await ruleIndex.rules

        return allRules.map { rule in
            RawRule(
                action: StringOrArray(rule.action),
                subject: StringOrArray(rule.subject),
                conditions: rule.conditions,
                fields: rule.fields.map { StringOrArray($0) },
                inverted: rule.inverted ? true : nil,
                reason: rule.reason
            )
        }
    }

    // MARK: - Helper Methods

    /// Detect subject type from instance (synchronous helper)
    private func detectSubjectTypeSync(_ subject: Any) -> String {
        // If subject is already a string, use it directly
        if let subjectString = subject as? String {
            return subjectString
        }

        // Otherwise use the detector function
        return options.detectSubjectType(subject)
    }
}
