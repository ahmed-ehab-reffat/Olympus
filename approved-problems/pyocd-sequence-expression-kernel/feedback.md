# feedback.md - pyocd-sequence-expression-kernel

**ACCEPTED 2026-09-24 at 5/10 (batch 2), archived.** Finalized: F-52 (new), L92, L93, Pattern 104;
batch 2 table in eval-results.md; dossier in failure-patterns.md § 2.

## Status

Round 5. **Batch 1 came back 0 of 11 - unsolvable.** Diagnosed, cut, re-measured at 2 of 11 = 18%
against the same agent solutions. The Auto Review before that batch was APPROVED with two notes,
both now closed.

Three rounds of pre-batch review found five real defects, all fixed:

- Round 1 (FAIL): a call result was never reduced to the domain, and a compound assignment read
  its target after the right hand side.
- Round 2 (FAIL): a control predicate bypassed the value-kind check, so `IfControl("DAP_Delay(1)")`
  ran the void call and was coerced to zero. Round 2 also FAILED the test-quality gate for the
  folding tests asserting AST shape through `_ConstantFolder`, and warned that base mode was
  running newly added tests from the modified existing file.
- Round 3 (FAIL): variadic integer arguments bypassed the same value check, because the repo's
  argument walk breaks out of the signature loop at the varargs parameter, so
  `Message(0, "%d", DAP_Delay(1))` ran the void call. The check now lives in one helper that both
  the fixed walk and the variadic tail call.

The value model is now closed at every boundary where a value enters or leaves an expression,
including the one context that is evaluated for its value rather than run for its statements. The
FINISH levers from DESIGN section 7 are in (levers 1, 2, 4 and 5); lever 3 was dropped as
unobservable and lever 6 on flakiness grounds.

- Repo: pyocd/pyOCD, Apache-2.0, 1462 stars, Python 99.7%, 0 of our 6 submissions.
- Base commit d1974ffdd16369148ba678478fa85886282d09b1 on `main`.
- Capability: one evaluation model shared by the constant folder, the interpreter, the semantic
  checker, the control predicate loop and the sequence function delegate, so that whether an
  operand is written as a literal cannot change a block's value OR the stream of calls and
  transfers it produces.

## Numbers

- solution.patch: 413 raw / **243 human-effective** across 4 files (`values.py` NEW,
  `sequences.py`, `scope.py`, `functions.py`). Was 182 raw / 107 eff in the slice.
- test.patch: test.sh + 90 new test functions (150 cases) + a 3-row deletion in the repo's own fold
  table. That deletion is now the ONLY change to an existing test file, so base mode contains no
  newly added test.
- Clean room, `--network none`, uid 1000 and root: base 1138 pass in all four configurations (the
  repo's own untouched baseline); new 150/150 fail on base and 150/150 pass with the solution; 3x
  identical, also as root and as an unmapped uid.
- Mutation self-check: 25 of 25 single-point mutations killed, each run against BOTH modes.
- Every one of the 150 cases fails on base, so no new test can leak into the P2P set.
- Measured pass rate after the cut: **2 of 11 = 18%** (replay over the batch-1 solutions).
- No test touches a private symbol: the new file imports only `Scope`, the node classes, the
  execution context, the error class and the common functions delegate.

## Round 11: Solution Quality (string-returning calls, the third time)

Rounds 8, 10 and 11 were all one question. The reviewer overrode the round-10 boundary sentence,
so the solution now does what both reviewers asked: a `-> str` call is rejected statically
wherever a value is required, and at run time anything that isn't an integer produces no value,
in the same expression that handles `None`. The contract names string-returning calls in the value
rule and scopes the statement rule to "a function that returns nothing", so a string call as a
bare statement is neither promised nor tested. That is what kept the tests safe: the statement
case is the one that replayed 0/11. Three position tests added (replay cost 0), plus the full
literal-vs-variable operator matrix (25 rows that base gets wrong; replay cost 0).

Replay (byte test excluded): **2 of 11 = 18%**.

## Round 10: Solution Quality (a string-returning call as a statement crashed)

My round-9 bug: the checker allowed `Label();` but the interpreter fed its string to `to_value`.
The tests the reviewer asked for replayed at 0/11 - both near-misses fail on them alone. Checking
the repo showed no sequence function returns a string at all (23 return `int`, 16 return `None`,
and the delegate docstring says so), so the string-return path came from a hypothetical delegate.
Cut in contract, solution and tests together; meta.md now opens the rule with the repo's real
boundary, "Every sequence function returns an integer or nothing, and only an integer is a value".
Also added the identity-literal matrix in a form that fails on base (replay cost 0).

Replay: **2 of 11 = 18%** without the byte test; 0 of 11 with it (those agents never saw the
byte sentence, so that number is not a prediction).

## Round 9: Auto Review (Description 1/3, Tests 1/3)

Two Highs, both real. (1) "a string cannot be ... an argument" banned `Message`'s own format
string; reworded to name both sides - no string "to a parameter that takes an integer", while "a
parameter that takes a string, such as the format of Message, still takes one". (2) The JTAG byte
gap for the third time. This review weighed the round-7 contest and rejected it, so the contest is
dead. The byte form is now STATED in meta.md with a literal example ("the bytes 0x34 0x12 are the
value 0x1234") and tested in exactly that form.

**Risk, stated plainly:** the replay reads 2/11 without the byte test and 0/11 with it, but the
0/11 is agents that were never told about bytes. A replay can't measure a description change. If
batch 2 reads 0, the fallback is to withdraw the byte form from contract and solution together.

Also: a fixed-integer-parameter string test (through `Label()`, so it fails on base; replay cost
0); the author's SWJ/JTAG sentence split; meta.md trimmed from 517 back to 493 words.

## Round 8: Solution Quality (str returns, abort again)

`-> str` delegate returns now classify as STRING (test added, replay cost 0). The abort write came
back because the round-7 scoping ("the Write functions") matched `DAP_WriteABORT` by name, and the
advisory list started asking for read-side masking off the same general sentence. Author decision:
the transfer rule is now a closed list of the exact functions the solution reduces. Abort and reads
are outside it and untouched by the reference. The literal-substitution table was also added (replay
cost 0). Replay **2 of 11 = 18%**.

The JTAG list/bytes contest from Round 7 still applies if the Tests gate raises it again.

## Round 7: Auto Review (Revision Requested, Tests 1/3)

Seven High coverage gaps and one Medium. Each requested test was replayed against the saved batch
before shipping. Six cost nothing and shipped: void call as a whole initialiser, void call as a
whole assigned value, `WriteAP`, `WriteAccessAP`, `WriteDP`, and the last statement deciding a
multi-statement predicate. Two would make the problem unsolvable:

- **SWD `DAP_WriteABORT`** - both near-misses fail that test alone. Cut from the contract and the
  solution together: meta.md now scopes the width rule to "the Write functions", and the abort
  command is a `DAP_` probe command, not one of them.
- **JTAG list/bytes response** - every run fails it (measured round 6). **Contest this one** (text
  below). It can neither be tested (0/11) nor cut (without the conversion, the function-result rule
  turns a real CMSIS-DAP response into a `TypeError`, which round 6 already failed).

Contest text, ready to paste:

> The JTAG list/bytes gap asks the hidden tests to require an undocumented backend quirk. The probe
> interface documents `jtag_sequence(...) -> Optional[int]` ("Either an integer with TDI bit values,
> or None"); only the CMSIS-DAP protocol layer returns the raw `resp[2:]` slice. The description says
> nothing about probe backends, so a solver working from the description and the documented API has
> no way to learn this requirement, and testing it would be a hidden requirement. The reference
> converts the byte form only so it does not regress real hardware relative to the base commit. We
> measured the cost of the requested test against the recorded agent solutions: it takes the pass
> rate from 2 of 11 to 0 of 11, and every run fails it.

Replay after round 7: **2 of 11 = 18%**.

## Round 6: post-cut Solution Quality review

Two real findings. (1) A declaration used as a predicate ran and was silently false - round 5's
contract blessed void-call predicates but not declarations. Closed with one uniform rule in
meta.md ("a last statement that produces no value ... makes it false"), which is base behaviour, not
by re-adding the rejection that caused batch 1's 0/11. (2) A real CMSIS-DAP probe reports JTAG TDO
as bytes (hidapi, pyusb) or an int list (pywinusb), not the documented int; `dap_jtag_sequence` now
converts it little-endian before masking.

**The byte-response test was written, replayed, and withheld:** with it the replay reads 0 of 11 -
every run failed it, both near-misses on that test alone. The fix ships in the solution; the test
does not. Replay stays at **2 of 11 = 18%**.

## Batch 1: the 0% and the cut

All 11 runs (10 Nova + 1 Vega) passed the baseline, failed the new suite, and were graded
FAIL_MISSED_REQUIREMENT with no environment blocker, `description_clear: true` and
`difficulty: challenging`. So the artifact was fair; it just demanded more independent rules than
an agent finishes.

Three tests for ONE rule killed 8 of 11, and BOTH near-misses failed nothing else: "a value is
required for the predicate of a conditional or a loop", the round-3 addition. That rule is now
gone from meta.md, the solution and the tests. What stays:

- The conditional-BRANCH checks. No agent failed those, and they are the form the round-3 reviewer
  actually recommended.
- The hole is closed by declaring it instead of checking it: meta.md now says a call that returns
  nothing is valid as a statement "including when that statement is the whole of a conditional or
  loop predicate". A predicate that produces nothing is false, which is what the base engine
  already does, so nothing is left unstated.
- The generic "where a value is required" promise is narrowed to "an operand, an argument, or a
  branch of a conditional expression" - the exact positions that are checked. The generic phrasing
  is what let the round-3 reviewer point at predicates in the first place.

Two description clauses were also made concrete, since the cut forces a full-price batch anyway
and the call/scope boundary was the second-biggest killer (7, 7, 7 and 6 kills): "A variable set to
a negative value reads back as the unsigned form of it, and a sequence function receives the
unsigned form of every value it is passed." Replay cannot measure a description delta (L35), so the
18% below does not count it.

Auto Review notes, both closed: a JTAG return assertion at a count of 64 or more (added, asserted
together with the sent direction so it fails on base), and the dead `_format_atom` helper (removed).

**Replay: 2 of 11 = 18%**, baseline green in all 11, measured by re-running every saved agent
solution against the trimmed suite with their own test edits excluded, exactly as the grader does.
The next levers if a fresh batch reads 0: Vega #1 now fails only the JTAG tests (dropping the
bit-sequence half of the transfer rule is a measured +1, to 27%) and Nova #4 fails only two. The
user chose to keep the transfer contract whole and ship at 18%.

## Round 4 findings and what they got

10. **"Variadic integer function arguments bypass the new value-required validation."** Correct.
    Round 2 put `_require_value` inside the repo's signature walk, which covers every FIXED
    parameter and stops at the `VAR_POSITIONAL` break, so `Message(0, "%d", DAP_Delay(1))` ran the
    void call. The per-argument check is now a helper called from both the fixed walk and the
    variadic tail, so the rule lives in one place instead of one path. An UNANNOTATED varargs
    parameter stays unchecked, exactly as an unannotated fixed parameter does, which is what keeps
    the repo's own `valid_fn_varg(123, x, q + 1, "hi there", 99)` passing in base mode.
11. **Two advisory coverage suggestions, both taken.** The conditional-branch cases now include
    the branch that is NOT selected (a run-time-only checker passes the old ones), and the
    bit-sequence cases now cover counts 0, 1, 4 and 16 rather than only 8 and >= 64.

## Round 3 findings and what they got

5. **"Control predicates bypass the new value-kind validation."** Correct for the void-call half.
   Verified before changing anything: `IfControl("DAP_Delay(1)")` ran the call and coerced it to
   zero, and `1 ? DAP_Delay(1) : 2` as a predicate did too. The reviewer's other example,
   `IfControl('"text"')`, was ALREADY rejected by the repo's own pre-existing `expr_stmt` string
   check, so that half of the finding was not live. Fixed by giving the checker the one piece of
   context it lacked: `Control` evaluates its tree for a value, so the tree's last statement must
   be an expression statement that produces one. Both branches of a conditional are now required
   to be values at the point they are written, which is the robust form the reviewer suggested and
   which let `_expression_kind` drop its conditional recursion.
6. **Test-quality FAIL on `TestSequenceConstantFolding`** (private `Parser` / `_ConstantFolder`,
   asserting `LarkTree` shape). Deleted. Its two claims are already asserted behaviourally by the
   effect tests, and the folds that must STILL happen stay pinned by the repo's own
   `TestConstantFolder` in base mode, which is pre-existing rather than newly added.
7. **Base/new separation warning.** The five fold rows added to `test_debug_sequences.py` last
   round are removed, so `test.patch` only deletes from that file now.
8. **Alignment warning: call-argument order not stated.** Added to meta.md.
9. **Description brevity (advisory).** The HIGH suggestion was applied (the "already correct
   sequences keep working" sentence is gone). Two MEDIUM clauses and the LOW clause were kept
   because each is the only sentence backing a test; see risk 5.

## What the round 1 review said, and what it got

1. **"Function-call results are not reduced to the unsigned 64-bit domain."** Correct, and the
   slice caused it deliberately: slice decision 5 deleted that normalisation as dead code because
   `Scope.set` already normalised. A call result reaches a comparison, a shift count and an
   argument without passing through a scope store, so it was not dead. `fncall` now reduces both
   the value it returns and every value it hands to the delegate.
2. **"Compound assignment evaluates its left value after its right operand."** Correct.
   `visit_children` evaluated the whole tree before the target was read. `assign_expr` now reads
   the variable first for a compound operator, and the four-test `TestSequenceCompoundAssignment`
   class pins it.
3. **Ten coverage suggestions.** All covered, and every suggestion that was "not discriminating"
   was made discriminating rather than added as-is (see below).
4. **Category warning (`bugfix` suggested).** meta.md was reframed. See risk 2.

## Decisions made without asking (rounds 2 and 3)

1. **Every new test fails on base.** Six tests the coverage suggestions ask for do not discriminate
   on their own (left-to-right order for ordinary operators, zero divisors, `==`/`!=` on a wrapped
   value, a void call as a statement, a call result as an operand, and the folds that must still
   happen). Rather than ship them as tests that pass on base, each was either given a second
   assertion that only the new model satisfies (a wrapped operand, an effectful dividend, a
   comparison against a wrapped literal) or moved into `test/unit/test_debug_sequences.py`, where
   it runs in BASE mode and becomes a real regression guard. The platform's Verify step wants the
   F2P set to fail without the solution, so a base-passing test in the new file is a liability.
2. **Nothing new is added to base mode.** Round 2 put five "a pure operand is still folded" rows
   into the repo's own `TestConstantFolder`; round 3 removed them, because the sanity gate counts
   any newly added test that base mode runs as lost separation. The repo's own 30 fold rows
   already red if a solution stops folding pure operands, so the guard survives without adding
   anything. `test.patch` now only DELETES three rows from that file.
3. **The width model was extended to `functions.py`** (DESIGN lever 1). A word written by a fixed
   width write, and the bits a sequence function sends or reports for a bit count, are reduced to
   that width; a width of 64 or more carries the whole value. The clamp is load-bearing: without
   it, `DAP_SWJ_Sequence(0 - 1, 0x55)` builds a 2**64-bit mask and dies. Read functions were NOT
   masked: a real AP cannot return more bits than the transfer, so that code would be unreachable
   and dead code is a revert cause.
4. **The "only an integer is a value" rule** (DESIGN lever 2) is reported by the semantic checker,
   which the repo's own docstring says runs "so semantic errors are raised prior to actually
   performing any actions". A string reaches an operator only through a conditional, a parenthesis
   or an assignment, because the grammar keeps `STRLIT` out of the operator rules; the kind
   analysis is recursive for exactly that reason.
5. **Two mutation survivors were fixed at the source, not with new tests.** Both were redundant
   normalisation (the scope re-read after an assignment, and operand reduction inside
   `evaluate_binary`). The invariant is now one reduction per boundary.
6. **Three advisory coverage suggestions were added and two declined.** Added: a `Write16` case, a
   positive oversized argument (a value above 2**64 handed to a delegate, which a solution masking
   only negatives would miss), and a bit count of exactly 64 carrying a wrapped value. Declined:
   `Read32("a")` is already rejected on BASE by the repo's own argument-type check, so it would be
   a base-passing test in the new file, and a `default_sequences.yaml` end-to-end trace is what
   base mode already is.
7. **`_expression_kind` stopped recursing into a conditional** when the branch check landed. Two
   paths deciding the same thing is exactly what produced the surviving mutants last round.
8. **DESIGN lever 6 (the `Control` timeout interaction) was dropped.** Every test in this problem
   has to be deterministic, and arming-vs-firing on a timeout is the one lever here that would put
   a clock in an assertion.

## Risks, in the order a reviewer will meet them

1. **LOC.** 243 human-effective clears the 200 floor but sits under the 275 design target, and the
   hook flags a padding-floor of 166 because the operator table is 18 rows. A reviewer who
   discounts the table as moved code (it replaces `_BINARY_OPS` / `_UNARY_OPS`) lands near 219. The
   honest position: the table rows are not the pick; the folder/interpreter reconciliation, the
   effect analysis, the kind analysis and the boundary reductions are.
2. **Category.** The platform picker suggests `bugfix` because the description explains what the
   engine does not settle today. meta.md now states the gap in one clause ("The engine has no
   single answer for those three questions today") and leads with the ask. The standing preference
   is `feature-request` and the title verb is Add, so it ships as `feature-request`.
3. **Scope breadth.** The model now touches four files and five consumers. Each addition is a
   boundary the value domain has to cross, and each is stated in meta.md in one sentence, but a
   reviewer may read the checker rule or the transfer width as a second feature. Both are defended
   above.
4. **Kept clauses the brevity gate wanted cut.** "A value handed to a sequence function is a value
   of this domain" is the only sentence covering `test_a_function_argument_is_a_value_of_the_domain`
   (the transfer-width rule covers the real delegate, not the value the interpreter hands a
   recording one), and "which is the value the variable ends up holding" defines what an assignment
   is worth. Both gates are advisory; the "every tested behaviour is documented" rule is not.
5. **Two `while` fixtures.** Bounded twice over (the test target stops reporting a non-zero word
   after eight reads, and each loop carries a 5 s control timeout) so a wrong solution fails
   instead of hanging the runner. The correct solution exits in microseconds, so no assertion
   depends on the clock.

## Gates re-run (round 2, unchanged since)

- Gate 5 cold-not-live: `git diff BASE origin/develop` on `sequences.py` and `scope.py` is EMPTY.
  `functions.py` (newly in scope) has 18 added lines on develop, all in the trace-buffer streaming
  lane (`bufferstreamout` format 1, new `tracebufferselected`). Nothing upstream touches the write
  or bit-sequence functions.
- Gate 7b exclusivity: canonical org resolves to `pyocd/pyOCD` (no redirect). The only open PRs
  listing anything under `pyocd/debug/sequences/` are still #1604 and #1687, both carrying only the
  already-merged `assign_expr` rename through a stale base, and neither lists `functions.py`.
  Feature-class PR searches for short circuit, constant fold, side effect, 64-bit, unsigned,
  transfer width and sequence expression return nothing in the lane.
- Gate 9 flakiness: 3x identical in four configurations plus two root runs; no sleeps, RNG,
  network or clock assertions.
- Gate 10 quota: 0 of 6.
- Dedup: no `pyocd` anywhere in approved-problems/, problems/, rejected/ or SATURATED-REPOS.md.

## Owed

- Requirement 0: the platform PICKER check for `pyocd/pyOCD` has NOT been done.
- Platform precheck re-upload.
- Re-run the SIX-CHECK and the canonical-org PR-DIFF immediately before submit.
