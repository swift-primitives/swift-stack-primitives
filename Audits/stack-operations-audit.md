# Stack Operations Audit

<!--
---
version: 1.0.0
last_updated: 2026-02-16
status: RECOMMENDATION
tier: 1
---
-->

## Context

Proactive audit of swift-stack-primitives to inventory all public operations and compare against canonical Stack ADT operations.

**Trigger**: [RES-012] Discovery — proactive operations audit across 13 data structure packages.

**Scope**: Package-specific (swift-stack-primitives).

## Question

Does swift-stack-primitives provide the canonical operations expected of the Stack ADT? Which operations are present, which are missing, and which missing operations are intentionally absent at the primitives layer?

## Canonical Operations (ADT Reference)

| Operation | Expected Complexity | Description |
|-----------|-------------------|-------------|
| push(x) | O(1) amortized | Add element to top |
| pop() | O(1) | Remove and return top element |
| top()/peek() | O(1) | View top element without removal |
| is_empty | O(1) | Empty check |
| size/count | O(1) | Number of elements |

---

## Current Operations Inventory

### Variant: Dynamic (`Stack`)

#### Canonical Operations

| Canonical Operation | Method/Property | Signature | Complexity | Source File |
|---------------------|----------------|-----------|------------|-------------|
| push(x) | `push(_:)` | `mutating func push(_ element: consuming Element)` | O(1) amortized | `Stack ~Copyable.swift` |
| push(x) (CoW) | `push(_:)` | `mutating func push(_ element: Element)` | O(1) amortized, O(n) if CoW copy | `Stack Copyable.swift` |
| pop() | `pop()` | `mutating func pop() -> Element?` | O(1) | `Stack ~Copyable.swift` |
| pop() (CoW) | `pop()` | `mutating func pop() -> Element?` | O(1), O(n) if CoW copy | `Stack Copyable.swift` |
| top/peek | `peek(_:)` | `func peek<R>(_ body: (borrowing Element) -> R) -> R?` | O(1) | `Stack ~Copyable.swift` |
| top/peek (Copyable) | `peek()` | `func peek() -> Element?` | O(1) | `Stack Copyable.swift` |
| is_empty | `isEmpty` | `var isEmpty: Bool` | O(1) | `Stack ~Copyable.swift` |
| size/count | `count` | `var count: Index.Count` | O(1) | `Stack ~Copyable.swift` |

#### Additional Operations

| Operation | Signature | Complexity | Source File | Notes |
|-----------|-----------|------------|-------------|-------|
| `capacity` | `var capacity: Index.Count` | O(1) | `Stack ~Copyable.swift` | Current allocated capacity |
| `init()` | `public init()` | O(1) | `Stack.swift` | No allocation until first push |
| `init(reservingCapacity:)` | `public init(reservingCapacity capacity: Index.Count)` | O(1) | `Stack.swift` | Pre-allocates storage |
| `reserve(_:)` | `mutating func reserve(_ minimumCapacity: Index.Count)` | O(n) worst case | `Stack ~Copyable.swift` | Reserve capacity |
| `clear(keepingCapacity:)` | `mutating func clear(keepingCapacity: Bool = true)` | O(n) | `Stack ~Copyable.swift` / `Stack Copyable.swift` | Remove all elements |
| `compact()` | `mutating func compact()` | O(n) | `Stack Copyable.swift` | Reduce capacity to count |
| `truncate(to:)` | `mutating func truncate(to newCount: Index.Count)` | O(k) | `Stack ~Copyable.swift` / `Stack Copyable.swift` | Bulk pop from top |
| `forEach(_:)` | `func forEach(_ body: (borrowing Element) -> Void)` | O(n) | `Stack ~Copyable.swift` | Bottom-to-top iteration (~Copyable) |
| `span` | `var span: Span<Element>` | O(1) | `Stack ~Copyable.swift` | Read-only contiguous view |
| `mutableSpan` | `var mutableSpan: MutableSpan<Element>` | O(1) | `Stack ~Copyable.swift` / `Stack Copyable.swift` | Mutable contiguous view (CoW-aware) |
| `drain(_:)` | `mutating func drain(_ body: (consuming Element) -> Void)` | O(n) | `Stack Copyable.swift` | Ownership-transferring iteration |
| `drain` (Property) | `var drain: Property<Sequence.Drain, Stack>.View` | — | `Stack Copyable.swift` | Property.View accessor |
| `removeAll()` | `mutating func removeAll()` | O(n) | `Stack Copyable.swift` | Sequence.Clearable requirement |
| `makeIterator()` | `borrowing func makeIterator() -> Iterator` | O(1) | `Stack Copyable.swift` | Sequence.Protocol requirement |
| `underestimatedCount` | `var underestimatedCount: Int` | O(1) | `Stack Copyable.swift` | Sequence disambiguation |

#### Protocol Conformances (Dynamic)

| Protocol | Constraint | Source |
|----------|-----------|--------|
| `Copyable` | `where Element: Copyable` | `Stack.swift` |
| `@unchecked Sendable` | `where Element: Sendable` | `Stack.swift` |
| `Sequence.Protocol` | `where Element: Copyable` | `Stack Copyable.swift` |
| `Swift.Sequence` | `where Element: Copyable` | `Stack Copyable.swift` |
| `Sequence.Clearable` | `where Element: Copyable` | `Stack Copyable.swift` |
| `Sequence.Drain.Protocol` | `where Element: Copyable` | `Stack Copyable.swift` |

---

### Variant: Bounded (`Stack.Bounded`)

#### Canonical Operations

| Canonical Operation | Method/Property | Signature | Complexity | Source File |
|---------------------|----------------|-----------|------------|-------------|
| push(x) | `push(_:)` | `mutating func push(_ element: consuming Element) throws(__StackBoundedError)` | O(1) | `Stack.Bounded ~Copyable.swift` |
| push(x) (CoW) | `push(_:)` | `mutating func push(_ element: Element) throws(__StackBoundedError)` | O(1) | `Stack.Bounded ~Copyable.swift` |
| pop() | `pop()` | `mutating func pop() -> Element?` | O(1) | `Stack.Bounded ~Copyable.swift` |
| pop() (CoW) | `pop()` | `mutating func pop() -> Element?` | O(1) | `Stack.Bounded ~Copyable.swift` |
| top/peek | `peek(_:)` | `func peek<R>(_ body: (borrowing Element) -> R) -> R?` | O(1) | `Stack.Bounded ~Copyable.swift` |
| top/peek (Copyable) | `peek()` | `func peek() -> Element?` | O(1) | `Stack.Bounded ~Copyable.swift` |
| is_empty | `isEmpty` | `var isEmpty: Bool` | O(1) | `Stack.Bounded ~Copyable.swift` |
| size/count | `count` | `var count: Stack<Element>.Index.Count` | O(1) | `Stack.Bounded ~Copyable.swift` |

#### Additional Operations

| Operation | Signature | Complexity | Source File | Notes |
|-----------|-----------|------------|-------------|-------|
| `capacity` | `var capacity: Stack<Element>.Index.Count` | O(1) | `Stack.Bounded ~Copyable.swift` | Returns `requestedCapacity` |
| `isFull` | `var isFull: Bool` | O(1) | `Stack.Bounded ~Copyable.swift` | Bounded-specific |
| `requestedCapacity` | `let requestedCapacity: Index.Count` | O(1) | `Stack.swift` | Stored property |
| `init(capacity:)` | `public init(capacity: Index.Count)` | O(1) | `Stack.swift` | Allocates upfront |
| `clear()` | `mutating func clear()` | O(n) | `Stack.Bounded ~Copyable.swift` | Remove all, keep capacity |
| `clear()` (CoW) | `mutating func clear()` | O(n) | `Stack.Bounded ~Copyable.swift` | CoW-aware variant |
| `truncate(to:)` | `mutating func truncate(to newCount: Stack<Element>.Index.Count)` | O(k) | `Stack.Bounded ~Copyable.swift` | ~Copyable and CoW variants |
| `forEach(_:)` | `func forEach(_ body: (borrowing Element) -> Void)` | O(n) | `Stack.Bounded ~Copyable.swift` | Bottom-to-top (~Copyable) |
| `span` | `var span: Span<Element>` | O(1) | `Stack.Bounded ~Copyable.swift` | Read-only contiguous view |
| `mutableSpan` | `var mutableSpan: MutableSpan<Element>` | O(1) | `Stack.Bounded ~Copyable.swift` | ~Copyable and CoW variants |
| `drain(_:)` | `mutating func drain(_ body: (consuming Element) -> Void)` | O(n) | `Stack.Bounded Copyable.swift` | Ownership-transferring iteration |
| `drain` (Property) | `var drain: Property<Sequence.Drain, Stack.Bounded>.View` | — | `Stack.Bounded Copyable.swift` | Property.View accessor |
| `removeAll()` | `mutating func removeAll()` | O(n) | `Stack.Bounded Copyable.swift` | Sequence.Clearable requirement |
| `makeIterator()` | `borrowing func makeIterator() -> Iterator` | O(1) | `Stack.Bounded Copyable.swift` | Sequence.Protocol requirement |
| `underestimatedCount` | `var underestimatedCount: Int` | O(1) | `Stack.Bounded Copyable.swift` | Sequence disambiguation |

#### Error Types (Bounded)

| Type | Cases | Source File |
|------|-------|-------------|
| `Stack.Bounded.Error` (alias for `__StackBoundedError`) | `.overflow` | `Stack.Error.swift` |

#### Protocol Conformances (Bounded)

| Protocol | Constraint | Source |
|----------|-----------|--------|
| `Copyable` | `where Element: Copyable` | `Stack.swift` |
| `@unchecked Sendable` | `where Element: Sendable` | `Stack.Bounded ~Copyable.swift` |
| `Swift.Sequence` | `where Element: Copyable` | `Stack.Bounded Copyable.swift` |
| `Sequence.Protocol` | `where Element: Copyable` | `Stack.Bounded Copyable.swift` |
| `Sequence.Clearable` | `where Element: Copyable` | `Stack.Bounded Copyable.swift` |
| `Sequence.Drain.Protocol` | `where Element: Copyable` | `Stack.Bounded Copyable.swift` |

---

### Variant: Static (`Stack.Static`)

#### Canonical Operations

| Canonical Operation | Method/Property | Signature | Complexity | Source File |
|---------------------|----------------|-----------|------------|-------------|
| push(x) | `push(_:)` | `mutating func push(_ element: consuming Element) throws(__StackStaticError)` | O(1) | `Stack.Static ~Copyable.swift` |
| pop() | `pop()` | `mutating func pop() -> Element?` | O(1) | `Stack.Static ~Copyable.swift` |
| top/peek | `peek(_:)` | `func peek<R>(_ body: (borrowing Element) -> R) -> R?` | O(1) | `Stack.Static ~Copyable.swift` |
| top/peek (Copyable) | `peek()` | `func peek() -> Element?` | O(1) | `Stack.Static ~Copyable.swift` |
| is_empty | `isEmpty` | `var isEmpty: Bool` | O(1) | `Stack.Static ~Copyable.swift` |
| size/count | `count` | `var count: Stack<Element>.Index.Count` | O(1) | `Stack.Static ~Copyable.swift` |

#### Additional Operations

| Operation | Signature | Complexity | Source File | Notes |
|-----------|-----------|------------|-------------|-------|
| `isFull` | `var isFull: Bool` | O(1) | `Stack.Static ~Copyable.swift` | Capacity-bounded check |
| `init()` | `public init()` | O(1) | `Stack.swift` | Inline storage, zero allocation |
| `clear()` | `mutating func clear()` | O(n) | `Stack.Static ~Copyable.swift` | Remove all |
| `truncate(to:)` | `mutating func truncate(to newCount: Stack<Element>.Index.Count)` | O(k) | `Stack.Static ~Copyable.swift` | Bulk pop from top |
| `forEach(_:)` | `func forEach(_ body: (borrowing Element) -> Void)` | O(n) | `Stack.Static ~Copyable.swift` | Bottom-to-top (~Copyable) |
| `span` | `var span: Span<Element>` | O(1) | `Stack.Static ~Copyable.swift` | Read-only contiguous view |
| `mutableSpan` | `var mutableSpan: MutableSpan<Element>` | O(1) | `Stack.Static ~Copyable.swift` | Mutable contiguous view |
| `drain(_:)` | `mutating func drain(_ body: (consuming Element) -> Void)` | O(n) | `Stack.Static Copyable.swift` | Ownership-transferring iteration |
| `removeAll()` | `mutating func removeAll()` | O(n) | `Stack.Static Copyable.swift` | Sequence.Clearable requirement |
| `makeIterator()` | `borrowing func makeIterator() -> Iterator` | O(n) | `Stack.Static Copyable.swift` | Copies to snapshot buffer |
| `underestimatedCount` | `var underestimatedCount: Int` | O(1) | `Stack.Static Copyable.swift` | Sequence disambiguation |

#### Property.View Accessors (Static, `where Element: Copyable`)

| Property | Type | Source File |
|----------|------|-------------|
| `drain` | `Property<Sequence.Drain, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `forEach` | `Property<Sequence.ForEach, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `satisfies` | `Property<Sequence.Satisfies, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `first` | `Property<Sequence.First, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `reduce` | `Property<Sequence.Reduce, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `contains` | `Property<Sequence.Contains, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `drop` | `Property<Sequence.Drop, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |
| `prefix` | `Property<Sequence.Prefix, Self>.View.Typed<Element>.Valued<capacity>` | `Stack.Static Copyable.swift` |

#### Error Types (Static)

| Type | Cases | Source File |
|------|-------|-------------|
| `Stack.Static.Error` (alias for `__StackStaticError`) | `.overflow` | `Stack.Error.swift` |

#### Protocol Conformances (Static)

| Protocol | Constraint | Source |
|----------|-----------|--------|
| `@unchecked Sendable` | `where Element: Sendable` | `Stack.Static ~Copyable.swift` |
| `Sequence.Protocol` | `where Element: Copyable` | `Stack.Static Copyable.swift` |
| `Sequence.Clearable` | `where Element: Copyable` | `Stack.Static Copyable.swift` |
| `Sequence.Drain.Protocol` | `where Element: Copyable` | `Stack.Static Copyable.swift` |

**Note**: `Stack.Static` is **unconditionally `~Copyable`** (inline storage requires deinit), so it cannot conform to `Swift.Sequence` (which requires `Copyable`). It conforms to `Sequence.Protocol` instead.

---

### Variant: Small (`Stack.Small`)

#### Canonical Operations

| Canonical Operation | Method/Property | Signature | Complexity | Source File |
|---------------------|----------------|-----------|------------|-------------|
| push(x) | `push(_:)` | `mutating func push(_ element: consuming Element)` | O(1) amortized, O(n) on spill | `Stack.Small ~Copyable.swift` |
| pop() | `pop()` | `mutating func pop() -> Element?` | O(1) | `Stack.Small ~Copyable.swift` |
| top/peek | `peek(_:)` | `func peek<R>(_ body: (borrowing Element) -> R) -> R?` | O(1) | `Stack.Small ~Copyable.swift` |
| top/peek (Copyable) | `peek()` | `func peek() -> Element?` | O(1) | `Stack.Small ~Copyable.swift` |
| is_empty | `isEmpty` | `var isEmpty: Bool` | O(1) | `Stack.Small ~Copyable.swift` |
| size/count | `count` | `var count: Stack<Element>.Index.Count` | O(1) | `Stack.Small ~Copyable.swift` |

#### Additional Operations

| Operation | Signature | Complexity | Source File | Notes |
|-----------|-----------|------------|-------------|-------|
| `capacity` | `var capacity: Stack<Element>.Index.Count` | O(1) | `Stack.Small ~Copyable.swift` | Inline or heap capacity |
| `isSpilled` | `var isSpilled: Bool` | O(1) | `Stack.swift` | Diagnostic: inline vs heap |
| `init()` | `public init()` | O(1) | `Stack.swift` | Inline storage |
| `clear()` | `mutating func clear()` | O(n) | `Stack.Small ~Copyable.swift` | Resets to inline mode if spilled |
| `truncate(to:)` | `mutating func truncate(to newCount: Stack<Element>.Index.Count)` | O(k) | `Stack.Small ~Copyable.swift` | Bulk pop from top |
| `forEach(_:)` | `func forEach(_ body: (borrowing Element) -> Void)` | O(n) | `Stack.Small ~Copyable.swift` | Bottom-to-top (~Copyable) |
| `span` | `var span: Span<Element>` | O(1) | `Stack.Small ~Copyable.swift` | Read-only contiguous view |
| `mutableSpan` | `var mutableSpan: MutableSpan<Element>` | O(1) | `Stack.Small ~Copyable.swift` | Mutable contiguous view |
| `drain(_:)` | `mutating func drain(_ body: (consuming Element) -> Void)` | O(n) | `Stack.Small Copyable.swift` | Ownership-transferring iteration |
| `removeAll()` | `mutating func removeAll()` | O(n) | `Stack.Small Copyable.swift` | Sequence.Clearable requirement |
| `makeIterator()` | `borrowing func makeIterator() -> Iterator` | O(n) | `Stack.Small Copyable.swift` | Copies to snapshot buffer |
| `underestimatedCount` | `var underestimatedCount: Int` | O(1) | `Stack.Small Copyable.swift` | Sequence disambiguation |

#### Property.View Accessors (Small, `where Element: Copyable`)

| Property | Type | Source File |
|----------|------|-------------|
| `drain` | `Property<Sequence.Drain, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `forEach` | `Property<Sequence.ForEach, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `satisfies` | `Property<Sequence.Satisfies, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `first` | `Property<Sequence.First, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `reduce` | `Property<Sequence.Reduce, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `contains` | `Property<Sequence.Contains, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `drop` | `Property<Sequence.Drop, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |
| `prefix` | `Property<Sequence.Prefix, Self>.View.Typed<Element>.Valued<inlineCapacity>` | `Stack.Small Copyable.swift` |

#### Protocol Conformances (Small)

| Protocol | Constraint | Source |
|----------|-----------|--------|
| `@unchecked Sendable` | `where Element: Sendable` | `Stack.Small ~Copyable.swift` |
| `Sequence.Protocol` | `where Element: Copyable` | `Stack.Small Copyable.swift` |
| `Sequence.Clearable` | `where Element: Copyable` | `Stack.Small Copyable.swift` |
| `Sequence.Drain.Protocol` | `where Element: Copyable` | `Stack.Small Copyable.swift` |

**Note**: Like `Stack.Static`, `Stack.Small` is **unconditionally `~Copyable`** (inline storage requires deinit), so it cannot conform to `Swift.Sequence`. It conforms to `Sequence.Protocol` instead.

---

### Shared Infrastructure (Stack Primitives Core)

| Item | Type | Source File |
|------|------|-------------|
| `Stack<Element>.Index` | `typealias` for `Index_Primitives.Index<Element>` | `Stack.Index.swift` |
| `Stack.Bounded.Error` | `typealias` for `__StackBoundedError<Element>` | `Stack.Error.swift` |
| `Stack.Static.Error` | `typealias` for `__StackStaticError<Element>` | `Stack.Error.swift` |
| `__StackBoundedError` | `enum` with `.overflow` case | `Stack.Error.swift` |
| `__StackStaticError` | `enum` with `.overflow` case | `Stack.Error.swift` |

---

## Gap Analysis

### Present and Correctly Mapped

All five canonical Stack ADT operations are present across all four variants:

| Canonical Op | Dynamic | Bounded | Static | Small |
|-------------|:---:|:---:|:---:|:---:|
| push(x) | `push(_:)` | `push(_:) throws` | `push(_:) throws` | `push(_:)` |
| pop() | `pop() -> Element?` | `pop() -> Element?` | `pop() -> Element?` | `pop() -> Element?` |
| top/peek | `peek()` / `peek(_:)` | `peek()` / `peek(_:)` | `peek()` / `peek(_:)` | `peek()` / `peek(_:)` |
| is_empty | `isEmpty` | `isEmpty` | `isEmpty` | `isEmpty` |
| size/count | `count` | `count` | `count` | `count` |

**Coverage**: 5/5 canonical operations = **100%** across all variants.

The variant-appropriate semantics are correct:
- Dynamic's `push` does not throw (grows automatically)
- Bounded's `push` throws `__StackBoundedError.overflow`
- Static's `push` throws `__StackStaticError.overflow`
- Small's `push` does not throw (spills to heap)
- All `pop()` return `Optional` (safe empty handling, not trapping)
- Both `peek()` (Copyable convenience) and `peek(_:)` (~Copyable closure form) are provided

### Missing -- Candidates for Primitives Layer

| Operation | Priority | Rationale |
|-----------|----------|-----------|
| `Equatable where Element: Equatable` | **High** | Capacity-independent element-wise equality is fundamental data structure semantics. Both C++ `std::stack` and Haskell `Data.Stack` provide it. Already identified in `stack-discipline-boundary-analysis.md`. |
| `Hashable where Element: Hashable` | **High** | Follows directly from Equatable. Required for using stacks as dictionary keys or set members. |
| `CustomStringConvertible` | **Low** | Human-readable stack representation. Useful for debugging but not a canonical ADT operation. |
| `CustomDebugStringConvertible` | **Low** | Debug representation. Same reasoning. |

### Missing -- Intentionally Absent (Higher Layer)

| Operation | Reason for Exclusion |
|-----------|---------------------|
| `contains(_:)` requiring `Equatable` | Available via `Sequence` conformance (Copyable elements) and via Property.View `contains` accessor (Static, Small). Not a canonical stack operation. Correctly gated behind protocol constraint, not added to the stack type itself. |
| `Comparable` / sorting | Stacks are not ordered collections. No canonical basis. |
| `Codable` | Serialization concern; belongs at Foundations layer (Layer 3). |
| `ExpressibleByArrayLiteral` | Convenience; not fundamental. Could be added later at a higher layer. |
| Indexed access (`subscript`, `element(at:)`) | Deliberately excluded per the `stack-indexed-access-adt-tension.md` analysis. Violates the LIFO discipline that defines a stack. The analysis recommended namespacing behind `.indexed`; the current state has these APIs fully absent. |

### Observations on Non-Canonical Operations

The package provides several operations beyond the canonical five that are well-motivated at the primitives layer:

| Operation | Present On | Justification |
|-----------|-----------|---------------|
| `clear()` / `clear(keepingCapacity:)` | All variants | Bulk removal. Equivalent to "pop all." Essential for reuse patterns. |
| `truncate(to:)` | All variants | Bulk pop from top. Semantically "pop until count equals N." Respects LIFO ordering. |
| `compact()` | Dynamic only | Memory management. Reduces capacity to match count. Consumer ergonomics over buffer mechanism. |
| `reserve(_:)` | Dynamic only | Pre-allocation hint. Consumer ergonomics for known workloads. |
| `capacity` | Dynamic, Bounded, Small | Capacity query. Necessary for capacity-aware code. |
| `isFull` | Bounded, Static | Essential for fixed-capacity variants -- caller must know before trying `push`. |
| `isSpilled` | Small only | Diagnostic for the SmallVec pattern. Legitimately consumer-facing. |
| `forEach(_:)` | All variants (~Copyable) | Iteration for move-only elements. Cannot use `Sequence` conformance. |
| `span` / `mutableSpan` | All variants | Standard Swift contiguous memory access mechanism. Required for FFI, serialization, bulk operations. Retained at top level per `stack-indexed-access-adt-tension.md` recommendation. |
| `drain(_:)` | All variants (Copyable) | Ownership-transferring iteration. Necessary for consuming stack contents. |
| Property.View accessors | Static, Small | `forEach`, `satisfies`, `first`, `reduce`, `contains`, `drop`, `prefix`. These are Sequence-operation facades via the Property.View pattern. Present only on the ~Copyable-unconditional variants that cannot use `Swift.Sequence` directly. |

### Cross-Variant Consistency

| Feature | Dynamic | Bounded | Static | Small | Notes |
|---------|:---:|:---:|:---:|:---:|-------|
| `push` | non-throwing | throwing | throwing | non-throwing | Correct: dynamic/small grow; bounded/static are fixed |
| `pop` | Optional | Optional | Optional | Optional | Consistent |
| `peek()` (Copyable) | Yes | Yes | Yes | Yes | Consistent |
| `peek(_:)` (~Copyable) | Yes | Yes | Yes | Yes | Consistent |
| `count` | Yes | Yes | Yes | Yes | Consistent |
| `isEmpty` | Yes | Yes | Yes | Yes | Consistent |
| `capacity` | Yes | Yes | -- | Yes | Static has no `capacity` property (compile-time known) |
| `isFull` | -- | Yes | Yes | -- | Correct: only fixed-capacity variants |
| `clear` | w/ keepingCapacity | no param | no param | no param | Dynamic's parameter makes sense (it can release storage) |
| `truncate(to:)` | Yes | Yes | Yes | Yes | Consistent |
| `forEach(_:)` (~Copyable) | Yes | Yes | Yes | Yes | Consistent |
| `span` | Yes | Yes | Yes | Yes | Consistent |
| `mutableSpan` | Yes | Yes | Yes | Yes | Consistent |
| `drain(_:)` | Copyable | Copyable | Copyable | Copyable | Consistent |
| `Swift.Sequence` | Yes | Yes | -- | -- | Static/Small are ~Copyable, cannot conform |
| `Sequence.Protocol` | Yes | Yes | Yes | Yes | Consistent |
| `Sequence.Clearable` | Yes | Yes | Yes | Yes | Consistent |
| `Sequence.Drain.Protocol` | Yes | Yes | Yes | Yes | Consistent |
| Property.View accessors | drain only | drain only | 8 accessors | 8 accessors | Static/Small need more Property.View surface to compensate for missing Swift.Sequence |
| `Copyable` | Conditional | Conditional | Never | Never | Correct: inline storage requires deinit |
| `Sendable` | Conditional | Conditional | Conditional | Conditional | Consistent |
| `compact()` | Yes | -- | -- | -- | Only Dynamic can shrink allocation |
| `reserve(_:)` | Yes | -- | -- | -- | Only Dynamic supports growth hints |
| `isSpilled` | -- | -- | -- | Yes | Only Small has the inline/heap duality |

---

## Outcome

**Status**: RECOMMENDATION

### Summary

**Canonical ADT coverage: 100%.** All five fundamental Stack operations (push, pop, peek, isEmpty, count) are present on all four variants with correct variant-appropriate semantics (throwing vs non-throwing push, safe Optional pop, both Copyable and ~Copyable peek forms).

**Cross-variant consistency is strong.** The four variants (Dynamic, Bounded, Static, Small) share a uniform core API surface, with differences only where the variant's storage model demands them (e.g., `isFull` on fixed-capacity variants, `compact()` on Dynamic, `isSpilled` on Small).

**The indexed-access APIs previously flagged as contested in `stack-discipline-boundary-analysis.md` and `stack-indexed-access-adt-tension.md` are not present in the current source.** This means the package's top-level surface is purely LIFO, matching the recommendation from those analyses. `span`/`mutableSpan` are retained as the standard Swift contiguous memory escape hatch.

### Action Items

| Item | Priority | Scope |
|------|----------|-------|
| Add `Equatable where Element: Equatable` | High | All 4 variants. Capacity-independent element-wise comparison. |
| Add `Hashable where Element: Hashable` | High | All 4 variants. Follows from Equatable. |
| Add `CustomStringConvertible` | Low | All 4 variants. Useful for debugging output. |
| Consider `pop(count:)` alias for `truncate(to:)` | Low | Vocabulary alignment per discipline-boundary analysis Recommendation 3. Not blocking. |

### References

- `stack-discipline-boundary-analysis.md` -- layering audit identifying missing Equatable/Hashable
- `stack-indexed-access-adt-tension.md` -- resolution of indexed-access question
- Liskov & Guttag, "Abstraction and Specification in Program Development" -- formal Stack ADT axioms
- CLRS, "Introduction to Algorithms," Ch. 10.1 -- canonical Stack operations
