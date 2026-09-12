# Repo Hunt 2026-08-07-C — first PYTHON sweep + the B2-ledger re-read

Run after the `olympus-hunt` skill changed in two ways:

1. **Python is in scope** (Requirement 2), with a modified trap catalogue (F-16 and F-12 lost, S6
   weakened, A4 host-semantics traps gained) and two extra mechanical gates (G-PY1 hash-seed
   determinism, G-PY2 C-extension test extras).
2. **A `SATURATED-REPOS.md` B1/B2/B3 hit is NO LONGER a reject.** Those sections are a LANE ledger,
   not a blocklist — the repo stays pickable in a different lane.

Both were exercised. The Python sweep is the new surface; the B2 re-read is where the actual RANK 1
came from.

**Headline: the RANK 1 is a lane I had been treating as dead — canvas clip-path.** The Python sweep
(63 keywords, 3 batches) produced no clean candidate.

---

### tdewolff/canvas — ★1825 — RANK 1 (clip-path lane)

Repo-level gates were all measured in `REPO-HUNT-2026-08-07.md` and are reused here rather than
re-derived, exactly as the amended Stage 2 allows. What is new is the LANE.

- **URL / stars:** https://github.com/tdewolff/canvas — ★1825
- **Language:** Go, pure for the core. `go.mod` pulls glfw/fyne/gioui/go-webp/go-avif but ONLY
  `renderers/{fyne,gio,opengl}` and `examples/` import them; the core and the six other backends
  build and test with no system headers.
- **Open issues:** 20. Open PRs: **3**, and none touch this lane (#382 `path_intersection.go`,
  #326 `svg.go` parsing, #271 `font/system.go`).
- **License:** MIT, read in full, no riders, single license.
- **Last commit:** 2026-08-03 (`8e86b9a`), real code.
- **Our quota:** 0/6. Not repo-dead anywhere. B2 entry explicitly reads "REPO STATUS: ALIVE AND
  RECOMMENDED — only the fill-rule LANE is dead."
- **Test framework:** `github.com/tdewolff/test`, table-driven, behavioural through the public API,
  with golden string comparison on emitted SVG/PDF/PS output — an ideal f2p surface.
- **Baseline determinism:** 3/3 identical, scoped suite under 1s (measured 2026-08-07).
- **Docker:** Pattern B (`olympus-base-go`), scoped to the 27 non-GPU packages with the reason
  documented. UNVERIFIED locally (no Docker on this workstation) — owed to the platform run.
- **Self-collision:** `approved-problems/lyon-arcs-join` and `lyon-fill-internal-vertices` are
  stroke joins and fill-tessellation interior — different subsystem, no overlap with clipping.
  `rejected/canvas-fill-rule-backends` is the same repo, different capability, and never submitted.

**Why this lane, and why now.** The B2 entry for canvas records the fill-rule lane dying at **44
effective LOC against the 200 floor** because `Path.Settle` already owned the machinery. It also
records, as untouched surface, that **the `Renderer` interface has no clipping at all**. That is the
`Missing machinery` question answered in the affirmative, and I verified it at the base commit
rather than trusting the note:

```
type Renderer interface {            // canvas.go:206 at 8e86b9a
    Size() (float64, float64)
    RenderPath(path *Path, style Style, m Matrix)
    RenderText(text *Text, m Matrix)
    RenderImage(img image.Image, m Matrix)
}
```

Seven types implement `Renderer` (pdf, ps, svg, rasterizer, htmlcanvas, tex, gio). **Clip references
at HEAD: pdf 1 (a comment about miter joiners), every other backend 0.** So clipping is absent from
the protocol AND from every backend — nothing to absorb the feature.

The shape that carries the LOC is the split between backends whose output format HAS a clipping
primitive (PDF `W`/`W*`, PS `clip`/`eoclip`, SVG `<clipPath>`) and backends that have none at all
(tex, htmlcanvas, and any third-party `Renderer` implementation, which cannot be modified). The
latter can only be served by a geometric fallback that intersects drawn paths against the clip
region through the existing boolean engine. That fallback is new machinery, not a call-through.

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-9 cross-stage resolution drop | **yes (lead)** | The `Renderer` protocol carries no clip state, so a clip established on the `Context` is resolved (or silently dropped) independently by each backend. One root cause breaks every backend at once |
| F-10 capability cross-product | **yes** | axes: 7 backends x {native clip primitive, geometric fallback} x {RenderPath, RenderText, RenderImage} x {nested clips, reset}. Text and image clipping are the cells that get missed |
| F-5 transitive pass-through | **yes** | a clip-applying wrapper renderer is a pass-through node — it must forward `Size()` faithfully while transforming everything else |
| F-6 ordering inversion | **yes** | clip-vs-transform order, and clip intersection vs `Settle`/`Flatten`, are unstated and observable |
| F-14 declared-vs-derived terminal state | **yes** | an empty clip region is a new "draw nothing" terminal state that must be honored at every existing early-return |
| F-8 named-algorithm override | partial | Bentley-Ottmann / Cohen-Sutherland already in-tree; the repo diverges from each in places |
| F-13 two-tier format | no | — |

**Live Gate-1 evidence:** issue **#314 "`canvas.Clip` translation doesn't follow `coordSystem`"** is
OPEN and ties the lane to canvas's own four-quadrant `CoordSystem` model — a repo-internal noun.
Gate 1 is still owed as a measurement (run it through the public API and capture observably wrong
output) before scope-lock.

**Estimated complexity:** ~250-400 effective LOC across 7-9 files, 4-6 packages. **Treat as an
estimate, not a measurement.** The fill-rule lane sketched 213 meaningful and measured 44; the
lesson from that death is to build the minimal-golden slice and count it BEFORE scope-lock. The one
encouraging datapoint is that a partial in-progress implementation covering only the protocol plus
PDF and SVG is already 233 raw added lines, with five backends, text/image clipping and #314 still
outstanding.

**Risks:**
- **(a) Magnet, moderate — this is the honest weak point.** "Adds clip-path support to a 2D vector
  graphics renderer" is largely intelligible to an outsider, and clipping is named by SVG, PDF and
  PostScript. It is weaker on Stage 2b than the fill-rule lane was (`Positive`/`Negative` were
  canvas's own model). The mitigation is to scope the capability around canvas's own `Renderer`
  protocol and `CoordSystem` — the negotiation between clip-capable and clip-incapable backends is
  repo-internal — but do not rate this LOW.
- **(b) LOC** — the canvas failure mode. Sketch and compile the minimal slice first.
- **(c)** Avoid `path_stroke.go` (lyon self-collision) and `path_intersection.go` (open PR #382).
- **(d)** Roadmap issue #74 items remain off-limits; clipping is not on it.

⚠️ **Housekeeping finding, not a hunt result:** `worktrees/canvas` carries **uncommitted local work
on this exact lane** from a prior session — untracked `clip.go` (179 lines, defining a `Clipper`
optional interface, `ClipState`, `Context.ClipPath`/`ClipRect`/`ResetClip`, and a `clipRenderer`
fallback wrapper) plus modifications to `canvas.go`, `renderers/pdf/pdf.go` and
`renderers/svg/svg.go` (54 lines). Nothing in `problems/` corresponds to it. Decide whether to keep
or discard it before authoring — starting from a dirty tree will corrupt the BASE_COMMIT diff.

---

## Python sweep — no clean candidate

63 keywords across three batches, restricted per the new guidance to obscure domains (schema and
validation engines, template engines, static analyzers, packet/binary parsers, constraint and
scheduling engines, config languages, scientific DSL pipelines) and away from SQL, datetime, HTTP,
ORM and famous-format serialization.

| Repo | ★ | Kill |
|---|---|---|
| olofk/fusesoc | 1444 | **Repo-fit LOC + outsourced machinery.** The best-shaped Python candidate found: BSD-2, obscure FPGA/ASIC build-abstraction domain, real staged pipeline (CAPI2 core files -> dependency resolution -> flow/target/parameter resolution -> backend generation), a genuine two-tier `_append` inheritance form (`fusesoc/capi2/inheritance.py`), G-PY2 clean (no numpy/scipy/lxml anywhere). **Dies on 6,545 total Python LOC** — the jd profile, far under PICK-FILTER's ~30k repo-fit proxy — and worse, the machinery that would carry a pick lives in OTHER repos: the SAT dependency solver is `simplesat`, the backend generators are `edalize`. fusesoc itself is glue. Also open PR #778 already owns the `..._append` merge lane and #734 the validation lane. |
| se2p/pynguin | 1384 | **Capability wave.** 300 commits/12mo and the recent stream is a sustained LLM-integration push (seeded token constants, LLM request budgeting, export re-execution namespaces). Test-generation is also GA-driven, which is a standing flakiness risk against the mandatory determinism gate. |
| dynaconf/dynaconf | 4320 | **Lane density, precisely on the seam I wanted.** The layered-settings cascade is a textbook F-13, and the maintainer is sweeping exactly it: 98 commits/12mo that are almost entirely `fix:` on merge tokens, override precedence, dotted-key resolution, `dynaconf_merge` nesting and sibling-key retention, plus 10 open PRs on loaders/casting/precedence. |
| cuthbertLab/music21 | 2550 | **Capability wave, broad.** 300 commits/12mo of active feature work (LilyPond typing, MetronomeMark output, ABC lyric import) and 10 open PRs spanning meter, spanners, pedal marks, tuplets and microtones. Music-theory capabilities are also externally named. The repo is large enough that a cold subsystem may exist, but finding it is a day's audit at veryl odds. |
| Scony/godot-gdscript-toolkit | 1588 | Genuinely cold (7 commits/12mo) but the last commit is 2025-10-09, and 8 open PRs sit on the formatter and linter (#415 plugin system, #413 and #393 formatter bugs). Formatter picks also self-collide with approved `gluon-format-comments`. |
| lark-parser/lark | 5948 | Already the doctrine's own Python precedent (`lark-counterexamples`, cited as canonical in `KNOWLEDGE.md`) — self-collision, and a famous parsing toolkit. |
| sqlfluff, sqlparse, dateparser, pdfminer.six, jsonschema, msgspec, mido, coveragepy | — | Excluded by the new Python guidance (SQL / datetime / famous-format / famous-library), by C-extension test extras (G-PY2), or both. |
| pyscf, astropy, statsmodels, pyvista, trimesh, deepchem | — | G-PY2: numpy/scipy/C-extension test paths. |

**Assessment of Python as a hunting ground (first data point).** The two warnings in the skill both
showed up immediately and are worth confirming. Saturation risk is real: the Python result pages are
dominated by household-name libraries in exactly the domains the doctrine forbids, and the obscure
tail is thinner than Rust's. And the LOC warning bit harder than expected — the best candidate died
at 6.5k LOC, because Python's ecosystem culture pushes the heavy machinery into separate installable
packages, which is machinery absorption at the REPO boundary rather than inside a file. For the next
Python sweep, add a total-LOC check early and prefer monorepo-style engines over composable
single-purpose libraries.

**Sweep noise:** roughly a third of every Python result page is AI/LLM tooling. Productive keywords:
`grammar`, `linter`, `constraint`, `verilog`, `netlist`, `notation`, `symbolic`, `automata`,
`instrumentation`. Pure noise: `inference`, `modeling`, `optimization`, `template`, `schema`.

**Disk:** fusesoc clone removed (definite reject). canvas and rbpf clones kept. `/home` at 92%.
