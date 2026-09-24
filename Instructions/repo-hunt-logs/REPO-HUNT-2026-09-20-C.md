# REPO HUNT 2026-09-20-C

Unattended `olympus-factory` hunt. `CONSECUTIVE_MISSES=0`, so the standard (un-softened) rules apply
except for the 2026-09-09-B softenings already baked into `.claude/skills/olympus-hunt/SKILL.md`.
No hard platform rule (licence, language, activity, 500-star floor, live-upstream, exclusivity,
quota) was relaxed. Preferences: none given (any supported language).

Scratch: `worktrees/_hunt/m_0920c/` (new) plus the reused tooling in `worktrees/_hunt/l_sci0920b/`
(`slice2.py`, `rep.py`, `topics2.txt`, `cache_all.tsv`) and `worktrees/_hunt/i_size/`,
`worktrees/_hunt/j_0920/`.

- **RESULT: CANDIDATE — `pyocd/pyOCD`** (Python, Apache-2.0, ★1462, 0 of our subs, no AI marks,
  zero signature accounts, CI green on the default branch). Lane: one expression kernel consumed by
  a parse-time constant folder, a run-time interpreter and the `Control` predicate loop, with no
  purity analysis, no short-circuit and no 64-bit value domain — so folding a literal silently
  deletes probe transactions. ~380 eff LOC over >=4 files. Base `d1974ff` on `main`.
- **Fallbacks:** `netenglabs/suzieq` (path identity + snapshot alignment, ~315 eff);
  `spcl/dace` (recorded Dockerisable, core exclusivity-dead — do not re-derive).
- **Found by:** the hint's own marker-split re-screen, not by either fresh niche sweep.

**Followed the previous log's `NEXT_HUNT_HINT` verbatim**, both items: (1) re-screened the
"tool-harness" class on marker-split evidence instead of on the `SATURATED-REPOS.md` row, and
(2) finished the 34 un-run topics in `l_sci0920b/topics2.txt`. Both corrections the previous hunt
asked for were applied; see **Corrections applied** below.

---

## Taken / excluded before any screening

From `pipeline/LEDGER.md`: `pytest-dev/pyfakefs` (AWAITING-PRECHECK),
`libspatialindex/libspatialindex` (READY), `messageformat/messageformat`, `oxipng/oxipng`,
`Cysharp/csbindgen` (CLAIMED), `siliconcompiler/siliconcompiler` (SLICING — its clone at
`worktrees/siliconcompiler` and `worktrees/_hunt/l_sci0920b/sc` was not touched).
Reserved as other hunts' fallbacks and therefore not eligible for RANK 1:
`PatWie/CppNumericalSolvers`, `python-control/python-control`, `Restream/reindexer`,
`greatscottgadgets/luna`, `walles/riff`, `macs3-project/MACS`.
Every folder under `problems/` was also treated as taken.

---

## Corrections applied (both from the previous log)

**Correction 1 — the nine-repo "tool-harness" row is not evidence.** `SATURATED-REPOS.md:969` kills
`cocotb · glasgow · gdsfactory · siliconcompiler · OpenLane · librelane · edalize · hls4ml ·
openFPGALoader` with one reason: *"tests need a simulator, EDA binaries, klayout or hardware"*.
That row was already overturned once (siliconcompiler declares `eda`/`docker` pytest markers and CI
runs `pytest -m "not eda and not docker"` green). This session re-screened the whole row on evidence.
**Result: the row's VERDICT survives for 8 of 9 repos, but its REASON is wrong for most of them** —
see the table under *Marker-split re-screen* below. That matters, because the stated reason is what
a future hunt would trust.

**Correction 2 — `deadlist_v*.txt` misses bare prose slugs.** Rebuilt as
`l_sci0920b/deadlist_v15.txt` (6,087 slugs) from `deadlist_v13.txt` plus a second pass that greps
bare `owner/repo` tokens (not just `github.com/...` URLs) out of `SATURATED-REPOS.md`,
`TOO-EASY.md` and every hunt log, filtered to drop path-like tokens with a source-file extension.
⚠️ Residual gap, recorded for the next hunt: the line-969 row and the
`ariel-os · probe-rs · GP2040-CE · lucidgloves · trice · adsb_deku · rustsbi · octox` row list
repos as **bare repo NAMES with no owner**, so even a bare-slug parser cannot see them. The only
real fix is to normalise `SATURATED-REPOS.md` to `owner/repo` form.

---

## Stage 0-bis — proven-repo pool, mined first

Pool rebuilt mechanically from the `Repository:` frontmatter of every `meta.md` in
`approved-problems/`, `problems/` and `rejected/`: **73 repos** (`l_sci0920b/subcount14.txt`),
against the 67 the previous session profiled in full. The diff is exactly six rows —
`Cysharp/csbindgen`, `libspatialindex/libspatialindex`, `messageformat/messageformat`,
`open2b/scriggo`, `oxipng/oxipng`, `pytest-dev/pyfakefs` — and **every one of them is already
CLAIMED, in-flight, or platform-reserved** (scriggo). So the pool's screenable content has not moved
since `REPO-HUNT-2026-09-20-B` profiled all 67 in one GraphQL pass, and its verdict stands without
re-fetching:

> the surviving pool repos are either competitor/maintainer-occupied (pysmt, sysidentpy, tantivy),
> dormancy magnets (worldengine, with the erosion lane sitting in open PR #270), AI-swept at root
> while sitting in a lane we already hold (sqlfluff, numbat, ir-sim, RocketPy, awkward,
> go-workflows, featurevisor, neva), famous-spec implementations (WeasyPrint, fonttools, rust-url,
> taplo, comrak, pulldown-cmark), platform-reuse-warned (sfepy, 25 subs by 6 other contributors),
> or corpses with a filling PR queue (toydb, ezno, lifelines, orb, iced, GQL).

**This is the fourth consecutive session to reach that conclusion.** The pool is a fallback source,
not a first source, until new repos enter it — and the only repos entering it now are the ones this
factory loop is itself producing.

## Cached-index triage (before any fresh fetch)

`worktrees/_hunt/` holds 2,214 cached rows (`l_sci0920b/cache_all.tsv`) from the star-band,
year-window and language-slice sweeps, plus the 1,397 slugs the previous session marked screened.
Cut against `deadlist_v15.txt` + `screened_prev.txt` + the previous session's `cand1/cand2/
cache_domain_new/sweep0920b` sets, the residual is **617 never-screened rows**
(`l_sci0920b/residual_0920c.tsv`); after a junk-description filter, 537 remain
(`residual_filtered.txt`), and all 537 were read.

**Yield: zero, and the failure is structural.** The residual is almost entirely (a) glue libraries
and clients (Django/Home-Assistant integrations, GraphQL/Redis/S3/Elasticsearch clients,
`aiomysql`, `supabase-py`, `pychromecast`), (b) single-header C++ utilities (`Tessil/robin-map`,
`ordered-map`, `hopscotch-map`, `LBFGSpp`, `Terathon-Math-Library`), (c) graphics/driver/kext code,
(d) ML research repos. The only engine-shaped rows were already dead for other reasons:
`google/jsir` (Bazel + MLIR, Docker-infeasible), `hyrise/sql-parser` (SQL = the second-most
saturated domain on the platform), `numba/llvmlite` (LLVM binding), `py2many/py2many` and
`elliotchance/c2go` (transpilers whose capability is named by the target language).

This is now the **third independent axis** (star band, domain vocabulary, and this residual cut) on
which the cached index reads exhausted. Recommend the next hunt stop cutting it and spend the
minutes on fresh sweeps instead.

## Sweep 0 (finishing the previous session's) — the 36 un-run `topics2.txt` topics

`l_sci0920b/sweepC.sh` + `topics_rem.txt`: `dnp3 chromatography flow-cytometry microfluidics
bioreactor titration rheology tribology heat-transfer hydraulics pneumatics mineralogy petrology
stratigraphy tide permafrost agronomy phenology polarimetry ellipsometry photometry radiosity
bathymetry fatigue fracture-mechanics truss plate composite-materials crystal-plasticity
boundary-element spectral-method preconditioner timeseries changepoint anomaly-detection
survival-analysis`.

106 rows returned. After `deadlist_v15` + `screened_prev` + the licence allowlist + the
500-6000 star window + the 12-month activity cut: **14 survivors, and every one is an ML /
time-series / database-client repo** (`chronos-forecasting`, `gluonts`, `Merlion`, `PyPOTS`,
`OpenOOD`, `ADBench`, `luminaire`, `node-influx`, `go-carbon`, `influxdb-client-python`, …).
**Yield: zero.** The previous log predicted this ("on this evidence the expected value is low") and
it was right. The `topics2.txt` vocabulary is now 100/100 run and fully exhausted — do not re-run it.

## Marker-split re-screen (the hint's item 1) — the nine-repo "tool-harness" row, on evidence

All nine were profiled with `l_sci0920b/slice2.py` (`th.jsonl`) and then read individually: root
tree, `pyproject.toml` marker block, the workflow file that runs tests, the default-branch CI
conclusions, and — for the two that survived that far — the full open-PR file-list enumeration and
the 6-month commit stream by directory.

| Repo | Marker split? | Real verdict, and why the row's reason is wrong or right |
|---|---|---|
| `siliconcompiler/siliconcompiler` ★1215 | **YES** — `pyproject.toml:139-148` declares `eda`/`docker`/`nightly`/`slurm`; CI runs `pytest -n logical -m "not eda and not docker"` green | Row's reason **WRONG**. Already re-opened by `REPO-HUNT-2026-09-20-B` and now SLICING. |
| `cocotb/cocotb` ★2510, BSD-3, CI green | **YES** — `pyproject.toml` declares `simulator_required` and `compile`, `testpaths = ["tests/pytest"]` | **DEAD, but not for the row's reason.** The marker split is real and the pure job is green; what kills it is that (a) the package's test build path compiles the C++ GPI layer (`src/cocotb/share/lib/gpi/**`, `cocotb_build_libs.py`), and (b) every lane with a capability model — `handle`, GPI object discovery, triggers, the scheduler — is *behind* `simulator_required`, so the marker split does not reach it. The only pure surface is `cocotb.types` (`Logic`/`LogicArray`/`Range`), which is IEEE-1164 by name = derivative magnet. Add Stage 2c: **59 open PRs**, `ktbarrett` sweeping `handle.py`, `GpiCommon.cpp`, the Runner and the test decorators (`#5750 Handle Optimizations`, `#5532`, `#5389 Implement cocotb.run`) — capability-consuming in exactly those lanes. |
| `GlasgowEmbedded/glasgow` ★2208, 0BSD, CI green | **YES (effectively)** — `software/tests/{gateware,protocol,support}` are Amaranth *simulation* tests; CI's `test-software` job runs them on 5 interpreters with only `libjpeg8-dev zlib1g-dev` from apt, and the bitstream toolchain is the pure-wheel YoWASP (yosys/nextpnr as WASM) | **DEAD, and the row's reason is WRONG.** Python is 96% of bytes, licence 0BSD, CI green, tests need no hardware — it is Dockerisable. It dies on **Stage 2c capability density instead**: 222 commits since 2026-03-20 spread across `gateware.stream`, `gateware.iostream`, `gateware.octoram`, `abstract`, `hardware.assembly`, `cli`, `support.usb` *and* the applet tree, i.e. every lane I could name, while whitequark is mid-flight on a **V2 applet API migration** (7 open PRs titled "migrate to V2 API", plus `#1209 [WIP] Implement HyperFIFO`). The one cold surface is the applet plugin registry, which is the absorbed missing-arm shape by construction (35 open PRs, ~25 of them "new applet X"). |
| `gdsfactory/gdsfactory` ★1042, MIT | partial (`norecursedirs` excludes klayout/simulation plugins) | **DEAD** — **1,329 commits/12 months**, `.agents` at root and a `Running Copilot Code Review` workflow. Capability-consuming firehose; the row's "needs klayout" reason is also wrong (the core is gdstk/kfactory, pure wheels). |
| `fastmachinelearning/hls4ml` ★2154, Apache-2.0 | no | **DEAD on Requirement 7** — the GitHub Actions set is `pre-commit / pypi-publish / sphinx / update-branch-on-pr`; **no workflow runs the test suite** on the default branch. Tests live in `.gitlab-ci.yml` + `Jenkinsfile` against Vivado. `AGENTS.md` at root, 44 open PRs. Here the row's reason is essentially right. |
| `chipfoundry/openlane2` | n/a | **DEAD** — 374 stars (under the floor), 1 commit/12 months, `lastcode` = none. Corpse. |
| `librelane/librelane` ★544 | n/a | **DEAD on Requirement 7** — `CI` conclusion `failure` on the default branch (measured again this session and in `REPO-HUNT-2026-09-20-B`). |
| `olofk/edalize` ★796 | n/a (tests are pure golden-file comparisons — the row's reason is WRONG) | **DEAD on exclusivity**, measured last session: `ThVerg` is sweeping the whole Flow API across 8+ open PRs (`#525` touches every file in `flows/` and `tools/`, `#562`, `#563`, `#546`, `#542`, `#541`, `#570`). |
| `trabucayre/openFPGALoader` ★1736 | n/a | **DEAD** — C++ with `libftdi1`/`libusb` system C in the test build path, and it genuinely needs hardware. Row's reason right. |

**What this re-screen actually establishes** (worth more than the individual verdicts): the
marker-split signal is REAL and it does overturn the harness label — 4 of 9 rows (siliconcompiler,
cocotb, glasgow, edalize) are Dockerisable and were killed for a false reason. But in 3 of those 4
the repo still dies, on capability density or exclusivity, which the row never measured. **So the
correct use of the marker-split lens is as a REINSTATEMENT filter, not as a discovery axis**: it
tells you a repo is eligible, and you still owe it the full Stage 2b/2c audit. A future hunt should
rewrite `SATURATED-REPOS.md:969` to record the real per-repo reason rather than one blanket label.

### Deliverable from correction 2: a NAME-level dead list

`worktrees/_hunt/l_sci0920b/deadnames_v1.txt` — **152 bare repo NAMES** parsed out of the
`·`-separated multi-repo table cells in `SATURATED-REPOS.md` and every hunt log (the rows a
`owner/repo` parser can never see): `adsb_deku algebrite … cocotb … edalize … gdsfactory … glasgow
… hls4ml … librelane … openfpgaloader … openlane … probe-rs … siliconcompiler … trice …`.
Use it as a SECOND filter beside `deadlist_v15.txt` (match on the repo name after the `/`), and
treat a hit as "look up why it was killed" rather than as a kill — several of these rows carry the
blanket reasons this session just disproved.

## Method notes carried forward

1. **`gh search code` is not a discovery axis.** The hint proposed finding marker-split repos with
   `gh search code 'not eda' filename:pyproject.toml`. Measured this session: the code-search
   endpoint has **no star qualifier and no sort**, `filename:` is a prefix match (it returns
   `pyproject.toml.testing`, `pyproject.toml.jinja`, `pyproject.toml.in`), the rate limit is
   **10 requests/minute**, and marker names are either too specific to hit (`requires_hardware`,
   `needs_simulator`, `requires_vivado` -> `total_count: 0`) or too generic to filter (`slow`,
   `integration`). It works as a CONFIRMATION tool on a repo you already have, not as a sweep.
   The productive form of the hint was the reinstatement filter described above.
2. **`gh search repos --topic=` remains the only sweep that is not LLM-colonised**, but the
   scientific/instrumentation vocabulary is now provably spent: 98 topics in sweep 1, 64 + 36 in
   sweep 2/0, 196 topics for two survivors, both from the hardware/numerical corner. The 36 topics
   finished this session returned 14 survivors and all 14 were ML/time-series.
3. **The cached star-band index is exhausted on three independent axes** (star band, domain
   vocabulary, and the un-screened residual cut done here). Future hunts should budget zero minutes
   for it.

### The second blanket row, re-screened the same way

`SATURATED-REPOS.md`'s `ariel-os · probe-rs · GP2040-CE · lucidgloves · trice · adsb_deku ·
rustsbi · octox` row ("needs hardware, or corpse") plus the `rellic · binsync · CreuSAT` row
("harness-infeasible") went through `slice2.py` in one GraphQL call (`l_sci0920b/hwrow.jsonl`):

| Repo | Measured | Verdict |
|---|---|---|
| `ariel-os/ariel-os` ★1226 Apache-2.0 | **1,981 commits/12mo, 133 open PRs** | capability-consuming firehose — dead for a reason the row never states |
| `probe-rs/probe-rs` ★2944 Apache-2.0 | 547 commits/12mo, **91 open PRs**, 271 issues | large multi-maintainer team; the open-PR queue alone is a published prior-art surface. Its pure lanes (target description, flash loader, DWARF variable rendering) ARE Dockerisable, so the row's reason is wrong — it dies on exclusivity/velocity instead |
| `rokath/trice` ★996 MIT Go | **990 commits/12mo**, `AGENTS.md` at root, 0 issues / 0 PRs | solo firehose + AI mark |
| `rustsbi/rustsbi` ★1314 MIT | 263 commits/12mo | the capability IS the RISC-V SBI specification — famous-spec kill row |
| `GP2040-CE` ★2526 MIT C++ | 101 commits/12mo | Pico-SDK firmware, genuinely needs hardware — row right |
| `LucidVR/lucidgloves` ★2379 | 26 commits, last code **2025-10-27** | corpse — row right |
| `rsadsb/adsb_deku` ★729 | **5 commits/12mo** | corpse — row right |
| `binsync/binsync` ★745 BSD-2 | 56 commits/12mo, `CLAUDE.md` at root | needs IDA/Ghidra/angr — row right |
| `sysprog21/octox`, `rellic/rellic`, `CreuSAT` | slug resolution failed (moved/renamed) | not pursued |

Same pattern as the EDA row: **the blanket label is wrong about half the time, and the repos still
die** — on velocity, corpse status, or spec-nameability. Net effect of the whole re-screen: the
"tool-harness / needs hardware" class is REINSTATED as screenable but yielded no candidate here.

## Fresh sweeps (two, per the budget) — run as parallel screening subagents

Both used the same brief (`worktrees/_hunt/m_0920c/BRIEF.md`) plus `deadlist_v15.txt`, the shared
`slice2.py`/`rep.py` profiler and `sig_accounts.txt`.

- **Sweep A — network / protocol ENGINES.** ~50 single-word topics, 988 distinct repos, 286 through
  the mechanical gates, 192 in the 500-6000 star band, ~60 bulk-profiled, 10 fully audited.
  **1 conditional survivor: `netenglabs/suzieq`** (RANK 2 below).
- **Sweep B — text layout / font / document composition.** **0 survivors.** The niche is already
  almost entirely on the dead list (typst, cosmic-text, parley, allsorts, fontations, rustybuzz,
  fonttools, WeasyPrint, dropflow, taffy, KaTeX, verovio, dagre, mermaid, ratatui, textual, …).
  The three that got furthest all died on rules this workspace already owns — and two of them on
  the same one.
- **Sweep C (not a niche — the hint's correction) — the marker-split class.** 674 topic hits,
  590 after the dead list, 181 licence/language-clean, ~40 seriously screened, 14 code-search
  queries over 376 more repos. **1 survivor: `pyocd/pyOCD`** (RANK 1 below).

### ⚠️ Finding worth more than either survivor: the terminal-table / text-wrap sub-lane is BURNED

Sweep B's two best mechanical profiles died on `sig_accounts.txt`, not on any repo property:

- `olekukonko/tablewriter` (★4813, Go, MIT, 119 code commits/12mo, **1 open issue / 1 open PR**, CI
  green, no AI marks — the cleanest profile of the whole session) has merged PRs from **three**
  recorded signature accounts in the *width/wrap kernel that is the only lane worth taking*:
  `team-humaki` ("wrap: split Widths.Global across columns"), `youdie006` ("Terminate WrapWords when
  the last word is wider than the limit"), `ChrisJr404` ("feat/rgb-color-support").
- `J-F-Liu/lopdf` (★2253, Rust, MIT, 120 commits/12mo, 1 open PR) — `binggao1230` merged three
  commits in the stream-filter/predictor lane, and the single open PR #571 is `ChrisJr404`.
- `jedib0t/go-pretty` — `jakezwang` merged #423, inside a burst of fresh accounts landing
  CJK-display-width / `WrapHard` fixes.

Three rival authors are visibly working the same sub-lane right now. **Treat terminal tables, text
wrapping and display-width as a burned CLASS, not three burned repos.**

⭐ **Method change earned here, adopt it:** run the signature-account check **before any clone**.
Both of sweep B's finalists passed every mechanical gate, were cloned and seam-audited, and then
died on one grep. The pre-filter is one call:
```bash
gh api "repos/O/R/commits?per_page=100" -q '.[].author.login' | sort -u \
  | grep -Fxi -f worktrees/_hunt/sig_accounts.txt
```

---

# RANK 1 — `pyocd/pyOCD` — ★1462 — Python

- **URL / stars:** https://github.com/pyocd/pyOCD — ★1462
- **Language:** Python **4,489,305 B (99.7%)**. The 3,904 B of C and 1,410 B of Assembly are
  pre-built flash-algorithm blobs shipped as data (`pyocd/target/builtin/.../flash_algos/`) and are
  in no build path. The 2026-09-19 platform language gate is clear with an enormous margin.
- **Domain:** ARM CMSIS-DAP / SWD debug-probe host — probe transport, DP/AP transaction layer,
  target packs, flash algorithms, a GDB server, and an interpreted **debug-sequence language**
  (lark grammar, constant folder, tree-walking interpreter, 61-function delegate).
- **Licence:** Apache-2.0, verified by reading `LICENSE` (137 lines, "Apache License / Version 2.0,
  January 2004"). The only other licence file is `pyocd/target/builtin/cypress/flash_algos/license`,
  a data blob. `grep -rliE 'GNU (General|Lesser) Public'` over the tree: zero hits. No vendored
  source tree.
- **Activity:** default branch `main`; last real code commit **2026-07-21** (`cf440c3 pack: builder:
  allow explicit RAM range outside memory map`). Development also runs on `develop` (last code
  2026-09-15). **203 commits / 120 merged PRs / 48 closed issues in 12 months** — healthy, and not a
  firehose.
- **Open issues / PRs:** 308 open issues, 53 open PRs. Not dormant (120 merged in 12mo), so the
  dormancy-magnet kill row does not apply.
- **AI marks:** **NONE.** `ls -a` at root shows no `CLAUDE.md`, `AGENTS.md`, `.agents`, `.claude`,
  `.coderabbit.yaml`, `GEMINI.md`, `.cursorrules`; `.github/` contains only `workflows`.
- **Competitor screen (2b-bis):** 32 distinct commit + PR authors across the last 100 of each,
  checked against all 53 accounts in `sig_accounts.txt` -> **zero matches**.
- **Our submissions:** **0**. `pyocd`/`pyOCD` appears nowhere in `approved-problems/`, `problems/`,
  `rejected/`, `diamond-problems/` or `SATURATED-REPOS.md`. Quota 0/6.

### ⭐ Requirement 7 + the marker-split evidence (this is why the repo exists as a candidate at all)

pyOCD is a debug-probe host, so every naive read says "the tests need a probe and a real MCU". It is
in fact split by pytest **`testpaths`**, not by a marker:

```toml
# pyproject.toml:17-21   (read in the clone at d1974ff)
[tool.pytest.ini_options]
testpaths = ["test/unit"]
junit_family = "xunit2"
```
```yaml
# .github/workflows/basic_test.yaml:76-78
- name: Test with pytest
  run: |
    pytest --junitxml=test-results-${{ matrix.os }}-${{ matrix.python-version }}.xml --cov=pyocd
```

Bare `pytest` therefore collects **only `test/unit`** (24 files). The hardware-bound suite sits at
`test/` top level — `automated_test.py`, `flash_test.py`, `gdb_test.py`, `cortex_test.py`,
`connect_test.py`, `speed_test.py`, `probeserver_test.py` — is **never collected by pytest**, and is
driven separately by tox (`pyproject.toml:21-34`: `changedir = test`, `python automated_test.py -j4`)
against a physically attached board.

**CI verdict on the default branch:** `basic_test.yaml` on `main` = `success` x6 (2026-08-26,
07-21, 07-15, 07-01, 06-24 x2); same workflow on `develop` = 6/6 `success`, latest 2026-09-15;
`CodeQL` and `Nightly` also green.

**And the lane's own tests are inside the pure job:** `test/unit/test_debug_sequences.py` is
777 lines / 56 tests, the largest file in `test/unit`, and it drives the kernel below through a
software `MockProbe` (`:110`) and a `SequenceFunctionsDelegateForTesting` (`:43`). No probe, no MCU,
no vendor toolchain.

### LANE

*Make the debug-sequence expression kernel obey ONE arithmetic and evaluation-order model across
all three surfaces that consume it — the parse-time `_ConstantFolder`, the run-time
`_InterpreterVisitor`, and the `Control` predicate loop — so that a `Block`'s value AND its emitted
DP/AP transaction stream do not depend on whether an operand happened to be an integer literal.*

### Missing machinery (what the repo structurally cannot do), measured in the clone at `d1974ff`

1. **No purity / side-effect analysis over the expression AST.** There is no way to ask "may this
   subtree be discarded?", so `_ConstantFolder` (`sequences.py:598-644`) drops whole subtrees that
   contain `Read32` / `WriteDP` / `DAP_Delay` / `Query` calls.
2. **No short-circuit evaluator.** `_InterpreterVisitor.binary_expr` (`sequences.py:922-923`) calls
   `self.visit_children(tree)` **first**, so `x != 0 && Read32(addr)` performs the AP read even when
   `x == 0`. Same for `||`.
3. **No 64-bit unsigned value domain.** `Scope.set`'s docstring says *"Integer value of the
   variable. Limited to 64-bit."* (`scope.py:88-115`) and nothing masks anywhere.

### The contradictions that make the base observably wrong (all verified by reading the clone)

- `sequences.py:664-666,672` — `'+': lambda l, r: l + r`, and the same for `-`, `*`, `<<`: **no
  64-bit mask**. But unary `-` DOES mask (`:689`, `& 0xffffffffffffffff`). So `0 - 1` and `-1`
  disagree inside one expression language.
- `sequences.py:667-668` — `/` and `%` use Python floor semantics, which diverge from C truncation
  the moment a value goes negative (which is only reachable *because* `-` is unmasked).
- `sequences.py:673` — `>>` is an arithmetic shift on an unbounded Python int, under a documented
  unsigned model.
- `sequences.py:674-675` — `&&` / `||` are plain lambdas over both operands; combined with the eager
  `visit_children` at `:923`, neither short-circuits.
- `sequences.py:619-622` — the folder's `left == 0` branch lists `'-'` among the
  "result is the right operand unmodified" ops, so **`0 - x` folds to `x`**. Flatly the wrong sign.
  (The two branch COMMENTS are also swapped relative to their conditions, which is exactly the kind
  of detail an agent skims past.)
- `sequences.py:610-613` — the folder's `right == 0` branch lists `'||'`, so **`x || 0` folds to
  `x`** (e.g. `5`), while `test_bool_and_or_expr` at `test/unit/test_debug_sequences.py:436` states
  the opposite contract verbatim: *"they must produce a 1 or 0 and not the value of either operand"*.
- `sequences.py:616-618` — `x && 0` folds to `0`, **discarding `x` entirely** and silently skipping
  every probe transaction inside it.

### TRAP SEAMS (`failure-patterns.md`)

| Pattern | Present | Evidence |
|---|---|---|
| F-9 cross-stage resolution drop | **yes (lead)** | the SAME operator semantics are resolved twice — once at parse time in `_ConstantFolder.binary_expr` (`sequences.py:598`) and once at run time in `_InterpreterVisitor.binary_expr` (`:922`) — from one shared table `_BINARY_OPS` (`:663`). One root cause breaks every capability at once. |
| F-19 shared-helper side effect on a global channel | **yes (variant)** | the discarded channel here is the probe TRANSACTION STREAM, not stdout: folding `x && 0` to `0` deletes real DP/AP writes. The `MockProbe` log is the observable. |
| F-10 capability cross-product | **yes** | {literal op literal, literal op expr, expr op literal, expr op expr} x {folder path, interpreter path, `Control` predicate path, compound-assign path `:874`}. Multiplicity axis = which operand is a literal; polarity axis = `&&` vs `\|\|` (the F-27 dual-combinator shape). |
| F-27 dual-combinator polarity | **yes** | `&&` and `\|\|` need mirror-image short-circuit and mirror-image fold identities; the folder currently gets `\|\|` wrong in one branch and `&&` wrong in another. |
| F-15 arming-vs-firing | **yes** | `Control.execute` (`:497-528`) starts a `Timeout` and loops `while result and timeout.check()`. A width fix that stops values wrapping at 2^64 arms an unterminating `while`. |
| F-14 declared-vs-derived terminal state | **yes** | `/` and `%` by zero return `0` rather than raising (`:667-668`), a deliberate divergence sitting beside `SemanticChecker` (`:692-828`), which could declare it an error instead. |
| F-8 named-algorithm override | **yes** | the Open-CMSIS-Pack Debug Description spec names a 64-bit unsigned C-like model; pyOCD's actual behaviour diverges from it in six measured places. Use the name as MISDIRECTION, never as the scope. |
| F-22 fixpoint | no | no iterate-to-stability loop in this subsystem. |
| F-13 two-tier format | no | — |

### Eff-LOC sketch — DECISION POINTS, not surfaces

| Decision cluster | eff |
|---|---|
| 64-bit unsigned value domain: `to_u64`/`as_signed`, applied at the `Scope` boundary (`scope.py:88`) | 25 |
| `_BINARY_OPS` -> per-op dispatch with width/sign rules (18 ops; `/` `%` truncate toward zero, `>>` logical, `<<` masked, comparisons unsigned) | 70 |
| `_UNARY_OPS` consistency (`~`, `-`, `!`) | 15 |
| **purity analysis over the AST** (fncall => impure; propagate through binary/unary/ternary/assign; new visitor) | 55 |
| folder gated on purity + boolean normalisation of the `&&`/`\|\|` identities | 45 |
| short-circuit in `_InterpreterVisitor.binary_expr` — restructure away from eager `visit_children` | 35 |
| lazy ternary + ternary folding under purity (`:584`, `:900`) | 20 |
| compound-assignment path through the new kernel (`:874`) | 15 |
| `Control.execute` truth test + timeout interaction under the new model (`:497`) | 25 |
| `functions.py` argument/return coercion at the 61-function delegate boundary (`read32:362`, `write32:436`, `dap_delay:514`, `query:588`) | 40 |
| `SemanticChecker` diagnostics (shift count >= 64, STRLIT in arithmetic) (`:692-828`) | 35 |
| **total** | **≈ 380 human-effective** |

Across >=4 non-test files (`sequences.py`, `scope.py`, `functions.py`, plus a new purity module).
Clears the 250 proceed line with margin. Items 4-6 are the genuinely new machinery — **they, not the
width mask, must carry the pick** (see the guard below).

### ⭐ Gate 5 COLD-NOT-LIVE — the kernel is frozen, the periphery is warm

| File | Commits ever on `develop` |
|---|---|
| `pyocd/debug/sequences/scope.py` | **1, on 2019-07-22.** Never touched since the subsystem was created. |
| `pyocd/debug/sequences/sequences.py` | **7 ever.** 2026: `traceclockin`/`traceclockout` debug vars, a `FlashSequenceParams` API argument, a STRLIT quote fix. **Nothing has touched `_BINARY_OPS`, `_ConstantFolder` or the interpreter's evaluation order since the 2019 original commit.** |
| `pyocd/debug/sequences/functions.py` | warm — `stream trace buffer data` (2026-09-14), `flash setup sequences` (2026-07-14), `runpython` (2026-06-15) |

Corollary for the author: the **delegate-function** surface of this package is the maintainer's live
workstream (trace + flash setup landed on `develop` in Sept 2026). Do not frame the pick as "add
function X"; the expression kernel is the cold part and it is where the lane lives.

### Prior-art / exclusivity checks run at hunt time

- **Open-PR enumeration (all 53, file lists, not keyword search):** exactly two list
  `sequences.lark` + `sequences.py` — **#1604** (`flit: cortex-m: step over breakpoint`, OPEN since
  2023-08-05) and **#1687** (`target: add xc2xx device support for XHSC`, OPEN since 2024-04-16).
  I pulled both real diffs: their sequences hunks are the `assign_stmt` -> `assign_expr` rename from
  the **already-merged** #1564, resurfacing through a stale base. Neither adds width semantics,
  short-circuiting or fold purity. Every other open PR is a target/board/SVD addition or probe
  plumbing. **Lane exclusivity holds.**
- **Epic / roadmap search:** `search/issues?q=repo:pyocd/pyOCD+in:title+epic` -> 0;
  `+in:title+roadmap` -> 0. No numbered plan, no checkbox stage list (the oxipng #551 death class).
- **Magnet test on the CAPABILITY:** no open, uncommented, long-lived issue asks for any of this.
  #1545 is an unrelated NXP attach failure. The 2026 closed sequences issues (#2030 trace, #2006
  flash setup, #1981, #1968, #1969, #1939) are all delegate-function work.
- **Sibling-library check:** `gh search code "DebugSequenceExecutionContext"` returns only pyOCD and
  Zephyr/vendored forks of it. No other OSS project, in any language, ships a CMSIS debug-sequence
  evaluator.
- **Previous-major-version check:** debug sequences were introduced in pyOCD itself (issue #1488,
  2022); no earlier pyOCD release and no parent project carries the capability.
- **Removal-record check (the kira gate):** nothing in the changelog removes any of this.
- **Self-collision:** `pyocd` appears in none of our dirs. Nearest feature classes are
  `approved-problems/tantivy-pipeline-aggregations` (evaluation order in an aggregation pipeline —
  different repo, domain and capability) and `rejected/cfn-guard-arithmetic` (**"add arithmetic
  operators to a rules language", shelved DERIVATIVE**). ⚠️ That second one is the framing hazard:
  pyOCD's operators already EXIST — the capability is reconciling three consumers of one op table,
  not adding arithmetic. `meta.md` must be written on `_ConstantFolder` / `Interpreter` / `Control` /
  `Scope` / `DebugSequenceDelegate` and on the transaction-stream invariant, never as "fix the
  arithmetic semantics".

### Stage 6 death-class guard — run explicitly, PASSES all four

1. **One shared kernel feeding several surfaces?** **Yes.** `_BINARY_OPS` (`sequences.py:663`) and
   `_UNARY_OPS` (`:685`) are consumed by `_ConstantFolder.binary_expr` (`:598`),
   `_InterpreterVisitor.binary_expr` (`:922`), `_InterpreterVisitor.assign_expr` (`:874`) and the
   `Control.execute` predicate loop (`:497-528`). A local fix to the folder regresses the
   interpreter's own documented contract at `test_debug_sequences.py:436`, and vice versa.
2. **Interdependent AND misdirecting?** **Yes, in three measured chains.** (a) Gate the folder on
   purity and it stops folding `x && Read32(a)` — which only helps if the interpreter now
   short-circuits, so fixing A *surfaces* B. (b) Normalise the `&&`/`||` fold identities and
   `TestConstantFolder::test_fold_left_0` (`:569`) / `test_fold_right_0` (`:588`) break — tests the
   agent never wrote and did not touch. (c) Mask `_BINARY_OPS` to 64 bits without masking at the
   `Scope` boundary and a `while` predicate stops wrapping at 2^64: the failure surfaces as a **hang
   under `Timeout`** (`:509-511`), pointing at the control-flow code, not at arithmetic. Reinforcing
   the misdirection, `Control.execute` builds **one** `Interpreter` at `:505` and re-runs it every
   iteration while `Block.execute` builds a fresh one per execution (`:566`) — so the same folding
   change behaves differently inside a loop than inside a block.
3. **Could a standalone new file with minimal wiring solve it?** **No.** The purity visitor is new
   but inert on its own: it is worthless unless the existing folder is gated on it and the existing
   interpreter is restructured away from `visit_children`. The capability is defined by modifying two
   existing visitors that must agree.
4. **`TOO-EASY.md` Pre-Pick Guard 1-5.** (1) ⚠️ **the one real risk** — the 64-bit mask alone IS
   "one rule at many sites", so it must NOT be the load-bearing axis; the purity analysis,
   short-circuit restructure and fold/interpreter reconciliation are not a uniform wrap and must
   carry the difficulty. (2) single-subsystem (`debug/sequences/`), which is fine for Olympus, and
   there are >=2 hidden-integration walls (the `Control` single-`Interpreter` reuse, the `Scope`
   boundary, the 61-function `functions.py` coercion edge). (3) the hardness survives full
   statement: you can write "short-circuit, 64-bit unsigned, the folder must preserve side effects"
   and the agent must still discover that the folder and the interpreter disagree *today*, that two
   existing tests lock the old folder in, and that `Control` reuses one interpreter. (4) not a port —
   no other project has this evaluator. (5) survives being spelled out.

**Verdict: hand over, with the design constraint in (4.1) written into the handoff.**

### Docker

Pattern B, `olympus-base-python` + `pip install -e .[test]`. `setup.cfg` install_requires are all
pure-Python or manylinux wheels: `capstone`, `cmsis-pack-manager`, `libusb-package` (bundles its own
`.so`), `lark`, `intervaltree`, `pyelftools`, `pyusb`, `pyyaml`, `intelhex`, `natsort`,
`prettytable`, `pylink-square`; `hidapi` is explicitly excluded on Linux
(`platform_system != "Linux"`). No system headers, no CGO, no external tool, no network at test
time. `test.sh` = `pytest test/unit --junitxml="$OUTPUT_PATH"`; the unit suite runs in seconds with
no sleeps, no RNG and no probe. **Estimate only — no image was built in this hunt.**

### Risks, in order

1. ⚠️ **Two existing tests encode one of the bugs.** `TestConstantFolder::test_fold_left_0`
   (`test/unit/test_debug_sequences.py:569`) and `::test_fold_right_0` (`:588`) assert
   `x || 0 -> x` and `0 - x -> x`. `test.patch` must AMEND those parametrize tables (the repo's own
   run-time test at `:436-437` states the opposite contract, so the amendment is defensible), or base
   mode must exclude exactly those two with a written reason. A reviewer will look hard at this — do
   not reach for the L31 anti-pattern of excluding the tests that cover the code you modify.
2. ⚠️ **Do not let the width mask carry the pick** (guard item 4.1 above).
3. **Nameable by the Open-CMSIS-Pack Debug Description spec.** MEDIUM under softened rule 6 — a
   mitigation, not a reject, because no long-open uncommented issue asks for it. Mitigate by phrasing
   on pyOCD's nouns, building the F-10 cell table, and re-running the PR-DIFF check at submit.
4. **`main` lags `develop` by ~2 months.** Base on `main` (CI green, `d1974ff` 2026-07-21) and
   re-confirm at scope-lock that `develop` has landed nothing in the expression kernel —
   `sequences.py`'s last kernel-relevant change is still the 2019 original.
5. **Test doubles.** `test/unit` uses `MockCore`/`MockProbe`, but these are transaction-level
   simulators of the repo's own extension points and the assertions are on real `Scope` values and
   real transaction logs. Not "mock-heavy" in the disqualifying sense — but say so in `DESIGN.md`.
6. **The delegate-function surface is the maintainer's live workstream** (trace, flash setup). Stay
   in the expression kernel.

---

# RANK 2 (fallback) — `netenglabs/suzieq` — ★904 — Python

- Apache-2.0 (verified, single `LICENSE`, no vendored subdirs), Python 99.5%, **default branch
  `develop`** (the screening agent reported `master`; the API says `develop` — corrected here),
  82 commits/12mo, last substantive code 2026-07-14, no AI marks at root, no signature accounts.
- **CI green**: `integration-tests` + `pre-commit` + `CodeQL` `success` on `develop` (2026-09-18) and
  on `master` (2026-08-29). The workflow runs the WHOLE suite under `pytest-split --splits 4` with
  no external services — the lane's tests are in the job that runs.
- **LANE:** *`path` has no path IDENTITY and no snapshot alignment* — the engine walks FIB/ARP/MAC/
  EVPN as of now, keys hops by a POSITIONAL `pathid` (`suzieq/engines/pandas/path.py:1238`,
  `"pathid": i + 1`), and cannot say which path in a later snapshot is the SAME path.
- **Missing machinery:** a canonical path key (hop-sequence normalisation with L2-hop collapsing) +
  a set-alignment algorithm (exact key, then longest-common-hop-prefix so a mutated path reads
  *altered* rather than add+remove) + per-hop attribute delta classification.
- **Confirmed in the clone at `75198b5`:** `suzieq/sqobjects/path.py:10-13` `_valid_get_args` has no
  `start_time`/`end_time`, and `:16-19` *raises* on `view='all'` — the object is hard-wired to one
  instant, while `engines/pandas/engineobj.py:491` `_get_table_sqobj` already takes
  `start_time`/`end_time` and `path.py:41-110` calls it six times without them. The plumbing exists;
  the capability structurally cannot reach it.
- **Trap seams:** shared kernel = positional `pathid`, consumed by `path show`, `summarize`
  (`:1319-1323`), `config/schema/path.avsc` and the golden-output integration suite — so a re-key
  that stabilises the diff silently reorders plain `path show`, and the failure lands in an unrelated
  existing sqcmd golden test (misdirection). Second kernel = the `prev_hop` shallow-copy back-patch
  (`:1212-1290`) that writes hop *j*'s `oif`/`nexthopIp`/`vtepLookup`/`isL2`/`outMtu` onto the
  previous row after the fact, so a key computed in-loop leaves every path's last hop stale.
  Third = `@lru_cache(maxsize=256)` on `_get_nh_with_peer` (`:607`), which will serve snapshot 1's
  nexthops to snapshot 2 in the same process.
- **Eff-LOC sketch:** ≈315 across >=6 files.
- **Exclusivity:** all 21 open PRs enumerated — poller / vendor-parsing / inventory only; **zero**
  touch `engines/pandas/path.py` or `sqobjects/path.py`. No epic/roadmap issue.
- **Why RANK 2, not RANK 1:** (a) semi-dormant, bursty maintenance — ~8 PRs merged in 12 months in
  two bursts after a 14-month gap, with 2022-2024 PRs still open, which will read thin at the
  platform's active-maintenance precheck; (b) `ddutt` was doing correctness work IN the path lane in
  July 2026 (`engine/path: Fix case of Cumulus with macvlan`, `engines/path: Fix source interface sel
  with junos`, `schema/path: add key fields to path` — that last one only marks `pathid`/`hopCount`
  as display keys, +2/-0, so it is not a lane kill but it is a warm signal); (c) a golden-file
  integration suite that any pathid/ordering change ripples through; (d) `-n auto` xdist plus a REST
  test that binds a real port, so base mode needs documented scoping; (e) a second-timestamp parquet
  fixture has to be authored from scratch; (f) derivative flag — batfish ships
  `differentialReachability` (different input and different machinery, but a reviewer may reach for
  it). Clone kept at `worktrees/_hunt/m_0920c/suzieq`.

# RANK 3 (fallback) — `spcl/dace` — ★595 — Python — **Dockerisable, core exclusivity-dead**

Recorded because it is the purest example of the correction and the next hunt should not re-derive
it: `pytest.ini:2-17` declares 13 tool markers (`gpu, mkl, papi, mlir, sve, lapack, mpi, scalapack,
hptt, torch, onnx, long, sequential`) and `general-ci.yml:66` runs `pytest -n auto -m "not gpu and
not autodiff and not torch and not onnx and not tensorflow and not mkl and not sve and not papi and
not mlir and not lapack and not mpi and not scalapack and not datainstrument and not long and not
sequential"`, GREEN on `main`. **The harness label on it was wrong.** It still dies: of ~100 open
PRs, **92 touch `dace/sdfg/`, 78 `dace/codegen/targets/`, 77 `dace/transformation/passes/`** — every
core lane is published prior art. Plus 126 open PRs, a `copilot-setup-steps.yml` workflow, `-n auto`
+ `--timeout=300`, and most "pure" tests still shell out to gcc per test.

---

## Closest misses (beyond the three ranked)

**Network / protocol**

| Repo | Reason |
|---|---|
| `faucetsdn/faucet` ★627 Apache-2.0 | Best capability model in the niche; **exclusivity-dead**. Maintainer `gizmoguy` has 6 open PRs across the reconfiguration/ACL/FIB core — #4850 alone is `faucet/dp.py`, `valve.py`, `valve_acl.py`, `valve_manager_base.py`, `valve_route.py` (+276/-10), `valve_switch_standalone.py`; plus #4819, #4815, #4833, #4823. Unit CI green and pure-Python otherwise. |
| `netsampler/goflow2` ★810 BSD-3 | Maintainer's own open PRs cover every lane: #515 adds `pkg/reflow/aggregate` (+1067) and new netflow/sflow encoders; #481 rewrites the IPFIX decoder; #289 rewrites `templates.go` + `producer_nf.go`. |
| `0xERR0R/blocky` ★6964 | `ChrisJr404` (signature) authored **merged in-lane** PR #2239 `feat(resolver): add refused block type`, inside a 2026-09-05 burst of ~8 drive-by resolver PRs from fresh accounts. |
| `google/capirca` ★857 | Zero community PRs merged in 12 months, 22 open back to 2020; and `aerleon/aerleon` is a live maintained fork shipping the same capabilities. |
| `NLnetLabs/routinator` ★573 | Open PRs #1109/#1106/#1112/#1077 cover the validation + output lanes; rsync/openssl in the path. |
| `folbricht/routedns`, `semihalev/sdns`, `razvandimescu/numa`, `wind-c/comqtt`, `moq-dev/moq`, `tenzir/tenzir`, `batfish/batfish`, `robustmq`, `paddler`, `erpc`, `routr`, `werift-webrtc`, `octodns`, `turn-rs`, `containerlab`, `nornir` | AI marks at root and/or a solo correctness firehose (sdns 250 c/12mo, numa 688, moq 2144, tenzir 3564) |
| `pion/*`, `webrtc-rs`, `aiortc`, `wtransport`, `s2n-quic`, `gosip`, `rustsbi` | RFC-nameable by construction — the derivative-magnet rule |
| `mochi-mqtt/server`, `BGPalerter`, `cidranger`, `patricia`, `mininet`, `openconfig/gnmi`, `meshnet-cni`, `libtins`, `hyperglass`, `plgd-dev/go-coap`, `pyang` | corpse, or dormant with a filling queue |

**Marker-split class**

| Repo | Reason |
|---|---|
| `pymeasure/pymeasure` ★782 MIT | Real split (`ProtocolAdapter` expected-exchange tests run pure), CI green — but 14 of 99 open PRs sit on the core (`common_base.py`, `adapters/*`, `instrument.py`, `registry.py`), one of them (#1358) ships `test_coverage_gap_analysis.md` + `test_implementation_plan.md` (AI-authored), plus `AGENTS.md` at root and 676 commits/12mo. |
| `probe-rs/probe-rs` ★2944 | Workspace split is genuine and `Run CI` is green on `master`, but **`Run smoke test` is a `failure` on the default branch**; 91 open PRs; 547 commits/12mo; and it duplicates pyOCD's domain. |
| `amaranth-lang/amaranth` ★2090 | yosys ships as a pip wheel so nothing external is needed — but **CI `failure` on default branch `main`, 8 of the last 8 runs.** Requirement 7 hard reject. |
| `YosysHQ/nextpnr` ★1753 ISC | `-DARCH=generic` split is real, CI green — but `arch_ci.yml:26-40` builds **yosys from source** plus `libboost-all-dev libeigen3-dev tcl-dev swig qt6-base-dev iverilog` for every arch. Gate 5. |
| `yaqwsx/KiKit` ★2027 MIT | Best profile of that sweep on paper; **no split at all** — the single job installs KiCad, inkscape, openscad, libmagickwand-dev, bats, then `make test`. Here the harness verdict is CORRECT. |
| `scikit-rf/scikit-rf` ★939 BSD-3 | Not really harness-bound; `testpaths` pulls in `doc/source/examples` + tutorials notebooks under `filterwarnings = ["error"]` (base-mode flakiness), and the calibration lanes are textbook-nameable. Parked as a future fallback. |
| `pyvisa/pyvisa` ★959 | Skip-decorator style, not a split; the pure-testable surface is a resource-name grammar over a C-library binding — too thin. |
| `f4pga/prjxray`, `PyHDI/Pyverilog`, `tracespace`, `meshio`, `scipipe`, `exo-lang/exo` | corpse or near-corpse |
| `alive2`, `AdaptiveCpp`, `kani`, `verible`, `SPIRV-Tools`, `mfem`, `OpenROAD`, `atopile` | LLVM/CBMC/hermetic-Bazel in the test path, or a firehose + AI marks (OpenROAD 10,943 commits/12mo) |
| GPL/LGPL/AGPL/EPL: `BornAgain`, `muGrid`, `pymobiledevice3`, `KiBot`, `openems`, `iverilog`, `moose`, `precice`, `dolfinx`, `pylops`, `dpdata`, `radis`, `python-mip` | licence |

**Text layout / font** — full kill list in sweep B's dossier; the load-bearing ones are in the
"burned sub-lane" section above, plus `litehtml` (cairo/pango/gtk in the test build path AND the
test suite lives in a second repo fetched by `FetchContent` at configure time), `glamour`,
`python-tabulate`, `presenterm`, `pagedjs`, `plotters`, `swash` (all dormant with filling queues),
`knowm/XChart` (AI-maintenance mark plus an in-lane backlog sweep), and the MPL-2.0 / LGPL / AGPL
/ NOASSERTION block (`satori`, `resvg`, `helix`, `mdBook`, `d2`, `plantuml`, `verovio`, `fpdf2`,
`ebooklib`, `unipdf`, `elk`, `tldraw`, `marked`, `konva`, `sphinx`, `OpenPDF`).

## Decisions taken unattended

1. **Re-opened a `SATURATED-REPOS.md` kill class on evidence.** The nine-repo "tool-harness" row and
   the eight-repo "needs hardware, or corpse" row were both re-screened rather than trusted. Nothing
   was rewritten in `SATURATED-REPOS.md` (the hunter does not own that file), but the corrected
   per-repo reasons are recorded above and the row should be normalised by whoever next edits it.
2. **Ranked `pyocd/pyOCD` above `netenglabs/suzieq`** on activity health (203 vs 82 commits/12mo,
   120 vs ~8 merged PRs), harness cost (a seconds-long pure unit suite vs a 1.5-2 GB image with a
   golden-file integration suite and xdist), and LOC headroom (380 vs 315). Both clones kept.
3. **Did not launch a third fresh niche** — the budget allows two, and the marker-split re-screen was
   the hint's own item, not a niche.
4. **Requirement 0 (platform picker) marked OWED**, per the agent contract; it cannot be checked
   without the platform UI.

## Disk discipline

No builds were run anywhere — no `cargo`, no `make`, no `cmake`, no `docker build`, no `pip install`.
`/` stayed at 13-14 G free throughout (87% used) against the 8 G floor. Clones kept:
`worktrees/_hunt/m_0920c/pyocd` (363 M, RANK 1) and `worktrees/_hunt/m_0920c/suzieq` (167 M,
RANK 2). Sweep B's clones (`tablewriter`, `litehtml`) and sweep C's rejects were deleted by the
agents. `worktrees/siliconcompiler` and `worktrees/_hunt/l_sci0920b/sc` were not touched.

## Scratch left for the next hunt

- `worktrees/_hunt/l_sci0920b/deadlist_v15.txt` — 6,087 slugs, now including bare prose slugs
- `worktrees/_hunt/l_sci0920b/deadnames_v1.txt` — 152 bare repo NAMES from `·`-separated kill rows
- `worktrees/_hunt/l_sci0920b/residual_0920c.tsv` / `residual_filtered.txt` — the 617/537 cache residual, all read
- `worktrees/_hunt/l_sci0920b/{th,hwrow}.jsonl` — the two blanket rows, fully profiled
- `worktrees/_hunt/l_sci0920b/topicsweepC.jsonl` + `topics_rem.txt` — the last 36 topics of `topics2.txt` (vocabulary now 100/100 spent)
- `worktrees/_hunt/m_0920c/` — this session's brief, profiles and the two kept clones
