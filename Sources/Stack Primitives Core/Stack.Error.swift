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

// MARK: - Hoisted Error Types (Module Level)
//
// Swift does not allow nested types inside generic types to be easily accessed.
// These error types are hoisted to module level and exposed via typealiases to
// provide the expected Nest.Name API (Stack.Bounded.Error, Stack.Static.Error).
//
// This is a documented exception per [API-EXC-001] due to Swift language
// limitations with generic nested types.
//
// Use the typealias forms in your code:
// - Stack<Element>.Bounded.Error
// - Stack<Element>.Static.Error

/// Hoisted implementation of ``Stack/Bounded/Error``.
///
/// - Note: Use ``Stack/Bounded/Error`` in your code, not this type directly.
public enum __StackBoundedError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The stack is full and cannot accept more elements.
    case overflow
}

extension __StackBoundedError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow:
            return "bounded stack is full"
        }
    }
}

/// Hoisted implementation of ``Stack/Static/Error``.
///
/// - Note: Use ``Stack/Static/Error`` in your code, not this type directly.
public enum __StackStaticError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The stack is full and cannot accept more elements.
    case overflow
}

extension __StackStaticError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow:
            return "static stack is full"
        }
    }
}

// MARK: - Typealiases (Nest.Name API)

extension Stack.Bounded {
    /// Errors that can occur during bounded stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Bounded/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackBoundedError<Element>
}

extension Stack.Static {
    /// Errors that can occur during static stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Static/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackStaticError<Element>
}
