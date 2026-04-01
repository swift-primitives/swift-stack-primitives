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

public import Buffer_Linear_Inline_Primitives

extension Stack where Element: ~Copyable {

    // MARK: - Static (Fixed-Capacity, Inline Storage)

    /// A fixed-capacity, inline-storage LIFO stack with compile-time capacity.
    ///
    /// `Stack.Static` stores elements directly within the struct's memory layout,
    /// requiring no heap allocation. The capacity is specified as a compile-time
    /// generic parameter.
    /// Element cleanup is handled by `Storage.Inline`'s deinit.
    public struct Static<let capacity: Int>: ~Copyable {
        @usableFromInline
        package var _buffer: Buffer<Element>.Linear.Inline<capacity>

        /// Creates an empty static stack.
        @inlinable
        public init() {
            self._buffer = .init()
        }
    }
}
