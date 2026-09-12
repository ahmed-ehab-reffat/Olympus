# REPO-HUNT 2026-09-01-B — re-hunt under the corrected heuristic

Run after geometry-central and choco-solver both died at the LOC floor as MISSING-ARM-OF-A-DISPATCH
picks. This hunt applies the two corrections those failures paid for: **Stage 3b (the absorption
test — name the algorithm the repo does not already contain)** and **Stage 2b run against issue
BODIES, not titles**. It also produced a third correction, **Stage 2b-bis (PR-author profiling)**,
which is the more important output of the session.

**Targeting change.** Stop ranking on *cold + large + no open PRs* — that selects for FINISHED
subsystems. Target repos with a real DOMAIN, where a new capability means new domain mathematics,
which is what every accepted pick in `approved-problems/` actually is.

---

## ⭐ THE SESSION'S MAIN FINDING — pipeline competitors are VISIBLE

The doctrine states in three places that competing prior art "lives in the submission pipeline where
GitHub queries cannot see it" and that "a clean SIX-CHECK is not evidence." **That is true of their
submissions and false of their authors.** Problem authors file public reconnaissance PRs.

Profiling the recent PR authors on CalebBell/thermo surfaced **`steps-re`** — 2 followers, no name,
no bio, 113 public repos — with July-August 2026 PRs across **thermo, biotite, scikit-bio, sunpy,
lmfit, PyDMD, ProDy, scanpy, PyPSA, movingpandas, serpent-tools, C-Star, slmsuite, gridstatus,
GSEApy**. Every one is a niche permissively-licensed scientific library; every PR is a tight
one-bug fix (`fix: handle atol=None in pair_align`, `Fix corrupted brute() candidates for a single
varying parameter`, `fix dihedral_backbone() returning garbage angles across chain breaks`).
**`scikit-bio` is a repo we hold an approved problem in**, and three of this session's five finalists
(thermo, biotite, sunpy) are on their list.

Control case on the same repo: `binggao1230` — real name, 770 repos, a coherent CFD/aerodynamics
footprint of their own. A genuine domain contributor looks nothing like the competitor profile.

Method recorded as **Stage 2b-bis** in the olympus-hunt skill. Treat a hit as a risk weight: their
lane is occupied; other lanes in the same repo carry elevated, unmeasurable derivative risk.

**Consequence for this shortlist: the whole niche-scientific-Python cluster is contested.** That is
the same space the approved corpus lives in, so it cannot simply be abandoned — but every candidate
below is now weighted by whether `steps-re` has touched it.

---

## Shortlist

| Rank | Repo | Lang | Stars | Licence | steps-re? | Verdict |
|---|---|---|---|---|---|---|
| 1 | CalebBell/thermo | Python | 784 | MIT (file-verified) | **yes** (stream.py, pure flash) | **LEAD** — hard citable gap, Stage 3b PASSES |
| - | biotite-dev/biotite | Python | 969 | BSD-3 | **yes** (2 PRs) | contested + capability-consuming maintainer stream |
| - | sunpy/sunpy | Python | 1033 | BSD-2 | **yes** (1 PR) | contested; 211 open issues, 21 open PRs, large team |
| - | colour-science/colour | Python | 2646 | BSD-3 | no | **REJECT** — dev model IS implementing published CIE standards (`Add TLCI-2012 and TLMF-2013 quality metrics`); every pick is a saturated-reference-port |
| - | pySTEPS/pysteps | Python | 580 | BSD-3 | no | HOLD — clean of competitors, but "add nowcasting method X" is pattern-followable (many existing siblings); blending lane is hot |
| - | obspy/obspy | Python | 1332 | **LGPL-3.0** | - | **HARD REJECT** — GitHub reports `NOASSERTION`; the LICENSE file says LGPL v3.0. Read the file, never the label |
| - | MDAnalysis, mdtraj | Python | - | GPL-2.0 / LGPL-2.1 | - | HARD REJECT — licence |
| - | poliastro | Python | 1013 | MIT | - | REJECT — archived |
| - | photutils, tomopy | Python | 307 / 395 | - | - | REJECT — under the 500-star floor |

Rust/Go/C++ deep-domain sweeps (23 domain keywords x 3 languages) returned almost nothing at
>=500 stars with a permissive licence — `dimforge/salva` (fluid sim, ★692), `Clarabel.rs` (conic
solver, ★594), `elodin` (★540) were the only real hits. **That thinness is itself a finding**: the
obscure-deep-domain space this doctrine targets is overwhelmingly Python, which is why the approved
corpus is, and why the competitor above is mining Python.

---

### CalebBell/thermo — ★784 — RANK 1

- **URL / licence:** https://github.com/CalebBell/thermo — **MIT, verified by reading LICENSE.txt**
- **Domain:** chemical-engineering thermodynamics — equations of state, activity models, phase equilibrium. Extremely obscure to problem authors
- **Activity:** 146 commits/12mo, pushed 2026-07-13. Single focused maintainer (Caleb Bell)
- **Open issues without PRs:** 10. **Open PRs: 3** — the leanest queue of any candidate
- **Deps:** `fluids`, `chemicals`, `scipy`, `pandas` — all pure-Python or wheels. Pattern B, `olympus-base-python`. No C toolchain. Docker-feasible (estimate; not built)
- **Self-collision:** nearest is `approved-problems/chempy-temperature-dependent-thermochemistry`, which is pure-component property CORRELATIONS (Shomate/NASA7 Cp-H-S). Mixture phase EQUILIBRIUM is a different subsystem class. Adjacent domain, different capability

**Phase 2 (issue BODIES read, all 10 open issues).** No magnet. The tracker is data-quality
questions (#148 paraffin densities, #5 Fe2O3 missing), usage questions (#145, #132, #104), and small
bugs (#185 lazy-init race). Two maintainer statements worth carrying: `GibbsExcessLiquid` is
"brittle by the nature of the underlying math" with kinks he intends to fix (#104) — a claimed lane,
avoid; and the `Chemical` class is "a legacy class", with flashers the supported path (#180).

**Stage 3b — the absorption test PASSES, with a citation.**

```python
# thermo/flash/flash_vln.py:168
if solids:
    raise ValueError("Solids are not supported in this model")
```

`flash_vln` (vapor + N-liquid) **refuses solids outright**, while `flash_pure_vls` supports solids
for PURE components only. So **solid-liquid equilibrium for multicomponent MIXTURES is absent** —
freeze-out, solid solubility, eutectic behaviour.

**The algorithm the repo does not contain:** solid-phase fugacity from fusion properties, solid-phase
stability testing, and the multiphase SLE solve. That is new mathematics, not a call-through — the
first candidate in three sessions to pass this test with a nameable missing algorithm.

**Footprint:** `flash_vln.py` (the refusal), `flash_base.py` (phase bookkeeping), `equilibrium.py`
(EquilibriumState), `bulk.py` (aggregation over phases), plus a solid phase model in `phases/`. >=4
files in one package, cross-subsystem within the flash architecture. Existing sizes are substantial
(`flash_utils.py` 206KB, `flash_base.py` 86KB, `flash_vln.py` 31KB), so absorption risk is real but
the refusal proves the capability is not merely unwired.

**Lane heat:** **zero** commits matching solid/SLE/freeze/sublimation/eutectic/crystall across 146
commits in 12 months. `flash_vln.py`'s recent touches are 1-line cleanups inside broad refactors.
The SLE lane is unclaimed by the maintainer.

**Risks, in order:**
1. **`steps-re` has two thermo PRs** (`stream.py` zero-division; multi-liquid selection in
   pure-component flash). Different lane from mixture SLE, but the repo is being mined — invisible
   derivative risk is elevated and cannot be measured.
2. **Spec-knowability.** SLE is textbook chemical engineering; the equations are derivable. The
   `TOO-EASY.md` spec-knowable-predicate class applies to the MATHS. The counter is the acoular
   precedent (known physics, hard integration): difficulty must come from threading a solid phase
   through thermo's own phase bookkeeping, stability testing and bulk aggregation, not from the
   equations. **This has to be established before authoring, not assumed.**
3. **Scope size.** Multicomponent SLE may be much larger than one submission wants. Sketch the diff
   before scope-locking.
4. Gate 9 (flakiness) unmeasured; thermo's suite is large and numerical.

**Still owed:** Gate 1 (reproduce the refusal through the public API), the diff sketch, Gate 9, and
a decision on risk 2 — which is the one most likely to kill it.

---

# S-C SWEEP (inversion shape) — first run of the inverted method

Ran `CAPABILITY-SHAPES.md § S-C` shape-first instead of repo-first. **Sharpened S-C criterion:** the
forward transform must be driven by a USER-SUPPLIED or REPO-INTERNAL specification, so the inverse
has to interpret that same spec. That is what kept customasm's disassembler off the saturated-port
list — it inverts the *user's own ruledef*, not a fixed ISA.

**Capability identified: template extraction** — `extract(template, rendered_text) -> context`,
the inverse of `render(template, context) -> text`. Never in any spec, driven entirely by the
engine's own template AST, and genuinely ambiguous exactly where rendering was lossy.

Why the shape is strong: adjacent variables with no literal between them (`{{a}}{{b}}`) are an
**F-11 local-vs-global selection scope** seam by construction — the band-decider on customasm (9/10)
— and it is inherent here, not bolted on. Extraction and rendering are also two evaluators of one
template model that must agree (**S5/S6**), with divergence hiding in whitespace-trim, `{{else}}`
and nested blocks. A round-trip law (`render(t, extract(t, s)) == s`, least-committing context) is
one contract sentence over a combinatorial instance space (**HARDENING P1**).

## Candidate hosts, and how they fell out

| Repo | Stars | Verdict |
|---|---|---|
| **sunng87/handlebars-rust** | 1483 | **LEAD** — MIT, 60 commits/12mo, PR authors are maintainer + dependabot ONLY |
| Keats/tera | 4299 | REJECT — shipped 2.1.1 / 2.2.0 / 2.3.0 in three weeks; maintainer consuming capabilities weekly |
| flosch/pongo2 | 3084 | REJECT — **contested**, see below |
| cobalt-org/liquid-rust | 583 | HOLD — zero competitor PRs (renovate only) but non-chore commits are "make clippy happy"; verify it is not capability-frozen |
| mitsuhiko/minijinja | 2753 | REJECT — prior art, a MiniJinja macro-rest problem exists in a sibling workspace |
| participle · lalrpop · lark · erg · kcl | - | REJECT — all carry sibling-workspace prior art (`participle-longest-match`, `lalrpop-operator-precedence`, `lark-counterexamples`, `erg-chained-comparison`, `kcl-*`) |

⭐ **Stage 2b-bis fired PROSPECTIVELY for the first time, and cheaply.** pongo2's recent PR list is
four surgical parser/lexer/macro fixes filed on a single day (2026-08-29) by **`codexagents`** —
account created 2026-06-25, **0 public repos, 0 followers, name literally set to "I AM A ROBOT"**,
active only on `flosch/pongo2` and its own fork. An automated agent is working pongo2's parser core.
That is the gate catching a contested repo BEFORE the seam audit, which is what it was built for.

## handlebars-rust — gates cleared

- MIT (LICENSE read), ★1483, pushed 2026-08-12, 60 commits/12mo with real maintainer feature work
- **6 real issues, PR authors maintainer + dependabot only** — no competitor footprint
- **Phase 2 on issue BODIES: no magnet.** Nearest are #692 "Dry-run mode" (which variables *would* be
  replaced) and #565 "extracting unused parameters?" — both adjacent static analysis, neither is the
  inverse, both near-uncommented and small
- **Absorption probe clean:** `grep -rniE "fn .*(extract|match_|reverse|unrender|parse_from|infer)" src/*.rs`
  returns NOTHING. No matching machinery exists; the capability needs a new matcher/unifier
- AST is well-shaped for it: `TemplateElement::{RawString, HtmlExpression, Expression, HelperBlock,
  DecoratorExpression, DecoratorBlock, PartialExpression, PartialBlock, Comment}` (`template.rs:1099`)
- 10.8k LOC total (`template.rs` 1554, `render.rs` 1302, `registry.rs` 1549); behavioural integration
  tests in `tests/`

## Risks — the first one is the real one

1. **"Solvable by a standalone new file with minimal wiring" is an explicit Phase-3 Step-C REJECT.**
   A matcher module could be written almost independently of the rest of the crate. The pick only
   survives if extraction must mirror `render.rs`'s exact semantics — whitespace trim markers,
   `{{else}}`, block params, `@index`, partials — making it a genuine dual-path consistency problem
   rather than a bolt-on. **Establish this before scope-locking; it is the make-or-break.**
2. Fairness: the ambiguity-resolution rules (greedy vs minimal capture, loop iteration counts, which
   conditional branch) must be fully stated, and stating them must not hand the fix.
3. 10.8k LOC is a smallish host; check the diff sketch reaches 200+ effective early.
4. Gate 9, Docker, Gate 1 all unmeasured.

---

# PROVEN-POOL RUN (Stage 0-bis, first use) — LEAD: pandapower continuation power flow

First hunt started from the proven-repo pool instead of a cold sweep. Result reached in one pass.

## Pool triage

Built the pool from `Repository:` frontmatter across `approved-problems/` + `problems/` + `rejected/`
(39 repos). Rejected on the way:

- **calyxir/calyx** (2 subs, MIT ★612) — the repo is fine, but its best remaining shape is a new
  whole-program analysis + pass in `calyx/opt`, which is **exactly what our approved
  `calyx-unused-port-elimination` already is** (`analysis/port_liveness.rs` +
  `passes/dead_port_elimination.rs`). Self-collision is subsystem-level. Its backend is genuinely
  cold (mlir 16 months, resources 18) but small (4.9k LOC) and the MLIR arm's `todo!()`s target the
  external CIRCT dialect = spec-transcription. Note `rejected/calyx-cider-checkpoints` already
  probed the interpreter and died because deterministic replay-from-seed satisfies the observable
  contract — a useful shortcut-trap precedent.
- **VirusTotal/yara-x** — CONTESTED. `king-tero` (5 repos, 4 followers, no identity) filed SEVEN perf
  PRs on 2026-08-30 across parser/wasm/compiler/scanner/regex, active only there and on its own fork.
- **quickwit-oss/tantivy** — ★16021 and maintainer mid-build on calculated fields in aggregation,
  colliding with our own approved pipeline-aggregations pick.
- **tokio-rs/turmoil** — capability-consuming (turmoil-fs, io_uring, turmoil-net, fault injection).

⭐ **The PR-author gate discriminates, it does not just flag everyone.** `KS-HTK` (7 pandapower PRs)
and `HeskethGD` (5 mpmath PRs) both look like the competitor shape by volume, but their footprints
are *focused on one project family* with real identities — genuine contributors. The competitor
signature needs BOTH no-identity AND scatter across unrelated niche libraries.

## e2nIEE/pandapower — LEAD

- **Proven:** 1 approved sub (`pandapower-reliability-assessment`) of a 6 cap
- **Licence: BSD-3-Clause, verified by reading LICENSE.** GitHub reports `NOASSERTION` purely because
  of the multi-line University of Kassel / Fraunhofer copyright block; there are **no rider
  conditions**. Same "the label lies" lesson as obspy, opposite direction — obspy's `NOASSERTION`
  hid LGPL-3.0 and killed it; pandapower's hides a clean BSD-3
- ★1252, pushed **2026-09-01**, 125 real open issues, deep domain (power systems)
- **No competitor** (see above)

**Capability: continuation power flow / voltage-stability analysis** — trace the PV curve as load
scales, locate the nose point, report the maximum loadability margin.

**Shape:** S-B missing domain effect — the largest approved cluster (~16), and the shape our own
acoular, turmoil, smoltcp, metpy, pvlib and skrf picks all take.

**Stage 3b absorption — PASSES, verified locally (not by code search, which OR-s phrases and lied):**

| probe | files |
|---|---|
| `continuation` | **0** |
| `voltage_stability` | **0** |
| `loadability` | **0** |
| `harmonic` | **0** |
| `arc_flash`, swing/transient stability | **0** |

The three `cpf` hits are `dcpf` (DC power flow: `pf/run_dc_pf.py`, `pypower/dcpf.py`,
`pypower/makeBdc.py`) — pandapower's vendored pypower does **not** ship `runcpf`.

**Make-or-break — PASSES.** `pandapower/pypower/newtonpf.py` is monolithic and formulation-specific,
hard-coded around FACTS/SVC/TCSC/VSC, DC buses and TDPF. A continuation **cannot wrap it**: the
augmented system adds a continuation parameter row/column and must switch parameterization at the
nose, where the ordinary Jacobian is singular in lambda. The reusable part is the Jacobian
construction (`pf/create_jacobian.py` + numba variants), so the pick **builds on existing machinery
rather than around it** — the acoular shape.

**Phase 2 (feature class, all states) — CLEAN.** No issue asks for continuation power flow, voltage
stability, PV curves, loadability or the nose point. **Nobody has requested it**, so it is an
invention rather than a tracker-named feature — which is what `RULES.md` asks for and what dodges the
open-but-unimplemented magnet class.

**Self-collision:** distinct subsystem from our reliability pick, which loops `runpp` over N-1
contingencies. This is a different solver formulation, not another contingency sweep.

**Natural trap material** (to be designed, not assumed): the parameterization switch is a
"the obvious code is wrong" sentinel — lambda-parameterization throughout diverges at the nose;
generator Q-limit enforcement switching PV->PQ buses *mid-trace* changes the Jacobian structure and
interacts with pandapower's existing `enforce_q_lims`, giving interdependence rather than a bolted-on
second mechanism.

## Risks, honestly ranked

1. **Spec-knowability is the real one.** CPF is textbook (Ajjarapu & Christy 1992) and the
   predictor-corrector scheme is derivable. This is the same class that I wrongly predicted for
   thermo and that genuinely killed cfn-guard-cidr. The pick survives only if the difficulty sits in
   the INTEGRATION — ppc conversion, bus-type switching under Q-limits, result writeback — and not in
   the equations. **Establish this before scope-locking.**
2. **LOC sketch not done.** This gate killed three picks; do it FIRST, before any design.
3. Gate 9 flakiness unmeasured (numerical, iterative — a real concern). Docker path is already proven
   by our approved pandapower problem.

## LOC sketch + integration check — BOTH PASS (run before any design work)

### Calibration (same repo, not a guess)

`approved-problems/pandapower-reliability-assessment` measured with the effective-LOC hook:
**823 raw / 557 human-effective across 14 files** — a new `reliability/` module (2 files) plus
`__init__.py`, `auxiliary.py`, `create/network_create.py`, five `network_schema/*`,
`network_structure.py`, `results.py` and two `topology/*`. That is the natural footprint of a
pandapower feature and the shape a CPF pick would follow.

### Sketch

| File | Work | est. eff |
|---|---|---|
| `continuation/run_continuation.py` (new) | predictor-corrector driver, step control, branch tracking | 180-250 |
| `continuation/parameterization.py` (new) | lambda-vs-state parameterization + switching, augmented residual/Jacobian | 90-140 |
| Q-limit interaction | mid-trace PV->PQ switching without the restore collision (below) | 60-100 |
| `pf/create_jacobian.py` (mod) | augmentation hook | 25-40 |
| `auxiliary.py` (mod) | options + ppci plumbing | 30-50 |
| `results.py` (mod) | trace + margin writeback | 25-40 |
| `network_schema/*` (mod) | result table schema | 20-40 |
| `continuation/__init__.py`, `__init__.py` | exports | 15 |

**~445-675 effective**, in line with the 557 the approved pandapower pick actually landed. The two
core files alone (270-390) clear the 200 floor, so the pick is not floor-dependent on the plumbing.

### Integration check — the difficulty is NOT the equations

**A real, repo-specific, misdirecting collision exists.** `_run_ac_pf_with_qlims_enforced`
(`pf/run_newton_raphson_pf.py:182+`) is a restart-from-scratch outer loop that snapshots and then
RESTORES the load vector:

```python
bus_backup_p_q = bus[:, [PD, QD]].copy()      # :184
...
bus[:, PD] = bus_backup_p_q[:, 0]             # :195   (each outer iteration)
...
bus[:, [PD, QD]] = bus_backup_p_q             # :218   (on exit)
```

A continuation scales load by varying PD/QD with lambda. **A CPF that delegates Q-limit enforcement
to this routine has its own load scaling silently reverted** — and the failure surfaces as a curve
that will not advance, nowhere near the Q-limit code. No textbook mentions this; it is purely
pandapower's own machinery. Bus-type switching mid-trace also changes the augmented system's
structure, which the restart-from-scratch loop cannot express while a tangent must be maintained.

### ⚠️ The shortcut that MUST be designed against (calyx-cider death shape)

pandapower already ships `timeseries/` (`run_time_series.py`, `ts_runpp.py`),
`control/controller/const_control.py` (`ConstControl`), and a first-class `scaling` column applied in
`build_bus.py:643-684`. So a solver can "implement CPF" as: sweep `scaling` upward with `ConstControl`
until `runpp` stops converging, call the last converged point the nose. That satisfies a loosely
worded contract while being a fundamentally different (and wrong) algorithm — exactly why
`rejected/calyx-cider-checkpoints` died.

**The contract must require what the sweep structurally cannot produce:** points on the LOWER
(unstable) branch past maximum loading, the nose located to a stated tolerance rather than to
step-size precision, and the tangent/sensitivity at the nose. A Newton sweep cannot go round the nose
at all — which turns the shortcut into an **F-1 convergent-architecture wall**, the largest lever
measured (+27 points on pulldown). Carries F-1's overshoot risk: name the root cause in the meta
(the curve continues past maximum loading; both branches are required) so a competent solver can
reach it.

**VERDICT: proceed to design.** First candidate in five to clear absorption, prior art, competitor
profiling, LOC and the integration check. Still owed: Gate 1 reproduce-on-base, Gate 9 flakiness
(numerical/iterative — the main remaining unknown), Docker (path already proven by the approved
pandapower pick), and a derivative check on "continuation power flow" as a capability name.

---

# ⭐ CANDIDATE FOUND — causal-learn orientation provenance (S-F)

Reached by hunting a SHAPE rather than a repo, after ~30 repos screened and 5 deep audits died.

## Why S-F was the right shape

**S-F (analysis / accounting layer) is structurally resistant to all five failure modes of this
session.** "Surface what the engine computes implicitly but never reports":

| Failure mode that killed a pick | Why S-F dodges it |
|---|---|
| Spec-knowable (thermo risk, vrp measured) | no external spec defines your internal report |
| Missing arm of a generic engine (choco) | there is nothing to be an arm OF |
| Machinery-absorbed (geometry-central, thermo) | the info is DISCARDED by construction — that is why it is not reported |
| Port inherits parent's features (pandapower) | the parent discards it too |
| Derivative magnet (geometry-central) | nobody files issues asking for internal accounting |

Precondition, and it is checkable from source: **an engine that makes internal decisions and throws
the reasoning away.** Approved S-F picks: rust-minidump trust accounting, calyx dead-port analysis,
astits stream analyzer, techan cost-basis ledger, sparse region analysis, pyparsing parse enumeration.

## py-why/causal-learn — capability: record WHY each edge got its orientation

- **Proven repo:** 1 approved sub (`causal-learn-mec-enumeration`) of a 6 cap. MIT, ★1681,
  pushed 2026-07-11, 56 commits/12mo, 61 real issues, **only 2 open PRs**
- **Competitor check: clean.** PR authors are kunwuz (maintainer), Ykabrit, ZJsheep
- Pure Python (numpy/scipy/pandas); Docker path already proven by our approved causal-learn pick

**Absorption — PASSES, verified locally.** The orientation rules mutate the graph **in place** and
return a bool `changeFlag`; `grep -rniE "provenance|reason|justif|explain|rule_applied"` over
`search/ConstraintBased/` returns **nothing**. A `verbose: bool` prints unstructured text. The
engine knows which rule fired on which triple with which witness, and keeps only the final graph.

**Port check — PASSES.** causal-learn is NOT a TETRAD port: its README points to TETRAD/py-tetrad as
a *separate, more comprehensive* Java program, and only 5 files reference Tetrad (attribution for the
`Endpoint` enum and GST), versus pandapower's 69 files carrying the parent's copyright.

**Sibling-ecosystem — PASSES, verified by cloning TETRAD (code search OR-s terms and lied again).**
TETRAD does not ship orientation provenance: `Edge.Property` is PAG markup (`dd`/`nl`/`pd`/`pl`),
`EdgeTypeProbability` is bootstrap statistical confidence, no `*Provenance*` or `*Explain*` class
exists, and the sole "provenance" hit is `sepsetProvenanceDump` — a debug STRING dump of separating
sets inside experimental `Fcit*`/`MarkovAuditUtils` classes.

**Phase 2 (issue BODIES) — CLEAN.** 61 open issues, all usage questions and bugs (GES failures, KCI
nan, numpy overflow, node naming). Nobody has asked for provenance, explanation or a derivation
record. No magnet.

**Self-collision — CLEAN, and unusually so.** Our MEC pick added three standalone files
(`utils/MECEnumeration.py`, `MECStructure.py`, `MECTraversal.py`) and touched **nothing** in the
search/orientation path. Zero file overlap; graph combinatorics on a finished graph vs the search's
decision trail.

**Footprint — cross-subsystem, and the arms genuinely differ:**

| File | LOC | Role |
|---|---|---|
| `search/ConstraintBased/FCI.py` | 1181 | **12 rule functions**: rule0, R1, R2, R1R2cycle, R3, R5, R6, R7, R4B, 8, 9, 10 |
| `graph/GeneralGraph.py` | 1013 | must carry the record |
| `search/ConstraintBased/PC.py` | 505 | wiring |
| `utils/PCUtils/UCSepset.py` | 381 | v-structure orientation (sepset witness) |
| `utils/PCUtils/Meek.py` | 194 | Meek R1-R4 on CPDAGs |
| `utils/PCUtils/BackgroundKnowledgeOrientUtils.py` | 37 | user-constraint source |

**Natural trap material, inherent not bolted on:**
- **F-10 cross-product:** {PC/Meek on CPDAGs, FCI on PAGs} x {sepset v-structure, rule inference,
  background knowledge} — two rule families, three orientation sources
- **F-2 fixpoint:** rules iterate to convergence on `changeFlag`; an edge can be touched repeatedly,
  so "which application is the DECIDING one" is a canonical-form decision the contract must state
- **S-I alive form:** the 12 FCI rules take genuinely different witnesses — R0 a sepset, R3 a
  discriminating triple, R4B a discriminating path, R9/R10 paths — so the arms are not uniform

## Risks to design against

1. **Uniform-wrap risk.** If every rule's provenance arm is "record the rule name + triple", the 12
   arms amortize to one pattern and the LOC is breadth, not depth (my own `effective_loc_check` hook
   flags exactly this as `padding-floor << human-effective`). The differing WITNESS types are what
   save it — make the witness part of the contract, not just the rule name.
2. **The verbose-print shortcut.** `verbose: bool` already prints rule firings. A solver could scrape
   or mirror that instead of building a structured record. Same shape as
   `rejected/calyx-cider-checkpoints`. The contract must require what a print stream cannot give:
   queryable per-edge records surviving the fixpoint, with the deciding application identified.
3. Gate 9 flakiness unmeasured — causal-learn uses statistical independence tests; check for unseeded
   RNG. **This is the main remaining unknown.**
4. LOC sketch is structural, not yet a real diff.
