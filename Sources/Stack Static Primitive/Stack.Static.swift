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
public import Buffer_Linear_Inline_Primitives

extension Stack where Element: ~Copyable {

    // MARK: - Static (Fixed-Capacity, Inline Storage)

    /// A fixed-capacity, inline-storage LIFO stack with compile-time capacity.
    ///
    /// `Stack.Static` stores elements directly within the struct's memory layout,
    /// requiring no heap allocation. The capacity is specified as a compile-time
    /// generic parameter.
    /// Element cleanup is handled by `Storage.Inline`'s deinit.
    ///
    /// ## Non-Copyable
    ///
    /// `Stack.Static` is unconditionally `~Copyable` (move-only) because inline
    /// storage requires a deinitializer. For `Copyable` semantics, use ``Stack``.
    // @frozen lifts the non-frozen partial-consume restriction so the consuming
    // `Sequenceable.makeIterator()` can extract `_buffer`. ABI-freeze is fine
    // pre-1.0.
    @frozen
    public struct Static<let capacity: Int>: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Storage<Element>.Heap>.Linear.Inline<capacity>

        /// Creates an empty static stack.
        @inlinable
        public init() {
            self._buffer = .init()
        }
    }
}

// MARK: - Sendable

/// Sendable conformance for `Stack.Static`.
///
/// ## Safety Invariant
///
/// `Stack.Static` is unconditionally `~Copyable` (inline storage). Unique
/// ownership ensures cross-thread transfer via move is race-free; the inline
/// element bytes travel with the struct.
///
/// ## Intended Use
///
/// - Stack-allocated stack moved from constructor to consumer without heap
///   allocation.
/// - Embedded contexts where the compile-time capacity matches a known workload.
///
/// ## Non-Goals
///
/// - Not a shared buffer — inline storage is tied to one owner at a time.
/// - No synchronization; mutating access must remain single-threaded.
extension Stack.Static: @unsafe @unchecked Sendable where Element: Sendable {}
