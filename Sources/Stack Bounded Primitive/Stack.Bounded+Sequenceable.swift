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
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Storage_Heap_Primitives
public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Bounded_Primitives

// MARK: - Sequenceable witness (makeIterator)
//
// The single-pass consuming iterator in bottom-to-top order — the `Copyable`
// witness for the cold `Sequenceable` conformance (declared in the ops module).
// A public member in the type module per [MOD-036] refined-C; delegates to the
// composed buffer's public makeIterator.

extension Stack.Bounded where Element: Copyable {

    /// A single-pass consuming iterator in bottom-to-top order. Witness for `Sequenceable`.
    @inlinable
    public consuming func makeIterator() -> Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear.Bounded.Scalar {
        _buffer.makeIterator()
    }
}
