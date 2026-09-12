# Gap analysis — stateful Theta A-not-B persistence

Verdict: `pass` for the immutable artifacts identified in `ARTIFACTS.sha256`.

Repository pin:
`d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`.

Exact artifact hashes:

- `meta.md`: `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`
- `test.patch`: `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132`
- `solution.patch`: `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f`
- `Dockerfile`: `41810ee27e986f723d0c7176059da76beb5566d3b91c9180988bc66e94eb688d`

## Atomic requirement map

| Public obligation | Repository-grounded dimensions | Strongest black-box coverage |
|---|---|---|
| Construct a persisted operation through both builder routes. | Family dispatch and `buildANotB(MemorySegment)` convenience overload. | `publicFactoriesAndBothBuilderRoutesAreAvailable` constructs both, checks resource identity, and uses the convenience-built state through the default typed wrap. |
| Expose the public static `int getMaxAnotBResultBytes(int k)` sizing helper. | Existing `ThetaSetOperation` public ABI and caller-provided direct storage. | The focused class calls the exact signature at compile time and uses its result for direct exact, estimation, live-view, and capacity scenarios. |
| Serialize and restore through typed and generic APIs. | `toByteArray`; one- and two-argument typed wrap; generic heapify and wrap. | Public-factory, exact-continuation, reset, validation, and read-only methods exercise every route behaviorally. |
| Preserve virgin, empty, exact, estimation, and zero-retained nonempty estimation state. | Heap/direct producers; exact versus theta-limited state; count-zero empty-bit distinction. | `virginEmptyAndExactEmptyStatesRemainReusable` and `estimationAndZeroRetainedNonemptyStatesRoundTrip`, including direct nonzero estimation continuation and direct exact/estimation zero-count restoration. |
| Heapify detaches; wrap aliases. | Mutable/read-only source, heap/native resource, same-resource and off-heap status. | `heapifyDetachesFromItsSourceImage`, `wrappedViewsShareLiveSetAndSubtractState`, `nativeDirectStorageReportsOwnershipAndOffHeapStatus`, and the read-only method. |
| Synchronize every state mutation, including reset-before-error for direct `setA(null)`. | `setA`, repeated `notB`, resetting result, direct null-`setA` reset before `SketchesArgumentException`, and second-operation reuse. | Shared-view, reset/reuse, direct estimation continuation, and null-reset methods observe through independently created views. |
| Preserve seed configuration and reject mismatches. | Heap serialization, direct family builder, typed wrap, and generic heapify. | `customSeedIsValidatedForHeapAndTypedWrap` uses a nondefault seed on heap and direct producers and challenges wrong expected seeds. |
| Reject insufficient capacity atomically. | State fits, subsequent larger `setA` does not; bytes and public result unchanged. | `directCapacityFailureLeavesPriorStateIntact` uses the repository sizing API for the prior state and compares the full supplied resource plus result. |
| Continue and reset correctly after restoration. | Exact and estimation continuation, interim reads, resetting final result, later independent operation. | Exact-continuation, direct-estimation, and reset/reuse methods. |
| Keep stateless A-not-B independent. | Heap state and read-only wrapped state. | `statelessCallsDoNotChangePersistedState` and the read-only stateless call. |
| Read-only images allow reads but reject mutation. | Typed/generic wrap and generic heapify. | `readOnlyWrapAllowsQueriesButRejectsStateMutations` checks result, serialization/heap restoration, stateless use, three mutators, both wrap dispatches, and detached heapify. |
| Reject wrong family/version/seed/inconsistent/truncated images. | Generic heapify/wrap and typed wrap; common preamble; empty/count/theta consistency; zero, out-of-theta, and duplicate retained hashes. | The validation methods mutate implementation-produced images. Theta is isolated with a zero-retained nonempty estimation state; retained hashes are corrupted only when their public result values are locatable in the standard payload, so alternate valid encodings are not rejected. |

The matrix groups heap exact-state fixtures across typed and generic restoration
when they delegate to the same public image contract. It keeps heap/direct
writers, heapify/wrap ownership, typed/generic dispatch, mutable/read-only
resources, exact/estimation zero-count state, and each lifecycle writer
separate because those cross distinct repository branches or public states.

## Demonstrated predecessor gaps

Six compile-valid mutations passed the predecessor's 16/16 focused methods:

| Prior-suite survivor | Missing independent boundary | Admitted final discriminator |
|---|---|---|
| Default typed wrap heap-copies instead of aliasing. | One-argument overload behavior. | Nonvirgin state, same-resource, and result parity through the default overload. |
| Generic wrap rejects read-only A-not-B while typed wrap works. | Generic read-only dispatch. | The read-only method exercises both wrap routes. |
| Direct writes replace estimation theta with exact theta. | Direct estimation producer. | Nonzero continuation and zero-retained estimation restoration through direct memory. |
| Direct construction ignores the configured seed. | Direct builder seed path. | Nondefault-seed family build, set, typed wrap, and mismatch rejection. |
| Typed wrap validates size/seed but omits common family/version/empty checks. | Typed validation separate from generic predispatch. | The implementation-produced image mutations are replayed through typed wrap. |
| Generic heapify rejects a read-only source although wrapping works. | Heap-copy source mutability. | Read-only generic heapify must detach and preserve the result. |

Each survivor was compile-valid and passed the predecessor focused suite. Each
also passed the complete pre-existing suite after cross-language fixtures were
provisioned in the approved offline image. The final reference passes every
admitted check; each corresponding mutant fails the intended method. Every
method remains fail-to-pass on the pristine implementation because its public
APIs or support are absent.

## Exact-version challenges

The final 19-mutant set additionally challenges heapification that aliases its
source, stale direct subtraction, stale direct reset, partial mutation before a
capacity error, collapsing zero-retained estimation to empty, direct exact-zero
empty-state corruption, ignored seed validation, stateful stateless calls,
missing direct null reset, read-only mutation with the wrong exception family,
unchecked generic source headers, omitted theta-domain validation, and omitted
retained-hash domain/duplicate validation. All 19 compile and all 19 are killed by
the focused suite. No final focused survivor entered a base-suite lane.

The direct exact-empty mutant initially survived because `getResult()`
canonicalized count-zero exact output. The admitted restoration conjunct
serializes and heapifies the live direct image, exposing the persisted
inconsistency without observing a private byte layout.

## Clarification re-audit

The new prompt sentences were split into two atomic obligations. The sizing
helper is an existing public static method at the pinned commit, and the focused
test compiles against its exact name, parameter type, return type, and owner
before using it to size several direct resources. No new behavioral probe is
needed for an ABI that the pristine repository already satisfies. The direct
null clause crosses a distinct failure-order and direct-writer boundary; M15
was replayed against the clarified version and produced exactly one focused
failure in the null-reset method. The reference and pristine focused outcomes,
the full 2,295-test reference suite, and all other dimension mappings were
rechecked. No newly public requirement is absent or merely indirect.

## Rejected gaps

- Requiring repeated serializations to be byte-identical or shorter than the
  supplied capacity was rejected: the prompt deliberately leaves the internal
  representation unspecified.
- Arbitrary payload-byte corruption, exact header size, retained-hash order,
  unused-tail zeroing, and serialized-size bounds were rejected as private
  representation choices.
- Additional permutations of the same heap/direct exact fixture were grouped
  unless they crossed a distinct writer, state predicate, restoration API, or
  ownership boundary.
- `notB` cannot grow retained state, so a second capacity-overflow direction
  would not represent another supported resource transition.

No actionable gap survived the attempted repository-grounded audit. This
`pass` is evidence for the enumerated dimensions and mutants, not proof that no
other false positive exists.

## Platform-path exact-version re-audit (historical Level 2)

The platform repair invalidated the prior verdict, so the atomic requirement
matrix and branch groupings above were re-audited against the new hashes. A
direct file comparison confirms that the additive TestNG class is byte-for-byte
unchanged; only generated `test.sh` tool discovery changed in `test.patch`.
`solution.patch` and `meta.md` are unchanged. The Dockerfile adds only standard
links to the already checksum-pinned tools.

Fresh exact composition preserved every behavioral cell: pristine base is
102/102, pristine focused has all 16 real methods and all 16 fail behaviorally,
reference base is 102/102, reference focused is 16/16, and testcase identities
match. The reference also passes 2,295/2,295 with the pinned fixtures. M15 was
rebuilt on this version and failed exactly the direct null-reset method. Because
no assertion, producer, state family, restoration route, or resource boundary
changed, no new coverage cell or probe is warranted. The exact-version gap
verdict is `pass`.

## Level 3 exact-version coverage audit

The final immutable hashes are those at the top of this file. The Level 2 raw
trajectories supplied exact repository-grounded evidence for two gaps: a
protected-test composition collision and incomplete logical-state corruption
coverage. The collision is not a participant discriminator; it is repaired by
keeping `test.patch` additive and selecting 82 unaffected base methods.

Logical-state validation is now decomposed into independent cells:

| State predicate | Producer/state used by the probe | Exact mutant result |
|---|---|---|
| Empty flag agrees with retained count and exact theta. | Nonempty exact image. | Existing M05 remains killed. |
| Theta is positive and within the common Theta domain. | Zero-retained nonempty estimation image, then common theta set to zero. | M18 initially survived the retained-hash fixture 16/16; after isolation it compiles and fails only `commonPreambleFamilyVersionAndEmptyConsistencyAreValidated`. |
| Every retained hash is positive and below theta. | Implementation-produced exact image; public result hashes locate raw-long payload values. | M19 compiles and fails only the common validation method. |
| Retained hashes are unique. | Two implementation-produced, publicly observed payload hashes. | The same M19 fails the duplicate conjunct in the common validation method. |

The hash probes are deliberately conditional. If a conforming implementation
does not expose its public result hashes as standard raw payload longs after
the common preamble, the test does not mutate arbitrary bytes and therefore
does not prescribe its internal encoding. Theta validation remains direct for
all representations because it uses the public common preamble and a count-zero
state that cannot be rejected by a retained-hash check.

The reference passes 82/82 base, 16/16 focused, and 2,295/2,295 complete tests.
Pristine passes 82/82 and fails all 16 focused methods behaviorally. Four
materially independent solver patches pass both exact lanes. M15, M18, and M19
were freshly rebuilt; each produces exactly one failure in its intended method.
The fifth solver patch is 14/16 on the final suite: its earlier short-header
miss remains, and the new duplicate-hash conjunct exposes its incomplete
logical-state validator.
No actionable repository-grounded gap survived. Verdict: `pass`.
