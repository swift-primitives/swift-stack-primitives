// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Stack_Primitive
public import Stack_Bounded_Primitive
public import Index_Primitives
import Buffer_Linear_Primitives
import Ownership_Shared_Primitive

// MARK: - Variant `@Stack.Builder` DSL inits
//
// Each capacity variant carries a thin `init(@Stack.Builder …)` that drains the
// dynamic `Stack<Element>` accumulator (from the shared `@Stack.Builder` grammar)
// through the variant's own `push`. Declaration order is push order; the last
// declared element ends at the top of the stack. Centralized here in the umbrella
// ops module (mirroring set-ordered's Variants+Builder) because `Stack.Builder`
// lives in this module while the variant types live in their own type modules.

extension Stack.Bounded where Element: ~Copyable {
    /// Constructs a heap-allocated bounded stack from a result-builder closure.
    ///
    /// Capacity supplied at the outer init; declaration order is push order.
    /// Overflow throws `Error` from `Stack.Bounded.push`.
    ///
    /// ```swift
    /// var stack = try Stack<Int>.Bounded(capacity: 8) {
    ///     1; 2; 3
    /// }
    /// stack.pop()  // 3
    /// ```
    public init(
        capacity: Index<Element>.Count,
        @Stack<Element>.Builder _ builder: () -> Stack<Element>
    ) throws(Self.Error) {
        var bounded = Stack<Element>.Bounded(capacity: capacity)
        var dynamic = builder()
        while !dynamic._buffer.isEmpty {
            try bounded.push(dynamic._buffer.withUnique { $0.removeFirst() })
        }
        self = bounded
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Constructs a heap-allocated bounded stack from a result-builder closure
    /// (the `Copyable` constructing twin — the inner `Bounded(capacity:)`
    /// resolves to the clone-capturing constructor, so the escaping stack's
    /// CoW box can restore uniqueness).
    ///
    /// Capacity supplied at the outer init; declaration order is push order.
    /// Overflow throws `Error` from `Stack.Bounded.push`.
    public init(
        capacity: Index<Element>.Count,
        @Stack<Element>.Builder _ builder: () -> Stack<Element>
    ) throws(Self.Error) {
        var bounded = Stack<Element>.Bounded(capacity: capacity)
        var dynamic = builder()
        while !dynamic._buffer.isEmpty {
            try bounded.push(dynamic._buffer.withUnique { $0.removeFirst() })
        }
        self = bounded
    }
}


