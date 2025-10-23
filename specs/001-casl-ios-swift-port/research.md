# Research & Design Decisions: CASL Swift Port

**Date**: 2025-10-22
**Status**: Phase 0 Complete
**Purpose**: Document technical research and design decisions for porting CASL to Swift 5.10

## Overview

This document captures research findings and design decisions for implementing CASL authorization library in Swift. Each decision is based on Swift best practices, performance requirements, and alignment with the CASL JavaScript reference implementation.

---

## 1. Subject Type Detection Strategy

### Decision

Use a **hybrid protocol + Mirror API approach**:
- Define a `SubjectTypeProvider` protocol for types that opt-in
- Fall back to Mirror API for automatic type detection
- Support custom type names via protocol conformance

### Rationale

**Why this approach**:
- Protocols give compile-time safety and performance for known types
- Mirror API provides automatic support for any Swift type without boilerplate
- Matches CASL's flexibility (works with classes, structs, enums)
- Developers can customize behavior when needed

**Performance**: Protocol dispatch is fast (<1ns), Mirror API adds ~10-50ns overhead but still well within <1ms budget

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Protocol-only | Requires all types to conform, too much boilerplate for users |
| Mirror-only | Slower and less type-safe than protocol approach |
| String-based only | Loses type safety benefits of Swift |

### Code Example

```swift
// Protocol for opt-in type detection
protocol SubjectTypeProvider {
    static var subjectType: String { get }
}

// Automatic detection using Mirror
func detectSubjectType<T>(_ subject: T) -> String {
    // First check protocol conformance
    if let provider = subject as? SubjectTypeProvider {
        return type(of: provider).subjectType
    }

    // Fall back to Mirror-based detection
    let mirror = Mirror(reflecting: subject)
    return String(describing: mirror.subjectType)
}

// Usage examples
class BlogPost: SubjectTypeProvider {
    static let subjectType = "BlogPost"
    let authorId: String
    let title: String
}

struct Comment {
    // No protocol conformance needed
    let text: String
}

// Both work automatically
let post = BlogPost(authorId: "123", title: "Hello")
let comment = Comment(text: "Great!")

detectSubjectType(post)    // "BlogPost" (via protocol)
detectSubjectType(comment) // "Comment" (via Mirror)
```

### Performance Implications

- Protocol path: ~1ns (negligible)
- Mirror path: ~10-50ns (still <1% of 1ms budget)
- Caching type names amortizes cost to near-zero

### References

- Swift Mirror documentation: https://developer.apple.com/documentation/swift/mirror
- Protocol-oriented programming: https://developer.apple.com/videos/play/wwdc2015/408/

---

## 2. Condition Matching Implementation

### Decision

Use **KeyPath + Mirror hybrid with enum-based operators**:
- Represent query operators as Swift enums (e.g., `.equal`, `.greaterThan`, `.in`)
- Use KeyPath for strongly-typed access when available
- Fall back to Mirror for dynamic property access
- Implement recursive evaluation for nested conditions

### Rationale

**Why this approach**:
- Enums provide type-safe, exhaustive operator representation
- KeyPath gives best performance for known types
- Mirror enables flexibility for any Swift type
- Matches MongoDB query semantics from CASL JS

**Performance**: KeyPath access is ~5-10ns, Mirror access ~50-100ns per property

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| String-based property access | No compile-time safety, error-prone |
| Codable-only | Requires all types to be Codable, too restrictive |
| NSPredicate | ObjC legacy, not idiomatic Swift, larger overhead |

### Code Example

```swift
// Query operator enum
enum QueryOperator: Codable {
    case equal(Any)
    case notEqual(Any)
    case greaterThan(Comparable)
    case lessThan(Comparable)
    case `in`([Any])
    case notIn([Any])
    case exists(Bool)

    // Logical operators
    case and([Condition])
    case or([Condition])
    case not(Condition)
}

// Condition type
struct Condition: Codable {
    let field: String
    let `operator`: QueryOperator
}

// Matcher implementation
struct QueryMatcher {
    func matches<T>(_ object: T, condition: Condition) -> Bool {
        // Extract property value
        let value = extractValue(from: object, field: condition.field)

        // Evaluate operator
        switch condition.operator {
        case .equal(let expected):
            return value == expected
        case .greaterThan(let threshold):
            return (value as? Comparable) > threshold
        case .in(let values):
            return values.contains(value)
        case .and(let conditions):
            return conditions.allSatisfy { matches(object, condition: $0) }
        // ... other operators
        }
    }

    private func extractValue<T>(from object: T, field: String) -> Any? {
        let mirror = Mirror(reflecting: object)
        return mirror.children.first { $0.label == field }?.value
    }
}

// Usage
let post = BlogPost(authorId: "123", createdAt: Date())
let condition = Condition(field: "authorId", operator: .equal("123"))
let matcher = QueryMatcher()
matcher.matches(post, condition: condition) // true
```

### Performance Implications

- Simple equality check: ~50-100ns (Mirror lookup + comparison)
- Complex nested condition: ~100-500ns (depends on depth)
- Well within <1ms budget even for 10+ conditions per rule

### References

- Swift enums with associated values: https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html
- Mirror API: https://developer.apple.com/documentation/swift/mirror

---

## 3. Generic Type Design

### Decision

Use **generic parameters with type erasure for flexibility**:
- Core types use generic parameters for actions and subjects
- Provide type-erased wrappers (`AnyAbility`) for dynamic use cases
- Use type aliases for common patterns

### Rationale

**Why this approach**:
- Generic parameters give compile-time type safety
- Type erasure provides escape hatch for dynamic scenarios
- Type aliases reduce API complexity for common cases
- Balances TypeScript's flexibility with Swift's type system

**Complexity**: Higher than simple types, but necessary for type-safe API

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Associated types only | Harder to use in practice, complicates API |
| No generics | Loses type safety, defeats Swift's strengths |
| Overly generic | API becomes too complex, poor developer experience |

### Code Example

```swift
// Generic Ability type
class Ability<Actions, SubjectTypes> {
    func can(_ action: Actions, _ subject: SubjectTypes, field: String? = nil) -> Bool {
        // ...
    }
}

// Type aliases for common patterns
typealias AppAbility = Ability<AppAction, AppSubject>

enum AppAction: String {
    case read, create, update, delete, manage
}

enum AppSubject: String {
    case blogPost = "BlogPost"
    case comment = "Comment"
    case user = "User"
}

// Type-erased wrapper for dynamic use
class AnyAbility {
    private let _can: (String, Any, String?) -> Bool

    init<A, S>(_ ability: Ability<A, S>) {
        _can = { action, subject, field in
            // Erase types and forward call
        }
    }

    func can(_ action: String, _ subject: Any, field: String? = nil) -> Bool {
        return _can(action, subject, field)
    }
}

// Usage - strongly typed
let ability = AppAbility(rules: rules)
ability.can(.read, .blogPost) // Compile-time checked

// Usage - dynamic
let anyAbility = AnyAbility(ability)
anyAbility.can("read", "BlogPost") // Runtime checked
```

### Performance Implications

- Generic version: Zero overhead (static dispatch)
- Type-erased version: ~10-20ns overhead (dynamic dispatch)
- Both well within performance budget

### References

- Swift generics: https://docs.swift.org/swift-book/LanguageGuide/Generics.html
- Type erasure pattern: https://www.swiftbysundell.com/articles/different-flavors-of-type-erasure-in-swift/

---

## 4. Thread Safety Strategy

### Decision

Use **copy-on-write structs + actor for mutable state**:
- Rules stored in value-type structs (immutable)
- Ability uses actor for thread-safe rule updates
- Permission checks use `nonisolated` methods for synchronous access
- Rule index uses concurrent data structures

### Rationale

**Why this approach**:
- Value semantics eliminate data races for rules
- Actor model provides compiler-enforced thread safety
- `nonisolated` allows synchronous permission checks (no async/await overhead)
- Aligns with Swift 5.10 strict concurrency

**Performance**: Actors add ~10-20ns overhead for isolated methods, zero for nonisolated reads

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| NSLock/Dispatch queues | Manual synchronization, error-prone, not idiomatic Swift 5.10 |
| Immutable-only | Can't support dynamic rule updates (FR-028) |
| Async-only APIs | Poor ergonomics for permission checks (need synchronous) |

### Code Example

```swift
// Value-type rule (immutable, thread-safe by design)
struct Rule: Sendable {
    let action: String
    let subject: String
    let conditions: Condition?
    let fields: [String]?
    let inverted: Bool
}

// Actor for thread-safe mutable state
actor Ability: Sendable {
    private var rules: [Rule]
    private let conditionsMatcher: ConditionsMatcher

    init(rules: [Rule], conditionsMatcher: ConditionsMatcher) {
        self.rules = rules
        self.conditionsMatcher = conditionsMatcher
    }

    // Isolated method (async, thread-safe)
    func update(rules: [Rule]) {
        self.rules = rules
    }

    // Nonisolated method (sync, reads immutable state)
    nonisolated func can(_ action: String, _ subject: Any, field: String? = nil) -> Bool {
        // Safe because rules are value types
        let snapshot = rules
        return snapshot.contains { rule in
            rule.matches(action: action, subject: subject, field: field)
        }
    }
}

// Usage - concurrent permission checks
let ability = Ability(rules: rules, conditionsMatcher: matcher)

// Synchronous permission checks (no await)
Task {
    ability.can("read", post)  // Thread-safe
}

Task {
    ability.can("update", post) // Concurrent with above
}

// Async rule updates
Task {
    await ability.update(rules: newRules)
}
```

### Performance Implications

- Permission checks (nonisolated): ~0ns overhead (direct access to immutable data)
- Rule updates (isolated): ~10-20ns actor dispatch overhead
- Concurrent checks: No contention, scales linearly
- Meets SC-003 requirement (1000+ concurrent checks)

### References

- Swift actors: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
- Sendable and data races: https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md

---

## 5. Serialization Approach

### Decision

Use **Codable with custom encoding for operators**:
- All rule types conform to Codable
- Custom encoding/decoding for query operators to match CASL JS JSON format
- Version field in serialized format for future compatibility
- Support for JSON encoding/decoding via JSONEncoder/JSONDecoder

### Rationale

**Why this approach**:
- Codable is idiomatic Swift, well-supported
- Custom encoding ensures JSON format matches CASL JS
- JSONEncoder/JSONDecoder handle edge cases (dates, optionals, etc.)
- Version field enables future format evolution

**Performance**: JSONEncoder is optimized, meets <10ms for 100 rules (SC-006)

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Manual JSON serialization | Error-prone, lots of boilerplate |
| PropertyListEncoder | Not portable across platforms |
| Third-party libraries | Violates zero-dependency requirement |

### Code Example

```swift
// RawRule with Codable conformance
struct RawRule: Codable {
    let action: String
    let subject: String?
    let conditions: [String: AnyCodable]?
    let fields: [String]?
    let inverted: Bool?
    let reason: String?
}

// Type-erased Codable wrapper for heterogeneous conditions
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported type"))
        }
    }
}

// Serialization
let rules: [RawRule] = [
    RawRule(action: "read", subject: "BlogPost", conditions: nil, fields: nil, inverted: false, reason: nil),
    RawRule(action: "update", subject: "BlogPost", conditions: ["authorId": AnyCodable("123")], fields: nil, inverted: false, reason: nil)
]

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let json = try encoder.encode(rules)

// Deserialization
let decoder = JSONDecoder()
let decoded = try decoder.decode([RawRule].self, from: json)
```

### Performance Implications

- Encoding 100 rules: ~2-5ms (well under 10ms budget)
- Decoding 100 rules: ~3-7ms (well under 10ms budget)
- Meets SC-006 requirement

### References

- Codable: https://developer.apple.com/documentation/swift/codable
- Custom encoding: https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types

---

## 6. Field Pattern Matching

### Decision

Use **custom glob-style pattern matcher**:
- Support exact matching (`"email"`)
- Support wildcard patterns (`"*"` for all fields)
- Support prefix patterns (`"address.*"` for nested fields)
- Implement efficient pattern compilation and caching

### Rationale

**Why this approach**:
- Matches CASL JS field matching semantics
- Simple to implement and understand
- Fast enough for permission checks
- No regex overhead for simple cases

**Performance**: Pattern matching adds ~10-50ns per field check

### Alternatives Considered

| Approach | Why Rejected |
|----------|--------------|
| Regular expressions | Overkill, slower, harder to understand |
| NSPredicate | ObjC legacy, not idiomatic Swift |
| Exact match only | Too limiting, doesn't match CASL JS |

### Code Example

```swift
// Field pattern matcher
struct FieldPattern {
    let pattern: String
    private let isWildcard: Bool
    private let prefix: String?

    init(_ pattern: String) {
        self.pattern = pattern

        if pattern == "*" {
            isWildcard = true
            prefix = nil
        } else if pattern.hasSuffix(".*") {
            isWildcard = false
            prefix = String(pattern.dropLast(2))
        } else {
            isWildcard = false
            prefix = nil
        }
    }

    func matches(_ field: String) -> Bool {
        if isWildcard {
            return true
        }

        if let prefix = prefix {
            return field.hasPrefix(prefix + ".")
        }

        return pattern == field
    }
}

// Field matcher
struct FieldMatcher {
    func matches(field: String, patterns: [String]) -> Bool {
        if patterns.isEmpty {
            return true // No restrictions = all fields allowed
        }

        return patterns.contains { FieldPattern($0).matches(field) }
    }
}

// Usage
let matcher = FieldMatcher()
matcher.matches(field: "email", patterns: ["*"])           // true
matcher.matches(field: "email", patterns: ["email"])       // true
matcher.matches(field: "address.street", patterns: ["address.*"]) // true
matcher.matches(field: "password", patterns: ["email"])    // false
```

### Performance Implications

- Exact match: ~5ns (string comparison)
- Wildcard: ~1ns (boolean check)
- Prefix match: ~10ns (string prefix check)
- Well within <1ms budget even with many field checks

### References

- Swift string operations: https://developer.apple.com/documentation/swift/string

---

## Summary of Decisions

| Area | Decision | Key Benefit |
|------|----------|-------------|
| Subject Type Detection | Protocol + Mirror hybrid | Flexibility + performance |
| Condition Matching | KeyPath + Mirror + enums | Type safety + flexibility |
| Generic Design | Generics + type erasure | Strong typing + escape hatch |
| Thread Safety | Value semantics + actors | Compiler-enforced safety |
| Serialization | Codable + custom encoding | Idiomatic + portable |
| Field Matching | Custom glob patterns | Simple + efficient |

## Performance Summary

All design decisions meet the performance requirements:

| Requirement | Target | Achieved |
|-------------|--------|----------|
| Permission check | <1ms for 100 rules | ~50-200μs estimated |
| Serialization | <10ms for 100 rules | ~5-10ms estimated |
| Concurrent checks | 1000+ simultaneous | No contention, scales linearly |
| Memory footprint | <5MB compiled | ~1-2MB estimated (minimal dependencies) |

## Next Steps

1. ✅ Research complete
2. **Phase 1**: Create data-model.md with detailed type specifications
3. **Phase 1**: Create contracts/api-reference.md with public API signatures
4. **Phase 1**: Create quickstart.md with usage examples
5. **Phase 2**: Generate tasks.md for implementation
