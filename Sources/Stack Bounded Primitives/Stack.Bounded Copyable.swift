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
public import Collection_Primitives
public import Sequence_Primitives
public import Index_Primitives

// MARK: - Swift.Sequence Conformance

/// `Stack.Bounded` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
extension Stack.Bounded: Swift.Sequence where Element: Copyable {

    /// An iterator over the elements of a bounded stack.
    public struct Iterator: IteratorProtocol {
        @usableFromInline
        let _storage: Storage<Element>

        @usableFromInline
        var _index: Stack<Element>.Index = .zero

        @usableFromInline
        init(storage: Storage<Element>) {
            self._storage = storage
        }

        /// Advances to the next element and returns it, or nil if no next element exists.
        @inlinable
        public mutating func next() -> Element? {
            guard _index < Stack<Element>.Index(_storage.count) else { return nil }
            let currentIndex = _index
            _index = _index + .one
            return unsafe _storage.read(at: currentIndex).pointee
        }
    }

    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        Iterator(storage: _storage)
    }

    /// The underestimated count for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: _storage.count) }
}
