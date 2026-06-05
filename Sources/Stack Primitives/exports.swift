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
// Re-export internal modules for consumers.
// Users import Stack_Primitives and get the LIFO-stack discipline: the base
// Stack type + conformances (this module), plus every storage variant
// (Bounded / Static / Small). Per [MOD-005] the base-ops plural doubles as the
// package umbrella.

@_exported public import Stack_Primitive
@_exported public import Stack_Bounded_Primitives
