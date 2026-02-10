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

import Index_Primitives

// MARK: - Hoisted Error Types (Module Level)
//
// Swift does not allow nested types inside generic types to be easily accessed.
// These error types are hoisted to module level and exposed via typealiases to
// provide the expected Nest.Name API (Stack.Error, Stack.Bounded.Error, etc.).
//
// This is a documented exception per [API-EXC-001] due to Swift language
// limitations with generic nested types.
//
// Use the typealias forms in your code:
// - Stack<Element>.Error
// - Stack<Element>.Bounded.Error
// - Stack<Element>.Static.Error
// - Stack<Element>.Small.Error

/// Hoisted implementation of ``Stack/Error``.
///
/// - Note: Use ``Stack/Error`` in your code, not this type directly.
public enum __StackError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// An index was out of bounds.
    case bounds(Bounds)

    /// Bounds violation payload.
    public struct Bounds: Sendable, Equatable {
        public let index: Index_Primitives.Index<Element>
        public let count: Index_Primitives.Index<Element>.Count

        @inlinable
        public init(index: Index_Primitives.Index<Element>, count: Index_Primitives.Index<Element>.Count) {
            self.index = index
            self.count = count
        }
    }
}

extension __StackError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        }
    }
}

/// Hoisted implementation of ``Stack/Bounded/Error``.
///
/// - Note: Use ``Stack/Bounded/Error`` in your code, not this type directly.
public enum __StackBoundedError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The stack is full and cannot accept more elements.
    case overflow

    /// An index was out of bounds.
    case bounds(Bounds)

    /// Bounds violation payload.
    public struct Bounds: Sendable, Equatable {
        public let index: Index_Primitives.Index<Element>
        public let count: Index_Primitives.Index<Element>.Count

        @inlinable
        public init(index: Index_Primitives.Index<Element>, count: Index_Primitives.Index<Element>.Count) {
            self.index = index
            self.count = count
        }
    }
}

extension __StackBoundedError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow:
            return "bounded stack is full"
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        }
    }
}

/// Hoisted implementation of ``Stack/Static/Error``.
///
/// - Note: Use ``Stack/Static/Error`` in your code, not this type directly.
public enum __StackStaticError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// The stack is full and cannot accept more elements.
    case overflow

    /// An index was out of bounds.
    case bounds(Bounds)

    /// Bounds violation payload.
    public struct Bounds: Sendable, Equatable {
        public let index: Index_Primitives.Index<Element>
        public let count: Index_Primitives.Index<Element>.Count

        @inlinable
        public init(index: Index_Primitives.Index<Element>, count: Index_Primitives.Index<Element>.Count) {
            self.index = index
            self.count = count
        }
    }
}

extension __StackStaticError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .overflow:
            return "static stack is full"
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        }
    }
}

/// Hoisted implementation of ``Stack/Small/Error``.
///
/// - Note: Use ``Stack/Small/Error`` in your code, not this type directly.
public enum __StackSmallError<Element: ~Copyable>: Swift.Error, Sendable, Equatable {
    /// An index was out of bounds.
    case bounds(Bounds)

    /// Bounds violation payload.
    public struct Bounds: Sendable, Equatable {
        public let index: Index_Primitives.Index<Element>
        public let count: Index_Primitives.Index<Element>.Count

        @inlinable
        public init(index: Index_Primitives.Index<Element>, count: Index_Primitives.Index<Element>.Count) {
            self.index = index
            self.count = count
        }
    }
}

extension __StackSmallError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bounds(let e):
            return "index \(Int(bitPattern: e.index)) out of bounds for count \(Int(bitPattern: e.count))"
        }
    }
}

// MARK: - Typealiases (Nest.Name API)

extension Stack {
    /// Errors that can occur during unbounded stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Error/bounds(_:)``: An index was out of bounds.
    public typealias Error = __StackError<Element>
}

extension Stack.Bounded {
    /// Errors that can occur during bounded stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Bounded/Error/overflow``: The stack is full and cannot accept more elements.
    /// - ``Stack/Bounded/Error/bounds(_:)``: An index was out of bounds.
    public typealias Error = __StackBoundedError<Element>
}

extension Stack.Static {
    /// Errors that can occur during static stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Static/Error/overflow``: The stack is full and cannot accept more elements.
    /// - ``Stack/Static/Error/bounds(_:)``: An index was out of bounds.
    public typealias Error = __StackStaticError<Element>
}

extension Stack.Small {
    /// Errors that can occur during small stack operations.
    ///
    /// ## Cases
    ///
    /// - ``Stack/Small/Error/bounds(_:)``: An index was out of bounds.
    public typealias Error = __StackSmallError<Element>
}
