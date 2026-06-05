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

public import Sequence_Primitives
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Storage_Heap_Primitives
public import Stack_Static_Primitive
public import Buffer_Linear_Inline_Primitives

// MARK: - Sequenceable (single-pass, consuming)
//
// Re-uses Buffer.Linear.Inline.Scalar. The consuming `makeIterator()` witness is a
// public member in the type module per [MOD-036] refined-C; this conformance is thin.
// `Stack.Static` does not conform to `Swift.Sequence` (DEFERRED interop axis).

extension Stack.Static: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear.Inline<capacity>.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
