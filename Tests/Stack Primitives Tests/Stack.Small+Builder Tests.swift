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

private struct SmallMove: ~Copyable {
    let v: Int
    init(_ v: Int) { self.v = v }
}

@Suite("Stack.Small+Builder")
struct StackSmallBuilderTests {
    @Suite struct Within {}
    @Suite struct Spill {}
    @Suite struct NC {}
}

extension StackSmallBuilderTests.Within {
    @Test
    func `within inline capacity`() {
        var s = Stack<Int>.Small<8> { 10; 20 }
        #expect(s.pop() == 20)
        #expect(s.pop() == 10)
    }
}

extension StackSmallBuilderTests.Spill {
    @Test
    func `spills to heap on overflow`() {
        var s = Stack<Int>.Small<2> { 1; 2; 3; 4; 5 }
        #expect(s.pop() == 5)
        #expect(s.pop() == 4)
    }
}

extension StackSmallBuilderTests.NC {
    @Test
    func `noncopyable element spills`() {
        let s = Stack<SmallMove>.Small<2> { SmallMove(1); SmallMove(2); SmallMove(3) }
        let isEmpty = s.isEmpty
        #expect(!isEmpty)
    }
}
