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

// MARK: - Properties

extension Stack where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { Int(bitPattern: _storage.count) }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _storage.count == .zero }

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
        let newStorage = Storage<Element>.create(minimumCapacity: Index.Count(UInt(newCapacity)))
        let currentCount = _storage.count

        _storage.move(to: newStorage, count: currentCount)
        newStorage.count = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // CRITICAL: Update cached pointer
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
        let currentCount = Int(bitPattern: _storage.count)
        ensureCapacity(currentCount + 1)
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
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        let count = _storage.count
        if count > .zero {
            _storage.deinitialize(count: count)
        }
        _storage.count = .zero

        if !keepingCapacity {
            _storage = Storage<Element>.create(minimumCapacity: .zero)
            unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // Update cached pointer
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
        guard _storage.count > .zero else {
            return nil
        }
        let topIndex = Index(Ordinal(UInt(Int(bitPattern: _storage.count) - 1)))  // Safe: count > 0
        return body(unsafe _storage.read(at: topIndex).pointee)
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
            unsafe Span(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
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
            unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
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
        precondition(index >= .zero && index < Index(_storage.count))
        return unsafe _storage.withUnsafeMutablePointerToElements { elements in
            unsafe body(elements + Int(bitPattern: index))
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
        precondition(index >= .zero && index < Index(_storage.count))
        return unsafe _storage.withUnsafeMutablePointerToElements { elements in
            unsafe body(elements + Int(bitPattern: index))
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
        let count = _storage.count
        _ = unsafe _storage.withUnsafeMutablePointerToElements { elements in
            (.zero..<count).forEach { index in
                body(unsafe (elements + index).pointee)
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
        let currentCount = _storage.count
        guard _storage.capacity > Int(bitPattern: currentCount) else { return }

        if currentCount == .zero {
            _storage = Storage<Element>.create(minimumCapacity: .zero)
            unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // Update cached pointer
            return
        }

        let newStorage = Storage<Element>.create(minimumCapacity: currentCount)
        _storage.move(to: newStorage, count: currentCount)
        newStorage.count = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // Update cached pointer
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
        let currentCount = Int(bitPattern: _storage.count)
        guard newCount < currentCount else { return }
        let targetCount = Swift.max(0, newCount)

        let startIdx = Index(Ordinal(UInt(targetCount)))
        let endIdx = Index(Ordinal(UInt(currentCount)))
        let range = Range.Lazy(startIdx..<endIdx)
        _storage.deinitialize(in: range)
        _storage.count = Index.Count(UInt(targetCount))
    }
}
