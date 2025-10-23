// RuleIndexTests.swift
// Tests for RuleIndex operations

import XCTest
@testable import CASL

final class RuleIndexTests: XCTestCase {

    // MARK: - Initialization

    func testRuleIndexInitEmpty() async {
        let index = RuleIndex()
        let rules = await index.rules

        XCTAssertEqual(rules.count, 0)
    }

    func testRuleIndexInitWithRules() async {
        let rules = [
            Rule(action: "read", subject: "BlogPost"),
            Rule(action: "write", subject: "Comment")
        ]

        let index = RuleIndex(rules: rules)
        let storedRules = await index.rules

        XCTAssertEqual(storedRules.count, 2)
        XCTAssertEqual(storedRules[0].action, "read")
        XCTAssertEqual(storedRules[1].action, "write")
    }

    func testRuleIndexInitWithOptions() async {
        let options = AbilityOptions(
            conditionsMatcher: QueryMatcher(),
            fieldMatcher: GlobFieldMatcher(),
            detectSubjectType: { _ in "CustomType" }
        )

        let index = RuleIndex(rules: [], options: options)
        let rules = await index.rules

        XCTAssertEqual(rules.count, 0)
    }

    // MARK: - Update Operations

    func testRuleIndexUpdate() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost")
        ])

        // Verify initial state
        var rules = await index.rules
        XCTAssertEqual(rules.count, 1)

        // Update rules
        let newRules = [
            Rule(action: "write", subject: "Comment"),
            Rule(action: "delete", subject: "User")
        ]
        await index.update(rules: newRules)

        // Verify updated state
        rules = await index.rules
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[0].action, "write")
        XCTAssertEqual(rules[1].action, "delete")
    }

    func testRuleIndexUpdateToEmpty() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost"),
            Rule(action: "write", subject: "Comment")
        ])

        await index.update(rules: [])

        let rules = await index.rules
        XCTAssertEqual(rules.count, 0)
    }

    func testRuleIndexUpdateWithManyRules() async {
        let index = RuleIndex(rules: [])

        // Create 100 rules
        var newRules: [Rule] = []
        for i in 0..<100 {
            newRules.append(Rule(action: "action\(i)", subject: "Subject\(i)"))
        }

        await index.update(rules: newRules)

        let rules = await index.rules
        XCTAssertEqual(rules.count, 100)
    }

    // MARK: - findMatchingRules

    func testFindMatchingRulesBasic() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost"),
            Rule(action: "write", subject: "BlogPost"),
            Rule(action: "read", subject: "Comment")
        ])

        let matching = await index.findMatchingRules(
            action: "read",
            subjectType: "BlogPost",
            field: nil
        )

        XCTAssertEqual(matching.count, 1)
        XCTAssertEqual(matching[0].action, "read")
        XCTAssertEqual(matching[0].subject, "BlogPost")
    }

    func testFindMatchingRulesWithWildcard() async {
        let index = RuleIndex(rules: [
            Rule(action: "manage", subject: "BlogPost"),
            Rule(action: "read", subject: "all")
        ])

        // manage should match any action
        let manageMatch = await index.findMatchingRules(
            action: "delete",
            subjectType: "BlogPost",
            field: nil
        )
        XCTAssertEqual(manageMatch.count, 1)

        // all should match any subject
        let allMatch = await index.findMatchingRules(
            action: "read",
            subjectType: "Comment",
            field: nil
        )
        XCTAssertEqual(allMatch.count, 1)
    }

    func testFindMatchingRulesWithFields() async {
        let options = AbilityOptions(
            conditionsMatcher: QueryMatcher(),
            fieldMatcher: GlobFieldMatcher(),
            detectSubjectType: defaultSubjectTypeDetector
        )

        let index = RuleIndex(
            rules: [
                Rule(action: "read", subject: "BlogPost", fields: ["title", "content"]),
                Rule(action: "read", subject: "BlogPost")
            ],
            options: options
        )

        let matchWithField = await index.findMatchingRules(
            action: "read",
            subjectType: "BlogPost",
            field: "title"
        )

        // First rule has field restrictions and should match "title"
        XCTAssertEqual(matchWithField.count, 2)
    }

    func testFindMatchingRulesNoMatch() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost")
        ])

        let noMatch = await index.findMatchingRules(
            action: "write",
            subjectType: "Comment",
            field: nil
        )

        XCTAssertEqual(noMatch.count, 0)
    }

    func testFindMatchingRulesMultipleMatches() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost"),
            Rule(action: "read", subject: "all"),
            Rule(action: "manage", subject: "BlogPost")
        ])

        let matches = await index.findMatchingRules(
            action: "read",
            subjectType: "BlogPost",
            field: nil
        )

        // All three rules should match:
        // 1. Exact action + subject match
        // 2. action match + "all" subject
        // 3. "manage" action + subject match
        XCTAssertEqual(matches.count, 3)
    }

    // MARK: - Thread Safety

    func testRuleIndexConcurrentReads() async {
        let index = RuleIndex(rules: [
            Rule(action: "read", subject: "BlogPost")
        ])

        // Perform multiple concurrent reads
        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    let rules = await index.rules
                    return rules.count
                }
            }

            var totalReads = 0
            for await count in group {
                totalReads += 1
                XCTAssertEqual(count, 1)
            }
            XCTAssertEqual(totalReads, 100)
        }
    }

    func testRuleIndexSequentialUpdates() async {
        let index = RuleIndex(rules: [])

        // Perform sequential updates
        for i in 0..<10 {
            await index.update(rules: [
                Rule(action: "action\(i)", subject: "Subject")
            ])

            let rules = await index.rules
            XCTAssertEqual(rules.count, 1)
            XCTAssertEqual(rules[0].action, "action\(i)")
        }
    }

    // MARK: - Rule Ordering

    func testRuleIndexMaintainsInsertionOrder() async {
        let rules = [
            Rule(action: "first", subject: "A"),
            Rule(action: "second", subject: "B"),
            Rule(action: "third", subject: "C")
        ]

        let index = RuleIndex(rules: rules)
        let storedRules = await index.rules

        XCTAssertEqual(storedRules[0].action, "first")
        XCTAssertEqual(storedRules[1].action, "second")
        XCTAssertEqual(storedRules[2].action, "third")
    }
}
