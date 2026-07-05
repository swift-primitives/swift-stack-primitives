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

public import Buffer_Primitive
public import Buffer_Linear_Primitive
public import Storage_Contiguous_Primitives
public import Memory_Heap_Primitives
public import Memory_Allocator_Primitive

// MARK: - Stack<E> — the CANONICAL front door ([DS-028])

/// A last-in-first-out (LIFO) stack over the default column: the heap-allocated,
/// move-only contiguous linear buffer.
///
/// This is the canonical front-door alias ([DS-028]) — the sanctioned [API-NAME-004]
/// generic-instantiation exception that pins the default column so consumers spell
/// `Stack<Element>`, never the carrier `__Stack` or a full column. The alias fully
/// specializes: conformances, the pinned constructors, and `~Copyable` elements all flow
/// through it with zero forwarding and zero runtime cost.
///
/// ```swift
/// var s = Stack<Int>()          // growable move-only LIFO stack (this alias)
/// s.push(1); s.push(2); s.push(3)
/// let t = s.top                 // 3  (O(1))
/// let removed = s.pop()         // 3  (O(1))
/// ```
///
/// `~Copyable` elements are fully supported (a move-only element flows through
/// push/pop/top); the LIFO discipline is order-free, so no element bound is required.
///
/// Variants live behind nested aliases on the family: `Stack<E>.Bounded` is the
/// fixed-capacity column (Stack.Bounded.swift). The `Shared` (CoW) and `Small`/`Inline`
/// allocation variants are consumer-pulled and land as they gain live consumers
/// ([DS-028] consumer-pulled discipline).
public typealias Stack<E: ~Copyable> =
    __Stack<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.Linear>
