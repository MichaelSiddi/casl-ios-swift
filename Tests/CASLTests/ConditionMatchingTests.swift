// ConditionMatchingTests.swift
// Tests for conditional permission matching (User Story 2)

import XCTest
@testable import CASL

final class ConditionMatchingTests: XCTestCase {

    // MARK: - Test Models

    struct BlogPost {
        let id: Int
        let title: String
        let authorId: String
        let status: String
        let views: Int
        let publishedAt: Date?
    }

    // MARK: - T037: Test condition matching with simple equality

    func testConditionMatchingWithSimpleEquality() async {
        let userId = "user123"

        let rules = [
            RawRule(
                action: "update",
                subject: "BlogPost",
                conditions: ["authorId": AnyCodable(userId)]
            )
        ]
        let ability = Ability(rules: rules)

        // Create posts - one by the user, one by someone else
        let ownPost = BlogPost(id: 1, title: "My Post", authorId: userId, status: "draft", views: 100, publishedAt: nil)
        let otherPost = BlogPost(id: 2, title: "Other Post", authorId: "other456", status: "published", views: 200, publishedAt: Date())

        // Should allow updating own post
        let canUpdateOwn = await ability.can("update", ownPost)
        XCTAssertTrue(canUpdateOwn, "Should be able to update own post")

        // Should deny updating other's post
        let canUpdateOther = await ability.can("update", otherPost)
        XCTAssertFalse(canUpdateOther, "Should not be able to update other's post")
    }

    // MARK: - T038: Test condition matching with greater than operator

    func testConditionMatchingWithGreaterThan() async {
        let rules = [
            RawRule(
                action: "feature",
                subject: "BlogPost",
                conditions: ["views": AnyCodable(["$gt": AnyCodable(1000)])]
            )
        ]
        let ability = Ability(rules: rules)

        let popularPost = BlogPost(id: 1, title: "Popular", authorId: "user1", status: "published", views: 5000, publishedAt: Date())
        let unpopularPost = BlogPost(id: 2, title: "Unpopular", authorId: "user1", status: "published", views: 50, publishedAt: Date())

        // Should allow featuring popular post
        let canFeaturePopular = await ability.can("feature", popularPost)
        XCTAssertTrue(canFeaturePopular, "Should be able to feature popular post (views > 1000)")

        // Should deny featuring unpopular post
        let canFeatureUnpopular = await ability.can("feature", unpopularPost)
        XCTAssertFalse(canFeatureUnpopular, "Should not be able to feature unpopular post (views <= 1000)")
    }

    // MARK: - T039: Test condition matching with less than operator

    func testConditionMatchingWithLessThan() async {
        let rules = [
            RawRule(
                action: "archive",
                subject: "BlogPost",
                conditions: ["views": AnyCodable(["$lt": AnyCodable(100)])]
            )
        ]
        let ability = Ability(rules: rules)

        let lowViewsPost = BlogPost(id: 1, title: "Low Views", authorId: "user1", status: "published", views: 10, publishedAt: Date())
        let highViewsPost = BlogPost(id: 2, title: "High Views", authorId: "user1", status: "published", views: 500, publishedAt: Date())

        // Should allow archiving low views post
        let canArchiveLow = await ability.can("archive", lowViewsPost)
        XCTAssertTrue(canArchiveLow, "Should be able to archive post with views < 100")

        // Should deny archiving high views post
        let canArchiveHigh = await ability.can("archive", highViewsPost)
        XCTAssertFalse(canArchiveHigh, "Should not be able to archive post with views >= 100")
    }

    // MARK: - T040: Test condition matching with $in operator

    func testConditionMatchingWithInOperator() async {
        let rules = [
            RawRule(
                action: "publish",
                subject: "BlogPost",
                conditions: ["status": AnyCodable(["$in": AnyCodable(["draft", "review"])])]
            )
        ]
        let ability = Ability(rules: rules)

        let draftPost = BlogPost(id: 1, title: "Draft", authorId: "user1", status: "draft", views: 0, publishedAt: nil)
        let reviewPost = BlogPost(id: 2, title: "Review", authorId: "user1", status: "review", views: 0, publishedAt: nil)
        let publishedPost = BlogPost(id: 3, title: "Published", authorId: "user1", status: "published", views: 100, publishedAt: Date())

        // Should allow publishing draft
        let canPublishDraft = await ability.can("publish", draftPost)
        XCTAssertTrue(canPublishDraft, "Should be able to publish draft post")

        // Should allow publishing review
        let canPublishReview = await ability.can("publish", reviewPost)
        XCTAssertTrue(canPublishReview, "Should be able to publish review post")

        // Should deny publishing already published
        let canPublishPublished = await ability.can("publish", publishedPost)
        XCTAssertFalse(canPublishPublished, "Should not be able to publish already published post")
    }

    // MARK: - T041: Test condition matching with $nin operator

    func testConditionMatchingWithNotInOperator() async {
        let rules = [
            RawRule(
                action: "edit",
                subject: "BlogPost",
                conditions: ["status": AnyCodable(["$nin": AnyCodable(["archived", "deleted"])])]
            )
        ]
        let ability = Ability(rules: rules)

        let draftPost = BlogPost(id: 1, title: "Draft", authorId: "user1", status: "draft", views: 0, publishedAt: nil)
        let archivedPost = BlogPost(id: 2, title: "Archived", authorId: "user1", status: "archived", views: 100, publishedAt: Date())

        // Should allow editing non-archived post
        let canEditDraft = await ability.can("edit", draftPost)
        XCTAssertTrue(canEditDraft, "Should be able to edit draft post")

        // Should deny editing archived post
        let canEditArchived = await ability.can("edit", archivedPost)
        XCTAssertFalse(canEditArchived, "Should not be able to edit archived post")
    }

    // MARK: - T042: Test condition matching with $exists operator

    func testConditionMatchingWithExistsOperator() async {
        let rules = [
            RawRule(
                action: "unpublish",
                subject: "BlogPost",
                conditions: ["publishedAt": AnyCodable(["$exists": AnyCodable(true)])]
            )
        ]
        let ability = Ability(rules: rules)

        let publishedPost = BlogPost(id: 1, title: "Published", authorId: "user1", status: "published", views: 100, publishedAt: Date())
        let draftPost = BlogPost(id: 2, title: "Draft", authorId: "user1", status: "draft", views: 0, publishedAt: nil)

        // Should allow unpublishing published post (has publishedAt)
        let canUnpublishPublished = await ability.can("unpublish", publishedPost)
        XCTAssertTrue(canUnpublishPublished, "Should be able to unpublish published post")

        // Should deny unpublishing draft (no publishedAt)
        let canUnpublishDraft = await ability.can("unpublish", draftPost)
        XCTAssertFalse(canUnpublishDraft, "Should not be able to unpublish draft post")
    }

    // MARK: - T043: Test compound conditions with $and

    func testCompoundConditionsWithAnd() async {
        let userId = "user123"

        let rules = [
            RawRule(
                action: "delete",
                subject: "BlogPost",
                conditions: [
                    "$and": AnyCodable([
                        AnyCodable(["authorId": AnyCodable(userId)]),
                        AnyCodable(["status": AnyCodable("draft")])
                    ])
                ]
            )
        ]
        let ability = Ability(rules: rules)

        let ownDraft = BlogPost(id: 1, title: "My Draft", authorId: userId, status: "draft", views: 0, publishedAt: nil)
        let ownPublished = BlogPost(id: 2, title: "My Published", authorId: userId, status: "published", views: 100, publishedAt: Date())
        let otherDraft = BlogPost(id: 3, title: "Other Draft", authorId: "other456", status: "draft", views: 0, publishedAt: nil)

        // Should allow deleting own draft (both conditions met)
        let canDeleteOwnDraft = await ability.can("delete", ownDraft)
        XCTAssertTrue(canDeleteOwnDraft, "Should be able to delete own draft")

        // Should deny deleting own published (second condition not met)
        let canDeleteOwnPublished = await ability.can("delete", ownPublished)
        XCTAssertFalse(canDeleteOwnPublished, "Should not be able to delete own published post")

        // Should deny deleting other's draft (first condition not met)
        let canDeleteOtherDraft = await ability.can("delete", otherDraft)
        XCTAssertFalse(canDeleteOtherDraft, "Should not be able to delete other's draft")
    }

    // MARK: - T044: Test compound conditions with $or

    func testCompoundConditionsWithOr() async {
        let userId = "user123"

        let rules = [
            RawRule(
                action: "read",
                subject: "BlogPost",
                conditions: [
                    "$or": AnyCodable([
                        AnyCodable(["authorId": AnyCodable(userId)]),
                        AnyCodable(["status": AnyCodable("published")])
                    ])
                ]
            )
        ]
        let ability = Ability(rules: rules)

        let ownDraft = BlogPost(id: 1, title: "My Draft", authorId: userId, status: "draft", views: 0, publishedAt: nil)
        let otherPublished = BlogPost(id: 2, title: "Other Published", authorId: "other456", status: "published", views: 100, publishedAt: Date())
        let otherDraft = BlogPost(id: 3, title: "Other Draft", authorId: "other456", status: "draft", views: 0, publishedAt: nil)

        // Should allow reading own draft (first condition met)
        let canReadOwnDraft = await ability.can("read", ownDraft)
        XCTAssertTrue(canReadOwnDraft, "Should be able to read own draft")

        // Should allow reading other's published (second condition met)
        let canReadOtherPublished = await ability.can("read", otherPublished)
        XCTAssertTrue(canReadOtherPublished, "Should be able to read other's published post")

        // Should deny reading other's draft (neither condition met)
        let canReadOtherDraft = await ability.can("read", otherDraft)
        XCTAssertFalse(canReadOtherDraft, "Should not be able to read other's draft")
    }

    // MARK: - T045: Test negated conditions with $not

    func testNegatedConditionsWithNot() async {
        let rules = [
            RawRule(
                action: "moderate",
                subject: "BlogPost",
                conditions: [
                    "$not": AnyCodable(["status": AnyCodable("archived")])
                ]
            )
        ]
        let ability = Ability(rules: rules)

        let draftPost = BlogPost(id: 1, title: "Draft", authorId: "user1", status: "draft", views: 0, publishedAt: nil)
        let archivedPost = BlogPost(id: 2, title: "Archived", authorId: "user1", status: "archived", views: 100, publishedAt: Date())

        // Should allow moderating non-archived post
        let canModerateDraft = await ability.can("moderate", draftPost)
        XCTAssertTrue(canModerateDraft, "Should be able to moderate non-archived post")

        // Should deny moderating archived post
        let canModerateArchived = await ability.can("moderate", archivedPost)
        XCTAssertFalse(canModerateArchived, "Should not be able to moderate archived post")
    }

    // MARK: - T046: Test permission denied when conditions don't match

    func testPermissionDeniedWhenConditionsDontMatch() async {
        let rules = [
            RawRule(
                action: "update",
                subject: "BlogPost",
                conditions: ["authorId": AnyCodable("user123")]
            )
        ]
        let ability = Ability(rules: rules)

        let post = BlogPost(id: 1, title: "Post", authorId: "other456", status: "draft", views: 0, publishedAt: nil)

        // Should deny when authorId doesn't match
        let canUpdate = await ability.can("update", post)
        XCTAssertFalse(canUpdate, "Should deny permission when conditions don't match")
    }

    // MARK: - T047: Test permission granted when conditions match

    func testPermissionGrantedWhenConditionsMatch() async {
        let rules = [
            RawRule(
                action: "update",
                subject: "BlogPost",
                conditions: ["authorId": AnyCodable("user123")]
            )
        ]
        let ability = Ability(rules: rules)

        let post = BlogPost(id: 1, title: "Post", authorId: "user123", status: "draft", views: 0, publishedAt: nil)

        // Should allow when authorId matches
        let canUpdate = await ability.can("update", post)
        XCTAssertTrue(canUpdate, "Should grant permission when conditions match")
    }

    // MARK: - T048: Test time-based conditions

    func testTimeBasedConditions() async {
        let cutoffDate = Date(timeIntervalSince1970: 1609459200) // Jan 1, 2021

        let rules = [
            RawRule(
                action: "archive",
                subject: "BlogPost",
                conditions: ["publishedAt": AnyCodable(["$lt": AnyCodable(cutoffDate)])]
            )
        ]
        let ability = Ability(rules: rules)

        let oldPost = BlogPost(
            id: 1,
            title: "Old Post",
            authorId: "user1",
            status: "published",
            views: 100,
            publishedAt: Date(timeIntervalSince1970: 1577836800) // Jan 1, 2020
        )

        let newPost = BlogPost(
            id: 2,
            title: "New Post",
            authorId: "user1",
            status: "published",
            views: 100,
            publishedAt: Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        )

        // Should allow archiving old post
        let canArchiveOld = await ability.can("archive", oldPost)
        XCTAssertTrue(canArchiveOld, "Should be able to archive old post")

        // Should deny archiving new post
        let canArchiveNew = await ability.can("archive", newPost)
        XCTAssertFalse(canArchiveNew, "Should not be able to archive new post")
    }
}
