# Stack Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-stack-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-stack-primitives/actions/workflows/ci.yml)

`Stack<Element>` — a dynamically-growing LIFO stack for any element type, including move-only (`~Copyable`) ones. Push and pop are amortized O(1); peek borrows the top element without removing it. It is the canonical stack — reach for it unless a constraint demands a fixed-capacity variant.

For workloads that must not allocate during use, `Stack.Bounded` is a fixed-capacity stack that allocates its buffer up front and throws on overflow rather than growing. Both stacks carry `~Copyable` elements by move, so pushing a move-only value transfers ownership into the stack and popping transfers it back out.

---

## Key Features

- **LIFO, amortized O(1)** — `push` / `pop` with automatic capacity growth.
- **Move-only elements** — `~Copyable` elements are pushed and popped by ownership transfer, never an implicit copy.
- **Borrowing peek** — inspect the top element in place without removing or copying it.
- **Fixed-capacity option** — `Stack.Bounded` allocates up front and throws on overflow, for allocation-free hot paths.

---

## Quick Start

```swift
import Stack_Primitives

var stack = Stack<Int>()
stack.push(1)
stack.push(2)
stack.pop()        // Optional(2)
stack.peek { $0 }  // Optional(1) — borrows the top, leaves it on the stack
```

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-stack-primitives.git", branch: "main")
]
```

Add a product to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Stack Primitives", package: "swift-stack-primitives")
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

| Product | Contents | When to import |
|---------|----------|----------------|
| `Stack Primitives` | Umbrella — `Stack` and `Stack.Bounded` with their conformances | Most consumers |
| `Stack Primitive` | `Stack<Element>` — the growable LIFO stack | Naming the growable stack directly |
| `Stack Bounded Primitive` / `Stack Bounded Primitives` | `Stack.Bounded` — the fixed-capacity stack and its conformances | Allocation-free, fixed-capacity use |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Pending (nightly-toolchain follow-up) |

---

## Related Packages

- [`swift-array-primitives`](https://github.com/swift-primitives/swift-array-primitives) — the sequential-container sibling for random-access storage.
- [`swift-collection-primitives`](https://github.com/swift-primitives/swift-collection-primitives) — the `Collection` capability the stack conforms to.
- [`swift-column-primitives`](https://github.com/swift-primitives/swift-column-primitives) — the storage columns the stack is built over.

---

## Community

<!-- BEGIN: discussion -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
