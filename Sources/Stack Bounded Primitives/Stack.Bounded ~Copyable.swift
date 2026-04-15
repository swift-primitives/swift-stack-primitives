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

public import Stack_Primitives_Core
public import Buffer_Linear_Primitives

// Note: Conditional Copyable conformance is in Stack.swift (must be same file as declaration)

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

// MARK: - Span Access

extension Stack.Bounded where Element: ~Copyable {
    /// A read-only view of the stack's elements.
    public var span: Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get {
            let span = _buffer.span
            return unsafe _overrideLifetime(span, borrowing: self)
        }
    }

    /// A mutable view of the stack's elements.
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            _buffer.mutableSpan
        }
    }
}

// MARK: - CoW-aware MutableSpan (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// A mutable view of the stack's elements (CoW-aware).
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            _buffer.mutableSpan
        }
    }
}

// MARK: - Sendable

/// Sendable conformance for `Stack.Bounded`.
///
/// ## Safety Invariant
///
/// `Stack.Bounded` is `~Copyable`. Single ownership is enforced by the type
/// system; the fixed-capacity `Buffer<Element>.Linear.Bounded` it owns
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

// MARK: - Iteration (for ~Copyable elements)

extension Stack.Bounded where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        _buffer.forEach(body)
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

// MARK: - CoW-aware Truncate (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// Removes elements beyond the specified count (CoW-aware).
    @inlinable
    public mutating func truncate(to newCount: Stack<Element>.Index.Count) {
        _buffer.truncate(to: newCount)
    }
}
