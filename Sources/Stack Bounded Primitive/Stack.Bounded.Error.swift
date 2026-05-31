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

// MARK: - Hoisted Error Type (Module Level)
//
// Swift does not allow nested types inside generic types to be easily accessed.
// This error type is hoisted to module level and exposed via a typealias to
// provide the expected Nest.Name API (Stack.Bounded.Error).
//
// This is a documented exception per [API-EXC-001] due to Swift language
// limitations with generic nested types.
//
// Use the typealias form in your code: Stack<Element>.Bounded.Error

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

// MARK: - Typealias (Nest.Name API)

extension Stack.Bounded where Element: ~Copyable {
    /// Errors that can occur during bounded stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Bounded/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackBoundedError<Element>
}
