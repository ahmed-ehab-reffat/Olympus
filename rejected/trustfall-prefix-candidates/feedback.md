# feedback.md — trustfall-prefix-candidates

Olympus attempt, O-Algorithm-correctness. See DESIGN.md.

## Implementation outcome (2026-07-21)
- Implemented has_prefix -> lexicographic-range candidate narrowing across static
  (hints/filters.rs), dynamic (hints/dynamic.rs), candidate-algebra (hints/candidates.rs),
  and the dynamic relevant-filter gate (hints/vertex_info.rs).
- Builds clean; 871 existing trustfall_core lib tests pass (no regression).
- Feature verified correct via a throwaway test: has_prefix "four" -> Range["four","fous")
  null-excluded; empty prefix -> full_non_null. Char-successor + empty-prefix edges work.

## REVIEW VERDICT: REQUEST CHANGE (fatal LOC-floor failure) -> pivot recommended
Decisive finding (PICK-FILTER Gate 4 LOC-CEILING, flagged as a risk in DESIGN section 7/10):
the honest reference is **64 effective LOC across 4 files** = BELOW the Mars 100 floor and far
below the Olympus 450 floor. The candidate-narrowing machinery already exists, so the correct
fix compresses to a surgical patch. Padding is banned (dead-code = revert cause), so this cannot
be salvaged into Olympus (or even Mars) as scoped.

Other review notes (all secondary to the LOC block):
- meta.md promises the dynamic (tagged) path; a fixture-driven public-API test for it is not yet
  built (only the static path is fixture-testable via the existing filter_op_has_prefix fixture).
- Feature, tests, and description are otherwise aligned and fair; difficulty (char-successor,
  char::MAX carry, null exclusion, exclusive end) is genuine O-Algorithm-correctness.

## Recommended pivot (genuine larger core, no padding)
FOLD AGGREGATIONS: TransformationKind and FoldSpecificFieldKind both have ONLY `Count`.
sum/min/max/mean are entirely missing. Adding them is a real O-Composite-add spanning
graphql_query (parse @transform ops) + frontend (validation + per-op type inference) +
ir (enum variants + exhaustive matches) + interpreter/execution (compute aggregation) +
interpreter/hints (generalize the count narrowing). Genuine irreducible LOC (each aggregation
has distinct type + null semantics), not pattern-followable, clears the Olympus floor honestly.
The prefix-narrowing work can be KEPT as a Mars-sized add-on or folded in as one axis.

## Open items
- Decide: (a) pivot to fold-aggregations Olympus, or (b) re-tier prefix-narrowing as a small
  Mars bundled with 1-2 more genuine narrowing axes to clear 100 eff.

## PIVOT ALSO DEAD — fold-aggregations is EXCLUSIVITY-DEAD (2026-07-21)
Maintainer draft PR #617 "Allow @transform directive to be applied to properties" (OPEN, draft,
created 2024-06-11, +19053/-2812, 602 files) implements the CENTRAL capability and touches the
exact core files: ir/mod.rs (+236), frontend/mod.rs (+895), graphql_query/directives.rs (+245),
interpreter/execution.rs (+471), NEW interpreter/transformation.rs (+297), hints/*.
Issue #748: maintainer names #617 as the answer to "add min/max, sum, average".
=> Gate 7b EXCLUSIVITY hard reject. Do NOT author fold-aggregations on trustfall.
Caught at PICK time (pre-authoring) = saved a full cycle (cf. nickel-optional-record-type).

## Net: trustfall has no clean Olympus for us.
- prefix-narrowing: sub-floor (64 eff).
- fold-aggregations / additional @transform ops: exclusivity-dead (#617).
Recommend switching repos for the Olympus (pulldown-cmark or suyashkumar/dicom from the shortlist).
