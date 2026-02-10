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

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack where Element: Copyable {
    /// Pushes an element onto the stack (CoW-aware).
    ///
    /// This method shadows the base `push(_:)` when `Element: Copyable`,
    /// providing copy-on-write semantics.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) if copy triggered
    @inlinable
    public mutating func push(_ element: Element) {
        _buffer.append(element)
    }

    /// Pops and returns the top element, or nil if empty (CoW-aware).
    ///
    /// This method shadows the base `pop()` when `Element: Copyable`,
    /// providing copy-on-write semantics.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1), O(n) if copy triggered
    @inlinable
    public mutating func pop() -> Element? {
        guard !_buffer.isEmpty else {
            return nil
        }
        return _buffer.removeLast()
    }

    /// Removes all elements from the stack (CoW-aware).
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        _buffer.removeAll()

        if !keepingCapacity {
            _buffer = Buffer<Element>.Linear(minimumCapacity: .zero)
        }
    }
}

// MARK: - Peek

extension Stack {
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

// MARK: - CoW-aware MutableSpan (Copyable elements)

extension Stack where Element: Copyable {
    /// A mutable view of the stack's elements (CoW-aware).
    ///
    /// This shadows the base `mutableSpan` when `Element: Copyable`,
    /// ensuring copy-on-write semantics before mutation.
    ///
    /// - Complexity: O(1), O(n) if CoW copy triggered
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            _buffer.mutableSpan
        }
    }
}

// MARK: - Sequence (Copyable elements only)

/// `Stack` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
extension Stack: Swift.Sequence where Element: Copyable {

    /// An iterator over the elements of a stack.
    public struct Iterator: IteratorProtocol {
        @usableFromInline
        var _elements: [Element]

        @usableFromInline
        var _position: Int

        @usableFromInline
        init(elements: [Element]) {
            self._elements = elements
            self._position = 0
        }

        /// Advances to the next element and returns it, or nil if no next element exists.
        @inlinable
        public mutating func next() -> Element? {
            guard _position < _elements.count else { return nil }
            let result = _elements[_position]
            _position += 1
            return result
        }
    }

    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        var elements: [Element] = []
        elements.reserveCapacity(Int(bitPattern: _buffer.count))

        var idx: Index = .zero
        let end = _buffer.count.map(Ordinal.init)
        while idx < end {
            elements.append(_buffer[idx])
            idx += .one
        }
        return Iterator(elements: elements)
    }

    /// The underestimatedCount for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: _buffer.count) }
}

// MARK: - CoW-aware Capacity Management (Copyable elements)

extension Stack where Element: Copyable {
    /// Reduces capacity to match the current count, releasing unused memory (CoW-aware).
    ///
    /// After calling this method, `capacity == count`.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func compact() {
        let currentCount = _buffer.count
        guard _buffer.capacity > currentCount else { return }

        if currentCount == .zero {
            _buffer = Buffer<Element>.Linear(minimumCapacity: .zero)
            return
        }

        var newBuffer = Buffer<Element>.Linear(minimumCapacity: currentCount)
        var idx: Index = .zero
        let end = currentCount.map(Ordinal.init)
        while idx < end {
            newBuffer.append(_buffer[idx])
            idx += .one
        }
        _buffer = newBuffer
    }

    /// Removes elements beyond the specified count (CoW-aware).
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Int) {
        let targetCount = Index.Count(clamping: newCount)
        guard targetCount < _buffer.count else { return }
        while _buffer.count > targetCount {
            _ = _buffer.removeLast()
        }
    }
}
