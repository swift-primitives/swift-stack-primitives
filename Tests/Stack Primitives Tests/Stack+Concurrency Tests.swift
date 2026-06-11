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

import Index_Primitives_Test_Support
import Synchronization
import Testing

@testable import Stack_Primitives

// W3 rider — STACK's own composition under concurrency (arc-1,
// GOAL-tower-arc-shared-soundness §W3): the A-1 reshape stores the `Shared`
// column (`Stack.swift:103`), so sibling stacks share one box until the first
// mutation runs the `withUnique` gate. The suite exercises the STACK surface
// (push/pop/peek/withSpan/drain) — not a copy of shared's suites.
//
// Conventions carried from W2 (REPORT-arc-shared-soundness-W2):
// — Span<class-element> closures EXTRACT values and assert outside (W2-F2:
//   guard/early-return Bool closures over class-element spans crash the 6.3.2
//   -O pipeline).
// — Teardown exactness via atomic ledgers (siblings drop on worker threads).
//
// Sendable note (W2-F1's stack twin, recorded in REPORT-…-W2 §2): the stack's
// `@unchecked Sendable` clause (`Stack.swift:191`) spells `Element: Sendable`
// bare — implicitly `Copyable` — so only Copyable-element stacks cross task
// boundaries today; the doc's "~Copyable handoff" intent is not realizable.
// This suite therefore fans out Copyable-element stacks only. Verified at this
// leg (compile error preserved below); fix is PROPOSED, not baked:
//     requireSendable(Stack<MoveOnlyProbe>())   // ← fails: 'MoveOnlyProbe'
//     // must conform to 'Copyable' (via Stack.swift:191's bare clause)

private enum Ledger {
    static let created = Atomic<Int>(0)
    static let destroyed = Atomic<Int>(0)
    static func reset() {
        created.store(0, ordering: .sequentiallyConsistent)
        destroyed.store(0, ordering: .sequentiallyConsistent)
    }
}

private final class Payload: Sendable {
    let value: Int
    init(_ value: Int) {
        self.value = value
        _ = Ledger.created.wrappingAdd(1, ordering: .relaxed)
    }
    deinit {
        _ = Ledger.destroyed.wrappingAdd(1, ordering: .relaxed)
    }
}

@Suite("Stack concurrency (W3 rider)")
struct StackConcurrencyTests {

    @Test(arguments: [2, 8, 32])
    func `concurrent push-pop detach: every sibling stack matches its LIFO model`(width: Int) async {
        var proto = Stack<Int>()
        for i in 0..<6 { proto.push(i) }
        let frozen = proto
        let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for t in 0..<width {
                group.addTask {
                    var mine = frozen                    // sibling: shares the column's box
                    var model = [0, 1, 2, 3, 4, 5]
                    var good = true
                    for k in 0..<120 {
                        switch k % 4 {
                        case 0, 1:
                            mine.push(t &* 1000 &+ k)    // first push detaches via the gate
                            model.append(t &* 1000 &+ k)
                        case 2:
                            let got = mine.pop()
                            let want = model.popLast()
                            good = good && (got == want)
                        default:
                            let top = mine.peek()
                            good = good && (top == model.last)
                        }
                    }
                    let snapshot = mine.withSpan { span in
                        var out: [Int] = []
                        out.reserveCapacity(span.count)
                        for i in 0..<span.count { out.append(span[i]) }
                        return out
                    }
                    return good && snapshot == model
                }
            }
            var out: [Bool] = []
            for await ok in group { out.append(ok) }
            return out
        }
        #expect(outcomes.count == width)
        #expect(outcomes.allSatisfy { $0 })
        let source = proto.withSpan { span in
            var out: [Int] = []
            for i in 0..<span.count { out.append(span[i]) }
            return out
        }
        #expect(source == [0, 1, 2, 3, 4, 5])            // the source stack never moved
        #expect(proto.count == 6)
    }

    @Test
    func `readers hold the seed while writers churn their own detached stacks`() async {
        var proto = Stack<Int>()
        proto.push(7)
        proto.push(8)
        let frozen = proto
        let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
            for _ in 0..<8 {
                group.addTask {                          // readers: never mutate their sibling
                    let mine = frozen
                    var good = true
                    for _ in 0..<200 {
                        let top = mine.peek()
                        let n = mine.count
                        let values = mine.withSpan { span in
                            var out: [Int] = []
                            for i in 0..<span.count { out.append(span[i]) }
                            return out
                        }
                        good = good && (top == 8) && (n == 2) && (values == [7, 8])
                    }
                    return good
                }
            }
            for t in 0..<8 {
                group.addTask {                          // writers: detach, churn, verify LIFO
                    var mine = frozen
                    for k in 0..<60 { mine.push(t &* 100 &+ k) }
                    var good = true
                    for k in (0..<60).reversed() {
                        good = good && (mine.pop() == t &* 100 &+ k)
                    }
                    let n = mine.count
                    return good && (n == 2)              // back to the seed depth
                }
            }
            var out: [Bool] = []
            for await ok in group { out.append(ok) }
            return out
        }
        #expect(outcomes.count == 16)
        #expect(outcomes.allSatisfy { $0 })
    }
}

// MARK: - Refcounted rung (exact teardown; serialized for the file-global ledger)

@Suite("Stack concurrency teardown (W3 rider)", .serialized)
struct StackConcurrencyTeardownTests {

    @Test
    func `refcounted payloads tear down exactly once across sibling stacks`() async {
        Ledger.reset()
        do {
            var proto = Stack<Payload>()
            for i in 0..<4 { proto.push(Payload(i)) }
            let frozen = proto
            let outcomes = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
                for t in 0..<12 {
                    group.addTask {
                        var mine = frozen                // sibling: retains the seed refs
                        for k in 0..<10 { mine.push(Payload(t &* 100 &+ k)) }
                        // W2-F2 discipline: extract, then assert outside the span borrow.
                        let values = mine.withSpan { span in
                            var out: [Int] = []
                            out.reserveCapacity(span.count)
                            for i in 0..<span.count { out.append(span[i].value) }
                            return out
                        }
                        var model: [Int] = [0, 1, 2, 3]
                        for k in 0..<10 { model.append(t &* 100 &+ k) }
                        var drained = 0
                        mine.drain { _ in drained &+= 1 }   // consuming param dies at closure end
                        let emptied = mine.isEmpty
                        return values == model && drained == 14 && emptied
                    }
                }
                var out: [Bool] = []
                for await ok in group { out.append(ok) }
                return out
            }
            #expect(outcomes.count == 12)
            #expect(outcomes.allSatisfy { $0 })
            let sourceDepth = proto.count
            #expect(sourceDepth == 4)                    // drains hit detached boxes only
        }
        // 4 seed + 12 × 10 pushed = 124 payloads, each destroyed exactly once
        // (drained in-task or released at scope exit).
        let created = Ledger.created.load(ordering: .sequentiallyConsistent)
        let destroyed = Ledger.destroyed.load(ordering: .sequentiallyConsistent)
        #expect(created == 124)
        #expect(destroyed == created)
    }
}
