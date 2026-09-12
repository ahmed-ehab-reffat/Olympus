# feedback.md — lol-html-sibling-combinators

## Strategic summary

Add the `+` / `~` sibling combinators and the `:is()` / `:where()` selector lists to lol-html's
compiled streaming selector VM. Chosen off `REPO-HUNT-2026-08-01.md` rank 1.

Lead trap is a dual-path flush (S5 / F-9): sibling continuation state must be recorded at every
terminal site of element execution and resumed after every attribute-bailout recovery point.
Band decider is expected to be a composition cell (F-10): void-element participation and
negated-alternation polarity, both of which have sole detectors in the suite.

## Scope history

- R0 pick: sibling combinators only. Build-measured at **169 human-effective LOC**, under the
  200 floor. This is the oracle-absorption failure mode recorded against customasm and taffy —
  the existing `ChildCounter` / jump machinery absorbed most of the work.
- R1 scope-up: added `:is()` / `:where()`. Not a bolt-on: an alternation is the first predicate
  form that cannot be split across the VM's existing local-name / attribute phases, so it forces
  a third expression phase that the sibling bailout logic then has to carry. Measured
  **286 human-effective** across 8 files.

## Validation performed

- Clean-room worktree at BASE_COMMIT: test.patch alone -> base green (185 cases), new 66/66 fail
  with `UnsupportedCombinator('+')` (right reason, not a build error).
- Plus solution.patch -> new 66/66 green 3x identical, base green 3x identical.
- Reverse apply order clean; both patches unapply clean.
- Docker: builds offline, runs `--network none --user 1000:1000`, both modes green.
  Needed `chmod -R a+rwX /app` (root-owned `target/` from the build blocks the non-root user) —
  same fix as the approved lyon-arcs-join Dockerfile.
- Trap reproduction: 8 natural-but-wrong implementations, every one caught. Table in
  `DESIGN.md § 11c`.

## Free independent oracle

The repo ships the W3C css3-modsel corpus and its harness skips selectors that do not parse.
This change activates 468 previously-skipped conformance cases per suite (6876 -> 6408 ignored,
across two suites). The reference passes all of them, and two of the eight mutations fail them —
so a wrong implementation can break an *existing* repo test whose failure reads as a fixture
output mismatch.

## Attempt history

| Round | Change | Result |
|---|---|---|
| R0 | sibling combinators only | 169 eff, under floor |
| R1 | + `:is()`/`:where()` alternation | 286 eff, 66 tests, all traps reproduced |
| R2 | self-review fixes (below) | 292 eff, 9 files, 66 tests, 0 compiler warnings |

No agent batch run yet.

## R2 self-review findings and fixes

Reviewed as an adversarial reviewer against the visible artifacts only.

1. **Dead public error variant (A2).** `SelectorError::UnsupportedCombinator` became
   unconstructible. Removing it would break semver on a public enum. The repo already has this
   exact situation and its own convention for it (`EmptyNegation`, marked `/// Unused` plus
   `#[deprecated(note = "unused")]`), so the variant now carries the same markers.
2. **Weak assertions (A5).** Four error tests used `.contains("Unsupported")` or
   `!...is_empty()`. Now compare the `SelectorError` value directly. This also caught a real
   mistake in my own test draft: I had asserted `:has(div)` yields `UnsupportedSyntax`; it
   actually yields `UnsupportedPseudoClassOrElement`.
3. **Misleading test name.** `sibling_matching_works_across_input_chunks` does not exercise
   chunking (`rewrite_str` feeds one chunk). Renamed to
   `later_matching_survives_a_long_run_of_siblings`, which is what it actually asserts.
4. **Weak fixture.** `adjacent_where_the_same_element_ends_and_starts_a_chain` asserted
   `["", ""]`. The elements now carry ids so the assertion pins which two matched.
5. **Fairness gap (A6).** Two tests lean on an element matching a handler's selector only once
   (`is_matches_an_element_satisfying_several_alternatives_once`,
   `several_sibling_selectors_match_the_same_element`). meta.md never said so. Added one
   sentence rather than dropping the tests.

Also verified: 0 compiler warnings across `--all-targets`, no unused imports, no dead helpers,
no drive-by refactors, solution touches only `src/selectors_vm/`.

## Open items before submit

- Confirm the platform does not flag lol-html as over-used (the "Learn more" page is the only
  oracle; nothing in `SATURATED-REPOS.md` and 0 of our own submissions).
- Re-run the canonical-org PR-diff exclusivity check immediately before submitting.
