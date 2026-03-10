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

@Suite("Stack - Deinit")
struct StackDeinitTests {

    final class Tracker: @unchecked Sendable {
        private var _storage: [Int] = []
        var count: Int { _storage.count }
        var deinitOrder: [Int] { _storage }
        func append(_ id: Int) { _storage.append(id) }
    }

    struct TrackedElement: ~Copyable {
        let id: Int
        let tracker: Tracker
        init(_ id: Int, tracker: Tracker) { self.id = id; self.tracker = tracker }
        deinit { tracker.append(id) }
    }

    // MARK: - Stack.Static

    @Test
    func `Static deinit destroys all elements`() throws {
        let tracker = Tracker()
        do {
            var stack = Stack<TrackedElement>.Static<4>()
            _ = try stack.push(TrackedElement(1, tracker: tracker))
            _ = try stack.push(TrackedElement(2, tracker: tracker))
            _ = try stack.push(TrackedElement(3, tracker: tracker))
        }
        #expect(tracker.count == 3)
    }

    @Test
    func `Static empty deinit does not crash`() {
        do {
            let _ = Stack<TrackedElement>.Static<4>()
        }
    }

    // MARK: - Stack.Small

    @Test
    func `Small deinit destroys all elements in inline mode`() {
        let tracker = Tracker()
        do {
            var stack = Stack<TrackedElement>.Small<4>()
            stack.push(TrackedElement(1, tracker: tracker))
            stack.push(TrackedElement(2, tracker: tracker))
            stack.push(TrackedElement(3, tracker: tracker))
        }
        #expect(tracker.count == 3)
    }

    @Test
    func `Small deinit destroys all elements after spill`() {
        let tracker = Tracker()
        do {
            var stack = Stack<TrackedElement>.Small<2>()
            stack.push(TrackedElement(1, tracker: tracker))
            stack.push(TrackedElement(2, tracker: tracker))
            // Spill to heap
            stack.push(TrackedElement(3, tracker: tracker))
            stack.push(TrackedElement(4, tracker: tracker))
        }
        #expect(tracker.count == 4)
    }

    @Test
    func `Small empty deinit does not crash`() {
        do {
            let _ = Stack<TrackedElement>.Small<4>()
        }
    }
}
