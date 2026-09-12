# DESIGN.md — dyon-compound-ordering

## 1. Title

Extend total ordering to compound values in Dyon

## 2. Shape classification

- Shape: **O-Composite-add** (net-new `cmp`/`sort` builtins + new type support wired across the type checker, the comparison intrinsics, and the loop-reduction runtime), with a strong **O-Algorithm-correctness** core (lexicographic + canonical-key ordering).
- Definition (PLAYBOOK § Pattern 12): a new capability spanning several subsystems (type checker → stdlib intrinsics → runtime reducers) whose failures are MISSED_REQUIREMENT / subtle correctness, not a single local wrap.
- Pass rate target: 15-25% (Olympus cap 40%; bias to the hard edge).
- Best agent: Mixed (Vega/Orion).
- Dominant verdict: MISSED_REQUIREMENT + WRONG_LOGIC.

## 3. Public API surface

Names tests assert (all reached through Dyon source):

- `<`, `<=`, `>`, `>=` — now accept two arrays, two objects, two options, two booleans, or two vec4s (same-kind), in addition to number/str. Different kinds error.
- `cmp(a, b) -> f64` — three-way comparison: returns `-1` when `a < b`, `0` when equal, `1` when `a > b`. Same ordering + same errors as the operators.
- `sort(a) -> []` — returns a new array with the elements of `a` in ascending canonical order; stable (equal elements keep input order); errors if elements are not mutually comparable.
- `min(a) -> any` / `max(a) -> any` — generalized from `[f64]` to any non-empty array of same-kind comparable elements; return the least / greatest element. (Empty numeric arrays keep returning `nan` as before.)
- `min i ... { }` / `max i ... { }` / `min ... in ... { }` / `max ... in ... { }` loop reductions — the reduced body value may now be any comparable kind, not only a number.

## 4. Canonical output form

- Only SAME-kind values are ordered. Comparing two different kinds is an error whose message contains `type`.
- bool: `false < true`.
- number: usual numeric order (unchanged for the operators; `cmp`/`sort` treat `nan` as an error containing `nan`).
- str: byte (lexicographic) order (unchanged).
- vec4: compare component x, then y, then z, then w.
- array: element by element in canonical order; the first differing element decides; if all compared elements are equal, the SHORTER array is less (a proper prefix is less than the longer array).
- object: compare by keys in ascending byte order; formally, compare the sorted lists of `(key, value)` pairs lexicographically, where a pair compares by key first then by value; a proper prefix (fewer keys, all shared leading pairs equal) is less.
- option: `none()` is less than any `some(_)`; `some(a)` vs `some(b)` compares `a` with `b`.
- Any other kind (link, closure, mat4, result, ...) cannot be ordered: comparing it is an error.
- A kind mismatch encountered DURING a compound comparison (e.g. a number meets a str at some array position) is an error and propagates; it does not count as "not less".

## 5. Blind-spot pre-empts (<=1 codebase-inferable)

- Sort-order ambiguity: quote — "compare by keys in ascending byte order" and "the shorter array is less" (verbatim in meta).
- Falsy/propagate-on-invalid: "A kind mismatch encountered during a comparison is an error and propagates."
- Codebase-inferable (1, allowed): the set of orderable kinds mirrors the kinds `==` already accepts (visible in `module.rs`); NOT restated as an implementation instruction.

## 6. Description draft (meta.md) — see meta.md, ~195 words.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (~0.65) | Reason |
| ------ | ---- | ----------- | --------- | ------------------ | ------ |
| MODIFY | src/dyon_std/mod.rs | 2600+ | +300 | ~200 | `cmp_vars` engine; compound `less`/`less_or_equal`; `cmp`, `sort` intrinsics; generalize `min`/`max` builtins |
| MODIFY | src/module.rs | 1000+ | +150 | ~95 | add array/object/option/bool/vec4 overloads to the 4 ordering binops; register `cmp`, `sort` |
| MODIFY | src/runtime/for_in.rs | 650 | +90 | ~60 | generalize `min_in_expr` / `max_in_expr` off the `f64::NAN` sentinel |
| MODIFY | src/runtime/for_n.rs | 470 | +90 | ~60 | generalize `min_n_expr` / `max_n_expr` off the `f64::NAN` sentinel |

TOTAL: ~630 raw / ~415-470 meaningful across 4 modified files, 3 subsystems. Reserve depth if under floor: a `bsearch(a, x)` intrinsic (binary search over the total order) — distinct real algorithm, not breadth.

Tier band check: Olympus 450 floor. Gate on the hook's `human-effective` >= 450; add `bsearch` if short.

## 8. Solution outline — pure-function helpers

- `cmp_vars(a, b) -> Result<Ordering, String>` ← the single source of truth for the order (§4). Recursive for array/object/option. THE engine.
- `less(a, b)` ← `cmp_vars(a,b)? == Less` (compound path added; scalar path unchanged for secrets).
- `less_or_equal(a, b)` ← `cmp_vars(a,b)? != Greater`. `greater`/`greater_or_equal` stay derived by negation (already correct for a total order).
- `cmp(rt)` intrinsic ← maps `cmp_vars` to `-1/0/1`.
- `sort(rt)` intrinsic ← stable sort of a clone via `cmp_vars` (bubble/insertion to guarantee a stable, error-propagating pass; not `slice::sort_by` which cannot return an error).
- `min(rt)` / `max(rt)` builtins ← `Option<Variable>` accumulator via `cmp_vars`; empty numeric preserved as `nan`.
- reducers `min_n_expr`/`max_n_expr`/`min_in_expr`/`max_in_expr` ← replace `let mut min = f64::NAN` with an `Option<Variable>` accumulator; keep the existing `sec` (secret) index tracking; keep the empty result as `F64(NAN)` for backward-compat.

Object canonical order helper (inside `cmp_vars`): collect keys, sort byte-ascending, compare `(key,value)` pairs — NOT HashMap iteration order.

## 9. Test file outline

Path: `tests/compound_ordering_<hash>.rs` (Rust integration test; matches `tests/lib.rs` style; runs Dyon via `Call::new(..).run_ret::<T>()`).

Block 1 — imports (`dyon::*`, `Arc`).
Block 2 — helpers: `eval_bool(body)` wraps `fn t() -> { <body> }` and pops a bool; `eval_f64(body)`; `err_of(body)` returns the error string; `expect_err(body, kw)` asserts Err containing kw.
Block 3 — assertion helpers (substring match for errors).
Block 4 — buckets:
- number/str baseline still works (regression guard).
- array lexicographic: equal-prefix-shorter-is-less; first-diff decides; nested arrays; `>=`/`>` derived consistency (`(a<b) == (b>a)`, `(a<=b) == !(b<a)`).
- object canonical key order: `{a:1}` vs `{b:1}` (key decides); `{a:1}` vs `{a:2}` (value decides); prefix `{a:1}` < `{a:1,b:0}`; **insertion-order independence** (`{a:1,b:2}` built two ways compare equal / consistent).
- bool / vec4 / option (`none` < `some`; `some(a)` vs `some(b)`).
- kind mismatch errors: `[1] < ["a"]` at top; `[1,2] < [1,"a"]` mid-array propagation; `1 < "a"`; object-vs-array; link/closure not orderable.
- `cmp`: `-1/0/1` on the above.
- `sort`: numbers; strings; arrays-of-arrays; stability (objects with equal key differing tie-break); error on mixed.
- `min`/`max` builtins: arrays of arrays; arrays of strings; mixed → error; single element.
- `min`/`max` loops returning arrays/strings.
- `nan` policy: `cmp(nan, 1)` errors; `sort` of a list containing `nan` errors.

Count anchor: ~55-70 tests.

5-axis coverage: every §4 rule; every new API; every branch of `cmp_vars`; edges (empty/single/prefix/nested/mismatch/nan); derived-operator inverse.

## 10. Forced bounds

- Rust: `cmp_vars` returns `Result<std::cmp::Ordering, String>`; recursion on `Array`/`Object`/`Option`. `sort` must NOT use `slice::sort_by` (closure can't propagate `Err`) → hand-written stable pass returning `Result`. Object path forces key collection + sort (HashMap has no order).

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence (§6) | Test that catches it |
| - | ---- | ----------------- | ---------------------- | -------------------- |
| 1 | Lexicographic prefix: shorter-is-less when prefix-equal | naive `zip` stops at the shorter and reports "equal" → not-less; and the derived `>=` then wrongly returns true | "if all compared elements are equal, the shorter array is less" | `array_prefix_shorter_is_less`, `derived_ge_prefix_consistent` |
| 2 | Object ordering must sort keys | `Object` is a `HashMap` (unordered); iterating it directly is nondeterministic AND wrong; the `==` template they'd copy is order-independent so it hides the need | "compare by keys in ascending byte order" | `object_insertion_order_independent`, `object_key_decides` |
| 3 | min/max reducers/builtins use their OWN f64 comparison, not `less` | fixing `less` alone leaves `min([[..]])` erroring; the failing test names `min`, pointing away from the reducer/builtin code | (min/max "generalized ... any comparable kind") | `min_of_arrays`, `max_loop_returns_str` |
| 4 | Mixed-kind element error must PROPAGATE | the `equal` intrinsic (their copy source) uses `matches!(.., Ok(Bool(true)))` which SWALLOWS the error → treats mismatch as "not less" → wrong `>=` | "a kind mismatch ... is an error and propagates; it does not count as not less" | `array_midelement_type_mismatch_errors` |
| 5 | Typecheck overloads needed on ALL FOUR ops | `<` may typecheck after adding one overload but `>`/`>=`/`<=` still reject compound; interdependent across the 4 binops | (operators listed together) | `derived_gt_arrays`, `le_objects` |

Wrong Logic expected >=25% → confirms a genuine correctness trap, spec is unambiguous.

## 12. Tier + category

- Tier: Olympus.
- Sub-rank: Olympus-Good (target ~15-20%).
- Category: **feature-request** (net-new `cmp`/`sort` intrinsics + net-new type support).

## 13. Predicted Nova pass rate

- Predicted: 12% - 22%.
- Reasoning: O-Composite-add band + 5 interdependent+misdirecting traps (prefix, key-sort, reducer-separation, error-propagation, four-binop typecheck). The `==` overload list is a fair single codebase-inferable hint for the TYPE surface only; the ORDER semantics are undiscoverable from it (equal is order-independent).
- Sanity: >0 (a careful implementer who reads §4 line-by-line and writes one `cmp` engine passes). Not >40% (each trap independently sinks a run).

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (Phase 1 below)
- [x] Existing-PR/issue check: 0 hits for compound ordering / sort / cmp (searched sort, compare, ordering, less, min max; only `==` structural equality PR #414 and f64 min/max PRs exist)
- [x] Closest approved opened as scaffolding: eventhorizon-reorder (O-Composite engine), zygomys-numeric-tower (value-kind dispatch) — DIFFERENT feature (numeric promotion vs structural ordering)
- [x] Title verb-led, names subsystem
- [x] Shape declared w/ citation
- [x] Public API lists every asserted name
- [x] Canonical order fully spelled out (§4)
- [x] <=1 codebase-inferable requirement (the type surface only)
- [x] Description word count <=200
- [x] No headers/labels/Box in meta
- [x] File footprint against real files
- [x] LOC within band (gate on hook; reserve `bsearch`)
- [x] 1+ helper per behavior (`cmp_vars` is the spine)
- [x] Test outline 4-block, scenario names
- [x] 5-axis coverage
- [x] Forced bounds documented (Result-returning sort)
- [x] 5 named traps each w/ pre-empt + catching test
- [x] Wrong Logic >=25% understood
- [x] Predicted pass matches band
- [x] Tier/category honest
- [x] NOT pattern-followable (no existing compound-ordering sibling; `==` is order-independent)
- [x] NOT in Features-already-used

### Phase 1 — Repo understanding
- Architecture: Dyon is a dynamically-typed embeddable scripting language; source -> piston_meta grammar (`assets/syntax.txt`) -> AST (`src/ast`) -> lifetime+type checker (`src/lifetime`, incl. `typecheck/refine.rs`) -> tree-walking runtime (`src/runtime`, values in `Variable`). Intrinsics live in `src/dyon_std`, registered with type signatures in `src/module.rs`.
- 5 subsystems: grammar/parse; ast; lifetime+typecheck; runtime; stdlib(dyon_std)+module registration.
- High-entanglement zones: the binop intrinsics (type sig in module.rs + impl in dyon_std + typecheck overload resolution in refine.rs); the loop-reduction family (ast + for_n/for_in runtime); `Variable` kind dispatch.
- Test framework: cargo `#[test]` in `tests/`; scripts under `source/`; `Call::new(..).run_ret::<T>()` to call a fn and read the value.
- Template test file: `tests/lib.rs`, `examples/call.rs`.

### Why this is not a duplicate
Closest siblings: `zygomys-numeric-tower` (numeric type PROMOTION across int/float/bignum — arithmetic widening, not structural ordering) and `eventhorizon-reorder-projection` (event reordering engine). This feature is total ORDERING of compound structural values (arrays/objects/options) with lexicographic + canonical-key semantics, a distinct trap family (prefix rule, HashMap key-sort, error-propagation) not present in either. `rune-match-patterns`/`risor-match-patterns` are pattern matching, unrelated.

Predicted iteration cycles: 2.

## Implementation deviation (post-build)
The min/max LOOP-reducer generalization (§7/§8) was DROPPED: it requires changing the hardcoded `sec[f64]` result type of min/max loops, which breaks dyon's secret-propagation type inference (`secret_9.dyon`). Reverted to base. Replaced with: (1) `call_binop` deep-resolves operands (fixes a latent `equal` Ref-swallowing bug and enables compound operators on variable-built arrays — a runtime/ surface), and (2) an ordering toolkit built on the single `cmp_vars` engine (`cmp`, `sort`, `bsearch`, `is_sorted`, `sorted_insert`, `dedup`, `lower_bound`, `upper_bound`, `argsort`, `group_by`, `rank`, `median`, `merge`, `kth_smallest`, `union`, `intersect`) plus generalized `min`/`max` builtins. The 5 traps remain concentrated in the shared core. Final footprint: 4 files, human-effective 472.
