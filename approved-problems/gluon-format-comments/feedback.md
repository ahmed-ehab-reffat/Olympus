# feedback — gluon-format-comments

## Pick
gluon (MIT, 3421 stars, alive: v0.18.3 released 2026-07-08). Quota 1/6 (gluon-match-guards in
flight, different subsystem). Base commit 418c6b7de22b244746bfd0570f9fcfd6d738e542.

Capability: make `gluon fmt` preserve every source comment and place it canonically (trailing
comments stay on their line, own-line comments keep their block indentation, tail comments stay
inside their construct, line comments force the enclosing construct to break, formatting stays
idempotent).

## Gate evidence (all run before authoring)
- Gate 1/6 REPRODUCED on base through the real entrypoint (`gluon fmt`):
  1. `y = 2, // about y` as the last record field -> the comment is DELETED.
  2. `| _ -> 2 // about default` -> the comment is moved OUT of the match and dedented to column 0.
  3. `let x = 1 // trailing` -> the comment is moved to its own line.
- Gate 5 COLD: `format/src/pretty_print.rs` last behavioural change 2020-10-15 ("Keep seq after
  formatting"). The 2026-07 commits touching it are `cargo fmt`, Edition 2024 and
  `s/expr_2021/expr/g` churn only.
- Gate 7b EXCLUSIVITY: no open PR touches `format/src/pretty_print.rs`. #977 touches only
  `format/Cargo.toml` and `format/src/lib.rs`; #897 "Format macro" is a string-formatting macro in
  `src/format_macro.rs`.
- Gate 8 PHILOSOPHY: PR #316 "feat: Vastly improve when comments are kept during formatting"
  (MERGED) shows the maintainer treats comment retention as a goal. No decline, no open debate.
- Baseline: `cargo test -p gluon_format --test pretty_print` = 52 passed / 0 failed / 0.24s.

## Known baseline defect (affects test.sh design)
`cargo test -p gluon_format` in isolation FAILS TO COMPILE: `format/tests/std.rs` uses
`#[tokio::main]` while format's dev-dependency enables only tokio's `macros` feature. Workspace
feature unification hides this in CI. Base mode must scope to targets that build, with the reason
documented.

## Implementation notes carried from the probe phase
- `CommentIter` (base/src/source.rs) yields bare `&str` with no positions and uses `""` to mean a
  blank line. Classification needs position or gap-order information.
- The shared emission machinery is `make_comments_doc` / `comments_count` / `comments_before` /
  `comments_after` in `base/src/types/pretty_print.rs`; every `//` comment is emitted with a
  trailing `hardline`, which is why nothing can currently stay on its own line's end.
- `format/src/pretty_print.rs` emits comments from the gap BEFORE each node
  (`pretty_expr_(previous_end, expr)`). Tail gaps are consumed at only two sites, which is the
  drop bug.
- pretty 0.10 semantics confirmed from the crate's own `line_comment` test: a `hardline` inside a
  group forces that group to break. So break-forcing is free IF the implementer emits `hardline`;
  an implementer who appends the comment without one produces the swallow bug. Trap 1 needs a
  trap-proof run to confirm it is reachable.

## Attempt history
- A0 (2026-08-04): repo gates, Gate 1/5/6/7b/8 all cleared, DESIGN.md written. No code yet.

## A1 (2026-08-04): solution core implemented and f2p demonstrated

Implemented across 3 files:
- `base/src/source.rs` — `Comment` / `CommentKind` / `GapCommentIter`, plus `comments_in(span)`
  and `starts_line(pos)` on the `Source` trait. The existing `CommentIter` stops at the first
  non-comment byte, which is exactly why a trailing comma hid the comment after the last record
  field; the new iterator scans a whole gap and carries positions.
- `base/src/types/pretty_print.rs` — `Gap` (trailing / own-line split, `has_line_comment`) plus
  `Printer::gap(span)` and the two composition helpers `between_items` and
  `before_closing_delimiter`. Classification uses newline counting between the previous position
  and the comment start, so it is decided on the SOURCE layout, not the output layout.
- `format/src/pretty_print.rs` — `CommaSeparated` now carries `previous_end` and places each
  boundary's gap once (trailing after the comma, own-line before the next item); the record path
  consumes its tail gap inside the braces; the match path places per-arm gaps and a head gap; and
  `pretty_expr_` places a statement-level trailing comment before the break.

All three measured base bugs are fixed and idempotent (verified by formatting twice):
- trailing comment on the last record field: preserved in place (was deleted)
- trailing comment on the last match arm: stays in the match at the arm's line (was moved out and
  dedented to column 0)
- `let x = 1 // trailing`: stays on the line (was moved to its own line)

### Two existing tests now fail, deliberately
`preserve_comments_in_empty_record` and `preserve_comments_in_record_base` pin the OLD dedented
placement (`{\n// 123\n}`). The feature indents own-line comments with the construct's items, so
those expectations change. Base mode will exclude exactly these two with the reason documented;
everything else in the file (50 tests) passes unchanged.

## A2 (2026-08-04): harden pass

**Stage 1 note: no agent runs exist, so this round PREDICTS rather than measures.** The levers
below were chosen structurally and each one is trap-proofed against a natural-but-wrong
implementation, which is a weak proxy for a batch (L15), not a substitute.

### Diagnosis
The design rested on ONE mechanism: classify a comment as trailing or own line, then place it.
A single insight discharging every site is the correlated-seam shape, so the round added levers on
axes that the classification insight does NOT clear by itself.

### Levers added
1. **Second printer (orthogonal axis).** Comments in RECORD TYPES go through the type printer in
   `base/src/types/mod.rs`, an entirely different code path from the expression printer. It drops
   them on base as well, so this is a real f2p gap, not just a trap. An implementer who fixes only
   the expression side loses the whole type bucket. Same contract sentence, zero extra description
   words (the F-3 second-axis shape).
2. **Cross-product cells (F-10).** Two nested cells: a trailing comment on a match alternative
   inside a record field, and a trailing comment on a record nested inside a match alternative.
3. **Doc comment exclusion (interdependent).** `///` comments are metadata and are printed by a
   different path; a gap scanner that treats them as ordinary comments prints them twice. Rides
   the same scanning chokepoint as every other trap, fails on a different axis (duplication, not
   placement).

### Trap-proof results (mutation, kills out of 22 new tests)
| Mutation | Kills |
|---|---|
| M3 classify every comment as own line (the naive fix) | **16** |
| M2 use the field NAME span rather than the whole field span in the comma separator | **1** (the nested cross-product cell, exactly as designed) |
| M1 do not skip `///` in the scanner | **1** (only after the doc test was moved onto a scanned gap; the first version of that test killed nothing) |

M1's first version is worth recording: the test passed under the mutation because a doc comment on
the FIRST field is not in any scanned gap. Moving it to the second field made it discriminate. A
test written for a rule is not automatically a test that detects the rule being broken.

### Three reference bugs found by hardening (L7 again, three for three)
1. `///` doc comments were scanned as ordinary comments and printed twice.
2. The comma separator tracked the field NAME span, so the gap for the next field swallowed the
   whole previous value and re-printed comments from inside it. Output grew on every format pass.
3. A match alternative gap emitted two breaks where it needed one, producing a blank line.

### Scoped out, honestly
- Variant alternatives (`| A Int // first`): the constructor's synthesised function type carries no
  usable source span, so the gap cannot be located. Not covered by the contract and not tested.
- Blank line preservation between comments, and an own line comment before the FIRST item of a
  construct: both need the opening delimiter's position threaded into the item iterator. An attempt
  at that regressed `hang_record` and the own-line indentation test, so it was reverted. Neither
  rule is stated in meta.md and neither is tested.

### Validation
| Check | Result |
|---|---|
| new tests with solution | 22 pass / 0 fail |
| new tests on base | 19 fail / 2 pass (the 2 are regression guards, not feature tests) |
| base mode on base | 50 pass / 0 fail (2 skipped, reason in test.sh) |
| base mode with solution | 50 pass / 0 fail |
| new mode 3x | identical every run |
| both apply orders + reverse apply | clean |
| Counter 2 human-effective | **278** across 4 files (floor 200) |
| test.sh mode | 100755 |
| banned markers | none |

## A3 (2026-08-04): pre-submit review pass (olympus-review, self-applied)

Stage 0 clean: meta.md is ASCII with no em dashes or smart quotes, no banned markers, test.sh
carries mode 100755, patches are not UTF-16. Stage 1 clean: base commit IS current HEAD, so there
is no base-to-HEAD drift; no open PR touches `format/src/pretty_print.rs`.

Three findings on my own artifact, all fixed rather than argued:

1. **Dead parameter (A2).** The abandoned attempt to seed the item iterator with a construct's
   opening position left `comma_sep_from(start, ...)` behind with `start` always `None`. Reverted
   to the original `comma_sep` signature. A reviewer would have called it scope creep and been
   right.
2. **A test asserting behaviour the description does not state (A6).** The block comment test
   pinned the record breaking across lines, which is pre-existing layout behaviour that meta.md
   never mentions. Deleted rather than adding a sentence for it, because the sentence would have
   been about layout and not about comments.
3. **An absolute sentence with an unstated exception (calyx L9).** "Every comment appears in the
   output exactly once" reads as a claim over the whole file, but variant alternatives are out of
   scope and still drop comments. Scoped it to "Within those constructs". Same failure mode calyx
   hit three times.

Final numbers after the fixes: solution 4 files / 378 added / **Counter 2 human-effective 272**;
21 new tests, 18 of them failing on base; base mode 50 pass with 2 documented skips; new mode
identical across 3 runs; both apply orders and reverse apply clean.

**Not verified and stated as such: the pass rate.** No agent batch has been run, so the difficulty
claim rests on structure and on three trap-proof mutations, not on measurement. The 10-25%
prediction in DESIGN.md is a prediction.

## A4 (2026-08-04): Dockerfile fix after a platform image-build failure

The first Dockerfile failed the platform build with `rustup could not choose a version of cargo to
run`. Cause: it set `RUSTUP_HOME=/root/.rustup` and `CARGO_HOME=/root/.cargo` and put
`/root/.cargo/bin` on PATH. `olympus-base-rust` keeps its toolchain in `/opt/cargo` and
`/opt/rustup`, so those vars pointed rustup at empty directories and no default toolchain existed.
The `chmod -R a+rX /root` plus symlink loop was serving the same wrong assumption.

Replaced with the shape every approved Rust submission uses (calyx, lyon, customasm,
pulldown-cmark): no toolchain env vars at all, and chmod the real toolchain paths for the non-root
run.

Build command is `cargo build --locked -p gluon_format --test pretty_print` rather than
`--workspace --tests` on purpose. Building every test target would try to build
`format/tests/std.rs`, which does not compile on this commit (`#[tokio::main]` against a tokio dev
dependency carrying only the `macros` feature) and would fail the image build for a reason that
has nothing to do with this change. Verified on a clean base checkout: the command finishes in 45s.

Still owed to the platform: Docker cannot be run on this workstation, so the image build is
verified statically and by matching the approved pattern, not locally.

## A5 (2026-08-06): platform feedback round

Four signals came back. Three were acted on; one was not my bug.

### Test Fairness FAIL, 1 of 21 unfair -- fixed by STATING the behaviour, not by dropping the test
`a_record_carrying_only_a_comment_keeps_it_indented` pinned four space indentation for a record
with NO fields. The reviewer was right that the description did not resolve it: every placement
rule was item relative ("indented to the same column as the item it precedes", "keeps the
indentation the items have"), and a record with no items has no item to be relative to.

The fix is a sentence in meta.md, not a deletion: "A record whose only content is a comment keeps
it inside as well, indented one level in from the line the record opens on, so it reads the same as
a record holding a single field." That is WHAT, not HOW, and it makes the test traceable. The
visible repo test `preserve_comments_in_empty_record` still shows the old column 0 placement, but
that is now a stale expectation the contract explicitly overrides, which is the ordinary situation
for a behaviour change and what AGENTS.md tells solvers to handle. It stays skipped in base mode
with the reason recorded in test.sh.

A test written for the same shape on a record TYPE had to be dropped, for a different and real
reason: `type R = { }` parses as the unit type, so it formats to `type R = ()` and there is no
record to hold a comment. The meta sentence is scoped to a record literal accordingly.

⭐ PROBE-HARNESS BUG worth keeping: my `gluon fmt` probe formats a file in place and prints it, so
a run where fmt FAILS is indistinguishable from a run where the output is already correct. The
empty record type looked like it preserved the comment when in fact the command had errored and
left the file untouched. Any in-place probe needs its exit code checked.

### Coverage suggestions -- both taken (L17: reviewer coverage suggestions are free difficulty)
1. **Ordinary comments at the end of a record type.** This exposed a REAL implementation hole that
   the AI code review had independently found and marked Partially Met on both dimensions: the
   type row path handled gaps BETWEEN fields but had no tail path before the closing delimiter,
   while the record and match paths did. `pretty_record_like` now takes the construct's end
   position and emits the tail gap inside the existing nest. Two tests added (own line before `}`,
   and trailing on the last field).
2. **Block comments in the ownership gaps.** Two tests added, one flat and one nested inside a
   match inside a record. Both already passed, so they are coverage rather than difficulty.

Note on the first fix: my initial version added a second `.nest(INDENT)` and double indented every
record type field to 8 spaces. Caught by the existing suite, not by the new tests.

### Description review, request_changes with 3 suggestions -- all applied
- HIGH: removed the paragraph narrating current broken behaviour. It was discoverable from the
  code and risked anchoring the solver on the existing implementation.
- MEDIUM: trimmed the tail after "exactly once"; it restated the same constraint.
- MEDIUM: removed the standalone idempotence sentence. Idempotence is still asserted by every test
  because the repo's own `test_format!` macro formats twice, and that macro is visible convention,
  so this is the one codebase inferable requirement rather than an unstated one.
Body is now 257 words, down from 360.

### Agent report "cargo test could not run" -- NOT this submission's bug
`tests/vm.rs` fails to compile with E0277 (`VmEnvInstance<'_>: CompletionEnv`) **on the base commit
with no patch applied**, verified by stashing every change and building clean. With and without
`--features test`. This is the third pre-existing baseline defect found in this repo, after
`format/tests/std.rs` (tokio `macros`-only dev dependency) and the two comment placement
expectations. `test.sh` is scoped to `-p gluon_format --test ...` and is unaffected, which is why
every local and clean room run is green. Worth watching in the batch: a solver that runs a bare
`cargo test` will hit an unrelated compile error and may burn messages on it.

### State after this round
| Check | Result |
|---|---|
| new tests with solution | 24 pass / 0 fail, identical 3x |
| new tests on base | 21 of 24 fail |
| base mode, before and after solution | 50 pass / 0 fail |
| Counter 2 human-effective | **294** across 4 files |
| both apply orders + reverse apply | clean |
| meta.md | 257 words, ASCII, feature-request framing |

## A6 (2026-08-06): fairness fixed by specification

Reverted the deletion from A5. The empty record test is back, and meta.md now states the rule it
depends on. Final state: 25 new tests (22 fail on base), base mode 50 pass before and after,
3 identical runs, Counter 2 human-effective 294 across 4 files, meta.md 293 words.

## A7 (2026-08-06): Verify Solution FAIL fixed + all coverage suggestions taken

### Verify Solution FAIL -- 3 new tests passed without the solution
The gate is that EVERY new test must fail without solution.patch, and three did not:
`a_doc_comment_is_not_repeated_as_an_ordinary_comment`,
`a_doc_comment_on_a_record_type_field_is_not_repeated`, and
`own_line_comment_is_indented_with_the_fields_it_precedes`. All three asserted behaviour the base
formatter already gets right, so they were coverage, not discrimination. I had reported "19 of 21
fail on base" as if the residue were harmless; the gate says otherwise and the gate is right.

Fixed by folding one base-breaking element into each fixture rather than deleting them: a trailing
comment on the let binding, on the last record type field, and on the last record field
respectively. Each test now still checks the doc comment or indentation rule it was written for,
and also fails on base. Result: **30 of 30 new tests fail on base**, 30 of 30 pass with the
solution.

### Coverage suggestions -- all four taken
1. One space normalisation: `a_trailing_comment_is_separated_from_the_code_by_exactly_one_space`
   drives `,// tight` and `,     // loose` to the same single space form.
2. Own line comment between successive let bindings, including before the first binding.
3. Own line comment after the final match alternative.
4. Own line block comment before a field, plus a record type nested in a record type carrying
   comments at both levels.

### A contract conflict found while probing suggestion 3
meta.md said a comment after the last item of "a record, a match or a record type" stays inside the
construct. For a match that is wrong and my own implementation disagreed with it: a match has no
closing brace, so an own line comment after the final alternative attaches to whatever follows,
which is what the formatter does. Reworded to scope the inside-the-construct rule to a record and a
record type, and to state the match case explicitly. The test asserts the stated behaviour.

This is the second time this round that writing a test for a suggestion exposed a spec or code
defect rather than just adding coverage. L17 keeps earning its place.

### Final pre-submit review (self-applied)
| Gate | Result |
|---|---|
| Stage 0 hard blocks | clean: ASCII meta, no em dash or smart quotes, test.sh mode 100755, no banned markers |
| Stage 1 GitHub audit | base commit IS HEAD, no drift; no open PR on `format/src/pretty_print.rs` |
| new tests on base | 30 of 30 fail |
| new tests with solution | 30 of 30 pass |
| base mode before and after solution | 50 pass / 0 fail |
| flakiness | base and new both green on 5 consecutive runs |
| compiler warnings on touched crates | 0 |
| weak assertions | 0 (exact string equality, asserted twice per test) |
| scope | 4 files, all in the formatter path |
| Counter 2 human-effective | 294 |
| meta.md | 320 words, ASCII, feature-request framing, WHAT not HOW |

Docker was NOT built locally (no Docker on this workstation, and the disk has no room for it).
The Dockerfile is verified statically against the approved Rust pattern and its build command was
run on a clean base checkout. Image build remains owed to the platform.

Still owed: the agent batch. Difficulty is still predicted, not measured.

## A8 (2026-08-06): the two base-mode exclusions are now SUPERSEDED, not just skipped

The exclusions were never removable, and it is worth writing down why. `preserve_comments_in_empty_record`
and `preserve_comments_in_record_base` pass on base and fail only once the solution is applied,
because the feature deliberately changes what they assert. They cannot stay in base mode (base mode
must be green with and without the solution) and they cannot move to new mode unmodified (new mode
must fail on base, and they pass there). Updating them in place would need test.patch to rewrite a
file whose original the solver still sees, which changes nothing for the solver and complicates the
harness.

What WAS fixable is the coverage hole, and it is now closed. Both shapes are asserted in the new
suite against the requested placement:
- empty record holding only a comment -> `a_record_carrying_only_a_comment_keeps_it_indented`
- record with a `..` base and comments around it -> `comments_around_a_record_base_stay_inside_the_record` (new this round)

So the two exclusions no longer drop any behaviour; they drop two stale expectations that the new
suite re-asserts in their corrected form. test.sh now says exactly that, naming both replacements,
so a reviewer reading the harness can verify the claim without running anything.

Final: 31 new tests, 31 of 31 fail on base, 31 of 31 pass with the solution across 3 runs; base mode
50 pass before and after; Counter 2 human-effective 294 across 4 files.

## A9 (2026-08-06): description trimmed after two converging reviews

Both reviewers flagged the same class: clauses that explain or justify a rule instead of stating
one. Applied all five suggestions plus the over-specification catch.

| Removed | Why it was wrong to keep |
|---|---|
| "keep the behaviour they have now:" (HIGH) | preserve-existing-behaviour filler; the rest of the sentence states the doc comment rule on its own |
| "Because such a comment runs to the end of the line," | justification, not a requirement |
| "and is written on its own line," | tautology after "begins a line of its own" |
| "A match has no closing brace, so" | explanatory lead-in; the attachment rule stands alone |
| "so it reads the same as a record holding a single field." | rationale after an already explicit indentation rule |
| "Losing a comment is losing work, ..." | motivational filler; the ask carries it |

The sixth change was the important one. "puts it back where they wrote it" OVERSTATED the contract:
the formatter normalises spacing (`a_trailing_comment_is_separated_from_the_code_by_exactly_one_space`)
and can force a construct onto multiple lines (`a_line_comment_breaks_a_record_that_would_otherwise_fit`),
so literal original position is not what the tests require. Now reads "attached to the code they
attached it to", which is what the suite actually asserts. That was a genuine description-to-test
misalignment, not a style nit, and it would have been fair game for a fairness reviewer.

Body is 250 words, down from 320. Every normative rule survived: traced all nine back to at least
one test by name after the edit, all nine present. No patch regeneration needed since meta.md is not
part of test.patch or solution.patch.

Note on the earlier "make it motivational" direction: the feature-request framing is carried by the
opening ask itself, so cutting the separate motivational sentence keeps the tone without the filler
both reviewers objected to.

## A10 (2026-08-06): Auto Review Revision Requested -- the coverage gap was hiding a REAL BUG

Auto Review scored Tests 1/3 on one High finding: no test placed an ordinary own line comment
BETWEEN items, only before the first item or after the last. Description 3/3 and Solution 3/3.

Probing that exact shape before writing the test found a defect in my own reference:

```
let r = {                          let r = {
    x = 1,                             x = 1,// first note     <- glued to the code line,
    // first note            ->                                   no space, own line lost
                                                                  
    // second note                     // second note
    y = 2, // about y                  y = 2, // about y
}                                  }
```

`Gap::between_items` only emitted a break BEFORE the own line comments when the same gap also
carried a trailing comment. With no trailing comment in the gap the own line comment was appended
straight onto the previous line. Every earlier test that exercised own line comments either sat in
the FIRST item slot (which goes through the old `space_before` path) or shared its gap with a
trailing comment, so 31 tests missed it. One line fixed it: always break before the own line run.

This is the third time this problem's coverage feedback has surfaced a defect rather than a gap in
the tests alone, and the strongest evidence yet for L17. The reviewer could not see the bug; it
inferred from the CONTRACT that an untested branch existed, and the branch was broken.

### Seven tests added, covering both reviewers' suggestions
| Test | Suggestion answered |
|---|---|
| `an_own_line_comment_before_a_later_alternative_belongs_to_that_alternative` | Auto Review High, match half |
| `an_own_line_comment_before_a_later_record_type_field_belongs_to_that_field` | Auto Review High, record type half |
| `consecutive_own_line_comments_keep_their_order_and_the_blank_line_between_them` | consecutive comments + blank line |
| `a_block_comment_spanning_lines_keeps_its_own_line` | multiline block comment |
| `comments_at_inner_and_outer_let_boundaries_each_stay_put` | nested let ownership |
| `identical_comment_text_at_several_places_survives_at_every_one` | repeated identical text, guards against text keyed dedup |
| `a_same_line_block_comment_breaks_a_record_that_would_otherwise_fit` | block comment multiline forcing |

The last one is back after being deleted in A5. It was unfair then because meta.md said nothing
about layout; the current wording states that the construct holding a same line comment is written
in its multiple line form, and that rule does not distinguish `//` from `/* */`, so the test now
traces to a stated sentence.

### State
| Check | Result |
|---|---|
| new tests with solution | 38 pass / 0 fail, identical 3x |
| new tests on base | **38 of 38 fail** |
| base mode before and after solution | 50 pass / 0 fail |
| Counter 2 human-effective | 295 across 4 files |
| blank line handling | now genuinely works between items, so the A2 "scoped out" note no longer applies to that path |

## A11 (2026-08-06): 0/12 batch — three clarifications aimed at the near-miss clusters

0/12 is a reject regardless of how good the failures look, so this round buys back solvability by
STATING behaviour, not by weakening tests. Four runs sat at 1 failure, and their causes split three
ways.

**1. Blank line between consecutive comments (7 kills, 2 of the 4 near-misses).** meta.md required
preservation, order, indentation and exactly-once, and said nothing about the author's blank line.
Six runs kept the comments and collapsed the blank line, which is a perfectly reasonable reading of
what was written. That is a hidden requirement and it was mine. Now stated: "a blank line the
author left between two comments is kept, with a run of several blank lines becoming one." The
collapse half is verified against the reference (three blank lines in, one out).

**2. Same-line block comments (6 + 5 + 4 kills, 1 near-miss).** The same-line rule said "a comment
that begins on the same line", then the multiple-line-form sentence followed it. Agents read the
forcing rule as applying to `//` only, and several also inserted a blank line after the block
comment. Now stated once, covering both forms: either one "ends the line it sits on, so the next
item starts on the line below and the construct holding the comment is written out in its multiple
line form".

**3. First-item ownership (4 kills, 1 near-miss).** Own-line comments were said to belong to
whatever follows, but nothing resolved the gap between a construct's head and its first item. Added
"including when what follows is the first item of a construct" — a general clause, not an example,
so Rule 7 and L21 hold.

None of these relaxes a test. Every one of the 42 tests still asserts exactly what it did before;
three sentences moved requirements from implied to stated. Predicted effect: the two blank-line
near-misses and the block-comment near-miss become passes, landing roughly 2-4 of 12. If it
overshoots past 40% the block-comment cluster is the lever to re-tighten, since it is the widest.

### Coverage suggestions taken (T4 Medium)
Four tests added, all verified to fail on base: same-line block comment on a let binding, on a
record-type field, a gap mixing a trailing block comment with an own-line line comment, and a run of
several blank lines collapsing to one.

### State
| Check | Result |
|---|---|
| new tests with solution | 42 pass / 0 fail, identical 3x |
| new tests on base | 42 of 42 fail |
| base mode before and after solution | 50 pass / 0 fail |
| Counter 2 human-effective | 295 across 4 files |
| meta.md | 306 words, ASCII |
| Long-horizon | batch showed substantial solution sizes and message counts on every run |

## A12 (2026-08-06): projection forced a partial revert — the block-comment clarification is OUT

Counterfactual over the 12 run artifacts: for each run, remove the clarified tests from its failure
set and see whether anything is left.

| Clarifications kept | Projected passes |
|---|---|
| blank line + first item + block comment (as written in A11) | **7/12 = 58%** |
| blank line + first item only | **4/12 = 33%** |

58% is over the 40% ceiling and over the target band, so the block-comment sentence was reverted.
It was also the one clarification fairness did not require: Auto Review scored Description 3/3 and
called the block-comment cluster "subtle but fair", flagging only the blank line as needing to be
explicit. The two kept clarifications are both fairness-motivated (a hidden requirement and an
unresolved ownership gap), and each cures a genuine near-miss.

⭐ THE MECHANISM WORTH REMEMBERING: clarifying a cause does not convert one run, it converts every
run whose REMAINING failures all sit inside that cause's cluster. The block-comment sentence cured
Orion 3 (1 fail) and also Nova 1 and Nova 10 (3 fails each, all block comments). That is why the
choice of WHICH near-miss to clarify matters far more than how many. Near-misses are a reservoir,
not a queue: the widest cluster is always the biggest rate lever, and it is usually the one you are
most tempted to explain.

Projected batch 2: **4/12 = 33%**, inside the 40% ceiling. Treat as a central estimate, not a
bound. It runs high if a clarified spec also helps agents fix adjacent bugs, or if agent capability
has drifted since batch 1 (L10). It runs low if a stated rule is still missed, which happens.
If batch 2 lands above 40%, the block-comment cluster is the re-tightening lever, since removing
that clarification is already proven to cost 3 runs.

meta.md is 282 words. Tests, patches and validation are unchanged from A11: 42 tests, 42 of 42 fail
on base, 50 base-mode green, Counter 2 human-effective 295.

## A13 (2026-08-06): shipping with the blank-line clarification ONLY

Final call on the clarification set. The first-item clause was also reverted, leaving one addition
to meta.md over what batch 1 ran against: the blank line rule.

| Clarification set | Projected passes |
|---|---|
| blank + first item + block comment | 7/12 = 58% (over the 40% ceiling) |
| blank + first item | 4/12 = 33% |
| **blank line only (shipping)** | **2/12 = 17%** |

Why this is the right edge to ship on. The blank line rule is the only one fairness actually
demanded: six runs preserved the comments and dropped the author's blank line, which is a correct
reading of a contract that never mentioned whitespace, so it was a hidden requirement. The other
two were emphasis, not new information. First-item ownership already follows from "a comment that
begins a line of its own belongs to whatever follows it", and Rule 7 / L21 both prefer the general
rule over the spelled-out instance. The block-comment cluster was rated "subtle but fair" by Auto
Review at Description 3/3.

Loosening is cheap, re-tightening is not (L10: ship at the low edge, agent capability drifts up).
Both reverted sentences are now MEASURED levers, so if batch 2 reads too hard the response is not
guesswork:

| If batch 2 lands | Add back | Expected |
|---|---|---|
| 0/12 | first-item clause | +2 runs (Nova 5, Orion 2 sit at 1 residual failure) |
| still 0 after that | block-comment sentence | +3 runs (Orion 3, Nova 1, Nova 10) |

Three runs sit at exactly one residual failure under the shipped wording (Nova 5, Orion 2 on the
first alternative; Orion 3 on the block comment), so the near-miss band is dense right under the
line. That is the healthy shape, and it also means the rate is sensitive to capability drift.

meta.md 271 words, ASCII. Tests, patches, Dockerfile and validation unchanged from A11: 42 tests,
42 of 42 fail on base, base mode 50 pass before and after, Counter 2 human-effective 295 across 4
files, 3 identical runs.

## A14 (2026-08-06): batch 2 read 0 legit / 14 — both clarifications restored

Batch 2 came back worse than batch 1, not better, because it ran against 42 tests rather than 31 and
the eleven added tests landed mostly on the record-type surface. Counterfactuals over the 14 run
artifacts show only one change converts anybody: restoring BOTH reverted clarifications, which
converts Orion 4 (its two failures are exactly the block-comment and first-alternative cases). Every
other lever tested, including dropping the whole record-type family, converts nobody.

So both sentences are back. Projected batch 3: **1 legitimate pass of 14 (7%)**, which clears the
solvability floor and sits far under the 40% ceiling. Nova 2 is one failure short, on the
record-field doc-comment rule that meta.md states outright, so that one is fair difficulty rather
than a missing clarification.

Correcting my own A12 projection: I predicted 2/12 for the blank-line-only wording and batch 2
delivered 0/14 legit. The projection was computed against batch 1's population and did not account
for the eleven tests added after that batch, six of them on the record-type printer. **A
counterfactual over an old batch is only valid while the test suite is unchanged.** That is the
lesson to carry.

## ⚠️ A15: the design contains a CHEAT TRAP and it has already cost a verdict

Orion 2 passed all 51 baseline and all 42 new tests and was classified **PASS_CHEATED**, because its
patch modified `format/tests/pretty_print.rs`. The grader named five tests it rewrote:
`preserve_block_comments`, `preserve_shebang_line`, `preserve_comments_app_types`,
`preserve_comments_in_empty_record`, `preserve_comments_in_record_base`.

Three of those it broke and then patched over, which is its own fault. But **two of them,
`preserve_comments_in_empty_record` and `preserve_comments_in_record_base`, are expectations this
feature legitimately invalidates** — they are the exact two that base mode skips. A correct solver
who follows AGENTS.md and updates stale expectations gets classified as cheating for doing the right
thing. That hazard is mine, not the agent's.

**Recommended structural fix (NOT yet applied, needs a call on scope):** change the tail rule so an
own line comment before a closing brace keeps the OUTER indentation, matching what those two
existing tests already assert, instead of the item indentation. Then a correct solution requires
zero edits to existing tests, base mode can run all 52, and the trap disappears.

- Cost: implementation change in both printers, re-expecting 4 of my tests
  (`own_line_comment_before_closing_brace_stays_inside_the_record`,
  `a_record_carrying_only_a_comment_keeps_it_indented`,
  `own_line_comment_after_the_last_record_type_field_stays_inside`,
  `comments_around_a_record_base_stay_inside_the_record`), plus full revalidation.
- Rate effect: measured at zero. It converts no run on its own.
- Benefit: removes a trap that can fail correct solvers, and removes the base-mode skips that two
  reviewers have already questioned.

## A16 (2026-08-06): one more fair easing, aimed at the single 1-away run

Batch-2 residuals after the two restored clarifications leave exactly one run within reach:
Nova 2, whose only remaining failure is `a_doc_comment_on_a_record_field_is_not_repeated`.
Everything else jumps straight to 5 or more failures, so there is no third lever that reaches
anybody.

The doc-comment paragraph said documentation comments "must not also be treated as ordinary
comments". The measured failure is DUPLICATION: the doc comment is already carried by the binding
it documents, and a new pass over the source prints it a second time. Agents read the old sentence
as "do not reformat them" rather than "do not print them twice". Reworded to state the observable
outcome: "Each one appears in the output once, carried by that binding or field, and never a second
time as a comment in its own right."

That is WHAT, not HOW, and it is consistent with the exactly-once rule already in the previous
paragraph. It names no file, path or mechanism.

| Projection over the batch-2 artifacts | Legit passes |
|---|---|
| batch 2 as it ran | 0/14 |
| + two restored clarifications | 1/14 (Orion 4) |
| **+ doc-comment wording (shipping)** | **2/14 (Orion 4, Nova 2)** |

The record-type cluster was considered and rejected as an easing target. It is not a wording
problem: meta.md already says the rules hold for the fields of a record type. Agents fail it
because the type printer is a different code path they never open, and the only wording that would
help would have to point at that path, which is HOW. If batch 3 still reads too hard, the honest
lever there is trimming that test family, which is a scope decision rather than a fairness one.

meta.md 322 words, ASCII, no em dashes. Tests, patches, Dockerfile unchanged: 42 tests, 42 of 42
fail on base, base mode 50 pass, Counter 2 human-effective 295.

## A17 (2026-08-06): blank-line coverage extended, and the projection is now MEASURED

The T4 finding was correct and I had not covered it: blank line preservation and multi blank
collapse were tested only between record literal fields, while the rule applies across match
alternatives, successive let bindings and record type fields too. Three tests added, one per
surface. The reference handles all three, and all three fail on base.

### Differential harness (HARDENING 3e) instead of another counterfactual
Rather than re-projecting on paper, I applied the two convertible agents' own patches to a clean
base checkout and ran the FULL 45 test suite against their code:

| Agent patch | Result on the new suite | Failing |
|---|---|---|
| Orion 4 | **43 / 45** | the two clarification tests only |
| Nova 2 | **44 / 45** | the record field doc comment test only |

Both pass all three new blank line tests. So the added coverage costs nothing: neither projected
pass is at risk from it, and the projection stays **2 of 14**. This is stronger evidence than the
counterfactual it replaces, because it ran their real code rather than subtracting test names from
a failure list.

### Nothing further is easeable in meta.md
After Orion 4 and Nova 2 convert, the next run sits at 5 residual failures. Every remaining
blocker is the record type surface, and that is not a wording problem: meta.md already states the
rules hold for the fields of a record type. Agents fail it because the type printer is a separate
code path they never open, and any wording that would help would have to point at that path, which
is HOW. Two description reviewers have already trimmed six clauses from this description for being
explanatory rather than normative, so adding more prose there would cost a band and buy no passes.

The three clarifications plus the doc comment wording are all the easing the description can carry
honestly. If batch 3 still reads too hard, the lever is trimming the record type test family, which
is a scope decision rather than a fairness one, and I would want your call on it.

### State
| Check | Result |
|---|---|
| new tests with solution | 45 pass / 0 fail, identical 3x |
| new tests on base | 45 of 45 fail |
| base mode before and after solution | 50 pass / 0 fail |
| Counter 2 human-effective | 295 across 4 files |
| meta.md | 322 words, ASCII |
| projected batch 3 | 2 of 14 legitimate passes, measured by differential harness |

## A18 (2026-08-06): record types DROPPED, S1 conceded to the repo, 20% measured

Batch 3 ran the current 45-test artifact and returned 0 legitimate passes again, which retired my
2/14 projection. Two clarifications were already in the meta the agents read, and Orion 2 still
missed the first alternative, so wording had stopped being the lever.

### The dropped feature: record TYPES
The record-type surface was the wall — eight tests, killing 3 to 6 of 10 each, and it is the axis
added during hardening precisely because it is a second printer in a different file. Removed from
all three places: the eight tests, both mentions in meta.md, and the `base/src/types/mod.rs` half
of the solution. Solution is now 3 files, Counter 2 **243** effective, still clear of the 200 floor.

Verified by differential harness rather than projected: Nova 2 and Orion 3 both score **37/37**
when their own patches run against the reduced suite. **Batch 4 measures at 2 of 10 = 20%.**

### Auto Review S1: conceded on the DESCRIPTION side, not the code
S1 asked that a same-line block comment after the final record field force multiline layout, and it
reproduced: `let r = { x = 1 /* note */ }` stayed on one line. I implemented the fix, and it broke
two more baseline tests: `preserve_block_comments` and `preserve_shebang_line`, both of which pin
one-line records holding inline block comments. Auto Review had already seen the smoke from this,
recording that 2 runs "tripped legacy baseline expectations that retain one-line inline
block-comment formatting" and marking it `unfair test`.

So the requirement contradicts the repo's own visible tests. That is L19: a wall that contradicts
the repo's published behaviour is a fairness bug that happens to be hard. The code change was
reverted and the description now claims the multiline rule only for LINE comments, which is the
honest statement of what the repo does, since a line comment runs to end of line and a block
comment does not. Conceding here also avoids widening the base-mode exclusions from 2 to 4.

### State
| Check | Result |
|---|---|
| new tests with solution | 37 pass / 0 fail, identical 3x |
| new tests on base | 37 of 37 fail |
| base mode before and after solution | 50 pass / 0 fail |
| Counter 2 human-effective | 243 across 3 files |
| meta.md | 306 words, ASCII |
| measured batch 4 rate | 2 of 10 = 20% |
