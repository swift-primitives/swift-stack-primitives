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

public import Sequence_Primitives
public import Property_Primitives
public import Buffer_Linear_Primitives
public import Buffer_Linear_Inline_Primitives

// Note: Stack.Static is unconditionally ~Copyable (inline storage requires deinit),
// so it cannot conform to Swift.Sequence which requires Copyable.
// It conforms to Sequence.Protocol which supports ~Copyable containers.

// ============================================================================
// MARK: - Iterator
// ============================================================================

extension Stack.Static where Element: Copyable {
    /// Iterator for Stack.Static elements.
    ///
    /// Copies elements to a `Buffer.Linear` snapshot for safe iteration,
    /// avoiding pointer escape issues with inline storage.
    public struct Iterator: Sequence.Iterator.`Protocol`, IteratorProtocol {
        @usableFromInline
        let _buffer: Buffer<Element>.Linear

        @usableFromInline
        let _end: Stack<Element>.Index.Count

        @usableFromInline
        var _position: Stack<Element>.Index = .zero

        @usableFromInline
        init(_buffer: Buffer<Element>.Linear) {
            self._buffer = _buffer
            self._end = _buffer.count
        }

        @inlinable
        public mutating func next() -> Element? {
            guard _position < _end else { return nil }
            let element = _buffer[_position]
            _position += .one
            return element
        }
    }
}

extension Stack.Static.Iterator: Sendable where Element: Sendable {}

// ============================================================================
// MARK: - Sequence.Protocol Conformance
// ============================================================================

extension Stack.Static: Sequence.`Protocol` where Element: Copyable {
    /// Returns an iterator over the stack elements.
    ///
    /// Copies elements to a `Buffer.Linear` snapshot for safe iteration,
    /// avoiding pointer escape issues with inline storage.
    ///
    /// - Note: Incurs O(n) copy cost. For performance-critical code, use
    ///   the mutating `forEach` method instead.
    @inlinable
    public borrowing func makeIterator() -> Iterator {
        var snapshot = Buffer<Element>.Linear(minimumCapacity: count)
        var idx: Stack<Element>.Index = .zero
        let end = count.map(Ordinal.init)
        while idx < end {
            snapshot.append(_buffer[idx])
            idx += .one
        }
        return Iterator(_buffer: snapshot)
    }

    /// Returns the count as the underestimated count since we know the exact size.
    @inlinable
    public var underestimatedCount: Int { Int(bitPattern: count) }
}

// ============================================================================
// MARK: - Sequence.Clearable Conformance
// ============================================================================

extension Stack.Static: Sequence.Clearable where Element: Copyable {
    /// Removes all elements from the stack.
    ///
    /// This enables `.forEach.consuming { }` pattern via `Property.View` extension.
    @inlinable
    public mutating func removeAll() {
        clear()
    }
}

// ============================================================================
// MARK: - Sequence.Drain.Protocol Conformance
// ============================================================================

extension Stack.Static: Sequence.Drain.`Protocol` where Element: Copyable {
    /// Drains all elements, passing each to the closure with ownership.
    ///
    /// After this method returns, the stack is empty but still usable.
    ///
    /// - Parameter body: A closure that receives each drained element with ownership.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func drain(_ body: (consuming Element) -> Void) {
        var idx: Stack<Element>.Index = .zero
        let end = count.map(Ordinal.init)
        while idx < end {
            body(_buffer[idx])
            idx += .one
        }
        _buffer.removeAll()
    }
}

// ============================================================================
// MARK: - Property Accessors
// ============================================================================

extension Stack.Static where Element: Copyable {
    /// Accessor for drain operations.
    public var drain: Property<Sequence.Drain, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Drain, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for forEach operations.
    public var forEach: Property<Sequence.ForEach, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.ForEach, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for predicate satisfaction checks.
    public var satisfies: Property<Sequence.Satisfies, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Satisfies, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for finding the first matching element.
    public var first: Property<Sequence.First, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.First, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for reduce operations.
    public var reduce: Property<Sequence.Reduce, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Reduce, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for containment checks.
    public var contains: Property<Sequence.Contains, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Contains, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for drop operations.
    public var drop: Property<Sequence.Drop, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Drop, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }

    /// Accessor for prefix operations.
    public var prefix: Property<Sequence.Prefix, Self>.View.Typed<Element>.Valued<capacity> {
        mutating _read { yield unsafe .init(&self) }
        mutating _modify { var view: Property<Sequence.Prefix, Self>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self); yield &view }
    }
}
