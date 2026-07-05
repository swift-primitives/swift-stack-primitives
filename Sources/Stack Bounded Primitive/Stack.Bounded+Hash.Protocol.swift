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
public import Hash_Protocol_Primitives
public import Shared_Primitive
public import Index_Primitives
import Ordinal_Primitives

// MARK: - Hash.Protocol Conformance

extension Stack.Bounded: Hash.`Protocol` where Element: Hash.`Protocol` & ~Copyable {
    /// Hashes the count and elements of this bounded stack, in bottom-to-top
    /// order.
    ///
    /// Walks the live prefix through the column's seam subscript (the stored
    /// `Shared` column has no returning span — the former span-keyed witness
    /// is re-expressed as the seam walk, mirroring `Shared`'s own
    /// element-keyed carriers). Count is combined first so the hash agrees
    /// with the equality walk's count guard.
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(Swift.Int(bitPattern: count))
        var slot: Index_Primitives.Index<Element> = .zero
        let end = _buffer.count.map(Ordinal.init)
        while slot < end {
            _buffer[slot].hash(into: &hasher)
            slot += .one
        }
    }
}

#if swift(>=6.4)
// Swift 6.4+ (SE-0499): `Hash.`Protocol`` refines `Swift.Hashable`, and a conditional
// conformance to a refining protocol no longer implies the inherited `Swift.Hashable`
// conformance — state it explicitly. The `hash(into:)` above (through the
// `Hash.`Protocol`` conformance) witnesses it. Matches the swift-product-primitives
// precedent.
extension Stack.Bounded: Swift.Hashable where Element: Hash.`Protocol` & ~Copyable {}
#endif
