# pict-engine-negative-values - feedback

NEXT (human): re-upload R4 (test.patch + solution.patch changed, meta.md unchanged) and re-run Auto Review.

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
