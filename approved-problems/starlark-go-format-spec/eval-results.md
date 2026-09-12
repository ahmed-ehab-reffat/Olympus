# eval-results.md - starlark-go-format-spec

Per-agent eval table, one section per platform batch. Local-only.

Fingerprint every batch (content-equality freshness): `git hash-object solution.patch test.patch meta.md Dockerfile BASE_COMMIT.txt`, the platform baseline/new test counts, and date+time.

---

## Local validation (pre-platform) -- 2026-06-19

Fingerprint (final bytes): sol=815c4dd9659e72b7f38d39a4c5774dcf7b4b3132 test=8913d3bc122dcd9456144aa67a189acc0d541709 meta=9dfafc3520abdbab61058c3e4832658eeda0e639 docker=4bd7588e26e5c37b11ac2ba40e8197a12503b005 base=5d4d981df6628441259aa2c92b0094661cf459bf
(Updated after the round-2 review fixes: rewrote the stale formatFloat doc comment; %s/%r now ignore the printf numeric flags like CPython. solution.patch only; re-fuzzed % incl. %s+flags = 0 mismatches; 4-cell re-PASS base|base 75/0, base|new 146/146 FAIL, sol|base 75/0, sol|new 146/0. 694 effective LOC. STILL NEEDS A FRESH AGENT BATCH on these bytes -- solvability remains unevidenced.)
(Re-validated 2026-06-19 after Batch-1 recalibration -- empty-type float made engine-consistent (== str / g), CPython-only #g dropped from the tested surface. 5 source files, 693 effective LOC. Explicit-type behaviors re-fuzzed vs CPython (str.format + %: 0 real mismatches; only empty-type-float intentionally now follows Starlark str/g). new suite 146 testcases / 142 subtests; base 75. 4-cell: base|base 75/0 PASS, base|new 146/146 FAIL, sol|base 75/0 PASS (no regression), sol|new 146/0 PASS. meta 394 words, ASCII-clean. THIS BUILD NEEDS A FRESH AGENT BATCH -- Batch 1 (0/6) ran on the PRE-recalibration bytes and is STALE evidence for solvability.)
(Re-validated 2026-06-19 after the Task-Quality Crit-08 fix -- unified the % interpolation operator with str.format (printf flags/width/precision through the shared renderers; eval.go now in solution.patch -> 5 source files, 704 effective LOC). Differential-fuzzed % (~5,700) + str.format (~4,400) vs CPython 3.12 -> 0 mismatches. new suite 155 testcases / 151 subtests across 4 test funcs; base suite 75. 4-cell: base|base 75/0 PASS, base|new 155/155 FAIL, sol|base 75/0 PASS (no regression on existing %-tests), sol|new 155/0 PASS.)
Image: public.ecr.aws/d3j8x8q7/olympus-base-go (Go 1.26.3). Run offline (--network none) + non-root (--user 1000:1000) from a clean `git archive BASE` checkout.

| Check | Result | Notes |
|---|---|---|
| Patches apply (both orders) | PASS | git apply --check test.patch + solution.patch clean |
| Docker BARE build (EnvQuality: BASE + Dockerfile, no patches) | PASS | go mod download + go install go-junit-report + go build ./... |
| test.sh base on BASE-STATE | PASS | 75 testcases, 0 failures |
| test.sh new on BASE-STATE | FAIL (correct) | every new testcase fails -> entire new suite is F2P |
| test.sh base on SOLUTION-STATE | PASS | 75 testcases, 0 failures (no regressions) |
| test.sh new on SOLUTION-STATE | PASS | new suite passes, 0 failures |
| oracle fuzz (Go vs CPython 3.12) | PASS | ~12,500 random+catalog (value,spec) cases across 2 seeds, 0 mismatches |
| effective LOC | PASS | 5 files, 1050 raw added, 704 human-effective (>= 430 floor; after the Crit-08 % unification added eval.go) |

4-cell: base|base PASS, base|new FAIL, sol|base PASS, sol|new PASS. Solvability proven (reference solution passes every F2P test). All new tests fail on base (feature absent) so the full new suite is F2P -- no before_f2p_unexpectedly_passing risk. (Exact testcase count is re-confirmed by the final re-validation below; the Fingerprint line above pins the bytes.)

---

## Platform eval batches

### Batch 2 -- 10 agents (RECALIBRATED build) -- 2026-06-19 -- APPROVED (1/10 = ~10%)
Fingerprint: sol=815c4dd9 test=8913d3bc meta=9dfafc35 docker=4bd7588e base=5d4d981d. Platform JUnit: baseline 75 / new 146.

| Solver | Eval | Verdict | msgs | files | LOC | Miss (fair, scattered) |
|---|---|---|---|---|---|---|
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 93 | 3 | 661 | grouping-zero-pad + int-as-float + comma-with-binary |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 75 | 4 | 878 | int-as-float (precision checked before float-type) |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 105 | 4 | 809 | grouping-zero-pad + int-as-float |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 76 | 4 | 790 | grouping-zero-pad + %-float-precision-zero |
| Nova | Nova | FAIL_MISSED_REQUIREMENT | 118 | 3 | 714 | int-as-float + grouping-zero-pad |
| **Orion** | **Orion** | **PASS_LEGITIMATE** | **202** | **5** | **1078** | -- (solved) |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 104 | 4 | 890 | grouping-zero-pad (float) |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 82 | 4 | 824 | grouping-zero-pad (float) |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 110 | 5 | 913 | sign-aware = + grouping-zero-pad + %-float-precision |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 115 | 4 | 958 | %c width right-align |

PROFILE: 1 PASS / 10 = ~10% (solvability + pass-rate gates met). SOLVER-MEDIAN messages = 202 (single solver Orion; >100 with huge margin; solver files 5, LOC 1078). All 9 fails FAIR (agent_blame_unfair=false, blocker=none, description_clear=true). Scattered across documented edges; the load-bearing universal edge (grouping-aware zero-pad) was solved by Orion and missed by 9/10 -- carrying the ~10% rate. The recalibration (vs Batch 1) flipped 0/6 -> 1/10 by removing exactly Orion's two prior blockers (empty-float engine-inconsistency bug + #g) while keeping the scattered difficulty. APPROVED by human reviewer.

### Batch 1 -- 6 agents (pre-recalibration build) -- 2026-06-19 -- SOLVABILITY 0/6 (FAIR fails) -- SUPERSEDED/STALE
Fingerprint at eval: the pre-recalibration build (empty-type float = CPython repr; #g tested). All 6 FAIL_MISSED_REQUIREMENT, all FAIR (agent_blame_unfair=false, blocker=none, description_clear=true, tests_deterministic=true).

| Solver | Eval | Verdict | msgs | files | LOC | Dominant miss |
|---|---|---|---|---|---|---|
| Orion | Orion | FAIL_MISSED_REQUIREMENT | 204 | 5 | 1104 | empty-float repr/precision + #g (ONLY these) |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 116 | 4 | 815 | grouping-zero-pad + empty-float |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 125 | 6 | 755 | grouping-zero-pad + empty-float + =-on-string |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 99 | 5 | 945 | grouping-zero-pad + #g + empty-float + %c |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 149 | 3 | 734 | grouping-zero-pad + empty-float + #g |
| Nova | Orion | FAIL_MISSED_REQUIREMENT | 75 | 4 | 900 | empty-float + grouping-zero-pad |

DIAGNOSIS (per olympus-difficulty-calibration "deterministic universal miss = 0%-trap"): the fails are FAIR but NOT scattered -- they cluster on the SAME surfaces every run. TWO problems:
(1) **Empty-type float was a genuine BUG + unfair trap**: my `{}`-format reimplemented CPython's repr exponent threshold, but Starlark's OWN `str()`/`Float.format` uses Go's shortest-`g` (so `str(1e15)`="1e+15"). "matches repr" pointed agents at the codebase's repr (they reused Float.format -> "1e+15"), which my test rejected (wanted CPython "1000000000000000.0"). Inconsistent with the engine AND unwinnable -> EVERY agent missed it.
(2) **#g trailing-zeros** is a CPython-only behavior with no Starlark precedent; even Orion (the strongest, 204 msgs, which solved everything else incl. grouping-zero-pad) missed it.
Orion's ONLY failures were (1)+(2). The grouping-aware zero-pad (the intended hard edge) was solved by Orion and missed by 5/6 -> good hard-but-solvable difficulty, KEPT.

RECALIBRATION (de-trap the universal miss; keep the scattered difficulty -- a FAIR clarification, not difficulty-easing):
- Empty-type float now ENGINE-CONSISTENT: no precision -> Starlark `str`/`Float.format` (so `{}`-format == `str`); with precision -> standard `g`. Discoverable (reuse Float.format / implement g), consistent, solvable. Verified my `g` matches CPython `g` (incl. `format(0.0,'.4g')`='0'). meta now says "an empty type renders a float as `str` does, and with a precision uses the general format `g`."
- Dropped the CPython-only `#g`-trailing-zeros from the tested+documented surface (removed 3 tests; removed the float-`#` meta clause). The solution still renders `#g` correctly (untested, engine-authoritative).
- KEPT grouping-aware zero padding + %c-zero-ignored + =-on-string + base-grouping + sign-aware pad + nested + accessors as the difficulty (Orion solved grouping; Novas missed it).
- Explicit-type behaviors re-fuzzed vs CPython after the change: STR.FORMAT 0 real mismatches, PERCENT 0 mismatches (only empty-type-float intentionally diverges from CPython, now matching Starlark str/g).

EXPECTED after recalibration: Orion-class agents (which solved everything except the now-fixed empty-float+#g) should PASS -> solvability >=1; most agents still fail on grouping-zero-pad etc. -> ~1-2/10. Solver msgs ~150-204 (Orion 204) -> >100 floor clears with margin. RE-RUN the platform batch to confirm.
