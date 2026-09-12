# Gap analysis - Dr.Jit JAX-to-Dr.Jit autodiff

Verdict: `pass` for the immutable artifact hashes in `DESIGN.md`.

Audit date: 2026-08-20. Repository pin:
`c0798bb752172e8ced661443cf308dc3a19d678c`.

This exact-version audit was restarted after the Python-scalar fairness
correction. It binds the clarified prompt, unchanged 22-case test patch,
reference, Dockerfile, evaluator composition, and artifact hashes recorded in
`DESIGN.md`.

## Requirement matrix

| Atomic public requirement | Independent family or boundary | Strongest probe |
|---|---|---|
| JAX calls a Dr.Jit function and receives JAX values | unbatched eager primal | nested primal test |
| Decorator source and target independently accept strings or modules | API dispatch | both mixed pairings plus homogeneous forms |
| Positional, keyword, list, tuple, and dictionary structure survives both crossings | PyTree conversion | nested primal and AD tests |
| Differentiable, non-differentiable, constant, and aliased outputs preserve structure | output reconstruction | mixed-output and aliased-output tests |
| JVP propagates every applicable input tangent | forward producer | nonlinear two-input/two-output JVP |
| VJP propagates every applicable output cotangent | reverse producer | weighted two-output pullback |
| Aliased output paths accumulate cotangents | reverse shared identity | aliased-output pullback |
| Inputs disconnected from the selected output receive zero | selected-output connectivity | select `f(x)` from `(f(x), g(y))` and check `dy == 0` |
| Python floating scalars cross and follow ordinary JAX differentiation | transformed scalar conversion | direct numeric JVP/VJP, including the analytic scalar VJP cotangent |
| Python integers and signed integer arrays remain non-differentiable without disrupting float AD | conversion and tangent typing | mixed int/literal grad and JVP with `float0` |
| Supported signed integer width and values survive | integer representation | int64 values outside int32 range |
| Non-float output tangents use JAX `float0` | tangent representation | mixed-output JVP, including an empty mapped axis |
| Broadcast cotangents reduce to each original input shape | reverse shape reduction | scalar-to-vector broadcast grad |
| Repeated calls do not share derivative state | call lifecycle | eager size sequence 2, 5, 3, 2 |
| Supported float dtypes and ranks survive | representation | float16/32/64 rank-2 primal and grad |
| Eager `vmap` invokes the bridge per mapped element | batching interpreter | mixed-axis primal batch |
| Primal mappedness follows value dependence rather than AD connectivity | batching result classification | mapped `floor` and float-from-mapped-int outputs |
| Mapped and unmapped leaves may be mixed | batch participation | nested payload plus unmapped scale |
| Any valid integer input axis is normalized | axis placement | axes `-2`, `0`, and `1` |
| Requested structured output axes are preserved | output batching | dict/list/tuple output with axes `1` and `0` |
| JVP works inside and outside `vmap` | transform composition | `vmap(jvp)` and `jvp(vmap)` |
| VJP works inside `vmap`; grad works outside it | transform composition | vmapped pullback and gradient of a vmapped objective |
| Batch elements have independent derivative scopes | per-element lifecycle | distinct values, tangents, and cotangents per element |
| Empty mapped axes preserve primal output metadata | zero-resource primal batching | structured empty primal |
| Empty mapped axes preserve forward tangent metadata | zero-resource forward batching | empty `vmap(jvp)` with a `float0` tangent |
| Empty mapped axes synthesize reverse results from input avals | zero-resource reverse batching | empty two-input vmapped grad with different leaf shapes |

Container and dtype examples are grouped when they traverse the same branch.
Forward and reverse AD, mappedness, axis normalization, structured outputs,
integer width, literal normalization, and each empty-batch metadata producer
remain separate because repository evidence and demonstrated candidates
implement them independently.

## Repository-grounded challenge pass

Eighteen compile/import-capable local mutants were composed from the exact
reference and run against the complete current feature suite:

| Targeted omission | Current result | Distinct cell challenged |
|---|---:|---|
| no JVP propagation | 6 failed, 16 passed | forward producer |
| only first output cotangent | 2 failed, 20 passed | reverse multi-output aggregation |
| ordinary integer-zero tangent | 1 failed, 21 passed | `float0` normalization |
| no scalar normalization | 2 failed, 20 passed | literal boundary in the reference architecture |
| stale shape-bound state | 1 failed, 21 passed | invocation lifecycle |
| force float32 to float64 | 3 failed, 19 passed | supported float dtype |
| reject tuple inputs | 2 failed, 20 passed | tuple input direction |
| reject list outputs | 2 failed, 20 passed | list output direction |
| homogeneous-only decorator forms | 2 failed, 20 passed | independent API normalization |
| overwrite aliased output seeds | 1 failed, 21 passed | shared-output accumulation |
| omit batching | 7 failed, 15 passed | batching interpreter boundary |
| force mapped axes to zero | 3 failed, 19 passed | nonleading and negative axes |
| reject unmapped batch inputs | 3 failed, 19 passed | mixed mapped participation |
| batch primal only | 4 failed, 18 passed | AD primitive batching |
| reject empty batches | 3 failed, 19 passed | zero-resource synthesis |
| infer mapped primal leaves from AD connectivity | 1 failed, 21 passed | mapped value dependence |
| reuse primal metadata for all empty derivative primitives | 2 failed, 20 passed | empty JVP and reverse metadata |
| normalize all signed integers to int32 | 1 failed, 21 passed | int64 preservation |

The last three mutants pass all 17 predecessor cases and the full base lane
(84 passed, 63 skipped) before failing only their new discriminator. The first
fifteen are the prior exact-version mutation set rerun against all 22 cases.
No local mutant survives.

The corrected prompt removes the only fairness ambiguity found by the latest
review. A solver may no longer reasonably suppress the cotangent of a direct
Python floating primal based on the former blanket statement about Python
numerics. Conversely, no probe differentiates Python integers: those remain
explicitly non-differentiable and use `float0`. The int64 assertion is now
directly announced as dtype/value preservation without narrowing.

Two current external candidates provide additional trajectory evidence. One
passed the 17-case predecessor while using AD connectivity as its batching
classifier; exact-runtime probes reproduced first-slice broadcasting for
`vmap(floor)` and float-from-mapped-int. The corresponding local mutant
reproduces and isolates that behavior. A different 17/17 candidate did not
normalize transformed Python numeric primals and crashed direct `jax.jvp` and
`jax.vjp`; its raw patch is not retained locally, so this audit relies on the
reported exact-runtime candidate/reference replay rather than claiming a local
full-suite replay. A reference mutant that simply removes all typed-literal
normalization is broader and already fails one predecessor case, confirming
that the external candidate represents a distinct input architecture rather
than that coarse mutation.

The pristine implementation fails 22/22 and the reference passes 22/22. The
reference also passes the complete base lane. All five retained solver patches
compose conflict-free and complete their base lanes; they pass 13, 14, 13, 15,
and 14 of the current feature cases respectively, for a 0/5 compatibility
result.

## Excluded and rejected cells

`jax.jit`, higher-order differentiation, and boolean tensor exchange are
public non-requirements. Nested `vmap`, named collectives, parallel execution,
the full rank/axis/container Cartesian product, every nonsmooth primitive, and
every empty-transform permutation were rejected as unannounced or redundant.
Additional int8/int16 and bfloat16 probes were rejected because the exact
reference/backend does not support them. Negative output axes and multi-axis
broadcasting passed exploratory reference probes but do not cross a new
implementation boundary beyond the admitted axis and broadcast tests.

No probe inspects primitive names, caches, call counts, loop order, descriptor
encoding, source layout, or timing. Environment behavior is audited separately
in `ENVIRONMENT.md` and creates no participant requirement.

## Verdict

Pass. Every atomic public requirement has a strongest black-box oracle, each
new probe passes the reference and pristine still fails it, all attempted
plausible local mutants are rejected, and the two demonstrated external false
positives are addressed without prescribing the reference implementation.
