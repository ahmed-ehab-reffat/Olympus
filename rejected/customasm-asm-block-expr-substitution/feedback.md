# feedback.md — customasm-asm-block-expr-substitution

Repo: hlorenzi/customasm | BASE_COMMIT c66cb389e7af95ad612520d4766bcb09adfea948
Tier: Olympus | Shape: O-Pipeline-hard

## Status

BUILT AND VALIDATED. All 5 deliverables exist. 722/722 tests pass, f2p clean both apply orders,
flakiness green. BLOCKED on two hard gates: effective LOC 167 (need 200) and 1 file (need 2).

## Attempt history

### Pick round 1 — branch relaxation / smallest-encoding selection: KILLED at design

Original hunt thesis. Dropped before any code for three independent reasons, any one fatal:

1. **Already implemented.** `src/asm/resolver/instruction.rs:266-277` already retains only the
   minimum-size encodings among candidate matches and errors with "multiple matches with the
   same encoding size" when ambiguous. No behavioral f2p gap (PICK-FILTER Gate 1, CLAUDE.md
   SIX-CHECK item 6). The earlier read of `e[0]` at line 91 is the single-candidate path, not
   the selection policy.
2. **Textbook feature core.** Branch relaxation / span-dependent instruction selection is a
   named, published compiler algorithm. TOO-EASY death class "saturated-reference port" plus the
   kitesql/rhai/async-graphql DEDUPE law: canonical semantics drive independent authors to a
   near-identical core, and no packaging change clears a similarity flag on it.
3. **Single-insight.** "Start small, widen monotonically, iterate" discharges every case — the
   jsondiff reindex-transform ceiling.

Maintainer position on #121 ("important that the assembler doesn't choose any one rule based on
order -- in the future it would allow for new optimizations") is FAVORABLE to the feature class,
so this died on redundancy and derivative risk, not philosophy.

### Pick round 2 — asm-block expression substitution: CURRENT

Pivoted to the nested sub-assembler. See DESIGN.md.

f2p reproduced on base with the release binary at BASE_COMMIT:

| Probe | Base behavior |
|---|---|
| `asm { ldi {addr} }` (bare name) | works |
| `asm { ldi {addr >> 8} }` (expression) | ``error: expected `}` `` |
| `asm { inner: ldi inner }` (bare label ref) | works, resolves in 1 iteration |
| `asm { inner: ldi {inner} }` (label via brace) | **fails** — substitution runs before labels exist |
| forward label through a bare brace | works, resolves in 4 iterations |

The third and fourth rows are the design's central asymmetry: a label is visible to the
instruction body but not to the substitution mechanism, because `perform_substitutions` runs once
in `eval_asm` before the block's fixpoint.

## GitHub audit (Phase 2)

- Canonical org resolved: `hlorenzi/customasm` (no redirect).
- All 44 PRs enumerated, every state. None implements brace-expression substitution.
- Adjacent diffs pulled and read: #120 CLOSED (local labels in asm blocks, targets the removed
  `src/asm/state.rs`), #119 MERGED (`$`/pc inside asm), #127 OPEN (string encoding suffixes,
  touches `src/expr/parser.rs` +5/-5), #248 / #249 OPEN (output formats only).
- Consequence: local/hierarchical labels inside asm blocks are OUT OF SCOPE — #120 publishes that
  capability and the exclusivity rule is existence-based. Keep `src/expr/parser.rs` changes
  minimal to stay clear of #127.
- Open issues informing (not binding) the design: #247, #172, #170 all describe substitution
  scoping and evaluation gaps. Feature scope was invented, not taken from an issue.
- Maintainer philosophy: no decline for this feature class. #247's answer documents the current
  single-bare-name restriction as a limitation, not a design principle.

## Gate status

| Gate | Status |
|---|---|
| Repo stars / license / activity | PASS — 1052, Apache-2.0 read from file, 34 commits in 12mo |
| Saturation + our quota | PASS — customasm absent from SATURATED-REPOS.md and all local dirs |
| Baseline determinism (Gate 9) | PASS — 691 tests, 3 runs identical, 0.26-0.28s |
| Gate 1 behavioral-f2p-gap | PASS — reproduced on base, table above |
| Gate 5 cold-not-live | PASS — 0 commits in trailing 90d; last commit 2026-04-13 |
| Gate 7b exclusivity | PASS — see audit above; re-run before submit |
| Gate 8 defined-behavior | PASS |
| **LOC floor** | **FAIL** — built and measured: Counter 2 = 167, Counter 1 = 206, **1 file**. Floor is 200 eff / 2 files. See "Blocking outcome" below. |
| Flakiness (3x base + 3x new) | PASS — identical counts and byte-identical JUnit XML across 3 runs each |
| f2p both apply orders | PASS — base 691/691 always; new 28/31 fail on base, 31/31 pass with solution |
| Trap reproduction (HARDENING 3a.4) | PASS — all three reproduced; trap 2 bit the reference itself (8 base failures) |

## Risks

1. **LOC.** The blocking one. Lever 1 (nested asm blocks inside a brace expression) is the
   reserved fix; build-measure before committing to it.
2. **Partial oracle for trap 1.** `resolve_once` already rebinds labels per iteration, which may
   hand a strong agent the deferral pattern. Traps 2 and 3 are independent of that loop, so the
   design does not rest on trap 1 — but confirm against the first batch's passing patches
   (HARDENING 3e capture protocol).
3. **Dormant repo.** 0 commits in 90d clears the >= 1-in-12-months gate comfortably, but re-verify
   the real last-commit date at submit (the mun lesson).


## Blocking outcome (measured, not predicted)

The feature was implemented end to end and is correct: 722/722 tests pass, both apply orders and
reverse-apply are clean, the flakiness gate is green, and the f2p is sharp. **It is still not
submittable as an Olympus problem**, on two hard gates:

| Gate | Required | Measured |
|---|---|---|
| Effective LOC (Counter 2) | >= 200 | **167** |
| Files modified | >= 2 | **1** |

Counter 1 (the looser platform auto-block measure) is 206, so the auto-block would not fire, but
Counter 2 is the binding number and it is short by 33.

**Root cause: the design-time sketch was wrong in a specific, recordable way.** The sketch
predicted ~318 meaningful across 5 files. The real implementation came in at 167 across 1 because
almost every piece I costed separately was absorbed by machinery that already existed:

- `$` / pc threading: costed 24, actual ~0. `inner_ctx` already carried the per-instruction
  position, so passing it to the deferred evaluator was one argument.
- Nested `asm` blocks: costed 36, actual 0. `Expr::Asm` already evaluates through
  `asm::resolver::eval`, so nesting worked with no code at all.
- Guess propagation: costed 42, actual ~20. `handle_value_resolution` and `ResolutionState::merge`
  already existed and did the whole job.
- Error span mapping: costed 27, actual 0. The walker is already built with the original file
  handle and line offset, so spans were correct without intervention.

This is the fundsp ORACLE law arriving on the LOC axis rather than the difficulty axis: the
partial oracle I flagged in DESIGN.md as a difficulty risk turned out to be a much stronger and
more general oracle than estimated, and it collapsed the implementation size. The DESIGN.md
warning named `resolve_once`'s per-iteration label rebinding; the reality is that the entire
resolver stack is reusable.

**What I did NOT do:** pad. Adding a public API surface or an adjacent capability (`#d` data
directives inside asm blocks was the tempting one) to reach 200 is the participle `Greedy()`
scope-creep failure and HARDENING 3d's "never pad LOC with public API". The honest position is
that this feature is a ~170-LOC change and no amount of packaging alters that.

**Options, in order of my preference:**

1. **Shelve to `rejected/` and record the lesson.** The pick is correct, fair, hard, and
   non-derivative but intrinsically sub-floor. This is the taffy/geo LOC-CEILING class.
2. **Re-scope onto a genuinely larger customasm capability** and reuse this work as one component.
   The candidate with real size is relocatable output plus linking (issue #48 informs it): new
   directives, a symbol-relocation model, output-section assignment, and resolver integration.
   That is a different feature, so it needs its own DESIGN.md and its own SIX-CHECK.
3. **Ship as-is knowing it fails two hard gates.** Not recommended.

## Tightening pass (HARDENING + TOO-EASY re-read)

Three changes, all doctrine-driven. None moved the LOC floor; two moved difficulty.

**1. Rule-7 de-enumeration of meta.md (HARDENING 3b, the CHECKLIST-META law).** The description
was a checklist: it enumerated block labels, "labels that appear after the instruction", the
program counter, nested asm blocks, and two error classes. fundsp measured enumerations producing
100% then 90% pass. Replaced the whole enumeration with one principle:

  "The expression is evaluated where it stands. It sees the same names an instruction written in
   that position would see, and it resolves them against the layout the block itself produces."

285 words -> 176. Forward labels, `$`, outer symbols and rule parameters are now consequences the
solver derives rather than a list it transcribes.

**Fairness proof for the de-enumeration (this is what makes it legal, not just shorter).**
Verified on the UNMODIFIED base binary that an unbraced operand inside an `asm` block already
resolves a forward label and `$`:

    seq => asm { emit later
                 later:
                 emit later }   ->  10 02 10 02
    pcs => asm { emit $ }       ->  10 04

So "the same names an instruction written in that position would see" genuinely entails both, and
an agent can confirm it against base behavior. No hidden requirement was created.

**2. Removed an error-message substring pin (HARDENING 3d, the data-forge no-substring-pins law).**
`err_non_integer_value` pinned "invalid type for substitution", a message *I* invented that no
natural solution would reproduce. The harness matches error kind + line with an empty excerpt, so
the fixture now asserts that it fails at the right place without pinning wording. All other pinned
substrings are pre-existing repo messages ("expected identifier", "expected `}`", "unknown
substitution argument", "unknown symbol", "recursion depth", "did not converge") and are fair.

**3. Recorded a free S5 dual-path gate found while reviewing the harness.** `src/test/file.rs:190`
runs EVERY fixture twice: variant `00` (`optimize_instruction_matching` and
`optimize_statically_known` both false) and variant `11` (both true). Every fixture is therefore
already a dual-path consistency check, and a failure names the VARIANT, not the cause. This was
not designed in; it comes free with the repo's harness and it strengthens the trap set at zero
authoring cost.

**What tightening did NOT fix.** Counter 2 is still 167 across 1 file. Difficulty levers do not
manufacture LOC, and HARDENING 3d ("never pad LOC with public API") forbids the obvious workaround.
The floor verdict is unchanged.
