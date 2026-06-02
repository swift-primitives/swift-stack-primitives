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
public import Hash_Primitives_Standard_Library_Integration

// MARK: - Hash.Protocol Conformance

extension Stack.Bounded: Hash.`Protocol` where Element: Hash.`Protocol` & ~Copyable {
    /// Hashes the count and elements of this bounded stack, in bottom-to-top order,
    /// over the span (`Span: Hash.Protocol`, hash-primitives Standard Library Integration).
    @inlinable
    public borrowing func hash(into hasher: inout Hasher) {
        span.hash(into: &hasher)
    }
}
