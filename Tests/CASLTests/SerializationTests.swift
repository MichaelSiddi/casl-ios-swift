// SerializationTests.swift
// Tests for JSON serialization and deserialization

import XCTest
@testable import CASL

final class SerializationTests: XCTestCase {

    // MARK: - RawRule Serialization

    func testRawRuleEncodingSimple() throws {
        let rule = RawRule(action: "read", subject: "BlogPost")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(rule)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"action\""), "Should encode action")
        XCTAssertTrue(json.contains("\"subject\""), "Should encode subject")
    }

    func testRawRuleDecodingSimple() throws {
        let json = """
        {
            "action": "read",
            "subject": "BlogPost"
        }
        """

        let decoder = JSONDecoder()
        let rule = try decoder.decode(RawRule.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(rule.action.values, ["read"])
        XCTAssertEqual(rule.subject?.values, ["BlogPost"])
    }

    func testRawRuleWithConditions() throws {
        let rule = RawRule(
            action: "update",
            subject: "BlogPost",
            conditions: ["authorId": AnyCodable("user123")],
            inverted: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawRule.self, from: data)

        XCTAssertEqual(decoded.action.values, ["update"])
        XCTAssertEqual(decoded.subject?.values, ["BlogPost"])
        XCTAssertNotNil(decoded.conditions)
        XCTAssertEqual(decoded.conditions?["authorId"]?.value as? String, "user123")
    }

    func testRawRuleWithFields() throws {
        let rule = RawRule(
            action: "read",
            subject: "User",
            fields: ["name", "email"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawRule.self, from: data)

        XCTAssertEqual(decoded.fields?.values, ["name", "email"])
    }

    func testRawRuleWithArrayActions() throws {
        let rule = RawRule(
            action: StringOrArray(["read", "write"]),
            subject: StringOrArray("BlogPost")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawRule.self, from: data)

        XCTAssertEqual(decoded.action.values, ["read", "write"])
    }

    func testRawRuleWithInvertedFlag() throws {
        let rule = RawRule(action: "delete", subject: "BlogPost", inverted: true)

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawRule.self, from: data)

        XCTAssertEqual(decoded.inverted, true)
    }

    func testRawRuleWithReason() throws {
        let rule = RawRule(
            action: "delete",
            subject: "BlogPost",
            reason: "Only admins can delete published posts"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RawRule.self, from: data)

        XCTAssertEqual(decoded.reason, "Only admins can delete published posts")
    }

    // MARK: - Ability Export/Import

    func testAbilityExportRules() async {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .can("update", "BlogPost", conditions: ["authorId": AnyCodable("user123")])
            .cannot("delete", "BlogPost")
            .build()

        let rules = await ability.exportRules()

        XCTAssertEqual(rules.count, 3)
        XCTAssertEqual(rules[0].action.values, ["read"])
        XCTAssertEqual(rules[1].action.values, ["update"])
        XCTAssertEqual(rules[2].action.values, ["delete"])
        XCTAssertEqual(rules[2].inverted, true)
    }

    func testAbilityExportAndImport() async throws {
        let original = AbilityBuilder()
            .can("read", "BlogPost")
            .can("update", "BlogPost", conditions: ["authorId": AnyCodable("user123")])
            .build()

        // Export
        let rules = await original.exportRules()

        // Serialize
        let encoder = JSONEncoder()
        let data = try encoder.encode(rules)

        // Deserialize
        let decoder = JSONDecoder()
        let decodedRules = try decoder.decode([RawRule].self, from: data)

        // Import
        let imported = Ability(rules: decodedRules)

        // Verify behavior is identical
        let canRead = await imported.can("read", "BlogPost")
        XCTAssertTrue(canRead)
    }

    // MARK: - AnyCodable Tests

    func testAnyCodableWithString() throws {
        let value = AnyCodable("hello")

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? String, "hello")
    }

    func testAnyCodableWithInt() throws {
        let value = AnyCodable(42)

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func testAnyCodableWithDouble() throws {
        let value = AnyCodable(3.14)

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Double, 3.14)
    }

    func testAnyCodableWithBool() throws {
        let value = AnyCodable(true)

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        XCTAssertEqual(decoded.value as? Bool, true)
    }

    func testAnyCodableWithArray() throws {
        let value = AnyCodable(["a", "b", "c"])

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let array = decoded.value as? [String]
        XCTAssertEqual(array, ["a", "b", "c"])
    }

    func testAnyCodableWithDictionary() throws {
        let value = AnyCodable(["key": "value"])

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AnyCodable.self, from: data)

        let dict = decoded.value as? [String: String]
        XCTAssertEqual(dict?["key"], "value")
    }

    func testAnyCodableEquality() {
        let a = AnyCodable("test")
        let b = AnyCodable("test")
        let c = AnyCodable("other")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - StringOrArray Tests

    func testStringOrArraySingle() throws {
        let value = StringOrArray.single("test")

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StringOrArray.self, from: data)

        XCTAssertEqual(decoded.values, ["test"])
    }

    func testStringOrArrayMultiple() throws {
        let value = StringOrArray.multiple(["a", "b", "c"])

        let encoder = JSONEncoder()
        let data = try encoder.encode(value)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StringOrArray.self, from: data)

        XCTAssertEqual(decoded.values, ["a", "b", "c"])
    }

    func testStringOrArrayInitWithString() {
        let value = StringOrArray("test")
        XCTAssertEqual(value.values, ["test"])
    }

    func testStringOrArrayInitWithArray() {
        let value = StringOrArray(["a", "b"])
        XCTAssertEqual(value.values, ["a", "b"])
    }

    func testStringOrArrayEquality() {
        let a = StringOrArray("test")
        let b = StringOrArray(["test"])
        let c = StringOrArray(["a", "b"])

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
