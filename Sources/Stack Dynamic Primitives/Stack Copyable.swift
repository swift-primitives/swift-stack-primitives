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

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack where Element: Copyable {
    /// Ensures the storage is uniquely referenced before mutation.
    @usableFromInline
    mutating func makeUnique() {
        if !isKnownUniquelyReferenced(&_storage) {
            _storage = _storage.copy()
            unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // CRITICAL: Update cached pointer
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
        let currentCount = Int(bitPattern: _storage.count)
        ensureCapacity(currentCount + 1)
        let index = Index(_storage.count)
        _storage.initialize(to: element, at: index)
        _storage.count = _storage.count + .one
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
        guard _storage.count > .zero else {
            return nil
        }
        _storage.count = try! _storage.count.subtract.exact(.one)  // Safe: count > 0
        return _storage.move(at: Index(_storage.count))
    }

    /// Removes all elements from the stack (CoW-aware).
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        makeUnique()
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
        guard _storage.count > .zero else {
            return nil
        }
        return unsafe _cachedPtr[Int(bitPattern: _storage.count) - 1]
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
            return unsafe MutableSpan(_unsafeStart: _cachedPtr, count: Int(bitPattern: _storage.count))
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
        let _basePtr: UnsafePointer<Element>

        @usableFromInline
        let _count: Stack<Element>.Index.Count

        @usableFromInline
        var _index: Stack<Element>.Index = .zero

        @usableFromInline
        init(basePtr: UnsafePointer<Element>, count: Stack<Element>.Index.Count) {
            self._basePtr = basePtr
            self._count = count
        }

        /// Advances to the next element and returns it, or nil if no next element exists.
        @inlinable
        public mutating func next() -> Element? {
            guard _index < Index(_count) else { return nil }
            let result = unsafe _basePtr[Int(bitPattern: _index)]
            _index = _index + .one
            return result
        }
    }

    /// Returns an iterator over the elements of the stack.
    ///
    /// Elements are yielded from bottom (oldest) to top (newest).
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        Iterator(basePtr: _cachedPtr, count: _storage.count)
    }

    /// The underestimatedCount for `Sequence` conformance.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: _storage.count) }
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
        let currentCount = _storage.count
        guard _storage.capacity > Int(bitPattern: currentCount) else { return }

        if currentCount == .zero {
            _storage = Storage<Element>.create(minimumCapacity: .zero)
            unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // Update cached pointer
            return
        }

        let newStorage = Storage<Element>.create(minimumCapacity: currentCount)
        _storage.copy(to: newStorage)
        newStorage.count = currentCount
        _storage = newStorage
        unsafe (_cachedPtr = _storage.pointer(at: .zero).base)  // Update cached pointer
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
