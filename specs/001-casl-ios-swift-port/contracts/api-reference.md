# API Reference: CASL Swift

**Version**: 1.0.0
**Date**: 2025-10-22
**Minimum Deployment**: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+

## Overview

This document provides the complete public API surface for the CASL Swift library. All types, methods, and protocols are documented with signatures, parameters, return values, and usage examples.

---

## Core Types

### Ability

The main interface for permission management and checking.

```swift
actor Ability: Sendable {
    // MARK: - Initialization

    /// Create an Ability with rules and options
    ///
    /// - Parameters:
    ///   - rules: Array of raw rules to initialize with
    ///   - options: Configuration options for matching strategies
    init(rules: [RawRule], options: AbilityOptions = .init())

    // MARK: - Permission Checking

    /// Check if action is permitted on subject
    ///
    /// - Parameters:
    ///   - action: The action to check (e.g., "read", "update")
    ///   - subject: The subject to check permission for (type or instance)
    ///   - field: Optional field name for field-level permissions
    /// - Returns: true if permission is granted, false otherwise
    nonisolated func can(_ action: String, _ subject: Any, field: String? = nil) -> Bool

    /// Check if action is denied on subject
    ///
    /// - Parameters:
    ///   - action: The action to check
    ///   - subject: The subject to check permission for
    ///   - field: Optional field name for field-level permissions
    /// - Returns: true if permission is explicitly denied, false otherwise
    nonisolated func cannot(_ action: String, _ subject: Any, field: String? = nil) -> Bool

    /// Find the relevant rule for given action/subject/field
    ///
    /// - Parameters:
    ///   - action: The action to find a rule for
    ///   - subject: The subject to find a rule for
    ///   - field: Optional field name
    /// - Returns: The first matching Rule, or nil if no match
    nonisolated func relevantRuleFor(
        _ action: String,
        _ subject: Any,
        field: String? = nil
    ) -> Rule?

    // MARK: - Rule Management

    /// Update all rules (replaces existing rules)
    ///
    /// - Parameter rules: New array of raw rules
    func update(rules: [RawRule]) async

    /// Get all rules for specific action and subject type
    ///
    /// - Parameters:
    ///   - action: Action to filter by
    ///   - subjectType: Subject type string to filter by
    ///   - field: Optional field to filter by
    /// - Returns: Array of matching rules
    nonisolated func rulesFor(
        action: String,
        subjectType: String,
        field: String? = nil
    ) -> [Rule]

    // MARK: - Serialization

    /// Export all rules as RawRule array for serialization
    ///
    /// - Returns: Array of RawRule instances
    nonisolated func exportRules() -> [RawRule]
}
```

**Usage Example**:
```swift
let ability = Ability(rules: [
    RawRule(action: "read", subject: "BlogPost"),
    RawRule(action: "update", subject: "BlogPost", conditions: ["authorId": userId])
])

// Check permissions
if ability.can("read", post) {
    // Allow access
}

if ability.cannot("delete", post) {
    // Deny access
}

// Update rules dynamically
await ability.update(rules: newRules)
```

---

### AbilityBuilder

Fluent API for constructing Ability instances.

```swift
class AbilityBuilder: Sendable {
    // MARK: - Initialization

    /// Create a new builder
    ///
    /// - Parameter options: Options to use when building the Ability
    init(options: AbilityOptions = .init())

    // MARK: - Allow Rules

    /// Define an allow rule for single action/subject
    ///
    /// - Parameters:
    ///   - action: Action to allow
    ///   - subject: Subject type to allow action on
    ///   - conditions: Optional conditions restricting when rule applies
    ///   - fields: Optional field restrictions
    /// - Returns: Self for chaining
    @discardableResult
    func can(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define allow rules for multiple actions on single subject
    ///
    /// - Parameters:
    ///   - actions: Array of actions to allow
    ///   - subject: Subject type to allow actions on
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    /// - Returns: Self for chaining
    @discardableResult
    func can(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define allow rule for single action on multiple subjects
    ///
    /// - Parameters:
    ///   - action: Action to allow
    ///   - subjects: Array of subject types
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    /// - Returns: Self for chaining
    @discardableResult
    func can(
        _ action: String,
        _ subjects: [String],
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    // MARK: - Deny Rules

    /// Define a deny rule for single action/subject
    ///
    /// - Parameters:
    ///   - action: Action to deny
    ///   - subject: Subject type to deny action on
    ///   - conditions: Optional conditions restricting when rule applies
    ///   - fields: Optional field restrictions
    /// - Returns: Self for chaining
    @discardableResult
    func cannot(
        _ action: String,
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    /// Define deny rules for multiple actions
    ///
    /// - Parameters:
    ///   - actions: Array of actions to deny
    ///   - subject: Subject type
    ///   - conditions: Optional conditions
    ///   - fields: Optional field restrictions
    /// - Returns: Self for chaining
    @discardableResult
    func cannot(
        _ actions: [String],
        _ subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil
    ) -> Self

    // MARK: - Building

    /// Build the Ability instance
    ///
    /// - Returns: Configured Ability with all defined rules
    func build() -> Ability

    // MARK: - Access

    /// Get accumulated raw rules
    var rules: [RawRule] { get }
}
```

**Usage Example**:
```swift
let ability = AbilityBuilder()
    .can("read", "BlogPost")
    .can(["create", "update"], "BlogPost", conditions: ["authorId": userId])
    .cannot("delete", "BlogPost", conditions: ["published": true])
    .can("manage", "Comment")
    .build()
```

---

### Rule

Immutable authorization rule with matching logic.

```swift
struct Rule: Sendable, Equatable {
    // MARK: - Properties

    /// Action this rule applies to
    let action: String

    /// Subject type this rule applies to
    let subject: String

    /// Optional conditions dictionary
    let conditions: [String: AnyCodable]?

    /// Optional field restrictions
    let fields: [String]?

    /// Whether this is a deny rule
    let inverted: Bool

    /// Optional reason string
    let reason: String?

    // MARK: - Matching

    /// Check if this rule matches given action
    ///
    /// - Parameter action: Action to check
    /// - Returns: true if matches (considering "manage" wildcard)
    func matchesAction(_ action: String) -> Bool

    /// Check if this rule matches given subject type
    ///
    /// - Parameter subjectType: Subject type to check
    /// - Returns: true if matches (considering "all" wildcard)
    func matchesSubjectType(_ subjectType: String) -> Bool

    /// Check if this rule matches given field
    ///
    /// - Parameters:
    ///   - field: Field name to check (nil = no field restriction)
    ///   - fieldMatcher: Matcher strategy for patterns
    /// - Returns: true if field matches or no field restriction
    func matchesField(_ field: String?, fieldMatcher: FieldMatcher) -> Bool

    /// Check if this rule's conditions match given subject instance
    ///
    /// - Parameter subject: Subject instance to check conditions against
    /// - Returns: true if conditions match or no conditions
    func matchesConditions(_ subject: Any?) -> Bool
}
```

---

### RawRule

Serializable rule representation.

```swift
struct RawRule: Codable, Equatable, Sendable {
    // MARK: - Properties

    /// Action or array of actions
    let action: StringOrArray

    /// Optional subject or array of subjects
    let subject: StringOrArray?

    /// Optional conditions dictionary
    let conditions: [String: AnyCodable]?

    /// Optional field or array of fields
    let fields: StringOrArray?

    /// Optional inverted flag
    let inverted: Bool?

    /// Optional reason string
    let reason: String?

    // MARK: - Initialization

    /// Create a raw rule
    ///
    /// - Parameters:
    ///   - action: Action string or array
    ///   - subject: Optional subject string or array
    ///   - conditions: Optional conditions dictionary
    ///   - fields: Optional field string or array
    ///   - inverted: Whether this is a deny rule (default: false)
    ///   - reason: Optional documentation string
    init(
        action: StringOrArray,
        subject: StringOrArray? = nil,
        conditions: [String: AnyCodable]? = nil,
        fields: StringOrArray? = nil,
        inverted: Bool? = nil,
        reason: String? = nil
    )

    /// Create a simple raw rule with single action/subject
    ///
    /// - Parameters:
    ///   - action: Single action string
    ///   - subject: Single subject string
    ///   - conditions: Optional conditions
    ///   - fields: Optional fields array
    ///   - inverted: Whether this is deny rule
    ///   - reason: Optional reason
    init(
        action: String,
        subject: String,
        conditions: [String: AnyCodable]? = nil,
        fields: [String]? = nil,
        inverted: Bool = false,
        reason: String? = nil
    )
}
```

**JSON Example**:
```json
{
  "action": ["read", "update"],
  "subject": "BlogPost",
  "conditions": {
    "authorId": "123",
    "published": { "$ne": false }
  },
  "fields": ["title", "content"],
  "inverted": false,
  "reason": "Authors can edit their published posts"
}
```

---

### ForbiddenError

Error type for authorization failures.

```swift
struct ForbiddenError: Error, LocalizedError, Sendable {
    // MARK: - Properties

    /// Action that was attempted
    let action: String

    /// Subject type that was accessed
    let subjectType: String

    /// Optional field that was accessed
    let field: String?

    /// Optional reason for denial
    let reason: String?

    // MARK: - Error Description

    /// Human-readable error description
    var errorDescription: String? { get }

    // MARK: - Throwing Helper

    /// Throw error unless permission is granted
    ///
    /// - Parameters:
    ///   - ability: Ability to check permission with
    ///   - action: Action to check
    ///   - subject: Subject to check
    ///   - field: Optional field to check
    /// - Throws: ForbiddenError if permission denied
    static func throwUnlessCan(
        _ ability: Ability,
        _ action: String,
        _ subject: Any,
        field: String? = nil
    ) throws
}
```

**Usage Example**:
```swift
do {
    try ForbiddenError.throwUnlessCan(ability, "delete", post)
    // Permission granted, proceed
    deletePost(post)
} catch let error as ForbiddenError {
    print(error.errorDescription)
    // "Cannot delete BlogPost"
}
```

---

## Protocols

### SubjectTypeProvider

Protocol for custom subject type identification.

```swift
protocol SubjectTypeProvider {
    /// Subject type string for permission checks
    static var subjectType: String { get }
}
```

**Usage Example**:
```swift
class BlogPost: SubjectTypeProvider {
    static let subjectType = "BlogPost"

    let id: String
    let authorId: String
}

let post = BlogPost(id: "1", authorId: "123")
// Automatically detected as "BlogPost" subject type
```

---

### ConditionsMatcher

Strategy protocol for condition matching.

```swift
protocol ConditionsMatcher: Sendable {
    /// Compile condition into matcher function
    ///
    /// - Parameter conditions: Conditions dictionary
    /// - Returns: Closure that checks if object matches
    func compile(_ conditions: [String: AnyCodable]) -> MatchConditions

    /// Check if object matches conditions
    ///
    /// - Parameters:
    ///   - object: Object to check
    ///   - conditions: Conditions to match against
    /// - Returns: true if object matches all conditions
    func matches(_ object: Any, conditions: [String: AnyCodable]) -> Bool
}

/// Compiled condition matcher closure
typealias MatchConditions = @Sendable (Any) -> Bool
```

**Built-in Implementation**:
- `QueryMatcher`: MongoDB-style query evaluation (default)

---

### FieldMatcher

Strategy protocol for field pattern matching.

```swift
protocol FieldMatcher: Sendable {
    /// Check if field matches any of the patterns
    ///
    /// - Parameters:
    ///   - field: Field name to check
    ///   - patterns: Array of pattern strings
    /// - Returns: true if field matches any pattern or patterns is empty
    func matches(field: String, patterns: [String]) -> Bool
}
```

**Built-in Implementations**:
- `GlobFieldMatcher`: Wildcard and prefix patterns (default)
- `ExactFieldMatcher`: Exact string matching only

---

## Supporting Types

### AnyCodable

Type-erased Codable wrapper for heterogeneous values.

```swift
struct AnyCodable: Codable, Equatable, Sendable {
    /// Wrapped value
    let value: Any

    /// Create with any value
    ///
    /// - Parameter value: Value to wrap
    init(_ value: Any)

    // Codable conformance handles Int, String, Bool, Double, Array, Dictionary
}
```

**Usage Example**:
```swift
let conditions: [String: AnyCodable] = [
    "authorId": AnyCodable("123"),
    "age": AnyCodable(25),
    "published": AnyCodable(true),
    "tags": AnyCodable(["swift", "authorization"])
]
```

---

### StringOrArray

Enum for single string or array of strings.

```swift
enum StringOrArray: Codable, Equatable, Sendable {
    case single(String)
    case multiple([String])

    /// Get all values as array
    var values: [String] { get }

    // Codable conformance automatically handles both formats
}
```

**JSON Examples**:
```json
"action": "read"              // StringOrArray.single("read")
"action": ["read", "update"]  // StringOrArray.multiple(["read", "update"])
```

---

### AbilityOptions

Configuration options for Ability.

```swift
struct AbilityOptions: Sendable {
    /// Conditions matching strategy (default: QueryMatcher)
    var conditionsMatcher: ConditionsMatcher

    /// Field matching strategy (default: GlobFieldMatcher)
    var fieldMatcher: FieldMatcher

    /// Custom subject type detector (default: protocol + Mirror)
    var detectSubjectType: @Sendable (Any) -> String

    /// Optional action alias resolver (default: standard aliases)
    var aliasResolver: AliasResolver?

    /// Default options
    init()
}
```

---

### AliasResolver

Maps action aliases to expanded forms.

```swift
struct AliasResolver: Sendable {
    /// Create with alias mapping
    ///
    /// - Parameter aliases: Dictionary mapping alias to array of actions
    init(aliases: [String: [String]])

    /// Resolve action to itself and any aliases
    ///
    /// - Parameter action: Action to resolve
    /// - Returns: Array of action strings (original + aliases)
    func resolve(_ action: String) -> [String]

    /// Standard CRUD aliases
    /// - "manage" → ["create", "read", "update", "delete"]
    /// - "modify" → ["update"]
    static let standard: AliasResolver
}
```

---

## Global Functions

### Subject Type Detection

```swift
/// Default subject type detector using protocol + Mirror
///
/// - Parameter subject: Subject instance
/// - Returns: Subject type string
func defaultSubjectTypeDetector(_ subject: Any) -> String
```

---

## Constants

### Special Action Names

```swift
/// Wildcard action matching all actions
let MANAGE_ACTION = "manage"
```

### Special Subject Names

```swift
/// Wildcard subject matching all subject types
let ALL_SUBJECTS = "all"
```

### Special Field Patterns

```swift
/// Wildcard field pattern matching all fields
let ALL_FIELDS = "*"
```

---

## Error Handling

All errors thrown by the library conform to Swift's `Error` protocol:

- `ForbiddenError`: Permission denied
- `DecodingError`: JSON deserialization failed
- `EncodingError`: JSON serialization failed

---

## Thread Safety

### Thread-Safe Operations
- Permission checking (`can`, `cannot`, `relevantRuleFor`)
- Rule querying (`rulesFor`, `exportRules`)

### Operations Requiring Synchronization
- Rule updates (`update(rules:)`) - use `await`

**Example**:
```swift
// Safe: Concurrent permission checks
Task {
    ability.can("read", post1)
}
Task {
    ability.can("update", post2)
}

// Safe: Rule updates are serialized
Task {
    await ability.update(rules: newRules)
}
```

---

## Performance Characteristics

| Operation | Time Complexity | Typical Performance |
|-----------|----------------|---------------------|
| `can()` | O(n × k) | <1ms for 100 rules |
| `cannot()` | O(n × k) | <1ms for 100 rules |
| `relevantRuleFor()` | O(n × k) | <1ms for 100 rules |
| `update(rules:)` | O(n) | <1ms for 100 rules |
| Serialization | O(n) | <10ms for 100 rules |
| Deserialization | O(n) | <10ms for 100 rules |

*n = number of rules, k = avg conditions per rule*

---

## Version Compatibility

- **Minimum Swift**: 5.10
- **Minimum iOS**: 13.0
- **Minimum macOS**: 10.15
- **Minimum watchOS**: 6.0
- **Minimum tvOS**: 13.0

---

## Next Steps

1. ✅ API reference complete
2. **Next**: Create quickstart.md with usage examples
3. **Then**: Update agent context
4. **Finally**: Prepare for task generation
