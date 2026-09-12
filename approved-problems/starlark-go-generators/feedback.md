# feedback.md - starlark-go-generators

## Summary

Repo: `google/starlark-go` (Go, BSD-3-Clause, 2736 stars, default branch active 2026-07-08).
Base commit `5395d018f003e2a08bfbca6dcb2562acee700f62`. Our second submission on this repo; the first is
the approved `starlark-go-format-spec` (string formatting in `library.go`), a different subsystem.

Feature (invented dialect extension, so it cannot be publicly solved): generator functions.
`yield` / `yield from` statements, generator expressions, the `generator` value type, `next()` and
`close()`, gated by a new `syntax.FileOptions.Generators` flag the way the repo gates `set`, `while`,
top-level control flow, global reassignment and recursion.

The work is a resumable-frame refactor of the bytecode interpreter, not new semantics. `CallInternal`
was split into `newFrameState` plus a `run` method that can leave the operand stack, the iterator stack
and the program counter parked in a `frameState` and re-enter the loop at the saved pc. Everything else
follows from that: the value type, the compiler's `YIELD` opcode and `Funcode.Generator` flag (with the
bytecode `Version` bump), the resolver's generator classification and static errors, the desugaring of a
generator expression into an implicit one-parameter generator function, and error propagation from an
iterator that can now fail, which had to be threaded through every place in `interp.go`, `eval.go` and
`library.go` that drives an iterator.

## Why this pick (gate log)

- **F2P**: `yield` is a reserved token with no statement rule on base, and no resumable frame exists.
- **Exclusivity**: `gh search issues --repo google/starlark-go` for yield / generator / coroutine returns
  nothing; there is no PR. An invented dialect extension cannot collide with public work.
- **Dedup**: no generator / coroutine feature anywhere in `problems/`, `rejected/` or the approved set.
  The other starlark-go sub is string formatting.
- **Cold**: `interp.go` and `internal/compile` carry no in-flight feature work; recent activity is
  dispatch micro-optimisation (open PRs #643, #645) and parser hardening.
- **Repo quota**: 1 prior sub, no saturation flag.
- **Flakiness**: the repo's own suite is deterministic (3 runs identical) and the new suite has no clock,
  no network, no randomness, no ordering assumptions.

### Residual risk, flagged deliberately

Issue [#557](https://github.com/google/starlark-go/issues/557) asks for *serializing* a running Starlark
thread, and adonovan replies that serializable continuations are "complex and invasive" and that he is
not convinced they belong in the repo, sketching how a fork would do it. That request is about
persisting a thread across processes; this feature is an in-process language construct behind a
FileOptions flag, and the reply neither declines generators nor exists as code. It is the one place a
reviewer running the maintainer-philosophy check could push back, so it is recorded here rather than
buried. If a reviewer treats it as a decline, the same interpreter work re-homes onto another engine
with a hand-written frame loop.

## Difficulty design

Lead traps, all verified by writing the natural-but-wrong version first:

1. **Laziness** (P2): the obvious implementation runs the body up to the first yield when the function is
   called. The discriminator is a side-effect log, so the failure reads as a wrong list, not as a
   generator bug.
2. **Iterator locks across suspension** (S3/S4): the existing `defer` in `CallInternal` calls `Done()` on
   every live iterator when the frame exits. A suspension must not do that, or a list being walked inside
   a suspended body silently unlocks; but the frame must still release them exactly once when the body
   finishes or is closed. Two requirements pulling on the same decision.
3. **Error propagation** (A1): a generator's iterator is the first iterator in this codebase that can
   fail, and `Iterator` has no error channel. Twenty-odd call sites in `interp.go`, `eval.go` and
   `library.go` treat "no next element" as end-of-sequence, so a partial fix makes `list(g)` truncate
   silently instead of failing.
4. **Freeze** (S2): module globals freeze after execution, so a generator stored in a global must refuse
   to advance afterwards; the frame's captured values have to freeze with it.
5. **Re-entrancy** (S1): a body that iterates its own generator corrupts the operand stack unless the
   activation is marked running.
6. **Bytecode round trip** (S3): the new `Funcode` flag has to be serialized and the format version
   bumped, or a compiled-and-reloaded program calls the generator function and gets its body's result.
7. **Eager first sequence** in a generator expression: the sequence of the first clause is evaluated
   where the expression appears, which falls out only if the expression is desugared into a call.

Not tested, deliberately: cross-thread advancement, `dir()` contents, and the wording of any error the
solver invents. No test asserts implementation error text at all; the only substrings matched are the
messages a test program passes to `fail()` itself, which is how the error-propagation tests tell a real
propagation apart from an unrelated failure.

## Validation

- Docker 4-cell from a fresh `git archive` of BASE, `--network none`, `--user 1000:1000`:
  base+test -> base 83 pass / new 91 fail; base+test+solution -> base 83 pass / new 91 pass.
- F2P node parity confirmed: the 91 (classname, name) pairs are identical in both states.
- Both apply orders clean, reverse-apply clean.
- Flakiness: new mode 3x identical (91/0), base mode 3x identical (83/0).
- Environment quality: the vanilla tree builds and `go test ./...` passes offline as UID 1000 in the
  image, before any patch.
- Effective LOC: human-effective 356, raw 601, 12 files (sprint floor 250).

## Platform pre-check round 1 (2026-07-26)

Four checks: three warnings, one hard fail. All addressed.

- **Test file names (FAIL)**: `starlark/gentest1b35e6/generators_test.go` collided with the predictable
  `starlark/generators_test.go`. Renamed to `generators_1b35e6_test.go`; the hashed directory alone was
  not enough, the file name itself has to carry the hash.
- **Description quality (request_changes, 2 HIGH)**: dropped "the way the other dialect options are" and
  the closing sentence about step budgeting and the bytecode round trip; also took the two mediums
  (removed "binds its arguments", cut the enumeration of consumers down to the general rule) and the low
  ("written in parentheses"). meta is now 377 words. Cutting the consumer enumeration also helps
  difficulty: one general rule, instances left to the solver.
- **Tests focus on behavior (WARNING)**: the four asserts on the substring "during iteration" were the
  only ones matching wording the description does not state, so they now assert that the mutation fails,
  not how it reads. The remaining substrings ("already running", "frozen", "exhausted") are words the
  description itself uses.
- **Alignment (WARNING)**: same substring point, plus everything else OK.

Open tension: the two tests for the bytecode round trip and the step budget now assert behavior the
description no longer names, because the description checker called both obvious defaults and demanded
the sentence go. They are kept, since the round trip is a real discriminator (a solver who forgets the
`Funcode` flag or the format version bump gets the body's result back instead of a generator) and both
are universal invariants of the repo's own API. If an alignment round flags them, the fix is a single
clause, not a test deletion.

## Platform pre-check round 2 (2026-07-26)

The file-name failure and the description round both cleared. Two checks came back with the same single
warning: three assertions matched implementation wording (`already running`, `frozen`, `exhausted`).
Those words are in the description as prose, but the description does not mandate message text, and the
corpus law is that no substring is stably fair across rounds. All three now assert only that the
operation fails: reentrant iteration, `next` on an exhausted generator, and advancing after the module
froze. The `fail()` messages the test programs supply themselves are untouched, since those verify that
an error propagated rather than that some unrelated thing broke.

Re-validated after the change: base+test 83/0 and 91 failing nodes; +solution 83/0 and 91/0 on three
consecutive runs; F2P parity 91 identical node ids; node names unchanged, so the `test.sh` fallback list
still matches.

## Test Fairness round (2026-07-26): FAIL, 2 of 64 unfair -> fixed

- **`next_requires_a_generator` (removed)**: asserted `next([1, 2])` must fail. The description introduces
  `next(g)` for a generator and says nothing about other types, and the repo has no prior `next` builtin,
  so a generic-iterable `next` is an equally reasonable reading. Deleted rather than documented: pinning
  the boundary would have added spec text for zero difficulty.
- **`close_is_repeatable` (removed)**: asserted a second `close()` is harmless. Idempotence is neither
  stated nor established anywhere in the repo. Deleted for the same reason; `close_stops_iteration` and
  `close_skips_remaining_body` still cover the documented effect.

All three advisory coverage suggestions were taken (92 nodes now, up from 91):

- `lock_released_when_the_body_fails`: a body that fails while iterating a list passed in as a
  predeclared value must leave that list mutable afterwards, checked from Go after the run aborts. The
  description's locking sentence now reads "until the body ends, by returning or by failing, or the
  generator is closed", so the release path is stated for both exits (meta 382 words).
- `close_during_delegation_releases_source`: `close()` on a generator suspended inside `yield from`
  stops it and releases the delegated source.
- `next_and_close_on_an_expression`: `next` and `close` applied to a generator expression, not only to a
  generator function.

Re-validated: base+test 83/0 with 92 failing new nodes; +solution 83/0 and 92/0 on three consecutive
runs; F2P parity 92 identical node ids.

## Test Fairness round 2 (2026-07-26): PASS, two advisory suggestions taken

No unfair tests. Both coverage suggestions added (92 -> 94 nodes), and both pass against the reference
without any solution change:

- `nested_yield_leaves_the_outer_function_plain`: a function whose only `yield` sits in a nested `def` is
  itself an ordinary function, so its body runs at call time and it returns normally. Complements
  `nested_def_is_a_generator` from the other side, and the description already says the rule is about a
  function's own body.
- `lock_released_when_the_expression_fails`: the generator-expression twin of the failing-body lock
  release, driven through a predeclared list so the source is still reachable from Go after the run
  aborts.

Re-validated: base+test 83/0 with 94 failing new nodes; +solution 83/0 and 94/0 on three consecutive
runs; F2P parity 94 identical node ids.

## Test Fairness round 3 (2026-07-26): PASS, three advisory suggestions taken

No unfair tests again. All three suggestions added (94 -> 97 nodes), all passing against the reference
unchanged:

- `truth_across_states`: a generator stays truthy fresh, partly consumed, exhausted and closed, which is
  what "always true" in the description means.
- `self_advance_through_next_is_an_error`: re-entrancy reached through `next(it)` inside the body rather
  than through `for v in it`, so the rule is not tested only via loop sugar.
- `expression_advanced_after_module_freeze`: the frozen rule applied to a generator expression saved in
  module globals, not just to generator functions.

Re-validated: base+test 83/0 with 97 failing new nodes; +solution 83/0 and 97/0 on three consecutive
runs; F2P parity 97 identical node ids.

## Test Fairness round 4 (2026-07-26): PASS, two of three suggestions taken

- `value_protocol_after_failure` (added): a generator stays truthy, keeps its type and stays unhashable
  after its body has failed. Observing that needs `SourceProgramOptions` + `prog.Init` rather than
  `ExecFileOptions`, since the latter freezes the globals and a frozen generator would mask the state
  under test.
- `yield_from_outside_function` and `yield_from_rejected_without_option` (added): the delegating form is
  scoped and gated exactly like a plain `yield`, not only the bare statement and the expression.
- **Error wording for reentrancy vs frozen: DECLINED.** The suggestion asks for assertions that the
  message says `already running` or `frozen`. Rounds 1 and 2 of the same pipeline flagged exactly those
  substrings as brittle and had me remove them. Re-adding them would fail the next round; no substring is
  stably fair across rounds, so the behavior stays asserted as "the operation fails". Recorded rather
  than silently skipped.

Re-validated: base+test 83/0 with 100 failing new nodes; +solution 83/0 and 100/0 on three consecutive
runs; F2P parity 100 identical node ids.

Session note: the harness temp filesystem filled up mid-round and truncated the worktree test file. The
staged blob restored it (`git checkout-index -f`), the deliverables on disk were never affected, and the
`sg-base` validation image was rebuilt from the deliverable Dockerfile.

## Test Fairness round 5 (2026-07-26): PASS, both suggestions taken

- `from_a_non_iterable`: `yield from 3` fails the way every other iterable-consuming construct in the
  repo does, since the delegation compiles to the same iterator push a `for` loop uses.
- `next_default_ignored_while_live`: `next(g, default)` returns the yielded element while the generator
  still has one, and only falls back to the default once it is spent.

Both pass against the reference unchanged (102 nodes). Re-validated: base+test 83/0 with 102 failing new
nodes; +solution 83/0 and 102/0 on three consecutive runs; F2P parity 102 identical node ids.

Five advisory-only rounds in a row now, each satisfied by the reference with no solution change. The
description and the implementation agree; further rounds are polishing coverage, not moving difficulty.
The one measurement still missing is a Nova/Orion batch, which is the only oracle for the pass band.

## Test Fairness round 6 (2026-07-26): PASS, both suggestions taken (one needed a spec fix first)

- **close idempotence, resolved rather than ping-ponged.** Round 3 removed `close_is_repeatable` as
  unfair because idempotence was "not stated or repo-established". This round asks for it back. The
  objection was about the spec, not the behavior, so the spec now says it: the close sentence gained
  "closing it again does nothing" (meta 387 words), and the test returns as
  `close_is_repeatable_and_next_after_close` together with `next_without_default_after_close_fails`,
  which cover the documented `next` pair against a closed generator.
- `later_clauses_are_lazy`: only the first `for` clause's sequence runs where the expression appears;
  a later `for` clause's sequence and an `if` condition run per element as the generator is advanced.
  Asserted through a side-effect log that shows the interleaving, not just the final values.

105 nodes; reference unchanged again. Re-validated: base+test 83/0 with 105 failing new nodes;
+solution 83/0 and 105/0 on three consecutive runs; F2P parity 105 identical node ids.

## Description Quality round 2 (2026-07-26): request_changes -> fixed

Both HIGH removals applied, plus both MEDIUMs; the LOW was skipped on purpose.

- HIGH: dropped "and the sequence ends when the body returns" and "while a generator whose body has
  finished produces nothing more". Exhaustion is still stated by "A generator is consumed as it is
  iterated and never restarts", which is what the exhaustion tests actually rely on.
- MEDIUM: dropped "whose operand is the element" (the yield paragraph already says a yield produces its
  operand) and "or by a generator expression" from the locking sentence (a generator expression is a
  generator, so "whatever it is iterating" covers it).
- **LOW skipped: "by returning or by failing" stays.** That fragment was added one round earlier
  precisely so `lock_released_when_the_body_fails` and `lock_released_when_the_expression_fails` (both
  requested by Test Fairness) are prompt-stated. Removing an optional phrase to satisfy a LOW note would
  hand the fairness check back a test whose contract is no longer stated.

meta is now 359 words, still ASCII. No test or solution change; the deliverables stay at the 105-node
validated state.

## Test Fairness round 7 (2026-07-26): PASS, both suggestions taken with one narrowing

- `close_before_first_advance`: closing a generator that has never been advanced produces nothing, runs
  no part of the body, and leaves `next(it, default)` returning the default.
- `expression_value_protocol`: type, truthiness (including an empty expression) and unhashability of a
  generator expression value.
  **Narrowed on purpose:** the suggestion also asked for `str(...)`. The description says a generator
  prints as `<generator NAME>`, but a generator expression has no user-written name, so the printed name
  is whatever the solver calls its implicit function. Pinning our reference's spelling would be exactly
  the kind of unstated-wording assert the earlier fairness rounds removed, so type, truth and
  hashability are asserted and the printed form is left alone.

107 nodes; reference unchanged. Re-validated: base+test 83/0 with 107 failing new nodes; +solution 83/0
and 107/0 on three consecutive runs; F2P parity 107 identical node ids.

## Test Fairness round 8 (2026-07-26): PASS, both suggestions taken

- `failed_generator_is_terminal`: after the body fails once, a later `list(g)` is empty,
  `next(g, default)` returns the default, and a side-effect log proves the body did not rerun. Uses
  `prog.Init` so the generator survives the failed call unfrozen and can still be probed.
- `expression_next_and_default` and `expression_next_on_exhausted_fails`: the `next` pair against a
  generator expression, matching the coverage generator functions already had.

110 nodes; reference unchanged. Re-validated: base+test 83/0 with 110 failing new nodes; +solution 83/0
and 110/0 on three consecutive runs; F2P parity 110 identical node ids.

Two tooling notes from this round, both mine, neither in the deliverables: a container run reported
`[setup failed]` once and passed on retry (module fetch race in the dev loop, not in the graded image,
which is offline and prebuilt); and `docker run` without `-i` silently produced an empty JUnit file,
which briefly truncated the synthesized-failure list in `test.sh`. Both caught by asserting the node
count before writing the list, which is now part of the regeneration step.

## Test Fairness round 9 (2026-07-26): PASS, both suggestions taken

- `expression_display_shape_is_stable`: round 7 asked for `str()` on a generator expression and I
  narrowed it out because the printed NAME is solver-invented. The suggestion came back, so this asserts
  only the part the description does fix: the value prints in the documented `<generator NAME>` shape
  (prefix and closing bracket) and that string does not change after exhaustion or close. The name
  itself is still not pinned.
- `delegated_iteration_locks_dict`, `delegated_dict_lock_released_by_close` and
  `delegated_dict_lock_released_when_the_body_fails`: the dict mirror of the delegated-list lock
  coverage, across all three exits.

114 nodes; reference unchanged. Re-validated: base+test 83/0 with 114 failing new nodes; +solution 83/0
and 114/0 on three consecutive runs; F2P parity 114 identical node ids.

Dev-loop fix: proxy.golang.org started timing out mid-round, which broke test runs in the plain base
image. The dev loop now runs against the prebuilt `sg-base` image with `--network none`, the same way
the graded environment does, so no round depends on the network.

## Test Fairness round 10 (2026-07-26): FAIL, 1 of 104 unfair -> fixed

- **Unfair: `expression_display_shape_is_stable [stable across states]`.** The checker split the test:
  the display *shape* assertion is rated Prompt-stated and fair, but asserting the string is
  byte-for-byte identical before draining, after draining and after close pins representation stability
  that neither the description nor the repo establishes. Correct call. The stability half is gone and
  the test is now `expression_display_shape`, keeping only the documented `<generator NAME>` shape.

  This closes the str() thread: round 7 dropped str entirely, round 9 asked for it back and I added
  shape plus stability, round 10 keeps shape and drops stability. Shape is what the description fixes;
  everything past it was mine to invent, which is exactly what fairness rejects.

- Both advisory suggestions taken:
  - `lock_released_by_explicit_return` and `dict_lock_released_by_explicit_return`: a body that exits
    mid-iteration through an explicit bare `return` releases the source immediately, for lists and dicts.
  - `rejection_precedes_execution`: with the option off, a top-level side effect never runs before the
    file is rejected, checked for the statement, the delegating form and the expression through a
    predeclared list that must stay empty.

117 nodes; reference unchanged. Re-validated: base+test 83/0 with 117 failing new nodes; +solution 83/0
and 117/0 on three consecutive runs; F2P parity 117 identical node ids.

## Test Fairness round 11 (2026-07-26): PASS, all three suggestions taken

- `expression_locks_a_dict` and `expression_dict_lock_released`: the dict mirror of the generator
  expression list-lock coverage, held while suspended and released on exhaustion and on close.
- `close_while_delegating_stops_the_outer_body`: closing an outer generator suspended inside
  `yield from inner()` produces nothing further and never runs the outer body past the delegation.
- `expressions_are_independent_activations`: evaluating the same generator expression twice yields two
  generators that advance separately and exhaust separately.

121 nodes; reference unchanged. Re-validated: base+test 83/0 with 121 failing new nodes; +solution 83/0
and 121/0 on three consecutive runs; F2P parity 121 identical node ids.

## Dockerfile guidelines round (2026-07-27): FAIL -> fixed

- **ERROR: no test execution during build.** The cache-warming step ran
  `go test -count=1 -run __none__ ./...`, which invokes the test command even though it selects no
  tests, and the rubric bans running tests at build time. Replaced with a compile-only loop,
  `for pkg in $(go list ./...); do go test -c -o /dev/null "$pkg"; done`, which builds every test binary
  and runs none. Cache warming is preserved, which is what the step was for.
- **WARNING: `GOPROXY=off` in the image ENV.** Dropped from `ENV`, so the image itself is not pinned
  offline and the download step no longer needs to override it. Offline behavior at evaluation time is
  unchanged because `test.sh` sets `GOPROXY=off` itself and the run has no network anyway.

Image rebuilt and the whole matrix re-run against it: base+test 83/0 with 121 failing new nodes;
+solution 83/0 and 121/0 on three consecutive runs; F2P parity 121; vanilla tree still builds and passes
`go test ./...` offline as UID 1000.

## Test Fairness round 12 (2026-07-27): FAIL, 1 of 46 unfair -> test removed for good

- **Unfair: `expression_display_shape`.** The checker now says the `<generator ` prefix and `>` suffix
  are unstated for expression-created generators, because the description fixes the print form only for
  generator functions. Last round the same assertion was rated Prompt-stated and fair. That is the
  substring/format ping-pong the corpus warns about, so the test is deleted rather than reworded a
  fourth time. `type_and_print` still covers `<generator NAME>` for generator functions, which the
  description does state and which has been rated fair every round.

  Full history of this one test: round 7 I left str() out; round 9 the check asked for it and I added
  shape plus stability; round 10 stability was unfair so shape stayed; round 12 shape is unfair too.
  Nothing about a generator expression's printed form is contractual, so nothing about it is testable.

- Both advisory suggestions taken:
  - `expression_closed_before_start`: closing a generator expression before any advance runs no body,
    produces nothing, and leaves the source unlocked.
  - `expression_resumes_after_break`: two for-loops over one generator expression, mirroring the
    generator-function resume-after-break coverage.

122 nodes; reference unchanged. Re-validated: base+test 83/0 with 122 failing new nodes; +solution 83/0
and 122/0 on three consecutive runs; F2P parity 122 identical node ids.

## Test Fairness round 13 (2026-07-27): PASS, both suggestions taken

- `next_with_default_on_a_frozen_generator`: the default argument does not rescue a frozen generator,
  because being frozen is an error condition and not exhaustion.
- `close_after_exhaustion` and `close_after_failure`: closing a generator that already ran out, or that
  already failed, is harmless and leaves it producing nothing.

The close clause in the description was **generalised rather than extended** for the second one: it read
"closing it again does nothing", which only covers an already closed generator, so it now reads "closing
one that has already finished does nothing" and covers closed, exhausted and failed alike. Same length,
broader contract, no new sentence for the description checker to trim (meta 362 words).

125 nodes; reference unchanged. Re-validated: base+test 83/0 with 125 failing new nodes; +solution 83/0
and 125/0 on three consecutive runs; F2P parity 125 identical node ids.

## Test Fairness round 14 (2026-07-27): FAIL, 2 of 87 unfair -> contract widened, tests kept

Both flags were `close()` on a never-started generator: `close_before_first_advance` and
`expression_closed_before_start`. The description scoped close to "a suspended generator" and to one
that "has already finished", leaving the fresh case unstated.

Both of those tests exist because the round 7 coverage suggestion asked for exactly this case, so
deleting them would just invite the same suggestion again. The gap was in the contract, not the tests:
"abandons a suspended generator ... does not resume the rest of its body" is now "abandons a generator
... runs no more of its body", which covers fresh, suspended and finished in the same breath and is
three words shorter (meta 359). The source-lock half needs nothing: a fresh generator is not iterating
anything yet, so the existing "a suspended generator holds whatever it is iterating" already implies an
unlocked source.

Both advisory suggestions taken:
- `expression_self_advance_is_an_error`: `(next(it) for v in [1, 2])` advancing itself hits the
  already-running rule, mirroring the generator-function reentrancy checks.
- bare `next(g)` on a generator that already failed now also has to fail, extending the existing
  post-failure terminal-state test rather than adding a second scaffold for it.

126 nodes; reference unchanged. Re-validated: base+test 83/0 with 126 failing new nodes; +solution 83/0
and 126/0 on three consecutive runs; F2P parity 126 identical node ids.

## Test Fairness round 15 (2026-07-27): PASS, both suggestions taken with one narrowing

- `delegate_failure_makes_the_outer_terminal`: `yield from inner()` where the inner generator fails.
  The outer becomes terminal (empty `list`, `next` default, harmless `close`) and never reaches the code
  after the delegation.
  **Narrowed:** the suggestion also wanted the *delegate* asserted terminal after closing the outer.
  Nothing in the description says closing an outer generator closes what it was delegating to, and the
  reference deliberately leaves the inner suspended, so asserting that would pin an unstated policy -
  the same class of flag that hit the fresh-close tests one round ago. Only the outer, which the
  contract does cover, is asserted.
- `failed_expression_is_terminal`: the post-failure terminal-state checks applied to a generator
  expression, matching the generator-function coverage.

128 nodes; reference unchanged. Re-validated: base+test 83/0 with 128 failing new nodes; +solution 83/0
and 128/0 on three consecutive runs; F2P parity 128 identical node ids.

## Test Fairness round 16 (2026-07-27): FAIL, 4 of 39 unfair -> contract widened, tests kept

All four flags were the same cluster: what a generator looks like after its body has failed
(`failed_generator_is_terminal`, `close_after_failure`, `failed_expression_is_terminal`,
`delegate_failure_makes_the_outer_terminal`). The description said the error reaches the consumer but
never said the generator is finished afterwards, so the aftermath - empty `list`, defaulting `next`,
failing bare `next`, benign `close` - was unstated policy.

Every one of those tests was added at this check's own request (rounds 8, 13 and 15 asked for
post-failure semantics, close-after-failure, and the expression mirror). Deleting them would drop
coverage the check keeps asking for, so the propagation sentence now ends "... and ends that generator,
which afterwards behaves like one whose body has finished". One clause makes all four prompt-stated,
because "finished" already carries the empty-drain, default-returning, bare-next-fails and
close-does-nothing behavior elsewhere in the description (meta 372 words, still ASCII).

No test or solution change. Re-validated: base+test 83/0 with 128 failing new nodes; +solution 83/0 and
128/0 on three consecutive runs; F2P parity 128 identical node ids.

Pattern worth recording for the next author: this checker samples a different subset each run (104, 46,
87, 39 assertions across rounds), and it will suggest a behavior in one round and flag the resulting
test as unstated in a later one. The stable fix is to move the behavior into the contract, not to keep
reshaping the test - unless the behavior is a formatting or wording choice, in which case delete it,
because no contract sentence makes an invented representation fair.

## Attempt history

- Pick round: ichiban/prolog coroutining (default branch 21 months stale), go-imap CONDSTORE and NOTIFY
  (open PRs #756, #690, #735 = exclusivity dead), fancy-regex recursion (maintainer shipped subroutines),
  surrealkv conflict modes (the conflict detector is the maintainer's live workstream). All dropped at
  the gates before any authoring.
- Build round: feature implemented, existing suite green throughout; the only reference bug found was in
  a test of my own (Starlark forbids recursion, so a self-recursive generator is rejected by the existing
  recursion check, which is correct behavior).
- No platform batch yet.
