# feedback.md — featurevisor-target-specialization

## Summary

Second featurevisor lane: make Target datafiles sound and pruned (three-valued specialization of
conditions and segments keyed on attribute-path presence in the Target context, per-kind pruning of
force / traffic / rule and variation overrides / global overrides, segment GC). Reference 231
human-eff in 2 files. Picked 2026-09-19 after the dinit lane was shelved (machinery-absorbed).

## Validation (2026-09-19, clean room `worktrees/_tools/fvclean-target.sh`, image built from a real clone)

| Check | Result |
|---|---|
| test.patch applies on base, test.sh 100755 | yes |
| new mode on base | 28/28 fail |
| base mode on base | 1033/1033 |
| solution applies, hunk landed | yes |
| new mode with solution, 3x | 28/28 each |
| base mode with solution, 3x | 1033/1033 each |
| offline, uid 1000 | yes |
| cold image build | 3m14s-4m33s |
| eslint / prettier on touched files | clean |
| tsc (core typecheck) | clean except pre-existing `@featurevisor/catalog` import |
| meta.md | ASCII, 313 words |

## Attempt history

| Round | Change | Result |
|---|---|---|
| R0 | reference + 28 new tests + 24 superseded cases removed + 2 base guards | batch 1: 2/10 (20%). Auto Review: Revision Requested (desc 3/3, tests 2/3, solution 1/3) |
| R1 | reference parses conditions like the SDK (any non-`*` string is JSON), segments stay `{`/`[`-only; +5 tests: requiredFeatures-only override, stringified rule overrides, stringified global overrides, scalar catch-all direct + via build | clean room green (33 fail on base, 33/33 + 1033/1033 x3). Replay: both passers fail the scalar pair -> re-eval would read 0/10 |
| R2 | meta.md: "Selectors may arrive stringified in any form the builder writes today, scalar JSON included." (names the root cause of the 10/10 scalar gap, not the fix). Solver-visible change -> fresh batch, not re-eval | batch 2: **3/10**, Auto Review Approved (desc 3/3, tests 2/3, solution 3/3), **ACCEPTED 2026-09-19** |

## Batch 1 Auto Review (2026-09-19)

- Solution 1/3, High: a global override authored with `conditions: "*"` is written by
  `buildGlobalVariableOverrides` as `JSON.stringify("*")`; the R0 parser decoded only `{`/`[` strings,
  decided the leaf false and pruned the override. Fixed in R1 (conditions now follow the SDK's
  `parseConditionsIfStringified`).
- Tests 2/3, Medium: no direct stringified cases on rule overrides or global overrides. Added in R1.
- FP panel: Nova passer #2 carried a solo judge FP dissent on the same scalar probe; dismissed only
  because the R0 reference shared the gap. Once the reference is fixed, the probe discriminates.
- Nova_10 passed both suites and was failed on static review (requiredFeatures-only override pruned):
  a test hole, closed in R1.

## Acceptance (2026-09-19)

Batch 2 3/10 legitimate, all Nova. Auto Review approved with two Medium test notes left as-is: condition
operators beyond the six the generator uses, and requiredFeatures + target-false selector on global and
variation overrides. Mined into failure-patterns.md (F-12 exported variant, F-39 parser instance, new F-43,
L77, L78, dossier), Pattern 99, the author/hunt/harden skills and the Instructions files.
