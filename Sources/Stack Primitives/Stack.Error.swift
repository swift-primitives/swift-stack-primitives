// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-standards open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-standards project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Hoisted Error Types (Module Level)
//
// Swift does not allow convenient access to nested types inside generic types.
// These error types are hoisted to module level per API-NAME-001 and exposed
// via typealiases to provide the expected Nest.Name API.
//
// Use the typealias forms in your code:
// - Stack<Element>.Error
// - Stack<Element>.Bounded.Error
// - Stack<Element>.Inline.Error

/// Hoisted implementation of ``Stack/Error``.
///
/// - Note: Use ``Stack/Error`` in your code, not this type directly.
public enum __StackError: Swift.Error, Sendable, Equatable {
    /// The requested capacity is invalid (negative).
    case invalidCapacity
}

/// Hoisted implementation of ``Stack/Bounded/Error``.
///
/// - Note: Use ``Stack/Bounded/Error`` in your code, not this type directly.
public enum __StackBoundedError: Swift.Error, Sendable, Equatable {
    /// The requested capacity is invalid (negative).
    case invalidCapacity

    /// The stack is full and cannot accept more elements.
    case overflow
}

/// Hoisted implementation of ``Stack/Inline/Error``.
///
/// - Note: Use ``Stack/Inline/Error`` in your code, not this type directly.
public enum __StackInlineError: Swift.Error, Sendable, Equatable {
    /// The stack is full and cannot accept more elements.
    case overflow
}

// MARK: - Typealiases (Nest.Name API)

extension Stack {
    /// Errors that can occur during unbounded stack operations.
    ///
    /// For the unbounded `Stack`, only `invalidCapacity` can occur
    /// (when reserving negative capacity). The stack grows automatically,
    /// so overflow is impossible.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Error/invalidCapacity``: The requested capacity is invalid (negative).
    public typealias Error = __StackError
}

extension Stack.Bounded {
    /// Errors that can occur during bounded stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Bounded/Error/invalidCapacity``: The requested capacity is invalid (negative).
    /// - ``Stack/Bounded/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackBoundedError
}

extension Stack.Inline {
    /// Errors that can occur during inline stack operations.
    ///
    /// For `Stack.Inline`, only `overflow` can occur. The capacity is
    /// fixed at compile time, so `invalidCapacity` is impossible.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Inline/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackInlineError
}
