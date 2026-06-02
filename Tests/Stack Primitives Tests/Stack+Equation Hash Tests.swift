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

@testable import Stack_Primitives

// A move-only element conforming Equation.Protocol + Hash.Protocol, to exercise
// span-derived equality / hashing over ~Copyable elements (no copy out of the span).
struct Token: ~Copyable {
    let value: Int
    init(_ value: Int) { self.value = value }
}

extension Token: Equation.`Protocol` {
    static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        lhs.value == rhs.value
    }
}

extension Token: Hash.`Protocol` {
    borrowing func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

@Suite("Stack span-derived Equatable + Hashable")
struct StackEquationHashTests {

    @Test
    func `equal stacks compare equal with equal hashes`() {
        var a = Stack<Int>()
        a.push(1)
        a.push(2)
        a.push(3)

        var b = Stack<Int>()
        b.push(1)
        b.push(2)
        b.push(3)

        let abEqual = a == b
        #expect(abEqual)

        var hasherA = Hasher()
        a.hash(into: &hasherA)
        var hasherB = Hasher()
        b.hash(into: &hasherB)
        #expect(hasherA.finalize() == hasherB.finalize())
    }

    @Test
    func `unequal stacks differ`() {
        var a = Stack<Int>()
        a.push(1)
        a.push(2)
        a.push(3)

        var c = Stack<Int>()
        c.push(1)
        c.push(2)
        c.push(9)

        let acEqual = a == c
        #expect(!acEqual)
    }

    @Test
    func `Stack of move-only elements compares and hashes over the span`() {
        var a = Stack<Token>()
        a.push(Token(1))
        a.push(Token(2))

        var b = Stack<Token>()
        b.push(Token(1))
        b.push(Token(2))

        let abEqual = a == b
        #expect(abEqual)

        var hasherA = Hasher()
        a.hash(into: &hasherA)
        var hasherB = Hasher()
        b.hash(into: &hasherB)
        #expect(hasherA.finalize() == hasherB.finalize())

        var c = Stack<Token>()
        c.push(Token(1))
        c.push(Token(9))

        let acEqual = a == c
        #expect(!acEqual)
    }
}
