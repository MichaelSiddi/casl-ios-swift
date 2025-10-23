# Implementation Plan: CASL Authorization Library for iOS Swift

**Branch**: `001-casl-ios-swift-port` | **Date**: 2025-10-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-casl-ios-swift-port/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Port the CASL JavaScript authorization library to iOS Swift 5.10, providing iOS developers with an isomorphic, type-safe permission management system. The library will enable declarative authorization rules, attribute-based access control, field-level permissions, and rule serialization for consistent authorization across application layers.

## Technical Context

**Language/Version**: Swift 5.10
**Primary Dependencies**: Foundation framework (JSON serialization), Swift Standard Library
**Storage**: N/A (pure logic library, no persistence layer)
**Testing**: XCTest with Swift Testing framework (iOS 13+)
**Target Platform**: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+
**Project Type**: Single library package (Swift Package Manager)
**Performance Goals**: <1ms permission checks for rule sets under 100 rules, <10ms serialization for 100 rules
**Constraints**:
- Zero third-party dependencies for core library
- Thread-safe for concurrent permission checks
- <5MB compiled binary size
- Must compile with strict concurrency checking enabled
**Scale/Scope**:
- Support rule sets up to 1000 rules
- Handle 1000+ concurrent permission checks
- API surface ~15-20 public types/protocols

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: Constitution file is a template and not yet populated with project-specific principles. Proceeding with standard library development best practices:

**Assumed Principles**:
1. **Library-First**: Core CASL authorization logic is self-contained, independently testable, with no UI or data layer dependencies
2. **Test-First**: Following TDD - tests will be written before implementation for all public APIs
3. **Zero Dependencies**: Core library uses only Swift stdlib and Foundation to maximize portability
4. **Type Safety**: Leverage Swift's type system for compile-time safety where possible
5. **Performance**: Sub-millisecond permission checks for typical rule sets

**Gates**:
- ✅ Library is self-contained (no external dependencies)
- ✅ Clear purpose (authorization/permission management)
- ✅ Independently testable (pure logic, no side effects)
- ✅ Test-first approach will be followed
- ✅ Simple architecture (no unnecessary abstractions)

**Re-evaluation after Phase 1**: Will verify data model and contracts align with test-first principles.

## Project Structure

### Documentation (this feature)

```text
specs/001-casl-ios-swift-port/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── api-reference.md # Public API signatures
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Sources/
└── CASL/
    ├── Ability.swift              # Main Ability class
    ├── PureAbility.swift          # Base ability implementation
    ├── AbilityBuilder.swift       # Fluent builder API
    ├── Rule.swift                 # Rule matching logic
    ├── RawRule.swift              # Serializable rule representation
    ├── RuleIndex.swift            # Rule storage and indexing
    ├── ForbiddenError.swift       # Authorization error type
    ├── Types.swift                # Core type definitions
    ├── Matchers/
    │   ├── ConditionsMatcher.swift    # Condition evaluation
    │   ├── QueryMatcher.swift         # MongoDB-style query syntax
    │   ├── FieldMatcher.swift         # Field pattern matching
    │   └── Operators.swift            # Comparison operators
    ├── Utils/
    │   ├── SubjectTypeDetector.swift  # Subject type extraction
    │   ├── AliasResolver.swift        # Action alias resolution
    │   └── ArrayHelpers.swift         # Array utilities
    └── Extra/
        ├── PackRules.swift            # Rule optimization
        ├── PermittedFields.swift      # Field permission helpers
        └── RulesToQuery.swift         # Query conversion utilities

Tests/
└── CASLTests/
    ├── AbilityTests.swift
    ├── AbilityBuilderTests.swift
    ├── RuleMatchingTests.swift
    ├── ConditionMatchingTests.swift
    ├── FieldMatchingTests.swift
    ├── SerializationTests.swift
    ├── ThreadSafetyTests.swift
    ├── PerformanceTests.swift
    └── IntegrationTests.swift

Package.swift                      # Swift Package Manager manifest
README.md                          # Library documentation
LICENSE                            # MIT License
.gitignore                         # Git ignore rules
```

**Structure Decision**: Single library project structure chosen because this is a standalone Swift package with no UI, networking, or data persistence. All authorization logic is contained in one coherent module. Tests are co-located following Swift Package Manager conventions.

## Complexity Tracking

No constitution violations at this stage. The library follows standard practices for Swift package development with minimal complexity.

## Phase 0: Research & Design Decisions

### Research Questions

The following areas require research to make informed design decisions:

1. **Subject Type Detection Strategy**
   - How to extract type information from Swift instances (Mirror API vs protocols)?
   - Support for classes, structs, enums with minimal boilerplate?
   - Custom type name resolution for serialization?

2. **Condition Matching Implementation**
   - How to implement MongoDB-style query operators in Swift?
   - Property access patterns (Mirror, KeyPath, Codable)?
   - Performance characteristics of different approaches?

3. **Generic Type Design**
   - How to achieve TypeScript-like generic flexibility in Swift?
   - Trade-offs between type safety and API ergonomics?
   - Use of associated types vs generic parameters?

4. **Thread Safety Strategy**
   - Copy-on-write semantics for rule updates?
   - Concurrent read access patterns?
   - Performance impact of thread-safe collections?

5. **Serialization Approach**
   - Codable conformance for all types?
   - Custom JSON encoding for complex conditions?
   - Version compatibility strategy?

6. **Field Pattern Matching**
   - Wildcard pattern syntax (glob-style)?
   - Nested field notation (dot notation)?
   - Regular expression support?

### Research Output

Research findings will be documented in `research.md` with:
- Decision made for each question
- Rationale based on Swift best practices and CASL JavaScript reference
- Alternatives considered and why rejected
- Code examples demonstrating the approach
- Performance implications

## Phase 1: Design Artifacts

### Data Model

The data model will define the core entities:

1. **Ability** - Rule container and permission evaluator
2. **Rule** - Single authorization rule with matching logic
3. **RawRule** - Serializable rule representation
4. **AbilityBuilder** - Fluent API for rule definition
5. **Subject types** - Protocols for type detection
6. **Condition types** - Query operator representations
7. **Matchers** - Pluggable matching strategies

Details will be in `data-model.md` with:
- Type signatures
- Property specifications
- Relationships between entities
- State transitions (rule matching flow)
- Validation rules

### API Contracts

Public API surface will be documented in `contracts/api-reference.md`:

1. **Ability API**
   - `init(rules:options:)` constructor
   - `can(action:subject:field:)` permission check
   - `cannot(action:subject:field:)` permission denial check
   - `relevantRuleFor(action:subject:field:)` rule lookup
   - `update(rules:)` dynamic rule updates

2. **AbilityBuilder API**
   - `can(action:subject:conditions:)` add allowed rule
   - `cannot(action:subject:conditions:)` add denied rule
   - `build(options:)` construct Ability

3. **Rule API**
   - Properties: action, subject, conditions, fields, inverted, reason
   - `matches(action:subject:field:)` matching logic

4. **RawRule Codable conformance**
   - JSON encoding/decoding specifications

5. **ForbiddenError**
   - Error properties and throwUnlessCan helper

6. **Matcher protocols**
   - ConditionsMatcher, FieldMatcher interfaces

### Quickstart Guide

The `quickstart.md` will provide:
- 5-minute getting started tutorial
- Basic permission checking example
- Conditional permissions example
- Builder API example
- Serialization example
- Integration patterns

## Phase 2: Implementation Tasks

*Generated by `/speckit.tasks` command - not part of this plan*

Tasks will be organized into phases:
1. Core types and protocols
2. Rule matching engine
3. Condition matcher implementation
4. Builder API
5. Serialization support
6. Helper utilities
7. Comprehensive testing
8. Documentation and examples

## Architecture Decisions

### 1. Protocol-Oriented Subject Type System

**Decision**: Use a combination of protocols and Swift's Mirror API for subject type detection.

**Rationale**:
- Protocols provide compile-time safety for types that opt-in
- Mirror API enables dynamic inspection for types without protocol conformance
- Matches CASL's flexibility while leveraging Swift's strengths

**Trade-off**: Some runtime overhead for Mirror-based detection, but acceptable given <1ms performance target.

### 2. Value Semantics for Rules

**Decision**: Use structs for Rule and RawRule with copy-on-write semantics.

**Rationale**:
- Immutability simplifies thread safety
- Value semantics align with Swift best practices
- Easier to reason about rule updates
- Supports efficient serialization

### 3. Matcher Strategy Pattern

**Decision**: Use protocols for ConditionsMatcher and FieldMatcher with default implementations.

**Rationale**:
- Pluggable matching strategies (as in CASL JS)
- Developers can provide custom matchers
- Testability through dependency injection
- Separation of concerns

### 4. Query Syntax via Operator Enums

**Decision**: Model MongoDB-style operators as Swift enums with associated values.

**Rationale**:
- Type-safe representation of query operators
- Exhaustive switching for operator evaluation
- Codable conformance for serialization
- Clear error messages for unsupported operators

### 5. KeyPath-Based Property Access

**Decision**: Use a hybrid approach - KeyPath for known types, Mirror for dynamic inspection.

**Rationale**:
- KeyPath provides compile-time safety when possible
- Mirror enables inspection of any type
- Matches CASL's flexibility
- Performance optimized for common case (KeyPath)

### 6. Thread Safety via Actor Model

**Decision**: Use Swift actors for Ability instances that require thread-safe updates, expose synchronous APIs via nonisolated methods for permission checks.

**Rationale**:
- Native Swift concurrency support
- Minimal performance overhead for read-heavy workloads
- Compiler-enforced thread safety
- Aligns with Swift 5.10 strict concurrency

**Alternative Considered**: NSLock-based locking, rejected for being more error-prone and less idiomatic.

## Risk Analysis

### High Risk
- **Performance of condition matching**: MongoDB-style queries on Swift objects using Mirror could be slow
  - Mitigation: Optimize hot paths, provide KeyPath-based fast path, benchmark early

### Medium Risk
- **Generic type complexity**: Matching TypeScript's generic flexibility may result in complex type signatures
  - Mitigation: Provide type aliases and builder APIs for common cases

- **Swift version compatibility**: Swift 5.10 is recent, may have concurrency bugs
  - Mitigation: Test on multiple Xcode versions, provide fallback implementations

### Low Risk
- **Serialization format compatibility**: JSON format must match CASL JS
  - Mitigation: Direct port of JSON schema, cross-validation with JS test cases

## Testing Strategy

### Unit Tests
- Every public API method
- All query operators
- Field pattern matching
- Rule precedence logic
- Error handling

### Integration Tests
- Complete permission scenarios from spec
- Builder API workflows
- Serialization round-trips
- Cross-platform compatibility (iOS, macOS, tvOS, watchOS)

### Performance Tests
- Permission check latency (<1ms for 100 rules)
- Serialization speed (<10ms for 100 rules)
- Concurrent access (1000+ simultaneous checks)
- Memory footprint (<5MB compiled)

### Compatibility Tests
- Port JavaScript test suite to Swift
- Verify identical behavior for equivalent scenarios
- Target 95%+ test equivalence

## Documentation Plan

### API Documentation
- DocC documentation for all public types
- Code examples for every major feature
- Migration guide from CASL JS concepts

### Guides
- Getting Started (quickstart.md)
- Advanced Usage (custom matchers, optimization)
- Architecture Overview (for contributors)
- API Reference (generated from DocC)

### Examples
- Basic RBAC example
- ABAC with ownership
- Field-level permissions
- Rule serialization
- SwiftUI integration pattern
- Combine publisher pattern

## Success Metrics

From spec, tracking:
- SC-002: <1ms permission checks (automated performance tests)
- SC-003: 1000+ concurrent checks (load tests)
- SC-006: <10ms serialization (automated performance tests)
- SC-008: Zero compiler warnings with strict concurrency (CI checks)
- SC-010: 95%+ test coverage of JS test suite (test harness)

## Next Steps

1. ✅ Complete this plan document
2. **Phase 0**: Generate research.md with detailed design decisions
3. **Phase 1**: Create data-model.md with type specifications
4. **Phase 1**: Create contracts/api-reference.md with public API
5. **Phase 1**: Create quickstart.md with usage examples
6. **Phase 1**: Update agent context with Swift + CASL technologies
7. **Phase 2**: Run `/speckit.tasks` to generate implementation task list
