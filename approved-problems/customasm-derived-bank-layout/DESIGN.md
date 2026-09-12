# DESIGN.md — customasm-derived-bank-layout

Base: `05c738138eea73fb1f8ff595cdc9b58fd35bad91` (hlorenzi/customasm v0.14.1, 2026-09-05)
Source: hunt 2026-09-06 RANK 1 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-06.md`)

## 1. Title

**Add derived bank placement to the assembler's iterative resolver**

Verb `Add` -> Category `feature-request`. Names the subsystem (the iterative resolver) rather than
the directive.

## 2. Shape classification

- **Shape:** O-Pipeline-hard (`SHAPES.md § Pattern 12`) — a new quantity that must cascade through
  an existing multi-stage pipeline, where the algorithm for making it converge has to be invented.
  Not O-Composite-add: no new subsystem is bolted on; an existing single-pass stage is promoted
  into the fixpoint.
- **Pass-rate target:** 10-25%. Ceiling is 40% (sprint), 0% is a reject.
- **Best agent:** Orion (long-horizon; SPEED-CORRELATES-WITH-FAILURE applies — this needs a full
  read of the resolver before a line is written).
- **Dominant verdict predicted:** MISSED_REQUIREMENT, with a REGRESSION tail from the shared
  address chokepoint.
- **Solver/our LOC ratio:** ~1.1x (O-Pipeline-hard band).

## 3. Public API surface

customasm's public surface is its directive/expression language, not Rust symbols. Exactly these
names are asserted by tests:

- `used` — member on the value `$bankof(...)` returns. Address units the bank's contents actually
  occupy, counted from the bank's start to the furthest point its cursor reached.
- `end` — member on the same value. The address one past the last unit the bank occupies, i.e.
  `addr + used`.
- `addr`, `size`, `outp`, `addr_end` — EXISTING `#bankdef` fields, whose accepted expression class
  widens: they may now reference labels and other banks' `used`/`end`.
- `#bankdef` — existing directive, unchanged syntax.
- Error text keywords asserted by substring, never whole-message:
  - `cannot be resolved` — a bank field never settles (circular placement).
  - `overlaps` — EXISTING message from `output::check_bank_overlap`, now reachable with derived
    values.
  - `outside the supported range` — EXISTING, negative or oversized derived placement.

No new directive, no new builtin function, no new CLI flag. The whole feature is a widening of what
the existing fields accept plus two members on an existing struct value.

## 4. Canonical output form

- **`used` counts from the bank's own start**, not from address zero, and is measured in the bank's
  address units (`bits`), matching `size`.
- **`used` is the FURTHEST point reached, not the number of units written.** A `#addr` directive
  that jumps forward inside the bank raises it; a later jump backwards does not lower it. Content
  written after a backward jump does not add to it.
- **An empty bank has `used` of zero, and `end` equal to `addr`.**
- **`end` is exclusive** — one past the last occupied unit — so a bank placed at another's `end`
  begins on the first free unit.
- **`#res` counts.** Reserved space occupies units and raises `used`, even though it emits nothing.
- **`used` ignores `#fill`.** Filling to the declared size is an output-stage concern; `used`
  reports content extent.
- **Resolution order is not declaration order.** A bank field is resolved when its dependencies
  are, in the same iterative pass that resolves labels and instruction encodings.
- **Non-convergence is an error, not a silent settle** — same treatment the resolver already gives
  instruction encodings that never stabilise.
- **Overlap is judged on final resolved values**, in output space, exactly as today.

## 5. Blind-spot pre-empts (`DESCRIPTION.md` sentence bank)

| Blind spot | Sentence placed in meta.md |
|---|---|
| Iteration termination | "resolved in the same iterative pass that settles labels and instruction encodings, and a placement that never settles is reported the way an unsettled encoding already is" |
| Result/extent semantics | "the furthest point its contents reached, measured from the bank's own start" |
| Unstated inverse | "moving the cursor backwards does not lower it" |
| Falsy/empty case | "a bank holding nothing reports zero" |
| Adjacent-vs-all | "reserved space occupies units like any other content" |

Codebase-inferable requirements: **1** (that `used`/`end` are in address units like the existing
`size` member — inferable from `eval.rs:466`). Within the <=1 budget.

## 6. Description draft (target <=200 words)

> Add derived bank placement to the assembler. A `#bankdef` field is evaluated once, before any
> address exists, so a bank can only be positioned at a literal or a constant; there is no way to
> put one where another bank's contents actually ended.
>
> Let the fields `addr`, `addr_end`, `size` and `outp` hold expressions that depend on the result of
> assembling, and resolve them in the same iterative pass that settles labels and instruction
> encodings. A placement that never settles is reported the way an unsettled encoding already is.
>
> Report what a bank actually occupies through two members on the value `$bankof` returns. `used` is
> the furthest point its contents reached, measured from the bank's own start in its address units;
> `end` is the first address past that point. Reserved space occupies units like any other content.
> Moving the cursor backwards does not lower either. A bank holding nothing reports zero, and its
> `end` is its own start.
>
> Banks placed this way are ordinary banks: they are checked for overlap and written to the output
> exactly as declared ones are.

Word count target ~190. Rule-7 compliant: states the PRINCIPLE ("resolve them in the same iterative
pass"), never the instance list of what may depend on what, and never how to sequence the passes.

## 7. File footprint (sketched against real source at base)

| Action | Path | Cur LOC | Raw delta | Meaningful (x0.65) | Reason |
|---|---|---|---|---|---|
| NEW | `src/asm/resolver/bankdef.rs` | — | +150 | 98 | Resolve bankdef fields per iteration; merge `ResolutionState`; detect never-settling placement |
| MODIFY | `src/asm/defs/bankdef.rs` | 208 | +120 | 78 | Split shape-definition from field-resolution; fields become deferrable instead of `eval_certain` |
| MODIFY | `src/asm/resolver/iter.rs` | 566 | +70 | 46 | Track per-bank furthest extent; propagate an unresolved bank start into `cur_position_resolved` |
| MODIFY | `src/asm/resolver/mod.rs` | 418 | +50 | 33 | New `ResolverNode::Bankdef` arm + dispatch |
| MODIFY | `src/asm/defs/mod.rs` | 206 | +40 | 26 | `Bankdef` field types carry resolution state; per-bank extent storage |
| MODIFY | `src/asm/resolver/eval.rs` | 470 | +45 | 29 | `used` / `end` members; drop the blanket `statically_known()` for derived members |
| MODIFY | `src/asm/output/mod.rs` | 365 | +60 | 39 | Overlap + build against resolved values; error when a placement is still unresolved at output |
| **TOTAL** | **1 new + 6 modified** | | **+535** | **~349** | |

Floor check (2026-07 sprint): **>=200 meaningful, >=2 files** -> sketch clears at ~349 across 7
files, a ~75% buffer over the floor.

### ⚠️ ORACLE-ABSORPTION AUDIT (mandatory in this repo — `TOO-EASY.md § customasm`)

The shelved `customasm-asm-block-expr-substitution` sketched 318 meaningful and measured **167**,
because 4 of 8 line items were already done by the surrounding stack. Per-item check, answering
"does the repo already do this for a sibling construct?":

| Line item | Already done? | Kept in estimate |
|---|---|---|
| Parse a new bankdef field | **YES** — `parser/fields.rs` is generic (`name = expr`), a field costs ~5 lines | dropped to ~0; design adds NO new field |
| Report a diagnostic with a span | **YES** — `diagn::Report` | ~8 lines each, counted as such |
| Overlap detection | **YES** — `util/overlap_checker.rs` | only the re-ordering counted |
| Propagate "position not yet known" | **PARTLY** — `BankData::cur_position_resolved` exists but only tracks content, never the bank START | half counted |
| Merge a per-node resolution state | **YES** — `ResolutionState::merge` | ~0 |
| Defer a bankdef field out of `eval_certain` | **NO** — every field is `eval_certain` at `defs/bankdef.rs:60-190` | full |
| Per-bank furthest-extent tracking | **NO** — nothing in the tree computes it | full |
| A resolver node kind for bankdefs | **NO** — `ResolverNode` has None/Symbol/Instruction/DataElement/Res/Align | full |
| Non-convergence for a non-instruction quantity | **NO** — only encodings have it | full |

Five of nine items are genuinely absent, and they are the large ones. **Independent corroboration:
the maintainer states the machinery does not exist** — hlorenzi on issue #195 (2025-10-05): *"There's
still no way to get the 'first free' address, though, since the assembler's infrastructure doesn't
quite work that way, so that would require more engineering to make possible."*

## 8. Solution outline — helpers, one per described behavior

```
resolver/bankdef.rs
  resolve_bankdef(report, opts, fileserver, bankdef_ref, decls, defs, ctx) -> ResolutionState
      <- "resolve them in the same iterative pass"
  eval_bank_field(report, opts, ..., field, ctx) -> Option<BigInt>        <- deferred field eval
  check_bankdefs_settled(report, decls, defs) -> Result<(), ()>           <- "never settles is reported"

resolver/iter.rs
  BankData::note_extent(&mut self, position)                              <- "furthest point reached"
      max-accumulate; a backward #addr cannot lower it
  bank_start_is_known(defs, bank_ref) -> bool                             <- gates cur_position_resolved

defs/bankdef.rs
  BankdefFields::from_ast(...)         <- keeps the AST exprs instead of collapsing to values
  BankdefFields::try_resolve(...)      <- certain fast path preserved for literal fields

resolver/eval.rs
  bank_used_units(defs, bank_ref)  -> Option<usize>     <- `used`
  bank_end_address(defs, bank_ref) -> Option<BigInt>    <- `end` = addr + used
```

**Fixpoint shape** (the resolver already owns the loop; the feature joins it):

```
// inside resolve_once, before the node walk
for bank_ref in defs.bankdefs.refs() {
    resolution_state.merge(bankdef::resolve_bankdef(..., bank_ref, ...)?);
}
// extents are re-accumulated from zero each iteration, never carried across
```

Extents MUST be reset per iteration — a max-accumulator carried across iterations is monotone and
cannot shrink when a size shrinks, which silently freezes a layout that should still be moving.
This is a designed trap (T2 below), not an implementation note for the description.

## 9. Test file outline

Fixture-driven, matching the repo exactly: directories under `tests/`, each `.asm` carrying
`; = <hex>` expected-output lines or `; error: <substring>` markers, discovered by
`src/test/file.rs`. **Every fixture runs twice** (variants `00` and `11` of
`optimize_instruction_matching` / `optimize_statically_known`, `src/test/file.rs:190`) — a free S5
dual-path consistency check on every test, whose failures name the VARIANT, not the cause.

New directories (random hex suffix on the Rust test-registration file only; fixture dirs follow repo
convention):

```
tests/bank_derived/          ok_*.asm / err_*.asm
tests/bank_extent/           ok_*.asm / err_*.asm
```

Buckets, decomposed per ATOM not per sentence:

| Bucket | Tests | Atoms |
|---|---|---|
| `used` basics | 8 | empty bank = 0; one instruction; several; `#res` counts; `#fill` does not; units follow `bits`; measured from bank start not zero; `end == addr + used` |
| Backward/forward cursor | 6 | forward `#addr` raises; backward `#addr` does NOT lower; content after a backward jump does not add; `#align` raises; the NEGATIVE of each |
| Derived placement | 10 | `addr` from another bank's `end`; `outp` derived; `size` derived; `addr_end` derived; chain of three banks; derived value used by a label; forward reference into a derived bank |
| Convergence | 6 | two banks each placed after the other -> `cannot be resolved`; self-reference; a placement that settles only on iteration 4; a size that shrinks between iterations (the reset trap) |
| Interaction with existing rules | 8 | overlap of two derived banks -> `overlaps`; derived vs declared overlap; negative derived addr -> range error; `#if` removing content changes `used`; `$bankof(label).used` inside an instruction operand |
| Baseline preservation | 6 | every existing bankdef form still assembles byte-identically; `size`/`size_b`/`addr`/`outp`/`data` members unchanged |
| **Total** | **~44** | |

5-axis coverage: every atom in meta.md; every new member and widened field; every solution branch
(certain fast path / deferred path / unresolved / non-convergent / reset); edge cases (empty, zero,
single, boundary, backward, conditional-compilation-removed); stated inverse (backward jump).

## 10. Forced trait bounds / signatures

Rust, but the solver-visible surface is the assembly language, so there is no public Rust signature
to guess -> **the C5 compile-wipe fairness hazard does not apply here** (`failure-patterns.md` C-5).
The only forced internal shape is that `Bankdef` fields can no longer be plain `usize` / `BigInt`;
any correct implementation must carry resolution state. That is discovered, not guessed, and it is
not asserted by any test.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis measured | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | **Two-pass placement.** The natural implementation assembles once to measure extents, then places banks, then re-assembles. Wrong when a bank's content size depends on a label in a bank placed later, because the measuring pass ran against a layout that no longer holds. | **F-1** (convergent-architecture wall) | S4 machinery-riding | *when* placement is computed | #2, #3 — all three ride the one fixpoint | The pipeline invites it: `matcher::match_all` and `defs::define_symbols` already run once before `resolve_iteratively`, so "one more pre-pass" matches the surrounding style | "resolved in the same iterative pass that settles labels and instruction encodings" — states WHEN, never how to restructure | `ok_forward_ref_into_derived_bank`, `ok_three_bank_chain` |
| 2 | **Monotone extent carried across iterations.** `used` is a max-accumulator; carrying it between iterations makes it unable to shrink, so a layout that should keep moving freezes at a stale value and the run converges on a wrong answer. | **F-2** (bidirectional seam) | S1 speculative-state isolation | *lifetime* of derived state | #1 (same loop), #3 (feeds the guard) | Reset-per-iteration is invisible unless you reason about shrinking; every natural fixture grows | none — the contract says `used` is the furthest point reached, and says nothing about iteration state (CONTRACT-STATED / FIX-HIDDEN holds) | `ok_size_shrinks_between_iterations` |
| 3 | **`statically_known()` copied onto a derived member.** `eval.rs:463-468` marks every existing bank member `.statically_known()`. A derived `used`/`end` is not statically known until the fixpoint settles; copying the neighbouring line bakes a first-iteration guess into an encoding. | **F-9** (cross-stage resolution drop) | S6 two-evaluators | *which stage* trusts the value | #1, #2 | It is literally the adjacent line of code, six times over; and the repo's own history shows this is subtle (`fix #242 track resolution state of all values`, `fix #246 restore encoding size guesses`) | none needed — no sentence describes value metadata | `ok_bank_used_in_operand`, `ok_derived_addr_settles_late` |
| 4 | **Extent noun ambiguity.** "What a bank occupies" reads naturally as *bytes written*; the contract means *furthest point reached*. They coincide on every simple fixture and diverge on `#res`, on `#addr` jumps, and on `#fill`. | **F-13** / L24 (format-noun extent) | A8 boundary inversion | *definition* of the measured quantity | — (independent, by design) | The natural-language reading is the local one; L24 measured 6/10 on exactly this shape | "the furthest point its contents reached" + "reserved space occupies units like any other content" | `ok_res_counts`, `ok_backward_jump_keeps_extent`, `ok_fill_excluded` |

**Interdependence check:** traps 1-3 share the fixpoint chokepoint — a local fix to any one surfaces
the next (fix the two-pass and you meet the monotone accumulator; fix that and the stale
`statically_known` bakes a guess). Trap 4 is deliberately INDEPENDENT, which is the L20 insurance:
customasm's own accepted problem was bimodal because one seam gated every killer, and its kill table
showed perfectly correlated failures. Trap 4 fails on different fixtures than 1-3 and gives the
batch a second, uncorrelated cluster.

**L34 (fairness disclosure is a difficulty debit):** trap 4's pre-empt sentences are already written
into the meta draft in section 6, so the disclosure is paid up front, not later.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = **which field is derived** (address space vs output space).
Axis 2 = **what the derivation depends on** (a bank that precedes it vs a bank that follows it).

| | depends on an EARLIER bank | depends on a LATER bank |
|---|---|---|
| **`addr` derived** | `ok_addr_after_earlier_bank` | `ok_addr_from_later_bank` **<- off-diagonal** |
| **`outp` derived** | `ok_outp_packed_after_earlier` | `ok_outp_from_later_bank` **<- off-diagonal** |

Both off-diagonal cells are required. Predicted failure mode is OVER-firing: a two-pass
implementation resolves the forward case by ordering banks topologically and silently produces a
stale address for the backward one, rather than failing outright.

Third axis available if the batch reads soft: **content present vs bank empty** — an empty bank's
`end` equals its `addr`, so a chain through an empty bank is the composition cell.

Scope audit: `used` is scoped to ONE bank, never to the program. Stated explicitly ("from the bank's
own start"). Format-noun audit: `used`, `end`, `content`, `bank` — all four get an extent sentence in
section 6. Tolerance audit: no "allow one, stop at the second" rule in this design, so L25 does not
apply; the convergence limit is the resolver's existing `max_iterations`, whose behaviour is
unchanged.

## 12. Tier + category

- **Tier:** Olympus (single tier).
- **Sub-rank target:** Good — 7 files, ~349 meaningful, 4 traps with an S-tier lead.
- **Category:** `feature-request` (title verb `Add`, net-new capability + two new value members).

## 13. Predicted pass rate

**Predicted 10-25%.** Reasoning: the lead trap is an architectural-timing wall (F-1 family, the
largest lever measured), it is interdependent with two others through one chokepoint, and the
independent fourth trap supplies an uncorrelated cluster. Against that, the contract is short and
every requirement is stated, and steroid-era agents transcribe stated contracts well — which is why
the estimate is not lower.

Solvability argument (0% is a reject): the resolver already exposes the exact pattern to copy —
`resolve_constant` and `resolve_instruction` are per-node functions returning a merged
`ResolutionState`, and `ResolutionState::merge` is public. An agent that reads `resolver/mod.rs`
before writing sees the shape it must follow. That is a real, reachable path, which is what L18 asks
for.

⚠️ **Budget note:** at 24 tokens/run for Orion with Nova locked, a 10-run batch is ~240 tokens and a
10% design is statistically hard to distinguish from 0%. If the first batch reads 0/10, the response
is `HARDENING § 3c-bis` step 3 (name the ROOT CAUSE — that placement participates in the existing
convergence loop — never the fix), not a redesign.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (section below)
- [x] Existing-PR check: all 43 PRs enumerated, every state; none touches placement, extent, or
      deferred bankdef fields. Commands in the Phase 2 record below
- [x] Publicly-solved check: issue BODIES + all comments read on #48, #121, #67, #195, #179, #225
- [x] Closest approved opened side-by-side: `approved-problems/customasm-ruledef-disassembly`
- [x] Title verb-led, 6 words, names the resolver
- [x] Shape declared with SHAPES citation
- [x] API surface lists every asserted name (`used`, `end`, the four widened fields, 3 error keywords)
- [x] Canonical form spelled out (section 4, nine rules)
- [x] 1 codebase-inferable requirement (<=1)
- [x] Description draft ~190 words, plain prose, no headers, no labels, no `Box<>`
- [x] File footprint sketched against real source with line citations
- [x] Meaningful LOC ~349 >= 200 floor, 7 files >= 2
- [x] 1+ pure-function helper per described behavior (section 8)
- [x] Fixpoint shape included
- [x] Test outline 4-block/fixture layout, scenario-encoded names
- [x] 5-axis coverage planned
- [x] Forced signatures: none solver-visible (C-5 hazard absent)
- [x] 4 traps, each with F-id, pre-empt, catching test
- [x] Traps on different axes; 1-3 interdependent; 4 deliberately independent (L20 insurance)
- [x] § 11b cross-product filled, both off-diagonal cells have tests
- [x] **Sibling-API audit (F-20): RESOLVED — the axis is UNAVAILABLE, do not count on it.** F-20
      needs an existing public behaviour that is documented but has NO repo test. `tests/fn_builtin/bankof/`
      holds 7 fixtures already asserting the sibling members (`addr` x5, `data` x8, `bits` x2,
      `outp` x2, `size` x2, `size_b` x2, plus `err_invalid` / `err_unknown`). The agent's own green
      baseline WILL warn them, so the seam is closed. Recorded rather than assumed.
- [x] **F-18 form-parity audit: RESOLVED — the axis is LIVE and is now a required test rule.** Both
      spellings are real and both are exercised by the existing suite: 56 fixtures use `#addr` (the
      hash form) and 11 use `addr =` (the modern form), and `parser/fields.rs:31-49` treats them as
      one rule. This is the gluon shape verbatim (7/11, 22 of 37 kills) and it costs ZERO description
      words beyond the single equivalence the parser already implements. **Rule for Step 3: every
      position tested with `addr = <expr>` is also tested with `#addr <expr>`, in both the derived
      and the extent buckets.**
- [x] Format-noun extents stated (section 11b)
- [x] Tolerance rule: none in this design (L25 N/A)
- [x] Predicted Wrong Logic <25%
- [x] Predicted pass <=40% ceiling
- [x] Category matches the description verb
- [x] Not pattern-followable: `ResolverNode` has no existing bankdef arm; no sibling to copy
- [x] **F-12 audit: RESOLVED — axis unavailable.** `grep -rl '#[cfg(test)]' src/` returns only
      `src/lib.rs`; none of the seven files this feature touches carries an inline test module, so
      there is nothing for the feature to invalidate and no base-mode skip decision to make.

---

## Phase 1 — Repo understanding (HARD GATE, 5/5)

**Architecture in one paragraph.** customasm assembles a program against an instruction set the
user declares in the same source language. It parses to an AST, collects declarations, builds
definitions, matches each instruction line against the declared `#ruledef` rules, then resolves
addresses and encodings to a fixed point, then emits bytes in one of ~15 output formats. The
central difficulty of the codebase is that instruction ENCODINGS can change size depending on
operand values, which depend on label addresses, which depend on preceding encodings — so
`resolve_iteratively` runs the whole program repeatedly until nothing changes.

**Five subsystems + boundaries.**
1. `src/syntax` (1510) — tokens, walker, excerpts.
2. `src/expr` (3185) — expression AST, evaluator, builtin functions, values.
3. `src/asm/parser` (~1500) — one file per directive, plus generic `fields.rs`.
4. `src/asm/{decls,defs,matcher,resolver,output}` (8610) — the assembly pipeline.
5. `src/util` (3553) — bigint, bitvec + the 15 output formats, symbol manager, overlap checker.

**Three high-entanglement zones.**
1. `resolver/iter.rs` — every node's address flows through `advance_address`; `BankData` is the
   per-bank cursor and `ResolverContext` hands `bank_ref` + `bank_data` to every resolve function.
2. `resolver/mod.rs::resolve_once` — the node dispatch every quantity must merge its state into.
3. `asm/mod.rs::assemble` (lines 144-260) — the stage ordering: a pre-iteration loop
   (decls/defs/constants/`#if`) then `match_all` then `resolve_iteratively` then
   `check_bank_overlap` then `build_output`.

**Test framework + location.** `src/test/file.rs` walks `tests/<dir>/*.asm` fixtures; `; = <hex>`
lines are expected output, `; error: <substring>` marks an expected diagnostic at that line. 708
tests, 1.80s, deterministic 3/3 measured locally.

**Formatting template cited.** `tests/bank_simple/ok_two_banks.asm` — two bankdefs, `#bank`
switches, trailing `; = ...` expected-output block.

## Phase 2 — GitHub audit record

```
CANON=$(gh api repos/hlorenzi/customasm -q .full_name)     # hlorenzi/customasm, no redirect
gh pr list -R "$CANON" --state all --limit 100             # 43 PRs, ALL enumerated by title
gh issue list -R "$CANON" --state open --limit 40          # 36 open issues, all titles read
gh issue view {48,121,67,195,179,225} -R "$CANON" --json body,comments   # bodies + every comment
```

**Result: no PR, in any state, implements bank placement, bank extent, or deferred bankdef fields.**
The only two open PRs are #127 (string encoding suffixes, 2021) and #98 (CLI crate split, 2021);
neither touches `src/asm/defs/`, `src/asm/resolver/` or `src/asm/output/`.

**Publicly-solved check — findings that SHAPE this design:**

- **#195 (OPEN, 2024-01-09) is the load-bearing evidence and also the main risk.** The reporter
  wants a bank's first-free address. Maintainer reply 2025-10-05: `bankof()` shipped in v0.13.12 for
  `addr`/`size`, *"There's still no way to get the 'first free' address, though, since the
  assembler's infrastructure doesn't quite work that way, so that would require more engineering to
  make possible."* This CONFIRMS the machinery is absent (absorption test) and CONFIRMS maintainer
  philosophy is favourable (Gate 8). It is also a visible open request, so it carries derivative-
  magnet risk — mitigated by the capability here being placement + resolution, not the read-only
  symbol the issue asks for.
- **#225 (CLOSED, shipped) — `$bankof()` and struct values already exist.** Verified on the base
  binary: `$bankof(here).addr` and `.size` work, `bankof` without `$` does not. So this design ADDS
  members to an existing value rather than inventing a builtin. The existing member table is
  `resolver/eval.rs:461-470`.
- **#48 (OPEN, linking) — DEMOTED, not used.** Two published design sketches in-thread
  (`theorzr`'s `#obj <format>`, `Phlosioneer`'s full `#external` design) plus the maintainer moving
  the discussion to Discord. Stage-2b magnet. This design deliberately does not touch external
  symbols or object files.
- **#121 — maintainer reserves rule-selection ordering for "future optimizations".** Not touched.

## Reproduce-on-base (Gate 6) — run against the release binary at BASE_COMMIT

| Probe | Base behaviour | Meaning |
|---|---|---|
| `#bankdef b { addr = A_END }` where `A_END = a_last` (a label in bank a) | **`error: unresolved symbol A_END`** | The f2p gap. Bank fields are `eval_certain` at `defs/bankdef.rs:60-190`, inside the pre-iteration loop, before any address exists |
| `$bankof(here).size` | returns the DECLARED size (`0x10`) | No used-extent quantity exists anywhere |
| `#bankdef code { bits = 8, size = 0x10, outp = 0 }` with no `addr` | assembles, addr defaults to 0 | Omitting `addr` is NOT an error today, so the feature must be opt-in through the expression, not through omission |
| cross-bank forward reference `jmp target` | resolves in 2 iterations | The address fixpoint already handles forward references — the machinery to join exists |

## Why this is not a duplicate

Closest two in `approved-problems/`:

1. **`customasm-ruledef-disassembly`** (same repo, ACCEPTED, 493 eff, F-11 lead). That pick INVERTS
   the matcher — bytes back to instructions — and lives entirely in `matcher/` plus a new decode
   subsystem. This one touches no matcher code and no ruledef semantics; it changes WHEN bank fields
   are evaluated and adds an extent quantity. Different subsystem, different capability.
2. **`avo-register-spilling`** (different repo, resource allocation under exhaustion). Nearest
   capability-level neighbour anywhere in the corpus. Different domain (Go assembler register
   allocator), different mechanism (spill-on-exhaustion vs converge-a-layout), no shared vocabulary.

Also cleared against `rejected/customasm-asm-block-expr-substitution`: that widened brace
substitution inside `asm{}` blocks, one file, `resolver/eval_asm.rs`. No overlap.

**Predicted iteration cycles: 3** (an O-Pipeline-hard with an invasive reference; the sprint band is
3-5 for Olympus).

## Audit results folded in (2026-09-06)

| Audit | Verdict | Consequence for Step 3 |
|---|---|---|
| F-20 sibling-API | **unavailable** — siblings already tested by 7 fixtures | Do not plan a leak-guard trap; the batch cannot pay for it |
| F-18 form parity | **LIVE** — 56 `#addr` vs 11 `addr =` fixtures, one rule two spellings | **Mandatory:** duplicate every derived/extent position across both spellings |
| F-12 inline tests | unavailable — only `src/lib.rs` has `#[cfg(test)]` | No base-mode skip decision needed |
| Docker / edition 2024 | **verified** — rustc 1.95.0, builds in 20.46s in the base image | Pattern A verbatim |

Net: one designed axis (F-20) is closed and one free axis (F-18) opens in its place, so the trap
count is unchanged at four with F-18 as a fifth, no-cost breadth lever.

## Open items before Step 2 (carry into implementation)

1. F-18 form-parity: test every position in BOTH `#addr 5` and `addr = 5` spellings (now mandatory).
2. Write the natural-but-wrong implementation FIRST and confirm each of traps 1-3 actually bites
   with a misdirecting symptom (`HARDENING § 3a` step 4). A trap not reproduced is a guess.
3. ~~Confirm `olympus-base-rust` ships rustc >= 1.85~~ — **DONE, and Docker feasibility is VERIFIED
   rather than estimated.** `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` ships
   **rustc 1.95.0 / cargo 1.95.0**, well past the 1.85 that stabilised edition 2024. The repo was
   built inside that image against this exact base commit: `cargo build --workspace` finished
   in **20.46s** with only `getopts` + `num-bigint` + their two transitive deps compiled, no system
   libraries. Dockerfile will be canonical Pattern A verbatim (no `ENV`, no `chmod`, no `--tests`).
4. Decide base-mode scope: expect none needed — the feature should leave all 708 existing tests
   green, and any that flip is trap 3 firing on my own reference.


## Build-round addendum (2026-09-07) — deviations from the sections above

- Section 3: error keyword is `did not converge` (existing resolver text), not `cannot be resolved`.
  Circular placement emits four such errors (two bankdefs + two start labels); the harness needs an
  exact message count so the fixture lists all four.
- Section 4/6: two rules added to the contract: `used` rounds a partial address unit up; `$` inside a
  bank definition stays rejected (keeps `bank_simple/err_address_ctx` live as a base-mode
  discriminator).
- Section 7: actual footprint 551 human-effective across 9 files (defs/bankdef.rs 124,
  resolver/bankdef.rs 297 NEW, iter.rs 59, eval.rs 30, mod.rs 28, addr.rs 6, plus 3 one-liners).
  output/mod.rs needed NO change: layouts are numeric and settled by the time output runs.
- Section 8/11: a fifth mechanism, `settle_bankdefs`, an end-of-pass fixpoint over bank placements
  using the freshly committed extents. Without it every derived link costs one resolver iteration and
  a chain longer than the 10-iteration budget dies with a spurious `did not converge`. Contract
  sentence: "The number of iterations must not grow with the length of a placement chain ...".
  Fixture: 24 banks placed in reverse declaration order (12 was not decisive: walk + one settle round
  already handles two links per pass).
- Section 9: 48 fixtures in `tests/bank_extent_4d1427/` (18) and `tests/bank_derived_c41fad/` (30),
  plus deletion of `bank_simple/err_constants_unresolved{1,2}` (programs now valid; re-added as
  `ok_addr_from_pc_constant{1,2}` with their bytes). F-18 duplication scaled back to two hash-spelling
  fixtures: both spellings are one AST field, so no implementation can diverge on them.
- Section 11 trap 4 (extent noun) got a fifth fixture family: alignment padding inside a derived bank
  depends on the (guessed) start, so `used` of that bank must stay a guess until the start settles.

## Review-round addendum (2026-09-07, Solution Quality FAIL -> fixed)

- The end-of-pass settle loop was not a joint fixpoint: extents were committed once per walk, so an
  extent that depends on a just-settled start (alignment, labelalign, `#addr` offset) lagged one
  outer iteration per chain link. `resolve_once` now alternates walk+commit and a bankdef round until
  no layout changes (bounded by the bankdef count). Trap 1 (two-pass placement) is therefore
  measured, not guessed: the pre-fix reference needed ~n/4 iterations for an n-bank reversed align
  chain; the fixtures use 40.
- `$` rejection became a context flag (`ResolverContext::address_available`) enforced in
  `eval_address`, which makes it transitive through `#fn` bodies and `asm {}` blocks; the description
  sentence is unchanged.
- Test count: 52 fixtures (17 extent + 35 derived).

## Review-round-4 addendum (2026-09-07)

- `defs::bankdef::define` is two-phase: register every bank with an unknown layout, then evaluate
  layouts. Removes any possibility of a layout evaluation observing an unregistered bank.
- `settle_bankdefs` is dependency-ordered. Each bankdef's field evaluation records which banks it
  read (a member-query hook on `Value::Bankdef`); a Kahn ordering over those edges drives a second
  evaluation pass, so an acyclic chain settles in one pass whatever order it was declared in.
  Cyclic components are appended and reach the existing non-convergence report.
- Measured whole-program traversals: 40- and 80-bank reversed placement chains both take 5.
  Alignment chains still cascade (one traversal per link) because a pad depends on the bank's own
  settled start; documented in feedback.md rather than papered over.
