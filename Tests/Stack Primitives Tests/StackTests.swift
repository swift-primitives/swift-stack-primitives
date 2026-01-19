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

import Testing

@testable import Stack_Primitives

// MARK: - Stack.Bounded Tests

@Suite("Stack.Bounded")
struct StackBoundedTests {
    @Test("Initialize with valid capacity")
    func initializeWithValidCapacity() throws {
        let stack = try Stack<Int>.Bounded(capacity: 10)
        #expect(stack.capacity == 10)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == false)
    }

    @Test("Initialize with zero capacity")
    func initializeWithZeroCapacity() throws {
        let stack = try Stack<Int>.Bounded(capacity: 0)
        #expect(stack.capacity == 0)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == true) // zero capacity is always full
    }

    @Test("Initialize with negative capacity throws")
    func initializeWithNegativeCapacity() {
        #expect(throws: __StackBoundedError.invalidCapacity) {
            _ = try Stack<Int>.Bounded(capacity: -1)
        }
    }

    @Test("Push and pop single element")
    func pushAndPopSingleElement() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(42)
        #expect(stack.count == 1)
        #expect(stack.isEmpty == false)

        let popped = stack.pop()
        #expect(popped == 42)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test("Push and pop multiple elements (LIFO order)")
    func pushAndPopMultipleElements() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test("Pop from empty stack returns nil")
    func popFromEmptyStack() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        #expect(stack.pop() == nil)
    }

    @Test("Push to full stack throws overflow")
    func pushToFullStackThrows() throws {
        var stack = try Stack<Int>.Bounded(capacity: 2)
        try stack.push(1)
        try stack.push(2)
        #expect(stack.isFull == true)

        #expect(throws: __StackBoundedError.overflow) {
            try stack.push(3)
        }
    }

    @Test("Peek returns top element without removing")
    func peekReturnsTopWithoutRemoving() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)

        let peeked = stack.peek { $0 }
        #expect(peeked == 2)
        #expect(stack.count == 2) // Still has 2 elements

        let popped = stack.pop()
        #expect(popped == 2)
    }

    @Test("Peek on empty stack returns nil")
    func peekOnEmptyStackReturnsNil() throws {
        let stack = try Stack<Int>.Bounded(capacity: 5)
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test("Span provides read-only access")
    func spanProvidesReadOnlyAccess() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        let span = stack.span
        #expect(span.count == 3)
        #expect(span[0] == 1) // Bottom
        #expect(span[1] == 2)
        #expect(span[2] == 3) // Top
    }

    @Test("Clear removes all elements")
    func clearRemovesAllElements() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        #expect(stack.count == 3)

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == 5) // Capacity unchanged
    }

    @Test("Peek sugar returns top element for Copyable")
    func peekSugarReturnsCopyableElement() throws {
        var stack = try Stack<Int>.Bounded(capacity: 5)
        try stack.push(1)
        try stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2) // Still has 2 elements
    }
}

// MARK: - Stack Tests (Unbounded)

@Suite("Stack (Unbounded)")
struct StackTests {
    @Test("Initialize empty stack")
    func initializeEmptyStack() {
        let stack = Stack<Int>()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == 0)
    }

    @Test("Initialize with reserved capacity")
    func initializeWithReservedCapacity() throws {
        let stack = try Stack<Int>(reservingCapacity: 10)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == 10)
    }

    @Test("Initialize with negative reserved capacity throws")
    func initializeWithNegativeReservedCapacity() {
        #expect(throws: __StackError.invalidCapacity) {
            _ = try Stack<Int>(reservingCapacity: -1)
        }
    }

    @Test("Push and pop single element")
    func pushAndPopSingleElement() {
        var stack = Stack<Int>()
        stack.push(42)
        #expect(stack.count == 1)
        #expect(stack.isEmpty == false)

        let popped = stack.pop()
        #expect(popped == 42)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test("Push and pop multiple elements (LIFO order)")
    func pushAndPopMultipleElements() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test("Pop from empty stack returns nil")
    func popFromEmptyStack() {
        var stack = Stack<Int>()
        #expect(stack.pop() == nil)
    }

    @Test("Growth behavior - capacity doubles")
    func growthBehavior() {
        var stack = Stack<Int>()

        // First push should allocate minimum capacity of 4
        stack.push(1)
        #expect(stack.capacity == 4)

        // Fill to capacity
        stack.push(2)
        stack.push(3)
        stack.push(4)
        #expect(stack.capacity == 4)

        // Next push should double capacity to 8
        stack.push(5)
        #expect(stack.capacity == 8)
    }

    @Test("Reserve capacity")
    func reserveCapacity() {
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

    @Test("Peek returns top element without removing")
    func peekReturnsTopWithoutRemoving() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)

        let peeked = stack.peek { $0 }
        #expect(peeked == 2)
        #expect(stack.count == 2)

        let popped = stack.pop()
        #expect(popped == 2)
    }

    @Test("Peek on empty stack returns nil")
    func peekOnEmptyStackReturnsNil() {
        let stack = Stack<Int>()
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test("Span provides read-only access")
    func spanProvidesReadOnlyAccess() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)

        let span = stack.span
        #expect(span.count == 3)
        #expect(span[0] == 1) // Bottom
        #expect(span[1] == 2)
        #expect(span[2] == 3) // Top
    }

    @Test("Many pushes stress test growth")
    func manyPushesStressTest() {
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

    @Test("Clear removes all elements keeping capacity")
    func clearRemovesAllElementsKeepingCapacity() {
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

    @Test("Clear removes all elements and deallocates")
    func clearRemovesAllElementsAndDeallocates() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        #expect(stack.capacity > 0)

        stack.clear(keepingCapacity: false)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.capacity == 0)
    }

    @Test("Peek sugar returns top element for Copyable")
    func peekSugarReturnsCopyableElement() {
        var stack = Stack<Int>()
        stack.push(1)
        stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2) // Still has 2 elements
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

    @Test("Bounded stack with move-only elements")
    func boundedStackWithMoveOnlyElements() throws {
        var stack = try Stack<MoveOnlyValue>.Bounded(capacity: 5)
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))

        if let popped = stack.pop() {
            #expect(popped.value == 2)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test("Unbounded stack with move-only elements")
    func unboundedStackWithMoveOnlyElements() {
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

    @Test("Unbounded stack growth with move-only elements")
    func unboundedStackGrowthWithMoveOnlyElements() {
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

    @Test("Peek with move-only elements uses borrowing")
    func peekWithMoveOnlyElementsUsesBorrowing() {
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

// MARK: - Stack.Inline Tests

@Suite("Stack.Inline")
struct StackInlineTests {
    @Test("Initialize empty stack")
    func initializeEmptyStack() {
        let stack = Stack<Int>.Inline<4>()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
        #expect(stack.isFull == false)
        // Capacity is the compile-time generic parameter (4)
    }

    @Test("Push and pop single element")
    func pushAndPopSingleElement() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(42)
        #expect(stack.count == 1)
        #expect(stack.isEmpty == false)

        let popped = stack.pop()
        #expect(popped == 42)
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test("Push and pop multiple elements (LIFO order)")
    func pushAndPopMultipleElements() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test("Pop from empty stack returns nil")
    func popFromEmptyStack() {
        var stack = Stack<Int>.Inline<4>()
        #expect(stack.pop() == nil)
    }

    @Test("Push to full stack throws overflow")
    func pushToFullStackThrows() throws {
        var stack = Stack<Int>.Inline<2>()
        try stack.push(1)
        try stack.push(2)
        #expect(stack.isFull == true)

        #expect(throws: __StackInlineError.overflow) {
            try stack.push(3)
        }
    }

    @Test("Peek returns top element without removing")
    func peekReturnsTopWithoutRemoving() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)

        let peeked = stack.peek { $0 }
        #expect(peeked == 2)
        #expect(stack.count == 2) // Still has 2 elements

        let popped = stack.pop()
        #expect(popped == 2)
    }

    @Test("Peek on empty stack returns nil")
    func peekOnEmptyStackReturnsNil() {
        let stack = Stack<Int>.Inline<4>()
        let result = stack.peek { $0 }
        #expect(result == nil)
    }

    @Test("Peek sugar returns top element for Copyable")
    func peekSugarReturnsCopyableElement() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)

        let peeked: Int? = stack.peek()
        #expect(peeked == 2)
        #expect(stack.count == 2) // Still has 2 elements
    }

    @Test("Clear removes all elements")
    func clearRemovesAllElements() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        #expect(stack.count == 3)

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test("Fill to capacity")
    func fillToCapacity() throws {
        var stack = Stack<Int>.Inline<4>()
        #expect(stack.isFull == false)

        try stack.push(1)
        try stack.push(2)
        try stack.push(3)
        try stack.push(4)

        #expect(stack.count == 4)
        #expect(stack.isFull == true)
    }

    @Test("span provides read-only indexed access")
    func spanProvidesReadOnlyIndexedAccess() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        // Index 0 is bottom, index 2 is top
        let s = stack.span
        let bottom = s[0]
        let middle = s[1]
        let top = s[2]

        #expect(bottom == 1)
        #expect(middle == 2)
        #expect(top == 3)
    }

    @Test("mutableSpan provides mutable indexed access")
    func mutableSpanProvidesMutableIndexedAccess() throws {
        var stack = Stack<Int>.Inline<4>()
        try stack.push(1)
        try stack.push(2)
        try stack.push(3)

        stack.mutableSpan[0] = 10
        stack.mutableSpan[1] = 20
        stack.mutableSpan[2] = 30

        #expect(stack.pop() == 30)
        #expect(stack.pop() == 20)
        #expect(stack.pop() == 10)
    }
}

// MARK: - Stack.Inline Move-Only Tests

@Suite("Stack.Inline Move-Only")
struct StackInlineMoveOnlyTests {
    struct MoveOnlyValue: ~Copyable {
        let value: Int

        init(_ value: Int) {
            self.value = value
        }
    }

    @Test("Inline stack with move-only elements")
    func inlineStackWithMoveOnlyElements() throws {
        var stack = Stack<MoveOnlyValue>.Inline<4>()
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))

        if let popped = stack.pop() {
            #expect(popped.value == 2)
        } else {
            Issue.record("Expected non-nil value")
        }
    }

    @Test("Peek with move-only elements uses borrowing")
    func peekWithMoveOnlyElementsUsesBorrowing() throws {
        var stack = Stack<MoveOnlyValue>.Inline<4>()
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

    @Test("Clear with move-only elements")
    func clearWithMoveOnlyElements() throws {
        var stack = Stack<MoveOnlyValue>.Inline<4>()
        try stack.push(MoveOnlyValue(1))
        try stack.push(MoveOnlyValue(2))
        try stack.push(MoveOnlyValue(3))

        stack.clear()
        #expect(stack.count == 0)
        #expect(stack.isEmpty == true)
    }

    @Test("Fill and empty cycle with move-only elements")
    func fillAndEmptyCycleWithMoveOnlyElements() throws {
        var stack = Stack<MoveOnlyValue>.Inline<4>()

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

// MARK: - Stack.Inline Stress Tests (Horror Tests)

@Suite("Stack.Inline Stress")
struct StackInlineStressTests {
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

    @Test("Deinit properly cleans up all elements via clear")
    func deinitProperlyCleanupViaClear() throws {
        let tracker = DeinitTracker()

        // Create stack and populate it
        var stack = Stack<TrackedValue>.Inline<8>()
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

    @Test("Stack.Bounded deinit test for comparison")
    func boundedDeinitTest() throws {
        let tracker = DeinitTracker()

        do {
            var stack = try Stack<TrackedValue>.Bounded(capacity: 8)
            try stack.push(TrackedValue(1, tracker: tracker))
            try stack.push(TrackedValue(2, tracker: tracker))
            try stack.push(TrackedValue(3, tracker: tracker))
            #expect(stack.count == 3)
        }

        // Bounded deinit should clean up
        #expect(tracker.deinitCount == 3)
    }

    @Test("Clear properly deinitializes elements")
    func clearProperlyDeinitializes() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Inline<8>()

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

    @Test("Pop properly deinitializes moved element")
    func popProperlyMoves() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Inline<8>()

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

    @Test("Multiple fill-empty cycles stress test")
    func multipleFillEmptyCycles() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Inline<4>()

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

    @Test("Interleaved push-pop stress test")
    func interleavedPushPop() throws {
        let tracker = DeinitTracker()
        var stack = Stack<TrackedValue>.Inline<16>()

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

    @Test("Large element type stress test")
    func largeElementTypeStressTest() throws {
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

        var stack = Stack<LargeValue>.Inline<4>()
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

    @Test("Partial fill then clear")
    func partialFillThenClear() throws {
        let tracker = DeinitTracker()

        var stack = Stack<TrackedValue>.Inline<16>()
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

    @Test("mutableSpan modification stress test")
    func mutableSpanModificationStress() throws {
        var stack = Stack<Int>.Inline<16>()

        for i in 0..<16 {
            try stack.push(i)
        }

        // Modify all elements via mutableSpan
        for i in 0..<16 {
            stack.mutableSpan[i] = stack.mutableSpan[i] * 2
        }

        // Verify modifications in LIFO order
        for i in (0..<16).reversed() {
            #expect(stack.pop() == i * 2)
        }
    }

    @Test("Overflow protection stress test")
    func overflowProtectionStressTest() throws {
        var stack = Stack<Int>.Inline<4>()

        // Fill to capacity
        for i in 0..<4 {
            try stack.push(i)
        }

        // Try many overflow attempts
        for _ in 0..<100 {
            #expect(throws: __StackInlineError.overflow) {
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

    @Test("Empty stack operations stress test")
    func emptyStackOperationsStressTest() {
        var stack = Stack<Int>.Inline<4>()

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
