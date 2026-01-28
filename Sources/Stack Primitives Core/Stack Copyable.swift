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

// MARK: - Storage Copyable Helpers

extension Stack.Storage where Element: Copyable {

    /// Creates a copy of this storage with all elements duplicated.
    @usableFromInline
    func copy() -> Stack.Storage {
        let count = header
        guard count > 0 else {
            return Stack.Storage.create()
        }

        let new = Stack.Storage.create(minimumCapacity: capacity)
        new.header = count

        _ = unsafe withUnsafeMutablePointerToElements { src in
            unsafe new.withUnsafeMutablePointerToElements { dst in
                unsafe dst.initialize(from: src, count: count)
            }
        }

        return new
    }

    /// Reads element at the given index.
    @usableFromInline
    func _readElement(at index: Int) -> Element {
        unsafe withUnsafeMutablePointerToElements { elements in
            unsafe elements[index]
        }
    }

    /// Copies all elements to new storage.
    @usableFromInline
    func _copyAllElements(to newStorage: Stack.Storage, count: Int) {
        _ = unsafe withUnsafeMutablePointerToElements { old in
            unsafe newStorage.withUnsafeMutablePointerToElements { new in
                unsafe new.initialize(from: old, count: count)
            }
        }
    }
}

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack where Element: Copyable {
    /// Ensures the storage is uniquely referenced before mutation.
    @usableFromInline
    mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
            unsafe (_cachedPtr = _storage._elementsPointer)  // CRITICAL: Update cached pointer
        }
    }

    /// Pushes an element onto the stack (CoW-aware).
    ///
    /// This method shadows the base `push(_:)` when `Element: Copyable`,
    /// providing copy-on-write semantics.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) if copy triggered
    @inlinable
    public mutating func push(_ element: Element) {
        makeUnique()
        ensureCapacity(_storage.header + 1)
        let index = _storage.header
        _storage._initializeElement(at: index, to: element)
        _storage.header += 1
    }

    /// Pops and returns the top element, or nil if empty (CoW-aware).
    ///
    /// This method shadows the base `pop()` when `Element: Copyable`,
    /// providing copy-on-write semantics.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1), O(n) if copy triggered
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
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        makeUnique()
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

extension Stack {
    /// Returns the top element without removing it, or nil if empty.
    ///
    /// This is a convenience method for `Copyable` elements. For `~Copyable`
    /// elements, use ``peek(_:)`` with a closure.
    ///
    /// - Returns: A copy of the top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek() -> Element? {
        guard _storage.header > 0 else {
            return nil
        }
        return _storage._readElement(at: _storage.header - 1)
    }
}

// MARK: - CoW-aware MutableSpan (Copyable elements)

extension Stack where Element: Copyable {
    /// A mutable view of the stack's elements (CoW-aware).
    ///
    /// This shadows the base `mutableSpan` when `Element: Copyable`,
    /// ensuring copy-on-write semantics before mutation.
    ///
    /// - Complexity: O(1), O(n) if CoW copy triggered
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        @inlinable
        mutating get {
            makeUnique()
            return unsafe MutableSpan(_unsafeStart: _cachedPtr, count: _storage.header)
        }
    }
}

// MARK: - Sequence (Copyable elements only)

/// `Stack` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
extension Stack: Swift.Sequence where Element: Copyable {

    /// An iterator over the elements of a stack.
    public struct Iterator: IteratorProtocol {
        @usableFromInline
        let _storage: Stack<Element>.Storage

        @usableFromInline
        var _index: Stack<Element>.Index = .zero

        @usableFromInline
        init(storage: Stack<Element>.Storage) {
            self._storage = storage
        }

        /// Advances to the next element and returns it, or nil if no next element exists.
        @inlinable
        public mutating func next() -> Element? {
            guard _index.position < _storage.header else { return nil }
            let currentIndex = _index.position
            _index = (_index + 1)!
            return _storage._readElement(at: currentIndex)
        }
    }

    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        Iterator(storage: _storage)
    }

    /// The underestimated count for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { _storage.header }
}

// MARK: - CoW-aware Capacity Management (Copyable elements)

extension Stack where Element: Copyable {
    /// Reduces capacity to match the current count, releasing unused memory (CoW-aware).
    ///
    /// After calling this method, `capacity == count`.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func compact() {
        makeUnique()
        let currentCount = _storage.header
        guard _storage.capacity > currentCount else { return }

        if currentCount == 0 {
            _storage = Storage.create()
            unsafe (_cachedPtr = _storage._elementsPointer)  // Update cached pointer
            return
        }

        let newStorage = Stack<Element>.Storage.create(minimumCapacity: currentCount)
        _storage._copyAllElements(to: newStorage, count: currentCount)
        newStorage.header = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage._elementsPointer)  // Update cached pointer
    }

    /// Removes elements beyond the specified count (CoW-aware).
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
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
