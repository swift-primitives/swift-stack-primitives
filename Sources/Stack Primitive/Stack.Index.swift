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

public import Index_Primitives

extension Stack where Element: ~Copyable {
    /// Type-safe index for stack elements.
    ///
    /// Uses `Index<Element>` to provide compile-time safety preventing
    /// cross-collection index confusion.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stackIdx: Stack<Int>.Index = 0
    /// let queueIdx: Queue<Int>.Index = 0
    /// // stackIdx == queueIdx  // Does not compile - different types
    /// ```
    ///
    /// ## Position Semantics
    ///
    /// Position 0 is the bottom of the stack (oldest element).
    /// The last position is the top (newest element).
    public typealias Index = Index_Primitives.Index<Element>
}
