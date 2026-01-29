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
    public var count: Int { Int(_storage.count.count) }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _storage.count == .zero }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { Int(_storage.count.count) == capacity }
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
        guard Int(_storage.count.count) < capacity else {
            throw .overflow
        }
        let index = Index<Element>(_storage.count)
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
        _storage.count = try! _storage.count - .one  // Safe: count > 0
        return _storage.move(at: Index<Element>(_storage.count))
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
        guard Int(_storage.count.count) < capacity else {
            throw .overflow
        }
        let index = Index<Element>(_storage.count)
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
        _storage.count = try! _storage.count - .one  // Safe: count > 0
        return _storage.move(at: Index<Element>(_storage.count))
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
        let topIndex = try! Index<Element>(_storage.count) - .one  // Safe: count > 0
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
        let topIndex = try! Index<Element>(_storage.count) - .one  // Safe: count > 0
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
            unsafe Span(_unsafeStart: _cachedPtr, count: Int(_storage.count.count))
        }
    }

    /// A mutable view of the stack's elements.
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(_storage.count.count))
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
            return unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(_storage.count.count))
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
        precondition(index >= .zero && index < Index<Element>(_storage.count))
        return unsafe body(_cachedPtr + index.position)
    }

    /// Provides mutable pointer access to the element at the specified index.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R>(
        at index: Stack<Element>.Index,
        _ body: (UnsafeMutablePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index < Index<Element>(_storage.count))
        return unsafe body(_cachedPtr + index.position)
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
        let currentCount = Int(_storage.count.count)
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        let range = Range.Lazy<Index<Element>>(
            lowerBound: Index<Element>(UInt(targetCount)),
            upperBound: Index<Element>(_storage.count)
        )
        _storage.deinitialize(in: range)
        _storage.count = Index<Element>.Count(UInt(targetCount))
    }
}

// MARK: - CoW-aware Truncate (Copyable elements)

extension Stack.Bounded where Element: Copyable {
    /// Removes elements beyond the specified count (CoW-aware).
    @inlinable
    public mutating func truncate(to newCount: Int) {
        makeUnique()
        let currentCount = Int(_storage.count.count)
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        let range = Range.Lazy<Index<Element>>(
            lowerBound: Index<Element>(UInt(targetCount)),
            upperBound: Index<Element>(_storage.count)
        )
        _storage.deinitialize(in: range)
        _storage.count = Index<Element>.Count(UInt(targetCount))
    }
}

// Note: Swift.Sequence conformance for Stack.Bounded is in Stack.swift
// (must be in same file as declaration due to Swift compiler bug with ~Copyable)
