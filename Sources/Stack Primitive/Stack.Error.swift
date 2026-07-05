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

extension __Stack where S: ~Copyable {
    /// Errors thrown by stack operations.
    ///
    /// The per-family nested error (M10 rider): only the BOUNDED columns can
    /// overflow (`full` — fixed-capacity semantics, carried by the column);
    /// growable columns grow instead. Spelled `Stack<E>.Error` at the consumer.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The fixed-capacity column is full; the pushed element was rejected
        /// (and, being unreturned, destroyed — snapshot a copy first if it must
        /// survive a full stack).
        case full
    }
}
