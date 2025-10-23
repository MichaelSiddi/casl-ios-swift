// FieldMatcher.swift
// Protocol for pluggable field pattern matching strategies

import Foundation

/// Protocol for field pattern matching strategies
///
/// Implementations determine whether a field name matches given patterns.
/// The default implementation is GlobFieldMatcher which supports wildcards.
public protocol FieldMatcher: Sendable {
    /// Check if a field matches any of the given patterns
    ///
    /// - Parameters:
    ///   - field: The field name to check
    ///   - patterns: Array of pattern strings to match against
    /// - Returns: true if field matches any pattern, or if patterns is empty (no restrictions)
    func matches(field: String, patterns: [String]) -> Bool
}

// MARK: - GlobFieldMatcher

/// Glob-style field pattern matcher
///
/// Supports:
/// - Exact matching: "title" matches only "title"
/// - Wildcard "*": matches any field
/// - Prefix pattern "prefix.*": matches any field starting with "prefix."
///
/// Examples:
/// - "title" matches "title" exactly
/// - "*" matches any field
/// - "profile.*" matches "profile.name", "profile.email", etc.
public struct GlobFieldMatcher: FieldMatcher {
    public init() {}

    public func matches(field: String, patterns: [String]) -> Bool {
        // If no patterns, deny by default (explicit field restrictions)
        guard !patterns.isEmpty else {
            return false
        }

        // Check if field matches any pattern
        for pattern in patterns {
            if matchesPattern(field: field, pattern: pattern) {
                return true
            }
        }

        return false
    }

    /// Check if a field matches a single pattern
    private func matchesPattern(field: String, pattern: String) -> Bool {
        // Wildcard matches everything
        if pattern == "*" {
            return true
        }

        // Exact match
        if pattern == field {
            return true
        }

        // Prefix pattern "prefix.*"
        if pattern.hasSuffix(".*") {
            let prefix = String(pattern.dropLast(2)) // Remove ".*"
            return field.hasPrefix(prefix + ".")
        }

        return false
    }
}
