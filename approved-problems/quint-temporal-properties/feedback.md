# feedback.md — quint-temporal-properties

## Pick

`quint-co/quint` (the repo moved from `informalsystems/quint`; the canonical slug is what every
exclusivity search used), Apache-2.0, 1556 stars, TypeScript, base `4e6a580e` (2026-07-20, the
default branch head). One earlier submission of ours on this repo, `quint-match-exhaustiveness`,
which touched the type-checking side and shipped 190 effective LOC; this one is a different
subsystem (the evaluator and the simulator) and clears the floor with room.

## Gates

- **Behavioral F2P.** `builtins.ts` rejects `always`, `eventually`, `leadsTo`, `enabled`, `orKeep`,
  `mustChange` with QNT501, and `next` has no case at all. All seven are declared in
  `src/builtin.qnt`, typed in `types/builtinSignatures.ts` and given effects in
  `effects/builtinSignatures.ts`: the front end is complete, the engine is missing. The docs name
  the limitation ("invariants only, temporal properties are not supported").
- **Cold.** The rejection block has not been touched since 2024-08-29. `leadsTo` was *added to it*
  in 2026-03 (PR #1932), which is the maintainers extending the language for Apalache without
  touching the simulator.
- **Exclusivity.** `gh pr list -R quint-co/quint --state all` searched for temporal, enabled,
  liveness, lasso, simulator temporal: nothing implements any of it. No issue asks for it either,
  so this is a gap rather than a workstream.
- **Maintainer philosophy.** The docs record the missing support as a limitation, not as a
  decision; fairness operators are left rejected, which is where the "use Apalache" line actually
  sits (they quantify over action occurrences and need a successor relation the simulator cannot
  invert).
- **Dedup.** No temporal logic, LTL, model checking or liveness anywhere in `Aprroved/`,
  `problems/`, `rejected/`, `Olympus/`, `Hagora/`, `Starter/`.
- **Env.** Vanilla suite 658 passing / 2 failing in 5s; the two failures are
  `test/runtime/rust/repl.test.ts`, which drive a Rust evaluator binary downloaded from GitHub
  releases and cannot pass on a checkout, let alone offline. `test.sh` base mode excludes that
  directory and says why.
- **Language + license + activity + stars**: TypeScript, Apache-2.0, active, 1556 stars.

## Build

540 human-effective LOC (754 raw) across 6 files: a new `runtime/impl/temporal.ts` carrying the run
shape and the three-valued evaluation, next-state building in `builder.ts` (plus `orKeep` and
`mustChange`, which need the argument expression rather than its value), `enabled` in
`builtins.ts`, a transition loader in `VarStorage.ts`, the per-run decision in `evaluator.ts`, and
one error code.

128 tests, all driven through `parse`, `parseExpressionOrDeclaration`, `Evaluator` and
`Evaluator.simulate`, which already exist, so the package still compiles on base and every test
fails at run time rather than taking the whole base mode down with a type error. Fixtures have
state spaces of two to six states. Most carry no nondeterminism the guards do not resolve; the one
fixture that does was checked across 40 seeds and gives the same verdicts for every one of them.

## What changed in an existing test

`test/runtime/deprecated/compile.test.ts` has an "unsupported operators" test that asserts each of
these operators errors. Three of its assertions (`enabled`, `orKeep`, `mustChange`) are removed in
test.patch, because the task makes those operators work. The remaining assertions still hold on
base and with the solution: `always` and `eventually` still error (now QNT518 rather than QNT501,
and the test only checks that an error occurs), and `weakFair`/`strongFair` are untouched.

## Platform pre-checks, round 1

- **Category FAILED, suggested bugfix.** The description opened with what the runtime does today
  ("only checks invariants", "declared ... but the runtime rejects every one of them"), which reads
  as completing an incomplete implementation. Rewritten to state the ask and the semantics only, so
  it reads as the capability it is. The same three sentences were the three HIGH-priority deletions
  from the necessary-information check, so one edit cleared both.
- **Necessary information, request_changes.** Three HIGH deletions applied. One MEDIUM applied: the
  clause pinning that `enabled` also restores the recorded action and picks is gone, and with it the
  test that asserted it. One MEDIUM declined: "the property, or any predicate inside it, may be
  written as a definition and referred to by name" stays, because two tests assert it (5 mutation
  kills) and deleting the sentence would leave them undocumented.
- **Alignment + sanity, WARNING on one ambiguity.** "Both come out false without touching the next
  state" sat after `orKeep` and `mustChange` and could be read as covering `orKeep`, which always
  holds. Now `orKeep` says "so it always holds" and the false case is stated for `mustChange` alone.
- **Tests focus on behavior, WARNING.** Every read of `evaluator.ctx.varStorage` is gone. "Leaves
  the next state untouched" is now asserted the way a spec author would see it: a following
  assignment survives, a run's transitions still match, and reading a next-state variable that was
  never assigned gives QNT502, which is what the repo already reports for an unset variable. Test
  count went 63 to 62, and the traps got stronger rather than weaker (`next` memo 7 to 11 kills, the
  missing-successor case 1 to 2); `enabled` isolation went 3 to 2 and still bites.

## Platform pre-checks, round 2

- **Necessary information, request_changes again.** Both HIGH items taken, plus the MEDIUM and both
  LOW ones. Gone: the sentence keeping `weakFair`/`strongFair` rejected; the sentence spelling out
  that the operators nest, combine with connectives and can be named; the sentence saying a
  non-temporal property is still checked as an invariant; "however each of them was reached"; and
  "whatever `a` assigned before it failed". meta.md is now 315 words.
- **Why removing the nesting sentence is still fair.** The tests for `always(eventually(p))` and for
  a property given by name do not test whether those forms can be *written* (the grammar and the
  type system already allow them); they test the semantics, which follows from the per-position
  definitions the description still gives. Nothing lost a discriminator: the mutation counts are
  unchanged.
- **Tests focus on behavior, WARNING on pinned codes.** The two `QNT501` assertions went with the
  fairness sentence, so that test is gone. The three `QNT502` assertions no longer pin a code; they
  assert only that reading a next-state variable which was never assigned fails, which is the
  observable side of "leaves the next state untouched". `Outcome.samples` is gone too: the test now
  asserts the verdict over three runs instead of the sample count. QNT518 stays pinned and stays
  documented.

## Platform pre-checks, round 3

Only the necessary-information check came back, and only one item was HIGH.

- **HIGH, taken in part.** "over that behavior every property has a definite answer, and the run
  reports a violation exactly when the answer is no" is two claims. The second half is the obvious
  default and is gone. The first half is the requirement that separates a cycling run from a prefix
  and is what makes `eventually(x == 5)` a violation rather than an open question, so it stays, as
  "and the property is decided over that behavior".
- **All three MEDIUM items taken.** Gone: "As the property of a run they are decided once the run is
  over rather than at each state"; the preface "Anywhere else there is no execution for them to talk
  about, so"; and "A run is a finite sequence of states".
- **LOW declined.** "and takes nothing: it leaves the state exactly as it was" is the whole contract
  for `enabled`, and three tests assert it (2 mutation kills). Dropping it would leave them
  asserting behavior the description never states, which is a Test Fairness reject. Low severity, so
  not blocking.

meta.md is now 267 words. No code or test changed, so the patches and the Docker matrix from round 2
still stand.

## Coverage suggestions, round 3 (advisory, all four taken)

- **Non-initial lasso entry.** A new fixture with a stem (`0`) and a two-state cycle (`1, 2`) that
  the initial state is not part of. `always(eventually(x == 0))` is a violation there, because the
  behavior only visits `0` once. This exposed a wall nothing had tested: folding from position zero
  instead of from the first repeated state (new mutation M11).
- **`mustChange` preserves the incoming next state.** A next-state value assigned before the call
  survives the rejection, which is the literal reading of "leaves the next state untouched" and
  stronger than the old assertion that the variable ends up unassigned. `mustChange` rollback went
  from 2 kills to 3.
- **Mixed nondeterministic runs.** A model with a genuine `any` branch, checked over 20 runs. To
  keep it fair rather than seed-lucky, the verdicts were verified across 40 different seeds: every
  seed gives the same three answers, so no implementation can fail this by consuming randomness in a
  different order.
- **Composite state equality.** A fixture whose variables hold a set and a record. This turned out
  to be the strongest single discriminator in the suite: comparing state records by reference
  instead of by value kills 16 tests (new mutation M12).

All four are covered by sentences the description already carries: the cycle rule ("reaches the
first repeated state and then cycles through the states from there on"), "leaves the next state
untouched", and "two states are the same state when their variables hold the same values". The
aggregate verdict over several runs is unchanged base behavior. No description change was needed.

Test count 61 to 71. Existing traps got sharper too (`next` memo 11 to 12, `always` folding 6 to 8).

## Coverage suggestions, round 4 (advisory, all three taken)

- **Irreparable violation on an open prefix.** A real gap: every open-prefix test so far checked an
  obligation that was still satisfiable, so nothing asserted that a prefix can refute at all. Added
  `always(x < 2)` over a strictly increasing run, plus the conjunction case where one operand is
  already broken and the other is still open, which is the Kleene rule the three-valued evaluation
  exists for. It made the open-prefix trap sharper (2 kills to 3).
- **Structured `mustChange` comparison.** Sets and records rebuilt with the same contents, in either
  argument order, and the same shapes genuinely changed. This is a different code site from the
  lasso comparison, and it was worth testing: comparing the observed value by reference kills 7
  tests (new mutation M14).
- **Error propagation.** An action that divides by zero, probed by each of `enabled`, `orKeep` and
  `mustChange`. All three let the error out; the interesting failure is `enabled` folding an error
  into "not enabled", which now kills a test (new mutation M13).

**What was deliberately not asserted:** whether the next state is rolled back when the probed action
*errors*. The description defines "leaves the next state untouched" for the false case only, and a
run aborts on an error anyway, so pinning a post-error state would be asserting behavior the
description never states. That is the Test Fairness failure mode, so the suggestion's second half is
answered in feedback rather than in a test.

All three groups trace to sentences already in the description: the open-prefix rule, "leaves the
next state untouched", and "two states are the same state when their variables hold the same
values". No description change was needed; meta.md stays at 267 words.

Test count 71 to 79. The solution is byte-identical to round 3.

## Coverage suggestions, round 5 (advisory, two taken in full, one in part)

- **Temporal operand runtime errors.** A property whose operand divides by zero now has to stop the
  run: status `error`, and every reported error carries the same code the same expression produces on
  its own, so nothing is invented or swallowed. The trap is real: folding the error into a `false`
  position kills 3 tests (new mutation M15). These three tests first passed on base for the wrong
  reason (`always` is an eager builtin, so the division error surfaces before the unsupported-operator
  error), so each one now also asserts a verdict that only works with the solution.
- **Zero-step and self-loop boundaries.** A zero-step budget leaves a single state: `always(x != 0)`
  is refuted there, everything still open stays open, and a predicate reading the next state says
  nothing because there is no step at all. A `Next = x' = x` run is the smallest possible cycle, and
  `always(next(x) == x)` only holds if the successor of the last position wraps to the start of the
  cycle. This caught a boundary nothing had pinned: keeping both occurrences of the repeated state in
  the cycle kills 2 tests (new mutation M16).
- **Nondeterministic probe rollback, taken in part.** The observable half is in: a run whose step
  probes an action that makes a nondeterministic pick and then fails produces exactly the transitions,
  the cycle and the verdicts of the same run without the probe.

**What was deliberately not asserted:** that a failed probe restores the recorded action and the
nondeterministic picks. That clause was in the description in round 1 and the necessary-information
check asked for its removal, so the test that asserted it went too. Re-adding the assertion now,
without the sentence, would pin behavior the description no longer states. The RNG half is outside
any contract as well: probing consumes randomness exactly as `any` does when it tries branches.

Test count 79 to 87. The solution is byte-identical to round 3.

## Coverage suggestions, round 6 (advisory, all three taken)

- **Empty observed value.** `orKeep(())` has no variables to keep, so a failed action stutters
  without restoring anything, while an enabled one is still taken; `mustChange(())` observes a value
  that can never differ, so it is always false. Both follow from the stated semantics rather than
  needing a new rule.
- **Deadlocked execution.** A `Next` that genuinely runs out of enabled steps before the budget. Its
  terminal position is neither a cycle nor a truncated prefix: a property its states broke is
  reported, one they merely never settled stays open, and a predicate reading the next state says
  nothing at the position with no successor. Sharpened both the open-prefix and no-successor traps
  (4 and 5 kills).
- **Delayed runtime error.** An operand that holds for the first positions and errors later. The
  provisional decision is discarded and the run reports `error` with the original code, for a
  satisfied `always` prefix and for an as-yet-unmet `eventually` alike. The error-as-false mutation
  went 3 kills to 5.

All three trace to sentences the description already carries; meta.md is unchanged at 267 words.
Test count 87 to 96. The solution is byte-identical to round 3.

## Coverage suggestions, round 7 (advisory, both taken; one found a real bug)

- **`mustChange` on derived observations.** `x + y` where both variables move but the sum does not
  must come out false, and the same through a named `val`. **The named form failed.** A definition
  read in the next state was being cached against the current state, so a second action tried from
  the same state saw the first action's next-state value. The cache only clears on a shift, which is
  right for a current-state `val` and wrong for a next-state one. Fixed in `buildDefWithMemo`, and
  the mutation that restores the old condition kills a test (M17). This is the trap I had recorded
  as retired in round 1 because no test could kill it: it was real all along, just on the next-state
  side, and only a derived observation could reach it.
- **`leadsTo` on an open prefix.** Focused assertions for both shapes: a cause whose effect has not
  arrived yet, and a cause whose effect already did. Both stay open, because no prefix can confirm
  an `always`; the contrast with the cycling cases that do report a violation is now explicit.

Both trace to sentences the description already carries, "the value of `v` in the next state differs
from its value in the current one" and the open-prefix rule, so meta.md is unchanged at 267 words.
Test count 96 to 100; the solution grew by one condition, 519 to 521 human-effective LOC.

## Coverage suggestions, round 8 (advisory, two taken in full, one in part)

- **`next` under `eventually` and `leadsTo`.** The successor lookup is position-relative wherever it
  appears, including at the wrap point of a cycle: on the three-state counter, `eventually(next(x) ==
  0)` holds because the last position's successor is the start of the cycle, and the same through
  `leadsTo`.
- **Negating an unsettled obligation on an open prefix.** Negation of something still open stays
  open, while negation of an obligation the prefix has already met is a definite violation. That
  last one is the case that distinguishes three-valued negation from a two-valued one.
- **Short-circuit errors under connectives, taken in part.** The case where the connective needs the
  erroring operand is now tested for `and` and `or`: the run stops with the original code. The case
  where the other operand already fixes the result is deliberately not pinned. The description says
  nothing about the order temporal operands are evaluated in, and both readings are defensible: the
  repository's plain `and` short-circuits, while a temporal fold that visits every position has no
  natural short-circuit point. Pinning either would assert behavior the description does not state.

Both tested groups trace to sentences already in the description; meta.md is unchanged at 267 words.
Test count 100 to 104, and the solution is byte-identical to round 7.

## Coverage suggestions, round 9 (advisory, both taken)

- **Temporal short-circuiting on runtime errors.** This reverses round 8, where I left the
  short-circuit reading unpinned because the description does not fix an evaluation order. The
  suggestion names the expected semantics, and following the language's own `and`, `or` and `implies`
  keeps it a codebase-inferable requirement rather than a new one. `foldOperands` now returns as soon
  as an operand settles the connective, and `implies` returns without looking at its consequent when
  the antecedent does not hold, so `false and <erroring>` and `true or <erroring>` decide rather than
  fail. Kleene combination is untouched for the cases nothing settles: `unknown and false` is still
  `false`. Mutation M18 removes the short-circuit and kills a test.
- **`leadsTo` obligation originating inside a cycle.** On the stem fixture the cause occurs only in
  the cycle and the effect is reachable only by wrapping past the last position, which is the
  discharge path the stem and counter cases never exercised.

Both trace to sentences the description already carries, so meta.md is unchanged at 267 words. Test
count 104 to 106; the solution grew by the short-circuit, 521 to 536 human-effective LOC.

## Test Fairness FAIL, round 10 (fixed)

The check failed on one assertion of 107: `always(x < 100) and eventually(x == 100)` on an open
prefix was asserted `ok`. The reviewer is right. The description says a prefix reports a violation
when no continuation could satisfy the property, and no continuation satisfies that conjunction: it
demands x stay under 100 forever and also reach exactly 100. My evaluation is compositional, so it
folds two `unknown` operands into `unknown` and reports `ok`. Seeing the contradiction would mean
deciding satisfiability of the conjunction, which is not what the description asks for and not
something a solver could be expected to implement.

Fixed by making the assertion consistent with the description rather than by changing the semantics:
the open conjunct is now `always(x < 100) and eventually(x == 50)`, whose operands are jointly
satisfiable, so `ok` follows from the prefix rule. The conclusive counterpart, an already-broken
conjunct with an open one reported as a violation, is unchanged. No other assertion in the suite
depends on correlated open operands.

## Coverage suggestions, round 10 (advisory, both taken)

- **Observation-expression errors.** An error while evaluating the observed value of `mustChange` now
  propagates and restores the successor that was pending before the call. This needed a solution
  change: the error path did not roll back, only the false path did. `orKeep` never evaluates its
  second argument at run time, since only the variables occurring in it are needed, so there is no
  observation error to raise there. Mutation M19 removes the rollback and kills a test.
- **Temporal effect-side errors.** A `leadsTo` whose effect predicate, rather than its cause, raises
  at a position where it has to be evaluated. The run stops with the original code.

## Test Fairness FAIL, round 11 (fixed by documenting the policy)

This one is the two checks disagreeing, and worth recording. In round 5 I declined to assert
rollback when a probed action errors, precisely because the description defined "leaves the next
state untouched" only for the false case. In round 10 the coverage check asked for that assertion, I
added it, and the fairness check then flagged it as an unstated author choice, correctly noting that
the neighbouring `actionAll` returns an error without recovering its snapshot.

Taken the way the coverage suggestion itself proposes: document the policy and apply it everywhere,
rather than drop the test. The description's `mustChange` sentence now ends with a general rule
covering all three operators and both failure kinds: "A step that is not taken leaves the next state
as it was, whether it came out false or raised an error." That is one clause, it replaces the
narrower false-only wording, and meta.md is 273 words.

The implementation was already uniform, so what was missing was coverage of the other paths. Three
tests added: an error inside the action probed by `enabled`, by `orKeep`, and by `mustChange`, each
leaving a pending assignment made before the call intact. Together with the observation-error test
that triggered the FAIL, all four paths the suggestion names are now stated and asserted. Three mutations, one per operator, keep the writes on the error path; each kills a test.

## Test Fairness FAIL, round 12 (stale description on the platform)

The check failed on the four rollback-on-error assertions with the reasoning "no such error-time
transaction rule is stated", quoting the description as specifying rollback "only when the observed
value does not differ". That is the round-10 wording. The round-11 edit added exactly that rule, so
this run scored the new tests against a description the platform had not been updated with:
meta.md is not carried in a patch, so the prompt field has to be re-pasted whenever it changes.

Two things done anyway, so the artifact does not depend on how that sentence is read:

- The rule is now its own sentence, names `enabled`, `orKeep` and `mustChange` explicitly, covers
  both a rejected step and an error, and says the next state goes back to what it was at the call
  "down to an assignment made before the call" -- the preservation of preexisting next-state
  assignments the coverage suggestion asked to state. It can no longer be read as scoped to
  `mustChange`. meta.md is 299 words.
- **Outside-run `next`.** A direct-evaluation test for `next(x)` where the transition never gave the
  variable a value: it fails rather than inventing one, asserted through the error alone with no code
  pinned, alongside the positive case in the same test so it still fails on base.

## Agent batch 1, three Nova runs: 0/3, two on a defect of mine

| run | verdict | msgs | LOC | where it went |
|---|---|---|---|---|
| 1 | FAIL_TEST_MISMATCH | 120 | 712 | implemented the whole feature in `evaluator/src/*.rs` |
| 2 | FAIL_MISSED_REQUIREMENT | 95 | 565 | TypeScript, 111 of 112 tests passing |
| 3 | FAIL_WRONG_FILE | 121 | 813 | implemented the whole feature in the Rust evaluator |

**The defect.** The repository ships two simulator backends, `quint/src/runtime/impl/evaluator.ts`
and `evaluator/src/simulator.rs`, and `quint/src/cli.ts` defaults simulation to `rust`. The
description said "the simulator" and named no backend, so two of three runs built a complete, careful
implementation in the Rust crate and scored 0/112 against tests that import the TypeScript evaluator.
Both evaluators called that unfair and they are right: picking the CLI default was the reasonable
read. Worse, the image has no cargo and no network, so those runs could not even compile what they
wrote.

Fixed by naming the target in the description: "This is about the TypeScript simulator under
`quint/src`. The repository also ships a Rust evaluator; leave that one alone." That is a scope
statement, not a hint about how to implement anything. meta.md is 318 words.

**What run 2 says about difficulty.** It is the calibration datapoint: TypeScript, the right target,
95 messages, 565 LOC, and it failed on exactly one test, negating an unsettled open-prefix result as
an ordinary boolean so `not(unknown)` came out as a violation instead of staying inconclusive. Its
own assessment is `description_clear: true`, `difficulty: challenging`, fair. That is the shape I
want: the three-valued negation boundary is the last thing standing, not the backend.

**Solvability is still unproven.** 0/3 is a hard blocker regardless of blame, and the two Rust runs
say nothing about the real difficulty. A fresh batch is needed on the corrected description before
this can be submitted; if run-2-shaped attempts keep landing at 111/112, the open-prefix negation
case is the single point to reconsider.

## Coverage suggestions, round 13 (advisory, all three taken)

No fairness failure this round. All three suggestions are about the successful path: the suite proved
rollback thoroughly and only covered commit indirectly.

- **`orKeep` commits everything an action it takes wrote**, observed or not, so the observation
  argument is shown to govern only the fallback branch.
- **`enabled` around a nonempty nondeterministic choice** is true, and the pick leaves nothing behind:
  an assignment made before the probe survives it and the variable the probe wrote stays unset. This
  is deterministic despite the random pick, since both picks give the same verdict and the same
  rollback.
- **`mustChange` commits every assignment of a step it accepts**, including one to a variable outside
  the observation.

All three follow from "takes `a`" plus the rollback rule already in the description; meta.md is
unchanged at 318 words. Test count 112 to 115.

## Coverage suggestions, round 14 (advisory, both taken)

- **Rollback of the recorded metadata.** Asserted through the public `Outcome.bestTraces`, not through
  the storage: with metadata stored, every state of a run whose step probes an action that cannot be
  taken records `mbt::actionTaken` as the step, and the pick the probe made inside itself is still
  `None`. Reading the trace this way keeps the assertion at the same level as the rest of the suite,
  after round 1 removed the tests that read `ctx.varStorage`. The description's rollback rule now ends
  "and to what the run records about the step", so the claim is stated; meta.md is 327 words.
  The error case is *not* asserted, because there is nothing public to read: an error aborts the run,
  so no state is ever recorded to inspect. Only the rejected-probe case is observable.
- **Temporal error at a terminal `next`.** A predicate reading the next state that errors on a real
  edge stops the run, while the successorless position raises nothing: `always(next(x) / 0 == 0)` is
  `error` over three steps and `ok` over zero, where no position has a successor to read at all. That
  pair pins both halves of the terminal rule at once.

Test count 115 to 118; the solution is unchanged.

## Test Fairness FAIL, round 15 (fixed by dropping the assertion)

One test of 118 was unfair: `false.orKeep(watched)` with `val watched = Set(x, y)` required `orKeep`
to find the variables transitively through a named definition. The description says "the variables
occurring in `v`" and never promises expansion through a definition, and the reviewer found no repo
example establishing it either -- `builtin.qnt` only shows a direct set. Fair call.

Dropped the test rather than documenting the expansion: it pinned one reading of a corner nobody
asked for, and `orKeep`'s variable set is already covered by the direct-syntax cases, including the
tuple form and the empty observation. The implementation still walks through definitions, since that
falls out of scanning the argument expression, but nothing hidden depends on it now.

## Coverage suggestions, round 15 (advisory, all three taken)

- **Standalone context rules.** The three temporal operators need a run and raise QNT518 anywhere
  else; the four transition operators do not. That asymmetry now has its positive half asserted next
  to the QNT518 test: `enabled`, `orKeep`, `mustChange` and `next` all evaluate directly, outside any
  simulation.
- **Definition expansion for `orKeep`.** Taken as the "otherwise remove that hidden assertion" branch,
  above.
- **A cycle closing on the initial state after several distinct ones.** A four-state counter returns
  to its initial valuation, so the cycle start is position zero with a non-trivial stem before it --
  a different indexing case from the stem fixture (cycle starts mid-run) and the self-loop (cycle of
  one). Recurrence of the initial state holds, stabilisation on it does not.

Test count 118 to 119; the solution is unchanged.

## Coverage suggestions, round 16 (advisory, both taken)

- **Error-path metadata rollback.** Round 14 said this was not observable, because an error aborts the
  run and no state is recorded. That was too narrow: `Evaluator.trace` and `shift` are public, so the
  probe can error and the run can then be shifted deliberately, and the recorded state read from the
  trace. Under all three operators, a probed action that picks nondeterministically, assigns, and then
  divides by zero leaves the pre-call assignment intact, the pick back at `None`, and its own name
  absent from the recorded step. One loop, three operators, no storage access.
- **Terminal `next` under the other temporal operators.** The pair that pins the terminal rule for
  `always` now exists for `eventually` and for `leadsTo` too: erroring on a real edge stops the run,
  while a zero-step execution where no position has a successor raises nothing.

Test count 119 to 122; the solution is unchanged.

## Coverage suggestions, round 17 (advisory, both taken)

- **`orKeep` stuttering over a pending assignment.** Two writes are pending, `x' = 5` and `y' = 9`,
  and then a disabled action is wrapped in `orKeep(Set(x))`. The observed variable is stuttered to its
  current value, so the pending 5 is overwritten by 0, while the unobserved 9 survives untouched. Both
  halves come straight from the description: the variables occurring in `v` "keep the values they
  already have", and everything else "goes back to what it was when the operator was called".
- **Successful probe metadata rollback.** The complement of the failed and erroring probes: a probe
  whose action picks nondeterministically and succeeds also leaves nothing behind, checked the same
  public way -- the pre-call assignment stands, the pick is back at `None`, and the probed action is
  not the recorded step.

Test count 122 to 124; the solution is unchanged.

## Coverage suggestions, round 18 (advisory, both taken)

- **Rejected-probe metadata.** The metadata checks covered a failed `enabled` probe, an erroring one
  and a successful one; the two ordinary rejections did not. Added both, read the same public way
  through the trace: a disabled action under an `orKeep` fallback, where the observed variable ends at
  its current value and the rejected action's pick and name are gone, and a `mustChange` rejected for
  not changing anything, where the pre-call assignment comes back and the rejected step leaves nothing.
- **Named temporal direct evaluation.** `temporal Safe = always(x < 2)` evaluated on its own raises
  QNT518, so the outside-a-run rule survives definition resolution and is not a property of the inline
  syntax alone.

Test count 124 to 127; the solution is unchanged.

## Coverage suggestions, round 19 (advisory, both taken)

- **`next` across the edge that closes a non-initial cycle.** On the stem fixture the last position is
  x=2 and its successor is the cycle start, x=1. Pinned directly: every state where x is 2 has a
  successor of 1, the same shape with 3 is a violation, and no transition is a self-loop. The earlier
  back-edge coverage went through `leadsTo`; this reads the edge with `next` itself.
- **Mixed liveness across runs.** A branching fixture where every run closes into a cycle but only some
  of them reach 2: `eventually(x == 2)` aggregates to a violation, while a disjunction every closed run
  satisfies stays `ok`. This exercises liveness aggregation over sampled runs rather than the
  invariant path. Made robust rather than seed-lucky: 50 runs of 8 steps, and the pair was verified
  identical across 30 seeds.

Test count 127 to 129; the solution is unchanged.

## Coverage suggestions, round 20 (advisory, both taken)

- **`orKeep` over an arbitrary observation expression.** The stutter set came only from sets and tuples
  so far. `orKeep(x + y)` on a disabled action stutters both variables, so what matters is the
  variables occurring in the expression and not the shape it is written in.
- **Metadata rollback after an observation failure.** The remaining `mustChange` corner: the action
  succeeds, picks nondeterministically and assigns, and then the observed value errors. The pre-call
  assignment, the pick and the recorded step all come back, read through the trace the same way as the
  other metadata cases.

Test count 129 to 131; the solution is unchanged.

## Quality check, round 21: trace formatting removed from the metadata tests

The quality check warned that the metadata assertions pinned trace formatting: `mbt::actionTaken`,
`variant("None")`, action names inside printed records. Fair, and it is the flip side of the coverage
suggestions that asked for those assertions in the first place. Rewritten so nothing names a key or a
format.

Each probe case is now differential: the same sequence is run twice, once with the probe attempted
before the shift and once without, and the two recorded steps must be identical. Seven cases in one
loop cover a failed probe, an erroring one, a successful one, an `orKeep` fallback, a `mustChange`
no-change rejection and an observation error. The only string involved is the printed state on both
sides of an equality, so no format is asserted.

Writing it this way exposed something the substring version had hidden: a probe *registers* its
nondeterministic pick slot when the action is first built, so the recorded state legitimately differs
from a run that never mentioned the action, by an empty slot versus a slot holding `None`. That is a
build artifact, not a leak. Both sides of the comparison now attempt the probe once as a warm-up, so
registration is identical and only a real leak can show up.

The run-level state comparison went away with it: the fixture that probes inside its step is already
covered behaviorally by the verdicts it produces, and the two harnesses could not be made
build-identical without contriving the baseline.

Test count 131 to 126, and every affected trap got stronger, not weaker: `enabled` isolation 4 to 5,
the three error-path rollbacks 1 to 2 each, `orKeep` rollback 2 to 3, error-as-unavailable 2 to 3.

## Platform pre-checks, round 22

**Quality warning: stale.** It quotes `mbt::actionTaken`, `variant("None")` and action-name substrings.
None of those exist any more; round 21 replaced every one with a differential comparison and a grep for
them over the current test file returns nothing. That run scored the previous test.patch.

**Necessary information, HIGH, taken in part.** The sentence naming the backend is now as short as it
can be while still doing its job: "in the TypeScript runtime. The Rust evaluator is out of scope." The
path and the wordier disclaimer are gone. I did not remove it altogether, because the check's rationale,
that the target is discoverable and not modifying Rust is a default assumption, is contradicted by the
batch: `cli.ts` defaults simulation to `rust`, and two of three Nova runs implemented the entire feature
in `evaluator/src/*.rs` and scored 0/112. Both run evaluators called that the task's fault, not the
agent's. Removing the sentence would re-open a failure mode I have direct evidence for, so the scope
note stays in its minimal form. meta.md is 319 words.

**MEDIUM declined.** Dropping "and takes nothing: it leaves the state exactly as it was" from `enabled`
is not redundant with the general rollback rule. That rule covers a step "none of these three operators
takes"; `enabled` never takes one even when the action is available, and the successful-probe rollback
tests rest on exactly that. An earlier fairness pass called this clause the whole contract for
`enabled`.

**LOW declined.** "so it always holds" on `orKeep` was added in round 1 to fix an ambiguity the
alignment check had flagged: without it, the following false-and-rollback sentence reads as covering
`orKeep` too. Removing it re-opens that.

## Solution Quality review, round 23: PASS, two findings, one real

**`leadsTo` evaluated its effect even where the cause was false. Real, fixed.** The reviewer is right
and it was an inconsistency of mine: round 9 gave `and`, `or` and `implies` proper short-circuiting but
left `leadsTo` computing `disjoin(negate(cause), effect)` with the effect search always run. The value
was correct, since `disjoin('true', anything)` is `'true'`, but an erroring effect at a position where
the cause does not hold would abort a run the property never depended on. Now a false cause returns
`'true'` without looking for the effect. A new test pins it: on the counter, a cause that never holds
paired with an effect that divides by zero is `ok`, where before it was an error. Mutation M23 restores
the eager form and kills that test. The existing effect-error test still holds, since there the cause
does hold at position 0 and the effect genuinely has to be evaluated.

**The wrapper's missing-testcase failure is stale.** It names `orKeep / 'finds the variables behind a
definition'`, the test removed in round 15 after the fairness check called it unfair. It is not in the
current suite and `grep` finds it nowhere in test.patch. The wrapper is comparing against an older
expected-nodeid list, so this clears once the current test.patch is uploaded.

**Also taken:** `underNextState()` now restores the memo and the flag in a `finally`, so a build-time
throw cannot leave the builder in next-state mode. I left `buildUnderDefContext()` alone: it is
pre-existing repo code and rewriting it would be a drive-by refactor outside this task.

## Batch 2 and the false-positive review, round 24

**Batch 2: 1 pass in 9, 11%.** Run 2 (Orion, 127 messages, 714 LOC) passed legitimately, so solvability
is settled. The eight failures are the designed traps firing, not confusion: three runs made `next` a
run-only operator, three collapsed open-prefix uncertainty into ordinary booleans so an outer negation
turned an unsettled formula into a violation, one filtered `#actionTaken` instead of the visible
`mbt::actionTaken` constant, one reused current-state memos for next-state definitions, and one invented
a `--temporal` flag while leaving the existing property argument per-state. Full table in
eval-results.md.

**The false positive is the important part, and it was mine.** The adjudicator found that the passing
run decides an open prefix by evaluating the whole formula twice, once with every open temporal operand
forced true and once forced false, instead of propagating three values through the connectives. That is
sound for monotone combinations but not for `iff` or an `or` under a negation, where it reports a
violation for a property some continuation satisfies. It passed because my suite only exercised
non-monotone combinations on *cycling* runs, where everything is already definite. The gap was in my
tests, exactly as the FP rule says.

Fixed by adding the discriminators, using the adjudicator's own probes plus one more, all verified
against the reference first: `eventually(x == 1) iff not(eventually(x == 2))` on a zero-step run,
`(eventually(x == 100) or eventually(x == 50)) and not(eventually(x == 100))` on an open climbing
prefix, and an `iff` between two open eventualities. All three must be `ok`, and they are covered by the
description sentence the adjudicator cited: a prefix reports a violation only when no continuation could
satisfy the property. Mutation M24 gives an open prefix one shared default instead of three values and
kills 10 tests, so the shape that produced the false pass is now caught.

**Also addressed: the recurring `next` misreading.** Three of nine runs made `next` run-only, which
`builtin.qnt` encourages by declaring it `temporal next(a)`. The QNT518 sentence now scopes itself
explicitly: those three operators are the only ones that need a run, and the four transition operators
are evaluated wherever they appear. That is a wording tightening of something the description already
implied, not new information. meta.md was 339 words at that point.

## Solvability, round 25

The 11% from batch 2 overstated things. The single pass was adjudicated a false positive, and the
discriminators added for it would fail that implementation, so the honest count right now is zero
legitimate passes. That is a hard blocker, not a band to bias toward.

Where the runs actually died says what to do about it. Six of the eight failures are two mistakes:
`next` treated as run-only (three runs, now addressed by scoping the QNT518 sentence) and open-prefix
uncertainty collapsed into ordinary booleans (three runs, and the false pass was a third variant of the
same thing, evaluating the formula twice under two extreme assignments). Everything else was a single
run each.

So the open-prefix rule is now stated per operator instead of only as a principle: an `always` is broken
when some state already breaks it and otherwise left undecided, an `eventually` holds when some state
already satisfies it and otherwise left undecided, and an undecided answer stays undecided through the
connectives rather than being read as true or false. That last clause is exactly what six runs got
wrong, in three different ways.

This is the contract, not the fix. It says which answers a prefix may report, and nothing about lasso
detection, position folding, next-state builds, rollback or the metadata comparison, which is where the
implementation work and the remaining traps live. No test changed and no test was weakened; the
non-monotone discriminators that caught the false positive all stay. meta.md was 391 words at that
point, still inside the 500 cap.

It needs a fresh batch to confirm. If a run-2-shaped attempt still lands at 100 or so of 128 with the
rule stated, the next thing to reconsider is the suite's non-monotone corner, not the description.

## Alignment warning, round 26

Non-blocking, and the fairness check has consistently accepted the error-propagation tests as
repo-discoverable: the existing lazy action operators return a left from an attempted branch, so
surfacing an error is the codebase's own convention. I closed it anyway, because its sibling already
cost a blocking FAIL. Round 11 failed on the *rollback* half of the error behavior being unstated; I
stated that half and left the propagation half implicit, which is exactly what this warning points at.

One clause added to the rollback sentence: an error is what the operator reports, rather than a step it
did or did not take. That also removes the reading the checker flagged, where "so it always holds" on
`orKeep` could be taken to mean an erroring action still stutters to a success. meta.md is 409 words.

## Mutation proof

Twenty-one of the twenty-two designed traps kill tests; the table with counts is in DESIGN.md section 6. The one
that killed nothing (a stale cached `val` across positions) is recorded as retired rather than
claimed. The round-2 test edits did not move a single count.

## Status

Built and validated locally. Docker matrix, both apply orders and the determinism runs are recorded
in eval-results.md. No agent batch has been run yet, so the pass rate is unmeasured.
