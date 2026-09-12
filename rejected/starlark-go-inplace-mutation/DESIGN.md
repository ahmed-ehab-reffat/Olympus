# DESIGN - starlark-go-inplace-mutation

## Shape / tier
Olympus, O-Composite-add (new syntax + methods threading parser -> AST -> resolver ->
compiler bytecode -> interpreter -> value/library). Category feature-request.

## Feature: in-place list/dict mutation (3 coherent, distinct capabilities)
1. List slice assignment: `x[i:j] = y` / `x[i:j:k] = y` (grow/shrink/insert/delete; extended
   slice exact-length; iterable RHS; immutable-target error). New opcode SETSLICE, List.SetSlice.
2. `del` statement: `del x[i]` (list index-delete OR dict key-delete), `del x[i:j]` (list),
   multi-target left-to-right; bare-name/dot/other-type/out-of-range/missing-key rejected.
   New AST DelStmt, opcodes DELINDEX/DELSLICE, List.DelIndex/DelSlice.
3. In-place `list.sort(key=, reverse=)` (stable, reuses sortSlice) and `list.reverse()`;
   both return None; frozen/iteration guards.

## Gates
- Dedup/canonical/BSD-3/active/0-of-our-subs OK. `del` is a reserved-but-unimplemented keyword
  (scan.go, spec.md) -> implementing it is spec-blessed, not a philosophy violation.
- Slice-assign, del, in-place sort/reverse all genuinely ABSENT on base (verified) and not in
  any open PR.

## DERIVATIVE pivot (platform review)
Prior starred-unpacking version flagged derivative vs a prior sub doing starred unpacking
(assignment + display splicing + dict **). Dropped the entire overlap; reshaped around the
reviewer-confirmed-distinct slice assignment + del + in-place sort/reverse. New core purpose is
distinct from all 5 candidates (starred / serialization / imports / type-annotations / optimizer).

## LOC / validation
Genuine effective LOC = 276 (strict). 9 source files + 1 test file (build tag mutate_bc87cd).
31 tests pass on solution / fail on base; base green; deterministic x3; patches apply+reverse
both orders. See feedback.md for the full validated checklist.

## Hardening (fair, FP-safe)
DOING-difficulty, not known semantics: del one-syntax type-dispatch (list-index vs dict-key);
shared sliceIndices reused by read+write+del; A8/A9 boundaries (extended-slice exact-length,
empty-slice insert/delete, iterable RHS, out-of-range/missing-key/immutable rejects); stable
key-sort. Every test traces to a meta sentence; error cases assert err!=nil (no substring pins);
1 codebase-inferable requirement (slice augmented-assign rejection).
