# REPO HUNT 2026-09-20-B

Unattended `olympus-factory` hunt. `CONSECUTIVE_MISSES=0`, so the standard (un-softened) rules apply
except where the 2026-09-09-B softenings are already baked into the skill. No relaxation of any hard
platform rule was needed or taken; the two judgement calls made without a human are recorded under
**Decisions taken unattended** below.

Preferences: none given (any supported language). Followed the previous log's `NEXT_HUNT_HINT`
verbatim: no star-band slicing of Go/Rust/TS/JS, a rebuilt slice builder keyed on default-branch
commit dates with non-chore subjects plus an AI-mark column, then `gh search repos --topic=`
single-word engineering topics in the scientific / simulation / instrumentation niches.

- **RESULT: CANDIDATE — `siliconcompiler/siliconcompiler`** (Python, Apache-2.0, ★1215)
- Fallbacks: `PatWie/CppNumericalSolvers` (C++), `python-control/python-control` (Python, pool repo)
- Scratch: `worktrees/_hunt/l_sci0920b/`

---

## Taken / excluded before any screening

From `pipeline/LEDGER.md` and `problems/`: pyfakefs (HUNTED), libspatialindex (BUILDING),
messageformat, oxipng, csbindgen (CLAIMED). Reserved as other hunts' fallbacks and therefore not
eligible for RANK 1: Restream/reindexer, greatscottgadgets/luna, walles/riff, macs3-project/MACS.
starlark-rust narrowing stays dead under the famous-language-feature carve-out.

---

## Stage 0-bis — proven-repo pool, mined first

Pool rebuilt mechanically from `approved-problems/*/meta.md`, `problems/*/meta.md`,
`rejected/*/meta.md` frontmatter: 67 repos at 1-3 submissions (cap 6). All 67 were run through the
new slice builder in one pass (`l_sci0920b/pool.jsonl`, 6 GraphQL batches).

What the pass actually shows, and why the pool produced no RANK 1:

| Repo | Why it did not carry a lane today |
|---|---|
| pysmt/pysmt (1 sub) | **Capability-consuming across every lane I would want.** `mikand` is sweeping the whole library in Sep 2026: SMT-LIB n-ary operators in the parser, empty symbol names in all solvers, constant arrays in CVC4/CVC5, `to_int`/`is_int` from Reals_Ints, assumptions inside unsat cores, and an "remove instance-based walkers in favour of class-based dispatch" refactor. That stream *is* the f2p surface. |
| Mindwerks/worldengine (1 sub) | **Dormancy magnet.** 34 commits/12mo and almost all of them dependabot/infra (`Bump pygments`, `Drop Python 3.9`, `ruff fix`); the erosion lane — the only lane left beside our approved precipitation pick — is sitting in **open PR #270 "Erosion Improvements"** (2024-07-20), a published diff. Three more PRs open since 2015. |
| wilsonrljr/sysidentpy (0 subs, but from the pool's neighbourhood and the previous hunter's abandoned clone) | Solo maintainer running a correctness sweep over exactly the f2p surface: `fix NAR n-step prediction across estimators`, `correct ER backward elimination`, `harden MetaMSS optimization and validation`, `fix: define degenerate regression metrics`, `centralize BaseMSS prediction methods`. Same shape as the neva AI-papercut programme. |
| tantivy · sqlfluff · numbat · ir-sim · RocketPy · awkward · go-workflows · featurevisor · neva | AI marks at root (`.claude` / `AGENTS.md` / `CLAUDE.md`) — a note on its own, but each also sits at 1-2 subs in a lane we already occupy. |
| WeasyPrint · fonttools · rust-url · taplo · comrak · pulldown-cmark | famous spec / format implementations — the >5000-star-with-a-famous-spec kill row in spirit. |
| sfepy | platform reuse warning (25 submissions by 6 other contributors, recorded 2026-09-17). |
| toydb · ezno · lifelines · paulmach/orb · icedland/iced · AmrDeveloper/GQL | last real code commit 3-11 months old with a filling PR queue. |
| python-control (2 subs) | **Survived** — carried forward as RANK 3, see below. |

Pool verdict: the pool is now mined to the point where the surviving repos are either
competitor/maintainer-occupied, AI-swept, or in a lane class we already hold. This is the third
consecutive session to reach that conclusion; the pool should be treated as a *fallback source*, not
a first source, until new repos enter it.

---

## Cached-index triage (before any fresh fetch)

`worktrees/_hunt/` already held `tri_0920.tsv` + `tri_0920b.tsv` + `tri_0920c.tsv` (2,214 unique
rows from the star-band and year-window sweeps) and `slice_{cpp,java,js,py,gorusts}_0920.tsv`
(1,397 slugs already screened by the previous session). I re-cut the cache on a **domain** axis
instead of a star axis — 70 scientific / simulation / instrumentation vocabulary terms — which is a
different slice of the same cached rows, not a refetch:

- 526 domain rows in the cache, **188 of them never screened** (`l_sci0920b/cache_domain_new.tsv`).
- Manual read of all 188: the survivors are ML-research code, ROS drivers, vendor wrappers, Home
  Assistant integrations and single-algorithm libraries. Nothing carried a repo-internal capability
  model. This confirms the previous log's finding that the star-band cache is structurally
  exhausted, and extends it: it is exhausted on the **domain** axis too, not just the star axis.
- Two rows were promoted out of the cache for deeper screening and both died:
  `PatWie/CppNumericalSolvers` (promoted to RANK 2 instead — see below) and `wildmeshing/fTetWild`
  (MPL-2.0, hard licence reject).

The previous hunter (#4, killed by a rate limit) had also left an unscreened shortlist at
`i_size/short1.txt`. 63 of its 61+ slugs were absent from the dead list; all 63 went through the new
slice builder (`l_sci0920b/short1.jsonl`). Best of them and why each died is in
**Closest misses** below.

---

## The rebuilt slice builder (the hint's item 1 + 2)

`worktrees/_hunt/l_sci0920b/slice2.py` — one GraphQL query per 12 repos returning, in a single
round trip: stars, archived/fork, licence SPDX, primary language **and the top-6 language byte
mix**, open issues, open PRs, **the root tree's file names**, the default branch name, and the
default branch's **commit count plus the last 40 `(date, subject, author)` triples**.

`rep.py` then flags each row with:

- `lastcode` — the most recent default-branch commit whose subject is **not** chore/ci/docs/deps/
  release/merge/typo/lint. `CORPSE` when there is none in 12 months. This is the hint's fix for
  `pushed_at` lying, and it works: it flagged `ucbrise/confluo`, `google/badwolf`,
  `ProjectQ-Framework/ProjectQ` as corpses in the same pass that measured everything else.
- `AI:` — `CLAUDE.md` / `AGENTS.md` / `.agents` / `.claude` / `.coderabbit.yaml` / `GEMINI.md` /
  `.cursorrules` / `.roomodes` at the repo root, from the same call.
- `LIC:` — anything outside the allowlist.
- `sub<N>` — our own submission count for that repo, joined from the corpus frontmatter.

Cost: 67 pool repos + 137 sweep candidates + 63 shortlist rows = **267 repos fully profiled in 23
GraphQL calls**. It replaces four separate REST passes and it is the tool to reuse.

⚠️ **Deadlist bug found and worth fixing.** `deadlist_v*.txt` is built by grepping
`github.com/<owner>/<repo>` out of `SATURATED-REPOS.md` and the hunt logs. Several kill rows in
`SATURATED-REPOS.md` list repos as **bare prose slugs with no URL** — including the
`cocotb · glasgow · gdsfactory · siliconcompiler · OpenLane · librelane · edalize · hls4ml ·
openFPGALoader` row at line 969. Those nine repos are therefore invisible to every mechanical
dead-list filter in this workspace. Either the file should be normalised to URLs, or the dead-list
builder should also parse bare `owner/repo` tokens out of table cells.

---

## Sweep 1 — scientific / simulation / instrumentation topics (98 topics)

`l_sci0920b/topics.txt` + `sweep.sh`. `gh search repos --topic=<t> --stars=">=500" --limit=50`,
89 topics returned rows, **1,375 unique repos**. After the dead list (5,776), the previous
session's screened set (1,397), licence, language, the 500-6000 star window, 12-month activity and
a junk-description filter: **137 candidates** (`cand1.tsv`), all profiled with `slice2.py`.

The honest result: **this niche returns mostly ML-research repos, ROS wrappers and vendor shims.**
`robotics`, `simulation`, `point-cloud`, `remote-sensing`, `slam`, `lidar` and `motion-planning`
are now colonised by model checkpoints and benchmark harnesses the same way star-sorted keyword
search is colonised by LLM infra. The topics that still return real engineering are the
hardware/verification ones (`verilog`, `vhdl`, `fpga`, `eda`, `pcb`) and the numerical ones
(`numerical-methods`, `optimization`, `finite-element`) — and those are where both survivors came
from.

Three parallel screening subagents worked the clusters that survived the 137-row profile. Their
full dossiers and kill lists are folded into **Closest misses** below.

## Sweep 2 — instrumentation / measurement / scientific-format topics (98 topics)

`l_sci0920b/topics2.txt` + `sweep2.sh`: `fits`, `dicom`, `netcdf`, `vcd`, `gerber`, `gcode`,
`opcua`, `nmea`, `adsb`, `mass-spectrometry`, `interferometry`, `phase-field`,
`lattice-boltzmann`, `boundary-element`, `multigrid`, `preconditioner`, `quadrature`,
`interval-arithmetic`, … **64 of 98 topics returned before the search API secondary limit closed the
window** (the three subagents were hitting the same endpoint concurrently); 557 rows,
**32 survivors** after filtering (`cand2.tsv`).

Yield: **zero**. The survivors are medical-imaging C++ toolkits with VTK/ITK/Qt in the test path
(`MITK`, `CTK`, `OHIF/Viewers`, `cornerstoneTools`), ray-tracing demos, and repos already killed
elsewhere (`imageio` — dormant with a 24-PR queue covering every plugin lane; `mne-python` — 619
open issues and a famous domain). The 34 un-run topics are listed in `topics2.txt` and are the
cheapest thing for the next hunt to resume, but on this evidence the expected value is low.

---

## RANK 1 — siliconcompiler/siliconcompiler — ★1215 — Python

- **URL / stars:** https://github.com/siliconcompiler/siliconcompiler — ★1215
- **Language:** Python **6,339,647 B (93%)**; Shell 308k, Tcl 299k, Verilog 151k (tool scripts and
  test fixtures, not the test build path); C 5.6 kB, C++ 561 B. Python is unambiguously primary, so
  the 2026-09-19 platform language gate is clear with a wide margin.
- **Domain:** open-source hardware compilation flow — a schema/parameter system, a `Design` /
  `Library` fileset model with a dependency graph, a flowgraph DAG, a scheduler, and tool drivers.
- **Licence:** Apache-2.0, **verified by reading the file**. `find . -iname 'LICEN*'` returns exactly
  two: the top-level `LICENSE` (Apache-2.0) and `siliconcompiler/data/RobotoMono/LICENSE.txt`, which
  is **also Apache-2.0** (not OFL — checked). `grep -rliE 'GNU General Public|GNU Lesser|GPL-3|AGPL'`
  over the tree: **zero hits**. No vendored C, no third-party source tree.
- **Activity:** default branch `main`, last real code commit **2026-09-18** (`account for skips and
  earlier reruns on IO checks`, `reduce unconditional imports to speed up initial load`, `create
  server extra requirements and move pandas into dashboard only`). Not a docs corpse.
- **Open issues / PRs:** **32 open issues; 1 open PR, and it is the repo's own bot**
  (`#5411 [SC-BOT] Update openroad`). Zero human PRs open. This is the strongest exclusivity
  position found in this session or the previous one.
- **Requirement 7 (CI runs its own tests and they pass):** `main` is **green** — `Python CI Tests`
  success, `Tools CI Tests` success, `Daily CI Tests` success, `Lint` success, `Wheels` success.
  The relevant job installs `pip install -e .[test,dashboard,server]` and runs
  `pytest -n logical -m "not eda and not docker"` across 5 Python versions x 4 OSes, apt-installing
  only `graphviz` and `python3-tk`. The `eda` / `docker` / `nightly` / `slurm` markers are declared
  in `pyproject.toml:139-148` — confirmed by reading the file in the clone.
- **Competitor screen (2b-bis):** last 60 PRs are `app/siliconcompiler` (37, the version bot),
  `gadfort` (18, the maintainer), `RiceShelley` (3) and `ciprianantoci-collab` (1) — both domain
  users with coherent hardware footprints. **Zero** matches against `sig_accounts.txt` (53 recorded
  signature accounts).
- **AI marks:** `AGENTS.md` at root (250 lines of orientation for coding agents), plus
  `address copilot feedback` / `address coderabbit feedback` commit subjects. Under the softened
  2026-09-09-B rule 3 this is a **NOTE, not a lane verdict**, and the lane test is explicit below.
- **Our submissions:** **0**. Not in `approved-problems/`, `problems/`, `rejected/`,
  `diamond-problems/`. Quota 0/6.
- **Self-collision:** `grep -rliE 'fileset|file list|flist'` across every `meta.md` in the corpus
  returns **nothing**. The nearest neighbours are `planetiler-custommap-schema-composition`
  (layered-config merge, F-38) and `kapture-dependency-closed-subset` (dependency closure) — both a
  different capability in a different repo and language; keep `meta.md` off "layered config
  override" phrasing so it does not drift toward the planetiler shape.

### LANE

*Make a `Design`'s fileset survive a round trip through the Verilog `.f` file-list format:
`write_fileset` must emit the dependency boundaries that `get_fileset` flattens away — as nested
per-dependency lists — together with the fileset surface it silently drops today (libdirs, libs,
undefines, params), and `read_fileset` must reconstruct that graph, honouring the real flist command
set (`-f` / `-F` with their different relative-path bases, `-y` / `-v` library search,
`+libext+`-driven filetype inference, multi-value `+define+a=1+b=2` / `+incdir+a+b`) while mapping
every resolved path back onto the right dataroot.*

**The algorithm the repo does not already contain:** the **inversion of `Design.__get_fileset`** —
reconstructing a fileset dependency graph (and its dataroots) from a nested, ordered, flattened text
list, plus the emitter that makes that reconstruction possible at all. Same shape as
`approved-problems/customasm-ruledef-disassembly` ("decode assembled bytes back to instructions
using the repo's own ruledefs", 493 eff, APPROVED), one level up: the flattening traversal exists,
its inverse does not.

### Missing machinery (what the repo structurally cannot do), measured in the clone at `6d3fea2a`

- `__read_flist` (`siliconcompiler/design.py:715-790`) is a 40-line line scanner. It understands
  exactly three things — `+incdir+`, `+define+`, "anything else is a file". No tokenizer, no
  directive table, no nesting, no per-list relative base, no cycle detection.
- `-y` / `-v` / `+libext+` exist nowhere in the package. `grep -rn "libext" --include=*.py` returns
  **one** hit: a hardcoded `+libext+.sv+.v` string the repo *emits* at `tools/surelog/parse.py:192`.
  The repo has produced the directive for years and has never parsed one.
- Extension -> filetype inference is a single global dict, `utils.get_default_iomap()`, consulted
  from `schema_support/filesetschema.py:233-235` by **every** `add_file` in the codebase. There is
  no per-list override path.
- Dataroot inference is a naive substring test — `if path_dir.startswith(pdir)`
  (`design.py:760-775`) — so `/proj/libs` swallows `/proj/libsrc`, and the invented names
  (`flist-<design>-<fileset>-<basename>-N`) are **asserted verbatim by the existing suite**
  (`tests/test_design.py:857`, `:883`, `:935-937`).
- `__write_flist` (`design.py:595-647`) emits only idirs, defines and files. `libdir`, `lib`,
  `undefine`, `param` and `topmodule` are written by nobody, so a write -> read cycle silently drops
  them — a lossy round trip in production code, not an exception.
- The writer's dedup is a **comment convention**: a repeated command is written as `// <cmd>`
  (`design.py:617-623`) and the reader skips every `//` line (`design.py:743-744`).

### Eff-LOC sketch — DECISION POINTS, not surfaces (per the dinit warning)

| Decision cluster | eff |
|---|---|
| directive tokenizer + dispatch table (`-f -F -v -y -sv -D +libext+ +systemverilogext+ +define+ +incdir+`, quoting, continuation, `#` vs `//`) | 85 |
| nested-list recursion: `-f` (CWD-relative) vs `-F` (list-file-relative), depth, cycle detection | 40 |
| `+libext+`-driven filetype inference overriding `get_default_iomap()` **per list**, without perturbing the global map | 32 |
| `-y` libdir / `-v` lib mapping onto `add_libdir` / `add_lib` | 32 |
| dataroot assignment rewrite: longest prefix on path *components*, abs vs rel, stable naming under the new directive set | 40 |
| writer: libdir / lib / undefine / param emission and its interaction with dedup | 70 |
| writer: per-dependency nested `-f` emission honouring `get_fileset` traversal + alias order | 40 |
| diagnostics (unknown directive, missing nested list, cycle, unresolvable extension) | 30 |
| **total** | **≈369 human-effective** |

Above the 250 proceed line with margin, across >=3 non-test files (`design.py`,
`schema_support/filesetschema.py`, a new flist module, probably `library.py`).

### TRAP SEAMS (`failure-patterns.md`)

| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | yes | `design.py:836-915` `__get_fileset` **flattens** the dependency graph to a `List[(Design, fileset)]` before the writer ever sees it. The boundary information the round trip needs is destroyed by the only door the writer has. |
| F-9 cross-stage resolution drop | yes | filetype is resolved once, globally, at `filesetschema.py:233-235` from `utils.get_default_iomap()`; the flist reader is a second site that must resolve the same thing differently (per-list `+libext+`) without moving the first. |
| F-19 shared-helper side effect | yes (variant) | the writer's `write()` closure (`design.py:617-623`) is a single dedup channel shared by every library in the emission; making it per-list is the fix, and not making it per-list silently deletes a later library's files as comments. |
| F-13 two-tier format (base + amendments) | yes | `-f` / `-F` nesting is exactly a base list plus sub-lists that override the relative base; a nested list alone can violate "every path resolves inside a dataroot". |
| F-10 capability cross-product | yes | {`+incdir+`, `+define+`, `+libext+`, `-y`, `-v`, plain file} x {top-level list, nested `-f`, nested `-F`}. Multiplicity axis = multi-value `+define+a=1+b=2`; polarity axis = CWD-relative vs list-file-relative base. |
| F-15 arming-vs-firing | yes | a dataroot is created the first time a *new* prefix is seen; `-y` search directories change **how many** dataroots exist and **in what order**, so the counter in `flist-...-N` shifts and pre-existing assertions move. |
| F-3 second-axis carve-out | yes | the fileset carries two parallel collections (`idir` + `libdir`, `define` + `undefine`) that must stay consistent through one emission pass. |
| F-22 fixpoint | no | there is no iterate-to-stability loop here. |
| F-8 named-algorithm override | no | nothing famous to misdirect with. |

### Stage 6 death-class guard — run explicitly, PASSES all four

1. **One shared kernel feeding several surfaces?** **Yes.** The fileset/dataroot model plus
   `get_fileset`'s flattening feeds the writer, the reader, `tool.py`'s input collection and every
   `add_file` call. A local fix to the reader's dataroot invention regresses the writer's relative
   paths and moves the dataroot-name assertions the existing suite already pins.
2. **Interdependent, not merely several?** **Yes, and misdirecting.** Making the writer emit
   per-dependency nested lists is the obvious first move; the global dedup set then comments out the
   second list's repeated commands, and the failure surfaces as *"a downstream library's files went
   missing"*, pointing at the traversal, not at the dedup. Fixing the dedup per-list then exposes
   the dataroot prefix collision (`/proj/libs` vs `/proj/libsrc`), which surfaces as a wrong relative
   path, not as a prefix bug. Adding `-y` changes dataroot creation order, which renumbers
   `flist-...-N` and breaks assertions in tests the agent did not touch.
3. **Could a standalone new file with minimal wiring solve it?** **No.** A tokenizer module alone
   satisfies none of: graph reconstruction, the writer's nesting, the dedup rescope, the per-list
   filetype override, or the dataroot rewrite. The round-trip contract binds reader and writer.
4. **`TOO-EASY.md` Pre-Pick Guard 1-5.** (1) not one rule at many sites — the tokenizer insight
   buys you none of the graph reconstruction, the dataroot assignment or the writer rescope;
   (2) not single-subsystem, and there are >=2 hidden-integration walls (the global iomap, the
   comment-dedup channel); (3) the hardness survives full statement — you can write "a write then a
   read reproduces the same filesets, dependency boundaries and dataroots" and the agent must still
   discover that the writer's dedup and the reader's comment-skip are the same channel; (4) not a
   port — the `.f` syntax is an industry convention but its reconstruction into SC's
   `Design` / `fileset` / `dataroot` / `depfileset` model is repo-internal by construction;
   (5) yes, it survives being spelled out.

### Prior-art / exclusivity checks run at hunt time

- **Open-PR enumeration (not keyword search):** one open PR, `#5411`, authored by the repo's own
  bot, an openroad version bump. Zero overlap with anything.
- **Epic / roadmap search:** `search/issues?q=repo:...+is:open+in:title+roadmap` -> **0**.
  All 32 open issue titles read: nothing about filesets, flists or file lists.
- **Magnet test on issue BODIES, not titles:** `flist` search across all states -> **0 issues**.
  `fileset` search -> 15 hits, all unrelated (LEF loading, NVC simulator support, build_macro
  hardcoding a stdcell fileset). There is **no open, uncommented, long-lived issue asking for flist
  directives**, so the outsider-nameable format is a MITIGATION under softened rule 6, not a reject.
- **Lane history caveat, recorded honestly:** the closed issues `#3710 implement read_flist`,
  `#3082 add support for flist import handling` and `#3091 add package as option to flist import`
  are how today's 40-line reader came to exist. The directive set and the round-trip contract
  appear in none of them and nothing open asks for either — but the lane *class* has maintainer
  history, so `meta.md` must be phrased on SC's own `Design` / `fileset` / `dataroot` /
  `depfileset` nouns and never as "support standard flist syntax".
- **Removal-record check (Stage 2d, the kira gate):** `grep -niE "no longer|removed|dropped"` over
  `Changes/` filtered to fileset/flist/dataroot -> **0**. Nothing was removed here.
- **Sibling-library check:** flist parsing exists in the wild (slang/pyslang has command-file
  support, and `pyslang` is already a dependency), but nothing public reconstructs into SC's
  `Design`/`fileset`/`dataroot` model, and the hard half — the reverse mapping and the emitter that
  preserves boundaries — is repo-internal.
- **Previous-major-version check:** SC's pre-2025 `Chip`-based API had no fileset abstraction at
  all (`AGENTS.md` warns agents about the old API explicitly), so there is no earlier implementation
  to inherit as prior art.
- **Lane churn (the AI-mark lane test):** commits since 2026-03-20 — `design.py` **3**,
  `schema_support/filesetschema.py` **0**, versus `package/` 34, `flowgraph.py` 11,
  `constraints/` 11. `gadfort`'s firehose lives in scheduler / flowgraph / tools / server. **The
  lane is cold**; the AI marks therefore stay a note. Corollary for the author: any *hot* lane in
  this repo (scheduler, flowgraph, package) is dead.

### Docker

Pattern B, `olympus-base-python`. `apt-get install -y graphviz` + `pip install -e .[test]`; base
mode is `pytest -m "not eda and not docker"`, exactly what CI runs green; JUnit via
`pytest --junitxml="$OUTPUT_PATH"`. All deps are pure-Python or ship manylinux wheels
(`pyslang==11.0.0` does). Two watch-items: pin `lambdapdk` (large data package, image bloat), and
confirm the `docker`/`psutil` deps never try to reach a daemon — the `not docker` marker already
excludes those tests. **Estimate only; no image was built in this hunt.**

### Risks, in order

1. ⚠️ **This repo is recorded dead TWICE in our own notes, and I am re-opening it on evidence.**
   (a) `SATURATED-REPOS.md:969` kills it in a nine-repo row labelled *"tool-harness — tests need a
   simulator, EDA binaries, klayout or hardware"*. That is **factually wrong for siliconcompiler**:
   the repo declares `eda` / `docker` pytest markers in `pyproject.toml:139-148` and CI runs a
   dedicated `Python CI Tests` job, green on `main`, as `pytest -n logical -m "not eda and not
   docker"` with only `graphviz` + `python3-tk` from apt. The `DataFixerUpper` precedent (LESSON A
   in the same file) is exactly this: a blanket CI/harness verdict overturned by reading the repo.
   (b) `REPO-HUNT-2026-09-20.md` method note 2 lists siliconcompiler among repos "killed by the
   AI-mark column". Under the softened 2026-09-09-B rule 3 an AI mark is a lane verdict, not a repo
   verdict, and the lane churn measured above (3 commits in 6 months in `design.py`, 0 in
   `filesetschema.py`) says the lane is cold. **Both re-openings are judgement calls made without a
   human; if the orchestrator disagrees, promote RANK 2.**
2. **Velocity.** `gadfort` merges several PRs a day and PR numbers are past 5411. Base-commit churn
   is real: scope-lock fast, and re-run the CLAUDE.md six-check plus the PR-DIFF check immediately
   before patch generation.
3. **Format nameability.** "Verilog `-f` file list" is an industry convention an outsider can name.
   Mitigation is mandatory and is the softened-rule-6 recipe: phrase `meta.md` on the repo's own
   model, build the F-10 cell table on SC's own directive x nesting cross-product, re-run the
   canonical-org PR-DIFF check at submit.
4. **Guard #1 residual.** If the author lets "write a proper tokenizer" be the whole insight, this
   collapses toward a rules list and caps high. The **round-trip / graph-reconstruction contract
   must be load-bearing**, and the comment-dedup channel and the dataroot prefix collision must both
   be tested as independent mechanisms.
5. **Flakiness 3-5x is OWED.** CI runs with `-n logical` (xdist), which is a mild ordering-flake
   risk; nothing was run locally in this hunt (a builder holds the disk).
6. **Repo size.** ~157 MB clone, ~80k LOC of Python. The lane's reviewer-visible surface is small
   (2 files plus 1 new), but the first `pip install` is slow.
7. **Requirement 0 (platform picker) is OWED** — see below.

- Clone kept at `worktrees/_hunt/l_sci0920b/sc` (157 MB), HEAD
  `6d3fea2a8d2f458f2ed0513d7fdaf043e4aa90f6`. No build output anywhere.

**Backup lane inside the same repo** if the flist lane dies on the closed-issue history:
`siliconcompiler/checklist.py:301-476` — `Checklist.check()` parses criteria with a single regex
`^(\w+)\s*([\>\=\<]+)\s*(number)$` (`:366`), with no unit awareness, no aggregation across the
`(job, step, index)` tasks it loops over, and waivers matched by metric name only (`:412`).
2 commits in 6 months; the adjacent open issue `#3020 record timing/power metrics on a per scenario
basis` (2024-12, uncommented) is a different ask.

---

## RANK 2 (FALLBACK) — PatWie/CppNumericalSolvers — ★977 — C++

Header-only C++17 optimization library. MIT (`LICENSE` read; deps are apt-installed, not vendored).
C++ 98.3% of bytes. Default branch `main`, last real code commit 2026-07-20 (`perf: Remove redundant
evaluations in unconstrained solver loops`). 1 open issue, 1 open PR (CI-only: `eigen5.yml`,
`MODULE.bazel`, `README.md`). CI **green** on `main` — `bazel test //...` plus a CMake/`ctest` job
plus an ASAN/UBSAN job; ~56 gtest cases in `src/test/`, deterministic numeric assertions, no mocks.
No AI marks at root.

**Lane:** `FunctionExpr` carries only scalar `R^n -> R` functions, so a
`ConstrainedOptimizationProblem` must enumerate every constraint as its own expression and
`AugmentedLagrangian` advances one `LagrangeMultiplierState` scalar at a time. Add a **composition**
expression over a vector-valued inner map — a `VectorFunctionInterface` carrying a Jacobian, the
composed gradient `J^T grad f` and Hessian `J^T H_f J + sum_i (grad f)_i H_{g_i}` — propagated
through the existing `DifferentiabilityMode` lattice and consumed by the penalty / AL composite as a
constraint **block**. `grep -rn "Jacobian\|Compose\|VectorValued" include/` returns **zero**
machinery hits. Sketch ~300-330 eff over 6 files.

Seams: the shared kernel is `function_base.h:52` `FunctionInterface` plus its mode-downgrade adapter
at `:136-161`; the interdependence is `function_expressions.h:76-91` `MinDifferentiability` against
`function_problem.h:54-70`, where `ConstrainedOptimizationProblem` collapses objective and
constraints to a **single** mode (and `:40-52` documents that the asymmetric-mode parameter was
deliberately deleted) — forcing `Second` on the compose node to get a Hessian breaks CTAD for every
existing deduction guide. Misdirection is strong: dropping the `sum_i (grad f)_i H_{g_i}` term
leaves value and gradient exact, so `lbfgs`/`bfgs` still converge and their tests pass; the failure
surfaces only in `trust_region_newton.h` as a CG-Steihaug step that stops progressing and in
`progress.h:152-165` as a KKT criterion that never trips — i.e. as "the solver doesn't converge".

**Why RANK 2 and not RANK 1:** (a) heavy C++17 template metaprogramming (CRTP + type erasure +
`if constexpr` mode dispatch) is a real 0%-pass / unsolvable risk, because agents burn the run on
compile errors instead of semantics — a smoke run is mandatory before committing a batch;
(b) the **sibling-library check is a live threat**: Ceres / NLopt / CasADi all ship vector-valued
residuals with Jacobians, and this is the exact shape that killed `sfepy-arc-length-continuation`
("the hard part is a named textbook algorithm"), so the differentiator must be the propagation
through *this repo's* mode lattice, PHR penalty builder and KKT stop, never the chain rule itself;
(c) near-dead tracker (1 open issue) is a ranking penalty and leaves no maintainer-welcomed lane to
cite. Do **not** take the finite-difference-accuracy lane: open issue `#175` (2026-08-29, 0 comments)
is exactly it. Do **not** take CMA-ES: v1 shipped it and v2 dropped it (previous-major-version
reject). Clone at `worktrees/_hunt/l_sci0920b/cppnum` (1.2 MB).

---

## RANK 3 (FALLBACK) — python-control/python-control — ★2082 — Python

Pool repo, BSD-3-Clause, 2 of 6 submissions used (`python-control-analysis-points`,
`python-control-multirate` — both in the **interconnection / discrete-time** subsystem class, so the
self-collision rule points elsewhere in the repo). 44 commits/12mo (cold), 81 open issues, 9 open
PRs, no AI marks, last real code commit 2026-08-13.

Open-PR enumeration (file lists, not keywords) shows the claimed lanes precisely: `bdalg.py` +
`statesp.py` (`#1249` lft), `mateqn.py` + `stochsys.py` (`#1248` symmetry), `sysnorm.py` (`#1201`),
`robust.py` (`#1184` hinfsyn), a large `dde.py` + `delaylti.py` addition (`#1148` continuous delay
systems), `modelsimp.py` (`#1031` okid), `statesp.py` (`#1039` xperm, `#888` d2c). **Untouched by
every open PR:** `flatsys/` (differential flatness and trajectory generation), `optimal.py`
(optimal control / MPC), `descfcn.py`, `phaseplot.py`, `nlsys.py`'s simulation surface.

**Why RANK 3:** the cold lanes are attractive but their hard parts (differential flatness, direct
collocation MPC) are named textbook methods with public siblings (`do-mpc`, CasADi, `gekko`), which
is the sibling-library death class — a lane here must be built on python-control's own
`InputOutputSystem` / signal-naming / interconnect model, not on the method. Also `#1148` has been
open since 2025-05 with a 9,000-line diff, which is a published solution for anything in the delay
lane.

---

## Closest misses and why each died

**EDA / hardware cluster**

- **olofk/edalize** (Python, BSD-2, ★796, CI green, 36 PRs merged/12mo — mechanically the cleanest
  repo in the cluster). **EXCLUSIVITY-DEAD.** Enumerating all 52 open PR file lists shows one
  contributor, `ThVerg`, sweeping the entire Flow API kernel in 8+ open PRs from 2026-05..09: `#525`
  type hints touching `flows/edaflow.py` (+104/-36) **and every file in `flows/` and `tools/`**,
  `#562` flow-option validation, `#563` EDAM tool-option scoping, `#546` Makefile-writer dedup
  (`utils.py`), `#542` mutable defaults, `#541` file handles, `#570` frontend completion targets.
  Any flow-API lane sits on published diffs. The only untouched alternative is the legacy
  `edalize/*.py` backends, which the maintainer is deprecating — and those already ship VHDL library
  (`logical_name`) handling, so the obvious "add libraries to the Flow API" lane is the repo's own
  earlier generation.
- **librelane/librelane** — `CI` conclusion **failure** on the default branch, 3 of the last 8 runs.
  Requirement 7, hard reject.
- **The-OpenROAD-Project/OpenLane** — corpse and self-superseded: default branch `superstable`, last
  commits 2025-09-15 and they are `hotfix: fix venv target` / `docs: clarify openlane/librelane
  status`.
- **Xilinx/finn** — no test-running workflow on the default branch (`pre-commit.yml` only;
  `quicktest-dev-pr.yml` is PR/dev-branch), and the suite needs Vivado/Vitis. Requirement 7 +
  Docker.
- **google/xls** — Bazel monorepo, a test build is hours and tens of GB. **trabucayre/openFPGALoader**
  — libftdi1/libusb system C in the test path. **dalance/svls** — the whole crate is ~500 LOC; all
  machinery lives in the author's separate `sv-parser`/`svlint` crates (repo-boundary absorption).
  **yaqwsx/PcbDraw** and **aklofas/kicad-happy** — import KiCad's `pcbnew`, installed from a PPA;
  not reproducible offline. **sergeykhbr/riscv_vhdl** — 14 months stale.

**Geometry / mesh / point cloud** (the whole cluster returned zero)

- `wildmeshing/fTetWild` MPL-2.0; `Yixin-Hu/TetWild` GPL-3.0; `wildmeshing/wildmeshing-toolkit`
  204 stars + NOASSERTION — licence/star rejects.
- `fwilliams/point-cloud-utils` (last push 2025-09-10) and `kzampog/cilantro` (2025-06-23) —
  Requirement 3 corpses.
- `eidelen/DicomToMesh` — VTK9 + DCMTK + Qt5 in the test build path.
- `url-kaist/patchwork-plusplus` — one published-paper algorithm, and the only tests are smoke
  tests.
- `mapbox/supercluster` (one 486-line file), `mourner/kdbush` (20 kB), `mapbox/delaunator` (27 kB),
  `w8r/martinez`, `mfogel/polygon-clipping`, `mapbox/earcut` — single-algorithm libraries; a 250-eff
  addition would be most of the codebase, and none can meet the >=2-file floor honestly.
- `CadQuery/CQ-editor` — PyQt5 GUI over conda-only OpenCascade bindings.
- `pyvista/pyvista` — `CLAUDE.md` + `AGENTS.md` + `.claude/` at root **combined with** an active
  gap-closing stream, and a VTK wrapper besides.
- `hhoppe/Mesh-processing-library` — `CLAUDE.md` at root and **zero** GitHub Actions runs.
- `MeshInspector/MeshLib` NOASSERTION + CUDA; `libigl`, `meshlab`, `Easy3D`, `CGAL` GPL/LGPL/rider.
- **`JamesLMilner/terra-draw`** (TS, MIT, ★1104, CI green, 24k LOC, 95 spec files) was the best
  *shell* in the whole session and is worth a revisit in ~6 months: killed because **every** lane is
  claimed — issue `#638` is a maintainer numbered v2 roadmap covering snapping and
  self-intersection/validation (the oxipng `#551` death class), `#425` has the maintainer declaring
  holes intentionally unsupported "due to the level of complexity" (Gate 8), open PR `#851`
  publishes the whole select-behaviour kernel diff and `#846` the geodesic/web-mercator lane.

**Signal / instrumentation / industrial protocols** (the whole cluster returned zero)

- `epfl-lts2/pygsp` (last commit 2025-09-11) and `OverLordGoldDragon/ssqueezepy` (last real code
  2024-11) — Requirement 3 corpses.
- `neuropsychology/NeuroKit`, `laszukdawid/PyEMD`, `Mayitzin/ahrs` — textbook-formula catalogues
  (Welch PSD, HRV indices, DFA; EMD/EEMD/CEEMDAN; Madgwick/Mahony/AQUA), every one with a public
  sibling shipping the same algorithm.
- `ottowayi/pycomm3`, `dmroeder/pylogix`, `sanny32/OpenModScan` — **no `.github/workflows` running
  tests at all** (pycomm3 and pylogix have only issue templates; OpenModScan has 7 packaging
  workflows and zero test workflows), because the tests need real hardware. On protocol/device
  repos, `gh api repos/R/contents/.github/workflows` is the cheapest first query there is: it killed
  three repos in one call.
- `pothosware/SoapySDR` — a plugin/registry API over out-of-tree vendor modules, and every commit in
  12 months is CMake/SWIG build compatibility.
- `PyWavelets/pywt` — MATLAB Wavelet Toolbox defines its semantics (`tests/test_matlab_compatibility.py`
  is in-tree), and every candidate lane already has a long-open **zero-comment** issue asking for
  exactly it (`#661` SWT extension modes 2022, `#768` non-decimated wavelet packets 2024, `#491` swt
  adjoint 2019, `#425` dual-tree complex WT, `#328` icwt). Textbook derivative magnet.
- `rokath/trice` (AGENTS.md + a visibly agent-run housekeeping stream, 0 issues 0 PRs),
  `rsadsb/adsb_deku` (last 6 CI runs on `master` all `failure`, plus 9 open PRs covering the two
  obvious lanes), `raphaelvallat/yasa` (`HYPNOGRAM_ROADMAP.md` at root plus a solo sweep over that
  exact surface), `nominal-io/instro` (`CLAUDE.md` + `AGENTS.md` + `.agents` + `.claude` + `.codex`
  + a `claude-review.yml` workflow), `imageio/imageio` (dormant with 24 open PRs covering every
  plugin/dispatch lane).

**From the previous hunter's abandoned shortlist (`i_size/short1.txt`)**

- `cvanaret/Uno` — 1063 commits/12mo and 27 open PRs: capability-consuming across the whole
  ingredient matrix.
- `guillermo-navas-palencia/optbinning` — 17 open PRs, 11 of them filed by `lcrmorin` on a single
  day (2026-08-23) and 3 more on 2026-09-19, covering Scorecard bin lookup, BinningProcess,
  `transform`, significance tests and dtype detection; plus Copilot-authored commits and PRs open
  since 2023. Burst + full-queue dormancy.
- `facebook/SPARTA` — mechanically clean (MIT, C++ 77% + Rust 22%, CI green) and structurally
  attractive (a C++ reference with a Rust twin under an identical-behaviour convention = the
  F-30/31/32 seam family from cwerg), but `arthaud` is **currently** rewriting exactly that kernel:
  `Preserve structural sharing in update, intersect and leaf combine`, `Widen on the local iteration
  count, as the C++ iterator does`, `Update uniquely owned Patricia nodes in place`, `Reference
  count tree nodes with triomphe::Arc`. Capability-consuming in the only lane worth taking. Revisit
  if that sweep lands and stops.
- `arminbiere/cadical` (every lane is a named CDCL/inprocessing technique with kissat/minisat/glucose
  as public siblings), `Simple-Robotics/proxsuite` (named algorithm + Eigen), `polyfem/polyfem`
  (490 commits, 23 open PRs, huge system deps), `BaseXdb/basex` (1,415 commits/12mo firehose, and
  XQuery is a famous spec), `infer-actively/pymdp` (a port of SPM's MATLAB `spm_MDP_VB_X`),
  `cdt15/lingam` + `graspologic` + `X-DataInitiative/tick` (algorithm catalogues or dormant),
  `go-spatial/tegola` (vector tiles — we already hold `tippecanoe` and `planetiler` in that class),
  `Esri/geometry-api-java` (5 code commits/12mo with 6 open PRs), `ucbrise/confluo`,
  `google/badwolf`, `ProjectQ-Framework/ProjectQ` (corpses, caught by the new `lastcode` column).

**From sweep 2** — `MITK`, `commontk/CTK`, `OHIF/Viewers`, `cornerstoneTools` (medical-imaging
toolkits with VTK/ITK/Qt or a deprecated banner), `mne-python` (619 open issues, famous domain),
`gunrock` (CUDA), the `raytracing` topic (demo renderers). Nothing reached a dossier.

---

## Decisions taken unattended (the skill says "ask the user"; I took the documented default and logged it)

1. **Re-opened `siliconcompiler` against two recorded kills.** Evidence in RANK 1 risk 1. The
   documented default is to follow the evidence when a blanket verdict is refuted by reading the
   repo (the `DataFixerUpper` LESSON A precedent in the same file) and to record it. Recorded here
   rather than editing `SATURATED-REPOS.md`, because other hunt sessions may be writing that file
   concurrently; the correction is owed and is stated in the method notes below.
2. **Did not build or install anything.** Root is at 14 GB with a builder running; the skill's disk
   rule and the run brief both say skip builds under 8 GB and delete build output immediately. No
   `pip install`, no `cargo`, no `cmake`, no `docker build` ran in this session. Consequences:
   Gate 1 (reproduce-on-base) and Gate 9 (3-5x determinism) are **OWED**, and the Docker line is an
   estimate.
3. **Sweep 2 stopped at 64 of 98 topics** when the GitHub search API returned its secondary limit
   (three screening subagents were on the same endpoint). Default taken: do not wait out the limit,
   spend the remaining budget on the candidates already in hand. The 34 un-run topics are in
   `topics2.txt`.

---

## Method notes worth carrying into the skill

1. **The `lastcode` column works and should be permanent.** Filtering the default-branch history on
   non-chore subjects, in the same GraphQL call that fetches stars/licence/root-tree, caught three
   corpses (`confluo`, `badwolf`, `ProjectQ`) that `pushed_at` reported as alive and cost nothing.
   `slice2.py` + `rep.py` do 267 repos in 23 calls; reuse them rather than rewriting a REST loop.
2. **`SATURATED-REPOS.md` has kill rows with bare slugs and no URLs, and the mechanical dead-list
   cannot see them.** Nine repos (the tool-harness row) are invisible to every `deadlist_v*.txt`.
   Normalise the file to URLs or teach the builder to parse bare `owner/repo` tokens from table
   cells. This is how siliconcompiler reached a full dossier without tripping the filter — which
   turned out well here, but next time it will waste a session.
3. **On protocol / device / instrument repos, query `.github/workflows` FIRST.** Before stars,
   before licence, before the clone. Three repos died to one call each in the signal cluster
   because their tests need hardware, so they simply have no test CI.
4. **A blanket "tool-harness" verdict needs a marker check before it is believed.** A repo whose
   suite needs external binaries very often declares a pytest/ctest marker to split them out
   (`-m "not eda and not docker"` here). One `pyproject.toml` read settles it, and the same move
   would have saved `cocotb`/`gdsfactory`/`hls4ml` from being pre-judged too.
5. **The scientific/simulation/instrumentation topic niches are now ML-colonised** the same way
   star-sorted keyword search is. `robotics`, `simulation`, `point-cloud`, `remote-sensing`, `slam`,
   `lidar`, `motion-planning` return checkpoints and benchmark harnesses. What still returns
   engineering: `verilog`, `vhdl`, `fpga`, `eda`, `pcb`, `numerical-methods`, `optimization`,
   `finite-element`. Both survivors came from those.
6. **The proven pool is exhausted as a FIRST source.** Three consecutive sessions have reached the
   same verdict. It should be re-run as a cheap mechanical pass (it is now one `slice2.py` call) but
   budgeted as a fallback, not as the lead.

---

## Tooling left behind

- `worktrees/_hunt/l_sci0920b/slice2.py` — the rebuilt slice builder (meta + langmix + root tree +
  default-branch history, 12 repos per GraphQL call).
- `worktrees/_hunt/l_sci0920b/rep.py` — the flag/report formatter (`lastcode`, `AI:`, `LIC:`,
  `CORPSE`, `sub<N>`).
- `worktrees/_hunt/l_sci0920b/deadlist_v13.txt` (5,776), `subcount.txt`, `screened_prev.txt` (1,397).
- `topics.txt` + `sweep.sh` + `topicsweep.jsonl` (1,682 rows, 89 topics) -> `cand1.tsv` (137).
- `topics2.txt` + `sweep2.sh` + `topicsweep2.jsonl` (557 rows, 64 topics) -> `cand2.tsv` (32).
- `cache_all.tsv` (2,214), `cache_domain.tsv` (526), `cache_domain_new.tsv` (188) — the domain re-cut
  of the cached star-band index.
- `pool.txt` / `pool.jsonl` (67 proven-pool repos profiled), `short1_new.txt` / `short1.jsonl`
  (63 rows from hunter #4's abandoned shortlist).
- `BRIEF-0920B.md` — the screening brief the three niche subagents ran.
- Clones kept: `l_sci0920b/sc` (157 MB, siliconcompiler @ `6d3fea2a`), `l_sci0920b/cppnum` (1.2 MB).
  `edalize`, `terradraw`, `supercluster`, `pywt` deleted. No build output produced anywhere.
  Root disk 14 GB free, unchanged.

---

## Next hunt

If siliconcompiler fails the platform picker or the precheck, promote `PatWie/CppNumericalSolvers`
(**smoke-run solvability first** — C++ template metaprogramming is a real 0%-pass risk) and then
`python-control` (build the lane on its own `InputOutputSystem`/interconnect model, never on the
textbook method).

For a fresh sweep: do **not** re-run the scientific/simulation/instrumentation topic vocabulary —
sweep 1 and sweep 2 together cover 153 topics and returned two survivors, both from the
hardware/numerical corner. The next axis worth spending on is **repos whose tests are declared
behind a pytest/ctest marker split** — `gh search code "not eda" filename:pyproject.toml` and
similar — because that marker is precisely the signal that a tool-harness repo is in fact
Dockerisable, and this session's RANK 1 is proof that class is unscreened. Second choice: finish the
34 un-run topics in `topics2.txt`.
