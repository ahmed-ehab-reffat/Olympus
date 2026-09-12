# Check temporal properties in the simulator

Make the simulator evaluate `always`, `eventually`, `leadsTo`, `enabled`, `orKeep`, `mustChange`
and `next`, in the TypeScript runtime. The Rust evaluator is out of scope.

`next(e)` is the value of `e` in the state a transition leads to. `enabled(a)` says that the action
`a` can be taken from the current state, and takes nothing: it leaves the state exactly as it was.
`a.orKeep(v)` takes `a` when it is enabled, and otherwise takes a stuttering step in which the
variables occurring in `v` keep the values they already have, so it always holds. `a.mustChange(v)`
takes `a` only when the value of `v` in the next state differs from its value in the current one.
A step none of these three operators takes leaves no mark on the next state: whether the step was
rejected or evaluating it raised an error, the next state goes back to what it was when the operator
was called, down to an assignment made before the call and to what the run records about the step. An
error is then what the operator reports, rather than a step it did or did not take.

`always(p)` says that `p` holds at every position of an execution, `eventually(p)` that it holds at
some position, and `p.leadsTo(q)` that after every position where `p` holds there is a position,
then or later, where `q` holds. These three are the only ones that need a run: evaluating `always`,
`eventually` or `leadsTo` outside one is a runtime error with code QNT518, while the four operators
above are evaluated wherever they appear.

Two states are the same state when their variables hold the same values. When a state repeats, the
run stands for the infinite behavior that reaches the first repeated state and then cycles through
the states from there on forever, and the property is decided over that behavior. When no state
repeats, the run is a prefix of executions that were never explored, so it reports a violation only
when no continuation of it could satisfy the property. Over such a prefix an `always` is broken when
some state already breaks it and is otherwise left undecided, an `eventually` holds when some state
already satisfies it and is otherwise left undecided, and an undecided answer stays undecided
through the boolean connectives rather than being read as true or as false. A position with no
successor says nothing about a predicate that reads the next state.
