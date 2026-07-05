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

import Stack_Primitives

// The single ratified column: the canonical `Stack<E>` front door rides the DIRECT,
// heap-allocated contiguous linear column (move-only). No `Shared` (CoW) column is
// pulled (no live consumer), so the stack family has one tower subject:
// `tower.direct`. This is the ADT-tower W2 reshape's before/after axis vs the
// pre-reshape `tower.stack` (element-generic, hand-rolled CoW) baselines
// (tower-family-benchmark-baselines.md, tip f648181).
//
// `stdlib` is `Swift.Array` used as a LIFO stack (`append` / `removeLast`) — the
// honest reference; the delta is the tower's typed-slot seam machinery vs stdlib's
// `Array` subscript.

typealias TowerStack = Stack<Int>
