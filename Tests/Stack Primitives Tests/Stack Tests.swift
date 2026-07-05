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

import Testing
import Index_Primitives
@testable import Stack_Primitives

// MARK: - Fixtures

/// A move-only element with no ordering requirement — the LIFO discipline is
/// order-free, so `Stack` carries `~Copyable` elements through push/pop/top with
/// no `Comparison.Protocol` bound (unlike `Heap`).
private struct Token: ~Copyable {
    let id: Int
    init(_ id: Int) { self.id = id }
}

// MARK: - Stack (LIFO — the ADT-tower W2 shape)
//
// The canonical `Stack<E>` rides the DIRECT heap column, so it is MOVE-ONLY for
// every element (Copyable or not). Observations are bound to locals before
// `#expect` — the property-access `#expect` form would otherwise require the
// move-only value to copy.

@Suite("Stack (last-in-first-out)")
struct StackTests {

    @Test("empty stack reports isEmpty and count 0")
    func emptyState() {
        let s = Stack<Int>()
        let empty = s.isEmpty
        let count = s.count
        #expect(empty)
        #expect(count == Index<Int>.Count(0))
    }

    @Test("push then pop yields last-in-first-out order")
    func lifoOrdering() {
        var s = Stack<Int>()
        for value in [42, 3, 25, 7] { s.push(value) }
        let nonEmpty = !s.isEmpty
        let count = s.count
        let t = s.top
        #expect(nonEmpty)
        #expect(count == Index<Int>.Count(4))
        #expect(t == 7)

        var drained: [Int] = []
        while let next = s.pop() { drained.append(next) }
        let empty = s.isEmpty
        let overDrain = s.pop()          // pop on empty -> nil (the convention)
        #expect(drained == [7, 25, 3, 42])
        #expect(empty)
        #expect(overDrain == nil)
    }

    @Test("top tracks the most-recently-pushed element")
    func topTracking() {
        var s = Stack<Int>()
        s.push(9); let t0 = s.top; #expect(t0 == 9)
        s.push(4); let t1 = s.top; #expect(t1 == 4)
        s.push(8); let t2 = s.top; #expect(t2 == 8)
        let popped = s.pop()
        let t3 = s.top
        #expect(popped == 8)          // Int? == Int-literal (Optional promotion)
        #expect(t3 == 4)
    }

    @Test("single-element stack: push, top, pop")
    func singleElement() {
        var s = Stack<Int>()
        s.push(17)
        let count = s.count
        let t = s.top
        #expect(count == Index<Int>.Count(1))
        #expect(t == 17)
        let popped = s.pop()
        let empty = s.isEmpty
        #expect(popped == 17)
        #expect(empty)
        let overDrain = s.pop()
        #expect(overDrain == nil)
    }

    @Test("~Copyable elements flow through push/pop/top")
    func moveOnlyElements() {
        var s = Stack<Token>()
        s.push(Token(5))
        s.push(Token(1))
        s.push(Token(3))
        let peeked = s.top.id
        #expect(peeked == 3)
        // Consuming-unwrap the `~Copyable` Token? each pop (no borrow of Element?).
        var ids: [Int] = []
        while let token = s.pop() { ids.append(token.id) }
        let empty = s.isEmpty
        #expect(ids == [3, 1, 5])
        #expect(empty)
    }

    @Test("growth past the initial capacity preserves LIFO order")
    func growthPreservesOrder() {
        var s = Stack<Int>(minimumCapacity: Index<Int>.Count(2))
        for value in 1...64 { s.push(value) }
        let count = s.count
        #expect(count == Index<Int>.Count(64))
        var expected = 64
        while let next = s.pop() {
            #expect(next == expected)
            expected -= 1
        }
    }
}
