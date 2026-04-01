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

public import Buffer_Linear_Small_Primitives

extension Stack where Element: ~Copyable {

    // MARK: - Small (SmallVec-style: inline then spill to heap)

    /// A LIFO stack with small-buffer optimization (SmallVec pattern).
    ///
    /// `Stack.Small` stores up to `inlineCapacity` elements in inline storage,
    /// then automatically spills to heap storage when that capacity is exceeded.
    /// This provides the performance benefits of inline storage for common cases
    /// while supporting unbounded growth.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = Stack<Int>.Small<4>()  // Inline up to 4 elements
    /// stack.push(1)  // Inline
    /// stack.push(2)  // Inline
    /// stack.push(3)  // Inline
    /// stack.push(4)  // Inline
    /// stack.push(5)  // Spills to heap, moves all elements
    /// ```
    ///
    /// ## When to Use
    ///
    /// Use `Stack.Small` when:
    /// - Most instances will hold a small number of elements
    /// - Occasional large instances need to be supported
    /// - Zero heap allocation for the common case is important
    ///
    /// For fixed capacity with no spill, use ``Stack/Static``.
    /// For unbounded growth from the start, use ``Stack``.
    ///
    /// ## Non-Copyable
    ///
    /// `Stack.Small` is unconditionally `~Copyable` (move-only) because it requires
    /// a deinitializer to clean up inline storage. If you need `Copyable` semantics
    /// with value generic capacity, use ``Stack`` instead (which always heap-allocates
    /// and supports conditional `Copyable` conformance).
    /// Element cleanup is handled by `Storage.Inline`'s deinit (inline path)
    /// or `Storage.Heap`'s deinit (spilled path).
    @safe
    public struct Small<let inlineCapacity: Int>: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Element>.Linear.Small<inlineCapacity>

        /// Creates an empty small stack.
        @inlinable
        public init() {
            self._buffer = .init()
        }

        /// Whether the stack is currently using heap storage.
        @inlinable
        public var isSpilled: Bool { _buffer.isSpilled }
    }
}
