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

// MARK: - removeAll()

extension Stack where Element: Copyable {
    /// Removes all elements from the stack.
    @inlinable
    public mutating func removeAll() {
        clear(keepingCapacity: false)
    }
}
