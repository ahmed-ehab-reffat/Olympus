# sqlfluff-fix-transaction

**Status:** READY (LOC floor waived by the user)
**Tier:** Olympus (user-mandated)
**Repo:** sqlfluff/sqlfluff @ 978dfbe3da1c5b589a308339331eb28b94945cb0 (MIT, 9.8k stars, pushed 2026-07-13)
**Category at submit:** feature-request

## Why this repo/feature (the distinctness fix)

The previous attempt (bleve span queries) was rejected `derivative` against two older corpus
submissions. Root lesson, now in memory as `olympus-canonical-family-port-collides`: porting a FAMOUS
feature family (Lucene spans, ES aggregations, MoreLikeThis) is the shape multiple authors converge
on. A distinct core has to be idiosyncratic repo machinery.

This one is. It is sqlfluff's own fix engine, not a named feature anyone ports.

Verified before writing code (the step whose absence killed the bleve replacement):

- **Upstream open PRs on the topic: ZERO.** Searched `conflict`, `atomic`, `provenance`, `oscillat`,
  `runaway`, `fix loop`.
- **Env-quality gate: GREEN.** Full vanilla suite offline, non-root: **10,415 passed / 0 failed**
  (needs `chmod -R a+rwX /app` in the Dockerfile -- the fix tests write into the repo tree, same
  non-root permission bug as bleve).
- Candidates rejected on evidence: **kustomize** (vanilla suite fails offline without injected
  ldflags, *in the packages the feature would touch*), **go-task** (env perfect, but four open PRs
  already attack the individual surfaces -- #1401/#2677/#2676/#1816), **atlas** (reverse planning
  already exists: `Change.ReverseStmts`, `sqlx.ReverseChanges`), **mtail** (goyacc-generated parser;
  any syntax feature buries solution.patch in generated tables).

## The gap (evidence-backed)

sqlfluff runs each rule against the tree the previous rule left behind, so:

1. **Cross-rule conflicts are architecturally unobservable.** Rule N+1 never sees rule N's tree. Two
   rules that want the same source silently last-write-win, and the winner is decided by alphabetical
   rule code -- an accident of naming. The existing `AnchorEditInfo.is_valid` check is intra-rule only
   and is `# pragma: no cover` dead code.
2. **Atomicity is inconsistent at three granularities.** A partially-fixed file genuinely reaches disk
   (pinned by the repo's own test at `test/core/linter/linter_test.py:1216`).
3. **Provenance does not exist.** Every skip/conflict/oscillation reason is a *logger call*. sqlfluff
   even reports a fix to the user that it has already decided never to apply. `LintedFile` has no
   field for it.

## What is built (and green)

Opt-in `fix_transaction` config (default `False`, so the 10,415 existing tests keep passing -- the
default sequential path is untouched, and an agent who changes it shreds the baseline).

- NEW `src/sqlfluff/core/linter/fix_transaction.py` -- `FixOutcome`, `StagedFix`, staging,
  overlap-based cross-rule conflict detection, deterministic resolution (lowest rule code wins),
  single-batch commit, rollback.
- `linter.py` -- stages every rule's fixes against ONE snapshot, then resolves / commits / rolls back.
- `linted_file.py` -- `LintedFile.fix_outcomes`.
- `default_config.cfg` -- `fix_transaction = False`.

**Backward compatible on purpose:** an early version changed `lint_fix_parsed`'s return arity and broke
`test/api/classes_test.py`. That is a breaking public-signature change, so it was reverted to an
optional out-parameter.

Local state: **12/12 new tests pass**; **1134 existing tests pass, 0 regressions**; no dead code.

## LOC: EXPANDED to clear >300 on user instruction (was waived, then user set the bar)

User first waived the floor ("continue do not matter about eff loc"), then set an explicit bar:
**"eff loc should be more than 300"**. Built out the feature's real surfaces to meet it -- no padding.

`effective_loc_check.py`: **151 -> 306 human-effective; 227 -> 479 raw; 4 -> 8 files.** Over the 300
bar. (Still under the nominal 430 Olympus floor; the user set 300 as the target and that is logged as
the governing instruction. If a reviewer re-counts and wants the full 430, the remaining headroom is
the templated-slice INTERSECTION refinement and a JSON-output path -- both deferred as test-fragile.)

Surfaces added, each real feature work with tests, all four originally-scoped items now built:

1. **Provenance delivery (CLI).** `OutputStreamFormatter.format_fix_transaction_report` /
   `dispatch_fix_transaction_report`, wired into the `fix` command. `sqlfluff fix` now prints the
   transaction summary and every skipped fix with its reason. Gated on outcomes existing, so the
   feature-off default path (all 10,415 vanilla tests) prints nothing new -> zero regression.
2. **Cross-file aggregation.** `LintedDir` retains outcomes + per-file serialised records even when
   files are discarded; `LintingResult.get_fix_outcomes` / `fix_transaction_report` /
   `fix_outcome_records` / `conflict_groups` / `oscillating_rules` roll them up.
3. **Templated-aware conflict.** Conflict = raw source overlap AND both fixes touch editable literal
   source (`StagedFix.touches_literal` via `LintFix.get_fix_slices`). A fix confined to a `{{...}}`
   region rewrites nothing and blocks no one. IMPORTANT correctness note: a non-templated file is a
   single whole-file literal raw slice, so a naive literal-slice INTERSECTION marks every cross-rule
   fix as conflicting (verified). The shipped rule is overlap-AND-both-literal, which is identical to
   pure numeric overlap on non-templated SQL (safe) and only excludes pure-templated fixes.
4. **Provenance query API + report.** `FixTransactionReport` (applied/skipped/reasons/total/summary/
   to_dict), `FixOutcome.to_dict`, `conflict_groups` (winner -> displaced losers), `oscillating_rules`,
   plus `applied_fixes` / `skipped_fixes` / `fix_conflicts` on `LintedFile`.

Tests grew 14 -> 19 to cover every new surface (distinct-source no-conflict, report tally + summary +
to_dict, conflict groups, oscillating rules, CLI render, result-level aggregation). All 19 fail on
base as distinct nodes, all pass on solution; full regression 1141 passed / 0 regressions.

## Deliverables

All 5 platform files + 2 tracking files are present. 4-cell matrix green (see eval-results.md):
base/base PASS 3399-0, base/new FAIL 12-12, sol/base PASS 3399-0, sol/new PASS 12-0. Patches apply in
either order and reverse to a pristine tree. meta.md is 230 words, ASCII, no headers.

**Still outstanding: the naive-agent benchmark has NOT been run.** It is mandatory before submitting.

## AI-check round 1 (2026-07-15) -- addressed

Three checks returned WARNING / request_changes. All addressed:

- **Tests cover required behavior (WARNING).** Added the three suggested cases (managers revert for
  unaddressed coverage): (a) `test_fixtx_opposite_end_inserts_on_one_anchor_compose` -- a
  `create_before` + `create_after` on one anchor both apply, no skip; (b) the `FixOutcome` import path
  from `sqlfluff.core.linter.fix_transaction` is now exercised (imported + `isinstance` in
  `test_fixtx_applied_fixes_are_recorded`); (c) `test_fixtx_is_off_unless_the_setting_is_turned_on`
  builds a config with NO `fix_transaction` override and asserts `fix_outcomes` empty + fix still
  applied. New suite: 12 -> 14, all fail on base as distinct nodes, all pass on solution.
- **Tests focus on behavior (WARNING) + alignment (WARNING).** Both flagged `fix_outcomes == ()`
  over-constraining the container type. Relaxed the two sites to `assert not linted.fix_outcomes`.
  meta keeps "fix_outcomes is empty" (no tuple pinned), so both directions agree.
- **Necessary-information (request_changes, 3 HIGH).** Complied with the two genuinely-redundant
  removals: deleted the background "Each rule fixes the tree..." sentence and the "and leaving the
  existing loop untouched" clause. KEPT the `FixOutcome` import path -- it is now directly tested, so
  removing it would create a description<->test misalignment (a hidden requirement, the harder reject).

  BYPASS for the surviving HIGH (import path), all six elements:
  Check `problem_description_contains_only_necessary_information` requested deletion of the
  `sqlfluff.core.linter.fix_transaction` import path; the request is WRONG here because the path is a
  load-bearing part of the public contract that the hidden suite asserts on -- `test.patch` imports
  `FixOutcome` from exactly that module and calls `isinstance`, so deleting the path from meta.md
  removes a DESCRIBED-and-TESTED fact and manufactures a hidden requirement, which is the more severe
  Test-Fairness reject. Numbers: 1 of 3 HIGH items retained, 2 complied with; 14 F2P tests, 1 of them
  binds the import path directly; meta.md 179 words (within the 150-250 complex-feature band). Dominant
  pattern: the necessary-information checker escalates any concrete public symbol to HIGH regardless of
  whether a test pins it, which is the known over-deletion failure mode. Alignment: every described
  behavior including the import path is tested, and every test traces to a described behavior, so the
  description is minimal AND complete. Conclusion: keeping the one tested import path is correct and the
  HIGH is safely bypassed.

## AI-check round 2 (2026-07-15) -- addressed (alignment had FAILED)

The expansion tripped a blocking `problem_and_tests_are_aligned` FAIL plus two WARNINGs and a
necessary-information request_changes. Resolved holistically:

- **Alignment FAIL (interface not specified).** Tests pinned method-ness, the `conflict_groups` shape,
  and `LintingResult` accessors that meta left vague. Fixed by DOCUMENTING exactly what the tests
  assert: `summary()`/`conflict_groups()`/`oscillating_rules()`/`fix_transaction_report()` named as
  methods with `()`, `conflict_groups` return shape spelled out (winner -> tuple of displaced codes,
  one per displaced fix), and the three aggregating `LintingResult` methods named
  (`get_fix_outcomes()`, `fix_transaction_report()`, `conflict_groups()`). `FixOutcome.to_dict()` also
  named (now tested).
- **Behavior-focus WARNING + the alignment CLI point.** Both said the exact CLI strings were
  over-pinned. RELAXED the formatter test to assert the information is present (counts, and each
  skipped fix listed with the rule it lost to) instead of the literal header/line text. Because the
  test no longer pins format, meta needs no CLI-format spec -- it stays behavioral ("prints the
  report, listing each skipped fix with its reason"), which is what the test now checks. Both the
  WARNING and the alignment CLI item are resolved by the single relaxation.
- **Coverage WARNING.** Added `test_fixtx_convenience_selectors_expose_outcomes` (asserts
  `applied_fixes`/`skipped_fixes`/`fix_conflicts` and the full `FixOutcome.to_dict` field set),
  addressing (b) and (c). For (a) -- "fixes confined to templated regions do not compete" -- the claim
  was REMOVED from meta rather than pinned: a clean, deterministic public-path test is not reliably
  constructible (templated fixes are discarded by apply_fixes before any outcome is observable, as
  three probes confirmed). The `StagedFix.touches_literal` gate remains as a correctness measure whose
  common (literal -> True) branch is exercised by every conflict test; with the claim gone there is no
  described-but-untested behavior. Tests 19 -> 20.
- **Necessary-information request_changes (3 HIGH-ish + redundancies).** Complied with the
  redundant-clause removals ("and told which rule took it", "regardless of the order the rules were
  given in", "(say different columns)"). KEPT `applied_fixes`/`skipped_fixes`/`fix_conflicts` in meta
  because they are now directly tested (removing them would recreate the alignment FAIL as a hidden
  requirement). Kept "including fixes that were themselves sound" -- it is asserted by the rollback
  test, so removing it would also misalign.

  BYPASS for the surviving necessary-information HIGH (the three convenience selectors), six elements:
  Check `problem_description_contains_only_necessary_information` asked to delete `applied_fixes`,
  `skipped_fixes` and `fix_conflicts` from meta.md; the request is WRONG here because those three are
  load-bearing tested contract -- `test_fixtx_convenience_selectors_expose_outcomes` calls all three
  and asserts their contents, so deleting them from meta.md removes described-and-tested facts and
  manufactures hidden requirements, which is exactly the blocking Test-Fairness / alignment failure
  that FAILED this same round. Numbers: 20 F2P tests (base/new 20 fail / 0 pass-on-base, sol/new 20
  pass), meta.md 281 words within the 200-450 API-heavy band, 3 of the round's redundant clauses
  complied with and only the 3 tested selectors retained. Dominant pattern: the necessary-information
  checker escalates every concrete public symbol to HIGH regardless of whether a hidden test pins it,
  the known over-deletion mode. Alignment: every described selector is tested and every test traces to
  a described method, so meta is minimal AND complete. Conclusion: retaining the three tested selectors
  is correct and the HIGH is safely bypassed.

## AI-check round 3 (2026-07-15) -- Test Fairness FAILED + to_dict ERROR + Solution 2/3s

Round 3 brought a blocking Test Fairness FAIL (6 tests), a blocking sanity ERROR, two Solution
Quality 2/3s, and the usual formatting WARNINGs. All addressed.

- **Sanity ERROR: `to_dict` key mismatch.** meta documents the field `rule_code`, but
  `FixOutcome.to_dict()` emitted key `code`. Renamed the key to `rule_code` (matches the attribute and
  meta) and updated the test. Now consistent.

- **Test Fairness FAIL (6 unfair -- exact-representation pinning on new API).** Relaxed every one to
  assert content, not representation, per the "relax unless genuinely required" rule:
  * `summary()` exact string -> assert it returns a non-empty `str` (existence is documented, wording
    is not).
  * report `to_dict()` exact shape -> assert it carries `applied`/`skipped`/`reasons` (all documented
    fields) without pinning the exact key set (an impl may add `total`).
  * `conflict_groups()` exact `{"T801": ("T802","T802")}` -> assert winner key present and loser named,
    no tuple/duplicate pinning. meta simplified to drop "a tuple ... one entry per displaced fix".
  * `oscillating_rules()` `frozenset` -> `set(...) == {"T804"}` (content, not container type).
  * formatter-helper test with exact header/body strings -> REPLACED with an end-to-end
    `test_fixtx_fix_command_prints_the_transaction_report` that runs `sqlfluff fix --force` on a file
    (built-in CP01, `fix_transaction = True` in `.sqlfluff`) and asserts the file is fixed and the
    report reaches output. No custom helper or exact wording required -> fair, and it satisfies the
    "add an end-to-end CLI test" coverage suggestion.
  * `LintingResult` exact accessor names -> kept (now named in meta, so discoverable/fair) but the
    value assertions were relaxed to match the per-file relaxations, in a dedicated
    `test_fixtx_result_aggregates_outcomes_across_a_run`.
  Note: the Fairness report was marked Stale and predated the round-2 meta that already names the
  methods/accessors; the relaxations above make the tests fair regardless of meta wording.

- **Behavior-focus WARNING (exact summary string).** Same relaxation as above.

- **Solution Comprehensiveness 2/3 -> aimed 3/3.**
  * G1 (outcomes not threaded through alternate parse variants): `lint_parsed` now passes the shared
    `fix_outcomes` buffer into the alternate-variant `lint_fix_parsed` call too, so every proposed fix
    in a multi-variant file leaves a `FixOutcome`.
  * G2 (conflict detection "coarser than exact source-touch"): replaced the boolean literal gate with
    a precise `StagedFix.footprint` (the set of literal raw-slice offsets a fix touches, via
    `get_fix_slices`). Conflict = source-position overlap AND footprint intersection. The position
    check still discriminates the single-whole-file-literal-slice case (where a naive intersection
    would mark everything as conflicting -- verified), and the intersection now correctly lets two
    source-only edits behind one anchor that touch different slices proceed without competing.

- **Code Quality 2/3 -> aimed 3/3.**
  * Formatter contract: added `dispatch_fix_transaction_report` to the abstract `FormatterInterface`
    (concrete no-op default, so existing implementers are not broken) -- the CLI call is now part of
    the declared contract.
  * Same-anchor guard: the transactional branch now runs `compute_anchor_edit_info` and only stages a
    rule's fixes when they pass the same intra-rule validity check the sequential path uses, so a rule
    returning internally-conflicting fixes behaves identically in both modes.
  * Typing: `FixOutcome.to_dict()` annotation widened to `dict[str, object]` (values include ints).

Result: tests 20 -> 21, effective LOC 306 -> 321 (9 files, raw 507). Matrix: base/new 21/21 fail / 0
pass-on-base; sol/base 3399/0; sol/new 21/0. Full regression 1143 passed / 0 regressions.

## AI-check round 4 (2026-07-15) -- Fairness 1 unfair + a REAL BUG caught + coverage

Down to one unfair test; also caught and fixed a genuine bug while adding the requested CLI coverage.

- **REAL BUG (found via the coverage suggestion).** Renaming the `to_dict` key `code` -> `rule_code`
  (round 3) left `format_fix_transaction_report` still reading `outcome['code']`, so `sqlfluff fix`
  raised `KeyError('code')` whenever a transaction had a skipped fix. The round-3 CLI test used CP01
  (no skips), so the path was never hit -- exactly the gap the "add a CLI test with skipped fixes"
  suggestion named. Fixed the formatter to read `rule_code`; the new CLI test below now guards it.

- **Test Fairness (1 unfair): `summary()` non-empty-string pin.** meta promised only "a summary()
  method"; the test asserted a non-empty `str`. Relaxed the test to `isinstance(report.summary(),
  str)` and documented "a `summary()` method returning a string" so meta and test agree (return type
  now stated, wording still free).

- **Coverage WARNING + suggestions.** Replaced the CP01 CLI test with an end-to-end
  `sqlfluff fix` on `SELECT a , b FROM t` using the built-in rules `LT01,LT09` (which genuinely
  conflict under a transaction -- verified), asserting the output shows `applied`, `skipped`, `LT09`
  and `conflict`. This is fully fair (built-in rules, no custom helper, content not exact format),
  covers the prompt's "lists each skipped fix with its reason", and guards the KeyError. Also added
  `test_fixtx_conflict_groups_track_distinct_losers` (one winner displacing two distinct loser rules)
  for the "multiple conflict groups" suggestion. Tests 21 -> 22.

- **Necessary-information request_changes.** Complied with the removable MEDIUM ("so no rule sees
  another's edits" -- implied by the single snapshot). KEPT the tested clauses: "so fixes to distinct
  source do not conflict" (asserted by test_fixtx_rules_on_distinct_sources_do_not_conflict),
  "including fixes that were themselves sound" (asserted by the rollback test), and "listing each
  skipped fix with its reason" (now asserted end-to-end by the CLI test). Left "applied as one batch"
  as a one-line aid (non-blocking MEDIUM).

  BYPASS for the necessary-information HIGH ("listing each skipped fix with its reason"), six elements:
  Check `problem_description_contains_only_necessary_information` asked to delete "listing each skipped
  fix with its reason"; the request is WRONG here because that user-visible detail is now load-bearing
  tested contract -- `test_fixtx_fix_command_prints_the_transaction_report` runs `sqlfluff fix` and
  asserts the skipped fix (`LT09`) and its reason (`conflict`) appear in output, and this exact
  behaviour also guards a real KeyError regression, so deleting it from meta.md would drop a
  described-and-tested fact and re-create a hidden requirement. Numbers: 22 F2P tests (base/new 22
  fail / 0 pass-on-base; sol/new 22 pass), meta.md 270 words within the 200-450 API-heavy band, 1 of
  the round's MEDIUM clauses complied with and only tested clauses retained. Dominant pattern: the
  necessary-information checker flags user-facing output detail as over-specification even when a
  hidden test pins it -- the known over-deletion mode. Alignment: the skipped-fix listing is both
  described and tested end-to-end, so meta stays minimal AND complete. Conclusion: retaining the
  clause is correct and the HIGH is safely bypassed.

## AI-check round 5 (2026-07-15) -- Fairness 1 unfair (incidental rule-code pin)

- **Test Fairness (1 unfair): `LT09` loser pin.** The end-to-end CLI test asserted the specific
  built-in loser code `LT09` appears -- an incidental, non-discoverable rule interaction. Relaxed to
  assert the report shows the counts (`applied`, `skipped`) and a `conflict` reason, without naming
  which built-in rule loses. Still covers "prints the report, listing each skipped fix with its
  reason" and still guards the KeyError regression; no longer coupled to incidental rule behaviour.

- **Coverage suggestions (advisory).** Added `test_fixtx_outcomes_aggregate_across_multiple_files`
  (lint_paths over two files -> 8 outcomes, report/conflict_groups aggregate). Attempted a CLI
  disabled-path test but it PASSES ON BASE by construction -- with the feature off the CLI behaves
  exactly like base, so there is nothing for it to distinguish (not an F2P-valid test). Removed it;
  the off path is already F2P-covered by the API tests, which reference `fix_outcomes` and so
  AttributeError on base. Left the "partial-overlap different-anchor" suggestion unaddressed: it is
  not cleanly constructible with SegmentSeekerCrawler rules (replace anchors are whole segments), and
  same-anchor overlap + distinct-source non-overlap are already tested.

  Tests 22 -> 23. Matrix: base/new 23/23 fail / 0 pass-on-base; sol/base 3399/0; sol/new 23/0;
  regression 1146 passed / 0.

## AI-check round 6 (2026-07-15) -- Fairness PASS; coverage + necessary-info

- **Test Fairness: PASS (0 unfair, all tests fair).** The reviewer explicitly praised the robustness
  (no exact summary wording, no order-sensitivity, no pinning which built-in rule loses).

- **Coverage (good-quality WARNING + fairness advisory suggestions).** Added
  `test_fixtx_report_lists_each_skipped_fix_with_its_reason`: dispatches the report via the contract
  method `dispatch_fix_transaction_report` (to a captured `FileOutput`) and asserts every skipped
  outcome's `rule_code` and `reason` appear -- the fairness reviewer's own suggestion #1, using the
  discoverable custom rules (T802) and content (not format) assertions, so it stays fair. Also added
  the two cheap advisory checks: applied outcomes carry `conflict_with is None`, and the report
  `reasons` map is asserted for the `unparsable` and `oscillation` cases. Tests 23 -> 24.

- **Necessary-information request_changes (2 HIGH + 2 MEDIUM + 1 LOW).** Complied with the one item
  that is neither tested nor load-bearing: removed "Within a pass every rule proposes its fixes against
  one snapshot" (para 1 already says the pass is staged as a transaction). Everything else is retained
  because removing it would break a passing check:
  * "including fixes that were themselves sound" (HIGH) -- asserted by the rollback test (the fairness
    reviewer cited this exact clause as the test's grounding).
  * "listing each skipped fix with its reason" (HIGH) -- asserted by the CLI test AND the new per-skip
    listing test.
  * "so fixes to distinct source do not conflict" (MEDIUM) -- asserted by the distinct-sources test.
  * "a summary() method returning a string" (LOW) -- "returning a string" is what makes the
    summary()-returns-str test fair (documented return type); dropping it re-opens the earlier
    Fairness finding.

  BYPASS for the necessary-information request_changes, six elements:
  Check `problem_description_contains_only_necessary_information` asked to delete four described facts
  ("including fixes that were themselves sound", "listing each skipped fix with its reason", "so fixes
  to distinct source do not conflict", "returning a string"); the request is WRONG for these because
  each is load-bearing tested contract -- the rollback test, the CLI + per-skip-listing tests, the
  distinct-sources test, and the summary()-returns-str test respectively assert them, so deleting any
  would manufacture a hidden requirement or re-open the just-passed Test Fairness check. Numbers: 24
  F2P tests (base/new 24 fail / 0 pass-on-base; sol/new 24 pass), Test Fairness PASS with 0 unfair,
  meta.md 259 words within the 200-450 API-heavy band, and the one non-tested mechanics sentence was
  complied with and removed. Dominant pattern: the necessary-information checker flags concrete tested
  API/behaviour as over-specification, the known over-deletion mode, here in direct tension with the
  Test Fairness and Test-Quality checks that require exactly these facts to be documented. Alignment:
  every retained clause is both described and tested, so meta stays minimal AND complete. Conclusion:
  the retained clauses are correct and the request_changes is safely bypassed.

## AI-check round 7 (2026-07-15) -- root-caused the recurring CLI warning + alignment ERROR

The "CLI per-fix listing weakly tested" WARNING kept recurring because I had put the per-fix assertion
in a FORMATTER-level test (calling `dispatch_fix_transaction_report`) instead of the actual
`sqlfluff fix` CLI test. That formatter test ALSO tripped a blocking alignment ERROR: it pinned
`OutputStreamFormatter.dispatch_fix_transaction_report`, a method meta does not (and should not)
document.

One change fixed both:
- Strengthened `test_fixtx_fix_command_prints_the_transaction_report` (the real end-to-end CLI test)
  to assert the per-fix line `skipped (conflict` appears in `sqlfluff fix` output -- verifying "lists
  each skipped fix with its reason" behaviorally, without pinning the incidental loser rule code or any
  formatter method.
- REMOVED the formatter-method test. The formatter/`dispatch_fix_transaction_report` code stays in the
  solution and is now exercised END TO END by the CLI test, so it is not dead and no test pins an
  undocumented internal method. Alignment ERROR gone; coverage WARNING addressed at the CLI level where
  the reviewer wanted it.

LESSON: to satisfy "CLI prints X" coverage, assert it through the CLI command output, never through the
internal formatter method -- the latter both fails alignment (undocumented method) and does not
convince the coverage checker it is the CLI path. Tests 24 -> 23.

## AI-check round 8 (2026-07-15) -- format-brittleness + necessary-info

Everything non-blocking except a bypassable necessary-info request_changes. Addressed all points:

- **Behavior-focus WARNING + alignment WARNING (the CLI substring).** Both flagged `"skipped (conflict"`
  as pinning punctuation/format. Relaxed the CLI test to `"conflict" in output` -- the skip reason is
  surfaced to the user (the behavioral contract) without pinning phrasing. Still fails on base (base
  fix output contains no "applied"/"skipped"/"conflict").
- **Behavior-focus WARNING (exact positions).** Relaxed `positions == [(1,8),(1,15)]` to: both on line
  1, two distinct positive positions. Tests "outcomes carry source position" without magic numbers.
- **Sanity nit: unused `os` import** (left over from the removed formatter test) -- deleted.
- **Necessary-information request_changes.** Complied with the HIGH: removed the concrete class name
  `FixTransactionReport` from meta ("The report has ..."); no test referenced the class name, so it is
  safe. Kept the tested clauses ("so fixes to distinct source do not conflict" -> distinct-sources
  test; "including fixes that were themselves sound" -> rollback test; "returning a string" -> the
  summary()-returns-str assertion).

  BYPASS for the necessary-information request_changes, six elements:
  Check `problem_description_contains_only_necessary_information` asked to delete the report type name
  plus three behavioural clauses; the type name was REMOVED (no test pins it), but the three clauses
  are load-bearing tested contract -- the distinct-sources test, the whole-batch rollback test, and the
  summary()-returns-str assertion respectively require them, so deleting any would manufacture a hidden
  requirement or re-open the previously-failed Test Fairness finding on summary()'s return type.
  Numbers: 23 F2P tests (base/new 23 fail / 0 pass-on-base; sol/new 23 pass), Test Fairness already
  PASS with 0 unfair, meta.md 256 words within the 200-450 API-heavy band, the one HIGH complied with.
  Dominant pattern: the necessary-information checker flags concrete tested behaviour as
  over-specification -- the known over-deletion mode -- in direct tension with the Test-Quality and
  Fairness checks that require these facts documented. Alignment: every retained clause is described
  and tested, so meta stays minimal AND complete. Conclusion: the retained clauses are correct and the
  request_changes is safely bypassed.

## AI-check round 9 (2026-07-15) -- necessary-info: COMPLIED WITH ALL, no bypass

Only the necessary-info check fired (request_changes). Unlike prior rounds, every suggested removal
was safe to make because the tested behaviour still traces to the remaining meta -- so I complied with
all five and did NOT bypass:

- "including fixes that were themselves sound" (HIGH) removed -- "the whole batch is discarded" already
  entails sound fixes are rolled back, so the rollback test stays grounded.
- "listing each skipped fix with its reason" (HIGH) removed -- the report's `reasons` are documented,
  so "prints the report" covers reason-surfacing. This also ENDS the recurring CLI per-fix-format
  whack-a-mole: with no per-fix claim in meta, the CLI test just checks the report's applied/skipped
  counts reach the user (grounded, non-brittle, no rule-code/format pinning). Relaxed the CLI test
  accordingly.
- "and every other rule that wanted the same source is skipped" (MEDIUM) removed -- loser-skip is
  documented via the `FixOutcome` `conflict`/`conflict_with` fields; the losing-fix test stays
  grounded there.
- "so fixes to distinct source do not conflict" (MEDIUM) removed -- it is the contrapositive of
  "conflict when editable source overlaps" (the reviewer agreed); the distinct-sources test stays
  grounded in the overlap definition.
- "the anchor's" (LOW) trimmed.

meta.md 256 -> 222 words. Tests still 23; every test re-checked to still trace to the trimmed meta
(bidirectional alignment preserved). Matrix green (base/new 23/23 fail /0 pass-on-base; sol 3399/0 and
23/0); regression 1145 / 0. No bypass paragraph needed this round.

## AI-check round 10 (2026-07-15) -- Fairness PASS confirmed + last advisory closed

- **Test Fairness: PASS, 0 unfair.** Verified the round-9 changes preserved fairness: dropping
  "conflict" from the CLI assertion and trimming meta clauses are strictly LOOSER, so no test can have
  become less fair. Each test was re-confirmed to still trace to the trimmed meta.
- **Fairness advisory #1 (CLI per-fix detail lines): now MOOT.** It was premised on the meta promising
  "each skipped fix is listed with its reason"; round 9 removed that promise (necessary-info HIGH), so
  there is no per-fix claim left to cover. This closes the long-running CLI-format whack-a-mole at the
  source.
- **Fairness advisory #2 (mixed skipped-reason filtering): added.**
  `test_fixtx_fix_conflicts_returns_only_conflict_skips` runs T801+T802+T803 on one input so that T802
  is conflict-skipped while the T801/T803 batch is unparsable-rolled-back; asserts `fix_conflicts()`
  returns only the conflict skips and is a proper subset of `skipped_fixes()`. Custom rules, grounded
  in the documented `fix_conflicts` = "fixes skipped because another rule took the same source"
  contract, so fair.

  Tests 23 -> 24. Matrix: base/new 24/24 fail / 0 pass-on-base; sol/base 3399/0; sol/new 24/0;
  regression 1146 / 0.

## AI-check round 11 (2026-07-15) -- Test Fairness FAIL + Task Quality FAIL (one root cause)

Two blocking FAILs, both the SAME defect I introduced in round 10: hidden tests coupling to
`FixOutcome` hashability / list identity, which the spec never promises.

- `test_fixtx_convenience_selectors_expose_outcomes`: `fix_conflicts() == skipped_fixes()` pinned exact
  list ordering/identity. Relaxed to `len(...)==len(...)` + "all skips are conflicts" (content).
- `test_fixtx_fix_conflicts_returns_only_conflict_skips`: `set(fix_conflicts()) < set(skipped_fixes())`
  required `FixOutcome` to be hashable. Relaxed to `len(<)` + `all(o in skipped_fixes())` -- `in` uses
  `==`, and since both selectors return the SAME objects out of `fix_outcomes`, it holds even for an
  implementation whose `FixOutcome` defines neither `__hash__` nor `__eq__`.

No hidden test requires `FixOutcome` to be hashable or order-stable anymore, which clears BOTH the Test
Fairness FAIL and Task Quality criterion 4 (Fair) without touching the spec (the reviewer's other
option -- documenting hashability -- would over-constrain the API, so relaxing the tests is the right
call). LESSON: never use `set()`/`==`-on-collections over domain objects whose hashability/equality the
spec doesn't mandate; assert on their fields or serialized form.

Also folded in two advisory-coverage suggestions: an applied-outcome `to_dict()` check, and switched
the multi-file aggregation test to `retain_files=False` so it proves outcomes still aggregate when the
per-file objects are dropped (the CLI fix path). CLI off-path suggestion intentionally NOT added: with
the feature off the CLI equals base behaviour, so such a test passes on base and is not F2P-valid.

## Round 12 (2026-07-15) -- SOLVABILITY TRAP in the CLI test (retain_files), fixed

User surfaced `test_fixtx_fix_command_prints_the_transaction_report` failing with no report in the
`sqlfluff fix` output. Investigation:
- My own solution PASSES this test (confirmed by running the single test against a fresh
  archive + solution.patch in a clean container: "1 passed").
- The failure the user saw is from a different (agent) solution. ROOT CAUSE: the default `sqlfluff
  fix` command lints with `retain_files=False`. My implementation accumulates outcomes in `LintedDir`
  independently of retention, so the report still prints; but an agent that aggregates outcomes by
  iterating retained `LintedFile` objects gets an EMPTY report and fails -- while passing every API
  test. That is a genuine solvability trap (an otherwise-correct solution fails on a non-obvious
  retain_files interaction not spelled out in meta).
- My round-11 `retain_files=False` multi-file test had the SAME trap.

Fix (keeps the feature, removes the trap): the CLI test now runs `fix --check` (with input "y"), which
uses `retain_files=True`, so BOTH a naive over-retained-files aggregation and a robust one print the
report; the multi-file test was reverted to the default (retained) path. Both remain F2P (base has no
fix_transaction, so no report/attributes). Verified `fix --check` prints "7 applied, 1 skipped, ..."
on a fresh file.

LESSON (record in KNOWLEDGE after approval): an end-to-end CLI test that goes through the fix command's
`retain_files=False` path can silently require retention-independent aggregation -- a hidden
requirement that fails reasonable solutions. Either drive it through a `retain_files=True` path
(`fix --check`) or document the retention-independent aggregation explicitly.

## Round 15 (2026-07-16) -- HUMAN reviewer (Neeraj B), Revision Requested (2/3 x3 + upstream)

First HUMAN review. All points addressed:

**Problem Description (P4):** dropped "editable" (a templating-flavored qualifier that could send an
agent toward templated-region handling not in the tested contract) -> "the source positions they touch
overlap". The literal/templated footprint gate stays as an internal robustness detail, undocumented.

**Tests (T4):**
- Added `test_fixtx_result_folds_every_reason_across_files`: three DISTINCT files, each engineered via
  identifier-isolated rules (T807/T810 conflict on file 1; T812 gated-delete -> unparsable on file 2;
  T813/T814 cycle -> oscillation on file 3), proving the run-level aggregators fold ALL reasons
  ({conflict:1, unparsable:1, oscillation:2}), not just conflict.
- Added zeroed/empty-form assertions to the clean/transaction-off test (report applied==skipped==
  total==0, occurred_reasons=={}, conflict_groups()=={}, oscillating_rules()==set()), pinning that path
  explicitly.

**Solution & Code (S2):**
- linter.py fix_transaction import block reordered to isort order-by-type (constants, then classes,
  then functions) via `ruff check --fix`.
- The two 89-char lines (formatters.py comprehension, fix_transaction.py from_outcomes return) fixed by
  `ruff format`.
- Added an explanatory comment above `fix_transaction = False` in default_config.cfg to match the
  file's convention.
- Solution is now RUFF CLEAN (`ruff check` + `ruff format --check` both pass).

**Solution & Code (S4):**
- `FormatterInterface.dispatch_fix_transaction_report` is now `@abstractmethod`, matching every other
  method on that ABC. Verified safe: OutputStreamFormatter is the only subclass and already implements
  it; full regression 1147/0.
- Removed the unjustified `except (AssertionError, ValueError): # pragma: no cover` in
  `StagedFix.footprint`. The method already guards `pos_marker`, and the only existing `get_fix_slices`
  caller (base.py) calls it directly, so the defensive catch didn't match established usage.

Also made the TEST file ruff-clean (repo applies the `D` docstring ruleset to tests too): added
one-line docstrings to every test function.

**upstream_activity (Medium):** VERIFIED the fix is NOT already upstream. `main`'s default_config.cfg
has no `fix_transaction` line and `src/sqlfluff/core/linter/fix_transaction.py` 404s on `main`. The
flagged default_config.cfg overlap is coincidental -- upstream edited that file for the unrelated
`allow_implicit_indents` deprecation coercion (commit 5c951f4), not for a fix-transaction feature.
`fix_transaction` is a novel feature invented for this task; the contributor is not recreating known
work.

Result: tests 24 -> 25; LOC 319 (raw 506); meta 239 words. Matrix base/new 25/25 fail /0 pass-on-base;
sol/base 3399/0; sol/new 25/0; regression 1147 / 0. Solution + test files both ruff-clean.

## Notes

- Docker: `chmod -R a+rwX /app` is REQUIRED or 8 fix/CLI tests fail as non-root.
- Custom test rules must use sqlfluff's code shape (`Rule_T801` -> `T801`); `Rule_FXA01` is not
  resolved by the rules allowlist.
- Disk hit 100% mid-session; a disk-full write silently ZEROED the test file. Source files survived.
  Freed 6GB by pruning unused Docker images (user-approved).
