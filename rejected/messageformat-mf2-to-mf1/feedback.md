# messageformat-mf2-to-mf1 — feedback / iteration log

Repo messageformat/messageformat @ 0ffba11d (main HEAD). Hunt: REPO-HUNT-2026-09-19-D RANK 1.
Picker check: confirmed selectable by the user 2026-09-19.

## Scope (frozen for the core slice)
1. NEW `messageToMF1(locale, msg)` in `@messageformat/icu-messageformat-1` (MF2 data model -> MF1 source),
   equivalence contract via `mf1ToMessage` round trip, locale-valid output.
2. FIX `mf1ToMessageData` (pre-existing): a nested statement under a statement for a different argument
   that lists fewer cases than its siblings produced empty variants (`{a, select, p {{b, select, other {B}}}
   other {{b, select, x {C} other {D}}}}` with a=p, b=x gave "" where `@messageformat/core` gives "B").
   Reference fix omits the cells that statement never lists, so MF2 selection falls through to the
   statement's own cases (locale-free; handles the plural exact-vs-category case the natural
   "fill with other" fix gets wrong).
3. FIX `selectPattern` (pre-existing): infinite loop when backtracking reaches a selector already on its
   catch-all (3+ selectors), e.g. `.match $a $b $c / 1 * x / * * *` with a=1, b=q, c=y.

Both bugs were found while building the round trip; neither has an upstream issue or PR.

## Test harness notes
- base mode excludes `mf2/messageformat/src/spec.test.ts`: it reads the `test/messageformat-wg` git
  submodule (Unicode spec test data), which a plain checkout does not contain.
- new mode runs each new test file in its own vitest invocation under `timeout 60`, because the base
  runtime loops synchronously on the 3-selector fixture and vitest cannot interrupt it; a timed-out file
  gets a synthetic failing testcase. JUnit files are merged by an inline node script.

## Attempt history
- 2026-09-19 core slice built and clean-room validated (Docker, uid 1000, --network none):
  base 1187/1187 without and with solution; new 10/10 fail on base, 10/10 pass with solution.
  Solution 287 human-effective (hook). Awaiting platform precheck (Step 4b) before building the full suite.
- 2026-09-19 platform precheck on the core slice: REJECTED, overlap Blocker. "270 of 354 authored subject
  lines (76.3%) re-deliver an older MF2-to-MF1 converter core already present independently in each of
  two older candidates"; the locale-sensitive synthesis and the two selection repairs were rated
  "additions around that shared core". Not contestable (exclusivity is binary). Shelved to rejected/,
  recorded in TOO-EASY.md and SATURATED-REPOS.md. No batch was run.
