# REPO-HUNT-2026-10-05-F (hunter #54, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE**.

Scratch: `worktrees/_hunt/s_1005h54/` (53M after cleanup):
- `AGENT_BRIEF_h54.md`: the h53 lane-audit brief plus hunt #54 additions (no builds at all, in-flight disjointness, licence-file reading, rejected-folder reading).
- Screens: `screen_secondlane_h54.txt` (9 repos), `screen_rejpool_h54.txt` (24 repos), `screen_approvedskip_h54.txt` (3 repos).
- Dossiers: `dossier_<repo>_h54.md` for eventsourcing, mirrorbits, hayro, TwelveMonkeys, object, rust-minidump, metpy, jte, 3DTilesRendererJS.
- Raw evidence: `*_h54.txt` (issue lists, PR lists, PR authors, commit streams).
- Kept clones: `3DTilesRendererJS` (29M) and `rust-minidump` (24M), both WEAK fallbacks. The hayro, metpy, jte, eventsourcing, mirrorbits and object clones were deleted after their audits. The TwelveMonkeys clone (401M) was deleted by its auditor. Nothing was built.

## Standing inputs
- **Human direction (2026-10-05, standing):** hunt SECOND, different-subsystem lanes on repos we already shipped or claimed, instead of broad discovery. Still enforced:
  - quota (<= 6 total, <= 3 per week);
  - a subsystem disjoint from every earlier problem on the repo;
  - fresh exclusivity / PR-DIFF / signature / activity / post-base checks on the current default branch;
  - TOO-EASY dead classes, including the 2026-10-05 history-rewrite / ledger-squash class.
  Licence, language, activity, Requirement 7, exclusivity and quota were not relaxed.
- **Previous hint (hunter #53):**
  1. approved-problems/ repos #53 did not cover;
  2. h35's WEAK rows (rust-minidump XSTATE, MetPy VCP; not turmoil).
  Repos with an in-flight problems/ folder may be audited for a disjoint lane only, and the dossier must say so.
- **Excluded:**
  - in flight or queued: teavm (HUNTED), aptly (SLICING), commafeed, gonum/plot;
  - reserved fallbacks: pyOCD lane K, ray-optics module inlining;
  - DEAD ledger rows, SATURATED-REPOS sections A/C/D/E.
- **Interpretation recorded (documented default):** the worker contract says to skip every repo with a problems/ folder. The orchestrator's message says such repos may be audited for a disjoint lane and must be flagged. I audited three of them (eventsourcing, mirrorbits, hayro) and would only have returned one as a flagged candidate if no other repo produced a lane. None did.
- **Softening:** misses = 0, so the 2026-09-09-B rules apply as written. No star or issue window was widened. Relaxations taken: none.
- **Requirement 0 (platform picker):** not checkable here. OWED for any future pick.
- **Disk:** `/` had 7.9G free at the start, under the 8G build gate, and 7.0-7.5G during the hunt (a builder was running). No build, venv, npm, cargo, mvn or Docker. Every Gate 1 is argued from code.

## Stage 0-bis: what the proven pool still held
- **The approved pool is fully mined.**
  - Hunt #35 covered 49 repos and hunt #37 covered the 53 older approved repos plus 10 finished-ledger repos.
  - Hunt #53 covered the 2026-09-24..30 approvals: pict, piscsi, bayesopt, teavm, pyocd, riff, grmtools, ray-optics.
  - Every approved repo carries a recorded verdict. The only approved repos never lane-audited were those #35 skipped at repo level:
    - "capability-consuming" (a LANE verdict under the 09-09-B softening): drjit, icu4x, neva, surrealkv, tantivy, openexr;
    - kapture (0/0 tracker).
- **I screened those repo-level skips again:**

  | Repo | Screen (2026-10-05) | Verdict |
  |---|---|---|
  | surrealdb/surrealkv | tobiemh + arriqaaq made 243 of 260 commits in 12 months; 1 open issue; the retention lane is ABSORBED (B2) | dead, not audited |
  | quickwit-oss/tantivy | ★16181 (penalty band); 50 open PRs; fulmicoton is building calculated-field aggregations; signature account `breken-ai` in aggregations; Lucene is the reference toolchain for every lane | dead, not audited |
  | AcademySoftwareFoundation/openexr | language reported as C; 107 AI co-author trailers in the last 100 commits (maintainer AI sweep); deep-encode lane already dead | dead, not audited |
  | mitsuba-renderer/drjit | wjakob made 275 of 300 commits; the only workflow is `wheels.yml`; heavy LLVM build | dead, not audited |
  | naver/kapture | 24 commits in 12 months, all releases, docs and pyproject; 0 issues and 0 PRs (Gate 8 unverifiable) | WEAK, near-corpse, not audited |
  | VirusTotal/yara-x | `king-tero` has 14 PRs (signature account, burst) | dead |
  | beartype/beartype | `binggao1230` + `SAY-5`: 2 signature accounts | dead |
  | icu4x, neva | port of ICU4C/J; neva re-audited in #38 (codex/* merges, typesystem draft) | dead |

- **New pool this hunt: the rejected/ repos.** These are repos we claimed and built once, mostly from a sibling workspace, and none of them has a second-lane audit on record. I screened 24 (`screen_rejpool_h54.txt`).

  | Repos | Result |
  |---|---|
  | abema/go-mp4 (ChrisJr404 + 2x MaxFreedomPollard), pdfminer.six (3 accounts), tamasfe/taplo (2) | dead, Gate 3 |
  | eliben/pyelftools | licence NOASSERTION (public domain), dead |
  | node-opcua | our earlier pick died to an unexplained platform environment failure (3 image records), too risky |
  | etcd-io/bbolt | ★9767 penalty band |
  | str0m (11 AI co-author trailers), salsa (team, 24 open PRs), taffy (50 open PRs), trustfall, rustpbx, iced, umoci, vivisect, rspirv, goblin, image-png, go-astisub, dnsjava (ChrisJr404 x2), sqlalchemy/alembic | NOT audited this hunt (budget). These are the next pool |
  | haraldk/TwelveMonkeys, gimli-rs/object, casid/jte, NASA-AMMOS/3DTilesRendererJS | audited below |

## Lane audits: 9 repos by 5 parallel subagents (brief `AGENT_BRIEF_h54.md`)
| Repo (our earlier pick) | Verdict | Best lane / what killed it |
|---|---|---|
| pyeventsourcing/eventsourcing (in flight: system-consistent-cut) | DEAD | See note 1 |
| videolabs/mirrorbits (in flight: mirror-sync-point) | DEAD | See note 2 |
| LaurenzV/hayro (in flight: optional-content-baking) | WEAK, not authorable | See note 3 |
| haraldk/TwelveMonkeys (rejected sgi-writer, similarity) | WEAK, not authorable | See note 4 |
| gimli-rs/object (rejected aix-big-archive, 0/10) | DEAD | See note 5 |
| rust-minidump (approved stack-containment) | WEAK (unchanged) | See note 6 |
| Unidata/MetPy (approved parcel-trajectories) | DEAD, Gate 3 | See note 7 |
| casid/jte (rejected html-context, Gate 8) | DEAD | See note 8 |
| NASA-AMMOS/3DTilesRendererJS (0 prior picks: `rejected/3d-tiles-atomic-output` was CesiumGS/3d-tiles-tools) | **WEAK, best of hunt** | See dossier below |

**Notes:**
1. **eventsourcing.** Base 9.5 `575d42c1`.
   - Rebase-on-conflict save (~150) is declined in docs (domain.rst:3155, "no value to allowing concurrent write access"), adjoins live DCB conflict detection, and is the Axon ConflictResolver pattern.
   - Relative topics (~90) are a uniform wrap.
   - Copy-and-transform migration (#103) shares the in-flight fork's feature class and is a magnet.
   - Blame history (~100) is single-pass.
   - Key rotation (~60) and shredding are against append-only.
   - The 10.0 rewrite replaces domain/application. Revisit only once 10.0 is the default branch.
2. **mirrorbits.** Master `dc9ecc1b`.
   - The in-flight problem holds scan/, monitor, mirrors and rpc. What remains reduces to one chokepoint:
     - group-consistent redirect ~110-150 (rendezvous hashing, #233);
     - traffic cap ~100-130 (#104; draft PR #100 holds stats);
     - selection rework #113 (lazka's msys2 patch is public);
     - cluster rebalance under 100;
     - open GeoIP is a drop-in;
     - multi-ASN under 60.
3. **hayro.** HEAD `ea9c81dc`.
   - Incremental-update revision history in hayro-syntax (xref.rs/pdf.rs/page.rs, disjoint from the in-flight problem) sketches ~190 but is expected at 120-190 after the measured shrink. The traps are good (hybrid XRefStm free entries, linearized double %%EOF, embedded attachments, affected pages), but it falls below the floor and could be a standalone revision.rs.
   - Licence flag: CC0 ICC profiles are `include_bytes!` in hayro-interpret and jpeg2000. Auto Review accepted the in-flight problem anyway.
4. **TwelveMonkeys.** HEAD `18d7858d`.
   - TIFF writer insert/remove/replace-metadata is ~150-180, because the relink primitive `writePage(..., lastIFDPointerOffset)` already exists. It trips Guard 2, open PR #1303 rewrites the same file, and the JDK TIFF writer probably ships insert (OWED).
   - JPEG mutable metadata is a magnet (#668).
   - TIFFUtilities BigTIFF is claimed by the maintainer (#676).
5. **object.** HEAD `095587d3`.
   - philipc wrote 171/204 commits and is building in every subsystem.
   - Dynsym from PT_DYNAMIC is magnet #831 and absorbed (120-160).
   - SymbolMap synthesis is the maintainer's bulleted plan.
   - SHT_GROUP + section GC is ~280, but lld/mold semantics trip Guard 4, and open PR #1003 edits build/elf.rs.
   - XCOFF loader is a missing arm.
   - Rewrite growth is a patchelf port (#719).
   - Note: `yuxi-liu-wired` (real identity, 61 followers, scattershot PRs across pulldown-cmark, pest, harfbuzz, zune-image, encoding_rs, cmark) opened 4 object PRs on 2026-10-03. Recorded as a note, not added to sig_accounts.txt.
6. **rust-minidump.** HEAD `69f36e5f`.
   - XSTATE is unchanged: #152 is still the welcomed spec-named magnet, at ~270 with only one interdependent pair.
   - Invented lanes died:
     - DSO-debug + auxv reconciliation (~185) is a standalone post-pass;
     - #323 is a uniform wrap;
     - #363 and #732 are the live bitflip/processor workstream;
     - #313 has a Sentry `symbolic` crib;
     - STACK WIN is our approved kernel.
7. **MetPy.** HEAD `07df928b`.
   - Gate 3: a `binggao1230` burst (#4067-#4069 in 3 days), `mitre88` (#4039), and a good-first-issue farming swarm (#3369 implemented three times).
   - Every invented lane also dies:
     - METAR has an open maintainer PR #100;
     - #3842 has PR #3862;
     - #1256 and #2873 are maintainer plans;
     - accessor features are moving out (#2364);
     - GINI is being removed (#2636).
8. **jte.** HEAD `8035c02f`.
   - Callee-scope default params (~80-110) are "make X consistent with Y", and open PR #570 rewrites the same generators.
   - Re-indent is magnet #492.
   - Minification is declined (#415).
   - Incremental precompile is absorbed by hotReload.
   - Template modules: casid's draft PR #279.
   - Line mapping is PR #570.

## Best-of-hunt dossier (WEAK, not returned): NASA-AMMOS/3DTilesRendererJS, in-place tileset refresh
Full dossier: `worktrees/_hunt/s_1005h54/dossier_3DTilesRendererJS_h54.md`. HEAD (suggested BASE) `b003e269fe9726204707954b144d7841ba141917`.

- **Mechanics:**
  - ★2478, Apache-2.0, nothing vendored, package-lock committed.
  - Node CI green on master 2026-09-15; hunt #28 proved the suite runs headless.
  - 0 signature accounts.
  - Note: a wave of AI-written bug issues in the LRU, cache, overlay and auth lanes (#1689, #1722, #1738, #1758, PR #1755), and the maintainer has threatened to close AI issues.
- **Capability:** `refreshTileset()` re-fetches the root tileset and any loaded external tilesets, then reconciles them with the live tree.
  - Unchanged content keeps its model, cache entry and traversal state.
  - Changed content is disposed and reloads lazily.
  - Removed subtrees are torn down.
  - Added tiles join lazily.
  - A changed transform moves kept models by a delta.
- **Files:** TilesRendererBase.js, three.js TilesRenderer.js, EnforceNonZeroErrorPlugin, ImplicitTilingPlugin, and optionally the Babylon renderer.
- **Size:** reference ~234 (210-260), leanest passer ~140-160. That is the 150-250 band, so it needs the coupled second levers stated in meta (external-tileset refresh + Babylon parity).
- **Traps:**
  - identity-keyed LRU/queues force in-place mutation (`TilesRendererBase.js:1580`);
  - re-preprocessing clobbers engineData while loadingState survives (`:1287`, `:1210`);
  - baked refine/geometricError/uri inheritance (`:1282`, `EnforceNonZeroErrorPlugin.js:20-28`, `:1182-1187`);
  - a baked world transform in kept scenes (`TilesRenderer.js:802`, `:618`);
  - a lazy-preprocess last-child heuristic (`:1408`).
- **Gates:**
  - Exclusivity: PASS (13 open PRs enumerated, ~14 phrasings).
  - Six-check: PASS, with maintainer philosophy unknown.
  - Lane cold; #1695 overlaps only the transform cascade.
  - No sibling crib (CesiumJS has no in-place refresh).
  - No magnet issue.
- **Why it is not returned:**
  1. Absorption: the honest expected size is ~150, against the 0.5-0.8x shrink measured on 2026-09/10 sketches (vrp, healthchecks, aerich, continuum), so it would be the fifth absorption death in two weeks.
  2. Stage 6 Q3 is only partial: snapshot + re-preprocess + restore + delta + an LRU remove loop is close to a standalone helper.
  3. Part of its difficulty is the TOO-EASY invariant-upkeep class (openglobus).
  4. It is not a second lane on a repo we shipped or claimed. The rejected folder that pointed here belongs to a different repo, so it is outside the human's standing direction.

  It goes to the human as an optional measure-first spike, not a pick.

## Stage 6 death-class guard
Not run on a RANK 1, because there is none. The two WEAK rows were run through Q1-Q4 by their auditors:
- 3DTilesRendererJS: Q1 yes, Q2 yes, Q3 partial, Guard 1-5 pass, but it fails absorption.
- rust-minidump XSTATE: only T1 x T2 is interdependent, and it is a Stage 2d worst-case magnet.

## Budget record
- Proven pool: done (approved repo-level skips, three in-flight repos, rejected-repo pool).
- Cached star-band index: not re-triaged. Hunts #50-#52 read every row (1,746 engine rows, 9,171 + 13,459 never-named rows, the 6k-15k band) and reported 0 survivors. The human's standing direction on 2026-10-05 replaced broad discovery with second lanes.
- Fresh niche sweeps: none, for the same reason.

## What the next hunt should change
1. **The second-lane pool of approved and in-flight repos is spent.**
   - eventsourcing becomes re-auditable when 10.0 is the default branch.
   - mirrorbits and hayro have no lane at their current size.
   - Do not re-audit them before their in-flight problems resolve.
2. **The remaining unaudited "claimed" pool is the rejected/ repos screened clean today:** str0m, salsa, trustfall, umoci, rustpbx, iced, vivisect, rspirv, goblin, image-png, go-astisub, dnsjava, alembic. Screens are in `s_1005h54/screen_rejpool_h54.txt`.
   - Prefer the low-velocity ones with a domain model: umoci, dnsjava, iced, goblin, rspirv.
   - Check whether our earlier pick there died for "overlap/done before". If so, another author holds an accepted task in that repo.
3. **3DTilesRendererJS refresh is an option only if the human accepts the leanest-passer risk.** Spike it at the chokepoint first (target >= 230 human-eff with both levers), and re-run the PR-DIFF and fork check.
4. **Signature list:** `mitre88` was already present. `yuxi-liu-wired` is recorded as a note: a real identity, 4 object PRs on 2026-10-03, scattershot across niche Rust/C libraries including pulldown-cmark. Promote it if it turns up on a second repo in our pool.
