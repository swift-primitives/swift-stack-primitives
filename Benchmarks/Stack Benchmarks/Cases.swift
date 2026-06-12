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
import Tagged_Primitives_Standard_Library_Integration
import Ordinal_Primitives
import Ordinal_Primitives_Standard_Library_Integration
import Cardinal_Primitives

// The pre-reshape element-generic ADT (weakness-sweep §4: hand-rolled CoW,
// S8 conditional-Copyable) at the f648181 post-Sendable-fix tip — measured
// as shipped, the before-picture for its eventual column respell.

extension Bench {
    /// Typed count from a runtime size via the non-throwing `UInt` lane.
    static func count<E>(_ n: Int) -> Index_Primitives.Index<E>.Count {
        Index_Primitives.Index<E>.Count(Cardinal(UInt(n)))
    }

    /// `pushPop.cycle` at steady occupancy n · `build.zero` (growth included,
    /// teardown in-batch) · `detach.firstMutation` (the hand-rolled CoW's
    /// sibling+push detach) — each vs `Swift.Array` push/pop.
    static func stackCases() -> [Result] {
        var results: [Result] = []
        let seed = opaque(7)

        for n in sizes {
            let pairs = Swift.max(1, (elementOpsTarget / 2) / Swift.max(n, 64)) * Swift.max(n, 64)
            let ops = pairs * 2

            var st = Stack<Int>(reservingCapacity: count(n))
            for i in 0..<n { st.push(i) }
            var sa: [Int] = []
            sa.reserveCapacity(n)
            for i in 0..<n { sa.append(i) }

            results.append(Result(
                name: "pushPop.cycle", subject: "tower.stack", n: n, opsPerBatch: ops,
                perOpNs: sample(opsPerBatch: ops) {
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

            results.append(Result(
                name: "build.zero", subject: "tower.stack", n: n, opsPerBatch: buildOps,
                perOpNs: sample(opsPerBatch: buildOps) {
                    var acc = 0
                    for _ in 0..<reps {
                        var b = Stack<Int>()
                        for i in 0..<n { b.push(i &+ seed) }
                        acc &+= b.peek() ?? 0
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
        }

        // The hand-rolled CoW's detach (sibling alive, one push) at two scales.
        for dn in [1_024, 65_536] {
            var owner = Stack<Int>(reservingCapacity: count(dn))
            for i in 0..<dn { owner.push(i) }
            var sOwner: [Int] = []
            sOwner.reserveCapacity(dn)
            for i in 0..<dn { sOwner.append(i) }
            let reps = Swift.max(16, copiedSlotsTarget / dn)

            results.append(Result(
                name: "detach.firstMutation", subject: "tower.stack", n: dn, opsPerBatch: reps,
                perOpNs: sample(opsPerBatch: reps) {
                    var acc = 0
                    for i in 0..<reps {
                        var sibling = owner
                        sibling.push(i &+ seed)
                        acc &+= sibling.pop() ?? 0
                    }
                    sink(acc)
                }
            ))

            results.append(Result(
                name: "detach.firstMutation", subject: "stdlib", n: dn, opsPerBatch: reps,
                perOpNs: sample(opsPerBatch: reps) {
                    var acc = 0
                    for i in 0..<reps {
                        var sibling = sOwner
                        sibling.append(i &+ seed)
                        acc &+= sibling.removeLast()
                    }
                    sink(acc)
                }
            ))
        }

        return results
    }
}
