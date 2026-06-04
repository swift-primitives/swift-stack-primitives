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
public import Buffer_Linear_Primitives
import Storage_Heap_Primitives
public import Index_Primitives

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
/// ## Iteration
///
/// `Stack` conforms to `Iterable` (multipass, borrowing) and — when `Element` is
/// `Copyable` — `Sequenceable` (single-pass, consuming). Both are vended in the
/// `Stack Primitives` ops module:
///
/// ```swift
/// var stack = Stack<Int>()
/// stack.push(1)
/// stack.push(2)
/// stack.forEach { print($0) }  // 1, then 2 — inherited from the Iterable floor
/// ```
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
// WHY: Category D — structural Sendable workaround; the type is
// WHY: structurally value-safe but the compiler cannot synthesize
// WHY: Sendable due to a stored pointer / generic parameter shape.
@safe
public struct Stack<Element: ~Copyable>: ~Copyable {

    /// Element storage using Buffer.Linear from buffer-primitives.
    ///
    /// `@usableFromInline package` ([MOD-036] refined-C): the hot
    /// `~Copyable`/`Copyable` operation surface co-located in this (type)
    /// module inlines cross-package to zero-witness-dispatch; the cold
    /// sequence/collection-family conformances in the ops module reach this
    /// storage only through the public `span` / `makeIterator` witnesses.
    @usableFromInline
    package var _buffer: Buffer<Storage<Element>.Heap>.Linear

    /// Creates an empty stack.
    ///
    /// No allocation occurs until the first push.
    @inlinable
    public init() {
        self._buffer = Buffer<Storage<Element>.Heap>.Linear(minimumCapacity: .zero)
    }

    // Note: init(_ elements: Swift.Sequence) is in Stack Primitives (ops)
    // because it requires push() which is defined there.

    /// Creates a stack with reserved capacity.
    ///
    /// Pre-allocates storage for the specified number of elements.
    /// Useful when the approximate number of elements is known.
    ///
    /// - Parameter capacity: Number of elements to reserve space for.
    @inlinable
    public init(reservingCapacity capacity: Index.Count) {
        self._buffer = Buffer<Storage<Element>.Heap>.Linear(minimumCapacity: capacity)
    }
}

// MARK: - Conditional Copyable

/// `Stack` is `Copyable` when its elements are `Copyable`.
///
/// This enables value semantics with copy-on-write optimization:
/// copies share storage until mutation.
extension Stack: Copyable where Element: Copyable {}

// MARK: - Sendable

/// `Stack` is `Sendable` when its elements are `Sendable`.
///
/// ## Safety Invariant
///
/// `Stack` is `~Copyable` (move-only), so at most one owner exists at any point.
/// Sending across threads is sound because the compiler enforces that the
/// sender loses access after the move — there is no aliasing to race on.
/// The internal `Buffer<Storage<Element>.Heap>.Linear` is owned exclusively by the stack
/// and moves with it.
///
/// ## Intended Use
///
/// - Transferring a prepared stack to a worker thread.
/// - Handing off a stack of `~Copyable` resources across actors.
/// - Actor-owned stacks constructed outside the actor and passed in at init.
///
/// ## Non-Goals
///
/// - Does not support concurrent access from multiple threads.
/// - Ownership is single-owner; transfer is one-shot via `consuming` parameter.
/// - This conformance does not make arbitrary sharing safe — `~Copyable`
///   prevents aliasing at compile time.
extension Stack: @unsafe @unchecked Sendable where Element: Sendable {}
