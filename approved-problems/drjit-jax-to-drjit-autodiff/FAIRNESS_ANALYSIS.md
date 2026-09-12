# Fairness analysis - Dr.Jit JAX-to-Dr.Jit autodiff

Verdict: `pass` for the immutable artifact hashes in `DESIGN.md`.

Audit date: 2026-08-20. Repository pin:
`c0798bb752172e8ced661443cf308dc3a19d678c`.

This exact-version audit was repeated after correcting the Python-scalar
contract. The clean offline composition gate rebuilt the image and replayed
pristine, reference, and five retained solver architectures. The two current
external predecessor passers are available as exact-runtime probe evidence but
not as local raw patches.

## Rejection-predicate audit

| Predicate class | What can reject a submission | Grounding | Verdict |
|---|---|---|---|
| API selection | either mixed or homogeneous string/module spelling fails | public statement that both arguments independently accept both forms; existing `wrap` contract | fair |
| Inside-boundary type | wrapped code does not receive Dr.Jit arrays | public meaning of `target="drjit"`; repository wrapper behavior | fair |
| Primal values and trees | values, constants, kwargs, or list/tuple/dict association differ | public PyTree and eager-primal requirements | fair |
| Forward derivatives | an analytic JVP value or applicable input tangent is missing | public first-order JVP requirement and stable calculus | fair |
| Reverse derivatives | an analytic VJP/grad value or output cotangent is missing | public first-order VJP/grad requirement and stable calculus | fair |
| Aliased reverse outputs | seeds for two paths to one value overwrite rather than accumulate | every applicable output cotangent must contribute; stable reverse summation | fair |
| Selected-output disconnection | an input affecting only an unselected result gets a nonzero cotangent | explicit selected-output zero-cotangent behavior; stable reverse semantics | fair |
| Non-float differentiation | integer tangent is not JAX `float0` or integers become differentiable | public signed-integer/non-differentiable requirement; JAX tangent semantics | fair |
| Direct Python floating primals | a Python float supplied as a transformed primal breaks JVP/VJP or receives the wrong analytic cotangent | explicit statement that Python floating scalars follow ordinary JAX differentiation; standard `jax.jvp`/`jax.vjp` entry forms | fair |
| Python and array integers | an integer becomes differentiable or has a non-`float0` JVP tangent | explicit non-differentiable integer and `float0` requirement; stable JAX tangent semantics | fair |
| Signed integer representation | an int64 input is narrowed or its values change | explicit preservation without narrowing; exact repository int64 conversion support | fair |
| Shape behavior | supported broadcasting, scalar reduction, rank, or output shape is wrong | public shape/broadcast contract and shared JAX/Dr.Jit semantics | fair |
| Floating dtype behavior | float16/32/64 changes dtype | public supported floating-dtype contract and repository support | fair |
| Lifecycle | repeated calls or batch elements share stale derivative state | explicit repeated-call and per-batch isolation requirements | fair |
| Mapped inputs | mixed mapped/unmapped nested inputs or valid axes are rejected or paired incorrectly | explicit eager-`vmap` contract and stable JAX axis semantics | fair |
| Mapped primal values | a result depending on a mapped value is broadcast merely because it is disconnected from Dr.Jit AD | eager `vmap` means value batching, not gradient-connectivity batching; ordinary `floor` and integer arithmetic | fair |
| Batched outputs | structured results or requested output axes are arranged incorrectly | explicit structured eager-`vmap` contract | fair |
| Batched AD | `vmap(jvp)`, `jvp(vmap)`, `vmap(vjp)`, or `grad(vmap)` is wrong | explicit first-order composition requirement and stable JAX transform semantics | fair |
| Empty primal batch | zero-size mapped inputs lose output shape or dtype | explicit empty-shape support and stable array semantics | fair |
| Empty forward batch | an empty mapped JVP gives wrong tangent shape or non-float tangent dtype | first-order composition plus empty-shape and `float0` requirements | fair |
| Empty reverse batch | an empty mapped grad uses output rather than input metadata for cotangents | first-order composition plus input-shape preservation | fair |
| Build lane | the patched exact repository cannot build offline | evaluator contract; failure appears as JUnit | fair |
| Base lane | existing `tests/test_wrap.py` regresses | concrete pre-existing repository behavior | fair |
| Runtime overlay | candidate Python sources are composed over the fixed compiled runtime | task location and repository architecture; every package Python file is overlaid | fair |

The new mapped-output test asserts only per-slice values. A sequential stack,
a vectorized implementation, a custom batching primitive, or a correct
mappedness analysis can all pass; it does not require the reference's
stack-every-leaf strategy. `dr.floor` and float arithmetic from a mapped int64
leaf are ordinary public operations chosen to separate value dependence from
AD connectivity.

The direct numeric test supplies `2.0` through normal `jax.jvp` and `jax.vjp`
APIs. Its nonzero scalar VJP cotangent is now stated explicitly by the public
JAX-differentiation rule; the test does not mention or assert JAX's private
literal wrapper type. The int64 fixture uses values outside int32 range so both
dtype and data-corruption errors are observable; int64 is supported by the
exact JAX/Dr.Jit CPU runtime.
The two empty derivative tests assert only public result shapes, floating
dtypes, and JAX's required non-float `float0` tangent. They do not constrain how
empty outputs are synthesized.

There are no malformed-input checks, arbitrary bytes, hidden layout or symbol
checks, source inspection, primitive-count checks, execution-count checks,
performance thresholds, or task-specific short deadlines. Numeric comparisons
use ordinary tolerances; structure and dtype are exact only where the public
contract requires preservation.

## Corrected fairness complaint

The predecessor description said that signed integer arrays and Python numeric
values “are not differentiable.” The direct numeric VJP simultaneously required
the cotangent of a Python float, so a solver following that sentence could
fairly suppress `dscale` and fail. That complaint was valid. The description
now distinguishes Python floating scalars from integers: floats follow ordinary
JAX differentiation, while Python integers and signed-integer arrays remain
non-differentiable with `float0` JVP tangents. It also explicitly announces
integer preservation without narrowing. No test assertion was added or changed
in this correction.

## Alternative-architecture replay

The exact reference passes 22/22 feature cases and 84 executed base cases with
63 repository skips. Pristine fails 22/22 at the unimplemented public branch.
All five retained solver patches apply, import, and complete their base lanes;
they fail feature assertions behaviorally and pass 13, 14, 13, 15, and 14 of
22. Their lack of batching makes them predecessor architectures rather than
current legitimate complete solutions.

Two substantially different current candidates passed the 17-case predecessor
suite. Exact-runtime candidate/reference probes demonstrate that one silently
broadcasts the first mapped value for grad-disconnected float results and the
other crashes on direct transformed Python numeric primals. Both new
rejections follow public behavior. Because their raw patches are unavailable,
the record does not represent these probes as complete local base-lane replays.

The reference uses sequential eager batching, but the tests permit materially
different correct architectures: vectorized conversion, custom batching,
call-local tapes, alternative metadata caches, or conservative result stacking.
Nothing asserts internal normalization types, metadata encoding, primitive
names, operation order, or loop direction.

## Scope and timeout audit

`jax.jit`, higher-order differentiation, and boolean tensor exchange remain
explicitly excluded. Nested `vmap`, named collectives, parallel execution, and
unsupported narrow integer or bfloat16 variants are not tested. The prompt
contains no runner, hidden-path, or overlay detail. The harness has no product
deadline assertion and requires no runtime network, writable home, package
manager, or root identity. Offline arbitrary-UID viability is recorded in
`ENVIRONMENT.md`.

## Verdict

Pass. Every distinct rejection predicate is grounded in the public prompt,
concrete repository support, or stable JAX/runtime semantics, and the suite
allows legitimate internal designs rather than prescribing the reference.
