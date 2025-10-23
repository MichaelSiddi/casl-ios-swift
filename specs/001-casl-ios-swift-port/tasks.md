# Tasks: CASL Authorization Library for iOS Swift

**Input**: Design documents from `/specs/001-casl-ios-swift-port/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/api-reference.md

**Tests**: Following TDD approach - tests written before implementation for all public APIs

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

All paths are relative to repository root:
- Source files: `Sources/CASL/`
- Test files: `Tests/CASLTests/`
- Package manifest: `Package.swift`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create Swift Package Manager project structure with Package.swift manifest
- [x] T002 Create Sources/CASL/ directory structure per plan.md
- [x] T003 [P] Create Tests/CASLTests/ directory structure per plan.md
- [x] T004 [P] Add .gitignore for Swift/Xcode artifacts
- [x] T005 [P] Create README.md with project overview and installation instructions
- [x] T006 [P] Add MIT LICENSE file
- [x] T007 Configure Package.swift with Swift 5.10, iOS 13+ deployment targets, and test dependencies

**Checkpoint**: Project structure ready for core implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core types and protocols that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T008 Create Types.swift with core type aliases and protocols in Sources/CASL/Types.swift
- [x] T009 [P] Create AnyCodable type-erased Codable wrapper in Sources/CASL/Types.swift
- [x] T010 [P] Create StringOrArray enum for flexible action/subject specification in Sources/CASL/Types.swift
- [x] T011 Create SubjectTypeProvider protocol in Sources/CASL/Types.swift
- [x] T012 Implement defaultSubjectTypeDetector function using Mirror API in Sources/CASL/Utils/SubjectTypeDetector.swift
- [x] T013 Create QueryOperator enum with all comparison operators in Sources/CASL/Matchers/Operators.swift
- [x] T014 [P] Create ConditionsMatcher protocol in Sources/CASL/Matchers/ConditionsMatcher.swift
- [x] T015 [P] Create FieldMatcher protocol in Sources/CASL/Matchers/FieldMatcher.swift
- [x] T016 Create RawRule struct with Codable conformance in Sources/CASL/RawRule.swift
- [x] T017 Implement RawRule custom encoding/decoding for MongoDB-style conditions in Sources/CASL/RawRule.swift

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Define and Check Basic Permissions (Priority: P1) 🎯 MVP

**Goal**: Enable developers to create Ability instances with simple rules and check if actions are permitted

**Independent Test**: Create an Ability with basic can/cannot rules, call can() and cannot() methods, verify correct permission evaluation

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T018 [P] [US1] Write test for Ability initialization with empty rules in Tests/CASLTests/AbilityTests.swift
- [ ] T019 [P] [US1] Write test for Ability.can() returns true for allowed action in Tests/CASLTests/AbilityTests.swift
- [ ] T020 [P] [US1] Write test for Ability.can() returns false for forbidden action in Tests/CASLTests/AbilityTests.swift
- [ ] T021 [P] [US1] Write test for Ability.cannot() returns true for denied action in Tests/CASLTests/AbilityTests.swift
- [ ] T022 [P] [US1] Write test for default deny behavior (no rules) in Tests/CASLTests/AbilityTests.swift
- [ ] T023 [P] [US1] Write test for "manage" action wildcard matching in Tests/CASLTests/AbilityTests.swift
- [ ] T024 [P] [US1] Write test for "all" subject wildcard matching in Tests/CASLTests/AbilityTests.swift
- [ ] T025 [P] [US1] Write test for inverted rules (cannot) override in Tests/CASLTests/AbilityTests.swift

### Implementation for User Story 1

- [ ] T026 [US1] Create Rule struct with basic properties (action, subject, inverted) in Sources/CASL/Rule.swift
- [ ] T027 [US1] Implement Rule.matchesAction() with "manage" wildcard support in Sources/CASL/Rule.swift
- [ ] T028 [US1] Implement Rule.matchesSubjectType() with "all" wildcard support in Sources/CASL/Rule.swift
- [ ] T029 [US1] Create RuleIndex class for rule storage and lookup in Sources/CASL/RuleIndex.swift
- [ ] T030 [US1] Implement RuleIndex.rulesFor(action:subjectType:) method in Sources/CASL/RuleIndex.swift
- [ ] T031 [US1] Create Ability actor with rules storage in Sources/CASL/Ability.swift
- [ ] T032 [US1] Implement Ability initializer accepting RawRule array in Sources/CASL/Ability.swift
- [ ] T033 [US1] Implement nonisolated Ability.can(_:_:field:) method in Sources/CASL/Ability.swift
- [ ] T034 [US1] Implement nonisolated Ability.cannot(_:_:field:) method in Sources/CASL/Ability.swift
- [ ] T035 [US1] Implement nonisolated Ability.relevantRuleFor(_:_:field:) method in Sources/CASL/Ability.swift
- [ ] T036 [US1] Run User Story 1 tests and verify all pass

**Checkpoint**: User Story 1 complete - Basic permission checking works ✅

---

## Phase 4: User Story 2 - Use Conditions to Restrict Permissions (Priority: P1)

**Goal**: Enable attribute-based access control with conditional rules that match object properties

**Independent Test**: Define rules with conditions (e.g., authorId equals current user), check permissions on objects with matching/non-matching attributes

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T037 [P] [US2] Write test for condition matching with simple equality in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T038 [P] [US2] Write test for condition matching with greater than operator in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T039 [P] [US2] Write test for condition matching with less than operator in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T040 [P] [US2] Write test for condition matching with $in operator in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T041 [P] [US2] Write test for condition matching with $nin operator in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T042 [P] [US2] Write test for condition matching with $exists operator in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T043 [P] [US2] Write test for compound conditions with $and in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T044 [P] [US2] Write test for compound conditions with $or in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T045 [P] [US2] Write test for negated conditions with $not in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T046 [P] [US2] Write test for permission denied when conditions don't match in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T047 [P] [US2] Write test for permission granted when conditions match in Tests/CASLTests/ConditionMatchingTests.swift
- [ ] T048 [P] [US2] Write test for time-based conditions in Tests/CASLTests/ConditionMatchingTests.swift

### Implementation for User Story 2

- [ ] T049 [P] [US2] Create QueryMatcher implementing ConditionsMatcher protocol in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T050 [US2] Implement QueryMatcher.compile() method for conditions in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T051 [US2] Implement QueryMatcher equality operator ($eq) evaluation in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T052 [P] [US2] Implement QueryMatcher not-equal operator ($ne) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T053 [P] [US2] Implement QueryMatcher greater-than operator ($gt) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T054 [P] [US2] Implement QueryMatcher less-than operator ($lt) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T055 [P] [US2] Implement QueryMatcher in-array operator ($in) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T056 [P] [US2] Implement QueryMatcher not-in-array operator ($nin) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T057 [P] [US2] Implement QueryMatcher exists operator ($exists) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T058 [US2] Implement QueryMatcher logical AND operator ($and) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T059 [P] [US2] Implement QueryMatcher logical OR operator ($or) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T060 [P] [US2] Implement QueryMatcher logical NOT operator ($not) in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T061 [US2] Implement property value extraction using Mirror API in Sources/CASL/Matchers/QueryMatcher.swift
- [ ] T062 [US2] Add conditions property to Rule struct in Sources/CASL/Rule.swift
- [ ] T063 [US2] Implement Rule.matchesConditions(_:) using ConditionsMatcher in Sources/CASL/Rule.swift
- [ ] T064 [US2] Update RawRule to include conditions field in Sources/CASL/RawRule.swift
- [ ] T065 [US2] Update Ability to use QueryMatcher by default in Sources/CASL/Ability.swift
- [ ] T066 [US2] Update Ability.can() to evaluate conditions when checking instances in Sources/CASL/Ability.swift
- [ ] T067 [US2] Run User Story 2 tests and verify all pass

**Checkpoint**: User Story 2 complete - Conditional permissions work ✅

---

## Phase 5: User Story 3 - Build Permissions with Fluent API (Priority: P2)

**Goal**: Provide fluent AbilityBuilder API for readable, chainable rule definition

**Independent Test**: Use AbilityBuilder to define multiple can/cannot rules with chaining, build Ability, verify all rules are registered

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T068 [P] [US3] Write test for AbilityBuilder basic can() rule in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T069 [P] [US3] Write test for AbilityBuilder cannot() rule in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T070 [P] [US3] Write test for AbilityBuilder method chaining in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T071 [P] [US3] Write test for AbilityBuilder with conditions in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T072 [P] [US3] Write test for AbilityBuilder with field restrictions in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T073 [P] [US3] Write test for AbilityBuilder with array actions in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T074 [P] [US3] Write test for AbilityBuilder with array subjects in Tests/CASLTests/AbilityBuilderTests.swift
- [ ] T075 [P] [US3] Write test for AbilityBuilder.build() creates working Ability in Tests/CASLTests/AbilityBuilderTests.swift

### Implementation for User Story 3

- [ ] T076 [US3] Create AbilityBuilder class in Sources/CASL/AbilityBuilder.swift
- [ ] T077 [US3] Implement AbilityBuilder.can(_:_:conditions:fields:) method in Sources/CASL/AbilityBuilder.swift
- [ ] T078 [US3] Implement AbilityBuilder.cannot(_:_:conditions:fields:) method in Sources/CASL/AbilityBuilder.swift
- [ ] T079 [US3] Implement AbilityBuilder.can() overload for array actions in Sources/CASL/AbilityBuilder.swift
- [ ] T080 [US3] Implement AbilityBuilder.can() overload for array subjects in Sources/CASL/AbilityBuilder.swift
- [ ] T081 [US3] Implement AbilityBuilder.cannot() overload for arrays in Sources/CASL/AbilityBuilder.swift
- [ ] T082 [US3] Implement AbilityBuilder.build() returning Ability instance in Sources/CASL/AbilityBuilder.swift
- [ ] T083 [US3] Add AbilityOptions struct for Ability configuration in Sources/CASL/Ability.swift
- [ ] T084 [US3] Update Ability initializer to accept AbilityOptions in Sources/CASL/Ability.swift
- [ ] T085 [US3] Run User Story 3 tests and verify all pass

**Checkpoint**: User Story 3 complete - Fluent builder API works ✅

---

## Phase 6: User Story 4 - Control Field-Level Permissions (Priority: P2)

**Goal**: Enable fine-grained permissions restricted to specific fields of resources

**Independent Test**: Define rules with field restrictions, check permissions for allowed and restricted fields, verify correct field-level access control

### Tests for User Story 4

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T086 [P] [US4] Write test for field-level permissions with exact match in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T087 [P] [US4] Write test for field-level permissions with wildcard "*" in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T088 [P] [US4] Write test for field-level permissions with prefix pattern in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T089 [P] [US4] Write test for permission denied on restricted field in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T090 [P] [US4] Write test for permission granted on allowed field in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T091 [P] [US4] Write test for no field restrictions means all fields allowed in Tests/CASLTests/FieldMatchingTests.swift
- [ ] T092 [P] [US4] Write test for multiple field patterns in Tests/CASLTests/FieldMatchingTests.swift

### Implementation for User Story 4

- [ ] T093 [P] [US4] Create FieldPattern struct for pattern parsing in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T094 [US4] Implement FieldPattern.matches(_:) for exact matching in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T095 [US4] Implement FieldPattern wildcard "*" matching in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T096 [US4] Implement FieldPattern prefix ".*" matching in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T097 [US4] Create GlobFieldMatcher implementing FieldMatcher protocol in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T098 [US4] Implement GlobFieldMatcher.matches(field:patterns:) in Sources/CASL/Matchers/FieldMatcher.swift
- [ ] T099 [US4] Add fields property to Rule struct in Sources/CASL/Rule.swift
- [ ] T100 [US4] Implement Rule.matchesField(_:fieldMatcher:) in Sources/CASL/Rule.swift
- [ ] T101 [US4] Update RawRule to include fields in Sources/CASL/RawRule.swift
- [ ] T102 [US4] Update Ability to use GlobFieldMatcher by default in Sources/CASL/Ability.swift
- [ ] T103 [US4] Update Ability.can() to evaluate field parameter in Sources/CASL/Ability.swift
- [ ] T104 [US4] Run User Story 4 tests and verify all pass

**Checkpoint**: User Story 4 complete - Field-level permissions work ✅

---

## Phase 7: User Story 5 - Handle Multiple Subject Types (Priority: P2)

**Goal**: Support Swift class types, struct types, and string identifiers as subjects

**Independent Test**: Define rules using Swift types and strings, check permissions using type references and instances, verify correct subject type detection

### Tests for User Story 5

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T105 [P] [US5] Write test for subject type detection from class instance in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T106 [P] [US5] Write test for subject type detection from struct instance in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T107 [P] [US5] Write test for SubjectTypeProvider protocol usage in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T108 [P] [US5] Write test for permission check using class type in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T109 [P] [US5] Write test for permission check using string subject in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T110 [P] [US5] Write test for permission check using instance in Tests/CASLTests/SubjectTypeTests.swift
- [ ] T111 [P] [US5] Write test for custom subject type name in Tests/CASLTests/SubjectTypeTests.swift

### Implementation for User Story 5

- [ ] T112 [US5] Enhance defaultSubjectTypeDetector to check SubjectTypeProvider first in Sources/CASL/Utils/SubjectTypeDetector.swift
- [ ] T113 [US5] Implement Mirror-based type name extraction in Sources/CASL/Utils/SubjectTypeDetector.swift
- [ ] T114 [US5] Add type name caching for performance in Sources/CASL/Utils/SubjectTypeDetector.swift
- [ ] T115 [US5] Update Ability.can() to handle both type and instance subjects in Sources/CASL/Ability.swift
- [ ] T116 [US5] Update Ability to support custom detectSubjectType function in Sources/CASL/Ability.swift
- [ ] T117 [US5] Run User Story 5 tests and verify all pass

**Checkpoint**: User Story 5 complete - Multiple subject types supported ✅

---

## Phase 8: User Story 6 - Manage Dynamic Permissions (Priority: P3)

**Goal**: Enable runtime rule updates for changing user roles and contexts

**Independent Test**: Create Ability, update rules dynamically, verify permission checks reflect new rules

### Tests for User Story 6

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T118 [P] [US6] Write test for Ability.update() changes rules in Tests/CASLTests/DynamicRulesTests.swift
- [ ] T119 [P] [US6] Write test for permission check after rule update in Tests/CASLTests/DynamicRulesTests.swift
- [ ] T120 [P] [US6] Write test for multiple sequential rule updates in Tests/CASLTests/DynamicRulesTests.swift
- [ ] T121 [P] [US6] Write test for thread safety of rule updates in Tests/CASLTests/ThreadSafetyTests.swift

### Implementation for User Story 6

- [ ] T122 [US6] Implement Ability.update(rules:) isolated method in Sources/CASL/Ability.swift
- [ ] T123 [US6] Ensure rule updates are serialized by actor in Sources/CASL/Ability.swift
- [ ] T124 [US6] Implement Ability.exportRules() for getting current rules in Sources/CASL/Ability.swift
- [ ] T125 [US6] Add thread safety tests for concurrent reads during updates in Tests/CASLTests/ThreadSafetyTests.swift
- [ ] T126 [US6] Run User Story 6 tests and verify all pass

**Checkpoint**: User Story 6 complete - Dynamic rule updates work ✅

---

## Phase 9: User Story 7 - Serialize and Deserialize Rules (Priority: P3)

**Goal**: Enable JSON serialization/deserialization for isomorphic authorization

**Independent Test**: Create Ability with complex rules, serialize to JSON, deserialize back, verify reconstructed Ability behaves identically

### Tests for User Story 7

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T127 [P] [US7] Write test for RawRule JSON encoding in Tests/CASLTests/SerializationTests.swift
- [ ] T128 [P] [US7] Write test for RawRule JSON decoding in Tests/CASLTests/SerializationTests.swift
- [ ] T129 [P] [US7] Write test for round-trip serialization (encode→decode) in Tests/CASLTests/SerializationTests.swift
- [ ] T130 [P] [US7] Write test for serializing complex conditions in Tests/CASLTests/SerializationTests.swift
- [ ] T131 [P] [US7] Write test for deserializing rules from server JSON in Tests/CASLTests/SerializationTests.swift
- [ ] T132 [P] [US7] Write test for malformed JSON error handling in Tests/CASLTests/SerializationTests.swift

### Implementation for User Story 7

- [ ] T133 [US7] Ensure AnyCodable handles all required types (Int, String, Bool, Double, Array, Dict) in Sources/CASL/Types.swift
- [ ] T134 [US7] Implement AnyCodable.encode(to:) for JSON encoding in Sources/CASL/Types.swift
- [ ] T135 [US7] Implement AnyCodable.init(from:) for JSON decoding in Sources/CASL/Types.swift
- [ ] T136 [US7] Implement RawRule.encode(to:) with proper key mapping in Sources/CASL/RawRule.swift
- [ ] T137 [US7] Implement RawRule.init(from:) with error handling in Sources/CASL/RawRule.swift
- [ ] T138 [US7] Implement StringOrArray Codable conformance in Sources/CASL/Types.swift
- [ ] T139 [US7] Test JSON compatibility with CASL JavaScript format in Tests/CASLTests/SerializationTests.swift
- [ ] T140 [US7] Run User Story 7 tests and verify all pass

**Checkpoint**: User Story 7 complete - Serialization works ✅

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Error handling, utilities, performance, and final integration

- [ ] T141 [P] Create ForbiddenError struct with LocalizedError conformance in Sources/CASL/ForbiddenError.swift
- [ ] T142 [P] Implement ForbiddenError.throwUnlessCan() helper in Sources/CASL/ForbiddenError.swift
- [ ] T143 [P] Write tests for ForbiddenError in Tests/CASLTests/ErrorTests.swift
- [ ] T144 [P] Create AliasResolver struct for action aliases in Sources/CASL/Utils/AliasResolver.swift
- [ ] T145 [P] Implement standard CRUD aliases ("manage" → all actions) in Sources/CASL/Utils/AliasResolver.swift
- [ ] T146 [P] Write tests for AliasResolver in Tests/CASLTests/AliasTests.swift
- [ ] T147 [P] Create Extra/PermittedFields.swift helper for allowed field extraction in Sources/CASL/Extra/PermittedFields.swift
- [ ] T148 [P] Create Extra/RulesToQuery.swift for database query conversion in Sources/CASL/Extra/RulesToQuery.swift
- [ ] T149 [P] Create Extra/PackRules.swift for rule optimization in Sources/CASL/Extra/PackRules.swift
- [ ] T150 [P] Write tests for Extra utilities in Tests/CASLTests/ExtraTests.swift
- [ ] T151 Write comprehensive integration tests covering all user stories in Tests/CASLTests/IntegrationTests.swift
- [ ] T152 Write performance tests for <1ms permission checks in Tests/CASLTests/PerformanceTests.swift
- [ ] T153 Write performance tests for <10ms serialization in Tests/CASLTests/PerformanceTests.swift
- [ ] T154 Write concurrency tests for 1000+ simultaneous checks in Tests/CASLTests/ThreadSafetyTests.swift
- [ ] T155 Add DocC documentation comments to all public APIs in Sources/CASL/
- [ ] T156 Create usage examples in README.md
- [ ] T157 Verify Package.swift exports all public types correctly
- [ ] T158 Run full test suite and ensure 100% pass rate
- [ ] T159 Run swift build with strict concurrency checking enabled
- [ ] T160 Verify zero compiler warnings

**Checkpoint**: Library complete and production-ready ✅

---

## Dependencies & Execution Order

### Story Completion Order (Based on Priorities)

```
Phase 1: Setup → Phase 2: Foundational
                         ↓
                   ┌─────┴─────┐
                   ↓           ↓
            US1 (P1)      US2 (P1)
              ↓              ↓
              └──────┬───────┘
                     ↓
                 US3 (P2) ─────┐
                     ↓          ↓
                 US4 (P2)   US5 (P2)
                     ↓          ↓
                     └────┬─────┘
                          ↓
                      US6 (P3)
                          ↓
                      US7 (P3)
                          ↓
                    Phase 10: Polish
```

### Story Independence Analysis

- **US1** (P1): Independent - Can be implemented after foundational
- **US2** (P1): Depends on US1 (extends Rule with conditions)
- **US3** (P2): Depends on US1, US2 (builder for existing functionality)
- **US4** (P2): Depends on US1 (adds field restrictions to rules)
- **US5** (P2): Independent of other P2 stories, depends on foundational
- **US6** (P3): Depends on US1 (adds update capability)
- **US7** (P3): Depends on US1, US2 (serializes all rule features)

### Parallel Execution Opportunities

#### After Foundational Phase:
- US1 and US2 can be developed in parallel by different developers (US2 waits for US1 before integration)

#### After US1, US2, US3:
- US4 and US5 can be developed in parallel (different parts of Rule system)

#### Within Each Story:
- All tests marked [P] can be written in parallel
- Implementation tasks marked [P] can be executed concurrently

#### Examples:

**Story 1 Parallel Tasks**:
```
T018-T025 (all tests) → can write simultaneously
T027 + T028 (Rule matching methods) → independent implementations
```

**Story 2 Parallel Tasks**:
```
T037-T048 (all tests) → can write simultaneously
T052-T057, T059-T060 (operator implementations) → independent
```

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**Recommended MVP**: User Story 1 + User Story 2 only

**Rationale**:
- US1 provides basic permission checking (core value)
- US2 adds conditional rules (differentiates from simple ACL)
- Together they deliver a working authorization system
- ~67 tasks, estimated 2-3 weeks for one developer

**MVP Deliverable**:
```swift
let ability = Ability(rules: [
    RawRule(action: "read", subject: "BlogPost"),
    RawRule(action: "update", subject: "BlogPost",
            conditions: ["authorId": userId])
])

if ability.can("read", post) { /* granted */ }
if ability.can("update", post) { /* check ownership */ }
```

### Incremental Delivery Plan

1. **Sprint 1** (MVP): US1 + US2 → Basic + conditional permissions
2. **Sprint 2**: US3 + US4 → Builder API + field-level permissions
3. **Sprint 3**: US5 → Type safety enhancements
4. **Sprint 4**: US6 + US7 → Dynamic updates + serialization
5. **Sprint 5**: Phase 10 → Polish and performance optimization

### Testing Strategy

**Test-First Approach** (per constitution):
1. Write tests for user story acceptance scenarios
2. Ensure tests FAIL
3. Implement features
4. Verify tests PASS
5. Refactor if needed

**Coverage Targets**:
- Unit tests: 95%+ code coverage
- Integration tests: All user story scenarios
- Performance tests: Meet <1ms and <10ms goals
- Thread safety: 1000+ concurrent operations

---

## Task Summary

**Total Tasks**: 160

**Tasks by Phase**:
- Phase 1 (Setup): 7 tasks
- Phase 2 (Foundational): 10 tasks
- Phase 3 (US1): 19 tasks (8 tests + 11 implementation)
- Phase 4 (US2): 31 tasks (12 tests + 19 implementation)
- Phase 5 (US3): 18 tasks (8 tests + 10 implementation)
- Phase 6 (US4): 19 tasks (7 tests + 12 implementation)
- Phase 7 (US5): 13 tasks (7 tests + 6 implementation)
- Phase 8 (US6): 9 tasks (4 tests + 5 implementation)
- Phase 9 (US7): 14 tasks (6 tests + 8 implementation)
- Phase 10 (Polish): 20 tasks

**Parallel Opportunities**: 89 tasks marked [P] (56% parallelizable)

**MVP Task Count**: 67 tasks (Phases 1-2 + US1 + US2)

**Estimated Effort**:
- MVP: 2-3 weeks (1 developer)
- Full implementation: 6-8 weeks (1 developer)
- With parallelization: 4-5 weeks (2 developers)

---

## Validation Checklist

✅ All tasks follow `- [ ] [ID] [P?] [Story?] Description with file path` format
✅ Tasks organized by user story for independent implementation
✅ Each user story has independent test criteria
✅ Test tasks written before implementation tasks (TDD)
✅ Dependencies clearly documented
✅ Parallel execution opportunities identified
✅ MVP scope defined (US1 + US2)
✅ File paths included in every task description
✅ Task IDs sequential (T001-T160)
✅ Story labels properly assigned ([US1]-[US7])

**Ready for implementation**: YES ✅
