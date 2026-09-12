# DESIGN - Dr.Jit callable exposure in JAX

Status: `accepted and archived 2026-08-20; user-confirmed platform success`.

Repository: `mitsuba-renderer/drjit` at
`c0798bb752172e8ced661443cf308dc3a19d678c`.

## Public contract and repository evidence

Implement the documented but unsupported `drjit.wrap(source="jax",
target="drjit")` direction so a JAX computation can call a Dr.Jit-authored
function. `source` is the framework outside the wrapped function and `target`
is the framework inside it; the original candidate wording had those roles
reversed and was corrected before test authoring.

The task covers eager primal evaluation and first-order `jax.jvp`, `jax.vjp`,
and `jax.grad`; positional and keyword arguments; nested list/tuple/dict
PyTrees in both directions; multiple outputs; float16/32/64 arrays; signed
integer arrays; Python numeric values; rank-2 shapes; valid broadcasting; and
call-local behavior across repeated shapes. Python floating scalars follow
ordinary JAX differentiation semantics. Python integers and signed-integer
arrays remain non-differentiable and use JAX's `float0` tangent convention;
supported signed-integer arrays retain their dtype and value without narrowing.
Unused floating inputs receive zero cotangents.

Eager `jax.vmap` is supported across arbitrary integer input axes, mixed mapped
and unmapped PyTree leaves, structured outputs, empty batches, and both orders
of composition with first-order AD. JIT, higher-order AD, and boolean tensor
exchange remain explicitly excluded.

Repository provenance:

- the public support table marks JAX-to-Dr.Jit primal, forward AD, and reverse
  AD as planned but unsupported;
- `wrap` rejects exactly this source/target combination;
- the existing Dr.Jit-to-JAX `WrapADOp` and Torch-to-Dr.Jit wrapper provide
  public parity evidence without prescribing the missing architecture;
- `from_drjit`, `to_drjit`, `fixup_grad`, `flatten`, and `unflatten` establish
  the conversion, `float0`, and structural conventions; and
- `tests/test_wrap.py` covers corresponding value and AD families in supported
  directions.

## Trajectory-informed design gate

The local problem, candidate, archive, actual-trajectory, and
estimate-trajectory records were searched for Dr.Jit, JAX wrapping,
cross-framework VJP/JVP, PyTrees, and autodiff bridges. No exact Dr.Jit task or
raw solver trajectory exists.

Representative related raw evidence was inspected instead:

| Evidence role | Record | Outcome | Generalized design lesson |
|---|---|---|---|
| Legitimate pass | h5py VDS related pass | pass | Preserve identity/association across a boundary. |
| Near-pass | h5py VDS related near-pass | near-pass | Value conversion alone can lose an identity-sensitive association. |
| Broad failure | PcapPlusPlus related broad failure | failure | One producer mode does not imply a distinct producer mode works. |

The exact repository is the fairness authority. A 2026-08-18 ownership audit
also checked fetched remote branches and the all-open issue/PR feed through
#528; no implementation owner for the missing direction was found.

### 2026-08-19 `agent-runs1` hardening gate

The subsequently available exact-version history was searched before revising
the hidden suite. All five `agent-runs1/Nova_Nova_*` records are legitimate
passes: each passed 84 executed base cases and all 10 predecessor hidden cases.
There is consequently no exact near-pass or broad-failure record in this batch;
those evidence roles are recorded as unavailable rather than replaced with an
unrelated trajectory.

The raw trajectories for runs 1 and 4 were inspected as representative
independent implementations. Run 1 built separate eager primal, JVP, and VJP
paths and exercised both string and module decorator forms. Run 4 explicitly
normalized `source` and `target` independently before dispatch. The remaining
solution patches were also retained for compatibility replay. This evidence
shows that the predecessor's 5/5 solve result is outside the accepted
calibration band and that mixed decorator spellings are a real uncovered API
cell, but it also predicts that adding that cell alone will not reject these
five legitimate solutions.

### 2026-08-19 aliased-output hardening gate

The five exact successful records were reviewed again after T4 closed without
changing their 5/5 result. The raw run 1 and run 4 trajectories remain the
representative legitimate-pass evidence; the batch contains no near-pass or
broad-failure trajectory. All five evaluator records and solution patches were
then compared at the reverse-seeding boundary:

| Run | Reverse-seeding architecture | Platform patch size | Aliased-output probe |
|---|---|---:|---:|
| 1 | per-call JAX spec and leaf-by-leaf Dr.Jit output seeding | 434 changed lines, 2 files | fail |
| 2 | custom JVP/VJP bridge with independently seeded output leaves | 367 changed lines, 2 files | fail |
| 3 | per-call primitive data with independently seeded output leaves | 494 changed lines, 2 files | fail |
| 4 | custom JVP plus whole-output-tree Dr.Jit reverse seeding | 431 changed lines, 2 files | pass |
| 5 | per-wrapper primitive state with independently seeded output leaves | 348 changed lines, 2 files | fail |

The raw trajectories show substantive, independently built eager bridges; none
hardcodes verifier values or shares the reference implementation. The common
leaf-by-leaf shortcut is nevertheless behaviorally wrong when two output paths
refer to the same differentiable Dr.Jit value: the later seed overwrites the
earlier seed, so one public output cotangent is lost. Run 4 demonstrates that a
materially different legitimate architecture can satisfy the behavior.

Fourteen black-box prototype cases were run against the reference and all five
solver patches. Reusable and interleaved pullbacks, rank-zero and multi-axis
broadcasting, mixed-output VJP trees, int64, float16 forward AD, default numeric
keywords, and alternate list/tuple directions passed everywhere. Those cells
were rejected as difficulty additions because they expose no observed shortcut
or distinct survivor. Only the aliased-output case discriminated: run 4 passed;
runs 1, 2, 3, and 5 failed; and a reference prototype using whole-tree reverse
seeding passed all fourteen cases.

### 2026-08-20 submission-rejection gate

The post-hardening review reports a complete 1/10 batch. Its one successful
solver passed the whole task; each of the other nine passed its baseline and 12
of 13 feature cases, failing only aliased-output cotangent accumulation. The
new raw bundle and `evaluation_result.json` are not present in the local problem
folder, so those ten trajectories cannot be inspected independently here. The
reported per-run result is nevertheless sufficient for the disposition
decision because it identifies the same single failure family already observed
in four of the five retained exact solver patches.

The retained raw run 4 trajectory remains a representative legitimate pass.
Runs 1, 2, 3, and 5 remain representative near-passes under the hardened suite:
they implement eager primal evaluation, JVP, VJP, PyTrees, dtype handling,
broadcasting, literals, and call isolation, and miss only alias accumulation.
There is no broad failure in either the retained batch or the externally
reported batch.

The T4 selected-output disconnection proposal was prototyped without changing
the submission artifacts. A wrapped function returned independent `f(x)` and
`g(y)` outputs; differentiating an objective that selected only `f(x)` produced
a zero cotangent for `y`. The current reference and all five retained solver
architectures passed. The probe is fair and closes a literal coverage cell, but
it adds no new implementation boundary and does not change the concentration
finding. Adding it would leave the same nine reported near-passes controlled by
the alias case.

| Observed evidence | Generalized shortcut | Public invariant and oracle | Disposition / anti-overfitting rationale |
|---|---|---|---|
| The existing unused-input test disconnects an input from every output. | Produce zero only for values absent from the complete output graph. | For `(f(x), g(y))`, selecting only `f(x)` must give `dy = 0`. | Fair but non-discriminating: reference and 5/5 retained architectures pass; rejected as an artifact revision because it cannot repair difficulty concentration. |
| Nine reported solvers and 4/5 retained solvers complete every other family but seed aliased leaves independently. | Treat output paths as independent gradient variables. | Two paths to one differentiable value must contribute both cotangents. | The current probe is behaviorally valid, but making this one edge the sole separator is not broad implementation difficulty; duplicating alias fixtures would overfit. |
| The platform reports 153 effective reference lines, below its 200-line floor. | A compact primitive-based reference implements the whole contract. | Code size is not a black-box behavior. | Padding, comments, duplicated branches, or artificial requirements are prohibited. A legitimate larger redesign would need a new public capability and a new problem-design cycle. |

The retained solver patches add two files and have simple nonblank/non-comment
counts of 334, 272, 383, 327, and 268 lines (median 327), which confirms that
agents performed substantial work. Under the local calibration protocol this
is stronger scope evidence than reference size. It does not, however, cure the
external solution-patch LOC rejection, and the reference must not be padded to
game that metric.

### 2026-08-20 eager-vmap redesign gate

The local history search was repeated for JAX batching, `jax.vmap`, primitive
batching rules, and Dr.Jit vectorization across the problem, candidate, archive,
actual-trajectory, and estimate-trajectory records. No separate implementation
or trajectory for JAX-to-Dr.Jit batching exists. The five retained solution
patches and representative raw runs 1 and 4 were inspected again. They all
explicitly stop at eager primal/JVP/VJP primitives; none registers a batching
rule. The externally reported batch has no local raw bundle, but its review says
all ten agents reached the same 12 predecessor behaviors, so it supplies no
contrary batching evidence.

The successor design adds eager `jax.vmap` composition over mapped
array axes, including mixed mapped/unmapped inputs, PyTree leaves, arbitrary
input-axis positions, structured outputs, and first-order JVP/VJP/grad composed
with batching. `jax.jit`, higher-order differentiation, and boolean exchange
remain excluded. Zero-sized mapped axes preserve output
abstract shapes without entering Dr.Jit. This is a new interpreter boundary:
the bridge must normalize batch axes, invoke its existing eager primitive for
each slice without leaking Dr.Jit derivative state, stack every output leaf,
and report output batch dimensions back to JAX. It is not another fixture for
the alias failure family.

Before artifact revision, retained compatibility was forecast at 0/5 because
no retained patch has batching behavior. Fresh calibration was forecast at
1-3/10: prior agents reliably completed the first-order bridge, while batching
adds a distinct JAX interpreter integration and several independent axis/state
boundaries. This is a compatibility replay estimate plus a fresh-calibration
expectation; any artifact revision resets calibration to 0/10.

| Observed evidence | Generalized shortcut | Public invariant and oracle | Anti-overfitting rationale |
|---|---|---|---|
| All retained patches register primal/JVP/VJP behavior but no primitive batcher. | Implement only unbatched eager calls. | `jax.vmap` over a mapped leading axis produces the per-example primal stack. | Exercises a distinct JAX interpreter boundary, not another AD numeric fixture. |
| Batch dimensions may occur on different input axes while some leaves are unmapped. | Assume every input is mapped on axis 0. | Compare mixed `in_axes=(1, None, 0)` against an explicit per-example oracle. | Challenges axis normalization and mapped/unmapped handling independently of formulas. |
| The bridge owns nested flatten/unflatten descriptors and multiple output leaves. | Batch only a flat single-output function. | Vmap a nested input and structured multi-output function and preserve leaf shapes/association. | Reuses the public PyTree contract across a new producer mode rather than prescribing internals. |
| Reverse and forward rules execute Dr.Jit with call-local derivative scopes. | Support primal batching but omit transformed batching or leak state between slices. | Compose vmap with JVP and grad/VJP using distinct per-example seeds. | Separates batching, forward AD, reverse AD, and per-slice lifecycle behavior. |

### 2026-08-20 post-vmap false-positive hardening gate

The local history search was repeated across `problems/README.md`, the
candidate ledgers, compact problem records, archive paths, actual and estimate
trajectory locations, and the retained `agent-runs1` bundle for Dr.Jit/JAX
batching, mapped non-differentiable outputs, JAX typed literals, empty-batch AD,
and signed-integer width. No new raw platform bundle is present locally. The
raw trajectories and patches for retained runs 1 and 4 were re-inspected as
representative independent predecessor architectures. Both built substantive
eager primal/JVP/VJP bridges; run 1 explicitly recognizes JAX typed literals,
while neither implements batching. There is still no local broad-failure
trajectory for the redesigned task.

External adjudication supplies two new exact-version near-passes that each
passed all 17 feature cases. Their raw patches are unavailable locally, so the
reported source snippets are not treated as complete trajectory substitutes.
The first infers whether a primal output is mapped from Dr.Jit AD connectivity;
exact-runtime probes show that `vmap(floor)` and float output derived from a
mapped integer collapse to the first slice. The second leaves JAX
`TypedFloat` primals static; direct `jax.jvp` and `jax.vjp` calls with a Python
numeric then raise in Dr.Jit arithmetic. A separate completeness audit
demonstrated two verifier mutants: reuse primal output metadata for empty JVP
and VJP batches, and normalize every signed integer to `int32`. Both passed the
17-case predecessor; the reference passes the proposed black-box probes.

Before artifact revision, the two demonstrated exact-version passers were
forecast at 0/2 compatibility because each violates a different public
requirement covered by the planned probes. The fresh-calibration expectation
remains 1-3/10: the revision clarifies existing mapped-value, numeric-leaf,
empty-batch AD, and signed-integer preservation obligations rather than adding
a new capability. This is a compatibility replay estimate plus a fresh-batch
forecast; artifact revision resets calibration to 0/10.

| Observed evidence | Generalized shortcut | Public invariant and oracle | Disposition / anti-overfitting rationale |
|---|---|---|---|
| A 17/17 candidate classifies mapped primal outputs through gradient connectivity and repeats the first slice for `floor` and integer-derived floats. | Treat a non-grad-connected float result as batch-invariant. | Every output computed from a mapped leaf is mapped regardless of differentiability; compare `vmap` with explicit per-slice `floor` and integer-to-float results. | Admit one combined black-box probe. It crosses the value-dependence boundary and does not require the reference's stack-all implementation. |
| A separate 17/17 candidate leaves JAX `TypedFloat` primals unconverted during transforms. | Test Python numerics only as captured constants. | Explicit Python numeric primals may cross the boundary without disrupting float JVP/VJP; exercise direct `jax.jvp` and `jax.vjp`. | Admit one probe covering both transform entry paths. Typed-literal normalization is an independently implemented input boundary. |
| A demonstrated mutant reuses primal output avals for every empty primitive. | Infer empty JVP/VJP outputs from primal result metadata. | Empty batches must preserve tangent `float0` and input-cotangent shapes/dtypes under stated first-order compositions. | Admit separate forward and reverse probes because JVP output metadata and VJP input metadata are different primitive branches. |
| A demonstrated mutant narrows every signed integer to `int32`. | Treat the existing int32 example as the only integer representation. | Supported signed integer dtype and value survive the round trip; use large `int64` values and differentiate only the float leaf. | Admit one width-boundary probe. It targets observable corruption, not an arbitrary extra integer fixture. |

Rejected expansions include every integer width, every non-smooth operation,
all combinations of empty-batch transform order, and extra positive/negative
axis permutations. Those would repeat the admitted discriminator families
without crossing another demonstrated implementation boundary.

### 2026-08-20 Python-scalar fairness correction gate

The history search was repeated across the problem and candidate ledgers, the
current compact records, local archive paths, and the retained `agent-runs1`
raw trajectories for Python scalars, typed JAX literals, integer tangents, and
direct scalar VJP. No newer raw platform bundle is available locally. Retained
runs 1 and 4 were re-inspected because they use materially different primitive
architectures. Both explicitly normalize JAX typed literals. Run 4 also
proactively exercised `jax.vjp` with a direct Python floating scalar and
observed its ordinary scalar cotangent, while both implementations preserve
JAX `float0` for integer leaves.

External fairness review found a real public-contract contradiction: the
description grouped all Python numerics with signed integers as
non-differentiable, while the direct numeric VJP test and the reference follow
ordinary JAX semantics for a Python float. The verifier assertion is stable and
useful, but it was not fairly announced. The correction changes only the public
description: Python floating scalars follow JAX differentiation semantics;
Python integers and signed-integer arrays remain non-differentiable and use
`float0` tangents; supported signed-integer arrays preserve dtype and value
without narrowing. No hidden test, solution behavior, or environment behavior
changes.

Before revision, compatibility was forecast to remain 0/2 for the two
demonstrated targeted candidate probes and 0/5 for the retained predecessor
solvers because the executable artifacts are unchanged. Fresh calibration
remains forecast at 1-3/10. This is a compatibility replay estimate plus a
fresh-calibration expectation; the prompt edit nevertheless resets the new
immutable version to 0/10.

| Observed evidence | Generalized shortcut | Public invariant and oracle | Disposition / anti-overfitting rationale |
|---|---|---|---|
| The prompt called all Python numerics non-differentiable, but the reference, direct VJP test, ordinary JAX, and retained run-4 probe differentiate a Python float. | Suppress the scalar cotangent while still converting the value. | Python floating scalars follow JAX differentiation; direct VJP returns the analytic scalar cotangent. Integers remain `float0`. | Clarify the public contract rather than changing the probe. This resolves the contradiction and preserves both a standard JAX input mode and implementation freedom. |

Removing only the scalar-cotangent assertion was rejected because it would
leave the reverse boundary for direct Python floating primals unspecified and
would allow the exact demonstrated transformed-literal failure family to be
partially implemented. Requiring differentiation of Python integers or narrow
integer types unsupported by Dr.Jit was also rejected.

## Discriminator ledger

| Repository-backed risk | Plausible shortcut | Public invariant | Black-box discriminator |
|---|---|---|---|
| Separate AD paths exist in supported wrappers. | Primal-only or reverse-only bridge. | Both first-order JVP and VJP cross the boundary. | Nonlinear, distinct-seed JVP and multi-output VJP. |
| Reverse outputs are independently seeded. | Use only the first cotangent. | Every output cotangent contributes. | Weighted two-output pullback. |
| Helpers preserve container descriptors. | Support dicts but omit tuple inputs or list outputs. | Supported containers survive in their original direction. | Tuple nested in input dict and list nested in output dict. |
| `fixup_grad` distinguishes non-floats. | Return ordinary integer zeros. | Integer output tangents use `float0`. | Mixed float/integer/literal direct JVP. |
| JAX introduces typed scalar literals under AD. | Convert arrays only. | Python numeric inputs remain usable. | Python float and integer operands during grad/JVP. |
| Wrapper state can be cached. | Reuse one shape-bound closure. | Calls of different shapes are independent. | Eager size sequence 2, 5, 3, 2. |
| Conversion code is dtype-sensitive. | Normalize all supported floats to one dtype. | Supported float dtype and rank survive. | Parametric float16/32/64 rank-2 round trip and grad. |
| Broadcasting creates cotangent reductions. | Return broadcast output-shaped cotangent. | Cotangent shape matches the original input. | Scalar input broadcast to vector output. |
| `source` and `target` are normalized independently by the repository API. | Accept only homogeneous string/string or module/module decorator spellings. | Each decorator argument independently accepts its documented string or module form. | Exercise both mixed module/string and string/module pairings through primal and reverse AD. |
| Four successful solvers seed reverse outputs leaf by leaf. | Overwrite the seed when the same differentiable value occupies multiple output paths. | Multi-output reverse AD uses every applicable cotangent, including cotangents attached to aliased PyTree leaves. | Return one shared nonlinear value through tuple and dict paths, seed both differently, and require their summed analytic gradient. |

## Design evolution

The first exact gap pass found missing coverage for Python numeric inputs,
non-differentiable direct JVP outputs, float16/rank-2 surfaces, and container
directionality. The public prompt and reference were revised together, then
the environment, gap, fairness, and false-positive gates restarted from the
new immutable version. Boolean exchange, JIT/vmap, higher-order AD, and private
primitive layout were not added.

External review then exposed an evaluator-only environment blocker: the image
builder appended an unsupported `pip --system` project install, while the test
harness also installed Dr.Jit at runtime. That version was quarantined and no
run counted. The final image builds a frozen Dr.Jit runtime into `/opt`, pins
all Python packages named by the Dockerfile, and completes an editable CPU-only
project install before making the appended project-install condition a no-op.
The final harness copies the frozen runtime, overlays the patched Python
package, and performs no package installation. The public description was also
rewritten as natural paragraphs and its exclusion list was reduced to the
three relevant transformation boundaries.

A second platform replay then exposed initialized submodules in the submitted
build context. Their `.git` pointer files conflicted with the full `.git`
directories in the exact dependency clones. That build was also quarantined
before tests and did not count as a solver result. Dependency staging now
replaces only `/app/ext/drjit-core` and `/app/ext/nanobind` before copying the
exact clones. An initialized-submodule build-context replay, including the
platform's appended install layer, passes on the final Dockerfile.

Final review considered adding solver-facing runner commands to explain the
no-install image design, but leakage review correctly rejected that text as
patch-specific operational detail. The runner and runtime-overlay mechanics
remain confined to internal verification records. The redundant statement that
the wrapped function must be pure was also removed because repeated-call state
independence already states the concrete observable obligation.

The accepted resolution to the later solver-discoverability report is entirely
environmental. The Dockerfile installs the project editably, copies native
artifacts beside the source package, removes the duplicate site-package copy,
and retains `/app` as the editable source path without forcing it ahead of an
explicit `PYTHONPATH`. Ordinary Python therefore imports
`/app/drjit/interop.py`, while an explicit CMake build tree can take precedence.
The evaluator starts Python without site initialization so its exact private
runtime composition remains independent of the editable hook.

An exact full-suite run then exposed a separate AArch64 viability defect in the
pinned native runtime. Docker's LLVM 16 reports the emulated host as `generic`
with a nonempty feature list that omits `+fullfp16`; Dr.Jit's empty-list
fallback therefore does not run, and LLVM aborts while selecting the half
precision `minimum` operation in `test_minmax_nan`. This was quarantined as an
environment failure, not a solver result. The Dockerfile now appends
`+fullfp16` only when the LLVM triple is AArch64, the CPU is exactly `generic`,
and the reported features omit it. A disposable reproducer, the exact no-cache
image, and the initialized-submodule platform image all compiled the corrected
core. The exact upstream suite now completes with 8,324 passed, 1,246 skipped,
and 6 expected failures.

A later out-of-box test report exposed two more image-composition defects.
Moving `pyproject.toml` to neutralize the platform installer also removed the
repository's `norecursedirs = ["ext"]` pytest configuration, so bare
repository-root collection entered unbuilt vendored nanobind tests. Separately,
the editable install left its scikit-build cache at the conventional
`/app/build/cp312-cp312-linux_*` path. Reconfiguring that cache with tests
enabled produced a stable-ABI nanobind abort in `test_call_ext`; deleting it
without preserving backend options instead enabled unavailable CUDA cases.
Both runs were quarantined as environment failures. The final image generates
an equivalent pytest exclusion for `ext` plus generated `build` tests and
replaces the stale cache with a clean Release/Ninja cache preconfigured for the
supported LLVM-only backend. Bare pytest now completes with 8,324 passed,
1,246 skipped, and 6 xfailed. The exact reported build-tree workflow completes
with its native extensions enabled: 8,530 passed, 1,040 skipped, and 6 xfailed.

The reference adds 309 patch lines in `drjit/interop.py`. The local count is
255 nonblank, non-comment lines, or 253 under the stricter convention that also
excludes both one-line docstrings. It uses distinct JAX primitives for primal,
JVP, and VJP, call-local
Dr.Jit AD execution, and batching rules that normalize axes, slice eager calls,
stack structured leaves, and synthesize correctly typed empty batches.

## Immutable artifact identity

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `c813a31df4803e40d5d88bfd47d52cb2f2014a0b307aeb3289f3bfed62c31584` |
| `test.patch` | `495da68f6dacc2731812092007b89589ccfa32cd82cc39fbcfaec3b30f13b4d3` |
| `solution.patch` | `af0e311c1cfb6883dcd22232454f82af28fbfb7c813ee7b1632ea98d0886d953` |
| `Dockerfile` | `7d9b3050dd858f1e69975d502a4e9c4b9550bcf7dc5e31b3822b8f9b02026748` |

Exact evaluator composition on 2026-08-20 produced:

- pristine/base: 84 passed, 63 skipped;
- pristine/new: 22 failed;
- reference/base: 84 passed, 63 skipped; and
- reference/new: 22 passed.

The feature JUnit testcase identities matched across baseline and reference.
Bare repository-root pytest and the explicit build-tree suite produced the
full results recorded above, and all eighteen local plausible mutants remained
rejected.
See `ENVIRONMENT.md`, `GAP_ANALYSIS.md`, `FAIRNESS_ANALYSIS.md`, and
`FALSE_POSITIVE_AUDIT.md` for the bound audit records.

## Difficulty forecast and calibration status

Before hardening, the predicted fresh solve rate was 2-5/10, based on the
independent forward/reverse AD, PyTree direction, literal, dtype, broadcast,
and lifecycle boundaries. This was a fresh-calibration expectation, not a
compatibility replay estimate, because no exact historical Dr.Jit solver patch
exists.

Observed compatible-solver replay is therefore 0/0 historical solver patches;
the reference compatibility lane passed 10/10 hidden cases and 84/84 executed
base cases. That is consistent with correctness but cannot confirm the 2-5/10
forecast. Fresh exact-version calibration remains 0/10 until a new immutable
ten-solver batch is run.

The accepted editable-install hardening is expected to raise the fresh solve
range to 3-6/10 by removing environment-discovery work without disclosing
hidden runner logic. This is a fresh-calibration expectation, not a historical
compatibility estimate. The observed reference replay stayed at 10/10 hidden
and 84/84 executed base cases, ordinary source-based pytest also passed all 84
executed base cases, and all eight mutants remained rejected. That matches the
compatibility forecast; no fresh solver result exists yet, so calibration is
still 0/10.

Before the AArch64 correction, the forecast remained 3-6/10 because the change
was environment-only and introduced no participant-facing discriminator. This
was a fresh-calibration expectation supported by the prior mutant matrix, while
the expected reference/base/full-suite results were a compatibility replay
estimate. The revised exact version produced reference 10/10, base 84 passed
with 63 repository skips, the complete upstream result above, and the unchanged
eight-mutant rejection matrix. This matches the compatibility forecast. Fresh
calibration remains 0/10 until a new ten-solver batch runs on this immutable
version.

Before the clean-cache and pytest-discovery correction, the predicted fresh
solve rate again remained 3-6/10. This was a fresh-calibration expectation,
supported by the unchanged ten-probe contract and prior eight-mutant matrix;
the expected reference, pristine, mutant, and upstream results were a
compatibility replay estimate. The revised immutable version produced
reference 10/10, pristine 0/10, zero survivors across all eight mutants,
8,324/1,246/6 for bare source pytest, and 8,530/1,040/6 for the native
build-tree suite. That matches the forecast. Fresh calibration remains 0/10
until a new exact-version ten-solver batch is run.

Before the mixed-decorator hardening, the compatibility forecast was 5/5
successful prior solvers and the fresh-calibration expectation was 7-10/10.
The predecessor had already produced five legitimate passes, and the inspected
run 4 implementation normalized the two decorator arguments independently.
The revision was therefore forecast to close a public false-positive cell
without moving the solve rate into the accepted band.

The revised exact version matched that forecast. All five compatible solver
patches passed 12/12 hidden cases and their complete base lanes. Pristine
failed 12/12, the reference passed 12/12, and the new homogeneous-only mutant
passed the predecessor's 10 cases before failing exactly the two mixed cases.
The nine-mutant matrix has zero survivors. Because this is a compatibility
replay rather than a fresh calibration batch, fresh calibration remains 0/10;
the predecessor batch is not carried forward.

Before the aliased-output hardening, the compatibility forecast was 1/5
successful prior solvers and the fresh-calibration expectation was 2-4/10.
The forecast was supported by the exact architectural split: runs 1, 2, 3,
and 5 independently seeded output leaves and failed the black-box prototype,
while run 4 seeded the output tree as a whole and passed. The compatibility
number was a replay estimate; the 2-4/10 range remains a fresh-calibration
expectation.

The revised immutable version matched the compatibility forecast exactly.
Run 4 passes all 13 feature cases; runs 1, 2, 3, and 5 pass the 12 predecessor
cases and fail only aliased-output cotangent accumulation. All five retain
their complete base-lane results. Pristine fails 13/13, the reference passes
13/13 plus 84 executed base cases, and all ten mutants are rejected. The old
leaf-by-leaf reference is isolated at 12/13 and also passes the full base lane.
That exact version is now externally reported at 1/10. Although the numeric
solve rate is inside the nominal 1-5/10 band, nine failures are near-complete
solutions rejected by the same narrow alias edge. The calibration therefore
does not establish broad long-horizon difficulty.

Before the eager-vmap redesign, retained compatibility was forecast at 0/5 and
fresh calibration at 1-3/10. The retained patches had no primitive batching
rules, while the prior ten-run evidence showed that agents could reliably build
the first-order bridge. The revised exact version matches the compatibility
forecast: run 4 passes all 13 predecessor cases and fails the four batching
cases; runs 1, 2, 3, and 5 also retain their prior alias failure. All five pass
their complete base lanes. The 15-mutant matrix has zero survivors, with five
separate batching shortcuts rejected across one to four cases. Fresh
calibration is reset to 0/10 for the new hashes; the predecessor's 1/10 result
is evidence only and does not count toward the successor batch.

Before the post-vmap verifier hardening, the two demonstrated 17/17 candidates
were forecast at 0/2 on the planned probes, while fresh calibration remained at
an expected 1-3/10. Exact-runtime adjudicator probes now provide the observed
0/2 feature-level compatibility result: one candidate repeats the first mapped
slice for `floor` and integer-derived floats, and the other rejects direct JAX
typed numeric primals. This matches the forecast. Their raw patches are not
present locally, so this is explicitly a probe replay rather than a complete
local base-lane replay.

The exact revised suite passes 22/22 on the reference and fails 22/22 on
pristine. Three locally constructed predecessor survivors pass 17/17 plus the
complete 84-pass/63-skip base lane, then fail only mapped primal dependence,
empty-batch derivative metadata, or `int64` preservation in the current suite.
The expanded eighteen-mutant local matrix has zero survivors. Fresh calibration
is reset to 0/10 for the new test hash; no result from the abandoned 17-case
version counts toward it.

Before the Python-scalar fairness correction, executable compatibility was
forecast to remain 0/2 on the two external targeted probes and 0/5 across the
retained predecessor solvers, with a fresh expectation of 1-3/10. The corrected
exact version matches that forecast: the unchanged reference passes 22/22 plus
84 base cases with 63 skips, pristine fails 22/22, the 18-mutant matrix has no
survivor, and retained solvers reproduce their 13, 14, 13, 15, and 14 passing
feature cases while completing every base lane. The external raw patches remain
unavailable, so their observed 0/2 result is still a targeted exact-runtime
probe replay rather than a complete local replay. Fresh calibration is 0/10 for
the corrected `meta.md` hash.

## Verdict

Accept the hardened four-artifact version for fresh calibration. The batching
capability and clarified verifier boundaries are public, repository-grounded,
and independently testable. The redesign raises the strict reference
implementation from 153 to 253 effective lines
without padding. Pristine fails 22/22, reference passes 22/22 plus the complete
base lane, all 18 local mutants are rejected, and demonstrated failures span
batching availability, mapped-value classification, axis normalization,
unmapped inputs, transformed and empty-batch AD, numeric literals, integer
width, and output identity. Submission readiness still requires a new
exact-version ten-run batch; its current status is 0/10.
