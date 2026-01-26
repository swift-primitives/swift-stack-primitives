# Stack Primitives Insights

<!--
---
title: Stack Primitives Insights
version: 1.0.0
last_updated: 2026-01-20
applies_to: [swift-stack-primitives]
normative: false
---
-->

@Metadata {
    @TitleHeading("Stack Primitives")
}

Design decisions, implementation patterns, and lessons learned specific to this package.

## Overview

This document captures insights that emerged during development of swift-stack-primitives. These are not API requirements—they are recorded decisions and patterns that inform future work on this package.

**Document type**: Non-normative (recorded decisions, not requirements).

**Consolidation source**: Reflection entries tagged with `[Package: swift-stack-primitives]`.

---

## The Extension Declaration Site Bug

**Date**: 2026-01-19

**Context**: `Stack.Inline<let capacity: Int>` compiled but failed at usage sites when Element was `~Copyable`. The struct was declared in an extension.

### The Bug

Nested types declared in extensions don't inherit `~Copyable` from the outer type:

```swift
// WORKS: Nested type inside struct body
struct Stack<Element: ~Copyable>: ~Copyable {
    struct Inline<let capacity: Int>: ~Copyable { ... }
}

// FAILS: Nested type in extension
struct Stack<Element: ~Copyable>: ~Copyable { }
extension Stack {
    struct Inline<let capacity: Int>: ~Copyable { ... }  // ~Copyable doesn't propagate
}
```

The declaration site determines whether the `~Copyable` suppression propagates.

### The Fix Pattern

1. Declare nested types with value generics INSIDE the outer struct body
2. Add explicit `where Element: ~Copyable` to ALL extensions on the nested type
3. Exception: extensions requiring Copyable elements use `where Element: Copyable`

**Applies to**: All nested types in `~Copyable` containers.

---

## SPI as API Boundary Enforcement

**Date**: 2026-01-19

**Context**: Unsafe pointer methods are legitimate for C interop but shouldn't pollute the default API surface.

### The SPI Solution

Swift's `@_spi(GroupName)` attribute hides declarations from the default public interface:

```swift
@_spi(Unsafe)
@unsafe
@inlinable
public func withUnsafePointer<R>(at index: Int, _ body: (UnsafePointer<Element>) -> R) -> R

// Consumer must opt-in
@_spi(Unsafe) import Stack_Primitives
```

### The Pattern

For primitives packages, gate escape hatches behind SPI:
1. Identify methods for interop or advanced use cases
2. Apply `@_spi(Unsafe)` or domain-appropriate SPI group
3. Document the SPI import required
4. Keep the default API surface clean and safe

**Applies to**: `withUnsafePointer`, `withUnsafeMutablePointer`, and similar methods.

---

## The Canonical API as Subtraction

**Date**: 2026-01-19

**Context**: The goal was "canonical best-in-class public API." The result was smaller, not larger.

### The Audit Result

Four closure methods were redundancy—wrapping properties that already existed. Two pointer methods were legitimate but not default-visible. After audit:

- Core operations: unchanged
- Properties: unchanged
- Span access: property-based only (`span`, `mutableSpan`)
- Element access: removed (use `span[index]`)
- Pointer access: gated behind `@_spi(Unsafe)`

### Subtraction as Quality

A "canonical best-in-class API" has:
- One way to do each thing (not three equivalent ways)
- Safe defaults (unsafe gated, not prominent)
- Alignment with ecosystem direction (SE-0456 compliance)

Achieving this required removing code, not adding it.

**Applies to**: All primitives package API design.

---

## The Stack as Canonical Reference

**Date**: 2026-01-19

**Context**: Stack demonstrates every pattern required for `~Copyable` collection primitives.

### What Makes Stack Canonical

1. **Type declaration**: `struct Stack<Element: ~Copyable>: ~Copyable`
2. **Conditional conformance**: `extension Stack: Copyable where Element: Copyable {}`
3. **Ownership-aware methods**: `push(_ element: consuming Element)`, `pop() -> Element?`
4. **Dual peek API**: Closure-based for `~Copyable`, direct return for `Copyable`
5. **Span access**: `@_lifetime(borrow self)` for safe borrowed views
6. **Error hoisting**: `__StackError` at module level with typealias for Nest.Name
7. **Conditional Sendable**: `@unchecked Sendable where Element: Sendable`

### Why Stack Avoids the Accessor Problem

Stack uses direct methods, not nested accessors:

```swift
// Stack pattern
func peek<R>(_ body: (borrowing Element) -> R) -> R?
func pop() -> Element?

// NOT the Deque pattern (would require copying container)
var peek: Peek { ... }
```

**Applies to**: All new collection primitives.

---

## Conditional Copyable via Class-Backed Storage

**Date**: 2026-01-19

**Context**: Testing whether Stack could be conditionally Copyable when Element is Copyable, enabling Sequence conformance.

### The Architecture

Structs with `deinit` cannot conform to `Copyable`, but structs holding class references can:

```swift
final class StackStorage<Element: ~Copyable> {
    var storage: UnsafeMutablePointer<Element>
    deinit { /* cleanup */ }
}

struct Stack<Element: ~Copyable>: ~Copyable {
    private var _storage: StackStorage<Element>
}

extension Stack: Copyable where Element: Copyable {}  // Now possible!
extension Stack: Swift.Sequence where Element: Copyable {}  // Enabled!
```

### The CoW Requirement

Class-backing requires Copy-on-Write for value semantics:

```swift
extension Stack where Element: Copyable {
    private mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
        }
    }
}
```

**Applies to**: Any container needing both `~Copyable` support and Sequence conformance.

---

## Stored Pointer Enables Property-Based Span

**Date**: 2026-01-19

**Context**: Implementing SE-0456-compliant property-based span access with class-backed storage.

### The Problem

With `ManagedBuffer`, the span depends on a closure-derived pointer that cannot escape:

```swift
var span: Span<Element> {
    borrowing get {
        _storage.withUnsafeMutablePointerToElements { ptr in
            // ERROR: lifetime-dependent value escapes its scope
            Span(_unsafeStart: ptr, count: _storage.header)
        }
    }
}
```

### The Solution: Stored Pointer

Store the pointer as a struct property:

```swift
struct Stack<Element: ~Copyable>: ~Copyable {
    private var _storage: Storage
    private var _cachedPtr: UnsafeMutablePointer<Element>

    var span: Span<Element> {
        @_lifetime(borrow self)
        borrowing get {
            unsafe Span(_unsafeStart: _cachedPtr, count: _storage.header)
        }
    }
}
```

The `_cachedPtr` must be updated on every reallocation.

**Applies to**: Any container using class-backed storage with property-based span access.

---

## Protocol Conformance File Locality for Nested Types

**Date**: 2026-01-20

**Context**: Adding Sequence conformance in a separate file triggered compiler errors on the declaration file.

### The Bug

Protocol conformances for nested types, when in separate files, break `~Copyable` propagation:

```swift
// File: Stack.swift
struct Stack<Element: ~Copyable>: ~Copyable {
    struct Bounded: ~Copyable {
        var ptr: UnsafeMutablePointer<Element>  // Works
    }
}

// File: Bounded.swift
extension Stack.Bounded: Swift.Sequence where Element: Copyable { }  // Breaks ptr!
```

### The Rule

For nested types with `~Copyable` generic parameters:

**Protocol conformances MUST be in the same file as the type declaration.**

**Applies to**: `Stack.Bounded`, `Stack.Inline`, any nested type.

---

## Unified Storage Architecture

**Date**: 2026-01-20

**Context**: Refactoring `Stack` and `Stack.Bounded` to share a single storage class.

### The Architecture

Both types share a single nested class:

```swift
public struct Stack<Element: ~Copyable>: ~Copyable {
    @usableFromInline
    final class Storage: ManagedBuffer<Int, Element> { ... }

    var _storage: Storage
    var _cachedPtr: UnsafeMutablePointer<Element>

    public struct Bounded: ~Copyable {
        var _storage: Storage  // Same Storage class
        var _cachedPtr: UnsafeMutablePointer<Element>
        let capacity: Int
    }
}
```

### Benefits

1. Single source of truth for memory management
2. Consistent behavior for growth, cleanup, pointer access
3. ~100 lines of duplicate code eliminated

**Applies to**: Related types sharing allocation strategy.

---

## The Stored Pointer Discipline

**Date**: 2026-01-20

**Context**: The hybrid architecture requires careful discipline to maintain correctness.

### Staleness Points

The pointer must be updated whenever storage changes:

1. **Initial allocation**: `init` sets `_cachedPtr = _storage._elementsPointer`
2. **Capacity growth**: `ensureCapacity()` must update pointer
3. **CoW copy**: `makeUnique()` must update pointer
4. **Clear with deallocation**: `clear(keepingCapacity: false)` must update pointer

Missing any update causes use-after-free.

### The Verification Pattern

Every path that replaces `_storage` should be followed by `_cachedPtr = _storage._elementsPointer`. Mark these sites with "CRITICAL: Update cached pointer".

**Applies to**: All storage replacement paths.

---

## Topics

### Related Documents

- <doc:Stack>
