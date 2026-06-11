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
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Shared_Primitive
import Index_Primitives
import Ordinal_Primitives

// The `Copyable`-element extras: surfaces that COPY elements out (`peek()`),
// reshape storage through the CoW lane (`compact`, the gated `withMutableSpan`),
// or drain with ownership transfer. The former CoW SHADOWS of the base ops
// (`push` / `pop` / `clear` / `truncate`) are deleted: the base bodies cross the
// `Shared` column through the `withUnique` gate, which IS the CoW restore for
// `Copyable` elements — one body now serves both lanes (the A-1 reshape).

// MARK: - Peek

extension Stack where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    ///
    /// This is a convenience method for `Copyable` elements. For `~Copyable`
    /// elements, use ``peek(_:)`` with a closure.
    ///
    /// - Returns: A copy of the top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek() -> Element? {
        guard !isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return _buffer[topIndex]
    }
}

// MARK: - CoW-gated MutableSpan (Copyable elements)

extension Stack where Element: Copyable {
    /// Calls `body` with a mutable span over the stack's elements
    /// (CoW-checked FIRST: uniqueness is restored before any mutable view
    /// exists).
    ///
    /// This shadows the base `withMutableSpan` when `Element: Copyable`,
    /// routing through the column's uniqueness gate.
    ///
    /// - Complexity: O(1), O(n) if a CoW copy is triggered
    @inlinable
    public mutating func withMutableSpan<R, Failure: Swift.Error>(
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try _buffer.withMutableSpan(body)
    }
}

// MARK: - Capacity Management (Copyable elements)

extension Stack where Element: Copyable {
    /// Reduces capacity to match the current count, releasing unused memory.
    ///
    /// After calling this method, `capacity == count`.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func compact() {
        guard _buffer.capacity > _buffer.count else { return }
        _buffer.reallocate(capacity: _buffer.count)
    }
}

// MARK: - Drain (Copyable)

extension Stack where Element: Copyable {
    /// Drains all elements, passing each to the closure with ownership.
    ///
    /// After this method returns, the stack is empty but still usable.
    /// Elements are drained from the top (newest) downward.
    ///
    /// - Parameter body: A closure that receives each drained element with ownership.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        _buffer.withUnique { column in
            while !column.isEmpty {
                body(column.removeLast())
            }
        }
    }

    /// Drains elements in LIFO order while the predicate returns true.
    ///
    /// Repeatedly peeks at the top element; if the predicate returns true,
    /// pops (consumes) the element and passes it to body; if false, stops.
    /// The stack survives with remaining elements intact.
    ///
    /// - Parameters:
    ///   - predicate: A closure that receives a borrowed reference to the top element.
    ///     Return `true` to drain it, `false` to stop.
    ///   - body: A closure that receives each drained element with ownership.
    /// - Complexity: O(k) where k is the number of elements drained.
    @inlinable
    public mutating func drain(
        while predicate: (borrowing Element) -> Bool,
        _ body: (consuming Element) -> Void
    ) {
        _buffer.withUnique { column in
            while !column.isEmpty {
                let topIndex = column.count.subtract.saturating(.one).map(Ordinal.init)
                guard predicate(column[topIndex]) else { return }
                body(column.removeLast())
            }
        }
    }
}
