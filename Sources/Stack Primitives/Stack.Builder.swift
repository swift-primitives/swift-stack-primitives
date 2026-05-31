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

public import Buffer_Linear_Primitives
public import Stack_Primitive

extension Stack where Element: ~Copyable {
    /// A result builder for declaratively constructing stacks.
    ///
    /// ## Push-Order Semantics
    ///
    /// **Declaration order is push order.** Each declared element is
    /// pushed onto the stack in the order it appears, exactly as if the
    /// imperative code had been written:
    ///
    /// ```swift
    /// var s = Stack<Int>()
    /// s.push(1)
    /// s.push(2)
    /// s.push(3)
    /// ```
    ///
    /// Consequently, `pop()` returns elements in **reverse** of declaration
    /// order — the last declared element is at the top of the stack:
    ///
    /// ```swift
    /// var stack = Stack<Int> {
    ///     1
    ///     2
    ///     3
    /// }
    /// stack.pop()  // 3 — last declared, top of stack
    /// stack.pop()  // 2
    /// stack.pop()  // 1 — first declared, bottom of stack
    /// ```
    ///
    /// This mirrors the imperative push-then-pop convention; the
    /// declarative form composes identically with builder bodies.
    ///
    /// ## ~Copyable Elements
    ///
    /// Supports `~Copyable` elements via consuming push:
    ///
    /// ```swift
    /// struct FileHandle: ~Copyable { ... }
    /// let stack: Stack<FileHandle> = Stack<FileHandle> {
    ///     FileHandle()
    ///     FileHandle()
    /// }
    /// ```
    ///
    /// ## `for` Loops Not Supported
    ///
    /// `buildArray` is omitted because Swift's result-builder transform's
    /// buildArray step uses `Swift.Array<Component>`, which currently
    /// requires `Component: Copyable`. The component here is the
    /// ~Copyable `Stack<Element>`.
    @resultBuilder
    public enum Builder {

        // MARK: - Expression Building

        @inlinable
        public static func buildExpression(
            _ expression: consuming Element
        ) -> Stack<Element> {
            var result = Stack<Element>()
            result.push(consume expression)
            return result
        }

        @inlinable
        public static func buildExpression(
            _ expression: consuming Stack<Element>
        ) -> Stack<Element> {
            consume expression
        }

        @inlinable
        public static func buildExpression(
            _ expression: consuming Element?
        ) -> Stack<Element> {
            var result = Stack<Element>()
            if let value = consume expression {
                result.push(consume value)
            }
            return result
        }

        // MARK: - Partial Block Building

        @inlinable
        public static func buildPartialBlock(
            first: consuming Stack<Element>
        ) -> Stack<Element> {
            consume first
        }

        @inlinable
        public static func buildPartialBlock(
            first: Void
        ) -> Stack<Element> {
            Stack<Element>()
        }

        @inlinable
        public static func buildPartialBlock(
            first: Never
        ) -> Stack<Element> {}

        @inlinable
        public static func buildPartialBlock(
            accumulated: consuming Stack<Element>,
            next: consuming Stack<Element>
        ) -> Stack<Element> {
            var result = consume accumulated
            var rest = consume next
            // Drain rest from the bottom (oldest-pushed first) so push order
            // is preserved when re-pushed onto result.
            while !rest._buffer.isEmpty {
                result.push(rest._buffer.remove.first())
            }
            return result
        }

        // MARK: - Block Building

        @inlinable
        public static func buildBlock() -> Stack<Element> {
            Stack<Element>()
        }

        // MARK: - Control Flow

        @inlinable
        public static func buildOptional(
            _ component: consuming Stack<Element>?
        ) -> Stack<Element> {
            if let result = consume component {
                return consume result
            }
            return Stack<Element>()
        }

        @inlinable
        public static func buildEither(
            first: consuming Stack<Element>
        ) -> Stack<Element> {
            consume first
        }

        @inlinable
        public static func buildEither(
            second: consuming Stack<Element>
        ) -> Stack<Element> {
            consume second
        }

        // buildArray omitted: see DocC above.

        @inlinable
        public static func buildLimitedAvailability(
            _ component: consuming Stack<Element>
        ) -> Stack<Element> {
            consume component
        }
    }
}

// MARK: - Convenience Init

extension Stack where Element: ~Copyable {
    /// Constructs a stack from a result-builder closure.
    ///
    /// Declaration order is push order; the last declared element ends up
    /// at the top of the stack. `pop()` returns the last declared element
    /// first.
    ///
    /// ```swift
    /// var stack = Stack<Int> {
    ///     1
    ///     2
    ///     3
    /// }
    /// stack.pop()  // 3 (top of stack — last declared)
    /// ```
    @inlinable
    public init(@Stack.Builder _ builder: () -> Self) {
        self = builder()
    }
}

// MARK: - Sequence Bulk-Add (Copyable Element only)

extension Stack.Builder where Element: Copyable {
    /// Bulk-push a Swift.Sequence onto the stack without per-iteration
    /// allocation. Iteration order = push order; the last element of the
    /// sequence ends up at the top of the stack.
    @inlinable
    public static func buildExpression<S: Swift.Sequence>(_ expression: S) -> Stack<Element>
    where S.Element == Element {
        var result = Stack<Element>()
        for value in expression {
            result.push(value)
        }
        return result
    }
}
