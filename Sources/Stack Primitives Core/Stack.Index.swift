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

public import Index_Primitives

extension Stack where Element: ~Copyable {
    /// Type-safe index for stack elements.
    ///
    /// Uses `Index<Element>` to provide compile-time safety preventing
    /// cross-collection index confusion.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let stackIdx: Stack<Int>.Index = 0
    /// let queueIdx: Queue<Int>.Index = 0
    /// // stackIdx == queueIdx  // Does not compile - different types
    /// ```
    ///
    /// ## Position Semantics
    ///
    /// Position 0 is the bottom of the stack (oldest element).
    /// Position `count - 1` is the top (newest element).
    public typealias Index = Index_Primitives.Index<Element>
}

// MARK: - Typed Subscript (Stack)

extension Stack where Element: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Index) -> Element {
        _read {
            precondition(index >= 0 && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe _cachedPtr[index.position.rawValue]
        }
        _modify {
            precondition(index >= 0 && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe &_cachedPtr[index.position.rawValue]
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
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe _cachedPtr[index.position.rawValue]
        }
        _modify {
            makeUnique()
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe &_cachedPtr[index.position.rawValue]
        }
    }
}

// MARK: - Typed Subscript (Stack.Bounded)

extension Stack.Bounded where Element: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Stack<Element>.Index) -> Element {
        _read {
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe _cachedPtr[index.position.rawValue]
        }
        _modify {
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe &_cachedPtr[index.position.rawValue]
        }
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Accesses the element at the given typed index with copy-on-write semantics.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Stack<Element>.Index) -> Element {
        _read {
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe _cachedPtr[index.position.rawValue]
        }
        _modify {
            makeUnique()
            precondition(index >= .zero && index.position.rawValue < _storage.header, "Index out of bounds")
            yield unsafe &_cachedPtr[index.position.rawValue]
        }
    }
}

// MARK: - Typed Subscript (Stack.Inline)

extension Stack.Inline where Element: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Stack<Element>.Index) -> Element {
        _read {
            precondition(index >= .zero && index.position.rawValue < _count, "Index out of bounds")
            yield unsafe _storage.read(at: index.position.rawValue).pointee
        }
        _modify {
            precondition(index >= .zero && index.position.rawValue < _count, "Index out of bounds")
            yield unsafe &_storage.pointer(at: index.position.rawValue).pointee
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
        guard index >= .zero && index.position.rawValue < _storage.header else { return nil }
        return _storage._readElement(at: index.position.rawValue)
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Returns the element at the typed index, or nil if out of bounds.
    ///
    /// - Parameter index: The typed index of the element to access.
    /// - Returns: The element at the index, or `nil` if out of bounds.
    @inlinable
    public func element(at index: Stack<Element>.Index) -> Element? {
        guard index >= .zero && index.position.rawValue < _storage.header else { return nil }
        return _storage._readElement(at: index.position.rawValue)
    }
}
