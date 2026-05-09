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

extension Stack.Static where Element: ~Copyable {
    /// Constructs a fixed-capacity inline stack from a result-builder closure.
    ///
    /// Wraps the dynamic `Stack<Element>.Builder` per Round-2 Option Y.
    /// Declaration order is push order (matches Round-1 OQ3=A semantics);
    /// the last declared element ends at the top of the stack. Overflow
    /// throws `Error` from `Stack.Static.push`.
    ///
    /// ```swift
    /// var stack = try Stack<Int>.Static<8> {
    ///     1; 2; 3
    /// }
    /// stack.pop()  // 3 — last declared at top
    /// ```
    public init(
        @Stack<Element>.Builder _ builder: () -> Stack<Element>
    ) throws(Self.Error) {
        var dynamic = builder()
        self.init()
        // Drain dynamic from the bottom (oldest pushed first) to preserve push order.
        while !dynamic._buffer.isEmpty {
            try self.push(dynamic._buffer.remove.first())
        }
    }
}
