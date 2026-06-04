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

public import Buffer_Linear_Primitive
public import Span_Protocol_Primitives

// MARK: - Span.`Protocol` Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C;
// conformance-placement decision): `Span.\`Protocol\`` is
// ~Copyable-compatible (`associatedtype Element: ~Copyable`); its single
// requirement `span` is witnessed below (`where Element: ~Copyable`), co-located
// with the type. This is the span capability, NOT iteration:
// the memory→Iterable bridge keys off `Span.\`Protocol\` where Self:
// Iterable` and vends the borrowing `Iterator.Chunk` when the type also declares
// `: Iterable` (in the ops module).

extension Stack: Span.`Protocol` where Element: ~Copyable {
    /// A read-only view of the stack's elements in bottom-to-top order.
    /// Witness for `Span.\`Protocol\``.
    ///
    /// - Complexity: O(1)
    @inlinable
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get { _buffer.span }
    }
}
