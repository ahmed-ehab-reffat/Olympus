# Repo Hunt 2026-08-07-D — Python, scientific / heavy-float / niche

Continuation of the Python sweep in `REPO-HUNT-2026-08-07-C.md`, steered per user direction into
scientific and heavy-mathematics domains with real floating-point content: astrodynamics, ephemeris,
geodesy, photogrammetry, colorimetry, thermodynamics, hydrology, hydraulics, seismic, geophysics,
crystallography, spectroscopy, kinematics, quaternions, quadrature, uncertainty, interval arithmetic,
combustion, aerodynamics, propulsion, vibration, acoustics, tomography, structural, nuclear, battery,
electrochemistry, photovoltaic, atmospheric, radiative, tidal.

**This sweep produced a genuine RANK 1 with a measured Gate-1 gap: JWock82/Pynite.**

---

## ⭐ Correction carried into this hunt — G-PY2 is a COST signal, not a numpy ban

I had been reading G-PY2 ("C-extension test extras: numpy|scipy|lxml|pillow|pandas|pyarrow") as a
near-reject, which would have excluded essentially all of scientific Python before the sweep started.
That reading is wrong, and `DOCKER.md` settles it: **every approved Python Dockerfile runs
`pip install` at build time** (`pip install -e .`, `pip install --no-cache-dir pytest ...`, the ormar
example installs a dozen pinned runtime deps). Network IS available during a Python image build,
unlike the Rust vendoring case that produced the rule.

So the real Python Docker reject is a dependency that **must compile from source or needs system
headers** — not one that ships a manylinux wheel. numpy, scipy and matplotlib all ship wheels and
install with no compiler. `vtk` and `pyvista` are the ones to watch (large, and OpenGL-linked).

Practical effect: scientific Python is in scope, and G-PY2 should be applied as "does this dep have a
wheel", not "is this dep in the list".

---

### JWock82/Pynite — ★722 — RANK 1

- **URL / stars:** https://github.com/JWock82/Pynite — ★722
- **Language:** Python. Runtime deps `numpy>=2.4`, `scipy`, `matplotlib`, `PrettyTable` — all
  manylinux wheels, no compiler, no system headers. Optional extras (`vtk`, `pyvista`, `pdfkit`,
  `Jinja2`) are visualization/reporting only.
- **Domain:** 3D structural-engineering finite element library — matrix structural analysis
- **Open issues:** 22. Open PRs: **3, and all three are tooling** (#333 uv packaging, #300 ruff
  pyupgrade, #299 unused-import lint). Zero capability PRs.
- **License:** MIT
- **Last commit:** 2026-08-04, real code
- **Our quota:** 0/6. No `pynite` / FEM / structural feature class anywhere in `approved-problems/`,
  `problems/`, `rejected/`. Not in `SATURATED-REPOS.md`.
- **Size:** 28,947 Python LOC total, 22,664 in the `Pynite/` package — clears the ~30k repo-fit proxy,
  and importantly does NOT have the fusesoc problem: the FEM machinery is all in-repo, with numpy and
  scipy used only as array/solver primitives.
- **Test framework:** 30 test files in `Testing/`, pytest, **behavioural through the public API**
  (build an `FEModel3D`, call `analyze*`, assert forces/displacements/reactions against
  hand-calculable or published values). Not mock-heavy. `test_AISC_PDelta_benchmarks.py` checks
  against published AISC benchmark answers.
- **Baseline determinism (G-PY1): PASS, 3/3 identical**, unpinned `PYTHONHASHSEED`: `124 passed,
  1 failed, 1 skipped, 18 subtests passed` every run, in ~4.7s. The single failure and 4 collection
  errors are all `ModuleNotFoundError: vtk` in the visualization files
  (`test_Visualization.py`, `test_meshes.py`, `test_shear_wall.py`, `test_vtkwriter.py`,
  `test_plates&quads.py::test_circular_hopper`) — scope base mode out of those with the reason
  documented, exactly as canvas does for its GPU backends.
- **Docker:** Pattern B (`olympus-base-python`), `pip install -e .` plus pytest. Fast, no system
  deps. UNVERIFIED locally (no Docker on this workstation) — owed to the platform run.
- **Architecture:** `FEModel3D` (model + global matrix assembly, 2983) / `Analysis.py` (solver
  drivers, 1571) / element classes `Member3D` 3247, `PhysMember` 1404, `Quad3D` 1239, `Plate3D` 692,
  `Tri3D` 688, `Spring3D` 255 / `Mesh` 2169 / rendering + reporting. A real assemble-solve-recover
  pipeline with five analysis entry points.
- **Capability-lane density (Stage 2c):** 300 commits/12mo, but the PR queue is tooling-only, so the
  maintainer's program is the thing to read (the rapier lesson). Keyword histogram over the 12-month
  commit subjects: **render 27, member 23, pushover 22, mesh 16, P-Delta 7, instability 4** — those
  lanes are HOT and are the maintainer's current program (nonlinear member end forces, pushover,
  global-instability detection via solution residual, physical members). **Cold: plate 2, quad 2,
  spring 3, tension/compression 0, load-combination 0, solver 0.** Pick in the shell-element lane,
  not in the nonlinear/pushover lane.
- **Maintainer-welcomed lanes (Stage 2d):** not swept this round; owed before scope-lock.
- **Self-collision:** none. Nearest is `approved-problems/lyon-*` (2D geometry) and
  `calyx-unused-port-elimination` — neither is FEM or matrix analysis.
- **Missing machinery (LOC carry) — MEASURED, not estimated:**

```
element class    has M() mass matrix?
Member3D         yes
Node3D           yes
Spring3D         NO
Plate3D          NO
Quad3D           NO
Tri3D            NO
```

  `FEModel3D.M()` (line 2004) assembles the global mass matrix by iterating **physical members and
  nodes only** — grepping the whole assembler for `plate|quad|tri|mesh` returns nothing but
  docstring and comment text. So **every shell element contributes exactly zero mass to modal
  analysis.** A slab, wall, tank or hopper modelled in quads has no mass at all; the only thing that
  stops a singular solve is the fallback at ~line 2100 that injects "an insignificant mass to those
  terms to get the matrix to solve", which silently produces wrong frequencies instead of an error.
  That is a textbook silent-drop, and the fix is genuinely new machinery: consistent mass matrices
  for three element classes (membrane + bending DOFs, 24x24 quad, 18x18 tri, plus the local-to-global
  transformation each class already owns for stiffness), the assembler wiring, the surface-load to
  mass conversion, and the interaction with the existing double-counting rule.

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-9 cross-stage resolution drop | **yes (lead)** | `FEModel3D.M():2004` assembles mass from members + nodes only while `K()` assembles stiffness from every element type including plates/quads/tris. The two assemblers disagree about what exists, and only the mass side is wrong |
| F-10 capability cross-product | **yes (strong)** | axes: 6 element types {Member3D, PhysMember, Spring3D, Plate3D, Quad3D, Tri3D} x 5 analysis entry points {`analyze_linear`, `analyze`, `analyze_PDelta`, `analyze_modal`, `analyze_pushover`}. Most cells are untested and several are wrong |
| F-14 declared-vs-derived terminal state | **yes** | `_check_TC_convergence():917` deactivates tension-only / compression-only members and springs iteratively; `phys_member.active[combo]` then gates assembly in both `K()` and `M()`. Multiple independent "give up" exits across `_first_order`, `_PDelta`, `_pushover_step` |
| F-15 arming-vs-firing | **yes** | `spring_tolerance` / `member_tolerance` / `max_iter=30` gate the T-C on-off switch. Note `_PDelta():329` takes **no tolerance parameters at all** and calls `_check_TC_convergence(model, combo_name, log)` at line 448, so P-Delta silently runs at zero tolerance while `_first_order` (line 308) honors the caller's values |
| F-6 ordering inversion | **yes** | T-C convergence vs P-Delta geometric-stiffness update vs load-step ratio (`_load_step_ratio():696`) — three iterations whose nesting order is unstated and observable |
| F-8 named-algorithm override | partial | DKMQ quad formulation (`A_Delta_inv_DKMQ`), MITC4 sitting in `Archived/`. The repo's element choices diverge from the textbook versions |
| F-5 transitive pass-through | yes | `PhysMember` is a container that forwards to sub-`Member3D`s — a pass-through node in every assembly walk |
| F-13 two-tier format | no | — |

**Best Olympus feature types:**

1. ⭐ **Consistent mass matrices for shell elements, wired into modal analysis.** Spans `Plate3D`,
   `Quad3D`, `Tri3D`, `FEModel3D.M()` and `analyze_modal` — 4-6 files, 2 subsystems. Gate 1 is
   already visible in source and needs one measurement to confirm end to end. Interdependent (the
   `active[combo]` gating and the member/node double-counting rule both constrain it), misdirecting
   (the failure surfaces as plausible-looking wrong frequencies, not an exception, because of the
   insignificant-mass fallback).
2. **Tolerance and convergence parity across the five analysis entry points** — `_PDelta` not
   accepting `spring_tolerance`/`member_tolerance` is a real drop, but on its own it is a
   two-parameter thread and will land far under the floor. Use as a bundled second capability, not
   as the core.
3. **Spring3D mass** — same class of gap, much smaller. Bundle, do not lead.

**Estimated complexity:** ~300-450 effective LOC across 4-6 files. Sketch and count the minimal
golden slice before scope-lock (the canvas 213-vs-44 lesson), but unlike canvas the machinery is
provably absent rather than merely unrouted.

**Why it matches:** exactly the brief — heavy floating point (stiffness and mass matrices, eigenvalue
extraction, iterative nonlinear convergence), a domain almost no problem author will reach for
(structural engineering FEM), MIT, 29k LOC of in-repo machinery, a fast deterministic behavioural
suite, an empty capability PR queue, and a maintainer program concentrated in lanes I would avoid
anyway.

**Risks:**
- **(a) Magnet, moderate.** "Consistent mass matrix for shell elements" is a textbook FEM term. The
  mitigation is that the SCOPE is Pynite's own model — the `mass_combo_name` load-to-mass conversion,
  `mass_direction`, the deliberate member/node separation to avoid double counting, and the
  `active[combo]` T-C gating are all repo-internal nouns. Do not rate this LOW.
- **(b) Float assertions.** Behavioural tests must assert frequencies within a tolerance. Choose
  models with closed-form answers (simply-supported plate) and set tolerances from the discretisation
  error, not from observed output.
- **(c) Test scoping owed.** 5 test files need the `vtk` extra; base mode must exclude them with a
  documented reason.
- **(d) Gate 1 still owed as a MEASUREMENT.** The zero-mass drop is proven in source; it has not yet
  been run through `analyze_modal` to capture the wrong frequencies. Do that first.
- **(e)** Avoid the pushover / P-Delta / rendering / mesh lanes (maintainer's active program) and
  `test_AISC_PDelta_benchmarks.py` (a vendored published answer key, the apd lesson).

---

### CalebBell/thermo — ★775 — RANK 2 (unaudited)

Cloned but not audited; recorded so the next scientific sweep starts here rather than re-deriving it.
MIT, 775 stars, 146 commits/12mo, **only 2 open PRs**, pushed 2026-07-13. Thermodynamics and phase
equilibrium: flash algorithms, equations of state, phase stability testing, activity coefficient
models — genuinely heavy floating point with real iterative convergence, and a chemical-engineering
domain that is about as far from author-obvious as it gets.

Two concerns to resolve before investing: (1) the sibling repos `fluids` (★448) and `chemicals`
(★303) are both **under the 500-star floor**, and `thermo` depends on both — check whether a pick can
be confined to `thermo` itself or whether the machinery lives downstream, which is the fusesoc death;
(2) `fluids` shows a run of commits reading "CI fixes - test tolerance loosening", which is a
**flaky-baseline signal** against the mandatory Gate 9 — run the 3x determinism check early.

---

## Rejected this sweep

| Repo | ★ | Kill |
|---|---|---|
| pybamm-team/PyBaMM | 1633 | **Capability wave.** 30 open PRs including a coordinated unstructured-mesh program (#5687 mesh infrastructure, #5688 unstructured FV spatial method, #5690 unstructured 2D/3D DFN, #5689 VTK plotting) plus active expression-tree work. Excellent shape (symbolic model -> discretisation -> solver is a real compiler pipeline) and worth revisiting if that wave lands. |
| pvlib/pvlib-python | 1633 | **Capability wave + magnet.** 26 open PRs and a fast feature stream, and essentially every capability is named after a published model (Perez, Marion, Sandia, Kimber, single-diode, SAPM). Stage-2b HIGH by construction. |
| pyproj4/pyproj | 1222 | Python interface to the PROJ **C library** — hard reject on bindings. |
| GenericMappingTools/pygmt | 870 | Same: a wrapper over the GMT C library. |
| simpeg/simpeg | 665 | 184 open issues, heavy academic team, geophysical inversion — capability velocity not checked because the domain is dominated by named inversion methods. |
| rai-opensource/spatialmath-python | 638 | Peter Corke's SE(3)/SO(3) library. Float-heavy and coupled, but every capability is named Lie-group mathematics — magnet, and the library is a teaching companion so the reference implementations are widely mirrored. |
| Phylliade/ikpy | 1024 | Inverse kinematics; the solvers are named (CCD, Jacobian, Levenberg-Marquardt) and the heavy lifting delegates to scipy. |
| moble/quaternion | 658 | A numpy dtype extension — C extension, and quaternion algebra is fully named. |
| CalebBell/fluids, CalebBell/chemicals | 448 / 303 | **Under the 500-star floor.** Relevant only as thermo's dependencies. |
| SALib/SALib | 999 | Sensitivity analysis; every method is named (Sobol, Morris, FAST) and the repo is essentially a catalogue of them — the oasdiff add-a-case profile. |
| lmcinnes/umap, sktime/pytorch-forecasting, google/uncertainty-baselines | — | ML, not the target class. |
| chaimleib/intervaltree | 691 | Single data structure, far under the repo-fit proxy. |

**Sweep noise:** the scientific Python index is cleaner than the general one (less AI slop) but has a
different contaminant — `projection` returns UMAP and 3D Gaussian splatting, `tidal` returns music
downloaders, `battery` returns Home Assistant integrations, `structural` returns protein models.
Productive keywords: `thermodynamics`, `structural`, `photovoltaic`, `battery`, `kinematics`,
`geophysics`, `crystallography`. Also note `gh search repos` over 20 keywords x 1 language exceeds a
2-minute tool timeout — batch 8 keywords at a time.

**Disk:** `worktrees/Pynite` 346M (includes a 300M `.venv` with numpy/scipy/matplotlib — keep it, the
PyPI connection here times out often and reinstalling is expensive). `worktrees/thermo` 64M kept for
the RANK 2 audit. `/home` at 93%.
