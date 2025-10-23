// AbilityTests.swift
// Tests for basic Ability permission checking (User Story 1)

import XCTest
@testable import CASL

final class AbilityTests: XCTestCase {

    // MARK: - T018: Test Ability initialization with empty rules

    func testAbilityInitializationWithEmptyRules() {
        let ability = Ability(rules: [])

        // Verify ability is created successfully
        XCTAssertNotNil(ability)
    }

    // MARK: - T019: Test can() returns true for allowed action

    func testCanReturnsTrueForAllowedAction() async {
        let rules = [
            RawRule(action: "read", subject: "BlogPost")
        ]
        let ability = Ability(rules: rules)

        // Should allow reading blog posts
        let canRead = await ability.can("read", "BlogPost")
        XCTAssertTrue(canRead, "Should be able to read BlogPost")
    }

    // MARK: - T020: Test can() returns false for forbidden action

    func testCanReturnsFalseForForbiddenAction() async {
        let rules = [
            RawRule(action: "read", subject: "BlogPost")
        ]
        let ability = Ability(rules: rules)

        // Should not allow deleting blog posts (no rule defined)
        let canDelete = await ability.can("delete", "BlogPost")
        XCTAssertFalse(canDelete, "Should not be able to delete BlogPost")
    }

    // MARK: - T021: Test cannot() returns true for denied action

    func testCannotReturnsTrueForDeniedAction() async {
        let rules = [
            RawRule(action: "delete", subject: "BlogPost", inverted: true)
        ]
        let ability = Ability(rules: rules)

        // Should deny deleting blog posts
        let cannotDelete = await ability.cannot("delete", "BlogPost")
        XCTAssertTrue(cannotDelete, "Should not be able to delete BlogPost")
    }

    // MARK: - T022: Test default deny behavior (no rules)

    func testDefaultDenyBehaviorWhenNoRules() async {
        let ability = Ability(rules: [])

        // Should deny everything when no rules defined
        let canRead = await ability.can("read", "BlogPost")
        let canCreate = await ability.can("create", "BlogPost")
        let canUpdate = await ability.can("update", "BlogPost")

        XCTAssertFalse(canRead, "Should deny read by default")
        XCTAssertFalse(canCreate, "Should deny create by default")
        XCTAssertFalse(canUpdate, "Should deny update by default")
    }

    // MARK: - T023: Test "manage" action wildcard matching

    func testManageActionWildcardMatching() async {
        let rules = [
            RawRule(action: "manage", subject: "BlogPost")
        ]
        let ability = Ability(rules: rules)

        // "manage" should match all actions
        let canRead = await ability.can("read", "BlogPost")
        let canCreate = await ability.can("create", "BlogPost")
        let canUpdate = await ability.can("update", "BlogPost")
        let canDelete = await ability.can("delete", "BlogPost")

        XCTAssertTrue(canRead, "'manage' should allow read")
        XCTAssertTrue(canCreate, "'manage' should allow create")
        XCTAssertTrue(canUpdate, "'manage' should allow update")
        XCTAssertTrue(canDelete, "'manage' should allow delete")
    }

    // MARK: - T024: Test "all" subject wildcard matching

    func testAllSubjectWildcardMatching() async {
        let rules = [
            RawRule(action: "read", subject: "all")
        ]
        let ability = Ability(rules: rules)

        // "all" should match any subject type
        let canReadBlogPost = await ability.can("read", "BlogPost")
        let canReadComment = await ability.can("read", "Comment")
        let canReadUser = await ability.can("read", "User")

        XCTAssertTrue(canReadBlogPost, "'all' should match BlogPost")
        XCTAssertTrue(canReadComment, "'all' should match Comment")
        XCTAssertTrue(canReadUser, "'all' should match User")
    }

    // MARK: - T025: Test inverted rules (cannot) override

    func testInvertedRulesCannotOverride() async {
        let rules = [
            RawRule(action: "manage", subject: "BlogPost"),
            RawRule(action: "delete", subject: "BlogPost", inverted: true)
        ]
        let ability = Ability(rules: rules)

        // Can do everything except delete
        let canRead = await ability.can("read", "BlogPost")
        let canUpdate = await ability.can("update", "BlogPost")
        let canDelete = await ability.can("delete", "BlogPost")

        XCTAssertTrue(canRead, "Should allow read")
        XCTAssertTrue(canUpdate, "Should allow update")
        XCTAssertFalse(canDelete, "Cannot should override manage for delete")
    }
}
