# DESIGN.md — featurevisor-target-specialization

Second lane in a proven repo (first: `approved-problems/featurevisor-minimal-rebucketing`, builder
traffic allocation). Source: `REPO-HUNT-2026-09-19.md` Part 2 RANK 2, dossier
`worktrees/_hunt/agents/featurevisor-0919.md`. Picked after `rejected/dinit-depends-any-groups`
died at 105 eff (machinery-absorbed). Base `b88f3981989c3cc7a06efea2597807517a624d16` (v3.11.0, HEAD,
no commits since the approved base).

## Phase 1 — repo understanding

Featurevisor builds JSON datafiles from YAML definitions (features, segments, attributes, variables,
targets). `packages/core/src/builder` builds a datafile per environment and, for each Target with a
`context`, specializes it through `applyContextToDatafile` (called from `buildProject.ts:143`). The SDK
(`packages/sdk`) evaluates datafiles: `conditions.ts` (leaf operators, and/or/not, empty containers),
`instance.ts` `getMatchedForce` (conditions OR segments), `getMatchedTraffic` (segments), global
variable overrides (requiredFeatures AND segments AND conditions), `evaluate.ts:811-836` rule and
variation overrides (requiredFeatures, then conditions if present else segments else
requiredFeatures-defined). Tests: jest, `packages/core/src/builder/*.spec.ts`; template
`applyContextToDatafile.spec.ts`.

## Phase 2 — exclusivity

Dossier § 10 (searches for scope, scoped datafile, target context, redundant, notEquals, notExists,
partial context, prune; code search for the builder functions): only #379 (the feature), #285 (closed
2024 draft, docs + `@TODO` stub), #409 (v3 task list, no pruning task). Public branch `scopes`
re-checked 2026-09-19: design doc + examples + a builder stub whose body is `@TODO: remove redundant
conditions / segments / rules` (intent, no implementation). No removal record. No SDK port or sibling
product does build-time specialization.

## Contract (meta.md)

1. Equivalence: Target datafile at runtime context R == full datafile at R + Target context.
2. A condition is decided only when the Target context has a value at its attribute path.
3. Decided conditions and decided segments are folded into every expression using them; SDK
   meaning of segments / and / or / not / lists, empty ones included; stringified selectors accepted.
4. Prune force, traffic, rule + variation variableOverrides, global overrides: drop never-matching,
   drop everything after an always-matching entry, per-kind SDK match rule; `requiredFeatures` can
   never be known to match.
5. Keep exactly the segments remaining entries reference.

## Reference (measured)

`specializeForTarget.ts` (new, 389 raw / 228 human-eff) + `applyContextToDatafile.ts` rewired
(3 eff). **231 human-effective**, 2 files. Three-valued tree specializer shared by conditions and
group segments, per-kind entry decisions (`EntrySpecializer`), `pruneEntries` cut-off, reference
collection + segment GC. Old two-valued helpers left intact with their 4000 lines of unit specs.

## Tests

New `targetSpecialization_cb9400.spec.ts`: 18 behaviour tests, 2 build-path tests through
`buildTargetDatafile` (stringify on and off), 8 seeded equivalence batches (40 random datafiles x 4
Targets x a context grid, SDK as the oracle). All 28 fail on base. Base mode: 1033 (the existing
suite minus 24 superseded cases, plus 2 guard tests in `applyContextToDatafile.spec.ts` that pass on
base and with the reference).

Superseded cases removed from base mode (they pin the old behaviour): 22 in
`applyContextToDatafile.spec.ts` ("non-matching ... remains", partial-match segment residuals on
segment tables no feature references, "preserves NOT rules as non-broadening", consecutive-`*`
dedupe), 2 in `buildDatafile.spec.ts` (re-expressed as the two build-path tests).

## Trap matrix (reproduced 2026-09-19 by mutating the reference)

| # | Naive design | F-id | Killed by |
|---|---|---|---|
| T1 | fold leaves with the SDK's two-valued matcher (base behaviour) | F-24 | 28/28 new tests |
| T2 | one generic "entry matches" rule (force as AND) | F-3 / F-10 | 26 (force cells, build test, 8 seed batches, 14 base-mode force specs) |
| T3 | requiredFeatures ignored when deciding "always matches" | F-10 | exactly the 2 requiredFeatures cells |
| T4 | `not` over a decided-false child filters the child (reuse of `removeRedundant*`) | F-39 | not cell + variation cell + 8 seed batches |
| T5 | segment GC blind to global-override references | F-7 | global + GC cells + 2 seed batches |
| T6 | presence by top-level key instead of attribute path | F-24 | base-mode guard (nested sibling path) |

## Risks

- Reviewer optics: 24 maintainer specs removed from base mode. Precedent: the accepted rebucketing
  pick moved 5 `traffic.spec.ts` cases the same way. Each removed case pins the behaviour the
  maintainer's own #379 docs and `targets.md` say should not happen.
- LOC 231 is above the 200 floor, under the 250-300 design target; agent diffs are expected to be
  larger (separate condition and segment walkers).
- Derivative: "partial evaluation" is a textbook idea; phrased on Targets, force, traffic, overrides.
- Word count 313.

Predicted pass: 15-35% (T2/T3/T4 are independent of each other but all ride the same entry kernel;
the seeded sweep punishes any unsound fold).
