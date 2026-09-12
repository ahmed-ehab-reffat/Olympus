# Gap analysis - Salsa persisted accumulator outputs

Verdict: `pass`.

This audit is bound to `salsa-rs/salsa` commit
`81496d19d42c9d6f4bab876d1f2ac9941ec8992f` and the following immutable
submission artifacts:

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `c8471d8bfe9ccb8857fbaf34e98c82ff7a4849bf6923a2a7735077c57dd65180` |
| `test.patch` | `955efec5c24d26c967040847e6d31261db2c8e64e306fdf43135c7e7c2b8a0af` |
| `solution.patch` | `3d241b5ed9c16334474ac02917757a51fc613932130ab62575a6ffe8d8af1201` |
| `Dockerfile` | `ecb18013b3ce715be5e7907ac5736af9f7cd97f5e5b7751a8311d5ab54351f24` |

## Atomic requirement map

The focused test is a host Rust test that creates an offline temporary consumer
crate and executes its public Salsa APIs. Assertions are against consumer-visible
values and Salsa's public event hook, never the serialized representation.

| ID | Public obligation | Strongest oracle | Coverage |
| --- | --- | --- | --- |
| R1 | `#[salsa::accumulator(persist)]` is accepted. | The temporary consumer compiles three persisted accumulator declarations and runs them. | direct compile and behavior |
| R2 | `persist(serialize = ..., deserialize = ...)` has the same hook semantics as other persisted values. | `Metric` deliberately lacks serde derives; its asymmetric `+41`/`-41` codec round-trips the original value. | direct |
| R3 | Direct values produced by a persisted tracked query survive database serialization and deserialization. | `leaf::accumulated` returns the two restored diagnostics and metric after restore. | direct |
| R4 | Restored values do not require re-executing an eligible persisted producer. | The database event stream is cleared after restore and must contain no `WillExecute` event after query and accumulated access. | direct |
| R5 | A restored persisted caller reaches values produced by a restored persisted callee. | The transitive case runs first in the fixture, restores `root -> leaf`, and reads the leaf values through `root::accumulated` without execution. | direct |
| R6 | Accumulator types remain separate and preserve production order and duplicate values. | Two distinct types are queried; the diagnostic vector contains two equal values at indices 0 and 1 and the metric vector contains only its own value. | direct |
| R7 | An eligible persisted accumulator with no produced values remains empty. | `leaf::accumulated::<Unused>` is empty after restore. | direct |
| R8 | An ordinary accumulator remains usable with a payload that has no serde implementation. | `Ephemeral(NotSerde)` compiles in the same persistence-enabled consumer. | direct compile |
| R9 | Existing behavior for values produced solely by non-persisted tracked queries is unchanged. | The prompt explicitly preserves, rather than extends, this branch; the unchanged upstream accumulator suite and normal-feature clippy lane pass. | indirect regression |
| R10 | No serialization byte layout is prescribed. | The test uses only `Database::as_serialize`, `Database::deserialize`, and public query APIs; it never inspects JSON keys or bytes. | direct structural audit |

The fixture also serializes the restored database after lazily materializing
direct accumulator values. This verifies the ordinary public lifecycle of a
deserialized database and prevents a one-shot restoration carrier from making
the database unusable for its next supported serialization call.

## Repository-grounded dimension matrix

| Dimension | Distinct equivalence classes | Coverage and grouping rationale |
| --- | --- | --- |
| Accumulator capability | persisted/default codec; persisted/custom codec; persisted/unused; ordinary/non-serde | All four are separate macro/runtime branches and are exercised. |
| Query topology | direct producer; persisted caller to persisted callee | Both are exercised. The transitive case is first so no prior direct type registration can initialize its child path. Greater depth and fan-out reuse the same repository DFS and persistence edge representation and add no independent branch. |
| Restore lifecycle | live production; serialize; fresh database deserialize; cached query access; accumulated access; serialize after lazy materialization | Every state is crossed in the fixture. A second deserialize of the last serialization would repeat the same codec and memo branches and was not added as another fixture. |
| Value cardinality | empty; one value; repeated equal values | `Unused`, `Metric`, and `Diagnostic` cover these classes. More unequal values do not cross a separate storage branch. |
| Type family | two independently registered accumulator ingredients | `Diagnostic` and `Metric` prove type separation. Additional concrete types repeat the ingredient-index path. |
| Codec direction | generated default encode/decode; supplied encode/decode | Both directions are forced by a round trip; the custom type cannot fall back to serde. |
| Cache behavior | legitimate reuse; recomputation | Reuse is observed deterministically through absence of `WillExecute` after a known successful initial execution. |
| Feature surface | normal workspace; persistence workspace; macros-only no-default-features | Exact Phase A runs formatting, both clippy surfaces, 290 persistence/default tests, 19 macros-only tests, and doctests. The focused API is intentionally persistence-enabled. |
| Producer mode | persisted tracked producer; solely non-persisted tracked producer | The former is the feature. The latter is explicitly unchanged and remains under upstream regression coverage; inventing flattening semantics would exceed the prompt and repository evidence. |

## Gap challenges and mutation results

Seven solution-derived mutants were built and executed offline as UID 10001
with read-only source. Each passes the unchanged 7-test persistence lane, so
the focused rejection is isolated from existing tests.

| Mutant | Plausible omission | Base | Focused result | Strongest discriminator |
| --- | --- | ---: | --- | --- |
| M1 `drop-map` | Accept the macro and persist memo outputs, but continue skipping the accumulated value map. | 7/7 | fail | restored transitive diagnostic count |
| M2 `drop-reachability` | Persist direct maps but serialize the `accumulated_inputs` state as empty. | 7/7 | fail | outer `root::accumulated` cannot reach the leaf |
| M3 `refresh-child` | Restore maps and reachability but use the old view-casting refresh path for every traversed child. | 7/7 | fail | transitive-first access panics at the child view boundary |
| M4 `ignore-codec` | Parse custom hook names but always generate default serde calls. | 7/7 | fail | consumer compile rejects non-serde `Metric` |
| M5 `persist-all` | Treat every accumulator as persisted and impose default serde bounds globally. | 7/7 | fail | consumer compile rejects `Ephemeral(NotSerde)` |
| M6 `dedup-values` | Serialize each per-type vector after set-like duplicate collapse. | 7/7 | fail | duplicate diagnostic count/order |
| M7 `single-type` | Serialize only the first persistable erased accumulator bucket. | 7/7 | fail | one of the two public accumulator results is absent |

No current mutant survives the focused suite, so there is no meaningful
focused-suite survivor to run through the complete pre-existing suite. The
reference itself passes the complete exact-version validation: formatting,
both clippy lanes, 291/291 persistence/default tests including the focused
test, 19/19 macros-only tests, and doctests.

## Admitted and rejected probes

One probe correction was admitted. During prototype review, direct access ran
before transitive access in the same process. Salsa's global view registration
could let M3 pass after the direct call even though a fresh transitive lookup
panicked. The transitive case was moved first, the predecessor verdict was
invalidated, and both environment phases and all audits restarted on the new
hash.

The following additions were rejected:

- A three-level chain, wider DAG, and extra persisted accumulator types repeat
  the already exercised DFS, ingredient-index, and per-value vector branches.
- Exact JSON fields, map order, payload strings, and old-snapshot compatibility
  are not public requirements and would prescribe the reference encoding.
- Values produced only by a non-persisted intermediate query have an explicit
  unchanged boundary and unresolved upstream flattening policy; requiring a
  new projection would invent behavior.
- Missing or duplicated custom-hook syntax diagnostics are handled by the
  existing shared option parser. No plausible runtime omission survived that
  would justify hidden error-message or compile-fail snapshots.
- Arbitrarily malformed persistence bytes and short performance deadlines are
  unrelated to the requested feature.

## Verdict

Every atomic public requirement maps to a direct public-boundary oracle or an
explicit unchanged regression surface. No actionable repository-grounded gap
survived the corrected focused suite. This exact immutable version passes gap
analysis; any submission-artifact or evaluator-path change invalidates the
verdict.
