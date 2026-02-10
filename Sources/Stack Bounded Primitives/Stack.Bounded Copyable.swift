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
internal import Collection_Primitives
internal import Sequence_Primitives

// MARK: - Swift.Sequence Conformance

/// `Stack.Bounded` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
extension Stack.Bounded: Swift.Sequence where Element: Copyable {

    /// An iterator over the elements of a bounded stack.
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

        var idx: Stack<Element>.Index = .zero
        let end = _buffer.count.map(Ordinal.init)
        while idx < end {
            elements.append(_buffer[idx])
            idx += .one
        }
        return Iterator(elements: elements)
    }

    /// The underestimated count for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: _buffer.count) }
}
