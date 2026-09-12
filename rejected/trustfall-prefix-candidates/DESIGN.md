# DESIGN — trustfall-prefix-candidates

## 1. Title
Narrow query candidate values from string-prefix filters

## 2. Shape classification
**O-Algorithm-correctness** (Olympus), cross-subsystem span within `trustfall_core`.
Closest approved analog: `pest-dispatch` (6 files, 532 LOC, 8% pass, subtle-algorithm trap,
Wrong Logic >= 25%). Secondary analog: `cel-go-strict-dyn` shape note (single-cluster feature,
Diamond/Olympus because the difficulty is correctness-of-semantics, not raw span).

Span: `interpreter/hints/filters.rs` (static narrowing) + `interpreter/hints/dynamic.rs`
(runtime/tagged narrowing) + `interpreter/hints/candidates.rs` (candidate algebra + lexicographic
successor) + `interpreter/hints/vertex_info.rs` (the relevant-filter gate) + a soundness invariant
tying the two narrowing paths to the executor `interpreter/filtering.rs`.

## 3. Public API surface (observable, already exported from the top-level `trustfall` crate)
- `VertexInfo::statically_required_property(&str) -> Option<CandidateValue<FieldValue>>`
- `VertexInfo::dynamically_required_property(&str) -> Option<DynamicallyResolvedValue>`
  -> `DynamicallyResolvedValue::resolve(...)` yields `CandidateValue<FieldValue>` per result
- `CandidateValue<T>` = { Impossible, Single(T), Multiple(Vec<T>), Range(Range<T>), All }
- `Range<T>` with inclusive/exclusive `start`/`end` bounds + `null_included` flag.

These are re-exported from `trustfall::provider::*`. Tests assert on the returned
`CandidateValue`/`Range` through an adapter's `ResolveInfo`/`QueryInfo` -> this is a BEHAVIORAL
contract, not perf-only. That defeats PICK-FILTER Gate 1's "perf-only" reject.

## 4. Base behavior (the F2P gap)
`candidate_from_statically_evaluated_filters` (hints/filters.rs) maps only
`is_null / is_not_null / = / != null / < / <= / > / >= / one_of / not_one_of` to candidates.
String-prefix filters fall through to the post-processing branch and produce NO narrowing:
`statically_required_property("name")` for `@filter(op: "has_prefix", value: ["$p"])` returns
`CandidateValue::All` (or the nullable-field default) today. The maintainer left
`// TODO: use the other kinds of filters to exclude more candidate values` in that function.
`dynamic.rs::resolve_*` has a SECOND copy of the operator->candidate map (for tagged/runtime
operands) that also omits `has_prefix`. Both are COLD: no logic change since PR #263/#255
(2020-era); recent commits are edition/clippy/format only.

## 5. Correct behavior / canonical form (WHAT, pinned; withhold the algorithm)
For a property filtered with `has_prefix` against a statically-known string `P`
(literal or query variable), the required candidate is the `Range` of string values whose
membership is exactly the set of non-null strings that begin with `P`:
- start bound: inclusive `P`.
- end bound: exclusive at the shortest string strictly greater than every string beginning
  with `P` (the lexicographic successor of `P` under `FieldValue::String` ordering, which is
  Rust `str` ordering = Unicode-scalar/byte lexicographic). Concretely the successor drops any
  trailing maximum-scalar chars and increments the last remaining char by one scalar value.
- null is excluded from the range (a `has_prefix` match is never null).
- empty prefix `""` -> the full range of non-null strings (`Range::full_non_null()`).
- a prefix consisting entirely of the maximum Unicode scalar -> inclusive-`P` start with an
  unbounded end, null excluded.
- The `has_prefix` candidate must intersect with any co-located candidate-producing filters on
  the same property (`= / < / <= / > / >= / one_of / != null`) so, e.g., `has_prefix "ab"` plus
  `= "abc"` -> `Single("abc")`, and `has_prefix "ab"` plus `= "xy"` -> `Impossible`.
- The tagged/runtime path (`dynamically_required_property` -> `resolve`) must produce the same
  `Range` per-result once the tag value is known.

Negative constraints (the inverse traps, spelled out in meta):
- `not_has_prefix`, `has_suffix`, `has_substring`, `contains`, `regex` and their negations do
  NOT produce a candidate range; they remain post-processing filters (no narrowing).
- The soundness invariant: every value the executor's `has_prefix` accepts must lie inside the
  produced candidate (over-approximation is allowed; under-approximation is a wrong result).

## 6. Blind-spot pre-empts (from DESCRIPTION.md bank + AGENTS.md)
- Canonical-form: spell out start inclusive / end exclusive / null excluded (tests assert_eq on
  `Range`).
- "increment the last CHAR, not the last byte" is deliberately NOT stated (the multi-byte trap is
  the hidden-difficulty; it is inferable from "Unicode-scalar lexicographic" + `char::MAX`).
  This is the <=1 codebase-inferable requirement.
- State both static AND dynamic paths explicitly ("cross-feature ordering / integration hook").
- State the intersection requirement (general rule) BEFORE the two examples (avoid the
  "specific examples override general rule" blind spot).

## 7. File footprint (MODIFY / CREATE) + LOC estimate
MODIFY (source only):
| File | raw ~ | meaningful ~ | what |
|---|---|---|---|
| interpreter/hints/candidates.rs | 130 | 95 | lexicographic-successor helper, prefix-range builder, intersect/normalize interaction for the new range, exclude interaction |
| interpreter/hints/filters.rs | 70 | 55 | static: route `has_prefix` -> prefix Range in the partition_map + fold |
| interpreter/hints/dynamic.rs | 75 | 55 | runtime/tagged: route `has_prefix` -> prefix Range in resolve_property + resolve_fold_specific_field |
| interpreter/hints/vertex_info.rs | 60 | 45 | add `HasPrefix` to the relevant-filter gate (lines ~265-321) so it feeds narrowing; both property and fold paths |
| interpreter/hints/mod.rs | 15 | 10 | re-export / small helper wiring if needed |
CREATE: none required (all extension of existing hint machinery). Optionally a small
`interpreter/hints/prefix.rs` to house the successor + prefix-range builder (keeps candidates.rs
lean and adds a clean file for the algorithm) -> +1 file, moves ~90 meaningful there.

Estimate: **~300-360 meaningful LOC** on the honest slice. This is Olympus-Okay / Mars-Strong
borderline. See section 9 for the scope-up levers to reach the >=450 comfort buffer BEFORE first
batch (do NOT retrofit after calibration).

## 8. Predicted trap matrix (interdependent + misdirecting)
1. Increment last BYTE not last CHAR -> invalid bound / wrong range on multi-byte prefixes. (misdirecting: unicode test fails, error looks like an ordering bug)
2. `char::MAX` carry: `char::from_u32(0x10FFFF+1)` is None -> panic or wrong bound; must drop-and-carry. (interdependent with the empty-prefix case)
3. Forget null exclusion -> range includes null -> unsound narrowing, a downstream result test flips.
4. Included vs Excluded end bound -> off-by-one at the boundary string (`"abd"` wrongly included).
5. Static path only, forget the dynamic/tagged path (or vice versa) -> half the tests fail. (integration hook)
6. `not_has_prefix` wrongly narrowed (inverse trap) -> a soundness/result test fails.
7. Intersection with `=`/range filters not wired -> `has_prefix + =` doesn't collapse to Single/Impossible.
8. Empty-prefix -> must be `full_non_null`, and the vertex_info assertion (line ~230) forbids
   returning a "completely unrestricted range" that should be `All`; interacts with normalize.

Independent + opposing: fixing (2) all-max via "unbounded end" can regress (4)/(3) if null/bound
handling is copied wrong; wiring (5) dynamic surfaces (7) intersection again in a second place.

## 9. Scope-up levers (invent, do not pad) to reach >=450 eff
- Co-equal axis: also implement candidate narrowing for the currently-unhandled interaction of
  `has_prefix` inside `@fold` post-filters and the `dynamically_required_property` on fold-specific
  fields (dynamic.rs already has `resolve_fold_specific_field`).
- Add a public optimization-API helper `CandidateValue::narrow_with_prefix` /
  `Range`-from-prefix constructor on the public hint surface (adapter authors need an ergonomic way
  to build the same prefix range) -> +40-60 eff, testable public API, pairs the additive surface
  with the behavior change (avoids the "additive-only is discounted" dedup note).
- Both are genuine surface, not padding. Decide at DESIGN-freeze; target ~460 meaningful.

## 10. Tier + category + predicted pass
- Category: **enhancement** (extends an existing pass/subsystem; title "Narrow ... from ...").
- Tier: **Olympus** (O-Algorithm-correctness). Honest risk: a reviewer could read it as
  single-subsystem and downgrade to Mars; the dynamic-path + public-helper axes are what hold it
  at Olympus. Fallback: ship as Mars-Strong if a batch lands >20% under the honest slice.
- Predicted pass: **8-15%** (O-Algorithm-correctness band). Wrong Logic expected >= 25% (the
  successor algorithm), which is the difficulty signal we want.

## 11. Solvability / near-miss expectation
Best agent should land 1-2 tests short on the `char::MAX` carry or the multi-byte successor.
Expect Mixed best agent (Vega or Nova->Orion). >= 1 pass required (Olympus solvability).

## 12. Docker
Rust cargo2junit pattern (DOCKER.md top section): `olympus-base-rust`,
`cargo install cargo2junit && cargo fetch && cargo build --workspace`, NO chmod.
test.sh: `RUSTC_BOOTSTRAP=1 ... --format json | cargo2junit`, build-fail fallback.
Note: edition 2024 / rust-version 1.91 — verify `olympus-base-rust` rustc (ships 1.93+, OK).

## 13. Flakiness
Hint narrowing is pure/deterministic. Base suite under trustfall_core is deterministic
(no timing/network/order). Run base+new 3-5x. Gate 9 satisfied.

## 14. Quality-gate checklist (pre-first-batch)
- [ ] meta.md <= 200 words, ASCII, no em-dash, canonical form pinned, general-rule-before-examples
- [ ] every test traces to a meta sentence; <=1 codebase-inferable (the byte-vs-char detail)
- [ ] soundness invariant tested via an adapter that USES the candidate to pre-filter, then
      compared against unoptimized results (the cross-subsystem tie)
- [ ] both static and dynamic paths tested
- [ ] negative-op tests (not_has_prefix/has_suffix/... produce no range)
- [ ] eff LOC >= 450 (add section-9 axes) OR ship Mars-Strong honestly
- [ ] cargo2junit JUnit, build-fail fallback, unique test filename hex suffix, no `shipd`/`datacurve`
