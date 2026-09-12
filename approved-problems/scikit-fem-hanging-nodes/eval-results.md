# eval-results.md — scikit-fem-hanging-nodes

## Agent runs

### Batch 1 (2026-08-06, 3x Nova, artifact with 106 tests)

| Run | Agent | Evaluator | Verdict | Base | New | Failure reason | Approach note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| #1 | Nova | Nova | FAIL_INTEGRATION_ERROR | 538/538 | 40/106 | queries exposed as properties (58), `residual_estimator` in `skfem.utils` (3), constrained solve wrong (5) | full feature attempted across 9 files; prolongation built with `lil_matrix` |
| #3 | Nova | Nova | FAIL_INTEGRATION_ERROR | 538/538 | 45/106 | properties (53), estimator module (3), queries only on `MeshQuad1` (5) | never touched `skfem/mesh/mesh.py`; otherwise no functional defect |
| #4 | Nova | Nova | FAIL_INTEGRATION_ERROR | 538/538 | 64/106 | properties (30), estimator module (3), coarsening + Q2 + estimator defects (9) | got furthest on the queries, weakest on coarsening |

Pass rate 0/3. All three evaluators rated the task `description_clear: true`,
`tests_deterministic: true`, `difficulty: challenging`, `agent_blame_unfair: false`, and two of
three recorded `blocker_detected: false`. Raw artifacts, trajectories and JUnit XML are under
`agent-runs/`.

### Batch 2 (2026-08-07, 4x Nova + 1x Orion, artifact with 118 tests)

Run after the API-shape clarifications. Every verdict moved from `FAIL_INTEGRATION_ERROR` to
`FAIL_MISSED_REQUIREMENT`, every run kept the baseline green, and no evaluator reported a blocker
or an unfair flag.

| Run | Agent | Verdict | Base | New | Remaining failures |
| --- | --- | --- | --- | --- | --- |
| Orion #1 | Orion | FAIL_MISSED_REQUIREMENT | 539/539 | 113/118 | 3 composite, 2 estimator |
| Nova #2 | Nova | FAIL_MISSED_REQUIREMENT | 539/539 | 111/118 | 6 coarsening/tags, 1 interior tag |
| Nova #1 | Nova | FAIL_MISSED_REQUIREMENT | 539/539 | 110/118 | 6 coarsening/tags, 1 interior tag, 1 duplicate `D` |
| Nova #4 | Nova | FAIL_MISSED_REQUIREMENT | 539/539 | 108/118 | 5 coarsening/tags, 3 composite, 1 duplicate `D` |
| Nova #3 | Nova | FAIL_MISSED_REQUIREMENT | 539/539 | 107/118 | 6 coarsening/tags, 2 estimator, 3 interior/conforming tags |

Failures collapse into three clusters, each traced to a defect in the prompt rather than to the
feature:

| Cluster | Runs | Root cause |
| --- | --- | --- |
| coarsening eligibility | 4 of 5 | "no facet on the outer boundary is split" read as "or is one of the halves"; Nova blocks on `split or hanging`, Orion blocks on `split` and passes every coarsening test |
| estimator size | 2 of 5 | the prompt said "element diameter" while the reference uses the repository's mesh parameter `h`; for a square cell those differ by exactly a factor of two in the interior term |
| composite fields | 2 of 5 | the prompt said "component by component", which does not name what a composite element's second field should do; both runs took `gbasis(...)[0]` and coupled the fields |

### Replay with the clarified prompt

Each fix below is the edit the corrected wording now dictates, applied to the agent's own code and
nothing else.

| Run | as submitted | after | edits applied |
| --- | --- | --- | --- |
| Orion #1 | 113/118 | **118/118** | `h` = the mesh parameter; select the constrained dof's own field |
| Nova #2 | 111/118 | 117/118 | delete `or f in hanging` from the eligibility test |

Orion reaches green on two prompt-directed edits, neither of which touches its coarsening,
balancing, boundary detection, prolongation or constrain logic. That is the solvability evidence.

### Failure attribution (batch 1)

| Cause | Nova #1 | Nova #3 | Nova #4 |
| --- | --- | --- | --- |
| queries declared as properties, suite calls them | 58 | 53 | 30 |
| `residual_estimator` not in `skfem.models.poisson` | 3 | 3 | 3 |
| queries added to `MeshQuad1` only | 0 | 5 | 0 |
| genuine defects in the designed traps | 5 | 0 | 9 |
| **total failed** | **66** | **61** | **42** |

88 percent of all failures are two facts about API *shape* that the prompt never pinned.

### Replay after removing the shape mismatch

Each agent's patch was re-run against the same suite with a mechanical adapter that turns their
properties into methods and aliases `residual_estimator` into `skfem.models.poisson`. Nothing
else was changed.

| Run | as submitted | after the adapter | what remains |
| --- | --- | --- | --- |
| #1 | 40/106 | **99/106** | the constrained solve: energy identity, both harmonic patch tests, Rayleigh, estimator-zero |
| #3 | 45/106 | **101/106** | only the cross-mesh placement, which the prompt does state |
| #4 | 64/106 | **90/106** | coarsening rules, Q2 half weights, perimeter, estimator attribution, interior tags |

The residual failures are precisely the designed traps, and they differ per agent, so the
difficulty is intact and distributed. Passing diffs go to `agent-runs/<batch>-<run>.patch` when a
batch produces one.

## Local validation (2026-08-06)

Image: `olympus-base-python:latest` plus the repo's own `requirements.txt` toolchain. Every run
offline (`--network none`) as uid 1000.

| State | `test.sh base` | `test.sh new` |
| --- | --- | --- |
| base + test.patch | 539 cases, 0 failures | 118 cases, **118 failures** |
| base + test.patch + solution.patch | 539 cases, 0 failures | 118 cases, 0 failures |

Failures on base are per-test nodes, not a collection error: the test module imports only symbols
that exist at the base commit and reaches the new API inside the test bodies.

## Flakiness

| Run | base | new |
| --- | --- | --- |
| 1 | 538 passed, 1 skipped | 118 passed |
| 2 | 538 passed, 1 skipped | 118 passed |
| 3 | 538 passed, 1 skipped | 118 passed |

The vanilla repository suite was also run three times before authoring: 538 passed, 1 skipped
every time. `tests/test_mamba.py` is excluded in both modes because it needs `petsc4py` from
conda-forge; the repository's own CI excludes it identically.

## Test Fairness

| Round | Verdict | Detail |
| --- | --- | --- |
| 1 | FAIL, 12 of 87 unfair | ten tests selected elements by raw index, three zipped two independently sorted queries, one pinned the queries onto `MeshTri` without a stated contract |
| 2 | FAIL, 15 of 103 unfair | fourteen tests pinned fixture-specific counts reachable only by simulating the author's closure or coarsening; one relied on unstated duplicate-`D` semantics |
| 3 | FAIL, 1 of 91 unfair | the smallest-eigenvalue check pinned 2*pi^2 at rtol 1e-3, an accuracy threshold neither the prompt nor the repository states |
| 4 | FAIL, 1 of 97 unfair | the estimator allocation test used a strict inequality that holds only because the jumps happen to be nonzero |
| 5 | PASS, 0 unfair | the allocation is an exact elementwise comparison adding half of every paired jump to both `hanging_f2t` neighbours; the `coarsened` out-of-range case is covered |
| 6 | PASS, 0 unfair | advisory only: the negative index lower bound and the `coarsen_theta` cutoff at non-default fractions |
| 7 | PASS, 0 unfair | advisory only: overlapping coarsening groups at three listing orders, and composite-field reproduction without cross-field coupling |
| 8 | pending re-check | advisory only: named interior facets through `conforming()`, and vector/composite `project`; probing the latter closed a fixed-point FP hole in all four projection constraint tests |

## Mutation battery

Thirteen defects planted in the reference one at a time, suite re-run each time, reference
restored afterwards.

| Planted defect | Tests killed | First failure |
| --- | --- | --- |
| `boundary_facets` back to `f2t[1] == -1` | 7 | test_boundary_facets_exclude_the_halves |
| no one-irregular balancing | 2 | test_refining_the_fine_side_pulls_in_the_coarse_neighbour |
| balancing without the fixpoint | 1 | test_balancing_repeats_until_nothing_is_forced |
| fresh midpoint instead of reuse | 2 | test_refinement_never_duplicates_a_vertex |
| only the hanging vertex constrained | 2 | test_second_order_half_weights_are_not_an_average |
| prolongation uses the fine element | 24 | test_first_order_masters_are_the_facet_ends |
| halves inherit the parent weights | 5 | test_second_order_half_weights_are_not_an_average |
| vector components not separated | 2 | test_vector_element_does_not_mix_components |
| estimator drops the coarse side | 2 | test_estimator_distributes_every_jump |
| `constrain` forgets the load restriction | 5 | test_constrained_solution_satisfies_the_discrete_identity |
| coarsening ignores finer neighbours | 1 | test_coarsening_stops_at_a_finer_neighbour |
| `hanging_f2t` not filled in | 3 | test_interior_facet_pairing_names_the_coarse_element |
| `constrain` does not merge `D` with the constrained set | 0 | contract test, not a trap |
| coarsening takes the lowest shared vertex first | 4 | test_coarsening_takes_the_highest_shared_vertex_first |
| `project` ignores the hanging constraints | 4 | test_constrained_projection_obeys_the_constraints |
| `FacetBasis` default keeps the halves | 1 | test_boundary_facet_basis_integrates_the_perimeter |

## Size

| Measure | Value |
| --- | --- |
| raw added lines | 639 |
| human-effective (Counter 2) | 411 |
| platform auto-block counter (Counter 1) | 494 |
| files touched | 11 |
| new tests | 118 |
| base cases | 539 |
| meta.md words | 498 |
