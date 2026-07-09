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

// MARK: - Differential test vs a plain-array oracle (template law: adt-tower.md:1247)
//
// The randomized floor every reshaped family ships: a long, mixed, duplicate-laden,
// interleaved push/pop workload with growth across reallocations, checked at every
// pop step against a trivially-correct `[Int]` LIFO oracle (append / removeLast).
// Deterministic (seeded), so a failure reproduces exactly.

/// SplitMix64 — a tiny deterministic `RandomNumberGenerator` (no `SystemRNG`).
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
}

extension SplitMix64 {
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("Stack differential (vs array oracle)")
struct StackDifferentialTests {

    @Test
    func `600 mixed ops: duplicates, interleaved push/pop, growth across reallocations`() {
        var rng = SplitMix64(seed: 0x5EED_1234_ABCD_0001)
        var stack = Stack<Int>()  // default capacity -> repeated growth under the push bias
        var oracle: [Int] = []  // trivially-correct LIFO multiset (append / removeLast)

        let totalOps = 600
        var pushes = 0
        var interleavedPops = 0

        for _ in 0..<totalOps {
            // Push-biased so the stack grows through several reallocations; small value
            // range guarantees many duplicates.
            let doPush = oracle.isEmpty || (Int(rng.next() % 100) < 58)
            if doPush {
                let value = Int(rng.next() % 40)
                stack.push(value)
                oracle.append(value)
                pushes += 1
            } else {
                let expected = oracle.removeLast()
                let got = stack.pop()
                #expect(got == expected)  // the top matches the oracle at EVERY step
                interleavedPops += 1
            }
        }

        // Drain the remainder: the tower's pop sequence must equal the oracle's
        // reverse-insertion (removeLast) drain.
        var tail: [Int] = []
        while let next = stack.pop() { tail.append(next) }
        var oracleTail: [Int] = []
        while let next = oracle.popLast() { oracleTail.append(next) }
        #expect(tail == oracleTail)

        // Over-drain returns nil (the remove-from-empty convention).
        let overDrain = stack.pop()
        #expect(overDrain == nil)

        // Shape sanity: the workload actually exercised both ops and forced growth.
        #expect(pushes + interleavedPops == totalOps)
        #expect(pushes >= 300)  // >> default capacity -> reallocations occurred
        #expect(interleavedPops >= 100)  // genuinely interleaved, not build-then-drain
    }
}
