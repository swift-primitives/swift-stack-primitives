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
public import Buffer_Linear_Inline_Primitives

// MARK: - Sequenceable witness (makeIterator)
//
// The single-pass consuming iterator in bottom-to-top order — the `Copyable`
// witness for the cold `Sequenceable` conformance (declared in the ops module).
// A public member in the type module per [MOD-036] refined-C; delegates to the
// composed buffer's public makeIterator. Enabled by `@frozen` on the Static
// struct, which permits the partial consume of `_buffer`.

extension Stack.Static where Element: Copyable {

    /// A single-pass consuming iterator in bottom-to-top order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Element>.Linear.Inline<capacity>.Scalar {
        _buffer.makeIterator()
    }
}
