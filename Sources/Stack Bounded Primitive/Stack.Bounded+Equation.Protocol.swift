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
public import Equation_Protocol_Primitives
public import Shared_Primitive
public import Index_Primitives
import Ordinal_Primitives

// MARK: - Equation.Protocol Conformance

extension Stack.Bounded: Equation.`Protocol` where Element: Equation.`Protocol` & ~Copyable {
    /// Compares two bounded stacks for element-wise, ordered-sequence equality
    /// (bottom-to-top).
    ///
    /// Walks the live prefix through the column's seam subscript (the stored
    /// `Shared` column has no returning span — the former span-keyed witness
    /// is re-expressed as the seam walk, mirroring `Shared`'s own
    /// element-keyed carriers).
    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        guard lhs._buffer.count == rhs._buffer.count else { return false }
        var slot: Index_Primitives.Index<Element> = .zero
        let end = lhs._buffer.count.map(Ordinal.init)
        while slot < end {
            guard lhs._buffer[slot] == rhs._buffer[slot] else { return false }
            slot += .one
        }
        return true
    }
}
