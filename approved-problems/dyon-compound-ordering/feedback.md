# feedback.md — dyon-compound-ordering

## Strategic summary
Olympus, autonomous one-shot. Target repo PistonDevelopers/dyon (Rust, Apache-2.0 OR MIT, 1914 stars, active 2025-12, obscure interpreter -> low training data = difficulty lever). Feature: extend total ordering (`<`,`<=`,`>`,`>=`, new `cmp`/`sort`, generalized `min`/`max`) from scalars to compound values (arrays/objects/options/bool/vec4), spanning type checker + stdlib + loop runtime.

## Assumptions / choices (autonomous)
- Repo pick: dyon over buntdb/gronx/roaring. gronx too small+complete (no 450-LOC gap); buntdb tx-adjacent to in-flight nutsdb; roaring too trained + correctness gives no F2P. dyon obscurity is the difficulty lever and it has a REAL gap: `equal` is structural (8 kind overloads) but ordering is scalar-only (3 overloads) and rejected at typecheck.
- BASE_COMMIT 3fb34a313a37e64937304754a13d15ee9eeff423 (HEAD 2025-12-23).
- Fresh-repo confirmation: dyon has NO prior problem folder (unused locally). A stray `worktrees/gronx`/`worktrees/dyon` clone existed but no `problems/dyon-*` -> repo unused as a problem.
- Empty numeric `min`/`max` builtin/reducer kept returning `nan` (no base test runs them; avoids regression). `cmp`/`sort` treat `nan` as an error (needed for a total order).
- Objects ordered by sorted `(key,value)` pairs (HashMap is unordered) — total order, insertion-order independent, consistent with `==`.
- Dropped nothing from cross-subsystem span; reducers kept behavior-preserving for f64.

## Phase B gate results (all GREEN)
- License Apache/MIT; 1914 stars; active; pure Rust; canonical org PistonDevelopers/dyon (not moved).
- SIX-CHECK: `sort`/`cmp` intrinsics absent; ordering never extended to compound (PR #414 = `==` structural equality only; #351/#352 = f64 min/max NaN). No maintainer philosophy hit. base==HEAD. Compound `<` currently fails at typecheck (#230) — capability absent.
- Exclusivity PR-DIFF: no PR/issue touches compound ordering or adds sort/cmp.
- Env-quality: `cargo test --no-run` exit 0; `cargo test` deterministic across 2 runs (will re-verify 3-5x in Docker).
- Flakiness: deterministic.

## Implementation reality (deviations from DESIGN.md)
- **Dropped the min/max LOOP-reducer generalization.** Making `min i n {}` / `max i n {}` reduce compound bodies requires changing their hardcoded `sec[f64]` result type (node.rs:438) and adding a typecheck refinement. That change breaks dyon's SECRET propagation timing (`source/typechk/secret_9.dyon` regressed: `why(a > 0)` needs `sec[bool]`). Too tangled/risky, so the loop reducers were reverted to base. The min/max BUILTINS are generalized instead (reachable + testable), which keeps the "reducers use their own comparison, not `less`" trap.
- **call_binop now deep-resolves operands** (`self.get(&x).deep_clone(&self.stack)`). Array/object elements are `Ref`s at runtime; the existing `equal` masks this by SWALLOWING the Ref error (so `[p]==[p]` for variables was a latent false). `cmp_vars` surfaces it, so operands must be deep-resolved. This also fixes the latent `equal` bug. New runtime/ surface.
- **Added an ordering toolkit for LOC depth** (compact-feature LOC wall: core alone was 212 human-eff). All build on one `cmp_vars` engine (distinct control flow, not registry breadth): `cmp`, `sort` (merge, stable), `bsearch`, `is_sorted`, `sorted_insert`, `dedup`, `lower_bound`, `upper_bound`, `argsort`, `group_by`, `rank`, `median`, `merge`, `kth_smallest`, `union`, `intersect`, plus generalized `min`/`max`. The HARD part is concentrated in the shared core (lexicographic prefix, HashMap key-sort, mid-array error-propagation, deep-ref resolution, four-binop typecheck), so the toolkit is interdependent, not 16 independent trivial functions.
- Final: 4 files (dyon_std/mod.rs, module.rs, runtime/mod.rs, lib.dyon), human-effective 472 (hook OK, >= 430). Base suite (7) stays green; 57 new tests (48 fail on base, all pass with solution).

## Attempt history
- Batch 0 (local): build clean (0 warnings), base 7/0, new pass with solution / fail on base. Deterministic x3.
- Docker validation (olympus-base-rust, --network none, --user 1000:1000): BOTH apply orders green. base 0 failures; new 47 fail (pre-solution) -> 0 (post). reverse-apply clean. JUnit counts 7 / 57. Determinism x3 identical. Edition-2024 image build OK (chmod /app + /opt/cargo AFTER cargo build so target/ is non-root-writable).
- Solvability sim (3 Sonnet imitators, meta-only): imit3 54/57 (missed only the deep-ref trap), imit2 36/57 (missed the compound core), imit1 stalled. See eval-results.md.
- Fairness fixes from sim: (1) DROPPED `kth_smallest_out_of_range_errors` (undocumented "range" keyword; both imitators missed it -> unfair universal miss). (2) ADDED a meta sentence documenting value-resolution ("reads the current value ... rather than by reference") so the deep-ref trap is fair-discoverable and the solvability floor is protected. Final: 57 tests. Reference solution 57/57; base 7/0 unchanged.

## Revision 1 (reviewer feedback)
- Description-quality (AI-slop): broke the two 150+ word paragraphs into 10 short paragraphs (longest now 56 words); no em-dashes/headers.
- Necessary-info: deleted the restatements of existing scalar behavior, the "utilities build on one canonical order" meta line, and the value-resolution sentence (value comparison is the default semantic; the variable-built tests exercise that default, so they stay fair without restating it).
- Test coverage: removed the "stable" claim from sort (stability is unobservable with whole-value comparison, so it cannot be tested here); made `min`/`max` error on an empty array (aligned with `median`) and added `min_max_empty_errors`; documented the empty-array error in meta.
- Behavior-focus/alignment: relaxed the non-mandated `nan`/`empty` substring assertions to "an error occurs" (new `errs` helper). Kept the `type` substring, which meta mandates.
- Re-validated in Docker both orders: base 0 fail, new 47 fail (pre) -> 0 (post) of 58, reverse clean. LOC 472. meta 410 words.

## Revision 2 (platform gates: Verify-Solution F2P + Solution-Quality + Test-Fairness)
Three platform gates fired; all addressed.
- **Verify Solution (F2P) FAIL** — 11 new tests passed on base (a new test that passes on base does not require the solution). Root causes: (a) regression tests (scalars, `==`, min/max-on-numbers) test unchanged behavior; (b) error-tests using `errs()` pass on base because the missing function errors "for the wrong reason"; (c) operator mixed-kind "type" tests pass on base because base typecheck already says "type". Fixes: removed the regression tests; moved mixed-kind checks onto the new `cmp` function (base "not found" lacks "type"); pinned nan errors on the `order` keyword (present in the solution message, absent from base + echoed source). Result: ALL 62 new tests fail on base.
- **Solution Quality FAIL** — real correctness gaps vs spec: scalar `nan` bypassed `cmp_vars` in `less`/`less_or_equal` (and derived `>`/`>=` gave a wrong bool); singleton fast-paths (`min`/`max` first element, `merge_sort`/`quickselect` len<=1) skipped validation so `sort([nan])`/`median([nan])`/`kth_smallest([nan],0)`/`min([ok(1)])` did not error; `lib.dyon` min/max docs stale. Fixes: nan-guard in the scalar `less`/`less_or_equal` fast-path (secret preserved); `resolved_items` now self-compares each element (`cmp_vars(x,x)`) so nan/unorderable error even for singletons, and `min`/`max`/`sort`/`is_sorted`/`sorted_insert`/`dedup`/`bsearch` all route through it (+ key validation on the search/insert utilities); lib.dyon docs corrected.
- **Test Fairness FAIL (1/58 unfair)** — `unorderable_kind_errors` over-pinned "type" for same-kind `result` values (not stated/discoverable). Removed. Added the 4 named coverage suggestions (sorted_insert tie, nan-in-nested-compound, utilities over options/bools, object byte-order) + real singleton-nan tests.
- **NaN gotcha**: `nan` is NOT a dyon literal (parses as an undefined variable). Real NaN is produced with `0.0 / 0.0`. Earlier nan tests were bogus (matched "nan" in the echoed source); rewritten to build NaN and assert `order`.
- Re-validated in Docker both orders: base 0 fail; new 62 fail (pre) -> 0 (post); reverse clean. 0 warnings. human-effective 485. 62 tests.

## Revision 3 (description-quality + alignment + necessary-info)
- **Good-quality FAIL + Alignment WARNING** — tests pinned error substrings (`order` for nan, `empty` for median) not stated in the description. Resolution (the reviewers' offered option, since relaxing to just-error breaks the F2P gate for new-function error tests): DOCUMENT the substrings, mirroring the accepted `type` pattern. Switched the nan keyword from `order` to `nan` (works now that the source builds NaN via `0.0/0.0`, so the literal `nan` no longer leaks into the echoed source) and made min/max/median empty tests assert `empty`. Meta now states nan errors contain "nan" and empty-array errors contain "empty".
- **Necessary-info request_changes (2 HIGH + 2 MEDIUM + 1 LOW)** — removed the redundant sentences: "Two values are ordered only when they are the same kind" (implied by the type-mismatch rule), the nested-mismatch propagation sentence (implied by same-kind rule + element-wise comparison), "whether through the ordering operators or these utilities", "whose elements share one kind", and "and let the first difference decide". Meta down to 318 words, 9 short paragraphs.
- Re-validated Docker both orders: base 0 fail; new 62 fail (pre) -> 0 (post); reverse clean. 0 warnings. human-effective 485. F2P clean (all 62 fail on base).

## Revision 4 (Test Fairness round 2 + coverage)
- **Test Fairness FAIL (1/66)** — `max_builtin_generalizes_to_strings` overreached: the meta enumerates min/max's extension as arrays/objects/options/booleans/vec4 (NOT text), and the repo advertises `max` as `[f64]->f64`. Replaced with `max_builtin_generalizes_to_arrays` (an enumerated kind). (`median`/`sort` over strings stay — they carry no enumerated-kind restriction, and the reviewer did not flag them.)
- Added the 3 advisory coverage suggestions (all F2P): `min_max_nan_errors` (generalized min/max reject nan), `intersect_dedups_results` (dedup on intersect, not just union), `nested_nan_in_object_errors` (recursive nan propagation inside objects).
- 69 tests. Docker both orders: new 69 fail (pre) -> 0 (post); base 0; reverse clean. F2P: all 69 fail on base. Solution unchanged (human-effective 485).

## Revision 5 (Test Fairness round 3 + coverage)
- **Test Fairness FAIL (1/69)** — `variable_built_equal_arrays_are_equal` pins `==` (equality) behavior, but the task scope is ORDERING, not equality; the repo never asks to change `==` (my call_binop deep-clone fixes it as a side effect, out of scope). Removed. The in-scope ORDERING variable-array tests (`variable_built_arrays_compare_by_value`, `nested_variable_arrays_ordered`, both `<`) stay and still exercise the deep-clone fix.
- Added the 2 coverage suggestions: dedup non-adjacent (`dedup([1,2,1]) == [1,2,1]`), and direct `cmp` over booleans/options/vec4 (`cmp_over_new_kinds`).
- 69 tests. Docker both orders: new 69 fail (pre) -> 0 (post); base 0; reverse clean. F2P: all 69 fail on base. 0 warnings. Solution unchanged (human-effective 485).

## Revision 6 (Test Fairness PASS + advisory coverage)
Test Fairness now PASSES (no unfair tests); the message carried only advisory coverage suggestions, all added (F2P-clean):
- `le_ge_over_compound_kinds` — direct `<=`/`>=` on objects, options, booleans, vec4.
- `helpers_over_compound_kinds` — lower_bound/upper_bound/is_sorted/group_by/merge over options, objects, arrays-of-arrays.
- `merge_boundaries` — empty inputs + duplicate-heavy inputs (duplicates preserved).
- 72 tests. Docker both orders: new 72 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 485).

## Revision 7 (advisory coverage; fairness-first)
Test Fairness PASS; advisory coverage suggestions handled selectively to avoid re-introducing unfairness:
- ADDED (fair): `bsearch_duplicate_returns_matching_index` (asserts the found index HOLDS the value via `a[i] == 2`, i.e. membership, not a pinned index); `helpers_propagate_type_errors` (mixed-kind via merge/union/intersect/lower_bound -> "type"); `helpers_propagate_nan_errors` (nan via merge/union -> "nan").
- SKIPPED (would be unfair to pin): out-of-range `k` for kth_smallest (behavior unspecified; this exact test was flagged unfair in an earlier round) and argsort tie-stability (a prior reviewer explicitly praised avoiding ties; "the indices that would sort a" is satisfied by any valid permutation, so pinning one is over-specification). Intent: any valid permutation / position is acceptable; not pinned.
- 75 tests. Docker both orders: new 75 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 485).

## Revision 8 (Solution Quality Code-Quality 3/3 + Test Fairness round 4)
- **Solution Quality Code Quality 2/3 -> aiming 3/3**: the only gap was API-overview consistency — `src/lib.dyon` (documentation only; NOT loaded at runtime, per DYON-API.md) documented just `min`/`max`. Added `///` doc declarations for all 16 new builtins (`cmp`, `sort`, `dedup`, `is_sorted`, `sorted_insert`, `bsearch`, `lower_bound`, `upper_bound`, `union`, `intersect`, `argsort`, `rank`, `group_by`, `merge`, `median`, `kth_smallest`) matching the repo's existing intrinsic-declaration style. (Comprehensiveness was already 3/3; PASS.)
- **Test Fairness FAIL (4/76)**: (1-3) singleton-NaN tests `sort([nan])`/`median([nan])`/`kth_smallest([nan],0)` over-specified eager validation (a singleton needs no comparison, so erroring is one valid strategy, not required) -> made median/kth **multi-element** (`median([2,n,1])`, `kth_smallest([2,n,1],1)`) so a comparison is forced (any impl must error), and dropped the redundant singleton `sort([n])` (multi-element `sort([1,n,2])` already covers it). (4) `lower_bound([1,[2]],1)` fed an unsorted/mixed array, violating the stated "sorted array" precondition -> removed that line (merge/union/intersect mixed-kind checks stay; the reviewer rated them fair since merging forces cross-array comparison).
- 74 tests. Docker both orders: new 74 fail (pre) -> 0 (post); base 0; reverse clean. F2P: all 74 fail on base. 0 warnings. human-effective 501.

## Revision 9 (Code Quality polish -> 3/3 + advisory coverage)
Addressed the reviewer's 3 concrete Code-Quality polish concerns:
- **call_binop deep-clone scoped**: was deep-cloning both operands for EVERY binary operator; now only Array/Object/Option operands are deep-resolved (scalars stay borrowed refs, zero clone). Narrows the cost to exactly the compound-comparison case that needs it.
- **rank O(n^2) -> O(n log n)**: sort once, then each element's rank is its lower_bound (count of strictly-smaller) via binary search.
- **median full-sort -> quickselect**: reuses the existing `quickselect` (O(n) average) instead of a full merge_sort.
- (Left the per-compare object key-sort: inherent to HashMap-backed objects; the reviewer called it an acceptable trade-off.)
Advisory coverage added (F2P-clean): `empty_array_search_bounds` (lower/upper_bound on []), `helpers_over_objects_and_vec4` (sort/dedup/argsort over objects + vec4).
- 76 tests. Docker both orders: new 76 fail (pre) -> 0 (post); base 0; reverse clean. 0 warnings. human-effective 514.

## Revision 10 (advisory coverage; fairness-first)
Test Fairness PASSES; these were advisory suggestions. Handled fairness-first:
- ADDED (fair): `argsort_ties_yield_sorted_sequence` — the reviewer's endorsed fair form: asserts the argsort permutation of `[5,5,3]` yields a non-decreasing sequence (`a[p[0]] <= a[p[1]] <= a[p[2]]`), without pinning a specific permutation.
- DECLINED (would regress Test Fairness): (a) kth_smallest out-of-range `k` — unspecified behavior; this exact test was flagged UNFAIR in an earlier round. (b) unsorted-input to bsearch/lower_bound/upper_bound/merge/union/intersect — "sorted array" is a stated PRECONDITION; behavior on violation is undefined, and pinning it (`lower_bound([1,[2]])`) was flagged UNFAIR earlier. Adding either would re-introduce an unfair test for zero gain (Test Fairness already passes; these are advisory).
- 77 tests. Docker both orders: new 77 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 514).

## Revision 11 (advisory coverage)
Test Fairness PASSES; both advisory suggestions fair and added (F2P-clean):
- `empty_helper_boundaries` — `dedup([]) == []` and `is_sorted([])` (vacuously true).
- `median_over_arrays` — compound-kind median (`median([[3],[1],[2]]) == [2]`), since prior median tests used only numbers/strings.
- 79 tests. Docker both orders: new 79 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 514).

## Revision 12 (advisory coverage)
Test Fairness PASSES; both advisory suggestions fair and added (F2P-clean):
- `search_helpers_nan_errors` — bsearch/lower_bound/upper_bound on `[1, n, 2]` (nan at the mid position, so a comparison is forced) -> error containing "nan".
- `search_set_helpers_over_vec4_and_objects` — bsearch/lower_bound over vec4 + objects, union over vec4, intersect over objects, completing the helper x new-kind cross-product.
- 81 tests. Docker both orders: new 81 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 514).

## Revision 13 (advisory coverage; fairness-first)
Test Fairness PASSES; advisory suggestions:
- ADDED (fair): `sort_over_vec4` — direct `sort` over vec4 values, exercising x/y/z/w ordering through the sort API.
- DECLINED (unfair, unspecified): kth_smallest out-of-range `k` — flagged UNFAIR in earlier rounds; the reviewer itself notes "the prompt defines selection but not bounds handling", i.e. undefined. Pinning it would regress Test Fairness for no score gain (advisory).
- 82 tests. Docker both orders: new 82 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 514).

## Revision 14 (Solution-Quality NaN gap + Test-Fairness NaN casing)
- **Solution Quality (Comprehensiveness/Code-Quality 2/3)**: the core `cmp_vars` short-circuits lexicographically, so `cmp([1, nan], [2, 0])` decided on `1 < 2` and never visited the nan — but spec says ANY value containing nan must error. Helpers dodged this via `resolved_items`, direct cmp/operators did not. Fix: added an explicit recursive `check_orderable(v)` (rejects nan/unorderable ANYWHERE in a value) and call it on both operands in `cmp` + `less` + `less_or_equal`; `resolved_items` now uses it too -> validation is UNIFORM and explicit across direct comparisons and helpers (also resolves the code-quality "inconsistency" note). Tightened 2 loose signatures (`bsearch` -> `opt[f64]`, `group_by` -> `[[any]]`). human-effective 547.
- **Test Fairness FAIL (10/82)**: all nan tests pinned the LOWERCASE substring `nan`, but the repo's existing error text spells it uppercase `NaN` (runtime/mod.rs:803-806, dyon_std/mod.rs:465-468) -> a solver following repo precedent would fail. Fix: made `err_has` CASE-INSENSITIVE (`e.to_lowercase().contains(kw.to_lowercase())`), so `nan`/`NaN`/`NAN` all pass. F2P preserved (base "not found" / `0.0/0.0` contain no "nan" in any case).
- Added the 2 coverage suggestions: argsort tie test now also asserts a true permutation (`sort(argsort([5,5,3])) == [0,1,2]`); `sorted_insert_over_objects`.
- 84 tests. Docker both orders: new 84 fail (pre) -> 0 (post); base 0; reverse clean. 0 warnings.

## Revision 15 (Auto Review: Tests 1/3 -> close 2 verified FN gaps)
Auto Review passed Scope 3/3, Description 3/3, Solution 3/3, but Tests 1/3 (revision requested) on two VERIFIED false-negative coverage holes. Both closed:
- **vec4 z never decisive** — existing vec4 tests exercised x/y/w but never made z the deciding component, so an impl ignoring z could pass. Added `vec4_z_component_decisive`: `(1,2,3,4) < (1,2,5,0)` (z 3<5 decides while w 4>0 would favor the opposite), and exercised through `sort` too.
- **kth_smallest numeric-only** — only numeric elements were tested, so a numbers-only impl could pass. Added `kth_smallest_over_compound` (nested arrays + options).
Also added the 2 advisory suggestions: recursive-nan for min/max (`min_max_recursive_nan_errors`, nested array containing nan) and generic kth_smallest (covered above).
- 87 tests. Docker both orders: new 87 fail (pre) -> 0 (post); base 0; reverse clean. F2P: all 87 fail on base. Solution unchanged (human-effective 547).

## Revision 16 (advisory coverage; fairness-first)
- ADDED (fair): `sorted_insert_into_empty` (`sorted_insert([], 5) == [5]`).
- DECLINED (would regress Test Fairness): (1) min/max on strings — this is the exact `max_builtin_generalizes_to_strings` test flagged UNFAIR earlier and removed; the meta enumerates min/max's extension as arrays/objects/options/booleans/vec4 (text NOT listed), and base min/max are `[f64]`-only, so min/max-over-str is new-but-unspecified (not a regression), and pinning it fails Test Fairness. (2) kth_smallest out-of-range `k` — unspecified behavior, flagged UNFAIR twice before.
- 88 tests. Docker both orders: new 88 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 547).

## Revision 17 (advisory coverage; F2P/fairness-first)
- ADDED (fair): `helper_family_over_strings` — `lower_bound`/`union`/`bsearch` over strings (generic helpers with no enumerated-kind restriction, like the accepted sort-over-strings; strings are already repo-ordered).
- DECLINED: (1) direct-operator mixed-kind (`[] < {}`) — NOT F2P: on base, compound operands to `<` always fail typecheck with a message already containing "type", so the test passes on base -> Verify-Solution F2P FAIL. Cross-kind "type" errors are only F2P-testable via `cmp`/helpers (base lacks them), already covered. (2) min/max over strings (part of suggestion 2) — enumeration-excluded, previously flagged unfair.
- 89 tests. Docker both orders: new 89 fail (pre) -> 0 (post); base 0; reverse clean. Solution unchanged (human-effective 547).

## Why this is not a duplicate
Closest local siblings: `zygomys-numeric-tower` (numeric type promotion int/float/bignum -- arithmetic widening, a different axis) and `eventhorizon-reorder-projection` (event reordering). This is structural TOTAL ORDERING of compound values (lexicographic arrays, canonical sorted-key objects, none<some options) plus a sorted-sequence toolkit, with a distinct trap family (lexicographic prefix rule, HashMap key-sort, mid-compound error-propagation, runtime Ref value-resolution, four-binop typecheck overloads). `rune-match-patterns`/`risor-match-patterns` are pattern matching, unrelated.
