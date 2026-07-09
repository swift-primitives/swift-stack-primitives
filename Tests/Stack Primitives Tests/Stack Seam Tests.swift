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

import Buffer_Linear_Bounded_Primitive
import Buffer_Linear_Primitive
import Buffer_Primitive
import Buffer_Primitives_Test_Support
import Index_Primitives
import Memory_Allocator_Primitive
import Memory_Heap_Primitives
import Stack_Primitives
import Storage_Contiguous_Primitives
import Storage_Primitive
import Testing

// MARK: - [DS-024] Seam.Ledger law — per front-door column
//
// `Stack<E>` pins the direct, heap-allocated contiguous linear column; `Stack<E>.Bounded`
// pins its fixed-capacity twin. [DS-024] requires every column consumed as an ADT storage
// column to keep `count` honest through its seam ops (initialize +1, move -1, subscript
// unchanged, capacity untouched) and to PROVE it by running `Seam.Ledger.violations` from
// its own suite — the type system cannot express the contract the seam-generic pop/top
// machinery relies on. Both front-door columns are proven here.

private typealias StackColumn<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear

private typealias StackBoundedColumn<E: ~Copyable> =
    Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear.Bounded

@Suite
struct `Stack Seam Tests` {

    @Test
    func `[DS-024] Seam.Ledger laws hold for the canonical Stack column`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { StackColumn<Int>(minimumCapacity: Index<Int>.Count(4)) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test
    func `[DS-024] Seam.Ledger laws hold for the Stack.Bounded column`() {
        let violations = Seam.Ledger.violations(
            makeEmpty: { StackBoundedColumn<Int>(minimumCapacity: Index<Int>.Count(64)) },
            element: { $0 }
        )
        #expect(violations.isEmpty, "\(violations)")
    }
}
