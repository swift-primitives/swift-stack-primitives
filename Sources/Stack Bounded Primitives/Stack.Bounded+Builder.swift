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

public import Stack_Dynamic_Primitives
public import Stack_Primitives_Core

extension Stack.Bounded where Element: ~Copyable {
    /// Constructs a heap-allocated bounded stack from a result-builder closure.
    ///
    /// Wraps the dynamic `Stack<Element>.Builder` per Round-2 Option Y.
    /// Capacity supplied at the outer init; declaration order is push
    /// order. Overflow throws `Error` from `Stack.Bounded.push`.
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
            try bounded.push(dynamic._buffer.remove.first())
        }
        self = bounded
    }
}
