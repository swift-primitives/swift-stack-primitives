---
name: stack-primitives
description: |
  LIFO stack collection primitives with ~Copyable element support.
  ALWAYS apply when working with stack data structures.

layer: implementation

requires:
  - primitives
  - memory

applies_to:
  - swift
  - swift-primitives
  - swift-stack-primitives
---

# Stack Primitives

LIFO stack collection with first-class ~Copyable support.

---

## Core Design Decisions

### [STK-001] Storage Variants

| Variant | Storage | Use Case |
|---------|---------|----------|
| `Stack.Inline<N>` | Stack-allocated | Small, fixed capacity |
| `Stack.Bounded` | Heap, fixed max | Known upper bound |
| `Stack.Unbounded` | Heap, growable | Dynamic size |

### [STK-002] ~Copyable Elements

**Statement**: All stack variants MUST support `~Copyable` elements.

```swift
struct Stack<Element: ~Copyable>: ~Copyable {
    final class Storage: ManagedBuffer<Header, Element> { }
}
extension Stack: Copyable where Element: Copyable {}
```

### [STK-003] Sequence Module Split

**Statement**: Sequence conformance MUST be in separate module due to Copyable requirement.

```
Stack Primitives Core      -> Core types (~Copyable support)
Stack Primitives Sequence  -> Sequence conformances
Stack Primitives           -> Re-exports both
```

---

## Key Operations

| Operation | Complexity | Ownership |
|-----------|------------|-----------|
| `push(_:)` | O(1) amortized | consuming |
| `pop()` | O(1) | consuming |
| `peek` | O(1) | borrowing |

---

## Cross-References

Full analysis: `Research/Research Paper.md`, `Research/Comparative Analysis.md`
