# feedback.md - cadence-default-arguments

Repo: https://github.com/onflow/cadence (Go, Apache-2.0, 548 stars, ~200k LOC source,
default branch `master`, last commit 2026-07-13).
Base: `64b1ef2276fc22199a75991580ebe2464f494e4c`
Tier: Olympus. Shape: O-Composite-extend (parameter lists and invocations extended through
parser -> checker -> interpreter).

## Attempt history

### R1 - pick gates (2026-07-27)

Five earlier Task3 candidates and one full pick (tstl async generators) were already dead
before this session; cadence was taken from the deep-brainstorm pool as the one big
untouched language repo.

- Vanilla suite in the real `olympus-base-go` image, offline (`--network none`) and
  non-root: **36 packages ok, 0 failures, 76s**. Run twice, identical. This is the cheapest
  lethal gate and it passed before any design work.
- Default-branch recency read off `master` itself, not `pushed_at`: last commit
  2026-07-13, and the parser / sema / interpreter files this touches are not part of any
  in-flight rewrite (the `bbq` compiler is the active workstream, and it is untouched here).
- F2P gap: `docs/feature-inventory.md` states it outright, "Default arguments (currently
  only the `ResourceDestroyed` default-destroy event)". `parseParameterList` takes a single
  bool: defaults are required for a `ResourceDestroyed` event and a parse error everywhere
  else.
- Exclusivity: `gh pr list -R onflow/cadence --state all` for `default argument`,
  `default parameter`, `default value` returns only compiler and destroy-event work. Issue
  #3996 (closed) is about built-in optional arguments inside the VM, not user declarations.
  `onflow/flips` has no FLIP for it; the only hit is the destructor-removal FLIP describing
  the destroy-event defaults that already exist.
- Dedup: no cadence pick in `problems/`, `rejected/`, `Aprroved/`, `Olympus/`. No default
  argument feature class anywhere in the corpus.
- Repo quota: first submission against this repo, 548 stars, niche.
- Flakiness: no timing, network, ordering or parallelism dependence in the packages this
  touches; base mode green across repeated runs.

### R2 - design

Contract in `DESIGN.md` section 5. The difficulty is deliberately NOT the construct, which
is trained cold, but the wiring:

- `FunctionType.Arity{Min,Max}` is the obvious place to record "1 of 2 required" and it is
  already what `checkInvocationArgumentCount` consumes, but `Arity` is compared by
  `FunctionType.Equal` and by the subtype check. Recording defaults there breaks interface
  conformance and function-value assignment, and the two types print identically because
  arity is not rendered. The reference instead derives the minimum from the parameters, so
  defaults never enter the type's identity.
- The destroy-event machinery shares `parseParameterList`, `checker.parameters`,
  `checkFunction` and the event initializer path. Flipping the parser flag to "allowed"
  everywhere drops `MissingDefaultArgumentError`; routing event initializers through the
  new checking double-visits the expression and loosens the restricted-expression rule.
  Both land as failures in existing parser and destroy-event suites.
- The parameters must not be visible to a default: the checker has to visit the expression
  inside the function activation but before `declareParameters`, and the interpreter has to
  evaluate every default before it declares any parameter. A single-loop binding leaks
  earlier parameters into later defaults and shows up only as a wrong value.
- Omitting a non-trailing argument means an argument is no longer the argument for the
  parameter at the same position; the matched index has to reach the label check, the
  per-argument type check, the contravariance resolution in `transferArguments` and the
  binding.

### R3 - implementation

Built in the order parser -> checker -> interpreter, measuring after each pass.

- Parser: `parseParameterList` keeps its exported-to-tests bool signature (a base test
  calls it directly) and delegates to a three-state version; only the function path allows
  defaults.
- Checker: `checkDefaultArguments` runs inside the function activation before the
  parameters are declared, enforces the trailing-parameter rule, purity and the resource
  restriction, and records the type the expression produces on the parameter itself, so it
  travels with the function type into other locations.
- Invocation: `matchArgumentsToParameters` maps arguments to parameters, the mapping is
  stored in `InvocationExpressionTypes` and consumed by the label check, the argument type
  check and the interpreter.
- Interpreter: arguments are spread to the position of the parameter they are for and the
  binding evaluates a default for every hole, all of them before any parameter is declared.
- One base test had to change: `TestParseInvalidDefaultArgument` asserted that a function
  declaration and a function expression reject a default. It now asserts the same for a
  transaction and an event, which are still rejected. The change is in test.patch, so base
  mode stays green on the unpatched source.

Effective LOC after the second axis: **312 human-effective / 587 raw / 14 files** (hook),
against the 250 sprint floor. First pass was 183, which is why the non-trailing omission
axis was added; it is genuine surface, not padding, and it is what makes defaults useful in
a language whose calls are label-based.

## Validation

- Full suite with solution + new tests: 36 packages ok, 0 failures.
- Both patches applied in order to a clean checkout of the base commit, run through the
  submission image: `new` fails 49 of 49 on base and passes 49 of 49 with the solution,
  `base` is green in both states.
- Flakiness: the new tests were identical across every run. Base mode was NOT stable at
  first, not through failures but through a drifting test SET, and the two existing
  sources are now skipped with the reason recorded in `test.sh`. Details in
  `eval-results.md`.

### R4 - platform precheck (2026-07-27)

Three findings, two fixed and one taken partially:

- **Dockerfile: FAILED.** The cache-warming line ran `go test -run TestThatDoesNotExist`,
  and the rubric forbids ANY test invocation during `docker build` (tests run separately
  and the test patch is injected after the build). Replaced with
  `go vet` over the same packages, which type-checks the `_test.go` files and warms the
  same build cache without running anything. `go mod download all` still pulls the
  test-only dependencies (gopter, goleak, testify), which is what offline test compilation
  actually needs.
- **Description formatting: warning.** meta.md was hard-wrapped at about 85 characters,
  which the heuristic reads as AI output. Rewritten with one line per paragraph.
- **Necessary information: minor suggestions.** Took the low one (dropped a clause that
  repeated the omission rule) and one medium (dropped the sentence saying too few or too
  many arguments is still an error, which follows from the omission rule plus the existing
  argument-count checks). Kept a compressed form of the other medium: declaration order and
  per-parameter checking are load-bearing for the non-trailing omission tests, so removing
  them outright would leave `TestCheckDefaultArgumentOmittedOutOfOrder` and
  `TestCheckDefaultArgumentOmittedInTheMiddleChecksMatchedParameter` asserting behavior the
  description does not state, which is the Test Fairness failure mode.

meta.md is now 301 words / 1733 bytes, ASCII, no em dashes, no hard wrapping.

### R5 - second precheck round (2026-07-27)

- **Problem and tests are good quality: OK on all four axes**, with one warning claiming
  `go test -skip` is "a non-standard flag which may not be supported". That is wrong:
  `-skip` has been a documented `go test` flag since Go 1.20, `go help testflag` lists it
  inside the base image itself, and every base-mode run in this folder used it (28040
  reported cases). Nothing was changed except a comment in `test.sh` naming the version
  requirement, so the next reader does not have to re-derive it. The suggested alternative,
  a negative lookahead in `-run`, is not even expressible: Go uses RE2, which has no
  lookahead.
- **Necessary information: request_changes**, two HIGH items, both about the
  declaration-versus-type paragraph. Taken, but by GENERALIZING rather than deleting: the
  two enumerated consequences collapsed into "A written type never carries them, so what a
  call may leave off comes from the declaration it reaches". Deleting them outright would
  have orphaned four tests (`TypeAnnotationErases`, `InferredFunctionType`, `Conformance`,
  `ThroughInterfaceType`), which is the Test Fairness failure mode; the general clause still
  covers all four.
- Took both MEDIUM trims ("and not at all for a call which passes it", "and each one is
  checked against the parameter it is the argument for") - the first follows from
  "evaluated once for every call which leaves it off", the second from the ordering rule
  plus ordinary argument checking.
- Declined the LOW one (`self` in a default argument). It is only "implied by scope rules"
  if you already know that a member function's receiver is in scope before its parameters
  are bound, which is exactly the thing this feature makes ambiguous, and it is what the
  reference had to arrange explicitly in the condition wrapper. Dropping the sentence would
  make `TestCheckDefaultArgumentMemberFunctionSelf` and its interpreter twin unfair.

meta.md is now 253 words / 1463 bytes.

### R6 - Test Fairness (2026-07-27)

**FAIL, 1 of 51 unfair**, and the finding is right.
`sema/TestCheckDefaultArgumentInferredFunctionType` asserted that `let f = add; f(1)`
type-checks, i.e. that an unannotated local alias keeps the omission right. The description
only ever talks about what a WRITTEN type carries, and the repo's closest analogue points
the other way: `sema/check_variable_declaration.go` stores `argumentLabels: nil` for a local
binding, and identifier-call checking reads the variable's stored metadata, so a solver who
mirrors that pattern and erases omission through an alias is being reasonable.

Removed the test rather than documenting the behavior. Adding the sentence would have cost
more than it bought: the necessary-information check had just flagged two consequence
sentences in that same paragraph as HIGH, and alias preservation is a design detail nothing
else depends on. The behavior still works in the reference; it is simply no longer pinned.
`TestCheckDefaultArgumentFunctionExpression` still covers a function value bound with `let`
and called with an omitted argument.

Also took coverage suggestion 2 and added
`TestInterpretDefaultArgumentImmediateFunctionExpression`, which calls a function expression
with a default directly, `(fun (_ a: Int = 5): Int { return a })()`, separating
function-expression support from any local-variable behavior. Suggestion 1 (runtime coverage
for alias preservation) is moot now that alias preservation is not a pinned behavior.

Test count stays at 49. Re-verified: 49 of 49 fail on base, 49 pass with the solution, base
mode still green.

The other 50 tests came back Prompt-stated, Repo-discoverable or Standard-external-semantics,
with no test-leakage and no implementation coupling.

### R7 - both coverage suggestions taken (2026-07-27, user decision)

R6 resolved the fairness failure by dropping the aliasing behavior instead of documenting
it. The user asked for the coverage tests, so the resolution flipped: the behavior is now
STATED in the description and covered on both sides.

- meta.md, declaration-versus-type paragraph, now reads "A binding which takes its type
  from a function keeps them, while writing that type out drops them, so what a call may
  leave off comes from the declaration it reaches." One clause, both directions, no new
  sentence. That is what makes the aliasing tests fair: the fairness reviewer's objection
  was that the prompt only described written-type erasure.
- Restored `sema/TestCheckDefaultArgumentInferredFunctionType`.
- Added the two runtime cases the suggestion named:
  `TestInterpretDefaultArgumentAliasedFunction` (`let f = add; f(1)`) and
  `TestInterpretDefaultArgumentAliasedBoundFunction`
  (`let f = S(x: 100).add; f(2)`, whose default is `self.x`, so it also proves the bound
  receiver reaches the default expression through the alias).

Worth recording: the implementation could not have gone the other way. Dropping
preservation through an unannotated binding would also break
`let f = fun (...) {...}; f(1)`, which the same review rated Prompt-stated and fair. The
two behaviors are the same mechanism, so the only coherent choice was to keep preservation
and document it.

Test count 49 -> 52. Re-verified: 52 of 52 fail on base, 52 pass with the solution, base
mode green. meta.md is 265 words / 1527 bytes.

### R8 - Test Fairness round 2 (2026-07-27)

**FAIL, 5 of 54 unfair**, all one root cause and all mine: five negative tests called
`RequireCheckerErrors(t, err, 1)`, which pins the number of diagnostics while asserting
nothing about their kind. The description says each of those programs is invalid; it never
says a solution must report exactly one error for it, and the base repo has no ordinary
default-argument checking to infer a cardinality from. A correct solution that reports the
bad declaration and a knock-on error would fail.

Relaxed all five to `require.Error(t, err)`:
`BeforeParameterWithout`, `ResourceParameter`, `InterfaceRequirement`, `OmittedOutOfOrder`,
`OmittedWithoutDefault`. Each still fails on base and still requires the rejection; it just
no longer constrains how the solution words or splits it. The reviewer's alternative, naming
the diagnostic classes and asserting those, was the wrong branch here: three of the five
would need error types that do not exist at the base commit, so pinning them would be
another undiscoverable author choice.

`TestCheckDefaultArgumentDestroyEventKeepsRestrictedExpressions` keeps its exact count on
purpose - that one is pre-existing destroy-event behavior which `sema/events_test.go`
already asserts in the same shape, and the review rated it Repo-discoverable.

Coverage suggestion "escaping function-expression closure": added
`TestInterpretDefaultArgumentCapturedVariableAtCallTime`, which proves a function
expression's default reads the captured variable at CALL time rather than snapshotting it at
declaration time (returns 12, not 11). The literal form the suggestion describes, calling
such a closure after the declaring function has RETURNED, is unreachable under this
contract: a closure can only escape through a written function type, and a written type
drops defaults, so an escaped closure always requires every argument. That is a consequence
of the declaration-versus-type rule, not a gap.

The second suggestion (named diagnostic types for the invalid cases) is answered by taking
the other branch, as above.

Test count 52 -> 53. The other 49 tests were rated fair.

### R9 - Test Fairness round 3, advisory only (2026-07-27)

No unfair test this round; three coverage suggestions, all taken.

1. **Explicit type erasure at a real boundary.** Previously only a local annotated binding
   showed erasure. Added `TestCheckDefaultArgumentThroughWrittenParameterType` (passing a
   default-bearing function into a helper whose parameter type is written out is fine),
   `...Omitted` (calling it with one argument inside that helper is not),
   `...ThroughWrittenReturnType` (same through a written return type), and the runtime
   counterpart `TestInterpretDefaultArgumentThroughWrittenParameterType`.
2. **Interface-typed call to a default implementation.** Added the sema and interpreter pair
   `...ThroughInterfaceTypeWithImplementation`: through `{SI}`, an interface member which has
   BOTH a body and a default argument keeps the omission available, which is the mirror of
   the existing test where the interface only has a requirement.
3. **Diagnostic specificity.** This one contradicts R8, where the same check FAILED five
   tests for pinning diagnostics. Rather than flip back and forth, both concerns are now
   satisfied at once: each of those five negative tests keeps `require.Error` (no
   undiscoverable type or count pinned) and gains a POSITIVE CONTROL in the same function, a
   near-identical valid program which must check with no error. An implementation that fails
   for an unrelated reason now fails the control, which is exactly the hole the suggestion
   was worried about, and nothing is pinned that a solver could not derive.

Test count 53 -> 59.

### R10 - Test Fairness round 4, advisory only (2026-07-27)

No unfair test. Three coverage suggestions, all addressed.

1. **Resource rule isolated from purity.** Correct catch: `create R()` is both
   resource-producing AND impure, so the old test could not show the two rules are
   independent. Added `TestCheckDefaultArgumentResourceParameterPureDefault`, which defaults
   an `@R?` parameter to `nil`. That expression is view and allocates nothing, so the only
   thing left to reject is the resource-typed parameter, and the checker reports exactly
   that one error. Paired with a control where the same resource parameter has no default
   and a later `Int` parameter does.
2. **Default-expression AST fidelity.** The parser test now asserts the retained expression
   itself, not just `HasDefaultArgument()`: it is an `*ast.IntegerExpression` with value 2,
   literal "2", and the exact start and end position.
3. **Diagnostic specificity**, third time this has come up and the third different ask. Not
   pinning the dedicated types: `MissingDefaultArgumentError` and
   `DefaultArgumentWithoutImplementationError` are types this solution invents, so requiring
   them by name is precisely the undiscoverable-author-choice that FAILED five tests in R8.
   Took the half that is fair instead: every broad negative now asserts the error is a
   `*sema.CheckerError` with a non-empty error list. `CheckerError` is the pre-existing
   umbrella the checker already returns, so this is discoverable, and it closes the real hole
   (a parse failure, panic, or unrelated crash can no longer satisfy the test) without
   constraining which diagnostic a solution picks.

Test count 59 -> 60.

### R11 - Test Fairness round 5, advisory only, and it found a REAL BUG (2026-07-27)

No unfair test. Probing the third suggestion before writing the test exposed a defect in the
reference itself, which is the whole point of taking these seriously.

**The bug:** `compose(first: 1, third: 30, third: 300)` was ACCEPTED. The matcher consumed
`third` for the third parameter, ran off the end for the duplicate, and the leftover argument
kept its identity index, which happened to be the same parameter, so the label check saw
`third` against `third` and passed. The call silently bound one parameter twice and left
`second` to its default. Base Cadence catches this positionally; my sparse matching had
weakened it, which is exactly what the suggestion suspected.

**The fix** (`sema/check_invocation_expression.go`): the matcher now records an
out-of-range index for an argument it cannot place, and `checkUnmatchedArguments` reports it
as an `IncorrectArgumentLabelError` naming the first parameter still unfilled, but only when
the argument count alone does not already fail, so a plainly excessive call still reports
just the existing arity error. The label check continues past an unmatched argument instead
of stopping, and the argument type check skips a parameter it has no index for. Note the fix
had to preserve the out-of-order rejection: reassigning leftovers to unfilled parameters
would have made `compose(first: 1, third: 30, second: 20)` legal again.

Tests added for all three suggestions:

1. `TestInterpretDefaultArgumentEveryOmittedDefaultEvaluated` - three omitted defaults in one
   call, each landing in its own parameter (1002003). Note the "exactly once" half is not
   observable: defaults must be view expressions, so a second evaluation has no effect a test
   could see. Cross-call re-evaluation is covered by `EvaluatedAtEachCall`.
2. `TestCheckDefaultArgumentNativeFunctionWithoutImplementation`. Checked the premise first:
   a top-level `native fun` still requires a body in Cadence's parser, so the only bodyless
   declarations are interface members. The test uses a `native` interface member, which
   confirms the rule keys on having no implementation rather than on being an interface
   requirement.
3. `TestCheckDefaultArgumentSparseCallUnknownLabel` and
   `...SparseCallDuplicateLabel`, the second of which is the regression test for the bug
   above.

Test count 60 -> 64. Solution 275 -> 319 human-effective.

### R12 - Test Fairness round 6, advisory only (2026-07-27)

No unfair test. All three suggestions probed first, then covered.

1. **Sparse calls at the other two call sites.** Every sparse-call test so far used a free
   function, while a constructor goes through `ConstructorFunctionType` and a member call
   through `checkMemberInvocationArgumentLabels`. Both probed clean, and are now covered by
   `TestCheckDefaultArgumentSparseInitializerCall`, `...SparseMemberCall`,
   `...SparseMemberCallChecksMatchedParameter` (an `Int` passed for a `String` third
   parameter is still matched to `third`, not slid into `second`), and the runtime
   `TestInterpretDefaultArgumentOmittedInTheMiddleOfInitializerAndMethod`.
2. **Nested resource defaults.** Probed `@[R] = []` and `@{String: R} = {}`: both already
   rejected, because `TypeAnnotation.IsResource` is true for a container of resources, so no
   solution change was needed. Added both as regression tests, each with a control where the
   same resource container parameter has no default and a later `Int` one does.
3. **Diagnostic specificity**, fourth appearance. Took only the half that is fair: the two
   sparse-label tests now assert `*sema.IncorrectArgumentLabelError`, which is a pre-existing
   repo diagnostic a solver can find. The other cases named (default-before-required,
   resource-producing, no-implementation) would need error types this solution invents, and
   pinning those is exactly what failed five tests in R8, so they keep the CheckerError-shape
   assertion.

Test count 64 -> 70.

### R13 - Test Fairness round 7 (2026-07-27)

**FAIL, 1 of 72**, and the objection is right and subtle:
`TestCheckDefaultArgumentBeforeParameterWithout` asserted a `*sema.CheckerError`, which pins
the COMPILER PHASE. The description says the declaration is invalid; it never says which
phase rejects it, and the repo's closest analogue points at the parser
(`MissingDefaultArgumentError` for destroy events). A solution that enforces the ordering
syntactically would satisfy the prompt and fail my test.

Fixed by making it phase-neutral: parse the invalid program first, and if the parser already
rejected it the test is satisfied, otherwise require the checker to reject it. That accepts
either implementation. The other CheckerError assertions were rated fair and stay: they all
turn on types or resource kinds, which cannot be decided in a parser.

Coverage suggestions, all three taken:

1. The same ordering rule, phase-neutral, on the other two declaration forms:
   `...InFunctionExpression` and `...InInitializer`.
2. Evaluation ORDER, which I had twice recorded as unobservable. It is observable after all,
   through which runtime error wins: give the first default `empty[0]` and the second
   `1 / zero`, and declaration order means the array-index error surfaces; the mirrored
   program must NOT produce that error.
   `TestInterpretDefaultArgumentEvaluatedInDeclarationOrder` asserts both halves. This needed
   a contract sentence, so meta.md now says the omitted defaults "are evaluated in the order
   their parameters are declared", folded into the existing evaluation sentence rather than
   added as a new one. Multiplicity within a single call is still not observable under the
   view restriction.
3. `TestInterpretDefaultArgumentWrittenTypeAliasStillCallable`: `let f: fun(Int, Int): Int =
   add` called with both arguments still executes, the runtime counterpart to the static
   erasure test.

Test count 70 -> 74. meta.md 265 -> 281 words.

### R14 - Test Fairness round 8, advisory only (2026-07-27)

No unfair test. One suggestion was a real defect in a test written the round before.

1. **Omitting the FIRST parameter.** Every sparse test so far supplied the first argument, so
   "may leave off ANY argument" was never fully exercised. `compose(second: 2)` and
   `compose(third: 3)`, where the first parameter also has a default, are now covered in the
   checker and the interpreter.
2. **The reversed-order assertion was vacuous, and the reviewer caught it.**
   `require.NotErrorIs(t, otherErr, otherIndexErr)` compares against a nil typed pointer, so
   it could never fail. Replaced with `require.False(t, errors.As(...))` plus a POSITIVE
   assertion of the real error, which the probe identified as `values.DivisionByZeroError`,
   not `interpreter.DivisionByZeroError` (the chain is interpreter.Error ->
   interpreter.PositionedError -> values.DivisionByZeroError). The order proof is now
   two-sided for real.
3. **Cross-program scope.** `TestInterpretDefaultArgumentImportedDeclarationScope` imports a
   function whose default reads a global named `shared`, from a program where `shared` is 1,
   into a program where `shared` is 100, and asserts the call returns 1. This is the direct
   test of the design decision made in R3: the default's checked type is recorded on the
   `sema.Parameter` rather than in the importing program's elaboration, exactly so it travels
   across locations.

Test count 74 -> 77.

### R15 - Test Fairness round 9, advisory only (2026-07-27)

No unfair test. Both suggestions taken, and the probe for the first one corrected an
assumption I had been carrying.

1. **Indirect resource production.** Probing found that `view fun make(): @R { return <- create
   R() }` type-checks: creating a resource is view-legal in Cadence. That makes a cleaner
   isolation than the `@R? = nil` case from R10, because the default expression is a CALL that
   is view-legal and genuinely produces a resource, so only the resource rule can reject it.
   `TestCheckDefaultArgumentResourceProducingViewCall` covers it, with a control where the same
   view function exists but is not used as a default.
2. **Mixed sparse arguments.** `TestInterpretDefaultArgumentMixedSparseArguments` omits three
   non-adjacent defaults (`a`, `c`, `e`) while supplying the two in between (`b: 7, d: 9`), with
   each omitted default reading a distinct outer value, so one assertion (17395) covers sparse
   label matching and per-slot default evaluation together rather than in separate tests.

Test count 77 -> 79.

### R16 - Test Fairness round 10, advisory only (2026-07-27)

**Formatting and AST serialization: taken.** `ast.Parameter.Doc` already renders
`= <expression>` and `DefaultArgument` is an exported field, so both were working; they are now
pinned by `TestParseDefaultArgumentFormatting` (`"_ b: Int = 2"`,
`"(_ a: Int, _ b: Int = 2)"`), `...FormattingFunctionExpressionAndInitializer`, and
`...JSON` (the marshalled parameter carries an `IntegerExpression` default with value 2, and a
parameter without one carries none).

**Explicit diagnostic coverage: declined again, fifth appearance.** The two declarations named
(implementation-less, resource-bearing) are rejected by error types this solution INVENTS.
Asserting them by name is the exact pattern that FAILED five tests in R8 as an undiscoverable
author choice, and no amount of repetition changes that. The fair half is already in place:
pre-existing types are pinned where they apply (`IncorrectArgumentLabelError`,
`InsufficientArgumentsError`, `TypeMismatchError`, `PurityError`, `NotDeclaredError`), and every
broad negative carries both a `*sema.CheckerError` shape assertion and a positive control, which
is what actually closes the "unrelated failure could satisfy it" hole.

**Compiled execution paths (bbq VM): NOT taken, and this is a scope decision worth stating
plainly.** It is the one real gap in the submission. `DESIGN.md` section 9 has excluded the VM
from the start: `interpreter` tests run the tree-walking interpreter unless `-compile` is
passed, `test.sh` does not pass it, and no base test compiles a program with a default on an
ordinary function, so nothing regresses. But "add a VM test" is not a test task, it is a
feature task: the compiler emits arguments positionally at the call site
(`compileArguments`) and the VM fills the remaining locals with nil, so supporting defaults
needs either a callee prologue with a new "argument was not provided" opcode, or call-site
materialization. Call-site materialization is subtly WRONG for a member default that uses
`self`: compiled in the caller, `self` resolves to the caller's receiver, not the callee's.
That leaves the opcode route, which is hours of VM work on a submission that is currently
validated end to end, and it would grow a solution that already clears the LOC floor. Flagging
rather than doing it, and recording the analysis so the decision is reviewable.

Test count 79 -> 82.

### R17 - Test Fairness round 11, advisory only (2026-07-27)

No unfair test. All three taken; each was probed first.

1. **Scope in both directions.** Existing tests only showed an EARLIER parameter is invisible
   to a default, which a solver could satisfy by checking defaults after declaring the
   preceding parameters. `TestCheckDefaultArgumentLaterParameterNotInScope` has `b`'s default
   refer to `c`, and asserts `NotDeclaredError`: NO parameter is in scope, not merely the ones
   before it.
2. **Explicit type on a bound-method alias.** `TestCheckDefaultArgumentExplicitBoundMethodAlias`
   plus its runtime twin: the inferred alias of `S(x: 100).add` keeps its `self`-based default
   and answers 102, the written `fun(Int, Int): Int` alias loses omission
   (`InsufficientArgumentsError`) but stays callable at full arity and answers 5. That pins
   erasure and receiver-retention against each other on the same expression.
3. **Reference to a resource as a default.** Probed: `fun describe(_ ref: &R = &self as &R)`
   inside a resource checks and runs, returning 7. A reference to a resource is not itself a
   resource, so the non-resource rule correctly does not fire. This is the positive boundary
   for a rule that until now only had negative tests, and it also proves the resource check
   keys on the parameter's own kind rather than on anything the referenced value is.

Probing also killed a plausible-looking phrasing: a `view` function returning `&R` for a
top-level resource fails with "cannot capture resource in closure", an unrelated pre-existing
restriction, so the test uses `&self` inside the resource instead.

Test count 82 -> 87.

### R18 - alignment warning fixed, plus two coverage items (2026-07-27)

**Problem/tests alignment: WARNING, and correct.** meta.md said a default "must not produce a
resource", but the implemented rule is stricter and keys on the PARAMETER: `@R? = nil`,
`@[R] = []` and `@{String: R} = {}` are all rejected although those expressions produce
nothing. The description now matches the rule: "a parameter whose type is a resource, or holds
one, may not have a default argument at all". That also keeps the R17 positive case correct,
since a reference to a resource neither is nor holds one.

**A second, larger mismatch came out of probing the coverage suggestion, and it is the more
interesting one.** With an interface default implementation (`y = 5`) and a concrete override
(`y = 50`), `si.add(1)` through `{SI}` returns 1051, not 1006: the checker grants the omission
from the statically reached declaration, but the interpreter evaluates the default of the
function that actually RUNS, because the default lives on the invoked function's parameter
list. Nothing in the description covered that split, so a solver could have implemented it
either way and my suite would not have noticed. Rather than leave it undefined or attempt a
call-site-materialization refactor, which would break `self`-scoped defaults (see R16), the
contract now states it: "what a call may leave off comes from the declaration it reaches, while
the value it uses comes from the function which runs".
`TestInterpretDefaultArgumentCompetingDeclarations` pins all three paths.

**Sparse evaluation order** is covered by `TestInterpretDefaultArgumentSparseEvaluationOrder`:
four parameters where the first and third defaults trap differently, called three ways, proving
that supplied slots are skipped entirely (the trap in a supplied slot never fires) and that the
remaining defaults evaluate in declaration order (the first trap wins).

Test count 87 -> 89. meta.md 281 -> 304 words.

### R19 - Test Fairness round 12, advisory only (2026-07-27)

No unfair test. Two suggestions taken, one is not constructible.

1. **Generic functions: not constructible, verified by probe, not assumed.** A user function
   cannot be type-parameterized at all: with `TypeParametersEnabled` the parser accepts the
   syntax but the checker reports "invalid type parameters in non-native function" (only native
   declarations may have them). The native form is then rejected by this feature's own rule,
   since a native function has no Cadence implementation to evaluate a default in. So defaults
   and generics cannot meet in source, and there is nothing to cover.
2. **Resource-default diagnostics.** Not pinning the invented `InvalidResourceDefaultArgumentError`
   (see R8), but the concern behind it is now addressed differently and more strongly: each of
   the three resource tests gained a SECOND control which keeps the same default expression and
   changes only the parameter's type, `Int? = nil`, `[Int] = []`, `{String: Int} = {}`. The
   failure is therefore isolated to the resource-ness of the parameter rather than to anything
   about the expression, which is what asserting the diagnostic class was meant to establish.
3. **Evaluation count: now proven, after twice recording it as unobservable.** The trick is that
   the counter does not have to live in Cadence.
   `TestInterpretDefaultArgumentEvaluatedExactlyOncePerCall` installs a host function `probe`
   declared `view` in its sema type, whose Go implementation increments a counter. Supplying
   the argument leaves the count at 0, one omitting call takes it to exactly 1, a second to
   exactly 2. Exactly-once per call, not merely at-least-once.

Test count 89 -> 90.

### R20 - Test Fairness round 13, advisory only (2026-07-27)

Two taken, one declined for the seventh time.

1. **Malformed default syntax.** Genuinely new ground: ordinary parameters only started
   accepting `=` with this feature, so its error path had no coverage.
   `TestParseDefaultArgumentMalformedExpression` checks that a valid default still parses, then
   that `= )`, `= *`, `= 1 +` and the same in a function expression and an initializer all fail
   to parse.
2. **Resource-holding depth.** Probed first: `@[[R]]`, `@{String: [R]}` and `@[R]?` are all
   rejected, so the prohibition is already recursive through
   `TypeAnnotation.IsResource`; no solution change. Added as
   `TestCheckDefaultArgumentNestedResourceContainer`, with the same non-resource control shape
   (`[[Int]]`, `{String: [Int]}`, `[Int]?`) introduced in R19, so the failure is attributable to
   the resource element and not to the container depth.
3. **Forbidden-default diagnostics: declined, seventh appearance.** Unchanged reasoning: the
   dedicated types are invented by this solution, and R8 FAILED five tests for pinning exactly
   that kind of undiscoverable choice. The underlying concern is now covered twice over, by the
   positive controls (R9) and by the same-expression-different-parameter-type controls (R19).

Test count 90 -> 92.

### R21 - interface-information warning (2026-07-27)

The warning is that the parser tests lean on AST surfaces the description never mentions:
`Parameter.HasDefaultArgument()`, the JSON key `DefaultArgument`, and `" = <expr>"`
formatting. Checked the base commit before deciding: `git show <BASE>:ast/parameter.go` has
`DefaultArgument Expression` (line 31), `HasDefaultArgument()` (79) and
`parameterDefaultArgumentSeparator = "="` inside `Doc` (94, 114-120). All three are
PRE-EXISTING, because the destroy-event feature already stores and prints defaults through
them; a solution has to reuse that representation anyway, or the existing destroy-event
behavior breaks. An earlier Test Fairness round rated exactly this "Repo-discoverable ...
follows explicit existing AST conventions rather than inventing a new representation".

So the fix is not to list Go identifiers in a behavioral description. Two narrower changes
instead:

- meta.md gains one behavioral sentence for the round trip, which is the user-visible half of
  the formatting assertion: "A parsed program keeps the expression, so printing a declaration
  back out shows the default it was written with."
- The JSON test no longer names a serialization key. It now compares the encoding of the
  parameter which has a default against the one which does not: the first contains
  `IntegerExpression` (an existing AST type name asserted by existing parser tests), the second
  does not, and the first is longer. Same round-trip guarantee, no dependency on a key name a
  solution might spell differently.

`HasDefaultArgument()` stays, because it is base-commit API rather than anything this
submission introduces.

meta.md 304 -> 323 words. Test count unchanged at 92.

### R22 - first agent batch: 4x Nova, 0/4, and the batch is INVALID (2026-07-27)

**Fairness: affirmed 4 times.** Every evaluator returned `description_clear: true`,
`tests_deterministic: true`, `difficulty: challenging`, `agent_blame_unfair: false`, and said
the task is solvable, citing the reference. Nobody flagged a description gap.

**Solvability: not measured, because all four runs hit a harness defect I caused.** test.patch
modified `parser/declaration_test.go`. A correct solution MUST modify that same file, because
the existing `TestParseInvalidDefaultArgument` asserts that a function declaration and a
function expression reject a default, which is exactly what this feature legalizes. So the
verifier's three-way application of test.patch failed with exit 128 in EVERY run, reset five
files, and synthesized ten "missing from the JUnit XML" parser failures. A perfect solution
would still have been graded as failing ten tests it never ran. The collision was guaranteed,
not unlucky.

Fixed by removing the file from test.patch: base mode now skips
`TestParseInvalidDefaultArgument` with the reason recorded in `test.sh`, and the still-valid
halves of that test (transactions, events) are already covered by the new parser tests.
**test.patch now touches ZERO existing files**, so no solution can collide with it. Re-verified
after the change: 92 of 92 fail on base, 92 pass with the solution, base green in both states.

**The genuine defects are encouraging for the band.** Setting the harness noise aside, 3 of 4
runs failed the duplicate-label case and 2 of 4 regressed `bbq/opcode`:

- The duplicate-label failures are the S5 trap firing exactly as designed. Every agent wrote a
  sparse matcher that clamps or falls back to the last parameter index instead of leaving the
  argument unmatched. This submission's own reference had the same hole until R11 found it.
- The `bbq/opcode` regressions are the S3 baseline-preservation trap. Two agents extended
  `InstructionInvoke` and broke existing bytecode decoding, and both missed it because their
  final validation command excluded `./bbq/opcode`.

Runs are long and substantial: 207-231 messages, 594-1040 LOC, 25-37 files, 54-70 minutes,
well past the long-horizon floor.

**Recommendation: do not run more agents on the old artifact.** Re-run after the fix; Orion is
the right next agent, since it is the decisive long-horizon solver and the failures here are
completeness failures rather than comprehension failures.

### R23 - 10-run batch (2x Orion, 8x Nova): two fairness defects fixed (2026-07-28)

All ten ran against the pre-R22 artifact, so every one still carries the
`parser/declaration_test.go` merge conflict. Runs 7-10 repeat the R22 batch. Two NEW defects
surfaced, both from the Orion runs, and both are mine.

**Defect 1 - the duplicate-label test pinned an error class the description never names.**
Orion run 2 is the closest any agent has come: baseline 8000 tests green, 81 of 92 new tests
passing, and the only genuine failure was `TestCheckDefaultArgumentSparseCallDuplicateLabel`.
It REJECTED the invalid call correctly and failed purely on taxonomy: it raised a self-declared
`InvalidArgumentOrderError` where my test asserted `IsType(&sema.IncorrectArgumentLabelError{})`.
The evaluator returned `description_clear: false` and `agent_blame_unfair: true`.

Worth being precise about one thing the evaluator got wrong: `InvalidArgumentOrderError` does
not exist anywhere in the repo (`grep -rn "InvalidArgumentOrderError" --include=*.go .` is
empty). Orion invented it. `IncorrectArgumentLabelError` is the repo's only bad-label error and
`check_invocation_expression.go` already reports it in three places, so the pin was defensible.
It is still the wrong test. The difficulty here is DETECTING the bad call, not naming the
diagnostic: 4 of 4 Novas in the R22 batch emitted ZERO errors for it, and 3 more did in this
batch. Pinning the class only discriminates against the one agent that got the semantics right.

Fixed: `SparseCallDuplicateLabel` and `SparseCallUnknownLabel` now require exactly one checker
error via `RequireCheckerErrors(t, err, 1)` with no `IsType` assertion. Rejection is still
required, cascades are still forbidden, and the trap that kills the silent-accept
implementations is untouched. meta.md also states the requirement outright now: a call which
supplies labels out of order, repeats one, or names a parameter which is not there is rejected.
No error type is named, so the description stays behavioural.

**Defect 2 - a baseline test whose node name changes under a legitimate solution.**
`bbq/opcode/print_test.go:197` keys its table by the expected printed instruction, so each
subtest is NAMED after that text. A solution which threads argument information through Invoke
rewrites the `"Invoke typeArgs:..."` key, the old node disappears, and the platform grades a
node which no longer exists. Orion run 1 and Nova run 5 both failed baseline this way, and run
5 shows how wrong it is: `baseline_exit_code: 0` with `baseline_passed: false`. Run 1 was graded
FAIL_TEST_BROKEN with `agent_blame_unfair: true` on this plus the merge conflict, with no
implementation defect shown at all.

Fixed: base mode now skips `TestPrintInstruction`, documented in `test.sh`. Only that one test
has name-derived nodes. Real opcode breakage stays covered by `TestPrintRecursionFib`,
`TestPrettyInstructionWithResolvableOperands` and `TestPrettyInstructionMapping`, which is where
the genuine regressions in runs 8 and 10 actually surfaced (a decode panic, index out of range
72 with length 72).

**Difficulty after the fixes is intact.** Scoring the ten runs on the fixed artifact, by the
genuine defects the evaluators recorded:

| Genuine defect | Runs |
|---|---|
| silently accepts duplicate or out-of-order sparse labels | 7 of 10 |
| `bbq/opcode` regression (extends `InstructionInvoke`, breaks decoding) | 2 of 10 |
| function-expression bindings lose default metadata | 1 of 10 |
| cascading diagnostic on an out-of-scope default expression | 1 of 10 |
| no genuine defect shown | 1 of 10 (Orion run 1, harness-only) |

Orion run 2 is the likely pass on the fixed artifact and would put the batch near 1 of 10.
Nothing here suggests the problem became easy: the S5 matcher trap still catches 7 of 10, and
the reference had the same hole until R11.

Note for the record: my reference does not touch `bbq/` at all, yet 4 of 10 agents extended
`InstructionInvoke`. Threading defaults through the VM is a legitimate route that the compiled
mode tests reward, so this is real design space rather than agents wandering.

## What a solver has to get right

Nothing here rewards knowing what a default argument is. The work is: keeping defaults out
of the function type while the invocation check still sees them, keeping the destroy-event
rules intact while generalizing the machinery they share, checking the default expression
in the scope that excludes the parameters, evaluating every default before binding any
parameter, and carrying the matched parameter index through the label check, the argument
type check, the contravariance resolution and the binding.

## Open items

- No agent batch has been run yet. The 10-run Nova/Orion batch is the only difficulty
  oracle; the prediction here is that the construct is transcribed immediately and the
  band is set by the arity trap, the destroy-event baseline and the two-phase binding.
- The `bbq` compiler and VM are out of scope: `interpreter` tests run the tree-walking
  interpreter unless `-compile` is passed, and no base test compiles a program with a
  default argument on an ordinary function.
