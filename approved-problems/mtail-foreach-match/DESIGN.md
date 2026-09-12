# DESIGN.md — mtail-foreach-match

## 1. Title
Add `foreach` iteration over line matches and metric entries

## 2. Shape classification
- Shape: **O-Composite-add** (net-new construct spanning lexer → parser → checker → codegen → opt → VM), with an O-Algorithm-correctness core (the loop kernel + matched-flag + N-fold accumulation semantics).
- PLAYBOOK § Pattern 12: O-Composite-add = new feature spanning parser/compiler/VM/runtime.
- Pass-rate target: **≤40% cap; design toward ~1/10 (hard edge).**
- Best agent: Vega/Orion (multi-subsystem refactor + decisive implement).
- Dominant verdict: MISSED_REQUIREMENT (accumulation / matched-flag / ordering) + INTEGRATION_ERROR (backward jump / capture scope).

## 3. Public API surface (the mtail-language surface tests assert)
- `foreach /pattern/ { body }` — execute `body` once per non-overlapping match of `pattern` on the current input line, left to right.
- `foreach /pattern/ in strexpr { body }` — same, but matches within the string value of `strexpr` (mtail expression) instead of the whole line.
- Inside a match `body`, capture groups `$0`/`$1`.../`$name` bind to the current match's captured substrings; numeric-only capture patterns drive Int/Float type inference onto metrics assigned in the body (unchanged capref semantics, per iteration).
- `foreach id in metric { body }` — execute `body` once per stored entry of the single-dimension `metric`, in ascending lexicographic key order; the identifier `id` binds (type String) to the entry's key; `body` reads the entry value via `metric[id]`.
- `matchindex()` — Int; the current match's 0-based iteration index inside the innermost enclosing match-`foreach` body. Compile error outside such a body.
- `matchcount(/pattern/)` / `matchcount(/pattern/, strexpr)` — Int; the number of non-overlapping matches of `pattern` on the line (or in `strexpr`), using the same match semantics as `foreach`.
- Semantics fixed below (§4).

## 4. Canonical output form / fixed semantics
- **Match order:** left-to-right by match start, exactly `regexp.FindAllString*(hay, -1)` (Go RE2), including zero-width matches per Go's non-overlapping advancement. `matchcount` uses the identical set.
- **N-fold accumulation:** the body runs once per match; counter/`+=` effects accumulate across all matches on a line, not once per line.
- **Empty:** zero matches / empty metric → body runs zero times.
- **`matched` flag:** a `foreach` sets the enclosing-scope match flag true iff it ran ≥1 iteration; a following `otherwise` in the same scope fires only when the `foreach` produced zero iterations. The flag is written at loop end from loop state, so nested conditionals inside the body do not affect it.
- **Metric order:** entries visited in ascending lexicographic order of the key string. Keys are snapshotted at loop entry, so mutating the metric inside the body iterates the pre-loop key set.
- **Metric restriction:** the `foreach id in metric` form requires a metric with exactly one dimension (`by` one axis); zero/multi-dimension is a compile error containing "single dimension".
- **`matchindex` scope:** innermost match-`foreach`; nested loops each report their own index.
- **Loop variable:** `id` is String, scoped to the body; it shadows nothing and is not exported.

## 5. Blind-spot pre-empts (verbatim sentences placed in §6 meta)
- Result ordering: "Entries are visited in ascending lexicographic order of their key." (result-ordering)
- Iteration termination / accumulation: "The block runs once for every match, so counters increase by the number of matches on the line, not once per line." (iteration-termination / N-fold)
- Rule resolution / flag: "When a `foreach` produces no iterations it counts as unmatched, so a following `otherwise` in the same block runs." (rule-resolution)
- Adjacent-vs-all: "All non-overlapping matches are visited, not just the first." (adjacent-vs-all)
- Falsy/scope: "`matchindex()` is only valid inside a pattern `foreach` body and reports the innermost loop's index." (falsy-on-invalid)
≤1 codebase-inferable requirement (the exact RE2 zero-width advancement is inferable from Go regexp; stated anyway).

## 6. Description draft (see meta.md; ~260 words, under 500 hard cap)
Two-form prose: (a) match iteration + captures + accumulation + matched-flag + `in`; (b) metric iteration + ordering + single-dimension; (c) the two builtins. No headers, plain prose.

## 7. File footprint (against real source; effective = raw − blank − comment − braces/imports; generated parser.go EXCLUDED)
| Action | Path | Raw + | Effective | Reason |
| --- | --- | --- | --- | --- |
| MODIFY | internal/runtime/compiler/ast/ast.go | ~28 | ~22 | `ForeachStmt` node (+ MetricForeach variant fields) + Pos/Type/Sym |
| MODIFY | internal/runtime/compiler/ast/walk.go | ~14 | ~11 | walk case for ForeachStmt |
| MODIFY | internal/runtime/compiler/parser/parser.y | ~22 | ~18 | FOREACH/IN tokens + 3 productions (source; parser.go regenerated, excluded) |
| MODIFY | internal/runtime/compiler/parser/lexer.go | ~4 | ~3 | keywords foreach/in |
| MODIFY | internal/runtime/compiler/parser/unparser.go | ~18 | ~15 | unparse ForeachStmt |
| MODIFY | internal/runtime/compiler/parser/sexp.go | ~18 | ~15 | s-expr dump ForeachStmt |
| MODIFY | internal/runtime/compiler/checker/checker.go | ~95 | ~78 | scope+capture registration, metric single-dim check, loop-var symbol, builtin typing + inside-foreach validation, haystack String-typing |
| MODIFY | internal/runtime/compiler/symbol/symtab.go | ~6 | ~5 | LoopvarSymbol kind |
| MODIFY | internal/runtime/compiler/codegen/codegen.go | ~110 | ~92 | ForeachStmt loop (backward jump), metric loop, `in` haystack, matchindex/matchcount, loopvar load |
| MODIFY | internal/runtime/compiler/opt/opt.go | ~10 | ~8 | ForeachStmt passthrough (no const-fold across loop) |
| MODIFY | internal/runtime/code/opcodes.go | ~26 | ~22 | 9 opcodes + opNames |
| MODIFY | internal/runtime/vm/vm.go | ~150 | ~120 | loopFrame + loopStack on thread; 9 execute cases; loopvar store; metric key snapshot+sort; errors |
| (regen) | internal/runtime/compiler/parser/parser.go | (gen) | 0 | goyacc output, excluded from effective count |
TOTAL effective ≈ **~409–430 hand-written**, plus required disassembly/String plumbing for opcodes (~20) → target **≥450**. If short after build, add: metric-value type propagation to the loop-var-indexed read, and a `matchcount` third form, both genuine.

Olympus floor: ≥450 effective design target (400 auto-block). Files: ~12 modified (≥2 floor; healthy).

## 8. Solution outline — helpers (1+ per behavior)
Codegen:
- `genPatternForeach(n)` ← match-iteration + `in` haystack + backward-jump loop.
- `genMetricForeach(n)` ← metric-entry iteration.
- emit for `matchindex()` → `Fidx`; `matchcount(...)` → `Fcount`/`Sfcount`.
VM (execute cases):
- `Fmatch idx` / `Sfmatch idx` (pop haystack) ← push loopFrame{matches:FindAllStringSubmatch(hay,-1), index:0, reIdx:idx}.
- `Fhasnext` ← push bool(top.index < len(top.matches)).
- `Fbind` ← t.matches[top.reIdx] = top.matches[top.index]; top.index++.
- `Fend` ← t.matched = top.index>0; pop loopFrame.
- `Fidx` ← push int64(top.index-1).
- `Fcount idx` / `Sfcount idx` ← push int64(len(FindAllStringSubmatch)).
- `Mforeach midx` ← snapshot sorted keys of metric → push metric loopFrame.
- `Mnext`/`Mbind`/`Mend` OR reuse Fhasnext/Fend with a key-frame; loopvar store `t.loopvars[name]=key`.
- `Loadloopvar name` ← push loop-var string.
Loop shape (backward jump = engine's first): `Fmatch; lTop: Fhasnext; Jnm lEnd; Fbind; <body>; Jmp lTop; lEnd: Fend`.
Checker:
- `checkForeach(n)` ← open child scope; if pattern form: `checkRegex` registers caprefs (numeric inference); if metric form: resolve metric, require 1 dim, insert LoopvarSymbol(String); type haystack expr as String.
- builtin typing: `matchindex`→Int (assert inside pattern-foreach via a checker flag/stack), `matchcount`→Int (arg is pattern [+ String]).

## 9. Test file outline
Path: `internal/runtime/mtail_foreach_<hex>_test.go` (new file, package runtime), using the `vmTests`-style harness: compile program string, feed log lines, assert `metrics.MetricSlice` values. Plus opcode-level cases in a second file if needed.
Blocks: (1) builder = compile+run helper mirroring `TestRuntimeEndToEnd`; (2) assertion helper on metric Int/String value; (3) tests by bucket:
- match-count accumulation: one line many matches → counter = match count; multi-line sum.
- captures per iteration: `foreach /(?P<k>\w+)=(?P<v>\d+)/ { m[$k] += $v }` → dimensioned sums.
- numeric type inference in body: metric typed Int/Float from capture pattern.
- matched-flag / otherwise: foreach with 0 matches → following `otherwise` runs; ≥1 match → it does not.
- `in strexpr`: match within a captured field, not whole line.
- matchindex: values 0..n-1; nested foreach reports innermost.
- matchcount: equals foreach iterations; standalone use; zero-width edge (`/a*/`).
- nested foreach: outer/inner independent capture + index.
- metric foreach: ascending key order (string concat), value read via `m[id]`, sum over entries; single-dimension compile error; snapshot-on-mutation.
- edge: empty line, no matches, empty metric.
- canary F2P: a trivial `counter c /x/{c++}` test to prove harness runs on base.
5-axis coverage: every behavior sentence, every builtin, every branch (hasnext true/false, pattern vs metric vs in, nested), edge (empty/zero/single/zero-width/unicode capture), inverse (0-match→otherwise).

## 10. Forced signatures / bounds (pin exactly to avoid fake-difficulty coin-flip)
- Go: `ast.ForeachStmt` struct fields pinned; `code` opcodes pinned; VM `loopFrame` internal. These are solution-internal (agent chooses), NOT asserted by tests → no compile-coupling. Tests assert only mtail-language behavior + metric values, so agents are free on internal shapes. (Avoids the Rust/Go signature-wipe anti-pattern: no hidden Go signature is asserted.)
- mtail-surface pinned in meta: `foreach`, `in`, `matchindex()`, `matchcount()`, ordering, accumulation, matched, single-dimension.

## 11. Predicted trap matrix
| # | Trap | Why agents hit it | Pre-empt in §6 | Catching test |
| --- | --- | --- | --- | --- |
| 1 | N-fold accumulation (body per match) | agents implement first-match like mtail default | "once for every match … not once per line" | match-count accumulation |
| 2 | matched-flag = iterations>0, set at loop end | naive sets unconditionally / never; body's nested cond clobbers | "no iterations ⇒ counts as unmatched, following `otherwise` runs" | matched-flag/otherwise |
| 3 | capture scope + numeric inference per iteration | forget to register caprefs in loop scope → undefined / String metric | capref semantics per iteration | numeric-type + captures |
| 4 | first backward jump; loop state OFF data stack | put index on data stack → body push/pop corrupts | (structural; inferable) | multi-match + nested |
| 5 | nested foreach frame isolation; matchindex innermost | single shared index/register → outer corrupted | "innermost loop's index" | nested foreach + matchindex |
| 6 | metric ascending-key order + snapshot | Go map iteration random / iterate live | "ascending lexicographic order"; snapshot | metric order + mutation |
Wrong-Logic ≥25% expected (accumulation + matched-flag are semantic-correctness traps) — spec is unambiguous, not underspecified.

## 12. Tier + category
- Tier: Olympus. Sub-rank: Good→Excellent (cross-subsystem, 12 files, ~470 eff, ~60 tests).
- Category: **feature-request** (net-new construct + builtins).

## 13. Predicted Nova pass rate
- Predicted: **5–15%** (target ~1/10). Reasoning: 6 interdependent+misdirecting traps stacked on one loop kernel; N-fold + matched-flag + nested-frame are classic universal misses; backward-jump in a loop-free codegen is a real integration wall; metric-order determinism is an orthogonal wiring trap. Corpus levers stacked: 1 (one kernel), 3 (misdirecting), 4 (obvious-code-wrong: first-match default, matched clobber), 5 (cold niche repo), 6 (multi-subsystem). Not a famous portable spec (invented construct). Solvable: an expert reading meta + repo can implement each rule; deterministic oracle. 0% risk mitigated by clear meta + drop-metric-form fallback.

## 14. Quality gate
- [x] Repo understanding 5/5 (arch report grounded).
- [x] Existing-PR check: 0 hits (foreach/global-match/all-matches/loop/iterate searched, all states).
- [x] Closest approved opened: tinywasm-exception-handling (control-flow VM feature), toydb-correlated-subqueries (compiler+exec span), starlark-format-spec (kernel).
- [x] Corpus recipe: one interdependent kernel (loop+match register); self-oracle (I define semantics + deterministic vmTests, no external lib); ≥3 interdependent+misdirecting traps incl. obvious-code-wrong; invented construct (exclusive); no hidden Go signature asserted.
- [x] Title verb-led; shape declared; API surface enumerated; canonical form fixed; ≤1 inferable req.
- [x] Description ≤500 (target ~260); plain prose.
- [x] Footprint real; effective target ≥450 (expand if short — named additions).
- [x] Helpers 1+/behavior; loop shape explicit.
- [x] 4-block tests; scenario names; 5-axis; canary F2P.
- [x] No fake-difficulty signature coin-flip (tests assert language behavior only).
- [x] Not pattern-followable; not in used features.

## Why this is not a duplicate
Closest local: no mtail problem exists (fresh repo). Feature-class `foreach`/global-match/iteration absent from mtail PRs and from the used-feature set. Distinct from any diff/query problem: this is a control-flow + iteration construct in a bespoke log-DSL, exclusive by construction.

Predicted iteration cycles: 2–3.
