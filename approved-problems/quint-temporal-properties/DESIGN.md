# DESIGN — quint-temporal-properties

## 1. Title

Check temporal properties in Quint's simulator.

## 2. Repo + base

- `quint-co/quint` (formerly `informalsystems/quint`), Apache-2.0, 1556 stars, TypeScript, ~1.5k★ niche
  (formal specification languages — zero entries of that domain in the corpus besides our own
  `quint-match-exhaustiveness`, which touched a disjoint subsystem).
- BASE_COMMIT `4e6a580ef40d96914fcebe4e1b4ae95f34c2a75e` (default branch head, 2026-07-20).
- Vanilla suite: 658 passing / 2 failing in 5s. The only two failures are
  `test/runtime/rust/repl.test.ts`, which drive a Rust evaluator binary that is downloaded from
  GitHub releases at run time; on a vanilla checkout (and offline) they cannot pass. `test.sh` base
  mode excludes that directory, with the reason recorded in the script.

## 3. Shape

O-Pipeline-hard / "second evaluation mode on an existing engine". The simulator already generates
runs and checks a state predicate at every state; the task adds a second way of deciding a property
— over the whole execution — and the operators that only make sense there.

## 4. The gap (behavioral F2P)

`quint/src/runtime/impl/builtins.ts` ends with a block that rejects a whole family of the language's
own builtins:

```
case 'always': case 'eventually': case 'enabled':
case 'orKeep': case 'mustChange': case 'weakFair': case 'strongFair': case 'leadsTo':
  return _ => left({ code: 'QNT501', message: `Runtime does not support the built -in operator ...` })
```

`next` is listed in `lazyOps` but has no case at all, so it falls through to `Unknown builtin next`.
Every one of these operators is declared in `src/builtin.qnt`, typed in
`src/types/builtinSignatures.ts` and given an effect in `src/effects/builtinSignatures.ts` — the
front end is complete and the engine is missing. The docs state the limitation:
"Given a model and properties (invariants only, temporal properties are not supported)".

That block has not been touched since 2024-08-29; `leadsTo` was *added to it* in 2026-03. Cold.

## 5. Scope

Make the simulator able to reason about single transitions and about whole executions:

| operator | kind | meaning |
|---|---|---|
| `next(e)` | transition | value of `e` in the successor state |
| `enabled(a)` | state | `a` can be taken from the current state, without taking it |
| `a.orKeep(v)` | action | `a`, or a stuttering step that keeps the variables occurring in `v` |
| `a.mustChange(v)` | action | `a`, and the value of `v` differs in the successor state |
| `always(p)` | run | `p` holds at every position of the behavior |
| `eventually(p)` | run | `p` holds at some position of the behavior |
| `p.leadsTo(q)` | run | after every position where `p` holds, `q` holds then or later |

`weakFair` / `strongFair` stay unsupported: they quantify over action occurrences, which needs a
successor relation the simulator cannot invert. The boundary is stated in the description.

### Run semantics (the part that is NOT already in the repo, so the description states it)

A run is a finite sequence of states. Two cases:

- **Lasso.** If a state repeats, the run denotes the infinite behavior that reaches the first
  repeated state and then cycles forever. Every temporal formula has a definite value there and it
  is computed exactly. Positions reachable from `k` are `[min(k, loopStart), lastDistinct]`.
- **Open prefix.** Otherwise the run is a prefix of unknown continuations, so it can only *refute*:
  a violation is reported only when no continuation could satisfy the formula. `always(p)` is
  refuted by one state where `p` fails; `eventually(p)` and `leadsTo` are never refuted by a prefix.

Three-valued (true / false / unknown) evaluation with Kleene connectives makes both cases one
algorithm. A run reports a violation exactly when the property is `false` at position 0.

## 6. Traps (contract stated, fix hidden), with measured kill counts

Every trap below was proven by writing the natural-but-wrong implementation and re-running the
suite. Kills are out of 128 tests.

| # | trap | kills |
|---|---|---|
| M12 | **State identity is by value, not by reference.** Every state record is rebuilt, so comparing references finds no repeat at all and nothing is ever decided; variables holding sets, tuples or records make the difference visible. | 24 |
| M11 | **The cycle is entered where it starts, not at position zero.** An execution with a stem visits its stem states once; folding from position zero instead of from the first repeated state makes a property that only the stem satisfies look recurrent. | 2 |
| M3 | **A1 `next` needs a second build of the same definition.** Reading `next(e)` means building `e` with variable references bound to the next registers. `Builder.memo` is keyed by definition id, so the second build silently hands back the current-state closure. Symptom: `next(x) == x` everywhere, and a definition read in both states poisons whichever was built first. | 21 |
| M10 | **`always` over the whole behavior, not the position it was asked about.** A recursion that evaluates the operand where it stands, instead of folding it over every position reachable from there, passes the simple cases and dies on nesting. | 13 |
| M9 | **The property arrives as a name.** A run is given `Prop`, not `always(...)`; the temporal structure is behind a definition and has to be unfolded to be recognised, both to route the property and to decompose it. | 9 |
| M1 | **S3 lasso detection has to ignore trace metadata.** `asRecord()` appends `mbt::actionTaken` and `mbt::nondetPicks` when metadata is stored, so comparing whole records never finds a repeat when a state was reached by a different action. Symptom: liveness silently reports OK, with no error. | 3 |
| M4 | **S1 `enabled` must leave nothing behind.** It runs an action; the assignments, the picks and the recorded action all have to be rolled back, or the step that follows inherits them. | 4 |
| M5 | **A prefix is not a behavior.** Concluding from a run that does not repeat a state invents violations for every liveness property that has not come true yet, and hides the ones an open prefix has already broken. | 7 |
| M7 | **`mustChange` restores the next state it found**, rather than clearing it. | 4 |
| M19 | **An error while reading the observed value rejects the step too.** The rollback belongs on the error path, not only on the no-change path. | 1 |
| M14 | **`mustChange` compares the observed value structurally.** A set or a record rebuilt with the same contents is the same value, so a reference comparison reports a change that did not happen. | 10 |
| M15 | **An error under a temporal operator is an error**, not a false position: reading it as a verdict decides a property the run never established. | 7 |
| M16 | **The repeated state belongs to the cycle once.** Keeping both occurrences makes the behavior visit one state twice per lap. | 2 |
| M13 | **An error inside a probed action is an error**, not an answer: swallowing it makes a broken action look merely unavailable. | 1 |
| M6 | **`orKeep` stutters from the state before the attempt**, not from whatever the failed action left behind. | 1 |
| M8 | **The last position of an open prefix has no successor**, so a predicate that reads the next state says nothing there; calling it false invents violations. | 4 |

Retired: a cached-`val` trap was designed (`Builder` clears cached values through `cachesToClear`)
but the mutation killed nothing, because top-level predicates in this path are not cached. Not
claimed.

M1, M5 and M10 are interdependent: making the lasso visible is what gives `eventually` something
definite to say, and folding over positions is what makes the difference between a prefix and a
cycle observable at all.

## 7. Files

| file | change |
|---|---|
| `quint/src/runtime/impl/temporal.ts` | NEW: lasso detection, three-valued evaluation, position sets |
| `quint/src/runtime/impl/builtins.ts` | `enabled`, `orKeep`, `mustChange`, temporal ops outside a run |
| `quint/src/runtime/impl/builder.ts` | next-state build mode, memo keying, `orKeep`/`mustChange` build |
| `quint/src/runtime/impl/VarStorage.ts` | load a state pair (current + successor) |
| `quint/src/runtime/impl/evaluator.ts` | `simulate` decides a temporal property per run |
| `quint/src/quintError.ts` | `QNT518` |

Delivered: 754 raw / **540 human-effective** across 6 files.

## 8. Tests

128 tests, driven only through existing exported APIs (`parse`, `parseExpressionOrDeclaration`,
`Evaluator`, `Evaluator.simulate`) so the package still compiles on base and each test fails at run
time with `QNT501` rather than taking the whole base mode down with a type error. 128/128 fail on
base, 128/128 pass with the solution.

All fixtures are deterministic: state spaces of two to six states, and where a choice appears its
branches are guarded so exactly one is enabled, so no test depends on the RNG.

`test/runtime/deprecated/compile.test.ts` has an "unsupported operators" test; test.patch drops its
`enabled`, `orKeep` and `mustChange` assertions, which the task makes false. The rest of that test
holds both on base and with the solution.

## 9. Fairness

Every operator's meaning is one clause in the description; the run semantics (lasso, refutation)
gets its own paragraph. No message substring is asserted — tests pin error codes and values.
`weakFair`/`strongFair` staying unsupported is stated.
