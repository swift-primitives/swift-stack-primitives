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

public import Buffer_Linear_Bounded_Primitive
public import Buffer_Linear_Primitive
public import Buffer_Primitive
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Storage_Primitive
public import Store_Protocol_Primitives

// MARK: - Stack<E>.Bounded — the CAPACITY variant ([DS-028])

extension __Stack where S: Store.Direct, S: ~Copyable {

    /// A fixed-capacity LIFO stack: the bounded linear column (rejects on overflow
    /// with typed throws at the family surface — the dissolved former hand-written
    /// `Stack.Bounded` type, §9.6.4).
    ///
    /// This is a capacity-axis variant alias ([DS-028] law 2): `Stack<Element>.Bounded`
    /// maps the canonical carrier's column through the **capacity twin** —
    /// `__Stack<S.Bounded>` — so it is **column-PRESERVING**: for the default linear
    /// column `S.Bounded` is `Buffer.Linear.Bounded` (the linear discipline's own
    /// bounded twin), never a Heap-hardcoded rebuild. A cross-axis chain from a
    /// non-heap direct column therefore keeps its axis instead of silently resetting
    /// it. `Element` is inherited from the member it is named on. Push on the bounded
    /// column throws `Error.full` (the decreed `throws(Overflow)` op form under the
    /// D4.1 variant test — a form difference, not a sibling).
    ///
    /// The `where S: Store.Direct` fence ([DS-028] law 1) is what makes the twin
    /// available; the alias body is generic over `S.Bounded`, so it names no concrete
    /// bounded type here (consumers resolving `Stack<E>.Bounded` see the concrete
    /// `Buffer.Linear.Bounded` through the carrier's own `Buffer Linear Bounded
    /// Primitive` re-export).
    public typealias Bounded = __Stack<S.Bounded>
}

// MARK: - Bounded construction + growth (column-pinned; the observation/removal ops
// ride the shared seam surface in Stack.swift — only push/init pin per column)

extension __Stack where S: ~Copyable {

    /// Creates an empty fixed-capacity stack (the bounded linear column).
    @inlinable
    public init<E: ~Copyable>(capacity: Index<E>.Count)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear.Bounded {
        self.init(column: S(minimumCapacity: capacity))
    }

    /// Pushes an element onto the top of a bounded stack.
    ///
    /// - Throws: `Error.full` when the fixed capacity is exhausted (the rejected
    ///   element is destroyed — the bounded-column contract).
    /// - Complexity: O(1)
    @inlinable
    public mutating func push<E: ~Copyable>(_ element: consuming E) throws(Error)
    where S == Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear.Bounded {
        guard column.append(element) == nil else {
            throw .full
        }
    }
}
