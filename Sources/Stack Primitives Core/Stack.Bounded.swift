// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-standards open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-standards project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// Note: Conditional Copyable conformance is in Stack.swift (must be same file as declaration)

// MARK: - Properties

extension Stack.Bounded where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { _storage.header }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _storage.header == 0 }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { _storage.header == capacity }
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
        guard _storage.header < capacity else {
            throw .overflow
        }
        let index = _storage.header
        _storage._initializeElement(at: index, to: element)
        _storage.header += 1
    }

    /// Pops and returns the top element, or nil if empty.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func pop() -> Element? {
        guard _storage.header > 0 else {
            return nil
        }
        _storage.header -= 1
        return _storage._moveElement(at: _storage.header)
    }

    /// Removes all elements from the stack.
    ///
    /// The capacity remains unchanged.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        let count = _storage.header
        if count > 0 {
            _storage._deinitializeElements(in: 0..<count)
        }
        _storage.header = 0
    }
}

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack.Bounded where Element: Copyable {
    /// Ensures the storage is uniquely referenced before mutation.
    @usableFromInline
    mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
            unsafe (_cachedPtr = _storage._elementsPointer)  // CRITICAL: Update cached pointer
        }
    }

    /// Pushes an element onto the stack (CoW-aware).
    @inlinable
    public mutating func push(_ element: Element) throws(__StackBoundedError) {
        makeUnique()
        guard _storage.header < capacity else {
            throw .overflow
        }
        let index = _storage.header
        _storage._initializeElement(at: index, to: element)
        _storage.header += 1
    }

    /// Pops and returns the top element, or nil if empty (CoW-aware).
    @inlinable
    public mutating func pop() -> Element? {
        makeUnique()
        guard _storage.header > 0 else {
            return nil
        }
        _storage.header -= 1
        return _storage._moveElement(at: _storage.header)
    }

    /// Removes all elements from the stack (CoW-aware).
    @inlinable
    public mutating func clear() {
        makeUnique()
        let count = _storage.header
        if count > 0 {
            _storage._deinitializeElements(in: 0..<count)
        }
        _storage.header = 0
    }
}

// MARK: - Peek

extension Stack.Bounded where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard _storage.header > 0 else {
            return nil
        }
        return unsafe body((_cachedPtr + _storage.header - 1).pointee)
    }
}

extension Stack.Bounded where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    @inlinable
    public func peek() -> Element? {
        guard _storage.header > 0 else {
            return nil
        }
        return _storage._readElement(at: _storage.header - 1)
    }
}

// MARK: - Span Access

extension Stack.Bounded where Element: ~Copyable {
    /// A read-only view of the stack's elements.
    public var span: Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get {
            unsafe Span(_unsafeStart: _cachedPtr, count: _storage.header)
        }
    }

    /// A mutable view of the stack's elements.
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            unsafe MutableSpan(_unsafeStart: _cachedPtr, count: _storage.header)
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
            return unsafe MutableSpan(_unsafeStart: _cachedPtr, count: _storage.header)
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
        precondition(index >= .zero && index.position.rawValue < _storage.header)
        return unsafe body(_cachedPtr + index.position.rawValue)
    }

    /// Provides mutable pointer access to the element at the specified index.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R>(
        at index: Stack<Element>.Index,
        _ body: (UnsafeMutablePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index.position.rawValue < _storage.header)
        return unsafe body(_cachedPtr + index.position.rawValue)
    }
}

// MARK: - Sendable

extension Stack.Bounded: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration (for ~Copyable elements)

extension Stack.Bounded where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        let count = _storage.header
        for i in 0..<count {
            body(unsafe (_cachedPtr + i).pointee)
        }
    }
}

// MARK: - Truncate

extension Stack.Bounded where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    @inlinable
    public mutating func truncate(to newCount: Int) {
        let currentCount = _storage.header
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        _storage._deinitializeElements(in: targetCount..<currentCount)
        _storage.header = targetCount
    }
}

// MARK: - CoW-aware Truncate (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// Removes elements beyond the specified count (CoW-aware).
    @inlinable
    public mutating func truncate(to newCount: Int) {
        makeUnique()
        let currentCount = _storage.header
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        _storage._deinitializeElements(in: targetCount..<currentCount)
        _storage.header = targetCount
    }
}

// Note: Sequence conformance for Stack.Bounded is in Stack.swift
// (must be in same file as declaration due to Swift compiler bug with ~Copyable)
