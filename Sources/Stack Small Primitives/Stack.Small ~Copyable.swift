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

// Note: Stack.Small is declared INSIDE the Stack struct body (in Stack.swift)
// due to a Swift compiler bug where nested types with value generic parameters
// declared in extensions do not properly inherit ~Copyable constraints from
// the outer type. This file contains only extensions to Stack.Small.

// MARK: - Properties

extension Stack.Small where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { Int(bitPattern: _buffer.count) }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _buffer.isEmpty }

    /// The current capacity (inline or heap).
    @inlinable
    public var capacity: Int { Int(bitPattern: _buffer.capacity) }
}

// MARK: - Core Operations (Base - for ~Copyable elements)

extension Stack.Small where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// If the stack exceeds inline capacity, elements are moved to heap storage.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) when spilling to heap.
    @inlinable
    public mutating func push(_ element: consuming Element) {
        _buffer.append(element)
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
        return _buffer.removeLast()
    }

    /// Removes all elements from the stack.
    ///
    /// Resets to inline mode if spilled.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        _buffer.removeAll()
    }
}

// Note: Stack.Small is UNCONDITIONALLY ~Copyable due to the deinit requirement
// for inline storage cleanup. No CoW extensions are needed.

// MARK: - Peek

extension Stack.Small where Element: ~Copyable {
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

extension Stack.Small where Element: Copyable {
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

extension Stack.Small where Element: ~Copyable {
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

// MARK: - Element Access

extension Stack.Small where Element: ~Copyable {
    /// Provides access to the element at the given index via closure.
    ///
    /// - Parameters:
    ///   - index: The index of the element (0 = bottom, count-1 = top).
    ///   - body: A closure that receives a borrowed reference to the element.
    /// - Returns: The value returned by the closure.
    /// - Precondition: `index` must be in `0..<count`.
    @inlinable
    public func withElement<R>(
        at index: Int,
        _ body: (borrowing Element) -> R
    ) -> R {
        precondition(index >= 0 && index < Int(bitPattern: _buffer.count), "Index out of bounds")
        let typedIndex = Stack<Element>.Index(__unchecked: (), Ordinal(UInt(index)))
        return body(_buffer[typedIndex])
    }

    /// Provides mutable access to the element at the given index via closure.
    ///
    /// - Parameters:
    ///   - index: The index of the element (0 = bottom, count-1 = top).
    ///   - body: A closure that receives a mutable reference to the element.
    /// - Returns: The value returned by the closure.
    /// - Precondition: `index` must be in `0..<count`.
    @inlinable
    public mutating func withMutableElement<R>(
        at index: Int,
        _ body: (inout Element) -> R
    ) -> R {
        precondition(index >= 0 && index < Int(bitPattern: _buffer.count), "Index out of bounds")
        let typedIndex = Stack<Element>.Index(__unchecked: (), Ordinal(UInt(index)))
        return body(&_buffer[typedIndex])
    }
}

// MARK: - Sendable

/// `Stack.Small` is `Sendable` when its elements are `Sendable`.
extension Stack.Small: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration (for ~Copyable elements)

extension Stack.Small where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    ///
    /// Elements are visited from bottom (oldest) to top (newest).
    ///
    /// - Parameter body: A closure that receives each element.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        var idx: Stack<Element>.Index = .zero
        let end = _buffer.count.map(Ordinal.init)
        while idx < end {
            body(_buffer[idx])
            idx += .one
        }
    }
}

// MARK: - Truncate

extension Stack.Small where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Stack<Element>.Index.Count) {
        guard newCount < _buffer.count else { return }
        while _buffer.count > newCount {
            _ = _buffer.removeLast()
        }
    }
}
