# eval-results - textual-functional-selectors

> **SOLVER-MEDIAN SCORING NOTE (added 2026-06-17).** The platform considers the MEDIAN of messages/LOC/files across PASSED runs ONLY - failing runs are EXCLUDED. So the many passages below that treat sub-100 FAILING Nova runs (71-99) as a ">100 EVERY agent" gate failure ("NOT MET on the Nova side", "OPEN risk") were reading the floor WRONG: those failing runs carry no floor signal. The only binding figure is the sole SOLVER (run 8, PASS_LEGITIMATE) at **101 msgs** -> median 101, which clears >100, so the gate was actually MET - but by ONLY 1 message = a thin margin and a real risk. Target a solver-median well above 100; do not generalize failing-run counts into a gate failure, and do not treat a +1 median as comfortable.

## Eval batch 5 (1 Nova, 79-test de-trapped build) - confirms difficulty floor, NOT too easy

| # | Solver | Verdict | Msgs | New | Base | Failing |
|---|---|---|---|---|---|---|
| 1 | Nova | FAIL_MISSED_REQUIREMENT | 83 | 78/79 | 3455/0 PASS | test_not_styles_do_not_leak_to_excluded_widget (:not stylesheet cache-leak; agent omitted not/is/where from _EXCLUDE_PSEUDO_CLASSES_FROM_CACHE) |

READ: NOT too easy - Nova (weakest agent, target ~90% fail) FAILED at a FAIR near-miss on a real
scattered-difficulty integration point the reference handles. Static integration difficulty
survived the de-trap. BUT two caveats: (1) 78/79 is a NEAR the easy edge - Nova misses only ONE
test now (vs 2-5 pre-de-trap); if a Nova lands :not-leak right it PASSES -> drift risk has flipped
toward too-easy, watch it. (2) This is Nova-only = confirms the Nova-fails half, NOT solvability;
still NO demonstrated >=1 pass. NEXT: run ORION (should pass - its batch-4 blockers were removed);
read pass-rate over ~10 runs (1-2/10 = ship; >2/10 or Nova-pass = re-add one dynamic surface;
0/10 = still too hard, unlikely). Message-count: Nova 83 (<100, early-term as usual); Orion was
141-176 (>100) - re-confirm on the Orion run.

## Eval batch 4 (10 runs, 90-test build) = 0/10 - scattered TOO-HARD -> de-trap the round-3 propagation gold-plating

Full batch (all FAIR, FAIL_MISSED_REQUIREMENT except #5 agent recursion bug; baseline PASSES all):
best 88/90. NO deterministic universal miss left (only-*/sort_children gone) - failures SCATTER
across the dynamic-restyle + deep-stylesheet second surface, and NO agent clears all of it:
| # | Solver | Msgs | New | Failing new tests |
|---|---|---|---|---|
| 1 | Orion | 159 | 88/90 | test_move_child_updates_positions, test_sibling_chain_descendant_restyles_on_move (BOTH dynamic-propagation) |
| 2 | Orion | 176 | broad | nested, sibling-stylesheet, move restyle |
| 3 | Nova | 89 | 87/90 | combinator-inside-not, sibling-combinator-stylesheet, nested-with-sibling |
| 4 | Orion | 141 | ~89/90 | nested_css_with_functional_pseudo_class |
| 5 | Nova | 90 | 85/90 | FAIL_INTEGRATION_ERROR - AGENT's own infinite-recursion restyle hook (not the reference) |
| 6 | Nova | 88 | ~88/90 | sibling-combinator-stylesheet (+) |
| 7 | Nova | 95 | broad | :not(:first-child) parse, :not(#c2) isolation |
| 8 | Nova | 94 | 85/90 | five selector tests |
| 9 | Nova | 96 | 88/90 | :not(:first-child) parse (2) |
| 10 | Nova | 82 | broad | move/sibling-chain restyle, sibling-stylesheet, nested-with-sibling, update_classes |

DIAGNOSIS: 0-of-10 FAIR + scattered + no pass = calibrated TOO HARD (the joint difficulty of the
many independent hard integration requirements is too high; even Orion scatters 2-3 misses).
Root cause: the DYNAMIC-RESTYLE propagation I expanded across review rounds 1-3 (restyle on
move/sort/class-change/deep-descendant) - my own review fleets optimized SOLUTION COMPLETENESS,
which pushed the PROBLEM from ~10% to 0%. The nearest run (#1 Orion, 159 msgs, 88/90) failed on
EXACTLY two dynamic-propagation tests (move + sibling-chain-on-move).
Message-count: Orion 141/159/176 (>100) - comfortably met by the solver class.

## DE-TRAP 4 (one lever: dynamic restyle full -> mount/remove only):
Reverted the move_child / class-change / deep-descendant restyle propagation - 11 tests + the
matching solution wiring (_update_dependent_styles + the 5 class-mutation calls + the
descendant-walk in _update_position_dependent_styles + move_child's call). KEPT: subject-level
mount/remove restyle (append/insert/remove nth + sibling) and the :has subtree sweep on
mount/remove (test_mount/remove_updates_has_match), plus ALL static selector matching (logical/
relational/sibling/nth/of in query+stylesheet, specificity, cache-exclusion, parse rejections).
This flips run #1 (its 2 fails were both removed) -> a pass, while the static scatter (nested,
sibling-stylesheet, :not parse/leak) keeps Nova failing -> ~10%. meta dynamic clause scoped to
"mounted or removed" (alignment preserved). Build: 79 tests, 780 raw / 477 hook-eff LOC / 11
files, meta 267w, black-clean, patches regenerated. 4-cell recorded below.
WATCH: this is a real scope trim; if the next batch over-shoots (>2/10) re-add one dynamic
surface; if still 0 with scattered static misses, the next lever is the compound nested/sibling-
stylesheet tests. Message-count may dip with less dynamic to implement - re-confirm Orion>100.

## Eval batch 3 (post-only-* de-trap, 91-test build) - baseline FIXED, ONE deterministic universal miss left

| Run | Solver | Verdict | Msgs | New | Base | Failing new tests |
|---|---|---|---|---|---|---|
| 1 | Nova | MISSED_REQ | 96 | 87/91 | 3455/0 PASS | sibling-stylesheet, :not(#c2) leak, sort_children, +1 |
| 2 | Orion | MISSED_REQ | 189 | 90/91 | 3455/0 PASS | test_sort_children_restyles_positions ONLY (clean near-solver) |
| 3 | Orion | MISSED_REQ | 150 | 88/91 | 3455/0 PASS | nested-CSS-functional, :not(#c2) leak, sort_children |
| 4 | Nova | MISSED_REQ | 81 | 85/91 | 3455/0 PASS | :not(:first-child) parse, nested, sibling, sort_children |
| 5 | Nova | INTEGRATION_ERROR | 121 | 60/91 | 3455/0 PASS | RecursionError - AGENT's own infinite restyle hook (App.update_styles<->Screen.update_node_styles); agent fault, not the reference (my impl is ScreenStackError-guarded single-walk; base 3544/0 = no recursion) |
| 6 | Nova | MISSED_REQ | 89 | 89/91 | 3455/0 PASS | :not(#c2) leak, sort_children |
| 7 | Orion | MISSED_REQ (STALE) | 164 | 89/91 | 3453/0 PASS | nested-CSS-functional, :not(#c2) leak - STALE snapshot (no sort_children fail = predates that test); failed only on scattered difficulty the reference handles |

CORRECTION (user): the batch is 7 runs (I initially tabulated 4). 0/7. Two are special:
run 5 = FAIL_INTEGRATION_ERROR from the AGENT's own recursion bug (not my build), run 7 = STALE
(old snapshot). Among the 5 valid current-build runs (1,2,3,4,6), sort_children failed in ALL 5
and was the SOLE failure of the cleanest run (#2, Orion 189 msgs). De-trap target confirmed.
Scattered difficulty is broader than first credited: :not(#c2) leak in 1/3/6/7, nested-CSS in
3/4/7 - good (run 2 PASSED both, proving solvable). Removing sort_children flips run 2 -> PASS
(>=1 pass = solvability) while scattered misses keep the rest failing -> ~10%.

KEY: the only-* de-trap WORKED - baseline now PASSES on every run (the 6/7 regression is gone).
Remaining: ONE deterministic universal miss - test_sort_children_restyles_positions fails in
ALL runs and is the SOLE failure of the strongest run (Orion 90/91, 189 msgs). Agents wire the
obvious restyle paths (mount/remove/move_child/class-change) but none patch the obscure
DOMNode.sort_children. The OTHER failures (sibling-stylesheet, :not(#c2) cache leak, nested-CSS,
:not(:first-child) parse) are SCATTERED across runs = good difficulty, KEEP. Message-count:
Orion 189 and 150 (>100) on this batch - the >100 gate is comfortably met by Orion-class runs.

## DE-TRAP 3 applied (2026-06-10): remove the sort_children deterministic universal miss
sort_children restyle was an EXTRA reorder entry point I added in the round-3 review, not core.
Removing it flips Orion 90/91 -> 91/91 PASS (solvability MET, 189 msgs >100) while the scattered
difficulty keeps the other agents failing -> ~10%. Discoverability is not an option (naming
DOMNode.sort_children in meta = a HOW leak), so removal is the clean de-trap.
- Removed test_sort_children_restyles_positions (test count 91 -> 90).
- Removed the 1-line self._update_position_dependent_styles() call from DOMNode.sort_children
  (keeps solution<->test symmetric; the "moved" contract stays honored+tested via move_child:
  test_move_child_updates_positions + test_sibling_chain_descendant_restyles_on_move).
Re-validated: hidden 90/90, base 3544/0 (no regression from the 1-line removal), LOC 490 eff /
796 raw / 11 files, black clean, patches regenerated. Definitive 4-cell recorded below.
Expect next batch: the Orion-class run passes (its sole blocker removed) -> >=1 pass; Nova still
fails the scattered cache/parse/nested difficulty -> ~10%.

## Eval batch (SINGLE batch of 7: 1 Orion + 6 Nova solvers, Vega locked), 101-test build, 2026-06-10

CORRECTION (user, 2026-06-10): all 7 runs below are ONE batch with a mixed agent assignment
(1 Orion + 6 Nova), NOT two separate batches. The Orion row is listed first; the 6 Nova rows
follow. 0/7. Vega was locked.

| Run | Solver | Eval | Verdict | Msgs | Files | LOC | New | Base | Failed-test clusters |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Nova | Orion | FAIL_MISSED_REQUIREMENT | 85 | 11 | 719 | 92/101 | 3452/3453 | :not(:first-child) parse; sibling stylesheet; :not(#c2) cache leak; move/sort restyle; +baseline test_hover_update_styles |
| 2 | Nova | Nova | FAIL_REGRESSION | 80 | 12 | 646 | 95/101 | 3452/3453 | remove/move/sort/nth-last restyle; :not(#c2) leak; +baseline regression |
| 3 | Nova | Nova | FAIL_REGRESSION | 99 | 11 | 714 | 96/101 | 1 fail | :not(:first-child)/:not(:only-child) parse; Label+Label stylesheet+nested; +baseline regression |
| 4 | Nova | Orion | FAIL_MISSED_REQUIREMENT | 88 | 11 | 719 | 98/101 | 3452/3453 | sibling stylesheet on identical siblings; :not(#c2) leak; nested-CSS sibling; +baseline regression |
| 5 | Nova | Orion | FAIL_MISSED_REQUIREMENT | 81 | 11 | 602 | 95/101 | 1 fail | sibling stylesheet; :not(#c2) leak; move_child/sort_children restyle; +baseline regression |
| 6 | Nova | Orion | FAIL_MISSED_REQUIREMENT | 88 | 11 | 561 | 95/101 | snapshot test_example_merlin | :not(:first-child)/:not(:only-child) parse; move/sort restyle |

## Orion detail (the strong run within the single batch above)

| Run | Solver | Eval | Verdict | Msgs | Files | LOC | New | Base | Failed-test clusters |
|---|---|---|---|---|---|---|---|---|---|
| 7 | Orion | Orion | FAIL_MISSED_REQUIREMENT | 160 | 11 | 643 | 99/101 | 3454/3455 | sibling-combinator STYLESHEET application (Label+Label, nested &+Label); +baseline test_hover_update_styles (only-of-type added to _PSEUDO_CLASSES) |

Two decisive readings:
- MESSAGE-COUNT, CORRECTED READ (single batch): the per-agent counts are 160 (Orion) and
  80/81/85/88/88/99 (the 6 Nova). Orion CLEARS >100; the 6 Nova do NOT. The >100-EVERY-agent
  gate is therefore NOT met on the Nova side. Orion's 160 proves the problem HAS long-horizon
  scope (a thorough agent spends 160), so this is Nova early-termination, not a small problem -
  but if the platform hard-gates per-agent message count (incl. failing runs, per the goja-Intl
  precedent), the Nova counts are an OPEN, separate risk the solvability de-trap does not fix
  (and may slightly worsen by removing scope). Surfaced to the user.
- SOLVABILITY 0%-TRAP CONFIRMED: across 7 runs (6 Nova + 1 Orion) the SAME two blockers recur,
  and even Orion (strongest available; Vega locked) hit BOTH while landing 99/101 + the baseline
  regression. Failures are CLUSTERED on 1-2 requirements (not scattered) = the deterministic-
  universal-miss diagnostic, threatening the absolute solvability floor:
  (1) only-* -> Widget._PSEUDO_CLASSES baseline regression (6/7 runs incl. Orion): only-child/
      only-of-type are the ONLY parameterless new pseudo-classes, so agents wire them beside
      first-child/last-child and break test_hover_update_styles (exact-set assertion). No
      meta-level fix exists (it is an internal-structure constraint, HOW-leak to state).
  (2) sibling-combinator STYLESHEET application (Orion + several Nova): agents implement the
      query path but not Stylesheet.apply level-grouping. Round-6 had REMOVED the
      "works in stylesheets and query" clause under necessary-info pressure - empirically that
      removal made the strongest agent miss exactly this.

## DE-TRAP applied (2026-06-10) - lift the floor, keep scattered difficulty
Per the deterministic-universal-miss protocol (de-trap by removal/discoverability; keep the
scattered difficulty; never bypass solvability):
- DROPPED :only-child / :only-of-type entirely (selector + OnlyPseudoClass + only_child/
  only_of_type widget properties + their _PSEUDO_CLASSES-set / _has_order_style entries + 10
  tests). Removes the SOLE lure to touch _PSEUDO_CLASSES -> the 6/7 baseline regression
  becomes structurally impossible (verified: test_hover_update_styles passes; base 3545/0).
  nth-*/logical/relational/sibling all take arguments, so none tempts the parameterless
  registry. only-* was the least-interesting family (count==1); LOC stays 491 eff (>400).
- RESTORED a concise discoverability clause to meta: "They apply both when styling widgets
  through stylesheets and when matching them through query." Fair (tested behavior; its
  removal demonstrably caused Orion's 2 misses); keeps the level-grouping implementation
  difficulty intact.
Resulting build: 91 hidden tests (was 101), meta 267 words, solution 797 raw / 491 hook
human-effective across 11 files, base suite 3545/0. Re-eval with Orion expected to pass
(its exact failure mode - 1 baseline + 2 sibling-stylesheet - is now both removed and made
discoverable) while Nova still fails the scattered cache/parse/propagation difficulty -> the
~10% target. Definitive 4-cell recorded below.

## Submission criteria check (batch 1)

- Working runs: 6/6 ran cleanly (0 infra/env blockers; all blocker_detected=false, confidence high).
- Fair: 6/6 FAIR - agent_blame_unfair=false, description_clear=true, tests_deterministic=true,
  difficulty=challenging on ALL. Zero FAIL_TEST_MISMATCH. Pure difficulty signal.
- Solvable (>=1 pass): NOT YET DEMONSTRATED on Nova (0/6). Reference is provably solvable
  (101/101, 0 regressions). 0/6 at a true ~10% rate is the >50%-likely outcome (0.9^6=0.53),
  so 0/6 is NOT a redesign signal - and this is NOVA-ONLY, the weakest agent and the WRONG
  solver for this O-Composite-add+algorithm shape (playbook solver = Vega/Orion).
- Hard (~10%): consistent with ~10% - best run 98/101, fails scattered across runs.
- Long-horizon (>100 msgs EVERY agent): NOT MET on Nova - runs 80/81/85/88/88/99 (max 99,
  all <100). The documented feature-from-spec tension (see olympus-message-count-floor).

## Failure analysis (batch 1)

Two failure families, both FAIR and BY DESIGN:
1. NEAR-UNIVERSAL baseline regression (5/6): agents add only-child/only-of-type to
   Widget._PSEUDO_CLASSES (the obvious wiring beside first-child/last-child), which breaks the
   existing tests/test_app.py::test_hover_update_styles exact-set assertion. The reference
   AVOIDS this by routing only-* through OnlyPseudoClass on the functional path - the
   intentional Nova-regression trap (see memory olympus-textual-functional-selectors). Caught
   only by running the FULL base suite; Nova ran focused CSS tests only. This is the designed
   "Nova fails / Orion-class passes" discriminator, NOT a 0%-trap - UNLESS Orion also hits it
   universally.
2. SCATTERED feature gaps (different agents, different subsets): stylesheet cache leak for
   :not()/sibling combinators across identical siblings (must add the new names to
   _EXCLUDE_PSEUDO_CLASSES_FROM_CACHE + sibling-combinator cache bypass); :not(:first-child)/
   :not(:only-child) over-rejected at parse (non-functional pseudo-classes ARE allowed in
   arguments); move_child/sort_children not restyling positional/sibling subjects. All
   reference-correct, all documented; legitimate scattered difficulty.

## Decision (batch 1) - run Orion as SOLVER, do not redesign

0/6 Nova is statistically expected AND agent-mismatched. Next: run Orion as the SOLVER (3-5
runs; Vega locked). Orion's full-suite discipline catches the only-* regression and its
commit-and-implement-fully counters the scattered cache/propagation gaps - the reference
proves a path. Keep all deliverables unchanged for that run. Decision rule recorded in feedback.md. (Same-batch Orion ran at 160 msgs / 99-101 and hit
both deterministic blockers -> 0%-trap confirmed and de-trapped; message-count met for Orion
but NOT for the 6 Nova - see corrected read below.)

## Local validation record (attempt 1 FINAL, post-review remediation, 2026-06-10)

- Hidden tests: 79 (after de-trap rounds 1-4). Reference 79/79 PASS; pristine base 79/79 FAIL;
  naive-agent benchmark recompute pending (70-85 calibrated band; discriminators across order
  invalidation, cache exclusion, and class-change/subtree invalidation).
- Solution: 780 raw / 477 hook human-effective / 289 padding-floor, 11 files (after the
  only-*, sort_children, and dynamic-propagation de-traps).
- Full base suite with solution: 3544 passed / 0 failed (3454 base + 90 hidden).
- Final 4-cell (fresh archives, pinned Dockerfile, offline non-root): recorded in the
  matrix below; the definitive run uses the FINAL 101-test build (serial base mode +
  shared-helper descendant propagation).
- Test-count reconciliation: 3454 = dev-container full suite pre-solution (excludes skips);
  3462 = in-Docker base-mode JUnit testcases (3454 + 3 skipped + 4 xfail + 1 xpass);
  3545/3546 = dev suite including the hidden test file.

## Superseded interim numbers (history only - the FINAL figures are in the section above)

Pre-review build for reference: 70 tests (ref 70/70, base 0/70), naive 59/70 = 84.3% over two
discriminator surfaces, LOC 702 raw / 443 hook-effective. The oracle record below remains
valid for the final build (the fuzzed families were unchanged by later rounds):

- Oracle (lxml+cssselect mirrored trees): ~1440 randomized selector evaluations over 120
  random trees, 0 mismatches (nth families incl. whitespace an+b forms, :not lists/compounds/
  structural inner, sibling chains, mixed combinators). The of-clause and :has families are
  outside cssselect's vocabulary; their tests are hand-derived and were independently
  re-simulated during the review rounds.

## Definitive 4-cell matrix (FINAL 79-test build, fresh git-archive contexts + the real
pinned Dockerfile, offline --network none, non-root --user 1000:1000)

| Cell | Result |
|---|---|
| base-state, base mode | PASS - 3462 testcases, failures=0, errors=0 |
| base-state, new mode | FAIL as expected - 79 testcases, failures=79 (CSS errors on the new syntax) |
| solution-state, base mode | PASS - 3462 testcases, failures=0, errors=0 (no regressions) |
| solution-state, new mode | PASS - 79 testcases, failures=0 |

(Definitive run: 101-test patch with SERIAL base mode and the shared-helper propagation
solution across all five mutation paths;
both patches apply and reverse-apply on pristine BASE archives. Verify-Tests hardening
evidence: serial base suite green under docker --cpus=2 [3454/0, 5:33] and --cpus=1
[3454/0, 6:05]; the old -n auto failed 12 tests at --cpus=2.)

F2P = 79 (every new test), P2P = 3462, no overlap (the new file is excluded from base mode via
--ignore).

Environment-Quality fix verification (precheck round 3): the platform sandbox sets NO_COLOR,
which failed 438 BASE tests (ANSI expectations). After the Dockerfile fix (ENV NO_COLOR="" +
a build-time root conftest.py that pops NO_COLOR at collection), bare `python -m pytest` with
NO_COLOR=1 injected passes: base image 3454 passed / 0 failed; solution image (pre-propagation build) 3548 passed /
0 failed; the NO_COLOR-scrub conftest is unchanged in the final image. The standard 4-cell above is from the same rebuilt
image. Both patches apply AND reverse-apply cleanly on pristine BASE archives; the
solution-state context applied solution.patch first then test.patch (order independence).
One environment finding fixed en route: the repo's hot-reloading tests WRITE to .tcss files
under /app, which fails as a non-root user on a root-owned tree - the Dockerfile therefore
ends with `chmod -R a+rwX /app` (a requirement of the repo's own suite, not error-silencing;
5 base tests fail non-root without it).

## APPROVAL batch - ADMIN APPROVED (2026-06-15), 79-test build
Fingerprint: sol=a08c0b9a test=7561d12 meta=8d712e1 docker=4490336 base=ca449fd
(baseline 3455 / new 79). FRESH against the current reverted 79-test deliverables.

| # | solver | eval | verdict | msgs | new | baseline | dominant cause |
|---|--------|------|---------|------|-----|----------|----------------|
| 1 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 90  | 76/79 | 3455/0 | :not(:first-child) parse + :not(#c2) cache leak |
| 2 | Orion | Orion | FAIL_MISSED_REQUIREMENT | 169 | 78/79 | 3455/0 | :not(#c2) cache leak |
| 3 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 84  | 78/79 | 3455/0 | :not(#c2) cache leak |
| 4 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 89  | 76/79 | 3455/0 | :not(:first-child) + nested-functional + :not(#c2) |
| 5 | Nova  | Orion | FAIL_REGRESSION         | 91  | 78/79 | 3454/1 | test_mega_stylesheet parse regression + :not(#c2) |
| 6 | Nova  | Orion | FAIL_REGRESSION         | 105 | 76/79 | 3432/21| ScreenStackError teardown regression |
| 7 | Nova  | Orion | FAIL_REGRESSION         | 88  | 78/79 | 3452/3 | UnboundLocalError in app.py restyle teardown |
| 8 | Nova  | Orion | PASS_LEGITIMATE         | 101 | 79/79 | 3455/0 | - (clean legitimate solve) |
| 9 | Nova  | Orion | FAIL_MISSED_REQUIREMENT | 71  | 74/79 | 3453/0 | sibling stylesheet + nested `& + Label` + :not(#c2) + :not(:first-child) |
| 10| Nova  | Orion | FAIL_MISSED_REQUIREMENT | 83  | 78/79 | 3455/0 | :not(#c2) cache leak |

Tally: 1 PASS / 9 FAIL, all FAIR (no FAIL_TEST_MISMATCH, no agent_blame_unfair, no external errors).
Pass rate 1/10 = 10% (target band). Solvability MET (run 8). Scattered fair difficulty (no
universal/0%-trap). RESULT: ADMIN APPROVED. Submission left in place (not moved/copied) per user
instruction.
