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

import Stack_Primitives
import Index_Primitives

// The ADT-tower W2 DIRECT move-only `Stack<Int>` measured against `Swift.Array`
// (append / removeLast). The tower `Stack` is move-only, so a persistent subject
// cannot be copied to reset between reps — every batch builds fresh (the heap-pilot
// harness shape). The pre-reshape `tower.stack` (element-generic hand-rolled CoW)
// baselines at tip f648181 are the before-picture; the CoW gate+box (~6 ns/op) is
// GONE from this column, so pushPop/build deltas vs those rows are large by design.

extension Bench {

    /// Typed count from a runtime size via the non-throwing `UInt` lane.
    static func count(_ n: Int) -> Index<Int>.Count { Index<Int>.Count(UInt(n)) }

    /// The stack family's hot ops: `pushPop.cycle` (steady occupancy n),
    /// `build.zero` (n pushes from empty; growth included), `drain.cycle` (build
    /// then pop to empty). One `push`/`pop` = one op.
    ///
    /// ATTRIBUTION: the pre-reshape `tower.stack` pushPop.cycle ran ~7.7 ns flat,
    /// dominated by the hand-rolled-CoW gate+box per op. This DIRECT column has no
    /// CoW column pulled, so there is no gate and no box — the residual cost is the
    /// typed-slot append/removeLast seam (count-ledger + initialize/move) vs stdlib's
    /// raw `Array`. The pre-reshape `detach.firstMutation` row has NO analog here: the
    /// direct column is move-only (no shared box to detach); it re-materializes only
    /// when the `Shared` CoW front door is consumer-pulled. `pushPop.cycle` builds
    /// fresh per batch (pre-fill of n is inside the timed region — a ~≤3% skew at the
    /// largest n, since pairs ≫ n).
    static func stackCases() -> [Result] {
        var results: [Result] = []
        let seed = opaque(7)

        for n in sizes {
            let pairs = Swift.max(1, (elementOpsTarget / 2) / Swift.max(n, 64)) * Swift.max(n, 64)
            let ops = pairs * 2

            // MARK: pushPop.cycle (steady occupancy n)

            results.append(Result(
                name: "pushPop.cycle", subject: "tower.direct", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var st = TowerStack(minimumCapacity: count(n))
                    for i in 0..<n { st.push(i) }
                    var acc = 0
                    for i in 0..<pairs {
                        st.push(i &+ seed)
                        acc &+= st.pop() ?? 0
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "pushPop.cycle", subject: "stdlib", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
                    var sa: [Int] = []
                    sa.reserveCapacity(n)
                    for i in 0..<n { sa.append(i) }
                    var acc = 0
                    for i in 0..<pairs {
                        sa.append(i &+ seed)
                        acc &+= sa.removeLast()
                    }
                    sink(acc)
                }
            ))

            let reps = Swift.max(1, structureOpsTarget / n)
            let buildOps = reps * n

            // MARK: build.zero (n pushes from empty; growth included)

            results.append(Result(
                name: "build.zero", subject: "tower.direct", n: n, opsPerBatch: buildOps,
                perOpNs: sample(opsPerBatch: buildOps) {
                    var acc = 0
                    for _ in 0..<reps {
                        var b = TowerStack()
                        for i in 0..<n { b.push(i &+ seed) }
                        let t = b.top
                        acc &+= t
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "build.zero", subject: "stdlib", n: n, opsPerBatch: buildOps,
                perOpNs: sample(opsPerBatch: buildOps) {
                    var acc = 0
                    for _ in 0..<reps {
                        var b: [Int] = []
                        for i in 0..<n { b.append(i &+ seed) }
                        acc &+= b.last ?? 0
                    }
                    sink(acc)
                }
            ))

            // MARK: drain.cycle (build then pop to empty)

            results.append(Result(
                name: "drain.cycle", subject: "tower.direct", n: n, opsPerBatch: buildOps,
                perOpNs: sample(opsPerBatch: buildOps) {
                    var acc = 0
                    for _ in 0..<reps {
                        var b = TowerStack()
                        for i in 0..<n { b.push(i &+ seed) }
                        while let v = b.pop() { acc &+= v }
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "drain.cycle", subject: "stdlib", n: n, opsPerBatch: buildOps,
                perOpNs: sample(opsPerBatch: buildOps) {
                    var acc = 0
                    for _ in 0..<reps {
                        var b: [Int] = []
                        for i in 0..<n { b.append(i &+ seed) }
                        while let v = b.popLast() { acc &+= v }
                    }
                    sink(acc)
                }
            ))
        }
        return results
    }
}
