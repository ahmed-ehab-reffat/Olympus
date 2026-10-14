# DESIGN.md - pict-engine-negative-values

## Phase 1 - repo understanding

**Architecture.** microsoft/pict (C++, MIT, 1,466 stars) is a combinatorial (t-way) test-case
generator. `cli/` parses a model file (`mparser`), a constraint language (`ctokenizer`, `cparser`)
and turns constraints into exclusions (`gcdexcl`); `cli/gcdmodel.cpp` translates the parsed model
into engine objects and `cli/gcd.cpp` drives generation and prints rows. `api/` is the engine
(`pictcore`): `Parameter` (value count, order, weights), `Model` (a tree: each model holds
parameters and child models; a child's result rows become one `PseudoParameter` of its parent),
`Task` (root model, exclusion set, seeds; `PrepareForGeneration` derives exclusions with
`ExclusionDeriver` and pushes each to the lowest model that holds all its parameters),
`Model::gcd` (greedy covering loop), and the C API `pictapi.h/.cpp` which exposes index-only
handles. The CLI does not go through the C API; it builds `pictcore` objects directly.

**Five subsystems.** (1) model/constraint front end `cli/mparser,ctokenizer,cparser`; (2)
constraint to exclusion translation `cli/gcdexcl`; (3) CLI generation driver + output
`cli/gcd,gcdmodel,model`; (4) engine core `api/model,combination,parameter,deriver,exclusion,task`;
(5) C API `api/pictapi`.

**Entanglement zones.** (a) `Model::generateMixedOrder` + `mapExclusionsToPseudoParameters` +
`mapRowSeedsToPseudoParameters` + `resolvePseudoParams` (child rows as pseudo values, exclusions
and seeds rewritten onto them); (b) `Task::PrepareForGeneration` + deriver (exclusion placement,
back-pointers into parameters); (c) CLI `gcd.cpp`/`gcdmodel.cpp` (two-run negative testing,
per-child order fixing, result translation).

**Tests.** `test/test.pl` (perl) runs ~587 CLI commands from `test/*/.tests`, checking only the
exit code and that re-seeding with the output reproduces the same row count. The committed
`rel-baseline.log` is not diffed by anything (and differs heavily from a fresh run). No API tests
exist; `api-usage/pictapi-sample.cpp` is the only API client. New tests follow the tippecanoe
pattern: a python runner emitting JUnit, API tests through `ctypes` on the repo's own
`make libpict.so` target, CLI tests through subprocess.

## Phase 2 - existing PR / publicly solved

- Canonical org: `microsoft/pict` (no redirect).
- PR search (all states): negative, submodel, sub-model, invalid, out-of-range, masking, seed, `~`,
  IsPositive, PictAddParameter, api, PictSet -> docs (#150 ISNEGATIVE docs), perf (#160), ARM64,
  2018 weights fix (#28), 2021 obsolete-STL cleanup (#71, diff read: no negativity). Nothing
  touches negativity in `api/` or the CLI two-run code.
- `git log -S egative -- api/` is empty: the engine never had negative values (not a removed
  capability).
- Issues: #44 (open, reproduced), #107 (maintainer: "It is just sets of indexes" - a per-index flag
  fits), #9 and #18 (maintainer explains negative semantics, declines conditional-negative
  syntax - not our lane), #131 (API column order question, open), #123/#134 (PictGenerate must
  replace earlier results - repeat generation is intended).
- Fork scan (every fork pushed since 2025-06, every non-upstream branch compared): danfiedler
  copilot/* branches are docs/CI plus a seed-contract doc note; Spruill-1 branches are #160 perf
  work; assuiedmilan/pict main is a CRLF whole-file rewrite (api files carry 0 negativity hits);
  takeyaqa/pict-wasm is a TS wrapper around the CLI. No lane work.
- Base = upstream main HEAD ab76c254 (2026-09-08); nothing after it.

## Phase 3 - candidate and gates

Lane (from hunt 2026-09-23-G): negative values as an engine/C API capability, honoured through
child models and seeds, with the CLI getting the same guarantees.

PICK-FILTER: gate 1 (F2P): the API has no way to mark a value negative; the CLI drops negative
values of one child when a sibling's negative-run rows all carry a negative (#44, reproduced), and
seeded negatives vanish the same way, crashing on the two-valued variant. Gate 5 (cold): no commit
has touched negativity since the initial import; the 12-month stream is perf/docs/CI. Gate 6:
reproduced on base. Gate 7/7b: no local collision (problems/, rejected/, approved-problems/, LEDGER
has only this pick); canonical-org PR diff scan clean. Gate 8: behaviour defined by `doc/pict.md`
"Negative Testing" (one out-of-range value per test case; every invalid value combined with valid
values) and by the maintainer (#9). Gate 9: `make test` verdicts identical over 3 runs (log text
differs only in /r seeds and timing). Gate 10: 0 of 6 pict submissions.

TOO-EASY guard: (1) not one rule at many sites - the work is a two-phase driver, state
save/restore across a generation that rewrites the model tree, partner rows for child models,
unique parameter identity for exclusions across models, row filtering, a result-layout API;
(2) not single-subsystem: engine + C API + CLI; (3) the sub-model requirement is stated, the fix
(partner rows) is not; (4) not a port; (5) survives full spelling-out.

Absorption check (sized against the chokepoints, not the surfaces): the core slice measured
**252 human-effective** (hook) across 13 files before any finishing scope, so the lane is not
machinery-absorbed.

## Traps (all reproduced on the reference by mutation or by base behaviour)

| # | Trap | F-id | Axis | Evidence |
|---|---|---|---|---|
| 1 | Porting the CLI two-run template loses a child's negatives when a sibling's negative-phase rows all carry a negative | F-39 (inherited template bug) | coverage through child models | partner-row mutant fails 9 tests; base CLI #44 |
| 2 | One valid partner row per child is not enough: a negative value must meet every valid value of the sibling | F-10 cell (negatives in several children x multi-valued valid partner) | cross-child coverage | single-partner mutant fails only the wide CLI test -> FINISH adds API cells |
| 3 | Masking exclusions across children crash in `ExclusionTermCompare`: the C API numbers parameters per model, so two children share sequences | F-9 family (identity lost between API and engine) | parameter identity | reference crashed on every API child test until sequences became unique |
| 4 | Stale exclusion back-pointers: a second derivation (CLI double prepare, root parameters beside children) asserts in `LinkExclusion` | S3 shared machinery | engine state | reference crashed on the root-parameter test and on ~40 CLI models |
| 5 | Generation rewrites the model tree (root parameters, exclusions, seeds, orders); a second phase or a second `PictGenerate` must start from the original | F-1 / S4 | repeatability | regen-identity test; base sub-model regen already returns different rows |
| 6 | Restoring the tree after generation must not lose the result layout (`PictGetTotalParameterCount`, `PictGetResultParameter`) | S2 composition with #5 | result layout | columns test |
| 7 | Seeds with a negative value under child models, and seeds with two negatives | F-10 (seeded x child) | seeds | base CLI drops them / asserts |
| 8 | Exclusions leaving a parameter only negative values must report an error, not assert | A8 | error path | base asserts in `processExclusions` |

## Cross-product matrix (F-10)

| | flat | children (valid rows present) | children (#44 regime) | nested |
|---|---|---|---|---|
| coverage | api flat x4 | api wide | api two_children + cli issue | api grandchild |
| multi-valued partner | api flat | api wide | cli wide (FINISH: api cell) | FINISH |
| seeds | api flat x2 | api across | api/cli seeded, two-valued | - |
| regenerate | api flat | api wide | FINISH | - |

## Description draft

See meta.md. The #44 symptom is deliberately NOT described (it would point at the template's
flaw); the contract states that the guarantees hold at every level of a model tree.

## FINISH plan (scope to add after the precheck)

- API cells: #44 regime with a multi-valued valid sibling (single-partner mutant), nested #44
  regime, regen on a #44-regime tree, root parameter + #44 child.
- Cross-model user exclusions through the C API (enabled by unique sequences; base asserts in
  `PictAddExclusion`) - one meta sentence + tests.
- `PictDeleteModel` must free every parameter of the tree once the tree is restored after
  generation (today it relies on the root holding them all post-generation).
- CLI: `/o:1` and order-3 child cells, JSON output check, statistics sanity.
- Marking an already negative value again (stated, needs a test).
- Mutation sweep over every hunk, base + new mode.

## Predicted pass rate

15-30%. Main killers: trap 1 (agents port the CLI template, and a self-made child fixture usually
has valid rows, so their own smoke test passes), trap 3 (a crash deep in exclusion ordering),
trap 5/6 interplay.
