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

extension Stack.Storage where Element: ~Copyable {

    /// Inline (stack-allocated) storage for small-buffer optimization.
    ///
    /// Provides the same element management API as `Stack.Storage` but for
    /// elements stored inline within a containing struct. Used by `Stack.Small`
    /// and `Stack.Inline` for their inline storage needs.
    ///
    /// ## API Symmetry with Stack.Storage
    ///
    /// | Heap (`Stack.Storage`) | Inline (`Stack.Storage.Inline`) |
    /// |------------------------|--------------------------------|
    /// | `_initializeElement(at:to:)` | `initialize(to:at:)` |
    /// | `_moveElement(at:)` | `move(at:)` |
    /// | `_deinitializeElements(in:)` | `deinitialize(count:)` |
    /// | `_moveAllElements(to:count:)` | `move(to:count:)` |
    /// | `_elementsPointer` | `mutableBasePointer()` |
    ///
    /// The inline variant requires `count` to be passed explicitly since it
    /// doesn't store count internally (the containing type manages count).
    @safe
    @usableFromInline
    struct Inline<let capacity: Int>: ~Copyable {

        /// Raw byte storage (64 bytes per slot).
        @usableFromInline
        var raw: InlineArray<capacity, (Int, Int, Int, Int, Int, Int, Int, Int)>

        /// Maximum element stride supported (64 bytes).
        @inlinable
        static var maxStride: Int { 64 }

        // MARK: - Lifecycle

        /// Creates uninitialized inline storage.
        ///
        /// - Precondition: Element stride must not exceed 64 bytes.
        /// - Precondition: Element alignment must not exceed `Int` alignment.
        @inlinable
        init() {
            precondition(
                MemoryLayout<Element>.stride <= Self.maxStride,
                "Element stride (\(MemoryLayout<Element>.stride)) exceeds inline storage slot size (\(Self.maxStride) bytes). Use Stack.Bounded instead."
            )
            precondition(
                MemoryLayout<Element>.alignment <= MemoryLayout<Int>.alignment,
                "Element alignment (\(MemoryLayout<Element>.alignment)) exceeds inline storage alignment (\(MemoryLayout<Int>.alignment)). Use Stack.Bounded instead."
            )
            self.raw = InlineArray(repeating: (0, 0, 0, 0, 0, 0, 0, 0))
        }
    }
}

extension Stack.Storage.Inline where Element: ~Copyable {
    // MARK: - Element Access (Mutable)

    /// Returns mutable pointer to element at index.
    ///
    /// - Parameter index: The index of the element.
    /// - Returns: A mutable pointer to the element.
    /// - Precondition: Index must be in bounds (caller's responsibility).
    @usableFromInline
    @unsafe
    mutating func pointer(at index: Int) -> UnsafeMutablePointer<Element> {
        let stride = MemoryLayout<Element>.stride
        return unsafe Swift.withUnsafeMutablePointer(to: &raw) { rawPointer in
            let base = UnsafeMutableRawPointer(rawPointer)
            return unsafe (base + index * stride).assumingMemoryBound(to: Element.self)
        }
    }

    /// Initializes element at the given index.
    ///
    /// - Parameters:
    ///   - element: The element to store (consumed).
    ///   - index: The index to initialize.
    /// - Precondition: The slot at index must be uninitialized.
    @usableFromInline
    mutating func initialize(to element: consuming Element, at index: Int) {
        let ptr = unsafe pointer(at: index)
        unsafe ptr.initialize(to: element)
    }

    /// Moves element from the given index.
    ///
    /// - Parameter index: The index to move from.
    /// - Returns: The moved element.
    /// - Precondition: The slot at index must be initialized.
    /// - Postcondition: The slot at index is deinitialized.
    @usableFromInline
    mutating func move(at index: Int) -> Element {
        unsafe pointer(at: index).move()
    }

    // MARK: - Element Access (Read-Only)

    /// Returns read-only pointer to element at index.
    ///
    /// - Parameter index: The index of the element.
    /// - Returns: A read-only pointer to the element.
    /// - Precondition: Index must be in bounds (caller's responsibility).
    @usableFromInline
    @unsafe
    func read(at index: Int) -> UnsafePointer<Element> {
        let stride = MemoryLayout<Element>.stride
        return unsafe Swift.withUnsafePointer(to: raw) { rawPointer in
            let base = unsafe UnsafeRawPointer(rawPointer)
            return unsafe (base + index * stride).assumingMemoryBound(to: Element.self)
        }
    }

    // MARK: - Base Pointers (for Span access)

    /// Returns the base pointer for element storage.
    ///
    /// Used for constructing `Span` views over the inline storage.
    ///
    /// - Returns: A read-only pointer to the first element slot.
    @usableFromInline
    @unsafe
    func basePointer() -> UnsafePointer<Element> {
        unsafe Swift.withUnsafePointer(to: raw) { rawPointer in
            let base = unsafe UnsafeRawPointer(rawPointer)
            return unsafe base.assumingMemoryBound(to: Element.self)
        }
    }

    /// Returns the mutable base pointer for element storage.
    ///
    /// Used for constructing `MutableSpan` views over the inline storage.
    ///
    /// - Returns: A mutable pointer to the first element slot.
    @usableFromInline
    @unsafe
    mutating func mutableBasePointer() -> UnsafeMutablePointer<Element> {
        unsafe Swift.withUnsafeMutablePointer(to: &raw) { rawPointer in
            let base = UnsafeMutableRawPointer(rawPointer)
            return unsafe base.assumingMemoryBound(to: Element.self)
        }
    }

    // MARK: - Bulk Operations

    /// Deinitializes all elements up to count.
    ///
    /// - Parameter count: The number of initialized elements.
    /// - Precondition: Elements at indices 0..<count must be initialized.
    /// - Postcondition: All elements are deinitialized.
    /// - Note: Non-mutating to allow use from deinit contexts.
    @usableFromInline
    func deinitialize(count: Int) {
        guard count > 0 else { return }
        let stride = MemoryLayout<Element>.stride
        unsafe Swift.withUnsafePointer(to: raw) { rawPointer in
            let base = unsafe UnsafeMutableRawPointer(mutating: UnsafeRawPointer(rawPointer))
            for i in 0..<count {
                unsafe (base + i * stride)
                    .assumingMemoryBound(to: Element.self)
                    .deinitialize(count: 1)
            }
        }
    }

    /// Moves all elements to heap storage.
    ///
    /// Used when spilling from inline to heap storage.
    ///
    /// - Parameters:
    ///   - heapStorage: The destination heap storage.
    ///   - count: The number of initialized elements.
    /// - Precondition: Elements at indices 0..<count must be initialized.
    /// - Precondition: Heap storage must have sufficient capacity.
    /// - Postcondition: Elements are moved to heap, inline slots are deinitialized.
    @usableFromInline
    mutating func move(to heapStorage: Stack<Element>.Storage, count: Int) {
        guard count > 0 else { return }
        let stride = MemoryLayout<Element>.stride
        unsafe Swift.withUnsafePointer(to: raw) { rawPointer in
            unsafe heapStorage.withUnsafeMutablePointerToElements { dst in
                let base = unsafe UnsafeMutableRawPointer(mutating: UnsafeRawPointer(rawPointer))
                for i in 0..<count {
                    let src = unsafe (base + i * stride).assumingMemoryBound(to: Element.self)
                    unsafe (dst + i).initialize(to: src.move())
                }
            }
        }
    }
}

// MARK: - Copyable Element Extensions

extension Stack.Storage.Inline where Element: Copyable {
    /// Copies all elements to heap storage.
    ///
    /// - Parameters:
    ///   - heapStorage: The destination heap storage.
    ///   - count: The number of initialized elements.
    /// - Precondition: Elements at indices 0..<count must be initialized.
    /// - Precondition: Heap storage must have sufficient capacity.
    @usableFromInline
    func copy(to heapStorage: Stack<Element>.Storage, count: Int) {
        guard count > 0 else { return }
        let stride = MemoryLayout<Element>.stride
        unsafe Swift.withUnsafePointer(to: raw) { rawPointer in
            unsafe heapStorage.withUnsafeMutablePointerToElements { dst in
                let base = unsafe UnsafeRawPointer(rawPointer)
                for i in 0..<count {
                    let src = unsafe (base + i * stride).assumingMemoryBound(to: Element.self)
                    unsafe (dst + i).initialize(to: src.pointee)
                }
            }
        }
    }
}
