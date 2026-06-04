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
public import Storage_Heap_Primitives
public import Stack_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Linear_Primitives

// MARK: - Sequenceable (single-pass, consuming)
//
// Re-uses Buffer.Linear.Scalar (single-pass, consuming), mirroring buffer-linear.
// The consuming `makeIterator()` witness is a public member in the type module
// (Stack+Sequenceable.swift) per [MOD-036] refined-C; this conformance is thin.
//
// `Stack` does not conform to `Swift.Sequence`: the span-primitive iteration
// family is `~Copyable, ~Escapable` end-to-end and cannot back a Copyable stdlib
// `IteratorProtocol` without re-introducing a per-type Copyable iterator (deleted
// in the SE-0516 migration). This is the DEFERRED `Swift.Sequence`-interop axis
// settled ecosystem-wide.

extension Stack: Sequenceable where Element: Copyable {
    @_implements(Sequenceable, Iterator)
    public typealias SequenceableIterator = Buffer<Storage<Element>.Heap>.Linear.Scalar

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}
