# DESIGN.md - bayesopt-search-space-migration

Repo: bayesian-optimization/BayesianOptimization (Python, MIT, 8,714 stars), base
af8b928212f0eacd1ce20c20be72c1a7b1d8d421 (master HEAD, 2026-08-21). Hunt: REPO-HUNT-2026-09-23-E RANK 1.

## Phase 1 - Repo understanding

**Architecture (one paragraph).** `BayesianOptimization` (bayesian_optimization.py) owns a `TargetSpace`,
a sklearn `GaussianProcessRegressor`, an acquisition function, an optional domain transformer, a lazy
probe queue, a `ScreenLogger` and a `RandomState`. `TargetSpace` (target_space.py) turns typed
parameters (`FloatParameter`, `IntParameter`, `CategoricalParameter`, user `BayesParameter` subclasses,
parameter.py) into one float vector: each parameter owns a contiguous slice (`masks`), categoricals are
one-hot (`dim = len(categories)`), and every stored point (`_params`, `_target`, `_constraint_values`,
the duplicate cache `_cache` keyed on the encoded tuple) lives in that encoding. The GP kernel and the
constraint GPs are wrapped by `wrap_kernel(..., transform=space.kernel_transform)`, a BOUND METHOD of
the space object. Acquisition functions (acquisition.py) suggest encoded points; `ConstantLiar` keeps
pending encoded `dummies` and copies the space in `_copy_target_space`; `GPHedge` keeps
`previous_candidates` (one encoded point per base acquisition) and `gains`; both nest arbitrary
acquisitions. `SequentialDomainReductionTransformer` (domain_reduction.py) keeps ~12 per-dimension
arrays and rewrites bounds after every `maximize` iteration. Persistence: `save_state` ->
`_state_to_dict` (JSON) and `load_state` -> `_load_state_dict`, which re-registers the saved params
POSITIONALLY into whatever space the loading optimizer has.

**Five subsystems.** (1) parameter typing/encoding (parameter.py), (2) point store + encoding kernel
(target_space.py), (3) acquisition functions incl. meta ones (acquisition.py), (4) domain reduction
(domain_reduction.py), (5) optimizer orchestration + persistence + logging (bayesian_optimization.py,
logger.py). Constraint modelling (constraint.py) hangs off (2).

**High-entanglement zones.** (a) The encoding: masks/bounds/params/cache/constraint values/kernel
transform all derive from `_keys` + `_params_config`; (b) acquisition state stored in the encoding
(dummies, candidates) with no reference back to the space; (c) the save/load path, which serialises
encoded arrays and re-reads them by position.

**Tests.** pytest, `tests/test_*.py`, behavioural through the public API with fixed `random_state`.
Template: `tests/test_bayesian_optimization.py` (module-level `target_func`, `PBOUNDS`, plain
functions, `tmp_path` for save/load). 167 base tests (notebook test excluded) pass locally in ~140 s.

## Phase 2 - Existing-PR / publicly-solved check (2026-09-23, canonical org = same slug)

- `CANON=bayesian-optimization/BayesianOptimization` (no move).
- PRs, all states, by class: `set_bounds`, `add parameter`, `remove parameter`, `new parameter`,
  `search space`, `change bounds`, `load_state`, `warm start`, `categorical bounds`, `dimension`,
  `migrate`, `pbounds`, `extend`, `resume`, `change parameters`. Nearest hits read by DIFF: #607 (2 lines,
  a type hint), #609 (extract `_state_to_dict`/`_load_state_dict`, no space logic), #365 (temporary
  observations, closed 2022), #577 (acquisition validation). None touches space changes. 0 open PRs.
- Issues, same classes plus `bounds`, `previous results`, `transfer`: nothing asks for adding, removing
  or retyping parameters on a live optimizer. Read in full: #341 (remove observations; maintainer
  suggests returning bad values instead - about points, not the space), #337, #486 (bounds transformer
  after loading logs; maintainer: serialization "hasn't really kept step"), #376 (parameter types,
  implemented in #531), #89 (conditional params), #99.
- Philosophy scan hit worth recording: #446, t-muser: "the number of parameters needs to be constant"
  (answer to a variadic `*args` target function). It describes the current design, not a refusal of an
  explicit reconfiguration call. Recorded as a note (YELLOW-minus); the feature is phrased as an
  explicit reconfiguration that keeps the count constant between calls.
- Closed-with-implemented scan: nothing on space changes.
- Base..HEAD: base IS master HEAD (af8b928, fetched 2026-09-23). Check 5 empty.
- Capability check on base (worktrees/_bo_tools probes): `set_bounds({"z": ...})` silently ignores a new
  name; `set_bounds({"x": ["a","b"]})` raises the type-mismatch ValueError; there is no way to remove a
  parameter; `load_state` into a different space mis-assigns by position.
- Code search `set_space` in Python repos: no bayes_opt fork hit. Sibling libraries (Optuna, Ax) keep
  parameterisations as named dicts; nothing remaps an encoded GP optimizer's state. Not a textbook
  algorithm (TOO-EASY cross-repo row does not apply).
- Local dedup: no bayes_opt entry in approved-problems/, problems/, rejected/, diamond-problems/,
  SATURATED-REPOS.md, TOO-EASY.md. Quota: 0 of 6 ours. Global count OWED (5000+ star penalty band).

## Phase 3 - Candidates (lane fixed by the hunt; variants scored)

| Candidate | One-line behaviour | Shape | Files | Raw | Meaningful | Pred. | Verdict |
|---|---|---|---|---|---|---|---|
| A. `set_space` + full state migration (obs, queue, acquisition state, reducer, load) | carry everything through add/remove/retype/category changes | O-Composite-add | 4 | ~520 | ~300 | 15-30% | **PICK** |
| B. only observations (`TargetSpace.set_space`) | remap points + cache | C | 1 | ~150 | ~90 | 60%+ | under floor, single subsystem (Guard #2) |
| C. load a saved run into a different space only | name-based load migration | A1 | 2 | ~180 | ~110 | 50% | under floor, one path |
| D. extend `set_bounds` to add/retype | partial-mapping semantics clash with removal | D-change | 2 | ~200 | ~120 | - | incoherent (partial map cannot remove) |
| E. reducer-aware bounds reset | reducer only | C | 1 | ~80 | ~50 | - | dead (under floor) |

Step A (TOO-EASY guard) on A: (1) not one guard - the encoding kernel is shared, but the reducer state,
the cache/collision policy, the acquisition tree and the load path each need their own logic; (2)
cross-module (4 files, 4 subsystems); (3) every trap below survives full statement (stating "a
categorical takes a value equal to a category" does not say the repo helper zero-encodes unknown
values; stating atomicity does not say the reducer's own check fires late); (4) not a port; (5) yes.
Globally coupled: one encoding feeds six holders and a local fix to the space leaves stale-width
holders that fail later in unrelated calls. Step B arsenal: lead S4 (machinery-riding: "everything the
optimizer already holds keeps working"), S1-flavoured atomicity (speculative change must not leak),
A9/F-39 inherited-helper edges. Absorption check ("solve with existing primitives"): rebuilding a
fresh space and re-registering `res` covers ~40% (points, cache, constraints) in ~25 lines, and misses
the queue, the acquisition tree, the reducer, the load path, the kernel-transform binding and the
zero-encoded removed categories - the LOC lives in those.

## 1. Title
Add search-space changes with state migration to BayesianOptimization

## 2. Shape classification
- Shape: O-Composite-add (new capability threaded through space, acquisition, reducer, persistence).
- Pass-rate target: <= 40% ceiling; design aims 15-30% (Orion-only availability, L65).
- Best agent: Orion (long-horizon); Nova thoroughness misses expected.
- Dominant verdict: MISSED_REQUIREMENT (silent wrong state) + INTEGRATION_ERROR (stale widths).

## 3. Public API surface
- `BayesianOptimization.set_space(pbounds, fill=None) -> None` - replace the space, migrate state.
- `BayesianOptimization.load_state(path, fill=None) -> None` - existing method, new keyword (FINISH).
- `BayesianOptimization.save_state(path)` - unchanged signature, file also describes the space (FINISH).
- Observed through existing API only: `space.keys`, `space.bounds`, `space.params`, `space.target`,
  `res`, `max`, `probe`, `suggest`, `maximize`, `register`, `acquisition_function.dummies`,
  `GPHedge.previous_candidates` / `gains`, reducer attributes, `space.array_to_params`.
- Errors: `ValueError` for every change that cannot be made.

## 4. Canonical output form
- Parameter order: the order of `pbounds`.
- Points: carried by VALUE (what `res` reports), re-encoded in the new space; kept order = registration
  order minus dropped points.
- Dedup: points that coincide after a removal keep the EARLIEST registered one when duplicates are not
  allowed; with duplicates allowed all are kept.
- Numeric conversion: float takes any number; int rounds the way `IntParameter.to_param` rounds
  (`np.round`); tests never use a .5 tie. Categorical: a value equal to one of its categories.
- Out-of-bounds numeric values are kept (as `set_bounds` keeps them) and simply do not count for `max`.
- Empty optimizer: `set_space` works, fill still required for added names.

## 5. Blind-spot pre-empts
- Result ordering: "its order becomes the parameter order".
- Dedup: "only the earliest registered one survives".
- Parallel API: `load_state` migrates "under the same rules" (FINISH).
- Falsy-on-invalid: "raises ValueError and the optimizer is left exactly as it was".

## 6. Description draft
See meta.md (slice version). The FINISH version adds the reducer and save/load paragraphs (drafted in
section 15).

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful | Reason |
|---|---|---|---|---|---|
| MODIFY | bayes_opt/target_space.py | 714 | +150 | ~95 | value conversion, point carrying, migrated-space build, commit |
| MODIFY | bayes_opt/bayesian_optimization.py | 524 | +150 | ~85 | `set_space` orchestration + queue; save/load description + migration (FINISH) |
| MODIFY | bayes_opt/acquisition.py | 1360 | +70 | ~45 | remap hooks on base/ConstantLiar/GPHedge (nesting); `_copy_target_space` fix (FINISH) |
| MODIFY | bayes_opt/domain_reduction.py | 295 | +90 | ~60 | per-dimension state migration, named minimum windows (FINISH) |
| MODIFY | bayes_opt/parameter.py | 509 | +30 | ~20 | per-type value conversion |
TOTAL: ~490 raw / ~300 meaningful across 5 files. Slice: target_space + bayesian_optimization +
acquisition + parameter (~170 meaningful).

## 8. Solution outline
- `BayesParameter.convert(value)` (per type; float/int numeric, categorical by equality; custom
  parameters keep their encoding) -> the value, or raises ValueError.
- `TargetSpace._migrated(pbounds, fill)` -> a new TargetSpace holding carried params/targets/constraint
  values/cache; validates fill; no mutation of self.
- `TargetSpace._carry_from(old_space, x, fill)` -> encoded point or None (dropped).
- `TargetSpace._adopt(other)` -> in-place commit (keeps the object so the bound `kernel_transform` in the
  GP and constraint kernels stays valid).
- `AcquisitionFunction._plan_remap(carry)` -> commit callback; ConstantLiar/GPHedge override and recurse.
- `SequentialDomainReductionTransformer._plan_migration(old, new)` -> commit callback (FINISH).
- `BayesianOptimization.set_space`: plan every holder (space, queue, acquisition tree, reducer), then
  commit all; any ValueError before commit leaves everything untouched.
- Load (FINISH): read the saved space description, rebuild the saved space, carry observations and
  acquisition state into the current one with the same carry function; legacy files keep today's path.

## 9. Test file outline
`tests/test_search_space_<hex>.py`. Block 1 imports; block 2 builders (`make_optimizer`, `register_all`,
`values_of(res)`); block 3 assertions (`assert_res_values`); block 4 tests by bucket: carry rules
(add/remove/retype/categories/out-of-bounds/collisions), fill validation + atomicity, holders (cache,
constraints, queue, ConstantLiar, GPHedge, nested), continuing (suggest/maximize/probe after a change),
FINISH buckets: reducer, save/load.

## 10. Forced shapes
`set_space(pbounds, fill=None)` keyword name `fill` (mapping). `load_state(path, fill=None)`. Both named
in meta with the full call shape (L72).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Meta sentence | Test |
|---|---|---|---|---|---|---|---|---|
| 1 | `CategoricalParameter.to_float` zero-encodes a value that is not a category; re-registering keeps the point as `categories[0]` | F-39 | A3 | encoding kernel | 2, 5 | reusing `params_to_array`/`register` is idiomatic and never raises | "a point with a value its new parameter cannot take is dropped" | removed category drops its points |
| 2 | categories reordered at the same width: raw slice copy for an unchanged-type parameter | F-10 | S2 | encoding kernel | 1 | same type + same dim looks unchanged | "a categorical parameter takes a value equal to one of its categories" | reorder keeps res values |
| 3 | late failure in another module (reducer all-float check, window fit) after the space already mutated | new (S1-like) | S1/P2 | atomicity | 6 | validation lives in `initialize` | "raises ValueError and the optimizer is left exactly as it was" | reducer + categorical add |
| 4 | reducer converts a named minimum window to a list at `initialize` (the name is discarded) | F-47 | L83 | reducer state | 6 | re-initialize or slice the list | "applies a minimum window given by name to an added parameter too" | named window on added param (FINISH) |
| 5 | load path migrates points but restores acquisition state / transformed bounds positionally | F-9 | S6 | persistence | 1, 2 | live path and load path written separately | "migrating the saved points, acquisition state and reduced bounds by parameter name" | ConstantLiar dummy after load into reordered space (FINISH) |
| 6 | reducer re-initialised instead of continued | F-34-like | S4 | reducer state | 3, 4 | `initialize(space)` is the obvious call | "keeps contracting kept parameters from where it was" | deep-copy oracle (FINISH) |
| 7 | nested acquisitions: remap only the top-level ConstantLiar/GPHedge | F-43-like | A3 | acquisition tree | 1, 2 | isinstance chain without recursion | "however acquisition functions are nested" | ConstantLiar(GPHedge) |
| 8 | `ConstantLiar._copy_target_space` zips keys with per-dimension bounds (base bug, acquisition.py:1026) | F-39 | A3 | acquisition x types | 7 | reached once a migration adds a categorical under ConstantLiar | "every acquisition function must keep suggesting in the new space whatever parameter types it has" | ConstantLiar after adding a categorical (FINISH) |
| 9 | replacing `self._space` leaves the GP and constraint kernels wrapping the OLD bound `kernel_transform` | F-9 | S4 | object identity | 3 | rebuilding is the easy escape | (none needed: "keep suggesting") | constrained suggest after change |

Axes differ per row except 1/2 (kernel) which are deliberately a pair (value path vs slice path).
Interdependence: 1/2/5 share the carry kernel; 3/4/6 share the reducer migration; 7/8 share the
acquisition tree.

## 11b. Capability cross-product (F-10)

| | observations/cache | queue | ConstantLiar | GPHedge | nested | reducer | load |
|---|---|---|---|---|---|---|---|
| add param | slice | slice | slice | slice | FINISH | FINISH | FINISH |
| remove param | slice (+collision) | slice | slice | - | slice | FINISH | FINISH |
| retype | slice | - | - | slice | - | FINISH (error) | FINISH |
| category removed | slice (drop) | slice (drop) | slice (drop) | - | - | - | FINISH |
| category reordered | slice | - | FINISH | - | - | - | FINISH |
| failure (atomic) | slice | slice | slice | - | - | FINISH | FINISH |

Scope audit: "points" = observations AND queued probes AND pending ConstantLiar points, stated together.
Format-noun audit: "point" = one encoded vector + its target + constraint value + cache entry.
Tolerance audit: n/a. Example audit: no examples in meta.

## 12. Tier + category
Olympus, feature-request ("Add").

## 13. Predicted pass rate
15-30% for the FINISH artifact. Reasoning: 5 silent traps (1, 2, 4, 6, 7) + 3 late-surfacing ones
(3, 5, 8) on different axes; each ~20-40% miss for a strong agent.

## 14. Quality-gate checklist
- [x] Phase 1 5/5; [x] Phase 2 0 hits (commands above); [x] approved analogue: sfepy (state rollback),
  ir-sim (runtime objects as ordinary members), libspatialindex (discarded state).
- [x] Title verb-led; [x] shape; [x] API names listed; [x] canonical form; [x] 0-1 codebase-inferable
  (int rounding style).
- [x] LOC sketch >= 200 meaningful (~300) across 5 files.
- [x] Every trap names an F-id; axes differ; interdependence present; F-10 matrix filled.
- [x] Stage-placement (L57): no new stage; [x] Float audit (L59): res values compared with tolerance where
  arithmetic is involved, exact for carried values (no arithmetic).
- [x] Sibling-API audit (F-20): `set_bounds` base behaviour is covered by base tests (not a free seam);
  kept in base mode.
- [x] Absent-key audit (F-24): fill for a missing name raises (stated).
- [x] Enumeration audit (L81): the only list is the holder examples ("pending `ConstantLiar` points,
  `GPHedge` candidates"), complete for built-in acquisitions that hold points.
- [x] Host-semantics audit (L80): conversions use plain equality/rounding, no host semantics promised.
- [x] Representation-pin sweep (L48/L49): tests compare decoded VALUES (`res`, `array_to_params`),
  never raw encodings of int/categorical dims.
- [x] In-process validation (L56).
- [x] Cold build < 600 s: pip wheels only.

## 15. Deferred to FINISH (differentiating scope, NOT in the slice)
- Domain reducer migration (traps 3, 4, 6): kept dimensions keep `previous/current_optimal`, `r`, `d`,
  `c`, `gamma`, `contraction_rate`; added ones start as `initialize` would (`r = eta * width`); global
  bounds = new bounds; named minimum windows from the ORIGINAL mapping; all-float and window-fit checks
  BEFORE any commit.
- (moved into the slice) `ConstantLiar._copy_target_space` categorical fix (trap 8) + test.
- save/load: faithful space description; `load_state(path, fill=None)` migration of points, acquisition
  state and transformed bounds by name (trap 5); legacy files load as today (golden legacy JSON test).
- Category reorder x ConstantLiar/load cells; nested GPHedge(ConstantLiar) cell.
- Draft FINISH meta paragraphs:
  "A `SequentialDomainReductionTransformer` keeps contracting kept parameters from where it was, treats
  the new bounds as the global bounds, starts added parameters as if it had just been set up, and applies
  a minimum window given by name to an added parameter too."
  "`save_state` also records the space itself, and `load_state(path, fill=None)` loads a saved run into
  an optimizer whose space differs, migrating the saved points, acquisition state and reduced bounds by
  parameter name under the same rules, with `fill` supplying parameters the file does not have. Files
  written before this change still load as they do today."

## Why this is not a duplicate
Closest approved: sfepy-adaptive-stepping-accounting (state rollback in a solver family) and
ir-sim-scenario-events (runtime objects as ordinary members) - different repos, different capability.
No approved or rejected bayes_opt work. The capability name cannot be written without repo nouns
(encoded one-hot space, ConstantLiar dummies, GPHedge candidates, domain reducer state).

Predicted iteration cycles: 3.

## Phase 5 - Failure-mode self-audit
- Bucket 1 hidden requirements: every slice test maps to a meta sentence (checked in feedback.md).
- Bucket 2 tone: plain prose.
- Bucket 3 base-passing tests: every new test calls `set_space` (absent on base) -> AttributeError.
- Bucket 4 over-constraint: values compared, not encodings.
- Bucket 5 LOC: slice under floor by design; FINISH carries ~300.
- Revert causes: no comments beyond repo docstring convention (ruff D rules require public docstrings).
- Blind spots: default ordering stated; dedup stated; parallel API (load) stated in FINISH.
