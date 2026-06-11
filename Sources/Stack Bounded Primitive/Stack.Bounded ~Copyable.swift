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
public import Shared_Primitive
import Index_Primitives
import Ordinal_Primitives

// The base operation surface, generic over element copyability. Every mutation
// crosses the stored `Shared` column through the gate-first scoped accessor
// (`withUnique` — a no-op gate on the statically-unique `~Copyable`-element
// lane, the CoW restore on the `Copyable`-element lane), so ONE body serves
// both lanes; the hand-rolled `ensureUnique` CoW and its `Copyable` shadow
// methods are deleted (the A-1 reshape — `Shared` supplies CoW). Unlike the
// growable column, `Shared` pins no span forms for the bounded column, so the
// scoped span pair here crosses the box through the generic devices
// (`withColumn` / `withUnique`) — the sanctioned family-pins-its-own-ops path.

// MARK: - Properties

extension Stack.Bounded where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Index_Primitives.Index<Element>.Count { _buffer.count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// The requested capacity of the stack.
    @inlinable
    public var capacity: Index_Primitives.Index<Element>.Count { requestedCapacity }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { _buffer.count >= requestedCapacity }
}

// MARK: - Core Operations

extension Stack.Bounded where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Throws: ``Stack/Bounded/Error/overflow`` if the stack is full
    ///   (the rejected element is destroyed).
    /// - Complexity: O(1), O(n) if a CoW copy is triggered
    @inlinable
    public mutating func push(_ element: consuming Element) throws(__StackBoundedError<Element>) {
        // The stack's contract is the REQUESTED capacity (the physical
        // allocation may round up); reject at the contract bound first.
        guard _buffer.count < requestedCapacity else {
            throw .overflow
        }
        // The payload-threading form ([MEM-OWN-017]): the element crosses the
        // box as a `consuming` closure PARAMETER; the column's `append`
        // returns the rejected element when the physical capacity is
        // exhausted, threaded OUT through the gate (the queue-primitives
        // bounded-enqueue shape).
        let rejected = _buffer.withUnique(consuming: element) { column, element in
            column.append(element)
        }
        guard rejected == nil else {
            throw .overflow
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
        return _buffer.withUnique { .some($0.remove.last()) }
    }

    /// Removes all elements from the stack.
    ///
    /// The capacity remains unchanged.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        _buffer.withUnique { $0.remove.all() }
    }
}

// MARK: - Peek

extension Stack.Bounded where Element: ~Copyable {
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

extension Stack.Bounded where Element: ~Copyable {
    /// Calls `body` with a read-only span over the stack's elements in
    /// bottom-to-top order.
    ///
    /// The scoped form replaces the former `span` property: a returning span
    /// cannot be forwarded out of the stored `Shared` column's class hop (the
    /// coroutine-window rule), so the region view is scoped. Reads never need
    /// the uniqueness gate.
    ///
    /// - Complexity: O(1)
    @inlinable
    public func withSpan<R, Failure: Swift.Error>(
        _ body: (Swift.Span<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try _buffer.withColumn { column throws(Failure) in
            try body(column.span)
        }
    }

    /// Calls `body` with a mutable span over the stack's elements
    /// (CoW-checked FIRST: uniqueness is restored before any mutable view
    /// exists).
    ///
    /// The scoped form replaces the former `mutableSpan` property (the
    /// coroutine-window rule, as above). ONE body serves both element lanes:
    /// the gate inside `withUnique` is the CoW restore on the
    /// `Copyable`-element lane and a no-op on the statically-unique
    /// `~Copyable`-element lane.
    ///
    /// - Complexity: O(1), O(n) if a CoW copy is triggered
    @inlinable
    public mutating func withMutableSpan<R, Failure: Swift.Error>(
        _ body: (inout Swift.MutableSpan<Element>) throws(Failure) -> R
    ) throws(Failure) -> R {
        try _buffer.withUnique { column throws(Failure) in
            var span = column.mutableSpan
            return try body(&span)
        }
    }
}

// MARK: - Truncate

extension Stack.Bounded where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Index_Primitives.Index<Element>.Count) {
        _buffer.withUnique { $0.truncate(to: newCount) }
    }
}
