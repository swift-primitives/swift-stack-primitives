// swift-tools-version: 6.3.1

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
        .library(
            name: "Stack Dynamic Primitives",
            targets: ["Stack Dynamic Primitives"]
        ),
        .library(
            name: "Stack Bounded Primitives",
            targets: ["Stack Bounded Primitives"]
        ),
        .library(
            name: "Stack Static Primitives",
            targets: ["Stack Static Primitives"]
        ),
        .library(
            name: "Stack Small Primitives",
            targets: ["Stack Small Primitives"]
        ),
        .library(
            name: "Stack Primitives Test Support",
            targets: ["Stack Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-finite-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Core
        .target(
            name: "Stack Primitives Core",
            dependencies: [
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
            ]
        ),

        // MARK: - Dynamic
        .target(
            name: "Stack Dynamic Primitives",
            dependencies: [
                "Stack Primitives Core",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Bounded
        .target(
            name: "Stack Bounded Primitives",
            dependencies: [
                "Stack Primitives Core",
                "Stack Dynamic Primitives",
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Static
        .target(
            name: "Stack Static Primitives",
            dependencies: [
                "Stack Primitives Core",
                "Stack Dynamic Primitives",
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),

        // MARK: - Small
        .target(
            name: "Stack Small Primitives",
            dependencies: [
                "Stack Primitives Core",
                "Stack Dynamic Primitives",
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Collection Primitives", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Stack Primitives",
            dependencies: [
                "Stack Primitives Core",
                "Stack Dynamic Primitives",
                "Stack Bounded Primitives",
                "Stack Static Primitives",
                "Stack Small Primitives",
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "Stack Primitives Tests",
            dependencies: [
                "Stack Primitives",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Stack Primitives Test Support",
            dependencies: [
                "Stack Primitives",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
                .product(name: "Collection Primitives Test Support", package: "swift-collection-primitives"),
                .product(name: "Sequence Primitives Test Support", package: "swift-sequence-primitives"),
                .product(name: "Finite Primitives Test Support", package: "swift-finite-primitives"),
            ],
            path: "Tests/Support"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
