# Repository map — stateful Theta A-not-B persistence

Pin: `d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`.

## Production seams

| Path | Role |
|---|---|
| `src/main/java/org/apache/datasketches/theta/ThetaAnotB.java` | Public stateful/stateless A-not-B API. |
| `src/main/java/org/apache/datasketches/theta/ThetaAnotBimpl.java` | Existing state machine and set-difference algorithm; reference persistence implementation. |
| `src/main/java/org/apache/datasketches/theta/ThetaSetOperation.java` | Generic heapify/wrap family dispatch and memory-status contract. |
| `src/main/java/org/apache/datasketches/theta/ThetaSetOperationBuilder.java` | Heap/direct operation construction and configured seed. |
| `src/main/java/org/apache/datasketches/theta/PreambleUtil.java` | Common Theta image fields and flags. |
| `src/main/java/org/apache/datasketches/theta/UnionImpl.java` | Sibling heap/direct/validation precedent. |
| `src/main/java/org/apache/datasketches/theta/ThetaIntersectionImpl.java` | Sibling wrap, heapify, read-only, and resource precedent. |

## Test seams

The base lane selects the existing A-not-B and sibling direct-memory tests:
`AnotBimplTest`, `CornerCaseThetaSetOperationsTest`, `SetOpsCornerCasesTest`,
`DirectIntersectionTest`, and `HeapIntersectionTest` (82 methods at the pin).
`SetOperationTest` is deliberately absent because its pristine direct A-not-B
predicate requires the old unsupported behavior and collided with verifier
composition once participants implemented the newly required builder path.

The additive hidden class contains 16 solution-required methods covering API
surfaces, state families, ownership, synchronization, resource boundaries,
continuation/reset/reuse, and validation. `test.sh` copies the read-only
composed repository to a task-scoped writable directory and invokes Maven
offline, preserving real Surefire XML.

## Environment seams

`tools/download_serialization_test_data.sh` provisions repository-required C++
and Go cross-language snapshots from the pinned DataSketches TCK commit. The
Dockerfile also preloads the exact toolchain, lifecycle plugins, test provider,
and dependencies needed for arbitrary-UID offline execution.
