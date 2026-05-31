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
// Hoisted to module level and exposed via a typealias to provide the expected
// Nest.Name API (Stack.Static.Error). Documented exception per [API-EXC-001]
// due to Swift language limitations with generic nested types.
//
// Use the typealias form in your code: Stack<Element>.Static.Error

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

// MARK: - Typealias (Nest.Name API)

extension Stack.Static where Element: ~Copyable {
    /// Errors that can occur during static stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Static/Error/overflow``: The stack is full and cannot accept more elements.
    public typealias Error = __StackStaticError<Element>
}
