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
// The package umbrella ([MOD-005]): consumers import `Stack_Primitives` and get
// the LIFO stack ADT — the bound-free carrier `__Stack<S>` + the canonical front
// door `Stack<E>` + the `.Bounded` capacity variant (the ADT-tower W2 shape).
//
// The former hand-written `Stack.Bounded` TYPE and the Builder / Static / Small /
// Sequence variant surface are DELETED (§9.6.4; the 2026-06-23 directive).
// `.Bounded` is now the capacity-twin front-door alias on the carrier.

@_exported public import Stack_Primitive
