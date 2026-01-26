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

// Note: Stack.Small is declared INSIDE the Stack struct body (in Stack.swift)
// due to a Swift compiler bug where nested types with value generic parameters
// declared in extensions do not properly inherit ~Copyable constraints from
// the outer type. This file contains only extensions to Stack.Small.

// MARK: - Properties

extension Stack.Small where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { _count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _count == 0 }

    /// The current capacity (inline or heap).
    @inlinable
    public var capacity: Int {
        if let heap = _heap {
            return heap.capacity
        }
        return inlineCapacity
    }
}

// MARK: - Core Operations (Base - for ~Copyable elements)

extension Stack.Small where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// If the stack exceeds inline capacity, elements are moved to heap storage.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) when spilling to heap.
    @inlinable
    public mutating func push(_ element: consuming Element) {
        if _heap != nil {
            // Already spilled - push to heap
            _pushToHeap(element)
        } else if _count < inlineCapacity {
            // Still inline and have space
            _inline.initialize(to: element, at: _count)
            _count += 1
        } else {
            // Need to spill
            _spillToHeap(minimumCapacity: _count + 1)
            _pushToHeap(element)
        }
    }

    /// Internal: push element to heap storage.
    @usableFromInline
    mutating func _pushToHeap(_ element: consuming Element) {
        guard
            let heap = _heap,
            let _ = unsafe _heapPtr else {
            preconditionFailure("_pushToHeap called without heap storage")
        }

        // Check if we need to grow
        if _count >= heap.capacity {
            _growHeap(minimumCapacity: _count + 1)
        }

        unsafe (_heapPtr! + _count).initialize(to: element)
        _count += 1
        heap.header = _count
    }

    /// Internal: grow heap storage.
    @usableFromInline
    mutating func _growHeap(minimumCapacity: Int) {
        guard let oldStorage = _heap else {
            preconditionFailure("_growHeap called without heap storage")
        }

        let newCapacity = Swift.max(minimumCapacity, oldStorage.capacity * 2)
        let newStorage = Stack<Element>.Storage.create(minimumCapacity: newCapacity)

        oldStorage._moveAllElements(to: newStorage, count: _count)
        newStorage.header = _count
        oldStorage.header = 0  // Elements moved, prevent double-free

        _heap = newStorage
        unsafe (_heapPtr = newStorage._elementsPointer)
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

        if let heap = _heap, let heapPtr = unsafe _heapPtr {
            heap.header = _count
            return unsafe (heapPtr + _count).move()
        } else {
            return _inline.move(at: _count)
        }
    }

    /// Removes all elements from the stack.
    ///
    /// Does not shrink back to inline storage if spilled.
    ///
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear() {
        guard _count > 0 else { return }

        if let heap = _heap {
            heap._deinitializeElements(in: 0..<_count)
            heap.header = 0
        } else {
            _inline.deinitialize(count: _count)
        }
        _count = 0
    }
}

// Note: Stack.Small is UNCONDITIONALLY ~Copyable due to the deinit requirement
// for inline storage cleanup. No CoW extensions are needed.

// MARK: - Peek

extension Stack.Small where Element: ~Copyable {
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

        if let heapPtr = unsafe _heapPtr {
            return try unsafe body((heapPtr + _count - 1).pointee)
        } else {
            return try unsafe body(_inline.read(at: _count - 1).pointee)
        }
    }
}

extension Stack.Small where Element: Copyable {
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

        if let heapPtr = unsafe _heapPtr {
            return unsafe (heapPtr + _count - 1).pointee
        } else {
            return unsafe _inline.read(at: _count - 1).pointee
        }
    }
}

// MARK: - Span Access

extension Stack.Small where Element: ~Copyable {
    /// Read-only span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    @inlinable
    public var span: Span<Element> {
        _read {
            if let heapPtr = unsafe _heapPtr {
                yield unsafe Span(_unsafeStart: heapPtr, count: _count)
            } else {
                yield unsafe Span(_unsafeStart: _inline.basePointer(), count: _count)
            }
        }
    }

    /// Mutable span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        _read {
            if let heapPtr = unsafe _heapPtr {
                yield unsafe MutableSpan(_unsafeStart: heapPtr, count: _count)
            } else {
                let ptr = unsafe UnsafeMutablePointer(mutating: _inline.basePointer())
                yield unsafe MutableSpan(_unsafeStart: ptr, count: _count)
            }
        }
        _modify {
            if let heapPtr = unsafe _heapPtr {
                var s = unsafe MutableSpan(_unsafeStart: heapPtr, count: _count)
                yield &s
            } else {
                var s = unsafe MutableSpan(_unsafeStart: _inline.mutableBasePointer(), count: _count)
                yield &s
            }
        }
    }
}

// MARK: - Sendable

/// `Stack.Small` is `Sendable` when its elements are `Sendable`.
extension Stack.Small: @unchecked Sendable where Element: Sendable {}

// MARK: - Iteration (for ~Copyable elements)

extension Stack.Small where Element: ~Copyable {
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
        if let heapPtr = unsafe _heapPtr {
            for i in 0..<_count {
                try unsafe body((heapPtr + i).pointee)
            }
        } else {
            for i in 0..<_count {
                try unsafe body(_inline.read(at: i).pointee)
            }
        }
    }
}

// MARK: - Truncate

extension Stack.Small where Element: ~Copyable {
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

        if let heap = _heap {
            heap._deinitializeElements(in: targetCount..<_count)
            heap.header = targetCount
        } else {
            for i in targetCount..<_count {
                unsafe _inline.pointer(at: i).deinitialize(count: 1)
            }
        }
        _count = targetCount
    }
}
