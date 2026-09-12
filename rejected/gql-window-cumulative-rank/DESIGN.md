# DESIGN.md — gql-window-cumulative-rank

## 1. Title

Extend window function evaluation with ordered cumulative frames

## 2. Shape classification

- Shape: O-Pipeline-hard (new variant + cascading, invented algorithm — no existing GQL code computes a per-row growing frame; the whole-partition broadcast is the only mechanism present today)
- Definition: a new capability (cumulative per-row frame evaluation) cascades through the existing window-function dispatch, forces every existing pure/aggregated window function through a second code path, and adds two brand-new functions (`RANK`, `DENSE_RANK`) whose correctness depends entirely on that new path being right.
- Pass rate target: 15% (O-Pipeline-hard band)
- Best agent: Vega (multi-file cascading refactor)
- Dominant verdict: mixed MISSED_REQUIREMENT / REGRESSION (existing whole-partition behavior must survive unchanged when no ORDER BY is given)
- Solver/our LOC ratio: ~1.3-1.5x (O-Pipeline band precedent)

## 3. Public API surface

No new Rust public API — this is entirely GQL-language-surface (query syntax), which is the correct
unit of "API" for a query-language repo. The surface the tests assert against:

- `RANK()` — new window function, zero arguments, valid only inside `OVER(... ORDER BY ...)`
- `DENSE_RANK()` — new window function, zero arguments, valid only inside `OVER(... ORDER BY ...)`
- Existing `SUM`/`AVG`/`COUNT`/`MIN`/`MAX`/`FIRST_VALUE`/`LAST_VALUE`/`NTH_VALUE`/`ROW_NUMBER` used
  as window functions with `OVER(... ORDER BY ...)` — behavior CHANGES from whole-partition
  broadcast to a per-row cumulative computation
- Same functions used with `OVER(PARTITION BY ...)` and no `ORDER BY` — behavior UNCHANGED
  (whole-partition broadcast, exactly as today)
- New parse-time error: `RANK`/`DENSE_RANK` called inside an `OVER(...)` with no `ORDER BY` clause

## 4. Canonical output form

- Cumulative frame extent: for a partition ordered by the window's `ORDER BY` key(s), row at
  position `i` (0-indexed, after ordering) is evaluated against the sub-frame containing rows
  `0..=i` of that ordered partition (its own row included). Ties in the order-by key do NOT
  merge into one sub-frame boundary for non-RANK functions — the sub-frame extends strictly by
  row position, not by distinct key value (`ROWS`-style framing, not `RANGE`-style).
- No `ORDER BY` in the window definition: the sub-frame is the WHOLE partition for every row,
  identical to current behavior (a single evaluation broadcast to all rows).
- `RANK`: 1 plus the count of rows in the cumulative sub-frame whose order-by key differs from
  the current row's key (competition ranking — ties share a rank, the next distinct value's rank
  skips ahead by the number of tied rows: keys `[1,1,2,2,2]` produce ranks `[1,1,3,3,3]`).
- `DENSE_RANK`: 1 plus the count of DISTINCT order-by key values strictly less than the current
  row's key within the partition (no gaps: the same keys produce `[1,1,2,2,2]`).
- `RANK`/`DENSE_RANK` with no `ORDER BY` in their `OVER(...)`: parse-time error, not a runtime
  NULL or a silently-empty rank.
- Multiple order-by expressions in the window's `ORDER BY`: two rows tie only when ALL order-by
  expressions evaluate equal between them (same rule already used for the window's existing
  `ORDER BY` sort).
- Empty partition input: no rows, no output — unchanged from today.

## 5. Blind-spot pre-empts

- "The cumulative sub-frame for a row is rows 0 through the current row of the ordered partition,
  inclusive of the current row itself" — pre-empts the classic off-by-one on whether the current
  row's own value counts toward its own aggregate.
- "When the window definition has no ORDER BY clause, every function keeps evaluating against
  the whole partition exactly as before" — pre-empts an agent applying cumulative framing
  unconditionally and breaking every existing (no-ORDER-BY) query.
- "RANK and DENSE_RANK require an ORDER BY clause in their OVER(...) and report a parse error
  when it is missing" — pre-empts silently returning NULL/0 or panicking.
- "Ties are determined by every ORDER BY expression evaluating equal, not just the first" —
  pre-empts single-key tie detection when a window orders by more than one expression.

## 6. Description draft (meta.md)

See `meta.md`. ~195 words, plain prose, no headers.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (~0.7x) | Reason |
|---|---|---|---|---|---|
| MODIFY | crates/gitql-engine/src/engine_window_functions.rs | 141 | +130 | ~90 | Cumulative-frame builder, per-row dispatch loop, order-key substitution for RANK/DENSE_RANK, dual-path branch on ORDER BY presence |
| MODIFY | crates/gitql-std/src/window.rs | 113 | +75 | ~52 | `window_rank`, `window_dense_rank` implementations + signature/map registration |
| MODIFY | crates/gitql-parser/src/parse_function_call.rs | ~730 | +30 | ~21 | Parse-time validation: RANK/DENSE_RANK require ORDER BY in their window definition |
| MODIFY | crates/gitql-core/src/signature.rs | 83 | +12 | ~8 | Shared `order_key_required_window_functions()` list, referenced by both parser (validation) and engine (argument substitution) |
| NEW | crates/gitql-engine/tests/window_cumulative_<hex>.rs | — | +230 | ~175 | Integration tests, in-memory DataProvider harness |

TOTAL solution.patch: ~247 raw / ~171 meaningful across 4 files. Below the 200 floor with the
default 0.65-0.7 multiplier estimate — **expand engine_window_functions.rs and window.rs beyond
the minimum** during implementation (extra helper extraction, explicit tie-detection helper shared
by RANK/DENSE_RANK, explicit cumulative-frame-builder as its own named function rather than inlined)
to land at a comfortable 300+ raw / 220+ meaningful buffer. Verify with the Counter-2 strip before
finalizing solution.patch (§ Pre-Submit).

## 8. Solution outline — pure-function helpers

- `build_cumulative_frames(partition_rows: &[Row], titles, arguments, env) -> Vec<Vec<Vec<Box<dyn Value>>>>`
  — for each row index `i` in the ordered partition, evaluates `arguments` against rows `0..=i`
  and returns the growing per-row frame. ← Canonical form § 4 "cumulative frame extent"
- `resolve_window_call_arguments(function, order_key_required, titles, row_values, env) -> Vec<Box<dyn Value>>`
  — for RANK/DENSE_RANK (empty `function.arguments`), evaluates the window definition's ORDER BY
  key expressions instead; for every other function, evaluates `function.arguments` as today.
  ← Public API § 3 "RANK/DENSE_RANK... zero arguments"
- `window_rank(frame: &[Vec<Box<dyn Value>>]) -> Vec<Box<dyn Value>>` (gitql-std) — counts trailing
  rows in the (sorted) frame equal to the current (last) row's key; rank = frame_len - tied + 1.
  ← Canonical form § 4 "RANK: ... competition ranking"
- `window_dense_rank(frame: &[Vec<Box<dyn Value>>]) -> Vec<Box<dyn Value>>` (gitql-std) — counts
  DISTINCT keys strictly less than the current row's key by walking the frame once.
  ← Canonical form § 4 "DENSE_RANK: ... no gaps"
- `validate_order_key_required_window_function(function_name, window_definition) -> Result<(), Diagnostic>`
  (gitql-parser) — checks `order_key_required_window_functions().contains(function_name)` implies
  `window_definition.ordering_clause.is_some()`. ← Blind-spot pre-empt "RANK and DENSE_RANK require..."

No fixpoint loop needed (frame construction is a single forward pass per row, not an
iterate-to-convergence transform). No cycle-trace pattern needed (no recursive AST traversal
introduced).

## 9. Test file outline

Path: `crates/gitql-engine/tests/window_cumulative_<hex6>.rs` (new integration test crate target;
no existing test directory exists in this repo — see DESIGN §14 Repo Understanding).

Block 1 — Imports: `gitql_core::environment::Environment`, `gitql_core::object::{GitQLObject, Group, Row}`,
`gitql_core::values::*`, `gitql_engine::data_provider::DataProvider`, `gitql_engine::engine::{evaluate, EvaluationResult}`,
`gitql_parser::parser::parse_gql`, `gitql_parser::tokenizer::tokenize` (or repo's actual tokenizer entry point,
confirmed against gitql-cli's invocation before writing).

Block 2 — Builder helpers (10-20 one-liners): `memory_provider(rows: Vec<(&str,&str,i64)>) -> impl DataProvider`,
`int_row(...)`, `text_row(...)`, `run_query(sql: &str, provider) -> GitQLObject` (parses, type-checks,
evaluates, returns the selected `GitQLObject`), `column_values(result, name) -> Vec<String>` (extracts
one output column as literals, in row order, for assertion).

Block 3 — Assertion helpers: `assert_column_eq(result, column, expected: &[&str])`, `assert_parse_error(sql, provider, expected_substring)`.

Block 4 — Tests by requirement bucket:
- Bucket "cumulative aggregated, order-by present": running SUM/COUNT over an ordered partition
  produces a strictly growing sequence, not one broadcast value (kills naive whole-partition reuse)
- Bucket "whole-partition unchanged, no order-by": SUM/COUNT/FIRST_VALUE without ORDER BY still
  broadcast one value to every row (regression guard — the dual-path branch must not collapse)
- Bucket "pure function cumulative semantics": FIRST_VALUE stays constant across the partition
  (regression, since first_value is invariant to cumulative vs whole-partition); LAST_VALUE returns
  the CURRENT row's own value at every position (the classic gotcha — this is the sole differentiator
  from a naive "just always widen the frame the same way" implementation); NTH_VALUE returns NULL
  for rows before position n and the value at position n from row n onward
- Bucket "rank ties": RANK on keys with a tie group produces the skip-ahead sequence (`1,1,3,3,3`);
  DENSE_RANK on the same input produces the no-gap sequence (`1,1,2,2,2`) — the off-diagonal cell
  distinguishing the two functions from each other, F-10
- Bucket "rank requires order by": `RANK() OVER (PARTITION BY x)` with no ORDER BY is a parse error
  containing "ORDER BY"; same for DENSE_RANK — both functions tested independently (not just one)
- Bucket "rank multi-partition": two partitions each get independent rank sequences starting at 1
  (guards against a global counter leaking across partitions)
- Bucket "rank multi-key order by": ties require ALL order-by expressions equal, not just the first
- Bucket "edge cases": empty result set (0 rows), single-row partition (rank always 1), all rows tied
  (rank all 1, dense_rank all 1)

Test count anchor: ~26-32 tests across 8 buckets (O-Pipeline-hard band precedent ~100 is for
larger multi-crate features; this is scoped to two engine-adjacent crates, so a leaner count with
full coverage on the two behavioral axes is appropriate — expand if any bucket above yields fewer
than 2 tests).

5-axis coverage check:
- Every described atom in meta.md: cumulative frame extent, no-order-by unchanged, RANK tie rule,
  DENSE_RANK no-gap rule, RANK/DENSE_RANK require ORDER BY, multi-expression tie rule — all covered above
- Every public surface: RANK, DENSE_RANK, and the 4 existing pure + aggregated functions under both
  ORDER BY and no-ORDER BY
- Every solution branch: the dual path (order-by present/absent) in engine_window_functions.rs;
  the tie-vs-no-tie branch in window_rank/window_dense_rank; the validation branch in the parser
- Standard edge cases: empty, single row, all-tied, boundary (nth_value before/at/after position n)
- Stated inverse: RANK vs DENSE_RANK is itself the stated-inverse pair (tie behavior diverges)

## 10. Forced trait bounds / generics / kwargs

None beyond what the existing `WindowFunction = fn(&[Vec<Box<dyn Value>>]) -> Vec<Box<dyn Value>>`
type alias already requires. `Value::equals(&self, other: &Box<dyn Value>) -> bool` (existing trait
method, `gitql-core/src/values/base.rs:32`) is what RANK/DENSE_RANK use for tie comparison — no new
trait bound needed since it is already object-safe and implemented by every value type.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (§6) | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | Applying cumulative framing unconditionally, breaking the no-ORDER-BY whole-partition path | F-9-adjacent (cross-path resolution drop: two code paths must both stay correct) | S5 dual-path consistency | order-by presence | #3 (RANK is built on the same cumulative builder — a broken builder breaks both) | Natural to unify "just always use cumulative logic" since it looks like it subsumes the old behavior when frame == whole partition happens to coincide for FIRST_VALUE-like functions, but breaks AGGREGATED functions (running SUM != total SUM) and LAST_VALUE | "When the window definition has no ORDER BY... exactly as before" | "whole-partition unchanged, no order-by" bucket |
| 2 | Treating LAST_VALUE as still meaning "the partition's true last row" under cumulative framing (copies FIRST_VALUE's invariance) | new pattern (host-language-adjacent: silent reuse of a sibling function's mental model) | A-tier reuse-missing-arm | pure-function semantics under order-by | #1 (both live in the same dispatch loop) | FIRST_VALUE and LAST_VALUE are visually symmetric in existing code (`window.rs:69` vs `window.rs:95`); an agent fixing one by analogy naturally "fixes" the other the same way, which is wrong for LAST_VALUE specifically | canonical form §4 "cumulative frame extent" + the LAST_VALUE test bucket description | "pure function cumulative semantics" bucket, LAST_VALUE case |
| 3 | Implementing RANK and DENSE_RANK identically (both skip-ahead, or both no-gap) | F-10 capability cross-product | S2 composition of documented rules | tie-handling variant | #1 (both ride the same cumulative frame + tie-comparison primitive) | The two functions differ by exactly one counting rule; an agent that gets one right by testing has no structural reason to notice the other diverges unless a test targets the off-diagonal cell directly | canonical form §4 both RANK and DENSE_RANK definitions, side by side | "rank ties" bucket, both functions on the SAME input |
| 4 | RANK/DENSE_RANK with no ORDER BY silently returning NULL/0 instead of erroring | F-14 declared-vs-derived terminal state | A-tier determination-channel seam | validation presence | — | The parser has no existing precedent for validating window-definition-level requirements (only argument type/count checks exist); adding a new validation site is easy to skip since nothing forces the agent to consider it | "RANK and DENSE_RANK require an ORDER BY clause..." | "rank requires order by" bucket |

Traps #1/#2/#3 sit on different axes (path-selection, per-function semantic reuse, tie-rule variant)
and #1 is the shared chokepoint all three ride through — genuinely interdependent, not just declared
so. #4 is orthogonal (validation-time vs evaluation-time) and independently testable.

CONTRACT-STATED/FIX-HIDDEN check: every trap's pre-empt sentence is quoted directly from §4/§5
above and will appear verbatim (or near-verbatim) in meta.md. None of the four traps depend on an
unstated behavior — the meta.md states the cumulative rule, the no-order-by fallback, both tie
rules explicitly, and the ORDER BY requirement. What remains hard is APPLYING three stated rules
consistently across one shared, newly-written code path, not guessing an unstated one.

## 11b. Capability cross-product matrix (F-10)

Axis 1 (multiplicity of code path): order-by present (cumulative) vs order-by absent (whole-partition).
Axis 2 (function kind): aggregated (SUM/COUNT/...) vs pure-positional (FIRST_VALUE/LAST_VALUE/NTH_VALUE/ROW_NUMBER) vs order-key (RANK/DENSE_RANK).

| | order-by present | order-by absent |
|---|---|---|
| **aggregated** | test: running SUM produces a growing sequence | test: SUM broadcasts one total to every row (regression) |
| **pure-positional** | test: LAST_VALUE returns the current row (off-diagonal — the gotcha) | test: LAST_VALUE returns the true partition-last value (regression) |
| **order-key (RANK/DENSE_RANK)** | test: valid, tie sequence produced | test: parse error required (the only cell where "absent" is invalid, not merely a different-but-valid behavior) |

Every cell has a test in the § 9 outline (buckets "cumulative aggregated", "whole-partition
unchanged", "pure function cumulative semantics", "rank requires order by"). The pure-positional /
order-by-present cell (LAST_VALUE) is the predicted highest-value off-diagonal test, matching the
measured F-10 pattern that off-diagonal cells fail by producing a plausible-looking WRONG value,
not a missing feature.

Format-noun audit (L24): the meta names "partition", "frame", and "row" — partition = the
PARTITION BY bucket (unchanged, existing concept), frame = the NEW cumulative sub-frame introduced
by this feature (extent stated explicitly in §4), row = a single output row. No ambiguous extent
remains unstated.

Tolerance-fixture audit (L25): not applicable — this design has no "allow N, stop at N+1" tolerance
rule; the closest analogue (tie counting) is fully covered by the RANK-vs-DENSE_RANK bucket testing
both a 2-way tie and a 3-way tie (the N-1/N boundary equivalent here is testing a tie group of
exactly 2 AND exactly 3, since a bug that only breaks 3+-way ties would pass a 2-tie-only suite).

Scope audit (F-11): the cumulative frame is scoped to ONE partition — ranks/running aggregates
reset at each partition boundary. This is stated in §4 and tested by the "rank multi-partition"
bucket. No recursive/nested scoping exists in this feature (single-level PARTITION BY only, matching
the existing `WindowPartitioningClause` which holds one expression, not a list).

## 12. Tier + category decision

- Tier: Olympus (one tier, 2026-07 sprint)
- Sub-rank target: Good (interdependent + misdirecting traps across 4-5 files, F-10 cross-product present)
- Category: **feature-request** (net-new `RANK`/`DENSE_RANK` window functions + new cumulative-evaluation
  semantics for existing window functions — matches title verb "Extend")

## 13. Predicted Nova pass rate

- Predicted: 15-25%
- Reasoning: O-Pipeline-hard shape band (15%) as a baseline, adjusted up slightly because the
  RANK-vs-DENSE_RANK off-diagonal (trap #3) and the validation trap (#4) are comparatively cheap
  for a careful agent to get right once trap #1 (the dual-path branch) is solved correctly — the
  four traps are not fully independent in difficulty, #1 gates a large fraction of correctness.
- Sanity check: within the current sprint ceiling (<=40%). Not 0% — an agent that reads the window
  function dispatch loop carefully and implements the cumulative builder correctly can pass; Vega's
  multi-file cascading-refactor strength fits this shape directly.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5: architecture paragraph (6-crate pipeline: gitql-ast -> gitql-parser ->
      gitql-core -> gitql-engine -> gitql-std -> gitql-cli; parser builds AST + type-checks inline via
      gitql-parser/type_checker.rs, engine executes via a fixed per-statement-kind pipeline in
      engine.rs/engine_executor.rs, gitql-std supplies the pluggable function tables); 5 subsystems
      (parser, type-checker, engine executor, std function library, core value/type system); 3
      high-entanglement zones (window function dispatch spans parser+std+engine+core; the
      Signature/OptionType/VarargsType machinery spans core+parser+std; alias resolution spans
      parser's symbol table and engine_executor's runtime alias_table); test framework = NONE exists
      today (2 inline `#[test]` fns unrelated to this feature, zero integration test directory) —
      this problem introduces the first integration test file, using the public `DataProvider` trait
      + `evaluate()`/`parse_gql()` entry points as the harness, no fixture template to cite since none
      exists (documented explicitly here instead of citing a nonexistent file).
- [x] Existing PR check: 0 hits. `gh api "repos/AmrDeveloper/GQL/pulls?state=open"` returned empty
      array (checked during olympus-hunt, 2026-08-11). `gh issue list -R AmrDeveloper/GQL --state open`
      shows 11 issues (subquery, dot-expression, GitHub-API support, diff performance, CLI error
      handling, ASDF plugin, pgwire protocol) — none overlap window functions, RANK, or cumulative
      evaluation.
- [x] Publicly-solved check: no issue comment links an external rank/window implementation; no
      community-posted code snippet for this capability found in any open or closed issue thread
      (searched issue titles/bodies for "rank", "window", "cumulative", "running" — no hits).
- [ ] Closest approved problem opened side-by-side — none of the 9 approved problems touch a query
      engine or window-function-shaped feature; closest by SHAPE (O-Pipeline-hard, cascading dispatch
      change) is noted in SHAPES.md precedent table, not a specific approved GQL problem (first pick
      in this repo).
- [x] Title verb-led, 5-10 words, names specific subsystem (window function evaluation)
- [x] Shape declared: O-Pipeline-hard
- [x] Public API surface lists every name tests assert (RANK, DENSE_RANK, existing 9 functions)
- [x] Canonical output form spelled out (§4: frame extent, no-order-by fallback, RANK rule, DENSE_RANK
      rule, ORDER BY requirement, multi-key tie rule, empty input)
- [x] 0 codebase-inferable requirements — TODO comment in source (`engine_window_functions.rs:139`,
      "Convert groups into window frames") is NOT used as the spec; the concrete cumulative rule,
      RANK/DENSE_RANK semantics, and validation requirement are all invented and will be fully stated
      in meta.md, not left for the agent to infer from the comment
- [ ] Description draft word count <=200 (drafting next in meta.md)
- [ ] Description draft: no headers/labels/Box<>/code-prose (drafting next)
- [x] File footprint sketched against real source files with real current LOC
- [ ] Raw/meaningful LOC clears 200 floor with buffer — flagged in §7 as needing expansion during
      implementation; will re-verify with the Counter-2 strip before finalizing solution.patch
- [x] Solution outline: 1+ pure-function helper per behavior
- [x] No fixpoint loop / cycle-trace needed (documented why in §8)
- [x] Test file outline: 4-block layout, scenario-encoded names
- [x] 5-axis test coverage planned
- [x] Forced trait bounds documented (none new; existing `Value::equals`)
- [x] 4 named traps, each with F-id/arsenal class + pre-empt sentence + catching test
- [x] Traps on different axes; #1 is the shared interdependence chokepoint
- [x] §11b cross-product matrix filled, every off-diagonal cell has a test
- [x] Form-parity audit (F-18): not applicable — no two lexical spellings of one concept exist in
      this feature's surface (RANK/DENSE_RANK are lexically distinct functions, not two spellings
      of the same thing)
- [x] Format-noun extents stated (§11b)
- [x] Tolerance-fixture audit: not applicable, documented why (§11b)
- [x] Predicted Wrong Logic <25% (this is a correctness-of-new-code trap set, not an
      ambiguous-spec trap; no Wrong Logic estimate above 20% for any individual trap)
- [x] Predicted Nova pass rate 15-25%, within <=40% ceiling
- [x] Category matches description: feature-request
- [x] Feature NOT pattern-followable: the 4 existing pure window functions are near-identical in
      shape (triviality risk flagged at hunt time), but this design's core mechanism (the cumulative
      per-row dispatch loop + dual-path branch + order-key argument substitution) has NO existing
      analogue anywhere in the 6-crate workspace to copy from
- [x] Feature not in RULES § Features already used (first GQL submission)

---

## Why this is not a duplicate

No approved problem in `approved-problems/` targets a query-language execution engine, window
functions, or cumulative/ranking evaluation. The closest approved shapes by MECHANISM
(`numbat-parse-unit-expressions`, `gluon-format-comments`) are parser/formatter features in
different domains (unit expression parsing, source-code comment formatting) with no execution-engine
component. This is the first submission against `AmrDeveloper/GQL`, confirmed via
`SATURATED-REPOS.md` grep (no hits for "GQL"/"gitql") and directory scan of `approved-problems/`,
`problems/`, `rejected/` (no hits) during the olympus-hunt session that sourced this repo.

## Predicted iteration cycles: 2

(1 for the inevitable pass-rate calibration pass once eval data exists, since this repo has no
prior GQL batch to calibrate the 15-25% prediction against; target ships in round 2.)
