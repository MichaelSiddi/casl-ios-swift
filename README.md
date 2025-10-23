# CASL Swift

**Isomorphic authorization library for iOS, macOS, watchOS, and tvOS**

CASL (pronounced "castle") is a Swift port of the popular [CASL JavaScript library](https://casl.js.org), providing declarative authorization and permission management for Apple platforms.

## Features

- ✅ **Declarative permissions** - Define what users can do with clean, readable rules
- ✅ **Attribute-based access control (ABAC)** - Conditional permissions based on resource properties
- ✅ **Field-level permissions** - Control access to specific fields of resources
- ✅ **Type-safe** - Leverages Swift's type system for compile-time safety
- ✅ **Thread-safe** - Built with Swift actors for concurrent permission checking
- ✅ **Zero dependencies** - Pure Swift with no third-party dependencies
- ✅ **Serializable** - JSON-compatible rules for isomorphic authorization
- ✅ **Performant** - Sub-millisecond permission checks

## Requirements

- Swift 5.10+
- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+

## Installation

### Swift Package Manager

Add CASL to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/michaelsiddi/casl-swift.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Packages...
2. Enter: `https://github.com/michaelsiddi/casl-swift.git`

## Quick Start

```swift
import CASL

// Define permissions
let ability = AbilityBuilder()
    .can("read", "BlogPost")
    .can("update", "BlogPost", conditions: ["authorId": userId])
    .cannot("delete", "BlogPost", conditions: ["published": true])
    .build()

// Check permissions
if ability.can("read", post) {
    // Allow access
}

if ability.cannot("delete", post) {
    // Deny access
}
```

## Documentation

- [Quick Start Guide](specs/001-casl-ios-swift-port/quickstart.md)
- [API Reference](specs/001-casl-ios-swift-port/contracts/api-reference.md)
- [Implementation Plan](specs/001-casl-ios-swift-port/plan.md)

## Examples

### Role-Based Access Control (RBAC)

```swift
func defineAbility(for role: UserRole) -> Ability {
    let builder = AbilityBuilder()

    switch role {
    case .guest:
        builder.can("read", "BlogPost")
    case .user:
        builder
            .can("read", "BlogPost")
            .can(["create", "update"], "BlogPost", conditions: ["authorId": userId])
    case .admin:
        builder.can("manage", "BlogPost") // All actions
    }

    return builder.build()
}
```

### Attribute-Based Access Control (ABAC)

```swift
let ability = AbilityBuilder()
    // Users can update their own posts
    .can("update", "BlogPost", conditions: ["authorId": currentUserId])

    // Users can delete posts created within last hour
    .can("delete", "Comment", conditions: [
        "createdAt": ["$gt": Date().addingTimeInterval(-3600)]
    ])

    // Moderators can update specific fields
    .can("update", "BlogPost", fields: ["status", "tags"])
    .build()
```

### Field-Level Permissions

```swift
// Check field-level access
if ability.can("update", post, field: "status") {
    // Can update status field
}

if ability.cannot("update", post, field: "content") {
    // Cannot update content field
}
```

### Serialization (Isomorphic Authorization)

```swift
// Export rules to JSON
let encoder = JSONEncoder()
let jsonData = try encoder.encode(ability.exportRules())

// Import rules from JSON (e.g., from server)
let decoder = JSONDecoder()
let rules = try decoder.decode([RawRule].self, from: jsonData)
let ability = Ability(rules: rules)
```

## Testing

```bash
swift test
```

## Performance

CASL Swift is designed for high performance:

- Permission checks: <1ms for 100 rules
- Serialization: <10ms for 100 rules
- Concurrent checks: 1000+ simultaneous operations

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

CASL Swift is a port of [CASL JavaScript](https://casl.js.org) by [Sergii Stotskyi](https://github.com/stalniy).

## Related Projects

- [CASL JavaScript](https://casl.js.org) - Original JavaScript implementation
- [@casl/ability](https://www.npmjs.com/package/@casl/ability) - Core JavaScript package
- [CASL Examples](https://github.com/stalniy/casl-examples) - JavaScript examples

## Support

- [GitHub Discussions](https://github.com/stalniy/casl/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/casl)

---

**Made with ❤️ for the Swift community**
