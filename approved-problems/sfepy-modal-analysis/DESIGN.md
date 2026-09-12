# DESIGN.md — sfepy-modal-analysis

## 1. Title

Add modal analysis and modal response to sfepy

## 2. Shape classification

O-Composite-add: a new module (`sfepy/discrete/modal.py`) carrying one coherent
capability with a wide derived API, wired into the existing `Problem` /
`Equations` / `Variables` / eigenvalue-solver machinery. Closest approved
siblings: `pvlib-loss-attribution` (derived-quantity family over an existing
pipeline) and `skrf-transient-simulation` (new module + result object with many
metrics).

## 3. Public API surface

`sfepy.discrete.modal`, re-exported through `sfepy.discrete`:

1. `assemble_matrices(problem, stiffness='stiffness', mass='mass')`
2. `solve_modes(problem, n_modes=6, stiffness='stiffness', mass='mass')` -> `ModalSolution`
3. `Problem.solve_modes(n_modes=6, stiffness='stiffness', mass='mass')`
4. `ModalSolution` attributes: `eigenvalues`, `omegas`, `frequencies`, `vectors`, `reduced_vectors`, `mtx_k`, `mtx_m`, `n_modes`
5. `ModalSolution.modal_masses()` / `.modal_stiffnesses()`
6. `ModalSolution.normalize(kind='mass')`
7. `ModalSolution.expand(reduced_vec)` / `.restrict(full_vec)` / `.project(full_vec)`
8. `ModalSolution.rigid_body_vectors(centre=None)`
9. `ModalSolution.participation_factors(centre=None)`
10. `ModalSolution.effective_masses(centre=None)` / `.mass_fractions(centre=None)` / `.cumulative_mass_fractions(centre=None)`
11. `ModalSolution.mac(other)` / `.pair(other)`
12. `ModalSolution.select(fmin=None, fmax=None, n_modes=None)`
13. `ModalSolution.static_correction(load)`
14. `ModalSolution.frequency_response(freqs, load, damping=0.0, correction='none')`
15. `ModalSolution.base_frequency_response(freqs, direction, damping=0.0, centre=None)`
16. `ModalSolution.response_spectrum(spectrum, direction, damping=0.0, rule='srss', centre=None)`
17. `ModalSolution.transient_response(times, load, history, damping=0.0, displacement=None, velocity=None)`
18. `ModalSolution.create_output(name='mode')`
19. `rayleigh_coefficients(f1, f2, zeta1, zeta2)` / `rayleigh_damping_ratios(alpha, beta, frequencies)`

## 4. Canonical output form

- `eigenvalues` ascending; `frequencies = sqrt(max(lambda, 0)) / (2 pi)` in Hz.
- Mode vectors live in the FULL DOF space of the problem, zero at DOFs fixed by
  essential conditions, expanded through the linear-combination operator.
- Sign convention after any normalization: the full-space component of largest
  magnitude is positive; ties go to the lowest DOF index. Without this the tests
  cannot compare vectors.
- Rigid-body direction order: 2D `[x, y, rotation about z]`, 3D
  `[x, y, z, rotation about x, y, z]`. Rotation column at a node with position
  `p` is `e_k x (p - centre)`; in 2D it is `(-(p_y - c_y), p_x - c_x)`.
- `participation_factors` shape `(n_modes, n_rigid)`, `effective_masses` and
  `mass_fractions` the same, `cumulative_mass_fractions` their running sum.
- `mac` shape `(n_modes, other.n_modes)`, values in `[0, 1]`.
- `frequency_response` returns complex `(len(freqs), n_dof_total)`.
- `response_spectrum` returns a real full-space vector.

## 5. Blind-spot pre-empts

- State that participation factors, effective masses and modal masses are taken
  in the CONSTRAINED (reduced) space, with the rigid-body columns restricted the
  same way — otherwise both readings are defensible.
- State that node positions come from the field nodes, not the mesh vertices
  (they differ for approximation order 2).
- State the sign convention (above) explicitly.
- State that a normalization other than mass normalization must still divide by
  the modal mass in the participation/effective-mass formulas.
- State the exact CQC correlation formula and that SRSS is its zero-damping,
  well-separated limit.

## 6. Description draft

See `meta.md`.

## 7. File footprint (measured)

| File | raw + | human-effective |
|---|---|---|
| `sfepy/discrete/modal.py` (new) | 711 | 445 |
| `sfepy/discrete/problem.py` | 15 | 4 |
| `sfepy/discrete/__init__.py` | 2 | 2 |
| total | 728 | 451 |

## 8. Solution outline

Pure helpers, one per behavior:

- `assemble_matrices` — assemble the two named equations, then apply the linear
  combination operator on both sides.
- `_solve_evp` — dense generalized EVP below 500 free DOFs, shift-inverted
  `eigsh` above it, ascending.
- `_fix_signs` — largest-magnitude-positive convention, applied to the reduced
  and the full vectors by the same factor.
- `_active_indices` — full-space indices of the DOFs the essential conditions
  leave free.
- `_duhamel_coefficients` — the recurrence of a mode driven by a load varying
  linearly over one step.
- `_cqc_correlations` — the correlation matrix of the complete quadratic
  combination.

## 9. Test file outline

`sfepy/tests/test_modal_<hash>.py`, four blocks: builders (bar/beam/free-free
block/order-2 field/LCBC problem), assertion helpers, granular tests, error
contract. Coverage:

- frequencies of a fixed-free bar against the analytic `(2k-1) c / (4 L)`.
- free-free block: 3 (2D) zero eigenvalues, rigid-body modes.
- orthogonality after each normalization kind + sign convention.
- participation/effective mass: sum over modes of a fixed-free bar approaches
  the free mass; exactness of `Gamma^2 / m_i` under a non-mass normalization.
- rotation columns with and without a centre.
- order-2 field: rigid vectors must use field nodes.
- LCBC problem: mode vectors respect the constraint.
- MAC identity on itself, pairing a permuted solution.
- frequency response against a direct solve of `(K - w^2 M) u = f` on a
  single-mode-dominated case, plus the static-correction limit at `w = 0`.
- response spectrum: SRSS/CQC/abssum arithmetic against a hand computation.
- Rayleigh helpers round-trip.
- every error in the contract.

## 10. Forced kwargs

`centre` (rotation reference), `damping` (scalar or per-mode), `correction`,
`rule`, `kind`. Each has a stated default.

## 11. Trap matrix (mutation kill counts, measured against the 108-test suite; lower bounds now)

1. **Reduced-vs-full space.** Modes are returned full but every mass-weighted
   quantity is reduced. Zero-padding the full vector and using a full mass
   matrix is the tempting wrong answer; the coupling block between free and
   fixed DOFs makes it differ. Misdirects because the frequencies are right.
2. **Field nodes vs mesh vertices.** Rigid-body columns need one row per DOF; at
   approximation order 2 the mesh has fewer vertices than the field has nodes,
   so a vertex-based build has the wrong length and, if broadcast, the wrong
   rotation arm. Interdependent with trap 1 (both feed participation factors).
3. **Normalization coupling.** `effective_masses` must divide by the modal mass;
   with the default mass normalization that divisor is 1, so the bug is
   invisible until a test uses `normalize('max')`.
4. **Sign convention.** Eigensolvers return arbitrary signs; without the stated
   convention the MAC and pairing tests still pass but the vector comparisons do
   not.
5. **The linear combination operator.** The matrices `Problem` graphs are sized
   in the essential-condition space, while `make_full_vec` expects the smaller
   linear-combination space, so a solver that skips `mtx_lcbc` fails on shape
   the moment a rigid region appears.

Measured kills, one mutation each against all 108 tests: linear combination
operator dropped 4, modal-mass divisor dropped 3, rotation sign flipped 3, mass
fraction denominator replaced 2, mesh vertices for field nodes 1, sign fix
dropped 1, static correction dropped 1.

## 12. Tier + category

Olympus. Category: numerical/structural engine extension.

## 13. Predicted pass rate

15-30%. Solvable: the assembly path is demonstrated by
`sfepy/examples/linear_elasticity/modal_analysis.py`; the derived quantities are
textbook. Held down by traps 1-3.

## 14. Quality-gate checklist

- [x] repo gates: 837 stars, BSD-3, Python, 45 source commits in 12 months, no
      prior submission of ours, single branch `master`, no PR or issue touching
      a modal API.
- [x] exclusivity: `gh pr list --state all` over modal/eigen/participation/
      response-spectrum/frequency-response/damping returns only merged example
      and solver-config work; branch enumeration shows only `master`.
- [x] dedup: no approved/rejected/authored problem covers modal analysis.
- [x] env quality: vanilla suite 221 passed / 0 failed offline, 15m44s.
- [x] LOC: `human-effective` 451 over 3 files.
- [x] every new test fails on base: 146 of 146.
- [x] FP matrix both directions; six gaps closed with discriminators.
