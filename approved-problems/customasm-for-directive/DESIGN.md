# DESIGN.md — customasm-for-directive

## 1. Title
Add a `#for` compile-time repetition directive to the assembler

## 2. Shape classification
- Shape: O-Algorithm-correctness (new directive + subtle multi-pass expansion semantics)
- Pass target: ≤40% (bias low / hard end)
- Best agent: mixed (Nova/Orion/Vega)
- Dominant verdict: MISSED_REQUIREMENT (deferral / half-open / shadowing)

## 3. Public API surface (assembler source-language surface, exact-byte oracle)
- `#for NAME in START, END { BODY }` — new directive. `NAME` is the loop variable identifier;
  `START, END` are integer expressions; `BODY` is a braced block of directives/data/instructions.
- Behavior asserted through `asm::assemble(...).output.format_binary()` byte output.

## 4. Canonical output form
- Iteration: `NAME` takes `START, START+1, ..., END-1` (half-open, END exclusive), increasing order.
- Empty: `START >= END` emits zero bytes and advances no address.
- Substitution: `NAME` resolves to the current iteration integer in every expression inside the body.
- Non-integer START/END: error containing `integer`.
- Deferral: START/END referencing a not-yet-known symbol defer expansion to a later pass; a genuinely
  unresolvable range errors (message contains `for`/unresolved).
- Nested loop with the same variable name: inner binding shadows outer within the inner body.
- A label declared directly in a body that iterates more than once => duplicate-symbol error.

## 5. Blind-spot pre-empts (verbatim in meta)
- "the value `END` is exclusive" (half-open / off-by-one)
- "If `START` is greater than or equal to `END`, the body is skipped entirely" (empty)
- "bounds may reference constants defined later in the file" (fixpoint deferral)
- "an inner loop variable of the same name shadows the outer one within the inner body" (shadowing)

## 6. Description draft
See meta.md (plain prose, ≤200 words).

## 7. File footprint (raw / meaningful)
| Action | Path | Raw delta | Meaningful |
| ------ | ---- | --------- | ---------- |
| NEW | src/asm/parser/directive_for.rs | ~80 | ~60 |
| NEW | src/asm/resolver/directive_for.rs | ~210 | ~170 |
| MODIFY | src/asm/parser/directive.rs | +4 | +4 |
| MODIFY | src/asm/parser/mod.rs | +8 | +6 |
| MODIFY | src/asm/resolver/mod.rs | +5 | +4 |
| MODIFY | src/asm/resolver/iter.rs | +3 | +3 |
| MODIFY | src/asm/mod.rs | +18 | +14 |
TOTAL: ~328 raw / ~261 meaningful across 2 new + 5 modified = 7 files. Target ≥250 eff, ≥2 files. OK.

## 8. Solution outline — helpers
- `directive_for::parse` — parse `NAME in START, END { BODY }` (reuse `parse_braced_block` idiom from #if).
- `substitute_var_in_expr(&Expr, name, &BigInt) -> Expr` — deep-clone, replace matching `Variable`.
- `substitute_var_in_block(&AstTopLevel, name, &BigInt) -> AstTopLevel` — walk body nodes, substitute in
  every Expr; skip descent into a nested `#for` body that rebinds the same `name` (shadowing).
- `resolve_fors(...) -> usize` — mirror `resolve_ifs`: for each `#for` whose START/END resolve via
  `eval_simple` to integers, remove node and splice N substituted body copies; return count.
- `check_leftover_fors(...)` — error on any remaining `#for` (unresolvable bounds), mirror `check_leftover_ifs`.
- Integrate into `assemble()` pre-iteration loop: call `resolve_fors`, include its count in the
  continue-condition, call `check_leftover_fors` alongside `check_leftover_ifs`.

## 9. Test outline (new file src/test/for_directive_<hash>.rs, wired into src/test/mod.rs)
Helper `asm(src) -> Vec<u8>` via FileServerMock + `asm::assemble` + `output.format_binary`; `asm_err(src, kw)`.
Buckets: basic count/order; half-open+empty+single; substitution in #d/#res/#addr/#assert; deferral via
forward `#const`; nested loops + shadowing; duplicate-label-on-repeat error; non-integer bound error;
loop var affecting address-dependent sizes; interaction with #if inside body.

## 10. Forced bounds
None exotic — Rust Clone on Expr/AstTopLevel already derived.

## 11. Trap matrix
| # | Trap | Why hit | Pre-empt | Catching test |
|1| END exclusive (half-open) | assume inclusive | §5 | for_zero_to_three_emits_three |
| 2 | forward-const bound must defer | eager single-pass eval | §5 | range_end_from_later_const_resolves |
| 3 | nested same-name shadowing | substitute into inner scope | §5 | nested_same_name_inner_shadows_outer |
| 4 | empty range advances no address | error/emit on empty | §5 | empty_range_emits_nothing |

## 12. Tier + category
- Tier: Olympus (single tier). Category: feature-request (net-new directive).

## 13. Predicted pass rate
- 10-30%. Deferral + half-open + shadowing are independent misses; core splice+substitute is solvable.

## 14. Quality gate — all planned green (repo understanding 5/5; 0 implementing PRs; exact-byte oracle;
≤1 codebase-inferable; ≥250 eff / ≥2 files; helpers 1:1 with behaviors; comment convention = NONE).

Why not a duplicate: no existing problem targets an assembler or compile-time macro/loop expansion; fresh
repo (customasm), fresh subsystem. Predicted iteration cycles: 2.
