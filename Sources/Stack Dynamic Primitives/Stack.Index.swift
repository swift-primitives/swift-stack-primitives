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
internal import Index_Primitives

// Note: Index typealias is defined in Stack Primitives Core/Stack.Index.swift

// MARK: - Typed Subscript (Stack)

extension Stack where Element: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Index) -> Element {
        _read {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield _buffer[index]
        }
        _modify {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield &_buffer[index]
        }
    }
}

extension Stack where Element: Copyable {
    /// Accesses the element at the given typed index with copy-on-write semantics.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Index) -> Element {
        _read {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield _buffer[index]
        }
        _modify {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield &_buffer[index]
        }
    }
}

// Note: Stack.Bounded subscripts are in Stack Bounded Primitives/Stack.Bounded ~Copyable.swift

// MARK: - Typed Subscript (Stack.Static)

extension Stack.Static where Element: Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Stack<Element>.Index) -> Element {
        _read {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield _buffer[index]
        }
        _modify {
            precondition(index >= .zero && index < _buffer.count, "Index out of bounds")
            yield &_buffer[index]
        }
    }
}

// MARK: - Safe Access

extension Stack where Element: Copyable {
    /// Returns the element at the typed index, or nil if out of bounds.
    ///
    /// - Parameter index: The typed index of the element to access.
    /// - Returns: The element at the index, or `nil` if out of bounds.
    @inlinable
    public func element(at index: Index) -> Element? {
        guard index >= .zero && index < _buffer.count else { return nil }
        return _buffer[index]
    }
}

// Note: Stack.Bounded element(at:) is in Stack Bounded Primitives
