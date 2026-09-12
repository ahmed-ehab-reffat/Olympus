# DESIGN — cadence default arguments

## 1. Title

Add default arguments to Cadence functions and initializers.

## 2. Repo / base

- `onflow/cadence`, Apache-2.0, 548 stars, Go, ~200k LOC source.
- BASE_COMMIT `64b1ef2276fc22199a75991580ebe2464f494e4c` (2026-07-13, tip of `master`).
- Fresh: no cadence submission in `problems/`, `rejected/`, `Aprroved/`, `Olympus/`.

## 3. Shape

O-Composite-extend. An existing language surface (parameter lists, invocations) is
extended through parser -> checker -> interpreter. Tests drive Cadence source strings, so
every test compiles on base and fails at parse/check time (clean F2P, no build break).

## 4. The gap

`docs/feature-inventory.md`: "Default arguments (currently only the `ResourceDestroyed`
default-destroy event)". `parseParameterList(p, expectDefaultArguments bool)` is a
two-state switch: defaults are REQUIRED for a `ResourceDestroyed` event declaration and a
parse error everywhere else (`UnexpectedDefaultArgumentError`). No PR, no issue, no FLIP
proposes general default arguments; issue #3996 (closed) is about built-in optional
arguments in the VM, not user declarations.

## 5. Contract (what the description states)

1. A parameter may be followed by `= expression`. Every parameter after one with a default
   must also have one.
2. A call may leave off any argument whose parameter has a default; each missing one uses
   that default.
3. A default expression is evaluated at each call that omits it, in the declaration's own
   scope, before any parameter is bound, so it cannot see the function's parameters. It is
   not evaluated when the argument is supplied.
4. A default expression must be `view` and must not produce a resource.
5. Defaults are not part of a function's type: a function that has them is still usable
   wherever the same parameter and return types are expected, and a value typed by an
   explicit annotation takes every argument.
6. Available on function declarations, function expressions and initializers. An
   implementation may add one the interface requirement does not have; a function with no
   implementation of its own may not declare one, since there is no scope to evaluate it
   in. Not available on transaction parameters or event parameters, where the existing
   rules stand.
7. A call may leave off any argument whose parameter has a default, not only a trailing
   run of them; the arguments it passes keep declaration order and their labels, and each
   is checked against the parameter it is matched to.

## 6. Trap matrix

| # | Class | Mechanism | Misdirecting symptom |
|---|---|---|---|
| T1 | S5 dual-path / wrong in-repo helper | `FunctionType.Arity{Min,Max}` is the obvious place to record "1 of 2 required" — it is what `checkInvocationArgumentCount` already consumes. But `Arity` is compared by `FunctionType.Equal` (type.go:4601) and by `subtype_check.go:69`. Recording defaults there makes the type of a defaulted function unequal to its own written-out type. | Conformance and assignment fail with a type mismatch between two types that PRINT IDENTICALLY (arity is not rendered by `String()`). Nothing points at the invocation checker. |
| T2 | S3 baseline preservation | The destroy-event default machinery shares `parseParameterList`, `checker.parameters`, `checkFunction` and the event initializer path. Flipping the parser flag to "allowed" everywhere drops `MissingDefaultArgumentError`; routing event initializers through the new default checking double-visits the expression and loosens `checkDefaultDestroyParamExpressionKind`. | Failures land in existing parser/destroy-event suites, not in anything the solver wrote. |
| T3 | scope + ordering (two consumers) | Parameters must not be visible to a default. The checker must visit the expression inside the function activation but BEFORE `declareParameters`; the interpreter must evaluate every needed default BEFORE declaring any parameter variable. A single-loop `bindParameterArguments` leaks earlier parameters into later defaults. | Silent wrong value: with `let x = 10` and `fun f(x: Int, y: Int = x)`, `f(x: 5)` returns 5 instead of 10. No error anywhere. |
| T4 | conditional evaluation | The default must not be evaluated when the argument is supplied. Eager evaluation is invisible for pure arithmetic and visible only through an observable effect. | A counter incremented by a defaulted call site reports one too many. |
| T5 | composition | Purity and the resource restriction have to hold for the default expression itself, which is checked outside the body's purity scope; the natural place (`checkFunction`) runs the body inside `InNewPurityScope`, the default is checked outside it. | An impure default in a non-view function is accepted. |

Every trap sits behind a stated contract sentence, and no sentence names the mechanism:
`Arity`, the visit order, and the two-phase binding are all discoveries.

## 7. File footprint (as built: 14 files, 523 raw, 275 human-effective)

| File | Change |
|---|---|
| `parser/function.go` | the two-state flag delegates to a three-state one (disallowed / allowed / required); the bool signature stays because a base test calls it |
| `ast/parameterlist.go` | required-argument-count helper |
| `sema/type.go` | `FunctionType.MinimumArgumentCount`, derived from the parameters so defaults stay out of `Equal` and subtyping |
| `sema/checker.go` | mark a parameter which declares a default when converting parameters |
| `sema/check_function.go` | check default expressions before the parameters are declared: order, type, purity, resource, no-implementation |
| `sema/check_invocation_expression.go` | match arguments to parameters, minimum argument count, matched-parameter type and label checks |
| `sema/elaboration.go` | the match is recorded for the interpreter |
| `sema/errors.go` | two new checker errors |
| `sema/check_composite_declaration.go`, `sema/check_transaction_declaration.go` | pass the new flag; event initializers keep their own path |
| `interpreter/interpreter_invocation.go` | spread arguments to their parameter position, evaluate every missing default before any parameter is bound |
| `interpreter/interpreter_expression.go`, `interpreter/interpreter.go`, `interpreter/interpreter_transaction.go` | binding call sites; `self` and `base` are made available before binding |

The second axis (leaving off a non-trailing argument) was added after the first pass
measured 183 human-effective. It is not padding: in a language whose calls are label-based
it is what makes a default argument useful, and it forces the matched index through the
label check, the argument type check, the contravariance resolution and the binding.

## 8. Tests

`sema` file: declaration and invocation checking (order, type, purity, resource, scope,
arity, conformance, annotation erasure, transaction/event rejection).
`interpreter` file: evaluation semantics (per-call, only-when-omitted, ordering, scope,
initializers, interfaces, closures).
Assertions on error COUNTS and on existing error types only; no new Go error type is named
by a test, so a solution that reports the same situations through its own error types
passes.

## 9. Out of scope

The `bbq` compiler/VM. `interpreter` tests run the tree-walking interpreter unless
`-compile` is passed (default false), and no base test compiles a program with defaults on
an ordinary function.
