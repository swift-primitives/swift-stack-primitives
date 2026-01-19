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

/// A dynamically-growing LIFO stack supporting move-only elements.
///
/// `Stack` is the general-purpose stack primitive. It provides O(1) amortized push
/// and O(1) pop with automatic capacity growth. This is the canonical stack type—
/// use it unless you have specific constraints requiring a variant.
///
/// ## Example
///
/// ```swift
/// var stack = Stack<Int>()
/// stack.push(1)
/// stack.push(2)
/// stack.pop()        // Optional(2)
/// stack.peek { $0 }  // Optional(1)
/// ```
///
/// ## Variants
///
/// - ``Stack``: Dynamically-growing with amortized O(1) push (this type)
/// - ``Stack/Bounded``: Fixed-capacity with upfront allocation, throws on overflow
/// - ``Stack/Inline``: Zero-allocation inline storage with compile-time capacity
///
/// ## Move-Only Support
///
/// Both the stack and its elements can be `~Copyable`:
///
/// ```swift
/// struct FileHandle: ~Copyable { ... }
/// var handles = Stack<FileHandle>()
/// handles.push(FileHandle())
/// ```
///
/// ## Growth Behavior
///
/// When capacity is exceeded, the stack allocates new storage at 2x the
/// current capacity (minimum 4) and moves all elements. This provides
/// O(1) amortized push with approximately 2.0 copies per element over
/// the stack's lifetime.
@safe
public struct Stack<Element: ~Copyable>: ~Copyable {
    @usableFromInline
    var storage: UnsafeMutablePointer<Element>

    @usableFromInline
    var _capacity: Int

    @usableFromInline
    var _count: Int

    // MARK: - Inline (declared here to fix Swift compiler bug with ~Copyable in extensions)

    /// A fixed-capacity, inline-storage LIFO stack with compile-time capacity.
    ///
    /// `Stack.Inline` stores elements directly within the struct's memory layout,
    /// requiring no heap allocation. The capacity is specified as a compile-time
    /// generic parameter.
    ///
    /// - Note: This type is declared inside `Stack` (not in an extension) due to a
    ///   Swift compiler bug where nested types with value generic parameters declared
    ///   in extensions do not properly inherit `~Copyable` constraints from the outer type.
    public struct Inline<let capacity: Int>: ~Copyable {
        /// Maximum element stride supported by inline storage (64 bytes per slot).
        @usableFromInline
        static var _maxStride: Int { 64 }

        /// Raw byte storage. Each slot is 64 bytes (8 Ints on 64-bit).
        @usableFromInline
        var _storage: InlineArray<capacity, (Int, Int, Int, Int, Int, Int, Int, Int)>

        @usableFromInline
        var _count: Int

        /// Creates an empty inline stack.
        @inlinable
        public init() {
            precondition(
                MemoryLayout<Element>.stride <= Self._maxStride,
                "Element stride (\(MemoryLayout<Element>.stride)) exceeds inline storage slot size (\(Self._maxStride) bytes). Use Stack.Bounded instead."
            )
            precondition(
                MemoryLayout<Element>.alignment <= MemoryLayout<Int>.alignment,
                "Element alignment (\(MemoryLayout<Element>.alignment)) exceeds inline storage alignment (\(MemoryLayout<Int>.alignment)). Use Stack.Bounded instead."
            )
            self._storage = InlineArray(repeating: (0, 0, 0, 0, 0, 0, 0, 0))
            self._count = 0
        }

        /// Creates an inline stack initialized with elements from a sequence.
        ///
        /// - Parameter elements: The elements to push onto the stack.
        /// - Throws: ``Stack/Inline/Error/overflow`` if the sequence exceeds capacity.
        /// - Complexity: O(n) where n is the number of elements.
        @inlinable
        public init(_ elements: some Sequence<Element>) throws(__StackInlineError) {
            self.init()
            for element in elements {
                try push(element)
            }
        }

        deinit {
            let count = _count
            guard count > 0 else { return }

            let stride = MemoryLayout<Element>.stride
            unsafe Swift.withUnsafeBytes(of: _storage) { bytes in
                let basePtr = unsafe UnsafeMutableRawPointer(mutating: bytes.baseAddress!)
                for i in 0..<count {
                    let elementPtr = unsafe (basePtr + i * stride)
                        .assumingMemoryBound(to: Element.self)
                    unsafe elementPtr.deinitialize(count: 1)
                }
            }
        }

        /// Returns a mutable pointer to the element at the given index.
        @usableFromInline
        @unsafe
        mutating func _pointerToElement(at index: Int) -> UnsafeMutablePointer<Element> {
            let stride = MemoryLayout<Element>.stride
            return unsafe Swift.withUnsafeMutablePointer(to: &_storage) { storagePtr in
                let basePtr = UnsafeMutableRawPointer(storagePtr)
                let elementPtr = unsafe (basePtr + index * stride)
                    .assumingMemoryBound(to: Element.self)
                return unsafe elementPtr
            }
        }

        /// Returns a read-only pointer to the element at the given index.
        @usableFromInline
        @unsafe
        func _readPointerToElement(at index: Int) -> UnsafePointer<Element> {
            let stride = MemoryLayout<Element>.stride
            return unsafe Swift.withUnsafePointer(to: _storage) { storagePtr in
                let basePtr = unsafe UnsafeRawPointer(storagePtr)
                let elementPtr = unsafe (basePtr + index * stride)
                    .assumingMemoryBound(to: Element.self)
                return unsafe elementPtr
            }
        }

        /// Returns the base pointer for element storage.
        @usableFromInline
        @unsafe
        func _basePointer() -> UnsafePointer<Element> {
            unsafe Swift.withUnsafePointer(to: _storage) { storagePtr in
                let basePtr = unsafe UnsafeRawPointer(storagePtr)
                return unsafe basePtr.assumingMemoryBound(to: Element.self)
            }
        }

        /// Returns the mutable base pointer for element storage.
        @usableFromInline
        @unsafe
        mutating func _mutableBasePointer() -> UnsafeMutablePointer<Element> {
            unsafe Swift.withUnsafeMutablePointer(to: &_storage) { storagePtr in
                let basePtr = UnsafeMutableRawPointer(storagePtr)
                return unsafe basePtr.assumingMemoryBound(to: Element.self)
            }
        }
    }
    
    /// A fixed-capacity LIFO stack supporting move-only elements.
    ///
    /// `Stack.Bounded` allocates storage upfront and throws on overflow.
    /// Use this variant when capacity is known or in contexts requiring
    /// predictable memory behavior (embedded, real-time).
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = try Stack<Int>.Bounded(capacity: 10)
    /// try stack.push(1)
    /// try stack.push(2)
    /// stack.pop()        // Optional(2)
    /// stack.peek { $0 }  // Optional(1)
    /// ```
    ///
    /// ## When to Use
    ///
    /// Use `Stack.Bounded` when:
    /// - Maximum capacity is known at runtime
    /// - Predictable memory behavior is required (embedded, real-time)
    /// - Overflow should be an explicit error
    ///
    /// For unbounded growth, use ``Stack`` (the canonical type).
    /// For compile-time capacity with zero heap allocation, use ``Stack/Inline``.
    ///
    /// ## Move-Only Support
    ///
    /// Both the stack and its elements can be `~Copyable`:
    ///
    /// ```swift
    /// struct FileHandle: ~Copyable { ... }
    /// var handles = try Stack<FileHandle>.Bounded(capacity: 5)
    /// try handles.push(FileHandle())
    /// ```
    @safe
    public struct Bounded: ~Copyable {
        @usableFromInline
        var storage: UnsafeMutablePointer<Element>

        /// The maximum number of elements the stack can hold.
        public let capacity: Int

        /// The current number of elements in the stack.
        @usableFromInline
        var _count: Int

        /// Creates a stack with the specified capacity.
        ///
        /// - Parameter capacity: Maximum number of elements. Must be non-negative.
        /// - Throws: ``Stack/Bounded/Error/invalidCapacity`` if capacity is negative.
        @inlinable
        public init(capacity: Int) throws(__StackBoundedError) {
            guard capacity >= 0 else {
                throw .invalidCapacity
            }

            if capacity == 0 {
                unsafe self.storage = UnsafeMutablePointer<Element>(bitPattern: MemoryLayout<Element>.alignment)!
                self.capacity = 0
                self._count = 0
                return
            }

            let storage = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
            unsafe self.storage = storage
            self.capacity = capacity
            self._count = 0
        }

        /// Creates a stack initialized with elements from a sequence.
        ///
        /// - Parameter capacity: Maximum number of elements. Must be non-negative.
        /// - Parameter elements: The elements to push onto the stack.
        /// - Throws: ``Stack/Bounded/Error/invalidCapacity`` if capacity is negative,
        ///   or ``Stack/Bounded/Error/overflow`` if the sequence exceeds capacity.
        /// - Complexity: O(n) where n is the number of elements.
        @inlinable
        public init(capacity: Int, _ elements: some Sequence<Element>) throws(__StackBoundedError) {
            try self.init(capacity: capacity)
            for element in elements {
                try push(element)
            }
        }

        deinit {
            for i in 0..<_count {
                unsafe (storage + i).deinitialize(count: 1)
            }
            if capacity > 0 {
                unsafe storage.deallocate()
            }
        }
    }

    /// Creates an empty stack.
    ///
    /// No allocation occurs until the first push.
    @inlinable
    public init() {
        unsafe self.storage = UnsafeMutablePointer<Element>(bitPattern: MemoryLayout<Element>.alignment)!
        self._capacity = 0
        self._count = 0
    }

    /// Creates a stack initialized with elements from a sequence.
    ///
    /// - Parameter elements: The elements to push onto the stack.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public init(_ elements: some Sequence<Element>) {
        self.init()
        for element in elements {
            push(element)
        }
    }

    /// Creates a stack with reserved capacity.
    ///
    /// Pre-allocates storage for the specified number of elements.
    /// Useful when the approximate number of elements is known.
    ///
    /// - Parameter capacity: Number of elements to reserve space for. Must be non-negative.
    /// - Throws: ``Stack/Error/invalidCapacity`` if capacity is negative.
    /// - Note: Error type is ``Stack/Error``.
    @inlinable
    public init(reservingCapacity capacity: Int) throws(__StackError) {
        guard capacity >= 0 else {
            throw .invalidCapacity
        }

        if capacity == 0 {
            unsafe self.storage = UnsafeMutablePointer<Element>(bitPattern: MemoryLayout<Element>.alignment)!
            self._capacity = 0
        } else {
            unsafe self.storage = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
            self._capacity = capacity
        }
        self._count = 0
    }

    deinit {
        for i in 0..<_count {
            unsafe (storage + i).deinitialize(count: 1)
        }
        if _capacity > 0 {
            unsafe storage.deallocate()
        }
    }
}

// MARK: - Properties

extension Stack where Element: ~Copyable {
    /// The current number of elements in the stack.
    @inlinable
    public var count: Int { _count }

    /// Whether the stack is empty.
    @inlinable
    public var isEmpty: Bool { _count == 0 }

    /// The current capacity of the stack.
    @inlinable
    public var capacity: Int { _capacity }
}

// MARK: - Capacity Management

extension Stack where Element: ~Copyable {
    /// Ensures the stack has capacity for at least the specified number of elements.
    @usableFromInline
    mutating func ensureCapacity(_ minimumCapacity: Int) {
        guard _capacity < minimumCapacity else { return }

        // Growth factor 2.0, minimum capacity 4
        let newCapacity = max(minimumCapacity, _capacity * 2, 4)
        let newStorage = UnsafeMutablePointer<Element>.allocate(capacity: newCapacity)

        // Move elements to new storage
        for i in 0..<_count {
            unsafe (newStorage + i).initialize(to: (storage + i).move())
        }

        if _capacity > 0 {
            unsafe storage.deallocate()
        }

        unsafe storage = newStorage
        _capacity = newCapacity
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

// MARK: - Core Operations

extension Stack where Element: ~Copyable {
    /// Pushes an element onto the stack.
    ///
    /// - Parameter element: The element to push.
    /// - Complexity: O(1) amortized
    @inlinable
    public mutating func push(_ element: consuming Element) {
        ensureCapacity(_count + 1)
        unsafe (storage + _count).initialize(to: element)
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
        return unsafe (storage + _count).move()
    }

    /// Removes all elements from the stack.
    ///
    /// - Parameter keepingCapacity: If `true`, the stack keeps its current capacity.
    ///   If `false`, the storage is deallocated. Default is `true`.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public mutating func clear(keepingCapacity: Bool = true) {
        for i in 0..<_count {
            unsafe (storage + i).deinitialize(count: 1)
        }
        _count = 0

        if !keepingCapacity && _capacity > 0 {
            unsafe storage.deallocate()
            unsafe storage = UnsafeMutablePointer<Element>(bitPattern: MemoryLayout<Element>.alignment)!
            _capacity = 0
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
    public func peek<R, E: Swift.Error>(_ body: (borrowing Element) throws(E) -> R) throws(E) -> R? {
        guard _count > 0 else {
            return nil
        }
        return try unsafe body((storage + _count - 1).pointee)
    }
}

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
        guard _count > 0 else {
            return nil
        }
        return unsafe (storage + _count - 1).pointee
    }
}

// MARK: - Span Access

extension Stack where Element: ~Copyable {
    /// Read-only span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    ///
    /// ## Lifetime Contract
    ///
    /// - The span is valid ONLY for the duration of the borrow of `self`.
    /// - The span MUST NOT be stored, returned, or allowed to escape.
    @inlinable
    public var span: Span<Element> {
        @_lifetime(borrow self)
        borrowing get {
            unsafe Span(_unsafeStart: storage, count: _count)
        }
    }

    /// Mutable span of the stack elements.
    ///
    /// Elements are ordered from bottom (index 0) to top (index count-1).
    ///
    /// ## Lifetime Contract
    ///
    /// - The span is valid ONLY for the duration of the exclusive mutable borrow.
    /// - The span MUST NOT be stored, returned, or allowed to escape.
    @inlinable
    public var mutableSpan: MutableSpan<Element> {
        @_lifetime(&self)
        mutating get {
            unsafe MutableSpan(_unsafeStart: storage, count: _count)
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
    public func withUnsafePointer<R, E: Swift.Error>(
        at index: Int,
        _ body: (UnsafePointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        precondition(index >= 0 && index < _count)
        return try unsafe body(storage + index)
    }

    /// Provides mutable pointer access to the element at the specified index.
    ///
    /// - Warning: This is an escape hatch for C interop. Prefer `mutableSpan` for safe access.
    /// - Warning: The pointer must not escape the closure scope.
    @_spi(Unsafe)
    @unsafe
    @inlinable
    public mutating func withUnsafeMutablePointer<R, E: Swift.Error>(
        at index: Int,
        _ body: (UnsafeMutablePointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        precondition(index >= 0 && index < _count)
        return try unsafe body(storage + index)
    }
}

// MARK: - Sendable

/// `Stack` is `Sendable` when its elements are `Sendable`.
///
/// This conformance allows the stack to be transferred between tasks.
/// However, concurrent mutation requires external synchronization—
/// the stack itself provides no thread-safety guarantees.
extension Stack: @unchecked Sendable where Element: Sendable {}

// MARK: - ExpressibleByArrayLiteral

extension Stack: ExpressibleByArrayLiteral where Element: Copyable {
    /// Creates a stack from an array literal.
    ///
    /// ```swift
    /// var stack: Stack<Int> = [1, 2, 3, 4, 5]
    /// ```
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            push(element)
        }
    }
}
