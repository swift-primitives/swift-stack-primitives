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
