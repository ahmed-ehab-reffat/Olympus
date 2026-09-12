# DESIGN - Salsa persisted accumulator outputs

Status: `rejected as previously implemented; archived at 0/10 on 2026-08-15`.

Repository: `salsa-rs/salsa` at
`81496d19d42c9d6f4bab876d1f2ac9941ec8992f` (default branch `master`,
2026-08-14).

## Candidate contract and repository evidence

Salsa's opt-in `persistence` feature serializes inputs, interned and tracked
structs, and memoized outputs for items marked `persist`. Accumulators are
memoized side-channel outputs, but the current implementation explicitly drops
both the type-erased `AccumulatedMap` and the `accumulated_inputs` reachability
bit during serialization. The accumulator macro likewise rejects `persist` and
contains the matching TODO.

The escalation evaluates a repository-native extension:

- allow `#[salsa::accumulator(persist)]`, including the same optional custom
  serializer/deserializer paths accepted by other persisted Salsa values;
- serialize values accumulated directly by a persisted tracked query and
  rebuild their registered accumulator type on deserialization;
- preserve stored order, multiplicity, and separation between multiple
  persisted accumulator types;
- restore the transitive accumulated-output reachability needed by
  `tracked_fn::accumulated`, so a persisted caller can find values produced by
  persisted callees without re-executing either query; and
- retain the existing opt-in boundary: ordinary accumulators do not acquire a
  `serde` bound merely because the crate was built with `persistence`.

The public behavioral discriminator is cache reuse, not a private byte layout.
After database serialization and deserialization, the existing event stream
must show that eligible tracked queries were reused rather than executed, while
their accumulated values remain observable through the generated public
`accumulated` API. Storing original inputs and recomputing is therefore not an
equivalent implementation of Salsa's existing persistent-cache contract.

The contract does not prescribe JSON field names, a concrete map encoding,
helper names, ownership layout, or whether dynamic dispatch lives on the
accumulator ingredient or on an erased accumulated-value object. Compatibility
with old persistence payloads is not claimed by the experimental upstream
feature and is not added here.

## Trajectory-informed startup gate

Before any `test.patch` work, `PROBLEM_DESIGN.md` was read and local history was
searched through `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, `problems/`, and `archive/` for Salsa,
accumulators, persisted side-channel outputs, snapshots, checkpoints,
serialization, restore, and replay. The only pre-existing Salsa path was an
empty `candidates/salsa-persisted-accumulators/` placeholder; no Salsa dossier,
solver run, or raw Salsa trajectory exists. This absence is recorded rather
than replaced with invented domain evidence.

The closest compact records were reviewed:

- `archive/calyx-cider-checkpoints/` rejects a checkpoint whose observable
  state can be rebuilt from original inputs plus a cycle count, and rejects a
  nondeterministic redesign because a transcript can replay prior observations.
- `problems/sqlsync-observed-sync-state/` shows that a persistence marker or
  declared public type is insufficient when the runtime carrier drops state or
  changes representation.
- `problems/rmk-portable-configuration-snapshot/` shows that typed snapshot
  restoration must retain distinct producer stages and legitimate alternative
  serializer architectures without prescribing their internal layout.

Representative raw SQLSync trajectories were then inspected directly from
`archive/sqlsync-observed-sync-state/agent-runs.tar.gz`, including each selected
trajectory record, evaluator record, solution diff, and final report:

| Evidence role | Raw member | Outcome | Architecture and decisive behavior |
|---|---|---|---|
| Analogical legitimate pass | `agent-runs10/Nova_Nova_1` | legitimate pass | Changed 13 production files at +492/-28. It carried receipt and watermark state through Rust, Wasm, worker, React, and Solid layers and converted the runtime LSN to a lossless decimal-string carrier rather than only relabeling its type. The ATIF record contains 4 top-level steps and 76 tool calls. |
| Analogical near-pass | `agent-runs10/Nova_Nova_3` | baseline pass; focused failure at the runtime representation boundary | Changed 12 production files at +519/-15. It declared a lossless TypeScript type but allowed the Rust `u64` to cross the Wasm boundary as a JavaScript number. The ATIF record contains 4 top-level steps and 65 tool calls. |
| Analogical broad failure | `agent-runs10/Nova_Nova_10` | baseline pass; broad subscription-delivery failure | Changed 12 production files at +464/-43. It built most state APIs but did not route later changes to registered handlers, illustrating that reconstructing stored values without restoring the reachability/delivery edge is incomplete. The ATIF record contains 4 top-level steps and 95 tool calls. |

These trajectories provide general carrier and reachability failure families
only. They do not justify copying SQLSync API names, tests, or implementation
choices into Salsa.

The exact upstream repository was cloned and its history inspected. The current
pin has explicit accumulator-persistence TODOs in
`components/salsa-macros/src/accumulator.rs`, `src/zalsa_local.rs`, and the
persistence mapping code. Git history traces them to the initial persistent
caching work and its dependency-flattening follow-up. Exact GitHub issue/PR
search found no open or merged implementation of persisted accumulators; PR
#967 is the already-merged general persistence prototype. The repository is
active, dual Apache-2.0/MIT licensed, and has 302 Rust test attributes across
148 files. It does not commit a root `Cargo.lock`, so the environment image must
resolve once during image construction and prove every evaluator run offline.

## Discriminator ledger

| Observed solver or repository behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| The macro currently accepts no accumulator options. | Add parser acceptance but never connect it to runtime persistence. | `persist` changes the accumulator's persistence capability and ordinary accumulators remain unbounded by `serde`. | Compile one persisted accumulator, one custom-codec accumulator, and one ordinary non-serializable accumulator under the combined feature set. | Macro/type capability | Accepts any generated trait plumbing and custom-codec architecture. |
| `AccumulatedMap` stores `Box<dyn AnyAccumulated>` keyed by ingredient index. | Derive `Serialize` on a wrapper or hard-code one concrete accumulator. | Every registered persisted accumulator type can serialize and rebuild its own erased value vector. | Round-trip two distinct accumulator types with interleaved production, duplicates, and empty peers. | Type erasure and registry dispatch | Checks public values and order, not the erased-object representation or JSON shape. |
| `QueryRevisionsExtraInner.accumulated` is explicitly `serde(skip)`. | Restore the memoized primary output but silently lose direct side-channel values. | Direct accumulated values of an eligible memo survive restore exactly. | Query once, round-trip the database, call `accumulated`, and reject any `WillExecute` event. | Direct memo output persistence | Recompute, eager copy, per-ingredient codecs, and a generic erased serializer are distinguished only by the existing cache-hit contract. |
| `QueryRevisions.accumulated_inputs` is reset to `Empty`. | Persist direct values but lose traversal through a restored caller. | A persisted caller retains reachability to accumulated values produced by a persisted callee. | Nested persisted queries, round-trip, query through the outer generated `accumulated` API, and observe no execution. | Transitive reachability | Does not prescribe a bit, edge cache, or traversal strategy. |
| Persistence flattens non-persisted query dependencies to their persistable leaves. | Treat a flattened computation edge as if it also preserved side-channel output. | No contract is assumed yet for accumulated values produced solely by a non-persisted intermediate query. | Prototype the branch before deciding whether to reject serialization, persist a projection, or explicitly exclude it. | Producer-mode boundary | Prevents hidden tests from inventing a private policy for an unresolved repository case. |
| Accumulation preserves execution order and de-duplicates dependency visits, not values. | Serialize a set, sort by payload, or merge types. | Per-type accumulated order and multiplicity match the uninterrupted database. | Repeated equal values and two accumulator types across a small persisted DAG. | Ordering/multiplicity/type separation | Reuses documented accumulator semantics without requiring map iteration order. |
| SQLSync near-pass changed only the declared type. | Generate `Serialize` bounds but omit actual custom serializer invocation or typed deserialization. | Custom codec hooks affect the real persisted carrier in both directions. | A value lacking ordinary serde support round-trips only through supplied functions. | Runtime codec plumbing | Mirrors existing Salsa `persist(serialize=..., deserialize=...)` behavior and avoids requiring derives. |
| Calyx replay reproduced public state but not a repository promise of stored execution reuse. | Recompute queries from restored inputs after load. | Eligible persisted memoized queries are not executed merely to recover their accumulators. | Existing public event logger observes cache reuse after deserialization. | Persistence versus reconstruction | Uses Salsa's own persistence semantics; no timing, size, or private-state requirement is introduced. |

## Pre-authoring stop conditions

No hidden patch will be authored until Phase A passes at this exact pin and a
disposable prototype proves all of the following without a private encoding
requirement:

1. direct persisted accumulator values round-trip through a fresh database;
2. nested persisted-query reachability is restored without execution;
3. ordinary non-persisted accumulators still compile with non-serde payloads;
4. custom codec paths are implementable through the existing macro pattern;
5. the solution crosses enough independent macro/runtime/persistence seams to
   avoid a thin one-file convergence task; and
6. the non-persisted-intermediate branch is either repository-grounded or kept
   explicitly outside the contract.

If deterministic recomputation is the only way to pass, if the public event
stream cannot distinguish it, if persisted output requires one private JSON
layout, or if two honest implementations converge below the intended scope,
the escalation stops before `test.patch`.

## Prototype and reference result

The disposable prototype satisfied all six pre-authoring stop conditions. The
reference adds 235 lines and removes 28 lines across 11 production and manifest
files. It crosses:

- procedural option acceptance and custom codec path generation;
- the generated accumulator trait capability and type-specific codecs;
- type-erased value-vector serialization and lazy restoration;
- revision-extra accumulated maps;
- transitive accumulated-input reachability; and
- type-erased query traversal that can read a restored child memo without
  requiring a previously registered child database view.

The public fixture uses default and custom-codec persisted accumulators,
multiple types, duplicate values, an empty persisted peer, an ordinary
non-serde accumulator, direct and transitive restored queries, and Salsa's
event callback to rule out recomputation. The transitive scenario executes
first in process state; this order is intentional because the prototype showed
that a prior direct access could mask an invalid child view-casting path.

No new behavior is required for values produced solely by non-persisted tracked
queries. The unresolved flattening policy therefore remains outside the task,
as required by the ledger.

## Exact gate and mutation verdict

The trajectory-informed startup gate, both environment phases, gap analysis,
fairness analysis, and false-positive audit pass for the artifact hashes
recorded in `ENVIRONMENT.md`. Exact observed results are:

- pristine Phase A: formatting and both clippy lanes pass, 290/290
  persistence/default tests, 19/19 macros-only tests, and passing doctests;
- evaluator composition: pristine base 7/7 and new 0/1 at the real feature
  testcase; reference base 7/7 and new 1/1 with matching JUnit identity;
- complete reference validation: 291/291 persistence/default tests including
  the focused node, 19/19 macros-only tests, both clippy lanes, formatting, and
  doctests; and
- false-positive isolation: seven plausible mutants each pass the existing
  7/7 base lane and fail the focused test at their intended behavioral or
  consumer-compilation boundary.

The seven families drop the accumulated map, drop transitive reachability,
reuse the old child refresh/view path, ignore custom codecs, impose persistence
on ordinary accumulators, deduplicate values, or serialize only one accumulator
type. No current mutant survives.

The task remained uncalibrated at 0/10. The user subsequently reported an
external rejection because the idea had been implemented before. That
disposition closes the task despite its passing local gates. Preserve this
record to prevent rediscovery; do not resubmit, reword, or add discriminators
to rescue the same persisted-accumulator feature.
