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

// exports.swift
// Re-exports for Stack Primitive — the ADT-tower carrier module.
// Declares the bound-free carrier `__Stack<S: ~Copyable>` (Stack.swift) + the
// canonical front-door alias `Stack<E>` (Stack.FrontDoor.swift) + the `.Bounded`
// capacity variant (Stack.Bounded.swift) + the per-family `Stack.Error`
// (Stack.Error.swift); re-exports the seams + the default linear/bounded/heap
// column vocabulary the front doors and the seam-generic ops compose.

@_exported public import Store_Protocol_Primitives
@_exported public import Buffer_Protocol_Primitives
@_exported public import Buffer_Primitive
@_exported public import Buffer_Linear_Primitive
@_exported public import Buffer_Linear_Bounded_Primitive
@_exported public import Storage_Contiguous_Primitives
@_exported public import Memory_Heap_Primitives
@_exported public import Memory_Allocator_Primitive
@_exported public import Index_Primitives
