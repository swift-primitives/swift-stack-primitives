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

public import Stack_Primitives_Core
public import Sequence_Primitives

// MARK: - Sequence.Protocol Conformance (Stack)

/// `Stack` conforms to `Sequence.Protocol` when `Element` is `Copyable`.
///
/// The `makeIterator()` method is defined in Stack.swift alongside
/// the `Swift.Sequence` conformance.
extension Stack: Sequence.`Protocol` where Element: Copyable {}

// MARK: - Sequence.Clearable Conformance (Stack)

extension Stack: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the stack.
    @inlinable
    public mutating func removeAll() {
        clear(keepingCapacity: false)
    }
}

// MARK: - ForEach Property (Stack)

extension Stack where Element: Copyable {
    /// Property-based iteration access.
    ///
    /// Provides `.forEach { }`, `.forEach.borrowing { }`, and
    /// `.forEach.consuming { }` iteration patterns.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = Stack<Int>()
    /// stack.push(1)
    /// stack.push(2)
    ///
    /// // Borrowing iteration
    /// stack.forEach { print($0) }  // 1, 2
    ///
    /// // Consuming iteration (clears stack)
    /// stack.forEach.consuming { print($0) }
    /// assert(stack.isEmpty)
    /// ```
    public var forEach: Property<Sequence.ForEach, Stack>.View {
        mutating _read {
            yield unsafe Property<Sequence.ForEach, Stack>.View(&self)
        }
        mutating _modify {
            var view = unsafe Property<Sequence.ForEach, Stack>.View(&self)
            yield &view
        }
    }
}

// MARK: - Sequence.Protocol Conformance (Stack.Bounded)

/// `Stack.Bounded` conforms to `Sequence.Protocol` when `Element` is `Copyable`.
///
/// The `makeIterator()` method is defined in Stack.swift alongside
/// the `Swift.Sequence` conformance.
extension Stack.Bounded: Sequence.`Protocol` where Element: Copyable {}

// MARK: - Sequence.Clearable Conformance (Stack.Bounded)

extension Stack.Bounded: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the stack.
    @inlinable
    public mutating func removeAll() {
        clear()
    }
}

// MARK: - ForEach Property (Stack.Bounded)

extension Stack.Bounded where Element: Copyable {
    /// Property-based iteration access.
    ///
    /// Provides `.forEach { }`, `.forEach.borrowing { }`, and
    /// `.forEach.consuming { }` iteration patterns.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = try Stack<Int>.Bounded(capacity: 10)
    /// try stack.push(1)
    /// try stack.push(2)
    ///
    /// // Borrowing iteration
    /// stack.forEach { print($0) }  // 1, 2
    ///
    /// // Consuming iteration (clears stack)
    /// stack.forEach.consuming { print($0) }
    /// assert(stack.isEmpty)
    /// ```
    public var forEach: Property<Sequence.ForEach, Stack.Bounded>.View {
        mutating _read {
            yield unsafe Property<Sequence.ForEach, Stack.Bounded>.View(&self)
        }
        mutating _modify {
            var view = unsafe Property<Sequence.ForEach, Stack.Bounded>.View(&self)
            yield &view
        }
    }
}
