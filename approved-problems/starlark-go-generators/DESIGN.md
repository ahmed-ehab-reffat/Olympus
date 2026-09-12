# DESIGN — Add generator functions to the Starlark interpreter

## 1. Title
Add generator functions and the `yield` statement to the Starlark dialect

## 2. Repo / base
- `google/starlark-go` (BSD-3-Clause, 2736 stars, active: last commit 2026-07-08), Go.
- BASE_COMMIT `5395d018f003e2a08bfbca6dcb2562acee700f62`.
- Our subs on this repo: 1 (`Aprroved/starlark-go-format-spec`, a string-formatting feature). Different
  subsystem: that one lives in `library.go` string formatting; this one is scanner -> parser -> resolver ->
  compiler -> bytecode interpreter -> value protocol.

## 3. Shape / tier
- Shape: O-Pipeline-hard (one construct threaded through every stage of the toolchain) crossed with
  S4 machinery-riding (a new value kind that every existing iteration consumer must handle).
- Tier: Olympus. Pass target: well under the 40% cap; the wall is interpreter-internals, not semantics.

## 4. Why this pick clears the gates
1. **Behavioral F2P gap**: base rejects `yield` outright (it is a reserved token with no statement rule),
   and there is no resumable-frame machinery anywhere in the interpreter. Nothing is composable from
   existing primitives.
2. **Not saturated / not a port**: generator *semantics* are familiar, but the difficulty is the
   suspend/resume refactor of `starlark/interp.go` plus the repo's mutation-lock, freeze, step-budget and
   iteration protocols. Nothing in the repo implements a resumable frame.
3. **Not a uniform wrap**: at least six independent mechanisms (laziness, iterator-lock retention,
   error propagation across ~20 iteration sites, freeze interaction, re-entrancy, bytecode
   serialization) — fixing one does not discharge another.
4. **LOC**: genuinely large missing core (new AST node, new opcode, resumable frame state, new value
   type, cross-file iteration plumbing). Target >= 450 effective.
5. **Cold**: `interp.go` / `compile.go` have no in-flight feature work; recent activity is dispatch
   micro-optimisation and parser hardening.
6. **Exclusivity**: no PR and no issue mentions generators / `yield` / coroutines in this repo
   (`gh search issues --repo google/starlark-go yield|generator|coroutine` -> nothing relevant).
   Invented dialect extension, so a public solution cannot exist.
7. **Defined behavior**: dialect extensions behind `syntax.FileOptions` are the repo's own established
   convention (`Set`, `While`, `TopLevelControl`, `GlobalReassign`, `Recursion`).
8. **Deterministic**: pure evaluation, no clock/network/concurrency; the whole suite is value asserts.
9. **Quota**: 1 prior sub on this repo, no platform saturation flag.

Residual risk (documented in feedback.md): issue #557 ("Serializing the state of the Starlark
program/REPL") carries a maintainer comment calling *serializable continuations* invasive. That request
is about persisting a whole thread across processes; this feature is an in-process language construct
gated by a FileOptions flag. Different ask, but a reviewer may read the thread.

## 5. Public surface (kept minimal; everything else is behavior)
- `syntax.FileOptions.Generators bool` — enables the construct for a file.
- `yield` / `yield EXPR` statement.
- A value whose `type()` is `"generator"`.
No new Go-visible constructor, no new exported iteration interface in the contract; the tests drive
everything through `ExecFileOptions` + Starlark source, plus one Go-side freeze check.

## 6. Semantics (the contract that goes in meta.md)
1. A `def` whose own body contains a `yield` is a generator function.
2. `yield` outside a function, or in a file compiled without the option, is a static error.
3. `return EXPR` inside a generator function is a static error; bare `return` ends it.
4. Calling a generator function evaluates and binds the arguments but runs **no** part of the body; it
   returns a generator.
5. Iterating a generator runs the body until the next `yield`; that value is the element. When the body
   returns (or falls off the end) iteration ends.
6. Generators are stateful and resumable: a partially consumed generator continues where it stopped; it
   is never restarted.
7. Advancing a generator that is currently running is an error (`already running`).
8. Advancing a frozen generator is an error.
9. While suspended, the generator keeps the containers it is iterating locked against mutation, exactly
   like a live `for` loop; the locks are released when the body finishes.
10. An error raised inside the body surfaces to whatever is consuming the generator: a `for` loop, a
    comprehension, `in`, argument unpacking, or a built-in such as `list`, `sorted`, `dict`, `min`, `any`.
11. `type()` is `generator`, printing is `<generator NAME>`, truth is true, generators are unhashable.
12. Steps spent inside a generator count against the thread's budget as ordinary steps.

## 7. Trap matrix (each verified by writing the natural-but-wrong implementation first)
| # | Trap | Natural wrong move | Misdirecting symptom | Class |
|---|------|--------------------|----------------------|-------|
| T1 | Laziness | run the body up to the first `yield` at call time | side-effect ordering test fails, not the generator test | P2 over-eagerness |
| T2 | Iterator locks | call `Done()` on the iterator stack when suspending (the existing `defer` does it) | a *later* `append` succeeds when it must fail, or fails when it must succeed | S3 / S4 |
| T3 | Error propagation | wire the error only into `ITERJMP` | `list(g)` silently truncates; the failure looks like a wrong list length | A1 cross-section |
| T4 | Freeze | forget `Freeze` on the new value, or freeze the captured frame values only | mutation of a yielded list is allowed after the module froze | S2 composition |
| T5 | Re-entrancy | no running flag | infinite loop / corrupted operand stack instead of an error | S1 speculative state |
| T6 | Resume after `break` | rebuild the frame from scratch on each `Iterate()` | the second loop restarts from the first element | S1 |
| T7 | Bytecode serialization | forget the `Funcode` flag / the `Version` bump | encode-decode-run yields the generator's *body result* instead of a generator | S3 |
| T8 | Recursion detector | reuse `Call` for resumption | "function g called recursively" on a plain nested generator | A4 host semantics |

Interdependence: T2 and T6 both live in the same `defer`/state-save decision but pull in opposite
directions (you must keep the iterator stack alive across a suspension yet still release it exactly once
on termination); T3 and T4 both ride the iteration protocol that T2 changes.

## 8. File footprint (reference solution)
| File | Change | ~raw |
|---|---|---|
| `syntax/options.go` | `Generators` flag | 3 |
| `syntax/syntax.go` | `YieldStmt` node + `Span` + `stmt()` | 22 |
| `syntax/walk.go` | walk case | 6 |
| `syntax/parse.go` | `yield` statement, option gate | 20 |
| `resolve/resolve.go` | generator classification, static errors | 55 |
| `resolve/binding.go` | `Function.HasYield` | 3 |
| `internal/compile/compile.go` | `YIELD` opcode, `Funcode.Generator`, emit | 40 |
| `internal/compile/serial.go` | encode/decode flag, `Version` bump | 10 |
| `starlark/interp.go` | resumable frame state + suspend/resume core | 180 |
| `starlark/generator.go` (new) | generator value, iterator, resume driver | 190 |
| `starlark/eval.go` | generator construction, `in`, unpacking | 40 |
| `starlark/library.go` | error propagation at the iteration sites | 60 |

## 9. Test outline (new file `starlark/generator_<hash>_test.go`)
Granular subtests, all deterministic, all through the public API:
- construction and laziness; argument binding at call time
- basic iteration, exhaustion, empty generator, `yield` with no value
- statefulness: partial consumption, `break` then continue, nested loops
- delegation: generator iterating another generator; recursion-free mutual use
- consumers: `for`, comprehension, `in`, `list`, `tuple`, `sorted`, `dict`, `min`, `max`, `any`, `all`,
  `enumerate`, `zip`, `reversed`, `set`, `*args` unpacking, tuple-assignment unpacking
- error propagation through each consumer class
- mutation locks held while suspended and released at exhaustion
- re-entrancy error; frozen-generator error (Go side, after module freeze)
- static errors: `yield` outside a function, option disabled, `return v` in a generator
- value protocol: `type`, `str`, truth, unhashable, no comparison
- bytecode round-trip through `Program.Write` / `CompiledProgram`
- step accounting inside a generator

## 10. Fairness
Every tested behavior is one of the twelve numbered sentences in section 6; the meta states the rules
(WHAT) and never the implementation (HOW: frame capture, opcode, iterator stack). Error assertions use
1-3 stable keywords, never whole messages. The one codebase-inferable requirement is the naming
convention of the `FileOptions` flag.

## 11. Predicted band
1-4 of 10. The semantics are transcribable; the resumable-frame refactor, the iterator-lock retention and
the cross-file error plumbing are not.
