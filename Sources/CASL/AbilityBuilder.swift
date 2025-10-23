// AbilityBuilder.swift
// Fluent API for building Ability instances

import Foundation

/// Fluent builder for creating Ability instances
///
/// AbilityBuilder provides a chainable API for defining authorization rules:
///
/// ```swift
/// let ability = AbilityBuilder()
///     .can("read", "BlogPost")
///     .can("update", "BlogPost", conditions: ["authorId": userId])
///     .cannot("delete", "BlogPost")
///     .build()
/// ```
public class AbilityBuilder {
    // MARK: - Properties

    /// Accumulated rules
    private var rules: [RawRule] = []

    /// Options for the ability
    private var options: AbilityOptions

    // MARK: - Initialization

    /// Create a new AbilityBuilder
    ///
    /// - Parameter options: Configuration options for the Ability
    public init(options: AbilityOptions = AbilityOptions()) {
        self.options = options
    }

    // MARK: - Single Action/Subject Methods

    /// Add a "can" rule for a single action and subject
    ///
    /// - Parameters:
    ///   - action: The action to allow (e.g., "read", "update")
    ///   - subject: The subject type (e.g., "BlogPost", "Comment")
    ///   - conditions: Optional conditions for attribute-based access control
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func can(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: action,
            subject: subject,
            conditions: conditions,
            fields: fields,
            inverted: false,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    /// Add a "cannot" rule for a single action and subject
    ///
    /// - Parameters:
    ///   - action: The action to deny
    ///   - subject: The subject type
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func cannot(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: action,
            subject: subject,
            conditions: conditions,
            fields: fields,
            inverted: true,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    // MARK: - Array Actions Methods

    /// Add a "can" rule for multiple actions and a single subject
    ///
    /// - Parameters:
    ///   - actions: Array of actions to allow
    ///   - subject: The subject type
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func can(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(actions),
            subject: StringOrArray(subject),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: false,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    /// Add a "cannot" rule for multiple actions and a single subject
    ///
    /// - Parameters:
    ///   - actions: Array of actions to deny
    ///   - subject: The subject type
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func cannot(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(actions),
            subject: StringOrArray(subject),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: true,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    // MARK: - Array Subjects Methods

    /// Add a "can" rule for a single action and multiple subjects
    ///
    /// - Parameters:
    ///   - action: The action to allow
    ///   - subjects: Array of subject types
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func can(
        _ action: String,
        _ subjects: [String],
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(action),
            subject: StringOrArray(subjects),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: false,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    /// Add a "cannot" rule for a single action and multiple subjects
    ///
    /// - Parameters:
    ///   - action: The action to deny
    ///   - subjects: Array of subject types
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func cannot(
        _ action: String,
        _ subjects: [String],
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(action),
            subject: StringOrArray(subjects),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: true,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    // MARK: - Array Actions and Subjects Methods

    /// Add a "can" rule for multiple actions and multiple subjects
    ///
    /// - Parameters:
    ///   - actions: Array of actions to allow
    ///   - subjects: Array of subject types
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func can(
        _ actions: [String],
        _ subjects: [String],
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(actions),
            subject: StringOrArray(subjects),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: false,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    /// Add a "cannot" rule for multiple actions and multiple subjects
    ///
    /// - Parameters:
    ///   - actions: Array of actions to deny
    ///   - subjects: Array of subject types
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    ///   - reason: Optional reason for this rule
    /// - Returns: Self for chaining
    @discardableResult
    public func cannot(
        _ actions: [String],
        _ subjects: [String],
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        reason: String? = nil
    ) -> Self {
        let rule = RawRule(
            action: StringOrArray(actions),
            subject: StringOrArray(subjects),
            conditions: conditions,
            fields: fields.map { StringOrArray($0) },
            inverted: true,
            reason: reason
        )
        rules.append(rule)
        return self
    }

    // MARK: - Build

    /// Build an Ability instance from the accumulated rules
    ///
    /// - Returns: A new Ability instance with all defined rules
    public func build() -> Ability {
        return Ability(rules: rules, options: options)
    }

    /// Clear all rules from the builder
    ///
    /// - Returns: Self for chaining
    @discardableResult
    public func clear() -> Self {
        rules.removeAll()
        return self
    }
}
