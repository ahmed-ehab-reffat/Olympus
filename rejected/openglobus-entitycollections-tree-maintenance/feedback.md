# feedback — openglobus-entitycollections-tree-maintenance

NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

## Status

**Step 4b core slice, locally validated. No platform batch, no differentiating scope.**

Repo `openglobus/openglobus`, base `61757dbc79604e37b3e85192ca1945b94c982d2a` (still master HEAD at
scope-lock). Feature: incremental insert and remove maintenance of the entity collections quadtree a
`Vector` layer keeps over its planet.

## Slice contents

- `meta.md` 319 body words, ASCII, frontmatter commit copied from `BASE_COMMIT.txt`.
- `solution.patch` 229 raw / **152 human-effective** across **7 files** (hook-measured). Under the
  200 floor by design; `DESIGN.md` section 15 carries ~135 more of orthogonal depth for FINISH.
- `test.patch` `test.sh` (mode 100755) + `tests/quadTree/EntityCollectionsTreeMaintenance.853b88.test.js`,
  **28 tests**.
- `Dockerfile` Pattern B, `olympus-base-typescript`, `npm ci --ignore-scripts`. Cold
  `--no-cache` build measured **197 s** (limit 600).

## Local validation (clean room: fresh clone at BASE, Docker, uid 1000, --network none)

| configuration | base mode | new mode |
|---|---|---|
| base + test.patch | 227 pass / 0 fail, exit 0 | 28 tests / **28 fail**, exit 1 |
| base + test.patch + solution.patch | 227 pass / 0 fail, exit 0 | 28 pass / 0 fail, exit 0 |

Flakiness: every one of those four cells run **3x**, byte-identical test-name and failure sets each
time (md5 of the extracted `name=` / `<failure message=` sets). Patches apply in both orders and
reverse-apply cleanly. `tsc --noEmit` clean. No `shipd`/`datacurve` in any name, no `::` in any JUnit
id, no comments in the tests, three concise JSDoc blocks in the solution matching the convention of
the two files that already JSDoc their public members.

## Harness route (the pick's make-or-break risk, RESOLVED)

The hunt log flagged that `Vector.addTo` needs `planet.renderer.handler`, so its probes drove
`v._planet` and the protected `_createEntityCollectionsTree` directly, which would be a test-quality
reject. Measured alternative, now used by the suite: `new Planet()`, assign a small duck-typed object
to the **public, documented** `Scene.renderer` field, then `planet.addLayer(layer)`,
`layer.setEntities(...)`, `layer.add(...)`, `layer.removeEntity(...)` and the new
`layer.getEntityCollectionsTreeStrategy()`. Every step is a public member. The stub needs exactly
`handler.isInitialized()`, `isInitialized()`, `requestRedraw()`, `assignPickingColor()`,
`clearPickingColor()` and `events.on/off`. No WebGL, no canvas, no pixel assertions; billboards are
built without `src` so no texture atlas is touched.

## Decisions taken without asking (unattended run)

1. **`getRootNodes()` is mostly an observability API.** It is the only way any caller can reach the
   strategy's trees, and `PICK-FILTER`'s scope levers allow an additive read-only accessor, but it is
   not load-bearing for `removeEntity` (which dispatches on `entity._nodePtr`). Kept, named in
   meta.md with its exact per-strategy order. Conservative alternative would have been to read the
   protected `_entityCollectionsTreeStrategy` from the tests, which is worse.
2. **A same-position exception was added to the capacity invariant.** Without it the contract is
   unsatisfiable and the split recursion never terminates on duplicate coordinates - base
   `buildTree` already has that hang. One clause in meta.md, one guard in the reference, two tests.
3. **Trap 3's cell count is thin (2 of 28).** The destination-predicate mutant kills only the two
   F-10 off-diagonal tests. That is the designed behaviour, but it means the north/south/Equi axis is
   currently carried by two tests; FINISH should widen it rather than adding more mercator cases.
4. **`_getPosition` was made protected, not public**, to keep the documented API surface to the three
   names meta.md states.

## Owed

- **Requirement 0 platform picker check for `openglobus/openglobus`** (human only). Record a refusal
  in `SATURATED-REPOS.md` section A0.
- **Platform precheck of this slice** (dedupe / scope gate). The lane is partly outsider-nameable
  ("incremental quadtree maintenance", MEDIUM), so the precheck is the only instrument that can see a
  rival. Do it before any FINISH work.

## Gate results

All ten PICK-FILTER gates, the SIX-CHECK and the canonical-org PR-DIFF exclusivity check are recorded
in `DESIGN.md` section 17, with the three base behaviours reproduced in section 18 and the seven
trap-proof mutants in section 19.

## REJECTED 2026-09-22 at the core-slice precheck: DERIVATIVE, overlap `Blocker`

> derivative - [another submission]: 92 of 197 authored subject solution lines (46.7%) re-deliver
> the older candidate's incremental entity-tree rebucketing, removal/count repair, same-position
> split guard, node-pointer maintenance, and cleanup engine; those lines are 92 of 338 (27.2%) of
> the candidate. The subject turns a repository-specific maintenance clause already implemented by
> the older candidate into the primary standalone task; new introspection APIs and stricter
> invariant coverage do not replace the recycled core.

Not contestable: the rival holds the same kernel, including our own "unattended decision 2" (the
same-position split guard). The FINISH scope in DESIGN.md sec 15 (re-homing, setter wiring, deferred
queue, `_renderingNodes` hygiene) is the same maintenance engine, so it cannot differentiate. Shelved
with no batch run and no picker spend. Case study: `Instructions/TOO-EASY.md`; repo ledger:
`Instructions/SATURATED-REPOS.md` B2-OPENGLOBUS.
