# REPO-HUNT-2026-09-24-D (hunt #33, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0924h33/` (fresh cloud container).

## Standing inputs
- Hint from hunt #32 (09-24-C): every GitHub discovery axis is exhausted. Spike a COMPOSITE (asdf lane 1
  + #1795 conversion-free info/search over the same lazy tree and block manager, guarded on a shared
  kernel) or ask the human for new anchor repos. Spike only when a whole mechanism is unsized on paper.
- Excluded: every LEDGER table row (21 rows: grmtools HUNTED; MACS, riff, ray-optics, hayro HANDOFF;
  the CLAIMED and DEAD rows), every `problems/` folder, SATURATED-REPOS A-E.
- Requirement 0 (platform picker): cannot be checked here -> OWED.
- Softening: misses=1 (< 2), so the 2026-09-09-B rules apply as written and no star or issue window
  was widened. Relaxations taken: none.
- "Ask the human for anchor repos": unattended default taken = no question asked; the hunt used its own
  knowledge list as the anchor source instead (sweep 1) and recorded it here.

## Environment notes (fresh container)
- `worktrees/` did not exist, so the cached star-band index and screeners (`worktrees/_hunt/`, the
  74.6k seen union) are NOT available here. Replacement dead list: every owner/repo token in
  `Instructions/`, `pipeline/`, `approved-problems/`, `problems/`, `rejected/` (5,734 tokens,
  `s_0924h33/deadlist_h33.txt`). It is a subset of the old seen union (judged or mentioned repos only).
- `gh` was not installed (installed the 2.62.0 release binary). The session proxy only allows
  repository-scoped GitHub REST for configured repos, so `gh api repos/...`, `gh search` and Actions
  reads return 403 for public repos. Working channels: `git clone` over HTTPS (all public repos) and the
  GitHub MCP search tools (`search_repositories`, `search_issues`, `search_pull_requests`). Issue and PR
  bodies and PR diffs for non-configured repos are NOT readable (`issue_read`, `pull_request_read`
  denied). Next hunter: budget for this, and read diffs by cloning plus `git fetch origin pull/N/head`.

## Stage 0-bis — proven pool
No approvals since hunt #32 outside the LEDGER (teavm and pyocd accepted today, both LEDGER rows).
Every other pool repo carries a lane verdict in 09-19-H .. 09-24-C. Not re-derived.

## Cached index
Not present in this container (see above). Triage replaced by the dead-list filter.

## Fresh sweep 1 — knowledge-sourced niche engines (new axis: the hunter's own recall, not GitHub search)
Four batches of hand-recalled engine repos across Rust/Go/Python/TS/C++/Java (compilers, analyzers,
solvers, geometry, DSP, CRDTs, model checkers, codegen, formats), 437 slugs in total, filtered against the
dead list, then mechanically screened with `search_repositories` (batched `repo:` queries).
- Batch 1 (132 slugs): 72 already judged in earlier logs, 55 unmentioned.
- Batches 2-3 (211 + 94): most unmentioned slugs are famous or out of band (sympy, mypy, jax, dask ...)
  or under 500 stars (pyfar 137, tskit 191, cedar-go 234, spade 339, pyccel 398, ...). This explains
  why earlier logs never named them.
- Unmentioned, in band, looked at in any depth:
  - google/mangle (Go ★2991, Apache): development moved to Codeberg in 2026-02 ("Update module path to
    codeberg.org/TauCeti/mangle-go"); GitHub is a mirror, Req 6 risk. Not pursued.
  - devitocodes/devito (Python ★714, MIT): 873 commits in 12 months, 262 `compiler:` commits by a 3-person
    core team; `ir/`, `passes/`, `types/` all >100 commits. Capability-consuming in every compiler lane,
    and the cold dirs (checkpointing 122 lines, builtins catalogue) are too small. DEAD.
  - serge-sans-paille/pythran (C++/Python ★2143, BSD-3, vendored boost BSL + xsimd/pocketfft BSD):
    **gate-clean and never judged before**. Solo maintainer, no outside PRs in the queue, the middle-end
    (analyses/optimizations/transformations, 11.4k lines) is cold next to the pythonic C++ runtime, and
    `test_optimizations.py` runs 85 tests in 22 s. Lanes: (a) an LICM-style optimization (no LICM/CSE
    exists; probed: `np.sum(a)` stays inside the loop in `-E` output) is performance-only, has no
    wrong-results F2P, and has plan-shape assertions only (TOO-EASY hot/cold inversion row) -> WEAK;
    (b) Python language-surface support = famous-language carve-out -> DEAD; (c) numpy functions =
    catalogue -> DEAD. Recorded as a clean repo for a future lane that is not perf-only.
  - tokio-rs/loom (2 commits/12mo, dormant, Req 6 risk), rust-lang/polonius (1 commit), uber-go/gopatch
    (0 commits): corpses. awslabs/shuttle (Apache ★1066): team adding tokio shims weekly (consuming).
    immutables/immutables (Java ★3575): outside fixers look like genuine users, but it is a sprawling
    annotation-processor framework and the criteria/mongo lane is BertschiAG's workstream. go-critic
    (checker catalogue), lpython/esbmc (LLVM/clang builds, L62), freemarker (template-language carve-out),
    pyuvm (UVM port), valhalla (★6248, heavy deps), piccolo (Lua VM carve-out): DEAD on sight.
- README-phrase probe (`"worklist" in:readme`): the 3 engine hits (SeaOfNodes/Simple, DCMTK,
  rustc_codegen_jvm) were all already judged. More evidence that the public band is exhausted.
Sweep 1 survivors: none that are authorable now (pythran is noted as clean with no lane).

## Fresh sweep 2 — not run as a GitHub sweep
The README probe above confirmed the prior finding. The budget went into the composite spike the hint asked for.

## Workshop — asdf-format/asdf composite spike (the #32 hint)
Scope: **lazy-tree conversion-free operations**. When a file is opened with `lazy_tree=True`, nodes the
user never touched stay in their stored tagged form: `write_to`/`update` re-emit them verbatim (same tag
version, converter never called, block references re-linked), and `info()`/`search()`/`schema_info()`
walk the tree without converting anything (search `.nodes`/`.node` convert only the matches).
Base commit `376790c2742c18511a859eb7b1d7d4e55c47b4ff` (main, 2026-09-11).

**F2P on base (probe `artifacts/asdf-lazy-composite-probe-h33.py`, counting converter with tags
point-1.0.0/1.1.0):** P1 lazy open + unrelated edit + `write_to` calls the converter 2/2 times and
re-tags point-1.0.0 as 1.1.0. P2 `info()` converts 2 nodes. P3 `search(type_=Point).paths` converts 2 nodes.
**Prototype:** P1 0 calls and 1.0.0 kept, with the nested array inside the raw Point re-linked correctly
on reread. P2 0 calls, and the write after info still keeps 1.0.0. P3 0 calls for paths and type queries,
with `.node` converting only the single match. P4 `update()` in place: 0 calls, all arrays correct on
reread, tag kept. P5 a version change forces full conversion (policy). The full suite passes 2188 / 1 skip
/ 2 xfail on base and with the patch. Probe output is byte-identical over 3 runs.

**Measured: 239 human-eff** (raw 291, padding-floor 191, 6 files). `_raw_tree.py` new 172 (shared kernel +
write view), `search.py` 35, `_node_info.py` 12, `_asdf.py` 6, `_display.py` 3, `yamlutil.py` 2. Core
(kernel + write view + raw-aware filters) ~170. Paper for lane 1 alone was ~195, the #31 spike measured
176, and the composite adds a second mechanism (~65 eff here) that nobody had sized. Genuine remaining
surface, not written yet: per-node converter-private-block policy (#1508, the global fallback is in),
lazy converters (`converter.lazy=True` data), `search().replace()` on raw parents, and copy/deepcopy of a
lazy tree followed by a write. Estimate +25-45 -> ~265-285 complete.
Patch: `Instructions/repo-hunt-logs/artifacts/asdf-lazy-composite-spike-h33.patch` (applies on 376790c2;
the clone `worktrees/h33_asdf` was restored clean and venvs deleted).

**Traps measured or observed while building:**
- T1 (measured, misdirecting): `_serial_write`'s `copy.copy(self._tree)` goes through
  `UserDict.copy()` -> `update(self)` -> `AsdfDictNode.__getitem__` and converts every top-level child
  before any write hook runs. The failing assertion is a written tag version, and the cause is a copy.
- T2 (measured, misdirecting, the composite's coupling): an info/search that converts (the natural path via
  `treeutil.get_children` or `node[key]`) silently breaks the WRITE surface. On base, `info()` then
  `write_to` re-tags. The test that fails is a write test, but the cause is in info/search.
- T3 (measured): an array nested inside an untouched custom node keeps a stale `source`. With re-linking
  disabled, the reread of the written file raises inside block loading, far from the cause. Re-linking
  also needs write-back (cache + parent) so that `update()` does not leave stale indices in memory.
- T4 (design cell, F-10): info must EXPAND an unconverted node (its stored fields; shape/dtype for arrays),
  while search must NOT descend into it, because the paths it returns must be valid on the converted tree.
  The same traversal kernel serves both with opposite rules.
- T5: `type_=` on an unconverted node is answered from the converter's declared types. The ndarray
  converter declares several types, so the ambiguous case must convert that node only. `value=` regex on
  unconverted containers is False without conversion, while equality needs conversion.
- T6: aliases. A raw node that another path already converted must be written as the converted object
  (tagged-object cache lookup), or the YAML anchor identity breaks.

## Stage 6 — death-class guard on RANK 1 (asdf composite)
1. ONE shared kernel feeding several surfaces, where a local fix regresses another: **YES.**
   `raw_children` + the tagged-object-cache lookup + `is_pending`/`materialize` decide "still
   unconverted" for write_to, update, info, search paths/nodes and schema_info. A conversion added in any
   read-side surface regresses the write surface (T2, measured on base).
2. Interdependent and misdirecting traps: **YES.** T1 and T2 both surface as a write-side tag or
   converter-count failure with the cause elsewhere. T3 surfaces at reread. T4 couples info and search
   through one kernel with opposite rules.
3. Standalone new file with minimal wiring: **PARTIAL, accepted with risk.** The kernel is naturally a new
   module (172 of 239 eff). It is not a post-pass over a public stream: it reads lazy-node internals and
   the tagged-object cache, hooks five internal chokepoints (serial-write copy, tagged-tree conversion
   entry, node-info traversal, display labels, search walker/filters/nodes), and drives the block manager
   through forced array conversion with write-back. The #31 spike rated lane 1 alone "mostly yes". The
   composite adds the read-side surfaces that make T2 exist.
4. TOO-EASY Pre-Pick Guard: #1 not a uniform wrap (write view, traversal and filters differ). #2 spans
   serialization + block manager + lazy nodes + display/search. #3 the contract is stated ("untouched nodes
   keep their stored form; info/search convert nothing; .nodes converts only matches") while the fix
   sites stay hidden (T1, T3 write-back). #4 no external spec or port: this is asdf's own lazy_tree model;
   earlier majors never had it. #5 T1/T2/T4 survive full statement. Value, not cost: the tag version in
   the output and converter-call counts are observable, so it is not a performance-only claim.
Guard verdict: **PASS with two carried risks** (Q3 partial; LOC at 239 measured, below the 250 design
target until the remaining surface is built).

## Dossier — RANK 1
### asdf-format/asdf — ★567 — RANK 1
- **URL:** https://github.com/asdf-format/asdf (canonical, default branch `main`)
- **Language:** Python 100%, pure (runtime deps asdf-standard, numpy, pyyaml, jmespath, packaging,
  semantic_version, typing-extensions, attrs; all wheels, no C build). Vendored `_jsonschema` MIT
  (Julian Berman) and `_extern/atomicfile.py` (atomicwrites, MIT), both in the allowlist.
- **Domain:** scientific file format library (YAML tree + binary blocks, converter/extension plugins,
  lazy tree).
- **License:** BSD-3 (AURA), LICENSE read.
- **Activity:** 277 non-merge, non-bot code commits since 2025-09-24; latest 2026-09-11. Maintainers sydduckworth
  (lazy copy fix #2133 on 09-04, validate_on_read, compressor protocol #2114), braingram, zacharyburnett.
- **CI (Req 7):** `ci.yml` runs nox test sessions. The 09-23-O log recorded main green (one downstream
  failure). NOT re-verified here because the Actions API is blocked by the session proxy -> OWED.
  The local suite is 2188 passed, identical over 5 runs, ~14 s with xdist.
- **Open issues:** 104 incl. PRs. Open PR queue: 6, all maintainer or bot (docs/mkdocs, CI).
- **Docker:** Pattern B `olympus-base-python`. `pip install -e .[tests]` is offline-able after a wheel
  cache, and there is no C build.
- **Capability-lane density:** the lazy lane is WARM (maintainer fixed copy/deepcopy with lazy_tree on
  09-04; #1979/#1922 earlier) but nobody is building pass-through write or conversion-free info/search. No
  PR in any state implements either (searched "lazy" across all PRs, 29 hits; keyword searches for
  pass-through/untouched/convert returned only #1795/#1978).
- **Maintainer-welcomed:** #1795 (maintainer-authored 2024-07-12, OPEN, 0 comments): "Consider a new
  design for the info and search methods that avoids conversion of nodes when the lazy_tree option is
  used ... When resources permit, this option should be investigated." Not a spec-named feature, so it is
  not the famous-magnet row. But it is a long-open zero-comment issue asking for exactly the read half,
  which is MEDIUM derivative risk. Lead the task with the write half and the coupling, and phrase it on
  asdf's own model.
- **PR-author profiling:** `binggao1230` (recorded signature account) filed TWO closed-unmerged PRs here
  in 2026-06: #2058 "Only treat ancestor references as recursive in info() (fixes #1891)" and #2069 "Warn
  when writing replaces a user-set asdf_library". Both touch files this pick modifies
  (`_node_info.from_root_node`, `_serial_write`) but different capabilities (recursion marking, a
  warning). By the 09-09-B rule this is one account and not a burst. It is ADJACENT to both halves, so it
  is a heavy note, not a reject. jdavies-st #2136 (memmap close) is a genuine STScI contributor.
- **Self-collision:** approved `enmime-preserving-edits` (Go, untouched-parts byte-identical rewrite) is
  the nearest class, in a different repo and language. No asdf problem exists in approved/problems/rejected.
  SATURATED-REPOS B3-tredecies lists asdf lane 1 as WEAK (a lane note, not repo-dead).
- **Missing machinery (LOC carry):** asdf has no notion of an unconverted child outside `__getitem__`.
  Every traversal (`get_children`, `walk_and_modify`, UserDict copy, converter `dict(obj)`) goes through
  conversion, and there is no way to re-link a stored block index without converting. The kernel and the
  write view are new machinery.
- **Trap seams:** F-20 (sibling-API contamination: info/search -> write), F-47 (state the lazy tree
  holds and write discards: tag versions, raw form), F-10 (expand-for-info vs do-not-descend-for-search;
  lazy vs non-lazy; write_to vs update), F-9-ish (block index resolved at read, re-resolved at write),
  F-34-adjacent (write-back into the caller's lazy tree on update).
- **Estimated complexity:** 239 human-eff measured, ~265-285 complete, 6 files, 4 subsystems.
- **Risks (carried to the builder):** (1) Requirement 0 picker OWED. (2) Q3 partial: keep the read-side
  surfaces in scope, or the pick collapses to the WEAK lane 1. (3) Derivative MEDIUM: #1795 and the
  binggao1230 adjacency. Run the core-slice precheck at the FIRST commit, before building tests.
  (4) The maintainer is active in lazy_tree: re-run the SIX-CHECK (commit stream) at submit. (5) Fairness
  load: the policy sentences (arrays are always re-linked through conversion; a standard-version change
  or unclaimed blocks force full conversion; the info labels for unconverted nodes) must be stated in
  meta.md. (6) Req 7 CI conclusion OWED (API blocked here).

## Result: CANDIDATE — asdf-format/asdf (composite lazy-tree conversion-free operations)
Fallbacks: NASA-AMMOS/3DTilesRendererJS (3D Tiles 1.1 multiple contents, WEAK, carried from 09-23-O);
serge-sans-paille/pythran (gate-clean, never judged before; needs a non-perf lane, NOT spiked).
Dead this hunt: devito (consuming), mangle (Codeberg mirror), loom/polonius/gopatch (corpses), shuttle
(consuming), pythran LICM lane (perf-only), the knowledge sweep's out-of-band tail.
Lesson: the composite the #32 hint asked for works when the two halves share a kernel whose failure in
one surface shows up in the other (T2). That coupling was invisible to both single-lane dossiers. Paper
said 195 (lane 1). Spiked, lane 1 alone was 176, and the composite is 239 measured, with the second
mechanism adding ~65.
Disk: / 30G free. No build output. Clones kept under `worktrees/h33_*` (asdf restored clean at
376790c2, pythran, immutables, shuttle, pyccel, mangle). Venvs deleted.
