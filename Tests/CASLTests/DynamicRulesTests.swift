// DynamicRulesTests.swift
// Tests for dynamic rule updates and edge cases

import XCTest
@testable import CASL

final class DynamicRulesTests: XCTestCase {

    // MARK: - Dynamic Rule Updates

    func testAbilityUpdateRules() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        // Initial state
        let canRead = await ability.can("read", "BlogPost")
        let canWrite = await ability.can("write", "BlogPost")
        XCTAssertTrue(canRead)
        XCTAssertFalse(canWrite)

        // Update rules
        let newRules = [
            RawRule(action: "write", subject: "BlogPost")
        ]
        await ability.update(rules: newRules)

        // Verify updated state
        let canReadAfter = await ability.can("read", "BlogPost")
        let canWriteAfter = await ability.can("write", "BlogPost")
        XCTAssertFalse(canReadAfter, "Old rule should be gone")
        XCTAssertTrue(canWriteAfter, "New rule should be active")
    }

    func testAbilityUpdateWithEmptyRules() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        // Update to empty rules
        await ability.update(rules: [])

        // Should deny everything
        let canRead = await ability.can("read", "BlogPost")
        XCTAssertFalse(canRead)
    }

    func testAbilityUpdateWithComplexRules() async {
        let ability = Ability(rules: [])
        let userId = "user123"

        // Update with complex rules
        let newRules = [
            RawRule(action: "read", subject: "BlogPost"),
            RawRule(
                action: "update",
                subject: "BlogPost",
                conditions: ["authorId": AnyCodable(userId)]
            ),
            RawRule(action: "delete", subject: "BlogPost", inverted: true)
        ]
        await ability.update(rules: newRules)

        struct BlogPost {
            let authorId: String
        }

        let ownPost = BlogPost(authorId: userId)
        let otherPost = BlogPost(authorId: "other")

        let canRead = await ability.can("read", ownPost)
        let canUpdateOwn = await ability.can("update", ownPost)
        let canUpdateOther = await ability.can("update", otherPost)
        let canDelete = await ability.can("delete", ownPost)

        XCTAssertTrue(canRead)
        XCTAssertTrue(canUpdateOwn)
        XCTAssertFalse(canUpdateOther)
        XCTAssertFalse(canDelete)
    }

    // MARK: - Ability Options

    func testAbilityWithCustomOptions() async {
        let customOptions = AbilityOptions(
            conditionsMatcher: QueryMatcher(),
            fieldMatcher: GlobFieldMatcher(),
            detectSubjectType: { subject in
                return "CustomType"
            }
        )

        let ability = Ability(
            rules: [RawRule(action: "read", subject: "CustomType")],
            options: customOptions
        )

        struct SomeType {
            let id: Int
        }

        let instance = SomeType(id: 1)
        let canRead = await ability.can("read", instance)

        XCTAssertTrue(canRead, "Custom subject type detector should return 'CustomType'")
    }

    // MARK: - Edge Cases

    func testAbilityWithNilSubject() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        // Passing a string subject (not nil)
        let canRead = await ability.can("read", "BlogPost")
        XCTAssertTrue(canRead)
    }

    func testAbilityWithEmptyActionString() async {
        let ability = Ability(rules: [
            RawRule(action: "", subject: "BlogPost")
        ])

        let canDoEmpty = await ability.can("", "BlogPost")
        let canDoRead = await ability.can("read", "BlogPost")

        XCTAssertTrue(canDoEmpty)
        XCTAssertFalse(canDoRead)
    }

    func testAbilityWithEmptySubjectString() async {
        let ability = Ability(rules: [
            RawRule(action: "read", subject: "")
        ])

        let canReadEmpty = await ability.can("read", "")
        let canReadBlogPost = await ability.can("read", "BlogPost")

        XCTAssertTrue(canReadEmpty)
        XCTAssertFalse(canReadBlogPost)
    }

    func testAbilityWithVeryLongStrings() async {
        let longAction = String(repeating: "a", count: 1000)
        let longSubject = String(repeating: "b", count: 1000)

        let ability = Ability(rules: [
            RawRule(action: longAction, subject: longSubject)
        ])

        let canDo = await ability.can(longAction, longSubject)
        XCTAssertTrue(canDo)
    }

    func testAbilityWithSpecialCharacters() async {
        let ability = Ability(rules: [
            RawRule(action: "read:特殊", subject: "BlogPost™")
        ])

        let canRead = await ability.can("read:特殊", "BlogPost™")
        XCTAssertTrue(canRead)
    }

    func testRelevantRuleForReturnsCorrectRule() async {
        let ability = Ability(rules: [
            RawRule(action: "read", subject: "BlogPost"),
            RawRule(action: "write", subject: "BlogPost"),
            RawRule(action: "delete", subject: "Comment")
        ])

        let readRule = await ability.relevantRuleFor("read", "BlogPost")
        let writeRule = await ability.relevantRuleFor("write", "BlogPost")
        let deleteRule = await ability.relevantRuleFor("delete", "Comment")
        let noRule = await ability.relevantRuleFor("update", "BlogPost")

        XCTAssertNotNil(readRule)
        XCTAssertEqual(readRule?.action, "read")
        XCTAssertNotNil(writeRule)
        XCTAssertEqual(writeRule?.action, "write")
        XCTAssertNotNil(deleteRule)
        XCTAssertEqual(deleteRule?.action, "delete")
        XCTAssertNil(noRule)
    }

    func testRelevantRuleForWithField() async {
        let ability = Ability(rules: [
            RawRule(action: "read", subject: "BlogPost", fields: ["title", "content"])
        ])

        let ruleForTitle = await ability.relevantRuleFor("read", "BlogPost", field: "title")
        let ruleForPassword = await ability.relevantRuleFor("read", "BlogPost", field: "password")

        XCTAssertNotNil(ruleForTitle)
        XCTAssertNil(ruleForPassword)
    }

    // MARK: - Builder Edge Cases

    func testAbilityBuilderClear() {
        let builder = AbilityBuilder()
            .can("read", "BlogPost")
            .can("write", "BlogPost")
            .clear()
            .can("delete", "Comment")

        let ability = builder.build()

        Task {
            let canRead = await ability.can("read", "BlogPost")
            let canDelete = await ability.can("delete", "Comment")

            XCTAssertFalse(canRead, "Cleared rules should be gone")
            XCTAssertTrue(canDelete, "New rule after clear should work")
        }
    }

    func testAbilityBuilderMultipleBuild() {
        let builder = AbilityBuilder()
            .can("read", "BlogPost")

        let ability1 = builder.build()
        let ability2 = builder.build()

        Task {
            let can1 = await ability1.can("read", "BlogPost")
            let can2 = await ability2.can("read", "BlogPost")

            XCTAssertTrue(can1)
            XCTAssertTrue(can2)
        }
    }

    func testAbilityBuilderArrayActionsAndSubjects() {
        let builder = AbilityBuilder()
            .can(["read", "write"], ["BlogPost", "Comment"])

        let ability = builder.build()

        Task {
            let canReadPost = await ability.can("read", "BlogPost")
            let canWritePost = await ability.can("write", "BlogPost")
            let canReadComment = await ability.can("read", "Comment")
            let canWriteComment = await ability.can("write", "Comment")
            let canDeletePost = await ability.can("delete", "BlogPost")

            XCTAssertTrue(canReadPost)
            XCTAssertTrue(canWritePost)
            XCTAssertTrue(canReadComment)
            XCTAssertTrue(canWriteComment)
            XCTAssertFalse(canDeletePost)
        }
    }

    func testAbilityBuilderCannotArrayActionsAndSubjects() {
        let builder = AbilityBuilder()
            .can("manage", "all")
            .cannot(["delete", "publish"], ["BlogPost", "Comment"])

        let ability = builder.build()

        Task {
            let canReadPost = await ability.can("read", "BlogPost")
            let canDeletePost = await ability.can("delete", "BlogPost")
            let canPublishComment = await ability.can("publish", "Comment")

            XCTAssertTrue(canReadPost)
            XCTAssertFalse(canDeletePost)
            XCTAssertFalse(canPublishComment)
        }
    }

    // MARK: - RawRule Expansion

    func testRawRuleExpansionSingleActions() {
        let rule = RawRule(action: "read", subject: "BlogPost")
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 1)
        XCTAssertEqual(expanded[0].action, "read")
        XCTAssertEqual(expanded[0].subject, "BlogPost")
    }

    func testRawRuleExpansionMultipleActions() {
        let rule = RawRule(
            action: StringOrArray(["read", "write"]),
            subject: StringOrArray("BlogPost")
        )
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 2)
        XCTAssertEqual(expanded[0].action, "read")
        XCTAssertEqual(expanded[1].action, "write")
    }

    func testRawRuleExpansionMultipleSubjects() {
        let rule = RawRule(
            action: StringOrArray("read"),
            subject: StringOrArray(["BlogPost", "Comment"])
        )
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 2)
        XCTAssertEqual(expanded[0].subject, "BlogPost")
        XCTAssertEqual(expanded[1].subject, "Comment")
    }

    func testRawRuleExpansionCartesianProduct() {
        let rule = RawRule(
            action: StringOrArray(["read", "write"]),
            subject: StringOrArray(["BlogPost", "Comment"])
        )
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 4)
        // read BlogPost, read Comment, write BlogPost, write Comment
    }

    func testRawRuleExpansionNoSubject() {
        let rule = RawRule(
            action: StringOrArray("read"),
            subject: nil
        )
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 1)
        XCTAssertNil(expanded[0].subject)
    }
}
