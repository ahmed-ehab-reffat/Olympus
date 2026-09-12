# DESIGN.md — customasm-ruledef-disassembly

Repo: hlorenzi/customasm (Rust, Apache-2.0, 1052 stars)
BASE_COMMIT: c66cb389e7af95ad612520d4766bcb09adfea948

## 0. Why this pick, after the last one died

The previous customasm pick (`rejected/customasm-asm-block-expr-substitution`) was correct, fair,
and hard, but measured 167 effective LOC across 1 file because the existing resolver stack absorbed
four of eight sketched line items. The lesson recorded in `TOO-EASY.md` was ORACLE-ABSORPTION: a
feature that plugs into mature machinery is priced as if that machinery did not exist.

This pick was chosen by running that test FIRST, per line item:

| Line item | Does the repo already do this for a sibling construct? |
|---|---|
| Analyze a rule's output expression into constant bits + parameter fields | **NO** — nothing walks `Rule::expr` for bit layout |
| Bit-directed decode over a byte stream | **NO** — `matcher/mod.rs` is text-directed |
| Recursive subruledef decode from bits | **NO** — the matcher recurses over text, not bits |
| Render a decoded rule back to source text | **NO** |
| Ambiguity policy among candidates | PARTIAL — `resolve_encoding` picks smallest for the ASSEMBLY direction only |
| CLI / driver wiring | PARTIAL — the driver has output-format plumbing |

Four clear NOs. That is the inverse of the last pick, which had four already-solved items.

## 1. Title

Add ruledef-driven disassembly of assembled output

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (SHAPES.md Pattern 12) — a new load-bearing algorithm whose
  difficulty is subtle correctness rather than breadth.
- Pass rate target: <= 40% ceiling, design intent 10-25%
- Best agent: Vega / Orion
- Dominant verdict: WRONG_LOGIC
- Span: `defs` (rule model) + new decode module + `driver` (CLI) + output formatting

## 3. Public API surface

Command-line and behavioral surface, plus the new module's exported names:

- `--disassemble` driver mode: read an assembled binary plus a ruledef source, emit source text
- `RuleDecoding` — the per-rule analysis result: the constant bit pattern, its mask, and where each
  parameter's bits sit
- `analyze_rule_decodability(rule) -> Option<RuleDecoding>` — the inversion analysis
- `disassemble(ruledefs, bytes) -> Result<Vec<DecodedInstruction>, ()>`
- `DecodedInstruction` — address, byte length, rendered text
- error `no rule matches the bytes at ...`
- error `ambiguous decoding at ...`

## 4. Canonical output form

- A rule is **decodable** when its output expression is a concatenation of terms, each term either
  an integer literal of known width or a single parameter used exactly once, optionally with a
  width suffix. Every other rule is skipped for decoding, never an error at load time.
- Field order in the encoding is left-to-right, most significant first, matching assembly.
- A parameter typed as a subruledef is decoded by recursively decoding its field's bits against
  that subruledef's own decodable rules.
- Among candidate rules matching at a position, the one with the **most constant bits** wins. A tie
  between rules that would consume different byte lengths is an ambiguity error naming both.
- Decoded integer operands render in hexadecimal with the same width the field carries.
- Signed parameters render as negative when their top field bit is set.
- Bytes that no rule matches produce an error naming the address, not a silent skip.
- Output is one instruction per line, in ascending address order.

## 5. Blind-spot pre-empts

- Rule-resolution: "the rule with the most constant bits is the one that decodes."
- Result ordering: "instructions are emitted in ascending address order."
- Falsy-on-invalid: rules that are not decodable are skipped rather than rejected.

Codebase-inferable requirements: 1 (that field order matches the assembly direction).

## 6. Description draft (meta.md)

Drafted at Rule-7 de-enumeration level, general principles only, no wall list:

> customasm can assemble a source file against a ruledef but cannot go the other way. Add a
> disassembly mode that takes the same ruledef and a block of assembled bytes and prints the
> instructions they encode.
>
> Not every rule can be run backwards. A rule can be decoded when its output is a concatenation of
> fixed bit patterns and whole parameters, so the bits sit in known places; a rule that computes
> its output some other way is simply not available for decoding, and that is not an error by
> itself. Where several rules could explain the bytes at a position, the one pinned down by the
> most fixed bits is the one that applies, and a genuine tie is reported rather than guessed.
> Parameters that name another ruledef are decoded the same way, from the bits of their own field.
>
> Bytes that no rule explains are reported with the address where decoding stopped.

Target ~180 words.

## 7. File footprint (estimated; MUST be build-measured before tests)

| Action | Path | Raw | Meaningful (x0.60) | Oracle risk |
|---|---|---|---|---|
| NEW | src/asm/disasm/mod.rs | 90 | 54 | none |
| NEW | src/asm/disasm/analyze.rs | 150 | 90 | none — no existing expr bit-layout walk |
| NEW | src/asm/disasm/decode.rs | 180 | 108 | none — matcher is text-directed |
| MODIFY | src/asm/mod.rs | 15 | 9 | plumbing |
| MODIFY | src/driver.rs | 70 | 42 | partial — format plumbing exists |
| MODIFY | src/util/mod.rs or a render helper | 40 | 24 | partial |

TOTAL estimate: **~545 raw / ~327 meaningful across 6 files (3 new)**.

Even discounting 30% for oracle absorption this lands ~230, clearing 200 with 2 files to spare.
**The estimate is not trusted until build-measured** — that is the whole lesson of the last pick.
Build order: `analyze.rs` first, measure, then decide whether `decode.rs` needs the full ambiguity
machinery or can be trimmed.

## 8. Solution outline — pure-function helpers

- `term_width(expr, params) -> Option<usize>` — width of one concatenation term. Requirement: the
  decodable-rule definition.
- `analyze_rule_decodability(rule) -> Option<RuleDecoding>` — flattens the concatenation, assigns
  bit offsets, rejects repeated or computed parameters. Requirement: which rules can be decoded.
- `candidates_at(decodings, bits, offset) -> Vec<&RuleDecoding>` — constant-mask match.
- `select_candidate(candidates) -> Result<&RuleDecoding, Ambiguity>` — most-constant-bits, tie
  reported. Requirement: the tie rule.
- `decode_parameter(param, field_bits, ruledefs) -> Result<DecodedOperand, ()>` — recurses for
  subruledef-typed parameters. Requirement: nested decoding.
- `render_instruction(rule, operands) -> String` — walks `RulePattern`, substituting operands.

## 9. Test file outline

Path: `tests/disasm_<hex>/` following the repo's fixture convention, driven through the CLI with
the existing `; command:` expectation mechanism so tests exercise the real entry point.

Blocks: decodable-rule analysis (which rules are in and out of the subset) · flat decode ·
subruledef recursion · ambiguity and most-constant-bits selection · signed and width rendering ·
unmatched bytes · round-trip (assemble then disassemble reproduces equivalent source) · edge cases
(empty input, single instruction, rule with no parameters, rule that is entirely constant).

The round-trip block is the machinery-forcing test (HARDENING 3a.6): only a real decode passes it,
not a lookup table built from the fixture.

## 10. Forced signatures

- `RuleDecoding` must own its mask and field list; borrowing from `Ruledef` collides with the
  recursive decode holding `&ItemDecls`.
- The analysis must run over `expr::Expr` before any evaluation, so it cannot use
  `asm::resolver::eval` — there is no context and no addresses at decode time. This is the main
  structural difference from every existing code path in the repo.

## 11. Predicted trap matrix

| # | Trap | Class | Why agents hit it | Contract sentence | Catching test |
|---|---|---|---|---|---|
| 1 | **Term width is not syntactic.** `0x10` is 8 bits, `0b1` is 1 bit, `x` is its declared type width, `` x`4 `` is 4. Getting one term's width wrong shifts every later field. | A9 index arithmetic | Agents assume byte alignment or literal-value-derived width | "fixed bit patterns and whole parameters, so the bits sit in known places" | width block + subruledef block |
| 2 | **Parent width depends on which child decoded.** A subruledef parameter's field width varies per sub-rule, so the parent instruction's total length is only known after the child is chosen. | F-2 bidirectional | Agents compute parent length first, then decode fields | "Parameters that name another ruledef are decoded the same way, from the bits of their own field" | subruledef recursion block |
| 3 | **Wrong candidate desynchronizes the stream.** Two rules match the same leading bits with different lengths; choosing wrong makes every later instruction wrong. | A8 precedence inversion | The failure surfaces many instructions later, not at the bad choice | "the one pinned down by the most fixed bits is the one that applies" | ambiguity + round-trip blocks |

Interdependence: trap 1 feeds both 2 and 3 (a wrong width changes both the child field and the
candidate length). Fixing 3 by preferring longer rules breaks 2's variable-width children.

CONTRACT-STATED / FIX-HIDDEN: each contract states WHAT decodes and which candidate wins; none
states how to compute widths, when to recurse, or how to resynchronize. PASS on all three.

## 12. Tier + category

Olympus. Category: **feature-request** (net-new capability and a new CLI mode).

## 13. Predicted pass rate

15-30%. Lower than the previous pick because there is no in-repo oracle to mirror and the base
suite cannot guide the agent toward a subsystem that does not exist yet. Risk of overshoot to 0%
is real if the invertible-subset contract is under-specified; the meta must define the subset
precisely while leaving width computation, recursion and resynchronization undocumented.

## 14. Quality-gate checklist

- [x] Repo understanding established across two picks
- [x] Exclusivity: zero PRs on disassemble / disassembler / decode / reverse, all states
- [x] Maintainer philosophy: issue #30 is FAVORABLE and explicitly proposes this exact scoping
      ("Maybe only for a subset of instructions with simple representations?"), and explicitly not
      a priority, so the subsystem is cold
- [x] Dedup: no local hit in problems/, rejected/, Olympus-Approved/, diamond-problems/
- [x] Death-class guard: not uniform-wrap, not single-subsystem, not spec-hiding, not a saturated
      port (the inverted model is customasm's own arbitrary-expression rule form, not a standard
      instruction encoding)
- [x] ORACLE-ABSORPTION test run per line item, 4 clear NOs
- [x] Traps interdependent + misdirecting, contracts verified fix-hidden
- [ ] **LOC build-measured — NOT YET. Estimate 327; must be confirmed after `analyze.rs` lands.**
- [ ] Traps reproduced against a natural-but-wrong implementation
- [ ] Flakiness gate
- [ ] FP check

## Risks

1. **Scope explosion.** A general disassembler is unbounded. The invertible-subset contract is what
   bounds it; if the build starts growing a general expression solver, stop and re-scope.
2. **Overshoot to 0%.** No in-repo oracle cuts both ways. Mitigation is a precise subset definition
   plus the round-trip test giving agents a self-check.
3. **Derivative risk is low but not zero** — "add a disassembler" is a recognizable idea; the
   defense is that the inverted artifact is customasm's own rule model, not a published ISA.

## Predicted iteration cycles: 3
