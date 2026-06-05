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
public import Storage_Small_Primitives
public import Storage_Primitive
public import Stack_Small_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// MARK: - Sequenceable (single-pass, consuming)
//
// Re-uses Buffer<Storage<E>.Small<n>>.Linear.Scalar (the absorbed substrate's scalar;
// #12a/#5a). The consuming `makeIterator()` witness is a public member in the type module
// per [MOD-036] refined-C; this conformance is thin. `Stack.Small` does not conform to
// `Swift.Sequence` (DEFERRED interop axis).

extension Stack.Small: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Storage<Element>.Small<inlineCapacity>>.Linear.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
