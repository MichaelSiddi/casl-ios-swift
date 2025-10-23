// FieldMatchingTests.swift
// Tests for field-level permissions (User Story 4)

import XCTest
@testable import CASL

final class FieldMatchingTests: XCTestCase {

    // MARK: - T086: Test field-level permissions with exact match

    func testFieldLevelPermissionsWithExactMatch() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost", fields: ["title", "content", "publishedAt"])
            .build()

        // Should allow reading specified fields
        let canReadTitle = await ability.can("read", "BlogPost", field: "title")
        let canReadContent = await ability.can("read", "BlogPost", field: "content")
        let canReadPublishedAt = await ability.can("read", "BlogPost", field: "publishedAt")

        XCTAssertTrue(canReadTitle, "Should be able to read title field")
        XCTAssertTrue(canReadContent, "Should be able to read content field")
        XCTAssertTrue(canReadPublishedAt, "Should be able to read publishedAt field")

        // Should deny reading non-specified fields
        let canReadAuthorId = await ability.can("read", "BlogPost", field: "authorId")
        let canReadPassword = await ability.can("read", "BlogPost", field: "password")

        XCTAssertFalse(canReadAuthorId, "Should not be able to read authorId field")
        XCTAssertFalse(canReadPassword, "Should not be able to read password field")
    }

    // MARK: - T087: Test field-level permissions with wildcard "*"

    func testFieldLevelPermissionsWithWildcard() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost", fields: ["*"])
            .build()

        // Wildcard should match any field
        let canReadTitle = await ability.can("read", "BlogPost", field: "title")
        let canReadAuthorId = await ability.can("read", "BlogPost", field: "authorId")
        let canReadPassword = await ability.can("read", "BlogPost", field: "password")
        let canReadAnything = await ability.can("read", "BlogPost", field: "anyFieldName")

        XCTAssertTrue(canReadTitle, "Wildcard should match title")
        XCTAssertTrue(canReadAuthorId, "Wildcard should match authorId")
        XCTAssertTrue(canReadPassword, "Wildcard should match password")
        XCTAssertTrue(canReadAnything, "Wildcard should match any field")
    }

    // MARK: - T088: Test field-level permissions with prefix pattern

    func testFieldLevelPermissionsWithPrefixPattern() async {
        let ability = AbilityBuilder()
            .can("read", "User", fields: ["profile.*"])
            .build()

        // Should match fields with profile. prefix
        let canReadProfileName = await ability.can("read", "User", field: "profile.name")
        let canReadProfileEmail = await ability.can("read", "User", field: "profile.email")
        let canReadProfileAvatar = await ability.can("read", "User", field: "profile.avatar")

        XCTAssertTrue(canReadProfileName, "Should match profile.name")
        XCTAssertTrue(canReadProfileEmail, "Should match profile.email")
        XCTAssertTrue(canReadProfileAvatar, "Should match profile.avatar")

        // Should not match fields without profile. prefix
        let canReadPassword = await ability.can("read", "User", field: "password")
        let canReadEmail = await ability.can("read", "User", field: "email")

        XCTAssertFalse(canReadPassword, "Should not match password")
        XCTAssertFalse(canReadEmail, "Should not match email (no prefix)")
    }

    // MARK: - T089: Test permission denied on restricted field

    func testPermissionDeniedOnRestrictedField() async {
        let ability = AbilityBuilder()
            .can("read", "User", fields: ["name", "email"])
            .cannot("read", "User", fields: ["email"]) // Explicitly deny email
            .build()

        let canReadName = await ability.can("read", "User", field: "name")
        let canReadEmail = await ability.can("read", "User", field: "email")
        let canReadPassword = await ability.can("read", "User", field: "password")

        XCTAssertTrue(canReadName, "Should be able to read name")
        XCTAssertFalse(canReadEmail, "Should not be able to read email (explicitly denied)")
        XCTAssertFalse(canReadPassword, "Should not be able to read password (not in allowed list)")
    }

    // MARK: - T090: Test permission granted on allowed field

    func testPermissionGrantedOnAllowedField() async {
        let ability = AbilityBuilder()
            .can("update", "BlogPost", fields: ["title", "content"])
            .build()

        let canUpdateTitle = await ability.can("update", "BlogPost", field: "title")
        let canUpdateContent = await ability.can("update", "BlogPost", field: "content")

        XCTAssertTrue(canUpdateTitle, "Should be able to update title")
        XCTAssertTrue(canUpdateContent, "Should be able to update content")
    }

    // MARK: - T091: Test no field restrictions means all fields allowed

    func testNoFieldRestrictionsMeansAllFieldsAllowed() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost") // No fields specified
            .build()

        // Without field restrictions, all fields should be allowed
        let canReadTitle = await ability.can("read", "BlogPost", field: "title")
        let canReadAuthorId = await ability.can("read", "BlogPost", field: "authorId")
        let canReadPassword = await ability.can("read", "BlogPost", field: "password")
        let canReadAnything = await ability.can("read", "BlogPost", field: "anyField")

        XCTAssertTrue(canReadTitle, "Should allow reading title (no field restrictions)")
        XCTAssertTrue(canReadAuthorId, "Should allow reading authorId (no field restrictions)")
        XCTAssertTrue(canReadPassword, "Should allow reading password (no field restrictions)")
        XCTAssertTrue(canReadAnything, "Should allow reading any field (no field restrictions)")
    }

    // MARK: - T092: Test multiple field patterns

    func testMultipleFieldPatterns() async {
        let ability = AbilityBuilder()
            .can("read", "User", fields: ["name", "email", "profile.*", "settings.theme"])
            .build()

        // Should match exact fields
        let canReadName = await ability.can("read", "User", field: "name")
        let canReadEmail = await ability.can("read", "User", field: "email")
        XCTAssertTrue(canReadName, "Should match exact field 'name'")
        XCTAssertTrue(canReadEmail, "Should match exact field 'email'")

        // Should match prefix pattern
        let canReadProfileBio = await ability.can("read", "User", field: "profile.bio")
        let canReadProfileAvatar = await ability.can("read", "User", field: "profile.avatar")
        XCTAssertTrue(canReadProfileBio, "Should match prefix pattern 'profile.*'")
        XCTAssertTrue(canReadProfileAvatar, "Should match prefix pattern 'profile.*'")

        // Should match nested exact field
        let canReadSettingsTheme = await ability.can("read", "User", field: "settings.theme")
        XCTAssertTrue(canReadSettingsTheme, "Should match nested exact field 'settings.theme'")

        // Should not match non-specified fields
        let canReadPassword = await ability.can("read", "User", field: "password")
        let canReadSettingsPrivacy = await ability.can("read", "User", field: "settings.privacy")
        XCTAssertFalse(canReadPassword, "Should not match non-specified field 'password'")
        XCTAssertFalse(canReadSettingsPrivacy, "Should not match non-specified field 'settings.privacy'")
    }
}
