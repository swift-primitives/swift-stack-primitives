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
public import Sequence_Primitives
public import Property_Primitives

// MARK: - Swift.Sequence Conformance

/// `Stack.Bounded` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
extension Stack.Bounded: Swift.Sequence where Element: Copyable {}

// ============================================================================
// MARK: - Iterator
// ============================================================================

extension Stack.Bounded where Element: Copyable {
    /// Pointer-based iterator for Stack.Bounded.
    ///
    /// Zero-copy iteration using typed `Index<Element>` for position tracking.
    @safe
    public struct Iterator: Sequence.Iterator.`Protocol`, IteratorProtocol {
        @usableFromInline
        let _buffer: Buffer<Element>.Linear.Bounded

        @usableFromInline
        let _end: Stack<Element>.Index.Count

        @usableFromInline
        var _position: Stack<Element>.Index

        @usableFromInline
        var _spanBuffer: [Element] = []

        @usableFromInline
        init(_buffer: Buffer<Element>.Linear.Bounded) {
            self._buffer = _buffer
            self._end = _buffer.count
            self._position = .zero
        }

        @_lifetime(&self)
        @inlinable
        public mutating func nextSpan(maximumCount: Cardinal) -> Span<Element> {
            _spanBuffer.removeAll(keepingCapacity: true)
            var remaining = Int(maximumCount.rawValue)
            while remaining > 0, _position < _end {
                _spanBuffer.append(_buffer[_position])
                _position += .one
                remaining -= 1
            }
            return _spanBuffer.span
        }

        @_lifetime(self: immortal)
        @inlinable
        public mutating func next() -> Element? {
            guard _position < _end else { return nil }
            let element = _buffer[_position]
            _position += .one
            return element
        }
    }
}

extension Stack.Bounded.Iterator: @unchecked Sendable where Element: Sendable {}

// ============================================================================
// MARK: - Sequence.Protocol Conformance
// ============================================================================

extension Stack.Bounded: Sequence.`Protocol` where Element: Copyable {
    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        Iterator(_buffer: _buffer)
    }

    /// Returns the count as the underestimated count since we know the exact size.
    ///
    /// This explicit implementation resolves ambiguity between Swift.Sequence
    /// and Sequence.Protocol+Swift.Sequence default implementation.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}

// ============================================================================
// MARK: - Sequence.Clearable Conformance
// ============================================================================

extension Stack.Bounded: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the stack.
    ///
    /// The capacity remains unchanged.
    /// This enables `.forEach.consuming { }` pattern via `Property.View` extension.
    @inlinable
    public mutating func removeAll() {
        clear()
    }
}

// ============================================================================
// MARK: - Sequence.Drain.Protocol Conformance
// ============================================================================

extension Stack.Bounded: Sequence.Drain.`Protocol` where Element: Copyable {
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
}

// MARK: - Conditional Drain

extension Stack.Bounded where Element: Copyable {
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

// ============================================================================
// MARK: - Drain Property Accessor
// ============================================================================

extension Stack.Bounded where Element: Copyable {
    /// Accessor for drain operations.
    public var drain: Property<Sequence.Drain, Stack.Bounded>.View {
        mutating _read {
            yield unsafe Property<Sequence.Drain, Stack.Bounded>.View(&self)
        }
        mutating _modify {
            var view = unsafe Property<Sequence.Drain, Stack.Bounded>.View(&self)
            yield &view
        }
    }
}
