# eval-results.md - pysmt-bit-blasting

No platform agent batch has been run yet. Everything below is local verification.

## Local validation matrix (Docker, `olympus-base-python`, `--network none`, `--user 1000:1000`)

| run | mode | tests | failures | errors | skipped | rc |
| --- | --- | --- | --- | --- | --- | --- |
| base tree + test.patch | base | 635 | 0 | 0 | 259 | 0 |
| base tree + test.patch | new | 135 | 135 | 0 | 0 | 1 |
| + solution.patch, run 1 | base | 635 | 0 | 0 | 259 | 0 |
| + solution.patch, run 1 | new | 135 | 0 | 0 | 0 | 0 |
| + solution.patch, run 2 | base | 635 | 0 | 0 | 259 | 0 |
| + solution.patch, run 2 | new | 135 | 0 | 0 | 0 | 0 |
| + solution.patch, run 3 | base | 635 | 0 | 0 | 259 | 0 |
| + solution.patch, run 3 | new | 135 | 0 | 0 | 0 | 0 |

Two further consecutive base/new pairs were run in an earlier container from the reverse apply
order (solution first, then tests): identical counts, five pairs total, no flips.

## Oracle fuzz (independent SMT-LIB model vs blaster vs pysmt simplifier)

| widths | operators | operand pairs | mismatches vs oracle | simplifier disagreements |
| --- | --- | --- | --- | --- |
| 1, 2, 3, 4 | add sub mul and or xor udiv urem sdiv srem smod lshl lshr ashr comp | every pair | 0 | 0 |
| 1, 2, 3, 4 | ult ule slt sle | every pair | 0 | 0 |

## Mutation proof (reference broken on purpose, 135-test suite)

| mutant | verdict | tests failed | example |
| --- | --- | --- | --- |
| srem takes the divisor sign | killed | 4 | test_bv_srem_follows_the_dividend_sign |
| shift without the overflow guard | killed | 8 | test_bv_ashr_beyond_the_width_repeats_the_sign |
| bits most significant first | killed | 31 | test_bit_symbols_are_least_significant_first |
| bit symbols named after the symbol | killed | 9 | test_bit_symbols_do_not_capture_existing_symbols |
| bit symbols fresh on every call | killed | 64 | test_separately_converted_formulae_agree |
| array store touches every cell | killed | 3 | test_array_store_leaves_other_cells_alone |
| array equality checks the first cell | killed | 1 | test_array_equality_compares_every_cell |
| quantifier body not instantiated | killed | 3 | test_quantified_symbol_gets_no_bits |
| reconstruct missing bits are true | killed | 2 | test_reconstruct_treats_missing_bits_as_false |
| udiv by zero fixup removed | survived | 0 | semantically neutral, see below |
| urem by zero fixup removed | survived | 0 | semantically neutral, see below |
| rotation modulo the width removed | survived | 0 | semantically neutral, see below |

The three survivors are not test gaps. The restoring divider already produces all ones for the
quotient and the dividend for the remainder when the divisor is zero, so the explicit fixups never
change a result, and pySMT's type checker rejects a rotation step larger than the width, so the
modulo can only ever fire on a step equal to the width, where the slice arithmetic already gives
the identity. Both behaviours are pinned by tests that pass in either form (every divisor
including zero at widths 1 to 3; rotations by zero, one and the width).

## Test suite shape

135 tests in `pysmt/test/test_bit_blasting_4cfb0e.py`, all failing by name on the base tree:

| bucket | tests |
| --- | --- |
| Boolean structure and pass-through | 7 |
| bitwise, arithmetic, multiplication | 12 |
| unsigned and signed division and remainder, including every zero divisor | 14 |
| shifts, including amounts at or beyond the width | 10 |
| rotations, extension, extract, concat, comp, repeat, derived macros | 16 |
| relations, equality, if-then-else over both types | 10 |
| arrays, nested arrays, constants, stores, equality | 20 |
| quantifiers | 7 |
| bit_symbols contract (order, freshness, collision, stability) | 10 |
| reconstruct and model | 12 |
| unsupported input errors | 8 |
| mixed and structural (shared subterms, widths, module function) | 9 |
