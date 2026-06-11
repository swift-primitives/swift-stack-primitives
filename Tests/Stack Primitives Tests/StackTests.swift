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

import Index_Primitives_Test_Support
import Testing

@testable import Stack_Primitives

// MARK: - Stack.Bounded Tests

@Suite("Stack.Bounded")
struct StackBoundedTests {
    @Test
    func `Initialize with valid capacity`() {
        let stack = Stack<Int>.Bounded(capacity: 10)
        #expect(stack.capacity == 10)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == false)
    }

    @Test
    func `Initialize with zero capacity`() {
        let stack = Stack<Int>.Bounded(capacity: 0)
        #expect(stack.capacity == 0)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == true)  // zero capacity is always full
    }

    @Test
    func `Push and pop single element`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(42)
        #expect(stack.count == 1)
        #expect(stack.isEmpty == false)

        let popped = stack.pop()
        #expect(popped == 42)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Push and pop multiple elements (LIFO order)`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Pop from empty stack returns nil`() {
        var stack = Stack<Int>.Bounded(capacity: 5)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Push to full stack throws overflow`() throws {
        var stack = Stack<Int>.Bounded(capacity: 2)
        try stack.push(1)
        try stack.push(2)
        #expect(stack.isFull == true)

        #expect(throws: __StackBoundedError<Int>.overflow) {
            try stack.push(3)
        }
    }

    @Test
    func `Peek returns top element without removing`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)

        let peeked = stack.peek { $0 }
        #expect(peeked == 2)
        #expect(stack.count == 2)  // Still has 2 elements

        let popped = stack.pop()
        #expect(popped == 2)
    }

    @Test
    func `Peek on empty stack returns nil`() {
        let stack = Stack<Int>.Bounded(capacity: 5)
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test
    func `Scoped span provides read-only access`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        // The returning `span` property is withdrawn at the A-1 reshape (the
        // stored Shared column has no returning span); the scoped form replaces it.
        stack.withSpan { span in
            #expect(span.count == 3)
            #expect(span[0] == 1)  // Bottom
            #expect(span[1] == 2)
            #expect(span[2] == 3)  // Top
        }
    }

    @Test
    func `Clear removes all elements`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        #expect(stack.count == 3)

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == 5)  // Capacity unchanged
    }

    @Test
    func `Peek sugar returns top element for Copyable`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2)  // Still has 2 elements
    }

    @Test
    func `Copies share storage until mutation, and the CoW detach preserves capacity`() throws {
        var a = Stack<Int>.Bounded(capacity: 4)
        try a.push(1)
        try a.push(2)

        // Copy shares the box; the first mutation of `b` detaches through the
        // CAPACITY-PRESERVING clone (a shrink-to-fit copy would make the
        // in-contract pushes below overflow).
        var b = a
        try b.push(3)
        #expect(a.count == 2)  // a untouched by b's mutation
        #expect(b.count == 3)
        #expect(b.capacity == 4)

        try b.push(4)  // still in-contract after the detach
        #expect(b.isFull == true)
        #expect(a.peek() == 2)
        #expect(b.peek() == 4)
    }
}

// MARK: - Stack Tests (Unbounded)

@Suite("Stack (Unbounded)")
struct StackTests {
    @Test
    func `Initialize empty stack`() {
        let stack = Stack<Int>()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        // Note: ManagedBuffer may allocate minimal capacity even for empty stack
        #expect(stack.capacity >= 0)
    }

    @Test
    func `Initialize with reserved capacity`() {
        let stack = Stack<Int>(reservingCapacity: 10)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        // ManagedBuffer may allocate slightly more than requested
        #expect(stack.capacity >= 10)
    }

    @Test
    func `Push and pop single element`() {
        var stack = Stack<Int>()
        stack.push(42)
        #expect(stack.count == 1)
        #expect(stack.isEmpty == false)

        let popped = stack.pop()
        #expect(popped == 42)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Push and pop multiple elements (LIFO order)`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Pop from empty stack returns nil`() {
        var stack = Stack<Int>()
        #expect(stack.pop() == nil)
    }

    @Test
    func `Growth behavior - capacity grows as needed`() {
        var stack = Stack<Int>()

        // Push elements and verify capacity grows as needed
        stack.push(1)
        #expect(stack.capacity >= 1)
        let capacityAfterFirst = Int(clamping: stack.capacity)

        // Fill to capacity (if capacity > 1)
        if capacityAfterFirst > 1 {
            for i in 2...capacityAfterFirst {
                stack.push(i)
            }
        }
        #expect(Int(clamping: stack.count) == capacityAfterFirst)
        #expect(stack.capacity >= stack.count)
        let capacityWhenFull = stack.capacity

        // Push beyond capacity - should grow
        stack.push(Int(clamping: capacityWhenFull) + 1)
        #expect(stack.capacity > capacityWhenFull)
        #expect(stack.capacity >= stack.count)
    }

    @Test
    func `Reserve capacity`() {
        var stack = Stack<Int>()
        stack.reserve(100)
        #expect(stack.capacity >= 100)
        #expect(stack.count == 0)

        // Elements are still preserved after reserve
        stack.push(1)
        stack.push(2)
        stack.reserve(200)
        #expect(stack.capacity >= 200)
        #expect(stack.count == 2)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
    }

    @Test
    func `Peek returns top element without removing`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)

        let peeked = stack.peek { $0 }
        #expect(peeked == 2)
        #expect(stack.count == 2)

        let popped = stack.pop()
        #expect(popped == 2)
    }

    @Test
    func `Peek on empty stack returns nil`() {
        let stack = Stack<Int>()
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test
    func `Scoped span provides read-only access`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        // The returning `span` property is withdrawn at the A-1 reshape (the
        // stored Shared column has no returning span); the scoped form replaces it.
        stack.withSpan { span in
            #expect(span.count == 3)
            #expect(span[0] == 1)  // Bottom
            #expect(span[1] == 2)
            #expect(span[2] == 3)  // Top
        }
    }

    @Test
    func `Many pushes stress test growth`() {
        var stack = Stack<Int>()

        for i in 0..<1000 {
            stack.push(i)
        }

        #expect(stack.count == 1000)

        // Verify LIFO order
        for i in (0..<1000).reversed() {
            #expect(stack.pop() == i)
        }

        #expect(stack.isEmpty == true)
    }

    @Test
    func `Clear removes all elements keeping capacity`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        let capacityBefore = stack.capacity
        #expect(stack.count == 3)

        stack.clear(keepingCapacity: true)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == capacityBefore)
    }

    @Test
    func `Clear removes all elements and deallocates`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        let capacityBefore = stack.capacity
        #expect(capacityBefore > 0)

        stack.clear(keepingCapacity: false)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        // Note: ManagedBuffer may still have minimal capacity after clear
        // The important behavior is that a fresh storage is created
        #expect(stack.capacity <= capacityBefore)
    }

    @Test
    func `Peek sugar returns top element for Copyable`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2)  // Still has 2 elements
    }
}

// MARK: - Move-Only Element Tests

@Suite("Move-Only Elements")
struct MoveOnlyElementTests {
    struct MoveOnlyValue: ~Copyable {
        let value: Int

        init(_ value: Int) {
            self.value = value
        }
    }

    @Test
    func `Bounded stack with move-only elements`() throws {
        var stack = Stack<MoveOnlyValue>.Bounded(capacity: 5)
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))

        if let popped = stack.pop() {
            #expect(popped.value == 2)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test
    func `Unbounded stack with move-only elements`() {
        var stack = Stack<MoveOnlyValue>()
        stack.push(MoveOnlyValue(1))
        stack.push(MoveOnlyValue(2))
        stack.push(MoveOnlyValue(3))

        if let popped = stack.pop() {
            #expect(popped.value == 3)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test
    func `Unbounded stack growth with move-only elements`() {
        var stack = Stack<MoveOnlyValue>()

        // Push enough to trigger growth
        for i in 0..<10 {
            stack.push(MoveOnlyValue(i))
        }

        #expect(stack.count == 10)

        // Verify values in LIFO order
        for i in (0..<10).reversed() {
            if let popped = stack.pop() {
                #expect(popped.value == i)
            } else {
                Issue.record("Expected non-nil value at index \(i)")
            }
        }
    }

    @Test
    func `Peek with move-only elements uses borrowing`() {
        var stack = Stack<MoveOnlyValue>()
        stack.push(MoveOnlyValue(42))

        // Peek borrows without moving
        let peekedValue = stack.peek { $0.value }
        #expect(peekedValue == 42)

        // Element is still there
        #expect(stack.count == 1)

        // Can still pop
        if let popped = stack.pop() {
            #expect(popped.value == 42)
        } else {
            Issue.record("Expected non-nil value")
        }
    }
}

// MARK: - drain(while:_:) Tests

@Suite("Stack drain(while:_:)")
struct StackDrainWhileTests {
    @Test
    func `Drains some elements in LIFO order`() {
        var stack = Stack<Int>()
        for e in [1, 2, 3, 4, 5] { stack.push(e) }
        // Stack top is 5, then 4, 3, 2, 1
        var drained: [Int] = []
        stack.drain(while: { $0 > 3 }) { drained.append($0) }
        #expect(drained == [5, 4])
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains zero elements`() {
        var stack = Stack<Int>()
        for e in [1, 2, 3] { stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 100 }) { drained.append($0) }
        #expect(drained.isEmpty)
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains all elements`() {
        var stack = Stack<Int>()
        for e in [1, 2, 3] { stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained == [3, 2, 1])
        #expect(stack.isEmpty)
    }

    @Test
    func `Drain on empty stack`() {
        var stack = Stack<Int>()
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained.isEmpty)
    }

    @Test
    func `Remaining elements intact after partial drain`() {
        var stack = Stack<Int>()
        for e in [1, 2, 3, 4, 5] { stack.push(e) }
        stack.drain(while: { $0 > 3 }) { _ in }
        // Remaining: 3, 2, 1 (top to bottom)
        #expect(stack.peek() == 3)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.isEmpty)
    }
}

@Suite("Stack.Bounded drain(while:_:)")
struct StackBoundedDrainWhileTests {
    @Test
    func `Drains some elements in LIFO order`() throws {
        var stack = Stack<Int>.Bounded(capacity: 10)
        for e in [1, 2, 3, 4, 5] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 3 }) { drained.append($0) }
        #expect(drained == [5, 4])
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains zero elements`() throws {
        var stack = Stack<Int>.Bounded(capacity: 10)
        for e in [1, 2, 3] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 100 }) { drained.append($0) }
        #expect(drained.isEmpty)
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains all elements`() throws {
        var stack = Stack<Int>.Bounded(capacity: 10)
        for e in [1, 2, 3] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained == [3, 2, 1])
        #expect(stack.isEmpty)
    }

    @Test
    func `Drain on empty stack`() {
        var stack = Stack<Int>.Bounded(capacity: 10)
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained.isEmpty)
    }

    @Test
    func `Remaining elements intact after partial drain`() throws {
        var stack = Stack<Int>.Bounded(capacity: 10)
        for e in [1, 2, 3, 4, 5] { try stack.push(e) }
        stack.drain(while: { $0 > 3 }) { _ in }
        #expect(stack.peek() == 3)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.isEmpty)
    }
}
