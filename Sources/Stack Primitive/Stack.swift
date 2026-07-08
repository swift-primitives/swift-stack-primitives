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

// MARK: - Stack (the ADT tier — a LIFO stack over the COLUMN)
//
// ADT Tower W2 reshape (Research/adt-tower.md §9.3 Stack row; SEAT+principal
// ratified 2026-07-02). Mirrors the landed heap pilot (swift-heap-primitives) —
// the seam-op bodies are the append/removeLast shapes of a LIFO stack:
//   1. thin bound-free carrier `__Stack<S: ~Copyable>` (hoisted per
//      [API-IMPL-009]/[PKG-NAME-006]; public spelling is the front-door alias
//      `Stack<E>` in Stack.FrontDoor.swift, [DS-028]);
//   2. semantic ops written ONCE over the Store/Buffer seams (push/pop are
//      append/removeLast shapes; the [DS-024] ledger laws keep `count` honest
//      through them), CoW-correct via `unshare()`, FULL ~Copyable element
//      support — the LIFO discipline is order-free, so no element bound;
//   3. growth written ONCE, pinned to the linear column GENERIC over the
//      allocation (`Resource: Memory.Growable` — the [DS-029] form-2 pin;
//      stack rides `Buffer.Linear`, so the R-generic pin is the shipped surface).
//
// The prior A-1 interim shape (Shared-CoW-default `_buffer`, element-generic
// public API, Builder/Static variant surface) is REPLACED. The canonical
// `Stack<E>` is the DIRECT move-only linear column; `Shared` (CoW) returns only
// consumer-pulled as a `.Shared` front-door variant. The hand-written
// `Stack.Bounded` TYPE is DELETED for the `.Bounded` capacity-twin front-door
// alias (Stack.Bounded.swift; the 2026-06-23 directive, §9.6.4).

public import Buffer_Linear_Primitive
public import Buffer_Primitive
public import Buffer_Protocol_Primitives
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Allocator_Protocol_Primitives
public import Storage_Contiguous_Primitives
public import Storage_Primitive
public import Store_Protocol_Primitives

// MARK: 1. The carrier (thin, bound-free; hoisted per [API-IMPL-009])

/// A last-in-first-out (LIFO) stack — the semantic ADT over an explicit storage COLUMN.
///
/// `__Stack` is the bound-free carrier ([DS-025]): its column parameter `S` is bound
/// `~Copyable` **only**; every capability (observability, the seam element ops,
/// construction/growth) attaches by conditional `@inlinable` extension keyed on the
/// seams the column conforms (D3). The PUBLIC spelling of the family is the front-door
/// aliases — `Stack<E>` (canonical) and `Stack<E>.Bounded` (fixed capacity), declared
/// in `Stack.FrontDoor.swift` / `Stack.Bounded.swift` ([DS-028]); the hoisted name
/// never appears in consumer signatures.
///
/// Copyability flows from the column: `__Stack<S>` is `Copyable` exactly when `S` is
/// (the default direct column is move-only by design; the `Shared` CoW column, when a
/// consumer pulls it, is `Copyable` iff its element is).
@_documentation(visibility: public)  // symbolgraph-extract drops __-prefixed decls otherwise
@frozen
public struct __Stack<S: ~Copyable>: ~Copyable {

    /// The storage column — a move-only buffer (the default ownership column) or a
    /// `Shared` CoW column.
    ///
    /// The ADT is a thin LIFO discipline over it; it carries NO deinit (teardown
    /// lives in the leaf's oracle / the shared box's drain).
    @usableFromInline
    package var column: S

    /// Wraps an existing column.
    @inlinable
    public init(column: consuming S) { self.column = column }

    /// Consumes the stack, yielding its storage column.
    @inlinable
    public consuming func take() -> S { column }
}

extension __Stack: Copyable where S: Copyable {}
extension __Stack: Sendable where S: Sendable & ~Copyable {}

// MARK: 2. Semantic ops — written ONCE over the seams (any conforming column)

extension __Stack where S: ~Copyable, S: Store.`Protocol` & Buffer.`Protocol` {

    /// The number of elements in the stack.
    @inlinable
    public var count: Index<S.Element>.Count { column.count }

    /// Whether the stack has no elements.
    @inlinable
    public var isEmpty: Bool { column.isEmpty }

    /// Runtime slot coordinate (LIFO index arithmetic happens in raw `Int`).
    @inlinable
    package func slot(_ k: Int) -> Index<S.Element> {
        Index(Ordinal(UInt(k)))
    }

    /// Borrowing access to the top (most-recently-pushed) element.
    ///
    /// Precondition-gated (traps on empty), NOT Optional-returning: there is no
    /// Optional *borrow* of a `~Copyable` element (an `Element?` borrow is
    /// structurally unavailable), so `top` cannot vend `Element?` by borrow —
    /// unlike `pop`, which consumes and returns `Element?`. Guard with `isEmpty`.
    ///
    /// - Precondition: The stack must not be empty.
    @inlinable
    public var top: S.Element {
        // reason: precondition-gated by `isEmpty` above the call site, so the count
        // is at least one here; this computes the raw-Int slot of the last element.
        // No typed Cardinal/Ordinal "last slot" helper exists yet in Index_Primitives
        // (verified: no such API on the typed count) — escalating per [INFRA-025]
        // rather than inventing one ad hoc. Same shape pre-exists unshielded in
        // swift-heap-primitives Heap.swift:205 (the pilot this file mirrors).
        // swiftlint:disable:next cardinal_count_minus_one_evasion
        _read { yield column[slot(Int(clamping: count) - 1)] }
    }

    /// Removes and returns the top element, or `nil` if the stack is empty
    /// (seam-generic; the removeLast shape — no growth involved).
    ///
    /// Returns `Element?` — the tower-wide remove-from-empty convention
    /// (adt-tower.md:1247; the landed `Queue.dequeue()` model). Consuming an
    /// `Element?` is available even for `~Copyable` elements (unlike a borrow —
    /// see `top`). The empty case is checked and returns `nil` BEFORE
    /// `column.unshare()` — the empty path has nothing to mutate, so it takes no
    /// CoW uniqueness check.
    @inlinable
    public mutating func pop() -> S.Element? {
        let n = Int(clamping: count)
        if n == 0 { return nil }
        column.unshare()
        return column.move(at: slot(n - 1))
    }
}

// MARK: 3. Growth — written ONCE, allocation-GENERIC ([DS-029] form-2 R-generic pin)

extension __Stack where S: ~Copyable {

    /// Creates an empty stack on any growable linear column.
    @inlinable
    public init<E: ~Copyable, Resource: Memory.Growable & ~Copyable>(
        minimumCapacity: Index<E>.Count = Index<E>.Count(4)
    ) where S == Buffer<Storage<Memory.Allocator<Resource>>.Contiguous<E>>.Linear {
        self.init(column: S(minimumCapacity: minimumCapacity))
    }

    /// Pushes an element onto the top (grow-if-full rides the column's own R-generic append).
    @inlinable
    public mutating func push<E: ~Copyable, Resource: Memory.Growable & ~Copyable>(
        _ element: consuming E
    ) where S == Buffer<Storage<Memory.Allocator<Resource>>.Contiguous<E>>.Linear {
        column.append(element)
    }
}
