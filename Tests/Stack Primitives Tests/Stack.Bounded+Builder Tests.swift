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

import Stack_Primitives_Test_Support
import Testing

@testable import Stack_Primitives

private struct BoundedMove: ~Copyable {
    let v: Int
    init(_ v: Int) { self.v = v }
}

@Suite("Stack.Bounded+Builder")
struct StackBoundedBuilderTests {
    @Suite struct Within {}
    @Suite struct Overflow {}
    @Suite struct NC {}
}

extension StackBoundedBuilderTests.Within {
    @Test
    func `within capacity`() throws {
        var s = try Stack<Int>.Bounded(capacity: 8) { 1; 2; 3 }
        #expect(s.pop() == 3)
    }

    @Test
    func `builder-built Copyable bounded stack supports CoW copies`() throws {
        // Regression: the Copyable builder-init twin constructs through the
        // clone-capturing path — a copy of a builder-built bounded stack must
        // detach on mutation, not trap on a clone-less shared box.
        let original = try Stack<Int>.Bounded(capacity: 4) { 1; 2 }
        var copy = original
        try copy.push(3)
        #expect(copy.pop() == 3)
        let originalTop = original.peek()
        #expect(originalTop == 2)  // original untouched
    }
}

extension StackBoundedBuilderTests.Overflow {
    @Test
    func `throws on overflow`() {
        do {
            _ = try Stack<Int>.Bounded(capacity: 2) { 1; 2; 3 }
            Issue.record("expected throw")
        } catch let e {
            #expect(e == .overflow)
        }
    }
}

extension StackBoundedBuilderTests.NC {
    @Test
    func `noncopyable element within capacity`() throws {
        let s = try Stack<BoundedMove>.Bounded(capacity: 4) { BoundedMove(1); BoundedMove(2) }
        let isEmpty = s.isEmpty
        #expect(!isEmpty)
    }
}
