# DESIGN.md — openglobus-entitycollections-tree-maintenance

Status: **Step 4b core slice** (olympus-factory MODE=SLICE). Differentiating scope (cross-tree
re-homing, the mutation-path wiring, the F-10 cross-product cells) is designed in section 15 and is
deliberately NOT built yet — it waits on the platform precheck verdict.

Repo: `openglobus/openglobus` (TypeScript, Apache-2.0, 936 stars)
Base: `61757dbc79604e37b3e85192ca1945b94c982d2a` (still `master` HEAD at scope-lock)

---

## 1. Title

**Add incremental maintenance to the Vector layer entity collections tree**

Verb: Add. Names the subsystem (`Vector` layer's entity collections tree). 9 words.

## 2. Shape classification

- Shape: **O-Composite-extend** (`SHAPES.md § Pattern 12`): one shared kernel
  (`EntityCollectionNode`) is extended with maintenance operations that every consumer of the tree
  (three Earth trees, two Equi trees, `Vector.removeEntity`, the two render passes) must keep
  working. Nearest historical Mars analogue is **A2** (concentrated, signature-adding).
- Pass rate target: <= 40% ceiling, design to the hard edge (~10-25%).
- Best agent: Orion (long-horizon, decisive); Nova is expected to write the naive one-level split.
- Dominant verdict predicted: MISSED_REQUIREMENT, then REGRESSION.
- Solver/our LOC ratio: expect ~1.3-1.7x (agents rewrite `buildTree` as well).

## 3. Public API surface (exact names the tests assert)

New:

- `Vector.getEntityCollectionsTreeStrategy(): EntityCollectionsTreeStrategy | null` — instance
  method, no arguments; returns the strategy the layer built for its planet, or `null` before the
  layer is added to one.
- `EntityCollectionsTreeStrategy.removeEntity(entity: Entity): boolean` — instance method; removes
  the entity from the tree it is held in and reports whether it was there.
- `EntityCollectionsTreeStrategy.getRootNodes(): EntityCollectionNode[]` — instance method, no
  arguments; the strategy's root nodes. Earth returns `[mercator, north, south]`, Equi returns
  `[west, east]`, the base class returns an empty array.
- `EntityCollectionNode.removeEntity(entity: Entity): boolean` — instance method on the node that
  holds the entity.

Not public API, so not named in meta.md: `EntityCollectionNode._getPosition(entity)` (protected,
overridden by the two lon/lat node subclasses beside their existing `isInside` override) and the
protected helpers in section 8.

Existing public surface the tests read (all already `public` at base):

- `EntityCollectionsTreeStrategy.insertEntity(entity, rightNow?)`, `.insertEntities(entities)`
- `EntityCollectionNode.count`, `.childNodes`, `.entityCollection`, `.extent`, `.deferredEntities`,
  `.parentNode`, `.zoom`, `.nodeId`, `.isInside(entity)`
- `Vector.add(entity)`, `.addEntities(entities)`, `.removeEntity(entity)`, `.setEntities(entities)`,
  `.getEntities()`
- `Entity._nodePtr`
- `Planet.addLayer(layer)`, `Planet.quadTreeStrategy`, `Scene.renderer`
- `EntityCollection.getEntities()`, `.belongs(entity)`

## 4. Canonical output form

The contract is a set of structural invariants over the tree, so they are spelled out exactly:

- **Residency:** an entity is held by exactly one node, that node's extent contains it, and that node
  has no child nodes.
- **Capacity:** no node holds more than `nodeCapacity` entities of its own, unless every one of them
  is at the same position, in which case no split could ever separate them and the node keeps them.
  Without this exception the contract is unsatisfiable and both the base `buildTree` and any
  incremental splitter recurse forever on duplicate coordinates (the hunt log's fifth, latent
  finding). Measured: base `buildTree` already hangs on `nodeCapacity + 1` entities at one position.
- **Counting:** `count` on every node equals the number of entities held at or below it.
- **Release:** a node holding nothing has no entity collection.
- **Collapse:** a node with nothing below it has no child nodes.
- **Split order / tie-break:** a position that lies on the boundary between two child extents belongs
  to the first of `NW`, `NE`, `SW`, `SE` whose extent contains it (this is base `buildTree`'s own
  order and `Extent.isInside` is inclusive on both edges, so the four children tile the parent
  exactly and no entity can fall outside).
- **Which tree:** unchanged from base. Earth routes by latitude band (north above
  `mercator.MAX_LAT`, south below `mercator.MIN_LAT`, otherwise the mercator tree); Equi routes by
  longitude sign.
- **Empty input / absent entity:** `removeEntity` on an entity the tree does not hold returns
  `false` and changes nothing.

## 5. Blind-spot pre-empts (DESCRIPTION.md sentence bank)

| Blind spot | Sentence used in meta.md |
|---|---|
| Iteration termination | "No node holds more than `nodeCapacity` entities of its own" states the invariant over the WHOLE tree, so the recursion is implied and not spelled out (Rule-7 de-enumeration). The exception clause that makes it terminable is stated: "unless every one of them sits at the same position" |
| Rule-resolution | "that node's extent contains it" plus "All of this holds in each of the three trees the Earth strategy keeps and in both trees the Equi strategy keeps" -- the scope is stated, the fact that the trees decide membership with different coordinates is left to the code (it is visible in the existing `isInside` overrides) |
| Unstated inverse | "a node holding nothing has no entity collection, and a node with nothing below it has no child nodes" |
| Parallel API | `getRootNodes()` named with its exact return for every strategy |
| Falsy-on-invalid | "`removeEntity` reports whether the entity was in the tree" |

Codebase-inferable requirements: **1** (that the Earth strategy has three trees and Equi two — it is
visible in `insertEntity`, and meta.md names it anyway, so effectively 0).

## 6. Description draft

See `meta.md`. 319 body words, plain prose, no headers, ASCII, unwrapped paragraphs.

## 7. File footprint (sketched against real source)

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | `src/quadTree/EntityCollectionNode.ts` | 336 | +178 | 115 | descend-to-leaf insert, split-on-residents with the same-position guard, redistribute, remove, release, collapse, `_nodePtr` on residency |
| MODIFY | `src/quadTree/EntityCollectionsTreeStrategy.ts` | 84 | +20 | 16 | `removeEntity`, `getRootNodes` |
| MODIFY | `src/quadTree/earth/EarthEntityCollectionsTreeStrategy.ts` | 213 | +4 | 2 | `getRootNodes` over three trees |
| MODIFY | `src/quadTree/earth/EarthEntityCollectionNodeLonLat.ts` | 116 | +4 | 2 | `_getPosition` in degrees |
| MODIFY | `src/quadTree/equi/EquiEntityCollectionsTreeStrategy.ts` | 160 | +5 | 3 | `getRootNodes` over two trees |
| MODIFY | `src/quadTree/equi/EquiEntityCollectionNodeLonLat.ts` | 110 | +4 | 2 | `_getPosition` in degrees |
| MODIFY | `src/layer/Vector.ts` | 1090 | +14 | 12 | `removeEntity` delegates to the strategy; `getEntityCollectionsTreeStrategy()` |

SLICE total, MEASURED with `.claude/hooks/effective_loc_check.py`: **229 raw / 152 human-effective
across 7 files** (sketch was 204 / 143 over 5, so the sketch was honest). Clears the >= 2-file floor;
the >= 200 human-effective floor is a FINISH-stage gate and section 15 carries the remaining ~135.
The hook flags padding-floor 74 against human-effective 152, i.e. the slice leans on breadth; the
FINISH scope in section 15 is orthogonal DEPTH (re-homing, the mutation-path split, the deferred
queue), not more of the same surface.

**Chokepoint honesty (the dinit lesson).** The five surfaces above are not five independent
estimates: the insert descent, the split, the removal and the collapse all live in
`EntityCollectionNode` and share `childNodes` / `count` / `entityCollection`. The number above counts
DECISION POINTS (descend, split-and-redistribute-recursively, release-a-collection,
remove-and-decrement, collapse-upwards), not surfaces, and it is a sketch — it is re-measured with
`effective_loc_check.py` at the end of the slice and again at FINISH.

## 8. Solution outline — helpers

- `EntityCollectionNode._getPosition(entity): LonLat` — the coordinate this node's `isInside`
  decides with. Base returns `entity._lonLatMerc`; the Earth and Equi lon/lat nodes return
  `entity._lonLat`. Requirement: the same-position exception, in every tree.
- `EntityCollectionNode._splitSeparates(entities): boolean` — whether the entities differ in
  position at all. Requirement: the same-position exception, and it is what makes the split
  recursion terminate.
- `EntityCollectionNode._childFor(entity): EntityCollectionNode | null` — the child whose own
  `isInside` accepts the entity, in NW/NE/SW/SE order. Requirement: residency + tie-break.
- `EntityCollectionNode._findLeafFor(entity): EntityCollectionNode | null` — descend from this node
  through `_childFor` until a node with no children. Requirement: residency.
- `EntityCollectionNode._residentEntities(): Entity[]` — the entities this node holds, whether they
  are in the entity collection or still in `deferredEntities`. Requirement: counting.
- `EntityCollectionNode._releaseCollection()` — detach the node's entity collection from the scene
  and forget it, dropping any deferred entities. Requirement: release.
- `EntityCollectionNode._splitIfNeeded(rightNow)` — if this node holds more than `nodeCapacity`,
  create children, move every resident into `_childFor` it, release this node's own collection, then
  do the same for each child. Requirement: capacity (recursive).
- `EntityCollectionNode._collapseUpwards()` — from this node up, while a node has nothing below it,
  release its collection and dispose its children. Requirement: collapse.
- `EntityCollectionNode._disposeSubtree()` — release this node and every descendant's collection.
- `EntityCollectionsTreeStrategy.removeEntity` / `.getRootNodes` — the strategy-level entry points.

No fixpoint loop is needed (the split recursion terminates because each split strictly increases
depth and the extents strictly shrink); the recursion is written explicitly rather than as a loop.

## 9. Test file outline

Path: `tests/quadTree/EntityCollectionsTreeMaintenance.<hex>.test.js` (vitest, jsdom, repo
convention: `tests/<area>/<Name>.test.js`).

**Harness route (the make-or-break question, RESOLVED).** The suite drives only public members:

```js
const planet = new Planet();          // or new Planet({quadTreeStrategyPrototype: EquiQuadTreeStrategy})
planet.renderer = stubRenderer();     // `Scene.renderer` is a public field; the stub is a plain object
planet.addLayer(layer);               // public
layer.setEntities([...]);             // public
layer.add(entity); layer.removeEntity(entity);   // public
const strategy = layer.getEntityCollectionsTreeStrategy();   // NEW public accessor
```

`Vector.addTo` dereferences `planet.renderer!.handler`, so a headless planet needs a renderer
object. `Scene.renderer` is declared `public renderer: Renderer | null` and is documented
("Assigned renderer. @public"), so assigning a duck-typed stub is a public-surface test mock, not a
private-member drive. The stub implements exactly `handler.isInitialized()`, `isInitialized()`,
`requestRedraw()`, `assignPickingColor()`, `clearPickingColor()` and `events.on/off`, every one of
which the base code already guards or calls unconditionally on the headless path. **Measured on
base: this route builds a real `EarthEntityCollectionsTreeStrategy` with a populated tree, and the
same route works for `EquiQuadTreeStrategy`.** No WebGL, no canvas, no pixel assertions; billboards
are created without `src` so no texture atlas is touched.

The only place the tests reach past a `public` member is `entity._nodePtr`, which is
`public _nodePtr?: EntityCollectionNode` on `Entity` and is named in meta.md.

Block 1 — imports (`Planet`, `Vector`, `Entity`, `LonLat`, `EquiQuadTreeStrategy`, `mercator`).
Block 2 — builders: `stubRenderer()`, `makeLayer(opts, StrategyProto)`, `ent(lon, lat, name)`,
`spread(n)`, `cluster(n, lon, lat)`.
Block 3 — assertion helpers: `roots(layer)`, `leafOf(entity)`, `allNodes(root)`,
`assertTreeInvariants(root, capacity)` (residency, capacity, counting, release, collapse checked
over the whole tree in the contract's own vocabulary, not through a structural proxy — F-17/L27),
`countEntities(root)`.
Block 4 — tests grouped by requirement:

- residency: insert descends into an existing child; an interior node holds nothing of its own
- capacity: one insert past capacity splits; a clustered run splits recursively; capacity holds
  after 60 inserts
- counting: counts after bulk build, after inserts, after removals, after a removal of an entity
  that was never in a split tree (the `_nodePtr` cell)
- release/collapse: emptying a leaf releases its collection; emptying every child drops the children;
  the collapsed parent accepts entities again
- per-tree: the same invariants in the Earth north tree (degrees) and in both Equi trees
- negatives: removing a foreign entity returns false and changes nothing; removing twice is a no-op
- base-behaviour guards: `getEntities()` order and `_layerIndex` after removal; a polyline entity
  (not in the tree) still removes through `Vector.removeEntity`

Plus two termination cells (`entities_sharing_a_position_stay_in_one_leaf`,
`a_bulk_build_of_one_position_stays_in_one_leaf`) and one tie-break cell
(`a_position_on_a_child_boundary_goes_to_the_first_child`, on the Equi east tree at longitude 45 /
latitude 0, both dyadic and therefore exact in binary).

Count for the slice: **28 tests**. FINISH grows it.

## 10. Forced shapes

- `getRootNodes()` returns an ARRAY, and the Earth order is `[mercator, north, south]` — stated in
  meta.md, because a test reads `roots[1]` for the north tree (L72: name the full call shape).
- `removeEntity` returns a boolean, stated.
- `getEntityCollectionsTreeStrategy()` is an instance method with no arguments, stated.
- No generics, no callbacks, no kwargs in this lane.

## 11. Predicted trap matrix (slice)

| # | Trap | F-id | Arsenal class | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | `_nodePtr` is assigned only on the split path, so a leaf-only tree has no back pointers and pointer-based removal silently does nothing | **F-41** (runtime path skips a loader-injected attribute) | S4 | pointer provenance | #4 (collapse needs to know which node) | `buildTree` sets `ei._nodePtr` inside the `entities.length > _nodeCapacity` branch only; `Vector.removeEntity` already dispatches on `_nodePtr`, so the field looks maintained. MEASURED on base: 3 entities at capacity 5 -> `_nodePtr` set on 0 of 3 | "every entity knows the node that holds it" | `remove_from_an_unsplit_tree_updates_the_count` |
| 2 | Split armed on the INCOMING batch length rather than on the node's resident count | **F-15** (arming vs firing) | A8 | when the split fires | #3 (the redistribution only runs if the split fires) | base's condition is `entities.length > this.layer._nodeCapacity` and `insertEntity` passes an array of one, so `1 > capacity` is never true. MEASURED: 8 entities at capacity 4 then 60 clustered inserts -> root count 68, children still 4, leaf sizes 3/1/3/1 | "no node holds more entities than `nodeCapacity`" | `one_insert_past_capacity_splits_the_leaf` and `a_clustered_run_splits_recursively` |
| 3 | Redistribution written against the parent's extent arithmetic or against `_lonLatMerc`, instead of asking the destination child | **F-18** (two spellings of one concept) / F-10 | A6 | which coordinate decides membership | #2 | `EntityCollectionNode.isInside` reads `entity._lonLatMerc` and its extent is in metres; `EarthEntityCollectionNodeLonLat` and `EquiEntityCollectionNodeLonLat` override `isInside` to read `entity._lonLat` and their extents are in degrees. A split hoisted into the base class is correct for the mercator tree and silently wrong for north, south, west and east | "the child whose extent contains it" | the north-tree and Equi split tests |
| 4 | A split node keeps its own (now empty) `entityCollection`, or a collapsed parent keeps its `childNodes` | **F-14** (declared vs derived terminal state) | S3 | node identity after a structural change | #1, #2 | `collectRenderCollectionsPASS1` tests `if (this.entityCollection) ... else if (cn.length)`, so an interior node that still owns a collection hides its whole subtree; and a parent that keeps four empty children can never accept an entity again | "a node holding nothing has no entity collection, and a node with nothing below it has no child nodes" | `splitting_releases_the_parent_collection`, `emptying_every_child_drops_them`, `a_collapsed_node_accepts_entities_again` |

Every row names a measured F-id. Axes differ (pointer provenance / firing condition / coordinate
predicate / structural terminal state). Rows 1-2-4 are interdependent: the pointer is what removal
walks, removal is what empties a node, and an emptied node is what the collapse rule is about; fixing
the split without row 4 regresses rendering, and fixing row 4 without row 2 leaves the tree unable to
grow.

**CONTRACT-STATED / FIX-HIDDEN check, per row.** Row 1: the contract says every entity knows its
node; it does not say the assignment belongs in `_addEntitiesToCollection` rather than in the split
branch. Row 2: the contract states the capacity invariant; it does not say the condition must read
the node's residents. Row 3: the contract says "the child whose extent contains it"; it does not say
that the child decides with a different coordinate than its parent's extent is expressed in. Row 4:
the contract states both terminal states; it does not mention `collectRenderCollectionsPASS1`'s
precedence, which is what makes a leftover collection fatal rather than merely untidy.

## 11b. Capability cross-product matrix (F-10)

Axis 1 = operation (`insert` that splits / `remove` that collapses).
Axis 2 = which tree (mercator, metres, `_lonLatMerc` predicate / lon-lat, degrees, `_lonLat`
predicate).

| | mercator tree | lon-lat tree (Earth north, Equi west/east) |
|---|---|---|
| **insert past capacity** | `one_insert_past_capacity_splits_the_leaf` | `north_tree_splits_past_capacity` <- off-diagonal |
| **remove to empty** | `emptying_every_child_drops_them` | `equi_west_collapses_when_emptied` <- off-diagonal |

Both off-diagonal cells are in the SLICE, because they are what makes the shared kernel shared;
the wider cross product (deferred vs immediate, Earth vs Equi vs EPSG4326, the four mutation APIs)
is FINISH scope.

Scope audit: `nodeCapacity` is scoped to a single node's OWN entities, not to a subtree — stated.
`count` is scoped to the subtree — stated. Example audit: meta.md carries no worked example.
Format-noun audit: "node", "entity collection", "child" all have the repo's meaning and meta.md uses
them in the same sense the source does. Tolerance audit: the capacity rule's discriminating fixture
is the N+1 insert into a leaf holding exactly N (L25), and the N-1 case (`stays_a_leaf_at_capacity`)
asserts nothing happened.

## 12. Tier + category

- Tier: Olympus (single tier).
- Category: **feature-request** (net-new public methods and a capability the tree does not have).
  Title verb is "Add". Matches.

## 13. Predicted pass rate

- Predicted 10-30%.
- Reasoning: the capacity invariant is transcribable and a competent agent will get the descent and
  the one-level split; the recursive split, the destination predicate on the lon-lat trees, and the
  release/collapse pair are three independent places to be wrong, and row 4 has no local symptom in
  the agent's own smoke tests.
- Risk of 0%: low for the slice (the invariants are all stated and checkable by the agent's own
  reasoning). Risk of >40%: real, which is why FINISH adds the re-homing lever and the wider F-10
  cells rather than more instances of the same axis.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (see section 16)
- [x] Existing PR / publicly-solved check: 0 hits (section 17)
- [x] Closest approved problem opened as scaffolding: `approved-problems/` TypeScript picks
      (featurevisor x2) for the JS/TS test and Docker shape
- [x] Title verb-led, 9 words, names the subsystem
- [x] Shape declared
- [x] Public API surface lists every name the tests assert
- [x] Canonical form spelled out (residency, capacity, counting, release, collapse, tie-break,
      which tree, absent entity)
- [x] <= 1 codebase-inferable requirement
- [x] Description draft under 500 words
- [x] No `##` headers / labels / `Box<>` / code-as-prose in meta.md
- [x] File footprint sketched against real source, chokepoint honesty stated
- [ ] LOC floor >= 200 meaningful — SLICE is under by design; FINISH scope in section 15
- [x] Helpers map 1:1 to requirements
- [x] Test outline 4-block, scenario-encoded names
- [x] 5-axis coverage planned
- [x] Forced call shapes documented and stated in meta.md (L72)
- [x] 4 named traps, each with an F-id, a pre-empt sentence and a catching test
- [x] Traps on different axes, three of four interdependent
- [x] F-10 matrix filled, both off-diagonal cells tested
- [x] Stage-placement audit (L57): meta.md says nothing about where a new step sits between existing
      ones; it states invariants over the finished tree
- [x] Float audit (L59): no assertion compares a computed coordinate for equality. Positions are
      chosen away from extent boundaries, and the one boundary rule that is stated (first of
      NW/NE/SW/SE) is tested with a point exactly on a dyadic child boundary of the degrees tree
      (lat 0 / lon 0), which is exact in binary
- [x] Sibling-API audit (F-20): `removeEntity` on the strategy is a sibling of `insertEntity`. The
      new rule is scoped by naming only the new method. Base-behaviour guard: a polyline entity,
      which never enters the tree, must still remove through `Vector.removeEntity`
- [x] Representation-pin sweep (L48/L49): the assertions read `count`, `childNodes.length`,
      `entityCollection === null` and collection membership — all named in meta.md as the contract's
      own vocabulary. `getEntities()` order is asserted through the public getter
- [x] Qualifier-attachment (L52): each invariant is its own sentence with one subject
- [x] Stated-but-untested audit (L53): every sentence in meta.md has at least one test
- [x] In-process validation (L56): no test shells out
- [x] Throttle/assert audit (L70): no test gates one resource and asserts on another
- [x] Loader-attribute audit (F-41): done — `_nodePtr` is exactly that seam, measured 0 of 3
- [x] No flaky construct: no timers, no RNG, no network, no ordering over a Map/Set
- [x] Predicted pass <= 40%

## 15. FINISH scope (designed, NOT built in the slice)

1. **Cross-partition re-homing.** `EntityCollectionsTreeStrategy.rehomeEntity(entity)`: recompute
   which tree and which leaf the entity belongs to, detach it from its current node (with the
   collapse rule), and insert it. Earth crosses between the mercator tree and the north/south trees
   at `mercator.MAX_LAT`/`MIN_LAT`; Equi crosses at longitude 0. ~55 eff.
2. **The mutation-path wiring and the silent setter.** `Entity.setLonLat`, `setLonLat2` and
   `setCartesian3v` must re-home; `_setCartesian3vSilent` must not, because
   `EntityCollectionNode.alignEntityToTheGround` calls it on every clamp-to-ground render pass and
   re-homing there would churn the tree every frame. `Entity.setLonLat` also leaves `_lonLatMerc`
   stale past `MAX_LAT` (the `//this._lonLatMerc = null;` line at `Entity.ts:1191`) while its twin
   `setLonLat2:1219` zeroes it — an F-18 cell between two public APIs that decides whether a re-home
   through one setter lands in the right tree. ~35 eff.
3. **The deferred queue.** With `async: true` entities sit in `deferredEntities` until
   `applyCollection` runs under `requestAnimationFrame`. Remove, split and collapse must all be
   correct for an entity that is still deferred. Tests use `rightNow: true` / `async: false` for
   determinism and one explicit `applyCollection()` call, never a timer. ~25 eff.
4. **`_renderingNodes` hygiene.** A released or collapsed node's id must be dropped from the right
   per-tree map (`_renderingNodes`, `_renderingNodesNorth/South`, `_renderingNodesWest/East`), or
   `isVisible()` keeps returning true for a node that no longer exists and the deferred queue
   re-arms on it. ~20 eff.
5. **Wider F-10 cells**: (Earth | Equi) x (merc | north | south | west | east) x (split | collapse |
   re-home), plus the interior-node-holds-nothing guard through `collectRenderCollectionsPASS1` with
   a synthetic `visibleNodes` map.

Total FINISH addition ~135 eff, taking the artifact to ~280 meaningful over 6-7 files.

## 16. Phase 1 — repo understanding

**Architecture in one paragraph.** openglobus renders a 3D globe. A `Globe` owns a `Renderer` which
drives `Scene` nodes; `Planet` is the Scene that draws the Earth. A `Planet` owns a
`QuadTreeStrategy` (Earth, Wgs84, Equi or EPSG4326) that maintains the terrain segment quadtree and
decides which segments are visible this frame. Layers attach to the planet; a `Vector` layer holds
`Entity` objects and, for billboard/label entities, indexes them in a SECOND quadtree built by an
`EntityCollectionsTreeStrategy` whose nodes (`EntityCollectionNode`) each own an `EntityCollection`.
Each frame the planet asks the vector layer for the entity collections that are visible, which walks
the entity tree against the terrain tree's visible-node map.

**Five top-level subsystems.** `src/renderer` (Handler, Renderer, framebuffers, shaders) ·
`src/scene` (Scene, Planet) · `src/quadTree` (terrain `Node`s, the per-projection `QuadTreeStrategy`
family, and the entity-collections tree family) · `src/layer` (Layer, BaseTileMaterialLayer, Vector,
XYZ, ...) · `src/entity` (Entity, EntityCollection and the per-feature handlers: billboard, label,
polyline, geoObject, strip, geometry).

**Three high-entanglement zones.** (a) `EntityCollectionNode` — read by two render passes, five
trees, three node subclasses and `Vector.removeEntity`. (b) `Entity` position state
(`_cartesian`, `_lonLat`, `_lonLatMerc`, `_absoluteCartesian`) written by five different setters with
different rules. (c) `Planet.frame` / `QuadTreeStrategy.collectRenderNodes` feeding
`_visibleNodes*` maps that the entity tree consumes by node id.

**Test framework and location.** vitest 4 with jsdom, `tests/<area>/<Name>.test.js`,
`npm test` = `vitest run --reporter=verbose`. JUnit is native:
`vitest run --reporter=junit --outputFile=<path>`.

**Formatting template cited.** `tests/quadTree/EntityCollectionNode.test.js` (constructs an
`EntityCollectionNode` directly against a hand-made strategy stub) and
`tests/scene/Planet.layers.test.js` (constructs a bare `new Planet()` headlessly). Both confirm that
driving these classes from a test without a renderer is the repo's own convention.

## 17. Gate results at scope-lock

| Gate | Result |
|---|---|
| 1 behavioral-f2p-gap | **PASS, reproduced by me on base in this session** (section 18) |
| 2 saturation | PASS. Not a port. "Incremental quadtree maintenance" is partly outsider-nameable (MEDIUM under the softened 2026-09-09-B rule); the reject condition is absent (zero tracker and PR hits for the capability, not a faithful port). Mitigated by phrasing meta.md on this repo's model and by the F-10 cell table |
| 3 uniform-wrap | PASS. Four distinct mechanisms: pointer provenance, firing condition, destination predicate, structural terminal state. A local fix to the split regresses rendering unless the collection is released; a local fix to the collapse leaves the tree unable to grow |
| 4 LOC-ceiling | PASS with the chokepoint caveat in section 7. There is no removal method on the node at base, no split after build, no collapse and no re-home; `Vector.removeEntity`'s cleanup branch is literally an unfinished `// ... //` stub |
| 5 cold-not-live | PASS. `src/quadTree/EntityCollectionNode.ts` 7 commits / 12mo, 2 / 90d; `src/quadTree/earth` 7 / 2; the maintainer's 90-day quadTree subjects are all rendering-adjacent (DepthCamera, csm, deferred, segment radius, idleMode). No commit, merged PR or open PR builds this capability |
| 6 reproduce-on-base | PASS (section 18) |
| 7 dedup all dirs | PASS. `grep -ril openglobus` over `approved-problems/ problems/ rejected/ Instructions/SATURATED-REPOS.md Instructions/TOO-EASY.md` = empty. Nearest feature-class neighbour is `problems/libspatialindex-tpr-temporal-knn` (C++ TPR-tree temporal QUERIES): different repo, different language, query algorithms rather than index maintenance. Adjacent at worst |
| 7b exclusivity, canonical-org PR-DIFF | PASS. `CANON=openglobus/openglobus` (no redirect). `gh pr list --state all --search` over `entityCollectionsTree`, `nodeCapacity`, `quadtree entity`, `removeEntity`, `EntityCollectionNode`, `entity collection node`, `rehome`, `entitymove`, `nodePtr`, `vector layer entity remove` = **zero hits each**. The entire open queue is one PR, **#1045 "Video projection"**, whose diff is `sandbox/uav/uav.js`, `src/renderer/projectors/Projector.ts`, `ProjectorManager.ts`, `src/shaders/common/projectors.glsl`, `src/shaders/common/uniforms.ts` — **zero overlap** with `src/quadTree/**`, `src/layer/Vector.ts`, `src/entity/Entity.ts` |
| 8 defined-behavior / maintainer philosophy | PASS. The correct tree shape is defined by the repo's OWN bulk `buildTree` (capacity-bounded leaves, membership by the node's own `isInside`). Philosophy scan over all `entity` issues for "prefer not to / don't want / by design / won't add / rejected / not planned" = zero. The only nearby open issue, #552, is a rendering-pipeline redesign, not tree maintenance |
| 9 no-flaky-repo | PASS at scope-lock (`npm test` = 43 files / 227 tests green); re-measured 3x through `test.sh` at slice validation |
| 10 repo-quota | PASS. 0 of 6 ours, not in `SATURATED-REPOS.md`, 936 stars (niche band, well under the 5000 penalty threshold) |

**SIX-CHECK.** (1) literal-name PR + issue search: empty. (2) namespace search
(`quadtree`, `entity move`, `vector layer performance`): only the closed EPSG4326 and the open
rendering-redesign issue, neither naming the capability. (3) maintainer-philosophy scan: no
declines. (4) closed-with-implemented scan: no "implemented in v..." comment on any hit. (5)
base..HEAD commit overlap: `git log 61757db..FETCH_HEAD` is **empty** — the base commit is still
`master` HEAD, so nothing shipped post-base. (6) existing-capability functional check: the three
gaps in section 18 were run against base and all three reproduce.

**TOO-EASY pre-pick guard.** (1) not one guard at many sites — four distinct mechanisms. (2) not
single-subsystem — `quadTree/`, `layer/`, `entity/` and the scene's entity-collection lifecycle.
(3) hardness does not need the spec to hide anything: every invariant is stated and the difficulty
is where the fix goes, not what the rule is. (4) not a memorised spec — a textbook quadtree has no
projection-dependent membership predicate, no three-trees-per-strategy split, no entity-collection
scene lifecycle and no render pass that stops at the first node owning a collection. (5) the
difficulty survives full specification. Also checked against the machinery-absorbed row: the engine
here is a FACADE over per-projection node implementations (`isInside`, `__setLonLat__`,
`_setExtentBounds`, `isVisible` and `renderCollection` are all overridden), not a generic engine that
absorbs a new case, so `CAPABILITY-SHAPES § S-I`'s "alive" branch applies. Also checked against the
provenance/bookkeeping row: the product is a restructured spatial index under mutation, not a record
of who did what.

## 18. Traps reproduced on base (measured in this session, `npx vitest run`)

All three through the public route in section 9, at `61757db`, with `async: false`.

1. **`_nodePtr` is set on 0 of 3 entities** in a tree that never split (3 entities, `nodeCapacity`
   5). After `layer.removeEntity(e)` the node's entity collection correctly holds 2 while
   `root.count` stays 3 forever.
2. **`nodeCapacity` is armed only at bulk-build time.** 8 entities at `nodeCapacity` 4 built a root
   with 4 children of sizes 4/0/1/3; 60 further clustered `layer.add()` calls left the children
   untouched at 4/0/1/3 and put all 60 in the ROOT node's own entity collection (`root.count` 68,
   `root.entityCollection` 60). Because `collectRenderCollectionsPASS1` returns at the first node
   that owns a collection, one incremental insert into a split tree hides every child's entities.
3. **Nothing re-homes.** 12 entities at `nodeCapacity` 3 in the mercator tree; moving one past
   `mercator.MAX_LAT` (85.0511287798066) leaves the mercator tree at 12 and the north tree at 0.
   (FINISH scope; recorded here because it was measured at scope-lock.)

## Why this is not a duplicate

Closest approved neighbours: `planetiler-custommap-schema-composition` (Java, layered-input merge
with provenance) shares only the "ordered mutation under an invariant" flavour; the kernel, the
language and the observable are unrelated. `featurevisor-minimal-rebucketing` (TypeScript, range
allocation) is the nearest TS pick and is about traffic-allocation arithmetic, not a spatial index.
`problems/libspatialindex-tpr-temporal-knn` is the only other spatial-index pick anywhere in this
workspace and is about temporal QUERIES on a TPR-tree in C++, not about maintaining an index under
insert and remove.

## 19. Trap-proof: natural-but-wrong implementations, measured

Each mutation was applied to the finished reference and the new suite re-run (28 tests). Every one is
killed, and the kill sets are what the design predicted.

| Mutant | Kills | Which tests |
|---|---|---|
| M1 `_nodePtr` no longer assigned on leaf residency (the base gap, trap 1) | 24 | almost everything, because residency is the suite's backbone |
| M2 the split does not recurse into the children it just filled (trap 2) | 3 | `an_interior_node_holds_no_entities_of_its_own`, `a_clustered_run_splits_recursively`, `capacity_holds_after_many_inserts` |
| M3 redistribution asks the parent's mercator extent instead of the destination child (trap 3) | 2 | `north_tree_splits_past_capacity`, `equi_east_splits_past_capacity` -- exactly the two F-10 off-diagonal cells, and nothing else |
| M4 a split node keeps its own entity collection (trap 4a) | 8 | the split tests plus `splitting_releases_the_parent_collection` |
| M5 a collapsed node keeps its child nodes (trap 4b) | 5 | the collapse tests in all three trees |
| M6 the same-position guard removed | 1 | `entities_sharing_a_position_stay_in_one_leaf` (the un-mutated version hangs) |
| M7 removal decrements only the leaf | 8 | every counting and collapse test |

Note on M3: a weaker first version of this mutant that changed only the NW branch killed nothing,
because the other three branches still asked the child. The honest mutant changes all four. Worth
remembering when writing mutants for a dispatch chain.

**Predicted iteration cycles: 2** (one precheck round, one review round).
