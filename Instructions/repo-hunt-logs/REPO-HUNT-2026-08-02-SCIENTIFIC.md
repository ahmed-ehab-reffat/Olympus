# Repo hunt 2026-08-02 (B) — scientific / numeric targets in the `lyon-arcs-join` family

Brief: find a repo that can carry a problem of the same CHARACTER as the approved
`lyon-arcs-join` — a numeric/geometric domain where the required construction is
provable rather than conventional, outputs are float-exact enough to pin with real
assertions, and the subsystem borders a famous published algorithm the repo
deliberately diverges from (F-8).

Sweeps run: 3 (35 keyword x language queries over `search/repositories`, stars
450-5000, permissive license, pushed > 2025-08). Issue window RELAXED from 100-1000
to >= 8 for every candidate below — niche scientific repos essentially never reach
100 open issues, and holding the window would have emptied the shortlist. Star floor,
license, language, and activity were NOT relaxed.

---

> **UPDATE 2026-08-02 (post-hunt, after a full feature-space sweep): RANK 1 rust-bio is
> REPO-GOOD but FEATURE-DEAD for the five picks checked.** Every repo gate passed and the
> baseline determinism was verified, but each candidate feature died: ORF six-frame to
> architecture-jump + saturated-port, myers long-traceback does not exist as a gap,
> myers text-side ambiguity measured ~50 effective LOC, pairwise convex gaps are externally
> named (derivative HIGH), and banded-vs-pairwise consistency is the "sibling Y is the answer
> key" dead class. Full detail in `Instructions/SATURATED-REPOS.md § B2`. **RANK 2 orb is now
> the live candidate.** The two rust-bio assets worth remembering: the documented Edlib
> tie-break divergence (native, fair F-8) and the two real S5 dual-path seams.

## RANK 1 — rust-bio/rust-bio — ★1821

- **URL:** https://github.com/rust-bio/rust-bio | **License:** MIT (verified) |
  **Language:** Rust, pure (deps: ndarray, statrs, bit-set, enum-map, itertools,
  bio-types, csv, serde — no `-sys`, no C)
- **Last SOURCE commit:** 2026-06-29 (`fix(pattern_matching): reject 64-symbol
  patterns in shift_and and bndm`) — **20 source commits in trailing 12 mo**
- **Open issues (no PR):** 63 | **Open PRs:** 22
- **Architecture:** `alignment/` 6.5k, `io/` 6.3k, `data_structures/` 5.9k,
  `stats/` 5.3k, `pattern_matching/` 4.8k, `alphabets/` 0.9k, `scores/`,
  `seq_analysis/`, `utils/`
- **Baseline determinism (Gate 9): PASS** — 3 identical runs, 486 unit + 2
  integration + 168 doctests, 0 failures, ~10 s suite, 48 s cold build
- **Docker:** Pattern A (`olympus-base-rust`), offline-safe, fast
- **Test style:** in-module `#[cfg(test)] mod tests` plus a `tests/mod.rs`
  integration target and heavy doctests — behavioural through the public API,
  zero mocks. A new `tests/<name>_<hex>.rs` drops straight in

**TRAP SEAMS**

| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | **yes** | `data_structures/fmindex.rs:75` `occ()` is computed from an already-built `BWT`; the suffix array that produced it is sampled away. Anything needing suffix-array positions the sampling dropped cannot be recovered by a post-pass |
| F-9 cross-stage resolution drop | **yes** | `alphabets::RankTransform` resolves symbols to ranks; `bwt.rs:186 less()` re-derives the same alphabet-order information, and `fmindex.rs:326` re-asserts the sentinel contract a third time. Three stages independently resolving one fact |
| F-10 capability cross-product | **yes** | polarity = forward vs reverse strand (`fmindex.rs:250` `BiInterval`, `:262 forward()`, `:275 swapped()`); multiplicity = single pattern vs multi-pattern search. Both axes already exist, so a new capability inherits a genuine 2x2 |
| F-8 named-algorithm override | **yes, natively** | every module borders a canonical published algorithm — Smith-Waterman-Gotoh (`alignment/pairwise/`), partial-order alignment (`alignment/poa.rs`), Viterbi (`stats/hmm/`), BWT/FM-index — and the repo's real behaviour diverges. PR #680 exists purely to document that `poa` uses linear gaps and **ignores `gap_extend`** |
| F-4 ownership trap | partial | Rust, but the structures are index-based rather than `Rc<RefCell<_>>` |
| F-2 bidirectional seam | partial | the FMD-index forward/reverse coupling is the closest thing |

**Feature theses (each spans >= 3 modules):**
1. A capability defined over rust-bio's OWN `Alphabet`/`RankTransform` model
   (e.g. an alphabet-aware transform that must stay consistent across
   `alphabets` -> `bwt` -> `fmindex` -> `pattern_matching`) — the F-9 seam pays
   for itself and the sentinel contract is a ready-made second wall.
2. Something in the `stats/pairhmm` + `stats/probs` + `scores` triangle, where
   log-space accumulation order is load-bearing and cannot be text-parsed.
3. An `alignment` capability that must hold on both the banded and full paths
   (`banded.rs` 2.4k vs `pairwise/mod.rs` 1.8k) — a built-in second axis.

**Why it matches the brief:** deep scientific domain, obscure to problem authors
(SATURATED-REPOS explicitly names bioinformatics as a preferred hunting ground),
float/log-space numerics that are load-bearing in coupled state, and the F-8
trap is native rather than manufactured.

**Risks:** **Stage 2b derivative risk is the live one.** Anything nameable by an
external standard ("add affine gaps", "add a bidirectional FM-index") is a
derivative magnet — the pick MUST be phrased in repo-internal nouns. Also 22 open
PRs: `alignment/poa.rs`, `alignment/pairwise/mod.rs` (#424, +358), `io/om/*`,
`stats/bayesian/model.rs`, `data_structures/fmindex.rs` (docs-only #679) are
touched — overlay before scope-lock.

---

## RANK 2 — paulmach/orb — ★1123

- **URL:** https://github.com/paulmach/orb | **License:** MIT | **Language:** Go,
  pure (protobuf, protoscan, mongo-driver — all pure Go)
- **Last SOURCE commit:** 2026-03-27 — 12 source commits in trailing 12 mo
- **Open issues (no PR):** 14 | **Open PRs: 1** (geojson generic properties)
- **Architecture:** 12.6k LOC over `encoding/{wkb,ewkb,wkt,mvt}` 5.7k,
  `geojson/` 1.3k, `clip/` 1.1k, `maptile/`, `simplify/`, `quadtree/`,
  `planar/`, `geo/`, `project/`, `resample/`
- **Docker:** Pattern B (`olympus-base-go`), trivial
- **Baseline determinism: NOT RUN** — no local Go toolchain; the Docker run timed
  out. Owed before scope-lock.

**TRAP SEAMS**

| Pattern | Present | Evidence |
|---|---|---|
| F-10 capability cross-product | **yes, structural** | `planar/` (Euclidean) and `geo/` (spherical) implement the SAME operations — `area.go`, `length.go`, `distance.go` — with different math, and `planar/` additionally has `contains.go` + `distance_from.go` that `geo/` lacks. That asymmetry is the cross-product cell |
| F-1 / F-9 pipeline | **yes** | `encoding/mvt/`: `projection.go` -> `clip.go` -> `simplify.go` -> `marshal.go` quantizes to integer tile coordinates; `unmarshal.go` (465 LOC) re-resolves what marshalling destroyed |
| F-5 transitive | partial | `quadtree/` + `clip/smartclip` |
| F-8 named-algorithm | partial | Douglas-Peucker / Visvalingam in `simplify/`, Mapbox Vector Tile spec in `encoding/mvt` |

**Feature theses:** a capability that must hold across the planar/spherical
polarity AND survive the MVT quantize round-trip; or one of the genuinely absent
big features — no convex hull, no polygon boolean ops, no triangulation, no
buffering anywhere in the tree.

**Why it matches:** the cleanest exclusivity picture in the whole sweep (ONE open
PR), a cold target subsystem, and Go keeps the Docker cost near zero.

**Risks:** compact-feature risk — orb is a mature 2D geometry library and the
`golang/geo` precedent in SATURATED-REPOS §B2 is exactly this shape (measured
picks came in at 49 effective LOC against a 250 estimate). **Sketch the
minimal-golden LOC before authoring.** Recency margin is also thinner: 5 months
since the last source commit.

---

## RANK 3 — georust/geo — ★1903

Deepest coupling of any candidate (`relate/geomgraph` topology, `kernels/` robust
predicates, boolean ops, `line_measures` planar-vs-geodesic duality), 127 source
commits in 12 mo, 78 open issues. A `Buffer` design draft already exists in this
workspace (`GEORUST-BUFFER-OLYMPUS-DESIGN.md`).

**Blocking concern:** ~20 open PRs and the queue is being flooded with
LLM-authored algorithm work — a five-PR stacked HDBSCAN series (#1573-#1577,
~2.4k LOC), `ball_tree.rs` (#1557), a 1.5k-LOC `compass.rs` (#1546), plus
`relate/geomgraph` (#1571, #1556), `contains_properly` (#1495, #1488) and
`line_measures` (#1561, #1334). The maintainers have opened #1568 "State policies
around agents and LLM contributions" in response. Combined with a 1900-star
flagship's HOT/COLD inversion, this is the objdiff situation forming. Pick only a
demonstrably cold `algorithm/` module and re-run Stage 2c the same day.

---

## Tier 2 — viable, each with one named caveat

| Repo | ★ | Lang · License | Src commits 12mo | Caveat |
|---|---|---|---|---|
| Axect/Peroxide | 723 | Rust · Apache-2.0 | 53 (last 2026-07-30) | Very active maintainer = Gate 5 risk; numeric library with real ODE/spline/special-function coupling but likely LOC-thin per feature |
| smartcorelib/smartcore | 940 | Rust · Apache-2.0 | 23 | ML algorithms are all textbook-named — Stage 2b HIGH unless phrased in repo-internal nouns |
| elodin-sys/elodin | 538 | Rust · Apache-2.0 | 261 | Aerospace sim + its own DSL, excellent domain, but 261 commits/12mo is a firehose |
| georust/rstar | 551 | Rust · Apache-2.0 | active | 13 open PRs incl. #41 all-nearest-neighbours and #105/#69 broad refactors; small crate, LOC floor risk |
| oxfordcontrol/Clarabel.rs | 582 | Rust · Apache-2.0 | 2 (last 2026-04-13) | Passes recency by a hair; 15 open PRs against 22 issues |
| dimforge/salva | 689 | Rust · Apache-2.0 | 1 | Effectively frozen; physics fixtures are a flakiness hazard |

---

## REJECTED this sweep — do not re-derive

| Repo | ★ | Gate failed | Evidence |
|---|---|---|---|
| **ricosjp/truck** | 1524 | **MIRROR-DEV (SATURATED-REPOS §D)** | Was **RANK 3 in `REPO-HUNT-2026-08-01.md`** and would have been authored. `.gitlab-ci.yml` present; 11 of the last 30 commits are GitLab-style `Merge branch 'X' into 'master'`; active branches reference issue **#221** (`221-least-square-bspline`) while the GitHub tracker tops out at **#128**. The issue tracker and MR queue live on GitLab, so the mandatory SIX-CHECK and the exclusivity PR-diff check **cannot run at all**. Same disqualifier as roto and cue |
| **linebender/kurbo** | 979 | Exclusivity / liveness | 27 open PRs blanketing the crate: `common.rs` (#600, #593, #588), `stroke.rs` (#597 +723, #377), `expand.rs` (#582), `arc.rs` (#557, #556, #381 +397), `affine.rs` (#589, #583), `bezpath.rs` (#565), `offset.rs` (#380), `param_curve.rs`, `svg.rs`, `ellipse.rs`, plus experimental `pathops` (#257) and cubic-intersection (#258) branches. Objdiff pattern — no cold core file left. **Also**: a kurbo stroke/offset/join pick would read as a near-sibling of our own approved `lyon-arcs-join` and invite a derivative flag |
| **bebop/poly** | 732 | **RECENCY-DEAD** | **0 `.go` commits in the trailing 12 months**; last source commit 2024-10-21. GitHub shows 2026-07-31 activity but it is a README edit, and 2026-06-09 is a CI linter bump. Exactly the mun / ichiban-prolog lie. Genuinely attractive otherwise (synthetic-biology toolkit: Zuker folding, codon optimisation, primer thermodynamics, assembly simulation) — so it will keep resurfacing |
| **jblindsay/whitebox-tools** | 1183 | **RECENCY-DEAD** | 0 source commits in 12 mo; last `.rs` commit 2025-02-07 |
| **iliekturtles/uom** | 1247 | Recency, marginal | 37 source commits inside the window but all clustered before 2025-08-30 — 11 months stale and will fail the gate outright within weeks |
| HydroniumLabs/h3o | 537 | Dead class | Faithful port of Uber's published H3 spec — saturated-reference-port |
| ejmahler/RustFFT, arkworks/algebra, Plonky3 | — | Dead class | Canonical published algorithms end to end |
| cpmech/gosl | 1877 | Not pure | Binds LAPACK/SuiteSparse/MUMPS |
| twpayne/go-geom | 971 | Contested-adjacent | 8 issues, 1 PR and cold, but a go-geom `polygonize` submission is already approved on the platform (30%), so the algorithm surface has a prior author on it |
| avhz/RustQuant, argmin-rs/argmin | 1796 / 1269 | Cool + heavy PR queue | Last source 2026-01-14 / 2025-10-02; argmin carries 29 open PRs |

---

## Owed before authoring the RANK 1 pick (`PICK-FILTER.md`)

1. **Gate 1 BEHAVIORAL-F2P-GAP** — base must produce observably wrong output.
2. **Gate 2b DERIVATIVE (the decisive one here)** — write the one-line summary the
   dedup engine would emit. If it is intelligible without rust-bio-specific nouns,
   change the pick.
3. **Gate 5 COLD-NOT-LIVE** — commit DATES on the target module, not issue state.
4. **Gate 6 REPRODUCE-ON-BASE** through the real public API.
5. **Gate 7b EXCLUSIVITY** — `CANON=$(gh api repos/rust-bio/rust-bio -q .full_name)`,
   then search PRs by feature CLASS in all states and **read the diffs**. Overlay
   the 22 open PR footprints on the planned file set.
6. **SIX-CHECK** — closed issues by feature class + maintainer philosophy +
   base->main commit overlap.
7. **Minimal-golden LOC sketch** against the >= 200 effective (Counter 2) floor
   before writing anything — the failure mode that killed three taffy picks and
   two golang/geo picks.
