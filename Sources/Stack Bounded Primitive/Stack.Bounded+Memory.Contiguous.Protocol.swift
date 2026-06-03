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
public import Buffer_Linear_Bounded_Primitive
public import Span_Protocol_Primitives

// MARK: - Span.`Protocol` Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C). The
// memory→Iterable bridge keys off this conformance to vend the borrowing
// `Iterator.Chunk` when the type also declares `: Iterable` (ops module).

extension Stack.Bounded: Span.`Protocol` where Element: ~Copyable {
    /// A read-only view of the stack's elements in bottom-to-top order.
    /// Witness for `Span.\`Protocol\``.
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { _buffer.span }
    }
}
