// QueryMatcher.swift
// MongoDB-style query matching for conditional permissions

import Foundation

/// QueryMatcher implements MongoDB-style query evaluation for conditions
///
/// Supports operators like $eq, $ne, $gt, $lt, $in, $nin, $exists, $and, $or, $not
public struct QueryMatcher: ConditionsMatcher {
    public init() {}

    /// Compile conditions into a matching function
    public func compile(_ conditions: [String: AnyCodable]) -> MatchConditions {
        return { subject in
            return self.evaluateConditions(conditions, on: subject)
        }
    }

    /// Check if object matches conditions
    public func matches(_ object: Any, conditions: [String: AnyCodable]) -> Bool {
        return evaluateConditions(conditions, on: object)
    }

    // MARK: - Condition Evaluation

    /// Evaluate all conditions against the subject
    private func evaluateConditions(_ conditions: [String: AnyCodable], on subject: Any) -> Bool {
        // Check for logical operators at the root level
        if let andValue = conditions["$and"]?.value {
            // Try to parse as array of AnyCodable (where each AnyCodable wraps a dict)
            if let andArray = andValue as? [AnyCodable] {
                let conditionsArray = andArray.compactMap { $0.value as? [String: AnyCodable] }
                return evaluateAnd(conditionsArray, on: subject)
            }
            // Try direct array of dictionaries
            if let andConditions = andValue as? [[String: AnyCodable]] {
                return evaluateAnd(andConditions, on: subject)
            }
        }

        if let orValue = conditions["$or"]?.value {
            // Try to parse as array of AnyCodable (where each AnyCodable wraps a dict)
            if let orArray = orValue as? [AnyCodable] {
                let conditionsArray = orArray.compactMap { $0.value as? [String: AnyCodable] }
                return evaluateOr(conditionsArray, on: subject)
            }
            // Try direct array of dictionaries
            if let orConditions = orValue as? [[String: AnyCodable]] {
                return evaluateOr(orConditions, on: subject)
            }
        }

        if let notValue = conditions["$not"]?.value {
            // Try to parse as AnyCodable wrapping a dict
            if let notAnyCodable = notValue as? AnyCodable, let notCondition = notAnyCodable.value as? [String: AnyCodable] {
                return !evaluateConditions(notCondition, on: subject)
            }
            // Try direct dictionary
            if let notCondition = notValue as? [String: AnyCodable] {
                return !evaluateConditions(notCondition, on: subject)
            }
        }

        // Evaluate all field conditions (implicit AND)
        for (field, value) in conditions {
            // Skip if it's a logical operator (already handled above)
            if field.hasPrefix("$") {
                continue
            }

            if !evaluateFieldCondition(field: field, value: value, on: subject) {
                return false
            }
        }

        return true
    }

    /// Evaluate a single field condition
    private func evaluateFieldCondition(field: String, value: AnyCodable, on subject: Any) -> Bool {
        let fieldValue = extractValue(for: field, from: subject)

        // Check if value is an operator object
        if let operatorDict = value.value as? [String: AnyCodable] {
            return evaluateOperators(operatorDict, fieldValue: fieldValue)
        }

        // Simple equality check
        return areEqual(fieldValue, value.value)
    }

    /// Evaluate operator dictionary against a field value
    private func evaluateOperators(_ operators: [String: AnyCodable], fieldValue: Any?) -> Bool {
        for (op, value) in operators {
            switch op {
            case "$eq":
                if !areEqual(fieldValue, value.value) {
                    return false
                }
            case "$ne":
                if areEqual(fieldValue, value.value) {
                    return false
                }
            case "$gt":
                if !isGreaterThan(fieldValue, value.value) {
                    return false
                }
            case "$gte":
                if !isGreaterThanOrEqual(fieldValue, value.value) {
                    return false
                }
            case "$lt":
                if !isLessThan(fieldValue, value.value) {
                    return false
                }
            case "$lte":
                if !isLessThanOrEqual(fieldValue, value.value) {
                    return false
                }
            case "$in":
                if !isIn(fieldValue, array: value.value) {
                    return false
                }
            case "$nin":
                if isIn(fieldValue, array: value.value) {
                    return false
                }
            case "$exists":
                if let shouldExist = value.value as? Bool {
                    let exists = fieldValue != nil && !isNil(fieldValue)
                    if exists != shouldExist {
                        return false
                    }
                }
            default:
                // Unknown operator - skip
                continue
            }
        }
        return true
    }

    // MARK: - Logical Operators

    /// Evaluate $and operator
    private func evaluateAnd(_ conditions: [[String: AnyCodable]], on subject: Any) -> Bool {
        for condition in conditions {
            if !evaluateConditions(condition, on: subject) {
                return false
            }
        }
        return true
    }

    /// Evaluate $or operator
    private func evaluateOr(_ conditions: [[String: AnyCodable]], on subject: Any) -> Bool {
        for condition in conditions {
            if evaluateConditions(condition, on: subject) {
                return true
            }
        }
        return false
    }

    // MARK: - Comparison Operators

    /// Check equality between two values
    private func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        // Handle nil cases
        if lhs == nil && rhs == nil {
            return true
        }
        if lhs == nil || rhs == nil {
            return false
        }

        // Unwrap AnyCodable if needed
        let lhsValue = (lhs as? AnyCodable)?.value ?? lhs!
        let rhsValue = (rhs as? AnyCodable)?.value ?? rhs!

        // Compare different types
        if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
            return lhsString == rhsString
        }
        if let lhsInt = asNumber(lhsValue), let rhsInt = asNumber(rhsValue) {
            return lhsInt == rhsInt
        }
        if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
            return lhsBool == rhsBool
        }
        if let lhsDate = lhsValue as? Date, let rhsDate = rhsValue as? Date {
            return lhsDate == rhsDate
        }

        return false
    }

    /// Check if lhs > rhs
    private func isGreaterThan(_ lhs: Any?, _ rhs: Any?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }

        let lhsValue = (lhs as? AnyCodable)?.value ?? lhs
        let rhsValue = (rhs as? AnyCodable)?.value ?? rhs

        // Compare numbers
        if let lhsNum = asNumber(lhsValue), let rhsNum = asNumber(rhsValue) {
            return lhsNum > rhsNum
        }

        // Compare dates
        if let lhsDate = lhsValue as? Date, let rhsDate = rhsValue as? Date {
            return lhsDate > rhsDate
        }

        return false
    }

    /// Check if lhs >= rhs
    private func isGreaterThanOrEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        return areEqual(lhs, rhs) || isGreaterThan(lhs, rhs)
    }

    /// Check if lhs < rhs
    private func isLessThan(_ lhs: Any?, _ rhs: Any?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }

        let lhsValue = (lhs as? AnyCodable)?.value ?? lhs
        let rhsValue = (rhs as? AnyCodable)?.value ?? rhs

        // Compare numbers
        if let lhsNum = asNumber(lhsValue), let rhsNum = asNumber(rhsValue) {
            return lhsNum < rhsNum
        }

        // Compare dates
        if let lhsDate = lhsValue as? Date, let rhsDate = rhsValue as? Date {
            return lhsDate < rhsDate
        }

        return false
    }

    /// Check if lhs <= rhs
    private func isLessThanOrEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        return areEqual(lhs, rhs) || isLessThan(lhs, rhs)
    }

    /// Check if value is in array
    private func isIn(_ value: Any?, array: Any?) -> Bool {
        guard let value = value else {
            return false
        }

        // Handle AnyCodable wrapping
        let arrayValue = (array as? AnyCodable)?.value ?? array

        // Try different array types
        if let arrayOfAnyCodable = arrayValue as? [AnyCodable] {
            for element in arrayOfAnyCodable {
                if areEqual(value, element.value) {
                    return true
                }
            }
            return false
        }

        if let arrayOfStrings = arrayValue as? [String] {
            for element in arrayOfStrings {
                if areEqual(value, element) {
                    return true
                }
            }
            return false
        }

        if let arrayOfInts = arrayValue as? [Int] {
            for element in arrayOfInts {
                if areEqual(value, element) {
                    return true
                }
            }
            return false
        }

        // Try as array of Any
        if let mirror = Mirror(reflecting: arrayValue).displayStyle, mirror == .collection {
            for case let element in Mirror(reflecting: arrayValue).children {
                if areEqual(value, element.value) {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Value Extraction

    /// Extract property value from object using Mirror API
    private func extractValue(for field: String, from subject: Any) -> Any? {
        let mirror = Mirror(reflecting: subject)

        // Search through all properties
        for child in mirror.children {
            if child.label == field {
                return child.value
            }
        }

        return nil
    }

    /// Check if a value is nil (handles Optional types)
    private func isNil(_ value: Any?) -> Bool {
        guard let value = value else {
            return true
        }

        // Use Mirror to check if it's an Optional with nil value
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.isEmpty
        }

        return false
    }

    /// Convert various numeric types to Double for comparison
    private func asNumber(_ value: Any) -> Double? {
        if let intValue = value as? Int {
            return Double(intValue)
        }
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let floatValue = value as? Float {
            return Double(floatValue)
        }
        if let int8Value = value as? Int8 {
            return Double(int8Value)
        }
        if let int16Value = value as? Int16 {
            return Double(int16Value)
        }
        if let int32Value = value as? Int32 {
            return Double(int32Value)
        }
        if let int64Value = value as? Int64 {
            return Double(int64Value)
        }
        if let uintValue = value as? UInt {
            return Double(uintValue)
        }
        if let uint8Value = value as? UInt8 {
            return Double(uint8Value)
        }
        if let uint16Value = value as? UInt16 {
            return Double(uint16Value)
        }
        if let uint32Value = value as? UInt32 {
            return Double(uint32Value)
        }
        if let uint64Value = value as? UInt64 {
            return Double(uint64Value)
        }

        return nil
    }
}
