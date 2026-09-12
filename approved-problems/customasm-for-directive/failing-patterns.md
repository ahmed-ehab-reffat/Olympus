# Failing-Agent Patterns — customasm-for-directive

Paste every failing agent run here. Goal: harvest the trap that killed each agent so the
next revision stacks INTERDEPENDENT + MISDIRECTING traps and stays under the pass cap.

Confirm a trap only if it is MISDIRECTING (failing test points away from the fix) and not
single-point-fixable (Nova single-shots isolated self-revealing traps).

Reusable classes bubble up to `Instructions/FAILING-PATTERNS.md`.

---

## Confirmed traps (promote here once 2+ agents die on the same one)

| # | Trap | Failing test(s) | Why it misdirects | Confirmed by |
|---|------|-----------------|-------------------|--------------|
|   |      |                 |                   |              |

---

## Failing runs

## Run 1 — Nova (eval Nova) — FAIL (Missed Requirement)
- Stats: 19m12s · 25 files · 769 LOC · 101 msgs
- Grading: baseline_passed=True (691/691), new_tests_passed=False (81/94). Wrapper exit 101.
- Implemented most of `#for` correctly; 13 of 94 new tests failed, all around per-iteration local
  scope for dotted `.local` labels and constants (e.g. `deferred_bound_with_per_iteration_local_label`).
- Root cause: agent uniquified local names with numeric SUFFIXES but left them as hierarchy-level
  local declarations with NO per-iteration parent scope. Loop bodies with top-level `.local`
  symbols could not assemble. -> general class C-2 (scope-establishment vs name-uniquification).
- Misdirecting? Yes — the mangle approach passed 81/94 (all simple cases). Only scope-STRUCTURE
  tests exposed the flat model.
- Single-point-fixable? No — correct fix is a different model (real nested scope per iteration),
  not a rename tweak. 19m/25 files/769 LOC and still shipped the flat approach.

Lesson for hardening: this is already a strong trap (misdirecting, high-LOC, non-single-shot,
fair per the repo's existing `.local` model). ~86% new-pass. Load-bearing tests are the
scope-BOUNDARY ones. To push pass-rate lower without unfairness, add a couple more boundary
cases the mangle model can't fake:
- symbol declared in body visible/not-visible after the loop per spec,
- shadowing the same `.local` name across iterations must NOT collide,
- dotted/hierarchical local at TOP-LEVEL loop body (the one that broke here),
- forward-ref across the iteration boundary.
Keep the simple positive cases so ≥1 agent still passes (solvability). Confirm each added test
traces to a described behavior (scope independence) so Fairness holds.

## Run 2 — Nova (eval Nova) — FAIL, but NEARLY PASSED (⚠️ too-easy signal)
- Stats: 15m57s(+) · 25 files · 907 LOC · 76 msgs
- Grading: baseline_passed=True (691/691), new_tests_passed=False (91/94). Only 3 new tests failed.
- Different, BETTER approach than Run 1: kept loops as TEMPLATES, expanded clones BEFORE normal
  assembly, and inserted real scope MARKERS per iteration (step 21: "preserve loops as templates,
  expand clones before normal assembly"; step 24 "Implementing Scope Markers"). This directly
  attacks the C-2 scope model Run 1 botched — and it worked for all but 3 tests.
- Which 3 failed: not captured (run log truncated). Grab them from the eval next time — they are
  the load-bearing residual traps and must be identified to harden precisely.

⚠️ Trend across 2 Nova runs: 81/94 -> 91/94. The scope trap (C-2) is REAL but SOFTENING — a
competent template+clone+scope-marker approach nearly beats it. This pick is drifting toward
too-easy: if a 3rd agent lands the last 3 cases it PASSES, and Olympus caps at 20% pass. Do NOT
assume Run 1's 13-fail margin is the true difficulty; Run 2 shows the real floor is ~3 failing
tests. Before submitting:
1. Identify the 3 tests Run 2 failed (the actual difficulty) — build MORE cases in that exact
   sub-area, not more of the easy scope cases both agents already pass.
2. Add an interdependent 2nd trap so the near-miss agents can't clean up with one more pass
   (e.g. couple the scope model to address-convergence or forward-ref-across-iteration so fixing
   the last scope cases regresses something else).
3. Re-run a batch; if pass-rate is climbing toward passing, this is heading for a too-easy reject.

## Run 3 — Nova (eval Nova) — OUTCOME UNKNOWN (grading block not in paste)
- Stats: ~15m23s · LOC/files not shown · paste ended at step 85 "Implemented".
- Approach: "repeat AST plus structural fixed-point passes" — constants resolve, then structural
  expansion converges with label-address bounds. Uses `local_suffix` (step 58) PLUS structural
  fixed-point passes; reported all focused `for_*` tests green and ran the full regression before
  finishing. So it likely lands near-pass again, but the wrapper grading (baseline_passed /
  new_tests_passed) was NOT included — do not assume a result.
- TODO: paste the `[post_agent] Wrapper grading:` line for this run to classify it. If it also
  landed high (like Run 2's 91/94) or PASSED, that is a 3rd data point that this pick is too easy
  and needs the hardening in Run 2's notes before submit.

### Batch trend so far (customasm-for-directive, Nova)
| Run | Approach | New pass | Note |
|-----|----------|----------|------|
| 1 | flat name-mangle, no per-iter scope | 81/94 | died on C-2 scope structure |
| 2 | template + clone-before-assembly + scope markers | 91/94 | near-pass; trap softening |
| 3 | repeat AST + structural fixed-point + `local_suffix` | UNKNOWN | grading not pasted |

Read: two of three Nova runs used a scope-aware approach and one nearly passed. Treat this pick as
too-easy-leaning until a full batch shows it holding under the 20% Olympus cap. Harden per Run 2.
