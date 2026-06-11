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
public import Shared_Primitive
public import Buffer_Linear_Primitive

// MARK: - forEach (scoped traversal)
//
// The `Iterable` conformance is withdrawn at the A-1 interim reshape: the
// memory→Iterable bridge rides the `Span.`Protocol`` conformance, and the
// stored `Shared` column has no returning span (scoped forms only). `forEach`
// — the floor's advertised traversal — survives as a plain member over the
// column's scoped borrowing access; the lattice membership re-materializes
// when `Shared` gains a span conformance upstream (recorded as future work).

extension Stack where Element: ~Copyable {
    /// Calls `body` with a borrow of each element, in bottom-to-top order.
    ///
    /// - Parameter body: A closure that receives each element borrowed in place.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public func forEach<E: Swift.Error>(
        _ body: (borrowing Element) throws(E) -> Void
    ) throws(E) {
        try _buffer.withColumn { column throws(E) in
            try column.forEach(body)
        }
    }
}
