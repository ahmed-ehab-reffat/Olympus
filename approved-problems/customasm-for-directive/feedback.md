# customasm-for-directive — feedback / attempt log

## Pick rationale (autonomous)
- User deferred repo choice -> standing preference: brand-new repo never used locally + hard feature.
- customasm (hlorenzi/customasm): Rust, Apache-2.0, 1052 stars, active (push 2026-04), NOT in exclusion
  set. Niche assembler for user-defined ISAs = exact-byte oracle, multi-pass fixpoint resolver =
  natural cross-subsystem depth, fast build (~5s).
- Feature: `#for` compile-time repetition directive. Confirmed GENUINELY MISSING (no loop/for/repeat/
  macro directive anywhere in src/std/examples; open issues request iteration-ish features, zero
  implementing PR across all 43 PRs -> exclusivity CLEAN). Fresh feature class (no existing problem
  targets an assembler or macro/loop expansion).

## Design decisions / assumptions (logged per autonomous mode)
- Implementation model mirrors `#if`: an AST-rewrite pre-pass (`resolve_fors`) that evaluates the
  bounds, then splices N deep-cloned+substituted body copies into the top-level node list; the flat
  fixpoint iterator then handles them unchanged. `decls::collect` re-runs each pre-iteration, so spliced
  nodes get their symbols. Chosen because `AstInstruction` stores raw `src` text (not Exprs) and the
  flat iterator makes per-iteration eval-context bindings invasive; splice+Expr-substitution is the
  tractable + faithful path.
- Loop variable resolves via substitution into the body's parsed Exprs (data/#res/#addr/#align/#assert/
  #if/nested-#for bounds). Description scopes the loop var to EXPRESSIONS (no claim about instruction
  operands), so a substitution-only solution and a fuller solution both pass. No test puts the loop var
  in an instruction operand.
- Range is half-open [START, END); START>=END => empty. Bounds deferred like `#if` conditions
  (forward-reference friendly).
- Syntax uses comma `#for i in START, END { }` (no new `..` token) to avoid fighting the member-access
  parser; low-risk, existing tokens only.

## Rejected alternative within customasm
- Full `#for` with loop var usable in instruction operands / per-iteration label auto-scoping: requires
  either token-level instruction-src substitution or threading eval-context bindings through the flat
  fixpoint iterator (customasm anchors name resolution by leading-dot depth, not free upward search) =
  high implementation risk for a one-shot. Scoped to expression contexts instead (documented, fair).

## Scope hardening
- Added an optional STEP (`#for i in START, END, STEP`) as orthogonal depth: distinct stride/direction
  logic + interacting trap (END stays exclusive under a negative step; step 0 errors). Lifts eff LOC and
  difficulty together.

## Local validation (build+F2P+flakiness+Docker) — all GREEN
- Build: baseline 691 tests pass; +solution 691 pass (no regressions). Fast (~2s incremental).
- F2P (clean BASE worktree, both apply orders + reverse-unapply all clean):
  - test.patch only: base 691 pass; new 30/30 FAIL (each a named node).
  - +solution.patch: base 691 pass; new 30/30 PASS.
- Flakiness: new 3x and base 3x identical/deterministic.
- Docker: olympus-base-rust builds; `--network none --user 1000:1000` runs base (691) + new (30),
  valid JUnit XML (691 / 30 testcases). Toolchain supports edition 2024.
- Effective LOC (hook human-effective): 313 across 7 files (2 new + 5 modified) — clears the 2026-07
  floor (>=250 eff, >=2 files). Comment convention: NONE (matches directive_if.rs). meta.md 260 words
  (<500 cap), ASCII, no em-dashes, no banned test markers.

## Fixes during build
- Test sources must be multi-line (customasm requires a linebreak after each directive; single-line
  `{ #d8 i }` -> "expected line break"). Rewrote all sources multi-line.
- F2P leak: `failing_assert_inside_loop_errors` passed on base because the rendered error embeds the
  source excerpt (which contains "#assert"). Changed needle to the message text "assertion failed".
  Also changed `unresolvable_bound_errors` needle "for" -> "bounds" (base "unknown directive `for`"
  contains "for").

## Attempt history
- v1 (design+build): complete, all local gates green. Not yet platform-eval'd (Nova/Orion/Vega run on
  platform). Predicted 15-35% pass (deferral + nested shadowing + negative-step exclusivity are the
  interdependent/misdirecting traps; splice+substitute mirroring `#if` is the solvable core).
- v2 (AI-review response):
  - Tests-coverage WARNING named two edges -> ADDED both (standing rule: always add named coverage
    tests): `outer_variable_bounds_a_nested_loop` (outer var in a nested `#for` bound) and
    `step_from_later_constant_resolves` (step from a later-defined `#const`). Now 32 new tests.
  - Description-quality HIGH (redundant enumeration after "any expression") -> removed it; also dropped
    the redundant "END is excluded either way" clause. KEPT the empty-range and inner-shadow sentences:
    they are the sole documentation of tested traps (removing them risks a hidden-requirement Test
    Fairness FAIL, which outranks an advisory MEDIUM). meta now 238 words.
  - Re-validated: clean-base F2P 32/32 FAIL (test-only) -> 32/32 PASS (+solution); base 691 always green;
    flakiness 2x identical; solution.patch unchanged (still 313 eff, comment-free); meta ASCII/no em-dash.
- v3 (AI-review round 2 response):
  - Coverage WARNING (no step-error tests) -> ADDED `non_integer_step_errors` + `unresolvable_step_errors`
    (step resolves like bounds). Now 34 new tests.
  - Message-coupling WARNING (error tests keyed on my exact wording "nonzero"/"integer"/"bounds"/...) ->
    replaced `expect_error(src, needle)` with `expect_feature_error(src)`, which asserts the input errors
    AND the message is NOT customasm's stable "unknown directive" fallback. This is agnostic to MY error
    wording (a correct impl with different phrasing still passes) yet stays F2P-valid: on base every
    `#for` is an unknown directive, so all error tests still fail on base. Cannot use bare has_errors()
    (would pass on base). All 5 existing + 2 new error tests use it.
  - Re-validated: clean-base F2P 34/34 FAIL -> 34/34 PASS; base 691 green; flakiness 2x identical;
    solution.patch unchanged (313 eff).
- v4 (Test Fairness + description-HIGH response):
  - Test Fairness FAIL (2/32 unfair: `zero_step_errors` pinned "nonzero", `unresolvable_bound_errors`
    pinned "bounds") was STALE -- it evaluated the v2 suite. v3's `expect_feature_error` refactor already
    removed those wording pins (asserts error + not the base "unknown directive" fallback). No further
    action needed on the 2 flags; confirmed current helper is message-agnostic to my wording.
  - Added the 2 remaining advisory coverage suggestions (non-integer STEP already added in v3):
    `outer_binding_restored_after_inner_same_name_loop`, `label_in_single_iteration_body_is_allowed`,
    `label_in_zero_iteration_body_is_allowed` (duplicate-label boundary). Now 37 new tests.
  - Description HIGH (redundant duplicate-symbol sentence): removed it; moved the load-bearing phrase
    "verbatim copy" into the para-1 expansion sentence so the label tests stay fair (verbatim copy +
    the assembler's existing duplicate-symbol rule = the single allowed codebase-inferable requirement).
    Kept the empty-range, "any expression", deferral, and inner-shadow sentences (each is the sole
    documentation of a tested trap; removing them = hidden-requirement Test Fairness FAIL, which outranks
    an advisory MEDIUM). meta now 212 words.
  - Re-validated: clean-base F2P 37/37 FAIL -> 37/37 PASS; base 691 green; flakiness 2x identical;
    solution.patch unchanged (313 eff, comment-free); meta ASCII/no em-dash.
- v5 (Solution Quality FAIL response -- Comprehensiveness 1/3, Code Quality 2/3):
  - Root cause: meta claimed the loop var works "in any expression" but substitution only covered a
    curated set of directive nodes -- instruction operands (raw `src` text), const/fn/ruledef exprs were
    left untouched. Chose to make the implementation GENUINELY general (not narrow the claim):
    * Instruction operands: token-aware substitution of `src` via customasm's own `Walker` (keeps the
      original span so diagnostics still point at the user's line; token-boundary safe -- `ix` != `i`).
    * Added uniform coverage for const value exprs (`AstSymbol`), `#fn` bodies (param-shadow guard), and
      `#ruledef` rule exprs (pattern-param shadow guard). Loop var now reaches EVERY expression-bearing
      node -> "any expression" is now literally true; meta unchanged.
  - Code Quality nits fixed: replaced the `i64` narrowing with `BigInt` throughout (start/end/step/counter
    via `Ord` + `checked_add`), and marked injected literals `.statically_known()` to match `parser.rs`.
  - Added 5 tests for the new capabilities + this round's 2 coverage suggestions:
    `loop_variable_in_instruction_operand`, `loop_variable_in_instruction_respects_token_boundaries`,
    `loop_variable_in_constant_value`, `outer_symbol_visible_again_after_loop` (post-loop scope leak),
    `start_bound_from_later_constant_resolves` (deferred START). Now 42 new tests.
  - Re-validated: clean-base F2P 42/42 FAIL -> 42/42 PASS; base 691 green; both apply orders + reverse
    clean; flakiness 3x identical; Docker offline non-root green (691 + 42, valid JUnit). Effective LOC
    rose to 404 (real distinct logic: instruction tokenizer walk + BigInt + fn/ruledef/const coverage).
    solution.patch comment-free.
- v6 (Solution Quality PASS -> push to 3/3):
  - Verdict was PASS (2/3 + 2/3). Two remaining points, both closed:
    * `DirectiveBankdef` expr fields (addr/size/outp/etc.) were the last uncovered expression-bearing
      node -> added a Bankdef arm substituting all 7 `Option<Expr>` fields (verified: loop var in a
      bankdef `addr` resolves). Substitution is now exhaustive across every expr-bearing AST node.
    * `check_leftover_fors` scanned only top-level -> made it recurse into `#if` arms.
  - Added this round's 3 coverage suggestions as tests: syntax validation (`missing_in_keyword_errors`,
    `missing_body_braces_errors`, `missing_end_bound_errors`, `non_identifier_loop_variable_errors`),
    START-bound failures (`non_integer_start_errors`, `unresolvable_start_errors`), and
    `constant_repeated_in_body_errors` (const in a >1 body duplicate-errors like labels). Now 49 tests.
  - Re-validated: clean-base F2P 49/49 FAIL -> 49/49 PASS; base 691 green; both apply orders + reverse
    clean; flakiness 3x identical; Docker offline non-root green (691 + 49). Effective LOC 427,
    comment-free.
- v7 (3 more advisory coverage suggestions -- test-only, solution unchanged):
  - `too_many_range_expressions_errors` (`#for i in 0,3,1,2` -> "expected `{`"),
    `step_from_later_negative_constant_resolves` (deferred negative step, 5,0,S / S=-2 -> 050301),
    `for_nested_under_if_expands` (#for under #if -> pre-iteration pipeline), and
    `for_from_included_file_expands` (added an `assemble_files` multi-file helper; #for inside an
    #include -> aa000102bb). Now 53 tests.
  - Re-validated: clean-base F2P 53/53 FAIL -> 53/53 PASS; base 691 green; flakiness 3x identical.
- v8 (3 more advisory coverage suggestions -- test-only, solution unchanged):
  - `outer_variable_starts_a_nested_loop` (outer var in inner START) + `outer_variable_steps_a_nested_loop`
    (outer var in inner STEP) -> loop state in more than just the inner END.
  - `deferred_bound_arithmetic_over_later_constants` (`A + 1, B * 2` with A/B defined later -> 010203) ->
    deferred evaluation through expression trees, not just single forward-ref identifiers.
  - `skipped_body_has_no_semantic_effect` (zero-iteration body containing a failing `#assert` and an
    unresolved symbol -> aacc) -> a skipped body is only parsed, never resolved/emitted. Now 57 tests.
  - Re-validated: clean-base F2P 57/57 FAIL -> 57/57 PASS; base 691 green; flakiness 2x identical.
- v9 (2 more advisory coverage suggestions -- test-only, solution unchanged):
  - `explicit_step_of_one_matches_omitted_step` (`0, 3, 1` == omitted -> 000102).
  - `constant_declared_in_body_is_visible_after_loop` (single-iter const x = i*2 -> visible after -> 0e)
    and `label_declared_in_body_is_visible_after_loop` (single-iter label usable after -> ff00) -> body
    declarations behave exactly like ordinary copied source once expanded. Now 60 tests.
  - Re-validated: clean-base F2P 60/60 FAIL -> 60/60 PASS; base 691 green; flakiness 2x identical.
- v10 (2 more advisory coverage suggestions -- test-only, solution unchanged):
  - `descending_range_with_positive_step_emits_nothing` (`5, 0, 1` -> aabb) symmetric to the
    negative-step START<END skip case.
  - `skipped_body_declaration_is_not_visible_after_loop` (const declared only in a zero-iteration body
    -> later `#d8 x` errors) mirrors `#if false` erased-constant behavior. Now 62 tests.
  - Re-validated: clean-base F2P 62/62 FAIL -> 62/62 PASS; base 691 green; flakiness 2x identical (v10).
- v11 (test-quality WARNING: error helper coupled to the "unknown directive" string):
  - Rewrote `expect_feature_error` to be FULLY message-agnostic: it now asserts (a) a canonical valid
    `#for` assembles (positive control proving the directive exists) AND (b) the given input does not
    assemble. No error-message string is inspected. Still F2P-valid: on base the positive control fails
    (directive unknown) so every error test fails; on solution the control assembles and the bad input
    still errors. Solution unchanged.
  - Re-validated: clean-base F2P 62/62 FAIL -> 62/62 PASS; base 691 green; flakiness 2x identical.
- v12 (4 more advisory coverage suggestions -- test-only, solution unchanged):
  - `deferred_zero_step_errors` (STEP from a later `#const` resolving to 0 -> zero-step error),
    `missing_start_bound_errors` and `trailing_comma_without_step_errors` (more malformed headers),
    `skipped_body_still_requires_valid_syntax` (a zero-iteration body with malformed syntax still errors
    -- syntactic validity is required even when semantic effects are suppressed), and
    `nested_same_name_header_uses_outer_binding` (`#for i in i, i+2` inside `#for i` -> inner header
    evaluated in the OUTER scope; the inner binding begins only for the inner body -> 01020203).
    Now 67 tests.
  - Re-validated: clean-base F2P 67/67 FAIL -> 67/67 PASS; base 691 green; flakiness 2x identical.
- v13 (description HIGH + alignment WARNING + 3 more coverage suggestions):
  - Description HIGH: removed "If START >= END, the body is skipped..." -- it is not just redundant, it is
    WRONG for a negative step (START=5 >= END=0 still iterates downward). The step rules already define
    emptiness correctly in both directions. Also trimmed the MEDIUM redundancy ("where NAME is a loop
    variable and START/END are integer expressions" -- integer req is stated later).
  - Alignment WARNING (skipped body must still parse): added a sentence -- "A loop that runs zero times
    emits nothing and evaluates nothing in its body, though the body is still parsed and must be
    syntactically valid." Covers both `skipped_body_has_no_semantic_effect` and
    `skipped_body_still_requires_valid_syntax`. meta now 206 words.
  - Added 6 tests for this round's 3 coverage suggestions: local `.label` in a body (single-iter OK;
    multi-iter duplicates like top-level; global lookup still works after), cyclic bound header
    (`A=B;B=A` -> unresolved, same as deferred `#if`), and header whitespace/comment tolerance. Now 73.
  - Re-validated: clean-base F2P 73/73 FAIL -> 73/73 PASS; base 691 green; flakiness 2x identical.
    solution.patch unchanged (427 eff).
- v14 (2 more advisory coverage suggestions -- test-only, solution unchanged):
  - `all_bounds_and_step_deferred_together` (START/END/STEP all later-defined at once -> 000204) and
    `outer_constant_seen_in_header_but_shadowed_in_body` (`i = 4` then `#for i in i, i+3` -> header reads
    the outer constant 4, body reads the loop var -> 040506; both halves of the shadow rule in one case).
    Now 75 tests.
  - Re-validated: clean-base F2P 75/75 FAIL -> 75/75 PASS; base 691 green; flakiness 2x identical.
- v15 (HARDEN: Nova 10/10 = too easy -> add a coupled sub-feature per HARDENING.md 3c(d)):
  - Root cause: `#for` mirrors the in-repo `#if` splice pattern, so Nova transcribes it (in-repo oracle).
    Trap-stacking on a mirror-feature is futile (doctrine); need a coupled sub-feature with its OWN
    integration path.
  - Added PER-ITERATION LOCAL-LABEL SCOPING (S2/S4 class, CONTRACT-STATED/FIX-HIDDEN): each iteration is
    an independent scope for local (`.`) labels -- a local label may be declared + referenced within an
    iteration and does NOT collide across iterations; a non-local label still collides. Implementation:
    resolve_fors prepends a synthetic non-emitting anonymous global label (`#for_scope_N`, unique via a
    counter threaded from assemble()) before each iteration's body, so `.local` labels declare under a
    fresh parent per iteration while global labels still declare at top-level. `is_reserved_name` allows
    `#`-prefixed synthetic names; `check_unused_defines` only checks CLI -D defines, so no warnings.
  - WHY IT KILLS NAIVE IMPLS (all three approaches Nova might take FAIL the new tests, each with a
    duplicate-symbol error -- the OLD behavior): (a) verbatim splice collides; (b) substitution-only
    collides; (c) naive loop-var-as-symbol binding still does not create per-iteration LABEL scopes.
    The fix is a symbol-hierarchy-subsystem discovery the contract does not reveal. Fair: behavioral
    tests (labels do not collide / are referenceable), not the mechanism; discoverable from customasm's
    local-label hierarchy.
  - Meta: dropped "verbatim copy" (locals are re-scoped, not verbatim); added the per-iteration-scope
    rule (one general principle, Rule-7 compliant, no pitfall spotlight). 253 words.
  - Tests: flipped `local_label_in_body_repeats...` -> `local_label_in_body_is_scoped_per_iteration`
    (now success); added `local_label_referenced_within_its_iteration` and
    `two_local_labels_scoped_per_iteration` (address arithmetic across two per-iter locals). 77 tests.
  - Re-validated: base 691 green (no customasm regression); clean-base F2P 77/77 FAIL -> 77/77 PASS;
    both apply orders + reverse clean; flakiness 3x identical; effective LOC 438; Docker offline
    non-root green (691 + 77, valid JUnit). NOT yet re-batched on Nova -- expect the per-iteration-scope
    wall to drop the rate toward the 1-3/10 target.
- v16 (Solution Quality FAIL: authoritative merged XML had a synthesized missing-node failure):
  - ROOT CAUSE: v15 RENAMED `local_label_in_body_repeats_like_top_level_label` ->
    `local_label_in_body_is_scoped_per_iteration`. The platform reconciles the JUnit node set against the
    PRIOR submission; the removed name became a synthesized failure -> FAIL. This is the F2P-test-names-
    immutable rule ([[olympus-f2p-testname-immutable]]): NEVER rename/delete a test function across
    revisions; change the BODY, keep the name, the set only grows.
  - FIX: restored the exact function name `local_label_in_body_repeats_like_top_level_label` (body now
    asserts the new per-iteration success behavior; the name is historical but the NODE persists).
    Confirmed the node appears in the new-mode XML. Comprehensiveness FAIL was ENTIRELY this missing node.
  - Added this round's 2 coverage suggestions: `loop_variable_not_visible_after_loop` (loop var not
    visible after the loop -> error) and `local_label_does_not_leak_across_iterations` (`.mark` resolves
    to each iteration's own address 1,3,5 -> 000101030205, not a previous iteration's). Now 79 tests.
  - Re-validated: base 691 green; clean-base F2P 79/79 FAIL -> 79/79 PASS; both apply orders + reverse
    clean; flakiness 3x identical; restored node present in JUnit. Solution unchanged (438 eff).
- v17 (alignment WARNING + 2 coverage suggestions -- meta + tests, solution unchanged):
  - Alignment: meta said non-local LABELS collide, but constant tests (`x = ...`) rely on the same
    global-scope rule. Broadened: "A non-local symbol, whether a label or a constant, is declared in the
    global scope, so declaring one in the body collides when the loop runs more than once." meta 266 words.
  - Added `forward_reference_to_local_label_within_iteration` (`.next` referenced before declared, resolves
    to the per-iteration address -> 0102) and `nested_zero_iteration_body_is_not_evaluated` (outer iterates,
    inner 0-iteration body with an unresolved symbol is never evaluated -> 0001). Now 81 tests.
  - Re-validated: base 691 green; clean-base F2P 81/81 FAIL -> 81/81 PASS; flakiness 2x identical.
- v18 (BATCH 1 = 7/10 PASS = 70% too easy -> composition-first re-harden, test-only):
  - Full 10x Nova batch on the 81-test version: 3 FAIL, 7 PASS (see eval-results.md). All 3 fails identical:
    the TEMPTING suffix-rename approach fails per-iteration local-label scope (esp. a local label with no
    preceding global); the 7 passers found the synthetic-scope approach and pass everything. The wall is
    real (30% kill) and FAIR (evals: challenging, description_clear, deterministic, not-unfair).
  - Added +8 scoping-facet discriminators (81 -> 89, test-only, solution+meta UNCHANGED): local CONSTANT
    per iteration; nested loops both using locals; deferred-bound + local; local label composed with the
    loop var; two loops reusing `.loc` (global-uniqueness); deferred 2nd loop reusing `.loc` (uniqueness
    across passes); local label in an INSTRUCTION operand; nested local composed with outer var. Each
    verified on the reference; each fair under the documented per-iteration-scope rule. They catch
    incomplete synthetic impls (label-only / single-level / per-loop-index naming) + kill suffix on more
    axes. Per doctrine: composition-first, zero new meta sentences.
  - Re-validated: base 691 green; clean-base F2P 89/89 FAIL -> 89/89 PASS; flakiness 2x identical.
  - HONEST CEILING: mirror-`#if` features ceiling; behaviors the synthetic approach itself fails are also
    failed by the reference (untestable-fairly). If batch 2 stays >40%, accept a Mars-band ceiling or
    redesign the core.
  - Alignment WARNING (meta-only): the `.c = i*3` test uses a dot-prefixed CONSTANT as per-iteration
    local, but meta said "local labels". Broadened the scope rule to "local symbols, meaning labels or
    constants whose name begins with a dot" (and the global-collision clause already covered both). 271
    words. Tests/solution unchanged; F2P unaffected.
- v19 (SECOND cross-subsystem wall: ADDRESS-DEPENDENT LOOP BOUNDS via an address-fixpoint meta-loop):
  - User: "hardest ever, fair." Scoping-facet stacking ceilings (~40-50%) because the correct synthetic
    approach handles all facets. Added a genuinely NEW cross-subsystem wall the CORRECT solvers also fail.
  - Feature: `#for` bounds/step may reference LABEL ADDRESSES (e.g. `#for i in 0, data_end - data_start`),
    resolved through the assembler's address resolution -- NOT constant-folding. ALL 10 batch agents
    expand in the pre-pass with eval_simple (constant-only), so every one of them FAILS address-dependent
    bounds. Fix is a real re-architecture (meta-fixpoint): expand constant-bound `#for` in the pre-pass
    (base unchanged); for address-dependent `#for`, probe addresses with a throwaway report, expand via
    eval_certain (addresses now in defs), reset item_refs, re-run; converges in ~2 passes for
    pre-loop-dependent bounds; cap 64 -> error on divergence.
  - CONTRACT-STATED/FIX-HIDDEN: meta states one general principle ("bounds may reference label addresses,
    resolved through address resolution"); the meta-fixpoint discovery is hidden. Genuinely cross-subsystem
    (couples to resolve_iteratively). Composes with per-iteration scoping (address-dependent bound + local
    labels tested = double wall).
  - Implementation: resolve_fors gains a use_addresses flag (eval_simple vs eval_certain-on-throwaway);
    added reset_item_refs, count_leftover_fors; assemble() wrapped in the meta-loop (common path
    BYTE-IDENTICAL -> base 691 untouched). Error msg -> "bounds must resolve to integer values".
  - Added 5 hard-tier tests: loop_count_from_label_difference, loop_count_from_single_label_address,
    address_dependent_bound_composes_with_local_labels, address_dependent_bound_with_step,
    address_dependent_start_and_end. Now 94 tests. Effective LOC 438 -> 590 (Good rank).
  - Re-validated: base 691 green + DETERMINISTIC 3x; nes_colors example still assembles; clean-base F2P
    94/94 FAIL -> 94/94 PASS; both apply orders + reverse clean; flakiness 2x identical; patch clean.
  - 0%-RISK NOTE: the meta-fixpoint is a hard architectural discovery; on a Nova-ONLY batch it may hit 0%
    (Nova is shallow; the doctrine says Orion is the decisive deep solver). Batch on the STANDARD mix; if
    0%, ease (shrink the address-dependent test fraction or strengthen the meta hint) -- the reference
    proves it IS solvable.
  - Docker offline non-root green (691 + 94, valid JUnit).
- v20 (description HIGH + Solution Quality PASS->push-3/3, meta + 1 solution line):
  - Description HIGH (redundant inner-shadow clause) removed; "shadows any symbol of the same name within
    the body" covers the nested case. Also applied the MEDIUM trims (step example, address-consequence
    filler, "then START plus one"). meta 303 -> 236 words.
  - Solution Quality Comprehensiveness gap: eval_bound resolves at GLOBAL scope (eval_simple/eval_certain,
    no ResolverContext), so a nested bound depending on a LOCAL label doesn't resolve -- my "any integer
    expression" over-claimed. NARROWED the meta to what the impl actually resolves: "constants and the
    addresses of TOP-LEVEL labels" (all my address-dependent tests use top-level labels). Closes the
    meta<->solution gap without an impl change. KEPT the constants-are-local clarification (prior alignment
    fix) and the forward-const deferral.
  - Code Quality: replaced the hardcoded `meta_index >= 64` with `opts.max_iterations` (existing
    configurable policy, default 10; converges in ~2 passes for pre-loop bounds). The invasive meta-loop +
    synthetic-label scoping are inherent to the hard cross-subsystem feature (reviewer: "not outright
    wrong").
  - Re-validated: full suite 785 (base 691 + 94), no regression; clean-base F2P 94/94 FAIL -> 94/94 PASS;
    both apply orders + reverse clean; flakiness 2x identical. meta 236 words/ASCII. (patch's only
    whitespace warnings are on REMOVED original-code lines; added lines are clean.)
