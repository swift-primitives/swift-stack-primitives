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
    public typealias Iterator = Buffer<Element>.Linear.Bounded.Iterator

    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        _buffer.makeIterator()
    }

    /// The underestimated count for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { Int(clamping: _buffer.count) }
}
