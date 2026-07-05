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
public import Buffer_Linear_Bounded_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Ownership_Shared_Primitive
import Index_Primitives
import Ordinal_Primitives

// The `Copyable`-element extras: surfaces that COPY elements out (`peek()`) or
// drain with ownership transfer. The former CoW SHADOWS of the base ops
// (`push` / `pop` / `clear` / `truncate` / the mutable span) are deleted: the
// base bodies cross the `Shared` column through the `withUnique` gate, which
// IS the CoW restore for `Copyable` elements — one body now serves both lanes
// (the A-1 reshape).

// MARK: - Peek

extension Stack.Bounded where Element: Copyable {
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

// MARK: - Drain (Copyable)

extension Stack.Bounded where Element: Copyable {
    /// Drains all elements, passing each to the closure with ownership.
    ///
    /// After this method returns, the stack is empty but still usable.
    /// The capacity remains unchanged.
    ///
    /// - Parameter body: A closure that receives each drained element with ownership.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        _buffer.withUnique { column in
            while !column.isEmpty {
                body(column.remove.last())
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
                body(column.remove.last())
            }
        }
    }
}
