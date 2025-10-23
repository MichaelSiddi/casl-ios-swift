# Feature Specification: CASL Authorization Library for iOS Swift

**Feature Branch**: `001-casl-ios-swift-port`
**Created**: 2025-10-22
**Status**: Draft
**Input**: User description: "Create a version of CASL authorization library for iOS Swift 5.10, porting the core JavaScript library functionality"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Define and Check Basic Permissions (Priority: P1)

As an iOS developer, I want to define authorization rules for my application and check if users have permission to perform actions on resources, so I can control access to features and data in my app.

**Why this priority**: This is the core value proposition of CASL - the ability to define and check permissions. Without this, the library has no purpose.

**Independent Test**: Can be fully tested by creating an Ability instance with rules, then calling can/cannot methods to verify permissions, delivering a working authorization system.

**Acceptance Scenarios**:

1. **Given** a user with defined permissions, **When** I check if they can perform an allowed action, **Then** the check returns true
2. **Given** a user with defined permissions, **When** I check if they can perform a forbidden action, **Then** the check returns false
3. **Given** no specific rules defined, **When** I check any permission, **Then** the default deny behavior is applied
4. **Given** multiple rules for the same resource, **When** I check permission, **Then** the most specific matching rule applies

---

### User Story 2 - Use Conditions to Restrict Permissions (Priority: P1)

As an iOS developer, I want to define conditional permissions based on resource attributes (like ownership), so users can only access their own data while being restricted from others' data.

**Why this priority**: Attribute-based access control is fundamental to CASL's power and differentiates it from simple role-based systems. This enables real-world authorization scenarios.

**Independent Test**: Can be fully tested by defining rules with conditions (e.g., "can update BlogPost where authorId equals userId"), then checking permissions against objects with different attribute values.

**Acceptance Scenarios**:

1. **Given** a rule allowing users to manage their own posts, **When** I check permission for a post they own, **Then** permission is granted
2. **Given** a rule allowing users to manage their own posts, **When** I check permission for a post owned by another user, **Then** permission is denied
3. **Given** a rule with multiple conditions, **When** all conditions match, **Then** permission is granted
4. **Given** a rule with time-based conditions, **When** the time condition is no longer valid, **Then** permission is denied

---

### User Story 3 - Build Permissions with Fluent API (Priority: P2)

As an iOS developer, I want to use a fluent builder pattern to define complex permission sets, so I can write clean, readable authorization code that matches my business logic.

**Why this priority**: Developer experience is critical for library adoption. A clean API makes the library easier to use and less error-prone.

**Independent Test**: Can be fully tested by using the AbilityBuilder to create rules with various combinations of actions, subjects, conditions, and fields, then verifying the built Ability behaves correctly.

**Acceptance Scenarios**:

1. **Given** I use the AbilityBuilder, **When** I define multiple can/cannot rules, **Then** all rules are properly registered
2. **Given** I chain multiple rule definitions, **When** I build the Ability, **Then** the resulting instance contains all defined rules
3. **Given** I define inverted rules with cannot, **When** I check permissions, **Then** the restrictions are properly enforced
4. **Given** I define rules with the same action but different subjects, **When** I check permissions, **Then** each subject is evaluated independently

---

### User Story 4 - Control Field-Level Permissions (Priority: P2)

As an iOS developer, I want to restrict permissions to specific fields of a resource, so users can view certain properties but not modify sensitive fields.

**Why this priority**: Field-level permissions enable fine-grained authorization, essential for many business requirements where different user roles need different access levels to the same resource.

**Independent Test**: Can be fully tested by defining rules that specify field restrictions, then checking permissions for different fields on the same resource.

**Acceptance Scenarios**:

1. **Given** a rule allowing read access to specific fields, **When** I check permission for an allowed field, **Then** permission is granted
2. **Given** a rule allowing read access to specific fields, **When** I check permission for a restricted field, **Then** permission is denied
3. **Given** multiple rules with different field restrictions, **When** I check permission, **Then** the most permissive matching rule applies
4. **Given** a rule without field restrictions, **When** I check field permission, **Then** all fields are accessible

---

### User Story 5 - Handle Multiple Subject Types (Priority: P2)

As an iOS developer, I want to define permissions for different resource types using Swift types (classes, structs, enums), so I can leverage Swift's type system for compile-time safety.

**Why this priority**: Type safety is a core strength of Swift. Supporting native Swift types makes the library feel natural to iOS developers and catches errors at compile time.

**Independent Test**: Can be fully tested by defining rules using Swift type references, then checking permissions using both type references and instances of those types.

**Acceptance Scenarios**:

1. **Given** rules defined using Swift class types, **When** I check permission using the class type, **Then** the rule matches correctly
2. **Given** rules defined using Swift class types, **When** I check permission using an instance of that class, **Then** the rule matches correctly
3. **Given** rules defined using string subject names, **When** I check permission using that string, **Then** the rule matches correctly
4. **Given** objects with custom subject type identifiers, **When** I check permission, **Then** the custom identifier is used for matching

---

### User Story 6 - Manage Dynamic Permissions (Priority: P3)

As an iOS developer, I want to update permissions at runtime based on changing user roles or context, so the authorization model can respond to authentication changes, role updates, or feature toggles.

**Why this priority**: Many apps need to update permissions when users log in/out or their roles change. This makes the library practical for real-world scenarios.

**Independent Test**: Can be fully tested by creating an Ability, modifying its rules, then verifying that permission checks reflect the updated rules.

**Acceptance Scenarios**:

1. **Given** an existing Ability instance, **When** I update its rules, **Then** subsequent permission checks use the new rules
2. **Given** permissions that change based on user login state, **When** the user logs out, **Then** the restricted permissions are no longer available
3. **Given** an Ability that emits update events, **When** rules are modified, **Then** registered observers are notified
4. **Given** multiple rule updates in sequence, **When** I check permissions, **Then** only the latest rules are active

---

### User Story 7 - Serialize and Deserialize Rules (Priority: P3)

As an iOS developer, I want to serialize permission rules to JSON and deserialize them back, so I can receive dynamic permission configurations from a backend server or cache them locally.

**Why this priority**: Isomorphic authorization (sharing rules between backend and frontend) is a key CASL feature. This enables consistent authorization across the application stack.

**Independent Test**: Can be fully tested by creating an Ability with complex rules, serializing to JSON, deserializing back, and verifying the reconstructed Ability behaves identically.

**Acceptance Scenarios**:

1. **Given** an Ability with defined rules, **When** I serialize it to JSON, **Then** all rules are properly encoded
2. **Given** a JSON representation of rules, **When** I deserialize it, **Then** the resulting Ability behaves identically to the original
3. **Given** rules with complex conditions, **When** I serialize and deserialize, **Then** the conditions are preserved accurately
4. **Given** rules received from a server, **When** I deserialize them, **Then** the Ability can enforce those server-defined permissions

---

### Edge Cases

- What happens when checking permissions on a nil subject?
- How does the system handle circular dependencies in conditions?
- What occurs when a rule matches multiple subjects with different conditions?
- How are permissions resolved when both can and cannot rules match the same action/subject?
- What happens when comparing conditions against objects missing expected properties?
- How does field matching work with nested object properties?
- What occurs when deserializing malformed or invalid JSON rules?
- How are permissions handled when an object's type cannot be determined?
- What happens when condition matchers throw errors during evaluation?
- How does the system behave with empty or zero-length arrays of actions or subjects?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide an Ability class that stores and evaluates authorization rules
- **FR-002**: System MUST support checking permissions using can(action, subject, field?) method
- **FR-003**: System MUST support checking permission denials using cannot(action, subject, field?) method
- **FR-004**: System MUST support defining rules with actions (verbs like "read", "create", "update", "delete")
- **FR-005**: System MUST support defining rules with subjects (resource types or instances)
- **FR-006**: System MUST support defining rules with optional conditions that restrict when rules apply
- **FR-007**: System MUST support defining rules with optional field restrictions for field-level permissions
- **FR-008**: System MUST support inverted rules (cannot) that explicitly deny permissions
- **FR-009**: System MUST evaluate rules in order of specificity, with more specific rules taking precedence
- **FR-010**: System MUST support the "manage" action as a special action that grants all permissions
- **FR-011**: System MUST support the "all" subject as a wildcard matching any subject type
- **FR-012**: System MUST provide an AbilityBuilder class for fluent rule definition
- **FR-013**: AbilityBuilder MUST support defining allowed permissions via can() method
- **FR-014**: AbilityBuilder MUST support defining denied permissions via cannot() method
- **FR-015**: AbilityBuilder MUST support building an Ability instance from accumulated rules
- **FR-016**: System MUST support condition matching using a query syntax (similar to MongoDB queries)
- **FR-017**: System MUST support comparison operators in conditions (equals, not equals, greater than, less than, in, not in, exists)
- **FR-018**: System MUST support logical operators in conditions (and, or, not)
- **FR-019**: System MUST support Swift class types as subjects for type-safe permission checking
- **FR-020**: System MUST support string identifiers as subjects for dynamic permission checking
- **FR-021**: System MUST support extracting subject type from instances using protocol conformance or custom detection logic
- **FR-022**: System MUST support checking permissions on both subject types and subject instances
- **FR-023**: System MUST evaluate instance-level conditions by comparing object properties against rule conditions
- **FR-024**: System MUST support field pattern matching (exact match, wildcard patterns)
- **FR-025**: System MUST provide a method to find the first matching rule for a given action/subject/field combination
- **FR-026**: System MUST serialize rules to a portable format (JSON)
- **FR-027**: System MUST deserialize rules from JSON back into Ability instances
- **FR-028**: System MUST support updating rules on an existing Ability instance
- **FR-029**: System MUST provide an error type for authorization failures
- **FR-030**: Error type MUST support throwing exceptions when permissions are denied
- **FR-031**: System MUST support defining custom subject type detection logic
- **FR-032**: System MUST support defining aliases for actions (e.g., "modify" as alias for "update")
- **FR-033**: System MUST be thread-safe for concurrent permission checks
- **FR-034**: System MUST support Codable protocol for Swift-native serialization
- **FR-035**: System MUST provide helper methods to determine all allowed fields for a given action/subject
- **FR-036**: System MUST support converting rules to a query format that can be used with data stores
- **FR-037**: System MUST support array subjects to define rules for multiple subject types at once
- **FR-038**: System MUST support array actions to define rules for multiple actions at once
- **FR-039**: System MUST support array fields to define field permissions for multiple fields at once
- **FR-040**: System MUST support a reason property on rules for documenting why a rule exists

### Key Entities

- **Ability**: The central authorization manager that stores rules and evaluates permissions. Contains a collection of rules and provides methods to check if actions are allowed or denied.

- **Rule**: Represents a single authorization rule with properties for action, subject, conditions, fields, and inverted flag. Includes matching logic to determine if the rule applies to a given scenario.

- **RawRule**: The serializable representation of a Rule, suitable for JSON encoding/decoding. Contains the same properties as Rule but without behavior logic.

- **AbilityBuilder**: A builder pattern helper for constructing Ability instances with a fluent API. Accumulates can/cannot calls and produces an Ability.

- **ForbiddenError**: An error type representing authorization failures. Contains information about what action was attempted, on what subject, and optionally which field and why it was denied.

- **Subject**: A protocol or type alias representing resources that can be authorized. Can be a Swift type, a string identifier, or an instance with properties.

- **SubjectType**: A protocol representing the type information for a subject, used for matching rules without requiring an instance.

- **Conditions**: A dictionary-like structure representing attribute-based restrictions on when a rule applies. Uses a query syntax for comparing object properties.

- **ConditionsMatcher**: A component responsible for evaluating whether an object satisfies a set of conditions. Pluggable to support different matching strategies.

- **FieldMatcher**: A component responsible for evaluating whether a field name matches a field pattern in a rule. Pluggable to support different matching strategies.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can define a complete permission set for a typical app (5+ resources, 20+ rules) in under 50 lines of code
- **SC-002**: Permission checks complete in under 1 millisecond for typical rule sets (under 100 rules)
- **SC-003**: The library supports 1000+ concurrent permission checks without performance degradation
- **SC-004**: Developers can implement role-based access control (RBAC) with 3 roles in under 30 minutes using only the library documentation
- **SC-005**: Developers can implement attribute-based access control (ABAC) with ownership checks in under 45 minutes
- **SC-006**: The library can serialize and deserialize rule sets of 100 rules in under 10 milliseconds
- **SC-007**: 90% of developers can integrate the library into an existing iOS app within 2 hours of first use
- **SC-008**: The library compiles without warnings under Swift 5.10 with strict concurrency checking enabled
- **SC-009**: Documentation covers 100% of public API surface with code examples for each major feature
- **SC-010**: The library passes 95%+ of feature-equivalent tests from the original CASL JavaScript library

## Scope & Boundaries *(mandatory)*

### In Scope

- Core permission definition and checking (can/cannot)
- Attribute-based conditions with query syntax
- Field-level permissions
- Rule serialization/deserialization (JSON)
- Builder pattern API (AbilityBuilder)
- Support for Swift types and string subjects
- Thread-safe permission checking
- Custom subject type detection
- Action aliases
- ForbiddenError for authorization failures
- Helper utilities (permitted fields, rules to query)

### Out of Scope

- UI framework integrations (UIKit, SwiftUI) - will be separate packages
- Database/ORM integrations (Core Data, Realm, SQLite) - will be separate packages
- Backend server integration or API client - developers handle their own networking
- User/role/group management - this is a pure authorization library
- Authentication - the library assumes identity is established elsewhere
- Rate limiting or throttling of permission checks
- Audit logging of permission checks - developers implement their own logging
- Permission UI visualization or debugging tools - may be added in future versions
- Multi-tenancy support - developers can implement using conditions
- Permission caching strategies - developers can wrap the library if needed
- GraphQL or REST API adapters - will be separate packages if needed

### Assumptions

- Developers understand basic authorization concepts (actions, subjects, permissions)
- The app has already established user identity before checking permissions
- Rule sets are reasonably sized (under 1000 rules for typical apps)
- Developers can provide subject type information for their domain objects
- Network latency for fetching rules from a server is handled by the developer
- Thread safety is required only for read operations (permission checks), not rule updates
- The primary target is iOS 13+ to leverage modern Swift features
- Developers are comfortable with Swift generics and protocol-oriented programming

### Dependencies

- Swift 5.10 standard library
- Foundation framework for JSON serialization
- No third-party dependencies for core library
- Developers may provide their own condition matching logic if they don't want the default query syntax

### Technical Constraints

- Must support Swift 5.10 language features
- Must compile for iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+
- Must be distributed as a Swift Package Manager package
- Should minimize memory footprint (target under 5MB compiled size)
- Should minimize dynamic dispatch for performance-critical paths
- Should leverage Swift's type system for compile-time safety where possible
- Should support both reference types (classes) and value types (structs) as subjects
