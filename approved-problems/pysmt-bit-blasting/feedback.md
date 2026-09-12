# feedback.md - pysmt-bit-blasting

Tier: Olympus. Category: feature-request. Status: built and locally validated, no agent batch run yet.

## Pick

Repo: pysmt/pysmt, Apache-2.0, 638 stars, last commit 2026-06-10, pure Python, no runtime
dependencies. Base commit `9342f1829ab7c1f846e00dca57e20603a38550e0`.

Gates run at pick time:

- License: Apache-2.0 read off the repo (in the allowed list).
- Stars / activity: 638 / commit within the last two months on the default branch.
- Fresh host: `pysmt` appears in none of `Aprroved/`, `problems/`, `rejected/`, `worktrees/`,
  `Olympus/problems/`, `Task*/problems/` (636 slugs checked). No SMT / SAT-encoding problem in the
  local corpus either, so no feature-class overlap.
- Not saturated: not in `SATURATED-REPOS.md`; a niche academic library, the opposite of the
  author-obvious profile that saturates (clean VM / SQL tool / config lang).
- Environment quality: the vanilla suite runs offline in `olympus-base-python` in 14s,
  376 passed / 259 skipped / 0 failed. No network, no solver binaries, no host-library drift.
- Exclusivity: `gh pr list -R pysmt/pysmt --state all --search "bit blast|bitblast|blasting|
  bit-vector"` returns nothing implementing this; `grep -ri bitblast pysmt` is empty. pySMT gets
  bit-vector reasoning only from external solver bindings.

Repos screened and dropped before this one: lipgloss (open PR #492 implements the exact table cell
merging), vpype (issue #52 is a long-open fill request with two public implementations linked),
biopython (Biopython License Agreement is not in the allowed list), python-docx (last commit
2025-06, fails the 12-month gate), notnil/chess (archived), BurntSushi/fst (Unlicense, stale),
mapstructure (478 stars), kustomize / marshmallow (presumed-saturated household names),
libopenapi / construct / chalk (already screened dead in `SATURATED-REPOS.md`).

## Feature

A pure-Python bit-blaster: `pysmt.bitblast.BitBlaster` turns a bit-vector formula into an
equivalent Boolean formula, with `bit_symbols`, `reconstruct` and `model` as the surrounding
surface, plus `bit_blast()` in `pysmt.rewritings` next to `nnf` / `cnf` / `aig`.

Why it is not a duplicate: the closest approved problems are `tinywasm-exception-handling`
(spec semantics threaded through a runtime) and `barcode-qr-decoder` (textbook algorithm pinned by
an exact oracle). Neither touches SMT, bit-vector theory or Boolean encoding, and no local problem
uses pysmt or any SMT library. The nearest local feature class is constant folding
(`gluesql-const-fold`, `oxc-fold-known-methods`, `expr-boolean-simplify-fixpoint`), which is
word-level simplification, not a translation between theories.

## Difficulty design

One kernel (term to tuple of bits) drives every operator, both relations, arrays, the symbol map
and model reconstruction, so a local fix to one operator's layout regresses the rest. Traps:

1. `bvudiv x 0` is all ones, `bvurem x 0` is the dividend.
2. `bvsdiv` truncates toward zero, `bvsrem` takes the sign of the dividend, both with the zero
   divisor carried through the magnitude form.
3. Shifts by an amount at least the width (zero, or the sign bit repeated for `bvashr`), which a
   log-step barrel shifter silently wraps instead.
4. Bit symbols must be fresh, so naming them after the symbol collides with an existing `x_0`.
5. Bit symbols must be stable per blaster, so two separately converted formulae can be conjoined.
6. A store rewrites one cell and leaves the others alone; array equality compares every cell.
7. A quantifier must be instantiated over the ORIGINAL body, so a bound symbol never gets bits.

## Oracle

An independent Python model of SMT-LIB 2.6 bit-vector semantics (in the scratchpad, not shipped)
was fuzzed against the blaster for widths 1 to 4 over every operand pair for all 15 binary
operators plus the 4 relations, and against pysmt's own constant folding at the same time:
0 mismatches, and no disagreement between the independent model and the simplifier either.

## Mutation proof

Twelve deliberate defects were injected into the reference; nine were killed by the suite
(srem sign 4 tests, shift guard 8, bit order 31, non-fresh names 9, per-call bits 64, store
aliasing 3, array equality 1, quantifier body 3, missing-bit default 2). Three survived and were
checked by hand: removing the division-by-zero fixups and the rotation modulo does not change any
result, because the restoring divider already yields all ones and the dividend when the divisor is
zero, and pySMT's type checker rejects a rotation step greater than the width. They are
semantically neutral edits, not gaps in the tests: the suite covers every divisor including zero
exhaustively at widths 1 to 3.

## Validation

Built from a clean clone at the base commit, in `olympus-base-python`, offline, as uid 1000:

| state | base | new |
| --- | --- | --- |
| test.patch only | 635 tests, 0 failures | 135 tests, 135 failures |
| plus solution.patch | 635 tests, 0 failures | 135 tests, 0 failures |

Both patches apply in either order and unapply cleanly. Five consecutive runs of base and new in
the container gave identical counts, and the repo's own suite has no timing, ordering, network or
RNG dependence.

## Assumptions and deviations

- meta.md is 620 words, above the 500 guidance. The contract covers three public methods, a module
  function, arrays, quantifiers and seven corner-case semantics, and every sentence maps to tests.
  Trimming further would leave a tested behaviour undocumented, which is the worse failure.
  Approved corpus metas run to 546 words.
- Effective LOC is 422 by the hook (552 raw, 2 files), over the 400 auto-block and the 250 sprint
  floor but under the 450 design target. Scope was expanded twice for this reason (arrays, then
  nested arrays and quantifier expansion); a third expansion would have meant either a
  fairness-hostile surface (DIMACS output, whose canonical form depends on the agent's own symbol
  names) or an invasive change to pysmt's operator table that risks base-suite regressions. Eight
  problems in the approved corpus sit below 400 by this same hook.
- The new tests guard their imports so that on the base tree each of the 135 tests fails by name
  rather than the module failing to collect.

## Iteration history

- R1: designed against pysmt's rewritings family, implemented the BV core, fuzzed to 0 mismatches.
- R2: LOC gate at 303 effective, added array blasting and quantifier expansion (403).
- R3: LOC gate at 403, added nested arrays (418, 422 once the second file was in the patch).
- R4: found that `git diff --cached` dropped the unstaged `rewritings.py`, so the first patch pair
  contained one file and the module function was missing in the container. Regenerated with
  everything staged.
- R5: pysmt's simplifier answers array equality wrongly (`Equals(a1, a2).simplify()` is TRUE for
  two different constant arrays), so the array-equality tests compare against a Select-expanded
  reference instead of the simplifier. Same for quantified formulae, which the simplifier cannot
  evaluate at all.
