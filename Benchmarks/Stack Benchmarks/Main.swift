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

/// Family-tier proving benchmark for swift-stack-primitives (ADT-tower W2).
///
/// MEASUREMENT DISCIPLINE (§9.5 + [BENCH-002]): run release-only via
/// `rm -rf .build && swift run -c release "Stack Benchmarks"` — never via
/// `swift test` (the io-bench process-hang precedent). Machine identity,
/// toolchain, and run conditions are recorded by the runner shell and the
/// baselines doc, not introspected here (the primitives tier is
/// Foundation-free, [PRIM-FOUND-001]).
///
/// 6.3.3 label of record:
/// "Apple Swift 6.3.3 (swiftlang-6.3.3.1.3), XcodeDefault (Xcode 26.6 17F113)".
@main
enum Main {
    static func main() {
        print("=== swift-stack-primitives — family-tier proving benchmark (ADT-tower W2) ===")
        print("label of record: Apple Swift 6.3.3 (swiftlang-6.3.3.1.3), XcodeDefault (Xcode 26.6 17F113)")
        print("config: sizes=\(Bench.sizes) samples=\(Bench.samples) warmup=\(Bench.warmup)")
        print("targets/sample: element=\(Bench.elementOpsTarget) structure=\(Bench.structureOpsTarget)")
        print("subjects: tower.direct=Stack<Int> (direct move-only linear column) · stdlib=Swift.Array LIFO")
        print("shapes: pushPop.cycle (steady occupancy n) · build.zero (push from empty) · drain.cycle (build + pop to empty)")
        print("NOTE: the pre-reshape tower.stack (element-generic hand-rolled CoW, tip f648181) is the")
        print("      before-picture; its ~6 ns/op CoW gate+box is GONE from this direct column, so")
        print("      pushPop/build deltas vs those baseline rows are large by design. detach.firstMutation")
        print("      has no analog (move-only column, no shared box) — it returns with the Shared front door.")
        print("")
        Bench.globalWarmup()

        var results: [Bench.Result] = []
        for result in Bench.stackCases() {
            print(result.record)
            results.append(result)
        }

        print("")
        print(summaryTable(results))
        Bench.flushSink()
    }

    /// Aligned median (cv%) table: one row per shape × scale, one column per subject.
    static func summaryTable(_ results: [Bench.Result]) -> String {
        let subjects = ["tower.direct", "stdlib"]
        var rowKeys: [String] = []
        var cells: [String: [String: String]] = [:]
        for r in results {
            let key = "\(r.name) n=\(r.n)"
            if cells[key] == nil {
                rowKeys.append(key)
                cells[key] = [:]
            }
            cells[key]![r.subject] = "\(Bench.fixed(r.median, 3)) (\(Bench.fixed(r.cvPercent, 1))%)"
        }

        let nameWidth = rowKeys.map(\.count).max() ?? 0
        let columnWidth = 22
        var lines: [String] = []
        lines.append(pad("shape", nameWidth) + subjects.map { pad($0, columnWidth) }.joined())
        lines.append(String(repeating: "-", count: nameWidth + columnWidth * subjects.count))
        for key in rowKeys {
            let row = subjects.map { pad(cells[key]?[$0] ?? "-", columnWidth) }.joined()
            lines.append(pad(key, nameWidth) + row)
        }
        lines.append("")
        lines.append("unit: ns/op, median across \(Bench.samples) samples (cv%); per-op = batch / opsPerBatch")
        lines.append("pushPop.cycle: one op = one push or pop at steady occupancy n")
        lines.append("build.zero: one op = one push from empty · drain.cycle: one op = one push+pop lifecycle")
        return lines.joined(separator: "\n")
    }

    static func pad(_ text: String, _ width: Int) -> String {
        text.count >= width ? text + " " : text + String(repeating: " ", count: width - text.count)
    }
}
