# Design — stateful Theta A-not-B persistence

Status: `accepted and archived 2026-08-17; immutable Level 3 gates pass`.

Repository: `apache/datasketches-java` at
`d5cce9b3ad3f7c39faabcebb7f3934c4f73f14fc`.

Production language: Java. Task type: feature request.

## Public contract and repository evidence

Stateful `ThetaAnotB` must support the persistence lifecycle already exposed by
the sibling Theta union and intersection operations: direct construction in
caller-provided memory, serialization, heap restoration, and wrapping. Restored
state must remain usable through `setA`, repeated `notB`, interim result reads,
resetting result reads, and later reuse. Heap restoration must detach from its
source; wrapping must retain the supplied resource and respect its read-only
status.

The pinned repository explicitly rejects `A_NOT_B` with destination memory in
`ThetaSetOperationBuilder`, omits that family from generic `heapify` and `wrap`
dispatch, and exposes no `ThetaAnotB.toByteArray` or typed wrap factory. The
implementation nevertheless owns five persistent components: seed hash, empty
state, theta, retained hashes, and retained count. Sibling set operations provide
the public memory-ownership, seed-validation, preamble, truncation, and reset
precedents. No private cache layout or particular batching strategy is part of
the public contract.

## Trajectory-informed startup gate

The local search covered 339 indexed repositories, candidate/problem registries,
archived compact records, all fetched DataSketches branches, about 4,053
reachable commits, and the repository's source and tests. Current ownership was
refreshed on 2026-08-16 with exact all-state GitHub issue/PR searches for
`ThetaAnotB`, `A_NOT_B`, persistence, serialization, heapify, and wrap. There is
no exact prior problem, implementation, issue, pull request, or active owner.
The only search result combining A-not-B and serialization was unrelated issue
599; there are no open Theta pull requests and no open Theta-persistence issues.

There is no DataSketches solver trajectory. The closest raw trajectories and
their evaluator records were inspected directly:

| Evidence role | Problem / run | Outcome | Design implication |
|---|---|---|---|
| Legitimate pass | h5py VDS relocation, `agent-runs3/Nova_Nova_8` | 24/24 | A compact architecture may be legitimate; test observable restoration and lifecycle boundaries, not source layout. |
| Near pass | h5py VDS relocation, `agent-runs3/Nova_Nova_6` | 22/24 | The solver passed its own full suite but lost same-file identity and variable-length metadata behavior; identity and continuation require separate oracles. |
| Persistence analogue | archived Salsa persisted accumulators | compact record | Restored public behavior and continuation are the stable contract, not one encoding. |
| Broad miss | PcapPlusPlus filtered copy, `agent-runs4/Nova_Nova_10` | 9/14 | A substantial common path still missed multi-section and option-list lifecycle boundaries; distinct state producers need independent challenges. |

The h5py pass and near-pass used materially different internal architectures.
That supports black-box result/ownership tests while preserving implementation
freedom. The PcapPlusPlus trajectory built a large implementation and a narrow
visible regression but missed stated alternate boundaries, supporting a compact
state-family matrix rather than repeated fixtures for one path.

### Prompt-clarification review — 2026-08-16

The design gate was refreshed before changing the public prompt. Searches of the
problem/candidate registries, local trajectory stores, archived records, and the
exact DataSketches source still found no DataSketches solver trajectory or new
implementation evidence. The representative pass, near-pass, persistence
analogue, and broad miss above therefore remain the relevant trajectory set.

Auto-review identified two existing hidden-test contracts that needed explicit
participant-facing provenance. At the pinned commit,
`ThetaSetOperation.getMaxAnotBResultBytes(int)` is already a public static sizing
helper, and heap-backed `ThetaAnotB.setA(null)` already resets before throwing
`SketchesArgumentException`. The revised prompt names the helper signature and
requires the same reset-before-error lifecycle for writable direct-backed state.
These are prompt clarifications only: they do not change `test.patch`, reference
behavior, the discriminator set, or the permitted persistence representation.

### Platform-path environment repair — 2026-08-16

The trajectory/design search was refreshed before revising `test.patch`. No new
DataSketches solver trajectory exists, so the representative pass, near-pass,
persistence analogue, and broad miss above remain the applicable evidence. The
new evidence is the platform's baseline environment log: its derived runtime
successfully used the submitted image as its base, but `./test.sh base` and
`./test.sh new` both stopped at the Maven invocation with `mvn: command not
found`. No Maven, Java, compilation, or TestNG process started, so this is an
environment blocker and supplies no behavioral or difficulty evidence.

The repair changes only tool discovery. `test.sh` will invoke the image's
checksum-pinned Maven, JDK, toolchain, and offline cache by absolute path, and
the Dockerfile will expose Maven, Java, and javac in `/usr/local/bin` for solver
shells whose inherited `PATH` omits `/opt`. The public prompt, hidden assertions,
test identities, reference behavior, and discriminator ledger are unchanged.
This preserves every legitimate implementation architecture and addresses only
the evaluator/runtime boundary demonstrated by the platform log.

### Level 2 calibration mismatch and validation review — 2026-08-16

The startup search was refreshed against the newly supplied
`agent-runs1/Nova_Nova_1` through `Nova_Nova_5` bundles. These are the first raw
DataSketches solver trajectories, so they supersede the analogue-only evidence
for this revision. The representative categories are:

| Evidence role | Run | Outcome | Architecture and observed boundary |
|---|---|---|---|
| Legitimate pass | `Nova_Nova_2` | 16/16 focused | Four production files, compact three-long state image, direct/heap shared implementation, live segment synchronization, and complete theta/hash/duplicate validation. The production diff is 476 additions plus 103 deletions; the trajectory used 43 tool calls and ran focused and full Maven checks. |
| Near pass | `Nova_Nova_1` | 15/16 focused | The same compact state family covered lifecycle and typed validation but generic dispatch read the family byte before checking a minimum header. Zero- to two-byte generic inputs leaked `IndexOutOfBoundsException`. The production diff is 343 additions plus 35 deletions; the trajectory used 87 tool calls. |
| Evaluator-conflict pass | `Nova_Nova_3` | 16/16 focused; classified test-broken | The submitted solution patch changes only the same four production files and passes the feature suite. The protected p2p restore replaces the verifier's transitional `SetOperationTest` edit with the pristine `expectedExceptions` method, so the baseline then rejects the newly required direct builder behavior. |
| Broad behavioral failure | unavailable | All five solvers implemented the full lifecycle; four pass all focused behavior and one misses only generic short-header validation. | No broad failure is invented from the three identical evaluator-conflict verdicts. |

Runs 3–5 independently confirm the evaluator collision. The platform captures
`SetOperationTest.checkBuilderAnotB_noSeg` in its p2p manifest and restores the
pristine source before executing `test.sh`; meanwhile the current `test.patch`
owns and rewrites that same file. Once restored, the old annotation requires
the family builder to throw, while the public task and feature test require it
to succeed. This is not a solver regression. The fair repair is to stop owning
the pre-existing test file and remove that class from the selected base lane,
so the next immutable version's p2p manifest never contains the superseded
predicate. No runtime source rewriting or synthetic result is acceptable.

Auto-review also identified a real attempted-mutation gap: the public prompt
requires inconsistent persisted state to be rejected, and the reference already
checks `checkThetaCorruption`, nonpositive/out-of-theta retained hashes, and
duplicates, but the focused suite challenges only the empty flag/count
relationship. The revised discriminator will add nonpositive-theta, zero/hash-
at-theta, and duplicate-hash corruptions to implementation-produced images.
The oracle remains representation-tolerant: the theta field is a common Theta
preamble field, and retained-hash corruption is applied only when the standard
raw-long compact/table representation used by the repository and all five
observed solvers can be located from public result hashes. It does not require
hash order, exact image length, padding, or a compact-only layout.

The five-run evidence predicts that this fairness/coverage revision will replay
four compatible passes and one existing near miss. That is 4/5, not a successful
difficulty hardening result; the fresh-calibration expectation is approximately
7–9 solves out of ten. The observed successful solutions change four production
files with effective production churn of 509, 536, 579, and 584 lines (median
557.5). The platform message-count metric is unavailable in these bundles and
is not inferred from tool calls. Any artifact change creates Level 3 and resets
fresh calibration to 0/10.

The exact reference full-suite replay additionally proves that the pristine
`SetOperationTest.checkBuilderAnotB_noSeg` predicate cannot coexist with the
new public behavior: it is the sole failure after the reference implementation
enables direct A-not-B construction. The compatibility correction therefore
belongs in `solution.patch`, where the reference change replaces that obsolete
expect-exception regression with an ordinary direct-builder resource assertion.
It does not belong in `test.patch`: keeping the verifier patch off the existing
test source avoids the demonstrated participant/verifier merge collision, while
the hidden lifecycle suite independently enforces the same public behavior.
This source-level regression correction has no conditional legacy acceptance or
challenge-history comment and does not add a discriminator. The 4/5 replay and
7–9/10 fresh-calibration forecasts are unchanged.

The first exact validation mutant exposed one remaining coupling before the
revised hidden patch was frozen. M18 removes only the explicit theta-domain
check while retaining empty/count and retained-hash checks; it compiled and
passed all 16 candidate methods because the initial zero-theta fixture retained
hashes, so the independent hash-range validator rejected it indirectly. The
theta probe is therefore refined to start from an implementation-produced,
zero-retained nonempty estimation state before setting the common theta field
to zero. That state has no payload hash capable of masking the omitted theta
predicate, remains representation-independent, and is public through retained
count, empty, and theta result semantics. M18 must then fail the common-state
validation method. This is a distinct public malformed-state discriminator,
not another layout fixture; recording it here precedes the `test.patch`
revision and preserves the prior 4/5 compatibility forecast.

## Discriminator ledger

| Observed or plausible shortcut | Fair public invariant | Black-box oracle | Distinct boundary |
|---|---|---|---|
| Serialize only `getResult()` and reconstruct a stateless sketch. | Restored operator state accepts later `notB` calls and preserves theta and seed behavior. | Restore after one subtraction, subtract a second sketch, compare with uninterrupted execution. | Stateful continuation |
| Implement `heapify` but make `wrap` a heap copy. | Writable wrap aliases the supplied resource; heapify detaches. | `isSameResource`, backing-byte changes, and source mutation isolation. | Ownership/direct memory |
| Handle exact nonempty state only. | Virgin, empty, exact, zero-retained estimation, and retained estimation states round-trip. | Construct each through public sketches and compare result plus continuation. | State families |
| Update object fields but leave direct bytes stale. | Every state mutation and reset is immediately represented in caller memory. | Wrap the same resource after each transition and continue through the second view. | Live direct synchronization |
| Treat read-only wrapping as fully writable or fully unusable. | Nonmutating result/serialization/stateless calls work; state mutations fail consistently with sibling operations. | Read-only typed/generic wraps with both query and mutation calls. | Mutability boundary |
| Add typed APIs but omit generic family dispatch or builder overloads. | All public sibling-shaped entry points participate in the lifecycle. | Exercise typed wrap, generic wrap/heapify, generic builder, and convenience builder. | Producer/API modes |
| Trust any preamble or partial payload. | Wrong family/version/seed and truncation fail through established exception families. | Mutate common preamble fields and truncate an image created by the implementation itself. | Validation |
| Validate only the empty/count relation and trust decoded theta/hashes. | Decoded theta is positive; every retained hash is positive, below theta, and unique. | Corrupt the common theta field and, for standard raw-long state images, replace located public result hashes with zero, theta, and a duplicate. | Logical-state validation |
| Reset Java fields but not wrapped state. | `getResult(true)` returns the final result and leaves a reusable virgin state in both modes. | Reset, wrap/heapify again, then run an unrelated second operation. | Lifecycle reset |

## Cheapest-complete prototype

The minimal prototype uses a compact live state image rather than a hash-table
layout. It changes four production classes and adds 230 production diff lines.
It implements typed and generic restoration, direct construction, read-only and
same-resource behavior, capacity checks, common-preamble and payload validation,
serialization, continuation, and reset synchronization. Two focused TestNG
methods passed exact and estimation continuation, heap/direct identity,
read-only mutation, truncation/count corruption, and reuse.

This is not the candidate's rejection condition: the feature does not collapse
to one serializer and dispatch edit. The reference architecture is only one
valid implementation; a solver may use separate heap/direct classes, an
updatable sketch gadget, a compact state array, or another representation that
meets the public lifecycle.

## Pristine environment gate

Phase A passed on 2026-08-16 after treating all bootstrap failures as environment
blockers. The approved general image required checksum-pinned Temurin 25.0.4+7,
Maven 3.9.12, an explicit toolchain, warmed Surefire TestNG dependencies, and
removal of Maven repository-origin marker files for offline reuse. The repository
also intentionally downloads C++ and Go cross-language snapshots from
`apache/datasketches-tck` commit
`d363b12d293b395d90abb42677f9ea63178dbc0d`; the image provisions them while
networking is allowed.

Path-repaired retained Phase A image manifest ID:
`sha256:597b62915a2b2698096a7a52fd0edab5e424908f0f42c35efcb36ef93d50f47e`.
The subsequent clean Phase B gate image manifest ID was
`sha256:1ce7e08939412972086c72fdf0fe8881e4898ce7bf8e12b879a3f89878e8aec6`.
With networking disabled and UID/GID 10001, `mvn -o -B test` produced real
TestNG/JUnit output: 2,279 tests, 0 failures, 0 errors, 0 skipped. The earlier
39 missing-fixture failures were quarantined and are not behavioral evidence.

## Forecast

Fresh-calibration expectation: 3–6 successful solvers out of ten, with the upper
edge carrying too-easy risk relative to the accepted 1–5 band. There is no exact
prior-run compatibility estimate. The estimate uses the h5py and PcapPlusPlus
miss families above plus the four-class, 230-line minimal prototype. Fresh
calibration remains 0/10 until an immutable exact-version batch is run.

## Level 1/2 historical exact-version outcome

The final evaluator composition passes with 102/102 base tests on pristine and
reference, all 16 focused methods failing behaviorally on pristine, all 16
passing on the reference, and identical testcase identities. The composed
reference passes the complete 2,295-test suite. Gap and fairness verdicts are
`pass`; the exact false-positive audit kills all 17 compile-valid mutants.

Six compile-valid predecessor survivors passed 16/16 focused and 2,295/2,295
complete tests before their public API, producer, resource, and validation
probes were admitted. The final direct exact-empty restoration probe closes one
additional survivor found during the audit. No exact solver patches exist, so
observed compatible-solver replay is unavailable; this matches the forecast's
absence of a compatibility estimate. The 3–6/10 fresh-calibration expectation
is unchanged, and fresh calibration remains 0/10.

After auto-review, `meta.md` was clarified to name the existing sizing-helper
signature and the direct null-reset ordering. The prompt hash is now
`959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`;
the other three submission artifacts were byte-identical in that prompt-only
revision. Fresh Phase A and
Phase B, the complete reference suite, gap, fairness, and false-positive audits
all pass. A fresh M15 replay failed exactly the null-reset method, confirming
the clarified clause's distinct discriminator. Calibration remains 0/10.

The later platform baseline stopped before Maven because the derived runtime
did not preserve the submitted `/opt` PATH. The new immutable version exposes
the pinned tools at standard compatibility paths and makes `test.sh` select its
JDK, Maven, toolchain, and offline cache explicitly. With inherited
`PATH=/usr/bin:/bin` and blank `JAVA_HOME`, pristine base passes 102/102 and the
reference focused lane passes 16/16. Fresh Phase A passes 2,279/2,279, exact
Phase B passes, and the corrected complete reference replay passes
2,295/2,295. M15 still fails exactly its one intended method. The change adds no
behavioral discriminator, so the 3–6/10 forecast is unchanged; compatible
solver replay remains unavailable and fresh Level 2 calibration is 0/10.

## Level 3 final outcome — test mismatch repair

The immutable Level 3 artifacts are:

- `meta.md`: `959c446e9974b757fe3a105e03d3cfdaec61950c48ef8407f520ca754caf98c0`
- `test.patch`: `7f05e0d86b7b8df86362a1be9c370bc9074db47d8d710926600bae5553ae9132`
- `solution.patch`: `b145b1895ff99fd1f0e53794c7c54a86e601f0ac80f5b3915ca6e230c834ec4f`
- `Dockerfile`: `41810ee27e986f723d0c7176059da76beb5566d3b91c9180988bc66e94eb688d`

`test.patch` now contains only the 16-method additive lifecycle class and the
harness. `SetOperationTest` is absent from the selected base lane, eliminating
the protected p2p node and participant/verifier merge collision. The reference
solution patch owns the clean repository regression update because direct
A-not-B construction necessarily invalidates the pristine expect-exception
method. There is no conditional legacy acceptance, challenge-history comment,
or runtime test rewrite.

The malformed-state cell is now independently discriminating. M18 first
survived 16/16 when hash-range validation masked a missing theta check. The
final zero-retained estimation fixture kills M18, while M19 separately proves
that zero, out-of-theta, and duplicate retained hashes are rejected when the
implementation uses a locatable standard raw-long payload. Both fail exactly
`commonPreambleFamilyVersionAndEmptyConsistencyAreValidated`; alternative
encodings are not rejected when their hashes cannot be located. The exact
mutation outcome is 19/19 killed.

Final environment results are pristine 82/82 base with 16/16 focused
behavioral failures, reference 82/82 and 16/16, pristine complete 2,279/2,279,
and reference complete 2,295/2,295. The four mandatory compatible solver
patches pass both lanes; the fifth raw patch is 14/16 on the final suite,
missing generic short-header normalization and duplicate-hash rejection.
Observed compatibility replay is therefore 4/5,
exactly matching the 4/5 pre-change forecast. This is not successful difficulty
hardening: 80% is above the accepted band, and the fresh-calibration expectation
remains approximately 7–9/10. Fresh Level 3 calibration is 0/10 until a new
exact-version batch is run.
