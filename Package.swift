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
        // MARK: - Base
        .library(name: "Stack Primitive", targets: ["Stack Primitive"]),
        .library(name: "Stack Primitives", targets: ["Stack Primitives"]),

        // MARK: - Bounded variant
        .library(name: "Stack Bounded Primitive", targets: ["Stack Bounded Primitive"]),
        .library(name: "Stack Bounded Primitives", targets: ["Stack Bounded Primitives"]),

        // MARK: - Static variant
        .library(name: "Stack Static Primitive", targets: ["Stack Static Primitive"]),
        .library(name: "Stack Static Primitives", targets: ["Stack Static Primitives"]),

        // MARK: - Small variant
        .library(name: "Stack Small Primitive", targets: ["Stack Small Primitive"]),
        .library(name: "Stack Small Primitives", targets: ["Stack Small Primitives"]),

        // MARK: - Test Support
        .library(name: "Stack Primitives Test Support", targets: ["Stack Primitives Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        // W2 mesh: buffer packages on their  worktrees so every path to memory
        // unifies on identity swift-memory-primitives (collision resolved).
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        // W3 ⑤-(N): the consumer spelling is now Buffer<Storage<Element>.Heap>.Linear,
        // so the substrate type Storage<Element>.Heap is referenced directly.
        .package(url: "https://github.com/swift-primitives/swift-storage-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-collection-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-iterator-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-iterator-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ordinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-finite-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-equation-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Base type (Stack dynamic/heap + Index typealias)
        .target(
            name: "Stack Primitive",
            dependencies: [
                .product(name: "Equation Primitives Standard Library Integration", package: "swift-equation-primitives"),
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),

        // MARK: - Bounded type
        .target(
            name: "Stack Bounded Primitive",
            dependencies: [
                .product(name: "Equation Primitives Standard Library Integration", package: "swift-equation-primitives"),
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),

        // MARK: - Static type
        .target(
            name: "Stack Static Primitive",
            dependencies: [
                .product(name: "Equation Primitives Standard Library Integration", package: "swift-equation-primitives"),
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),

        // MARK: - Small type
        .target(
            name: "Stack Small Primitive",
            dependencies: [
                .product(name: "Equation Primitives Standard Library Integration", package: "swift-equation-primitives"),
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Memory Contiguous Primitives", package: "swift-memory-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),

        // MARK: - Bounded ops
        .target(
            name: "Stack Bounded Primitives",
            dependencies: [
                "Stack Bounded Primitive",
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),

        // MARK: - Static ops
        .target(
            name: "Stack Static Primitives",
            dependencies: [
                "Stack Static Primitive",
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),

        // MARK: - Small ops
        .target(
            name: "Stack Small Primitives",
            dependencies: [
                "Stack Small Primitive",
                "Stack Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
            ]
        ),

        // MARK: - Base ops + Umbrella ([MOD-005] dual-role: base conformances + re-export of all variants)
        .target(
            name: "Stack Primitives",
            dependencies: [
                "Stack Primitive",
                "Stack Bounded Primitive",
                "Stack Bounded Primitives",
                "Stack Static Primitive",
                "Stack Static Primitives",
                "Stack Small Primitive",
                "Stack Small Primitives",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
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
