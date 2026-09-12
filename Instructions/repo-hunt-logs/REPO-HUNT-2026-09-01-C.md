# REPO-HUNT 2026-09-01-C — proven-pool hunt, 18 repos triaged, 3 seam-audited

Third hunt of the day. Ran Stage 0-bis (mine the proven-repo pool) over 18 repos at 1-3 subs, with
the mechanical gates, CI-green gate, commit-stream classification and Stage 2b-bis PR-author
profiling done in parallel per repo, then Stage 3/3b seam + absorption audits on the three cleanest.

**Shortlist: lyon (RANK 1, S-C inversion) > acoular (RANK 2, S-B) > sfepy (RANK 3, S-G/S-F).**
Reserves: smoltcp, scikit-fem, pvlib. Handoff to `olympus-author` still owes Gate 1 / Gate 6 / Gate 7b
PR-DIFF / Gate 8 / Gate 9 on the chosen pick.

---

## ⭐ MAIN FINDING — the proven scientific-Python pool is being mined SYSTEMATICALLY

Stage 2b-bis found competitor-signature accounts on 11 of 18 repos. Ten distinct accounts, several
sharing targets that are OUR corpus repos (taplo, petl, enmime, dnsjava, python-pathspec, voluptuous),
so this is one pipeline, not coincidence. `binggao1230` — read as a genuine contributor yesterday
because it carries a real name — filed ~30 surgical fixes in Aug 4-16 across palette, koanf,
dnspython, jsonpickle, TatSu, PhpSpreadsheet, gosnmp, taplo, pyshp, petl, phonenumbers, mailparse,
pyCGNS, foamlib AND scikit-fem, scikit-rf, MetPy, mpmath. **A real name does not clear an account;
scatter across unrelated niche libs is the discriminator.**

| Account | Signature | Repos hit this session |
|---|---|---|
| steps-re | 2 followers, no name, 113 repos | PlasmaPy (merged #3327), thermo, biotite, sunpy, scikit-bio ... |
| binggao1230 | real name, 770 repos, 30 PRs in 12 days | scikit-fem, scikit-rf, MetPy (x3), mpmath (x4) |
| sapunyangkut | created 2026-07-11, 0 followers, ~30 PRs on one day | scikit-rf; satpy, csvkit, nmrglue, pycalphad, SALib, trackpy, rioxarray |
| Mohit-Ak | one fix/day Aug 15-Sep 1 | PlasmaPy (2 merged); swarms, fastmcp, fiftyone, nextflow, pycbc, cobrapy, sunpy, scanpy |
| Sanjays2402 | 709 repos, ~50 unrelated libs | mpmath, QuantEcon; rdflib, fonttools, lark, dulwich, pandera |
| deepakganesh78 | no name, 1 follower, ~45 libs | QuantEcon; body-parser, chi, gin, tablib, tqdm, networkx |
| youdie006 | "KBS", 315 repos, ~25 libs Go/Py/C/Ruby | verde (spline.py); chroma, bitset, hjson-go, msgp, speedate |
| ChrisJr404 | 610 repos, ~25 PRs on 2026-08-26/27 | mp4ff, numbat; enmime, dnsjava, taplo, boa, hickory-dns, gatus |
| karpovantonme | bio "driftkit", ~25 PRs in 2 weeks | moov-io/ach; qutip, felupe, RustPython, qdrant, keras |
| Jorge-Polanco-Roque | owns a repo named `contribution-pipeline` | numbat; harper, RustPython, sktime, tract, polars |
| nagendramohan, manduinca | weaker | numbat; MetPy |

**Clean on 2026-09-01:** sfepy, acoular, lyon, smoltcp, rust-minidump, customasm, tinywasm, avo,
pvlib (one weak), scikit-fem (one visit), QuantEcon (trivial only).

---

## Triage table (18 repos)

| Repo | ★ | Lic | CI tests | Stream (12mo) | Competitor | Verdict |
|---|---|---|---|---|---|---|
| nical/lyon | 2596 | MIT/Apache | green | 38, all bug fixes, 0 open PRs | none | **ALIVE** — algorithms/path/geom cold; tessellation consumed (3 subs) |
| acoular/acoular | 650 | BSD-3 | green | 109, infra-heavy; CMF/SBL lane hot | none | **ALIVE** — tbeamform, sources, trajectory, signals cold |
| sfepy/sfepy | 838 | BSD-3 | green | 240, capability-consuming by rc (fields, LCBC, homog) | none | **ALIVE** — solvers/ts_*, iga, dg, shells cold |
| smoltcp-rs/smoltcp | 4582 | 0BSD | green | 211+, 17 capability PRs open | none | ALIVE-narrow: storage, udp/dhcpv4, sixlowpan; penalty band |
| kinnala/scikit-fem | 653 | BSD-3 | green | 25, ~1 feature/mo | binggao1230 x1 | ALIVE: mapping/refdom/quadrature, hex/wedge, models |
| pvlib/pvlib-python | 1652 | BSD-3 | green | 140, capability-consuming | weak | ALIVE: solarposition, shading, clearsky, soiling; reference-model-port risk |
| rust-minidump | 510 | MIT | green | 46 maintenance | none | ALIVE marginal (zero star margin) |
| QuantEcon.py | 2394 | MIT | green | 59 | Sanjays2402 (trivial) | contested-alive; textbook-code repo = port risk |
| mpmath | 1203 | BSD-3 | green | 300+, very hot | binggao1230, Sanjays2402 | CONTESTED |
| scikit-rf | 927 | BSD-3 | green | 292, capability-consuming | binggao1230, sapunyangkut | CONTESTED |
| PlasmaPy | 708 | BSD-3 | green | 201 (124 lockfile bumps) | steps-re, Mohit-Ak (merged) | CONTESTED |
| MetPy | 1439 | BSD-3 | green | 300 (263 dependabot), 0 features | binggao1230 x3 | CONTESTED, feature-dormant |
| pyamg | 653 | MIT | green (Mar) | 18 maintenance, idle 5mo | none | CONTESTED by 9 stale capability PRs |
| Eyevinn/mp4ff | 653 | MIT | green | 136, 53 feat | ChrisJr404 | CONTESTED; defrag PRs kill our own progressive pick |
| moov-io/ach | 560 | Apache | green | 249 (mostly bumps) | karpovantonme | CONTESTED; #1724 v2 validation diff public |
| numbat | 2675 | Apache/MIT | green | 197, capability-consuming | 3 accounts | CONTESTED (3 subs already) |
| customasm | 1056 | Apache | green (Apr) | 34, all maintainer | none | self-contested (3 folders); diagn/syntax left |
| verde | 666 | BSD-3 | **RED on main** (sklearn 1.9, #558) | 27, near-dormant | youdie006 in spline.py | DEAD-for-now |
| lifelines | 2607 | MIT | green but nothing ran in 6mo | 18, dormant | hass-nation, Qayad-Ali weak | near-DEAD |
| avo | 2988 | BSD-3 | green | 14, ALL bot; last human commit 2024-12 | none | DEAD (corpse by Requirement 6) |
| tinywasm | 587 | Apache/MIT | green | 149, single-author rewrite on `next` | none | DEAD for now (every subsystem hot, nightly toolchain) |

---

### nical/lyon — ★2596 — RANK 1

- **URL / stars:** https://github.com/nical/lyon — ★2596 (penalty band starts at 5000; fine)
- **Language:** Rust, pure; algorithms deps = lyon_path + num-traits; `no_std` crate
- **Domain:** 2D vector path geometry (builder, path model, algorithms, tessellator)
- **Open issues / PRs:** 18 / **0**. Licence MIT + Apache dual (files read by prior picks)
- **Last commit:** 2026-08-31 (walk.rs loop guard, maintainer)
- **Tests:** inline `#[test]` at file bottom, behavioural through public API, no randomness; approved picks used `crates/<crate>/tests/<name>_<hex>.rs` + `cargo test -p <crate> --test <file>`
- **Baseline determinism:** CI green 6/6 on 08-31; run 3x locally at author time (owed)
- **Docker:** Pattern A, reusable verbatim from `approved-problems/lyon-*` (`olympus-base-rust`, `cargo fetch --locked`, examples/bench/cli excluded from workspace)
- **Architecture:** crates geom (8.8k) / path (7.4k) / algorithms (4.2k) / tessellation (33k, CONSUMED) / extra
- **Lane density:** tessellation = 3 of our subs (arcs-join, fill-internal-vertices, rejected stroke-to-fill). algorithms untouched since 2024-10 except rect.rs 2026-03-08, walk.rs 08-31 guard. No branch families, no open PRs at all
- **Self-collision:** both approved picks + the rejected one are tessellation; algorithms/geom/path is a different subsystem class
- **Prior art (issue+PR search, bodies via search API):** "rounded rectangle ellipse recognize detect circle" = 0 hits; "rect" = only bounding-rect work (#48-#97, #376, #390) and #578 negative-winding rounded rect. No issue asks for shape recognition. Existing `to_axis_aligned_rectangle` (rect.rs:44, PR #768 "inspired from skia") is the SIBLING, rectangles only, 147 eff
- **Missing machinery:** bezier chain -> circular-arc recognition (`grep -rnE "from_cubic|fit_arc|is_arc|arc_from|circle_from"` = only `SvgArc::to_arc`); any rounded-rect / ellipse detector (`grep -rniE "rounded|ellipse" rect.rs` = 0)

**TRAP SEAMS:** F-15 present (builder.rs:1523/1589 `CONSTANT_FACTOR = 0.55191505`; agents key on the constant, SVG-arc and rounded-polygon corners defeat it), F-10 present (Winding decides which corner gets which BorderRadii field; asymmetric radii fixtures), F-6 present (zero-radius corners emit no curve, degenerate cubics are lines: both "sharp"), F-9 tolerance semantics (rect.rs:245), F-11 start-point-mid-corner splits one arc across Begin/End (wrap-merge vs run counter rect.rs:169), F-17 risk (test in contract nouns, not event counts), F-14 `#[non_exhaustive]` options. F-12 weak (inline tests drive public API).

**Thesis T1 — recognise rounded rectangles and ellipses by inverting the builder's shape emitters (S-C).** `to_rounded_rectangle(path, options) -> Option<(Box2D, BorderRadii, Winding)>` and `to_ellipse/to_circle` for any start point, either winding, fill or stroke semantics as `to_axis_aligned_rectangle`, corners circular within `tolerance`, returned radii post-clamp so `add_rounded_rectangle(result)` re-recognises identically (round-trip idempotence oracle). Files: geom/cubic_bezier.rs + quadratic_bezier.rs arc fit (~90), algorithms/rect.rs (~230), algorithms ellipse (~100), lib.rs. **~400-450 eff, 4-5 files, 3 crates.** Derivative-magnet LOW-MED: Skia's `isRRect`/`isOval` are flag-based not geometric, no issue names it; still run Phase 2 on the capability name at author time.
- T2 fallback: hatcher fill-rule + global row phase (#890, maintainer-welcome) + attributes, ~280 eff but single file.

**Risks:** lyon at 3/6 subs (quota fine; check ≤3/week); T1 sits next to a Skia-named feature class; tolerance semantics must be fully stated (fairness); geom crate arc-fit could be argued "textbook" — keep the invention in the recogniser, not the fit.

---

### acoular/acoular — ★650 — RANK 2

- MIT? no: **BSD-3** (verified by prior pick). Pure Python (numba/traits/scipy), `uv.lock`, Dockerfile reusable verbatim from `acoular-reflecting-panels`
- 43 issues / 8 PRs (5 capability, all TU Berlin lab). Stream: 109 commits, infra-heavy; hot only in fbeamform CMF/SBL. No competitor
- **Self-collision:** our pick = environments.py reflections (read-only now). tbeamform/sources/trajectory/signals cold (trajectory.py eff 29; last touched 2 commits)
- **Prior art:** PR #536 (CLOSED draft, +337 `directivity.py`) kills any DIRECTIVITY thesis. Searches for flow/moving-source/Doppler/time-varying convolution: empty. #171 "Passby tools" open, empty body
- **Test harness constraint (decisive for design):** pytest-regtest with **441 snapshots** auto-covering every `Generator` subclass (`tests/regression/test_generator.py`, `SKIP_DEFAULT` list). A NEW Generator class with a `source` trait enters the snapshot case with no snapshot => base regression. Prefer default-off traits on EXISTING classes; the snapshots then pin default behaviour bit-for-bit (free S-D trap). Also `test_classes.py` sets every trait to 0.1/False/1/middle-enum; `test_result_generators.py` asserts block-size independence

**Seams (all present, file:line in the audit):** F-2 Newton retarded-time loops sources.py:1121/1383/1707; F-3 `prepadding` only on moving sources; F-6 `MovingLineSource` "assume Mr is the same" :1786; F-9 nearest-neighbour emission vs linear-interp reception; F-10 dispatch by class-NAME string tbeamform.py:168; F-14 `except IndexError: break`; F-15 `epslim`, `+pi/30`; F-17 per-block `rmax` clip tbeamform.py:817.

**Thesis T-A — moving sources and the trajectory beamformer in a convected medium (S-B + S-F).** `MovingPointSource`/`Dipole`/`LineSource` and `BeamformerTimeTraj`/`CleantTraj` honour `UniformFlowEnvironment` flow: retarded time solved in the moving medium, Doppler/`conv_amp` from medium-relative Mach, beamformer focusing is the exact inverse (source ⇄ beamformer round trip = differential harness). Today: solver is Euclidean and reads only `env.c`; `MovingLineSource` is INCONSISTENT (Euclidean emission, flow-corrected `apparent_r` :1783); `BeamformerTimeTraj` uses convected delays :418 but flow-free `_get_macostheta` :338. Files sources.py (~140), tbeamform.py (~70), trajectory.py (~30), + GeneralFlow degradation (~50). **~250-300 eff, 3-4 files.** Traps interdependent: `(1-Mr)` denominator in Newton; fix source without beamformer fails peak position, fix delays without `conv_amp` fails level while position passes (misdirecting); 441 snapshots must stay bit-identical for plain `Environment`. Derivative-magnet MEDIUM ("Doppler in moving medium" is textbook) — contract must be stated in `trajectory`/`conv_amp`/`rvec`/`apparent_r` nouns.
- T-B fallback: time-varying partitioned convolution for a source moving through an IR field (~260 eff, defined-behaviour risk).

**Risks:** LOC is at the tight end (250-300, floor 200); physics-convention ambiguity is the fairness risk; second pick in a repo where our first landed at 7.7% is a calibration asset.

---

### sfepy/sfepy — ★838 — RANK 3

- BSD-3, 79 issues / 3 PRs (all maintenance), CI green 7/7, 240 commits (rc lands a subsystem-level feature monthly in fields/LCBC/homogenization/hyperelastic — AVOID). No competitor. 11 Cython exts (scikit-build + cmake); thesis touches pure-Python `solvers/` + `problem.py` only
- **Self-collision:** `sfepy-modal-analysis` = discrete/modal + eigen. solvers/ts_* untouched
- **Cold proof:** `ts_controllers.py:128 aux = unpack(vec0)` is a `NameError` whenever `guess_dt0=True` — nobody has run it
- **Seams:** F-9 strong (controller `Struct(u_err,v_err,emax,result)` printed then dropped ts_solvers.py:730; rejected substeps never counted); F-10 strong (`adapt_time_step` accepts the NON-converged iterate on the dt floor :294); F-14 17 give-up exits (Newton `condition=2` at i_max, callers proceed); F-15 ABSENT (ED reject loop :718 has no rejection cap, no min-dt: infinite loop if emax>1 forever); F-6 `set_time_step(update_time=True)` rewrites `times[step]` ts.py:193 vs `set_state` assert `len(times)==step+1` :158

**Thesis A — accountable adaptive time stepping (S-G + S-F + S-D):** per-step ledger in `status`, no silent acceptance on the floor, rejection cap + min-dt with distinct error, final step clamped to `t1` (today `advance` overshoots, ts.py:198), controller state (`adt.red/wait`, `emax0/emax00`, `count`) through `save_restart`/`load_restart`. Files ts_controllers.py (~90), ts_solvers.py (~120), ts.py (~40), solvers.py (~15), problem.py (~60). **~325 eff, 5 files, 2 packages.** Traps: clamp -> `set_time_step` -> `clear_lin_solver` stale constant matrix (ts_solvers.py:733); ledger keyed on `times` double-counts, keyed on step breaks restart assert; two `is_break=True` exits; `_TimingNLS` sorts status keys into CSV columns. Derivative-magnet MED-LOW.
- Thesis B fallback: Newton stagnation/divergence diagnostics that `ts.adaptive` acts on (~275 eff, 6 files; `conv_test` shared by semismooth_newton + oseen).

**Risks:** less "domain mathematics" than A/B above — it is solver engineering, so the PRIME-DIRECTIVE difficulty story rests on the interdependence, not on a missing model; Cython build in Docker is a cost (agents never rebuild, but the image must).

---

## Reserves (not audited)

- **smoltcp** — 0BSD, ★4582 (penalty band), no competitor, but 17 capability PRs open and JPDye lands a TCP PR weekly; open #1200 overlaps our own approved ICMP/PMTU pick. Cold: `storage/`, udp/dhcpv4 socket semantics, sixlowpan/ieee802154. Only if a pick lives entirely there.
- **scikit-fem** — clean bar one binggao1230 visit; cold mapping/refdom/quadrature, hex/wedge/tet meshes, element_global, models. Our hanging-nodes pick read 0/5 twice (calibration warning).
- **pvlib** — clean-ish; cold solarposition/spa, shading, clearsky, soiling. But pvlib is a published-model reference library (colour-science class) — every pick risks saturated-reference-port.

## Dead / do-not-re-pick this quarter

avo (bot-only commits since 2024-12 = corpse), tinywasm (mid-rewrite on `next`, every subsystem hot), verde (red baseline #558 + competitor in spline.py), lifelines (dormant 6 mo, two rival-looking authors), mp4ff (defrag PRs #557/#560/#561 + issue #548 make our own progressive-writer exclusivity-dead), numbat (3 competitors + every language lane under maintainer PR), pyamg (9 stale capability PR diffs blanket classical/relaxation/krylov/amg_core).

## Method notes

- Fan-out worked: 7 triage agents × 3 repos in ~7 min wall, then 3 seam audits in ~9 min. Total hunt ~45 min.
- `gh api search/issues` in a loop hung past 2 min (secondary limit); `gh search issues --include-prs` with `timeout` is the reliable form. `--state all` is not valid for `gh search issues`.
- Requirement-7 CI gate cost one call per repo and caught verde (red on main) before any clone.

---

# STAGE 6 HANDOFF — lyon T1 gate results (all run 2026-09-01, verdict CLEAR)

Every gate PICK-FILTER still owed after the hunt has now been run. **The pick is scope-locked and
ready for `olympus-author`.** Clone left pristine at `worktrees/lyon` @ `994526f` (2026-08-31);
`git status --porcelain` empty; target 149M.

| Gate | Verdict | Evidence |
|---|---|---|
| 1 BEHAVIORAL-F2P-GAP | **PASS** | `to_axis_aligned_rectangle(rounded_rect, fill(0.01))` -> `None`. Reproduced through the public API on a path built by the repo's own `add_rounded_rectangle`. Repro kept at `scratchpad/lyon_gate1_repro.rs` |
| 2 SATURATION | PASS | lyon in no dead section of `SATURATED-REPOS.md`; not platform-flagged |
| 4 LOC | **PASS, verify at design** | sibling `rect.rs` = 447 raw / 292 eff, of which 172 lines are inline tests -> **~170 eff for the sharp-rect recogniser**. Full pick sketches 380-500 eff (arc fit 90-120 in geom, rounded-rect recogniser 200-260, ellipse/circle 90-120). Clears the 200 floor with margin; the 400+ band is plausible but NOT yet proven - sketch the real diff before scope-lock |
| 5 COLD-NOT-LIVE | **PASS, unusually strong** | `git log -- crates/algorithms/src/rect.rs` = **2 commits ever** (`6aa2fdb` 2022, `1a1e437` 2026-03-08). **The whole repo has ZERO open PRs** (`gh pr list --state open` -> 0) |
| 6 REPRODUCE-ON-BASE | PASS | as Gate 1, via `cargo test -p lyon_algorithms --test gate1_repro` |
| 7 DEDUP | PASS | no "recognise a shape from a geometric stream" or "fit arcs to curves" capability in `approved-problems/`, `problems/`, `rejected/`, or the `reference/` sibling snapshot |
| 7b EXCLUSIVITY | **PASS** | zero open PRs, so no file set to overlay. Every feature-class search empty (`rounded rectangle recognize`, `detect shape path`, `is_rounded_rect`, `to_ellipse` all 0 hits, against live positives for bare `rectangle`=20 / `ellipse`=13). **PR #768** (the one that ADDED rect.rs, nical, merged 2022) has body "Inspired from skia.", **zero comments**, and its diff rejects any curve leaving the from->to axis - no rounded corners, no ellipse, no arc fit, no `BorderRadii`, no winding. PR #950 is a 2-line tightening |
| 8 DEFINED-BEHAVIOR + philosophy | **PASS, positive signal** | nical on #846: *"If your implementation is general enough ... we could add it to lyon_algorithms"*; on #494: *"I would definitely love to receive pull requests for features like this!"*. The only "out of scope" statements (#185, #470) are about the TESSELLATOR. `lyon_algorithms` is the declared home for path utilities and nical wrote the existing recogniser himself. #698 "1.0 TODO" lists no recogniser on the roadmap |
| 9 FLAKY | **PASS** | `cargo test -p lyon_algorithms -p lyon_geom -p lyon_path` = 158 tests green; 3 runs byte-identical once the timing text is stripped; per-test name+status hash identical. No RNG in any of the three crates |
| 10 QUOTA | PASS | lyon = 3 folders (2 approved + 1 rejected) of the 6 cap |

## ⭐ The sibling-ecosystem check passes for a MECHANICAL reason, not merely an absence

**Skia's `SkPath::isRRect` / `isOval` / `isArc` are NOT geometric** - they read `fIsRRect` / `fIsOval`
flags cached in `SkPathRef` at construction by `addRRect`/`addOval`. Only `isRect` walks the verbs,
and **that is exactly the one nical already ported** (#768). So the famous-tool well is dry for the
extension. And **lyon's `Path` has no such cached flag**: `grep -rniE "is_rect|is_oval|is_rrect|
shape_hint|cached_shape" crates/path/` = zero hits over the whole crate. The construction-flag
shortcut is structurally unavailable, so a solver MUST do it geometrically. No dependency provides
arc fitting either (`algorithms` = lyon_path + num-traits + serde; `geom` = euclid + arrayvec +
num-traits + serde; no kurbo/tiny-skia/pathfinder anywhere in the manifests).

⚠️ Carried caution: `rejected/lyon-stroke-to-fill` died because nical pointed at an external
license-compatible implementation. I searched that lens - every `pathfinder` / `tiny-skia` / `kurbo`
mention in the tracker clusters on stroke-to-fill, the tessellator and curve intersections. **None on
shape recognition, rounded-rect detection or arc fitting.**

## Trap material MEASURED on base (not predicted) - all inherent, none bolted on

Printed by the Gate-1 repro; these are the discriminators the design should be built around.

1. **One circle, TWO emissions, both from the public API.** `add_circle(c, 20, Positive)` emits **4
   cubics** using `CONSTANT_FACTOR = 0.55191505` (`builder.rs:1522`); `add_ellipse(c, vector(20,20),
   0, Positive)` emits **8 quadratics** from `Arc::for_each_quadratic_bezier` (`builder.rs:626`). An
   agent that recognises by matching the cubic control-point offsets passes every circle test and
   fails every ellipse-form test. This is F-18/F-15 made fair - both forms are producible by the
   repo's own API, so the contract can demand both without hiding anything.
2. **The ellipse form does not close exactly.** Last point `(70.0, 50.000004)` vs first `(70.0,
   50.0)`. Recognition must be tolerance-driven; exact comparison dies here.
3. **Radii clamping is sequential and lossy** (`builder.rs:1570-1589`): `min(min_wh)` then FOUR
   pairwise clamps in a fixed order (tl+tr>w, bl+br>w, tr+br>h, tl+bl>h). The recogniser must
   return POST-clamp radii, and `add_rounded_rectangle(recognise(p)) == p` is a genuine fixpoint
   oracle. Measured: input `tl=tr=80, bl=br=5` on a 100x60 box yields top radii 50, bottom 5.
4. **Degenerate zero-length edges appear in valid output.** That same input emits
   `Line { from: (50,0), to: (50,0) }` because the two top radii exactly consume the width. A
   recogniser that requires four non-degenerate edges rejects a legitimate rounded rectangle (F-6).
5. **Zero-radius corners emit no curve at all** (`if tl > 0.0`), and an all-zero rounded rect **is
   already accepted** by the existing recogniser (`-> Some(Box2D((0,0),(100,60)))`). The new
   recogniser must agree with the old one on that input - a consistency constraint between two
   functions, which is where agents break things.
6. **Winding reverses everything.** Positive starts at `(0, 4.0)` (top-left radius 4), Negative at
   `(0, 48.0)` (bottom-left radius 12), and the corner traversal order flips. The mapping from
   traversal position to `BorderRadii` field depends on winding (F-10). Symmetric-radii fixtures
   mask the bug entirely; asymmetric ones kill it.

## Docker + harness: reusable verbatim

`approved-problems/lyon-fill-internal-vertices/Dockerfile` works with one word changed:
`cargo build -p lyon_tessellation` -> `-p lyon_algorithms -p lyon_geom`. Base image
`olympus-base-rust`, `cargo install cargo2junit --version 0.1.15`, `cargo fetch --locked`,
`chmod -R a+rwX /app`, `CMD ["/bin/bash"]`. Its `test.sh` (mode 100755, `--output_path`, explicit
`NEW_TEST_NAMES` list, and a synthetic build-failure JUnit XML fallback) is the template; base mode
becomes `cargo test -p lyon_algorithms -p lyon_geom -p lyon_path --lib`. New tests go in
`crates/algorithms/tests/<name>_<hex6>.rs` (no `tests/` dir exists in that crate today) and
`crates/geom/tests/` for the arc fit.

## What DESIGN.md must argue explicitly

- **Inversion is the differentiator against our own `lyon-arcs-join`**, which is `geom` arc machinery
  in the EMITTING direction. Say so; the similarity check will look there.
- **Tolerance semantics must be fully stated** without handing the fit: what "circular within
  tolerance" means, sampled where, and that returned radii are post-clamp.
- Keep the invention in the RECOGNISER. A bezier-to-arc fit on its own is arguably textbook; the
  repo-specific content is reproducing `add_rounded_rectangle`'s clamp, corner order and winding
  mapping from an event stream.

---

# ⛔ POST-HUNT CORRECTION — lyon T1 REJECTED at the olympus-author Phase-3 guard

The Stage-6 handoff above stands on its facts: every mechanical gate really did pass, and the trap
material really was measured on base. **The pick is still dead**, and the reason is not in any of the
ten gates.

`failure-patterns.md § 5` lists as an explicit anti-target *"anything a post-pass over the public
event/AST stream can do end to end"*, and a shape recogniser IS that. It also trips `TOO-EASY.md`
Pre-Pick Guard #2 (single-subsystem fully-specified transform, zero hidden-integration walls) and the
skill's own Phase-3 Step C reject, *"solvable by a standalone new file with minimal wiring"*. Worse,
its four measured traps are **independent**: fixing the curve-form handling does not surface the
winding bug, which does not surface the clamp bug. Independent traps are single-shot-fixed (L2/L3).

Full case study, with the measured trap evidence preserved for reuse:
`Instructions/TOO-EASY.md § RECOGNISER / POST-PASS-OVER-THE-PUBLIC-STREAM`.

**The method lesson, which is the valuable part.** This hunt ranked candidates on repo cleanliness —
cold lane, zero open PRs, no competitor account, green CI, clean prior art. That is the right way to
find where you are ALLOWED to author. It says nothing about whether the capability is GLOBALLY
COUPLED, which is what decides difficulty. The two axes are independent, and lyon scored top on the
first and bottom on the second. **Run the Phase-3 death-class guard on the hunt's RANK 1 before
handing it to olympus-author** — add it to Stage 6, not to the author phase, so a full gate sweep is
not spent on a structurally dead shape.

Consequence: the shortlist re-ranks on difficulty structure, and the two survivors are the ones with
a shared kernel feeding several surfaces —

1. **acoular T-A** — one retarded-time kernel used by three moving-source classes and inverted by two
   trajectory beamformers, so a fix to the source alone regresses the round trip (S5 dual-path), with
   441 regtest snapshots pinning the still-medium path (S3).
2. **sfepy A** — one stepper feeding the controllers, the restart path and the Newton status, with a
   measured chokepoint (`set_time_step` -> `clear_lin_solver`) and 17 existing give-up exits (F-14)
   and no rejection cap (F-15).

Both go through the absorption + LOC probe before either is scope-locked, because both are at risk of
being thin call-throughs over machinery the repo already owns.
