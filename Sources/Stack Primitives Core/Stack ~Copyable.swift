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

// MARK: - Properties

extension Stack where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { _storage.header }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _storage.header == 0 }

    /// The current capacity of the stack.
    @inlinable
    public var capacity: Int { _storage.capacity }
}

// MARK: - Capacity Management

extension Stack where Element: ~Copyable {
    /// Ensures the stack has capacity for at least the specified number of elements.
    @usableFromInline
    mutating func ensureCapacity(_ minimumCapacity: Int) {
        guard _storage.capacity < minimumCapacity else { return }

        // Growth factor 2.0, minimum capacity 4
        let newCapacity = Swift.max(minimumCapacity, _storage.capacity * 2, 4)
        let newStorage = Stack<Element>.Storage.create(minimumCapacity: newCapacity)
        let currentCount = _storage.header

        _storage._moveAllElements(to: newStorage, count: currentCount)
        newStorage.header = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage._elementsPointer)  // CRITICAL: Update cached pointer
    }

    /// Reserves capacity for at least the specified number of elements.
    ///
    /// Use this method to avoid multiple reallocations when adding a known
    /// number of elements.
    ///
    /// - Parameter minimumCapacity: The minimum total capacity to reserve.
    @inlinable
    public mutating func reserve(_ minimumCapacity: Int) {
        ensureCapacity(minimumCapacity)
    }
}

// MARK: - Core Operations (Base - for ~Copyable elements)

extension Stack where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized
    @inlinable
    public mutating func push(_ element: consuming Element) {
        ensureCapacity(_storage.header + 1)
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
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        let count = _storage.header
        if count > 0 {
            _storage._deinitializeElements(in: 0..<count)
        }
        _storage.header = 0

        if !keepingCapacity {
            _storage = Storage.create()
            unsafe (_cachedPtr = _storage._elementsPointer)  // Update cached pointer
        }
    }
}

// MARK: - Peek

extension Stack where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    ///
    /// Uses a closure to support `~Copyable` elements via borrowing.
    ///
    /// - Parameter body: A closure that receives a borrowed reference to the top element.
    /// - Returns: The result of the closure, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek<R>(_ body: (borrowing Element) -> R) -> R? {
        guard _storage.header > 0 else {
            return nil
        }
        return unsafe _storage.withUnsafeMutablePointerToElements { elements in
            body(unsafe (elements + _storage.header - 1).pointee)
        }
    }
}

// MARK: - Span Access
//
// Property-based Span access is enabled by storing _cachedPtr as a struct property.
// This makes the pointer's lifetime tied to the struct's lifetime, allowing
// @_lifetime(borrow self) to work correctly. See SE-0456 for canonical pattern.

extension Stack where Element: ~Copyable {
    /// A read-only view of the stack's elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    ///
    /// - Complexity: O(1)
    public var span: Span<Element> {
        @_lifetime(borrow self)
        @inlinable
        borrowing get {
            unsafe Span(_unsafeStart: _cachedPtr, count: _storage.header)
        }
    }

    /// A mutable view of the stack's elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    /// For Copyable elements, this triggers CoW if needed.
    ///
    /// - Complexity: O(1), O(n) if CoW copy triggered
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            unsafe MutableSpan(_unsafeStart: _cachedPtr, count: _storage.header)
        }
    }
}

// MARK: - Pointer Access (Escape Hatch)

extension Stack where Element: ~Copyable {
    /// Provides read-only pointer access to the element at the specified index.
    ///
    /// - Warning: This is an escape hatch for C interop. Prefer `span` for safe access.
    /// - Warning: The pointer must not escape the closure scope.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public func withUnsafePointer<R>(
        at index: Index,
        _ body: (UnsafePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index.position.rawValue < _storage.header)
        return unsafe _storage.withUnsafeMutablePointerToElements { elements in
            unsafe body(elements + index.position.rawValue)
        }
    }

    /// Provides mutable pointer access to the element at the specified index.
    ///
    /// - Warning: This is an escape hatch for C interop. Prefer `mutableSpan` for safe access.
    /// - Warning: The pointer must not escape the closure scope.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R>(
        at index: Index,
        _ body: (UnsafeMutablePointer<Element>) -> R
    ) -> R {
        precondition(index >= .zero && index.position.rawValue < _storage.header)
        return unsafe _storage.withUnsafeMutablePointerToElements { elements in
            unsafe body(elements + index.position.rawValue)
        }
    }
}

// MARK: - Iteration (for ~Copyable elements)

extension Stack where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    ///
    /// Elements are visited from bottom (oldest) to top (newest).
    ///
    /// - Parameter body: A closure that receives each element.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public func forEach(_ body: (borrowing Element) -> Void) {
        let count = _storage.header
        _ = unsafe _storage.withUnsafeMutablePointerToElements { elements in
            for i in 0..<count {
                body(unsafe (elements + i).pointee)
            }
        }
    }
}

// MARK: - Capacity Management (Additional)

extension Stack where Element: ~Copyable {
    /// Reduces capacity to match the current count, releasing unused memory.
    ///
    /// After calling this method, `capacity == count`.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func compact() {
        let currentCount = _storage.header
        guard _storage.capacity > currentCount else { return }

        if currentCount == 0 {
            _storage = Storage.create()
            unsafe (_cachedPtr = _storage._elementsPointer)  // Update cached pointer
            return
        }

        let newStorage = Stack<Element>.Storage.create(minimumCapacity: currentCount)
        _storage._moveAllElements(to: newStorage, count: currentCount)
        newStorage.header = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage._elementsPointer)  // Update cached pointer
    }

    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Int) {
        let currentCount = _storage.header
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        _storage._deinitializeElements(in: targetCount..<currentCount)
        _storage.header = targetCount
    }
}
