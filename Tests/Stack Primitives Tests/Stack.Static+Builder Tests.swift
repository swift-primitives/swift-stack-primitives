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

private struct StaticMove: ~Copyable {
    let v: Int
    init(_ v: Int) { self.v = v }
}

@Suite("Stack.Static+Builder")
struct StackStaticBuilderTests {
    @Suite struct Within {}
    @Suite struct Overflow {}
    @Suite struct NC {}
}

extension StackStaticBuilderTests.Within {
    @Test
    func `within capacity`() throws {
        var s = try Stack<Int>.Static<8> { 1; 2; 3 }
        #expect(s.pop() == 3)
        #expect(s.pop() == 2)
        #expect(s.pop() == 1)
    }
}

extension StackStaticBuilderTests.Overflow {
    @Test
    func `throws on overflow`() {
        do {
            _ = try Stack<Int>.Static<2> { 1; 2; 3 }
            Issue.record("expected throw")
        } catch let e {
            #expect(e == .overflow)
        }
    }
}

extension StackStaticBuilderTests.NC {
    @Test
    func `noncopyable element within capacity`() throws {
        let s = try Stack<StaticMove>.Static<4> { StaticMove(1); StaticMove(2); StaticMove(3) }
        let isEmpty = s.isEmpty
        #expect(!isEmpty)
    }
}
