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
public import Ownership_Shared_Primitive
import Index_Primitives
import Ordinal_Primitives

// The base operation surface, generic over element copyability. Every mutation
// crosses the stored `Shared` column through the gate-first scoped accessor
// (`withUnique` — a no-op gate on the statically-unique `~Copyable`-element
// lane, the CoW restore on the `Copyable`-element lane), so ONE body serves
// both lanes; the hand-rolled `ensureUnique` CoW and its `Copyable` shadow
// methods are deleted (the A-1 reshape — `Shared` supplies CoW).

// MARK: - Properties

extension Stack where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Index.Count { _buffer.count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// The current capacity of the stack.
    @inlinable
    public var capacity: Index.Count { _buffer.capacity }
}

// MARK: - Capacity Management

extension Stack where Element: ~Copyable {
    /// Reserves capacity for at least the specified number of elements.
    ///
    /// Use this method to avoid multiple reallocations when adding a known
    /// number of elements.
    ///
    /// - Parameter minimumCapacity: The minimum total capacity to reserve.
    @inlinable
    public mutating func reserve(_ minimumCapacity: Index.Count) {
        _buffer.withUnique { $0.reserveCapacity(minimumCapacity) }
    }
}

// MARK: - Core Operations

extension Stack where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) if a CoW copy is triggered
    @inlinable
    public mutating func push(_ element: consuming Element) {
        // The payload-threading form: a `consuming` parameter cannot be
        // consumed inside a closure capture ([MEM-OWN-017]), so the element
        // crosses the box as a `consuming` closure PARAMETER.
        _buffer.withUnique(consuming: element) { column, element in
            column.append(element)
        }
    }

    /// Pops and returns the top element, or nil if empty.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1), O(n) if a CoW copy is triggered
    @inlinable
    public mutating func pop() -> Element? {
        guard !isEmpty else {
            return nil
        }
        return _buffer.withUnique { .some($0.removeLast()) }
    }

    /// Removes all elements from the stack.
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        _buffer.withUnique { $0.removeAll(keepingCapacity: keepingCapacity) }
    }
}

// MARK: - Peek

extension Stack where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    ///
    /// Uses a closure to support `~Copyable` elements via borrowing.
    ///
    /// - Parameter body: A closure that receives a borrowed reference to the top element.
    /// - Returns: The result of the closure, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard !isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return body(_buffer[topIndex])
    }
}

// MARK: - Scoped Span Access

extension Stack where Element: ~Copyable {
    /// Calls `body` with a read-only span over the stack's elements in
    /// bottom-to-top order.
    ///
    /// The scoped form replaces the former `span` property: a returning span
    /// cannot be forwarded out of the stored `Shared` column's class hop (the
    /// coroutine-window rule), so the region view is scoped.
    ///
    /// - Complexity: O(1)
    @inlinable
    public func withSpan<R, Failure: Swift.Error>(
        _ body: (Swift.Span<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try _buffer.withSpan(body)
    }

    /// Calls `body` with a mutable span over the stack's elements
    /// (statically-unique `~Copyable`-element lane).
    ///
    /// The scoped form replaces the former `mutableSpan` property (the
    /// coroutine-window rule, as above). The stack is move-only for
    /// `~Copyable` elements, so its box is statically unique — the
    /// assuming-unique lane is sound by construction (the Array precedent).
    ///
    /// - Complexity: O(1)
    @inlinable
    public mutating func withMutableSpan<R, Failure: Swift.Error>(
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try _buffer.withMutableSpanAssumingUnique(body)
    }
}

// MARK: - Capacity Management (Additional)

extension Stack where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Index.Count) {
        _buffer.withUnique { $0.truncate(to: newCount) }
    }
}
