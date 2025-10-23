// ConditionsMatcher.swift
// Protocol for pluggable condition matching strategies

import Foundation

/// Compiled condition matcher closure
///
/// Takes an object and returns true if it matches the conditions
public typealias MatchConditions = @Sendable (Any) -> Bool

/// Protocol for condition matching strategies
///
/// Implementations evaluate whether objects satisfy query conditions.
/// The default implementation is QueryMatcher which supports MongoDB-style queries.
public protocol ConditionsMatcher: Sendable {
    /// Compile conditions into a matcher function
    ///
    /// - Parameter conditions: Dictionary of field names to condition values
    /// - Returns: A closure that checks if an object matches the conditions
    func compile(_ conditions: [String: AnyCodable]) -> MatchConditions

    /// Check if an object matches conditions
    ///
    /// - Parameters:
    ///   - object: The object to check
    ///   - conditions: Dictionary of field names to condition values
    /// - Returns: true if the object matches all conditions
    func matches(_ object: Any, conditions: [String: AnyCodable]) -> Bool
}

// MARK: - Default Implementation

extension ConditionsMatcher {
    /// Default implementation compiles and executes
    public func matches(_ object: Any, conditions: [String: AnyCodable]) -> Bool {
        let matcher = compile(conditions)
        return matcher(object)
    }
}
