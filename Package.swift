// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-stack-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Stack Primitives",
            targets: ["Stack Primitives"]
        ),
        .library(
            name: "Stack Primitives Core",
            targets: ["Stack Primitives Core"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-collection-primitives"),
        .package(path: "../swift-property-primitives"),
        .package(path: "../swift-range-primitives"),
        .package(path: "../swift-sequence-primitives"),
    ],
    targets: [
        // Core types with ~Copyable support (Stack, Inline, Small, Bounded structs)
        .target(
            name: "Stack Primitives Core",
            dependencies: [
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
                .product(name: "Storage Primitives", package: "swift-storage-primitives"),
            ]
        ),
        // Per-variant modules: Protocol conformances (Element: Copyable)
        // Separate modules to avoid constraint poisoning on Core types
        .target(
            name: "Stack Dynamic Primitives",  // Base Stack (growable, heap)
            dependencies: [
                "Stack Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
            ]
        ),
        .target(
            name: "Stack Bounded Primitives",  // Fixed-capacity heap stack
            dependencies: [
                "Stack Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
            ]
        ),
        .target(
            name: "Stack Inline Primitives",  // Fixed-capacity inline stack
            dependencies: [
                "Stack Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
            ]
        ),
        .target(
            name: "Stack Small Primitives",  // Small-buffer optimization stack
            dependencies: [
                "Stack Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Range Primitives", package: "swift-range-primitives"),
            ]
        ),
        // Public: Re-exports Core and all variant modules
        .target(
            name: "Stack Primitives",
            dependencies: [
                "Stack Primitives Core",
                "Stack Dynamic Primitives",
                "Stack Bounded Primitives",
                "Stack Inline Primitives",
                "Stack Small Primitives",
            ]
        ),
        .testTarget(
            name: "Stack Primitives Tests",
            dependencies: ["Stack Primitives"]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableExperimentalFeature("Lifetimes"),
        .strictMemorySafety()
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
