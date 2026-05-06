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

extension Stack.Small where Element: ~Copyable {
    /// Constructs a SmallVec stack from a result-builder closure.
    ///
    /// Wraps the dynamic `Stack<Element>.Builder` per Round-2 Option Y.
    /// Declaration order is push order. Non-throwing because Small
    /// spills inline capacity to the heap rather than failing on overflow.
    ///
    /// ```swift
    /// var stack = Stack<Int>.Small<4> {
    ///     1; 2; 3; 4; 5  // first 4 inline, 5th spills to heap
    /// }
    /// stack.pop()  // 5
    /// ```
    public init(
        @Stack<Element>.Builder _ builder: () -> Stack<Element>
    ) {
        var dynamic = builder()
        self.init()
        while !dynamic._buffer.isEmpty {
            self.push(dynamic._buffer.remove.first())
        }
    }
}
