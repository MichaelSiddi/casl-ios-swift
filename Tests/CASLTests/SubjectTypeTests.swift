// SubjectTypeTests.swift
// Tests for multiple subject type handling (User Story 5)

import XCTest
@testable import CASL

final class SubjectTypeTests: XCTestCase {

    // MARK: - Test Models

    class BlogPost {
        let id: Int
        let title: String

        init(id: Int, title: String) {
            self.id = id
            self.title = title
        }
    }

    struct Comment {
        let id: Int
        let text: String
    }

    struct Article: SubjectTypeProvider {
        static var subjectType: String { "Article" }

        let id: Int
        let title: String
    }

    // MARK: - T105: Test subject type detection from class instance

    func testSubjectTypeDetectionFromClassInstance() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        let post = BlogPost(id: 1, title: "Test")

        // Should detect "BlogPost" from class instance
        let canRead = await ability.can("read", post)
        XCTAssertTrue(canRead, "Should detect BlogPost type from class instance")
    }

    // MARK: - T106: Test subject type detection from struct instance

    func testSubjectTypeDetectionFromStructInstance() async {
        let ability = AbilityBuilder()
            .can("read", "Comment")
            .build()

        let comment = Comment(id: 1, text: "Great post!")

        // Should detect "Comment" from struct instance
        let canRead = await ability.can("read", comment)
        XCTAssertTrue(canRead, "Should detect Comment type from struct instance")
    }

    // MARK: - T107: Test SubjectTypeProvider protocol usage

    func testSubjectTypeProviderProtocol() async {
        let ability = AbilityBuilder()
            .can("read", "Article")
            .build()

        let article = Article(id: 1, title: "Test Article")

        // Should use SubjectTypeProvider protocol to get type name
        let canRead = await ability.can("read", article)
        XCTAssertTrue(canRead, "Should use SubjectTypeProvider to detect Article type")
    }

    // MARK: - T108: Test permission check using class type

    func testPermissionCheckUsingClassType() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        // Check using string subject type
        let canRead = await ability.can("read", "BlogPost")
        XCTAssertTrue(canRead, "Should allow reading BlogPost using string type")

        let canWrite = await ability.can("write", "BlogPost")
        XCTAssertFalse(canWrite, "Should deny writing BlogPost")
    }

    // MARK: - T109: Test permission check using string subject

    func testPermissionCheckUsingStringSubject() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .can("write", "Comment")
            .build()

        let canReadBlogPost = await ability.can("read", "BlogPost")
        let canWriteComment = await ability.can("write", "Comment")
        let canDeleteBlogPost = await ability.can("delete", "BlogPost")

        XCTAssertTrue(canReadBlogPost, "Should allow reading BlogPost")
        XCTAssertTrue(canWriteComment, "Should allow writing Comment")
        XCTAssertFalse(canDeleteBlogPost, "Should deny deleting BlogPost")
    }

    // MARK: - T110: Test permission check using instance

    func testPermissionCheckUsingInstance() async {
        let userId = "user123"

        // Define a struct that identifies itself as "BlogPost"
        struct BlogPostWithAuthor: SubjectTypeProvider {
            static var subjectType: String { "BlogPost" }

            let id: Int
            let title: String
            let authorId: String
        }

        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .can("update", "BlogPost", conditions: ["authorId": AnyCodable(userId)])
            .build()

        let ownPost = BlogPostWithAuthor(id: 1, title: "My Post", authorId: userId)
        let otherPost = BlogPostWithAuthor(id: 2, title: "Other Post", authorId: "other456")

        // Should allow reading any post (no conditions)
        let canReadOwn = await ability.can("read", ownPost)
        let canReadOther = await ability.can("read", otherPost)
        XCTAssertTrue(canReadOwn, "Should allow reading own post")
        XCTAssertTrue(canReadOther, "Should allow reading other's post")

        // Should only allow updating own post (with conditions)
        let canUpdateOwn = await ability.can("update", ownPost)
        let canUpdateOther = await ability.can("update", otherPost)
        XCTAssertTrue(canUpdateOwn, "Should allow updating own post")
        XCTAssertFalse(canUpdateOther, "Should deny updating other's post")
    }

    // MARK: - T111: Test custom subject type name

    func testCustomSubjectTypeName() async {
        // Custom struct with SubjectTypeProvider
        struct CustomResource: SubjectTypeProvider {
            static var subjectType: String { "MyCustomResource" }
            let id: Int
        }

        let ability = AbilityBuilder()
            .can("read", "MyCustomResource")
            .build()

        let resource = CustomResource(id: 1)

        // Should use custom type name from SubjectTypeProvider
        let canRead = await ability.can("read", resource)
        XCTAssertTrue(canRead, "Should use custom type name 'MyCustomResource'")

        // Should not match actual struct name
        let canReadByStructName = await ability.can("read", "CustomResource")
        XCTAssertFalse(canReadByStructName, "Should not match struct name 'CustomResource'")
    }
}
