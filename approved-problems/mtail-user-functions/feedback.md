# mtail-user-functions - feedback / attempt log

## Pick (2026-07-28)

**Repo:** google/mtail, Apache-2.0, 4024 stars, Go, 26.9k LOC.
**Base:** `4c7e0e1174ac1ead032efe28d86428bbbe0ae145` (2026-02-26, tip of `main`).
**Feature:** user-defined functions (`func` / `return` / calls / `local` storage) threaded through
lexer, goyacc grammar, AST, symbol table, type checker, code generator, bytecode VM, and the two
program printers.

### Hunt log (candidates killed before this one)

| Candidate | Killed by |
|---|---|
| brimdata/super (1566, Go) | LICENSE is the "SuperDB Source Available License" - not in the allowed set |
| Pyomo/pyomo (2493, Python) | LICENSE.md carries a FOQUS rider clause bolted onto BSD-3 (rider-BSD = hard reject) |
| Instagram/LibCST (1932, Python) | dual MIT + PSF-2.0; PSF is not in the allowed family list |
| Hans-Halverson/brimstone (1316, Rust) | `rust-toolchain.toml` pins 1.95.0 + ICU4X/jemalloc dep tree -> Env-Quality offline build risk (same death as egglog/slatedb) |
| pb33f/libopenapi (861, Go, MIT) | the obvious features already exist: `bundler/` does composition + `$ref` rewriting, `overlay/` does overlays, `what-changed/` does diffing (Gate 6 existing-capability) |
| lotusdblabs/lotusdb (2253, Go) | last commit 2025-02-18, 17 months stale (recency gate) |
| construct/construct (1011, Python) | last commit 2025-04-22, 15 months stale |
| araddon/qlbridge, segmentio/parquet-go | frozen since 2021 / 2023 |
| jsonata-js/jsonata (2665, JS, MIT) | `npm test` posttest enforces 100% statement/branch coverage, so any added source fails the repo's own suite |

### Gate evidence

- **1 behavioural F2P gap.** `func f(x) { return x }` is a parse error on base. The language
  reference states outright that user defined functions are not supported.
- **5 cold-not-live.** Every open PR on google/mtail is dependabot. Upstream development moved to
  the 29-star fork `jaqx0r/mtail`, whose recent commits are dependency bumps only. Nothing touches
  the compiler.
- **7 dedup.** One prior submission on this repo (`mtail-foreach-match`, iteration over line matches
  and metric entries) - a different capability. No call-frame / function work anywhere in the corpus
  for a log-processing VM.
- **7b exclusivity.** `gh pr list -R google/mtail --state all --search function` returns dependabot
  bumps only; the fork's commit log likewise.
- **8 defined-behaviour.** Issue #333 (open) has the maintainer saying "There's no other concept of
  temporary variables, but there could be. I can leave this open as a feature request." Nothing
  declines functions. Issue #970 (multi-line matching) IS declined by the maintainer, so that
  neighbouring idea was avoided.
- **9 flakiness.** Vanilla `go test ./...` in `olympus-base-go`: 21 packages ok, 0 failures, ~7s,
  run 3x offline with byte-identical results.
- **10 quota.** 1 of our 6 for this repo; 4024 stars is under the 5k presumed-saturation line.

## Design

Traps, lead first (full matrix in DESIGN.md):

1. **S1 speculative-state isolation.** `thread.matches` is keyed by the *global* regex constant
   index and `thread.matched` is one flag, so the natural implementation - run the body on the
   caller's thread - lets a match inside the callee clobber the caller's capture groups and set its
   matched flag. Reproduced before authoring: without the frame snapshot,
   `TestFuncCallDoesNotClobberCallerSameRegexE6382b` reads the callee's value out of `$1`.
2. **S2 composition, opposing trap 1.** The obvious fix for trap 1, snapshotting the whole thread,
   also restores the timestamp register, so `strptime` inside a body silently stops working. Only a
   partial save is correct. The two rules are stated in the prompt; neither states where the state
   lives or how to split the save.
3. **S3 baseline preservation.** Decorators are inlined at codegen through a `decos` stack that
   `next` unwinds; implementing calls by AST inlining or by reusing that stack breaks existing
   decorator tests. Base mode runs the whole repo suite (663 nodes) so this fires loudly.
4. **S4 machinery-riding.** A call has to work as a builtin argument, as a metric index, on the
   right of `+=`, in a condition, nested inside another call, inside a decorated block, and inside a
   function body. The prompt says this as one general sentence rather than a list (Rule 7).
5. **A12 type gate.** mtail's own builtin path calls `types.FreshType` before unifying, which gives
   a *fresh* type per call site. Copying that idiom makes functions polymorphic and passes every
   single-call-site test; the contract requires one type per function.
6. **Architecture-jump block.** Recursion with a depth limit forbids the "inline the body like a
   decorator" shortcut that would defeat traps 1-4 in one move.
7. **Printer machinery.** `unparser.go` and `sexp.go` both `panic` on an unknown node type, so
   `mfmt` and `--dump_ast` crash on a program with functions unless the solver extends them too.

## Build log

- R1: opcodes + `Object.Functions`, AST nodes, walker, symbol kinds, `Function` type reuse, checker
  declaration/call/return, codegen out-of-line bodies + `Call`, VM frame stack. Smoke test green.
- R2: two real bugs found by the suite. (a) mtail's parser wraps a bare identifier in an *empty*
  `IndexedExpr`, so the assignment-to-a-local intercept never fired and `n += 3` compiled to the
  metric `inc` path; fixed with an unwrapping helper. (b) The mixed int/float call-site test was
  dropped: base mtail already narrows a metric assigned from both an int and a float capref to Int,
  so pinning a value there would have tested undiscoverable behaviour.
- R3: scope raised with `local` declarations (answers issue #333) and printer support, both of which
  are genuine machinery rather than padding: 438 human-effective LOC across 12 hand-written files
  (the hook reports 837 including the goyacc-generated `parser.go`, which the reviewer strips).
- R4: `test.sh` needed `$(go env GOPATH)/bin` on PATH or `go-junit-report` is not found and the
  pipeline dies with SIGPIPE. Dockerfile needed `GOBIN=/usr/local/bin` for goyacc so the non-root
  solver can regenerate the parser.

## Validation

| Check | Result |
|---|---|
| base mode, BASE only | exit 0, 639 test cases, 0 failures |
| new mode, BASE only | exit 1, 97 test cases, **97 failures** (strict F2P) |
| base mode, with solution | exit 0, 639 test cases, 0 failures (zero regressions) |
| new mode, with solution | exit 0, 97 test cases, 0 failures |
| apply order test->solution | clean |
| apply order solution->test | clean |
| determinism | 3x identical, offline (`--network none`) |
| submission image | built, matrix green offline as uid 1000 |
| effective LOC | 438 human-effective excluding generated `parser.go`; 13 files touched |
| meta | 495 words, ASCII clean |
| banned test-file markers | none |

## Open items

- No agent batch has been run, so there is **no difficulty datapoint yet**. The band is a prediction
  (10-25%), not a measurement. Run the standard Nova-heavy batch before submitting and record it in
  eval-results.md.
- If the batch reads too easy, the composition-first lever is ready: the isolation and timestamp
  rules already interact, so harden by testing them *together* (a call that both matches and sets a
  timestamp inside a nested call) rather than adding new prompt sentences.

## Platform pre-check round 1 (2026-07-28)

Four AI pre-checks ran. One hard failure, three warnings; all addressed.

**Dockerfile [FAILED -> fixed].** Three rubric violations: the repo must not be cloned during build
(the build context IS the pre-cloned repo, so `COPY . .`), tests must not run during build (the
`go test -run XXXNONEXISTENT` cache-warm line is banned outright), and `@latest` installs are
non-reproducible. Now: `COPY . .`, no test invocation, `goyacc@v0.48.0` pinned, still installed with
`GOBIN=/usr/local/bin` so a non-root solver can regenerate the parser. Rebuilt from a pre-cloned
context and re-validated.

**Test quality [WARNING -> fixed].** The three named coverage gaps are now tested: calling a
function before its declaration, calling a metric name as if it were a function, and a duplicate
`local` declaration.

**Alignment + behaviour focus [WARNING -> fixed].** Every negative test used to pin an error message
substring ("Redeclaration of function", "expecting 1 arguments", ...), which HARDENING 3d already
calls out as unstably fair. They now use an accept/reject PAIR: a control program that must compile
and a one-change variant that must not. That is behaviour-only, needs no error-wording sentence in
the prompt, and keeps strict F2P, because on base the control program itself fails to compile and
the test fails. The `del` test no longer reads `Metric.LabelValues` length; it asserts datum values
through `GetDatum`. The printer tests no longer pin s-expression tokens; the unparse test asserts
idempotence and that the printed program still runs to the same metric value.

**Description [request_changes -> fixed].** Dropped both HIGH rhetorical sentences and the two
MEDIUM redundancies. The Rule-7 general clause was NOT simply deleted (that would open a fairness
gap for the decorator / `del` / `stop` / indexing tests); it was made concrete instead: "A body is
an ordinary statement list. Patterns, conditionals, otherwise blocks, metric reads and updates,
`del` and `stop` behave inside one exactly as they do outside ...". Naming existing constructs
covers those tests without enumerating any wall. 425 words.

Re-validated after the edits: base 663/0, new 57/57 fail on base and 57/0 with the solution, both
apply orders clean, 3x deterministic, whole matrix green offline as uid 1000 in the rebuilt image.

## Coverage advisory round (2026-07-28)

Four advisory coverage suggestions. Each was PROBED against the real implementation before writing
anything, because two of the four would have been tests of behaviour that does not exist.

**Conflicting type inference [probed, redirected].** The suggestion asked for negative compile tests
where two call sites or two return paths force incompatible types. mtail's type lattice does not
work that way: `types.typeCoercions` contains {Int, String} and {Int, Float}, so `return 1` beside
`return "abc"` unifies to String and COMPILES. There is no fair "incompatible types" rejection to
test - the pairs a program can actually produce all have a least upper bound. Writing the requested
negative test would have invented behaviour. Redirected to the positive form, which is the real
discriminator for the shared-type contract: two differing return paths land on ONE result type
(`TestFuncOneResultTypeAcrossReturns`), and two call sites agree on ONE parameter type driven by the
body (`TestFuncOneParameterTypeAcrossCallSites`). A per-call-site implementation fails both.

**Runtime error attribution [added, no message pin].** `TestFuncDepthLimitStopsTheLine` asserts the
statement before the overflowing call took effect and the statement after it did not, which is
attribution to the processed line expressed as behaviour. No part of the diagnostic string is
matched. mtail's own `errorf` already appends the instruction and source line.

**S-expression structure [added].** `TestFuncSexpStructure` checks the dump represents the function
name, both parameter names, the local declaration and the call's argument, using distinctive
author-chosen identifiers rather than the dumper's node wording.

**Name collisions [probed, one real gap closed].** A parameter and a `local` of the same name
COMPILED, with the local silently shadowing the parameter so the incoming argument became
unreachable - a genuine footgun the suggestion surfaced. Now rejected in the checker
(`c.scope.Lookup` for an existing local before inserting, which also catches an outer-block local of
the same name). A function name colliding with a metric already errored in BOTH declaration orders,
because `Scope.Insert` keys on name alone; both directions are now tested. A `local` colliding with
a metric shadows it, consistent with the parameter rule, and is tested positively.

**Fairness of the additions.** Three prompt clauses were added so nothing new is tested undocumented:
"every return leaves a value of the one result type and every call site agrees on the parameter
types"; "a parameter or a local shadows a metric of the same name"; "A function's name has to be
distinct from every other name declared at the top level", plus "reusing a parameter's name for a
local" in the compile-error list. The recursion sentence now says the runtime error "stops the
program for the line being processed", which is what the attribution test asserts. 476 words, still
under the 500 cap, ASCII clean.

Re-validated: 65 tests, base 663/0, new 65/65 fail on base and 65/0 with the solution, both apply
orders, 3x deterministic offline.

## Coverage advisory round 2 (2026-07-28)

Four more advisory suggestions, again probed before writing.

**Arity lower bound [added].** The suite only passed too MANY arguments. `double()` against a
one-parameter function is a clean checker rejection; added as an accept/reject pair. Already covered
by "passing the wrong number of arguments, is a compile error", which reads both ways.

**Bare `return` [added].** `return` with no expression is a syntax error. The prompt sentence was
sharpened from "leaves the function with the value of its expression" to "`return` takes an
expression and leaves the function with its value" so the rejection is stated rather than implied.

**Top-level namespace [added].** Probed both remaining declaration kinds: a function named after a
`const` pattern fragment and a function named after a decorator `def` are both rejected, because
`Scope.Insert` keys on name alone regardless of symbol kind. Both added. No new prose needed - "A
function's name has to be distinct from every other name declared at the top level" already covers
`const` and `def`.

**Type-conflict rejection [added, after fixing a wart it exposed].** Round 1 established that
Int/Float/String all coerce, so those pairs cannot be rejected. Probing further found the pairs that
DO fail: an argument the conversion table cannot produce, e.g. a regex pattern passed where the
parameter is numeric (`arg_expr` accepts `pattern_expr`, so this is user-reachable). The rejection
was real but surfaced as "Internal compiler error, aborting compilation: internal error: can't
convert ..." - the wrong class of message for a user mistake, and the sort of thing Solution Quality
flags. Both the argument and the return conversion sites now report a normal user-facing type error
instead. The test asserts only that the program is rejected, so no message wording is pinned.

70 tests. Re-validated: base 663/0, new 70/70 fail on base and 70/0 with the solution, both apply
orders, 3x deterministic offline. meta 477 words, ASCII clean.

## Coverage advisory round 3 (2026-07-28)

Two suggestions, both probed and both added. No prompt change was needed this time - each maps to a
sentence already there.

**Float local zero initialisation [added].** `TestFuncFloatLocalZeroInitialisedPerCall` declares a
`local` the body only ever touches with `+=` (so it is read before it is written) inside a function
whose arithmetic types it Float. The discriminator is the repeat: the same input on two consecutive
lines must give 2.5 both times, not 5.0. An implementation that allocates the frame once, or that
zero-fills with an integer, fails. Probed first to confirm the local really does infer Float and
that `zeroValue` hands back 0.0 rather than int64(0) - a wrong zero there produces a runtime
conversion error, and the probe's runtime error string was empty. Covered by "storage local to the
call" plus "`local`, which starts at the zero value of its type".

**Call-site type disagreement [added].** Round 2's pattern-argument test already had two call sites,
but it reads as an argument-kind test, so this adds the pure form: a body that constrains nothing
(`return n`), one call site supplying a numeric capture and the other a regex pattern, so the
conflict comes only from the call sites. Probed the alternatives first - a histogram value at one
site and a number at the other COMPILES, so Buckets is not a usable conflict; Pattern is the one
type in the lattice with no path to a numeric or string parameter. Covered by "every call site
agrees on the parameter types".

72 tests. Re-validated: base 663/0, new 72/72 fail on base and 72/0 with the solution, both apply
orders, 3x deterministic offline. meta unchanged at 477 words.

## Verify Solution round 1 - FAIL on a pre-existing repo flake (2026-07-28)

`./test.sh base` failed on the base repo with 2 failures, both the same test:
`internal/mtail::TestFileSocketStreamComparison` and its subtest
`examples/dhcpd.mtail_on_unixgram://testdata/anonymised_dhcpd_log`. 655 passed, 6 skipped, 2 failed.

Not caused by this submission: base mode applies test.patch ONLY, so none of the solution is
present, and the failing test lives in the log-transport layer, nowhere near the compiler or the VM.
It runs two mtail instances concurrently and pumps a log file through a **unixgram** socket, which
is SOCK_DGRAM: datagrams are dropped when the receiver cannot keep up, so the file-store versus
socket-store metric comparison fails whenever the machine is busy. It passed 3x locally offline,
which is exactly the profile of a load-dependent race.

Fix: `test.sh` base mode now skips `TestFileSocketStreamComparison`, alongside the existing skip of
the new tests, with the reason recorded in the script. The rubric permits skipping flaky tests but
not failures. The whole test function is skipped rather than only the `unixgram` half, because the
`unix` half shares the same three-goroutine timeout harness and would be the next thing to flake;
the transport it covers is unrelated to this task.

Baseline is now 640 cases instead of 663 (the excluded function contributes 23 subtests across its
two schemes). Re-validated: base 640/0 with and without the solution, new 72/72 fail on base and
72/0 with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 4 (2026-07-28) - found a real crash

Four suggestions. One of them exposed a genuine defect in the solution, which is the second time a
coverage advisory has done that on this problem.

**Completely returnless functions [BUG FOUND AND FIXED].** The prompt promises "a body that
finishes without returning leaves the zero value of the function's result type". A function with NO
`return` statement anywhere did not do that - it crashed the compiler with "Internal compiler error,
aborting compilation: no opcode for type typeVar15 in op 57401". Root cause: nothing ever
constrained the result type variable. Returns are what normally bind it, and when the call context
is also unconstrained (a counter, whose own type is a fresh variable), the pair unify with each
other and stay unresolved, so codegen has no opcode to pick. Fix: `checker.Check` now runs
`defaultFuncResults` after the walk, which unifies any still-incomplete function result with Int.
It has to run after the walk, not at the end of the declaration, because a call site is always
later in the source than the declaration it calls and may be what pins the type. Three tests added,
one per zero value, each pinning the result through a different call context: Int (0), Float via
`+ 0.5` (0.5, proving the zero was 0.0 and not an integer), String via `+ "!"` ("!").

**Unused parameters [behaviour changed to match the prompt].** The prompt says "leaving a
declaration unused" is a compile error, and the reviewer correctly asked whether that includes
parameters. It did not: parameters were pre-marked used at declaration. Since every other
declaration kind in mtail rejects being unused (metrics, pattern constants, and now functions and
locals), the honest fix was to make parameters behave the same rather than carve them out of the
sentence. Parameters are no longer pre-marked, and `checkSymbolTable` now runs over the parameter
scope when the body finishes.

**Incompatible return constraints [added].** Round 3 established that Int, Float and String all
coerce, so those branches cannot conflict. The pair that does is Bool against String: the lattice
lists {Bool, String} as a coercion but `emitConversion` has no opcode for it, which is exactly the
inconsistency round 2 turned into a proper user-facing error. `return n > 5` beside `return "small"`
is now a documented rejection.

**Local placement variants [added].** Probed all three placements outside a function: inside a
top-level pattern block, inside a decorated block, and inside a decorator definition. All three are
already rejected by the `len(c.funcs) == 0` guard. The first two are now tested.

No prompt change was needed: all four map to sentences already present ("leaving a declaration
unused", "a body that finishes without returning leaves the zero value", "every return leaves a
value of the one result type", "using `return` or `local` outside a function").

79 tests. Re-validated: base 640/0 with and without the solution, new 79/79 fail on base and 79/0
with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 5 (2026-07-28) - boolean results were unusable

Two suggestions. The first exposed a gap; the second was a straight improvement to an assertion.

**Boolean-valued results [gap found and closed].** `func positive(n) { return n > 0 }` used
directly as a condition was rejected with "Can't interpret Bool as a boolean expression here". The
checker decides what may be a condition by switching on the AST NODE KIND (BinaryExpr, UnaryExpr,
OtherwiseStmt), so a call never qualified no matter what it returned. That contradicts the prompt's
"it may appear anywhere a value may". Fixed by accepting a `*ast.CallExpr` condition whose type is
Bool, and keeping the existing error for any other type. `zeroValue` also gained a Bool case
returning `false`, so a Bool function that falls off the end yields false rather than an integer
zero that `Jnm` would misread. Three tests: call as a bare condition, calls combined with `&&`, and
the Bool fall-off case.

Probed the boundary before touching anything: `total = $1 > 2` is an internal compiler error on
BASE mtail with no functions involved, so assigning a boolean into a numeric metric is a
pre-existing engine limitation, not something this feature introduced. It is deliberately left
alone and not tested - fixing it would mean adding Bool conversions to mtail's shared conversion
table, which is exactly the kind of unrelated blast radius the baseline suite is there to protect.

**Deletion observability [assertion strengthened].** The `del` test asserted the datum value after
deletion, but `GetDatum` recreates a removed series at its zero value, so the check could pass for
the wrong reason. It now uses `FindLabelValueOrNil`, which reports absence directly: the deleted
label is nil, the untouched sibling is not, and its value is still 1.

One prompt clause changed: the zero-value list is now "0, 0.0, false or the empty string", because
a Bool result is now reachable and its fall-off value is tested. 478 words.

82 tests. Re-validated: base 640/0 with and without the solution, new 82/82 fail on base and 82/0
with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 6 (2026-07-28)

Three suggestions, all added. No solution change and no prompt change this round - each one already
worked and each maps to a sentence already in the prompt.

**`func` inside a decorator definition [added].** Probed: already rejected with "Functions may only
be declared at the top level of a program". The block and nested-function placements were tested;
the `def` placement now is too. Covered by "declaring one anywhere else is a compile error".

**Boolean local zero initialisation [added].** A `local` only assigned under a guard, returned, and
used as the call condition. The input sequence is the discriminator: 3 (guard never runs, flag must
read false), 7 (guard runs, sets false), 200 (guard runs, sets true, fires once), then 3 again,
which must NOT fire because the frame is re-zeroed for the new call. An implementation that
allocates the local once, or that zero-fills a Bool slot with an integer, fails on the last line.
Covered by "`local`, which starts at the zero value of its type" plus the zero list that now
includes false. Note this test only became expressible after round 5 made a Bool-typed call usable
as a condition; before that there was no way to observe a Bool local at all.

**Stop recovery across lines [added].** Mirrors the recursion recovery check: three matching lines,
`before` reaches 3 while `later` stays 0, so `stop` inside a body ends only its own line and the VM
resumes for the next. The original single-line test is left untouched. Covered by "`del` and `stop`
behave inside one exactly as they do outside".

85 tests. Re-validated: base 640/0 with and without the solution, new 85/85 fail on base and 85/0
with the solution, both apply orders, 3x deterministic offline. meta unchanged at 478 words.

## Coverage advisory round 7 (2026-07-28)

Two suggestions, both added. No solution change, no prompt change - each already worked and each
maps to a sentence already present.

**Declaration ordering across function bodies [added].** The ordering test only called a later
declaration from a top-level pattern block. `func outer(n) { return inner(n) }` above `func inner`
is now tested too, as an accept/reject pair with the same two functions in the opposite order.
Probed first: rejected with "Function `inner' is not defined". Covered by "A function has to be
declared before it is called", which does not care where the call sits.

**Return control flow side effects [added].** A fair criticism of the existing early-return test:
it asserted the returned VALUE (4 + 10 = 14), which only proves `return` supplies a value, not that
it exits. Two tests now check the exit directly. The first puts `post++` after `return n` in a
straight-line body and asserts `post` stays 0. The second uses a guarded return with three input
lines, two of which take the early path, and asserts `post` is 1 rather than 3 while the total is
still right. Covered by "`return` takes an expression and leaves the function with its value" -
"leaves the function" is the exit. The original test is untouched.

One thing the probe caught: `after` is an mtail keyword (`del ... after <duration>`), so a metric
named `after` is a syntax error. The tests use `post`.

88 tests. Re-validated: base 640/0 with and without the solution, new 88/88 fail on base and 88/0
with the solution, both apply orders, 3x deterministic offline. meta unchanged at 478 words.

## Test Fairness round 1 - FAIL, 3 of 88 unfair (2026-07-28)

The three type-conflict REJECTION tests were ruled unfair and are removed. 85 of 88 passed; the
verdict called the rest deterministic, public-behaviour, and closely tracking the prompt.

Removed: `TestFuncPatternArgumentError`, `TestFuncCallSitesDisagreeOnParameterTypeError`,
`TestFuncIncompatibleReturnTypesError`.

The reviewer is right, and this was a self-inflicted wound. mtail's own lattice gives
`LUB(Pattern, Int) = Bool` (`types.go:530-533`, asserted in `types_test.go:141-146`) and lists
Bool to String as a valid coercion (`types.go:463-470`). Those programs are only rejected because
`emitConversion` has no opcode for the pair - a codegen gap, not a type rule. A solver reusing the
existing type system would reasonably ACCEPT them, so pinning rejection punished the more
repo-faithful implementation. Worse, it was internally inconsistent: another test in the same suite
asserts Int and String DO unify.

I had already reached this conclusion in advisory round 2 ("both available type-conflict rejections
are lattice-vs-codegen inconsistencies, not clean type errors ... risky/unfair") and then added them
anyway because the coverage advisory asked three rounds running. The lesson is that an advisory
suggestion is not evidence a behaviour is fair to pin; when a probe shows a rejection comes from a
missing conversion rather than from a stated rule, the honest answer to the advisory is "this cannot
be tested fairly", which is what I wrote in round 1 and should have held to.

Nothing became undocumented as a result. The prompt's "every call site agrees on the parameter
types" and "every return leaves a value of the one result type" stay covered by the positive tests
that were all judged fair: `TestFuncOneResultTypeAcrossReturns`, `TestFuncOneParameterTypeAcrossCallSites`,
`TestFuncCallSiteDrivesParameterType`, `TestFuncBodyDrivesParameterType`. No prompt change needed.

The codegen change from round 2 stays: an argument or return the conversion table cannot produce now
reports a normal user-facing error instead of "Internal compiler error". It is no longer pinned by
any test, so a solver that accepts those programs instead is equally fine.

85 tests. Re-validated: base 640/0 with and without the solution, new 85/85 fail on base and 85/0
with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 8 (2026-07-28) - one added, one declined

**Runtime error state isolation [added].** `TestFuncRecoversFullyAfterDepthError` runs a line that
blows the recursion limit, then two lines that call a different function using a parameter, a
`local` and a capture, then a line that matches nothing. Total reaches 14 and the call counter
reaches 2, so frames and the value stack unwound cleanly; the `otherwise` block fires once on the
non-matching line, so the match register recovered too. Covered by "a runtime error that stops the
program for the line being processed" plus the capture and match-state rules.

Got the fixture wrong on the first attempt and the test caught it: I expected the `otherwise` to
fire on the recovered `ok` lines, but those lines match an earlier block, and mtail's `otherwise`
only fires when nothing in that scope matched. Fixed the fixture, not the assertion.

**Incompatible type unification [DECLINED].** This is the same request whose tests just FAILED the
Test Fairness gate this round (3 of 88 unfair, all three of them these). Re-adding them would
re-fail it. The premise "the prompt-stated failure boundary" does not hold: the prompt states
exactly two compile errors for calls, calling a non-function and wrong arity, and never says
differing types fail. mtail's lattice gives `LUB(Pattern, Int) = Bool` and lists Bool to String as a
coercion, so a solver following the repo ACCEPTS these programs; the only reason mine rejected them
was a missing `emitConversion` opcode.

Rather than leave the ambiguity for a third round, the prompt now states the rule the fair positive
tests already assert: "Types that differ combine the way the rest of the language already combines
them." That closes the question in the accepting direction, matches the repo, and protects a solver
who would otherwise guess that a rejection is wanted. 492 words.

86 tests. Re-validated: base 640/0 with and without the solution, new 86/86 fail on base and 86/0
with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 9 (2026-07-28) - two added, one declined again

**Recursion boundary [added, with a prompt change to make it fair].** Probed the real edge:
`countdown(99)` succeeds, `countdown(100)` raises the error, so the limit is exactly 100 nested
calls. The prompt only said "too deeply", which makes ANY depth assertion a hidden pin, so it now
says "nests more than a hundred calls deep". `TestFuncFiniteRecursionWellInsideLimit` runs a
50-deep countdown and asserts both the result and the absence of a runtime error, which is what
distinguishes a working guard from an implementation that refuses substantial recursion.

Deliberately NOT testing 99-passes/100-fails. Catching an off-by-one there would pin whether the
outermost call counts as a frame, which the prompt does not say and which does not matter to any
user. After losing three tests to the fairness gate for exactly this kind of over-pinning, a
comfortable interior case plus the existing unbounded-recursion failure covers both directions
without punishing a solver whose frame count differs by one.

**Nested local placement [added].** Probed: `local` inside a conditional block and inside a pattern
block, both within a function body, are allowed and work, and the declaration re-runs each time the
block is entered. Two tests added. The prompt already covers this without a change: the only stated
placement error is `local` OUTSIDE a function, and "a body may declare storage of its own with
`local`" puts no restriction on where in the body.

**Incompatible type constraints [DECLINED, third time].** Same request, same answer. These exact
tests FAILED the Test Fairness gate last round (3 of 88 unfair). mtail's lattice gives
`LUB(Pattern, Int) = Bool` and lists Bool to String as a coercion, so the repo-faithful
implementation ACCEPTS these programs; mine rejected them only because `emitConversion` lacks the
opcode. The prompt now states the accepting rule outright ("Types that differ combine the way the
rest of the language already combines them"), so there is no failure boundary left to test. Adding
these back would re-fail a binding gate to satisfy an advisory one.

89 tests. Re-validated: base 640/0 with and without the solution, new 89/89 fail on base and 89/0
with the solution, both apply orders, 3x deterministic offline.

## Coverage advisory round 10 (2026-07-28) - the type-conflict ask, finally satisfied fairly

**Incompatible type constraints [ADDED, after finding the pair that is actually fair].** Declined
three times because the only rejections I had found (Pattern/Int argument, Bool/String return) came
from a missing `emitConversion` opcode while mtail's lattice says those pairs DO combine - which is
what failed the fairness gate. This round I read `LeastUpperBound` instead of probing by guesswork
and found the real boundary: the function falls through to `TypeError{ErrTypeMismatch}` for any pair
with no coercion and no special case, and **Float against Pattern** is exactly that, while
Pattern/Int is special-cased to Bool and Bool/String is in `typeCoercions`.

Float/Pattern is rejected by mtail's OWN unification, with mtail's own message
("call to `half': type mismatch; expected Float received Pattern"), so a solver reusing `Unify`
rejects it too. That is the difference from the three deleted tests: those punished the
repo-faithful implementation, these agree with it. Both halves the advisory asked for are reachable:
the call-site half passes `/abc/` where the body forced Float via `/ 2.0`, and the return half
returns a `const` pattern name from one branch and a float from the other, since a bare regex is not
allowed in return position. Covered by the prompt's "Types that differ combine the way the rest of
the language already combines them" - when the language cannot combine them, the program cannot be
typed.

**Exact recursion boundary [added, after making the count unambiguous].** Last round I refused to
pin 100/101 because "nests more than a hundred calls deep" does not say whether the outermost call
counts. Fixed the wording instead of dodging it again: "a program with more than a hundred calls
active at once". Active-at-once is a frame count and includes the outermost call, so the edge is now
defined by the prompt rather than by my implementation. `countdown(99)` is 100 active calls and must
succeed with no runtime error; `countdown(100)` is 101 and must raise it. Probed both before
writing.

93 tests. Re-validated: base 640/0 with and without the solution, new 93/93 fail on base and 93/0
with the solution, both apply orders, 3x deterministic offline.

## Verify Flakiness round 1 - FAIL on a second pre-existing repo flake (2026-07-28)

`internal/tailer/logstream::TestFifoStreamReadCompletedBecauseCancel` flipped across the gate's 6
runs. Same class as the socket test excluded earlier and equally unrelated to this submission: it
wraps a fifo write, a context cancel and a goroutine join in a one second `TimeoutTest`, which a
loaded machine misses. Base mode applies test.patch only, so no part of the solution is involved.

Added to the `FLAKY` skip list in test.sh with the reason recorded. Baseline is now 639 cases.
Verified the way the gate does: 6 consecutive base runs, all 639/0, then 6 more with the solution
applied, all 639/0 and 94/0. No test flipped.

## Coverage advisory round 11 + description trim (2026-07-28)

**Callee capture initialization [added].** The advisory expected a runtime check that a caller's
captures are invisible inside a body. The guarantee is stronger than that: a body that reads `$1`
without a match of its own does not compile, because the function's scope parent is the top level
rather than the caller's block, so the capture reference resolves against nothing. The test is an
accept/reject pair, control passing the capture in as a parameter. Covered by "Capture groups inside
a body belong to the matches made inside that body".

**Description suggestions - one taken, one declined.** Removed "A body is an ordinary statement
list.", which did duplicate "gives it a body of ordinary statements" in the opening paragraph; the
sentence that follows still carries the coverage for the pattern, otherwise, `del`, `stop` and
decorator tests. 490 words now.

Kept "Types that differ combine the way the rest of the language already combines them." It is not
an obvious default, it is the sentence that resolves the exact ambiguity that FAILED the Test
Fairness gate two rounds ago: three tests were ruled unfair for assuming differing types reject.
That sentence is now the documented basis for both directions of the suite, the coercion tests
(Int and String unify to String) and this round's Float against Pattern rejections. Removing it
would reopen a gap that has already cost one gate failure, so I am keeping it and flagging the
disagreement rather than trading a binding gate for an optional suggestion.

94 tests. Re-validated: base 639/0 with and without the solution, new 94/94 fail on base and 94/0
with the solution, both apply orders, 6x deterministic offline.

## Description round 3 + coverage advisory round 12 (2026-07-28)

**The HIGH blocker is taken.** Removed "Types that differ combine the way the rest of the language
already combines them." I kept it last round to protect the fairness of the type tests, then checked
that reasoning properly this time and it does not hold. The Float against Pattern rejections follow
from "A function has one type ... every call site agrees on the parameter types": if no single type
can satisfy both sites the program cannot be typed. The coercion tests follow from the same sentence
plus mtail's own table. What made the three DELETED tests unfair was never a missing sentence, it was
that they demanded rejection where mtail's `Unify` SUCCEEDS. That asymmetry is independent of this
sentence, so removing it costs nothing.

**Two of the three MEDIUM/LOW suggestions taken.** Dropped the zero-value enumeration "which is 0,
0.0, false or the empty string" (the four zero tests still rest on "the zero value of its type",
which is unambiguous for these types) and the filler "Add them.". 464 words now.

**Two declined, because each is the only documentation for an assertion.** "stops the program for
the line being processed" is what `TestFuncDepthLimitStopsTheLine` and
`TestFuncStopRecoversOnNextLine` assert, and "Assigning to one changes nothing for the caller" is
what the parameter aliasing test asserts. Both are short. Cutting a sentence that a test pins is how
a description trim turns into a Test Fairness failure, which has already happened once here.

**Nested-local extent [advisory found a real prompt bug].** The prompt said a local shadows a metric
"for the extent of the body". That is wrong: a local declared in a nested block leaves scope at the
end of that block, and the name refers to the metric again afterwards. Reworded to "wherever it is
in scope", which is accurate for a parameter (whole body) and for a local (its block), and added
`TestFuncNestedLocalLeavesScopeAtBlockEnd` to pin it: a local `acc` inside a guard, then `acc = n`
after the guard, must write the METRIC. Had the wording stayed, a solver implementing whole-body
extent would have matched the prompt and failed the test.

**Failed callee match isolation [added].** Two tests where the callee attempts a match that fails:
the caller's capture still reads correctly afterwards and the callee's block does not fire, and a
caller `otherwise` still keys off the caller's own matches. Previous isolation tests all used
successful callee matches.

97 tests. Re-validated: base 639/0 with and without the solution, new 97/97 fail on base and 97/0
with the solution, both apply orders, 6x deterministic offline.

## Problem-and-tests quality round 1 (2026-07-28)

Verdict was OK on leakage, coverage and sanity, with one WARNING: two printer tests assert more
than the brief's "render the new forms" requires, namely unparse idempotence and specific
identifiers in the s-expression dump.

**Unparse test [fixed, and it got stronger].** It carried three assertions: that the output differs
from an unrelated program, that unparsing twice is byte-identical, and that the printed program
recompiles and still produces 21. Only the last is the actual requirement, and it subsumes the other
two: a printer that dropped `func`, the `local`, the guard or either `return` cannot reprint a
program that parses and yields the same metric. Dropped the first two. What remains pins meaning
preservation and no formatting at all.

**S-expression test [kept, brief tightened instead].** The dump is a debug view, not re-parseable,
so a behavioural round trip is not available; the only checks possible are "does not panic" and
"the content appears". Advisory round 1 explicitly asked for the second, calling the panic-only
version shallow, so weakening it now would just reverse a change another reviewer requested. The
assertions are author-chosen identifiers rather than printer punctuation, so no format is pinned.
Removed the "not strictly mandated" objection at its root by making the brief mandate it: "render
the new forms, parameters and call arguments included." 469 words.

97 tests. Re-validated: base 639/0 with and without the solution, new 97/97 fail on base and 97/0
with the solution, both apply orders, 6x deterministic offline.

## Batch 1 - 0 of 7 (2026-07-28). Three hidden requirements, two of them self-inflicted.

0% is a reject, so this is the round that matters. Per the fairness-analysis rule I read every
failure before touching anything, and the tally is damning in a specific way: three of the four
recurring causes were requirements the prompt did not state at batch time, and two of those had been
stated until the description gate asked me to remove them the round before.

**1. A boolean call used as a condition (runs 3, 6, 7).** Never documented. I taught the checker to
accept a Bool-typed `*ast.CallExpr` as a condition back in advisory round 5, because mtail decides
what may be a condition by switching on the AST node kind, and then I tested it without ever saying
so in the prompt. Agents hit the same node-kind switch, saw that mtail rejects bare non-comparison
expressions as conditions even for metrics, and reasonably concluded calls are not allowed either.
This is my own gap, not the description gate's. Now stated: "one that yields a boolean works as a
condition".

**2. Float zero values (runs 1, 3, 7).** The enumeration "which is 0, 0.0, false or the empty
string" was in the prompt and I removed it last round on a MEDIUM suggestion that the zero-of-type
rules "can be inferred from existing code". They cannot: mtail has no user-visible zero-of-type
concept for expressions, and agents defaulted every fall-through and every uninitialised local to
`int64(0)`, which is right for Int and wrong for Float. Run 1 passed 95 of 97 and died on exactly
this. Restored.

**3. Coercive unification at call and return boundaries (runs 5, 6).** "Types that differ combine
the way the rest of the language already combines them" was removed last round on the HIGH
suggestion that it restates deducible global behaviour. The batch says otherwise: two agents built
strict unification that rejects Int to String and Int to Float at function boundaries, which is
valid inside mtail's own expressions but not, apparently, an obvious default at a new boundary.
Restored in shorter form: "Types that differ combine as they already do elsewhere in the language."

**4. An undefined-function call must be a compile error rather than a checker crash (runs 1, 2, 4).**
This one is FAIR and stays. The prompt says calling a name that is not a function is a compile
error; crashing the type checker is an implementation bug.

The lesson to carry: a description reviewer optimises for terseness and cannot see the solver batch.
When it says a requirement is inferable, that is a hypothesis, and the batch is the experiment. Two
sentences it called redundant were, empirically, load-bearing. I had already declined two other
trims on exactly this reasoning and should have declined these as well. Restoring them is not
contesting the reviewer for its own sake, it is the evidence-driven fix the 0-of-7 result demands.

Meta is 495 words, still under the 500 cap, ASCII clean. Nothing else changed: no test was weakened
and no requirement was dropped to make the problem easier. The next batch should show whether
removing three hidden requirements is enough to land inside the band, and run 1's 95 of 97 suggests
it is close.
