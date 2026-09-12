# feedback.md — yara-x-regexp-captures

## Summary

- Repo: `VirusTotal/yara-x` (Rust, BSD-3-Clause, 1234 stars, last commit 2026-08-05).
- BASE_COMMIT: `be2a32547d833cb7a0f6545d421c66854f4aad70`.
- Tier: Olympus. Category: feature-request.
- Feature: capture groups in regexp patterns, reported through two new condition accessors
  `@a[i][g]` and `!a[i][g]`.
- Shape: O-Composite-add across the regexp engine (`lib/src/re/`), the scanner match store, the
  rule parser/AST, the IR, WASM emission and the runtime.

## Status

All five deliverables are built and validated. The four-cell matrix is green inside the image,
offline, as uid 1000, in the order the platform uses (image from the vanilla repo, patches applied
at run time): base/base 368 cases 0 failures, base/new 86 of 86 failing, solution/base 368 cases 0
failures, solution/new 86 passing. Both patches apply in either order and reverse-apply cleanly.
Five runs of each mode are identical. A seven-mutation battery is fully killed. What remains is
the platform-side work: the agent batch and the FP check against real passing agents.

## Pick and the gates

Gates run at pick time:

- License: BSD-3-Clause read off the repo LICENSE file, in the allowed list.
- Stars / activity: 1234 stars, commit on the day of the pick.
- Not saturated: absent from `SATURATED-REPOS.md`; VirusTotal/yara-x is a malware-rule engine, not
  the author-obvious clean-VM / SQL-tool / config-lang profile that saturates.
- Repo quota: 1 of our 6 used (`Aprroved/yara-x-aggregate-expressions`).
- Dedup by feature class: the one local yara-x problem is the condition-loop subsystem
  (`for count|sum|min|max|avg`), which touches no file under `lib/src/re/`. No capture-group,
  submatch or Pike VM problem exists in `problems/`, `rejected/` or `Aprroved/`.
- Exclusivity: canonical org resolved (`VirusTotal/yara-x`). PR and issue searches for
  "capture group", "capturing", "backreference", "submatch" and "regexp group" return no hit in
  any state. All five non-default branches (`add-vsix-module`, `deep_scan`,
  `hash-and-crypto-dependencies`, `unpack`, `xintxx-opt`) were diffed against `main`; none touches
  `lib/src/re/`.
- Environment: the sibling approved problem on this repo proves the `olympus-base-rust` Dockerfile
  and the offline suite; re-verified on this base commit.
- F2P architecture: YARA rules are runtime strings, so `test.patch` compiles on base and fails at
  run time. No new Rust symbol is asserted, which also rules out the compile-wipe
  fake-difficulty anti-pattern.

## Repos screened and dropped before this one

The fresh-repo preference was relaxed by the user after every fresh candidate died on a hard gate:

- `rust-lang/chalk` — already screened dead in `SATURATED-REPOS.md` (self-declared deprecated).
  Its design (a constness qualifier threaded through parser, lowering, IR, clause generation,
  coherence and the program printer) was the strongest shape found and is worth re-homing later.
- `brimdata/super` — SuperDB Source Available License.
- `AcademySoftwareFoundation/OpenTimelineIO` — open PR #842 on the exact time-effect kernel.
- `zarr-developers/zarr-python` — chunk grids and sharding are live workstreams (PR #4198).
- `MikePopoloski/slang` — zero LRM gaps; also carries a CC-BY-SA-3.0 doc asset.
- `Hans-Halverson/brimstone` — ES2026-complete apart from SharedArrayBuffer/Atomics.
- `klauspost/compress` — the in-repo decoder is an oracle for the encoder.
- `emersion/go-imap` — CONDSTORE already present; server layer too small.
- `hyperledger-solang` (LLVM dependency), `RazrFalcon/resvg` and `hashicorp/hcl` (MPL),
  `Pyomo/pyomo` and `e2nIEE/pandapower` (NOASSERTION), `errata-ai/vale` and `mvdan/sh`
  (author-obvious / blocklisted), `oxidecomputer/typify` (compile-time macro surface breaks F2P).

## Assumptions logged

- Group numbering follows opening-parenthesis order and `(?:...)` is excluded, matching the
  convention every mainstream regexp engine uses; stated explicitly in `meta.md` so it is not a
  codebase-inferable requirement.
- Alternation resolves leftmost-first, which is the priority order the Pike VM already uses for
  greediness; stated in `meta.md`.
- Captures are recorded for every regexp pattern that has at least one capturing group, rather
  than only when a condition references them. This avoids a pattern-compile-before-condition
  ordering dependency and keeps the contract stateable in one sentence.

## Attempt history

| Round | What changed | Result |
| --- | --- | --- |
| 0 | Pick + 10 gates + `DESIGN.md` | design gate green |
| 0 | Base-suite health on `be2a325` | `cargo test -p yara-x --lib` 326 passed / 0 failed / 13s |
| 1 | Reference implementation complete | `cargo test --workspace` green, 0 failures |
| 2 | Platform pre-checks: 2 spec/test contradictions + 1 formatting + 1 brittle-assertion flag | all four fixed, 4-cell re-validated green |
| 3 | Coverage suggestion: group zero on hex patterns | 2 tests added (88 total), 4-cell re-validated green |
| 4 | Coverage suggestions: accessor-grammar rejection, undefined-length symmetry, named groups with wide/multiple matches | 19 tests added (107 total), second mutation battery, 4-cell re-validated green |
| 5 | Test Fairness FAIL on a match-count assertion | assertion was correct but ambiguous to read; three fixtures made unambiguous, 4-cell re-validated green |
| 6 | Coverage suggestions: duplicate names, dynamic group indexes, mixed ascii/wide encodings | 7 tests added (114 total), third mutation battery, meta gained the duplicate-name rule, 4-cell re-validated green |
| 7 | Coverage suggestions: names across patterns, backtracked captures, malformed name syntax | 12 tests added (126 total), fourth battery, weakest trap strengthened from 1 kill to 4, 4-cell re-validated green |
| 8 | Coverage suggestions: dynamic length group index, named access with a variable match index | 6 tests added (132 total), M13 up from 7 kills to 9, M15 added, 4-cell re-validated green |

## Traps reproduced while building the reference

Each of these bit during implementation, so the difficulty claim is grounded rather than predicted.

1. **Three separate shortcuts swallow the groups.** A pattern only reaches the regexp engine if it
   escapes all of: the exact-atom fast path in the scanner, the `LiteralWithMask` sub-pattern, and
   the alternation-of-literals path. `/a(bc)d/` is a plain literal once the group is ignored, so it
   took the `LiteralWithMask` route and reported nothing, while `/x(ab)+y/` worked from the first
   try. This is trap 4 of the design and it is worse than predicted: there are three shortcuts, not
   one, and each fails silently with the group simply undefined.
2. **The backward run records mirrored positions.** yara-x verifies a match by running the Pike VM
   forward from the atom and backward from it, so a group that encloses the atom has its start
   recorded by one run and its end by the other, in opposite coordinate systems.
   `capture_ranges` is the single place that reconciles them.
3. **Thread dedup decides which alternative's groups survive.** The epsilon closure keeps at most
   one thread per instruction; keeping the last arrival instead of the first silently changes the
   groups while leaving the overall match intact.
4. **`wide` positions are in the de-interleaved view** and have to be doubled before they mean
   anything in the scanned data.
5. **Adding a field to the IR changed every IR hash**, which broke 12 goldenfiles with no visible
   connection to the feature. The hash has to include the group, otherwise `@a[1]` and `@a[1][2]`
   collide in common-subexpression elimination.
6. **Emitting a new VM instruction shifted every bytecode address**, so 19 bytecode goldens in
   `lib/src/re/thompson/tests.rs` had to be regenerated.

## Size

`human-effective` on the 16 non-test source files: **472** (759 raw). Counting the goldenfile and
in-crate test churn the hook reports 1119 over 30 files, but the honest number is the 472.

## Round 2: what the platform pre-checks caught

Two of the four were real contradictions between `meta.md` and the tests, and both were my
description being wrong rather than the tests:

1. **Group zero on a non-regexp pattern.** The description said both accessors are undefined when
   the pattern is not a regexp, but `text_pattern_still_reports_group_zero` expects `@a[1][0]` and
   `!a[1][0]` to work for a text pattern. The implementation is right (group zero is the whole
   match for any pattern kind); the sentence was over-broad. It now scopes the undefined rule to
   groups above zero and says group zero works for every kind of pattern.
2. **The empty-group offset.** The description said a group matching the empty string "has a
   defined offset and length 0", which reads as though the offset is zero too. The tests expect the
   position where the empty match occurred (`@a[1][1] == 1` for `/a(b*)c/` over `ac`). Reworded to
   "a length of zero and the offset at which it matched".

The other two were quality flags rather than contradictions:

3. **Brittle error assertions.** Four tests pinned the compile error text ("unknown capture group",
   once with the name in backticks), which the description never promises. Pinning error strings is
   a known unfair shape, so the assertions were relaxed to "compiling this rule fails". That alone
   would have made them pass on base, where the same rules fail with a syntax error, so each test
   now leads with a positive assertion on the new syntax: the valid name is checked to resolve
   before the unknown one is checked to be rejected. All 86 still fail on base.
4. **Hard-wrapped description.** `meta.md` was wrapped at ~80 characters, which reads as machine
   output. Rewritten as unwrapped paragraphs, 402 words, ASCII, no em dashes.

## Environment footgun found and fixed

The sibling approved problem on this repo ships a Dockerfile that only does
`chmod -R a+rwX /app /opt/cargo`, and records that the image was never actually built. Building it
here fails at run time: `lib/build.rs` copies generated protobuf sources back into
`src/modules/protos/generated/` with `fs::copy`, which also copies permissions, and that is an
EPERM for uid 1000 on a root-owned destination however permissive the mode bits are. The scan
aborts with `PermissionDenied` and the base suite silently drops to 42 cases instead of 368.
Adding `chown -R 1000:1000 /app /opt/cargo` before the chmod fixes it. Worth carrying back to
`Aprroved/yara-x-aggregate-expressions/Dockerfile`, which has the same latent problem.

## Test-suite shape

183 tests in `lib/tests/captures_dec915.rs`, all through the public `yara_x` API with the rule as a
runtime string, so the file compiles on base and every test fails there. Buckets: numbering and
nesting 12, non-capturing groups 3, patterns without groups 6 (text and hex, including group zero on both), undefined cases 8, alternation 5,
repetition 6, atom-relative verification 8, `wide` 5, `nocase` and `fullword` 4, empty groups and
classes 6, multiple matches 5, use in expressions 3, named groups 8, unknown-name errors 4,
baseline preservation 6.

## Remaining work

1. Agent batch (Nova/Orion), then the FP check against every passing agent.
2. Capture passing-agent diffs into `agent-runs/` at batch time.

## FP audit

The platform FP check runs against passing agents, and no batch has run yet, so this is the
pre-batch version of it: every sentence of `meta.md` mapped to a discriminator, every test mapped
back to a sentence, and each discriminator proven by breaking the reference on purpose rather than
by inspection.

| Described rule | Discriminator | Proven by |
| --- | --- | --- |
| groups numbered by opening parenthesis, nesting included | `nesting_and_sibling_numbering`, `three_levels_of_nesting` | M7 (numbering off by one) kills 64 |
| `(?:...)` takes no number | `non_capturing_group_takes_no_number`, `non_capturing_group_is_not_reported` | covered by M7 |
| group zero is the whole match for every pattern kind | `group_zero_agrees_with_plain_accessors`, `text_pattern_still_reports_group_zero`, `hex_pattern_still_reports_group_zero` | M9 kills 15 |
| undefined above zero: out of range, non-regexp, took no part | 22 `not defined` assertions across both accessors | M8 kills 11, M9 kills 15 |
| alternation resolves leftmost first | `alternation_prefers_leftmost` | M3 kills 1 |
| repetition reports the last iteration | `repeated_group_reports_last_iteration` and 4 more | M6/M7 |
| empty group: length zero, offset where it matched | `empty_group_has_an_offset`, `empty_group_at_the_end` | M9 |
| absolute offsets, `wide` counts the zero bytes | `wide_group_length_counts_zero_bytes` and 5 more | M2 kills 3 |
| every regexp with a group reports its groups whatever its shape | `group_before_a_long_atom`, `group_enclosing_the_atom`, plain-literal patterns | M4 kills 34, M5 kills 40, M1 kills 7 |
| a name resolves to its own group | `named_group_agrees_with_its_number` and 12 more | M10 kills 3 |
| an undefined name is a compile-time error | 4 `rejects` tests, each with a positive half | — |
| accessors are written after the match index | `a_name_needs_an_explicit_match_index`, `a_third_index_is_rejected` | M11 kills 2 |

Nothing in `meta.md` is unasserted, and no test asserts behaviour `meta.md` does not state. The two
fixed-point risks for this feature are an implementation that reports the whole match for every
group and one that reports zero for a group that took no part; both are killed (M9, M8).

Remaining FP risk is the part only a batch can settle: whether a passing agent satisfied the tests
while breaking something the tests do not reach. The base suite runs the full `yara-x` lib and
`yara-x-parser` lib in base mode, which is where a rerouting of the existing accessors would show
up.

## Process note

The mutation harness left a stale build. It backed files up with `shutil.copy` and restored with
`shutil.move`, so the restored file carried the backup's older mtime and cargo did not rebuild:
the local test binary still contained the grammar mutant, and two tests failed locally while a
fresh container build passed. The source was byte-identical to `solution.patch` throughout. Any
future mutation script must touch the restored file, or verify against a clean build before
trusting a local result.

## Round 5: the Test Fairness FAIL

The checker flagged `named_group_of_each_of_several_matches` for asserting `#a == 3` on
`/(?P<g>a+)x/` over `axzaax`, saying there are only two matches, `ax` at 0 and `aax` at 3.

The assertion was correct. `a+x` can also start at the second `a`, so there is a third match `ax`
at offset 4, and yara-x keeps it because it dedups matches by starting offset, not by overlap.
Probed directly on the patched tree: `#a == 3` with offsets 0, 3 and 4.

The test was changed anyway. A hidden test whose expected value takes a careful reading to confirm
is a liability whether or not the value is right, and a human reviewer can misread it exactly as
the checker did. The count assertion now runs on `axzax`, where the two matches at 0 and 3 are the
only ones possible. Two neighbouring tests carried the same ambiguity without being flagged and
were changed too: both length-per-match tests now use `/(a|bb)x/` over `axzbbx`, which gives
exactly two matches with group lengths 1 and 2 and no nested start. `axzaax` survives only in
`group_inside_a_for_loop_over_match_indexes`, whose assertion holds for every match and pins no
count.

Coverage is unchanged: per-match capture storage, varying group lengths across matches and named
access per match index are all still asserted, on fixtures that read unambiguously.

## Round 6: what the three coverage suggestions turned up

All three named behaviours were already well defined, so each became a test rather than a change
to the reference:

- **Duplicate names.** `regex-syntax` rejects `(?P<x>a)(?P<x>b)` and yara-x surfaces that as
  `error[E014]: invalid regular expression`. The test asserts only that compiling fails. Because
  the prompt promised nothing about duplicates, `meta.md` gained one clause saying a name cannot
  be given to two groups of one pattern, so the test is prompt-stated rather than inherited.
- **Dynamic group indexes.** A group number is an ordinary integer expression, exactly as the
  match index already is, so a loop variable, an arithmetic expression and a runtime out-of-range
  value all work. Out of range is undefined, which is the rule the prompt already states. Four
  tests, including a loop that walks group numbers past the end.
- **Mixed encodings.** For an `ascii wide` pattern over data holding both forms, the two matches
  keep their own coordinates: the ascii capture is offset 1 length 2, the wide one offset 8
  length 4. This is the sharpest test in the suite for the wide conversion being per match rather
  than global, which mutation M12 confirms: applying the doubling to every match kills 59 tests.

The mutation harness was also fixed. It now copies the backup back and calls `os.utime`, so the
restored file gets a current mtime and cargo rebuilds; the stale-binary problem from round 4
cannot recur. Verified by a clean 114 of 114 run immediately after the battery.

## Round 7: the backtracking suggestion paid off indirectly

- **Names across patterns.** The same name in two patterns resolves independently, which the
  prompt already implies by limiting uniqueness to groups "of one pattern". The sharper test uses
  `x` as group 1 of `$a` and group 2 of `$b` and checks each name equals its own pattern's number.
  A name belonging to another pattern is still a compile error.
- **Backtracked captures.** Four tests: an alternation branch that captures `ab` in full and then
  fails on the next byte, and a repetition that captures and then unwinds to zero iterations, each
  paired with the case where that path does succeed. All four hold.
- **Malformed names.** An empty name and a name with a space are rejected as invalid regexps.
  Asserted as compile failures only, with a positive half so they still fail on base.

The backtracking tests did not kill what I expected. An abandoned thread dies without ever
reaching the same instruction as the winner, so dedup order is irrelevant to them: they are killed
by M14 (slots shared instead of copied per thread), which is the isolation they genuinely verify.
That left M3, the dedup-priority trap, still at a single kill. Three more tests force two branches
to reach the same instruction at the same position with different captures, `/(a)|a/`,
`/(a)|(a)/` and `/(a)b|(ab)/`, and M3 now kills 4. The suggestion was worth taking for the trap it
exposed as under-tested rather than for the one it named.

## Round 8

Both suggestions were symmetry gaps rather than new behaviour, and both closed cleanly.

- **Dynamic group index on lengths.** The offset side already had a runtime out-of-range case and
  a loop-variable case; `!a[i][expr]` had neither. Three tests now mirror it, including
  `for all i in (1..2) : ( !a[1][i] == i )` over `/(a)(bb)/`, which pins each group's length to
  its own number. The out-of-range mutation M13 went from 7 kills to 9.
- **Named access with a variable match index.** Name resolution happens at compile time against
  the pattern the accessor names, so a loop variable in the match index was expected to work, but
  nothing asserted it. Three tests walk `@a[i]["g"]` and `!a[i]["g"]` over both matches and check
  each equals the numeric form. A new mutation, M15, resolves a name against the rule's first
  pattern instead of the accessor's own pattern; it kills 2 tests, both from round 7's
  cross-pattern group.

## Round 9: the Nova batch came back at ~100 percent

The pick is too easy and the fix is not more tests. See `eval-results.md` for the root cause; the
short version is that the module being extended links to the article that describes the exact
implementation, capture groups are recallable in every detail, and each designed trap surfaces as
a wrong number in the solver's own smoke test rather than staying hidden.

The two levers the playbook offers for a too-easy batch are both unavailable here:

- **Rule-7 de-enumeration of the meta** is blocked. 132 tests pin every stated rule and Test
  Fairness verified the mapping, so removing a rule from the description makes its tests unfair.
  The contract is already at the fairness floor.
- **More traps on the same axis** is the futility case (`PATTERNS-ADVANCED` Pattern 17): the
  variants all funnel through one decision, "thread capture slots through the VM", and an agent
  that makes it clears every one of them.

What is left is an independent axis whose implementation is not recallable and not in the linked
article. The candidate is backreferences.

### Why backreferences

- The Pike VM article covers submatches and explicitly does not cover backreferences, because a
  backreference is not a regular construct. There is no recipe to transcribe.
- It breaks the NFA model. A thread must compare input against a span it captured earlier, which
  means per-thread progress state through a variable number of bytes, on top of the slots.
- It composes viciously with the atom split. A backreference in the head can refer to a group
  captured in the tail, and the two runs are independent, so the solver has to make a real design
  decision rather than follow a rule.
- It forces atom-extraction changes: a backreference contributes no literal bytes, and treating it
  as one silently breaks matching.
- It interacts with `wide` and `nocase`, where the comparison is not byte equality.

### Feasibility, checked rather than assumed

`regex-syntax` rejects `\1` and `\k<name>` outright: both come back as
`error[E014]: invalid regular expression`. That is not a blocker. `re::parser::Parser::parse`
already runs a rewrite-and-retry loop over the regexp source for constructs `regex-syntax` will
not take, adjusting spans as it goes, so a backreference can follow the same route: pre-scan,
substitute a placeholder, re-parse, then rebuild the node in the HIR.

### Cost

This is a redesign, not a tweak: placeholder scheme and span handling in the parser, a new HIR
node, a VM instruction that consumes a variable number of bytes with per-thread progress, the
backward-direction decision, atom exclusion, `wide` and `nocase` comparison, then a new test
bucket and a full revalidation pass. A dedicated session.

### The alternative

If the backreference axis is judged too large, the protocol is to shelve: record the pick in
`Instructions/TOO-EASY.md` under the recallable-capability death class, `git mv` this folder to
`rejected/`, and keep the two findings that transfer, namely the yara-x Dockerfile ownership fix
and the note that a repo whose own module documentation links to the implementation article should
be screened out at pick time.

## Round 10: hardened against the real batch, plus two coverage suggestions

The batch artifacts made this round evidence-driven rather than speculative. Full detail of the
architectures, the probe families and the per-run kills is in `eval-results.md`; the outcome is
that twenty tests built from measured divergences take the batch from 9 of 10 passing to 4 of 10,
which is 40 percent, at the cap.

The last two coverage suggestions were answered but changed nothing about difficulty:

- **Unicode mode.** `(?u)` with a non-ASCII literal works and reports byte coordinates, which is
  what the suggestion asked to pin: `/(?u)(e-acute)/` over `xe-acute` gives offset 1 and length 2.
  Three tests cover it, including group zero.
- **Capture-name boundaries.** `a_1`, `_x` and `x9` are all accepted and resolve; a name starting
  with a digit is rejected. Four tests. A Unicode name such as `e-acute` is also accepted by the
  parser, which is recorded here but not pinned, since nothing in the description promises it.

### A pre-existing yara-x bug found while probing

`(?u)` combined with a class or a dot panics the regexp compiler:
`/(?u)./` aborts at `lib/src/re/thompson/compiler.rs` inside `visit_post_alternation`. This
reproduces on the **untouched base commit** with no capture group anywhere in the pattern, so it is
an upstream limitation and not a regression from this work. No test goes near it; unicode coverage
is restricted to literals, which are sound. Worth reporting upstream, and worth remembering as a
reason to probe a repo's exotic modes before writing tests that depend on them.

### Where the difficulty now stands

Nova 2, 3, 4 and 9 built the real Pike VM machinery and are correct on all 159 tests plus 77
further probes: assertion times wide times nocase times fullword compositions, anchors, bounded
jumps, nested groups spanning the atom, non-greedy quantifiers, serialization round-trips, scanner
reuse across scans, block scanning, cross-rule pattern dedup, unicode literals and name syntax.
Test-only hardening is exhausted at 40 percent. Going lower needs the second axis, and the batch
sharpened what that axis has to be: something the correct VM implementation does not already give
for free, which is why backreferences remain the candidate.

## Round 11: two interface rules stated, and an ambiguity caught while stating them

The alignment check flagged two things the tests pin that `meta.md` did not state, and both were
real gaps rather than test overreach, so the description now states them:

- **Capture-name syntax.** A name cannot be empty, cannot contain a space and cannot begin with a
  digit. Worded as those three constraints rather than as a full grammar, because the parser also
  accepts Unicode identifiers and no test pins that; claiming an exhaustive character set would
  have been inaccurate in the other direction.
- **What a group index may be.** Either a number or a quoted name.

Writing the second sentence surfaced a genuine ambiguity. The first draft said the number "is
never negative ... anything else is an error at compile time", which reads as though a negative
index is always rejected. It is not. Probing both forms:

| Form | Behaviour |
| --- | --- |
| `@a[1][-1]`, a constant | compile error |
| `@a[1][#a - 5]`, negative only while scanning | compiles, accessor is undefined |

The constant is rejected by the compile-time range check on the index expression; a value that
only goes negative at scan time falls through to the runtime conversion and comes back undefined,
exactly like any other out-of-range number. The description now says so explicitly, and three
tests pin the runtime case, which nothing covered before. That was a live false-positive hole: an
implementation that raised an error, or returned zero, for a scan-time negative would have passed
the whole suite.

## Round 12: lazy repetition and the short naming syntax

Eleven tests, 173 in total. All three suggestions named real gaps in coverage, none of them
changed the pass rate: the four surviving runs from the batch are correct on every one.

- **Lazy repetition.** The description says a group inside a repetition reports the iteration that
  matched last, and says nothing about greediness, so lazy forms are covered by the same sentence.
  Five tests: `+?`, a bounded `{2,3}?`, a lazy group body, a lazy repetition after a long atom, and
  one that runs zero times and is therefore undefined.
- **Unknown name in a length on a regexp.** The offset form and the text-pattern length form were
  both covered, this exact combination was not.
- **The short naming syntax.** `(?<name>...)` was only exercised on the success path. Duplicate,
  digit-initial, empty and space-containing names are now rejected through it as well, matching
  the `(?P<name>...)` cases one for one.

One judgement call while writing these. `/(a)*?b/` over `aab` reports the group at offset 0, which
I could not derive from the description with confidence, so no test pins it. Every lazy case that
did go in is anchored by surrounding literals, where the expected span is unambiguous. Pinning a
value I cannot explain is how an unfair test gets written.

## Round 13: numbering hygiene and scanner reuse

Ten tests, 183 in total. Again none of them move the pass rate; the four surviving runs are
correct on all of them.

- **Negative literal selector on lengths.** `!a[1][-1]` is rejected at compile time, mirroring the
  offset test that already existed.
- **Escaped and class parentheses.** `\(`, `\)` and a parenthesis inside a character class are
  literal bytes and take no group number. Six tests confirm the numbering does not shift, including
  a case where an escaped parenthesis sits before a long atom so the backward run has to cross it.
- **Scanner reuse.** Four tests reuse one `Scanner` across two buffers, through a new `scan_twice`
  helper. The sharpest is the optional group: the first buffer makes it participate and the second
  does not, so a scanner that kept the earlier capture would report a stale offset instead of
  undefined. This was probed back in round 9 and every agent was correct, but it had never been
  written as a test, so nothing guarded it.

The pattern over rounds 10 to 13 is worth recording. Thirteen advisory suggestions produced two
genuine false-positive holes (undefined lengths, and a group index that only turns negative at scan
time), one upstream panic in yara-x's unicode mode, and a lot of coverage that no agent gets wrong.
None of them changed difficulty. That is the expected shape once a suite is already aligned with
its description: coverage work makes a problem fairer and harder to pass by accident, but it does
not make a recallable capability harder to implement.
