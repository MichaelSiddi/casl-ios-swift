# Data Model: CASL Swift

**Date**: 2025-10-22
**Status**: Phase 1 Design
**Purpose**: Define core data structures and their relationships for CASL authorization library

## Overview

This document specifies the data model for the CASL Swift library, including all core types, their properties, relationships, and state transitions. The model is designed for immutability, thread safety, and efficient permission checking.

---

## Core Entities

### 1. Ability

The central authorization manager that stores rules and evaluates permissions.

**Type**: Actor (thread-safe reference type)
**Purpose**: Container for rules with permission checking logic
**Lifecycle**: Created once per authorization context (user/session), updated dynamically

```swift
actor Ability: Sendable {
    // MARK: - Properties

    /// All authorization rules
    private(set) var rules: [Rule]

    /// Strategy for matching conditions against objects
    private let conditionsMatcher: ConditionsMatcher

    /// Strategy for matching field patterns
    private let fieldMatcher: FieldMatcher

    /// Custom function to detect subject type from instances
    private let detectSubjectType: (Any) -> String

    /// Action alias resolver (e.g., "manage" -> all actions)
    private let aliasResolver: AliasResolver?

    // MARK: - Initializer

    init(
        rules: [RawRule],
        conditionsMatcher: ConditionsMatcher = QueryMatcher(),
        fieldMatcher: FieldMatcher = GlobFieldMatcher(),
        detectSubjectType: @escaping (Any) -> String = defaultSubjectTypeDetector,
        aliasResolver: AliasResolver? = nil
    )

    // MARK: - Permission Checking (nonisolated for sync access)

    /// Check if action is permitted
    nonisolated func can(_ action: String, _ subject: Any, field: String? = nil) -> Bool

    /// Check if action is denied
    nonisolated func cannot(_ action: String, _ subject: Any, field: String? = nil) -> Bool

    /// Find the first matching rule for given action/subject/field
    nonisolated func relevantRuleFor(_ action: String, _ subject: Any, field: String? = nil) -> Rule?

    // MARK: - Rule Management (isolated, async)

    /// Update all rules (replaces existing rules)
    func update(rules: [RawRule])

    /// Get all rules matching action and subject type
    nonisolated func rulesFor(action: String, subjectType: String, field: String? = nil) -> [Rule]
}
```

**State Transitions**:
1. Created with initial rules
2. Rules evaluated during permission checks (immutable read)
3. Rules updated via `update(rules:)` (isolated write)

**Relationships**:
- Contains many `Rule` instances
- Uses `ConditionsMatcher` strategy
- Uses `FieldMatcher` strategy
- Uses `AliasResolver` optionally

---

### 2. Rule

Represents a single authorization rule with matching logic.

**Type**: Struct (value type, immutable, Sendable)
**Purpose**: Encapsulate permission grant/deny logic with conditions
**Lifecycle**: Immutable after creation, compared during permission checks

```swift
struct Rule: Sendable, Equatable {
    // MARK: - Properties

    /// Action(s) this rule applies to (e.g., "read", "update")
    let action: String

    /// Subject type(s) this rule applies to (e.g., "BlogPost")
    let subject: String

    /// Optional conditions that restrict when rule applies
    let conditions: Condition?

    /// Optional field restrictions
    let fields: [String]?

    /// If true, this is a deny rule (cannot); if false, allow rule (can)
    let inverted: Bool

    /// Optional reason explaining why this rule exists
    let reason: String?

    /// Compiled condition matcher (lazily created from conditions)
    private let compiledMatcher: MatchConditions?

    // MARK: - Initializer

    init(
        action: String,
        subject: String,
        conditions: Condition? = nil,
        fields: [String]? = nil,
        inverted: Bool = false,
        reason: String? = nil,
        conditionsMatcher: ConditionsMatcher
    )

    // MARK: - Matching Logic

    /// Check if this rule matches the given action
    func matchesAction(_ action: String) -> Bool

    /// Check if this rule matches the given subject type
    func matchesSubjectType(_ subjectType: String) -> Bool

    /// Check if this rule matches the given field (if field restrictions exist)
    func matchesField(_ field: String?, fieldMatcher: FieldMatcher) -> Bool

    /// Check if this rule's conditions match the given subject instance
    func matchesConditions(_ subject: Any?) -> Bool

    /// Check if this rule fully matches action/subject/field
    func matches(action: String, subject: Any, field: String?, detectSubjectType: (Any) -> String, fieldMatcher: FieldMatcher) -> Bool
}
```

**Validation Rules**:
- `action` must not be empty
- `subject` must not be empty (use "all" for wildcard)
- If `fields` is non-nil, must not be empty array
- `conditions` are validated by `ConditionsMatcher`

**Special Values**:
- Action `"manage"` = wildcard matching all actions
- Subject `"all"` = wildcard matching all subject types
- Fields `["*"]` = wildcard matching all fields

---

### 3. RawRule

The serializable representation of a Rule, used for JSON encoding/decoding.

**Type**: Struct (value type, Codable)
**Purpose**: Portable rule format for serialization and network transport
**Lifecycle**: Created from/to JSON, converted to/from Rule

```swift
struct RawRule: Codable, Equatable, Sendable {
    // MARK: - Properties

    /// Action or array of actions
    let action: StringOrArray

    /// Optional subject or array of subjects
    let subject: StringOrArray?

    /// Optional conditions dictionary (MongoDB-style query)
    let conditions: [String: AnyCodable]?

    /// Optional field or array of fields
    let fields: StringOrArray?

    /// Optional inverted flag (defaults to false if omitted)
    let inverted: Bool?

    /// Optional reason string
    let reason: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case action, subject, conditions, fields, inverted, reason
    }

    // MARK: - Conversion

    /// Expand to multiple Rule instances (if arrays present)
    func toRules(conditionsMatcher: ConditionsMatcher) -> [Rule]
}

/// Helper type for string or array of strings
enum StringOrArray: Codable, Equatable {
    case single(String)
    case multiple([String])

    var values: [String] {
        switch self {
        case .single(let s): return [s]
        case .multiple(let arr): return arr
        }
    }
}
```

**JSON Format** (matches CASL JavaScript):
```json
{
  "action": "read",
  "subject": "BlogPost",
  "conditions": { "authorId": "123" },
  "fields": ["title", "content"],
  "inverted": false,
  "reason": "Users can read their own posts"
}
```

**Conversion Rules**:
- Single `action` + single `subject` → 1 Rule
- Array `action` + single `subject` → N Rules (one per action)
- Single `action` + array `subject` → M Rules (one per subject)
- Array `action` + array `subject` → N×M Rules (cartesian product)

---

### 4. Condition

Represents a query condition for attribute-based access control.

**Type**: Struct (value type, Codable)
**Purpose**: Define restrictions on when a rule applies based on subject properties
**Lifecycle**: Immutable after creation, evaluated during permission checks

```swift
struct Condition: Codable, Equatable, Sendable {
    // MARK: - Properties

    /// Field name to query (e.g., "authorId", "createdAt")
    let field: String

    /// Query operator to apply
    let `operator`: QueryOperator

    // MARK: - Convenience Initializers

    static func equal(_ field: String, _ value: AnyCodable) -> Condition
    static func greaterThan(_ field: String, _ value: AnyCodable) -> Condition
    static func lessThan(_ field: String, _ value: AnyCodable) -> Condition
    static func `in`(_ field: String, _ values: [AnyCodable]) -> Condition
    static func notIn(_ field: String, _ values: [AnyCodable]) -> Condition
    static func exists(_ field: String, _ exists: Bool = true) -> Condition

    // MARK: - Logical Combinators

    static func and(_ conditions: [Condition]) -> Condition
    static func or(_ conditions: [Condition]) -> Condition
    static func not(_ condition: Condition) -> Condition
}
```

**MongoDB-Style Query Syntax**:
```swift
// Simple condition
Condition.equal("authorId", "123")
// Translates to: { "authorId": { "$eq": "123" } }

// Compound condition
Condition.and([
    .equal("authorId", "123"),
    .greaterThan("createdAt", Date().addingTimeInterval(-86400))
])
// Translates to: { "$and": [ {...}, {...} ] }
```

---

### 5. QueryOperator

Enum representing MongoDB-style query operators.

**Type**: Enum with associated values (Codable)
**Purpose**: Type-safe representation of comparison and logical operators
**Lifecycle**: Immutable, evaluated during condition matching

```swift
enum QueryOperator: Codable, Equatable, Sendable {
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

    /// Logical AND ($and)
    case and([Condition])

    /// Logical OR ($or)
    case or([Condition])

    /// Logical NOT ($not)
    case not(Condition)

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
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
}
```

---

### 6. AbilityBuilder

Builder pattern helper for constructing Ability instances with fluent API.

**Type**: Class (reference type for mutation)
**Purpose**: Accumulate rules using can/cannot methods, then build Ability
**Lifecycle**: Created, rules added via can/cannot, built once into Ability

```swift
class AbilityBuilder: Sendable {
    // MARK: - Properties

    /// Accumulated raw rules
    private(set) var rules: [RawRule] = []

    /// Options for building the Ability
    private let options: AbilityOptions

    // MARK: - Initializer

    init(options: AbilityOptions = .init())

    // MARK: - Rule Definition Methods

    /// Define an allow rule
    @discardableResult
    func can(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define multiple allow rules (array actions and/or subjects)
    @discardableResult
    func can(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define a deny rule
    @discardableResult
    func cannot(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define multiple deny rules
    @discardableResult
    func cannot(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    // MARK: - Building

    /// Build the Ability instance
    func build() -> Ability
}
```

**Usage Pattern**:
```swift
let ability = AbilityBuilder()
    .can("read", "BlogPost")
    .can("update", "BlogPost", conditions: ["authorId": userId])
    .cannot("delete", "BlogPost", conditions: ["createdAt": ["$lt": Date().addingTimeInterval(-86400)]])
    .build()
```

---

### 7. ForbiddenError

Error type representing authorization failures.

**Type**: Struct (Error, LocalizedError)
**Purpose**: Provide detailed information about permission denial
**Lifecycle**: Thrown when permission check fails

```swift
struct ForbiddenError: Error, LocalizedError, Sendable {
    // MARK: - Properties

    /// Action that was attempted
    let action: String

    /// Subject type that was accessed
    let subjectType: String

    /// Optional field that was accessed
    let field: String?

    /// Optional reason why denied
    let reason: String?

    // MARK: - Error Description

    var errorDescription: String? {
        var message = "Cannot \(action) \(subjectType)"
        if let field = field {
            message += ".\(field)"
        }
        if let reason = reason {
            message += ": \(reason)"
        }
        return message
    }

    // MARK: - Helper Method

    /// Throw error unless permission is granted
    static func throwUnlessCan(
        _ ability: Ability,
        _ action: String,
        _ subject: Any,
        field: String? = nil
    ) throws {
        if !ability.can(action, subject, field: field) {
            let subjectType = ability.detectSubjectType(subject)
            throw ForbiddenError(
                action: action,
                subjectType: subjectType,
                field: field,
                reason: nil
            )
        }
    }
}
```

**Usage**:
```swift
// Throw if permission denied
try ForbiddenError.throwUnlessCan(ability, "delete", post)

// Catch and handle
do {
    try ForbiddenError.throwUnlessCan(ability, "delete", post)
} catch let error as ForbiddenError {
    print(error.errorDescription) // "Cannot delete BlogPost"
}
```

---

## Supporting Types

### 8. SubjectTypeProvider Protocol

Protocol for types that provide custom subject type identification.

```swift
protocol SubjectTypeProvider {
    /// The subject type string for permission checks
    static var subjectType: String { get }
}
```

**Usage**:
```swift
class BlogPost: SubjectTypeProvider {
    static let subjectType = "BlogPost"

    let id: String
    let authorId: String
    let title: String
}
```

---

### 9. ConditionsMatcher Protocol

Strategy protocol for matching conditions against objects.

```swift
protocol ConditionsMatcher: Sendable {
    /// Compile a condition into a matcher function
    func compile(_ condition: Condition) -> MatchConditions

    /// Check if object matches condition
    func matches(_ object: Any, condition: Condition) -> Bool
}

/// Closure type for compiled condition matchers
typealias MatchConditions = @Sendable (Any) -> Bool
```

**Implementations**:
- `QueryMatcher`: MongoDB-style query evaluation (default)
- Custom implementations for domain-specific needs

---

### 10. FieldMatcher Protocol

Strategy protocol for matching field patterns.

```swift
protocol FieldMatcher: Sendable {
    /// Check if field matches pattern
    func matches(field: String, patterns: [String]) -> Bool
}
```

**Implementations**:
- `GlobFieldMatcher`: Supports wildcard and prefix patterns (default)
- `ExactFieldMatcher`: Only exact string matching
- Custom implementations for advanced needs

---

### 11. AliasResolver

Maps action aliases to their expanded forms.

```swift
struct AliasResolver: Sendable {
    private let aliases: [String: [String]]

    init(aliases: [String: [String]])

    /// Resolve action to itself and any aliases
    func resolve(_ action: String) -> [String]

    /// Standard CRUD alias resolver
    static let standard = AliasResolver(aliases: [
        "manage": ["create", "read", "update", "delete"],
        "modify": ["update"]
    ])
}
```

---

### 12. AbilityOptions

Configuration options for Ability creation.

```swift
struct AbilityOptions: Sendable {
    /// Conditions matching strategy
    var conditionsMatcher: ConditionsMatcher = QueryMatcher()

    /// Field matching strategy
    var fieldMatcher: FieldMatcher = GlobFieldMatcher()

    /// Custom subject type detector
    var detectSubjectType: @Sendable (Any) -> String = defaultSubjectTypeDetector

    /// Optional action alias resolver
    var aliasResolver: AliasResolver? = .standard
}
```

---

## Data Flow Diagrams

### Permission Check Flow

```
┌─────────────┐
│ User calls  │
│ can(action, │
│ subject)    │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ Detect subject   │
│ type from object │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Find rules for   │
│ action + subject │
│ type + field     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ For each rule:   │
│ - Match action?  │
│ - Match subject? │
│ - Match field?   │
│ - Match conds?   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Found matching   │
│ rule?            │
├──────────────────┤
│ Yes: Return      │
│ !rule.inverted   │
│ No: Return false │
└──────────────────┘
```

### Rule Matching Priority

Rules are evaluated in order of specificity:
1. Rules with conditions + fields (most specific)
2. Rules with conditions only
3. Rules with fields only
4. Rules without conditions or fields (least specific)

Within same specificity level, first rule wins (CASL behavior).

---

## Memory Layout Considerations

### Value Types (Stack/Inline)
- `Rule` (~200-400 bytes depending on conditions)
- `RawRule` (~150-300 bytes)
- `Condition` (~100-200 bytes)
- `QueryOperator` (~50-150 bytes)

### Reference Types (Heap)
- `Ability` (actor) - minimal overhead, rules are value types
- `AbilityBuilder` - temporary, deallocated after build

### Performance Characteristics
- Rule lookup: O(n) linear scan (optimized with indexing)
- Condition matching: O(k) where k = number of conditions
- Overall permission check: O(n×k) ≈ O(100) for typical rule sets
- Target: <1ms for 100 rules achieved via efficient matching

---

## Thread Safety Guarantees

1. **Ability**: Actor-isolated, compiler-enforced thread safety
2. **Rule**: Immutable value type, inherently thread-safe
3. **RawRule**: Immutable value type, inherently thread-safe
4. **Permission checks**: Nonisolated (sync), safe via value semantics
5. **Rule updates**: Isolated (async), serialized by actor

---

## Validation Rules Summary

| Type | Validation |
|------|------------|
| Rule.action | Non-empty string |
| Rule.subject | Non-empty string or "all" |
| Rule.fields | If present, non-empty array |
| Condition.field | Non-empty string, valid property path |
| QueryOperator values | Type-appropriate (numbers for comparisons, etc.) |
| RawRule.action | Non-empty string or array |
| RawRule.subject | If present, non-empty string or array |

---

## Next Steps

1. ✅ Data model defined
2. **Next**: Create contracts/api-reference.md with full API signatures
3. **Then**: Create quickstart.md with usage examples
4. **Finally**: Update agent context and prepare for task generation
