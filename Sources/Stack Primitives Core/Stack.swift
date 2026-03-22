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

public import Buffer_Linear_Primitives
internal import Buffer_Linear_Inline_Primitives
internal import Buffer_Linear_Small_Primitives

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
/// - ``Stack/Static``: Zero-allocation inline storage with compile-time capacity
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

    @usableFromInline
    package var _buffer: Buffer<Element>.Linear

    /// A fixed-capacity LIFO stack supporting move-only elements.
    ///
    /// `Stack.Bounded` allocates storage upfront and throws on overflow.
    /// Use this variant when capacity is known or in contexts requiring
    /// predictable memory behavior (embedded, real-time).
    ///
    /// ## Example
    ///
    /// ```swift
    /// var stack = Stack<Int>.Bounded(capacity: 10)
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
    /// For compile-time capacity with zero heap allocation, use ``Stack/Static``.
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
        package var _buffer: Buffer<Element>.Linear.Bounded

        /// The requested capacity (for overflow checking).
        public let requestedCapacity: Index.Count

        /// Creates a stack with the specified capacity.
        ///
        /// - Parameter capacity: Maximum number of elements.
        @inlinable
        public init(capacity: Index.Count) {
            self._buffer = Buffer<Element>.Linear.Bounded(
                minimumCapacity: capacity
            )
            self.requestedCapacity = capacity
        }
    }

    /// Creates an empty stack.
    ///
    /// No allocation occurs until the first push.
    @inlinable
    public init() {
        self._buffer = Buffer<Element>.Linear(minimumCapacity: .zero)
    }

    // Note: init(_ elementS: Swift.Sequence) is in Stack Dynamic Primitives
    // because it requires push() which is defined there.

    /// Creates a stack with reserved capacity.
    ///
    /// Pre-allocates storage for the specified number of elements.
    /// Useful when the approximate number of elements is known.
    ///
    /// - Parameter capacity: Number of elements to reserve space for.
    @inlinable
    public init(reservingCapacity capacity: Index.Count) {
        self._buffer = Buffer<Element>.Linear(minimumCapacity: capacity)
    }
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

// Note: Stack.Bounded: Swift.Sequence conformance is in Stack Bounded Primitives module
// to avoid constraint poisoning on the Core type.

// MARK: - Sendable

/// `Stack` is `Sendable` when its elements are `Sendable`.
///
/// This conformance allows the stack to be transferred between tasks.
/// However, concurrent mutation requires external synchronization—
/// the stack itself provides no thread-safety guarantees.
extension Stack: @unchecked Sendable where Element: Sendable {}
