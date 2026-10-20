# REPO-HUNT-2026-10-15-B (hunter #66, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended). Result: **NO-CANDIDATE.** Eight repos were lane-audited and 40 were screened mechanically. The closest miss is systemc scheduler wait-state introspection, at 225 human-effective written, but it fails Stage 6 Q3 (a standalone query under 300 with no waiver) and TOO-EASY Guard #2.

Scratch: `worktrees/_hunt/s_1015h66/`. It holds:
- the screener `mech_h66.sh` (h65's copy) with outputs `mechdeb_h66.out` (25 rows), `mechdeb2_h66.out` (5 rows) and `mechdeb3_h66.out` (10 rows), plus the `_c_*` and `_p_*` tsv files;
- `debian_rest_h66.tsv`: all 18,668 Debian GitHub slugs joined to the band (505-8000 stars, in-scope language, pushed since 2025-10-15), minus h65's team join. That gives 1,393 rows, 1,321 with no verdict;
- `AGENT_BRIEF_h66.md` (the h66 block on top of the h65 brief);
- dossiers `dossier_{librime,systemc,spectral,python-skyfield,pyshp,walrus,nextpnr}_h66.md`;
- sketches `sketch_systemc_waitstate_h66.patch` (225), `sketch_nextpnr_net-region-routing_h66.patch` (85) and `sketch_librime_cfgprov_h66.patch` (47);
- tracker and PR dumps per repo;
- `judged_add_h66.tsv`, the 38 rows appended to `judged.tsv` (backup `judged.bak_h66`).

No clones were kept (the directory is 3.1M). Nothing was built. Disk `/` went from 12G to 11G free.

## Standing inputs and defaults taken
- **Rules applied as written (2026-10-05 user decisions):**
  - LEDGER rows exclude only their own lane;
  - only repo-scope verdicts block a repo;
  - ~505 star margin;
  - the return bar is 220 written;
  - the Q3 waiver applies only above ~300 with an internal wall;
  - the submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet, AI-sweep, velocity and signature rules, and the tracker-named-lane rule.
- **Softening:** misses = 0, so none was taken. No star or issue window was widened.
- **Requirement 0:** OWED (nothing to check).
- **Excluded lanes:**
  - Cwerg compact unions (HANDOFF);
  - allsorts (SLICING);
  - micasa blob reclaim (HUNTED by #65);
  - any qq lane;
  - pint, commafeed, aptly, ray-optics module inlining, eventsourcing;
  - every CLAIMED row;
  - the platform-dead lanes.

## Stage 0-bis: proven pool
- `REVERT-RECALIBRATION-2026-10.md` shows three acceptances today: micasa, csbindgen and **mirrorbits**. Hunter #65 covered micasa and csbindgen.
- **mirrorbits** (MIT, 592★, 30 commits in 12 months, CI green, no signature accounts): the 10-05-F second-lane audit still stands. Every lane outside the accepted scan/ledger file set is under 150 or tracker-named:
  - group-consistent redirect, #233;
  - traffic cap, #104 plus draft PR #100;
  - selection rework, #113, with a public msys2 patch;
  - rebalance;
  - GeoIP;
  - multi-ASN.

  Recorded as a lane row.
- **Other pool repos** were all re-audited on 10-14 (h63/h64): MACS, pyOCD, libspatialindex, asdf, Cwerg, hayro and the rest. None of those verdicts has passed its 60-day expiry. **The pool produced nothing.**
- gdstk is still at ★503, under the ~505 margin, so it stays on WATCH.

## Stage 0: cache tier, `debian_join_h65.tsv` (h65's hint)
- 25 rows were screened mechanically (`mechdeb_h66.out`).
- **Repo-level kills (Requirement 7: no test workflow, or a build-only one):**
  - seqkit;
  - delly (CI runs `make` only);
  - openTSNE;
  - amgcl;
  - Sniffles (release workflow only);
  - apicula (only the chipdb and YoWASP example workflows, both failing; the chipdb needs the vendor IDE).
- **Repo-level kills (signature accounts):**
  - deepTools: cindykrafft burst, 5 PRs on 09-03..08;
  - pyuvm: seam0814 burst, 3 PRs on 06-20..25, on top of an IEEE 1800.2 port shape;
  - anndata: 3 accounts;
  - numexpr: 2 accounts.
- **Lane notes (dormant with a PR queue):**
  - pyftdi: 6 commits, 20 open PRs;
  - toml11: 4 commits;
  - manif: 7 commits, 12 PRs.
- **Screened, not audited:** param, sourmash, satpy, salmon (48 AI trailers), vcflib.
- **Lane-audited by four parallel agents:**

| Repo | Verdict | Lanes and killing gates |
|---|---|---|
| rime/librime (C++, BSD-3, 4669★) | DEAD | Config provenance came to **47 written**: a parse-time tag carries through copy-on-write, so it is absorbed. Polyphone phrase encoding is refused by maintainer philosophy (#383). Pack syllables are refused too (#390: packs "must not introduce new code, or syllables"). Reverse lookup of phrases is tracker-named (#822) and public fork commits implement it. Weight split is tracker-named (#87). Encoder-rule inference is standalone (Q3). Poet, algebra, syllabifier and corrector sit in lotem's own stream. User-dict is a dead class plus PR #1196. Deps are all apt-installable, which overturns the 09-21 dependency kill. Config/ is only ~2 KLOC of reading surface. |
| accellera-official/systemc (C++, Apache, 695★) | DEAD | **Scheduler wait-state and pending-notification introspection, 225 written** (187 core plus a second lever). The gap is clean: no issue or PR names it, and IEEE 1666 does not define it. The traps are real: an AND-list counter, timeout and kernel events, cancelled-notification ghosts in an unsorted heap, sc_event_queue's private heap, and `wait(n)` storing n-1. It still fails Q3, because all of it is additive query code under 300, and Guard #2 trips. Eval-order seeding is <200. VCD $dumpoff is a verilator/bsc crib. A netlist dump is an SCC crib. Checkpointing is tracker-named (#8/#164/#153). The working group also develops privately (OSCI-wg), so prior art may exist that we cannot see. |
| spectralpython/spectral (Py, MIT, 686★) | DEAD | Every IO lane is tracker-named: #117, #120, #98 (maintainer-authored), #35, #74, #153. ENVI header propagation is <200 and has pyre/arosics cribs. Detectors can be cribbed from pysptools (open PR #156). |
| skyfielders/python-skyfield (Py, MIT, 1785★) | DEAD | SPK chain resolution: closed PR #975 has a 412-line diff. Eclipses: open PR #1076. Planetary frames: PRs #798/#839. UTC-TAI 1961-72: #679, with an implementation posted. Lunisolar calendar: philosophy (#307). Horizon mask: ~40, absorbed by `find_discrete`. **shaneraphel is confirmed a signature account** (146 repos, 266 scattershot PRs); its PR is outside these lanes. |
| GeospatialPython/pyshp (Py, MIT, 1157★) | DEAD (repo) | Two signature accounts: binggao1230 #442, which the maintainer closed as "AI slop", and **eeshsaxena #443** (548 scattershot PRs). The library is one 5.2 KLOC module and every lane is spec-named. The Editor class was removed in v2.0.0 (changelog:402). |
| wasm-bindgen/walrus (Rust, Apache/MIT, 528★) | DEAD | DWARF remap is tracker-named (#67, open since 2019) and guybedford is actively fixing DWARF. Module merge has PR #257 and #223. Branch hints are ~60-90, absorbed by `CodeTransform`. Duplicate-function elimination is standalone with a binaryen crib. Round-trip order is philosophy (#142). New capabilities arrive as wasm proposals, which are spec magnets. |
| YosysHQ/nextpnr (C++, ISC, 1773★) | DEAD | **Net-region routing came to 85 written**: router2 funnels every expansion through `checkPipAvailForNet`. Timing exceptions: closed PR #1372 diff plus roadmap #470. ECO: roadmap #333. Region attributes: #1784, with a full design. The placer/router lanes are gatecat's stream. The 09-20-C feasibility kill is overturned: generic-arch gtest needs no chipdb (PR #1793 pattern). Latent bug: pybindings.cc:260/262 binds `constr_wires`/`constr_pips` as "constr_bels". |

## Fresh sweep 1 (of 2): Debian, all GitHub-homed source packages (not just domain teams)
- `debian_rest_h66.tsv` joins h65's cached 18,668 Debian slugs to the band with no team filter: **1,321 unjudged rows.**
- Most are famous infrastructure from the Go, Rust, JS and Python packaging teams.
- A domain-keyword filter at <=4000★ left about 300 rows. 15 were screened (`mechdeb2_h66.out`, `mechdeb3_h66.out`):

| Repo | Reading |
|---|---|
| walrus | audited (above) |
| symbolic | Sentry firehose |
| canmatrix | 2 signature accounts (repo-dead) |
| python-evtx | 4 commits |
| python-bibtexparser | 2 signature accounts plus 63 AI trailers (repo-dead) |
| ProtonMail/gluon | CI moved to GitLab 2026-09-03; last GitHub test run failed (repo-dead) |
| gokrazy/rsync | every lane is an rsync manual flag in stapelberg's live stream |
| segno | 1 commit |
| nholthaus/units | maintainer v3 rewrite, 147 of 149 commits |
| tengo | dormant, 20-PR queue |
| cadquery | 41 PRs, 5940★ |
| zarr | 3 signature accounts plus 255 AI trailers (repo-dead) |
| tex-fmt | SAY-5 x3 plus 2 new accounts |
| tdewolff/parse | 3 signature accounts plus red CI (repo-dead) |
| mvel | 32 AI trailers |

Nothing reached a lane audit beyond walrus.

## Fresh sweep 2 (of 2)
Not run. Every package index and corpus lens has already been used: conda-forge, Homebrew, vcpkg, crates.io, PyPI, npm, Debian, JOSS and topics. The budget was spent on the four lane-audit agents.

## Submission counts (warning only)
- mirrorbits: 1 (accepted).
- Every other repo audited today: 0.

## Verdict rows and signature accounts
- `judged.tsv`: 38 rows appended.
  - **Repo-scope (17):** seqkit, delly, openTSNE, amgcl, Sniffles, apicula, deepTools, pyuvm, anndata, numexpr, canmatrix, bibtexparser, zarr, tdewolff/parse, pyshp, gluon, luma.core (161★).
  - **Lane-scope:** the rest, including librime, systemc, spectral, skyfield, walrus, nextpnr and mirrorbits.
- `sig_accounts.txt`: added **shaneraphel** and **eeshsaxena**.

## Why this hunt found nothing
All seven new audits failed in one of two ways:
1. **Cold, well-factored domain engines** (librime config/encoder, walrus, spectral IO). Their remaining gaps are refused by design, already named in the tracker, or a carry-through absorbed by an existing chokepoint (`checkPipAvailForNet`, `CodeTransform`, copy-on-write tags). This is the Stage 3b law again.
2. **Read-only introspection** (systemc). The state exists and the lane only reports it, so it is additive and standalone even when the traps are good.

Debian domain-team packaging selects for exactly the mature, finished libraries that the absorption law kills.

## What the next hunt should change
1. **Stop mining distribution and package lenses for now.** Debian (teams and all), PyPI, crates.io, npm, Homebrew, conda-forge and JOSS are all spent through ~10-15. The unscreened remainder of `debian_rest_h66.tsv` (~1,300 rows) is famous infrastructure.
2. **Wait for pool expiries and acceptances.** The proven pool re-opens around 2026-11-01. Re-audit any repo on the day its in-flight lane is accepted (cwerg compact unions, allsorts, qq, pint, commafeed, aptly, ray-optics module inlining). That is the only lens that produced returnable lanes this week (micasa 328, Cwerg 304, allsorts 280).
3. **systemc wait-state is the nearest miss.** If a future rule waives Q3 for introspection with internal traps, or a second, mutating surface appears (for example a deterministic-replay or event-cancellation API that must use the same resolver), its 225-line sketch and trap map are in `dossier_systemc_h66.md`.
