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

public import Buffer_Linear_Primitive
public import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Storage_Contiguous_Primitives
public import Buffer_Linear_Primitives
import Index_Primitives
import Ordinal_Primitives

// MARK: - Copy-on-Write (Copyable elements only)

extension Stack where Element: Copyable {
    /// Pushes an element onto the stack (CoW-aware).
    ///
    /// This method shadows the base `push(_:)` when `Element: Copyable`,
    /// providing copy-on-write semantics.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized, O(n) if copy triggered
    @inlinable
    public mutating func push(_ element: Element) {
        _buffer.append(element)
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
        guard !_buffer.isEmpty else {
            return nil
        }
        return _buffer.remove.last()
    }

    /// Removes all elements from the stack (CoW-aware).
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is released. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        _buffer.remove.all()

        if !keepingCapacity {
            _buffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear(minimumCapacity: .zero)
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
        guard !_buffer.isEmpty else {
            return nil
        }
        let topIndex = _buffer.count.subtract.saturating(.one).map(Ordinal.init)
        return _buffer[topIndex]
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
    ///
    /// Forwards the base `Buffer.Linear`'s form-α `mutableSpan()` *method* (D1).
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get {
            _buffer.mutableSpan()
        }
    }
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
        let currentCount = _buffer.count
        guard _buffer.capacity > currentCount else { return }

        if currentCount == .zero {
            _buffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear(minimumCapacity: .zero)
            return
        }

        var newBuffer = Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linear(minimumCapacity: currentCount)
        var idx: Index = .zero
        let end = currentCount.map(Ordinal.init)
        while idx < end {
            newBuffer.append(_buffer[idx])
            idx += .one
        }
        _buffer = newBuffer
    }

    /// Removes elements beyond the specified count (CoW-aware).
    ///
    /// If `newCount >= count`, this method has no effect.
    /// Elements are removed from the top of the stack.
    ///
    /// - Parameter newCount: The maximum number of elements to retain.
    /// - Complexity: O(k) where k is the number of removed elements.
    @inlinable
    public mutating func truncate(to newCount: Index.Count) {
        _buffer.truncate(to: newCount)
    }
}

// MARK: - Drain (Copyable)

extension Stack where Element: Copyable {
    /// Drains all elements, passing each to the closure with ownership.
    ///
    /// After this method returns, the stack is empty but still usable.
    /// Elements are drained from bottom (oldest) to top (newest).
    ///
    /// - Parameter body: A closure that receives each drained element with ownership.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        _buffer.ensureUnique()
        while !_buffer.isEmpty {
            body(_buffer.remove.last())
        }
    }

    /// Drains elements in LIFO order while the predicate returns true.
    ///
    /// Repeatedly peeks at the top element; if the predicate returns true,
    /// pops (consumes) the element and passes it to body; if false, stops.
    /// The stack survives with remaining elements intact.
    ///
    /// - Parameters:
    ///   - predicate: A closure that receives a borrowed reference to the top element.
    ///     Return `true` to drain it, `false` to stop.
    ///   - body: A closure that receives each drained element with ownership.
    /// - Complexity: O(k) where k is the number of elements drained.
    @inlinable
    public mutating func drain(
        while predicate: (borrowing Element) -> Bool,
        _ body: (consuming Element) -> Void
    ) {
        _buffer.ensureUnique()
        while let element = peek(), predicate(element) {
            body(pop()!)
        }
    }
}
