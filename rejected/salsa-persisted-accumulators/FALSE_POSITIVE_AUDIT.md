# False-positive audit - Salsa persisted accumulator outputs

Status: `pass; exact immutable version; calibration remains 0/10`.

Repository pin: `81496d19d42c9d6f4bab876d1f2ac9941ec8992f`.

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `c8471d8bfe9ccb8857fbaf34e98c82ff7a4849bf6923a2a7735077c57dd65180` |
| `test.patch` | `955efec5c24d26c967040847e6d31261db2c8e64e306fdf43135c7e7c2b8a0af` |
| `solution.patch` | `3d241b5ed9c16334474ac02917757a51fc613932130ab62575a6ffe8d8af1201` |
| `Dockerfile` | `ecb18013b3ce715be5e7907ac5736af9f7cd97f5e5b7751a8311d5ab54351f24` |

## Requirement-to-strongest-test map

| Participant-facing rule | Strongest focused behavior |
| --- | --- |
| Persisted accumulator annotation | Three `#[salsa::accumulator(persist...)]` types compile and participate in a real round trip. |
| Default and custom codecs | `Diagnostic` uses derives; non-serde `Metric` can round-trip only if its supplied `+41`/`-41` hooks are invoked. |
| Direct restored values without producer execution | Fresh `leaf::accumulated` returns two diagnostics and one metric after restore with no `WillExecute`. |
| Transitive restored caller/callee values without execution | The fixture's first accumulated lookup is `root::accumulated` over a restored `root -> leaf` graph; values and cached result are checked with no execution. |
| Type separation, order, and duplicates | Separate diagnostic and metric vectors are asserted; two equal diagnostic entries must remain at indices 0 and 1. |
| Empty persisted type | `Unused` is registered but never produced and must return an empty vector. |
| Ordinary accumulators have no serde requirement | `Ephemeral(NotSerde)` compiles under the same persistence-enabled build. |
| Solely non-persisted producers remain unchanged | No new persistence behavior is asserted for that branch; existing accumulator and feature regressions remain in the upstream suite. |
| No required byte layout | The focused test never reads or compares serialized bytes. |

## Construction method

Mutants were derived from exact upstream branches and the reference seams
identified in `DESIGN.md`: procedural option plumbing, generated codecs,
type-erased accumulated storage, revision serialization, and accumulated graph
traversal. Each mutation was applied alone to a fresh exact-pin reference tree.

Every run used the gated image with networking disabled, a read-only source
mount, UID/GID 10001, an image-local lockfile, and writable temporary target
storage. Each mutant first ran the unchanged base selection
(`persistence`, `persistence_never_change`, and
`tracked-struct-entries-persistence`), then the focused test. Compilation or
discovery failures were inspected before classification.

## Actionable trials

| ID | Isolated mutation | Why plausible | Base | Focused result |
| --- | --- | --- | ---: | --- |
| M1 | Restore the original `serde(skip)` on `QueryRevisionsExtraInner.accumulated`. | The repository already skipped this type-erased map; macro-only implementations can leave it untouched. | 7/7 | 0/1: restored diagnostics absent |
| M2 | Serialize `accumulated_inputs` as its default empty state while preserving direct maps. | Direct storage and transitive reachability are independent repository fields. | 7/7 | 0/1: outer query cannot traverse to the leaf |
| M3 | Use the old `view_caster().downcast_unchecked` plus `refresh_memo` path for every traversed ingredient. | It is the smallest reuse of existing live-database accumulation code after adding serialized fields. | 7/7 | 0/1: fresh transitive child access panics at the view boundary |
| M4 | Accept custom codec syntax but always generate default serde calls. | Parser-only support and declared-type-only fixes are common trajectory shortcuts. | 7/7 | 0/1: consumer compile reports missing serde traits for `Metric` |
| M5 | Mark every accumulator persistable and generate default codecs for ordinary types. | A global serde-bound implementation is simpler than preserving the opt-in boundary. | 7/7 | 0/1: consumer compile reports missing serde traits for `Ephemeral` |
| M6 | Deduplicate each serialized accumulator vector. | A set-like or deduplicating carrier is a plausible replacement for an erased value collection. | 7/7 | 0/1: duplicate diagnostic count changes |
| M7 | Serialize only the first persistable accumulated type in each map. | A hard-coded or single-erased-bucket implementation can appear correct with one accumulator type. | 7/7 | 0/1: one public accumulator type is absent |

All seven mutations compile far enough to pass the existing 7/7 base lane.
M4 and M5 are intentionally rejected when the external consumer instantiates
the invalid generated API; those are participant type-system failures, not
production-crate or harness startup failures.

## Actionable predecessor survivor and correction

The initial fixture performed its direct lookup before its transitive lookup.
During the disposable reference prototype, the old child-refresh architecture
could work after direct access registered the required view globally, while the
same transitive lookup in a fresh process state panicked. That made ordering a
real false-positive path rather than a speculative symmetry case.

The black-box correction moved the transitive round trip before every direct
accumulated lookup. It is public, distinct, reference-passing, M3-failing, and
still fails on pristine upstream. `test.patch` changed, so the predecessor
environment verdict was discarded; Phase A, Phase B, gap analysis, fairness
analysis, and this mutation audit all restarted for the new hash.

No mutant survives the corrected focused test. Consequently there is no
current focused-suite survivor to carry into the complete pre-existing suite.
For positive compatibility evidence, the exact reference passes formatting,
both clippy lanes, 291/291 persistence/default tests including the focused
node, 19/19 macros-only tests, and doctests.

## Rejected and non-actionable trials

- Exact JSON keys, map order, and encoded payload fragments were rejected
  because the prompt expressly permits any serialized layout.
- Old-payload compatibility was rejected because Salsa's experimental
  persistence feature and this prompt make no compatibility promise.
- A third accumulator type, more unequal values, a wider DAG, and a deeper
  chain repeat already covered ingredient-index, vector, and traversal
  branches without a new repository seam.
- Reversing an arbitrary one-direction-only order predicate was rejected as an
  adversarial symmetry mutation; duplicate retention and ordinary production
  order are already categorical.
- Arbitrary corrupt bytes, serialization-size limits, and short deadlines have
  no participant-facing or stable repository provenance.
- New semantics for accumulators produced only by non-persisted intermediates
  were rejected because the task explicitly leaves that upstream behavior
  unchanged and repository flattening does not establish one required policy.

## Result

The corrected exact-version suite has zero survivors in the attempted seven
repository-grounded mutation families. This is evidence for those families,
not proof that false positives are impossible. No calibration result or solver
patch was available to replay, and none is inferred. Any artifact or evaluator
change invalidates this audit and resets the problem to a fresh 0/10 version.
