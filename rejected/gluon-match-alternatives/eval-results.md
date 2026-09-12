# eval-results.md — gluon-match-alternatives

No platform agent runs yet. Everything below is local validation.

## Local validation

| Check | Result |
|---|---|
| new mode, solution applied | 91 / 91 pass |
| new mode, base only | 80 / 91 fail (the 11 passers are error-expecting or regression tests) |
| base mode, base only | 426 pass / 0 fail, 24 suites |
| base mode, solution applied | 426 pass / 0 fail |
| flakiness, base mode 3x | identical (426 / 0) every run |
| flakiness, new mode 3x | identical every run |
| patch apply, test then solution | clean |
| patch apply, solution then test | clean |
| patch reverse-apply, both | clean |
| encoding | ASCII, LF; `test.sh` mode 100755 |
| banned markers in test paths | none |

## Fingerprint

`solution.patch` — 16 files, raw +402, Counter 1 = 375, human-effective (Counter 2) = 277.
`test.patch` — `test.sh` + `tests/match_alternatives_75d59b.rs`, 91 tests.

## FP mutation harness (per-branch, one mutation per run, restored between)

| # | Mutation | Tests killed | Reads |
|---|---|---|---|
| M1 | `rename.rs`: or-branches do not reuse branch 0's symbols | 26 | the lead trap; every binding test dies with a VM ICE |
| M2 | `translate_guarded`: a false guard goes to match-failure instead of the fallback | 24 | the fall-through trap |
| M3 | `expand_or_patterns`: expansion not recursive | 1 | nested or-patterns |
| M4 | `check_or_branch_bindings`: drop the missing-name direction | 0 -> **2** after fix | names bound only by an earlier branch |
| M5 | `check_or_branch_bindings`: drop the extra-name direction | 0 -> **1** after fixture rebuild | names bound only by a later branch |
| M6 | `check_or_branch_bindings`: drop cross-branch type unification | 2 | branch type agreement |
| M7 | typecheck: drop the guard-against-`Bool` unification | 0, by design | see below |
| M8 | parser: `@` no longer distributes over an or-pattern | 3 -> **5** after hardening | `@` over or-pattern |

**Two holes were found and closed.**

- **M4 survived at 0 kills.** `(A n | B m)` is caught by the extra-name direction alone, so the
  missing-name direction was never independently exercised. Closed with
  `or_binding_absent_from_a_later_branch_is_type_error` and its nested twin: `(A n | B)` where the
  later branch binds nothing, which only the missing-name direction can catch.
**M7 survives and that is correct, not a hole.** The guard block is the same shape as gluon's own
`IfElse` predicate handling at `check/src/typecheck.rs:720-723`: `typecheck(expr,
ModType::rigid(&bool_type))` followed by `unify_span`. The first line already rejects a non-`Bool`
guard, so removing the second changes nothing observable. The tests were still tightened (from a
bare `is_err()` to asserting the error names `Bool`) because the description states the type
directly and the bare assertion could not tell a type rejection from any other failure.

**A third hole opened during the review round and was closed.** Replacing the unfair error-phrase
pins (see below) with variable-name assertions made `or_binding_extra_variable_in_one_branch_is_type_error`
stop discriminating: its fixture `(A n | B n extra_binding)` was being rejected on constructor
arity, not on the binding rule, so removing the extra-name check left it green. Rebuilt as
`(A n 0 | B n extra_binding)`, where both branches are well-typed and only the binding rule can
reject. Re-verified: the mutation now kills it.

**One unfair assertion was found and removed, not by mutation but by the review pass.** Five tests
asserted the error text contained the literal phrase `not bound by every alternative`. The
description promises "a type error that names the variable", never that wording, so the phrase
pinned the reference's own message (`HARDENING.md` 3d: no error-message substring pins). Rewritten
to use distinctive identifiers (`only_in_first`, `shared_name`, `only_in_third`, `extra_binding`)
and assert the message names the offending variable, which is exactly what the description states.

## Hardening round 1 (pre-batch, no agent data)

**Diagnosis is a prediction, not a measurement.** No batch has run, so the levers were chosen for
structural reasons rather than from a kill table: the DESIGN § 11b matrix had empty off-diagonal
cells (F-10), and the contract has two lexical spellings of one concept — a flat or-pattern
`(A n | B n | D n)` and a nested one `(A n | (B n | D n))` — with the equivalence stated in one
clause and only ONE nested test in the suite (F-18).

**Lever: 12 tests, zero new description words.** Six F-18 parity cells (nested or-pattern at each
position where the flat form was already tested: guard-true, guard-false fall-through, under a
constructor, inside a tuple, inside a record, under `@`) and six F-10 composition cells (`@` over
an or-pattern with a failing guard, swapped-variable branches under a failing guard, an
or-pattern whose guard fails falling through to an alternative with its branches REORDERED, and a
nested or-pattern whose guard fails falling through to the equivalent flat one).

**It found a reference bug (L7).** `w @ (A n | (B n | D n))` panicked with
`ICE: Or-pattern survived pattern expansion`: `@` was distributed over the outer or-pattern only,
leaving `As(w, Or(..))` in a branch. Fixed by making the distribution recursive in a new
`parser::distribute_as` helper. This would have shipped as a crash on valid input.

**Trap-proof, hardened suite vs the pre-hardening suite:**

| Mutation | before | after |
|---|---|---|
| M1 `rename.rs` or-branches do not reuse branch 0's symbols | 26 | **38** |
| M2 a false guard goes to match-failure instead of the fallback | 24 | **30** |
| M3 or-expansion not recursive | 1 | **8** |
| M8 `@` never distributes over an or-pattern | 3 | **5** |
| M8b distribution not recursive (the bug found above) | n/a | 1 |

M3 moving 1 -> 8 is the F-18 parity effect measured directly: the same rule, the non-salient
spelling, at every position.

**Predicted effect on pass rate: modest and unverified.** L15 says mutation kills do not predict
agent kills. What the round buys with confidence is FP coverage and a fixed crash; the band claim
stays a prediction until a batch runs.

## Notes for the batch

- Capture every passing agent's diff into `agent-runs/` while the run view is open.
- Watch for PASS_CHEATED on `parser/tests/support/mod.rs` — that file cannot compile against the
  new `Alternative` field and is deliberately outside base mode. Any run that edits it did not
  need to.
- Watch the split between M1-class failures (VM ICE, `Undefined variable`) and M2-class failures
  (wrong value from a guard that should have fallen through). Those are the two designed axes; if
  the batch shows only one, the other is not biting.
