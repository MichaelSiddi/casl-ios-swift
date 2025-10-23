// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CASL",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        // Main CASL library
        .library(
            name: "CASL",
            targets: ["CASL"]
        ),
    ],
    dependencies: [
        // No external dependencies - pure Swift implementation
    ],
    targets: [
        // Core CASL target
        .target(
            name: "CASL",
            dependencies: [],
            path: "Sources/CASL",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        // Test target
        .testTarget(
            name: "CASLTests",
            dependencies: ["CASL"],
            path: "Tests/CASLTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
