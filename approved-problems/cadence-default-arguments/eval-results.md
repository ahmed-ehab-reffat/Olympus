# eval-results.md - cadence-default-arguments

Base: `64b1ef2276fc22199a75991580ebe2464f494e4c` (onflow/cadence, master, 2026-07-13)
Image: `olympus-base-go` (go1.26.3), all runs `--network none`, non-root (`-u 1000:1000`).

## Environment gate (before any authoring)

| Run | Command | Result |
|---|---|---|
| vanilla 1 | `go test -count=1 ./...` on the unpatched repo, offline | 36 packages ok, 0 fail, 76s |
| vanilla 2 | same, non-root | 36 packages ok, 0 fail |

## F2P matrix

Both patches applied with `git apply` to a clean checkout of the base commit, in that
order, and run through the submission Dockerfile image.

| Mode | Test cases | Failures | Verdict |
|---|---|---|---|
| `./test.sh new` on base (test.patch only) | 49 | 49 | every new test fails on base, no vacuous pass |
| `./test.sh base` on base (test.patch only) | 28040 | 0 | baseline green with the updated base test |
| `./test.sh new` with solution | 49 | 0 | |
| `./test.sh base` with solution | 28040 | 0 | no regression |

Both apply orders are clean: test.patch then solution.patch, and solution.patch then
test.patch.

Re-verified after the precheck Dockerfile fix (the test invocation was replaced with
`go vet`), this time with the image built from a CLEAN base checkout and no cache mounted
from the host, so the container runs on nothing but what the image carries:

| State | Mode | Test cases | Failures |
|---|---|---|---|
| test.patch only | `new` | 49 | 49 |
| test.patch only | `base` | 28040 | 0 |
| both patches | `new` | 49 | 0 |
| both patches | `base` | 28040 | 0 |

The new-mode run takes 9 seconds in that image, so the `go vet` warm-up leaves the build
cache in the same usable state the removed `go test` line did.

## Flakiness (mandatory gate)

| Run set | Result |
|---|---|
| `new` x3 with solution | 49 cases / 0 failures, identical every run |
| `base` x3 with solution, first attempt | 0 failures every run, but the case COUNT moved: 28150 / 28150 / 28147 |
| `base` x3 with solution, after the fix below | 28040 / 28040 / 28040, 0 failures |

Zero tests ever failed, but the reported test SET drifted, which is the failure mode that
makes a verifier report missing baseline tests. Diffing the reported names across runs
found two existing sources, neither related to this change:

1. `interpreter.TestStringer` (interpreter/value_test.go) adds entries to the map it is
   ranging over, so how many `optional ...` subtests it generates depends on Go's map
   iteration order. This is the main source: the symmetric difference between two runs is
   13 to 16 subtest names, all of them `TestStringer/optional_...`.
2. `interpreter/values_test.go`'s `TestInterpretSmokeRandom*` and `TestRandomValueGeneration`
   seed their generator from the current time (`-smokeTestSeed` defaults to -1).

Both are skipped in base mode, with the reason recorded in `test.sh`, and the reporter now
parses `go test -json` (`go-junit-report -parser gojson`) instead of interleaved `-v` text.
The new tests are not affected: they were identical across every run from the start.

Every negative test (a case which must still be rejected) carries a canary assertion in the
same test function that only passes with the feature, so nothing passes vacuously on base.
Verified mechanically: the JUnit XML from base mode has zero `<testcase>` nodes without a
`<failure>` child, and no `[build failed]` node, so each test is a named node.

## New tests (92 nodes)

Test Fairness (2026-07-27) rated 50 of 51 fair and flagged one,
`sema/TestCheckDefaultArgumentInferredFunctionType`, for pinning an under-specified choice:
an unannotated binding keeping omission rights. Both of its coverage suggestions were then
taken, so that behavior is now DOCUMENTED in the description ("a binding which takes its
type from a function keeps them, while writing that type out drops them") and covered at
runtime as the suggestion asked, rather than dropped. Counts below reflect the final set;
every number in this file was re-measured after it.

A second Test Fairness round flagged five negative tests for pinning an exact diagnostic
COUNT (`RequireCheckerErrors(..., 1)`) without asserting a kind: the description makes each
program invalid but never fixes how many errors a solution reports. All five now assert
`require.Error` instead, so they still demand the rejection without constraining its shape.
The one remaining bare count, `DestroyEventKeepsRestrictedExpressions`, is pre-existing
destroy-event behavior that `sema/events_test.go` already asserts in the same shape.

A third round raised no unfair test, only coverage suggestions: erasure at a real call
boundary (a helper whose parameter or return type is written out), an interface-typed call
whose reached member has both a body and a default, and diagnostic specificity for the broad
negative checks. All three were taken; the last one without re-pinning diagnostics, by giving
each broad negative test a positive control in the same function so an unrelated failure
cannot satisfy it.

A fourth round again raised no unfair test. Its three suggestions were taken: the resource
restriction is now shown independently of purity (an `@R?` parameter defaulted to `nil`, an
expression which is view and allocates nothing), the parser test asserts the retained
default expression itself (kind, value, literal and exact range) rather than only
`HasDefaultArgument()`, and every broad negative now asserts a `*sema.CheckerError` with a
non-empty error list, which rules out parse failures and crashes without pinning a
diagnostic kind or count.

A fifth round found no unfair test, and probing one of its suggestions found a real defect in
the reference: `compose(first: 1, third: 30, third: 300)` was accepted, binding one parameter
twice while `second` silently took its default, because sparse matching let a duplicate label
keep an identity index that happened to match. Fixed in
`sema/check_invocation_expression, malformed default expressions.go` (`checkUnmatchedArguments`) and covered by
`TestCheckDefaultArgumentSparseCallDuplicateLabel`. The solution grew from 275 to 319
human-effective LOC as a result.

A sixth round again raised no unfair test. Its suggestions were probed before writing
anything: sparse omission on an initializer and on a member method (different checker paths
from a free function) both worked and are now covered on the checker and the interpreter
side; defaults whose type CONTAINS resources (`@[R]`, `@{String: R}`) were already rejected,
since `TypeAnnotation.IsResource` covers a container of resources, so they were added as
regression tests without a solution change.

A seventh round failed one test: `TestCheckDefaultArgumentBeforeParameterWithout` asserted a
`*sema.CheckerError` and so pinned the compiler PHASE, although the description never says
whether the ordering rule is syntactic or semantic, and the repo's closest analogue is
parser-enforced. It is now phase-neutral: if the parser already rejects the program the test
is satisfied, otherwise the checker must reject it. The same phase-neutral shape covers
function expressions and initializers. Evaluation ORDER also turned out to be observable,
through which runtime error wins between `empty[0]` and `1 / zero` defaults, so it is now
stated in the description and tested in both directions.

An eighth round raised no unfair test but caught a vacuous assertion in the order test:
`require.NotErrorIs` against a nil typed pointer can never fail. It now asserts
`errors.As` is false for the array-index error AND positively matches
`values.DivisionByZeroError`. Also added: a call omitting the FIRST parameter, and a
cross-program import case proving a default reads the DECLARING program's global (1) rather
than the caller's identically named one (100), which is the direct test of the R3 decision to
record the default's type on `sema.Parameter` so it travels across locations.

A ninth round raised no unfair test. Both suggestions were taken, and probing the first
corrected a standing assumption: `view fun make(): @R { return <- create R() }` type-checks,
so resource creation is view-legal, which makes a resource-producing VIEW CALL the cleanest
isolation of the non-resource rule from the purity rule.

A tenth round raised no unfair test. Formatting and AST serialization are now pinned
(`ast.Parameter.Doc` already rendered `= <expression>`, and `DefaultArgument` is an exported
JSON field, so both worked; they just were not asserted). The bbq compiler and VM stay out of
scope, deliberately: `test.sh` never passes `-compile`, no base test compiles a program with a
default on an ordinary function, and supporting them is a feature change rather than a test,
because the compiler emits arguments positionally and call-site materialization would resolve a
`self`-using default against the CALLER's receiver. See feedback.md R16.

An eleventh round raised no unfair test. Its three suggestions closed the last obvious holes:
scope is now shown to exclude LATER parameters as well as earlier ones, erasure and
receiver-retention are pinned against each other on the same bound-method expression, and the
non-resource rule has a positive boundary (a reference to a resource is not a resource, so
`&self as &R` is a legal default).

A twelfth round raised a description/tests alignment WARNING that was correct twice over. The
stated rule ("must not produce a resource") was looser than the implemented one, which rejects
any resource-typed parameter including `@R? = nil` and empty resource containers; and probing
the coverage suggestion exposed a second, undocumented split: with an interface default
implementation and a concrete override, the checker grants omission from the statically reached
declaration while the interpreter uses the default of the function that RUNS (1051, not 1006).
Both are now stated in the description and pinned by
`TestInterpretDefaultArgumentCompetingDeclarations`.

A thirteenth round raised no unfair test. Two things changed: the three resource tests each
gained a second control which keeps the default expression and changes only the parameter type
(`Int? = nil`, `[Int] = []`, `{String: Int} = {}`), isolating the failure to the parameter's
resource-ness; and evaluation COUNT, twice recorded here as unobservable, is now proven by
installing a `view`-typed host function whose Go implementation counts calls: 0 when the
argument is supplied, exactly 1 after one omitting call, exactly 2 after two. Generic functions
were probed and cannot carry defaults in source at all (a user function may not be
type-parameterized; the native form has no Cadence implementation).

A fourteenth round added the parser error path for malformed defaults (`= )`, `= *`, `= 1 +`,
in functions, function expressions and initializers), which only became reachable because
ordinary parameters now accept `=`; and confirmed by probe that the resource prohibition is
already recursive (`@[[R]]`, `@{String: [R]}`, `@[R]?` are all rejected), covered with
non-resource controls of the same shape.

`parser/default_arguments_c34547_test.go` (10): declaration, function expression,
initializer, transaction parameter rejected, event parameter rejected, destroy event still
requires a default on every parameter, formatting of a parameter and a parameter list,
formatting for function expressions and initializers, JSON serialization of the default
expression.

`sema/default_arguments_c34547_test.go` (49): omitted suffix, too few, too many, default
before a parameter without one, type mismatch, subtype, parameter not in scope, outer name
shadowed by a parameter, impure default, view default, resource default, initializer,
initializer arity, `self` in a member function default, conformance with an added default,
erasure through an interface type, default on an interface requirement rejected, interface
default implementation, erasure through a written function type, inferred function type,
function expression, argument labels, destroy event restricted expressions, destroy event
still checked, omission in the middle, matched-parameter type check, out of order, omission
of a parameter without a default.

`interpreter/default_arguments_c34547_test.go` (33): omitted suffix values, not evaluated
when the argument is given, evaluated when omitted, evaluated at each call, parameters not
visible to a default, optional parameter boxing, string default, initializer, resource
initializer, `self` member default, function expression capture, nested defaults, interface
default implementation, resource parameter followed by a default, omission in the middle,
direct call of a function expression with a default, aliased function value, aliased bound
member function value, captured variable read at call time, erasure through a written
parameter type, interface-typed call to a default implementation, resource rule isolated
from purity, sparse-call unknown label, sparse-call duplicate label, native member without
an implementation, sparse initializer call, sparse member call, sparse member matched
parameter, resource array default, resource dictionary default, default before a required
parameter in a function expression and in an initializer, omitting the first parameter,
resource-producing view call as a default, later parameter not in scope, explicitly typed
bound-method alias, reference to a resource as a default, sparse evaluation order, competing
interface and concrete defaults, exactly-once evaluation per call.

## Agent batches

### Batch 2 - 2x Orion + 8x Nova (2026-07-28) - 0/10, still INVALID, two fairness fixes

Runs 7-10 repeat batch 1. All ten predate the R22 merge-conflict fix, so every run carries the
ten synthetic parser failures. Two NEW defects surfaced, both mine, both from the Orion runs.

| Run | Solver | Verdict | Msgs | LOC | Baseline | Genuine defect |
|---|---|---|---|---|---|---|
| 1 | Orion | FAIL_TEST_BROKEN | 435 | 1472 | node renamed | NONE - harness only, `agent_blame_unfair: true` |
| 2 | Orion | FAIL_TEST_MISMATCH | 426 | 1513 | pass (8000 tests) | none functional: rejected the duplicate call but with its own error type, `agent_blame_unfair: true` |
| 3 | Nova | FAIL_MISSED_REQUIREMENT | 215 | 784 | pass | out-of-order + duplicate accepted; cascading diagnostic |
| 4 | Nova | FAIL_MISSED_REQUIREMENT | 223 | 742 | pass | function-expression bindings lose defaults; out-of-order + duplicate |
| 5 | Nova | FAIL_MISSED_REQUIREMENT | 175 | 837 | node renamed (exit 0!) | duplicate accepted, 91 of 92 passed |
| 6 | Nova | FAIL_MISSED_REQUIREMENT | 186 | 681 | node renamed | out-of-order accepted |

**Defect 1: the duplicate-label test pinned an error class the description never names.** Orion
run 2 passed 8000 baseline tests and 81 of 92 new ones; its only genuine failure was raising a
self-declared `InvalidArgumentOrderError` instead of `IncorrectArgumentLabelError`. The call WAS
rejected. `InvalidArgumentOrderError` exists nowhere in the repo, so Orion invented it, and
`IncorrectArgumentLabelError` is the repo's only bad-label error, which makes the pin
defensible but still wrong: the difficulty is detecting the bad call, and 7 of 10 runs emitted
no error at all for it. Relaxed to `RequireCheckerErrors(t, err, 1)` with no `IsType`, on both
the duplicate-label and unknown-label tests. meta.md now states the rejection requirement
outright without naming a diagnostic.

**Defect 2: `bbq/opcode` `TestPrintInstruction` keys its table by the printed instruction**, so
subtests are named after that text. Any solution threading argument data through Invoke renames
the node and gets graded on a node which no longer exists. Three runs failed baseline this way;
run 5 recorded `baseline_exit_code: 0` alongside `baseline_passed: false`. Now skipped in base
mode, documented in `test.sh`. Genuine opcode breakage stays covered by `TestPrintRecursionFib`
and the pretty-print tests, which is exactly where the real regressions in runs 8 and 10 landed.

Genuine-defect frequency across all ten, which is what survives on the fixed artifact: sparse
matcher accepts duplicate or out-of-order labels 7 of 10, `bbq/opcode` regression 2 of 10,
function-expression metadata lost 1 of 10, harness-only 1 of 10. Orion run 2 is the likely pass.

### Batch 1 - 4x Nova (2026-07-27) - 0/4, INVALID as a difficulty datapoint

| Run | Verdict | Msgs | LOC | Files | Baseline | Genuine agent defect | Harness defect |
|---|---|---|---|---|---|---|---|
| 1 | FAIL_MISSED_REQUIREMENT | 224 | 869 | 35 | pass | duplicate sparse label accepted (clamped index to `parameterCount - 1`) | yes, 10 parser tests synthesized as missing |
| 2 | FAIL_REGRESSION | 218 | 594 | 25 | FAIL | `bbq/opcode` regression (parameter ordinals encoded as type indexes) + out-of-order, unknown and duplicate labels | yes, same |
| 3 | FAIL_MISSED_REQUIREMENT | 231 | 1040 | 37 | pass | duplicate sparse label accepted (81 of 92 new cases passed) | yes, same |
| 4 | FAIL_REGRESSION | 207 | 703 | 25 | FAIL | `bbq/opcode` decode panic (changed `InstructionInvoke` layout) + out-of-order and duplicate labels | yes, same |

Every evaluator answered `description_clear: true`, `tests_deterministic: true`,
`difficulty: challenging`, `agent_blame_unfair: false`, and stated the task is solvable, citing
the reference solution. Fairness is therefore affirmed 4 times over.

**The batch cannot be read as a pass rate, because all four runs hit the same harness defect
which this submission caused.** test.patch modified `parser/declaration_test.go`, and a correct
solution MUST modify that same file, because the existing `TestParseInvalidDefaultArgument`
asserts that a function declaration and a function expression reject a default, which is exactly
what the feature legalizes. The verifier's three-way application of test.patch then failed with
exit 128 in every run, reset five files, and synthesized ten "missing from the JUnit XML" parser
failures. Any agent, including a perfect one, would have been graded as failing ten tests it
never ran.

Fixed by removing that file from test.patch entirely: base mode now skips
`TestParseInvalidDefaultArgument` for a documented reason (it asserts behaviour this task
changes; the transaction and event halves are covered by the new parser tests). test.patch now
touches ZERO existing files, so no solution can collide with it.

The genuine agent defects are worth keeping in view: 3 of 4 runs failed the duplicate-label
case and 2 of 4 regressed `bbq/opcode`. Those are the S5 wrong-helper trap and the S3
baseline-preservation trap biting as designed, and the same duplicate-label hole was found in
this submission's own reference implementation in R11.



Batch 1 above is not a usable difficulty datapoint. A clean batch is owed after the
patch-collision fix.
