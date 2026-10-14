# pyocd-dwt-watchpoint-planner - eval results

No platform batch yet.

## Local validation (SLICE, 2026-09-29)

Docker clean room: clone of 3078bf1 with .git, Dockerfile from the problem folder, image built with
test.patch (+ solution.patch for the solution image), runs as uid 1000 with `--network none`.

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 18 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 18 tests, 18 failures |

- Patches apply and unapply cleanly in both orders.
- No `::` in any JUnit classname/name; all ids unique.
- effective_loc_check.py: raw 188, human-effective 152, padding-floor 121, 5 files (slice, under
  floor by design).
- Mutants: 5 of 6 designed trap mutants killed (see feedback.md).

## Local validation (FINISH, 2026-09-30)

Same clean room (clone of 3078bf1 with .git, uid 1000, `--network none`).

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 49 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 49 tests, 49 failures |

- Patches apply and unapply cleanly; test.sh 100755; both patches ASCII; no `::` in JUnit ids.
- Full unit suite with solution (dev mount): 1149 passed, 41 skipped.
- effective_loc_check.py: raw 262, human-effective 220, padding-floor 178, 7 files.
- 22/22 mutants killed. Planner optimality: 4000 random cases vs brute force, 0 mismatches.

## Local validation (description rewrite + coverage round, 2026-09-30)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 53 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 53 tests, 53 failures |

Patches reversible, no `::` ids, 22/22 mutants killed. meta.md body 650 words.

## Local validation (Solution Quality fix, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 56 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 56 tests, 56 failures |

Patches reversible, no `::` ids, 25/25 mutants killed. human-effective 223 (raw 263), 7 files.

## Local validation (Solution Quality fix #2, bounded planner, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 61 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 61 tests, 61 failures |

Patches reversible, no `::` ids, 25/25 mutants killed, planner oracle 4000/4000 optimal, 4 GiB refusal
instant. human-effective 234 (raw 274), 7 files. Dead v1 post-loop `if blocks` check removed.

## Local validation (Auto Review fixes, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 65 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 65 tests, 65 failures |

Patches reversible, no `::` ids, 29/29 mutants killed. human-effective 240 incl. 6 doc lines (234 code), 8 files.

## Local validation (flush-in-transaction fix, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 71 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 71 tests, 71 failures |

Patches reversible, no `::` ids, 31/31 mutants killed. human-effective 248 (raw 289), 8 files incl. 6 doc lines.

## Local validation (lswatch init, zero-size object, commander lengths, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 73 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 73 tests, 73 failures |

Patches reversible, no `::` ids, 38/38 mutants killed (symbol_ignored retargeted). human-effective 249 (raw 290),
8 files incl. 6 doc lines.

## Batch 1 (2026-10-01): 0/11 (10 Nova + 1 Vega), 73-test suite

| Run | Verdict | New passed | Failed tests (beyond the two 11/11 traps) | Approach note |
|---|---|---|---|---|
| Vega #1 | MISSED_REQ | 66/73 | pair_write_leaves_nothing_listed, lswatch_before_any_watch | 7 files, no flush |
| Nova #10 | MISSED_REQ | 65/73 | pair_write_leaves_nothing_listed, lswatch_before_any_watch, lswatch_counts | lswatch wording |
| Nova #9 | MISSED_REQ | 24/73 | 49 tests: v1 planner, allocation, hit, commander | v1 planner broken |
| Nova #8 | MISSED_REQ | 62/73 | removed/reused-before-query (3), step/reset drain (3) | no capture before remove |
| Nova #7 | MISSED_REQ | 61/73 | unreported halt, step/reset drain, zero-size object, cannot-fit, below-one cmd | |
| Nova #6 | MISSED_REQ | 47/73 | whole v2 pair/fallback path, removal-capture, step/reset drain, continue | v2 pair broken |
| Nova #5 | MISSED_REQ | 65/73 | step/reset drain, plain halt after reset | no step/reset drain |
| Nova #4 | MISSED_REQ | 68/73 | none | ONLY the two traps; 324 human-eff |
| Nova #3 | MISSED_REQ | 66/73 | step/reset drain | |
| Nova #2 | MISSED_REQ | 64/73 | step/reset drain, plain halt after reset, cannot-fit | |
| Nova #1 | MISSED_REQ | 68/73 | none | ONLY the two traps; 288 human-eff; regenerated docs |

Kill counts: deferred_write[1|2] 11/11, PSoC6 family reset 11/11, PSoC64 family reset [CORE|SYSTEM] 11/11,
step_discards 7, reset_discards 7, plain_halt_after_reset 6, then 3 and below. No run flushed; no run touched
target_psoc6.py. Evaluators: description_clear true, tests_deterministic true, no blocker, all FAIL_MISSED_REQUIREMENT.
Trajectory step counts are collapsed (4-6 per run), so message counts are not measurable from these files.
Both near-misses (Nova #4, Nova #1) probe each MASK with 31 and read back; no FP exposure found on them.

## Local validation (option B: deferred-write tests cut, family-reset sentence in meta, 2026-10-01)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 71 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 71 tests, 71 failures |

Patches reversible, no `::` ids, 32/32 mutants killed (flush mutants retired with the cut tests).
Replaying batch 1's junit results on the 71-test suite: Nova #4 and Nova #1 pass (2/11); every other run
fails a stated trap. The new meta sentence will change the family-reset kill count in a fresh batch.

## Batch 2 (2026-10-02): 0/10 Nova, 71-test suite, option-B meta (773 words, family-reset sentence present)

| Run | Verdict | New passed | Failed tests | Note |
|---|---|---|---|---|
| Nova #10 | MISSED_REQ | 60/71 | unreported-halt, step hit, step/reset/family drain, bkpt+watch, commander step x2 | |
| Nova #9 | MISSED_REQ | 65/71 | unreported-halt, step/reset/family drain | |
| Nova #8 | MISSED_REQ | 68/71 | v2 single fallback (3) | drains every run path incl. PSoC |
| Nova #7 | MISSED_REQ | 61/71 | unreported-halt, step/reset/family, lswatch fresh 0, zero-size object, "Set write watchpoint" wording | |
| Nova #6 | REGRESSION | 70/71 | test_watch_reports_a_range_that_cannot_fit ONLY: printed "Set write watchpoint at" | UNFAIR kill (unstated base wording) |
| Nova #5 | MISSED_REQ | 65/71 | step/reset/family drain, zero-size object | |
| Nova #4 | MISSED_REQ | 64/71 | unreported-halt, step/reset/family drain | |
| Nova #3 | MISSED_REQ | 62/71 | capture-before-remove (3), step/reset/family drain | |
| Nova #2 | MISSED_REQ | 60/71 | capture-before-remove (3), step/reset/family drain, zero-size, wording | |
| Nova #1 | MISSED_REQ | 63/71 | reset/family drain, zero-size + cannot-fit + below-one (all wording) | |

Kills: reset_discards 8, family reset x3 8, step_discards 7, plain_halt_after_reset 6, unreported_halt 4,
zero_size 4 / cannot_fit 4 (mostly the acknowledgement wording), capture-before-remove 2-3.
Unfair: tests asserted pyOCD's existing "Set watchpoint at" / "Failed to set watchpoint at" text, which meta
never states; 4 runs rephrased it. Fixed to outcome checks. Nova #6 passes the fixed suite (1/10).

## Local validation (batch-3 candidate: 73 tests, outcome-based commander tests, 395-word meta, 2026-10-02)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 73 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 73 tests, 73 failures |

Patches reversible, no `::` ids, 34/34 mutants killed.

## Local validation (Test Quality fix, 75 tests, 2026-10-02)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 75 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 75 tests, 75 failures |

Patches reversible, no `::` ids, 34/34 mutants killed.

## Local validation (final pre-batch-3 suite, 76 tests, 2026-10-03)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 76 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 76 tests, 76 failures |

Patches reversible, no `::` ids, 36/36 mutants killed. test.patch contains the lswatch prefix-match fix.

## Batch 3, re-eval 1 (2026-10-03): 0/10 Nova, 76-test suite, 395-word humanized meta

| Run | New passed | Failed beyond family-reset (3) | Note |
|---|---|---|---|
| Nova #10 | 70/76 | several-match, earlier-access, lswatch-reuse hit | reports every match |
| Nova #9 | 47/76 | whole v2 path, step drain, continue | v2 broken |
| Nova #8 | 70/76 | removal capture (3) | |
| Nova #7 | 64/76 | several-match x2, removal capture x3, step/reset drain, lswatch reuse | |
| Nova #6 | 68/76 | several-match x2, lswatch reuse, ELF object x2 | reports every match |
| Nova #5 | 67/76 | several-match x2, removal capture x3, lswatch reuse | reports every match |
| Nova #4 | 73/76 | none | ONLY the family resets |
| Nova #3 | 62/76 | v2 pair path, several-match x2, lswatch reuse | |
| Nova #2 | 60/76 | v2 pair path, step drain, continue | |
| Nova #1 | 70/76 | removal capture x3, step hit, step drain, bkpt+watch | passes family resets |

Kills: family reset x3 9/10 (plain CortexM reset only 1/10; no patch touches target_psoc6.py),
several-match / earlier-access / lswatch-reuse hit 6/10 (all from runs reporting EVERY matching watchpoint in
creation order), removal-capture 4-6, step drain 4, v2 pair path 3.
Diagnosis: two humanizer-induced description regressions. (1) The family-reset sentence became a parenthetical
without `target_psoc6.py`; batch 2's explicit sentence had every reset-draining run also drain PSoC. (2) "naming
the watchpoint set first if several match" reads as an ordering rule, not "only one". All 10 runs probe MASK by
writing 31.

## Local validation (batch-4 candidate: 77 tests, meta with explicit family resets + "only the one set first", 2026-10-03)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 77 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 77 tests, 77 failures |

Patches reversible, no `::` ids, 37/37 mutants killed.

## Batch 4, re-eval 1 (2026-10-03): 0/10 graded; 1 FP-flagged pass, 1 verifier blocker

| Run | New passed | Failed | Note |
|---|---|---|---|
| Nova #10 | 37/77 | 40 (v1 planner broken) | |
| Nova #9 | 72/77 | family reset x3, ELF object x2 | |
| Nova #8 | 69/77 | removal capture x3, family x3, ELF object x2 | |
| Nova #7 | 74/77 | comparator limits x2, lswatch fresh | |
| Nova #6 | 67/77 | family x3, lswatch x4, commander lengths x3 | REGRESSION verdict |
| Nova #5 | 74/77 | family x3 ONLY | VERIFIER BLOCKER: export dropped target_psoc6.py |
| Nova #4 | 76/77 | lswatch fresh count | |
| Nova #3 | 77/77 | none | FP: evaluator says no clear on PSoC6 NSRST / PSoC64 HARDWARE (no PRE_RESET there) |
| Nova #2 | 58/77 | 19 (hit capture/drain) | |
| Nova #1 | 59/77 | v2 pair path, removal capture, step drain, family | |

PLATFORM EXPORT BUG (evidence): in batches 3 and 4, 19 of 20 runs edited pyocd/target/family/target_psoc6.py
(apply_patch, no failures; their own final `git status` lists it as M, often with
pyocd/target/builtin/target_s5js100.py too), and NONE of the 20 exported solution patches or workspace diffs
contains any file under pyocd/target/. In batch 2 all 3 runs that edited it were exported with it. So every
family-reset kill in batches 3-4 is suspect: the graded patch is not the agent's code. The repo file is
tracked, not ignored, LF, `*.py text`; harness protected.json is []. Nothing in our artifact excludes it.
Checked the dropped edits in the trajectories: Nova #3 added explicit `if reset_type is NSRST` (PSoC6) and
`if reset_type is HARDWARE` (PSoC64) clears in target_psoc6.py, the exact branches its FP verdict says are
missing; Nova #5 cleared on every branch. With the file exported, batch 4 reads 2/10 genuine passes.

## Local validation (79 tests: + PSoC6 NSRST / PSoC64 HARDWARE resets, 7-byte rmwatch, 2026-10-03)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 79 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 79 tests, 79 failures |

Patches reversible, no `::` ids, 39/39 mutants killed.

## Batch 4, re-eval 2 (2026-10-03): 79-test suite, 0/10 graded, 2 External Error (verifier)

Same batch-4 solutions. Export still contains nothing under pyocd/target/ (9/10 runs edited target_psoc6.py).
Platform now flags Nova #3 (77/79, fails only NSRST + HARDWARE) and Nova #5 (74/79, fails only the 5 family
cases) as FAIL_EXECUTION_ERROR_EXTERNAL: "solution-patch capture dropped a tracked production-file change".
Nova #4 (76/79) has no PSoC edit: fails NSRST, HARDWARE (PRE_RESET-only clear) and fresh lswatch, genuine.
Without the family-reset tests: Nova #3 and Nova #5 pass, everyone else fails a stated rule -> 2/10.

## Local validation (PSoC rule dropped: 74 tests, meta 383 words, 2026-10-03)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 74 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 74 tests, 74 failures |

Patches reversible, no `::` ids, 35/35 mutants killed. Neither patch touches pyocd/target/.
human-effective 247 (raw 288), 7 files.

## Local validation (token-setter fix, 74 tests, 2026-10-04)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 74 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 74 tests, 74 failures |

Patches reversible, no `::` ids, 36/36 mutants killed. human-effective 252 (raw 300), 7 files. PSoC reset probe:
all 5 reset types clean without touching pyocd/target/.
No-.git rebuild check (git archive snapshot + patch -p1): image builds, `test.sh new` exits 0 (all new tests pass).

## Local validation (disconnect test added, 76 tests, 2026-10-04)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 76 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 76 tests, 76 failures |

Patches reversible, no `::` ids, 37/37 mutants killed.

## Batch 6 (2026-10-04): 3/10 Nova, 76-test suite, meta scoped to CortexM.reset()

| Run | Verdict | New passed | Failed |
|---|---|---|---|
| Nova #10 | PASS_LEGITIMATE | 76/76 | FP panel: genuine (judge-c dissent over force_signal and PSoC reset, both out of prompt scope) |
| Nova #9 | PASS_LEGITIMATE | 76/76 | FP panel: genuine (dissent over 32-bit address bounds and PC echo, out of scope) |
| Nova #5 | PASS_LEGITIMATE | 76/76 | FP panel: genuine, unanimous (note: v1 FUNCTION carries the v2 ACTION bit, untested) |
| Nova #8 / #7 / #1 | MISSED_REQ | 72-73/76 | removal / comparator-reuse before the query (x3); #1 also fresh lswatch |
| Nova #6 | MISSED_REQ | 74/76 | ELF data object sizing (x2) |
| Nova #4 | MISSED_REQ | 69/76 | removal capture x3, step/reset drain |
| Nova #3 | MISSED_REQ | 52/76 | hit reporting / planning broadly |
| Nova #2 | MISSED_REQ | 71/76 | pair-write listing, disconnect x2, fresh lswatch |

Kills: removal/reuse-before-query 5 each, fresh lswatch 4, step/reset drain 2, ELF object 1-2.
Passing patches ~340 effective LOC (Auto Review), 60-71 messages. Auto Review: Prompt 3/3, Tests 1/3 (T5: probe
test demanded eager MASK probes of unused comparators), Solution 3/3.

## Local validation (probe test narrowed, 76 tests, 2026-10-04)

| Config | Mode | Result (3 runs each, identical) |
|---|---|---|
| solution | base | 1141 tests, 0 failures |
| solution | new | 76 tests, 0 failures (also root and uid 4242) |
| no solution | base | 1141 tests, 0 failures |
| no solution | new | 76 tests, 76 failures |

Patches reversible, no `::` ids, 37/37 mutants killed (probe_with_requested_mask still caught by the narrowed test).

## Batch 7 (2026-10-09, NEW-MODEL GATE): Nova 0/11, Orion 0/4

| Agent | Result | Seq length | Notes |
|---|---|---|---|
| Nova x11 | 0/11 (67-73/76) | avg 513k (min 274k) | step/reset/unreported-halt drain 10/11 each; fresh lswatch 11/11; comparator limits 5; v2 too-many-singles 5 |
| Orion x4 | 0/4, every run 75/76 | avg 76k | ALL four fail ONLY test_lswatch_before_any_watch_counts_every_comparator |

Diagnosis: test_lswatch_before_any_watch_counts_every_comparator is UNFAIR. It runs `lswatch` on a DWT that was
never initialized, a state real pyOCD never reaches: CoreSight discovery calls `cmp.init()` on the DWT at connect
(pyocd/coresight/discovery.py:64). Only the fake core skips it. It killed 15/15 runs of both agents.
Fixed to `test_lswatch_after_discovery_counts_every_comparator` (calls `core.dwt.init()` first, like discovery).
With it fixed, Orion reads 4/4 -> TOO EASY under the new gate (needs 1/4). Nova stays 0/11.

## Batch 7 local replay on the hardened suite (2026-10-09, 78 tests)

| Run | Result | Failing tests |
|---|---|---|
| Orion_Nova_2 | PASS 78/78 | - |
| Orion_Nova_1, 3, 4 | 76/78 | both top-of-memory tests (sole failures) |
| Nova x11 | 0/11 (68-74/78) | each also fails both top-of-memory tests |

Orion 1/4, Nova 0/11: inside the new gate. Awaiting platform re-eval to confirm.
