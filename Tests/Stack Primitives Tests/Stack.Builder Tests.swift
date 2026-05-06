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

// MARK: - Test Suite Structure

@Suite("Stack.Builder")
struct StackBuilderTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite struct NonCopyable {}
    @Suite struct StaticMethods {}
    @Suite struct PushOrderSemantics {}
}

// MARK: - Move-Only Test Fixture

private struct Move: ~Copyable {
    let value: Int
    init(_ value: Int) { self.value = value }
}

// MARK: - Iteration Helpers

extension StackBuilderTests {

    /// Drain stack via repeated pop (returns elements in LIFO order — top first)
    fileprivate static func collectedPopOrder(
        _ stack: consuming Stack<Int>
    ) -> [Int] {
        var rest = consume stack
        var result: [Int] = []
        while let elem = rest.pop() {
            result.append(elem)
        }
        return result
    }

    fileprivate static func collectedPopOrder(
        _ stack: consuming Stack<Move>
    ) -> [Int] {
        var rest = consume stack
        var result: [Int] = []
        while let elem = rest.pop() {
            result.append(elem.value)
        }
        return result
    }
}

// MARK: - Push Order Semantics (OQ3 verification)

extension StackBuilderTests.PushOrderSemantics {

    @Test
    func `Declaration order is push order - pop returns last declared first`() {
        var stack = Stack<Int> {
            1
            2
            3
        }
        // 1 pushed first (bottom), 3 pushed last (top)
        // pop returns top (last declared) first
        #expect(stack.pop() == 3)
        #expect(stack.pop() == 2)
        #expect(stack.pop() == 1)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Builder is equivalent to imperative push sequence`() {
        let viaBuilder = Stack<Int> {
            10
            20
            30
        }
        var viaImperative = Stack<Int>()
        viaImperative.push(10)
        viaImperative.push(20)
        viaImperative.push(30)
        #expect(
            StackBuilderTests.collectedPopOrder(viaBuilder)
                == StackBuilderTests.collectedPopOrder(viaImperative)
        )
    }

    @Test
    func `Single-element builder pushes one element`() {
        var stack = Stack<Int> { 42 }
        #expect(stack.pop() == 42)
        #expect(stack.pop() == nil)
    }

    @Test
    func `Peek shows last declared as top`() {
        let stack = Stack<Int> {
            1
            2
            3
        }
        let top = stack.peek { $0 }
        #expect(top == 3)
    }
}

// MARK: - Unit Tests

extension StackBuilderTests.Unit {

    @Test
    func `Single element expression`() {
        let stack = Stack<Int> { 42 }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [42])
    }

    @Test
    func `Multiple element expressions - pop order is reverse declaration`() {
        let stack = Stack<Int> {
            1
            2
            3
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 2, 1])
    }

    @Test
    func `Optional element - some`() {
        let value: Int? = 42
        let stack = Stack<Int> { value }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [42])
    }

    @Test
    func `Optional element - none`() {
        let value: Int? = nil
        let stack = Stack<Int> { value }
        let isEmpty = stack.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `Mixed elements and optionals`() {
        let some: Int? = 2
        let none: Int? = nil
        let stack = Stack<Int> {
            1
            some
            none
            3
        }
        // Push order: 1, 2, 3. Pop order: 3, 2, 1.
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 2, 1])
    }

    @Test
    func `Empty block`() {
        let stack = Stack<Int> {}
        let isEmpty = stack.isEmpty
        #expect(isEmpty)
    }
}

// MARK: - Control Flow

extension StackBuilderTests.Unit {

    @Test
    func `Conditional include`() {
        let include = true
        let stack = Stack<Int> {
            1
            if include {
                2
            }
            3
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 2, 1])
    }

    @Test
    func `Conditional exclude`() {
        let include = false
        let stack = Stack<Int> {
            1
            if include {
                2
            }
            3
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 1])
    }

    @Test
    func `If-else first branch`() {
        let condition = true
        let stack = Stack<Int> {
            if condition {
                1
            } else {
                2
            }
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [1])
    }

    @Test
    func `If-else second branch`() {
        let condition = false
        let stack = Stack<Int> {
            if condition {
                1
            } else {
                2
            }
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [2])
    }
}

// MARK: - Edge Cases

extension StackBuilderTests.EdgeCase {

    @Test
    func `Deeply nested conditionals`() {
        let a = true
        let b = false
        let c = true
        let stack = Stack<Int> {
            0
            if a {
                1
                if b {
                    2
                } else {
                    3
                    if c {
                        4
                    }
                }
            }
            99
        }
        // Push order: 0, 1, 3, 4, 99. Pop order: 99, 4, 3, 1, 0.
        #expect(StackBuilderTests.collectedPopOrder(stack) == [99, 4, 3, 1, 0])
    }

    @Test
    func `Many elements preserve push order`() {
        let stack = Stack<Int> {
            1
            2
            3
            4
            5
            6
            7
            8
            9
            10
        }
        let popped = StackBuilderTests.collectedPopOrder(stack)
        // Pop order is reverse of declaration
        #expect(popped == Swift.Array((1...10).reversed()))
    }
}

// MARK: - Integration

extension StackBuilderTests.Integration {

    @Test
    func `Builder result accepts further pushes`() {
        var stack = Stack<Int> {
            1
            2
        }
        stack.push(3)
        stack.push(4)
        // Push order: 1, 2, 3, 4. Pop: 4, 3, 2, 1.
        #expect(StackBuilderTests.collectedPopOrder(stack) == [4, 3, 2, 1])
    }

    @Test
    func `Builder result has expected element count`() {
        let stack = Stack<Int> {
            1
            2
            3
        }
        let popped = StackBuilderTests.collectedPopOrder(stack)
        #expect(popped.count == 3)
    }
}

// MARK: - NonCopyable

extension StackBuilderTests.NonCopyable {

    @Test
    func `Builder with single noncopyable element`() {
        let stack = Stack<Move> {
            Move(42)
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [42])
    }

    @Test
    func `Builder with multiple noncopyable elements - LIFO pop order`() {
        let stack = Stack<Move> {
            Move(1)
            Move(2)
            Move(3)
        }
        // Push order: 1, 2, 3. Pop order: 3, 2, 1.
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 2, 1])
    }

    @Test
    func `Builder with conditional noncopyable element - included`() {
        let include = true
        let stack = Stack<Move> {
            Move(1)
            if include {
                Move(2)
            }
            Move(3)
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 2, 1])
    }

    @Test
    func `Builder with conditional noncopyable element - excluded`() {
        let include = false
        let stack = Stack<Move> {
            Move(1)
            if include {
                Move(2)
            }
            Move(3)
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [3, 1])
    }

    @Test
    func `Builder with if-else noncopyable`() {
        let condition = true
        let stack = Stack<Move> {
            if condition {
                Move(10)
            } else {
                Move(20)
            }
        }
        #expect(StackBuilderTests.collectedPopOrder(stack) == [10])
    }

    @Test
    func `Empty noncopyable builder`() {
        let stack = Stack<Move> {}
        let isEmpty = stack.isEmpty
        #expect(isEmpty)
    }
}

// MARK: - Static Method Tests

extension StackBuilderTests.StaticMethods {

    @Test
    func `buildExpression single element`() {
        let result = Stack<Int>.Builder.buildExpression(42)
        #expect(StackBuilderTests.collectedPopOrder(result) == [42])
    }

    @Test
    func `buildExpression existing stack`() {
        let input: Stack<Int> = Stack<Int> { 1; 2; 3 }
        let result = Stack<Int>.Builder.buildExpression(input)
        // Pass-through preserves the original stack
        #expect(StackBuilderTests.collectedPopOrder(result) == [3, 2, 1])
    }

    @Test
    func `buildExpression optional - some`() {
        let value: Int? = 42
        let result = Stack<Int>.Builder.buildExpression(value)
        #expect(StackBuilderTests.collectedPopOrder(result) == [42])
    }

    @Test
    func `buildExpression optional - none`() {
        let value: Int? = nil
        let result = Stack<Int>.Builder.buildExpression(value)
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildPartialBlock first`() {
        let first: Stack<Int> = Stack<Int> { 1; 2; 3 }
        let result = Stack<Int>.Builder.buildPartialBlock(first: first)
        #expect(StackBuilderTests.collectedPopOrder(result) == [3, 2, 1])
    }

    @Test
    func `buildPartialBlock first void`() {
        let result = Stack<Int>.Builder.buildPartialBlock(first: ())
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildPartialBlock accumulated and next preserves push order`() {
        let acc: Stack<Int> = Stack<Int> { 1; 2 }       // pushed 1, then 2
        let next: Stack<Int> = Stack<Int> { 3; 4 }      // pushed 3, then 4
        let result = Stack<Int>.Builder.buildPartialBlock(
            accumulated: acc,
            next: next
        )
        // Total push order: 1, 2, 3, 4. Pop order: 4, 3, 2, 1.
        #expect(StackBuilderTests.collectedPopOrder(result) == [4, 3, 2, 1])
    }

    @Test
    func `buildBlock empty`() {
        let result = Stack<Int>.Builder.buildBlock()
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildOptional some`() {
        let component: Stack<Int>? = Stack<Int> { 1; 2 }
        let result = Stack<Int>.Builder.buildOptional(component)
        #expect(StackBuilderTests.collectedPopOrder(result) == [2, 1])
    }

    @Test
    func `buildOptional none`() {
        let component: Stack<Int>? = nil
        let result = Stack<Int>.Builder.buildOptional(component)
        let isEmpty = result.isEmpty
        #expect(isEmpty)
    }

    @Test
    func `buildEither first`() {
        let first: Stack<Int> = Stack<Int> { 1; 2 }
        let result = Stack<Int>.Builder.buildEither(first: first)
        #expect(StackBuilderTests.collectedPopOrder(result) == [2, 1])
    }

    @Test
    func `buildEither second`() {
        let second: Stack<Int> = Stack<Int> { 3; 4 }
        let result = Stack<Int>.Builder.buildEither(second: second)
        #expect(StackBuilderTests.collectedPopOrder(result) == [4, 3])
    }

    @Test
    func `buildLimitedAvailability passthrough`() {
        let component: Stack<Int> = Stack<Int> { 1; 2; 3 }
        let result = Stack<Int>.Builder.buildLimitedAvailability(component)
        #expect(StackBuilderTests.collectedPopOrder(result) == [3, 2, 1])
    }
}
