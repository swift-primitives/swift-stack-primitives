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
public import Memory_Contiguous_Primitives

// MARK: - Memory.Contiguous.Protocol Conformance
//
// Co-located with the type and its span witness ([MOD-036] refined-C;
// conformance-placement decision): `Memory.Contiguous.Protocol` is
// ~Copyable-compatible (`associatedtype Element: ~Copyable`); its single
// requirement `span` is witnessed below (`where Element: ~Copyable`), co-located
// with the type. This is the memory-layer span capability, NOT iteration:
// the memory→Iterable bridge keys off `Memory.ContiguousProtocol where Self:
// Iterable` and vends the borrowing `Iterator.Chunk` when the type also declares
// `: Iterable` (in the ops module).

extension Stack: Memory.Contiguous.`Protocol` where Element: ~Copyable {
    /// A read-only view of the stack's elements in bottom-to-top order.
    /// Witness for `Memory.Contiguous.Protocol`.
    ///
    /// - Complexity: O(1)
    @inlinable
    public var span: Span<Element> {
        @_lifetime(borrow self)
        borrowing get { _buffer.span }
    }
}
