# ray-optics-module-inlining - eval results

No platform batch yet.

## Local validation (SLICE, 2026-10-05)
| Tree | Mode | uid 1000 | root | 4242 |
|---|---|---|---|---|
| base + test.patch | base | 1301/1301 pass | same | same |
| base + test.patch | new | 13/13 fail | same | same |
| + solution.patch | base | 1301/1301 pass | same | same |
| + solution.patch | new | 13/13 pass | same | same |

Image factory-ray-optics-module-inlining, --network none, cold build 364 s. No `::` in JUnit ids.
Effective LOC (hook): 299 human-effective, 398 raw, 2 files.
Flakiness 3x: not run yet (FINISH).

## Batch 1 (2026-10-11) - Orion x4, pre-fix meta (humanized cap "no distinct variables have identical names")
| Run | Verdict | Msgs | Seq len | Files | LOC | Failed tests | Approach |
|---|---|---|---|---|---|---|---|
| Orion_Orion_2 (#3) | TEST_MISMATCH (EB verifier) | 46 | 83K | 7 | 769 | merges loops | propertyUtils/moduleTransformations.js; handles formal shadow |
| Orion_Orion_3 (#2) | TEST_MISMATCH (EB verifier) | 36 | 82K | 3 | 781 | merges loops; function arg same name | moduleUtils.js, no fresh child loop names |
| Orion_Orion_1 (#4) / _4 (#1) | TEST_MISMATCH (EB mixed canvas / verifier) | 40 / 39 | 80K / 79K | 4 / 4 | 740 / 698 | merges loops; function arg same name | moduleUtils.js, same |
(The two 4-file runs could not be told apart from the pasted summaries.)
Verdict: invalid batch (fixtures outside the stated domain). Replay on fixed fixture: same kills.

## Batch 2 (2026-10-13) - Orion x4, meta round 3 (cap fix), 15-test suite
| Run | Verdict | Seq len | Files | +LOC | Failed tests | Approach |
|---|---|---|---|---|---|---|
| Orion_Orion_1 (#4) | no verdict, empty patch | 36K | 0 | 0 | all 15 (nothing written) | died after ~2 min, 4 steps |
| Orion_Orion_2 (#3) | PASS_LEGITIMATE | 84K | 4 | 740 | - | transactional rewrite, scope-aware incl. loop shadowing |
| Orion_Orion_3 (#2) | FAIL_MISSED_REQUIREMENT | 92K | 3 | 662 | keeps negative literal positions and parameters | negative number substituted without parens (-2^2) |
| Orion_Orion_4 (#1) | PASS_LEGITIMATE | 49K | 2 | 358 | - | moduleUtils.js, lexical function inlining, fresh loop names; rename ignores loop scope |
Result: 2 passes / 3 working (2/4 if the empty run counts) = too easy for the Orion gate (<= 25%). No Nova runs yet.
Replay (worktrees/ray-optics-tools/probe3): the 4 Auto Review gap tests + 9 more candidates (nesting 3 levels,
middle-module removal, name collisions, 2nd ray point, two containers) kill nobody. Only loop-variable-shadows-
own-parameter in rename divides them: o2 passes, o3 and o4 fail 3/3 (row loop, nested piece loop, instance row loop).
Replay of the 23-test suite: ref 23/23, o2 23/23, o3 19/23, o4 20/23 -> 1/4 on this population.

## Batch 3 (2026-10-13) - Orion x4, meta round 4 (loop-shadow clause), 23-test suite
| Run | Verdict | Seq len | Files | +LOC | Failed tests | FP panel |
|---|---|---|---|---|---|---|
| Orion_Orion_1 (#4) | PASS_LEGITIMATE | 79K | 3 | 733 | - | genuine (judges: `2 pi a` breaks, shared w/ reference then) |
| Orion_Orion_2 (#3) | PASS_LEGITIMATE | 80K | 3 | 673 | - | genuine (judges: `i r` breaks, shared) |
| Orion_Orion_3 (#2) | PASS_LEGITIMATE | 89K | 5 | 787 | - | genuine |
| Orion_Orion_4 (#1) | PASS_LEGITIMATE | 116K | 3 | 854 | - | FALSE POSITIVE: whole-scene pre-check refuses when an unrelated instance errors |
Result: 4/4 (too easy). Stated loop-shadow rule handled by all four. No Nova runs yet.
Replay of the 30-test suite (worktrees/ray-optics-tools/probe3/out/suite30.txt): ref 30/30; every one of the 7 saved
Orion solutions fails >= 1: b3o1 `2 pi a`; b3o2 `i r`; b3o3/b3o4 broken-instance + both products; b2 o2/o4 broken
instance + `2 pi a` (+ shadow for o4); b2 o3 negative literal + shadow.

## Batch 4 (2026-10-14) - Orion x4, meta round 6 (function-loop-var cap), 32-test suite
| Run | Verdict | Seq len | Files | +LOC | Failed tests | Approach |
|---|---|---|---|---|---|---|
| Orion_Orion_1 (#4) | FAIL_MISSED_REQUIREMENT | 102K | 2 src (+1 test) | 778 | removal + rename with an unrelated broken instance | moduleUtils.js + whole-scene preflight validator |
| Orion_Orion_2 (#3) | FAIL_MISSED_REQUIREMENT | 90K | 2 src (+2) | 765 | same two | same shape, shared validator |
| Orion_Orion_3 (#2) | FAIL_REGRESSION | 94K | 2 src (+1) | 775 | same two | shared transaction validator rejects any instance error |
| Orion_Orion_4 (#1) | FAIL_REGRESSION | 85K | 3 src (+1) | 671 | same two | shared commit helper rejects any instance error |
Result: 0/4. All four pass the other 30 tests, including both implicit products, loop shadowing, negative literals and the
new refusal/multi-definition cases. All four evaluators: description_clear true, rule "inferable from codebase"
(base removeModule ignores unrelated instances; expandObjs stores object-local errors), "stating it would improve clarity".
Probe (probe3/probe-b4): batch-4 solutions pass function-body products, step-bound refusal and whole-scene-unchanged
refusal; equation products are out of domain (base equations with juxtaposed literals do not evaluate before the call).
No test lever splits this batch: it is 0/4 or 4/4 depending only on the broken-instance pair.
History of the broken-instance pair: handled by b2 o3, b3o1, b3o2; missed by b2 o2/o4, b3o3/b3o4, b4 x4 -> 3/11.

## Batch 5 (2026-10-14) - Orion x4 (folder 5 runs 1-4; runs 5-8 are the batch-4 runs again), 32-test suite
| Run | Verdict | Seq len | +LOC | Failed tests | FP panel |
|---|---|---|---|---|---|
| Orion_Orion_1 (#4) | FAIL_REGRESSION | 109K | 764 | broken-instance remove + rename | - |
| Orion_Orion_2 (#3) | PASS_LEGITIMATE | 113K | 767 | - | FALSE POSITIVE: rewriteEquation splices JS-printed numbers into LaTeX; 1e-7 / cos(pi/2) round-off read as 1*e-7 |
| Orion_Orion_3 (#2) | PASS_LEGITIMATE | 116K | 769 | - | genuine (judge findings shared with the reference: for-before-if on merged rows, raised loop cap) |
| Orion_Orion_4 (#1) | FAIL_REGRESSION | 75K | 695 | broken-instance remove + rename | - |
Orion across batches 4+5: 2/8 raw, 1/8 after the FP. No Nova runs yet.
Fix (34-test suite): two tests with a tiny equation parameter (computed cos(90 deg) for remove, scene value 1e-7 for
inline). Replay: b5o2 fails both, b5o3 34/34, b5o1/b5o4 unchanged (broken-instance pair). All 11 older saved
solutions pass the tiny-value probe (probe3/out/tiny-old.txt). Re-eval of this batch should read 1/8 genuine.

## Batch 6 (2026-10-14/15) - Nova x8 (fresh) + Orion re-eval of batches 4+5, 34-test suite
| Run | Verdict | Seq len (compactions summed) | New tests | Failed tests |
|---|---|---|---|---|
| Nova #8 | FAIL | 235K | 27/34 | swap names, merged loops+if x2, negative literal, loop limit, row-loop shadow, nested-loop shadow |
| Nova #7 | FAIL | 228K | 28/34 | swap names, merged loops+if x2, loop limit, row-loop shadow, nested-loop shadow |
| Nova #6 | FAIL | 239K | 26/34 | merged loops+if x2, negative literal, both products, loop limit, row-loop shadow, nested-loop shadow |
| Nova #5 | FAIL | 217K | 32/34 | swap names, loop limit |
| Nova #4 | FAIL | 236K | 26/34 | coated lens remove, tiny cos value, swap names, merged loops+if x2, loop limit, row-loop shadow, keeps other instances |
| Nova #3 | FAIL | 241K | 32/34 | loop limit, nested-loop shadow |
| Nova #2 | FAIL | 340K (261+78) | 31/34 | negative literal, loop limit, nested-loop shadow |
| Nova #1 | FAIL | 580K (262+318) | 32/34 | loop limit, nested-loop shadow |
Nova 0/8. Seq length estimate from trajectory.json (max prompt+completion per window, summed over compactions):
avg 290K; without summing, avg of single-step maxima 247K. Platform figure is the authority.
Orion re-eval (same 8 solutions as batches 4+5): 1/8 pass = b5o3 (FP panel: genuine, high confidence; judges'
70/70 and 76/76 probes). b5o2 now fails the two tiny-value tests; the other six fail the broken-instance pair.
Gate: Nova 0/8 + Orion 1/8 met, pending the platform's Nova sequence-length average.

## Auto Review round (2026-10-15): Revision Requested (Description 3/3, Tests 1/3, Solution 1/3)
Probe (probe3/probe-ar2, out/ar2.txt) over the reference + all 23 saved solutions:
- Invalid targets (missing module, index 3 / -1, non-instance row, missing module/param, var name): all pass all.
- Dependent loop step (remove + inline), parent var capturing a free symbol (remove + inline): all pass all.
- Stricter child loop limit (inline + remove), default-limit child overflow, outer overflow: the reference and 22/23
  solutions change the expansion; only b6n5 (snapshot-verify-restore) keeps it. b5o3 fails them -> not tested.
Suite 44 replay (out/suite44.txt): the 10 new tests kill nothing; b5o3 44/44; every Nova run unchanged.

## Batch 7 = re-eval of batch 6 on the 44-test suite (2026-10-16) - ACCEPTED
| Run | Verdict | Failed /44 | Failed tests | Files | +LOC | ptok |
|---|---|---|---|---|---|---|
| Nova #1 | MISSED_REQ | 7 | swap, merge x2, negative literal, loop limit, row-loop shadow, nested shadow | 4 | 1974 | 17.5M |
| Nova #2 | MISSED_REQ | 6 | swap, merge x2, loop limit, row-loop shadow, nested shadow | 3 | 1837 | 15.9M |
| Nova #3 | MISSED_REQ | 8 | merge x2, negative literal, both products, loop limit, row-loop shadow, nested shadow | 3 | 1697 | 16.2M |
| Nova #4 | MISSED_REQ | 2 | swap, loop limit | 3 | 1760 | 14.2M |
| Nova #5 | MISSED_REQ | 8 | coated lens remove, near-zero equation, swap, merge x2, loop limit, row-loop shadow, keeps other instances | 3 | 1965 | 16.6M |
| Nova #6 | MISSED_REQ | 2 | loop limit, nested shadow | 3 | 1897 | 18.1M |
| Nova #7 | MISSED_REQ | 3 | negative literal, loop limit, nested shadow | 4 | 1835 | 19.9M |
| Nova #8 | MISSED_REQ | 2 | loop limit, nested shadow | 3 | 1657 | 31.6M |
| Orion #1-#5, #8 | MISSED_REQ / REGRESSION | 2 each | unrelated broken instance: remove + rename | 3-5 | 667-813 | 2.0-4.2M |
| Orion #6 | MISSED_REQ | 2 | tiny-value pair (near-zero, 1e-7) | 5 | 824 | 3.7M |
| Orion #7 | PASS_LEGITIMATE | 0 | - | 4 | 823 | 4.7M |
Nova 0/8, Orion 1/8. Per-test kills: loop limit 8, nested shadow 6, broken-instance pair 6+6, swap 4, row-loop
shadow 4, merge x2 4+4, negative literal 3, near-zero 2, 1e-7 1, products 1+1, coated lens 1, keeps other
instances 1. Killed nothing: 29/44 (all refusals, invalid targets, round-9 coverage). FP panel: Orion #7
genuine (high; 107/107 incl. its own tests, judges 571 + 9 probes). Auto Review Approved 3/2/3 (T4 Medium:
rename across two containing definitions, one uninstantiated). Human reviewer: ACCEPTED 2026-10-16.
