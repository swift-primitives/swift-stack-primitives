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

public import Iterable
public import Iterator_Chunk_Primitives
public import Stack_Primitive
import Memory_Iterator_Primitives

// MARK: - Iterable (multipass, borrowing)
//
// The multipass borrowing `makeIterator()` is vended FOR FREE by the memory→Iterable
// bridge over the `Memory.Contiguous.Protocol` conformance (type module), yielding
// `Iterator.Chunk` — no hand-written iterator. The `@_implements(Iterable, Iterator)`
// escape hatch binds Iterable's `Iterator` to `Iterator.Chunk`, leaving Sequenceable's
// binding to the sibling Stack+Sequenceable.swift. `forEach` is inherited from the
// Iterable floor.

extension Stack: Iterable where Element: ~Copyable {
    @_implements(Iterable, Iterator)
    public typealias IterableIterator = Iterator_Chunk_Primitives.Iterator.Chunk<Element>
}
