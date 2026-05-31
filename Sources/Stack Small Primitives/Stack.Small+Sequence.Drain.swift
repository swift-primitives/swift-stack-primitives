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

internal import Property_Primitives
import Sequence_Primitives
public import Stack_Small_Primitive

// MARK: - Sequence.Drain.Protocol Conformance

extension Stack.Small: Sequence.Drain.`Protocol` where Element: Copyable {
    // drain(_ body:) method already exists in Stack.Small ~Copyable.swift (type module).
    // This extension declares conformance to the protocol.
}

// MARK: - Drain Property Accessor

extension Stack.Small where Element: Copyable {
    /// Accessor for drain operations.
    public var drain: Property<Sequence.Drain, Self>.Inout {
        mutating _read {
            yield Property<Sequence.Drain, Self>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Sequence.Drain, Self>.Inout(&self)
            yield &accessor
        }
    }
}
