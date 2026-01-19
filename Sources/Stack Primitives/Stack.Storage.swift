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

// MARK: - ManagedBuffer-Backed Storage

/// Internal storage class for `Stack`.
///
/// Uses `ManagedBuffer` to combine header metadata (count) with element storage
/// in a single allocation. This architecture enables:
/// - Conditional `Copyable` conformance for `Stack`
/// - Copy-on-Write semantics for value types
/// - `Sequence` conformance when `Element: Copyable`
///
/// The header stores the current element count. Capacity is managed by
/// `ManagedBuffer.capacity`.
@usableFromInline
final class _StackStorage<Element: ~Copyable>: ManagedBuffer<Int, Element> {

    /// Creates empty storage with no capacity.
    @usableFromInline
    static func create() -> _StackStorage<Element> {
        let storage = _StackStorage.create(minimumCapacity: 0) { _ in 0 }
        return unsafe unsafeDowncast(storage, to: _StackStorage.self)
    }

    /// Creates storage with the specified minimum capacity.
    @usableFromInline
    static func create(minimumCapacity: Int) -> _StackStorage<Element> {
        let storage = _StackStorage.create(minimumCapacity: minimumCapacity) { _ in 0 }
        return unsafe unsafeDowncast(storage, to: _StackStorage.self)
    }

    deinit {
        let count = header
        guard count > 0 else { return }
        _ = unsafe withUnsafeMutablePointerToElements { elements in
            for i in 0..<count {
                unsafe (elements + i).deinitialize(count: 1)
            }
        }
    }

    // MARK: - Internal Helpers

    /// Returns pointer to element storage.
    @usableFromInline
    var _elementsPointer: UnsafeMutablePointer<Element> {
        unsafe withUnsafeMutablePointerToElements { unsafe $0 }
    }

    /// Initializes element at the given index.
    @usableFromInline
    func _initializeElement(at index: Int, to element: consuming Element) {
        let ptr = unsafe withUnsafeMutablePointerToElements { unsafe $0 + index }
        unsafe ptr.initialize(to: element)
    }

    /// Moves element from the given index.
    @usableFromInline
    func _moveElement(at index: Int) -> Element {
        unsafe withUnsafeMutablePointerToElements { elements in
            unsafe (elements + index).move()
        }
    }

    /// Deinitializes elements in the given range.
    @usableFromInline
    func _deinitializeElements(in range: Range<Int>) {
        _ = unsafe withUnsafeMutablePointerToElements { elements in
            for i in range {
                unsafe (elements + i).deinitialize(count: 1)
            }
        }
    }

    /// Moves all elements to new storage.
    @usableFromInline
    func _moveAllElements(to newStorage: _StackStorage<Element>, count: Int) {
        _ = unsafe withUnsafeMutablePointerToElements { old in
            unsafe newStorage.withUnsafeMutablePointerToElements { new in
                unsafe new.moveInitialize(from: old, count: count)
            }
        }
    }
}

// MARK: - Copyable Element Helpers

extension _StackStorage where Element: Copyable {

    /// Creates a copy of this storage with all elements duplicated.
    @usableFromInline
    func copy() -> _StackStorage<Element> {
        let count = header
        guard count > 0 else {
            return _StackStorage.create()
        }

        let new = _StackStorage.create(minimumCapacity: capacity)
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
    func _copyAllElements(to newStorage: _StackStorage<Element>, count: Int) {
        _ = unsafe withUnsafeMutablePointerToElements { old in
            unsafe newStorage.withUnsafeMutablePointerToElements { new in
                unsafe new.initialize(from: old, count: count)
            }
        }
    }
}
