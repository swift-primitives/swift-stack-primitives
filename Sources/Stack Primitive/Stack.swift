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

public import Buffer_Linear_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
import Index_Primitives
public import Column_Primitives
public import Shared_Primitive

/// A dynamically-growing LIFO stack supporting move-only elements.
///
/// `Stack` is the general-purpose stack primitive. It provides O(1) amortized push
/// and O(1) pop with automatic capacity growth. This is the canonical stack type—
/// use it unless you have specific constraints requiring a variant.
///
/// ## Example
///
/// ```swift
/// var stack = Stack<Int>()
/// stack.push(1)
/// stack.push(2)
/// stack.pop()        // Optional(2)
/// stack.peek { $0 }  // Optional(1)
/// ```
///
/// ## Variants
///
/// - ``Stack``: Dynamically-growing with amortized O(1) push (this type)
/// - ``Stack/Bounded``: Fixed-capacity with upfront allocation, throws on overflow
/// - ``Stack/Static``: Zero-allocation inline storage with compile-time capacity
///
/// ## Move-Only Support
///
/// Both the stack and its elements can be `~Copyable`:
///
/// ```swift
/// struct FileHandle: ~Copyable { ... }
/// var handles = Stack<FileHandle>()
/// handles.push(FileHandle())
/// ```
///
/// ## Iteration
///
/// Element traversal is scoped: `forEach` (ops module) and the scoped span forms
/// (`withSpan` / `withMutableSpan`) borrow the elements in bottom-to-top order.
/// The protocol-lattice memberships (`Iterable` / `Sequenceable`) are withdrawn
/// at the A-1 interim reshape — the stored `Shared` column has no returning span
/// or consuming extraction; they re-materialize when `Shared` gains those
/// surfaces upstream (recorded as future work).
///
/// ```swift
/// var stack = Stack<Int>()
/// stack.push(1)
/// stack.push(2)
/// stack.forEach { print($0) }  // 1, then 2 — bottom-to-top
/// ```
///
/// ## Copy-on-Write
///
/// When `Element` is `Copyable`, `Stack` uses copy-on-write semantics:
/// copies share storage until mutation, providing efficient value semantics.
/// The CoW machinery is the ratified `Shared` column (the W4/W5 tower design):
/// the stored buffer rides a refcounted box whose uniqueness gate
/// (`withUnique`) runs before every mutation. For `~Copyable` elements the
/// stack is move-only and the gate is a no-op.
///
/// ## Growth Behavior
///
/// When capacity is exceeded, the stack allocates new storage at 2x the
/// current capacity (minimum 4) and moves all elements. This provides
/// O(1) amortized push with approximately 2.0 copies per element over
/// the stack's lifetime.
// WHY: Category D — structural Sendable workaround; the type is
// WHY: structurally value-safe but the compiler cannot synthesize
// WHY: Sendable due to a stored pointer / generic parameter shape.
@safe
@frozen
public struct Stack<Element: ~Copyable>: ~Copyable {

    /// Element storage: the `Shared` column over the growable heap buffer
    /// (`Column.Heap<Element>` = `Buffer.Linear` over system-allocated
    /// contiguous storage).
    ///
    /// Conditional copyability flows from the column (`Shared<E, B>` is
    /// `Copyable` iff `E` is), and value semantics ride the ratified CoW box —
    /// the A-1 interim reshape (public element-generic API preserved; the
    /// hand-rolled `ensureUnique` CoW is deleted).
    ///
    /// `@usableFromInline package` ([MOD-036] refined-C): the hot
    /// `~Copyable`/`Copyable` operation surface co-located in this (type)
    /// module inlines cross-package to zero-witness-dispatch; the cold
    /// sequence-family ops in the ops module reach this storage through the
    /// same package-visible field.
    @usableFromInline
    package var _buffer: Shared<Element, Column.Heap<Element>>

    /// Creates an empty stack of move-only elements.
    ///
    /// No allocation occurs until the first push. The column is statically
    /// unique (no clone strategy exists for `~Copyable` elements; the wrapper
    /// cannot be duplicated).
    @inlinable
    public init() {
        self._buffer = Shared(Column.Heap<Element>(minimumCapacity: .zero))
    }

    // Note: init(_ elements: Swift.Sequence) is in Stack Primitives (ops)
    // because it requires push() which is defined there.

    /// Creates a stack of move-only elements with reserved capacity.
    ///
    /// Pre-allocates storage for the specified number of elements.
    /// Useful when the approximate number of elements is known.
    ///
    /// - Parameter capacity: Number of elements to reserve space for.
    @inlinable
    public init(reservingCapacity capacity: Index.Count) {
        self._buffer = Shared(Column.Heap<Element>(minimumCapacity: capacity))
    }
}

// MARK: - Construction (Copyable twins — the clone-capturing sites)

// `Shared`'s constructors split on element copyability: the `Copyable` overload
// captures the column's deep-copy strategy so a shared box can restore
// uniqueness; the `~Copyable` overload captures none. The split must surface at
// STACK construction too — a `Copyable`-element stack constructed through the
// `~Copyable` path would carry a box that cannot restore uniqueness. At
// `Copyable` call sites the more-constrained twin wins.

extension Stack where Element: Copyable {
    /// Creates an empty stack (CoW-capable column; the clone strategy is
    /// captured here).
    ///
    /// No allocation occurs until the first push.
    @inlinable
    public init() {
        self._buffer = Shared(Column.Heap<Element>(minimumCapacity: .zero))
    }

    /// Creates a stack with reserved capacity (CoW-capable column; the clone
    /// strategy is captured here).
    ///
    /// - Parameter capacity: Number of elements to reserve space for.
    @inlinable
    public init(reservingCapacity capacity: Index.Count) {
        self._buffer = Shared(Column.Heap<Element>(minimumCapacity: capacity))
    }
}

// MARK: - Conditional Copyable

/// `Stack` is `Copyable` when its elements are `Copyable`.
///
/// Copyability flows from the stored column: `Shared<Element, B>` is
/// `Copyable` exactly when `Element` is. Copies share the box until the first
/// mutation restores uniqueness (the `withUnique` gate).
extension Stack: Copyable where Element: Copyable {}

// MARK: - Sendable

/// `Stack` is `Sendable` when its elements are `Sendable`.
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
/// - Transferring a prepared stack to a worker thread.
/// - Handing off a stack of `~Copyable` resources across actors.
/// - Actor-owned stacks constructed outside the actor and passed in at init.
///
/// ## Non-Goals
///
/// - Does not support concurrent access from multiple threads.
/// - This conformance does not make arbitrary sharing safe — mutation requires
///   exclusive access to the stack value itself.
///
/// `Element: ~Copyable & Sendable` — the suppression is load-bearing: a bare
/// `Element: Sendable` clause implicitly requires `Element: Copyable`, which
/// excluded exactly the move-only handoff documented above (arc-1 finding
/// W3-F1, REPORT-arc-shared-soundness-W3 §1; fix principal-ratified
/// 2026-06-11).
extension Stack: @unsafe @unchecked Sendable where Element: ~Copyable & Sendable {}
