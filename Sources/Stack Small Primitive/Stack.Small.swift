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
public import Storage_Heap_Primitives
public import Buffer_Linear_Small_Primitive

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
    // SAFETY: Safe by construction — backing storage uses only stdlib
    // SAFETY: safe types; `@safe` documents that this type performs no
    // SAFETY: unsafe operations.
    // @frozen lifts the non-frozen partial-consume restriction so the consuming
    // `Sequenceable.makeIterator()` can extract `_buffer`. ABI-freeze is fine pre-1.0.
    @safe
    @frozen
    public struct Small<let inlineCapacity: Int>: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Storage<Element>.Heap>.Linear.Small<inlineCapacity>

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

// MARK: - Sendable

/// Sendable conformance for `Stack.Small`.
///
/// ## Safety Invariant
///
/// `Stack.Small` is unconditionally `~Copyable` (inline storage with automatic
/// heap spill). Unique ownership ensures the move across threads relinquishes the
/// sender's access; both the inline bytes and any spilled allocation transfer
/// together.
///
/// ## Intended Use
///
/// - SmallVec-style stack handed from builder to consumer where typical workloads
///   fit inline but can spill.
/// - Transferring small-size-optimized stacks of `~Copyable` elements without
///   forcing heap allocation for common cases.
///
/// ## Non-Goals
///
/// - Not safe for concurrent mutation on either the inline or spilled path.
/// - Spill transitions are not atomic with respect to external observers.
extension Stack.Small: @unsafe @unchecked Sendable where Element: Sendable {}
