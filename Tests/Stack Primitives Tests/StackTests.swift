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
    func `Span provides read-only access`() throws {
        var stack = Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        let span = stack.span
        #expect(span.count == 3)
        #expect(span[0] == 1)  // Bottom
        #expect(span[1] == 2)
        #expect(span[2] == 3)  // Top
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
    func `Span provides read-only access`() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        let span = stack.span
        #expect(span.count == 3)
        #expect(span[0] == 1)  // Bottom
        #expect(span[1] == 2)
        #expect(span[2] == 3)  // Top
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

// MARK: - Stack.Static Tests

@Suite("Stack.Static")
struct StackStaticTests {
    @Test
    func `Initialize empty stack`() {
        let stack = Stack<Int>.Static<4>()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == false)
    }

    @Test
    func `Push and pop single element`() throws {
        var stack = Stack<Int>.Static<4>()
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
        var stack = Stack<Int>.Static<4>()
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
        var stack = Stack<Int>.Static<4>()
        #expect(stack.pop() == nil)
    }

    @Test
    func `Push to full stack throws overflow`() throws {
        var stack = Stack<Int>.Static<2>()
        try stack.push(1)
        try stack.push(2)
        #expect(stack.isFull == true)

        #expect(throws: __StackStaticError<Int>.overflow) {
            try stack.push(3)
        }
    }

    @Test
    func `Peek returns top element without removing`() throws {
        var stack = Stack<Int>.Static<4>()
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
        let stack = Stack<Int>.Static<4>()
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test
    func `Peek sugar returns top element for Copyable`() throws {
        var stack = Stack<Int>.Static<4>()
        try stack.push(1)
        try stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2)  // Still has 2 elements
    }

    @Test
    func `Clear removes all elements`() throws {
        var stack = Stack<Int>.Static<4>()
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        #expect(stack.count == 3)

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Fill to capacity`() throws {
        var stack = Stack<Int>.Static<4>()
        #expect(stack.isFull == false)

        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        try stack.push(4)

        #expect(stack.count == 4)
        #expect(stack.isFull == true)
    }

}

// MARK: - Stack.Static Move-Only Tests

@Suite("Stack.Static Move-Only")
struct StackStaticMoveOnlyTests {
    struct MoveOnlyValue: ~Copyable {
        let value: Int

        init(_ value: Int) {
            self.value = value
        }
    }

    @Test
    func `Static stack with move-only elements`() throws {
        var stack = Stack<MoveOnlyValue>.Static<4>()
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))

        if let popped = stack.pop() {
            #expect(popped.value == 2)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test
    func `Peek with move-only elements uses borrowing`() throws {
        var stack = Stack<MoveOnlyValue>.Static<4>()
        try stack.push(MoveOnlyValue(42))

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

    @Test
    func `Clear with move-only elements`() throws {
        var stack = Stack<MoveOnlyValue>.Static<4>()
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))
        try stack.push(MoveOnlyValue(3))

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Fill and empty cycle with move-only elements`() throws {
        var stack = Stack<MoveOnlyValue>.Static<4>()

        // Fill
        for i in 0..<4 {
            try stack.push(MoveOnlyValue(i))
        }
        #expect(stack.isFull == true)

        // Empty
        for i in (0..<4).reversed() {
            if let popped = stack.pop() {
                #expect(popped.value == i)
            } else {
                Issue.record("Expected non-nil value at index \(i)")
            }
        }
        #expect(stack.isEmpty == true)
    }
}

// MARK: - Stack.Static Stress Tests (Horror Tests)

@Suite("Stack.Static Stress")
struct StackStaticStressTests {
    // Track deinit calls to verify proper cleanup
    final class DeinitTracker: @unchecked Sendable {
        var deinitCount: Int = 0
    }

    struct TrackedValue: ~Copyable {
        let value: Int
        let tracker: DeinitTracker

        init(_ value: Int, tracker: DeinitTracker) {
            self.value = value
            self.tracker = tracker
        }

        deinit {
            tracker.deinitCount += 1
        }
    }

    @Test
    func `Deinit properly cleans up all elements via clear`() throws {
        let tracker = DeinitTracker()

        // Create stack and populate it
        var stack = Stack<TrackedValue>.Static<8>()
        try stack.push(TrackedValue(1, tracker: tracker))
        try stack.push(TrackedValue(2, tracker: tracker))
        try stack.push(TrackedValue(3, tracker: tracker))
        #expect(stack.count == 3)
        #expect(tracker.deinitCount == 0)

        // Clear should deinitialize elements
        stack.clear()

        // All 3 elements should be deinitialized
        #expect(tracker.deinitCount == 3)
    }

    @Test
    func `Stack.Bounded deinit test for comparison`() throws {
        let tracker = DeinitTracker()

        do {
            var stack = Stack<TrackedValue>.Bounded(capacity: 8)
            try stack.push(TrackedValue(1, tracker: tracker))
            try stack.push(TrackedValue(2, tracker: tracker))
            try stack.push(TrackedValue(3, tracker: tracker))
            #expect(stack.count == 3)
        }

        // Bounded deinit should clean up
        #expect(tracker.deinitCount == 3)
    }

    @Test
    func `Clear properly deinitializes elements`() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Static<8>()

        try stack.push(TrackedValue(1, tracker: tracker))
        try stack.push(TrackedValue(2, tracker: tracker))
        try stack.push(TrackedValue(3, tracker: tracker))
        #expect(tracker.deinitCount == 0)

        stack.clear()
        #expect(tracker.deinitCount == 3)

        // Stack should be reusable after clear
        try stack.push(TrackedValue(4, tracker: tracker))
        #expect(stack.count == 1)
    }

    @Test
    func `Pop properly deinitializes moved element`() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Static<8>()

        try stack.push(TrackedValue(1, tracker: tracker))
        #expect(tracker.deinitCount == 0)

        if let popped = stack.pop() {
            // Element is moved out, not yet deinitialized
            #expect(tracker.deinitCount == 0)
            // Force deinit by discarding
            _ = consume popped
        } else {
            Issue.record("Expected non-nil value")
        }
        #expect(tracker.deinitCount == 1)
    }

    @Test
    func `Multiple fill-empty cycles stress test`() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Static<4>()

        for cycle in 0..<100 {
            // Fill
            for i in 0..<4 {
                try stack.push(TrackedValue(cycle * 4 + i, tracker: tracker))
            }
            #expect(stack.isFull == true)

            // Empty
            while stack.pop() != nil {}
            #expect(stack.isEmpty == true)
        }

        // All 400 elements should be deinitialized
        #expect(tracker.deinitCount == 400)
    }

    @Test
    func `Interleaved push-pop stress test`() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Static<16>()

        var totalPushed = 0
        var totalPopped = 0

        for i in 0..<1000 {
            if stack.isFull || (i % 3 != 0 && !stack.isEmpty) {
                _ = stack.pop()
                totalPopped += 1
            } else {
                try stack.push(TrackedValue(i, tracker: tracker))
                totalPushed += 1
            }
        }

        // Drain remaining
        while stack.pop() != nil {
            totalPopped += 1
        }

        #expect(totalPushed == totalPopped)
        #expect(tracker.deinitCount == totalPushed)
    }

    @Test
    func `Large element type stress test`() throws {
        // 56 bytes - should fit in 64-byte slot
        struct LargeValue: ~Copyable {
            var a: Int64 = 1
            var b: Int64 = 2
            var c: Int64 = 3
            var d: Int64 = 4
            var e: Int64 = 5
            var f: Int64 = 6
            var g: Int64 = 7
        }

        var stack = Stack<LargeValue>.Static<4>()
        try stack.push(LargeValue())
        try stack.push(LargeValue())
        try stack.push(LargeValue())
        try stack.push(LargeValue())

        #expect(stack.isFull == true)

        while let popped = stack.pop() {
            #expect(popped.a == 1)
            #expect(popped.g == 7)
        }
    }

    @Test
    func `Partial fill then clear`() throws {
        let tracker = DeinitTracker()

        var stack = Stack<TrackedValue>.Static<16>()
        // Only fill partially
        for i in 0..<5 {
            try stack.push(TrackedValue(i, tracker: tracker))
        }
        #expect(tracker.deinitCount == 0)

        // Clear properly deinitializes only the initialized elements
        stack.clear()

        // Only the 5 initialized elements should be deinitialized
        #expect(tracker.deinitCount == 5)
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Overflow protection stress test`() throws {
        var stack = Stack<Int>.Static<4>()

        // Fill to capacity
        for i in 0..<4 {
            try stack.push(i)
        }

        // Try many overflow attempts
        for _ in 0..<100 {
            #expect(throws: __StackStaticError<Int>.overflow) {
                try stack.push(999)
            }
        }

        // Stack should still be intact
        #expect(stack.count == 4)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == 0)
    }

    @Test
    func `Empty stack operations stress test`() {
        var stack = Stack<Int>.Static<4>()

        // Many pops on empty stack
        for _ in 0..<100 {
            #expect(stack.pop() == nil)
        }

        // Many peeks on empty stack
        for _ in 0..<100 {
            #expect(stack.peek() == nil)
            #expect(stack.peek { $0 } == nil)
        }

        // Stack should still be usable
        #expect(stack.isEmpty == true)
        #expect(stack.count == 0)
    }
}

// MARK: - Stack.Small Tests

@Suite("Stack.Small")
struct StackSmallTests {
    @Test
    func `Initialize empty stack`() {
        let stack = Stack<Int>.Small<4>()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isSpilled == false)
    }

    @Test
    func `Push and pop within inline capacity`() {
        var stack = Stack<Int>.Small<4>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        #expect(stack.count == 3)
        #expect(stack.isSpilled == false)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Spill to heap when exceeding inline capacity`() {
        var stack = Stack<Int>.Small<4>()

        // Fill inline capacity
        for i in 0..<4 {
            stack.push(i)
        }
        #expect(stack.isSpilled == false)
        #expect(stack.count == 4)

        // This push should trigger spill
        stack.push(4)
        #expect(stack.isSpilled == true)
        #expect(stack.count == 5)

        // Continue pushing
        stack.push(5)
        stack.push(6)
        #expect(stack.count == 7)

        // Pop all in LIFO order
        #expect(stack.pop() == 6)
        #expect(stack.pop() == 5)
        #expect(stack.pop() == 4)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == 0)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Peek from inline storage`() {
        var stack = Stack<Int>.Small<4>()
        stack.push(42)

        #expect(stack.peek() == 42)
        #expect(stack.count == 1)
        #expect(stack.isSpilled == false)
    }

    @Test
    func `Peek from heap storage`() {
        var stack = Stack<Int>.Small<2>()
        stack.push(1)
        stack.push(2)
        stack.push(3)  // Triggers spill

        #expect(stack.isSpilled == true)
        #expect(stack.peek() == 3)
        #expect(stack.count == 3)
    }

    @Test
    func `Clear inline storage`() {
        var stack = Stack<Int>.Small<4>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isSpilled == false)
    }

    @Test
    func `Clear heap storage`() {
        var stack = Stack<Int>.Small<2>()
        stack.push(1)
        stack.push(2)
        stack.push(3)  // Triggers spill

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        // Buffer.Linear.Small.removeAll() resets to inline mode
        #expect(stack.isSpilled == false)
    }

    @Test
    func `Truncate within inline storage`() {
        var stack = Stack<Int>.Small<4>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        stack.push(4)

        stack.truncate(to: 2)
        #expect(stack.count == 2)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
    }

    @Test
    func `Truncate within heap storage`() {
        var stack = Stack<Int>.Small<2>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        stack.push(4)
        stack.push(5)

        stack.truncate(to: 2)
        #expect(stack.count == 2)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
    }

    @Test
    func `ForEach iteration`() {
        var stack = Stack<Int>.Small<4>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        var sum = 0
        stack.forEach { sum += $0 }
        #expect(sum == 6)
    }

    @Test
    func `Capacity property reflects current state`() {
        var stack = Stack<Int>.Small<4>()
        #expect(stack.capacity == 4)  // Inline capacity

        stack.push(1)
        stack.push(2)
        stack.push(3)
        stack.push(4)
        stack.push(5)  // Spill

        #expect(stack.capacity >= 5)  // Heap capacity (at least 5)
    }
}

// MARK: - Stack.Small with Move-Only Elements

@Suite("Stack.Small Move-Only")
struct StackSmallMoveOnlyTests {
    struct MoveOnlyValue: ~Copyable {
        let value: Int
        init(_ value: Int) { self.value = value }
    }

    @Test
    func `Push and pop move-only elements within inline capacity`() {
        var stack = Stack<MoveOnlyValue>.Small<4>()
        stack.push(MoveOnlyValue(1))
        stack.push(MoveOnlyValue(2))

        if let popped = stack.pop() {
            #expect(popped.value == 2)
        } else {
            Issue.record("Expected non-nil value")
        }

        if let popped = stack.pop() {
            #expect(popped.value == 1)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test
    func `Spill move-only elements to heap`() {
        var stack = Stack<MoveOnlyValue>.Small<2>()
        stack.push(MoveOnlyValue(1))
        stack.push(MoveOnlyValue(2))
        stack.push(MoveOnlyValue(3))  // Triggers spill

        #expect(stack.isSpilled == true)

        if let popped = stack.pop() {
            #expect(popped.value == 3)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test
    func `Peek with move-only elements uses borrowing`() {
        var stack = Stack<MoveOnlyValue>.Small<4>()
        stack.push(MoveOnlyValue(42))

        let peekedValue = stack.peek { $0.value }
        #expect(peekedValue == 42)
        #expect(stack.count == 1)
    }

    @Test
    func `Clear move-only elements`() {
        var stack = Stack<MoveOnlyValue>.Small<4>()
        stack.push(MoveOnlyValue(1))
        stack.push(MoveOnlyValue(2))
        stack.push(MoveOnlyValue(3))

        stack.clear()
        #expect(stack.count == 0)
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

@Suite("Stack.Static drain(while:_:)")
struct StackStaticDrainWhileTests {
    @Test
    func `Drains some elements in LIFO order`() throws {
        var stack = Stack<Int>.Static<8>()
        for e in [1, 2, 3, 4, 5] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 3 }) { drained.append($0) }
        #expect(drained == [5, 4])
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains zero elements`() throws {
        var stack = Stack<Int>.Static<8>()
        for e in [1, 2, 3] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 100 }) { drained.append($0) }
        #expect(drained.isEmpty)
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains all elements`() throws {
        var stack = Stack<Int>.Static<8>()
        for e in [1, 2, 3] { try stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained == [3, 2, 1])
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Drain on empty stack`() {
        var stack = Stack<Int>.Static<8>()
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained.isEmpty)
    }

    @Test
    func `Remaining elements intact after partial drain`() throws {
        var stack = Stack<Int>.Static<8>()
        for e in [1, 2, 3, 4, 5] { try stack.push(e) }
        stack.drain(while: { $0 > 3 }) { _ in }
        #expect(stack.peek() == 3)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.isEmpty == true)
    }
}

@Suite("Stack.Small drain(while:_:)")
struct StackSmallDrainWhileTests {
    @Test
    func `Drains some elements in LIFO order (inline)`() {
        var stack = Stack<Int>.Small<8>()
        for e in [1, 2, 3, 4, 5] { stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 3 }) { drained.append($0) }
        #expect(drained == [5, 4])
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains some elements in LIFO order (spilled)`() {
        var stack = Stack<Int>.Small<2>()
        for e in [1, 2, 3, 4, 5] { stack.push(e) }
        #expect(stack.isSpilled == true)
        var drained: [Int] = []
        stack.drain(while: { $0 > 3 }) { drained.append($0) }
        #expect(drained == [5, 4])
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains zero elements`() {
        var stack = Stack<Int>.Small<8>()
        for e in [1, 2, 3] { stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { $0 > 100 }) { drained.append($0) }
        #expect(drained.isEmpty)
        #expect(Int(bitPattern: stack.count) == 3)
    }

    @Test
    func `Drains all elements`() {
        var stack = Stack<Int>.Small<8>()
        for e in [1, 2, 3] { stack.push(e) }
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained == [3, 2, 1])
        #expect(stack.isEmpty == true)
    }

    @Test
    func `Drain on empty stack`() {
        var stack = Stack<Int>.Small<8>()
        var drained: [Int] = []
        stack.drain(while: { _ in true }) { drained.append($0) }
        #expect(drained.isEmpty)
    }

    @Test
    func `Remaining elements intact after partial drain`() {
        var stack = Stack<Int>.Small<8>()
        for e in [1, 2, 3, 4, 5] { stack.push(e) }
        stack.drain(while: { $0 > 3 }) { _ in }
        #expect(stack.peek() == 3)
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.isEmpty == true)
    }
}
