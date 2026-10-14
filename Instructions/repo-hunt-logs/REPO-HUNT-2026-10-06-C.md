# REPO-HUNT-2026-10-06-C (hunter #61, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1006h61/`. It holds the screener `mech_h61.sh` and its outputs `mech1-3_h61.out`, the eight lane dossiers `dossier_<repo>_h61.md`, the PR and issue scans, the topic sweep `topicsweep_h61.tsv`, the agent brief `AGENT_BRIEF_h61.md`, and the only written sketch, `sketch_aerion_calqueue_h61.patch` (161 human-eff, dead). All clones were deleted. Nothing was built.

## Standing inputs and defaults taken
- The 2026-10-05 user rules were applied as written:
  - lane-only exclusion;
  - a verdict-only dead list, with lane rows expiring after 60 days;
  - Requirement 7 kills only on a failing test workflow in the lane, or when there is no test workflow at all;
  - a ~505 star margin;
  - a 220 written return bar;
  - the Q3 waiver only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule, and the AI-sweep, velocity and signature rules.
- **Softening:** misses = 0, so nothing was relaxed and no window was widened.
- **Requirement 0:** OWED (not reached).
- **Excluded lanes:**
  - qq typed binary schema (HUNTED);
  - pint value ranges (SLICING);
  - pianoplayer, protobuf-es printer, gonum/plot, commafeed, aptly, ray-optics module inlining (HANDOFF);
  - every CLAIMED row;
  - the dead lanes on the do-not-return list;
  - the reserved fallbacks: pcodec, rain, dstask.
- **Submission counts:**
  - Our count is 0 on every repo audited.
  - The platform count is unknown for all of them; it was never reached.
- **Disk:** `/` stayed at 6.5-6.6G free. Root never reached the 8G build gate, so there were no builds, venvs or package installs.

## Stage 0-bis: proven pool
I re-read the judged rows for all 92 pool repos.
- Every pool repo carries either a recent second-lane verdict (hunts #53-#60) or a SATURATED-REPOS kill.
- Those kills cover:
  - signature swarms: ezdxf, petl, python-control, pyparsing, mpmath, scikit-bio, yara-x;
  - Req 7: awkward, causal-learn;
  - corpses: ezno, toydb;
  - capability-consuming maintainers: beartype, surrealkv, iwe;
  - other: tantivy is in the penalty band beside a collision; turmoil is held by closed PR #22.
- No lane verdict on a pool repo has expired; the 60-day window first opens around 2026-11-01. The proven pool produced nothing, as #59 and #60 predicted.

## Stage 0: cached index (no fetch)
I cut the cached bands (`band*.jsonl`, 34k rows) down to repos never named in any markdown verdict source (hunt logs, Instructions, s_* dossiers, judged.tsv, LEDGER):
1. That left 28.9k alive rows in scope.
2. A domain-vocabulary filter (stars 505-9000, AI/app/web noise removed) left 3,716 rows. I read the Go, Rust and C++/Java lists in full, and the Python and TS/JS lists through an engine-word filter.
3. Joining with the cached commit histories (`hist*.jsonl`) gave 745 solo-active rows: 25-600 commits in 12 months, top author >= 60% of the recent sample. I read all of them.

Mechanical screening covered 57 repos with `mech_h61.sh`, which checks licence, languages, commits, AI trailers, workflows, default-branch runs, signature authors in the last 80 PRs, and open PRs.

## Fresh sweep 1 (of 2): 100 engineering topics
- I ran `gh search repos --topic` on 100 topics not in `used_topics.txt`, for example bvh, gerber, kicad, ephemeris, geodesy, voronoi, csg, sdf, cfd, timetabling, bin-packing, music-theory, subtitles, hyphenation, three-way-merge, rsync, erasure-coding, modbus, plc, a2l, mach-o, spirv, decompiler, symbolic-execution, model-checking, sat-solver, term-rewriting, incremental-computation, crdt, event-sourcing, inverted-index and query-optimizer.
- Stars 505-6000, a permissive licence and a push since 2026-06-01 gave 259 rows. About 150 were never mentioned anywhere; most are apps or AI tools.
- The domain rows I screened were osmnx, tinybase, opral/lix, elfshaker, python-snap7, itchio/butler, python-udsoncan and emhass.

**Fresh sweep 2 was not spent.** The first sweep re-surfaced band rows already in the cache, and every audited lane died on maintainer scope, a burst, a roadmap or the floor. None died for lack of candidates, so another fetch would not change the outcome.

## Mechanical kills (repo-scope rows written to judged.tsv)
| Repo | Kill |
|---|---|
| robpike/ivy (★1486) | Req 7: no `.github/workflows` |
| manifold-systems/manifold (★2761) | Req 7: only a pages workflow |
| anufrievroman/calcure (★2372) | Req 7: no workflows |
| rhysd/actionlint (★4296) | two signature accounts (dylanpulver, Eljees x2) |
| chimpler/pyhocon (★535) | two signature accounts (binggao1230 x2, santhreal) |
| itchio/butler (★991) | Req 5: crawshaw.io/sqlite is CGO |
| jbikker/tinybvh (★1207) | licence: zlib-licensed GLFW and zlib are vendored, plus binary .lib blobs |
| tinyplex/tinybase (★5184) | burst: `dajiaohuang` opened 5 PRs in 4 days (#297-#305) across checkpoints, metrics, relationships and indexes. Added to `sig_accounts.txt` |
| pymanopt, openscope, exprtk, cron-utils | activity: 0 default-branch commits in 12 months |

**Notes (no kill):**
- ledger/ledger: 33 AI trailers per 100 commits, and a Lean-oracle correctness sweep by jwiegley.
- muparser: a `claude/*` bug sweep.
- libremidi: 23 AI trailers.
- marmot: 58 AI trailers.
- heitzmann/gdstk: ★502, under the ~505 margin; a WATCH repo for when it crosses.
- goccmack/gocc, F3, thalo, SolidPython and others: 1-4 commits in 12 months.

## Lane audits (4 parallel agents, 8 repos, brief `AGENT_BRIEF_h61.md`)
All eight are DEAD. No lane reached 220; the only lane written came to 161.

| Repo | Lanes tried | Best lane and its killer |
|---|---|---|
| sminez/ad (Rust ★744) | 8 | Undo tree ~170, with a crib in helix `history.rs`. Sam `m`/`t` is ~90 and absorbed, since gather-then-apply already exists. Maintainer roadmaps: #15 and #92. Base bugs found at exec/mod.rs:245 (stale offsets) and buffer/edit.rs:174 (redo) are each smaller than 200 |
| jbikker/tinybvh (C++ ★1207) | 6 | Repo licence kill (vendored zlib/GLFW). The lanes were textbook anyway: embree point query, Box2D dynamic tree. Roadmap: #57 |
| alphaville/optimization-engine (Rust ★649) | 6 | PANOC prox term ~180-250 on paper, with a crib in alpaqa. Constraint arms are absorbed. Maintainer roadmaps: #333, #303, #285, #402, #419 |
| sisong/HDiffPatch (C++ ★2123) | 7 | Patch composition was declined in #302. Cross-format resave is ~60 per direction in a standalone file. Exe preprocessing is roadmap #4. In-place is lane-dense. **Overturns** 10-05-D's "NOASSERTION" licence read: the licence is MIT+MIT. The repo still dies on lane reasons |
| hkdb/aerion (Go ★964) | 5 | Calendar offline-queue reconciliation, **161 written**. It is carry-state (every trap fix is 15 lines or fewer), and pending_writes.go:23 names the gap. Snooze ~115. Undo-send is roadmap (#246, #345). Recipient harvest was declined in #418 |
| checkmake/checkmake (Go ★1217) | 6 | Conditional-directive model ~140. Magnets: #97 (include) and #31 (suppression). #73 declined variable expansion. Open PRs: #190, #254, #289, #259 |
| gboeing/osmnx (Py ★5859) | 11 | The maintainer declines new graph kernels on scope: #22, #874, #1382, #1207, #1161, #1056. The one welcomed offline gap is his own PR #1338 |
| tinyplex/tinybase (TS ★5184) | 9 | Repo burst kill. Cascade delete #271 is a magnet. Queries and indexes are lane-dense |

Also judged by the hunter: **brentyi/tyro**, `to_args` CLI inverse. DEAD by absorption: per-primitive `str_from_instance` (`_primitive_spec.py`) and the `default=obj` path (`_arguments.py:806`) already map an instance to argument strings.

## Verdict rows appended to `worktrees/_hunt/judged.tsv`
24 rows (backup `s_1006h61/judged.bak_h61`):
- 12 repo-scope rows;
- 8 lane rows (tyro, ad, OpEn, HDiffPatch, aerion, checkmake, osmnx);
- 4 note rows.

`sig_accounts.txt` gained `dajiaohuang` (backup `s_1006h61/sig_accounts.bak_h61`).

## Fallbacks
None. aerion calendar queue (161) and checkmake conditionals (~140) are both under 210 written and priced, with no real second lever.

## What the next hunt should change
1. **The never-mentioned remainder of the cached band is now read.** The 3,716-row domain cut and the 745-row solo-active join of rows never named in any verdict have been looked at (h60 read the low-activity and persisted-format cuts). The next cache re-cut should come from a different axis, not a new vocabulary.
2. **The killers here were maintainer behaviour, not mechanics.** Six of eight repos died on scope declines, roadmap issues, an AI burst or a maintainer's own open PR. Run the closed-issue philosophy scan (maintainer closing comments) and the author-of-open-issues check before the lane audit; both are two calls.
3. **Wait for 2026-11-01**, when the proven pool's earliest lane verdicts expire. Until then the best remaining source is probably the band's 6000-15000 penalty slice (`band_hi.jsonl`, 3,480 rows). Hunts have filtered it out with `stars <= 6000` in every topic sweep, so it has only had the 120-row `hi_cand.txt` look. Screen it for repo-internal capabilities only.
4. **Watch heitzmann/gdstk (★502):** BSL-1.0, CI green, solo maintainer. Audit it once it reaches about 505.
