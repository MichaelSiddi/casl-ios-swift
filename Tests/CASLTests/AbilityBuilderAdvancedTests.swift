// AbilityBuilderAdvancedTests.swift
// Advanced tests for AbilityBuilder method combinations

import XCTest
@testable import CASL

final class AbilityBuilderAdvancedTests: XCTestCase {

    // MARK: - Array Actions with Conditions

    func testArrayActionsWithConditions() async {
        let userId = "user123"

        let ability = AbilityBuilder()
            .can(
                ["read", "update"],
                "BlogPost",
                conditions: ["authorId": AnyCodable(userId)]
            )
            .build()

        struct BlogPost {
            let authorId: String
        }

        let ownPost = BlogPost(authorId: userId)
        let otherPost = BlogPost(authorId: "other")

        let canReadOwn = await ability.can("read", ownPost)
        let canUpdateOwn = await ability.can("update", ownPost)
        let canReadOther = await ability.can("read", otherPost)

        XCTAssertTrue(canReadOwn)
        XCTAssertTrue(canUpdateOwn)
        XCTAssertFalse(canReadOther)
    }

    func testArrayActionsWithFields() async {
        let ability = AbilityBuilder()
            .can(["read", "update"], "BlogPost", fields: ["title", "content"])
            .build()

        let canReadTitle = await ability.can("read", "BlogPost", field: "title")
        let canUpdateContent = await ability.can("update", "BlogPost", field: "content")
        let canReadPassword = await ability.can("read", "BlogPost", field: "password")

        XCTAssertTrue(canReadTitle)
        XCTAssertTrue(canUpdateContent)
        XCTAssertFalse(canReadPassword)
    }

    func testArrayActionsWithReason() async {
        let ability = AbilityBuilder()
            .can(
                ["read", "write"],
                "BlogPost",
                reason: "Authenticated users can read and write posts"
            )
            .build()

        let canRead = await ability.can("read", "BlogPost")
        let canWrite = await ability.can("write", "BlogPost")

        XCTAssertTrue(canRead)
        XCTAssertTrue(canWrite)
    }

    // MARK: - Array Subjects with Conditions

    func testArraySubjectsWithConditions() async {
        let userId = "user123"

        let ability = AbilityBuilder()
            .can(
                "update",
                ["BlogPost", "Comment"],
                conditions: ["authorId": AnyCodable(userId)]
            )
            .build()

        struct BlogPost {
            let authorId: String
        }

        struct Comment {
            let authorId: String
        }

        let ownPost = BlogPost(authorId: userId)
        let ownComment = Comment(authorId: userId)
        let otherPost = BlogPost(authorId: "other")

        let canUpdatePost = await ability.can("update", ownPost)
        let canUpdateComment = await ability.can("update", ownComment)
        let canUpdateOther = await ability.can("update", otherPost)

        XCTAssertTrue(canUpdatePost)
        XCTAssertTrue(canUpdateComment)
        XCTAssertFalse(canUpdateOther)
    }

    func testArraySubjectsWithFields() async {
        let ability = AbilityBuilder()
            .can("read", ["BlogPost", "Comment"], fields: ["title", "text"])
            .build()

        let canReadPostTitle = await ability.can("read", "BlogPost", field: "title")
        let canReadCommentText = await ability.can("read", "Comment", field: "text")
        let canReadPostPassword = await ability.can("read", "BlogPost", field: "password")

        XCTAssertTrue(canReadPostTitle)
        XCTAssertTrue(canReadCommentText)
        XCTAssertFalse(canReadPostPassword)
    }

    // MARK: - Array Actions AND Array Subjects

    func testArrayActionsAndSubjects() async {
        let ability = AbilityBuilder()
            .can(["read", "create"], ["BlogPost", "Comment", "User"])
            .build()

        let canReadPost = await ability.can("read", "BlogPost")
        let canCreateComment = await ability.can("create", "Comment")
        let canReadUser = await ability.can("read", "User")
        let canDeletePost = await ability.can("delete", "BlogPost")

        XCTAssertTrue(canReadPost)
        XCTAssertTrue(canCreateComment)
        XCTAssertTrue(canReadUser)
        XCTAssertFalse(canDeletePost)
    }

    func testArrayActionsAndSubjectsWithConditions() async {
        let userId = "user123"

        let ability = AbilityBuilder()
            .can(
                ["update", "delete"],
                ["BlogPost", "Comment"],
                conditions: ["authorId": AnyCodable(userId)]
            )
            .build()

        struct BlogPost {
            let authorId: String
        }

        let ownPost = BlogPost(authorId: userId)
        let otherPost = BlogPost(authorId: "other")

        let canUpdateOwn = await ability.can("update", ownPost)
        let canDeleteOwn = await ability.can("delete", ownPost)
        let canUpdateOther = await ability.can("update", otherPost)

        XCTAssertTrue(canUpdateOwn)
        XCTAssertTrue(canDeleteOwn)
        XCTAssertFalse(canUpdateOther)
    }

    // MARK: - Cannot with Arrays

    func testCannotWithArrayActions() async {
        let ability = AbilityBuilder()
            .can("manage", "BlogPost")
            .cannot(["delete", "publish"], "BlogPost")
            .build()

        let canRead = await ability.can("read", "BlogPost")
        let canDelete = await ability.can("delete", "BlogPost")
        let canPublish = await ability.can("publish", "BlogPost")

        XCTAssertTrue(canRead)
        XCTAssertFalse(canDelete)
        XCTAssertFalse(canPublish)
    }

    func testCannotWithArraySubjects() async {
        let ability = AbilityBuilder()
            .can("read", "all")
            .cannot("read", ["Secret", "Private"])
            .build()

        let canReadPublic = await ability.can("read", "Public")
        let canReadSecret = await ability.can("read", "Secret")
        let canReadPrivate = await ability.can("read", "Private")

        XCTAssertTrue(canReadPublic)
        XCTAssertFalse(canReadSecret)
        XCTAssertFalse(canReadPrivate)
    }

    func testCannotWithArrayActionsAndSubjects() async {
        let ability = AbilityBuilder()
            .can("manage", "all")
            .cannot(["delete", "destroy"], ["User", "Admin"])
            .build()

        let canReadUser = await ability.can("read", "User")
        let canDeleteUser = await ability.can("delete", "User")
        let canDestroyAdmin = await ability.can("destroy", "Admin")
        let canDeletePost = await ability.can("delete", "BlogPost")

        XCTAssertTrue(canReadUser)
        XCTAssertFalse(canDeleteUser)
        XCTAssertFalse(canDestroyAdmin)
        XCTAssertTrue(canDeletePost)
    }

    // MARK: - Builder with Custom Options

    func testBuilderWithCustomOptions() async {
        let customOptions = AbilityOptions(
            conditionsMatcher: QueryMatcher(),
            fieldMatcher: GlobFieldMatcher(),
            detectSubjectType: { _ in "CustomType" }
        )

        let ability = AbilityBuilder(options: customOptions)
            .can("read", "CustomType")
            .build()

        struct AnyType {
            let id: Int
        }

        let instance = AnyType(id: 1)
        let canRead = await ability.can("read", instance)

        XCTAssertTrue(canRead)
    }

    // MARK: - Complex Scenarios

    func testComplexPermissionScenario() async {
        let userId = "user123"

        let ability = AbilityBuilder()
            // Public read access
            .can("read", ["BlogPost", "Comment"])

            // Author can update their own content
            .can(
                ["update", "delete"],
                ["BlogPost", "Comment"],
                conditions: ["authorId": AnyCodable(userId)]
            )

            // Can't delete published posts
            .cannot("delete", "BlogPost", conditions: ["status": AnyCodable("published")])

            // Field-level restrictions on sensitive data
            .can("read", "User", fields: ["name", "email"])
            .cannot("read", "User", fields: ["password"])

            .build()

        struct BlogPost: SubjectTypeProvider {
            static var subjectType: String { "BlogPost" }
            let authorId: String
            let status: String
        }

        struct User: SubjectTypeProvider {
            static var subjectType: String { "User" }
            let name: String
        }

        let ownDraftPost = BlogPost(authorId: userId, status: "draft")
        let ownPublishedPost = BlogPost(authorId: userId, status: "published")
        let user = User(name: "John")

        // Can read any post
        let canReadPost = await ability.can("read", ownDraftPost)
        XCTAssertTrue(canReadPost)

        // Can update own posts
        let canUpdatePost = await ability.can("update", ownDraftPost)
        XCTAssertTrue(canUpdatePost)

        // Can delete own draft
        let canDeleteDraft = await ability.can("delete", ownDraftPost)
        XCTAssertTrue(canDeleteDraft)

        // Cannot delete own published post
        let canDeletePublished = await ability.can("delete", ownPublishedPost)
        XCTAssertFalse(canDeletePublished)

        // Field-level permissions on user
        let canReadName = await ability.can("read", user, field: "name")
        let canReadPassword = await ability.can("read", user, field: "password")
        XCTAssertTrue(canReadName)
        XCTAssertFalse(canReadPassword)
    }

    func testBuilderMethodCombinations() async {
        let ability = AbilityBuilder()
            // Single action, single subject
            .can("read", "BlogPost")

            // Array actions, single subject
            .can(["create", "update"], "Comment")

            // Single action, array subjects
            .can("delete", ["Draft", "Archived"])

            // Array actions, array subjects
            .can(["view", "download"], ["Image", "Video"])

            // With conditions
            .can("edit", "Profile", conditions: ["userId": AnyCodable("123")])

            // With fields
            .can("read", "Settings", fields: ["theme", "language"])

            // Cannot variations
            .cannot("destroy", "System")
            .cannot(["hack", "exploit"], "Security")
            .cannot("access", ["Restricted", "Classified"])

            .build()

        let canRead = await ability.can("read", "BlogPost")
        let canCreate = await ability.can("create", "Comment")
        let canDelete = await ability.can("delete", "Draft")
        let canView = await ability.can("view", "Image")
        let canDestroy = await ability.can("destroy", "System")

        XCTAssertTrue(canRead)
        XCTAssertTrue(canCreate)
        XCTAssertTrue(canDelete)
        XCTAssertTrue(canView)
        XCTAssertFalse(canDestroy)
    }

    // MARK: - Edge Cases

    func testEmptyArrayActions() async {
        let ability = AbilityBuilder()
            .can([], "BlogPost")
            .build()

        let canRead = await ability.can("read", "BlogPost")
        XCTAssertFalse(canRead)
    }

    func testEmptyArraySubjects() async {
        let ability = AbilityBuilder()
            .can("read", [String]())
            .build()

        let canRead = await ability.can("read", "BlogPost")
        XCTAssertFalse(canRead)
    }

    func testSingleElementArrays() async {
        let ability = AbilityBuilder()
            .can(["read"], ["BlogPost"])
            .build()

        let canRead = await ability.can("read", "BlogPost")
        XCTAssertTrue(canRead)
    }

    func testLargeArrays() async {
        var actions: [String] = []
        var subjects: [String] = []

        for i in 0..<50 {
            actions.append("action\(i)")
            subjects.append("Subject\(i)")
        }

        let ability = AbilityBuilder()
            .can(actions, subjects)
            .build()

        let canDo = await ability.can("action25", "Subject25")
        XCTAssertTrue(canDo)
    }
}
