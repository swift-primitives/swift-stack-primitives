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
public import Column_Primitives
public import Shared_Primitive

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
    ///
    /// ## Iteration
    ///
    /// Element traversal is scoped: `forEach` (ops module) and the scoped span
    /// forms (`withSpan` / `withMutableSpan`) borrow the elements in
    /// bottom-to-top order. The protocol-lattice memberships
    /// (`Iterable` / `Sequenceable`) are withdrawn at the A-1 interim reshape —
    /// the stored `Shared` column has no returning span or consuming
    /// extraction; they re-materialize when `Shared` gains those surfaces
    /// upstream (recorded as future work).
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
    /// When `Element` is `Copyable`, `Stack.Bounded` uses copy-on-write
    /// semantics: copies share storage until mutation, providing efficient
    /// value semantics. The CoW machinery is the ratified `Shared` column (the
    /// W4/W5 tower design): the stored bounded buffer rides a refcounted box
    /// whose uniqueness gate (`withUnique`) runs before every mutation, and the
    /// CoW detach clones CAPACITY-PRESERVINGLY (a shrink-to-fit copy would
    /// break the bounded capacity contract). For `~Copyable` elements the
    /// stack is move-only and the gate is a no-op.
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
        /// Element storage: the `Shared` column over the fixed-capacity heap
        /// buffer (`Column.Bounded<Element>` = `Buffer.Linear.Bounded` over
        /// system-allocated contiguous storage).
        ///
        /// Conditional copyability flows from the column (`Shared<E, B>` is
        /// `Copyable` iff `E` is), and value semantics ride the ratified CoW
        /// box — the A-1 interim reshape (public element-generic API
        /// preserved; the hand-rolled `ensureUnique` CoW is deleted).
        ///
        /// `@usableFromInline package` ([MOD-036] refined-C): the hot
        /// `~Copyable`/`Copyable` operation surface co-located in this (type)
        /// module inlines cross-package to zero-witness-dispatch; the cold
        /// sequence-family ops in the ops module reach this storage through
        /// the same package-visible field.
        @usableFromInline
        package var _buffer: Shared<Element, Column.Bounded<Element>>

        /// The requested capacity (for overflow checking).
        ///
        /// The underlying storage may round its physical capacity up; this
        /// stored bound is the stack's contract — `push` rejects at exactly
        /// this count.
        public let requestedCapacity: Index_Primitives.Index<Element>.Count
    }
}

// MARK: - Construction (Copyable twins — the clone-capturing sites)

// `Shared`'s constructors split on element copyability: the `Copyable` overload
// captures the column's deep-copy strategy — the CAPACITY-PRESERVING
// `Buffer.Linear.Bounded.clone()` — so a shared box can restore uniqueness; the
// `~Copyable` overload captures none. The split must surface at STACK
// construction too — a `Copyable`-element stack constructed through the
// `~Copyable` path would carry a box that cannot restore uniqueness. At
// `Copyable` call sites the more-constrained twin wins.
//
// BOTH twins live in extensions (not the struct body): a struct-body member of
// the extension-nested `Bounded` and a `where Element: Copyable` extension
// member mangle to the SAME symbol on 6.3.2 (the redundant-with-default
// `Copyable` requirement is dropped from the extension's mangled signature) —
// the extension/extension split is the coexisting spelling (the
// `withMutableSpan` precedent on the growable type).

extension Stack.Bounded where Element: ~Copyable {
    /// Creates a stack of move-only elements with the specified capacity.
    ///
    /// The column is statically unique (no clone strategy exists for
    /// `~Copyable` elements; the wrapper cannot be duplicated).
    ///
    /// - Parameter capacity: Maximum number of elements.
    @inlinable
    public init(capacity: Index_Primitives.Index<Element>.Count) {
        self._buffer = Shared(Column.Bounded<Element>(minimumCapacity: capacity))
        self.requestedCapacity = capacity
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Creates a stack with the specified capacity (CoW-capable column; the
    /// capacity-preserving clone strategy is captured here).
    ///
    /// - Parameter capacity: Maximum number of elements.
    @inlinable
    public init(capacity: Index_Primitives.Index<Element>.Count) {
        self._buffer = Shared(Column.Bounded<Element>(minimumCapacity: capacity))
        self.requestedCapacity = capacity
    }
}

// MARK: - Conditional Copyable

/// `Stack.Bounded` is `Copyable` when its elements are `Copyable`.
///
/// Copyability flows from the stored column: `Shared<Element, B>` is
/// `Copyable` exactly when `Element` is. Copies share the box until the first
/// mutation restores uniqueness (the `withUnique` gate).
extension Stack.Bounded: Copyable where Element: Copyable {}

// MARK: - Sendable

/// `Stack.Bounded` is `Sendable` when its elements are `Sendable`.
///
/// ## Safety Invariant
///
/// The stored `Shared` column is mutated exclusively through its uniqueness
/// gate (`withUnique` restores uniqueness FIRST), so a box shared between two
/// `Copyable`-element stack values is never written while shared — the stdlib
/// CoW-Sendable discipline. For `~Copyable` elements the stack is move-only:
/// at most one owner exists, and the box moves with it.
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
/// - Does not guarantee overflow safety under concurrent push; mutation
///   requires exclusive access to the stack value itself.
extension Stack.Bounded: @unsafe @unchecked Sendable where Element: Sendable {}
