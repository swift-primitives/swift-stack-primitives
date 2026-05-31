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
public import Buffer_Linear_Bounded_Primitives
import Ordinal_Primitives

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack.Bounded where Element: Copyable {
    /// Pushes an element onto the stack (CoW-aware).
    @inlinable
    public mutating func push(_ element: Element) throws(__StackBoundedError<Element>) {
        guard _buffer.count < requestedCapacity else {
            throw .overflow
        }
        if let rejected = _buffer.append(element) {
            _ = rejected
            throw .overflow
        }
    }

    /// Pops and returns the top element, or nil if empty (CoW-aware).
    @inlinable
    public mutating func pop() -> Element? {
        guard !_buffer.isEmpty else {
            return nil
        }
        return _buffer.remove.last()
    }

    /// Removes all elements from the stack (CoW-aware).
    @inlinable
    public mutating func clear() {
        _buffer.remove.all()
    }
}

// MARK: - Peek

extension Stack.Bounded where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    @inlinable
    public func peek() -> Element? {
        guard !_buffer.isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return _buffer[topIndex]
    }
}

// MARK: - CoW-aware MutableSpan (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// A mutable view of the stack's elements (CoW-aware).
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get {
            _buffer.mutableSpan
        }
    }
}

// MARK: - CoW-aware Truncate (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// Removes elements beyond the specified count (CoW-aware).
    @inlinable
    public mutating func truncate(to newCount: Stack<Element>.Index.Count) {
        _buffer.truncate(to: newCount)
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
        _buffer.ensureUnique()
        while !_buffer.isEmpty {
            body(_buffer.remove.last())
        }
    }

    /// Drains elements in LIFO order while the predicate returns true.
    @inlinable
    public mutating func drain(
        while predicate: (borrowing Element) -> Bool,
        _ body: (consuming Element) -> Void
    ) {
        _buffer.ensureUnique()
        while let element = peek(), predicate(element) {
            body(pop()!)
        }
    }
}
