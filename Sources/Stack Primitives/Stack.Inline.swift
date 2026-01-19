// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-standards open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-standards project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// Note: Stack.Inline is declared INSIDE the Stack struct body (in Stack.swift)
// due to a Swift compiler bug where nested types with value generic parameters
// declared in extensions do not properly inherit ~Copyable constraints from
// the outer type. This file contains only extensions to Stack.Inline.

// MARK: - Properties

extension Stack.Inline where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { _count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _count == 0 }

    /// Whether the stack is full.
    @inlinable
    public var isFull: Bool { _count == Self.capacity }
}

// MARK: - Core Operations

extension Stack.Inline where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Throws: ``Stack/Inline/Error/overflow`` if the stack is full.
    /// - Complexity: O(1)
    @inlinable
    public mutating func push(_ element: consuming Element) throws(__StackInlineError) {
        guard _count < Self.capacity else {
            throw .overflow
        }
        unsafe _pointerToElement(at: _count).initialize(to: element)
        _count += 1
    }

    /// Pops and returns the top element, or nil if empty.
    ///
    /// - Returns: The top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public mutating func pop() -> Element? {
        guard _count > 0 else {
            return nil
        }
        _count -= 1
        return unsafe _pointerToElement(at: _count).move()
    }

    /// Removes all elements from the stack.
    ///
    /// **Important**: Always call this method before the stack goes out of scope
    /// to ensure proper element cleanup due to a Swift compiler limitation.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        for i in 0..<_count {
            unsafe _pointerToElement(at: i).deinitialize(count: 1)
        }
        _count = 0
    }
}

// MARK: - Peek

extension Stack.Inline where Element: ~Copyable {
    /// Peeks at the top element without removing it.
    ///
    /// Uses a closure to support `~Copyable` elements via borrowing.
    ///
    /// - Parameter body: A closure that receives a borrowed reference to the top element.
    /// - Returns: The result of the closure, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek<R, E: Swift.Error>(_ body: (borrowing Element) throws(E) -> R) throws(E) -> R? {
        guard _count > 0 else {
            return nil
        }
        return try unsafe body(_readPointerToElement(at: _count - 1).pointee)
    }
}

extension Stack.Inline where Element: Copyable {
    /// Returns the top element without removing it, or nil if empty.
    ///
    /// This is a convenience method for `Copyable` elements. For `~Copyable`
    /// elements, use ``peek(_:)`` with a closure.
    ///
    /// - Returns: A copy of the top element, or `nil` if the stack is empty.
    /// - Complexity: O(1)
    @inlinable
    public func peek() -> Element? {
        guard _count > 0 else {
            return nil
        }
        return unsafe _readPointerToElement(at: _count - 1).pointee
    }
}

// MARK: - Span Access

extension Stack.Inline where Element: ~Copyable {
    /// Read-only span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    /// The span views the initialized prefix of the storage.
    ///
    /// ## Layout Guarantee
    ///
    /// Elements are stored contiguously at stride intervals:
    /// - Element i is at `base + i * stride(Element)`
    /// - This matches standard array layout
    /// - The span correctly views all initialized elements
    ///
    /// ## Lifetime Contract
    ///
    /// - The span is valid ONLY for the duration of the access.
    /// - The span MUST NOT be stored, returned, or allowed to escape.
    /// - The `_read` accessor enforces proper lifetime scoping.
    @inlinable
    public var span: Span<Element> {
        _read {
            yield unsafe Span(_unsafeStart: _basePointer(), count: _count)
        }
    }

    /// Mutable span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    /// The span views the initialized prefix of the storage.
    ///
    /// ## Layout Guarantee
    ///
    /// Elements are stored contiguously at stride intervals:
    /// - Element i is at `base + i * stride(Element)`
    /// - This matches standard array layout
    /// - The span correctly views all initialized elements
    ///
    /// ## Lifetime Contract
    ///
    /// - The span is valid ONLY for the duration of the access.
    /// - The span MUST NOT be stored, returned, or allowed to escape.
    /// - The `_read`/`_modify` accessors enforce proper lifetime scoping.
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        _read {
            // For _read, we provide read-only access through the span.
            // Using mutating cast is safe here because _read doesn't allow mutation.
            let ptr = unsafe UnsafeMutablePointer(mutating: _basePointer())
            yield unsafe MutableSpan(_unsafeStart: ptr, count: _count)
        }
        _modify {
            var s = unsafe MutableSpan(_unsafeStart: _mutableBasePointer(), count: _count)
            yield &s
        }
    }
}



// MARK: - Sendable

/// `Stack.Inline` is `Sendable` when its elements are `Sendable`.
///
/// This conformance allows the stack to be transferred between tasks.
/// However, concurrent mutation requires external synchronization—
/// the stack itself provides no thread-safety guarantees.
extension Stack.Inline: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration

extension Stack.Inline where Element: ~Copyable {
    /// Calls the given closure for each element in the stack.
    ///
    /// Elements are visited from bottom (oldest) to top (newest).
    ///
    /// - Parameter body: A closure that receives each element.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public func forEach<E: Swift.Error>(
        _ body: (borrowing Element) throws(E) -> Void
    ) throws(E) {
        for i in 0..<_count {
            try unsafe body(_readPointerToElement(at: i).pointee)
        }
    }
}

// MARK: - Truncate

extension Stack.Inline where Element: ~Copyable {
    /// Removes elements beyond the specified count.
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Int) {
        guard newCount < _count else { return }
        let targetCount = Swift.max(0, newCount)

        let stride = MemoryLayout<Element>.stride
        unsafe Swift.withUnsafeMutablePointer(to: &_storage) { storagePtr in
            let basePtr = UnsafeMutableRawPointer(storagePtr)
            for i in targetCount..<_count {
                let elementPtr = unsafe (basePtr + i * stride)
                    .assumingMemoryBound(to: Element.self)
                unsafe elementPtr.deinitialize(count: 1)
            }
        }
        _count = targetCount
    }
}

