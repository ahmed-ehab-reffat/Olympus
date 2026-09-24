# REPO-HUNT-2026-09-23-P (hunt #29, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0923h29/`.

## Standing inputs
- Hint from hunt #28 (09-23-O): stop star-band mining. Target the riff shape: a stage that carries
  STREAMING STATE across chunk / hunk / tile / frame / page / record boundaries the repo processes one
  at a time. Source from (a) the proven pool at the SUBSYSTEM level, (b) gate-clean repos from the
  09-2x logs and agent dossiers. One spike per lane.
- Excluded: every LEDGER row (19 repos incl. walles/riff), greatscottgadgets/luna, thorvg/thorvg,
  every lane judged in 09-23-C..O.
- AI markers: root AGENTS.md/CLAUDE.md = ranking penalty; 90-day AI commits lane-scoped (09-09-B #3).
- Requirement 0 (platform picker): cannot be checked by this worker -> OWED on any candidate.
- Softening: misses=1 < 2, so the 09-09-B softened rules apply as written in SKILL.md (they are the
  standing text) but no extra window widening is taken. Relaxations taken: none so far.
- Mandatory per lane: fork-branch exclusivity scan (forks?sort=newest, grep
  agents/adx-labtesing-deepswe-forks.txt + sig_accounts.txt), vendored licence headers, C++ cold
  build timing (600 s), SPIKE measured with .claude/hooks/effective_loc_check.py
  (candidate needs >=250 honest human-eff total and >=150 core).

## Stage 0-bis — proven pool (subsystem level)
Pool re-read at subsystem level for the streaming shape (chunk/record/frame/page state). Every pool
repo with a streaming subsystem is already dead on file: cantools, calamine, petl, agate, enmime,
datasketches (competitor swarms); tablesaw, avr8js, statig, sqlsync, laspy (corpse/dormant);
kira (B2 DO-NOT-PICK), surrealkv (lane ledger), astits (reference toolchain + published diffs),
mp4ff (capability-consuming), amaranth (RFC-gated), pcapplusplus (closed at 4/6), awkward (Req 7 +
swarm), h5py/tifffile/openexr (09-2x verdicts), WeasyPrint (page lanes author-obvious, page-floats
held by two foreign subs), acoular (B2 lane ledger), planetiler (09-23 dossier: every lane dead or
<=180). Group P of 09-23-J already re-judged the rest. No pool lane to spike.

## Cached index — streaming-shaped rows never judged (targeted by shape, not by star band)
Brainstormed ~40 streaming-state engines, checked each against `s_0923h28/judged.txt` and
`s_0923h24/allseen_k2.txt`. Judged already (skip): moor, acoular, defmt, flatgeobuf, libosmium,
angle-grinder, ydiff, fflate, mido, zune-image, construct, pymodbus, qpdf, pypdf, postcard, miller.
Seen-never-judged, mechanical screen (`s_0923h29/screen1.tsv`):
- DEAD Req 3 (no push in 12 months): nardew/talipp (2025-09-09), gopxl/beep, python-hyper/h11.
- DEAD <500 stars: mediacommon 99, pion/rtp 476, pion/interceptor 147, pyais 256, image-gif 176,
  zstd-rs 450, rubato 356.
- DEAD by shape on sight: ulikunitz/xz (BCJ lane = xi2/xz Go sibling), stumpy (named algorithms),
  river (catalogue, 6.1k), wfdb-python (port of the WFDB C library: reference-tool prior art).
- Live, audited below: composefs/tar-rs, pamburus/hl, RustAudio/rodio, bluenviron/gortsplib,
  zaeleus/noodles, quixio/quix-streams.

### composefs/tar-rs (moved from alexcrichton/tar-rs) — DEAD (exclusivity + maintainer rewrite)
★739 Apache/MIT Rust. Lane: header-stream state (PAX global `g` headers applied to all following
entries, PAX sparse 0.0/0.1/1.0 with the 1.0 map in the data area, size precedence). F2P real:
`pax.rs` carries the Go archive/tar GNU.sparse.* keyword constants under `allow(dead_code)`, global
headers are never applied. Killed by: PR #298 (OPEN, 2022) "Add support for PAX Format, Version 1.0"
= archive.rs +60, entry.rs +42, pax.rs +13 + a pax_sparse.tar fixture (public diff of the core);
PR #457 (OPEN draft, cgwalters, 2026-05-18) "Rebase on tar core" replaces the entry parser with the
maintainer's own tar-core crate (archive.rs +266/-184, same pax_sparse fixture); issue #412 spells
out global/local precedence. Maintainer workstream + public diff in the lane.

### pamburus/hl — DEAD (app, lanes consumed by the maintainer's spec-kit programme)
★3292 MIT Rust log viewer, root CLAUDE.md + `specs/001..010` spec-kit (AI spec-driven) + 10 AI
co-author marks in 12 months (penalty/note). Streaming lanes (segment scanning, follow-mode merge)
are the maintainer's live stream: #1544 (pamburus, OPEN) fixes follow-mode same-timestamp drops,
#1352/#1353 reworked the follow merger in Feb. Remaining asks are output/UX (#1481 output format,
#611 custom formatting). No lane.

### RustAudio/rodio — DEAD (maintainer rewrite in the lane)
★2470. The span-boundary lane (channels/sample-rate change at `current_span_len` boundaries) is the
exact subject of the in-progress rewrite: README "in progress rewrite" warning, `const_source` /
`fixed_source` landed Jul-Sep 2026 (PR #903 phase1a), span-boundary fixes 2026-05-31 and #894.

### bluenviron/gortsplib — DEAD (capability-consuming)
★940 MIT. aler9 lands 30+ commits/90d across codecs, auth, tests; `winklemad` filed 5 surgical codec
fixes in September (rtpav1, rtpklv, rtpmjpeg, latm, digest) = signature-shaped burst (not yet in
sig_accounts.txt; recommend adding). RTP de/packetizers are RFC-named per format.

### zaeleus/noodles — DEAD (capability-consuming, spec-knowable)
★724 MIT Rust, solo maintainer landing ~60 commits/90d across bgzf/csi/vcf/cram indexing and CRAM
record codecs. Every lane is a SAM/BAM/CRAM/VCF spec item with htslib as reference toolchain.

### quixio/quix-streams — DEAD (capability-consuming in the windowing/state lane)
★1572 Apache. Session windows merged TODAY (#994), state TTL migrations (#1134/#1145), recovery
(#1146), lookup buffer (#1151): the company roadmap owns windows and state.

### Cached-index streaming triage (no network)
`s_0923h29/stream_triage.py` over every cached jsonl: in-language, allowlisted, 500-6000 stars,
pushed >= 2026-01-01, never judged, description matches streaming keywords -> 2,351 rows; strong
keywords only -> 147 (`stream_unjudged.tsv`). Read by eye: stream-processing platforms (fluvio,
arroyo, iggy, numaflow, fluss: company roadmaps, huge), apps (subtitle tools, players, NVRs,
downloaders), famous codecs (jackson-core, go-json, msgpack), bindings (pyav, go-astiav, rust-pcap).
Engine-shaped residue checked live: videojs/mux.js (no commits since 2026-03, sibling transmuxers
hls.js/mpegts.js ship every codec lane), xqq/mpegts.js (maintainer landed 25 split-across-PES /
lone-sample streaming fixes TODAY), gpac/mp4box.js (fragmentation lanes active: #548/#549 +
dukesook box sweep), shinyoshiaki/werift-webrtc (ticket-driven agent workflow, RFC lanes),
tsduck (C++, full build far over the 600 s budget), python-multipart (~2k LOC, lanes sub-floor).
All DEAD.

## Fresh sweep 1 (of 2): streaming-processor TOPICS
`s_0923h29/sweep1_streamtopics.sh`: 112 single-word topics (demuxer, depacketizer, sans-io,
incremental-parsing, reassembly, canopen, j1939, nmea, mavlink, pcapng, bgzf, gcode, subtitles,
hl7, x12, binlog, cdc, wal, diff, patch, three-way-merge, rtp, mpeg-ts, fmp4, flac, gpx, ads-b,
ax25, sdr, ...) -> 1,018 rows; after licence/language/pushed >= 2025-10 / <= 6000 stars / not
judged -> 141 (`sweep1_unjudged.tsv`), of which only 3 are NOT in the seen union (an event-sourcing
reference app, an AI-agent memory layer, a chat-export auditor). Seen-never-judged engine-shaped
rows: java-diff-utils, pyeventsourcing, eventhorizon, dicom-rs (spec transcription), gotreesitter
(tree-sitter port), jsonriver (dormant since 2025-12), tinytag/exif-py (format catalogues).
**0 survivors.** Confirms 09-23-O: the shape is not findable by topic either; the seen union is
the universe.

## Back to the pool: e2nIEE/pandapower control/timeseries/protection (pandapower-added subsystems)
B2-PANDAPOWER says MATPOWER's feature list is off-limits wholesale, and names `timeseries`/
`control`/`protection` as the authorable pandapower-own surface. Our approved pick
(reliability-assessment) is in topology/reliability, a different subsystem class. Streaming-state
lanes there (state carried across TIME STEPS or across TOPOLOGY STAGES):
- L1 time-aware discrete controllers (tap changer delay / inter-tap delay / reset, switched
  shunts): `grep delay|hysteres|timer` over pandapower/control = 0; issue/PR search for tap delay,
  hysteresis, deadband, timer = nothing. Only `hunting_limit` carries state across iterations.
- L2 storage state-of-charge across time steps: DEAD, `tutorials/building_a_controller.ipynb`
  implements exactly this controller (public prior art in the repo).
- L3 sequential fault clearing: `calculate_protection_times` (run_protection.py) evaluates every
  relay/fuse independently on ONE short-circuit result; nothing opens the first device, recomputes
  the currents and carries partial relay/fuse progress into the next stage. Issue search
  (protection, relay, fuse, trip, recloser, selectivity): #1991 (closed, refactor list), #2407
  (distance protection, Fraunhofer says implemented internally, unreleased).
**pandapower gates: DEAD (competitor swarm, and one account inside the timeseries lane).**
★1279, BSD-3 (read before, B2). CI on develop: workflow `pandapower` concludes `failure` on every
push, but only the downstream `relying (3.10)` and `warnings (3.14, 2)` jobs fail; all ten `build`
matrix jobs are green (a note, not a Req-7 kill). Last 100 PRs (`s_0923h29/pp_prs.txt`): recorded
signature `binggao1230` (#3083 1ph short circuit, OPEN), `be-student` x2 (#3121/#3123) and
`dylanpulver` (#3117) - both listed in the petl swarm row - plus one-bug surgical accounts
`RanaPriyansh` (#3144 "Fix timeseries recovery after a failed recycled power flow" = INSIDE the
timeseries lane, #3145, same day), `H4nZi97`, `manusri4002`, `Kkkakania`, and `Houmgaor`
(#3074 OPEN "import OpenDSS RegControl as a tap controller" = adjacent to L1). Softened rule 2
threshold (two or more distinct signature accounts, or one in the lane) is met twice over. No
spike. Recommend SATURATED-REPOS row: pandapower COMPETITOR-SWARMED since 2026-08.

## Fresh sweep 2 (of 2): engine keywords in the 6,001-15,000-star band
The seen union covers 500-6000; the penalty band above it is not a documented ceiling (hunt #18
R1). `s_0923h29/sweep2_highstar.sh`: 19 engine keywords x 7 languages, 6001-15000 stars -> 353
rows, 160 never judged (159 seen, 1 new). Read by eye: household names (brotli, dask, trino,
numba, jsoup, PapaParse, skia, JoltPhysics, boa, wazero, re2, closure-compiler, PRQL, turf,
nunjucks = Jinja2 port, two.js), AI/app/pipeline platforms, workflow/BPM engines. Streaming-shaped
but famous or spec-bound. **0 survivors.** Sweep budget spent.

## Other gate-clean repos re-opened for the streaming shape (live checks)
- tdewolff/canvas (text flow across boxes/pages would fit the shape): `Go` workflow still
  `failure` on master (2026-08-29, 09-01, 09-13) = Req 7; maintainer is cherry-picking
  anaelorlinski's AI-generated `fix(text)` / pdf commits ("Cleanup AI output") = in-lane. DEAD.
- ChrisBuilds/terminaltexteffects (★4264, frames): 100+ maintainer commits since June in a
  repo-wide Harden/Validate/Optimize sweep (easing, canvas layout, terminal, ANSI). DEAD.
- AzurIce/ranim (★649, frames): wgpu renderer, `docs(agents)` agent-driven workflow, maintainer
  building the timeline/runtime now (#209/#210). DEAD.
- hanruihua/ir-sim (pool): maintainer shipped step modes, per-env RNG, vectorised step in the last
  60 days (09-23-E: "shipped every lane"). DEAD.
- python-control (pool): SATURATED says COMPETITOR-SWARMED (marko1olo 12+ PRs). DEAD.
- The only never-SPIKED paper lane with the streaming shape among the 09-2x WEAK rows is
  macs3-project/MACS circular chromosomes (09-23-M paper ~190 / ~225 with the BAMPE lever,
  core ~110-145; wrap across the chromosome end/start boundary through one pileup chokepoint).
  The riff lesson (paper ~245 -> spike 440) says paper sketches run low, so it gets the one spike
  this hunt can afford. MACS CI on the default branch `main` is green (2026-09-22, x64 + non-x64);
  the red `master` rows are a fork PR head branch.

## Workshop (1 agent): MACS circular-chromosome spike
Brief: re-check gates, build Cython in a venv, PROTOTYPE the lane core (working code), measure with
the hook, answer the guard, clean up. Spike patch kept: `s_0923h29/macs-circular-spike.patch`
(applies on ece0896); F2P probes kept: `s_0923h29/probe/` (mkbam.py synthetic BAM generator,
f2p.py, f2p90.py, broad.py, model.py).

### macs3-project/MACS — circular chromosomes — SPIKE 312 human-eff (paper said ~190)
**Gates re-checked 2026-09-23:** ★784, BSD-3-Clause, default `main`, last 6 main runs green
(v3.0.5 release 2026-09-22); the red `master` rows are yevshin fork PR runs. Base suite 106 passed /
4 skipped (30 s after a 73 s `build_ext -j8`), unchanged with the spike applied. Vendored code all
permissive: fermi-lite MIT (Broad), simde submodule MIT (+ CC0 hedley/debug-trap), swalign MIT,
cPosValCalculation BSD; no GPL/LGPL/MPL. Python primary (1.23 MB vs Jupyter 0.70 MB, C 0.22 MB).
No root AGENTS.md/CLAUDE.md. One AI-co-authored commit in 90 days: 9dbb3c7 (cindykrafft, "Claude
Fable 5.1", bdgdiff ScoreTrack.py) = outside the lane, NOTE. Quota 0/6, no macs folder anywhere.
**Exclusivity:** PRs+issues all states for circular / plasmid / chrM / mitochondri / origin / wrap /
bacteria / topology: nothing in the lane (#112 "circular" as a word; #353/#692 bacterial questions
on the model; #747/#749 summit-padding "origin" bug). Open PRs: #749 (taoliu, summit padding,
CallPeakUnit.py +11/-16 + ScoreTrack.py) = same file, different capability (rebase-churn note);
#740 (yevshin, per-base q-value bedGraph) not in the lane. **Fork-branch scan:** 43 forks pushed
after creation, 557 branches, 157 unique heads compared against main: 52 ahead, 25 touch lane files,
zero added lines mention circular / wrap / plasmid / chrM / topology; the one message hit (AREM
"peaks at chrom end") is a MACS 1.4 linear-end bug. `adx-labtesing-deepswe-forks.txt`: no MACS.
Signature accounts in the last 40 PR authors: cindykrafft only (#739 bdgdiff, outside the lane) =
NOTE under softened rule 2. Removal record: none (09-23-M: `git log --all --grep=circular` = 0,
ChangeLog clean, macs_v1/v2 trees clean). Sibling check (`search/code`): freddolino-lab/ipod
`peak_utils.py` (a lab pipeline with its own bacterial wrap utilities) is the nearest public code;
the lane's hard part is MACS-internal (pqtable/cutoff accounting, broad two-level linkage, BAMPE
pair recovery, PeakModel scan), not a named algorithm, so no sibling-textbook kill.

**Spike (working code, 11 files):** CallPeakUnit.py 137 raw (circular lengths state; rotation of the
tail below-cutoff run into negative coordinates at narrow, broad lvl1, broad lvl2 and cutoff
analysis; origin offset at the three close/add sites; no clip at 0 for call-summits padding;
per-chromosome re-sort; lvl1 lift into the frame of an origin-spanning broad region) | Parser.py 73
(BAMPE origin-spanning improper-pair rebuild `[mate, read_end + L)`) | PileupV2.py 58 (mod-L wrap
split in the SE PN kernel = treatment + every SE/PE lambda window, and in the PE LR kernel) |
PeakModel.py 34 (tags rotated to the widest gap for the paired-peak scan) | callpeak_cmd.py 23 |
PeakIO.py 17 (summits.bed / xls abs_summit mod L) | FixWidthTrack.py 14 | PairedEndTrack.py 14 |
OptValidator.py 7 | PeakDetect.py 4 | bin/macs3 2. bedGraph needed no code (arrays never rotated).
Output convention chosen: an origin-spanning peak is reported once with start in [0, L), end > L.
**Measurement (hook):** raw 383 / counter1 351 / **human-effective 312** / padding-floor 257;
~294 with the 55 added docstring lines stripped. CORE (wrap kernel ~36, segmentation/rotation/lift
~103, PeakModel ~24, BAMPE rebuild ~50) = **~190-213**; plumbing ~99. Unimplemented remainder
~60-80 (PETrackII/FRAG weighted kernels ~35, `-f BAM` on paired data ~10, PeakIO exclude/overlap
with end > L ~10, pileup/bdg subcommands ~20). Honest total 294-312 now, ~360-380 complete.
Both bars (>= 250 total, >= 150 core) clear. The paper sketch was ~40% low, same as riff.
**F2P (synthetic L = 20 kb, a site straddling 0 + an interior twin at 10000):** base is worse than
09-23-M recorded - both half-peaks fall under min_length, so the origin site VANISHES from narrow,
summits and broad; bedGraph at the origin is half height (62 vs 123). Spike: one narrow peak
19834-20148 (twin 9842-10168); a site at +90 gives 19929-20246 with summits 86/87 mod L; broad one
region 19833-20156; an origin-spanning broad region with an inner strong block gives one gappedPeak
19055-20881 with the block kept (base: two regions, block lost). BAMPE CLI: base 480 fragments and
origin pileup 0-1; spike 558 fragments (78 pairs rebuilt), one origin peak 19875-20132. Interior
q-values move legitimately (104.98 -> 105.67 SE, 72.7 -> 67.1 PE) because the pqtable now counts
the origin at full height - that is the misdirecting cell. PeakModel rotation runs but the
synthetic showed no model-level F2P yet (same 132 pairs, d = 179 both ways) - OWED.

## Stage 6 — death-class guard on RANK 1 (macs3-project/MACS, circular chromosomes)
1. ONE shared kernel feeding several surfaces, local fix regresses another: YES. One wrap kernel
   feeds the treatment pileup and every d/slocal/llocal lambda window; one chokepoint array
   (`pileup_treat_ctrl_a_chromosome`) feeds pqtable, cutoff analysis, narrow, call-summits, broad
   lvl1/lvl2 and bedGraph. Rotating the arrays to fix segmentation breaks bedGraph coordinates;
   fixing narrow leaves broad split and loses gappedPeak blocks.
2. Traps interdependent + misdirecting: YES (moderate). The natural pad-and-fold shortcut
   (duplicate reads past L, call on L+K, fold back) passes every origin cell but double-counts the
   padded bp in the genome-wide pqtable, so INTERIOR peaks' q-values and the cutoff analysis shift
   (failure shows far from the origin). Wrapping only the treatment leaves the control lambda
   clipped (origin fold-enrichment wrong, misdirecting as a lambda issue). Summit frame vs mod-L
   differs between writers; rotation changes peak order/numbering unless re-sorted.
3. Standalone file / post-pass: NO for correctness. A post-pass cannot recover the halves (already
   discarded under min_length); a track-level pad-and-fold pre-pass is exactly the misdirecting
   wrong answer above.
4. TOO-EASY Pre-Pick Guard: #1 uniform wrap - PASS (the kernel is one mod-L rule, but
   segmentation rotation, two-level broad lift, BAMPE pair recovery and the model rotation are
   distinct non-collapsing mechanisms); #2 single-subsystem transform - PASS (IO/Parser, Signal
   pileup, PeakModel, CallPeakUnit, PeakIO; hidden walls = pqtable accounting, broad linkage, BAMPE
   pairing); #3 hardness from unstated spec - PASS with care (the output convention must be stated
   in meta.md; the pqtable wall survives being stated as "each position counted once"); #4 port of
   a known spec - PASS (no spec, no reference tool ships it); #5 survives full spelling - YES
   (cross-stage integration).
Guard verdict: PASS, no question fails. Moderate risks recorded: Q3/#2 (the difficulty must come
from the pqtable / broad / summit-frame / BAMPE cross-product cells, F-10 style), open PR #749 in
CallPeakUnit.py, Cython rebuild in test.sh (~73 s with -j8).

## Dossier — RANK 1
### macs3-project/MACS — ★784 — RANK 1
- **URL:** https://github.com/macs3-project/MACS (canonical; default branch `main`)
- **Language:** Python primary (Cython pure-Python-mode .py compiled at install; vendored C: fermi-lite MIT, simde MIT, swalign MIT, cPosValCalculation BSD)
- **Domain:** ChIP-seq/ATAC-seq peak-calling pipeline (parse -> model -> pileup -> lambda -> pqtable -> segmentation -> output)
- **License:** BSD-3-Clause (vendored files read, all permissive)
- **Last commit:** 2026-09-22 (v3.0.5 release); CI green on main
- **Tests:** pytest, 106 passed / 4 skipped, ~30 s warm; behavioural through public API (callpeak units + CLI); anndata needed for test_PairedEndTrack.py
- **Determinism:** 104/4 identical x3 (09-19 hunt), 106/4 twice in this spike; 3x in Docker OWED
- **Docker:** Pattern B `olympus-base-python`; test.sh must `build_ext --inplace` changed modules (73 s with -j8, ~5 min single-threaded); not built in Docker here
- **Capability-lane density:** dead lanes recorded in 09-23-M (per-library pooling = WACS branch, dedup = cindykrafft fork, blacklist = #613 magnet, spike-in #356, bdgdiff, provenance post-passes); summit code is maintainer-hot (#741/#747/#749) - the lane touches the summit padding clip only
- **Maintainer-welcomed:** none found; no request either way (no Gate 8 signal; taoliu favours pooled controls, unrelated)
- **Self-collision:** none (no peak-calling / ChIP pick in approved-problems, problems, rejected)
- **Missing machinery (LOC carry):** no circular topology anywhere: `fix_coordinates` clips, segmentation is linear (`above_cutoff_startpos[0] = 0` special case), PeakModel scan is linear, the BAMPE parser drops improper origin-spanning pairs
- **Trap seams:** F-9 (a stage discards what a later one needs: clip at pileup -> segmentation/pqtable), F-10 (form axes: SE/PE x narrow/broad/summits x treatment/control lambda x origin/interior), F-47 (discarded extension), F-14-ish (improper-pair exit in the parser)
- **Estimated complexity:** 294-312 human-eff measured, ~360-380 complete, 11 files, 5 packages
- **Risks:** outsider-nameable ("circular chromosome support") = MEDIUM, mitigate by phrasing on MACS's model (no long-open issue asks for it); open PR #749 same file; cindykrafft (sig) visits outside lane; model-level F2P not yet shown; Cython build time in test.sh.

## Result: CANDIDATE — macs3-project/MACS
Fallbacks (both WEAK, neither clears 250/150 on their current evidence):
NASA-AMMOS/3DTilesRendererJS (3D Tiles 1.1 multiple contents, spike 133 / honest ~215/115,
spec-named, #608 plan) and asdf-format/asdf (lazy_tree pass-through write, paper ~195/120, class
overlap with the approved enmime Rewrite).

Recommendations for the human (not applied): add SATURATED-REPOS rows for e2nIEE/pandapower
(COMPETITOR-SWARMED since 2026-08: binggao1230, be-student, dylanpulver, RanaPriyansh in-lane),
composefs/tar-rs (PR #298 + maintainer tar-core rebase #457), quixio/quix-streams and
xqq/mpegts.js (maintainer-consumed streaming lanes); consider profiling `winklemad` (gortsplib,
5 surgical codec fixes in September) and `RanaPriyansh` for sig_accounts.txt.
Lesson: the one never-spiked paper lane with the streaming shape measured 64% over its sketch
(190 -> 312), the second time in two hunts a paper sketch ran ~40-65% low. Re-spike the other
paper-WEAK rows (asdf lane 1, urbansim, cartopy Z-through-project) before calling them dead.
Disk: 15G free at the end; spike worktree, venv and 1.1G fork-scan repo removed; the f_bio/MACS
clone is back at ece0896, clean.
