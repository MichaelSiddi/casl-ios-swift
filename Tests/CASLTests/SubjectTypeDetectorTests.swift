// SubjectTypeDetectorTests.swift
// Tests for subject type detection edge cases

import XCTest
@testable import CASL

final class SubjectTypeDetectorTests: XCTestCase {

    // MARK: - Default Subject Type Detector

    func testDetectTypeFromString() {
        let result = defaultSubjectTypeDetector("BlogPost")
        XCTAssertEqual(result, "String")
    }

    func testDetectTypeFromStruct() {
        struct Article {
            let id: Int
        }

        let article = Article(id: 1)
        let result = defaultSubjectTypeDetector(article)

        XCTAssertEqual(result, "Article")
    }

    func testDetectTypeFromClass() {
        class BlogPost {
            let id: Int
            init(id: Int) { self.id = id }
        }

        let post = BlogPost(id: 1)
        let result = defaultSubjectTypeDetector(post)

        XCTAssertEqual(result, "BlogPost")
    }

    func testDetectTypeFromSubjectTypeProvider() {
        struct CustomType: SubjectTypeProvider {
            static var subjectType: String { "MyCustomType" }
            let id: Int
        }

        let instance = CustomType(id: 1)
        let result = defaultSubjectTypeDetector(instance)

        XCTAssertEqual(result, "MyCustomType")
    }

    func testDetectTypeFromNestedType() {
        struct Outer {
            struct Inner {
                let value: String
            }
        }

        let inner = Outer.Inner(value: "test")
        let result = defaultSubjectTypeDetector(inner)

        // Should extract just "Inner" not "Outer.Inner"
        XCTAssertEqual(result, "Inner")
    }

    func testDetectTypeFromGenericType() {
        struct Container<T> {
            let value: T
        }

        let container = Container(value: "test")
        let result = defaultSubjectTypeDetector(container)

        // Should handle generic types
        XCTAssertTrue(result.contains("Container"))
    }

    func testDetectTypeFromOptional() {
        struct BlogPost {
            let id: Int
        }

        let post: BlogPost? = BlogPost(id: 1)
        let result = defaultSubjectTypeDetector(post as Any)

        // Should detect Optional wrapper
        XCTAssertTrue(result.contains("Optional") || result.contains("BlogPost"))
    }

    func testDetectTypeFromArray() {
        let array = [1, 2, 3]
        let result = defaultSubjectTypeDetector(array)

        XCTAssertTrue(result.contains("Array"))
    }

    func testDetectTypeFromDictionary() {
        let dict = ["key": "value"]
        let result = defaultSubjectTypeDetector(dict)

        XCTAssertTrue(result.contains("Dictionary"))
    }

    func testDetectTypeFromTuple() {
        let tuple = (1, "test")
        let result = defaultSubjectTypeDetector(tuple)

        // Tuples have complex type names
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - SubjectTypeProvider Protocol

    func testSubjectTypeProviderTakesPrecedence() {
        struct TypeWithProvider: SubjectTypeProvider {
            static var subjectType: String { "OverriddenName" }
            let id: Int
        }

        let instance = TypeWithProvider(id: 1)
        let result = defaultSubjectTypeDetector(instance)

        XCTAssertEqual(result, "OverriddenName", "SubjectTypeProvider should take precedence over reflection")
    }

    func testSubjectTypeProviderWithEmptyString() {
        struct EmptyType: SubjectTypeProvider {
            static var subjectType: String { "" }
        }

        let instance = EmptyType()
        let result = defaultSubjectTypeDetector(instance)

        XCTAssertEqual(result, "")
    }

    func testSubjectTypeProviderWithSpecialCharacters() {
        struct SpecialType: SubjectTypeProvider {
            static var subjectType: String { "Type::With::Colons" }
        }

        let instance = SpecialType()
        let result = defaultSubjectTypeDetector(instance)

        XCTAssertEqual(result, "Type::With::Colons")
    }

    // MARK: - Edge Cases

    func testDetectTypeFromInt() {
        let result = defaultSubjectTypeDetector(42)
        XCTAssertEqual(result, "Int")
    }

    func testDetectTypeFromDouble() {
        let result = defaultSubjectTypeDetector(3.14)
        XCTAssertEqual(result, "Double")
    }

    func testDetectTypeFromBool() {
        let result = defaultSubjectTypeDetector(true)
        XCTAssertEqual(result, "Bool")
    }

    func testDetectTypeFromNSObject() {
        let obj = NSObject()
        let result = defaultSubjectTypeDetector(obj)

        XCTAssertEqual(result, "NSObject")
    }

    func testDetectTypeFromAnyObject() {
        class MyClass {}
        let obj: AnyObject = MyClass()
        let result = defaultSubjectTypeDetector(obj)

        XCTAssertEqual(result, "MyClass")
    }

    func testDetectTypeConsistency() {
        struct TestType {
            let id: Int
        }

        let instance1 = TestType(id: 1)
        let instance2 = TestType(id: 2)

        let result1 = defaultSubjectTypeDetector(instance1)
        let result2 = defaultSubjectTypeDetector(instance2)

        XCTAssertEqual(result1, result2, "Same type should always return same type name")
    }

    func testDetectTypeFromClosure() {
        let closure = { (x: Int) -> Int in x * 2 }
        let result = defaultSubjectTypeDetector(closure)

        // Closures have complex type names
        XCTAssertFalse(result.isEmpty)
    }

    func testDetectTypeFromEnum() {
        enum Status {
            case active
            case inactive
        }

        let status = Status.active
        let result = defaultSubjectTypeDetector(status)

        XCTAssertEqual(result, "Status")
    }

    func testDetectTypeFromEnumWithAssociatedValue() {
        enum Result {
            case success(String)
            case failure(Error)
        }

        let result = Result.success("test")
        let typeName = defaultSubjectTypeDetector(result)

        XCTAssertEqual(typeName, "Result")
    }
}
