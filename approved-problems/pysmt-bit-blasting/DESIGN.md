# DESIGN.md — pysmt-bit-blasting

## 1. Title

Translate bit-vector formulae into Boolean formulae

Repo: https://github.com/pysmt/pysmt (Apache-2.0, 638 stars, last commit 2026-06-10)
Base commit: 9342f1829ab7c1f846e00dca57e20603a38550e0

## 2. Shape classification

- Shape: **O-Algorithm-correctness** (PLAYBOOK Pattern 12): one new evaluation/translation
  mode over an existing engine whose difficulty is subtle semantic correctness across a wide
  operator surface, not scaffolding.
- Pass-rate target: **≤ 40% cap; designed for the corpus mode of ~1/10**.
- Best agent: mixed (Orion/Vega).
- Dominant verdict expected: MISSED_REQUIREMENT (one operator's corner semantics wrong).

Corpus levers stacked (need >= 3, have 6):
1. One interdependent kernel: a single "term -> tuple of Boolean bits" encoder feeds every
   operator, every relation, the symbol map and the model reconstruction. A local fix to one
   operator's bit layout regresses the others.
2. External oracle: SMT-LIB 2.6 bit-vector semantics, cross-checked against pysmt's OWN
   constant-folding simplifier, fuzzed to 0 mismatches before shipping.
3. Misdirecting traps: a wrong shift-overflow guard shows up as a wrong `bvashr` value only
   for shift amounts >= width; a wrong bit order shows up first in `reconstruct`.
4. "Obvious code is wrong" edges: `bvudiv x 0` = all ones, `bvurem x 0` = x, `bvsrem` takes the
   sign of the DIVIDEND, shifts >= width, rotate steps modulo width.
5. De-training: pysmt is a niche academic library; the feature does not exist in it and no
   PR/issue proposes it.
6. Long horizon: new module + rewritings integration, ~25 operators, 3 public surfaces.

## 3. Public API surface

In new module `pysmt/bitblast.py`, re-exported from `pysmt/rewritings.py`:

- `BitBlaster(environment=None)` — class, sibling of `CNFizer`/`NNFizer`/`AIGer`.
- `BitBlaster.convert(formula) -> FNode` — Boolean formula equivalent to `formula`.
- `BitBlaster.bit_symbols(symbol) -> tuple[FNode, ...]` — the Boolean symbols standing for the
  bits of a bit-vector symbol, least significant first; created on demand, stable per instance.
- `BitBlaster.reconstruct(assignment) -> dict[FNode, FNode]` — bit-vector symbol to bit-vector
  constant, from a `{Boolean symbol: bool}` assignment; absent bits count as false.
- `BitBlaster.model(assignment) -> EagerModel` — same information as an `EagerModel` that also
  carries the Boolean symbols of the converted formulae, so it can evaluate the ORIGINAL formula.
- `bit_blast(formula, environment=None) -> FNode` — module-level shortcut, sibling of
  `nnf()`, `cnf()`, `aig()`.
- `ConvertExpressionError` (existing) — raised for unsupported input.

## 4. Canonical output form

- Bit order: index 0 is the least significant bit, everywhere (`bit_symbols`, `reconstruct`).
- The result is equivalent, not merely equisatisfiable: no auxiliary variables are introduced,
  so the free symbols of the result are exactly the bit symbols of the bit-vector symbols that
  occur plus the Boolean symbols that occur.
- Bit symbols are fresh: they never coincide with a symbol already known to the environment.
- Per instance, one bit-vector symbol always maps to the same bit symbols, across any number of
  `convert` calls, so separately converted formulae can be combined.
- Semantics are SMT-LIB's, matching what the library's simplifier already computes when the
  arguments are constants: `bvudiv x 0` is all ones, `bvurem x 0` is `x`, `bvsdiv`/`bvsrem`
  follow the two's-complement sign rules with the remainder taking the sign of the dividend,
  `bvlshl`/`bvlshr` by an amount >= the width give zero, `bvashr` gives the sign bit repeated,
  rotations count steps modulo the width, `bvcomp` gives a one-bit result.
- Unsupported input raises `ConvertExpressionError`: quantifiers, and any term whose type is
  neither Boolean nor bit-vector (integers, reals, arrays, strings, uninterpreted functions),
  including `BVToNatural`.

## 5. Blind-spot pre-empts (from DESCRIPTION.md bank)

- Result ordering / canonical form: "least significant bit first" stated once, explicitly.
- Unstated inverse: `reconstruct` is stated to treat a missing bit as false.
- Iteration termination: not applicable (structural recursion over a DAG).
- Falsy-on-invalid: unsupported terms raise rather than pass through.
- Cross-feature ordering: the per-instance stability rule is stated (same symbol, same bits).

Codebase-inferable requirements: exactly ONE — the exact corner semantics of division,
remainder, shifts and rotations are already implemented for constants in `pysmt/simplifier.py`,
and the description points at that (fair, discoverable, and the description also names the
corner cases outright).

## 6. Description draft

See meta.md (~430 words, prose, no headers).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Reason |
| ------ | ---- | ----------- | --------- | ------ |
| NEW    | pysmt/bitblast.py    | —    | +560 | BitBlaster: walkers, circuits, symbol map, reconstruct, model |
| MODIFY | pysmt/rewritings.py  | 1080 | +25  | `bit_blast()` shortcut + re-export, sibling of nnf/cnf/aig |

TOTAL: ~585 raw. Target human-effective >= 450 (gate on the hook).

## 8. Solution outline — pure-function helpers

Kernel: `_bits(term) -> tuple[FNode, ...]` produced by a `DagWalker`, one helper per behaviour:

- `_const_bits(value, width)` — constant to bits
- `_ite_bits(cond, a, b)` — bitwise selection
- `_eq_bits(a, b)` / `_ult_bits(a, b)` / `_slt_bits(a, b)` — relations
- `_add_bits(a, b, carry_in)` — ripple-carry adder, returns bits (used by sub/neg/mul/div)
- `_neg_bits(a)` — two's complement
- `_mul_bits(a, b)` — shift-and-add, truncated to width
- `_divrem_bits(a, b)` — restoring division, returns (quotient, remainder) with the
  division-by-zero fixups applied at the end
- `_signed_divrem_bits(a, b, want_rem)` — sign fixups over `_divrem_bits`
- `_shift_bits(a, b, direction, fill)` — barrel shifter plus the >= width guard
- `_rotate_bits(a, steps, left)` — steps modulo width
- `_extract/_concat/_zext/_sext/_comp`
- `_symbol_bits(symbol)` — fresh symbol allocation, memoized per instance

No fixpoint loop is needed; memoization comes from `DagWalker`.

## 9. Test file outline

Path: `pysmt/test/test_bit_blasting_<hash>.py` (repo convention: tests live in `pysmt/test/`).

Block 1 — imports.
Block 2 — builders: `bv(name, width)`, `bvc(value, width)`, small formula builders.
Block 3 — assertion helpers:
  - `assert_blast_equivalent(formula, width_bound)` — enumerate EVERY assignment of the
    bit-vector and Boolean symbols, evaluate the original by substitution + simplification,
    evaluate the blasted formula under the corresponding bit assignment, require equality.
  - `assert_boolean_only(formula)` — the result has no bit-vector operator and Boolean type.
  - `expect_convert_error(formula)` — substring match on the raised error.
Block 4 — buckets:
  - bitwise/structural ops, arithmetic, multiplication
  - unsigned and signed division and remainder including every zero-divisor case
  - shifts by every amount including >= width; arithmetic shift on negative values
  - rotations including steps > width; extract/concat/extend/comp/repeat/macros
  - relations (ult/ule/slt/sle and the derived gt/ge), equality, ite over both types
  - Boolean structure, nesting, shared subterms
  - bit_symbols contract: order, freshness, collision with a same-named Boolean symbol,
    stability across two convert calls and combination of the two results
  - reconstruct: round trip, missing bits, several symbols, widths 1 and 5
  - model: evaluates the original formula to TRUE on a satisfying assignment
  - errors: quantifier, Int, Real, Array, String, uninterpreted function, BVToNatural

5-axis coverage: every described behaviour, every public name, every solution branch
(each operator walker and each corner-case branch), edge cases (width 1, all-zero, all-one,
minimum signed value, empty Boolean structure), stated inverse (missing bit = false).

## 10. Forced signatures

`convert`, `bit_symbols`, `reconstruct`, `model`, `bit_blast` names and return shapes are pinned
in meta.md verbatim, so no agent has to guess a signature (avoids the fake-difficulty
compile/attribute-error anti-pattern). Python has no compile-time coupling, but an attribute
name mismatch would wipe the suite just the same.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt in meta | Test that catches it |
| - | ---- | ----------------- | ---------------- | -------------------- |
| 1 | `bvudiv x 0` = all ones, `bvurem x 0` = x | Hardware dividers leave garbage; the natural circuit returns 0 | named outright | every zero-divisor pair, widths 1..4 |
| 2 | `bvsrem` sign follows the dividend, `bvsdiv` truncates toward zero, both with the zero-divisor fixup | Agents reuse Python `%`, which follows the divisor | named outright | exhaustive signed pairs at width 4 |
| 3 | Shift amount >= width | Log-step barrel shifter silently wraps the amount | named outright | every shift amount at widths 2,3,4 |
| 4 | Rotation steps modulo width | `BVRol(x, 5)` on width 3 | named outright | steps 0..2*width |
| 5 | Fresh bit symbols must not collide | Naming bits `x_0` collides with an existing Boolean `x_0` | freshness stated | formula mixing BV `x` with Boolean `x_0`, `x_1` |
| 6 | Same symbol, same bits across calls | Fresh symbols per call breaks combination | stability stated | convert f, convert g, conjoin, check equivalence |
| 7 | LSB-first everywhere | Reversed order still self-consistent inside `convert` | order stated | `reconstruct` and `bit_symbols` order tests |

Traps 1-4 are interdependent through `_divrem_bits`/`_shift_bits` (the signed operators are
built on the unsigned ones, so a zero-divisor fix in the wrong place breaks the signed cases),
and misdirecting: the failing assertion is an unequal bit-vector value, never the rule.

## 12. Tier + category

- Tier: Olympus. Sub-rank target: Good.
- Category: feature-request (net-new public API).

## 13. Predicted pass rate

10%-25%. The scaffolding (a DagWalker sibling) is easy and the operator list is public, so
somebody will produce a working blaster; the exhaustive per-operator equivalence tests mean any
single corner-case slip fails. Not 0%: every semantic rule is either stated in the description
or already visible in `pysmt/simplifier.py`.

## 14. Quality gate

- [x] Repo understanding: architecture (FNode DAG + FormulaManager hash-consing, walkers,
      simplifier/substituter, oracles, rewritings, solver wrappers, SMT-LIB parser/printer);
      subsystems listed; entanglement zones (walkers, formula manager, type checker);
      test framework pytest under `pysmt/test/`; template `pysmt/test/test_rewritings.py`.
- [x] Existing PR/issue check: `gh pr list -R pysmt/pysmt --state all --search "bit blast|bitblast|blasting|bit-vector"` — no hit; `grep -ri "bitblast" pysmt` — empty.
- [x] Closest approved problems opened: `tinywasm-exception-handling` (spec semantics with
      integration walls), `barcode-qr-decoder` (textbook algorithm + exact oracle).
- [x] Corpus hardness recipe: 6 levers stacked, oracle planned, 7 traps, signatures pinned.
- [x] Not pattern-followable: the rewritings siblings share only the walker scaffold.
- [x] Not a duplicate: no bit-vector/SAT-encoding problem in `Aprroved/`, `problems/`,
      `rejected/`; pysmt is not used anywhere in the local corpus.
- [x] LOC sketch above the floor; gate on the hook before submit.
- [x] Word count of meta.md within the corpus range (297-546 observed).

Predicted iteration cycles: 2.
