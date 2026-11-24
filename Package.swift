// swift-tools-version: 6.2
import PackageDescription

/// Compiler settings shared by every target. See docs/standards.md §1.
let strict: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .treatAllWarnings(as: .error),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

/// UI targets run on the main actor by default.
let uiSettings: [SwiftSetting] = strict + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "cmux-radar",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RadarCore", targets: ["RadarCore"]),
        .library(name: "RadarCmux", targets: ["RadarCmux"]),
        .library(name: "RadarUI", targets: ["RadarUI"]),
        .executable(name: "RadarCatalog", targets: ["RadarCatalog"]),
    ],
    dependencies: [
        .package(url: "https://github.com/x-sheep/swift-property-based", exact: "2.0.1"),
    ],
    targets: [
        // Pure domain logic. No UI, no I/O.
        .target(name: "RadarCore", swiftSettings: strict),

        // Decodes cmux frames and Feed items into RadarCore events. Pure: no sockets, no files.
        .target(name: "RadarCmux", dependencies: ["RadarCore"], swiftSettings: strict),

        // Dumb SwiftUI components. Know only their inputs.
        .target(name: "RadarUI", swiftSettings: uiSettings),

        // Every component state as data. Drives the catalog and the snapshot tests.
        .target(name: "RadarStories", dependencies: ["RadarUI"], swiftSettings: uiSettings),

        // Component catalog app — the project's Storybook. `make catalog`.
        .executableTarget(name: "RadarCatalog", dependencies: ["RadarUI", "RadarStories"], swiftSettings: uiSettings),

        // Snapshot testing without XCTest (see docs/adr/0002).
        .target(name: "RadarSnapshot", swiftSettings: strict),

        .testTarget(
            name: "RadarCoreTests",
            dependencies: [
                "RadarCore",
                .product(name: "PropertyBased", package: "swift-property-based"),
            ],
            swiftSettings: strict,
        ),

        .testTarget(
            name: "RadarCmuxTests",
            dependencies: [
                "RadarCmux",
                "RadarCore",
                .product(name: "PropertyBased", package: "swift-property-based"),
            ],
            swiftSettings: strict,
        ),

        .testTarget(
            name: "RadarSnapshotTests",
            dependencies: [
                "RadarSnapshot",
                .product(name: "PropertyBased", package: "swift-property-based"),
            ],
            swiftSettings: strict,
        ),

        .testTarget(
            name: "RadarUITests",
            dependencies: [
                "RadarUI",
                "RadarStories",
                "RadarSnapshot",
                .product(name: "PropertyBased", package: "swift-property-based"),
            ],
            exclude: ["__Snapshots__"],
            swiftSettings: strict,
        ),
    ],
)
