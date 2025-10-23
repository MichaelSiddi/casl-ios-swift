// Operators.swift
// MongoDB-style query operators for condition matching

import Foundation

/// MongoDB-style query operators for conditions
///
/// Supports comparison operators ($eq, $ne, $gt, $lt, $in, $nin, $exists)
/// and logical operators ($and, $or, $not)
///
/// Note: Marked as `indirect` because logical operators create recursive references
public indirect enum QueryOperator: Codable, Equatable, Sendable {
    // MARK: - Comparison Operators

    /// Equal ($eq)
    case equal(AnyCodable)

    /// Not equal ($ne)
    case notEqual(AnyCodable)

    /// Greater than ($gt)
    case greaterThan(AnyCodable)

    /// Greater than or equal ($gte)
    case greaterThanOrEqual(AnyCodable)

    /// Less than ($lt)
    case lessThan(AnyCodable)

    /// Less than or equal ($lte)
    case lessThanOrEqual(AnyCodable)

    /// In array ($in)
    case `in`([AnyCodable])

    /// Not in array ($nin)
    case notIn([AnyCodable])

    /// Field exists ($exists)
    case exists(Bool)

    // MARK: - Logical Operators

    /// Logical AND ($and) - all conditions must match
    case and([Condition])

    /// Logical OR ($or) - at least one condition must match
    case or([Condition])

    /// Logical NOT ($not) - condition must not match
    case not(Condition)

    // MARK: - Coding Keys

    private enum CodingKeys: String, CodingKey {
        case equal = "$eq"
        case notEqual = "$ne"
        case greaterThan = "$gt"
        case greaterThanOrEqual = "$gte"
        case lessThan = "$lt"
        case lessThanOrEqual = "$lte"
        case `in` = "$in"
        case notIn = "$nin"
        case exists = "$exists"
        case and = "$and"
        case or = "$or"
        case not = "$not"
    }

    // MARK: - Codable Conformance

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode each operator type
        if let value = try? container.decode(AnyCodable.self, forKey: .equal) {
            self = .equal(value)
        } else if let value = try? container.decode(AnyCodable.self, forKey: .notEqual) {
            self = .notEqual(value)
        } else if let value = try? container.decode(AnyCodable.self, forKey: .greaterThan) {
            self = .greaterThan(value)
        } else if let value = try? container.decode(AnyCodable.self, forKey: .greaterThanOrEqual) {
            self = .greaterThanOrEqual(value)
        } else if let value = try? container.decode(AnyCodable.self, forKey: .lessThan) {
            self = .lessThan(value)
        } else if let value = try? container.decode(AnyCodable.self, forKey: .lessThanOrEqual) {
            self = .lessThanOrEqual(value)
        } else if let value = try? container.decode([AnyCodable].self, forKey: .in) {
            self = .in(value)
        } else if let value = try? container.decode([AnyCodable].self, forKey: .notIn) {
            self = .notIn(value)
        } else if let value = try? container.decode(Bool.self, forKey: .exists) {
            self = .exists(value)
        } else if let value = try? container.decode([Condition].self, forKey: .and) {
            self = .and(value)
        } else if let value = try? container.decode([Condition].self, forKey: .or) {
            self = .or(value)
        } else if let value = try? container.decode(Condition.self, forKey: .not) {
            self = .not(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown query operator"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .equal(let value):
            try container.encode(value, forKey: .equal)
        case .notEqual(let value):
            try container.encode(value, forKey: .notEqual)
        case .greaterThan(let value):
            try container.encode(value, forKey: .greaterThan)
        case .greaterThanOrEqual(let value):
            try container.encode(value, forKey: .greaterThanOrEqual)
        case .lessThan(let value):
            try container.encode(value, forKey: .lessThan)
        case .lessThanOrEqual(let value):
            try container.encode(value, forKey: .lessThanOrEqual)
        case .in(let values):
            try container.encode(values, forKey: .in)
        case .notIn(let values):
            try container.encode(values, forKey: .notIn)
        case .exists(let value):
            try container.encode(value, forKey: .exists)
        case .and(let conditions):
            try container.encode(conditions, forKey: .and)
        case .or(let conditions):
            try container.encode(conditions, forKey: .or)
        case .not(let condition):
            try container.encode(condition, forKey: .not)
        }
    }
}

// MARK: - Condition

/// Represents a query condition for attribute-based access control
public struct Condition: Codable, Equatable, Sendable {
    /// Field name to query
    public let field: String

    /// Query operator to apply
    public let `operator`: QueryOperator

    public init(field: String, operator: QueryOperator) {
        self.field = field
        self.operator = `operator`
    }
}

// MARK: - Convenience Condition Constructors

extension Condition {
    /// Equal condition
    public static func equal(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .equal(value))
    }

    /// Not equal condition
    public static func notEqual(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .notEqual(value))
    }

    /// Greater than condition
    public static func greaterThan(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .greaterThan(value))
    }

    /// Greater than or equal condition
    public static func greaterThanOrEqual(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .greaterThanOrEqual(value))
    }

    /// Less than condition
    public static func lessThan(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .lessThan(value))
    }

    /// Less than or equal condition
    public static func lessThanOrEqual(_ field: String, _ value: AnyCodable) -> Condition {
        Condition(field: field, operator: .lessThanOrEqual(value))
    }

    /// In array condition
    public static func `in`(_ field: String, _ values: [AnyCodable]) -> Condition {
        Condition(field: field, operator: .in(values))
    }

    /// Not in array condition
    public static func notIn(_ field: String, _ values: [AnyCodable]) -> Condition {
        Condition(field: field, operator: .notIn(values))
    }

    /// Exists condition
    public static func exists(_ field: String, _ exists: Bool = true) -> Condition {
        Condition(field: field, operator: .exists(exists))
    }

    /// Logical AND combinator
    public static func and(_ conditions: [Condition]) -> Condition {
        // Use a placeholder field for logical operators
        Condition(field: "$and", operator: .and(conditions))
    }

    /// Logical OR combinator
    public static func or(_ conditions: [Condition]) -> Condition {
        Condition(field: "$or", operator: .or(conditions))
    }

    /// Logical NOT combinator
    public static func not(_ condition: Condition) -> Condition {
        Condition(field: "$not", operator: .not(condition))
    }
}
