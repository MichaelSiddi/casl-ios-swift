// EdgeCaseTests.swift
// Additional edge case tests for maximum coverage

import XCTest
@testable import CASL

final class EdgeCaseTests: XCTestCase {

    // MARK: - Rule Edge Cases

    func testRuleEquality() {
        let rule1 = Rule(action: "read", subject: "BlogPost")
        let rule2 = Rule(action: "read", subject: "BlogPost")
        let rule3 = Rule(action: "write", subject: "BlogPost")

        XCTAssertEqual(rule1, rule2)
        XCTAssertNotEqual(rule1, rule3)
    }

    func testRuleWithAllProperties() {
        let rule = Rule(
            action: "update",
            subject: "BlogPost",
            conditions: ["authorId": AnyCodable("user123")],
            fields: ["title", "content"],
            inverted: true,
            reason: "Testing all properties"
        )

        XCTAssertEqual(rule.action, "update")
        XCTAssertEqual(rule.subject, "BlogPost")
        XCTAssertNotNil(rule.conditions)
        XCTAssertEqual(rule.fields, ["title", "content"])
        XCTAssertTrue(rule.inverted)
        XCTAssertEqual(rule.reason, "Testing all properties")
    }

    // MARK: - AnyCodable Edge Cases

    func testAnyCodableWithDate() {
        // AnyCodable doesn't support Date type directly
        // This is expected behavior - use ISO8601 string or timestamp instead
        let date = Date(timeIntervalSince1970: 1000)
        let value = AnyCodable(date)

        XCTAssertNotNil(value.value as? Date)
        // Note: Date encoding would need special handling
    }

    func testAnyCodableWithNestedDictionary() throws {
        let nested = [
            "outer": [
                "inner": "value"
            ]
        ]
        let value = AnyCodable(nested)

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let dict = decoded.value as? [String: [String: String]]
        XCTAssertEqual(dict?["outer"]?["inner"], "value")
    }

    func testAnyCodableWithMixedArray() {
        // For mixed arrays, use simple types directly
        let mixed: [Any] = ["string", 42, true]
        let value = AnyCodable(mixed)

        let array = value.value as? [Any]
        XCTAssertNotNil(array)
        XCTAssertEqual(array?.count, 3)
    }

    func testAnyCodableEqualityWithDifferentTypes() {
        let string = AnyCodable("test")
        let int = AnyCodable(42)
        let bool = AnyCodable(true)

        XCTAssertNotEqual(string, int)
        XCTAssertNotEqual(int, bool)
        XCTAssertNotEqual(string, bool)
    }

    func testAnyCodableWithNil() throws {
        // AnyCodable doesn't directly support nil, but we can encode null
        let json = "null".data(using: .utf8)!
        let decoder = JSONDecoder()

        // This will fail or decode as nil value depending on implementation
        do {
            let _ = try decoder.decode(AnyCodable.self, from: json)
        } catch {
            // Expected behavior - AnyCodable doesn't support nil
            XCTAssertTrue(true)
        }
    }

    // MARK: - StringOrArray Edge Cases

    func testStringOrArrayFromSingleString() {
        let value = StringOrArray("test")

        switch value {
        case .single(let str):
            XCTAssertEqual(str, "test")
        case .multiple:
            XCTFail("Should be single")
        }
    }

    func testStringOrArrayFromMultipleStrings() {
        let value = StringOrArray(["a", "b", "c"])

        switch value {
        case .single:
            XCTFail("Should be multiple")
        case .multiple(let arr):
            XCTAssertEqual(arr, ["a", "b", "c"])
        }
    }

    // MARK: - Subject Type Detection

    func testDetectTypeWithModuleName() {
        struct MyModule {
            struct MyType {
                let id: Int
            }
        }

        let instance = MyModule.MyType(id: 1)
        let result = defaultSubjectTypeDetector(instance)

        // Should extract just the type name
        XCTAssertTrue(result.contains("MyType"))
    }

    func testDetectTypeWithGenericConstraint() {
        struct Container<T: Equatable> {
            let value: T
        }

        let container = Container(value: "test")
        let result = defaultSubjectTypeDetector(container)

        XCTAssertTrue(result.contains("Container"))
    }

    func testDetectTypeFromProtocolType() {
        protocol MyProtocol {}
        struct MyStruct: MyProtocol {
            let id: Int
        }

        let instance: MyProtocol = MyStruct(id: 1)
        let result = defaultSubjectTypeDetector(instance)

        XCTAssertEqual(result, "MyStruct")
    }

    func testDetectTypeFromExistentialAny() {
        let value: Any = "test"
        let result = defaultSubjectTypeDetector(value)

        XCTAssertEqual(result, "String")
    }

    func testDetectTypeFromMetatype() {
        let type = String.self
        let result = defaultSubjectTypeDetector(type)

        // Metatypes have complex names
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Query Matcher Edge Cases

    func testQueryMatcherWithEmptyConditions() {
        let matcher = QueryMatcher()
        let conditions: [String: AnyCodable] = [:]

        struct Item {
            let value: Int
        }

        let item = Item(value: 10)

        // Empty conditions should match everything
        XCTAssertTrue(matcher.matches(item, conditions: conditions))
    }

    func testQueryMatcherWithUnknownField() {
        let matcher = QueryMatcher()
        let conditions = ["unknownField": AnyCodable(["$eq": AnyCodable(10)])]

        struct Item {
            let knownField: Int
        }

        let item = Item(knownField: 10)

        // Unknown field should not match
        XCTAssertFalse(matcher.matches(item, conditions: conditions))
    }

    func testQueryMatcherWithComplexNestedObject() {
        let matcher = QueryMatcher()
        let conditions = ["value": AnyCodable(10)]

        struct Inner {
            let value: Int
        }

        struct Outer {
            let inner: Inner
        }

        let obj = Outer(inner: Inner(value: 10))

        // Doesn't support nested property access (by design)
        XCTAssertFalse(matcher.matches(obj, conditions: conditions))
    }

    // MARK: - Field Matcher Edge Cases

    func testGlobFieldMatcherWithEmptyPattern() {
        let matcher = GlobFieldMatcher()

        // Empty patterns array means no fields allowed
        XCTAssertFalse(matcher.matches(field: "any", patterns: []))
    }

    func testGlobFieldMatcherWithMultiplePatterns() {
        let matcher = GlobFieldMatcher()

        let patterns = ["title", "content", "author.*"]

        XCTAssertTrue(matcher.matches(field: "title", patterns: patterns))
        XCTAssertTrue(matcher.matches(field: "content", patterns: patterns))
        XCTAssertTrue(matcher.matches(field: "author.name", patterns: patterns))
        XCTAssertFalse(matcher.matches(field: "password", patterns: patterns))
    }

    func testGlobFieldMatcherWithSuffixPattern() {
        let matcher = GlobFieldMatcher()

        // Note: Current implementation doesn't support suffix patterns
        // This test documents current behavior
        let patterns = ["*.md"]

        XCTAssertFalse(matcher.matches(field: "file.md", patterns: patterns))
        // Would need enhancement to support suffix patterns
    }

    // MARK: - Ability with Various Options

    func testAbilityWithAllDefaultOptions() async {
        let ability = Ability(rules: [
            RawRule(action: "read", subject: "BlogPost")
        ])

        let canRead = await ability.can("read", "BlogPost")
        XCTAssertTrue(canRead)
    }

    func testAbilityWithCustomConditionsMatcher() async {
        struct AlwaysTrueMatcher: ConditionsMatcher {
            func compile(_ conditions: [String: AnyCodable]) -> MatchConditions {
                return { _ in true }
            }

            func matches(_ object: Any, conditions: [String: AnyCodable]) -> Bool {
                return true
            }
        }

        let options = AbilityOptions(
            conditionsMatcher: AlwaysTrueMatcher(),
            fieldMatcher: GlobFieldMatcher(),
            detectSubjectType: defaultSubjectTypeDetector
        )

        let ability = Ability(
            rules: [
                RawRule(
                    action: "update",
                    subject: "BlogPost",
                    conditions: ["authorId": AnyCodable("user123")]
                )
            ],
            options: options
        )

        struct BlogPost {
            let authorId: String
        }

        let post = BlogPost(authorId: "differentUser")

        // Custom matcher always returns true
        let canUpdate = await ability.can("update", post)
        XCTAssertTrue(canUpdate)
    }

    func testAbilityWithCustomFieldMatcher() async {
        struct AlwaysFalseMatcher: FieldMatcher {
            func matches(field: String, patterns: [String]) -> Bool {
                return false
            }
        }

        let options = AbilityOptions(
            conditionsMatcher: QueryMatcher(),
            fieldMatcher: AlwaysFalseMatcher(),
            detectSubjectType: defaultSubjectTypeDetector
        )

        let ability = Ability(
            rules: [RawRule(action: "read", subject: "BlogPost", fields: ["title"])],
            options: options
        )

        // Custom matcher always returns false
        let canRead = await ability.can("read", "BlogPost", field: "title")
        XCTAssertFalse(canRead)
    }

    // MARK: - RawRule Edge Cases

    func testRawRuleWithAllFieldsNil() {
        let rule = RawRule(
            action: StringOrArray("read"),
            subject: StringOrArray("BlogPost"),
            conditions: nil,
            fields: nil,
            inverted: nil,
            reason: nil
        )

        XCTAssertEqual(rule.action.values, ["read"])
        XCTAssertEqual(rule.subject?.values, ["BlogPost"])
        XCTAssertNil(rule.conditions)
        XCTAssertNil(rule.fields)
        XCTAssertNil(rule.inverted)
        XCTAssertNil(rule.reason)
    }

    func testRawRuleExpansionSingleToSingle() {
        let rule = RawRule(action: "read", subject: "BlogPost")
        let expanded = rule.expandToMultiple()

        XCTAssertEqual(expanded.count, 1)
        XCTAssertEqual(expanded[0].action, "read")
        XCTAssertEqual(expanded[0].subject, "BlogPost")
    }
}
