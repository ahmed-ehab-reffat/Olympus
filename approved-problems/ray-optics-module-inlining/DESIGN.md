# DESIGN.md — ray-optics-module-inlining

Repo ricktu288/ray-optics (Apache-2.0, 1788 stars, JS), base `daf76772` (HEAD 2026-10-05).
Lane from hunt #56 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-10-05-H.md`, lane M+R).

## Phase 1 — repo understanding

**Architecture (one paragraph).** A `Scene` (src/core/Scene.js) owns a flat list of scene objects
(`scene.objs`) and a map of module definitions (`scene.modules`). A module definition is plain JSON:
`numPoints`, `params` (range specs `name=start:step:end[:default]`), `vars` (math.js assignments and
function definitions evaluated in order), `objs` (rows of object JSON whose string values are templates:
single-backtick blocks are evaluated by math.js, double-backtick blocks become LaTeX equations with the
scope substituted), plus `maxLoopLength`. A `ModuleObj` (src/core/sceneObjs/special/ModuleObj.js) is an
instance: control points + parameter values; `expandObjs()` builds the scope (params, `x_k`/`y_k`,
`random`, vars), expands each row (`for` ranges evaluated in the outer scope, `if` per iteration) and
constructs real scene objects, including nested `ModuleObj` instances for rows of other modules. The
simulators (legacy `Simulator`, primitive engines) read `scene.opticalObjs`, which flattens instances
recursively. The Vue app edits modules through `ModuleEditor.vue` / `ModuleTools.vue` and the Pinia
store, all of which call the Scene methods.

**Subsystems.** (1) Scene model and module registry (Scene.js); (2) module expansion / template
evaluation (ModuleObj.js + math.js); (3) scene objects (sceneObjs/*, incl. custom surfaces whose
equations are LaTeX evaluated by `equation.js`/evaluatex); (4) simulation engines; (5) the Vue app
(sidebar module editor, toolbar, store).

**High-entanglement zones.** (a) `ModuleObj.expandArray`/`expandString`/`expandEquation`: three
evaluation paths with different scoping rules; (b) Scene module bookkeeping (`removeModule`,
`renameModule`, `moveObjsToModule`, `moveModuleObjsToScene`, `getModuleObjRefsById`, `reloadAllModules`)
which every UI action reaches; (c) custom-surface equation strings shared by template expansion and
the simulators.

**Tests.** jest (babel), `test/{formula,primitive,propertyUtils,sceneObjs}`, plus a scene-render
script. Template for a Scene-level test: `test/sceneObjs/Simulator.test.js` (`new Scene()`, Scene API,
i18next mocked by `test/sceneObjs/helpers/setupTests.js`).

## Phase 2 — existing-PR / publicly-solved check (2026-10-05)

`CANON=ricktu288/ray-optics` (no move). PR search (all states): "inline module", "nested module",
"remove module", "removeModule", "rename parameter", "module parameter", "demodulize", "module",
"inline", "parameter rename", "template": 0 lane hits (only #202 ConcaveDiffractionGrating, unrelated).
Issues: "module" -> #187, #259, #337 (backward loop ranges, open, uncommented), #329 (sidebar LaTeX
conversion), others unrelated. Discussions: #145 "Introducing the module feature" (2024), nothing on
inlining or param renaming. Branches: master, dist-integrations, gh-pages, patch/5.2, patch/5.3 (release
branches). `git log --grep` for inline/nested/rename-param: only 87876d3f (control-point drawing). No
removed capability. PR/issue authors vs `worktrees/_hunt/sig_accounts.txt` (incl. SahilRajputdotexe,
AHMETHAKANBEZIR1): 0 hits. Base..HEAD: base is HEAD. Capability check on base: removing a module nested
in another leaves the parent pointing at a deleted module (`unknownModule` error, the nested objects
vanish); there is no core parameter rename (the editor only rekeys instance values, so the templates
keep the old name).

## Phase 3 — candidate and guards

Candidate (the hunted lane, M+R): template-level inlining of nested module instances (on
`removeModule` and on demand) plus template-aware parameter rename, both under one expansion-preserving
law. Other lanes in this repo are dead per hunt #56 and `SATURATED-REPOS.md § B2-RAYOPTICS`.

Death-class guard: not a uniform wrap (one rewrite kernel, but each of its seams is a different repo
semantic); single-subsystem transform risk is the main one (kysely class) — answered by the hidden walls
being repo/evaluator semantics the law does not disclose (math.js transform recursion, dynamic function
scope, outer-scope loop ranges, loop budget, two equation paths). Not a famous language feature in this
repo's lane sense; "hygienic inlining" is textbook, so the difficulty must come from the repo's
evaluator, not from knowing capture-avoidance. Measure-first spike written before this document:
**299 human-effective** (hook, 2 files) vs hunter's 212 sketch; floor 200 cleared.

Arsenal: P1 algebraic-law contract (expansion preserved) as the lead, S2 compositions (capture x loops x
functions), A4 host-library semantics (math.js `transform` continues into a returned node; function
bodies see the definition scope), F-10 cross-product cells, F-49-style three-level fixture.

## 1. Title
Inline nested module instances and rename module parameters

## 2. Shape
O-Composite-add (new capability over the module registry + template engine). Category feature-request.

## 3. Public API
- `scene.removeModule(name) -> boolean` — top-level instances demodulized as today; instances inside other
  definitions inlined; false and no change when refused.
- `scene.inlineModuleInstance(moduleName, index) -> boolean` — inline one instance row of a definition,
  keep the inlined module.
- `scene.renameModuleParam(moduleName, oldName, newName) -> boolean` — rename a parameter everywhere the
  definition uses it and in every instance that sets it.

## 4. Canonical form / law
After a successful call every instance in the scene expands to the same objects (multiset; equations
compared by value), the scene has no error. Refusal returns false and leaves `scene.modules` and
`scene.objs` unchanged.

## 5. Blind-spot pre-empts
Order: "though not necessarily in the same order" (loops make interleaving impossible).
Refusal list stated as closed. Domain caps stated in one sentence (no `random`, no reassignment, no
loop variable reusing a defined name, all-or-none parameters, numbers or single-backtick values).

## 6. Description draft — see meta.md (draft, ~230 words).

## 7. File footprint (measured spike)
| Action | Path | human-eff |
|---|---|---|
| NEW | src/core/moduleRewriting.js | 235 |
| MODIFY | src/core/Scene.js | 64 |
Total 299 human-effective, 2 files.

## 8. Solution outline
Kernel (moduleRewriting.js): `mapTemplate` (single/double-backtick blocks exactly as `expandString`
splits them), `mapRow` (`for` bounds in the outer scope, `if` and values in the row scope), name
collection (`namesUsedIn`, `definedNames`, `freeNamesOf`), `substitute` (simultaneous substitution with
function-call inlining, formals bound to wrapped args, bodies resolved in the module's final scope),
`bindInstance` (points, params or defaults, vars in order), fresh loop names, `inlineRows` (merge loops,
conjoin `if`, refusal checks, loop-limit need), `renameParamInDef` (formals shadow, loop variables
shadow, validity and collision checks). Scene.js: atomic plan-then-apply in `removeModule`,
`inlineModuleInstance`, `renameModuleParam` (rekey via `getModuleObjRefsById`).

## 9. Test outline
`test/sceneObjs/moduleRewriting-2450fd.test.js`. Helpers: `load(json)`, `expansion(scene)` (flatten
instances, serialize, custom-surface equations replaced by `initOutRayFns` values at fixed variables,
numbers to 10 significant digits, sorted), `expectPreserved(json, op)`. Buckets: removal (real
CoatedLens data, top-level + nested, capture/swap, function bodies, loops + if, negative literals,
defaults, loop budget, three levels), refusals (dependent range, free-name capture, atomicity), explicit
inline, rename (real data, formals, vars, nested instance values, rekey, refusals), cross cells (rename
then remove; remove with several parents).

## 10. Forced bounds
none (JS). Return types are booleans; stated.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Pre-empt | Test |
|---|---|---|---|---|---|---|---|
| 1 | child names captured by parent names / sequential substitution (CoatedLens d,A,B; swap a:=b,b:=a) | candidate (S2) | S2 | binding hygiene | 2, 4 (one substitution kernel) | law sentence | coated lens, swap |
| 2 | function bodies keep child params; copying `expandEquation`'s numeric-only body substitution or hoisting functions into the parent captures the parent's names | F-20 family (sibling copy) | S2/A4 | function scope | 1 | law sentence | coated lens equations, single-backtick function rows |
| 3 | negative literal substituted without parentheses (`-5 ^ 2`) | candidate (A4) | A4 | precedence | 1 | law | negative point/param |
| 4 | child loop variable collides with parent names; merged `for` + `if` | F-10 | S2 | loop scope | 1, 5 | law | loop cells |
| 5 | merged loops exceed `maxLoopLength` | F-25 family (budget) | S4 | loop budget | 4 | law | 40 x 30 loops |
| 6 | dependent range / free-name capture must refuse atomically | F-10 refusal cell | A8 | refusal | 1 | stated rule | refusal tests |
| 7 | rename: math.js `transform` keeps descending into a returned node, so a formal that shadows the param gets renamed | candidate (A4 host library) | A4 | shadowing | 1 (same kernel) | none needed (law) | formal shadow test |
| 8 | rename rekeys instance rows inside OTHER definitions, not only scene instances | F-9 origin / F-3 | S3 | two holders | — | stated ("every instance that sets it") | nested rekey test |
| 9 | three-level nesting (remove the middle module) | F-49 depth | S2 | depth | 1,4 | law | three-level test |

## 11b. Cross-product matrix
| | single row | looping row (parent for) |
|---|---|---|
| child row plain | base cell | parent-loop cell |
| child row looping | child-loop cell | merged loops + budget (off-diagonal) |
Second matrix: operation (remove, inline, rename) x holder (scene instance, instance inside another
definition): every off-diagonal has a test (rename rekey in a definition row; remove with a top-level
instance and a nested one).

## 12. Tier/category
Olympus, feature-request ("Add/Inline" verb → title "Inline ...", category feature-request).

## 13. Predicted pass rate
20-40%. Hygienic substitution is a known technique; the band has to come from traps 2, 3, 5, 7 and the
cross cells. Risk of too-easy if agents test against the real expansion engine (they will: the law is
directly checkable with `expandObjs`). Mitigation in FINISH: seeded random corpus of module pairs
compared before/after (Pattern 99), which no agent self-test covers.

## 14. Quality gates
Repo understanding 5/5; Phase 2 clean; closest approved: ray-optics-formula-conditionals (math.js
template engine knowledge, disjoint files); title verb-led; API listed; law + order stated; caps stated;
footprint measured (299); traps on different axes; interdependence through the shared kernel; F-10
matrix filled; no unobservable frequency; enumeration audit (refusal list closed and complete).

## Why this is not a duplicate
ray-optics-formula-conditionals edits `src/core/formula/*` (a new node family in the formula DAG);
ray-optics-sp-coherence-transport edits the primitive engines and adds scene objects (Scene.js only for
theme colours). This lane edits the module registry and adds a template rewriter; no shared capability.

Predicted iteration cycles: 2.
