# False-positive trials

Status: complete and applied. Five additional mode-specific false positives
were added to the four previously approved probes; one artificial survivor was
intentionally ignored.

This audit uses the proposed 37-test matrix as its baseline: the validated
33-test artifact plus the four independently reproduced local-transition probes
described in `adjustment.md`. Known gaps are not counted again.

## Method

1. Map each participant-facing rule to its strongest existing behavioral test.
2. Construct plausible implementations that violate one uncovered edge while
   preserving the rest of the design.
3. Require a candidate false positive to compile and pass all 37 focused tests.
4. Run meaningful survivors through the complete pre-existing workspace suite.
5. Prototype a public-behavior probe against the reference and the survivor.
6. Replay all six run-8 patches to detect a new shared failure family.
7. Recommend a patch only when the behavior is explicit, the mutation is
   plausible, and the probe adds a distinct discriminator.

## Result

Three remaining coverage families produced five actionable false positives:

1. Blocking and awaitable leaf-origin local transitions can return `(1, 1)` for
   every distinct target. That is correct for the existing rootless probe but
   wrong for a hierarchical cross-branch target.
2. Blocking and awaitable distinct local transitions accepted by the topmost
   superstate can be treated as external. Existing topmost local coverage is
   self-transition-only, so the incorrect root exit and re-entry is unseen.
3. The awaitable engine can assume every distinct local path has balanced exit
   and entry counts. Blocking `LocalB` already rejects this, but the awaitable
   fixture has only `ExternalB`.

All five mutations pass the proposed 37/37 suite. The combined local-origin
implementation also passes all 23 workspace tests and 22 doctests. The
awaitable balanced-path mutation independently passes the complete base suite.

## Actionable trials

### FP-1: direct-leaf local cross-branch shortcut

Mutation:

- when a distinct local outcome comes directly from the leaf, return one exit
  and one entry without calculating the hierarchy path;
- apply it to only blocking or only awaitable.

Why it is plausible:

The exact shortcut previously survived for leaf-origin external transitions.
The local branch has the same tempting special case, and every existing
leaf-origin distinct local target is rootless, where `(1, 1)` is correct.

Probe:

- hierarchy: `LeftLeaf -> Left -> Root` and
  `RightLeaf -> Right -> Root`;
- the active leaf directly returns `LocalTransition(RightLeaf)`;
- require `exit left leaf`, `exit left`, `enter right`,
  `enter right leaf`.

Results:

- reference: both probes pass;
- blocking mutation: fails only the blocking probe;
- awaitable mutation: fails only the awaitable probe.

Recommendation: add both probes.

### FP-2: topmost distinct local transition treated as external

Mutation:

- preserve the existing zero-action local-self case;
- for a distinct local outcome accepted by the topmost explicit superstate,
  use a full external path and re-enter the root;
- apply it to only blocking or only awaitable.

Why it is plausible:

Top-boundary arithmetic is already the hardest part of external routing. An
implementation can correctly special-case local self-transitions but reuse the
external top-boundary clamp for distinct targets. Current local tests exercise
leaf, immediate-parent, and deeper handlers, but not a distinct target accepted
by the topmost handler.

Probe:

- reuse the two-branch hierarchy from FP-1;
- defer from `LeftLeaf` through `Left` to `Root`;
- `Root` returns `LocalTransition(RightLeaf)`;
- require the same ordinary path as FP-1, with no root exit or entry.

Results:

- reference: both probes pass;
- blocking mutation: fails only the blocking root-accepted probe;
- awaitable mutation: fails only the awaitable root-accepted probe.

Recommendation: add both probes.

### FP-3: awaitable local paths assumed to be balanced

Mutation:

- compute the ordinary awaitable local path;
- keep it only when exit and entry counts are equal;
- otherwise collapse it to `(1, 1)`.

Why it is plausible:

All awaitable distinct-local cases have equal source and target depth. Blocking
already has `LocalB`, whose source path is one level deeper than its target
path, but the awaitable mirror is absent.

Probe:

- add `LocalB` to the existing awaitable `q7m2` fixture;
- return `LocalTransition(B1)` from `A`;
- require `exit A11`, `exit A1`, `exit A`, `enter B`, `enter B1`.

Results:

- blocking version of the mutation is already caught by the existing
  blocking `LocalB` assertion;
- reference with the awaitable mirror: 42/42;
- awaitable mutation: 41/42, failing only the new mirror.

Recommendation: add the one missing awaitable test.

## Combined prototype

The proposed 37 tests plus the five actionable probes form a 42-test prototype.

- Reference: 42/42.
- Each FP-1 and FP-2 mutation is caught by exactly one corresponding test.
- FP-3 is caught only by the new awaitable `LocalB` test.
- All six run-8 patches pass all five probes and score 40/42.
- Every run-8 failure remains one of the two parent-insertion cases.

The additions therefore close distinct false positives without changing the
known solver bottleneck.

## Negative and rejected trials

### Already covered: topmost external handler retention

A blocking mutation retained the topmost explicit superstate instead of exiting
and re-entering it. It failed the existing
`deferred_self_transition_uses_parent_boundary_only_when_external` test.

The awaitable equivalent failed that test's awaitable mirror and the existing
root-handler boundary assertion. The audit's topmost external observation is
therefore already pinned; no test should be added.

### Ignore: one-direction-only hierarchy change

An intentionally asymmetric local-self mutation ran no actions only when the
target depth was greater than or equal to the source depth. It passes the
proposed 37 tests because the new hierarchy-change probe inserts a parent but
does not remove one.

This survivor should not drive another test:

- the prompt's same-variant rule is categorical;
- the natural mistaken implementation checks equal depths and is already
  rejected by the parent-insertion probe;
- choosing one inequality direction is an arbitrary adversarial predicate, not
  a likely architectural shortcut;
- adding both increase and decrease cases would begin an unbounded symmetry
  matrix without introducing a new semantic rule.

## Approved patch set

The previous four local probes and these five were approved in the same
iteration:

1. two `local_handler_extremes` modules in `v3n8`, each with leaf-accepted and
   root-accepted cross-branch local tests;
2. one awaitable `LocalB` mirror in `q7m2`;
3. five one-distinct-test verifier mutations.

The combined change moves from the predecessor's 33 tests to 42:

- four already proposed degenerate-boundary tests;
- four local handler-extreme tests from FP-1 and FP-2;
- one awaitable unbalanced/outside-path mirror from FP-3.

The verifier moves from 20 to 29 mutations: four for the previously proposed
probes and five for this audit. `meta.md` and `solution.patch` remain
byte-identical.

## Validated 42-test predecessor

The full package was applied and validated:

- reference: 42/42 focused tests;
- baseline: 23 workspace tests and 22 doctests;
- feature composition: blocking-only and async-only no-default-feature builds;
- verifier: all 29 mutations caught, with every new mutation isolated to one
  intended test;
- run-8 replay: all six patches scored 40/42 and failed only the two existing
  parent-insertion cases.

Final SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `b47d2a0aff86ecaff1acfaab4abae6a2bd8c34d91b7e1cafa94684c7cd5ea01c` |
| `test.patch` | `504ec3205030665706f382bb8faf47541fcb08fb0875db2f16271650586daa58` |
| `solution.patch` | `9fd3f07e7b1c202187f96e4d2fea0b968ea69e962faf0a5b0dfbedb7077f67bd` |
| `verify/mutations.sh` | `899680ab75ac8d5c8e0f4bde8dacd7461b5beb92fa9f9468fd085e668b55840d` |
| `verify/README.md` | `296f1ca28a436be4b785fba26fdf98f96e400f794f8450ec7b467ef6a1887121` |

The finalized 42-test artifact is a fresh immutable version at 0/10. The next
step is exactly one Nova and one Orion preflight before committing the rest of
the run budget.

## Follow-up trial: distinct-local hierarchy mutation

Status: complete and applied. Four additional mode-specific false positives
were added to the production matrix.

### Baseline

This trial begins with the validated 42-test artifact. The immediately proposed
leaf-handler hierarchy-mutation pair forms a 44-test intermediate prototype.
The follow-up then searches for an implementation that passes those new probes
while still violating the same current-shortest-path rule through a different
handler origin.

### Trial A: stale hierarchy for leaf-origin local outcomes

Mutation:

- capture the active source depth before dispatch;
- for a distinct local outcome returned directly by the leaf, combine that
  stale depth with the post-handler target and common boundary;
- apply the defect to only blocking or only awaitable.

Probe:

- `Source` initially has `Root` as its direct superstate;
- its leaf handler inserts `Branch` below `Root` and returns a local transition
  to `Target`, which is also below `Branch`;
- require only `exit source`, then `enter target`.

Results:

- both one-engine mutations pass the current 42/42 suite;
- the reference passes the symmetric 44/44 prototype;
- each mutation scores 43/44 and fails only its corresponding probe;
- all six run-8 patches pass both probes and fail only the two pre-existing
  parent-insertion cases.

### Trial B: stale hierarchy only for superstate-origin local outcomes

Mutation:

- compute leaf-origin local paths from current hierarchy, so Trial A passes;
- retain the pre-dispatch source depth only when a superstate returns a
  distinct local outcome;
- apply the defect to only blocking or only awaitable.

Probe:

- the active path begins as `Source -> Branch -> Root`;
- the accepting `Branch` handler inserts `AddedParent` above itself;
- it returns a local transition to
  `Target -> Branch -> AddedParent -> Root`;
- require only `exit source`, then `enter target`, because `Branch` is the
  post-handler deepest common boundary.

Results:

- both one-engine mutations pass the proposed 44/44 Trial A matrix;
- the reference passes the combined 46/46 prototype;
- each mutation scores 45/46 and fails only its corresponding Trial B probe;
- all six run-8 patches score 44/46 and still fail only the same blocking and
  awaitable parent-insertion tests.

### Rejected follow-ups

No additional actionable family was found.

- Mutating hierarchy only inside `after_dispatch` or transition hooks would
  test generic callback side effects not stated as part of the new transition
  semantics.
- Repeating Trial B at every possible deferral depth is a combinatorial
  expansion of the same stale-superstate metadata defect, not a new
  architecture.
- Testing both parent insertion and parent removal would duplicate the same
  current-versus-stale decision without distinguishing another survivor.

### Approved implementation

All four probes were added in one iteration:

1. blocking and awaitable leaf-origin hierarchy mutation;
2. blocking and awaitable superstate-origin hierarchy mutation;
3. four one-distinct-test verifier mutations.

The completed artifact moves from 42 to 46 focused tests and from 29 to 33
mutations. `meta.md` and `solution.patch` remain byte-identical. The prompt
already requires the current shortest path regardless of which handler accepts
the event.

Final validation:

- reference: 46/46 focused tests;
- baseline: 23 workspace tests and 22 doctests;
- feature composition: blocking-only and async-only no-default-feature builds;
- verifier: all 33 mutations caught, with each new mutation isolated to one
  intended test;
- run-8 replay: all six patches scored 44/46 and failed only the two existing
  parent-insertion cases.

Final SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| `meta.md` | `b47d2a0aff86ecaff1acfaab4abae6a2bd8c34d91b7e1cafa94684c7cd5ea01c` |
| `test.patch` | `408ea040917b64feb0688ecb7ed92338d85a3c11748e16d38927c81b4e99f9d9` |
| `solution.patch` | `9fd3f07e7b1c202187f96e4d2fea0b968ea69e962faf0a5b0dfbedb7077f67bd` |
| `verify/mutations.sh` | `c56a6c0a02035a3fc2341ef10fcbe59b596812c1674442b5ffedaa3056ae6eb8` |
| `verify/README.md` | `63032585478b5bcb768188c21d0c960b9f8c93907f7652f680dab36a53e236c1` |

The finalized 46-test artifact is a fresh immutable version at 0/10. The next
step remains exactly one Nova and one Orion preflight.
