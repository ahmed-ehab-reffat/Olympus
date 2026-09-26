# pict-engine-negative-values - feedback

NEXT (human): R10 = R9 meta + test.patch (whole-row test) -> Auto Review, then a FRESH batch (full price).

## R10 (2026-09-26) - Auto Review on R9: Description 3/3, Tests 1/3 (High), Solution 3/3

- T3/T4 High: cross-child checks only projected leaf values; a child is a pseudo-parameter whose values
  are whole child rows. New Suite.assert_whole_rows + test_child_models_combine_as_whole_rows (two_children
  and wide_children, root order 2 with only the two children): child rows are derived from the OUTPUT
  (valid = projections in rows without negatives, negative = projections carrying a negative), then every
  valid x valid pair must appear in a row without negatives and every negative x valid pair in some row.
  Mutant (one partner row per child) -> only this test fails.
- Replay over all 22 saved solutions: both previous full-suite passers (b1 dir 9, b2 dir 4) pass it.
- 35 tests. Clean room 1000/0/4242 green x3.

## R9 (2026-09-26) - re-eval 1/11 (Nova #7) FP-flagged; user chose: precondition in meta

- FP: Nova #7 hangs on a flat model with a starved value (exclusion a=1 & c=1 where c=1 is c's only
  non-negative value); reference returns success. Probe over all 22 saved solutions: 13 succeed, the
  rest abort/hang/error, and BOTH solutions that ever passed the full suite fail it -> a test for it
  would measure 0/22.
- Required coverage for a starved value is ill-defined under the current contract (its positive
  combinations cannot exist), so meta now states the precondition: apart from the generation-error
  case, every non-negative value that the exclusions allow can appear in some row with no negative
  value. Brute-force check: no fixture starves a value (the nested generation-error test is the
  separate "no non-negative value at all" case). Tests and solution unchanged. 397 words.

## R8 (2026-09-25) - batch 2 0/11; Auto Review APPROVED (Tests 2/3, one Medium)

- Nova #7 failed only the lifecycle test, and on a generation abort, not a leak. Cause: my R6 fixture
  exclusion (L1=0, L2=1) where L1=0 is L1's only non-negative value, so L2=1 has no non-negative partner.
  Degenerate case, stated nowhere, tested only by accident inside a deletion test. Fixture now excludes
  (L1=1 negative, L2=2). Lesson: when moving exclusions around, check none uses a parameter's LAST
  non-negative value unless that is the point of the test.
- Auto Review Medium: Tree.fetch checks every cell is in range for its column's parameter.
- Replay: 1/11 (Nova #7 34/34, base clean). Clean room green.

## R7 (2026-09-25) - Auto Review on the R6 cut: Description 3/3, Tests 1/3, Solution 3/3

- T3/T4 High: PictGetResultParameter never checked after a generation with no negative values. New
  test_result_parameters_map_columns_of_a_model_without_negative_values: root + child, no negatives;
  raw-column oracle independent of the getter (distinct value counts 2/3/4/5 identify each column by its
  largest value), handle per column, null at count, count+1, count+100. Mutant (mapping only in the
  negative branch) -> only this test fails. The replay passer (dir 9) and dirs 1, 2 pass it.
- 34 tests. Clean room 1000/0/4242: 588 base pass, 34 fail without / pass with, x3. Solution unchanged (214).

## R6 (2026-09-25) - batch 1 = 0/11, user chose: cut CLI parity + cross-model exclusions

Batch 1 (10 Nova + 1 Vega) 0/11; details in eval-results.md. Every run hit >= 2 independent walls; no
test-only lever produced a pass (nearest: Nova #9 failed only the 4 cross-model user-exclusion tests
but also aborted 9 base tests). Classic gate-round ratchet: R2-R5 each added a surface (cross-model
exclusions, CLI order 3, CLI constraints, CLI seeds, lifecycle) and the batch paid for all of them.

Cut (user decision):
- CLI parity dropped: meta.md CLI paragraph removed, cli/ reverted to base in the solution, the 7 CLI
  tests and cli_negative_8f8ea0.py removed. The CLI-only engine hooks (Task::Generate prepareModel
  callback, task-level combination counters) removed as dead code. Base CLI harness 588/588 with the
  API-only solution.
- Cross-model user exclusions dropped: meta now says each exclusion names parameters of a single
  model; excluded_tree rewritten with exclusions inside inner, middle (new M2) and branch; nested
  generation-error test and the lifecycle client use within-model exclusions.
- Kept: #44 partner-row trap on the API, the inherent sequence collision for masking exclusions
  across children, repeat generation state, lifecycle, header/export checks.
- 33 API tests. Solution 214 human-effective (7 files) - thin margin over the 200 floor.
- Replay of the batch-1 patches on the R6 suite: 1/11 counterfactual pass (dir 9, Nova #2, whose api-only
  changes also keep the base suite clean). Base C API aborts on user exclusions in two child models (a
  pre-existing bug), so user exclusions now sit in one model per tree; meta says so.

## R5 (2026-09-24) - Auto Review: Description 3/3, Tests 1/3, Solution 3/3

- T4 High: nothing checked api/pict.def (the Makefile's ELF link never reads it). New
  test_new_functions_are_listed_in_the_export_definition parses EXPORTS. meta.md now says each new
  function is declared in pictapi.h and listed in api/pict.def (the reviewer called it
  codebase-inferable; stating it keeps the test fair). Mutant: def entries removed -> only that
  test fails.
- T4 Medium: marking an already-negative value again must succeed (python marking test + client
  header check). Mutant with the last-non-negative count checked first -> both fail.
- T4 Medium: CLI repeatability. Standalone would pass on base (deterministic output there too), so
  the constraints and seeded CLI tests now run the same model twice and compare full stdout.
- 40 new tests. Clean room 1000/0/4242: 588 base pass, 40 fail without / pass with, x3.
- Review cycle note: R2-R5 each surfaced a new High T4 gap in an area previous rounds rated fine.
  Pattern: every stated contract clause needs a test on EVERY surface that carries it (C header,
  export manifest, CLI, nested trees), not just the main one.

## R4 (2026-09-24) - Auto Review: Description 3/3, Tests 1/3, Solution 3/3

- T3/T4 lifecycle (High): the allocation balance only ran after PictDeleteModel AND PictDeleteTask,
  so "PictDeleteModel does nothing, PictDeleteTask frees the tree" passed. The client now records
  every pointer operator delete sees while PictDeleteModel runs and requires all 4 model and 7
  parameter handles among them, with the task still alive (0, 1, 2 generations), plus a task-free
  never-attached tree whose allocation balance is taken right after PictDeleteModel.
  Mutants: deferral to PictDeleteTask, root-only params, params deferred to task -> all fail.
- S4 Low: removed the dead CLI m_hasNegativeValues flag (getter, init, parser write) and the unused
  engine Parameter::HasNegativeValues. 253 human-effective.
- Advisory taken: flat order-4 test (5 params), three-value exclusions at order 3.
- 39 new tests. Clean room 1000/0/4242: 588 base pass, 39 fail without / pass with solution, x3.

## R3 (2026-09-24) - Auto Review: Description 3/3, Tests 1/3, Solution 3/3

Tests only; meta.md and solution.patch unchanged.
- T3/T4 API order 3 across the tree (High): order_three_tree() = root params R(6 values, 1 neg) and
  S(5) at order 3, child X (3 params, attached @3), child Y (2 params, @2); new
  Suite.assert_spanning() enumerates triples with one param from each of 3 distinct groups.
  Pairwise-join mutant (models with children capped at order 2, their params too) -> fails
  (65 rows vs 294). Lesson: the first fixture (two 8-row children, small root params) did NOT
  discriminate; pairwise over two big pseudo-params already emits nearly every row. Root elements
  must be larger than the children so pairwise output has fewer rows than the required triples.
- T3/T4 CLI order 3 across submodels (High): ORDER_THREE_MODEL, three groups, /o:3, group B in the
  #44 shape. With root params R/S present the base CLI already covered triples (identical output),
  so the fixture is groups-only. Fails on base (missing A1/C2 negatives) and on the mutant.
- Medium: CLI only-negative-left failure folded into the CLI constraints test (a standalone test
  passes on base: base exits 5 too). Nested API generation error added to the flat error test.
  Stateful repeat: excluded_tree + two seeds, generated 3x, exact row equality. Two-negative seeds:
  API across children, CLI seed file (two rows with two negatives, absent).
- HARNESS FIX (found while checking F2P): cli_negative imported support, which bound
  PictSetNegativeValue via ctypes at import, so on base EVERY CLI test failed with
  "undefined symbol" and test_cli_submodel_order_three_with_negative_values actually passed on base
  behaviourally. Split ctypes code into library_8f8ea0.py; CLI tests no longer load the lib. That
  test now uses the ISSUE model with a 4-param @3 group so it fails on base through behaviour.
- 37 new tests (30 API, 7 CLI).

## R2 (2026-09-24) - Auto Review: Description 3/3, Tests 1/3, Solution 1/3

Findings and fixes:
- S2 leak (High): Task::Generate restores each model's own parameter vector, but PictDeleteModel still
  deleted only root->GetParameters() (the base post-generation flattened list). Fix: collect
  GetAllParameters() over the tree, dedupe, delete. Also fixes the pre-existing leak for a tree that
  was never generated.
- T3/T4 public header (High): ctypes bypassed pictapi.h. New tests/negative_8f8ea0/client_8f8ea0.cpp
  compiled with g++ against api/ + libpict.so: static_assert on PICT_INVALID_VALUE, function-pointer
  assignments typecheck both declarations, then calls them (test_public_header_declares_the_negative_value_api).
  Mutant "old pictapi.h + stale lib" -> header test fails, ctypes test still passes.
- Lifecycle regression test: same client replaces operator new/delete, counts live allocations over
  5 create/generate(0,1,2 times)/delete cycles (test_deleting_model_trees_releases_every_parameter).
  Without the fix: 80 allocations leak.
- T4 exclusions in a model tree (High): excluded_tree() fixture, exclusions inside a grandchild,
  negative-involving, and across branches; two tests (rows respect them / every other combination
  covered). Mutant "user exclusions dropped from child models in the negative phase" passes every
  old test and fails the new one.
- T4 CLI constraints (High): CONSTRAINED_MODEL (WIDE_MODEL + 5 IF/THEN constraints, all combos
  feasible) -> test_cli_submodel_constraints_hold_with_negative_values. Fails under both
  drop-exclusion mutants. Note: the CLI derives its constraints into the models before
  Task::Generate, so a mutant that only clears Task::m_exclusions is invisible there.
- Coverage suggestions taken: more out-of-range indices/sizes; last-non-negative rejection on a
  second parameter plus a state-unchanged check.
- meta.md: dropped the "Today only the command-line tool..." sentence (description reviewer
  suggestion); stated exclusions inside one child and across models; stated PictDeleteModel frees
  the whole tree whether or not generated. Body 369 words.
- Fixture mistakes caught while writing (not solution bugs): first CLI constraint set made ~x and
  ~9 infeasible (base warns the same); M1 with 3 values made I2=2,B2=0 an implied exclusion.
- LOC: 257 human-effective (hook), above the 200 floor, under the hook's 275 design target.

STATUS (2026-09-23, SLICE): core slice built. Reference 252 human-effective (hook) over 13 files,
28 new tests (23 API via ctypes on `make libpict.so`, 5 CLI), all fail on base, all pass with the
reference. Base mode = the repo's perl harness (587 commands, exit code + re-seeding checks)
converted to JUnit; verdicts identical 3x. Docker clean room (image from pristine base, patches
applied in the container, --network none) green as uid 0, 1000 and 4242; flakiness 3x identical.
Dockerfile follows the coordinator's 2026-09-23 rule (COPY --chown=1000:1000 + targeted find/chmod,
no bind mount, no COPY --chmod). Reference left uncommitted in worktrees/pict for FINISH.

## Scope-lock log

- Base commit = upstream main HEAD (ab76c2548f551fcb46314e58653a1bd1172f3a72, 2026-09-08). No post-base commits.
- #44 reproduced on base CLI: issue model `{C1,C2}@2 {D1,D2,D3}@2` -> no row carries `C1=~0` or `C2=~0`.
  Second report (seeded, `/o:1`) -> the seeded C negatives vanish.
- `api/` has never had any notion of negative values (`git log -S egative -- api/` empty).
- Exclusivity: canonical-org PR search by feature class (all states) clean; every fork branch
  pushed since 2025-06 compared, none touches negativity in api/ or the CLI two-run code.
- SIX-CHECK: literal names (PictSetNegativeValue, PictGetResultParameter) absent; namespace and
  philosophy scan clean (#107 "just sets of indexes" fits a per-index flag; #18 declined a
  different syntax lane); no closed-as-implemented; base..main empty; API has no capability today.

## Findings while building the reference (these are the walls)

1. Porting the CLI two-run method into the engine keeps #44: a child whose negative-phase rows
   all carry a negative leaves its siblings' negative rows without partners. Fix: add the child's
   positive-phase rows to its negative-phase rows before the parent generates.
2. Masking exclusions across children assert in `ExclusionTermCompare`: `PictAddParameter`
   numbered parameters per model, so children share sequences. Fix: unique sequences.
3. A second derivation asserts in `LinkExclusion` (stale back-pointers): hit by the CLI double
   prepare and by root parameters beside children. Fix: clear links before deriving.
4. Generation rewrites the model tree; phases and repeated `PictGenerate` restore it, and the
   result layout is kept separately for `PictGetTotalParameterCount` / `PictGetResultParameter`.
5. Exclusions leaving only negative values asserted; now `PICT_GENERATION_ERROR`.
6. The Makefile has no header dependencies: editing `generator.h` and running `make` links stale
   objects and crashes. test.sh uses `make -B`.

## Decisions made without the user (unattended run)

- Issue field `N/A`: the feature is invented; #44 only informs it. meta.md deliberately does not
  describe the #44 symptom (it would point at the template's flaw); it states the guarantee holds
  at every level of a model tree.
- Added `PictGetResultParameter`: API child-model tests cannot identify columns otherwise (the
  base column order for child models is an unstable sort over colliding sequences, #131). Small
  surface, needed for testability.
- CLI tests in new mode are only the ones that fail on base (child models, seeds); flat CLI
  negative behaviour is guarded by the repo's own harness in base mode.
- Single-partner mutant is caught by one CLI test only; more cells are FINISH scope (DESIGN.md).
