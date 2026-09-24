# feedback.md - bayesopt-search-space-migration

NEXT (human): round-7 artifact (tests + meta changed 2026-09-24; solution unchanged since round 6) needs prechecks, then a FULL batch.

Repo: bayesian-optimization/BayesianOptimization (MIT, 8,714 stars), base af8b928 (master HEAD 2026-08-21).
Hunt: Instructions/repo-hunt-logs/REPO-HUNT-2026-09-23-E.md (RANK 1). Mode: factory SLICE.

## Status
- 2026-09-23: folder created, clone at worktrees/BayesianOptimization (full history, base = master HEAD).
- Base suite local venv (worktrees/_bo_tools/venv: numpy 2.3.3, scipy 1.16.2, sklearn 1.7.2): 167 passed, 142 s.
- Gates run (DESIGN.md Phase 2): PICK-FILTER 1/5/6/7b/8, SIX-CHECK, canonical-org PR-DIFF: clean.
  One note: #446 maintainer "the number of parameters needs to be constant" (about variadic targets).
- FORK-BRANCH EXCLUSIVITY SCAN (coordinator gate, 2026-09-23): CLEAN.
  1,587 forks listed (gh api forks?sort=newest, paginated; worktrees/_bo_tools/forks.tsv). 201 received
  pushes after forking; every branch of all 201 compared against upstream master (compare API, 113 +
  ~150 branch rows in branch_scan*.tsv). Branches touching target_space/acquisition/bayesian_optimization/
  domain_reduction/parameter were read by DIFF or commit list: t-muser feature-scaling (uniform feature
  scaling), t-muser parameter-types-pinned (the typed-parameter work that became #531), MerlinK75 TAF
  (population models), jacktang feature-scaling (+ HD examples), udicaprio (DE minimiser), quuger (the
  #607/#609 branches), cballam convergence criteria, MandaKausthubh SAASBO, PepeRoConde alpha arg,
  heartfelt-tech/jmehault 2019 ptypes + set_bounds rounding, JammyL transferData (multi-source data),
  Zongshun96 remove observations, joswinkj/tzoiker fixed args. None adds, removes or retypes parameters
  on a live optimizer or migrates state. No LabTesing/deepswe fork, no blitzy fork, no fork owner in
  worktrees/_hunt/sig_accounts.txt (+ o_0920d, m_0920c lists) or adx-labtesing-deepswe-forks.txt.
- DESIGN.md written (slice = observations/cache/constraints/queue/ConstantLiar/GPHedge; FINISH =
  reducer, save/load migration). Reference slice built in worktrees/BayesianOptimization:
  parameter.py (convert/contains per type), target_space.py (_migrated kernel + _adopt in place),
  acquisition.py (_plan_space_change on base/ConstantLiar/GPHedge, recursive; _copy_target_space
  categorical fix pulled into the slice), bayesian_optimization.py (set_space: plan all, then commit).
- Tests: tests/test_search_space_092a65.py, 21 functions / 29 cases, all pass on the reference; base suite
  167/167 with the reference applied (host venv). ruff check + format clean (ruff 0.15.6).
- Hook: human-effective 140 (raw 256, 4 files) - under floor BY DESIGN for the slice; FINISH adds reducer
  + load migration (+ ~120-140 eff) to reach >= 250.
- meta.md draft (slice scope, 381 words, ASCII, one line per paragraph). Patches generated
  (test.sh mode 100755).
- Dockerfile: olympus-base-python (py 3.12.13) + pinned numpy 2.3.3 / scipy 1.16.2 / scikit-learn 1.7.2 /
  colorama 0.4.6 / packaging 25.0 / pytest 9.1.1, editable install, COPY --chown + chmod -R a+rwX (small tree).
  Cold --no-cache build ~95 s (pip layer 61 s).
- Slice mutants (host, worktrees/_bo_tools/mutate.py, each asserted to land): 12 run; M9 was an equivalent
  mutant; first pass M4 (cache not adopted), M10 (int not rounded), M12 (constraint values sliced) survived
  on fixture coincidences -> fixtures changed + new test (values that round together) -> all 11 real mutants killed.
  meta.md: the coincidence sentence generalised from "removing parameters" to "the change" (rounding too).
- Final slice: 22 test functions / 30 cases. Docker clean room (--network none; uid 0, 1000, unmapped 4242;
  pristine clone at BASE, patches applied inside, hunks asserted): base-on-base 167/0, new-on-base 30/30 fail
  (all AttributeError set_space), base-on-solution 167/0, new-on-solution 30/0. Per-test verdict lists identical
  across 3 runs in all four cells. No duplicate or "::" JUnit ids. Patches apply in both orders and reverse cleanly.
- Image factory-bayesopt-search-space-migration removed at the end of the SLICE run (rebuild ~95 s).

## FINISH owes
- Domain reducer migration + named minimum windows + late-failure atomicity (DESIGN sec 15, traps 3/4/6).
- save_state space description + load_state(path, fill=None) migration + golden legacy-file test (trap 5).
- Category-reorder x ConstantLiar / load cells; LOC to >= 250 human-effective (slice 140).
- Full flakiness 3x after FINISH, FP mutation sweep incl. base mode (L33).

## Decisions taken unattended (conservative choices)
- #446 read as a design note, not a refusal (the feature is an explicit reconfiguration call). Recorded, not a kill.
- Slice scope limited to the carry kernel + point holders; reducer and load deferred (DESIGN sec 15).
- ConstantLiar._copy_target_space categorical fix pulled INTO the slice (small, and meta states every
  acquisition function keeps suggesting whatever the parameter types).
- `fill` must also be within bounds for numeric parameters and may not name non-added parameters (stated).

## Attempt history

## Precheck round 1 (2026-09-24)
- "Problem and tests are good quality": FAILED on item 3 (tests read internals). Flagged: optimizer.space.keys/bounds/params/target/dim,
  len(optimizer.space), optimizer._queue, liar.dummies, hedge.previous_candidates/gains, optimizer._gp.predict gain formula,
  and the out-of-bounds-not-counted-for-max assertion (not stated in meta).
- "Description only necessary info": warnings (HIGH: drop "the ones res reports"; MEDIUM: drop "written exactly as for the constructor"; LOWs).
- Fix, tests (public API only: register / probe / maximize / suggest / res / max / set_space):
  - snapshot/assert_unchanged replaced by a TWIN: an optimizer whose set_space failed must drain its queue (maximize n_iter=0) and
    then suggest exactly what an untouched twin suggests, 3 rounds.
  - Acquisition state (ConstantLiar, GPHedge, ConstantLiar(GPHedge)): undo-twin tests. Add a parameter then remove it, or move bounds
    then move them back, and the optimizer must match an untouched twin's res and next 3 suggestions exactly. Integer retype round trip
    rejected: raw acquisition candidates (n=0.83) come back rounded, legitimately lossy.
  - GPHedge fixture: 1 pre-change suggestion + targets x10, seed 1, UCB/EI. With 2 suggestions or unit-scale targets the softmax is
    shift-invariant and both bases propose near-identical points, so dropping candidates never changed a pick (M7 survived). Seed search
    confirmed seed 1 diverges at round 0 for plain and nested.
  - Order via res params dict order + suggestion key order; dim/len checks replaced by res/suggest; duplicate check via
    probe(lazy=False) + call counting of f and of the constraint function (no space.probe return values).
  - Cases: 24 functions / 34 cases.
- Fix, meta.md: took HIGH + MEDIUM trims; added "as there they do not count for max"; duplicate check now "does not evaluate it again";
  "including nested acquisition functions"; new undo sentence (add-then-remove, bounds-and-back leave results and further suggestions
  unchanged) which the twin tests need to be fair. Kept the rounding example and "whatever parameter types" (they back tests). 388 words.
- Mutants (17): 14 killed incl. M7 hedge-clear (survived before the fixture change), M13 liar-drop-all, M15 queue-cleared-before-validate,
  M16 cache-lost. Survivors: M9 (equivalent), M14 gains-reset (equivalent at 1 pre-change suggestion; gains not named in meta),
  M17 hedge-no-recurse (equivalent: GPHedge children are stateless in the fixtures).
- solution.patch unchanged. ruff check + format clean.

## Precheck round 2 (2026-09-24) - Solution Quality FAIL (Comprehensiveness 1/3, Code Quality 3/3)
- Issue 1: carried ConstantLiar pending points that coincide (removed param, or floats rounding to one int) were both kept;
  next suggest registered both into the copied space -> NotUniqueError. Fix: ConstantLiar._plan_space_change dedups carried
  points in order when duplicates are disallowed (planner now receives the new TargetSpace). Test: seed 2, pending y 7.03/7.03,
  set_space({"y": (0, 10, int)}), 3 more suggestions, both duplicate settings.
- Issue 2: SequentialDomainReductionTransformer not migrated -> broadcasting ValueError at the next maximize after the optimizer
  already mutated. Fix (the FINISH reducer scope, pulled in): DomainTransformer._plan_space_change default = deepcopy +
  initialize(new space), commit copies state. SDRT override: plan on a copy re-initialized on the new space (runs the all-float and
  window-fit checks BEFORE commit), copy kept columns (optimal/r/d/c/c_hat/gamma/contraction_rate) by name, kept parameters keep their
  current reduced window trimmed by _trim to the new global bounds, added ones start fresh, named minimum windows looked up by name
  (initialize no longer overwrites the mapping with a positional list). Commit sets the trimmed window on the space.
- Coverage advisories taken: constrained drop test, PI/EI after an integer retype/add, non-fill atomic failures (transformer rejects).
- Reducer tests use a bowl objective (optimum 0.3). With the linear scaled_sum the suggestion sat in the corner whatever the window,
  so R3/R4/R5 survived; with the bowl all 8 reducer mutants die. Twins: added-param start == optimizer built in the new space;
  removed-param == optimizer built without it; add-then-remove after 4 reduced iterations == untouched twin (named + scalar windows);
  5 rejects (categorical, int, window wider than bounds, param missing from named windows, scalar window wider) == untouched twin;
  narrowed x keeps later suggestions inside the new bounds.
- meta.md: new transformer paragraph; undo sentence now scoped ("moving bounds and back when no bounds transformer is set", since
  narrowing trims the reduced window for good); "today" sentence cut to fit. 483 words.
- Mutants: R1 no migration, R2 plain reinit, R3 window not kept, R4 kept state not copied, R5 window from new bounds, R6 positional
  windows, R7 initialize after adopt, R8 liar no dedup, R10 window not trimmed: all KILLED. R9 (dedup even when duplicates allowed)
  survives: not observable through suggestions; not stated beyond "all are kept".
- Tests 49 cases. Host full suite with solution: 216 passed. Hook: human-effective 218, raw 343, 5 files.

## Precheck round 3 (2026-09-24) - Solution Quality FAIL (Comprehensiveness 1/3, Code Quality 2/3)
- Issue 1 (high): GPHedge kept previous_candidates only if ALL carried; one dropped sibling threw away the valid ones and skipped
  the gain update. Fix: candidates stay aligned with base acquisitions; a dropped one becomes a NaN row; _update_gains scores only
  non-NaN rows (reshape(n_acq, -1) so the repo's 1-D mock tests still pass); all rows dropped -> None. JSON save/load keeps NaN
  (checked: reloaded optimizer suggests the same point).
- Issue 2 (medium, code quality): SDRT bounds history ragged after a dimension change. Fix: every past window re-keyed by name
  (removed rows dropped, added rows = new global bounds) before appending the migrated window. No test (history is internal state).
- Test for issue 1: offset twins. GPHedge's gain = sum of predicted targets at its candidates, pick = softmax(gains). Twins whose
  targets differ only by +/-1000 pick the same acquisition when all candidates carry (offset cancels) and different ones when exactly
  one carries (offset lands on one gain). Removing "a" and removing "b" (seed 1: candidates a, b) -> picks differ; reordering
  categories -> same pick (control). The all-or-nothing reference fails both partial cases, passes the control.
- Coverage advisories taken: integer fill out of bounds + non-numeric; float rounded to an integer outside the new integer bounds is
  kept but excluded from max; queued probes that coincide under both duplicate settings (call counting + res).
- Tests 57 cases. Host full suite with solution: 224 passed. Hook: human-effective 231, raw 359, 5 files.

## Precheck round 4 (2026-09-24) - Solution Quality FAIL (Comprehensiveness 1/3, Code Quality 2/3)
- Issue 1 (high): complex category value (is_numeric accepts complex) retyped to float/int -> float() TypeError escaped carry
  (which only catches ValueError) and aborted set_space; complex fill -> TypeError not ValueError. Fix: parameter._real_number
  rejects complex (np.iscomplexobj, so np.complex128(0.5) is rejected instead of silently losing its imaginary part) and turns any
  float() failure into ValueError; Float/IntParameter.convert both use it. meta: "real number" in the conversion and fill rules.
- Issue 2 (medium): SDRT history grew by one entry per set_space (mapped history + appended window). Fix: the migrated window
  REPLACES the last (current) entry, so add-then-remove restores the history exactly. No test (internal state).
- meta: user-supplied split of the long carry sentence, keeping "under the same rules as registered points". 485 words.
- Coverage advisories taken: partial fill with two added params; complex fills (float z, int n); transformer failure with a
  queue + two ConstantLiar(GPHedge) suggestions vs twin; one combined constrained + queue + GPHedge(EI, PI) mixed-type change
  (int retype, added categorical, removed y). Skipped: custom acquisition class, direct-reorder reducer reference (no public way
  to build the reference state).
- Old conversion (no complex guard) fails 4 new cases. Tests 64 cases. Host full suite with solution: 231 passed.

## Batch 1 + Auto Review (2026-09-24): 0/11 -> unsolvable; Auto Review revision (Solution 1/3, Tests 2/3, Description 3/3)
- 0/11. gphedge_partial killed 11/11. EVERY agent chose GPHedge all-or-nothing on purpose, with written reasons ("the only
  shape-safe option", "the same incompatibility rule used for registered points"); my own first reference did the same. The
  per-candidate rule was a hidden requirement, not difficulty. 5 runs failed ONLY that test.
- Auto Review S1 x2: EI/PI raise NoValidPointRegisteredError when every carried point is outside the new bounds (reference AND
  all 11 agents). T4: no half-way rounding case.
- Fix (round 5, solver-visible, so a full batch is owed):
  - meta: GPHedge contract stated ("When only some of those candidates can be carried, that suggestion still scores the carried
    ones, each for the acquisition function that proposed it") -> the fix stays hidden: a compacted candidate array silently
    broadcasts one reward onto every gain, so the carry AND _update_gains both have to change.
  - meta + solution: with no registered point inside the bounds, suggest returns a random point as before anything is
    registered (bounds-only check in BayesianOptimization.suggest; the constrained no-feasible-point error is untouched).
  - meta trimmed to 493 words (dropped the set_bounds motivation line, the coincide example, and two clauses).
  - tests: fallback twin (EI, PI, UCB, ConstantLiar, GPHedge == fresh optimizer's first suggestion, then a normal suggestion);
    ties 2.5/-1.5/3.5/0.5 -> 2/-2/4/0; queued probes through an integer retype; numpy + negative reals carried.
- Predicted: the 5 GPHedge-only runs now see the rule; risk of landing near the 40% ceiling. No fair extra lever found by probing.
- Tests 72 cases. Host full suite with solution: 239 passed.

## Auto Review round 6 (2026-09-24): Description 3/3, Tests 1/3, Solution 1/3
- S1 x3: non-finite numbers. _real_number now rejects NaN/+-inf (np.isfinite after float()) -> integer inf fill raises ValueError
  (was OverflowError), NaN/inf registered points dropped, NaN queued probe dropped. meta unchanged ("real number" already excludes them).
- T3/T4 x3, fixed through get_acquisition_params() (the public serialization API save_state uses; the reviewer suggested it) and
  only representation-free values (gains vector, decoded pending values):
  - warmed GPHedge (3 suggest+probe rounds, gains asserted nonzero) + queue; add/remove round trip -> full acquisition params
    equal the untouched twin, then same course. Plain and ConstantLiar(GPHedge).
  - attribution: after removing one category, the gain change over the next suggestion is > 900 at the surviving candidate's
    acquisition and exactly 0 at the other, both positions.
  - ConstantLiar coincide: carried pending values == the suggestions' rounded ys, earliest-unique when duplicates are off, all when on.
- Advisories taken: queued probes (incl. one outside the narrowed bounds) through both undo tests; malformed definition
  (single category) rollback vs twin.
- Named mutants: gains reset, compact-first-slots, liar always/never dedup, no finite check: all KILLED.
- Risk noted: the first precheck grader objected to reading acquisition state; these reads go through the public
  get_acquisition_params() only.
- Tests 82 cases. Host full suite: 249 passed. human-effective 242.

## Auto Review round 7 (2026-09-24): Description 3/3, Tests 1/3, Solution 3/3
- T3/T4 (High): no test separated "kept window carried + trimmed" from "kept parameter re-initialized" when its GLOBAL bounds
  change. The old (0.6, 1) case could not: the bowl pulls x's window to [0.06, 0.60], entirely below 0.6, so the trim resets it
  to the full new bounds, same as a fresh start.
- Fix: test_domain_reduction_carries_a_kept_window_into_moved_global_bounds. New x bounds (0.33, 1) overlap the window
  (guarded), expected window = [0.33, old high] with y's row unchanged, r unchanged, original_bounds = new bounds, next suggestions
  inside the trimmed window. Reads the user-held transformer's public bounds/r/original_bounds (repo tests read
  bounds_transformer.bounds the same way). The reviewer's mutant (re-init kept params whose global bounds moved) is KILLED.
- P4 (Low): split the long transformer sentence in meta (493 words, unchanged count).
- Tests 83 cases. Host full suite: 250 passed.

