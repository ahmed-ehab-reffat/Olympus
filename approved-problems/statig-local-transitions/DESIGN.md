# Design - explicit local and external transition boundaries

Status: approved on 2026-07-23, implemented, and accepted on 2026-07-26. The
refreshed upstream and available local-similarity gates passed with the
previously accepted cross-repository risk. Final verification and archive
results are recorded in `SUMMARY.md` and `RUNS.md`.

## Decision summary

Statig will add `Outcome::LocalTransition(S)` and
`Outcome::ExternalTransition(S)` without redefining
`Outcome::Transition(S)`. Local transitions retain the deepest boundary shared
by the active and target leaf states, including a self-transition that replaces
the leaf value without running actions. External transitions also retain the
relative depth of the handler that accepted a deferred event. When the target
remains in that handler's subtree, the engine widens the path just enough to
exit and re-enter the handler.

Handler depth and transition classification remain crate-private. The public
`StateExt::handle` and `SuperstateExt::handle` signatures, transition-hook
signatures, generated macro syntax, and leaf values supplied to hooks do not
change. Blocking and awaitable `Inner` implementations use private dispatch
paths because the existing public handlers return only `Outcome`.

## Gate ledger

| ID | Gate | Result and design consequence |
|---|---|---|
| G1 | Pinned default head | `origin/main` still resolves to `3780eecdbcf4326051c38676d592c6c2b4a3bab5`, dated 2025-11-29. The source checkout remains clean, and a separate `solution` worktree now exists at the same commit. |
| G2 | Upstream task novelty | All 44 issues and 37 pull requests, including closed items, were searched across title and body. No transition-kind, handler-boundary, re-entry, or common-ancestor proposal was found. |
| G3 | Current upstream activity | Six issues and two pull requests are open. Issue #82 asks for examples of deep nesting, while PR #79 rearranges trait bounds; neither specifies transition-boundary semantics. |
| G4 | Code and history novelty | All fetched remote branches, tags, source, README, and commit messages contain only the existing shortest-path transition behavior. There is no `LocalTransition` or `ExternalTransition`, implementation, revert, or abandoned branch. |
| G5 | Releases and repository state | The repository is active, unarchived, MIT licensed, and has no GitHub releases. |
| G6 | Available submission similarity | Exact and conceptual searches across `problems/`, `archive/`, candidate records, instructions, templates, and patches found only this candidate's own planning records. No equivalent local submission is available. |
| G7 | Residual archive risk | Local/external is standard statechart vocabulary, so an unavailable private submission archive could still contain a structurally equivalent task. The user explicitly selected this candidate with that risk; wording changes would not cure an idea-level match. |
| G8 | Feasibility and scope | The compatibility-preserving probe changes 397 production lines across six core files (348 insertions, 49 deletions), passes the full workspace suite, and preserves both no-default-feature builds. |

The available gates said `proceed to design review`. The target platform's
private cross-repository submission archive was not available before challenge
tests were authored, so the user-approved residual risk in G7 remains rather
than being presented as a completed search. Rerun that check before submission
if the platform exposes it. An equivalent task whose central discriminator is
retaining the transition-producing handler boundary remains a stop condition.

## Repository evidence

| Area | Observed contract |
|---|---|
| `statig/src/outcome.rs` | `Outcome<S>` has `Handled`, `Super`, and `Transition(S)`, with manual variant-sensitive `PartialEq` and `Debug`. `Response<S>` is a deprecated alias. |
| `statig/src/lib.rs` and mode modules | The root exports `Outcome`; blocking, awaitable, and the prelude glob-export its variants. New variants naturally follow the same paths. |
| Blocking state/superstate extensions | Public `handle` methods own current dispatch-hook behavior and recursively defer through `Super`, but return no handler-origin metadata. |
| Awaitable state extension | Async deferral is an iterative loop because recursive async calls would require boxing. It also returns only `Outcome`. |
| Both `Inner` implementations | They currently receive an already-unwound outcome, select `Transition`, call hooks, compute a shortest path, exit, swap once, enter, and call the final hook. |
| Hierarchy helpers | Leaf and superstate identity use enum discriminants. Depth includes the current node. A common-ancestor depth of zero denotes implicit `Top`. |
| Macro crate | Generated handler implementations forward the user's `Outcome<State>` unchanged. No generated exhaustive match distinguishes outcome variants, so no parser, lowering, code-generation, or attribute change is needed. |
| README | Public documentation currently describes three outcomes and only the shortest-path transition. |

## Hierarchy and handler model

The behavioral hierarchy used for design and tests is:

```text
Top (implicit, depth 0)
└── Root (depth 1)
    ├── A (depth 2)
    │   ├── A1 (depth 3)
    │   │   ├── A11 (depth 4, initial leaf)
    │   │   └── A12 (depth 4)
    │   └── A2 (depth 3)
    │       └── A21 (depth 4)
    └── B (depth 2)
        └── B1 (depth 3)
```

For one event dispatch, `h` is the transition-producing handler's offset from
the active leaf:

- `h = 0` for the leaf handler;
- `h = 1` for its immediate superstate;
- each further `Super` increments `h`;
- the handler's absolute hierarchy depth is `H = Ds - h`, where `Ds` is the
  active leaf's depth.

The offset is determined by the dispatch path, not by recomputing an absolute
depth from a mutable handler after it returns. This keeps the accepting position
stable even when a direct trait implementation mutates data used by
`superstate()`. It also distinguishes two occurrences of the same superstate
enum variant at different offsets; a discriminant identifies a state kind, not
the accepting occurrence.

Dispatch construction guarantees `0 <= h < Ds`. The implementation will use
checked subtraction when deriving `H`; the root handler has `H = 1`, and its
parent is implicit `Top` at depth zero.

State-local fields never participate in identity. Two values of the same leaf
variant have common depth `Ds`, even if their stored fields differ.

## Transition path equations

Let:

- `Ds` be the active leaf depth;
- `Dt` be the target leaf depth;
- `c` be their deepest common-ancestor depth, with the same leaf discriminant
  producing `c = Ds`;
- `r` be the retained boundary depth;
- `x = Ds - r` be the number of exit actions;
- `e = Dt - r` be the number of entry actions.

The three public outcomes select `r` as follows.

### Legacy transition

```text
r = Ds - 1    when source and target have the same leaf discriminant
r = c         otherwise
```

This is the existing `transition_path()` behavior. Handler depth is ignored.
A legacy leaf self-transition therefore remains `(x, e) = (1, 1)`.

### Local transition

```text
r = c
```

Distinct leaves use the current shortest path. For the same leaf discriminant,
`r = Ds`, so `(x, e) = (0, 0)`. The transition transaction still swaps in the
target value and invokes both transition hooks once.

### External transition

```text
H = Ds - h
P = H - 1
r = min(c, P)
```

`P` is the handler's parent boundary. If `c >= H`, the target is at or below
the handler, so retaining only `P` forces that handler to exit and re-enter. If
`c < H`, the target is already outside the handler subtree, and `min(c, P) = c`
keeps the ordinary path. For a leaf handler, `P = Ds - 1`, which exactly
matches legacy behavior. For `Root`, `P = 0`, so an external transition to a
descendant exits and re-enters the complete active hierarchy.

All arithmetic stays in leaf-inclusive absolute depths. The root case uses a
zero parent boundary and never decrements an unchecked zero.

## Normative examples

With `A11` active:

| Outcome-producing handler and target | Exit path | Entry path | Retained boundary |
|---|---|---|---|
| Local from `A1` to `A12` | `A11` | `A12` | `A1` |
| External from `A1` to `A12` | `A11`, `A1` | `A1`, `A12` | `A` |
| External from `A` to `A12` | `A11`, `A1`, `A` | `A`, `A1`, `A12` | `Root` |
| External from `Root` to `A12` | `A11`, `A1`, `A`, `Root` | `Root`, `A`, `A1`, `A12` | `Top` |
| Local from `A` to `A12` | `A11` | `A12` | `A1`, despite the shallower handler |
| External from `A1` to `B1` | `A11`, `A1`, `A` | `B`, `B1` | `Root`; no extra widening |

A local self-transition to `A11 { value: new }` runs no entry or exit action
but installs `new`. External and legacy leaf self-transitions run the `A11`
exit on the old value, install the target, and run the `A11` entry on the new
value.

## Internal dispatch design

The core will have a crate-private transition classification and a
crate-private dispatch result containing:

```text
Outcome<State>
handler depth relative to the active leaf
```

Names and exact placement are implementation details. No origin field, path
type, or transition kind becomes public.

### Blocking engine

`Inner::handle_with_context` will use a private dispatch path rather than the
public `StateExt::handle`:

1. Run the leaf's before-dispatch hook, call its handler, then run its
   after-dispatch hook.
2. On `Super`, borrow the immediate superstate and recurse through a private
   helper.
3. A transition returned at the current handler starts with relative depth
   zero; each unwound `Super` edge increments it.
4. Keep the existing outer before/after hook wrapping around recursive
   superstate dispatch.
5. Return the outcome and final handler depth to `Inner`, which selects the
   path equations above.

The public blocking `StateExt::handle` and `SuperstateExt::handle` remain
available with their exact signatures. Their exhaustive matches will propagate
either new transition variant unchanged, but they do not expose origin.

### Awaitable engine

`Inner::handle_with_context` will likewise call a private async dispatch path:

1. Dispatch the leaf with its current hook pair.
2. On `Super`, iterate through borrowed superstates without recursion or boxed
   futures.
3. Initialize the relative depth to one for the immediate superstate and
   increment it before moving to each parent.
4. Return as soon as a handler produces a non-`Super` outcome.

The public async `StateExt::handle` retains its current
`impl Future<Output = Outcome<Self>>` signature and iterative control flow. Its
two exhaustive matches will propagate both new variants.

### Transition transaction

Both engines keep the same transaction:

1. Call `before_transition` once with the old active leaf and target.
2. Compute `(x, e)` for the selected kind.
3. Run `x` exit actions leaf-up on the old value.
4. Swap the active and target leaf exactly once.
5. Run `e` entry actions boundary-down on the new value.
6. Call `after_transition` once with the old leaf and new active leaf.

The transaction is not skipped for `(0, 0)`. This preserves hook calls and
installs local storage for a local self-transition. No allocation, `std`
dependency, unsafe origin identity, or public callback argument is introduced.

## Hook-order contract

Transition hooks have the same ordering in both modes:

```text
before_transition(old leaf, target)
old-value exit actions, leaf upward
single leaf swap
new-value entry actions, ancestor downward
after_transition(old leaf, new leaf)
```

Dispatch hooks retain each engine's existing order.

For a blocking event handled by `A` after deferral from `A11` through `A1`:

```text
before A11, after A11,
before A1, before A, after A, after A1
```

For the same awaitable dispatch:

```text
before A11, after A11,
before A1, after A1,
before A, after A
```

Origin tracking must not add, remove, or reorder these calls. `Handled` and a
`Super` that reaches implicit `Top` cause no state replacement, entry/exit
action, or transition hook.

## Public compatibility ledger

| Surface | Required result |
|---|---|
| `Outcome<S>` | Add public `LocalTransition(S)` and `ExternalTransition(S)`, yielding exactly five public variants. The unavoidable enum-extension effect is that downstream exhaustive matches must add arms; handler origin must not appear as a sixth public or doc-hidden variant. |
| Equality | Equal only when both the variant and target are equal. Different transition variants are unequal even with equal targets. |
| Debug | Include the `LocalTransition` or `ExternalTransition` variant name and the target's own `Debug` representation without prescribing punctuation. |
| `Response<S>` | Remain an alias for `Outcome<S>` and support all five variants. |
| Legacy behavior | Preserve shortest paths, leaf self exit/re-entry, state-local action timing, hooks, and final values exactly. |
| Direct traits | Keep every existing `State`, `Superstate`, `StateExt`, and `SuperstateExt` method signature. |
| Macro | Require no new attribute or syntax; handlers simply return either new public variant. |
| Hooks | Keep hook signatures and the old/new leaf values they receive. Handler origin remains internal. |
| Features | Preserve blocking default use, `--no-default-features`, independent `async`, macro, serde, Bevy, and `#![no_std]` compilation. |

No serialization format changes: `Outcome` itself is not serialized, and state
machine serialization continues to contain only shared storage and the active
leaf.

## Documentation design

README's state-outcome list will describe all five outcomes. A short transition
section will use a nested parent with two child leaves:

- legacy `Transition` keeps current shortest-path behavior;
- `LocalTransition` keeps the deepest shared active/target boundary;
- `ExternalTransition` re-enters the superstate handler when the target remains
  in its subtree;
- a local leaf self-transition replaces state-local storage without actions,
  while legacy and external leaf self-transitions exit and re-enter.

The docs will not present handler depth or path equations as public API.

## Trajectory-informed design gate

The completed search covered `problems/README.md`,
`candidates/CANDIDATES.md`, this problem's `SUMMARY.md`, `LEVELS.md`, and
`ERRORS.md`, and all four local `agent-runs*` directories. Raw fourth-round
trajectories, evaluator results, and solution patches were inspected for a
legitimate pass (Nova 4), the near-pass (Nova 3), and the two other initially
passing representations (Nova 1 and Nova 2).

The comparable-problem search used the terms `state`, `transition`, `dispatch`,
`origin`, `boundary`, `provenance`, `atomic`, `rollback`, and `staged` across
the problem index, candidate registry, and compact problem records. It read the
relevant `DESIGN.md`, `SUMMARY.md`, `LEVELS.md`, `ERRORS.md`, and `RUNS.md`
records for 3D Tiles and moov ACH, plus the str0m design that independently
identifies those archives as the closest stored evidence for mutation coupled
to later commit. The archive manifests were read, members were listed with
`tar -tf`, and archived `trajectory.json`, `solution-patch.patch`,
`eval-result.json`, and `run.txt` members were inspected with `tar -xOf`.
The corresponding Statig files were read directly from `agent-runs4/`.

| Evidence role | Problem / run / archive member | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Direct legitimate pass | Statig fourth round, `agent-runs4/Nova_Nova_4` | 26/26 focused and 23/23 baseline in its recorded evaluation; 26/26 under the current replay | Changed `outcome.rs` and the blocking/awaitable `state.rs`, `superstate.rs`, and `inner.rs` seams. It carried the accepting handler as a leaf-relative number of dispatch edges and selected the path only after dispatch returned. Handler mutations could change the current hierarchy without moving that captured dispatch position. The solver added blocking macro and direct awaitable checks, then ran focused, feature, and formatting validation. |
| Direct near-pass | Statig fourth round, `agent-runs4/Nova_Nova_3` | 24/26 in its recorded evaluation; 22/26 under the current replay | Changed the same public and mode-engine seams, kept a private `DispatchOutcome`, and preserved both modes, but represented the accepting handler with a superstate discriminant plus an absolute depth and searched target ancestry for that variant. A repeated variant on an unrelated branch was mistaken for the accepting occurrence. Its own outside-subtree test used distinct variants and therefore did not challenge the shortcut. |
| Direct broad failure | Statig stored runs | Unavailable | No raw Statig run broadly failed the transition behavior. Older compile, regression, and timebox failures are summarized in `LEVELS.md`, but they are not substituted for a raw broad trajectory. |
| Analogical legitimate pass | 3D Tiles Nova 3, `agent-runs/Nova_Nova_3` in `archive/3d-tiles-atomic-output/agent-runs.tar.gz` | 30/30 focused and 869/869 baseline | Introduced a private pipeline publisher, staged every final output away from the destination, waited for target finalization, and then committed with backup, rollback, parent-ownership, and cleanup handling. It preserved the existing `PipelineError` boundary and proactively exercised directory, JSON, and package paths before the full suite. |
| Analogical near-pass | 3D Tiles Nova 2, `agent-runs/Nova_Nova_2` in the same archive | 26/30 focused; 869/869 baseline | Reached the same sound stage-then-publish architecture and validated real storage forms, but collision paths threw plain `Error` instead of the repository's public `PipelineError`. Correct core state behavior did not preserve the adjacent public failure surface. |
| Analogical broad failure | moov ACH run 12, `actual_trajectories/run_nova_12` in `archive/moov-ach/actual_trajectories.tar.gz` | 100/120 focused; 1534/1534 baseline | Implemented the operation in one large `correction.go`, built a call-start target index, and applied corrections in order, but tentative offset work mutated coupled entries and refusal restored only the primary target. Later notifications observed contaminated derived state; Refused and Undo metadata also came from the wrong boundary. Its added tests and full repository run passed because they did not span those coupled cases. |

The Statig runs remain the primary evidence. The 3D Tiles and moov runs are
analogical only: they do not define statechart semantics. They reinforce three
repository-grounded constraints already present here. Provenance must survive
mutable work instead of being reconstructed from post-handler state; private
coordination data must cross the complete operation without becoming public;
and a correct new state path must still preserve neighboring public contracts.
The analogous runs therefore strengthen existing compatibility and mutable
boundary discriminators rather than adding unrelated rollback requirements.

All four fourth-round Statig implementations changed the public outcome and
both engines, retained private dispatch metadata, and validated feature
combinations before handoff. Nova 4 carried a leaf-relative distance to the
accepting handler. Nova 1 and Nova 2 represented that position with an absolute
pre-handler depth. Nova 3 searched target ancestry by superstate discriminant.
The final discriminator set targets the recurring shortcuts while preserving
Nova 4's legitimate alternative.

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Statig Nova 1 and Nova 2 snapshot an accepting superstate's absolute hierarchy depth; moov run 12 likewise treated mutable derived offsets as stable after restoring only the obvious target. | Use a root-relative coordinate derived from mutable state as provenance, then repair only the most visible value when that state changes. | Mutations during handling must not move the accepting handler boundary, while the ordinary path must use the hierarchy that exists when the transition executes. | Keep the accepting handler as the leaf's immediate parent, add an ancestor above it during handling, and require the new ancestor to remain retained while the handler and leaf exit and re-enter. | Handler-origin capture across mutable hierarchy | The assertion names no metadata representation and accepts relative offsets, stable occurrence identities, captured paths, or any other implementation producing the same public actions. |
| Statig Nova 3 searches for a matching superstate variant anywhere in target ancestry. | Treat a discriminant as a unique occurrence rather than a state kind that may appear at several depths or branches. | A target outside the accepting handler's subtree keeps the ordinary common-ancestor path. | Put the same variant at another target-branch depth and assert the complete ordinary path. | Subtree membership with repeated representations | Repetition is valid in direct trait implementations; the test observes only final state and action order and does not require the reference search strategy. |
| An early Statig run exposed origin through an extra public outcome; 3D Tiles Nova 2 preserved the transaction but changed the public error class. | Complete the new behavior by widening or weakening an adjacent public carrier. | `Outcome` has exactly the five documented variants, `Response` remains an alias, existing handler signatures remain unchanged, and legacy behavior is preserved. | Exhaustively match the five variants, compile direct public-handler calls at their existing types, and compare legacy action/hook snapshots. | Public API and compatibility surface | Any crate-private carrier and any internal dispatch architecture pass; only externally visible contract changes fail. |
| Earlier Statig runs stopped after one engine or did not finish awaitable parity. | Treat structurally different execution modes as optional copies of the primary implementation. | Blocking and awaitable machines implement the same transition choices and mutable-boundary behavior. | Mirror the decisive self-storage, outside-subtree, and changed-hierarchy observations in both modes. | Blocking/awaitable engine parity | The modes have different recursive/iterative dispatch shapes, so parity is checked through public states and logs rather than shared private helpers. |

After removing a mode-module/prelude constructor assertion not stated in the
brief and one duplicate blocking macro function, the reference passes all 26
focused tests. Replaying the four fourth-round patches unchanged yields 24/26,
24/26, 22/26, and 26/26
respectively. The three failures under-widen, over-widen, and asymmetrically
enter the changed hierarchy; the fourth implementation remains a legitimate
alternate pass. This 25% result hardens the suite without reintroducing the
earlier universally failing below-handler mutation.

### Fifth-batch zero-solve redesign gate

The next immutable calibration batch completed 0/10 against the 27-test suite:
six patches scored 25/27 and failed only the blocking/awaitable copies of the
ancestor-above-handler case, three scored 23/27 and also lost the leaf-origin
boundary after a depth change, and one exposed dispatch metadata through a
sixth public `Outcome` variant and failed compilation. All ten preserved the
baseline.

Raw evidence was inspected for the existing legitimate pass
(`agent-runs4/Nova_Nova_4`), a latest near-pass
(`agent-runs6/Orion_Nova_1`), and the batch's integration failure
(`agent-runs5/Nova_Nova_1`). The pass recognized late in its trajectory that a
mutable absolute depth was unsafe and changed to a leaf-relative dispatch
distance. The near-pass explicitly intended to snapshot a mutation-stable
boundary but still combined an absolute depth with target-side discriminant
rediscovery. The integration failure implemented the behavior behind an extra
public enum variant. None was blocked by the environment or by broad semantic
ambiguity.

| Candidate easing | Historical projection | Decision |
|---|---:|---|
| Delete the ancestor-above-handler pair | Six of the ten failed patches become 25/25 passes, projecting 60% and missing the difficulty band. | Reject; too much easing. |
| Accept leaf-only, added-parent, or asymmetric paths | Converts incorrect external boundaries into valid behavior and contradicts the handler-source contract. | Reject; changes semantics. |
| Prescribe a relative offset | Would reveal the reference mechanism and reject other valid private representations. | Reject; implementation-specific. |
| Clarify that mutations include changes to ancestors above the accepting handler | Leaves every oracle and implementation choice intact while directing solvers to the only requirement missed by nine compiling patches. | Select as the minimum discoverability adjustment. |

The selected iteration changes only one public sentence. The focused suite,
reference solution, and mutation set remain unchanged. Because the prompt
changes, the failed 0/10 batch is historical evidence only; all checks and a
new calibration batch restart from zero. The artifact audit, all four pristine
patch-state gates, both feature-only compile checks, and all twelve mutation
checks passed after the clarification.

### Fairness-review duplication adjustment

A subsequent fairness review marked the blocking macro test that bundled
`A`-origin local, `A`-origin external, and `Root`-origin external paths as
unfair, but supplied only placeholder evidence. Each assertion follows the
public handler-source rule; nevertheless, the function adds no unique
discriminator. The awaitable macro matrix covers the same `A` and `Root`
boundaries, and another blocking macro case already contrasts local and
external transitions accepted by `A`.

The bundled blocking function is therefore removed as duplicate coverage, not
because its expected paths are invalid. Every compiling patch in the completed
0/10 batch already passed it, so removing it converts no failed solution into a
pass and does not undo the prompt-only easing decision. The focused suite
becomes 26 tests; behavior, reference code, and the hard mutation discriminator
remain unchanged.

### Current 0/6 repeated-identity redesign gate

The next immutable version reached 0/6: four Nova runs and two Orion runs all
preserved the baseline, scored 22/26, and failed only the blocking and
awaitable copies of two repeated-superstate observations. Every implementation
transported private accepting-handler metadata and passed the ancestor-above,
changed-source, leaf-origin, local-storage, macro, hook, and public-API checks.
Each then rediscovered target membership by comparing superstate variants,
which collapsed distinct hierarchy occurrences.

The required raw-evidence sample was refreshed before revising tests. The
legitimate pass remains `agent-runs4/Nova_Nova_4`, whose leaf-relative dispatch
position passes the current 26-test suite unchanged. The current near-pass is
`agent-runs7/Orion_Nova_2`; it independently built private dispatch metadata in
both engines but stored only a superstate discriminant for target-side
membership. The available broad failure remains
`agent-runs5/Nova_Nova_1`, which exposed dispatch metadata through a sixth
public `Outcome` variant and failed focused-suite compilation. Their raw
trajectories, patches, evaluator summaries, validation commands, and handoff
timing were inspected. No environment issue caused the semantic failures.

The six-run convergence shows that four assertions now represent one dominant
shortcut rather than four independent discriminators. The next version keeps
the behavior but distributes observations across different implementation
boundaries:

| Observed convergence | Generalized shortcut | Fair public invariant | Black-box oracle | Diversification decision |
|---|---|---|---|---|
| All six current patches matched a target ancestor by superstate variant. | Treat a state kind as a unique handler occurrence. | The accepting handler is a hierarchy position; another occurrence of the same variant does not establish subtree membership. | Keep one in-subtree repeated-occurrence observation and one outside-subtree collision observation. | State the positional rule behaviorally and split the two observations across blocking and awaitable modes instead of mirroring both in both modes. |
| Current patches passed direct local storage but calibration feedback identified no macro storage observation. | Implement the engine transaction correctly while missing integration through generated state-local variants or the structurally different async engine. | A same-leaf local transition installs the target value without actions regardless of whether the handler was generated. | An awaitable macro-generated state replaces its local field and records no entry or exit action. | Add one awaitable macro oracle rather than another blocking/awaitable mirror. |
| Calibration feedback suggested direct awaitable `SuperstateExt::handle` coverage. Repository inspection shows that only blocking `SuperstateExt` defines `handle`; the awaitable extension exposes hierarchy helpers but no dispatch helper. | Turn a symmetry assumption into a requirement for an API that does not exist. | New variants must preserve existing public surfaces, not create a blocking/awaitable API symmetry absent from the base repository. | Compile against the actual extension traits and retain the existing blocking superstate and awaitable state helper checks. | Reject the suggested awaitable superstate oracle as invalid; add no new public method requirement. |
| The mutation, handler-origin, and outside-path cases already fail different historical architectures. | Overfit the redesign entirely to repeated variants. | Handler position remains stable across mutation while ordinary paths use current source hierarchy. | Retain the existing ancestor-above, changed-source, leaf-origin, and cross-subtree observations. | Keep these tests unchanged; they remain separate failure families. |

This is a coverage rebalance, not a semantic relaxation. Two exact
blocking/awaitable mirrors are removed, while an awaitable macro-storage
boundary is added. The public description gains one behavioral sentence about
hierarchy occurrence and does not prescribe depth, offsets, discriminants, or
a private carrier. Any prompt or test change creates a new immutable problem
version, so the abandoned 0/6 results remain evidence only and calibration
restarts at 0/10 after all gates pass.

The implemented rebalance contains 25 focused tests. The unchanged reference
passes 25/25. Replaying each of the six current-batch patches produces 23/25:
both positional observations reject the variant-search shortcut, and the new
awaitable macro-storage observation passes. The artifact audit, four pristine
offline patch-state gates, both feature-only checks, and all twelve mutations
pass. Docker again exhibited its recorded client transport stall without
creating containers, so the four equivalent local-clone gates are the final
patch-state evidence for this iteration.

## Shallow implementations ruled out

| Incorrect approach | Decisive public observation |
|---|---|
| Treat both new variants as legacy | Local self actions are wrong; external transitions from `A1`, `A`, and `Root` retain too much hierarchy. |
| Make all same-variant transitions action-free | Legacy and external self-transition logs change. |
| Return early for local self | New state-local storage is not installed and transition hooks are absent. |
| Compare complete leaf values | Different local fields incorrectly turn a local self-transition into exit/re-entry. |
| Track only whether a superstate handled | External transitions from `A1`, `A`, and `Root` choose the same boundary. |
| Hard-code origin depth one | `A` and `Root` fail to exit/re-enter their own boundaries. |
| Always widen external paths to the handler parent | A transition to `B1` exits an unrelated retained ancestor or underflows/re-enters too much. |
| Compute external paths only from the leaf | A superstate-emitted external transition becomes legacy. |
| Change only blocking or awaitable | The counterpart hierarchy and self-storage suite fails. |
| Modify public `handle` to return metadata | Existing direct-trait code no longer type-checks. |
| Add a doc-hidden public outcome carrying origin | An exhaustive downstream match over the documented five variants no longer compiles. |
| Add macro syntax | Direct and macro APIs diverge despite both already returning `Outcome<State>`. |
| Search the target hierarchy for any matching superstate discriminant | The same variant at a different depth in an unrelated branch is incorrectly classified as inside the handler subtree. |
| Reuse the pre-handler active depth after hierarchy mutation | An outside-subtree transition omits an added source ancestor from its ordinary common-ancestor path. |
| Anchor the accepting handler only by its pre-handler absolute root depth | Adding an ancestor above the still-immediate accepting handler either re-enters that ancestor or fails to re-enter the handler. |

## Clause-to-test ledger

Test IDs group the implemented external behavior tests.

| Clause | Maintainer-facing contract | Planned tests |
|---|---|---|
| C1 | Both variants are public members of `Outcome`, variant-sensitive in `PartialEq`/`Eq`, accurately formatted by `Debug`, and usable through `Response`. | T1 |
| C2 | Legacy sibling, cross-branch, and self-transition action/hook behavior is unchanged. | T2, T6, T8, T10 |
| C3 | Local transitions retain the deepest active/target common boundary regardless of the handler that produced them. | T2, T3, T9 |
| C4 | A local leaf self-transition replaces local storage with no actions and exactly one before/after transition-hook pair. | T6, T9, T10 |
| C5 | An external transition to a target in the handler subtree exits and re-enters that handler, with the boundary moving for `A1`, `A`, and `Root`. | T2, T3, T9 |
| C6 | An external transition outside the handler subtree uses the ordinary common ancestor and does not exit unrelated ancestors twice. | T4, T9 |
| C7 | External leaf self-transition matches legacy self-transition and observes old storage on exit and new storage on entry. | T6, T10 |
| C8 | Handler-origin behavior remains stable when handling changes hierarchy below or above the accepting handler, and repeated occurrences of one superstate variant do not turn an outside target into a descendant. | T5 |
| C9 | Macro-generated and direct-trait machines support the same semantics in blocking and awaitable modes without public signature changes. | T2-T10 |
| C10 | Core functionality builds with no defaults and with async independently of macros; the full feature workspace remains healthy. | T7, T10, T11 |
| C11 | README explains the three transition choices, nested behavior, and self-transition storage distinction. | T11 |

## Test-to-clause ledger

Challenge tests live under `grader_tests/` in a standalone test crate, use
neutral randomized filenames, and assert only public outcomes, states, local
values, hooks, and action logs.

| Test | Scenario and public assertions | Clauses |
|---|---|---|
| T1 | Construct all variants through `Outcome`; exhaustively match exactly five public variants; require `Outcome<T>: Eq`; compare same and cross variants; check that debug output contains the variant name and target representation; construct both new variants through deprecated `Response`. | C1 |
| T2 | Blocking macro machine: local and external `A1 -> A12`, plus legacy sibling baseline; assert exact action and transition-hook logs and final leaf. | C2, C3, C5, C9 |
| T3 | Blocking macro machine: local and external transitions produced by `A` target a different descendant branch; assert that local retains `A` while external exits and re-enters it. | C3, C5, C9 |
| T4 | Blocking macro machine: local and external transitions from inside `A` to `B1`; assert `Root` is retained and exact leaf-up/root-down order. | C6, C9 |
| T5 | Direct blocking and awaitable hierarchies mutate borrowed data used by `superstate()` before an outside transition and add an ancestor above a stable immediate-parent handler. A blocking hierarchy repeats one variant within a branch; an awaitable hierarchy places that variant at another depth in an unrelated target branch. Assert ordinary paths and accepting boundaries through action order. | C5, C6, C8, C9 |
| T6 | Direct blocking traits with state-local old/new values: local, external, and legacy self-transitions plus a legacy sibling; assert action values, hook arguments/counts, and installed target. | C2, C4, C7, C9 |
| T7 | Direct blocking checks for the existing `StateExt::handle` and `SuperstateExt::handle` return types under no default features; assert both new variants propagate unchanged across leaf and deferred handlers. | C9, C10 |
| T8 | Byte-for-byte expected legacy action/hook snapshots for macro and direct blocking machines. | C2, C9 |
| T9 | Awaitable macro hierarchies exercise `A1`, `A`, `Root`, and outside-subtree boundaries plus a generated same-leaf local transition that installs new state-local storage without actions. | C3, C4, C5, C6, C9 |
| T10 | Direct awaitable traits repeat local/external/legacy self-storage and legacy sibling cases; compile existing async `StateExt::handle`, assert new-variant propagation, and assert exact async hooks. | C2, C4, C7, C9, C10 |
| T11 | Offline build matrix runs upstream all-features tests, blocking direct tests with no defaults, async direct tests with only `async`, changed-file formatting, and doctests including README. | C10, C11 |

The suite will not assert an internal record name, handler-depth integer, helper
location, transition-kind type, arithmetic function, recursion strategy, or
call stack.

## Mutation obligations

Every compiling semantic mutation below has at least two independent behavioral
assertions expected to reject it.

| Mutation | Independent failures |
|---|---|
| Map both new variants to legacy | T6/T10 local-self action logs; T2/T3/T9 external handler boundaries |
| Force local self path to `(1, 1)` | T6 action absence and installed value; T10 action absence and hook log |
| Skip the swap for local self | T6 final local value and after-hook target; T10 final value and hook arguments |
| Skip hooks for `(0, 0)` | T6 before/after counts and ordered hook log; T10 corresponding async assertions |
| Treat every external transition as leaf-originated | T2 `A1` log; T3 `A` and `Root` logs; T9 async counterparts |
| Hard-code handler depth to one | T3 `A` boundary and `Root` full re-entry; T9 async counterparts |
| Widen external transitions even outside the handler subtree | T4 retained `Root` and exact action count/order; T9 async outside case |
| Update blocking only | T9 hierarchy boundaries and T10 self-storage semantics |
| Update awaitable only | T2/T3 hierarchy boundaries and T6 self-storage semantics |
| Omit new `Debug` arms | T1 independently checks inclusion of both variant names and target representations |
| Make equality target-only | T1 checks local-vs-legacy and external-vs-legacy inequality plus unequal targets |
| Break legacy self behavior | T6/T10 old/new action values; T8 macro/direct snapshots |
| Change a public `handle` signature to expose origin | T7 direct blocking type checks and T10 direct awaitable type checks fail to compile |
| Add a public or doc-hidden outcome variant carrying origin | T1's exhaustive five-variant match fails to compile |

Compile failure is accepted only for deliberate public-surface mutations such
as missing variants or changed signatures. It is not a substitute for the
semantic assertions above.

## Harness and formatting baseline

The later Docker image will pin Rust 1.90.0, resolve the `unit-enum` git
development dependency during its networked build, and run both grader modes
offline with networking disabled. `test.sh` will support `base` and `new`, both
accepted `--output_path` forms, non-fail-fast execution, stale-report removal,
well-formed JUnit on build or collection failure, and nonzero failure status.

The refreshed `cargo +1.90.0 fmt --all -- --check` baseline reports formatting
diffs in three pinned files:

- `examples/macro/blinky/src/main.rs`;
- `examples/macro/calculator/src/state.rs`;
- `statig/src/blocking/superstate.rs`.

The first two are unrelated examples and will not be edited. The third is an
intended production touch because its exhaustive outcome match must change; the
solution will format that file. Every changed Rust file must pass Rust 1.90
formatting, and the full solution formatter diff must contain no new file
beyond the two untouched example baselines.

## Prototype and size boundary

The corrected disposable probe:

- preserves all existing public trait method signatures;
- changes six production files by 348 insertions and 49 deletions;
- passes `cargo +1.90.0 test --workspace --all-features`, including five probe
  boundary tests, 11 macro tests, and 22 doctests;
- passes `cargo +1.90.0 check -p statig --no-default-features`;
- passes
  `cargo +1.90.0 check -p statig --no-default-features --features async`.

The final design improves encapsulation over the scratch probe: origin-aware
path selection belongs in private `Inner` helpers rather than new public
extension-trait methods. The honest expected production diff remains 340-430
changed lines across `outcome.rs`, both `inner.rs` files, both public dispatch
extension files, and blocking `superstate.rs`; README changes are additional.
Implementation stops for review below 300 or above 475 changed production
lines, or if private origin propagation proves impossible without changing an
existing public signature.

## Approval gate

The user approved this design on 2026-07-23. That approval authorized the
behavior-only challenge tests, offline harness, and compatibility-preserving
reference implementation described above.
