# feedback.md - featurevisor-minimal-rebucketing

## Status

**✅ ACCEPTED 2026-09-19 at 2/11 (Orion, Vega) on the re-eval of batch 1. Auto Review Approved (3/3/3), FP panel upheld both passes. Finalized: F-39, F-40, L74, Pattern 97.**

**SCOPE GATE PASSED (2026-09-17). Quality review FAILs fixed in R1; Verify Solution FAIL (18 new-mode tests passed without the solution) fixed in R2; Verify Solution FAIL `before_extras_not_skipped` (test-ID collision on `::`) + Solution Quality medium (`__proto__`) fixed in R3. **Batch 1: 2/11 (18%). Auto Review "Revision Requested" (Tests 1/3; Description 3/3, Solution 3/3) addressed in R4, test.patch only, re-eval eligible.** Base
`b88f3981989c3cc7a06efea2597807517a624d16` (v3.11.0). Do not write the remaining scope (group slot
semantics, state `ranges` persistence, CLI surfacing) until the scope verdict is clean.

## Why this pick

Found by the niche-sweep subagents after the sfepy arc-length pick died `publicly-solved`
(JAX-FEM). Hunt log: `Instructions/repo-hunt-logs/REPO-HUNT-2026-09-17.md`; dossier
`worktrees/_hunt/agents/engines.md`.

- **Own-model hard part.** The capability is defined by featurevisor's own allocation ranges, state
  file and group slot ranges. GrowthBook's "sticky bucketing" is an SDK-side per-user store, a
  different mechanism; no public range-reallocation implementation found.
- **Maintainer note, not a decline.** `traffic.ts` carries "worth checking if we can maintain
  consistent bucketing for this use case as well"; docs call it a limitation. No issue or PR asks
  for it, and there are 0 open PRs on the repo.
- **Latent bugs on the same seam** (kept for later scope, not fixed in the slice): state is written
  without `ranges`, so `detectIfRangesChanged` can never fire; and
  `getUpdatedAvailableRangesAfterFilling` drops untouched later ranges, which the slice's kernel
  avoids by subtracting filled ranges instead.

## Core slice

- `allocator.ts`: range algebra (`intersectRanges`, `subtractRanges`, `sortRanges`, `getRangesSize`,
  `normalizeAllocation`), `reallocate` (the kernel), `getAllocationChanges`.
- `traffic.ts`: `getTraffic` now computes per-variation targets and delegates to `reallocate`;
  the increase-only preservation path and the rebucketing flags are gone.
- `buildDatafile.ts` / `buildProject.ts`: optional `rebucketing` collector + `formatRebucketing`.
- 164 human-effective, 4 files. **Below the 200 auto-block; must grow before submission.**

## Validation record (Docker `fv-slice:base`, uid 1000, `--network none`)

| Check | Result |
|---|---|
| Image builds from the submission Dockerfile at base | yes (needs `NODE_ENV=development`; the base image sets production and prunes devDeps) |
| test.patch applies, test.sh mode 100755 | yes |
| New tests on base | **31 of 31 fail**, JUnit written (no collection wipe) |
| New tests with solution, 3x | 31/31 every run |
| Base suite on base and with solution, 3x | 1050/1050 every run (1040 + the 10 untouched `traffic.spec.ts` cases) |
| Typecheck / eslint / prettier | clean |
| Comments added | zero (repo convention) |
| meta.md | 458 body words, ASCII, frontmatter present |

## Owed after a clean scope verdict

Group slot semantics (targets currently clamp inside a slot, existing quirk left alone), persisting
`ranges` in state, surfacing the report in the CLI, F-10 cross-product cells, LOC to 275+.

## Known risks

1. **Nameable capability.** The in-code note makes it findable by any author; the maintainer ships
   roughly weekly. Re-run the post-base commit check at submit.
2. **Clean-room tool moved** to `worktrees/_tools/fvclean.sh` (the scratchpad copy went missing).
3. **LOC.** 160 effective; needs the owed scope.

## Review findings and fixes

**R1 (2026-09-17), after Test Quality FAIL (1 of 21 unfair) + Solution Quality FAIL.**

1. **Solution, high:** a rule `variationWeights` override of `0` was read with a truthiness check, so
   it fell back to the variation's own weight (`{ a: 0, b: 100 }` gave `a` 50%). The repo's own
   schema allows `0` (`featureSchema.ts:1461`). Inherited verbatim from the pre-existing code.
   Fixed with a `typeof !== "undefined"` check, plus two regression tests.
2. **Tests, unfair:** `formats one summary line per rebucketed rule` pinned the literal
   `checkout (rule everyone)` while meta.md only said "the rule in parentheses", so a compliant
   formatter emitting `checkout (everyone)` failed. Test now matches either label form and still
   pins the percentages; meta.md unchanged on that point.
3. **Solution, low:** removed the superseded `detectIfVariationsChanged`, `getRulePercentageDiff`
   and `detectIfRangesChanged` (no remaining call sites; the module is not publicly exported).
4. **Advisory coverage added:** grouped-feature slot region, reuse by rule key rather than position
   (written so by-position gives a different result), zero-weight range dropping, build report
   ordering across two features with the full `RebucketingChange` payload.
   Still untested: the build prints summaries after its targets finish (`buildForEnvironment` is not
   exported; would need a full on-disk project).
5. **meta.md:** now says the rule override is taken "zero included" (460 body words, still ASCII).

## Attempt history

| Round | What changed | Result |
|---|---|---|
| R0 | core slice + meta.md + Dockerfile + clean room | **scope gate PASSED**; quality review FAIL |
| R1 | zero-override fix, fair formatter assert, dead helpers removed, 5 coverage tests | new 36/36, base 1040/1040, 18 of 36 fail on base |
| R2 | Verify Solution FAIL: every new-mode test must fail without the solution | **new 27/27 (3x), 27 of 27 fail on base, base 1050/1050 (3x)** |
| R3 | Verify Solution FAIL `before_extras_not_skipped` (314 phantom tests); Solution Quality PASS with a medium `__proto__` issue | **new 31/31 (3x), 31 of 31 fail on base, base 1050/1050 (3x), 0 `::` in XML, 0 duplicate IDs** |
| Batch 1 | 8 Nova + 1 Orion + 2 Vega on R3 | **2/11 (18%)**; see eval-results.md |
| R4 | Auto Review: Tests 1/3 (2 High, 4 Medium). test.patch only | **new 34/34 (3x), 34 of 34 fail on base, base 1050/1050 (3x); replay of the 11 saved patches: still 2/11, representation failures 7 -> 0** |

## R4 detail (Auto Review, Tests 1/3)

- **T5 formatter representation (Medium, unfair):** tests required `formatRebucketing` to return an
  array and one `console.log` per rule; the prose only promises one rendered line per change. Five
  runs used a joined string or a per-change formatter. Now asserted through `renderLines`, which
  renders whatever shape the formatter returns, and the print test counts rendered lines.
- **Grouped slot-range change (High):** added a case with stored `ExistingFeature.ranges` that
  change, owners placed so the kept-in-place answer differs from a fresh fill (this is exactly the
  base `rangesChanged` reset branch).
- **Disjoint accounting (High):** equal-size shift into unallocated buckets must read
  removed + added, moved 0.
- **Positive `added` on a collected change (Medium):** full record asserted at the build boundary.
- **Two environments (Medium):** each environment's lines printed once, after its own last target
  and before the next environment's first target.
- **Fallback diagnostics (Medium):** `test.sh` now tees jest output and, when no XML exists, writes a
  failing testcase carrying the ANSI-stripped, XML-escaped tail. Verified by hiding `jest-junit`.
- Kept, per the reviewer: the `__proto__` test (fair, repo types say `VariationValue = string`) and
  the multi-range tests (fair, prose says slot ranges are walked in order).

## R3 detail

**`before_extras_not_skipped`.** The repo's own linter specs name describe blocks with a literal
` :: ` (`describe("attributeSchema.ts :: getAttributeZodSchema")`), and jest-junit copies that into
both `classname` and `name`. The platform keys tests as `classname::name`, so those IDs split
wrongly in one pass and 314 of them surfaced as unmatched "extras" (P2P and F2P were themselves
correct: 1050 / 27). `test.sh` now rewrites ` :: ` to ` - ` in the JUnit file after jest finishes.
Verified: zero `::` left in any XML, zero duplicate `(classname, name)` pairs in either mode.
**Lesson:** check the repo's existing test titles for the grader's ID separator before shipping a
JUnit wrapper.

**Solution Quality medium.** `getAllocationChanges` built `variations` as `{}`, so a variation value
of `__proto__` (valid: the schema only requires a non-empty string) hit the prototype setter and
vanished. Now `Object.create(null)`; regression test added.

**Advisory coverage added, each written to fail on base:** a group region cut partway through a
later slot (previous allocation placed in opposite slots so a refill gives a different answer),
appending to a pre-filled `rebucketing` collector, and `getAllocationChanges(existing, undefined)`.

## R2 detail (Verify Solution)

Two causes, both fixed without touching meta.md or the solution:

1. `traffic.spec.ts` was in new mode because 5 of its tests were edited, which dragged its 10
   untouched cases (passing on base) into new mode. The 5 superseded cases are now removed from
   `traffic.spec.ts` and live, with their new expectations and without the repo's inline input
   comments, in `rebucketing_a0018f.spec.ts` under "previous traffic cases". `traffic.spec.ts`
   is back in base mode; new mode runs only the new spec.
2. Eight new tests used transitions where today's full refill happens to give the same answer.
   Each was rebuilt on a discriminating case: declared-order swap, removed variations refilled in
   a different declared order, decrease from an interleaved allocation, an 80/20 rule override, a
   zero weight alongside a new variation, a kept-maximality check via `getAllocationChanges` in the
   invariant sweep, and the repeat-build test now also requires the first change to be reported.
   The from-scratch baseline guard was dropped (it can never fail on base).

Advisory coverage from the same review, now tested: growth-only rebuild appends nothing; two
features both losing buckets report in build order; `formatRebucketing` with two changes; and
`buildProject` prints each affected rule's line once, after the environment's last target
datafile is written (mocked datasource with two targets, `console.log` spy, lines identified by
content not by label wording).

## Acceptance (2026-09-19)

| Round | What changed | Result |
|---|---|---|
| Re-eval (batch 2) | R4 test.patch over the batch-1 solutions | **2/11 (Orion, Vega); Auto Review Approved, Description 3/3, Tests 3/3, Solution 3/3; FP panel: both passes genuine; ACCEPTED** |

Kills: `__proto__` 7/11 (six sole), removed-variations refill and grouped slots 3/11 each (same three
runs). 31 of 34 tests killed nothing. The replay predicted every run. The agent-run reviewer filed a
High "difficulty discrepancy" (six near-misses on one special key) without blocking approval.

