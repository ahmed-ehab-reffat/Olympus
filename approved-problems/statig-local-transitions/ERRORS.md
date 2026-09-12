# Implementation and review findings

## Resolved: nextest compiler compatibility

The initial Dockerfile pinned `cargo-nextest` 0.9.140, which requires Rust 1.91
and could not be installed by the repository's Rust 1.90 verification
toolchain. The image now pins 0.9.128, which supports Rust 1.89 and installs,
builds, and runs successfully under Rust 1.90.

## Resolved: outside-subtree discriminator

The first outside-subtree case emitted its external transition from `A`, whose
parent was already the ordinary common ancestor with `B`. An implementation
that unconditionally retained that handler boundary therefore produced the
same path. The final test emits the transition from `A1`; its parent `A` is
deeper than the ordinary `Root` common ancestor with `B`. The corrected case
rejects unconditional widening in both blocking and awaitable engines.

## Resolved: doc-hidden public origin variant

The first independent calibration found a concise implementation that encoded
handler depth in a sixth doc-hidden public `Outcome` variant. It passed the
initial behavior suite but violated the requirement that origin metadata remain
private and made the extra representation observable to downstream exhaustive
matches. The outcome test now exhaustively matches exactly the five documented
variants. This rejects an additional public or doc-hidden carrier while leaving
private dispatch-result designs unconstrained.

## Resolved: over-specified Debug punctuation

The task requires `Debug` to represent both the transition variant and target,
but it does not prescribe delimiters or whitespace. The focused test originally
compared complete strings such as `LocalTransition(Leaf { value: 7 })`. It now
checks independently that the output contains the variant name and the target's
own `Debug` representation, accepting any clear punctuation.

## Resolved: runner environment assumptions

The first runner invoked `cargo +1.90.0 nextest` unconditionally. The Dockerfile
does install both components, but direct use outside the image could fail before
tests started. The runner now prefers the pinned toolchain when rustup reports
it, otherwise uses the active Cargo toolchain. It detects nextest and falls back
to non-fail-fast `cargo test`, emitting a well-formed skipped runner placeholder
when per-test JUnit is unavailable.

Focused tests also record the initialization action-log length dynamically
instead of slicing at fixed offsets, and the helper crate no longer declares an
unnecessary `#![no_std]`.

## Resolved: unclassified synthetic JUnit testcase

When compilation failed before test discovery, the runner emitted a failing
synthetic testcase named `new.run`. Wrapper classification correctly noted that
this placeholder was neither a regression nor a focused test. The runner now
copies nextest JUnit even when real tests fail, preserving their real names. If
no per-test report exists because collection, compilation, or fallback
execution cannot emit one, the synthetic runner testcase is explicitly marked
skipped while the process exit code still reports success or failure.

## Resolved: grader-only offline dependency

The first focused-test crate used `futures` 0.3.26 only for
`futures::executor::block_on` while the runner required offline Cargo. A clean
environment without that package cached could therefore fail before exercising
the submission. The grader now uses a small standard-library executor backed by
a thread waker. Its dependency graph adds only the local Statig crate, and all
focused tests still run offline.

## Resolved: mutable-handler origin timing

Three of four new trajectories passed the original focused suite by recording
an accepting handler's absolute depth. Those implementations recomputed depth
either before or after mutable handler code, so the recorded boundary could
move when a direct trait implementation changed data used by `superstate()`.
The contract now defines origin as the dispatch position that reached the
handler. Focused blocking and awaitable cases cover both a leaf whose hierarchy
deepens while handling and a superstate whose own parent changes before it
returns. The reference solution passes all four cases; every recorded
trajectory fails at least two focused tests.

## Resolved: second-round boundary representations

All four second-round trajectories passed the 20-test suite, but they used
three distinguishable boundary representations. Two carried a relative source
offset and then searched the target ancestry by superstate discriminant; two
stored an absolute accepting depth or boundary.

The interim direct-trait cases exercised the contract's stable accepting boundary.
A hierarchy repeats the same `Layer` variant at two depths, so a target-side
discriminant search cannot identify which occurrence accepted the event. A
separate GAT-backed superstate borrows a `Cell` from the active leaf and inserts
an intermediate ancestor before returning its external transition, so an
absolute snapshot no longer denotes the accepting dispatch position. Blocking
and awaitable observations use only final state and entry/exit action order.
The reference passed 24/24; relative-plus-search patches scored 20/24 and
absolute-depth patches scored 22/24.

## Resolved: concentrated third-round failure

All five third-round trajectories preserved the baseline and passed 22/24
focused tests. Their only failures were the blocking and awaitable copies of
the borrowed handler inserting an ancestor inside its own subtree. Keeping
that pair would have made success depend almost entirely on one subtle dynamic
representation choice.

The pair was replaced with two distinct behaviors. A static outside-subtree
case places the same superstate variant at a different depth in the unrelated
target branch, rejecting searches that match a discriminant anywhere. A
borrowed handler separately deepens the active source before transitioning
outside its subtree, where the ordinary common-ancestor path must include the
changed hierarchy. The unchanged replay is now 3/5 passes: Nova 3 scores 22/26,
Orion scores 24/26, and the other three score 26/26.

## Resolved: fourth-round absolute-depth convergence

Three of four fourth-round trajectories passed the 26-test suite. Two of those
passes stored the accepting handler at an absolute hierarchy depth sampled
before its code ran. That value becomes stale when the same handler remains the
leaf's immediate parent but gains a new ancestor above itself.

The final direct-trait pair performs exactly that mutation in blocking and
awaitable modes. The new ancestor is retained, while the accepting handler
exits and re-enters. After removing an export-path assertion not required by
the brief and one duplicated blocking macro function, the reference and Nova 4
pass 26/26. Nova 1 under-widens to a
leaf-only path, Nova 2 over-widens through the new parent, and Nova 3 enters
the new parent asymmetrically while also retaining its independent cross-branch
collision failure. The resulting unchanged replay is 1/4 passes, with three
observable failure shapes rather than one representation-specific assertion.

## Resolved: fifth-batch discoverability concentration

The next immutable batch completed 0/10. Six patches failed only the two engine
copies of the accepting handler gaining an ancestor above itself, three also
failed the leaf-origin depth-change pair, and one exposed a sixth public
outcome variant. All ten preserved the baseline.

Removing the concentrated pair would project six historical passes and make
the level too easy. The oracle is also a direct consequence of the external
handler-source boundary, so accepting the observed leaf-only or added-parent
paths would weaken the feature. The new iteration instead changes only the
public mutation sentence to explicitly include changes to ancestors above the
accepting handler. Tests and reference behavior remain unchanged, and
calibration restarts at 0/10.

## Resolved: duplicated blocking fairness flag

A fairness review marked the blocking macro function that bundled `A`-origin
local, `A`-origin external, and `Root`-origin external paths as unfair, but its
evidence fields were placeholders. The paths follow the public handler-source
contract, yet the review correctly identified broad blocking/awaitable
duplication. The awaitable macro matrix already covers those boundaries, and a
separate blocking case covers the same local/external split at `A`.

The bundled blocking function and its unused fixture arms were removed. Every
compiling calibration patch passed that function, so no historical failure
becomes a solve. The focused suite is now 26 tests, and all patch-state,
feature, audit, and mutation gates still pass.

## Resolved: repeated-variant failure concentration

The next immutable version reached 0/6. Four Nova patches and two Orion patches
all passed 22 of 26 focused tests and failed only the blocking and awaitable
copies of two repeated-superstate behaviors. Each implementation carried
private handler metadata but searched target ancestry by superstate variant,
collapsing distinct occurrences within one branch and across unrelated
branches.

The behavior remains required, but four assertions no longer dominate the
suite. The prompt now states that subtree membership follows hierarchy
position, the in-branch repeated observation remains only in blocking, and the
cross-branch collision remains only in awaitable. An awaitable macro
same-leaf-storage test adds a separate integration boundary. The reference
passes 25/25; all six unchanged near-passes score 23/25. Because prompt and
tests changed, calibration restarts at 0/10.

## Rejected: nonexistent awaitable superstate helper

Review feedback suggested testing `awaitable::SuperstateExt::handle` directly.
The base repository has no such method: blocking `SuperstateExt` defines
`handle`, while the awaitable extension exposes only hierarchy helpers.
Requiring symmetric helper behavior would invent a new API outside the task.
The existing blocking superstate and awaitable state extension checks remain;
no awaitable superstate helper test was added.

## Expected: upstream formatter baseline

`cargo +1.90.0 fmt --all -- --check` reports existing differences in
`examples/macro/blinky/src/main.rs` and
`examples/macro/calculator/src/state.rs`. Neither file is part of the solution.
All changed Rust files pass an explicit Rust 1.90 formatting check, and the
solution introduces no additional formatter difference.

## Environment: final Docker replay transport

The existing verification image remains inspectable, and the 20-test
predecessor completed all four network-disabled container gates. During the
interim 24-test replay, four `docker run` clients remained idle without creating
containers in the engine. They were terminated, and the same four commands
were rerun in separate pristine local clones with Cargo offline. All expected
patch-state results and JUnit artifacts were produced. This is recorded as a
host Docker transport failure rather than a patch or test failure.

## Open: private submission similarity

The repository's issues, pull requests, branches, tags, history, source, and
available local problem records contain no equivalent handler-origin
transition task. The private cross-repository submission archive was not
available in this environment. Because local and external transitions are
standard statechart concepts, idea-level duplication there remains possible;
the user previously accepted this residual risk.

## Open: dependency resolution without a committed lockfile

Upstream intentionally ignores `Cargo.lock`. The Docker build creates a lock,
fetches every dependency, and prebuilds the workspace before runtime networking
is disabled. The `unit-enum` git dependency resolved to
`5d815fdb8c876ec542a52471b8f897e659db5d92`. A future image rebuild can resolve
newer semver-compatible registry packages unless upstream commits a lockfile or
the platform supplies one before the image build.
