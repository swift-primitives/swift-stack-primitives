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
public import Stack_Primitive

// MARK: - Sequence.Drain.Protocol Conformance

extension Stack: Sequence.Drain.`Protocol` where Element: Copyable {
    // drain(_ body:) method already exists in Stack Copyable.swift (type module).
    // This extension declares conformance to the protocol.
}

// MARK: - Drain Property Accessor

extension Stack where Element: Copyable {
    /// Accessor for drain operations.
    ///
    /// Draining removes all elements from the stack, passing each to a closure
    /// with ownership transferred. The stack survives but is empty after draining.
    ///
    /// ```swift
    /// var stack = Stack<Int>()
    /// stack.push(1)
    /// stack.push(2)
    /// stack.drain { element in
    ///     print(element)  // ownership transferred
    /// }
    /// // stack is now empty but still usable
    /// stack.push(10)  // OK
    /// ```
    public var drain: Property<Sequence.Drain, Stack>.Inout {
        mutating _read {
            yield Property<Sequence.Drain, Stack>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Sequence.Drain, Stack>.Inout(&self)
            yield &accessor
        }
    }
}
