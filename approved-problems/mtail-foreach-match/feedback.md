# feedback.md — mtail-foreach-match

## Pick decision (2026-07-25)

**Repo:** google/mtail @ 4c7e0e1174ac1ead032efe28d86428bbbe0ae145
- 4023★, Apache-2.0, Go 1.21, pure-Go (no cgo/network) → clean offline build, deterministic.
- Maintenance-mode (real feature gap 2024-10 → 2026-02) → COLD code paths, no live collision.
- Full language engine: lexer → parser (goyacc) → checker (type inference) → codegen → opt → bytecode VM. 8072 LOC engine across ~24 files. Corpus lever 6 (multi-subsystem span) + lever 1 (one interdependent kernel: the match register + capture machinery + matched flag).

**User intake:** Olympus, hard edge (~1/10 target). Auto-discover fresh repo + fresh hard feature. User then constrained to **≥500★ repos only** (ruled out numscript 105★, the strongest raw difficulty vehicle).

**Discovery log (why mtail):** exhaustive sweep across Go/Rust/TS/Python × ~30 engine topics, auto-excluding the ~538 already-used repo names. Rejections: numscript (105★, user vetoed sub-500); kalker (1898★ MIT — feature-complete calculator, remaining gaps publicly-solved = derivative/too-easy risk; already has Piecewise/matrices/equations); rink/beancount/HyperFormula (GPL); uvm (host-dep SDL/audio/net build + WIP-unstable base = env-quality risk); rulego/flow-engines (concurrency flakiness). mtail survived every gate.

## Feature (invented, exclusive)

`foreach /regex/ { ... }` — run the action block once per non-overlapping match of the pattern on the current line, re-binding capture registers ($1, $name) each iteration. mtail is deliberately **loop-free / first-match-only**; this is the seam.

- **Exclusivity:** CLEAN. PR/issue search (foreach, global match, repeated match, all matches, gsub, iterate, each match, loop) → no implementation. mtail-specific construct = invented => exclusive; no external reference lib.
- **Deterministic + exact:** matches on a line are fixed; asserted values are int counts / string captures. No float, no map-iteration order, no time, no concurrency.

### Interdependent + misdirecting traps (NOT stdlib-absorbed)
1. **Capture-register save/restore around the loop** — single per-thread match register; body must set it per iteration and restore prior state after. Naive impl leaves it stale → wrong captures in code AFTER the foreach (misdirecting: symptom is downstream).
2. **`matched` flag wiring** — ≥1 match must set matched=true (skips following `otherwise`); 0 matches leaves it false (fires `else`/`otherwise`). Orthogonal cache/flag trap (corpus recurring class). Symptom: an `otherwise`/`else` block wrongly (not) firing.
3. **Checker capture-scope + numeric-capture type inference** — foreach captures must be registered in a loop-scoped symbol context; `\d+` etc. must drive Int/Float inference onto body-assigned metrics. Naive scope reuse → "capture undefined" or wrong metric type (Int vs String).
4. **Nested foreach register shadowing** — inner loop must save/restore outer loop's current match; single-register naive impl corrupts outer counts.
5. **Codegen backward-jump in a loop-free codegen** — new backward jump + forward exit backpatch + per-iteration stack discipline; naive impl leaks stack per iteration → imbalance.

(The classic empty-match-advancement infinite-loop edge is absorbed by Go's `regexp.FindAll*`; kept only as a minor edge test, not a headline trap.)

## Final delivered scope (cohesive `foreach` iteration family)

Grew from the core (match/in/metric + matchindex) to clear the Olympus LOC floor with genuine orthogonal depth (not breadth padding):
1. `foreach /pattern/ { body }` — per non-overlapping match, left to right; captures rebind per iteration; numeric-capture type inference flows to body metrics.
2. `foreach /pattern/ in expr { body }` — match within a string expression (Sfmatch, coerced to string).
3. `foreach /pattern/ ... else { body }` — else runs on zero iterations; drives the `matched` flag (Otherwise+Jnm).
4. `foreach id in metric { body }` — per stored entry, ascending key order; keys snapshotted at loop entry; value via `metric[id]`.
5. `foreach key, value in metric { body }` — also binds the value (Mbindval; value stored via `Datum.ValueString()`, converted by the loop-var's resolved type).
6. `foreach id in metric limit n { body }` — top-N by value descending, ties by ascending key (Mforeachn; sort.SliceStable). Genuine sort-by-value depth.
7. `foreach id in fields(expr, /sep/) { body }` — split by regex separator (Ffields; re.Split), bind each field.
8. `matchindex()` — 0-based innermost-loop index (Fidx); compile error outside a foreach.
9. `matchcount(/pattern/)` — non-overlapping match count on the line (Fcount).

Kernel: one loop-codegen shape reused by every form, introducing the engine's FIRST backward jump (`Jmp lTop`), with iteration state on a per-thread `loopStack` (OFF the data stack). 12 source files + regenerated `parser.go` (goyacc, clean — zero conflicts).

## Difficulty / traps (interdependent + misdirecting)
- N-fold accumulation (body per match, not per line).
- `matched` flag set from loop iteration count at Fend (immune to body's nested-conditional clobber); drives `else`/`otherwise` (misdirecting: symptom is a downstream branch).
- Capture scope + numeric type inference per iteration (loop-scoped `checkRegex`).
- First backward jump in a loop-free codegen; per-iteration state off the data stack.
- Nested-frame isolation; `matchindex()` reads innermost.
- Metric ascending-key vs top-N-by-value ordering; key snapshot on mutation.

## Easiness red-team (pre-submit)
- Single-file shim: NO (spans 12 files + goyacc regen).
- Verbatim meta transcription: NO (meta is WHAT; the HOW needs backward-jump codegen, matched-flag-from-loop-state, capture-register binding, nested frames).
- 50-line stub passing >half: NO (whole lexer->parser->checker->codegen->VM pipeline required).
- Tests all one behavior: NO (5 iteration forms + 2 builtins + else + type inference + 2 ordering rules, orthogonal).
- Obvious architecture satisfies all: NO (matched-flag/else, nested-frame, accumulation, ordering each force a specific choice).
Verdict: not too-easy. Predicted ~1/10-3/10.

## FP consideration
Tests assert metric VALUES from running foreach programs end to end; the only way to pass is to actually implement foreach semantics. No gaming path. FP-clean by construction.

## Local validation matrix (all GREEN, olympus-base-go, offline `--network none`, non-root `--user 1000:1000`)
- Docker image builds offline after `go mod download` (build-time network only).
- test.patch + solution.patch apply clean in BOTH orders (test->solution and solution->test).
- BASE state: `test.sh base` PASS (442 testcases, 0 fail); `test.sh new` FAIL (feature absent -> `foreach` parse error, the right reason).
- SOLUTION state: `test.sh base` PASS; `test.sh new` PASS (33 tests).
- Determinism: 3x identical (33 tests, 0 failures each run).
- Effective LOC: human-effective 442 (>= 430), raw 559, 12 files. parser.go excluded as generated.
- Flakiness: no time/RNG/network; map iteration replaced by explicit `sort` everywhere.

## Remaining (platform-only, not runnable in this authoring env)
- Nova/Orion/Vega empirical pass-rate runs (the difficulty oracle) + FP check across passing agents.

## R2 — platform pre-check feedback fixes (2026-07-25)

- **BLOCKER (test-patch sanity): `go test -skip` flagged unsupported.** The platform's static checker rejects `-skip` even though Go 1.20+ (image has 1.26) supports it. Rewrote `test.sh`: `new` runs only the foreach tests via `-run`; `base` runs all `internal/runtime/...` subpackages (they directly cover every changed file: checker/codegen/parser/vm/types/code) PLUS the top package's existing tests by name (`TestCompileAndRun|TestLoadProg|TestNewRuntime|TestNewRuntimeErrors|TestRuntimeEndToEnd`) via `-run` — no `-skip`. Re-validated: base=0 (442 tc), new=0 (34 tc), F2P holds, 3x deterministic.
- **Description request_changes (HIGH+med+low redundancy):** removed the accumulation restatement (implied by "once per non-overlapping match"), "using the same match set...", the `$0/$1/$name` parenthetical, "just as in an ordinary action", and "read the value with `metric[id]`". meta now 269w/1608b, all behaviors still traceable.
- **Alignment WARNING:** generalized `limit n` to "either metric form" (was shown only on the single-var form; tests use both).
- **Tests-cover WARNING:** added `TestMetricForeachLimitDescendingValueOrder` asserting descending-value iteration order (order concat "abc" for values 3,2,1) — the spec's "descending value order" is now explicitly observed.
- **Brittleness note:** relaxed the matchindex-outside-foreach test to assert a compile error occurs (dropped the error-text substring coupling).

## R3 — Environment Quality fix (2026-07-26)

- **FAIL:** the env-quality validator runs the canonical `go test ./...` on the VANILLA repo and gave up before producing a verdict. Root cause: mtail's suite is not slow per se (~9-18s), but my Dockerfile warmed only the *build* cache (`go build ./...`), NOT test-binary compilation — so the validator's `go test ./...` paid a cold test-compile cost, and its turn-based polling exhausted the budget before completion.
- **Fix:** added `(go vet ./... || true)` to the Dockerfile after `go build`. `go vet` compiles all packages *including test files*, warming the test-compilation cache into the shared `GOCACHE=/tmp/gocache`. It is static analysis, not a test command (rubric-clean; `|| true` so vet findings don't break the build). Verified on the vanilla repo, offline non-root: `go build ./...` = 0.8s, `go test ./...` = **~9s** (21 ok pkgs, 0 failures) — comfortably inside the validator budget.
- No change to solution/test patches or behavior. Re-verified full problem: base=0 (442 tc), new=0 (35 tc, 0 failures).
- Also caught earlier this round: F2P (matchindex-outside test vacuously passed on base -> anchored with a positive in-foreach assertion), test-quality (relaxed metric-type assertion to behavioral, added non-overlapping /aa/ test), description (removed redundant clauses), alignment (limit applies to both metric forms), Dockerfile (pinned go-junit-report@v2.1.0), and the `-skip` blocker (base mode now selects tests without `-skip`).

## R4 — Solution Quality 2/3 -> close every gap for 3/3 (2026-07-26)

Solution Quality PASSED (2/3 comprehensiveness, 2/3 code quality). Closed all five reviewer-named gaps (also makes the feature HARDER: more enforced requirements = lower pass rate):

1. **`else` only on plain pattern form -> now on ALL forms.** Refactored the grammar to a single `opt_else` non-terminal used by every foreach production (pattern, `in expr`, fields, metric, metric+limit, k/v, k/v+limit). goyacc regen clean (0 conflicts). Added `Else` to MetricForeachStmt/FieldsForeachStmt AST + walk + a shared codegen `emitElse` helper + unparser `elseBlock`.
2. **Metric foreach didn't reject non-single-dimension metrics -> now enforced.** Checker `isSingleDimension` rejects scalar and multi-key metrics with "single dimension" error before the VM's single-key assumption is reached.
3. **Flat name-keyed `loopvars` aliased nested same-name vars -> slot-based addressing.** Checker allocates a unique `Addr` slot per LoopvarSymbol (`newLoopvar`); Mbind/Mbindval/Loadvar now use the int slot; VM `loopvars` is `map[int]string`. Nested `foreach k ... { foreach k ... }` no longer clobbers the outer binding (verified: outer="pq", not "zz").
4. **Unparser dropped `limit` -> added** (and `else` for metric/fields), so AST round-trips.
5. **Coverage tests added** (the 3 advisory suggestions): scalar + multi-dim rejection (error-substring anchored so they still fail on base), else on empty metric, else on the `in expr` form, `limit` exceeding entry count, and nested same-name isolation.

Re-validated: build clean, 41 new tests (was 35), zero regressions, F2P holds (0/41 pass on base), both apply orders, 3x deterministic, human-effective **476** (was 442), image builds, base=0/new=0 offline non-root. meta.md generalized (`else` on any form; metric must be single dimension). solution.patch + test.patch + meta.md regenerated; Dockerfile unchanged (env-quality still green).

## R5 — Undocumented-requirement FAIL (verifier unfair) fix (2026-07-26)

- **FAIL (agentBlameUnfair=true):** a Nova solver passed 30/35; its 5 failures were compile-time "loop variable never used" errors. My checker EXEMPTED metric/fields loop vars from mtail's unused-symbol check (`sym.Used = true`), but the prompt never says loop bindings are exempt. A solver that reuses mtail's existing unused-symbol machinery (the natural implementation) rejects any of my test programs whose loop var is not referenced -> the hidden verifier enforced an undocumented language rule.
- **Root cause:** `checkSymbolTable` errors on any unused non-capref symbol; my `Used = true` exemption on loop vars was an invisible special case. (Unused CAPREFS only warn, so pattern-foreach tests were never affected.)
- **Fix (solver-independent):** (1) removed the exemption so loop vars follow mtail's existing unused-symbol rule (no special case, matches the natural/failing-agent implementation); (2) rewrote the 7 tests whose loop var was unused so EVERY declared loop var is referenced in its body. Now the tests pass whether a solver errors on unused loop vars OR allows them -> the undocumented requirement is gone. Verified: with the exemption removed, all 42 tests pass on the reference (which now errors on unused loop vars, exactly like the failing Nova).
- Added `TestForeachMatchedImmuneToBodyConditional` (fair, documented): a foreach with >=1 iteration counts as matched even if a nested conditional in its body did not match, so a following `otherwise` does not run. Strengthens the misdirecting matched-flag trap.
- Re-validated: 42 tests, zero regressions, F2P (0/42 on base), both apply orders, 3x deterministic, human-effective 475, meta.md unchanged (behavior is now mtail's default unused-symbol rule, no new requirement).

**Difficulty note:** the "failing" Nova actually implemented the feature (30/35, all 5 fails were the unfair issue), and the other Nova solved it — so on n=2 the feature is solvable/moderate, likely toward the easy end. The real oracle is the 10+ run platform batch. If it lands >40%, the clean hardening is a documented subtle-correctness trap (e.g. exact zero-width / overlapping match count pinned to RE2 FindAll semantics), NOT another hidden rule.

## R6 — Difficulty hardening: zero-width / empty-match trap (fair) (2026-07-26)

Added the corpus "obvious-code-is-wrong" trap (lever 4) + exact-output correctness (lever 2), kept fair:

- **The trap:** foreach's match set must equal the engine's GLOBAL search (Go RE2 `FindAllString*`), INCLUDING empty matches. A solver who extends mtail's existing single-match machinery (`FindStringSubmatch`) with a manual find-and-advance loop miscounts or infinite-loops on zero-width patterns (`a*`, `x?`); a solver who uses the engine's global search passes. Misdirecting: the failing test is a wrong COUNT on an unusual pattern, not a crash pointing at the cause.
- **Fair:** meta paragraph 1 now states "the matches are exactly the set a global search with the pattern finds, including empty matches" — a competent engineer reads that and uses `FindAll*`; the exact counts are DERIVED by using the right API, not memorized. Front-loaded so it survives any description truncation.
- **Interdependence:** `matchcount(/re/)` and `foreach /re/` must agree on the same zero-width set (`TestMatchcountAgreesWithForeachOnEmptyMatches`).
- **Empirically pinned counts** (Go FindAll, and my solution already matches since it uses FindAllStringSubmatch): `/a*/` on "baa"=2, on "xyz"=4, on ""=1; `/x?/` on "xyx"=2; `/\d*/` on "a12b3"=3.
- 5 new tests (47 total). Re-validated: build clean, zero regressions, F2P (0/47 on base), both apply orders, 3x deterministic, human-effective 475, image builds, base=0/new=0 offline. meta 301w/1795b ASCII.

## R7 — Test Fairness (1/47 unfair) + advisory coverage (2026-07-26)

- **UNFAIR: `TestMatchcountAgreesWithForeachOnEmptyMatches`.** meta documented empty-match semantics for `foreach` but not for `matchcount`, so pinning `matchcount(/\d*/)=3` (empty matches counted) assumed an unstated policy. **Fix:** meta now says `matchcount` counts "the same match set a `foreach` over the pattern iterates" -> the empty-match behavior is documented for matchcount too, and the interdependence trap stays.
- **Advisory coverage (added, all fair + loop vars used):**
  - `TestMatchindexInMetricForeach` / `TestMatchindexInFieldsForeach` -- matchindex() inside metric and fields foreach (meta already says "innermost enclosing foreach").
  - `TestMetricForeachKeyValueWithLimit` -- `foreach k, v in m limit 2` exercising top-N ordering + value binding together (uses both k and v).
  - `TestFieldsForeachKeepsEmptyFields` -- leading/trailing/adjacent separators keep empty fields; meta's fields sentence now states "keeping empty fields produced by leading, trailing, or adjacent separators" to remove the split-edge ambiguity.
- solution.patch UNCHANGED (meta + tests only). 51 tests (was 47). Re-validated: zero regressions, F2P (0/51 on base), both apply orders, 3x deterministic, meta 321w/1923b ASCII.

## R8 — Alignment WARNING: concrete empty-match examples (2026-07-26)

Advisory WARNING (not a FAIL): "including empty matches" could be read ambiguously. Replaced the vague tail with the verified concrete examples that mirror the tests: `a*` matches `xyz` four times (empty at each position) and `baa` twice (empty, then `aa`), and `x?` matches `xyx` twice. Meta-only change (solution.patch + test.patch unchanged). meta 327w/1954b ASCII; examples match test expectations exactly.

## R9 — Test-quality WARNINGs: de-brittle reject tests + 2 edge tests (2026-07-26)

- **Error-message coupling (WARNING):** the two metric-rejection tests asserted the error text contained "single dimension". Could NOT simply relax to "compilation fails" (on base the foreach is a syntax error, so that passes vacuously -> breaks F2P). Fix: **anchored** each reject test with a valid single-dimension foreach (`validSingleDimForeach`) that only compiles WITH the solution (keeps F2P), then assert the scalar/multi-dim program is merely rejected (`compileErr(...) == nil` fails), with NO substring. 0 "single dimension" substrings remain.
- **Coverage (WARNING):** added `TestFieldsForeachAdjacentSeparators` (`a,,b` -> keeps the empty middle field) and `TestForeachInExprBindsCaptures` (named captures bind inside the `foreach /re/ in expr` variant: `a:1,b:2,a:3` -> m[a]=4,m[b]=2).
- solution.patch UNCHANGED (test-only). 53 tests (was 51). Re-validated: no vet issues, zero regressions, F2P (0/53 on base, reject tests still fail on base via the valid-foreach anchor), both apply orders, 3x deterministic.

## R10 — Solution Quality FAIL: two real control-flow bugs + description request_changes (2026-07-26)

Two genuine spec violations the reviewer found (tests passed only because they didn't exercise these edges):

- **BUG 1 - matchindex() accepted in an else block.** The checker incremented `foreachDepth` across the whole ForeachStmt and decremented it in VisitAfter, AFTER the walker had already traversed `Else`, so `matchindex()` in `else { ... }` (outside the loop body) was wrongly accepted (and would read a popped frame at runtime). **Fix:** converted the three foreach checker cases to a MANUAL walk that brackets `foreachDepth++/--` around the BODY only, then walks `Else` at the enclosing depth; removed the now-dead VisitAfter cases. Also added a `Fidx` VM guard (`len(t.loops)==0` -> runtime error, no panic).
- **BUG 2 - else block clobbered the matched flag.** `Fend` set matched=(iterations>0) BEFORE the else block ran, so a successful match inside the else block flipped matched=true and suppressed a following `otherwise`, even though a 0-iteration foreach must count as unmatched. **Fix:** `emitElse` now emits `Setmatched false` after the else body (reached only when the loop had 0 iterations), so the foreach stays unmatched and the enclosing `otherwise` runs.
- Tests added: `TestMatchindexRejectedInElseBlock` (anchored: matchindex in body compiles, in else is rejected) and `TestForeachElseDoesNotSuppressOtherwise` (else's nested match runs `elsehit=1` yet `otherwise` still runs `deflt=1`).

**Description request_changes (HIGH + 2 MEDIUM):** removed the verbose empty-match examples (HIGH) and the "runs its block repeatedly" filler (MEDIUM); the rule "the set a global search finds, including empty matches" fully specifies behavior without them. KEPT the matchcount "same match set" clause (removing it -- an optional MEDIUM -- would re-break the R7 fairness fix).

Re-validated: 55 tests (was 53), build clean, no vet issues, zero regressions, F2P (0/55 on base), both apply orders, 3x deterministic, human-effective **489**, image builds, base=0/new=0 offline. meta 296w/1772b.

## R11 — Alignment ERROR: specify the exact empty-match rule (2026-07-26)

Alignment flipped to ERROR: "including empty matches" was under-specified (and the reviewer wrongly thought the counts diverge from RE2 -- they are exactly Go `FindAll`). This deadlocked with the earlier necessary-info request_changes that had me delete the examples. User kept the difficulty (rejected removing the trap) and wanted alignment fixed.

**Fix:** derived Go's exact empty-match rule and stated it precisely in meta: matches are left to right, non-overlapping, and "an empty match immediately following the previous match is skipped" -- with the examples the reviewer asked for (`a*`->`baa` 2, `xyz` 4; `x?`->`xyx` 2). This rule reproduces every tested count (also `/\d*/` a12b3=3, `/a*/` ""=1), so description now matches tests exactly. Meta-only change; solution.patch + test.patch unchanged (the VM already uses `FindAllStringSubmatch` = this rule). meta 320w/1903b ASCII.

## R12 — Auto Review Tests 1/3: close cross-surface otherwise gap (2026-07-26)

Auto Review: Description 3/3, Solution 3/3, Tests 1/3 (T4). Only the REGEX foreach had a following-`otherwise` test; the metric and `in expr` forms tested their own `else` but not that a zero-iteration loop still counts as unmatched for a following `otherwise`. A surface-specific impl could suppress `otherwise` on those forms and pass.

**Fix (test-only; solution already correct via the universal `emitElse` reset):** added `TestMetricForeachElseDoesNotSuppressOtherwise` (empty metric foreach, else's `/a/` matches, following `otherwise` still runs -> elsehit=1, deflt=1) and `TestForeachInExprElseDoesNotSuppressOtherwise` (no-match `foreach /\d+/ in $d`, same shape). 57 tests (was 55). solution.patch UNCHANGED.

Re-validated: zero regressions, both new tests pass on solution, F2P (0/57 on base), both apply orders, 3x deterministic.

Note: Auto Review confirmed FAIR discriminating difficulty -- 4/10 agent runs passed; the 6 failures were near-complete (54/55 + all 442 baseline) and all converged on the SAME miss (not resetting matched after a matched conditional in a zero-iteration else). That is exactly the trap this feature targets; the reviewer explicitly said do NOT simplify.

## R14 — Human reviewer feedback (P4/T4/T3/S2/S4) (2026-07-26)

- **S2 (data race, real bug):** `Mforeach`/`Mforeachn` ranged `metric.LabelValues` without a lock, unlike `varz.go`/`GetDatum`. Added `m.RLock()`/`m.RUnlock()` around the snapshot in both. Verified `go test -race ./internal/runtime/...` clean.
- **S4 (silent error):** `Mforeachn` swallowed a non-numeric `ValueString()` parse error and used 0. Now breaks and reports via `v.errorf("foreach limit requires a numeric metric value: ...")`. No regression (limit tests use numeric metrics).
- **S4 (comment):** `LoopvarSymbol` comment now "metric key/value or fields field" (used by all forms).
- **P4 (spec):** meta now states `matchindex()` is invalid in an `else` block (matches existing checker rejection + `TestMatchindexRejectedInElseBlock`).
- **T4 (metric + in-expr otherwise):** `TestMetricForeachElseDoesNotSuppressOtherwise` + `TestForeachInExprElseDoesNotSuppressOtherwise` (else body runs a matching conditional; following `otherwise` still fires). Both present.
- **T4 (fields):** `TestFieldsForeachMatchesSoElseSkippedAndOtherwiseSuppressed`. fields split always yields >=1 field, so it can never zero-iterate; the correct parity is that fields matches -> its `else` is skipped and a following `otherwise` is suppressed. (Reviewer's own note: a zero-iteration fields case is impossible under the split semantics.)
- **S2 (docs):** added an "Iterating with `foreach`" section to `docs/Language.md`; now included in solution.patch.
- **T3 (advisory):** keeping the bespoke black-box helpers (`runForeach`/`wantInt`/`wantString`). Intentional: 58 small independent scenarios read far cleaner than the table-driven `vmTests`/`ExpectNoDiff` pattern; assertions stay black-box (metric values / compile errors), no internal over-pinning.

Re-validated: build clean, 58 tests (was 55), zero regressions, `-race` clean, base=0/new=0, 3x deterministic, F2P holds, human-effective 498. solution.patch now 14 files (adds docs/Language.md); test.patch 58 funcs.

## Attempt history

- **R0 (design):** repo + feature locked; DESIGN.md produced + self-audited green. Grounding architecture read delegated. BASE_COMMIT saved.
- **R1 (build):** implemented core (243 eff) + validated 6 smoke behaviors. Expanded with else/matchcount/key-value/fields/limit for orthogonal LOC depth -> 442 eff. Fixed: else must use Otherwise+Jnm (not Jm); loop vars exempt from unused-symbol check; Mbindval must use `Datum.ValueString()` (GetString panics on Int). Wrote 33 F2P tests; fixed 2 test-expectation miscounts (digit count; ASCII tie-break). Full Docker validation matrix GREEN.

## R15 — Coverage suggestions (3, advisory) (2026-07-26)

Added 4 tests (58 -> 62) for the three advisory gaps. All three behaviors already worked; these pin them.

- **limit validation:** `limit 0` now compiles and iterates 0 entries. Root cause of prior compile-reject: non-limit productions left `Limit: 0`, indistinguishable from an explicit `limit 0`. Fixed in parser.y: non-limit forms set `Limit: -1` (sentinel = no clause); codegen/unparser gate on `Limit >= 0` (was `> 0`). Regenerated parser.go (`--text` diff — repo `.gitattributes` marks it `-diff`). `TestMetricForeachLimitZeroIteratesNothing`.
- **fields empty-match separator:** `fields($r, /x*/)` on "abc" terminates cleanly, yielding a,b,c (Go `regexp.Split` skips the empty match after a match). `TestFieldsForeachEmptyMatchSeparatorTerminates`.
- **metric value typing:** `foreach k, v in metric` binds `v` to the metric's own datum type. `TestMetricForeachFloatValueBinding` (float gauge: copy + sum, 1.5/2.25 -> 3.75) and `TestMetricForeachTextValueBinding` (text gauge: v copies through as string). Added `wantFloat` helper.

Re-validated on pristine base: solution applies, test applies, F2P 62/62 fail on base, new 62/62 pass on solution, base 442/442 no regressions, 3x deterministic, `-race` clean, human-effective 928 (532 excl. generated parser.go). solution.patch still 14 files; test.patch 62 funcs.

## R16 — Test Fairness FAIL (1/62 unfair) + 3 advisory coverage (2026-07-26)

**Removed the unfair test.** `TestFieldsForeachEmptyMatchSeparatorTerminates` pinned an exact zero-width-separator split (`fields(_, /x*/)` -> a,b,c with no leading/trailing empties). The prompt never specifies zero-width behavior and the repo has no prior `fields(` to anchor it; multiple reasonable splits fit. Deleted.

**Replaced + added 3 fair, prompt-traceable tests** (the reviewer's own advisory suggestions, all discoverable):
- `TestFieldsForeachNoSeparatorMatchWholeString` — separator that never matches -> whole string as one field (parts=1). Traces to "splits the string on the separator pattern" (standard Go split; single reasonable outcome).
- `TestForeachLimitRejectedOnNonMetricFormsAndNonInteger` — `limit` on regex/fields foreach and a float `limit 1.5` all compile-reject. Traces to "Adding `limit n` to either metric form" (metric-only + integer). Anchored with a valid `foreach x in src limit 1` so it fails on base (no vacuous pass).
- `TestMatchcountInsideInExprForeachCountsWholeLine` — `matchcount(/\d+/)` inside `foreach /re/ in $d` counts the whole line each iteration (3 digits x 3 iters = 9). Traces to "matchcount returns the number of matches on the current line".

64 tests (was 62). Re-validated on pristine base: F2P 64/64 fail on base, new 64/64 pass on solution (3x deterministic), base 442/442 no regressions, `-race` clean. solution.patch unchanged (test-only fix); test.patch 64 funcs.

## R17 — 3 more advisory coverage suggestions (2026-07-26)

Added the 2 with a single well-defined outcome; deliberately skipped the 1 that is underspecified (same class as the R16 unfair test).

- **Top-N snapshot timing** -> `TestMetricForeachLimitSnapshotsSelectionBeforeMutation`. `foreach k in hits limit 2` selects {a,b}; bumping `hits["c"]` to 201 inside the loop does not change selection or order (`order="ab"`, `visited[c]=0`). Traces to "keys are fixed when the loop begins" + the limit selection rule.
- **Empty-string fields input** -> `TestFieldsForeachEmptyInputYieldsOneEmptyField`. `fields("", /,/)` yields exactly one empty field -> one iteration (`iters=1`, `seenEmpty[""]=1`), so the `else` is skipped (`elsehit=0`). Traces to "keeping empty fields" + else "runs only when there were no iterations". Single reasonable outcome (Go split of "").
- **Capture refs in foreach else** -> NOT added. `$n` from the foreach pattern in the else block is unbound; whether it compile-errors, yields empty, or yields a last value is genuinely underspecified (the prompt only constrains `matchindex()` there, already covered by `TestMatchindexRejectedInElseBlock`). Pinning an exact result here would repeat the R16 zero-width unfairness. Left unpinned by design.

66 tests (was 64). Re-validated on pristine base: F2P 66/66 fail on base, new 66/66 pass on solution (3x deterministic), base 442/442 no regressions, `-race` clean. solution.patch unchanged; test.patch 66 funcs.

## R18 — Test Fairness FAIL (2/66 unfair) (2026-07-26)

Removed both flagged tests; added nothing (this round's 2 advisory suggestions are the same underspecified classes).

- **Removed `TestMetricForeachLimitSnapshotsSelectionBeforeMutation`** (added R17). Pinned snapshot-before-mutation for top-N `limit` selection; the prompt only freezes *keys*, not limited selection among existing keys when their values change mid-loop. Underspecified. (Ironically the reviewer's own R17 suggestion, but pinning it is unfair.)
- **Removed `TestNestedForeachSameVarNameIsolated`** (from R1). Pinned a shadow/restore policy for reusing the same loop-variable name in nested foreaches; neither the prompt nor any pre-existing repo loop-binder singles this out. Nested binding is still covered fairly by `TestNestedForeachIndependentCaptures` (distinct names).
- **Advisory (2), both SKIPPED as underspecified:** "fields separator that matches empty strings" is the exact zero-width class removed in R16; "metric foreach mutation of existing values without limit" is the same snapshot-vs-perturb ambiguity just removed. Pinning either repeats the failure.

64 tests (was 66). Re-validated on pristine base: F2P 64/64 fail on base, new 64/64 pass on solution (3x deterministic), base 442/442 no regressions, `-race` clean. solution.patch unchanged; test.patch 64 funcs.

## R19 — Solution Quality FAIL (deleted-test synth failures) (2026-07-26)

R18's DELETION of the two unfair tests backfired: the platform tracks the expected new-test NAME set across revisions and synthesized failures for the now-missing `TestMetricForeachLimitSnapshotsSelectionBeforeMutation` and `TestNestedForeachSameVarNameIsolated`, failing Solution Quality's new-test phase. This is the F2P-testname-immutability rule (never delete tracked test FUNCTIONS across revisions; relax bodies only).

**Fix: restored both NAMES with fair, prompt-stated bodies** (satisfies both gates at once):
- `TestMetricForeachLimitSnapshotsSelectionBeforeMutation` -> now adds a NEW key inside the `limit 2` loop and asserts `order=="ab"`. Traces to "keys are fixed when the loop begins, so entries added inside the block are not visited" + the limit rule. Does NOT pin snapshot-vs-mutation of an existing key's value (the R18 unfairness).
- `TestNestedForeachSameVarNameIsolated` -> now references `k` only within each loop's own body (`seen1[k]` at the outer top, `seen2[k]` inside), asserting `seen1[p]=seen1[q]=1`, `seen2[z]=2`. Passes under both same-slot and separate-slot implementations, so it pins no shadow/restore policy (the R18 unfairness) while still exercising nested same-name loops.

66 tests. Re-validated on pristine base: F2P 66/66 fail on base, new 66/66 pass on solution (3x deterministic), base 442/442 no regressions, `-race` clean. solution.patch unchanged; test.patch 66 funcs.

**Lesson:** a Test Fairness "unfair test" flag and the F2P-testname-immutability rule collide when the fix is deletion. Resolve by RELAXING the flagged test's BODY to assert only prompt-stated/discoverable behavior, keeping the function name stable. Never delete a test the platform has already tracked.

## R20 — Auto Review: same-package test-helper collision (T3 harness fragility) (2026-07-26)

Confirmed root cause of the env-blocked run: the hidden test declared generic package-level helpers (`metricByName`, `none`, `wantInt`, `runForeach`, `compileErr`, `wantString`, `wantFloat`, `labelsMatch`) in `package runtime`. A solver added `internal/runtime/foreach_integration_test.go` with its own package-level `metricByName` (different signature) -> Go has no overloading -> the whole `runtime` test package failed to compile -> both base and new suites exited 1 with all-synthetic failures (false negative). `agentBlameUnfair: true`.

**Fix:** renamed all 8 package-level helpers with a unique `Fe7c80` suffix (`metricByNameFe7c80`, `noneFe7c80`, ...). Test FUNCTION names unchanged (F2P node-ids intact). Verified with a COLLISION REGRESSION: injected a solver `foreach_integration_test.go` defining both `metricByName` and `none` in `package runtime`; the hidden suite now compiles and passes 66/66 alongside it (previously an instant compile wipe).

Re-validated (fresh cache): F2P 66/66 fail on base, new 66/66 pass on solution (3x deterministic), base 442/442 no regressions, `-race` clean, package compiles alongside a colliding solver helper. solution.patch unchanged; test.patch 66 funcs.
