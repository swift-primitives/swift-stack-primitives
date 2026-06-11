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

public import Hash_Primitives_Standard_Library_Integration
public import Shared_Primitive
public import Index_Primitives
import Ordinal_Primitives

// MARK: - Hash.Protocol Conformance

extension Stack: Hash.`Protocol` where Element: Hash.`Protocol` & ~Copyable {
    /// Hashes the count and elements of this stack, in bottom-to-top order.
    ///
    /// Walks the live prefix through the column's seam subscript (the stored
    /// `Shared` column has no returning span — the former span-keyed witness
    /// is re-expressed as the seam walk, mirroring `Shared`'s own
    /// element-keyed carriers). Count is combined first so the hash agrees
    /// with the equality walk's count guard.
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(Swift.Int(bitPattern: count))
        var slot: Index = .zero
        let end = _buffer.count.map(Ordinal.init)
        while slot < end {
            _buffer[slot].hash(into: &hasher)
            slot += .one
        }
    }
}
