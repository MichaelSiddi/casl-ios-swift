// QueryMatcherTests.swift
// Tests for QueryMatcher edge cases and operators

import XCTest
@testable import CASL

final class QueryMatcherTests: XCTestCase {

    // MARK: - Compile Method

    func testQueryMatcherCompile() {
        let matcher = QueryMatcher()
        let conditions = ["status": AnyCodable("active")]

        let matchFn = matcher.compile(conditions)

        struct Item {
            let status: String
        }

        let activeItem = Item(status: "active")
        let inactiveItem = Item(status: "inactive")

        XCTAssertTrue(matchFn(activeItem))
        XCTAssertFalse(matchFn(inactiveItem))
    }

    func testQueryMatcherMatches() {
        let matcher = QueryMatcher()
        let conditions = ["count": AnyCodable(["$gt": AnyCodable(10)])]

        struct Item {
            let count: Int
        }

        let item1 = Item(count: 20)
        let item2 = Item(count: 5)

        XCTAssertTrue(matcher.matches(item1, conditions: conditions))
        XCTAssertFalse(matcher.matches(item2, conditions: conditions))
    }

    // MARK: - Comparison Operators

    func testGreaterThanOrEqualOperator() {
        let matcher = QueryMatcher()
        let conditions = ["age": AnyCodable(["$gte": AnyCodable(18)])]

        struct Person {
            let age: Int
        }

        let adult = Person(age: 18)
        let older = Person(age: 25)
        let minor = Person(age: 17)

        XCTAssertTrue(matcher.matches(adult, conditions: conditions))
        XCTAssertTrue(matcher.matches(older, conditions: conditions))
        XCTAssertFalse(matcher.matches(minor, conditions: conditions))
    }

    func testLessThanOrEqualOperator() {
        let matcher = QueryMatcher()
        let conditions = ["price": AnyCodable(["$lte": AnyCodable(100)])]

        struct Product {
            let price: Double
        }

        let cheap = Product(price: 50.0)
        let exact = Product(price: 100.0)
        let expensive = Product(price: 150.0)

        XCTAssertTrue(matcher.matches(cheap, conditions: conditions))
        XCTAssertTrue(matcher.matches(exact, conditions: conditions))
        XCTAssertFalse(matcher.matches(expensive, conditions: conditions))
    }

    func testNotEqualOperator() {
        let matcher = QueryMatcher()
        let conditions = ["status": AnyCodable(["$ne": AnyCodable("deleted")])]

        struct Item {
            let status: String
        }

        let active = Item(status: "active")
        let deleted = Item(status: "deleted")

        XCTAssertTrue(matcher.matches(active, conditions: conditions))
        XCTAssertFalse(matcher.matches(deleted, conditions: conditions))
    }

    // MARK: - Complex Nested Conditions

    func testNestedAndConditions() {
        let matcher = QueryMatcher()
        let conditions = [
            "$and": AnyCodable([
                AnyCodable([
                    "$and": AnyCodable([
                        AnyCodable(["status": AnyCodable("active")]),
                        AnyCodable(["verified": AnyCodable(true)])
                    ])
                ]),
                AnyCodable(["count": AnyCodable(["$gt": AnyCodable(0)])])
            ])
        ]

        struct Item {
            let status: String
            let verified: Bool
            let count: Int
        }

        let valid = Item(status: "active", verified: true, count: 5)
        let invalid1 = Item(status: "inactive", verified: true, count: 5)
        let invalid2 = Item(status: "active", verified: false, count: 5)
        let invalid3 = Item(status: "active", verified: true, count: 0)

        XCTAssertTrue(matcher.matches(valid, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid1, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid2, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid3, conditions: conditions))
    }

    func testNestedOrConditions() {
        let matcher = QueryMatcher()
        let conditions = [
            "$or": AnyCodable([
                AnyCodable([
                    "$or": AnyCodable([
                        AnyCodable(["status": AnyCodable("draft")]),
                        AnyCodable(["status": AnyCodable("review")])
                    ])
                ]),
                AnyCodable(["priority": AnyCodable("high")])
            ])
        ]

        struct Item {
            let status: String
            let priority: String
        }

        let draft = Item(status: "draft", priority: "low")
        let review = Item(status: "review", priority: "low")
        let highPriority = Item(status: "published", priority: "high")
        let none = Item(status: "published", priority: "low")

        XCTAssertTrue(matcher.matches(draft, conditions: conditions))
        XCTAssertTrue(matcher.matches(review, conditions: conditions))
        XCTAssertTrue(matcher.matches(highPriority, conditions: conditions))
        XCTAssertFalse(matcher.matches(none, conditions: conditions))
    }

    // MARK: - Property Extraction Edge Cases

    func testExtractMissingProperty() {
        let matcher = QueryMatcher()
        let conditions = ["nonexistent": AnyCodable("value")]

        struct Item {
            let existing: String
        }

        let item = Item(existing: "test")

        XCTAssertFalse(matcher.matches(item, conditions: conditions))
    }

    func testExtractNestedProperty() {
        let matcher = QueryMatcher()
        let conditions = ["name": AnyCodable("test")]

        struct Profile {
            let name: String
        }

        struct User {
            let profile: Profile
        }

        let user = User(profile: Profile(name: "test"))

        // Note: Current implementation doesn't support nested properties
        // This test documents current behavior
        XCTAssertFalse(matcher.matches(user, conditions: conditions))
    }

    func testExtractOptionalProperty() {
        let matcher = QueryMatcher()

        struct Item {
            let optional: String?
        }

        // Test exists with nil value
        let conditionsExists = ["optional": AnyCodable(["$exists": AnyCodable(false)])]
        let itemWithNil = Item(optional: nil)
        XCTAssertTrue(matcher.matches(itemWithNil, conditions: conditionsExists))

        // Test exists with non-nil value
        let conditionsExistsTrue = ["optional": AnyCodable(["$exists": AnyCodable(true)])]
        let itemWithValue = Item(optional: "value")
        XCTAssertTrue(matcher.matches(itemWithValue, conditions: conditionsExistsTrue))
    }

    // MARK: - Type Comparison Edge Cases

    func testCompareIntAndDouble() {
        let matcher = QueryMatcher()
        let conditions = ["value": AnyCodable(10.0)]

        struct Item {
            let value: Int
        }

        let item = Item(value: 10)

        // Should compare numbers regardless of Int/Double
        XCTAssertTrue(matcher.matches(item, conditions: conditions))
    }

    func testCompareDateTypes() {
        let matcher = QueryMatcher()
        let date1 = Date(timeIntervalSince1970: 1000)
        let date2 = Date(timeIntervalSince1970: 2000)

        let conditions = ["createdAt": AnyCodable(["$lt": AnyCodable(date2)])]

        struct Item {
            let createdAt: Date
        }

        let oldItem = Item(createdAt: date1)
        let newItem = Item(createdAt: date2)

        XCTAssertTrue(matcher.matches(oldItem, conditions: conditions))
        XCTAssertFalse(matcher.matches(newItem, conditions: conditions))
    }

    func testCompareWithNil() {
        let matcher = QueryMatcher()

        struct Item {
            let value: String?
        }

        // Test equality with nil
        let conditions = ["value": AnyCodable(["$exists": AnyCodable(false)])]
        let itemWithNil = Item(value: nil)
        let itemWithValue = Item(value: "test")

        XCTAssertTrue(matcher.matches(itemWithNil, conditions: conditions))
        XCTAssertFalse(matcher.matches(itemWithValue, conditions: conditions))
    }

    // MARK: - Array Operations

    func testInOperatorWithMixedTypes() {
        let matcher = QueryMatcher()
        let conditions = ["status": AnyCodable(["$in": AnyCodable([
            AnyCodable("active"),
            AnyCodable("pending"),
            AnyCodable("review")
        ])])]

        struct Item {
            let status: String
        }

        let active = Item(status: "active")
        let deleted = Item(status: "deleted")

        XCTAssertTrue(matcher.matches(active, conditions: conditions))
        XCTAssertFalse(matcher.matches(deleted, conditions: conditions))
    }

    func testInOperatorWithNumbers() {
        let matcher = QueryMatcher()
        let conditions = ["id": AnyCodable(["$in": AnyCodable([1, 2, 3])])]

        struct Item {
            let id: Int
        }

        let item1 = Item(id: 1)
        let item5 = Item(id: 5)

        XCTAssertTrue(matcher.matches(item1, conditions: conditions))
        XCTAssertFalse(matcher.matches(item5, conditions: conditions))
    }

    func testInOperatorWithEmptyArray() {
        let matcher = QueryMatcher()
        let conditions = ["status": AnyCodable(["$in": AnyCodable([AnyCodable]())])]

        struct Item {
            let status: String
        }

        let item = Item(status: "active")

        XCTAssertFalse(matcher.matches(item, conditions: conditions))
    }

    func testNotInOperatorWithNumbers() {
        let matcher = QueryMatcher()
        let conditions = ["id": AnyCodable(["$nin": AnyCodable([1, 2, 3])])]

        struct Item {
            let id: Int
        }

        let item1 = Item(id: 1)
        let item5 = Item(id: 5)

        XCTAssertFalse(matcher.matches(item1, conditions: conditions))
        XCTAssertTrue(matcher.matches(item5, conditions: conditions))
    }

    // MARK: - Multiple Operators

    func testMultipleOperatorsOnSameField() {
        let matcher = QueryMatcher()
        let conditions = ["age": AnyCodable([
            "$gte": AnyCodable(18),
            "$lte": AnyCodable(65)
        ])]

        struct Person {
            let age: Int
        }

        let young = Person(age: 25)
        let tooYoung = Person(age: 15)
        let tooOld = Person(age: 70)

        XCTAssertTrue(matcher.matches(young, conditions: conditions))
        XCTAssertFalse(matcher.matches(tooYoung, conditions: conditions))
        XCTAssertFalse(matcher.matches(tooOld, conditions: conditions))
    }

    // MARK: - Implicit AND

    func testImplicitAndBetweenFields() {
        let matcher = QueryMatcher()
        let conditions = [
            "status": AnyCodable("active"),
            "verified": AnyCodable(true),
            "count": AnyCodable(["$gt": AnyCodable(0)])
        ]

        struct Item {
            let status: String
            let verified: Bool
            let count: Int
        }

        let valid = Item(status: "active", verified: true, count: 5)
        let invalid1 = Item(status: "inactive", verified: true, count: 5)
        let invalid2 = Item(status: "active", verified: false, count: 5)
        let invalid3 = Item(status: "active", verified: true, count: 0)

        XCTAssertTrue(matcher.matches(valid, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid1, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid2, conditions: conditions))
        XCTAssertFalse(matcher.matches(invalid3, conditions: conditions))
    }

    // MARK: - Unknown Operators

    func testUnknownOperatorsAreIgnored() {
        let matcher = QueryMatcher()
        let conditions = [
            "value": AnyCodable([
                "$unknown": AnyCodable("ignored"),
                "$eq": AnyCodable(10)
            ])
        ]

        struct Item {
            let value: Int
        }

        let item = Item(value: 10)

        // Unknown operator should be ignored, $eq should work
        XCTAssertTrue(matcher.matches(item, conditions: conditions))
    }

    // MARK: - Number Type Conversions

    func testNumberTypeConversions() {
        let matcher = QueryMatcher()

        struct Item {
            let int8: Int8
            let int16: Int16
            let int32: Int32
            let int64: Int64
            let uint: UInt
            let uint8: UInt8
            let uint16: UInt16
            let uint32: UInt32
            let uint64: UInt64
            let float: Float
            let double: Double
        }

        let item = Item(
            int8: 10,
            int16: 100,
            int32: 1000,
            int64: 10000,
            uint: 5,
            uint8: 1,
            uint16: 10,
            uint32: 100,
            uint64: 1000,
            float: 3.14,
            double: 2.718
        )

        // Test that all numeric types can be compared
        XCTAssertTrue(matcher.matches(item, conditions: ["int8": AnyCodable(["$eq": AnyCodable(10)])]))
        XCTAssertTrue(matcher.matches(item, conditions: ["int16": AnyCodable(["$eq": AnyCodable(100)])]))
        XCTAssertTrue(matcher.matches(item, conditions: ["float": AnyCodable(["$gt": AnyCodable(3.0)])]))
    }
}
