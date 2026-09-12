# feedback.md — customasm-ruledef-disassembly

Repo: hlorenzi/customasm | BASE_COMMIT c66cb389e7af95ad612520d4766bcb09adfea948
Tier: Olympus | Shape: O-Algorithm-correctness

## Status

DESIGN complete. No code yet. Build order is deliberate: `analyze.rs` first, then BUILD-MEASURE
before writing anything else. This is the direct correction of the previous pick, which was fully
built before its LOC was measured.

## Gate status

| Gate | Status |
|---|---|
| Repo stars / license / activity | PASS — 1052, Apache-2.0, 34 commits/12mo |
| Saturation + quota | PASS — customasm not blocked; 0 prior submissions from us |
| Exclusivity (Gate 7b) | PASS — zero PRs on disassemble/disassembler/decode/reverse, ALL states |
| Maintainer philosophy | PASS, and better than neutral — issue #30 hlorenzi: "This would be incredibly cool... Maybe only for a subset of instructions with simple representations?" That endorses the exact invertible-subset scoping this design uses. Also "not really a priority" = cold. |
| Gate 1 behavioral-f2p-gap | PASS — capability absent entirely |
| Gate 5 cold-not-live | PASS — 0 commits in trailing 90d |
| Death-class guard | PASS on all 5 |
| ORACLE-ABSORPTION test (new) | PASS — 4 of 6 line items have no sibling implementation |
| Baseline determinism | PASS — inherited, 691 tests deterministic across 3 runs |
| **LOC** | **ESTIMATED 327, NOT MEASURED.** Hard checkpoint after analyze.rs. |

## Why this pick and not the alternatives

- **Linking / object files (#48):** rejected. Maintainer is still gathering requirements
  ("I think I'd need more input from you guys"), so the behavior is undefined (Gate 8), and
  ELF/COFF are textbook formats (saturated-reference risk).
- **Floating point (#233/#180/#92):** rejected. IEEE-754 is the canonical saturated-reference port.
- **Disassembly (#30):** chosen. Genuinely absent, maintainer-welcomed, cold, and the thing being
  inverted is customasm's own arbitrary-expression rule model rather than a published ISA, which is
  what keeps it non-derivative.

## Build outcome — SHIPPABLE

All deliverables built and validated. Every gate green.

| Metric | Floor | Measured |
|---|---|---|
| Effective LOC (Counter 2) | >= 200 | **367** |
| Files modified | >= 2 | **5** (3 new) |
| Pass ceiling | <= 40% | projected 15-30%, batch is the oracle |
| Base regressions | 0 | 691/691 pass, before and after |
| f2p sharpness | new must fail on base | **14/14 fail on base**, 14/14 pass with solution |
| Flakiness (3x base + 3x new) | deterministic | byte-identical JUnit XML |
| Both apply orders + reverse | clean | clean |

Counter 1 = 546.

## The LOC checkpoint that made this pick work

The design predicted 327 meaningful; `analyze.rs` alone measured **144 against a 90 estimate** at
the first checkpoint. That is the opposite of the previous pick, and for a traceable reason: the
ORACLE-ABSORPTION test run at pick time found four line items with no sibling implementation in
the repo, so none of the work got absorbed. The checkpoint was the go/no-go, and it said go.

## Dead code found and removed at review

The compiler could not flag these because the items were `pub`:

- `RuleDecoding::is_fixed_width()` and `RuleDecoding::constant_prefix_width()` — zero callers.
- `RuleDecoding.width` field — computed in `analyze_rule` and never read (variable-width handling
  actually lives on `DecodingTerm::Parameter.width`). Removing it also deleted ~25 lines of
  width-accumulation logic.
- `analyze_rule` was exported twice but only ever called inside `analyze.rs`; made private.

Cost about 6 effective LOC and was the right trade. A2 is the second-most-flagged reviewer pattern
and a `pub` item never warns.

## FP pre-check (light-bulb, both directions)

No agent batch has run, so this is the pre-batch alignment check, not the post-batch FP check.

Every meta sentence maps to at least one fixture, and every fixture maps back to a sentence. One
gap was found and closed: the claim "a constant only pins down bits when its own width is known"
had no discriminating test. Added `ok_unsized_constant_not_decodable`, where a decimal-constant
rule and a hex-constant rule would produce identical bytes; if a solver sizes decimal literals via
`min_size()`, the decimal rule becomes decodable, ties, and the ambiguity error fires the test.
That is a sharp discriminator for meta claim 4 and for trap 1.

Also found during the build: the design promised "a genuine tie is reported rather than guessed"
and the implementation silently kept the first candidate. Implemented ambiguity detection rather
than weakening the description, and added `err_ambiguous_decoding`.

## Traps, as built

- **Trap 1 (term width is not syntactic)** — grounded in real repo behavior: `0x10` carries
  `size = Some(8)` from `excerpt_as_bigint` while decimal `16` carries `None`. Fixtures:
  `ok_unsized_constant_not_decodable`, `ok_wide_field`.
- **Trap 2 (parent width depends on which child decoded)** — live and demonstrated:
  `ok_variable_width_subruledef` has `op short` at 8 bits and `op long` at 16, from the same rule.
- **Trap 3 (wrong candidate desynchronizes the stream)** — `ok_most_constant_bits_wins` has `nop`
  (0xa0, 8 constant bits) beating `mov 0x0` (4 constant bits) on the same byte.

All three surfaced during the build against my own reference, which is the trap-reproduction
evidence HARDENING 3a.4 asks for.

## Pre-submit verification (2026-07-30)

**SIX-CHECK re-run immediately before submit — CLEAN on all six.**

1-2. Literal + namespace PR search on the canonical org (`hlorenzi/customasm`, no redirect):
     0 PRs for disasm / disassemble / disassembler / decode / "reverse mapping", all states.
3.   Maintainer philosophy: issue #30 stays OPEN and FAVORABLE.
4.   Closed-with-implemented scan surfaced **issue #50 "Feature Request: Disassembly", CLOSED**.
     Read in full before proceeding: closed 2020-10-14 by the REPORTER with the single comment
     "Whoops. duplicate of #30". Not a maintainer decline, not an implementation. GitHub labels the
     state reason COMPLETED, which is misleading; the comment is decisive. This is exactly the check
     that killed dasel-slice-operator, so it was read rather than counted.
5.   Base..origin/HEAD: **0 commits**. The base commit IS current HEAD; last real commit 2026-04-13.
6.   Existing-capability: the feature is absent on base (14/14 new fixtures fail there).

**Docker build-verified (not just written).**

The Dockerfile initially FAILED to build. The Pattern A template in CLAUDE.md overrides
CARGO_HOME/RUSTUP_HOME to `/root/...`, but `olympus-base-rust` installs the toolchain at
`/opt/cargo` + `/opt/rustup`; the override makes rustup lose its default toolchain. Corrected
Dockerfile verified end to end:

- image builds clean
- `docker run --rm --network none --user 1000:1000` runs BOTH test.sh modes
- base: 691 cases / 0 failures; new: 14 cases / 0 failures; JUnit XML valid in both

The corrected template and the root cause are recorded in `Instructions/DOCKER.md` so the next Rust
pick does not inherit the broken snippet. Note the chmod must be `a+rwX` over `/opt/cargo`,
`/opt/rustup` and `/app` because the platform runs non-root and cargo writes both the registry cache
and `target/`.

## What remains

Only the platform batch, which is user-triggered. Everything author-side is done and verified.

## Precheck round 1 — all failures fixed (2026-07-30)

Two FAILs and three WARNINGs came back. Two of the findings were genuine defects in my artifacts,
not checker noise.

**FAIL 1 — predictable test names. FIXED.** My random hex sat only on the top directory
(`tests/disasm_123a9c/`); every leaf was `<predictable_name>/main.asm` + `out.txt`, and the checker
correctly predicted `tests/driver/ok_format_disasm/main.asm`. Randomized BOTH levels: each fixture
directory now carries its own hex suffix and the files inside are `m_<hex>.asm` / `o_<hex>.txt`,
with the `; command:` and `; output:` lines rewritten to match. Zero predictable leaf names remain.

**FAIL 2 — alignment ERROR on the ambiguity test. FIXED, and it was a real bug.** The checker
found that `err_ambiguous_decoding/out.txt` contained `0000: one` while the test also expects an
"ambiguous decoding" error, contradicting the description's "a genuine tie is reported rather than
guessed". Root cause: those `out.txt` files were STALE ARTIFACTS, generated when I ran the binary
to inspect behavior BEFORE ambiguity detection existed, and never cleaned up. The harness ignores
them for `; error:` fixtures so the suite stayed green and I never noticed. Deleted from both error
fixtures. A leftover file that silently contradicts the spec is exactly the class of defect a green
local suite cannot catch.

**WARNING — missing partial-decode coverage. FIXED.** The requirement "bytes that no rule explains
are reported along with the position where decoding stopped" was only exercised at position 0.
Added `err_partial_decode_position`: `plain 7` decodes, then `calc 5` (a non-decodable rule) does
not, and the error names **position 16**. Genuine gap, genuine new coverage.

**WARNING — output formatting not specified. FIXED (fairness).** Tests pinned zero-padded 4-digit
lowercase hex addresses and `0x`-prefixed lowercase operands while the description only said
"prefixed with the byte address" and "operands print as hexadecimal". That is an unstated
requirement, so meta.md now spells out the canonical form: four lowercase hex digits with leading
zeros, colon, single space; operands lowercase hex with `0x`; signed values with a leading minus;
remaining text reproduced from the rule's pattern. This is the canonical-output-form rule from the
design template that the Rule-7 de-enumeration pass had trimmed too aggressively.

**WARNING — description conciseness. ACCEPTED BOTH.** Removed "Not every rule can be run
backwards." (redundant with the sentences that follow) and "so how many bits an instruction
occupies can depend on which of those inner rules matched." The second is a Rule-7 win as well as a
conciseness one: it stated a CONSEQUENCE of the subruledef rule, and removing it makes trap 2
harder while the component rule stays documented.

**Dockerfile WARNING — FIXED.** `Cargo.lock` is committed and tracked in customasm, so the build
now uses `cargo fetch --locked && cargo build --locked`. Not a workspace, so `--workspace` does not
apply.

### Post-fix state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | 367 across 5 files (unchanged) |
| Fixtures | 15 (was 14) |
| f2p | 15/15 fail on base, 15/15 pass with solution |
| Base | 691/691, before and after |
| Flakiness | byte-identical JUnit XML over 3 runs each |
| meta.md | 251 words, ASCII, no banned markers |

## FP check — held, after two real fixes

Ran both directions against the REVISED meta.md (14 claims C1-C14) and all fixtures. Both close
with no orphans: every claim has at least one discriminating fixture, every fixture traces back to
a claim. Two genuine FP breaks were found and fixed in the process.

**FP break 1 — whitespace was an unstated requirement.** meta.md said the line "is reproduced
exactly as its rule's pattern spells it". It is not: `render_rule` emits `RulePatternPart::Whitespace`
as a SINGLE space, so a ruledef pattern of `add  r1,   r2` renders `add r1, r2`. An agent
implementing the sentence literally would preserve the double space and FAIL `ok_flat`, whose
ruledef happens to contain exactly that. Classic false-positive setup: tests enforcing a rule the
description contradicts. Reworded to "the rest of the line follows the rule's own pattern, with
each run of whitespace in that pattern written as a single space."

**FP break 2 — the address-width claim was false at scale.** meta.md said "four lowercase
hexadecimal digits". The formatter is `{:04x}`, which is a MINIMUM width; past 0xffff of output it
prints five. Reworded to "padded with leading zeros to at least four digits". Untested at that
size (it needs >64KB of output) but now accurate rather than wrong.

**Coverage hole closed.** C13 (whitespace) was only INCIDENTALLY covered, by `ok_flat` happening to
use a double space. Added `ok_pattern_whitespace`, a deliberate discriminator: the ruledef uses
`spaced   r1 ,    r2` (three then four spaces) and `tight {v: u8},r3` (no spaces around the comma).
Correct output is `spaced r1 , r2` / `tight 0x9,r3`. Preserving raw spacing yields
`spaced   r1 ,    r2` and dropping whitespace yields `spacedr1,r2` - both fail.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | 367 across 5 files |
| Fixtures | 16 |
| f2p | 16/16 fail on base, 16/16 pass with solution |
| Base | 691/691 before and after |
| Flakiness | byte-identical JUnit XML, 3 runs each |
| meta.md | 264 words, ASCII |
| Predictable leaf names | 0 |
| Stale goldens in error fixtures | 0 |

Lesson recorded in `Instructions/TESTS.md` (stale-golden pre-submit check + the two-level
randomization requirement).

## Precheck round 2 — alignment FAIL fixed (2026-07-30)

One FAIL remained: tests pinned error strings the description never stated.

**Root cause.** `"no rule decodes the bits at position N"` and `"ambiguous decoding at position N"`
are wording I invented, so no natural solution reproduces them. HARDENING 3d's no-substring-pins
law says do not pin invented wording; the platform's fix is to DOCUMENT the strings. Documenting
resolves the tension: once the exact message is in the description it is derivable, so the pin is
fair rather than a guess. Both messages are now stated verbatim in meta.md, including that the
position is counted in BITS.

**The checker's read was slightly off, and the artifact was worse than it thought.** It reported
three distinct messages, treating `"no rule decodes"` (position 0) and `"no rule decodes the bits
at position N"` as separate. They are one format string; my position-0 fixture just asserted a
shorter prefix. Made all three error fixtures assert the FULL documented message so the intent is
unambiguous.

**Third error string found and removed.** Auditing the messages surfaced a `"zero-width decoding
at position N"` guard that is UNREACHABLE: `analyze_rule` rejects empty term lists, so a
zero-width decoding cannot be produced. That is speculative defensive code (explicitly forbidden by
the solution rules) and an undocumented third error path. Deleted. Counter 2 moved 367 -> 361.

**Conciseness warning — took all five.** Removed "so every bit sits in a known place", "one per
line", "is the one that applies", "when its field says so", and "then the instruction text". All
were restatements; none carried a requirement. This is a WARNING, not a blocker (1 medium, 4 low,
no high), but the edits are genuine improvements.

**Dockerfile warning is STALE — no action needed on my side.** The raw JSON quotes
`RUN cargo fetch \ && cargo build \` with no `--locked`, but the Dockerfile in this folder has read
`cargo fetch --locked && cargo build --locked` since the round-1 fix. That check ran against an
older upload. Re-upload the Dockerfile before the next precheck run. customasm is a single crate,
not a workspace, so the `--workspace` suggestion does not apply.

### Post-round-2 state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | 361 across 5 files |
| Fixtures | 16 |
| f2p | 16/16 fail on base, 16/16 pass with solution |
| Base | 691/691 before and after |
| Flakiness | byte-identical JUnit XML, 3 runs each |
| meta.md | 269 words, ASCII |
| Error paths | 2, both documented verbatim and both tested |

## Auto Review round 1 — Revision Requested, all three findings fixed (2026-07-30)

Bands were Description 3/3, Tests 1/3, Solution 0/3. Test Fairness had already passed 16/16 with
zero unfair. Both scored-down findings were real bugs in MY reference, not test-harness noise.

**S1 (High) — nested ambiguity was not reported. FIXED.** `decode_nested` duplicated the top-level
candidate loop but omitted tie tracking, so a subruledef with two equally-constrained matching rules
silently kept the FIRST match instead of reporting `ambiguous decoding at position N`. The
description says ruledef-typed parameters are decoded "the same way" and that genuine ties are
reported, so this was a direct requirement violation. Reworked: `DecodeAttempt.ambiguous` (bool)
became `ambiguous_at: Option<usize>`, `decode_nested` now returns a `NestedDecoding` carrying that
position, `try_decoding` propagates it out of both nested paths, and the shared tie predicate was
factored into `differs()` so top-level and nested selection cannot drift apart again. The reported
position is the NESTED field's bit position, which is where the tie actually is.

**S1/S2 (High) — i128 operand accumulator. FIXED.** `render_integer_field` accumulated into `i128`,
so any parameter wider than 128 bits was truncated or panic-prone, despite the repo's arbitrary-width
`util::BigInt`. Rewritten on `util::BigInt`: bits are set directly, and sign extension computes the
magnitude as `2^width - value` via `maybe_sub`, which avoids num_bigint's `-0x..` hex form and yields
the documented `-0x` spelling. Zero `i128` references remain.

**T3/T4 (High) — nested selection untested. FIXED with three fixtures.**

- `ok_nested_most_fixed_bits`: a generic `any {v: u4}` rule is listed BEFORE a fully-fixed `zero`
  rule and both match the same nibble. Correct output is `op zero`; a first-match implementation
  renders `op any 0x0` and fails. This is exactly the hole the reviewer identified.
- `err_nested_ambiguous`: two subruledef rules with identical constant bits both match, requiring
  `ambiguous decoding at position 4` (the nested field position, not the instruction position).
- `ok_field_wider_than_128_bits`: a `u160` field and a signed `s136` field. These fail under the old
  i128 accumulator, so the BigInt fix is now enforced by a test rather than trusted.

**Advisory kept as-is (deliberately).** All four agents accepted bare parameters but rejected
explicitly sized whole parameters (`v`4`, `a`12`) represented as `SliceShort` AST nodes, failing the
same 4 fixtures. The reviewer graded this fair difficulty rather than ambiguity, so those cases stay
prominent. This is the design's trap 1 (term width is not syntactic) biting exactly as intended.

**Solvability note.** The reviewer flagged 0 of 4 agents reaching PASS on the previous version. The
nested-selection and BigInt fixes do not make the task easier; the SliceShort trap that blocked all
four is untouched. If the next batch also returns 0 passes, the correct response is the 3c-bis
disclosure lever (name the root cause, never the fix), not removing the trap.

### Post-revision state

| Metric | Before | After |
|---|---|---|
| Effective LOC (Counter 2) | 361 | **384** |
| Files | 5 | 5 |
| Fixtures | 16 | **19** |
| f2p | 16/16 | **19/19 fail on base** |
| Base | 691/691 | 691/691 |
| Flakiness | deterministic | deterministic |
| i128 references | 1 | **0** |
| Compiler warnings | 0 | 0 |

## Auto Review round 2 + the 0/6 solvability question (2026-07-30)

### Diagnosis: this was NOT a hint problem, it was an under-specified contract

Six runs (3 Nova + 3 Orion), all fail, all with the SAME 6 of 22 fixtures and the SAME root cause.
Per HARDENING 3c-bis step 1 that signature is the profile of a fair-but-hard wall, not an unsolvable
one: divergent failures mean flailing, convergent failures mean one well-defined missed sub-step.

The decisive evidence came from reading the patches, not the summaries. Every trajectory DOES
mention `SliceShort`, so this was never a discovery failure. Nova_Nova_1 handled it, for literals
only, with its own comment:

    // Width suffixes on literals are represented by the parser as a
    // short slice. They are still a fixed bit pattern, not a computed
    // parameter field.
    expr::Expr::SliceShort(_, _, _, inner) => match inner { Literal => push_fixed, _ => false }

So the agents found the node, understood it, and deliberately decided a width-suffixed PARAMETER is
not a whole parameter. That is a reasonable reading of "whole parameters" - a width suffix looks
like a truncation. They were penalised for a sentence I never wrote.

Confirmed from the opposite direction by Solution Quality S1: it flagged that `v`4` on a `u8`
SHOULD be rejected as lossy. So the correct rule is width-dependent, and NOTHING in the description
conveyed that. Two independent reviewers plus six agents triangulated the same spec gap.

Classification under 3c-bis step 2: **hidden requirement**, not "one genuinely hard step". The
prescribed fix is one explicit meta sentence, not a hint, and it was mandatory anyway because S1a
makes the whole-versus-lossy distinction load-bearing and untestable-fairly while unstated.

### What changed

**Contract repair (one sentence, WHAT not HOW):** "A parameter is whole when it contributes exactly
the width it was declared with, and spelling that width out explicitly leaves it whole; contributing
fewer bits than it declares does not, and makes the rule unavailable." No mention of AST nodes,
`SliceShort`, or backtick parsing - the representation is still theirs to find.

**S1a - lossy width-wrapped parameters rejected.** `classify_sized_parameter` now requires the
explicit width to equal the declared width for fixed-width integer parameters.

**S1b - nested fixed bits accumulate into specificity.** `NestedDecoding` carries `constant_bits`
and `try_decoding` folds them in, so competing outer rules are ranked by all bits that pin them
down rather than only the outer rule's own constants.

**Three new discriminating fixtures**, closing both T3/T4 holes plus the new S1a rule:
- `err_repeated_param_unavailable`: assembles bytes THROUGH `twice {v: u4} => 0x6 @ v`4 @ v`4` and
  requires `no rule decodes the bits at position 0`. The old fixture only decoded the neighbouring
  `once` rule and could not tell exclusion from retention.
- `ok_unsized_constant_never_candidate`: an unsized-constant rule sits beside a zero-fixed-bit rule
  emitting the same bits. Correct behaviour decodes cleanly; an implementation that retains the
  unsized rule ties and raises ambiguity. This is the reviewer's own suggested construction.
- `err_lossy_param_slice`: `lossy {v: u8} => 0x5 @ v`4` must be unavailable, pinning S1a.

### Net effect on difficulty (the "will it jump to 10/10" question)

One UNFAIR barrier removed, three FAIR discriminators added. The clarification tells solvers what
counts as whole; it does not tell them how the width suffix is represented, that the size and inner
operands are stored in that order, or how to accumulate nested specificity. Agents were at 13/19 and
converged; expect a real jump, plausibly into the 20-50% range, so a >40% too-easy reading is now
the live risk rather than 0%.

If the next batch reads >40%, the correct response is NOT to re-hide the width sentence (that
re-creates the unfairness). Harden on the orthogonal axes instead: nested specificity accumulation
and nested tie reporting are freshly test-enforced but only lightly probed, and a deeper composition
(nested ambiguity beneath a variable-width parent) is the natural next wall.

### Post-revision state

| Metric | Before | After |
|---|---|---|
| Effective LOC (Counter 2) | 384 | **392** |
| Fixtures | 19 | **22** |
| f2p | 19/19 | **22/22 fail on base** |
| Base | 691/691 | 691/691 |
| meta.md | 269 words | 305 words |

## Orthogonal hardening + final review (2026-07-30)

Hardened on the three axes named as the fallback plan, all CONTRACT-STATED so a strong solver can
derive them, none of them handing the implementation.

**New meta contract (two sentences, WHAT not HOW):**

- "...decoded the same way from the bits of their own field, to whatever depth the nesting reaches,
  and a tie found down there is reported against the position of the field holding it."
- "The bits that pin an explanation down include those contributed by the nested explanations it
  settled on, so a nested choice can decide which of two outer rules wins."

Neither names a data structure, a traversal, or where specificity is accumulated. The second is the
contract for S1b, which the Auto Review demanded but which was previously untestable-fairly because
nothing stated it.

**Three new fixtures, one mutation-proven:**

- `ok_nested_bits_break_outer_tie` - two outer rules with identical outer constants (`0x8` each);
  only the nested choice separates them (`fixed` contributes 4 bits, `freev` contributes 0).
  **MUTATION-PROVEN**: reverting `constant_bits + nested_bits` to `constant_bits` turns the expected
  `0000: p fixed` into `ambiguous decoding at position 0`. This is the HARDENING 3c requirement that
  a hardening test must fail an implementation that lacks the behavior, verified rather than assumed.
- `err_nested_tie_under_variable_width` - a nested tie sitting beneath a variable-width parent, so
  the solver must get variable-width alternatives AND tie reporting right together. Reports position 4.
- `err_nested_tie_two_levels_deep` - ruledef inside ruledef inside rule; the tie is two levels down
  and must propagate to the top with the innermost field's position (8).

The last two are COMPOSITION traps in the S2 sense: each component rule is documented, but their
interaction is what has to be reasoned about.

**Difficulty rebalance rationale.** Round 3 removed one unfair barrier (the unstated whole-parameter
width rule). These three add fair walls on axes the previous batches never reached, because all six
runs died before nested selection mattered. Net expectation: the width clarification lifts the floor
off 0%, the nested composition traps hold the ceiling under 40%.

**FP check v2 - HOLDS.** Re-mapped both directions against 19 claims and 25 fixtures. No orphan
claims, no orphan fixtures. Four claim INTERACTIONS are covered by dedicated fixtures (C13xC11,
C12xC11, C15xC10, C3xC16), which is what the composition traps are for.

**Review pass - all green.** Stage 0: ASCII, no em-dashes/smart quotes/headers, test.sh 100755, no
banned markers, no predictable leaf names, no stale goldens, no cross-contamination between patches.
Solution: 0 compiler warnings, 0 comments in added code, 0 trailing whitespace, no scope creep.
Tests: 25/25 fail on base, 25/25 pass with solution, 691/691 base unaffected, reverse-apply clean,
byte-identical JUnit XML over 3 runs each.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **392** across 5 files |
| Counter 1 | 576 |
| Fixtures | **25** |
| f2p | **25/25 fail on base** |
| Base | 691/691 before and after |
| Flakiness | deterministic, byte-identical XML |
| meta.md | 330 words, ASCII |
| Compiler warnings | 0 |

## Auto Review round 3 + FP adjudication (2026-07-30)

Verdicts: FP panel GENUINE PASS (adjudicator high confidence, judges 1/2 pass, judge 3 dissent).
Auto Review: Description 3/3, Tests 2/3, Solution 0/3. All four items addressed.

**S1 (High, the blocker) — nested decoding was not field-bounded. FIXED.** For a fixed-width
`RuledefRef` field, `decode_nested` ranked candidates over the REMAINING GLOBAL stream and only
rejected the winner afterward if its width did not match the field. A longer nested rule could
therefore read past the field boundary, out-rank a valid field-local candidate, and sink the whole
outer rule. `decode_nested` now takes a `field_width` bound and skips non-conforming candidates
BEFORE ranking, so selection is field-local by construction; the after-the-fact width check is gone.

Proven with a mutation test, not assumed. `ok_nested_bounded_to_field` has `small => 0x3` (4 bits)
and `wide => 0x3ff` (12 bits) in one subruledef, with the outer rule `0x1 @ a`4 @ t`. The assembled
bytes are `0x13ff`, so the 12 bits starting at the field ARE `0x3ff` - `wide` out-ranks `small` on
fixed bits if the bound is missing. Reverting the bound turns the expected `0000: op small, 0xff`
into `no rule decodes the bits at position 0`, exactly the reviewer's described failure.

**FP dissent (judge 3) — RESOLVED by pinning the contract, not by changing the reference.** The one
real divergence was `computed => (0x40 + 0x2)`8`: the candidate decoded it, the reference rejected
it. The adjudicator called it genuinely underspecified and said that if the reference's stricter
reading is intended, a hidden test should pin it. Done both ways: meta now says "A fixed bit
pattern is a literal, and it pins down bits only when its own width is known; arithmetic still
counts as computing the output even when nothing varies", and `err_computed_constant_not_literal`
enforces it. That divergence can no longer produce a defensible FP in either direction.

**T4 (Medium) — declared parameter omitted from the output. FIXED.** `analyze_rule` already
rejected it (`used_parameters` check) but nothing tested it. Added `err_declared_param_omitted`
(`omit {v: u4} => 0x55`), and meta now states "every parameter its pattern declares appears there
exactly once".

**T4 (Medium) — address above 0xffff. ACCEPTED AS A KNOWN GAP, documented.** Enforcing the "at
least four digits" clause needs an instruction beginning past byte 0x10000, which needs >64KB of
DECODABLE output. Padding does not work: `#res` emits zeros that no rule decodes, and a sized
literal like `0x0`524288`` is a SliceShort, not a decodable literal term. The only compact route is
a single literal of ~131072 hex digits, bloating test.patch by ~131KB and slowing every run. The
claim is accurate as written, the finding is Medium on a Band-2 Tests score, and it was never the
blocker, so the cost is not justified. Recorded here rather than silently dropped.

**Calibration - the real remaining risk is now TOO EASY, not unsolvable.** The batch read 5 of 10
passing (50%), above the 40% ceiling, with all five failures having implemented most of the feature.
Round 3's fairness repair did its job and then some. The three fixes above all cut against the
passers rather than the failers: field-bounded nested decoding is a genuine algorithmic constraint
that a globally-ranking implementation gets wrong, and the literal-only and omitted-parameter rules
are eligibility checks a permissive analyzer skips. Judge 3's dissent is direct evidence that at
least one strong solver already diverged on the literal rule. Expect the next batch below 50%; if it
lands above 40% again, the next lever is composition depth on the field bound (a bounded nested
field whose own nested field is variable-width), NOT re-hiding any contract.

**FP check v3 - HOLDS.** 22 claims, 28 fixtures, no orphans either direction. Two claims are now
mutation-proven (C14 field bound, C17 nested specificity). The single known gap (C2 "at least")
is documented above.

**Review pass - green.** Stage 0 all clean. Solution: 0 warnings, 0 comments, 0 trailing whitespace,
every helper has callers, no scope creep. Tests: 28/28 fail on base, 28/28 pass with solution,
691/691 base unaffected, deterministic across 3 runs.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **396** across 5 files |
| Fixtures | **28** |
| f2p | **28/28 fail on base** |
| Base | 691/691 before and after |
| meta.md | 354 words, ASCII |
| Mutation-proven fixtures | 2 |

## Auto Review round 4 (2026-07-30) — all three findings fixed

**S1 (High, blocker) — greedy nested commitment. FIXED with real backtracking.** For an UNSIZED
nested ruledef parameter followed by another term, the decoder committed to the locally most
specific nested candidate before checking whether the rest of the outer rule could still match. The
reviewer grounded this in real repo syntax: `tests/issue97/ok.asm:8`, `test {a: sub} ({b: u8}) =>
0x11 @ a @ b`.

The linear term loop was rewritten as a recursive search. `decode_terms` walks the term list and,
at any ruledef-typed field, enumerates candidates from `nested_candidates` in specificity order and
recurses on the REMAINING terms, restoring operands and trying the next candidate when the
remainder fails. `decode_nested` (single-best selection) is gone; ambiguity is now computed per
specificity group inside `nested_candidates`, so a tied group only reports ambiguity if a member of
it is actually selected.

Mutation-proven, and the first attempt at the fixture was WRONG which is worth recording:
`ok_nested_backtracks_for_outer` initially used `op short 0x2`, where the bits are `0x1 @ 0x02` and
the 8-bit `long => 0x12` never matches, so greedy and backtracking agreed and the fixture proved
nothing. Corrected to `op short 0x24`: bits `0x1 @ 0x24` start with `0x12`, so BOTH candidates match
the field and greedy consumes the `b` field. Reverting to `candidates.into_iter().take(1)` turns the
expected `0000: op short 0x24` into `no rule decodes the bits at position 0`. A discriminator has to
be verified against the broken implementation, not assumed from its shape.

**T4 (Medium) — address beyond four digits. FIXED, and my previous refusal was wrong.** I had
declined this twice claiming it needed ~131KB of fixture. That estimate assumed ONE huge literal.
Reusing a single 8192-hex-digit literal (4096 bytes) across 16 instructions reaches byte 0x10000 in
an **8.4KB** fixture. `ok_address_beyond_four_digits` asserts 16 `pad` lines at `0000` through
`f000` and then `10000: end`, so an implementation formatting into a fixed four-character field
fails. Recording the error: I rejected a reviewer finding on a cost estimate I never checked.

**P4 (Low) — opening motivation. FIXED.** Raised on two consecutive rounds and not adopted either
time; removed now. The description opens directly with the request.

**New contract sentence for the backtracking rule** (WHAT, not HOW): "A nested choice only counts
if the rest of the rule still fits the bits that follow it." No mention of search, retry, or
ordering.

**Calibration.** Only one working run this round (22/28, failing on width-constrained ruledef
parameters), so the 50% reading from the previous batch is the live estimate. The three additions
all cut against passers: backtracking is an algorithmic requirement a straight-line decoder gets
wrong, and the address fixture catches fixed-width formatting.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **422** across 5 files |
| Counter 1 | 608 |
| Fixtures | **30** |
| f2p | **30/30 fail on base** |
| Base | 691/691 before and after |
| meta.md | 357 words, ASCII |
| Mutation-proven fixtures | **3** (field bound, nested specificity, backtracking) |
| Compiler warnings | 0 |

## Auto Review round 5 (2026-07-30) — single finding fixed; Description 3/3, Tests 3/3

Only one item remained. Description and Tests both reached 3/3 (Tests scored "Clean - covers all
requirements and obvious edge cases"), so the address and preamble fixes from round 4 landed.

**S1 (High) — false ambiguity from eager tie marking. FIXED.** `nested_candidates` marked every
equally specific nested candidate ambiguous BEFORE `decode_terms` checked which of them actually let
the enclosing rule continue. The first candidate that completed therefore carried an ambiguity
caused solely by alternatives that could never complete, so valid bytes could fail with a spurious
`ambiguous decoding` diagnostic. That contradicts the stated rule that a nested choice only counts
if the rest of the rule still fits.

Restructured: `nested_candidates` now only ranks and propagates ambiguity found deeper inside a
candidate. `decode_terms` collects every candidate whose remainder completes, keeps the
highest-specificity group among those VIABLE ones, and reports a tie only within that group.
Ambiguity precedence stays innermost-first: a tie found deeper wins over one at this level, which
wins over one in a later term.

Mutation-proven. `ok_no_false_ambiguity_when_only_one_completes` uses `p => 0x5` (4 bits) and
`q {v: u4} => 0x5 @ v`4` (8 bits) - equal fixed-bit counts, different widths - under
`op {a: sub} {b: u8} => a @ b`. Decoding `op p 0x33`, only `p` leaves room for the `u8`, so the
answer is unambiguous. Re-introducing pre-filter tie marking produces exactly
`ambiguous decoding at position 0`, the reviewer's described failure.

**Calibration.** The single unhinted run passed (1/1). That is a soft too-easy signal on a
one-run sample, and the reviewer noted the passing implementation was substantive (39 messages,
403 added lines in the decoder alone). This round's change tightens correctness rather than
difficulty. If a full batch reads above 40%, the next lever remains composition depth on the field
bound, not any reduction of the stated contract.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **428** across 5 files |
| Counter 1 | 611 |
| Fixtures | **31** |
| f2p | **31/31 fail on base** |
| Base | 691/691 before and after |
| meta.md | 357 words, ASCII |
| Mutation-proven fixtures | **4** (field bound, nested specificity, backtracking, false ambiguity) |
| Compiler warnings | 0 |

## Solution Quality round 2 + integration gap (2026-07-30)

Verdict PASS (2/3 code quality, 2/3 comprehensiveness). Two items; one was already fixed.

**Nested ambiguity edge case — ALREADY FIXED, report predates it.** The Solution Quality run was
against the 30-fixture artifact and flags exactly the eager tie-marking in `nested_candidates` that
round 5 removed. Verified against current source: `nested_candidates` no longer annotates ties at
all, and tie detection now runs in `decode_terms` after `viable.retain(...)` filters candidates by
whether the enclosing rule completes. Covered by
`ok_no_false_ambiguity_when_only_one_completes`, mutation-proven.

**Integration gap — FIXED, this was genuinely unhandled.** Raised in round 1 as a minor note and
again here: the format was wired into parsing and output generation but not into the surfaces that
advertise it. Both now updated:

- `src/usage_help.md` gains a `disasm` entry beside the other formats, so `--help` lists it.
- `web/index.html` gains `<option value="disasm">Disassembly</option>` in the format selector.

That takes the solution to 7 files. Patch generation now diffs `src/ web/` rather than `src/` alone;
`web/index.html` would otherwise have been silently dropped from solution.patch.

**One trailing-whitespace warning is intentional and stays.** `git apply` reports whitespace on the
added `* `disasm`  ` line in usage_help.md. That is markdown's two-space line break and the file's
own convention: 41 existing entries end the same way. Stripping it would break rendering and diverge
from repo style, so it is kept. This is the opposite call from the Rust sources, where trailing
whitespace was stripped because it carries no meaning there.

**FP check v4 — HOLDS.** 23 claims, 31 fixtures, no orphans either direction. This round's changes
are FP-neutral by construction: the help and web listings are consequences of the existing "Add a
`disasm` output format" claim, not new requirements, and add no tested behavior.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **432** across **7** files |
| Counter 1 | 615 |
| Fixtures | **31** |
| f2p | **31/31 fail on base** |
| Base | 691/691 before and after |
| meta.md | 357 words, ASCII, unchanged since round 4 |
| Mutation-proven fixtures | **4** |
| Compiler warnings | 0 |

## Coverage suggestions adopted (2026-07-30)

All three Test Fairness coverage suggestions were genuine gaps and all three were implemented. Each
is an INSTANCE of an already-stated contract, so no meta change was needed and FP is unaffected.

**`ok_deep_nesting_renders`** - the existing two-level fixture only proved ambiguity PROPAGATION
through two levels; nothing proved successful two-level RENDERING. Now `top wrap dx` reconstructs
text through ruledef -> mid -> deep, with a second case so the inner choice is load-bearing rather
than constant.

**`ok_signed_boundary_values`** - `ok_signed` only covered -3, 3 and an unsigned 0xff. Added the
two's-complement edges: `s8` -128 renders `-0x80` (most negative, where the magnitude equals the
modulus minus the value), 127 renders `0x7f` (most positive, top bit clear), plus -1 -> `-0x1` and
0 -> `0x0`. These are exactly the points where the `2^width - value` sign path could be off by one.

**`err_top_level_ambiguity_nonzero`** - nonzero positions were covered for no-match (16) and nested
ambiguity (4 and 8), but top-level ambiguity was only ever asserted at position 0, so a hardcoded
zero would have passed. A valid `lead` instruction now precedes the ambiguous byte, requiring
`ambiguous decoding at position 8`.

FP check v5: 23 claims, 34 fixtures, no orphans. The three additions map to existing claims
(C13/C15 deep nesting, C19 signed rendering, C12 tie diagnostic); no new claim was introduced.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **432** across 7 files |
| Fixtures | **34** |
| f2p | **34/34 fail on base** |
| Base | 691/691 before and after |
| meta.md | 357 words, unchanged since round 4 |
| Mutation-proven fixtures | 4 |

## Composition wall on the field bound (2026-07-30) — and it exposed a reference bug

I had named this lever twice as the next hardening step without building it. Building it found that
the REFERENCE was wrong.

**The probe.** A fixed-width nested field whose subruledef rule itself contains a variable-width
nested field:

    #subruledef leaf { s => 0x2      l => 0x23 }
    #subruledef box  { b {x: leaf} => 0x4 @ x }
    #ruledef { narrow {a: box}, {t: u8} => 0x7 @ a`8 @ t }

`box` is 8 bits with `s` and 12 bits with `l`. Both leaf alternatives MATCH the bits, but only `s`
makes the box exactly the 8 bits the field declares. Reference output before the fix:
`no rule decodes the bits at position 0`.

**Root cause.** The field bound was applied only as a post-hoc filter on the finished nested
attempt. Inside `box`, the greedy pick was `l` (8 fixed bits beats `s`'s 4), producing a 12-bit box
that then failed the 8-bit filter, with no retry of the shorter inner alternative. The bound never
reached the inner choice.

**Fix.** The bound is now a `target_end` threaded through `try_decoding` into `decode_terms` and
enforced at the base case: when a nested rule's terms are exhausted, the cursor must land exactly on
the field's end, otherwise the walk fails and the existing backtracking retries another inner
alternative. `nested_candidates` converts `field_width` into that target and the post-hoc width
filter is gone, since it is now unreachable-false.

**Fixture** `ok_bound_selects_inner_width` drives the bound in BOTH directions so it cannot be
satisfied by a "prefer shortest" or "prefer most specific" shortcut:
- `narrow` bounds the field to 8, forcing `s` even though `l` has MORE fixed bits;
- `wide` bounds it to 12, forcing `l`.

Mutation-proven: restoring the post-hoc filter reproduces `no rule decodes the bits at position 0`.

**Meta contract extended** (WHAT, not HOW): "...and if a field it sits in is exactly as wide as the
field says." One clause; it states the constraint without describing threading, targets, or retry.

**Why this is the right kind of hardening.** It is a genuine composition of three already-stated
rules (field bounding x variable-width nesting x specificity), not a new mechanism, and it is the
axis all previous batches never reached. It also cuts against passers rather than failers: a
straight-line implementation that filters after the fact gets it wrong, which is exactly what mine
did.

**FP check v6 — HOLDS.** 24 claims, 35 fixtures, no orphans. The new clause (C24) has exactly one
discriminating fixture, mutation-proven, and that fixture maps to no other claim.

### Final state

| Metric | Value |
|---|---|
| Effective LOC (Counter 2) | **437** across 7 files |
| Fixtures | **35** |
| f2p | **35/35 fail on base** |
| Base | 691/691 before and after |
| meta.md | 372 words, ASCII |
| Mutation-proven fixtures | **5** |
| Compiler warnings | 0 |

## HARDEN round (2026-07-30) — 90% batch diagnosed and re-hardened

### Stage 1: evidence (agent-runs2, 10 runs, ElementTree)

**9/10 pass = 90%**, far above the 40% ceiling. The decisive number is not the pass rate:

**27 of 35 tests killed NOTHING.** All 8 kills came from a single run (Nova_Nova_8) and were
mutually correlated, tracing to one root cause: rejection of explicitly sized nested ruledef
fields. Old runs for comparison: 0/13 across four batches, every failure the SAME cause.

### Stage 2: diagnosis

The suite had exactly ONE working trap, and I disarmed it myself. Round 3 added
"spelling that width out explicitly leaves it whole" to repair a genuine fairness break (6/6 agents
were failing on an unstated requirement). That sentence was correct and must stay, but it was
load-bearing for the entire difficulty of the problem. Everything I added in rounds 4-8 was
correctness or coverage, and none of it killed anything.

Diagnosis per HARDENING Stage-2 table: "Everyone passes, few or no failures -> one weak or
self-revealing trap -> do NOT add wording, add a second mechanism on a DIFFERENT axis."

### Stage 3: lever selection, informed by the PASSING patches

Read the passing solutions before choosing. All three sampled passers render through
`RulePatternPart::ParameterIndex` and map operands by parameter index, so Auto Review's
"reordered scalar parameters" suggestion would kill ZERO agents - the repo's own data model forces
correct identity mapping. Added it anyway for coverage (L17: take reviewer suggestions) but it is
NOT counted as difficulty. This is the neva lesson applied: do not add tests that kill nothing and
call it hardening.

The real lever came from `fp.txt`, which recorded that the REFERENCE segfaults on cyclic ruledefs
while one candidate handled it cleanly. Verified locally: a self-delegating subruledef
(`n {x: node} => x`) stack-overflowed my reference, **exit 134**. That is a genuine crash bug on
legal input AND an axis orthogonal to every existing trap (eligibility, specificity, bounds,
ambiguity, rendering, backtracking all assume termination).

### New axes added

| Axis | Fixture | Status |
|---|---|---|
| **Termination / self-delegation** | ok_self_delegating_rule_unavailable | MUTATION-PROVEN (removing guard = stack overflow) |
| **Decode depth** | ok_deep_nesting_depth (30 levels) | contract-stated by "to whatever depth the nesting reaches"; kills depth-capped impls (fp.txt shows a real candidate capped at 25) |
| **Eligibility x recursion** | ok_nested_unavailable_alternative | computed alternative inside a subruledef must be skipped without poisoning the outer decode |
| **Parameter identity vs encoding order** | ok_reordered_scalar_params | coverage only, expected 0 kills |
| **INTERDEPENDENT: termination x bound-threading** | ok_interdependent_bound_and_termination | MUTATION-PROVEN on BOTH mechanisms |

### The interdependent trap (what the round was really for)

`ok_interdependent_bound_and_termination` composes a self-delegating subruledef rule, a
variable-width nested alternative, and an 8-bit field bound. Both mechanisms are required and each
fails DIFFERENTLY:

- remove the termination guard -> **exit 134, stack overflow**
- remove bound threading (post-hoc width filter instead) -> **`no rule decodes the bits at position 0`**
- correct -> `0000: op b s, 0x3f`

Neither symptom points at its cause: a crash reads as a resource bug, a no-decode reads as a
matching bug. Fixing termination naively with a depth cap then fails `ok_deep_nesting_depth`;
fixing the bound naively with a post-hoc filter fails this fixture. That is genuine
interdependence, and the difficulty is in DOING (getting the recursion structure right), not in
knowing a rule.

### Fairness

One new meta sentence, the minimum for the termination axis, WHAT not HOW: "A rule that hands its
whole encoding to another ruledef without pinning down any bits of its own cannot be told apart
from what it wraps, so it is not available either." No mention of cycles, guards, depth, or
recursion. The other three axes needed NO new sentences - depth is covered by the existing "to
whatever depth the nesting reaches", nested eligibility by the eligibility rules plus "decoded the
same way", and operand identity by "follows the rule's own pattern".

Nothing previously documented was re-hidden. The round-3 width sentence stays.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | **445** across 7 files |
| counter1 | 632 |
| Fixtures | **40** |
| f2p | **40/40 fail on base** |
| Base | 691/691 before and after |
| Flakiness | byte-identical JUnit XML, 3 runs |
| meta.md | 404 words, ASCII |
| Compiler warnings | 0 |
| Mutation-proven fixtures | **7** |

### Predicted effect — stated honestly

The termination axis should be the strongest: it crashes an implementation rather than producing a
wrong value, and no agent in either batch wrote a guard for it. Depth-capping is a real observed
failure mode (fp.txt). The interdependent fixture requires two mechanisms simultaneously. I expect
a substantial drop from 90%, but the honest position is that only a 10-run batch closes the loop -
mutation kills measure test coverage, not agent difficulty. If the next batch still reads above
40%, the evidence to look at is which of the five new fixtures killed nothing, not the rate alone.

## Round-3 sentence de-enumerated (2026-07-30)

The sentence that disarmed the problem's only original trap has been reworded. It is a Rule-7
de-enumeration, not a re-hiding.

BEFORE: "A parameter is whole when it contributes exactly the width it was declared with, and
spelling that width out explicitly leaves it whole; contributing fewer bits does not."

AFTER:  "A parameter is whole when the bits it contributes are exactly the width it was declared
with; contributing fewer than that does not."

The clause removed ("spelling that width out explicitly leaves it whole") was an INSTANCE: it named
the syntactic form and told the solver it counts. The RULE it instantiates - whole means contributing
exactly the declared width - is fully retained. Rule 7 says state the general principle and delete
the instance list, which is exactly this edit.

**Why this is fair and not a return to the 0/6 state.** The original unfair version said only
"whole parameters" with NO criterion, so agents guessed and 6 of 6 guessed that a width suffix means
not-whole. The current version gives a DECIDABLE test they can apply to any form: count the bits the
form contributes, compare to the declared width. Both directions follow from it without naming any
syntax:

- a 4-bit-wide form on a `u4` parameter contributes 4 == 4 -> whole
- the same form on a `u8` parameter contributes 4 < 8 -> not whole (`err_lossy_param_slice`)
- a bare parameter contributes its declared width -> whole

Ruledef-typed parameters have no declared width and are covered separately by the nesting paragraph
("a field it sits in is exactly as wide as the field says"), so no claim is orphaned.

**Why the 0% risk is much lower than it was in round 3.** Then, width was the ONLY trap: disarming
it gave 90%, re-hiding it would have given 0%. The problem now carries five axes - termination,
decode depth, eligibility x recursion, bound threading, and the interdependent
termination x bound fixture. An agent that resolves the width question still faces all of them, and
one that does not fails regardless, so the distribution should spread rather than collapse to either
edge.

FP re-check: every claim still has a discriminating fixture and every fixture still traces to a
claim; the reworded sentence covers exactly the same tests as before, by criterion instead of by
example. 40/40 still fail on base, 691/691 base green, deterministic across 3 runs.

meta.md: 399 words (was 404).

## Suggestion audit (2026-07-30) — what was applied, and two that were NOT

Asked directly whether the FP, fairness and Auto Review suggestions were applied. Audited rather
than asserted. Four were already in; two were not, and both were real.

**Applied (verified present):**

| Source | Suggestion | Fixture |
|---|---|---|
| Auto Review T4 | reordered scalar parameter mapping | ok_reordered_scalar_params |
| Auto Review T4 / Test Fairness | unavailable alternative inside a nested ruledef | ok_nested_unavailable_alternative |
| fp.txt (Orion judge-c) | depth cap at 25 vs "whatever depth the nesting reaches" | ok_deep_nesting_depth (30 levels) |
| fp.txt (Orion adjudicator) | reference segfaults on cyclic ruledefs | ok_self_delegating_rule_unavailable |

**NOT applied until now — two fp.txt grey zones, both real defects in MY reference.** The Nova-8
adjudication recorded two candidate/reference divergences and called them unsettled by the prompt.
Both turned out to be cases where the reference CONTRADICTED its own stated criterion, in opposite
directions:

- **Full-range bit slice `v[7:0]`.** The criterion says a parameter is whole when the bits it
  contributes equal its declared width. On a `u8`, `v[7:0]` contributes exactly 8, so the contract
  says whole, but the reference answered `no rule decodes` because only the `SliceShort` form was
  handled. The candidate that accepted it was more faithful to the meta than my own solution.
  Fixed: `classify_ranged_parameter` accepts a full-range slice anchored at bit 0 whose span equals
  the declared width. A partial range such as `v[3:0]` on a `u8` contributes 4 of 8 and stays
  unavailable, which is the same lossy rule already stated.
- **Untyped parameter `{x}` written `x`8`.** An untyped parameter has NO declared width, so
  "exactly the width it was declared with" cannot be satisfied and it can never be shown whole.
  The reference accepted it anyway, because the declared-width check was skipped whenever
  `parameter_width` returned `None` - which is also the case for ruledef-typed parameters. Fixed by
  splitting those two: `check_declared_width` exempts ruledef parameters (governed by the nesting
  rules) and rejects everything else without a declared width.

Both are now PINNED by fixtures, which is what the adjudicator asked for and what actually closes an
FP grey zone: `ok_full_range_slice_is_whole`, `err_partial_range_slice_not_whole`,
`err_untyped_param_not_decodable`.

**No new meta sentence was needed for either.** Both outcomes follow from the existing criterion
once it is applied consistently; the bug was the reference not following its own contract, not the
contract being silent. This is the cheapest kind of FP fix - make the implementation match the
sentence rather than add a sentence.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | **480** across 7 files |
| Fixtures | **43** |
| f2p | **43/43 fail on base** |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| Stale goldens in err dirs | 0 |
| Compiler warnings | 0 |
| meta.md | 399 words, unchanged this round |

## meta.md WHAT-not-HOW audit + FP re-verification (2026-07-30)

**WHAT-not-HOW: verified mechanically, not asserted.** Scanned meta.md for implementation
vocabulary (recurs/backtrack/iterate/loop/guard/visited/cache/stack/sort/filter/traverse/parse/
node/struct/function/helper/module/file/algorithm/store/table/map) and for repo internals
(SliceShort, Expr, RuleParameterType, ItemRef, BitVec, BigInt, decode_*, analyze_*, classify_*).

Result: ZERO real hits. The four apparent matches were substring artifacts - "struct" inside
"instructions" and "ast" inside "at least" / "past it". No repo identifier appears anywhere.

Backticked names are public surface only: `disasm` (the new format), `0x` (operand prefix, part of
the output contract), and the two diagnostics. No internal name is backticked.

**Per-trap FIX-HIDDEN check.** Every wall states its outcome and withholds its mechanism:

| Trap | Contract states | Withheld |
|---|---|---|
| whole-parameter width | the criterion (contributed bits == declared width) | which syntactic forms qualify |
| termination | self-delegating rules are unavailable, and WHY (indistinguishable from what they wrap) | cycles, guards, depth caps |
| field bound | the field is exactly as wide as it says | threading a target, when to check |
| backtracking | a nested choice counts only if the rest fits | retry, search order |
| nested specificity | pinning bits include nested contributions | where to accumulate |
| depth | to whatever depth the nesting reaches | how to avoid blowing the stack |

The termination sentence gives the ROOT CAUSE rather than the fix, which is the HARDENING 3c-bis
easing form: it tells the solver why such a rule cannot work without telling it to add a guard.

**FP re-verified both directions after the meta reflow (whitespace-only, no wording change):**
24 claims, 43 fixtures, 43 referenced, **0 orphans, 0 phantoms, every claim has at least one
fixture.** One gap was found and closed during the check - `ok_param_used_twice_skipped` was missing
from claim C4 in my written map (a bookkeeping omission, not a missing test). Map saved to
`.fp-map.txt` so the next round starts from a checked artifact rather than rebuilding it by hand.

Suite unchanged at 734 passing; meta.md 399 words.

## Auto Review round 6 (2026-08-02) — CALIBRATION CONFIRMED + converse edge closed

**The headline is the difficulty number, not the finding: 2 of 10 passed = 20%, inside the <=40%
band.** The harden round did its job (previous batch was 9/10 = 90%). The reviewer's own read
agrees: substantial failing implementations, failures landing on explicitly stated requirements,
no leakage or unfairness signal. Recorded failure modes: six agents mishandled whole parameters
expressed as exact-width slices (especially bounding nested fields), three imposed arbitrary
recursion caps and failed the ~30-level valid case. Both of those are the axes added in the harden
round, so the new walls are the ones doing the work.

Bands: Description 3/3, Solution 3/3, Tests 2/3 on one Medium finding.

**Is the extra test important? Yes, and for a sharper reason than the reviewer gave.** The finding
was that only the NARROWER direction of the exact-width rule is tested (`u8` contributed as 4 bits),
so an implementation using `>=` could pass. Checking my own artifacts:

- the implementation was already correct: `check_declared_width` uses `!=`, so `u4` contributed as
  `v`8` is rejected;
- but meta.md said "...exactly the width it was declared with; **contributing fewer than that does
  not**". That trailing clause states only ONE direction, and it is precisely the wording that
  would license a `>=` reading. The rule was complete via "exactly" and then undercut by its own
  example.

Both fixed:

- **Wording** now "...exactly the width it was declared with, and not whole otherwise." Symmetric,
  and a Rule-7 win: the one-sided instance is gone, so nothing hints which direction to guard.
- **Fixture** `err_over_wide_param_slice`: `over {v: u4} => 0x5 @ v`8` must report
  `no rule decodes the bits at position 0`.

This is the same class of defect as the earlier round-3 sentence: a clarifying example that
narrowed a general rule. Worth carrying forward as a check - when a rule says "exactly", do not
append an example covering one side of it.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | see run output above |
| Fixtures | **44** |
| f2p | **44/44 fail on base** |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| Stale goldens / warnings | 0 / 0 |
| meta.md | 397 words (was 399) |
| FP | 24 claims, 44 fixtures, 0 orphans, 0 phantoms |

## Takeaway wording vs finding wording (2026-08-02) — both now covered

Checked whether what I added actually matches the takeaway. It matched the FINDING but not the
TAKEAWAY, because the two use different examples of the same rule:

- finding "Expected": "a `u4` parameter contributed as `v`8`" -> this is exactly what
  `err_over_wide_param_slice` does;
- "Your takeaway": "you already reject `{v: u8}` when only four bits are contributed; also exercise
  an explicitly wider-than-eight-bit contribution" -> a `u8` contributed at MORE than 8 bits, which
  my fixture did not cover since it declares `u4`.

Both test the same contract (contributed width != declared width -> not whole), so the rule was
never unprotected, but the takeaway's specific shape was absent. Added
`err_over_wide_u8_param`: `over {v: u8} => 0x5 @ v`16`, expecting
`no rule decodes the bits at position 0`.

Keeping both is deliberate rather than redundant: the two fixtures use DIFFERENT declared widths
(4 and 8) on the over-wide side, so an implementation that hardcodes 8 anywhere in its width
comparison is caught by one of them. Together with `err_lossy_param_slice` (u8 contributed at 4)
and `err_partial_range_slice_not_whole` (u8 contributed at 4 via a range), the exact-width rule is
now covered under-width and over-width at two different declared widths.

Validation after the addition: 45 fixtures, 45/45 fail on base, 45/45 pass with the solution,
691/691 base green both before and after, deterministic across 3 runs, no stale goldens.
FP: 24 claims, 45 fixtures, 0 orphans, 0 phantoms.

## Solution Quality round 3 (2026-08-02) — nested tie identity aligned

Verdict PASS (2/3 code quality, 2/3 comprehensiveness), single finding both times: nested tie
detection compared only rendered width and text, while top-level tie detection compared rule
identity via `differs()`. Same contract, two different equality tests.

**The finding is correct about the code and wrong about the impact - checked, not assumed.** I
tried to build a probe that exercises it: two distinct nested rules that render identically with the
same width. Such rules necessarily produce identical bits, and customasm's OWN assembler rejects
that source at assembly time with `multiple matches with the same encoding size`. The decoder only
ever sees bytes customasm itself emitted, so the divergent path is unreachable from any assembled
input. There is no behavioral defect and no fixture can pin one.

Fixed anyway. `NestedDecoding` now carries `rule_ref` and the nested tie check compares it, so both
levels use the same notion of "a different rule". The change is behaviorally inert on every valid
input - which is exactly why it is safe - and it removes an inconsistency that has now cost a point
on both rubric dimensions twice. Consistency here is worth more than the line it saves: a reader
comparing the two levels should not find two different answers to "when are two explanations the
same".

No fixture added, deliberately. A test for an unreachable state would either be untestable or
require constructing bytes the assembler cannot produce, and inventing such a fixture to look
thorough is the opposite of the FP discipline used everywhere else in this submission.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | **483** across 7 files |
| Fixtures | 45 |
| f2p | 45/45 fail on base |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| Compiler warnings | 0 |
| meta.md | unchanged (397 words) |

## Why the pass rate keeps swinging (2026-08-02) — diagnosed from agent-runs 3

Pass-rate history: **0/13 -> 90% -> 20% -> 57%**. That is not noise around a stable difficulty; it
is a BIMODAL problem.

The decisive evidence is in `agent-runs 3`: all three failing agents failed the **identical 13
tests**. Not overlapping - identical. Perfect correlation across independent runs:

    err_nested_ambiguous, err_nested_tie_two_levels_deep, ok_bound_selects_inner_width,
    ok_deep_nesting_renders, ok_full_range_slice_is_whole, ok_interdependent_bound_and_termination,
    ok_most_constant_bits_wins, ok_nested_bits_break_outer_tie, ok_nested_bounded_to_field,
    ok_nested_most_fixed_bits, ok_param_used_twice_skipped, ok_subruledef, ok_wide_field

Every one of those depends on recognising full-width parameter slice forms (`v`4`, `v[7:0]`),
because those forms are also what bounds nested fields. So ONE decision decides the whole run:
handle slice forms -> pass all 48; miss them -> fail exactly that cluster.

Pass rate is therefore `P(agent handles slice forms)`, a near coin-flip that moves with agent mix
and small samples. That is the correlated-seam shape TOO-EASY records for participle: "an
implementation that makes the choice passes all; one who does not fails all." Stacking more tests
on the SAME seam cannot stabilise it - they all die together.

**What would actually stabilise it:** failures that are INDEPENDENT of the slice decision. The
termination and depth axes added in the harden round are such axes - they bit in the 20% batch
(three agents failed on recursion caps) but not in agent-runs 3. They need to be strong enough to
fire regardless of the slice outcome. That, not more slice coverage, is the remaining work.

## Auto Review round 7 fixes

**S1 (0/3 blocker) - over-broad wrapper exclusion. FIXED.** The guard rejected every zero-literal
rule whose terms are all ruledef parameters. The contract excludes only a rule that hands its whole
encoding to ANOTHER ruledef (singular) - a transparent wrapper. A composite of two whole bounded
ruledef fields is distinguishable through its nested explanations and must stay decodable.
Narrowed to `constant_bits == 0 && terms.len() == 1 && is_ruledef_term(&terms[0], rule)`. Verified
the cyclic self-delegation case still terminates (exit 0), so the termination axis is intact.
New fixture `ok_composite_two_ruledef_fields` pins it.

**T4 (Tests 1/3 blocker) - no literal after or between parameters. FIXED.** Every mixed fixture put
constants first, so a decoder supporting only opcode prefixes could pass. Added
`ok_literal_after_parameter` (`tail {v: u8} => v @ 0xaa`) and `ok_literal_between_parameters`
(`mid {a: u4}, {b: u4} => a`4 @ 0x5 @ b`4`).

### Still owed - two FP gaps, designs recorded rather than rushed

Two of four FP adjudications came back FALSE POSITIVE. Both name a missing fixture, and both need
exact bit arithmetic to construct so that BOTH tied members are viable. Recording the designs
instead of shipping a half-checked fixture:

1. **Nova-4** - nested tie whose tied members have DIFFERENT widths, followed by another operand.
   Needs two subrules with EQUAL constant bits but different widths (e.g. `s1 => 0x1` and
   `s2 {v: u4} => 0x1 @ v`4`, both 4 fixed bits, widths 4 and 8), inside
   `op {a: t} {b: u8} => 0xf @ a @ b`, with the stream sized so BOTH complete. Must report the
   FIELD position, not the instruction start.
2. **Nova-1** - two consecutive unbounded nested fields, to pin that each field is chosen by its
   OWN fixed bits rather than by maximising the whole-explanation total.

These are the highest-value remaining tests: an FP means reward was paid for wrong behaviour.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | 483 across 7 files |
| Fixtures | **48** |
| f2p | 48/48 fail on base |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| FP map | 24 claims, 48 fixtures, 0 orphans, 0 phantoms |

## HARDEN round 2 (2026-08-02) — decorrelating the bimodal seam

**Diagnosis (Stage 2 table):** "one dominant cause but SOME agents cleared it -> legitimate design
wall (L18) -> keep it, harden elsewhere." 4 of 7 cleared the slice-form wall, so it is a real wall,
not an unfair one. The problem is not miscalibrated; it is BIMODAL, and stacking more tests on the
same seam cannot fix that because they all die together.

**Lever (Stage 3 order): F-10 cross-product cells, on FLAT decoding.** Every one of the 13
correlated failures is a NESTED test, so the decorrelating cells must live where slice handling is
irrelevant. Filled three empty flat cells in one fixture, `ok_flat_field_boundaries`:

| Cell | Rule | Why it is independent of the slice seam |
|---|---|---|
| signed field NOT last | `mid {v: s8} => 0x3 @ v @ 0xc` | sign extension must use the FIELD width, not the remaining stream |
| width not a multiple of 4 | `odd {w: u5} => 0x7 @ w`5` | 5-bit field, byte- and nibble-unaligned |
| unsigned top-bit-set NOT last | `hi {u: u8} => 0x2 @ u @ 0x9` | must NOT sign-extend an unsigned field |

All three are flat rules with no subruledef anywhere, so an agent that handles `v`4`/`v[7:0]`
perfectly can still fail them - which is exactly the property the previous batches lacked.

**Mutation-proven.** Changing sign extension to trigger only when the field runs to the end of the
stream (`offset + width == bits.len()`) - the natural mistake of sign-extending against the
remaining stream rather than the declared field - turns `mid -0x3` into `mid 0xfd`. The other two
cells guard the same helper from the opposite side.

**Zero new description words.** All three cells are compositions of already-stated rules (operands
in lowercase hex, signed prints a leading minus, whole parameters contribute their declared width),
which is the F-10 property: a contract stating both axes already covers their composition.

**Predicted effect, stated honestly.** This does not lower the ceiling for an agent that gets
everything right, and it will not by itself move a batch from 57% to under 40%. What it should do
is DECORRELATE: pass/fail stops being a single coin-flip on slice forms, so the rate should stop
swinging 0/90/20/57 and settle. Confirming that needs a batch; per L15 mutation kills measure test
coverage, not agent difficulty. If the next batch still shows every failure in one cluster, the
remaining lever is F-9 (cross-stage resolution drop), not more cells.

### Also landed this round

- **FP gap 1 (Nova-1)** `ok_nested_local_specificity`: two consecutive unbounded nested fields;
  correct output `op short any 0xabc`, the global-scoring candidate produced `op long 0x1a fixed`.
- **FP gap 2 (Nova-4)** `err_nested_tie_differing_widths`: tied members of DIFFERENT widths (4 and
  8, both 4 fixed bits) with a trailing operand; must report the FIELD position (4), not the
  instruction start (0) the candidate reported.
- **Coverage** `ok_non_byte_aligned_stream` (12-bit total) and `ok_addresses_are_stream_offsets`
  (bank at `#addr 0x8000` still prints `0000`/`0002`).
- **meta wording** now says "byte offset ... within those bytes" instead of "byte address", because
  the old phrasing implied logical bank addresses while the behaviour is stream offsets. That
  ambiguity was what the coverage suggestion was really pointing at.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | 483 across 7 files |
| Fixtures | **53** |
| f2p | 53/53 fail on base |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| FP map | 24 claims, 53 fixtures, 0 orphans, 0 phantoms |
| Mutation-proven fixtures | **6** |
| meta.md | 400 words |

## F-9 lever: cross-stage resolution drop (2026-08-02)

The lever the harden skill ranks second, and the right one here because its failure mode is
completely independent of the slice-form seam that made the problem bimodal.

**The elidable form with an implicit default.** customasm bankdefs carry `addr_unit`, set by
`#bits`, defaulting to 8 (`src/asm/defs/bankdef.rs:31`). The repo's own address arithmetic already
divides by it (`src/asm/resolver/iter.rs:496`, `cur_position / addr_unit`). The unit is declared in
the BANKDEF stage and must be resolved by the OUTPUT stage - two different subsystems from the
ruledef analysis where every existing trap lives.

**My reference had the bug.** It divided by 8 unconditionally, so under `#bits 16` it printed
`0000 / 0002 / 0004` where the correct offsets are `0000 / 0001 / 0002`. Fixed by resolving the
unit from the bank that owns the output. Note the resolution order matters and is itself a small
trap: bankdef 0 is the IMPLICIT default (unit 8, output offset 0) and user-declared banks come
after it, so scanning forward finds the default and silently returns 8. The search runs in reverse.

**Mutation-proven.** Replacing the lookup with a hardcoded `8` - precisely the natural mistake, and
what my own first version did - reproduces `0000 / 0002 / 0004`. `ok_offset_unit_from_bank` pins it.

**Why it decorrelates.** The fixture contains no subruledef, no nested field and no slice form. An
agent that handles `v`4` and `v[7:0]` perfectly still fails it if it assumes byte offsets, and an
agent that misses slice forms can still pass it. That is the property every existing axis lacked:
all 13 correlated failures were nested tests.

**Fairness.** Contract sentence rewritten WHAT-not-HOW: "starts with the offset the instruction
begins at, counted in the units the output is addressed in". Scanned clean for `bankdef`,
`addr_unit`, `#bits`, `divide` - the sentence says what the number means, never where the unit
comes from or how to fetch it. The unit itself is repo-discoverable: the default is in
`bankdef.rs` and the division idiom is already used in `iter.rs`, which satisfies the
"not contradicting the repo's own docs" guard.

This also retires the earlier "byte offset" wording, which was doubly wrong: it implied bytes are
always the unit, and it was the ambiguity the address coverage suggestion had flagged.

### Validation

| Check | Result |
|---|---|
| human-effective (Counter 2) | **493** across 7 files |
| Fixtures | **54** |
| f2p | 54/54 fail on base |
| Base | 691/691 before and after |
| Flakiness | byte-identical XML, 3 runs |
| FP map | 24 claims, 54 fixtures, 0 orphans, 0 phantoms |
| Mutation-proven fixtures | **7** |
| meta.md | 405 words, ASCII, no HOW-leak |

**Predicted effect.** Two independent axes now exist off the slice seam (flat field boundaries,
output addressing unit), both mutation-proven. Expect the failure distribution to stop collapsing
into a single cluster; whether the rate lands under 40% is for the batch to say, not the mutations.
If the next batch again shows one cluster, the remaining untried lever is F-1, which requires
reading the passing patches first.
