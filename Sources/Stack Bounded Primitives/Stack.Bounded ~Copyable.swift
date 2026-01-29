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
public import Index_Primitives
public import Range_Primitives

// Note: Conditional Copyable conformance is in Stack.swift (must be same file as declaration)

// MARK: - Properties

extension Stack.Bounded where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { Int(bitPattern: _storage.count) }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _storage.count == .zero }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { Int(bitPattern: _storage.count) == capacity }
}

// MARK: - Core Operations (Base - for ~Copyable elements)

extension Stack.Bounded where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Throws: ``Stack/Bounded/Error/overflow`` if the stack is full.
    /// - Complexity: O(1)
    @inlinable
    public mutating func push(_ element: consuming Element) throws(__StackBoundedError) {
        guard Int(bitPattern: _storage.count) < capacity else {
            throw .overflow
        }
        let index = Index(_storage.count)
        _storage.initialize(to: element, at: index)
        _storage.count = _storage.count + .one
    }

    /// Pops and returns the top element, or nil if empty.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func pop() -> Element? {
        guard _storage.count > .zero else {
            return nil
        }
        _storage.count = try! _storage.count.subtract.exact(.one)  // Safe: count > 0
        return _storage.move(at: Index(_storage.count))
    }

    /// Removes all elements from the stack.
    ///
    /// The capacity remains unchanged.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        let count = _storage.count
        if count > .zero {
            _storage.deinitialize(count: count)
        }
        _storage.count = .zero
    }
}

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack.Bounded where Element: Copyable {
    /// Ensures the storage is uniquely referenced before mutation.
    @usableFromInline
    mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
            unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // CRITICAL: Update cached pointer
        }
    }

    /// Pushes an element onto the stack (CoW-aware).
    @inlinable
    public mutating func push(_ element: Element) throws(__StackBoundedError) {
        makeUnique()
        guard Int(bitPattern: _storage.count) < capacity else {
            throw .overflow
        }
        let index = Index(_storage.count)
        _storage.initialize(to: element, at: index)
        _storage.count = _storage.count + .one
    }

    /// Pops and returns the top element, or nil if empty (CoW-aware).
    @inlinable
    public mutating func pop() -> Element? {
        makeUnique()
        guard _storage.count > .zero else {
            return nil
        }
        _storage.count = try! _storage.count.subtract.exact(.one)  // Safe: count > 0
        return _storage.move(at: Index(_storage.count))
    }

    /// Removes all elements from the stack (CoW-aware).
    @inlinable
    public mutating func clear() {
        makeUnique()
        let count = _storage.count
        if count > .zero {
            _storage.deinitialize(count: count)
        }
        _storage.count = .zero
    }
}

// MARK: - Peek

extension Stack.Bounded where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard _storage.count > .zero else {
            return nil
        }
        let topIndex = Stack<Element>.Index(Ordinal(UInt(Int(bitPattern: _storage.count) - 1)))  // Safe: count > 0
        return body(unsafe _storage.read(at: topIndex).pointee)
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    @inlinable
    public func peek() -> Element? {
        guard _storage.count > .zero else {
            return nil
        }
        let topIndex = Stack<Element>.Index(Ordinal(UInt(Int(bitPattern: _storage.count) - 1)))  // Safe: count > 0
        return unsafe _storage.read(at: topIndex).pointee
    }
}

// MARK: - Span Access

extension Stack.Bounded where Element: ~Copyable {
    /// A read-only view of the stack's elements.
    public var span: Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get {
            unsafe Span(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
        }
    }

    /// A mutable view of the stack's elements.
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
        }
    }
}

// MARK: - CoW-aware MutableSpan (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// A mutable view of the stack's elements (CoW-aware).
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            makeUnique()
            return unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
        }
    }
}

// MARK: - Pointer Access (Escape Hatch)

extension Stack.Bounded where Element: ~Copyable {
    /// Provides read-only pointer access to the element at the specified index.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public func withUnsafePointer<R>(
        at index: Stack<Element>.Index,
        _ body: (UnsafePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index < Index(_storage.count))
        return unsafe body(_cachedPtr + Int(bitPattern: index))
    }

    /// Provides mutable pointer access to the element at the specified index.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R>(
        at index: Stack<Element>.Index,
        _ body: (UnsafeMutablePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index < Index(_storage.count))
        return unsafe body(_cachedPtr + Int(bitPattern: index))
    }
}

// MARK: - Sendable

extension Stack.Bounded: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration (for ~Copyable elements)

extension Stack.Bounded where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        let count = _storage.count
        (.zero..<count).forEach { index in
            body(unsafe _storage.read(at: index).pointee)
        }
    }
}

// MARK: - Truncate

extension Stack.Bounded where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    @inlinable
    public mutating func truncate(to newCount: Int) {
        let currentCount = Int(bitPattern: _storage.count)
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        let startIdx = Stack<Element>.Index(Ordinal(UInt(targetCount)))
        let endIdx = Stack<Element>.Index(Ordinal(UInt(currentCount)))
        let range = Range.Lazy(startIdx..<endIdx)
        _storage.deinitialize(in: range)
        _storage.count = Stack<Element>.Index.Count(UInt(targetCount))
    }
}

// MARK: - CoW-aware Truncate (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// Removes elements beyond the specified count (CoW-aware).
    @inlinable
    public mutating func truncate(to newCount: Int) {
        makeUnique()
        let currentCount = Int(bitPattern: _storage.count)
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        let startIdx = Stack<Element>.Index(Ordinal(UInt(targetCount)))
        let endIdx = Stack<Element>.Index(Ordinal(UInt(currentCount)))
        let range = Range.Lazy(startIdx..<endIdx)
        _storage.deinitialize(in: range)
        _storage.count = Stack<Element>.Index.Count(UInt(targetCount))
    }
}

// MARK: - Typed Subscript

extension Stack.Bounded where Element: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// - Parameter index: The typed index of the element to access (0 = bottom).
    /// - Precondition: `index.position` must be in `0..<count`.
    @inlinable
    public subscript(index: Stack<Element>.Index) -> Element {
        _read {
            precondition(index >= .zero && Int(bitPattern: index) < Int(bitPattern: _storage.count), "Index out of bounds")
            yield unsafe _cachedPtr[Int(bitPattern: index)]
        }
        _modify {
            precondition(index >= .zero && Int(bitPattern: index) < Int(bitPattern: _storage.count), "Index out of bounds")
            yield unsafe &_cachedPtr[Int(bitPattern: index)]
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
            precondition(index >= .zero && Int(bitPattern: index) < Int(bitPattern: _storage.count), "Index out of bounds")
            yield unsafe _cachedPtr[Int(bitPattern: index)]
        }
        _modify {
            makeUnique()
            precondition(index >= .zero && Int(bitPattern: index) < Int(bitPattern: _storage.count), "Index out of bounds")
            yield unsafe &_cachedPtr[Int(bitPattern: index)]
        }
    }
}

// MARK: - Safe Access

extension Stack.Bounded where Element: Copyable {
    /// Returns the element at the typed index, or nil if out of bounds.
    ///
    /// - Parameter index: The typed index of the element to access.
    /// - Returns: The element at the index, or `nil` if out of bounds.
    @inlinable
    public func element(at index: Stack<Element>.Index) -> Element? {
        guard index >= .zero && Int(bitPattern: index) < Int(bitPattern: _storage.count) else { return nil }
        return unsafe _storage.read(at: index).pointee
    }
}

// Note: Swift.Sequence conformance for Stack.Bounded is in Stack.Bounded Copyable.swift
