# Calibration levels - explicit local and external transitions

## Current level

The problem was accepted on 2026-07-26. The final immutable artifact contains
46 focused tests and 33 false-positive mutations. It retains the same core
difficulty: private accepting-handler provenance across two structurally
different engines, GAT-safe ownership, exactly five public outcome variants,
legacy self-transition timing, and current hierarchy occurrences rather than
stale depths or matching variants.

The reference solution changes 349 production lines across six core files.
`RUNS.md` is the compact collection index; the detailed narrative below
preserves the calibration and redesign history without treating results from
different immutable versions as one aggregate rate.

## Results

| Run | Result | Churn | Failure or completion family |
|---|---|---:|---|
| 1 | Initial 18/18 new and full base pass | 153 | Encoded origin in a sixth doc-hidden public outcome; the revised exhaustive variant check rejects it. |
| 2 | 18/18 new and full base pass | 374 | Valid private dispatch result; README work omitted at timebox. |
| 3 | Did not compile | 374 | `E0507` move from a GAT-backed non-`Copy` superstate while deriving ancestry. |
| 4 | Production compiled; base UI test failed | 290 | Trybuild diagnostic snapshot changed, indicating a public trait/bound regression; focused run not reached. |
| 5 | Verification not reached | 446 | Stopped at formatting, including both implementation diffs and the documented upstream example baseline. |
| 6 | 18/18 new and full base pass | 277 | Valid private boundary-depth dispatch; README work omitted at timebox. |
| 7 | Partial blocking implementation | 181 | Awaitable parity and exhaustive matches remained incomplete. |
| 8 | Analysis-only | 0 | Identified private handler-origin transport as the central implementation blocker. |
| 9 | Analysis-only | 0 | Identified the same compile/API and recursive-versus-iterative dispatch split. |
| 10 | Analysis-only | 0 | Identified GAT-safe private dispatch as the main risk; rated difficulty 4/5. |

## Nova hardening replay

Four later trajectories produced a 75% pass rate against the original 18-test
suite. They exposed a shared assumption that handler origin could be represented
as an absolute hierarchy depth sampled around the handler call.

| Run | Original result | Hardened result | Newly exposed failure |
|---|---|---|---|
| Nova 1 | 18/18 pass | 18/20 | Recomputed a mutable superstate's depth after it returned. |
| Nova 2 | 17/18 | 18/20 | Lost the mutable superstate boundary; its original hook-order failure is outside the narrowed focused scope. |
| Nova 3 | 18/18 pass | 18/20 | Sampled leaf depth before a handler changed its hierarchy, so a leaf-origin external transition no longer matched legacy behavior. |
| Nova 4 | 18/18 pass | 18/20 | Recomputed a mutable superstate's depth after it returned. |

The reference solution passes all 20 tests because it records the number of
dispatch edges from the leaf to the accepting handler. The hardened replay is
therefore 0/4 without making the public contract implementation-specific.

## Second-round discriminator replay

Four fresh trajectories all passed the 20-test suite. Their implementations
split into two families: Nova 1 and 3 carried relative edge counts but searched
the target hierarchy by superstate discriminant, while Nova 2 and 4 recorded
absolute handler or boundary depths.

| Run | Initial result | Interim result | Newly exposed failure |
|---|---|---|---|
| Nova 1 | 20/20 pass | 20/24 | Collapsed repeated `Layer` occurrences and rediscovered a moved borrowed boundary. |
| Nova 2 | 20/20 pass | 22/24 | Kept an absolute boundary sampled before a borrowed handler inserted a hierarchy level. |
| Nova 3 | 20/20 pass | 20/24 | Collapsed repeated `Layer` occurrences and rediscovered a moved borrowed boundary. |
| Nova 4 | 20/20 pass | 22/24 | Kept an absolute handler depth sampled before a borrowed handler inserted a hierarchy level. |

The interim direct-trait machine varied two independent dimensions in both
engines. One hierarchy contains the same superstate enum variant at two
different dispatch offsets; another lets a GAT-borrowed accepting superstate
change the active leaf's ancestry before returning. The reference remains
24/24 and that second-round replay was 0/4.

## Third-round rebalancing replay

Five new trajectories all passed 22 of 24 tests and failed only the mirrored
borrowed in-subtree boundary case. The case was behaviorally defensible but
over-concentrated calibration on one representation edge, so it was replaced
with two narrower public observations.

| Run | Interim result | Final result | Final failure family |
|---|---|---|---|
| Nova 1 | 22/24 | 26/26 pass | None. |
| Nova 2 | 22/24 | 26/26 pass | None. |
| Nova 3 | 22/24 | 22/26 | Treats any matching superstate discriminant as inside the handler subtree and reuses stale source depth after mutation. |
| Nova 4 | 22/24 | 26/26 pass | None. |
| Orion | 22/24 | 24/26 | Reuses pre-handler source depth for an outside-subtree ordinary path. |

The rebalanced third-round suite therefore produced a 60% pass rate. Its
failures were split between static subtree classification and changed-source
path accounting instead of five copies of one borrowed-boundary assertion.

## Fourth-round hardening replay

Four new Nova trajectories produced a 75% pass rate against the 26-test suite.
The three passing implementations split again: Nova 1 and Nova 2 stored an
accepting superstate's pre-handler absolute depth, while Nova 4 retained a
leaf-relative distance. The added case leaves the accepting handler as the
leaf's immediate parent but inserts a new ancestor above it before the handler
returns.

| Run | Initial result | Hardened result | Hardened observation |
|---|---|---|---|
| Nova 1 | 26/26 pass | 25/27 | Retains too much hierarchy and fails to re-enter the accepting handler. |
| Nova 2 | 26/26 pass | 25/27 | Widens too far and exits/re-enters the newly inserted parent. |
| Nova 3 | 24/26 | 23/27 | Enters the inserted parent on the new path and still collapses the unrelated repeated variant. |
| Nova 4 | 26/26 pass | 27/27 pass | Its leaf-relative boundary continues to identify the accepting handler. |

The hardened replay is 1/4 passes, or 25%. The new pair is grounded directly
in the public rule that mutations during handling must not move the accepting
boundary, asserts only final state and action order, and preserves a legitimate
non-reference implementation. Its three failing patches produce distinct
under-widening, over-widening, and asymmetric-entry paths. A later review
removed the separate mode-module/prelude constructor assertion because those
locations are discoverable from the existing `Transition` exports; this
changed raw scores by one without changing the pass rate.

A later fairness review removed one blocking macro function whose `A`- and
`Root`-origin paths were already covered by the awaitable matrix and another
blocking `A`-origin case. Every compiling fourth-round and fifth-batch patch
passed that function. Current replay totals are therefore one lower, with all
pass/fail classifications unchanged.

## Fifth immutable batch: zero solves

The next platform batch used the shorter 149-word prompt and completed all ten
runs without a solve: six Nova runs followed by four Orion runs.

| Result family | Runs | Focused result | Failure |
|---|---:|---:|---|
| Near-pass | 6 | 25/27 | Only the blocking and awaitable copies of the accepting handler gaining an ancestor above itself. |
| Broader mutation miss | 3 | 23/27 | The same pair plus both leaf-origin depth-change cases. |
| Public carrier failure | 1 | Compile failure | Added a sixth public `Outcome` variant for dispatch metadata. |

All ten passed the baseline. The nine compiling patches implemented both
engines and almost every transition rule, but they converged on absolute
pre-handler depths or target-side ancestry rediscovery. Their own mutation
tests generally removed a parent or changed hierarchy below the boundary; they
did not add an ancestor above a still-accepting handler.

Deleting that final pair would make the six near-passes succeed, projecting
6/10 and violating the 40% difficulty ceiling. Relaxing its action path would
change the external-transition contract. The selected next iteration therefore
changes specification discoverability only: the existing mutation sentence now
explicitly includes ancestors above the accepting handler. Because the prompt
changed, none of the fifth-batch runs count toward the revised version and the
new batch starts at 0/10.

## Sixth immutable batch: repeated-identity convergence

The clarified version reached 0/6 before iteration: four Nova runs and two
Orion runs all passed the baseline and scored 22/26. Every patch passed the
ancestor-above, changed-source, local-storage, hooks, macro, and public-surface
checks. All six failed only four assertions representing two behaviors mirrored
across both engines:

- a repeated superstate variant within one hierarchy was collapsed to the
  nearest matching occurrence;
- the same variant in an unrelated target branch was treated as inside the
  accepting handler's subtree.

The implementations were materially different but shared the same target-side
variant search. The next iteration therefore states that handler boundaries are
hierarchy occurrences, retains one in-subtree repeated observation in blocking
and one cross-branch collision in awaitable, and adds an awaitable macro
same-leaf storage observation. Replaying the six unchanged patches yields
23/25 for each: the two positional checks still reject them, while the macro
storage check passes. This replay is diagnostic only because the prompt and
tests changed; the new version restarts at 0/10.

## Interpretation

Two of ten calibrators completed the full behavioral and regression suites with
the required five-variant public API. A third passed the original suite through
a shallow public-metadata carrier, which was recorded before the focused test
was strengthened. The remaining attempts failed or stopped in implementation,
not because local/external path behavior was unclear.

Recurring ambiguity was low for semantics and moderate for internal mechanism:
the contract deliberately does not prescribe how private handler origin is
transported. No calibrator reported contradictory action, hook, self-transition,
or outside-subtree requirements. The task therefore discriminates on
handler-origin propagation, blocking/awaitable parity, and Rust lifetime
engineering rather than prompt interpretation.

## Recorded failure families

- public or doc-hidden outcome metadata leakage, now rejected;
- GAT-backed superstate ownership and lifetime errors;
- unintended public trait/bound changes visible to trybuild;
- incomplete awaitable parity or exhaustive outcome handling;
- incorrect use of the known full-workspace formatting baseline;
- documentation omitted after behavior completion;
- clean-base compile failure from the two intentionally missing variants.

The public-metadata loophole was a fairness correction. The third-round
rebalancing removed a universally failing dynamic case and restored distinct
handler-origin, subtree, and mutation observations. The fourth-round evidence
then exposed a narrower absolute-depth convergence while preserving one valid
passing architecture. The fifth immutable batch showed that the shortened
prompt made that invariant insufficiently discoverable. The sixth batch then
showed a second concentration around superstate-variant identity. The current
level makes that positional rule explicit, removes exact cross-mode mirrors,
and adds an awaitable macro-storage boundary without changing transition
semantics.

Post-calibration editorial review removed redundant legacy-behavior,
dispatch-hook, API-stability, and build-configuration boilerplate from
`meta.md`. It also relaxed exact `Debug` punctuation to require only the
variant name and target representation. These changes reduce incidental
instructions without changing the local/external boundary discriminator.
Further review removed a duplicate local-hook sentence and an example already
generalized by the accepting-handler boundary rule.
The final documentation and explicit non-goal sentences were also removed as
non-functional guidance.
The remaining generic transition-action paragraph was removed in the final
review. Harness hardening added toolchain and nextest fallbacks, dynamic
initialization log baselines, and a standard helper crate. The new iteration
retains repeated-variant and changed-hierarchy coverage, including the stable
handler whose parent changes, while explicitly naming ancestor-above mutations
in the prompt.
