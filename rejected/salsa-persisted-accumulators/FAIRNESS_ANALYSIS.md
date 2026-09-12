# Fairness analysis - Salsa persisted accumulator outputs

Verdict: `pass`.

This audit covers `salsa-rs/salsa` commit
`81496d19d42c9d6f4bab876d1f2ac9941ec8992f` and exactly these artifacts:

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `c8471d8bfe9ccb8857fbaf34e98c82ff7a4849bf6923a2a7735077c57dd65180` |
| `test.patch` | `955efec5c24d26c967040847e6d31261db2c8e64e306fdf43135c7e7c2b8a0af` |
| `solution.patch` | `3d241b5ed9c16334474ac02917757a51fc613932130ab62575a6ffe8d8af1201` |
| `Dockerfile` | `ecb18013b3ce715be5e7907ac5736af9f7cd97f5e5b7751a8311d5ab54351f24` |

## Rejection predicates and provenance

| ID | Rejection predicate | Provenance | Fairness result |
| --- | --- | --- | --- |
| P1 | A persistence-enabled consumer accepts `#[salsa::accumulator(persist)]`. | Explicit first paragraph of `meta.md`; the upstream macro contains the matching unsupported TODO. | fair |
| P2 | Default-codec persisted accumulators round-trip through Salsa's public database serialization APIs. | Explicit retention requirement and the repository's existing generic serde persistence API. | fair |
| P3 | Supplied `serialize` and `deserialize` functions are actually used, so `Metric` needs no serde derives. | Explicit “same semantics as other persisted Salsa values” requirement; existing persisted macro options expose these generic serde hooks. | fair |
| P4 | An ordinary `Ephemeral(NotSerde)` accumulator compiles while persistence is enabled. | Explicit final paragraph of `meta.md` and Salsa's existing opt-in accumulator semantics. | fair |
| P5 | A restored persisted `root` returns its cached primary value and exposes values produced by persisted `leaf`. | Explicit direct and caller/callee restoration requirements; generated tracked-query APIs are public repository behavior. | fair |
| P6 | Per-type diagnostic values retain two equal entries in production order. | Explicit type separation, order, and duplicate-value requirements. | fair |
| P7 | The metric result is separate from diagnostics and retains its original value after its custom codec. | Explicit type separation and custom-hook semantics. | fair |
| P8 | The declared-but-unused persisted accumulator returns an empty result. | Stable generated `accumulated::<A>` API behavior and the ordinary meaning of retaining produced values; the test does not require a serialized empty bucket. | fair |
| P9 | No `WillExecute` event appears after clearing events on the restored database and accessing eligible cached results. | Explicit “without re-executing an eligible persisted producer” requirement; Salsa's public event callback and `EventKind::WillExecute` are the repository-native observation boundary. | fair |
| P10 | A restored database remains serializable after its direct accumulated values have been materialized. | A database created by the public deserialize operation remains an ordinary database accepted by the existing public `as_serialize` operation. No second payload layout is asserted. | fair |
| P11 | The unchanged base lane's seven persistence tests continue to pass. | Concrete pre-existing repository behavior on the feature surface touched by the task. | fair |
| P12 | The test harness produces the real nextest/JUnit testcase identity and a nonzero result on failure. | Evaluator composition requirements, not product behavior; Phase B proves the pristine failure reaches the real test and reference uses the identical node. | fair |

## Implementation freedom preserved

The suite does not inspect serialized bytes, JSON object keys, field order,
ingredient indices, private maps, helper functions, file layout, or candidate
APIs. JSON is merely one normal serde backend supplied to Salsa's existing
generic public serializer; candidates remain free to choose their internal
payload representation and the task explicitly disclaims a byte layout.

Candidates may use eager or lazy reconstruction, a registry, erased-value
dispatch, ingredient-level dispatch, per-query side tables, or another safe
design. They may store a reachability bit, derive reachability from restored
edges, or traverse another equivalent public graph. The tests observe only
typed values, order/multiplicity, and absence of query execution.

No assertion requires an exact error message, allocation count, serialized
size, algorithm, map iteration order, helper name, module placement, thread
schedule, retry count, or product latency. The fixture contains no malformed
input and no internal timeout.

## Determinism and lifecycle review

All checks are synchronous. Each database is populated by a completed initial
query call, serialized, deserialized into a fresh `Db`, and has its event vector
cleared before restored access. The no-execution predicate is therefore paired
with positive progress: the initial query result, restored primary result, and
restored accumulated values must all be observed. It cannot pass because the
implementation did nothing or because an asynchronous writer was late.

The transitive scenario runs before direct accumulated access. This was a
fairness and false-positive correction: direct-first ordering could initialize
global view state and make the suite favor an old view-casting architecture.
Moving the transitive case first requires only correct fresh-database behavior
and does not prescribe how that behavior is implemented.

The solely non-persisted-producer branch is not tested for new persistence.
The prompt says its existing behavior is unchanged, avoiding an undocumented
policy for Salsa's dependency-flattening boundary.

## Harness and environment fairness

The Docker environment pins Salsa's declared Rust 1.85 MSRV and
`cargo-nextest` 0.9.97, resolves dependencies only while the image is built,
and executes with `--network none`, a read-only root and source, and UID/GID
10001. Runtime scratch, Cargo target, nextest store, and the temporary consumer
are placed in writable temporary storage. The source checkout itself need not
be writable.

The root workspace intentionally has no committed `Cargo.lock`; the Dockerfile
first rejects a contaminated build context, then generates and fetches one in
the image. Every evaluator Cargo command is `--offline --locked`. Phase A
passes formatting, normal and persistence clippy, 290/290
persistence/default tests, 19/19 macros-only tests, and doctests. Phase B
reproduces baseline and reference patch order and matches real JUnit testcase
identity.

The temporary consumer pins versions already present in the image lock/cache
and uses only a local path dependency on the candidate Salsa tree. A compile
failure inside that consumer is reported inside the real host test, separating
participant API/type failures from nextest discovery or environment startup.

## Legitimate architecture replay

The exact reference passes 291/291 persistence/default tests including the
focused node, 19/19 macros-only tests, both clippy lanes, formatting, and
doctests. No independent solver patch exists because calibration is 0/10, so
there is no materially different legitimate implementation to replay yet. This
absence is recorded and is not treated as positive evidence. The black-box
suite was additionally reviewed against plausible eager/lazy and
ingredient/erased-dispatch designs; none is excluded by a private assertion.

## Corrected and rejected fairness concerns

- Corrected: direct-first execution could privilege an implementation that
  relies on prior global type-view registration. Transitive-first execution
  removes the privilege; the old verdict was invalidated and all gates rerun.
- Rejected: using JSON does not prescribe Salsa's representation. It invokes
  the existing serializer abstraction and never examines the resulting text.
- Rejected: duplicate order is not an accidental container expectation; it is
  explicitly participant-facing and matches existing accumulator behavior.
- Rejected: `WillExecute` is not a private timing proxy. It is Salsa's public,
  deterministic event for the exact forbidden behavior.
- Rejected: requiring a deserialized database to serialize again does not
  mandate lazy storage; it preserves an existing public operation on a valid
  database lifecycle state.
- Rejected: no negative byte corpus, scheduler silence, network service,
  writable home, privileged UID, or unstated feature combination is used.

## Verdict

Every logically distinct rejection predicate is grounded in the public prompt,
discoverable Salsa behavior, or evaluator correctness. No unresolved or
architecture-prescribing predicate remains. Fairness passes only for the exact
immutable version above; any submission-artifact or evaluator-path change
requires a fresh audit.
