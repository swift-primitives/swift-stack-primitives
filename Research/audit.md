# Audit: swift-stack-primitives

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/audit-primitives.md (2026-04-03)

**Pre-publication dependency-tree audit — P0/P1/P2 checks**

#### P1: Multi-Type File [API-IMPL-005]

**File**: `Sources/Stack Primitives Core/Stack.Error.swift` (2 types, 77 lines)

| Line | Type |
|------|------|
| 28 | `__StackBoundedError<Element>` |
| 45 | `__StackStaticError<Element>` |

**Assessment**: `__`-prefixed internal error enums hoisted to module scope for typed throws. Grouping is justified: related error types for variants of the same data structure sharing documentation context.

**Recommendation**: Accept as-is. The `__` prefix signals implementation infrastructure, not public API surface.

---

### From: swift-institute/Research/audits/implementation-naming-2026-03-20/swift-data-structures-batch.md (2026-03-20)

**Implementation + naming audit**

CLEAN - no findings
