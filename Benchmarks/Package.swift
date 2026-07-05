// swift-tools-version: 6.3.1

import PackageDescription

// Nested benchmark package (arc-bench W2; the W1-ratified instrument:
// executable target run via the binary directly, release-only, never
// `swift test` — seat verdict 2026-06-11 on REPORT-arc-bench-W1).
//
// Worktree-run gotcha (§6): `.package(path: "../")` resolves the dep identity to
// the CHECKOUT's basename. In a worktree that is the branch name (adt-tower-w2),
// not `swift-stack-primitives`; the committed `package:` refs stay
// `swift-stack-primitives` (correct post-merge) — to RUN in the worktree,
// transiently `sed` the product refs to the worktree basename, run, then restore.
let package = Package(
    name: "stack-bench",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: "../"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Stack Benchmarks",
            dependencies: [
                .product(name: "Stack Primitives", package: "swift-stack-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
            ],
            path: "Stack Benchmarks"
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
