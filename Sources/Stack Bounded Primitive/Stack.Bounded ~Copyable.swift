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

// MARK: - Properties

extension Stack.Bounded where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Stack<Element>.Index.Count { _buffer.count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// The requested capacity of the stack.
    @inlinable
    public var capacity: Stack<Element>.Index.Count { requestedCapacity }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { _buffer.count >= requestedCapacity }
}

// MARK: - Core Operations (Base - for ~Copyable elements)

extension Stack.Bounded where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Throws: ``Stack/Bounded/Error/overflow`` if the stack is full.
    /// - Complexity: O(1)
    @inlinable
    public mutating func push(_ element: consuming Element) throws(__StackBoundedError<Element>) {
        guard _buffer.count < requestedCapacity else {
            throw .overflow
        }
        if let rejected = _buffer.append(element) {
            // Buffer was full at the actual allocated capacity level — shouldn't happen
            // if requestedCapacity <= actual capacity, but handle gracefully
            _ = consume rejected
            throw .overflow
        }
    }

    /// Pops and returns the top element, or nil if empty.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func pop() -> Element? {
        guard !_buffer.isEmpty else {
            return nil
        }
        return _buffer.remove.last()
    }

    /// Removes all elements from the stack.
    ///
    /// The capacity remains unchanged.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        _buffer.remove.all()
    }
}

// MARK: - Peek

extension Stack.Bounded where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard !_buffer.isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return body(_buffer[topIndex])
    }
}

// MARK: - Span Access

extension Stack.Bounded where Element: ~Copyable {
    /// A mutable view of the stack's elements.
    ///
    /// Forwards `Buffer.Linear.Bounded`'s form-α `mutableSpan()` *method* (D1).
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get {
            _buffer.mutableSpan()
        }
    }
}

// MARK: - Truncate

extension Stack.Bounded where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    @inlinable
    public mutating func truncate(to newCount: Stack<Element>.Index.Count) {
        _buffer.truncate(to: newCount)
    }
}
