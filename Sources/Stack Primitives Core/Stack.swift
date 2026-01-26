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
/// ## Sequence Conformance
///
/// When `Element` is `Copyable`, `Stack` conforms to `Sequence`:
///
/// ```swift
/// var stack = Stack<Int>()
/// stack.push(1)
/// stack.push(2)
/// for element in stack {
///     print(element)  // 1, then 2
/// }
/// ```
///
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
///
/// ## Copy-on-Write
///
/// When `Element` is `Copyable`, `Stack` uses copy-on-write semantics:
/// copies share storage until mutation, providing efficient value semantics.
///
/// ## Growth Behavior
///
/// When capacity is exceeded, the stack allocates new storage at 2x the
/// current capacity (minimum 4) and moves all elements. This provides
/// O(1) amortized push with approximately 2.0 copies per element over
/// the stack's lifetime.
@safe
public struct Stack<Element: ~Copyable>: ~Copyable {

    // MARK: - Unified Storage (nested to inherit Element's ~Copyable context)

    /// Internal storage class for both `Stack` and `Stack.Bounded`.
    ///
    /// Uses `ManagedBuffer` for efficient single-allocation storage.
    /// Declared as a nested class inside `Stack` so that the `Element` generic
    /// inherits the `~Copyable` suppression from the outer type. This enables
    /// both `Stack` and `Stack.Bounded` to be conditionally Copyable.
    ///
    /// - Note: This must be nested, not module-level, due to Swift's generic
    ///   constraint propagation limitations with `~Copyable` and nested types.
    @usableFromInline
    final class Storage: ManagedBuffer<Int, Element> {

        /// Creates empty storage with no capacity.
        @usableFromInline
        static func create() -> Storage {
            let storage = Storage.create(minimumCapacity: 0) { _ in 0 }
            return unsafe unsafeDowncast(storage, to: Storage.self)
        }

        /// Creates storage with the specified minimum capacity.
        @usableFromInline
        static func create(minimumCapacity: Int) -> Storage {
            let storage = Storage.create(minimumCapacity: minimumCapacity) { _ in 0 }
            return unsafe unsafeDowncast(storage, to: Storage.self)
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
        func _moveAllElements(to newStorage: Storage, count: Int) {
            _ = unsafe withUnsafeMutablePointerToElements { old in
                unsafe newStorage.withUnsafeMutablePointerToElements { new in
                    unsafe new.moveInitialize(from: old, count: count)
                }
            }
        }
    }

    @usableFromInline
    var _storage: Storage

    /// Cached pointer to element storage. Stored in struct to enable property-based Span access.
    /// CRITICAL: Must be updated whenever _storage is replaced (reallocation, CoW copy).
    @usableFromInline
    var _cachedPtr: UnsafeMutablePointer<Element>

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
        /// Inline storage using shared `Storage.Inline` type.
        @usableFromInline
        var _storage: Stack<Element>.Storage.Inline<capacity>

        @usableFromInline
        var _count: Int

        /// Workaround for Swift compiler bug where deinit element cleanup
        /// fails for ~Copyable structs that contain only value-type properties.
        /// Adding a reference type property (`AnyObject?`) fixes the bug.
        /// See: https://github.com/swiftlang/swift/issues/86652
        @usableFromInline
        var _deinitWorkaround: AnyObject? = nil

        /// Creates an empty inline stack.
        @inlinable
        public init() {
            self._storage = .init()  // Preconditions handled by Storage.Inline
            self._count = 0
        }

        deinit {
            _storage.deinitialize(count: _count)
        }
    }

    // MARK: - Small (SmallVec-style: inline then spill to heap)

    /// A LIFO stack with small-buffer optimization (SmallVec pattern).
    ///
    /// `Stack.Small` stores up to `inlineCapacity` elements in inline storage,
    /// then automatically spills to heap storage when that capacity is exceeded.
    /// This provides the performance benefits of inline storage for common cases
    /// while supporting unbounded growth.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = Stack<Int>.Small<4>()  // Inline up to 4 elements
    /// stack.push(1)  // Inline
    /// stack.push(2)  // Inline
    /// stack.push(3)  // Inline
    /// stack.push(4)  // Inline
    /// stack.push(5)  // Spills to heap, moves all elements
    /// ```
    ///
    /// ## When to Use
    ///
    /// Use `Stack.Small` when:
    /// - Most instances will hold a small number of elements
    /// - Occasional large instances need to be supported
    /// - Zero heap allocation for the common case is important
    ///
    /// For fixed capacity with no spill, use ``Stack/Inline``.
    /// For unbounded growth from the start, use ``Stack``.
    ///
    /// ## Non-Copyable
    ///
    /// `Stack.Small` is unconditionally `~Copyable` (move-only) because it requires
    /// a deinitializer to clean up inline storage. If you need `Copyable` semantics
    /// with value generic capacity, use ``Stack`` instead (which always heap-allocates
    /// and supports conditional `Copyable` conformance).
    ///
    /// - Note: This type is declared inside `Stack` (not in an extension) due to a
    ///   Swift compiler bug where nested types with value generic parameters declared
    ///   in extensions do not properly inherit `~Copyable` constraints from the outer type.
    @safe
    public struct Small<let inlineCapacity: Int>: ~Copyable {
        /// Inline storage using shared `Storage.Inline` type.
        @usableFromInline
        var _inline: Stack<Element>.Storage.Inline<inlineCapacity>

        /// Current element count (valid elements in either inline or heap storage).
        @usableFromInline
        var _count: Int

        /// Heap storage when spilled. Nil when using inline storage.
        @usableFromInline
        var _heap: Storage?

        /// Cached pointer to heap elements. Only valid when _heap is non-nil.
        @usableFromInline
        var _heapPtr: UnsafeMutablePointer<Element>?

        /// Creates an empty small stack.
        @inlinable
        public init() {
            self._inline = .init()  // Preconditions handled by Storage.Inline
            self._count = 0
            self._heap = nil
            unsafe self._heapPtr = nil
        }

        deinit {
            if let heap = _heap {
                // Elements are on heap - Storage handles cleanup via its deinit
                // But we need to set count for deinit
                heap.header = _count
            } else {
                // Elements are inline - delegate to Storage.Inline
                _inline.deinitialize(count: _count)
            }
        }

        /// Whether the stack is currently using heap storage.
        @inlinable
        public var isSpilled: Bool { _heap != nil }

        /// Spills inline storage to heap.
        @usableFromInline
        mutating func _spillToHeap(minimumCapacity: Int) {
            precondition(_heap == nil, "Already spilled")

            // Create heap storage with growth factor
            let newCapacity = Swift.max(minimumCapacity, inlineCapacity * 2, 8)
            let newStorage = Storage.create(minimumCapacity: newCapacity)

            // Move elements from inline to heap using Storage.Inline
            _inline.move(to: newStorage, count: _count)
            newStorage.header = _count

            _heap = newStorage
            unsafe (_heapPtr = newStorage._elementsPointer)
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
    /// ## Sequence Conformance
    ///
    /// When `Element` is `Copyable`, `Stack.Bounded` conforms to `Sequence`:
    ///
    /// ```swift
    /// var stack = try Stack<Int>.Bounded(capacity: 10)
    /// try stack.push(1)
    /// try stack.push(2)
    /// for element in stack {
    ///     print(element)  // 1, then 2
    /// }
    /// ```
    ///
    /// ## Copy-on-Write
    ///
    /// When `Element` is `Copyable`, `Stack.Bounded` uses copy-on-write semantics:
    /// copies share storage until mutation, providing efficient value semantics.
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
        var _storage: Storage  // Uses unified nested storage class

        /// Cached pointer to element storage. Stored in struct to enable property-based Span access.
        /// CRITICAL: Must be updated whenever _storage is replaced (CoW copy).
        @usableFromInline
        var _cachedPtr: UnsafeMutablePointer<Element>

        /// The maximum number of elements the stack can hold.
        public let capacity: Int

        /// Creates a stack with the specified capacity.
        ///
        /// - Parameter capacity: Maximum number of elements. Must be non-negative.
        /// - Throws: ``Stack/Bounded/Error/invalidCapacity`` if capacity is negative.
        @inlinable
        public init(capacity: Int) throws(__StackBoundedError) {
            guard capacity >= 0 else {
                throw .invalidCapacity
            }

            self._storage = Storage.create(minimumCapacity: capacity)
            unsafe (self._cachedPtr = _storage._elementsPointer)
            self.capacity = capacity
        }

        // Note: No deinit needed - Storage handles cleanup
    }

    /// Creates an empty stack.
    ///
    /// No allocation occurs until the first push.
    @inlinable
    public init() {
        self._storage = Storage.create()
        unsafe (self._cachedPtr = _storage._elementsPointer)
    }

    /// Creates a stack initialized with elements from a sequence.
    ///
    /// - Parameter elements: The elements to push onto the stack.
    /// - Complexity: O(n) where n is the number of elements.
    @inlinable
    public init(_ elements: some Swift.Sequence<Element>) {
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
            self._storage = Storage.create()
        } else {
            self._storage = Storage.create(minimumCapacity: capacity)
        }
        unsafe (self._cachedPtr = _storage._elementsPointer)
    }

    // Note: No deinit needed - Storage handles cleanup
}

// MARK: - Conditional Copyable

/// `Stack` is `Copyable` when its elements are `Copyable`.
///
/// This enables value semantics with copy-on-write optimization:
/// copies share storage until mutation.
extension Stack: Copyable where Element: Copyable {}

/// `Stack.Bounded` is `Copyable` when its elements are `Copyable`.
///
/// This enables value semantics with copy-on-write optimization:
/// copies share storage until mutation.
extension Stack.Bounded: Copyable where Element: Copyable {}

// Note: Stack.Small is UNCONDITIONALLY ~Copyable due to the deinit requirement
// for inline storage cleanup. If you need Copyable semantics, use Stack (which
// always heap-allocates and can be conditionally Copyable).

/// `Stack.Bounded` conforms to `Sequence` when `Element` is `Copyable`.
///
/// This enables `for-in` loops, `map`, `filter`, and other sequence operations.
/// For `~Copyable` elements, use ``forEach(_:)`` instead.
///
/// - Note: This conformance must be in the same file as the type declaration
///   due to a Swift compiler bug where protocol conformances for nested types
///   in separate files cause `~Copyable` constraint propagation to fail.
extension Stack.Bounded: Swift.Sequence where Element: Copyable {

    /// An iterator over the elements of a bounded stack.
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
            guard _index.position.rawValue < _storage.header else { return nil }
            let currentIndex = _index.position.rawValue
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

// MARK: - Sendable

/// `Stack` is `Sendable` when its elements are `Sendable`.
///
/// This conformance allows the stack to be transferred between tasks.
/// However, concurrent mutation requires external synchronization—
/// the stack itself provides no thread-safety guarantees.
extension Stack: @unchecked Sendable where Element: Sendable {}
