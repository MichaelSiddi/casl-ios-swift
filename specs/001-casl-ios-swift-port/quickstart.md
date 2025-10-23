# CASL Swift Quickstart Guide

**Time to Complete**: 5-10 minutes
**Prerequisites**: Swift 5.10+, iOS 13+

## What is CASL?

CASL (pronounced "castle") is an authorization library that lets you define **what users can do** in your application. It's perfect for implementing permissions, access control, and authorization logic in a clean, declarative way.

**Key Benefits**:
- ✅ Type-safe permission checking
- ✅ Attribute-based access control (ABAC)
- ✅ Field-level permissions
- ✅ Serializable rules (sync with backend)
- ✅ Zero dependencies

---

## Installation

Add CASL to your Swift package dependencies:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/stalniy/casl-swift.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter: `https://github.com/stalniy/casl-swift.git`
3. Add to your target

---

## Basic Usage (5 minutes)

### Step 1: Import CASL

```swift
import CASL
```

### Step 2: Define Your Permissions

```swift
// Simple permissions for a blog app
let ability = AbilityBuilder()
    .can("read", "BlogPost")        // Anyone can read posts
    .can("create", "BlogPost")      // Anyone can create posts
    .cannot("delete", "BlogPost")   // No one can delete posts
    .build()
```

### Step 3: Check Permissions

```swift
// Check if user can perform action
if ability.can("read", "BlogPost") {
    print("✅ Can read blog posts")
}

if ability.cannot("delete", "BlogPost") {
    print("❌ Cannot delete blog posts")
}
```

**That's it!** You've just implemented basic authorization. 🎉

---

## Conditional Permissions (10 minutes)

Real apps need more than simple yes/no permissions. Let's add **attribute-based** rules that depend on data.

### Example: Users Can Only Edit Their Own Posts

```swift
// Define your data model
struct BlogPost {
    let id: String
    let authorId: String
    let title: String
    let published: Bool
}

// Current user ID
let currentUserId = "user-123"

// Define permissions with conditions
let ability = AbilityBuilder()
    .can("read", "BlogPost")
    .can("update", "BlogPost", conditions: [
        "authorId": AnyCodable(currentUserId)  // Only if author matches
    ])
    .cannot("delete", "BlogPost", conditions: [
        "published": AnyCodable(true)  // Can't delete if published
    ])
    .build()
```

### Check Permissions on Actual Objects

```swift
let myPost = BlogPost(
    id: "1",
    authorId: "user-123",  // Matches currentUserId
    title: "My Post",
    published: false
)

let otherPost = BlogPost(
    id: "2",
    authorId: "user-456",  // Different author
    title: "Other Post",
    published: true
)

// Check permissions
ability.can("update", myPost)     // ✅ true - you're the author
ability.can("update", otherPost)  // ❌ false - not your post
ability.can("delete", myPost)     // ✅ true - not published
ability.can("delete", otherPost)  // ❌ false - is published
```

---

## Field-Level Permissions

Control access to specific fields of your objects.

```swift
// Moderators can update "status" and "tags", but not "content"
let moderatorAbility = AbilityBuilder()
    .can("read", "BlogPost")
    .can("update", "BlogPost", fields: ["status", "tags"])
    .build()

// Check field permissions
moderatorAbility.can("update", post, field: "status")   // ✅ true
moderatorAbility.can("update", post, field: "tags")     // ✅ true
moderatorAbility.can("update", post, field: "content")  // ❌ false
```

---

## Common Patterns

### Pattern 1: Role-Based Access Control (RBAC)

```swift
enum UserRole {
    case guest
    case user
    case admin
}

func defineAbility(for role: UserRole) -> Ability {
    let builder = AbilityBuilder()

    switch role {
    case .guest:
        builder
            .can("read", "BlogPost")

    case .user:
        builder
            .can("read", "BlogPost")
            .can(["create", "update"], "BlogPost", conditions: [
                "authorId": AnyCodable(currentUserId)
            ])

    case .admin:
        builder
            .can("manage", "BlogPost")  // "manage" = all actions
    }

    return builder.build()
}

// Usage
let ability = defineAbility(for: .user)
```

### Pattern 2: Ownership-Based Access

```swift
protocol Ownable {
    var ownerId: String { get }
}

func userAbility(userId: String) -> Ability {
    AbilityBuilder()
        .can("read", "all")  // Read everything
        .can(["update", "delete"], "all", conditions: [
            "ownerId": AnyCodable(userId)  // Modify only owned items
        ])
        .build()
}
```

### Pattern 3: Advanced Conditions

```swift
let ability = AbilityBuilder()
    // Time-based: Can delete only if created within last hour
    .can("delete", "Comment", conditions: [
        "createdAt": [
            "$gt": AnyCodable(Date().addingTimeInterval(-3600))
        ]
    ])

    // Range-based: Can update posts with less than 100 likes
    .can("update", "BlogPost", conditions: [
        "likesCount": [
            "$lt": AnyCodable(100)
        ]
    ])

    // Array-based: Can moderate posts in specific categories
    .can("moderate", "BlogPost", conditions: [
        "category": [
            "$in": AnyCodable(["news", "politics"])
        ]
    ])
    .build()
```

---

## Query Operators

CASL supports MongoDB-style query operators:

| Operator | Example | Meaning |
|----------|---------|---------|
| `$eq` | `"status": "$eq": "draft"` | Equals |
| `$ne` | `"status": ["$ne": "deleted"]` | Not equals |
| `$gt` | `"age": ["$gt": 18]` | Greater than |
| `$gte` | `"age": ["$gte": 18]` | Greater than or equal |
| `$lt` | `"price": ["$lt": 100]` | Less than |
| `$lte` | `"price": ["$lte": 100]` | Less than or equal |
| `$in` | `"role": ["$in": ["admin", "mod"]]` | In array |
| `$nin` | `"status": ["$nin": ["banned"]]` | Not in array |
| `$exists` | `"email": ["$exists": true]` | Field exists |

---

## Serialization (Sync with Backend)

Share permissions between your iOS app and backend server.

### Export Rules to JSON

```swift
let ability = AbilityBuilder()
    .can("read", "BlogPost")
    .can("update", "BlogPost", conditions: ["authorId": userId])
    .build()

// Export to JSON
let encoder = JSONEncoder()
let jsonData = try encoder.encode(ability.exportRules())
let jsonString = String(data: jsonData, encoding: .utf8)
```

**Output**:
```json
[
  {
    "action": "read",
    "subject": "BlogPost"
  },
  {
    "action": "update",
    "subject": "BlogPost",
    "conditions": {
      "authorId": "user-123"
    }
  }
]
```

### Import Rules from JSON

```swift
// Receive JSON from server
let jsonData = """
[
  {"action": "read", "subject": "BlogPost"},
  {"action": "update", "subject": "BlogPost", "conditions": {"authorId": "user-123"}}
]
""".data(using: .utf8)!

// Decode rules
let decoder = JSONDecoder()
let rules = try decoder.decode([RawRule].self, from: jsonData)

// Create ability
let ability = Ability(rules: rules)
```

---

## Error Handling

Throw errors when permissions are denied:

```swift
do {
    try ForbiddenError.throwUnlessCan(ability, "delete", post)
    // Permission granted - proceed with deletion
    deletePost(post)
} catch let error as ForbiddenError {
    // Permission denied - show error
    showAlert(error.errorDescription)
    // "Cannot delete BlogPost"
}
```

---

## Dynamic Updates

Update permissions at runtime (e.g., after login):

```swift
// Create ability with guest permissions
let ability = Ability(rules: [
    RawRule(action: "read", subject: "BlogPost")
])

// Later, after user logs in...
Task {
    await ability.update(rules: [
        RawRule(action: "read", subject: "BlogPost"),
        RawRule(action: "create", subject: "BlogPost"),
        RawRule(action: "update", subject: "BlogPost", conditions: [
            "authorId": AnyCodable(currentUserId)
        ])
    ])
}
```

---

## SwiftUI Integration

Use CASL in your SwiftUI views:

```swift
struct PostView: View {
    let post: BlogPost
    let ability: Ability

    var body: some View {
        VStack {
            Text(post.title)

            if ability.can("update", post) {
                Button("Edit") {
                    editPost()
                }
            }

            if ability.can("delete", post) {
                Button("Delete", role: .destructive) {
                    deletePost()
                }
            }
        }
    }
}
```

### Custom View Modifier

```swift
extension View {
    func requiresPermission(
        _ ability: Ability,
        _ action: String,
        _ subject: Any
    ) -> some View {
        self.opacity(ability.can(action, subject) ? 1.0 : 0.3)
            .disabled(!ability.can(action, subject))
    }
}

// Usage
Button("Delete") { deletePost() }
    .requiresPermission(ability, "delete", post)
```

---

## Testing

Test your authorization logic:

```swift
import XCTest
@testable import YourApp

class PermissionTests: XCTestCase {
    func testUserCanReadAllPosts() {
        let ability = AbilityBuilder()
            .can("read", "BlogPost")
            .build()

        XCTAssertTrue(ability.can("read", "BlogPost"))
    }

    func testUserCanOnlyEditOwnPosts() {
        let ability = AbilityBuilder()
            .can("update", "BlogPost", conditions: [
                "authorId": AnyCodable("user-123")
            ])
            .build()

        let ownPost = BlogPost(id: "1", authorId: "user-123", title: "Mine")
        let otherPost = BlogPost(id: "2", authorId: "user-456", title: "Theirs")

        XCTAssertTrue(ability.can("update", ownPost))
        XCTAssertFalse(ability.can("update", otherPost))
    }
}
```

---

## Best Practices

### ✅ DO

- Define permissions based on user roles/context
- Use conditions for ownership checks
- Serialize rules from backend for consistency
- Test permission logic thoroughly
- Use field-level permissions for fine-grained control

### ❌ DON'T

- Hardcode user IDs in permission definitions
- Skip permission checks assuming something is "safe"
- Mix authorization logic with business logic
- Forget to handle permission errors gracefully
- Use string literals everywhere (define constants)

---

## Common Issues

### Issue: Permission check returns false unexpectedly

**Cause**: Conditions don't match object properties

**Solution**: Ensure property names match exactly:
```swift
// ❌ Wrong - property name mismatch
.can("update", "Post", conditions: ["author_id": userId])

// ✅ Correct - matches property name
.can("update", "Post", conditions: ["authorId": userId])
```

### Issue: Subject type not detected

**Cause**: Type detection failed

**Solution**: Implement `SubjectTypeProvider`:
```swift
class BlogPost: SubjectTypeProvider {
    static let subjectType = "BlogPost"
    // ...
}
```

### Issue: Field permissions don't work

**Cause**: Not specifying field in check

**Solution**: Pass field parameter:
```swift
// ❌ Wrong - no field specified
ability.can("update", post)

// ✅ Correct - field specified
ability.can("update", post, field: "title")
```

---

## Next Steps

Now that you know the basics:

1. **Read the API Reference**: [contracts/api-reference.md](contracts/api-reference.md)
2. **Explore Advanced Features**: Custom matchers, aliases, optimization
3. **Check Examples**: See real-world integration patterns
4. **Join the Community**: Ask questions, share solutions

---

## Quick Reference

```swift
// Define permissions
let ability = AbilityBuilder()
    .can(action, subject)
    .can(action, subject, conditions: [...])
    .can(action, subject, fields: [...])
    .cannot(action, subject)
    .build()

// Check permissions
ability.can(action, subject)
ability.cannot(action, subject)
ability.can(action, subject, field: "property")

// Find matching rule
let rule = ability.relevantRuleFor(action, subject)

// Throw on denial
try ForbiddenError.throwUnlessCan(ability, action, subject)

// Update rules
await ability.update(rules: newRules)

// Serialize
let json = try encoder.encode(ability.exportRules())
```

---

**Questions?** Check the full [API Reference](contracts/api-reference.md) or the [Data Model](data-model.md) documentation.
