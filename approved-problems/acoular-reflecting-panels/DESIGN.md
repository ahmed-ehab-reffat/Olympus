# DESIGN.md — acoular-reflecting-panels

## 1. Title

Add specular reflection paths to acoustic propagation

Repo: acoular/acoular @ `b5a20cdbff51bb0ec7b281fc9b02192ad1516b0b` (BSD-3-Clause, 645 stars, Python 98%,
last commit 2026-08-06). Never used locally: absent from `problems/`, `rejected/`, `Instructions/Aprroved/`.

## 2. Shape classification

- Shape: **O-Algorithm-correctness** with composite span (PLAYBOOK Pattern 12): one geometric kernel
  whose subtle correctness drives six consumer surfaces.
- Pass-rate target: design to **1/10 (10%)**; hard cap 40%.
- Best agent: mixed.
- Dominant verdict: MISSED_REQUIREMENT / wrong logic.

Corpus levers stacked (need >=3, have 5):
1. **One interdependent kernel** — `ReflectiveEnvironment.paths()` feeds `SteeringVector.transfer`,
   four source models, `BeamformerTime`, `impulse_response` and `reflection_points()`. A local fix to
   the occlusion test kills every reflection; a local fix to the mirror chain silently moves every
   image.
2. **External oracle** — Fermat's principle. For each panel sequence, numerically minimise the total
   path length over the reflection points; the minimiser must reproduce the image-source distance and
   the specular points. Fuzzed over random geometries to zero mismatches before shipping.
3. **Misdirecting traps** — the mirror-order defect surfaces as a wrong beamformer level, not as a
   geometry error; the strict-interior occlusion defect surfaces as *all* reflections vanishing.
4. **"Obvious code is wrong" edge** — mirroring in reverse order is indistinguishable on parallel
   panels and wrong on every non-parallel pair; `0 <= t <= 1` occlusion blocks every path by its own
   endpoints.
5. **De-training** — an aeroacoustic beamforming library is an unusual host for the image-source
   method, and the contract (finite two-sided panels, canonical sequence ordering, validity separated
   from amplitude, direct reference distance) is bespoke rather than a portable spec.

## 3. Public API surface (as shipped)

New in `acoular/environments.py`, which is where the module autosummary lists them:

- `ReflectingPlane` — a flat rectangular reflector, two sided and opaque.
  - `corner`, `edge1`, `edge2` — arrays of 3 floats; the edges must be perpendicular and non-zero
  - `reflection_factor` — float, amplitude factor per reflection, default `1.0`
  - `impedance` — `None` or float; when set it replaces `reflection_factor` with an angle
    dependent factor
  - `normal` — read-only unit normal along `edge1` x `edge2`
  - `digest` — read-only identifier
  - `signed_distance(pos)` — `(3, N)` in, `(N,)` out
  - `mirror(pos)` / `mirror_direction(vec)` — `(3, N)` in and out; the second ignores the plane's
    position
  - `contains(pos)` — `(3, N)` in, bool `(N,)` out
  - `crossing(start, end)` — two `(3, N)` in; `((3, N), (N,))` out, strict interior only
  - `factor_at(cosine)` — `(N,)` in and out
- `ReflectiveEnvironment(Environment)`
  - `planes`, `max_order` (default `1`), `plane_digest`, `digest`
  - `path_sequences()` — list of tuples of panel indices
  - `image(sequence, pos)` / `image_velocity(sequence, vec)`
  - `paths(gpos, mpos)` — `(r, amplitude, valid)`, each `(P, N, M)`
  - `paths_at(gpos, mpos)` — the same for matched pairs, each `(P, N)`
  - `reflection_points(index, gpos, mpos)` — `(L, 3, N, M)`
  - `incidence(index, gpos, mpos)` — `(L, N, M)`

Added to `Environment` (base) so every consumer is uniform: `path_sequences()`, `paths`,
`paths_at`, `image`, `image_velocity`, and `impulse_response(gpos, mpos, sample_freq, num_samples)`.

Consumers wired to the path set: `SteeringVector.transfer`, `PointSource`, `PointSourceDipole`,
`LineSource`, `MovingPointSource`, `BeamformerTime` and `BeamformerTimeSq`.

Errors: `ValueError` for degenerate or non-perpendicular edges, and for a negative `max_order`.

## 4. Canonical output form

- **Sequence enumeration.** `path_sequences()` returns every tuple of panel indices of length `0` to
  `max_order` in which no two consecutive entries are equal, ordered by length first and
  lexicographically within a length. The empty tuple (the direct path) is always index `0`.
- **Encounter order.** A sequence lists panels in the order the ray meets them, travelling from the
  source position to the receiver position.
- **Image chain.** The image for a sequence is built by mirroring the source position about each
  panel of the sequence in turn, in sequence order. `r` is the distance from the final image to the
  receiver.
- **Amplitude.** `amplitude` is the product of `reflection_factor` over the sequence, `1.0` for the
  direct path, and is reported for every sequence whether or not the path is valid.
- **Reflection points.** For sequence `(s_1, ..., s_L)` with images `I_1, ..., I_L`, the last point is
  where the segment from `I_L` to the receiver crosses panel `s_L`, and each earlier point `q_j` is
  where the segment from `I_j` to `q_{j+1}` crosses panel `s_j`. `reflection_points` returns them in
  sequence order. A crossing counts only when it lies strictly between the two segment endpoints.
- **Validity.** A path is valid when every reflection point exists, lies inside its own panel, and no
  panel blocks any of the ray's segments. The ray's segments are source to `q_1`, `q_j` to `q_{j+1}`,
  and `q_L` to receiver. A panel blocks a segment when the segment crosses the panel's plane strictly
  between its endpoints and the crossing point lies inside the rectangle. The direct path can be
  blocked.
- **Missing points.** Where a crossing does not exist the entry of `reflection_points` is `nan`, and
  every earlier point of that sequence is `nan` too, because the walk cannot continue.
- **Empty configuration.** No panels or `max_order` of zero leaves exactly the direct path, so
  `ReflectiveEnvironment` behaves as `Environment`.
- **Negative factors.** `reflection_factor` may be negative or greater than one; it is used as given.
- **Reference distance.** `SteeringVector.r0` and `Environment.apparent_r` stay direct distances and
  ignore panels.

## 5. Blind-spot pre-empts

| Blind spot | Sentence in the description |
| --- | --- |
| Result list ordering | "ordered by length first and lexicographically within a length" |
| Compound order preservation | "in the order the ray meets them, travelling from the source to the receiver" |
| Adjacent vs all positions | "no two consecutive entries are equal" |
| Unstated inverse | "the direct path can be blocked as well" |
| Falsy-on-invalid | "amplitude is reported for every sequence whether or not the path is valid" |
| Ambiguous bounds | "strictly between the two segment endpoints" |
| Iteration termination | "every tuple of length zero to max_order" |

Codebase-inferable requirements: 1 (the `(3, N)` position layout, which every acoular geometry API uses).

## 6. Description draft

See `meta.md`. Plain prose, five paragraphs, 846 words, inside the approved corpus band
(median ~470, maximum 834 before this one).

## 7. File footprint

| Action | Path | Raw delta | human-effective | Reason |
| --- | --- | --- | --- | --- |
| MODIFY | `acoular/environments.py` | +604 | 206 | `ReflectingPlane`, `ReflectiveEnvironment`, base path API, impulse response |
| MODIFY | `acoular/sources.py` | +79 | 72 | four source models radiate along every path |
| MODIFY | `acoular/tfastfuncs.py` | +55 | 31 | `_delayandsumreflect` numba kernel |
| MODIFY | `acoular/fbeamform.py` | +22 | 20 | `SteeringVector.transfer` sums reflection terms |
| MODIFY | `acoular/tbeamform.py` | +20 | 20 | `BeamformerTime` builds path aware delay arrays |

TOTAL 840 raw / 384 human-effective across 5 modified files. `acoular/__init__.py` is deliberately
NOT touched: it is one of the 20 CRLF-stored files in an otherwise LF repository, and the platform's
checkout does not preserve the CR, so a hunk against it cannot be applied there. Both new classes
stay public in `acoular.environments`. Under the 450 design target and over
the 250 sprint floor; the gap and the reason it was not closed are recorded in `feedback.md`.

## 8. Solution outline — helpers

- `ReflectingPlane._get_normal()` — validated unit normal, raises on degenerate or non-perpendicular edges
- `ReflectingPlane.signed_distance(pos)` — requirement: side of the plane
- `ReflectingPlane.mirror(pos)` — requirement: image chain
- `ReflectingPlane.contains(pos)` — requirement: reflection point inside its own panel
- `ReflectingPlane._crossing(a, b)` — segment/plane crossing parameter and point, strict interior
- `_sequences(num_planes, max_order)` — requirement: canonical enumeration, no consecutive repeats
- `ReflectiveEnvironment._images(gpos)` — requirement: mirror in encounter order
- `ReflectiveEnvironment.reflection_points(index, gpos, mpos)` — requirement: back-walk
- `ReflectiveEnvironment._blocked(a, b)` — requirement: occlusion of one segment by any panel
- `ReflectiveEnvironment.paths(gpos, mpos)` — assembles `r`, `amplitude`, `valid`
- `Environment.paths` / `Environment.path_sequences` — the trivial single-path case
- `SteeringVector.transfer` — direct term unchanged (`calcTransfer`), reflection terms added
- `PointSource.result` — direct block unchanged, reflection blocks accumulated

No fixpoint loop. The back-walk is a bounded recursion over the sequence length.

## 9. Test file outline

Path: `tests/unittests/test_reflection_paths_<hash>.py`

Block 1 — imports (numpy, pytest, acoular).
Block 2 — builder helpers: `panel(...)`, `floor()`, `wall()`, `env(...)`, `mics(...)`, `grid(...)`.
Block 3 — assertion helpers: `assert_close`, `expect_error`.
Block 4 — buckets:

- panel geometry: normal orientation, signed distance, mirror involution, contains inside/edge/outside,
  perpendicularity and degeneracy errors
- sequence enumeration: order, length grouping, no consecutive repeats, `max_order` 0/1/2/3, no panels
- image chain and path length: single panel closed form, two parallel panels, two perpendicular
  panels where mirror order matters, order-2 and order-3
- reflection points: closed-form specular point over a floor, back-walk for order 2, nan when the
  crossing does not exist
- validity: point inside the panel, point off the panel edge, receiver behind, occlusion of a
  reflected segment, occlusion of the direct path, strict-interior self-exclusion
- amplitude: product over the sequence, reported for invalid paths, negative factor, order 2
- transfer: direct-only equals base `Environment`, two-path interference, pressure doubling at low
  frequency, comb nulls, invalid path contributes nothing, negative factor inverts
- point source simulation: reflection arrives delayed by the extra path length and scaled by
  `amplitude / r`, blocked reflection contributes nothing, two panels
- oracle cross-check: Fermat minimisation reproduces path length and specular points on random geometries
- base compatibility: `Environment.paths` shape and values, `ReflectiveEnvironment` with no panels

Shipped: 230 tests, all failing on base.

## 10. Forced signatures

- `paths` returns a 3-tuple of `(P, N, M)` arrays — pinned in the description, no signature guessing.
- `reflection_points` returns `(L, 3, N, M)` — pinned.
- `contains` / `signed_distance` / `mirror` take `(3, N)` and return `(N,)` / `(N,)` / `(3, N)` — pinned.
- Errors are `ValueError` — pinned.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Catching test |
| --- | --- | --- | --- | --- |
| 1 | Mirror chain applied in reverse order | Indistinguishable on parallel panels, the case everyone tries first | "mirroring the source position about each panel of the sequence in turn, in that order" | `two_perpendicular_panels_order_matters` |
| 2 | Occlusion test uses a closed interval | The obvious `0 <= t <= 1` blocks every segment at its own reflection point | "strictly between the segment's endpoints" | `reflection_not_self_blocked` |
| 3 | Only the last reflection point checked | Textbook shortcut for convex rooms | "every reflection point ... lies inside its own panel" | `order_two_first_point_off_panel_invalid` |
| 4 | Amplitude keeps the direct distance | Spreading loss silently taken from `rm` | "scaled by the amplitude divided by the path length" | `reflection_amplitude_uses_path_length` |
| 5 | Sequences with consecutive repeats kept | Naive product enumeration | "no two consecutive entries are equal" | `sequences_exclude_consecutive_repeats` |
| 6 | `amplitude` zeroed for invalid paths | Conflating the two outputs | "reported for every sequence whether or not the path is valid" | `amplitude_reported_for_invalid_path` |
| 7 | Direct path never blocked | Only reflections get an occlusion test | "the direct path can be blocked as well" | `direct_path_blocked_by_panel` |
| 8 | Reference distance follows the panels | `r0` looks like it should match | "the reference distance stays a direct distance" | `transfer_matches_base_environment` |

Traps 1-3 are interdependent: repairing 2 exposes 3, and 1 moves every image so 3 never fires until it
is fixed.

Mutation proof (each defect implemented in the reference, suite re-run, then reverted; baseline
160 passed):

| Mutation | Tests killed |
| --- | --- |
| mirror chain reversed | 2 |
| crossing uses a closed interval | 24 |
| only the last reflection point checked | 1 |
| no occlusion test | 6 |
| consecutive repeats kept | 13 |
| spreading uses the direct distance | 5 |
| amplitude zeroed for invalid paths | 1 |
| `image_velocity` mirrors like a position | 2 |
| impulse response rounds the delay | 1 |
| blocked direct path kept in the transfer | 1 |
| autopower removed per path instead of per microphone | 1 |

## 12. Tier + category

- Tier: Olympus
- Sub-rank: Olympus-Good
- Category: feature-request (net-new public classes and methods)

## 13. Predicted Nova pass rate

- Predicted 10% - 20%.
- Reasoning: five corpus levers stacked, eight named traps of which three are interdependent, exact
  numeric assertions with an independent oracle, and a cross-file wiring requirement. The core idea
  (image sources) is known, which keeps it above zero; the bespoke contract and the occlusion and
  ordering rules are what agents miss.

## 14. Quality gate

- [x] Repo understanding 5/5 — pipeline `SamplesGenerator -> PowerSpectra -> SteeringVector ->
      Beamformer`, subsystems `sources` / `spectra` / `fbeamform` / `tbeamform` / `grids` +
      `environments`; entanglement at `Environment.apparent_r`, `SteeringVector`, `TimeOut.result`;
      pytest with `pytest-cases` and `pytest-regtest`, tests in `tests/unittests`; template
      `tests/unittests/test_grid.py`
- [x] Existing PR / issue check: 0 hits (`reflection`, `image source`, `ground`, `mirror`, `boundary`,
      `hard wall`, `multipath`, `refraction`, all states, PRs and issues)
- [x] Closest approved problems opened: `pvlib-loss-attribution`, `skrf-transient-simulation`
- [x] Corpus recipe satisfied (5 levers, oracle planned, 8 traps, signatures pinned, not a portable spec)
- [x] Title verb-led, names the subsystem
- [x] Shape declared
- [x] Public API surface complete
- [x] Canonical output form spelled out
- [x] <= 1 codebase-inferable requirement
- [x] Description in corpus word band, plain prose, no headers
- [x] File footprint against real files
- [x] Test outline, 4-block layout, scenario names
- [x] Signatures pinned
- [x] Traps with pre-empts and catching tests
- [x] Not pattern-followable — no reflection support anywhere in the repo

## Why this is not a duplicate

Closest approved: `skrf-transient-simulation` (numeric RF signal processing, but a time-domain
transform of network parameters, no geometry) and `pvlib-loss-attribution` (Python scientific pipeline
decomposition, no geometry, no propagation model). Nothing in the approved or rejected corpus touches
acoustics, image sources, specular geometry, or acoular. Repo never used locally.

Predicted iteration cycles: 2
