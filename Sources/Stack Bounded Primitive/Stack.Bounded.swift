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
public import Storage_Contiguous_Primitives
public import Buffer_Linear_Bounded_Primitive
public import Index_Primitives

extension Stack where Element: ~Copyable {

    // MARK: - Bounded (Fixed-Capacity, Heap-Allocated)

    /// A fixed-capacity LIFO stack supporting move-only elements.
    ///
    /// `Stack.Bounded` allocates storage upfront and throws on overflow.
    /// Use this variant when capacity is known or in contexts requiring
    /// predictable memory behavior (embedded, real-time).
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = Stack<Int>.Bounded(capacity: 10)
    /// try stack.push(1)
    /// try stack.push(2)
    /// stack.pop()        // Optional(2)
    /// stack.peek { $0 }  // Optional(1)
    /// ```
    ///
    /// ## When to Use
    ///
    /// Use `Stack.Bounded` when:
    /// - Maximum capacity is known at runtime
    /// - Predictable memory behavior is required (embedded, real-time)
    /// - Overflow should be an explicit error
    ///
    /// For unbounded growth, use ``Stack`` (the canonical type).
    /// For compile-time capacity with zero heap allocation, use ``Stack/Static``.
    ///
    /// ## Iteration
    ///
    /// When `Element` is `Copyable`, `Stack.Bounded` conforms to `Sequenceable`;
    /// it always conforms to `Iterable` (use `forEach`):
    ///
    /// ```swift
    /// var stack = Stack<Int>.Bounded(capacity: 10)
    /// try stack.push(1)
    /// try stack.push(2)
    /// stack.forEach { print($0) }  // 1, then 2
    /// ```
    ///
    /// ## Copy-on-Write
    ///
    /// When `Element` is `Copyable`, `Stack.Bounded` uses copy-on-write semantics:
    /// copies share storage until mutation, providing efficient value semantics.
    ///
    /// ## Move-Only Support
    ///
    /// Both the stack and its elements can be `~Copyable`:
    ///
    /// ```swift
    /// struct FileHandle: ~Copyable { ... }
    /// var handles = Stack<FileHandle>.Bounded(capacity: 5)
    /// try handles.push(FileHandle())
    /// ```
    // WHY: Category D — structural Sendable workaround; the type is
    // WHY: structurally value-safe but the compiler cannot synthesize
    // WHY: Sendable due to a stored pointer / generic parameter shape.
    @safe
    public struct Bounded: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear.Bounded

        /// The requested capacity (for overflow checking).
        public let requestedCapacity: Stack<Element>.Index.Count

        /// Creates a stack with the specified capacity.
        ///
        /// - Parameter capacity: Maximum number of elements.
        @inlinable
        public init(capacity: Stack<Element>.Index.Count) {
            self._buffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear.Bounded(
                minimumCapacity: capacity
            )
            self.requestedCapacity = capacity
        }
    }
}

// MARK: - Conditional Copyable

/// `Stack.Bounded` is `Copyable` when its elements are `Copyable`.
///
/// This enables value semantics with copy-on-write optimization:
/// copies share storage until mutation.
extension Stack.Bounded: Copyable where Element: Copyable {}

// MARK: - Sendable

/// Sendable conformance for `Stack.Bounded`.
///
/// ## Safety Invariant
///
/// `Stack.Bounded` is `~Copyable`. Single ownership is enforced by the type
/// system; the fixed-capacity `Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear.Bounded` it owns
/// transfers with it across isolation boundaries.
///
/// ## Intended Use
///
/// - Transferring a pre-sized stack to a worker or actor.
/// - Embedded/real-time contexts where capacity is bounded and the stack is
///   constructed at startup then moved to its consumer.
///
/// ## Non-Goals
///
/// - Not a shared concurrent stack — external synchronization required.
/// - Does not guarantee overflow safety under concurrent push; single-owner
///   mutation is required.
extension Stack.Bounded: @unsafe @unchecked Sendable where Element: Sendable {}
