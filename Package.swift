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
        // MARK: - Base (ADT-tower W2 shape: carrier `__Stack<S>` + front doors
        //          `Stack<E>` (canonical) and `Stack<E>.Bounded` (capacity twin))
        .library(name: "Stack Primitive", targets: ["Stack Primitive"]),
        .library(name: "Stack Primitives", targets: ["Stack Primitives"]),

        // MARK: - Test Support
        .library(name: "Stack Primitives Test Support", targets: ["Stack Primitives Test Support"]),

        // NOTE (ADT-tower W2, 2026-07-02): the hand-written `Stack.Bounded` TYPE
        // targets (`Stack Bounded Primitive` / `Stack Bounded Primitives`) are
        // DELETED. `.Bounded` is now the capacity-twin front-door alias on the
        // carrier (Stack.Bounded.swift; the 2026-06-23 directive, §9.6.4).
    ],
    dependencies: [
        // Carrier + front doors (Stack Primitive):
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-storage-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
        // Test support:
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-input-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Carrier + front doors (the ADT-tower W2 core)
        .target(
            name: "Stack Primitive",
            dependencies: [
                // Seams (D3): the generic mutate + observability surfaces the ops ride.
                .product(name: "Store Protocol Primitives", package: "swift-storage-primitives"),
                .product(name: "Buffer Protocol Primitives", package: "swift-buffer-primitives"),
                // Column vocabulary: the default direct heap-allocated linear column
                // + its bounded capacity twin (the `.Bounded` front door).
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Primitive", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                // Allocation-generic growth pin ([DS-029] form-2: `Resource: Memory.Growable`).
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
                .product(name: "Memory Allocator Protocol Primitives", package: "swift-memory-allocation-primitives"),
                // Typed slots.
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Umbrella ([MOD-005]): re-exports the carrier module.
        .target(
            name: "Stack Primitives",
            dependencies: [
                "Stack Primitive",
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "Stack Primitives Tests",
            dependencies: [
                "Stack Primitives",
                "Stack Primitives Test Support",
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Stack Primitives Test Support",
            dependencies: [
                "Stack Primitives",
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Collection Primitives Test Support", package: "swift-collection-primitives"),
                .product(name: "Input Primitives Test Support", package: "swift-input-primitives"),
                .product(name: "Sequence Primitives Test Support", package: "swift-sequence-primitives"),
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
