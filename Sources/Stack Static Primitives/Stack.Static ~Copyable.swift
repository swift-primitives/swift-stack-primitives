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
public import Buffer_Linear_Inline_Primitives
internal import Finite_Primitives

// Note: Stack.Static is declared INSIDE the Stack struct body (in Stack.swift)
// due to a Swift compiler bug where nested types with value generic parameters
// declared in extensions do not properly inherit ~Copyable constraints from
// the outer type. This file contains only extensions to Stack.Static.

// MARK: - Properties

extension Stack.Static where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Stack<Element>.Index.Count { _buffer.count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { _buffer.isFull }
}

// MARK: - Core Operations

extension Stack.Static where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Throws: ``Stack/Static/Error/overflow`` if the stack is full.
    /// - Complexity: O(1)
    @inlinable
    public mutating func push(_ element: consuming Element) throws(__StackStaticError<Element>) {
        if let rejected = _buffer.append(element) {
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
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        _buffer.remove.all()
    }
}

// MARK: - Peek

extension Stack.Static where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    ///
    /// Uses a closure to support `~Copyable` elements via borrowing.
    ///
    /// - Parameter body: A closure that receives a borrowed reference to the top element.
    /// - Returns: The result of the closure, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard !_buffer.isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return body(_buffer[topIndex])
    }
}

extension Stack.Static where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    ///
    /// This is a convenience method for `Copyable` elements. For `~Copyable`
    /// elements, use ``peek(_:)`` with a closure.
    ///
    /// - Returns: A copy of the top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
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

extension Stack.Static where Element: ~Copyable {
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

// MARK: - Sendable

/// `Stack.Static` is `Sendable` when its elements are `Sendable`.
extension Stack.Static: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration

extension Stack.Static where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    ///
    /// Elements are visited from bottom (oldest) to top (newest).
    ///
    /// - Parameter body: A closure that receives each element.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        _buffer.forEach(body)
    }
}

// MARK: - Truncate

extension Stack.Static where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Stack<Element>.Index.Count) {
        _buffer.truncate(to: newCount)
    }
}
