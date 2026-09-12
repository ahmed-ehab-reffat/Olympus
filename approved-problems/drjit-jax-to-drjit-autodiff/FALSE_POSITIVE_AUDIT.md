# False-positive audit - Dr.Jit JAX-to-Dr.Jit autodiff

Verdict: `pass` for the immutable artifact hashes in `DESIGN.md`.

Audit date: 2026-08-20. This audit was rerun after the Python-scalar contract
correction and follows the worked
`problems/statig-local-transitions/false_postive trials.md` protocol.

## Participant-facing requirements and strongest tests

| Requirement | Strongest behavioral test |
|---|---|
| eager primal bridge | nested primal test |
| independent module/string decorator forms | both mixed pairings plus homogeneous forms |
| positional/keyword nested lists, tuples, and dicts | nested primal and AD tests |
| all forward tangents | nonlinear two-input/two-output JVP |
| all reverse cotangents | weighted two-output VJP |
| aliased-output cotangent accumulation | shared nonlinear value with unequal path cotangents |
| unused and selected-output-disconnected inputs | unused-input test plus `(f(x), g(y))` objective selecting `f(x)` |
| non-differentiable inputs and outputs | mixed float/int/literal grad and direct JVP |
| direct Python floating primals follow JAX differentiation | explicit float argument to both `jax.jvp` and `jax.vjp`, including its scalar VJP cotangent |
| Python integers and signed arrays remain non-differentiable | mixed integer JVP with `float0` tangents |
| supported signed integer preservation | int64 values outside int32 range, plus float primal and grad |
| valid broadcasting | scalar-to-vector reverse reduction |
| call-local derivative state | repeated size sequence with grad and JVP |
| supported float dtype and rank | float16/32/64 rank-2 primal and grad |
| mixed mapped/unmapped inputs and valid axes | nested inputs with axes `-2`, `0`, and `1` |
| primal mappedness independent of AD connectivity | mapped `floor` and float-from-mapped-int values |
| structured batched outputs and output axes | PyTree result with non-default output placement |
| first-order AD composed with batching | `vmap(jvp)`, `jvp(vmap)`, `vmap(vjp)`, and `grad(vmap)` |
| empty primal batching | zero-size mapped input with exact output metadata |
| empty forward batching | empty `vmap(jvp)` including an integer `float0` tangent |
| empty reverse batching | two differently shaped empty inputs under vmapped grad |
| per-batch derivative isolation | mapped JVP/VJP with distinct elementwise sensitivities |

## Plausible mutant construction and isolation

Mutants came from exact repository branches, supported-wrapper asymmetries,
retained solver shortcuts, demonstrated passing-candidate defects, and the gap
audit. All 18 local mutants import and reach behavioral tests in the verified
CPU image.

| Mutant | Evidence for plausibility | Current result | Isolating discriminator |
|---|---|---:|---|
| return zero JVP | supported wrappers have separate forward hooks | 6 failed, 16 passed | forward JVP families |
| seed only first output cotangent | multi-output aggregation is an easy partial implementation | 2 failed, 20 passed | weighted and aliased VJP |
| emit integer zeros instead of `float0` | non-float tangent normalization is a special branch | 1 failed, 21 passed | mixed-output JVP |
| omit scalar normalization | transform-time literals have distinct representations | 2 failed, 20 passed | Python numeric cases in the reference architecture |
| retain stale shape-bound state | foreign wrappers commonly cache descriptors | 1 failed, 21 passed | repeated shape sequence |
| coerce float32 to float64 | bridges may normalize precision | 3 failed, 19 passed | float32 preservation |
| reject nested tuple input | directional flatteners may support one container family | 2 failed, 20 passed | tuple-in-dict input |
| reject nested list output | input and output flatteners may be asymmetric | 2 failed, 20 passed | list-in-dict output |
| accept module forms only as a homogeneous pair | coupled handling passes homogeneous spellings | 2 failed, 20 passed | both mixed pairings |
| overwrite aliased output seeds | repeated `set_grad` can overwrite instead of add | 1 failed, 21 passed | aliased pullback |
| register no batching | predecessor implementations stop at JVP/VJP | 7 failed, 15 passed | eager-`vmap` families |
| support only axis zero | a minimal rule assumes leading-axis mapping | 3 failed, 19 passed | negative and nonleading axes |
| reject unmapped arguments | a rule may require a batch dimension on every leaf | 3 failed, 19 passed | mixed mapped/unmapped PyTrees |
| batch only primal calls | transform registration may omit AD primitives | 4 failed, 18 passed | JVP/VJP batching |
| reject empty batches | slice-first code cannot infer output metadata | 3 failed, 19 passed | all empty-batch families |
| classify mapped float outputs by AD connectivity | primal and derivative metadata are tempting to conflate | 1 failed, 21 passed | mapped `floor` and int-derived float |
| reuse primal output avals for empty JVP and reverse results | all empty branches may share one fallback | 2 failed, 20 passed | empty tangent and input-cotangent metadata |
| narrow signed arrays to int32 | bridges often choose one common integer representation | 1 failed, 21 passed | out-of-range int64 round trip |

The last three local mutants pass all 17 predecessor cases and the full base
lane (84 passed, 63 skipped). They then fail only their named additions. The
first fifteen are the prior exact mutation set rerun against all 22 current
cases. The current suite has zero survivors across the 18 attempted local
mutants.

The prompt-only correction does not add a discriminator or alter mutation
isolation. It resolves the former contradiction that could legitimize a
scalar-cotangent-suppression survivor: Python floats are now explicitly
differentiable, while integer leaves remain explicitly `float0`. All 18 local
mutants were rerun on the corrected immutable version and retained the exact
results above. The three new predecessor survivors were also rerun through the
complete base lane and again produced 84 passed and 63 skipped.

## Demonstrated external survivors

The external panel supplied two independent 17/17 candidates that the prior
verifier accepted:

- The mapped-connectivity candidate returns the first slice and marks the leaf
  unmapped when a diff-typed float result lacks an enabled Dr.Jit gradient.
  Exact-runtime probes produce `[0, 0, 0, 0]` for mapped `floor` where the
  reference gives `[0, 1, 2, 3]`; the local mapped-connectivity mutant
  reproduces this and is rejected by the new primal batching test.
- The transformed-literal candidate treats direct Python numeric primals as
  static leaves, allowing a JAX literal wrapper to reach Dr.Jit arithmetic.
  Exact-runtime `jax.jvp` and `jax.vjp` probes crash while the reference passes.
  Its raw patch is unavailable locally, so the evidence is recorded as an
  external targeted replay, not a local full-suite or base-lane replay.

A coarse local mutant removing every typed-literal normalization fails one old
case and therefore is not claimed as a predecessor survivor. The external
candidate's static-capture design explains why captured constants pass while
direct transformed primals fail, and the new test targets that public boundary
without naming the private JAX wrapper type.

## Survivor and probe decisions

No current local mutant survives. The following exploratory or hypothetical
checks were rejected:

- JIT, higher-order differentiation, and boolean exchange are explicit
  non-requirements;
- nested `vmap`, named collectives, and parallel execution are unannounced;
- int8/int16 and bfloat16 fail in the exact reference/backend;
- every nonsmooth operation, integer width, empty-transform arrangement,
  rank, axis, and container permutation would duplicate admitted semantic
  boundaries; and
- primitive names, source layout, caches, metadata encoding, loop order, call
  counts, and timing would prescribe private implementation details.

All five retained predecessor solvers compose and complete their base lanes.
They pass 13, 14, 13, 15, and 14 of the 22 current feature cases, so none is a
current survivor. Their failures are public behavioral assertions, not build,
startup, patch-composition, or permission failures.

## Exact results and version binding

- pristine feature lane: 22 failed;
- reference feature lane: 22 passed;
- reference base lane: 84 passed, 63 skipped;
- 18 plausible local mutants: zero survivors;
- three new local predecessor survivors: 17/17 plus base pass before their
  targeted current rejection;
- two demonstrated external predecessor passers: 0/2 on the new exact-runtime
  targeted probes; complete raw-patch replay unavailable;
- five retained solver replays: 0/5 current feature pass, all base lanes
  complete; and
- feature testcase identities: matched in the exact composition gate.

Repository and artifact hashes are recorded in `DESIGN.md`. The no-cache
offline arbitrary-UID gate and initialized-submodule replay are recorded in
`ENVIRONMENT.md`. Any submission-artifact, repository, dependency, or
evaluator-composition change invalidates this audit.

## Verdict

Pass. Every admitted probe covers a distinct public discriminator, the exact
reference and base lane pass, pristine and all attempted plausible local
mutants fail appropriately, and the demonstrated external false positives are
addressed. Zero survivors is evidence only for this attempted mutant set, not
proof that false positives are impossible.
