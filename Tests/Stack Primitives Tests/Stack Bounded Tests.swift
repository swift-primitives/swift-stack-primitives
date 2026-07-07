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

import Index_Primitives
import Testing

@testable import Stack_Primitives

// MARK: - Stack<E>.Bounded (fixed-capacity — the capacity-twin front door)
//
// The observation/removal ops (count, isEmpty, top, pop) ride the SHARED seam surface
// (Stack.swift), so they work over the bounded column with no per-column code; only
// push/init pin per column. Push on the bounded column throws `Error.full` (the decreed
// `throws(Overflow)` op form, M10 per-family error).

@Suite("Stack.Bounded (fixed-capacity)")
struct StackBoundedTests {

    @Test("push up to capacity, then push throws Error.full (rejected element destroyed)")
    func overflowThrows() throws {
        var s = Stack<Int>.Bounded(capacity: Index<Int>.Count(3))
        try s.push(1)
        try s.push(2)
        try s.push(3)
        let count = s.count
        let t = s.top
        #expect(count == Index<Int>.Count(3))
        #expect(t == 3)

        // Overflow: the fourth push throws `.full` and leaves the stack unchanged.
        // The per-family error is nested on the carrier, so it is spelled through the
        // BOUNDED instantiation (`Stack<Int>.Bounded.Error`, matching the landed
        // `Queue<E>.Bounded.Error`) — the typed-throws error `s.push` raises.
        var caught: Stack<Int>.Bounded.Error?
        do {
            try s.push(4)
            Issue.record("expected Stack.Error.full on overflow")
        } catch {
            caught = error  // typed-throws: `error` is `Stack<Int>.Bounded.Error`
        }
        let countAfter = s.count
        let topAfter = s.top
        #expect(caught == .full)
        #expect(countAfter == Index<Int>.Count(3))
        #expect(topAfter == 3)
    }

    @Test("bounded pop yields LIFO order and drains to nil")
    func lifoDrain() throws {
        var s = Stack<Int>.Bounded(capacity: Index<Int>.Count(4))
        try s.push(10)
        try s.push(20)
        try s.push(30)
        var drained: [Int] = []
        while let next = s.pop() { drained.append(next) }
        let empty = s.isEmpty
        let overDrain = s.pop()
        #expect(drained == [30, 20, 10])
        #expect(empty)
        #expect(overDrain == nil)
    }
}
