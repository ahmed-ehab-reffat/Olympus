# REPO-HUNT-2026-09-29-C (hunt #37, CONSECUTIVE_MISSES=1)

Worker: olympus-hunter (unattended). Scratch: `worktrees/_hunt/s_0929h37/`. It holds:
- screens: `screen_accpool_h37.txt`, `screen_fresh10_h37.txt`;
- the lane-audit brief `AGENT_BRIEF_h37.md`;
- per-repo dossiers `dossier_<repo>_h37.md`;
- raw evidence `mc_*`, `pf_*`, `sb_*`.

## Standing inputs
- **Human direction (2026-09-29): "use accepted repos again".** Re-mine the repos behind our ACCEPTED
  problems (`approved-problems/`, 126 folders, including pict-engine-negative-values and
  macs-circular-chromosomes) for a second lane in a different subsystem.
  - Same-repo self-collision is checked at the platform precheck.
  - Still enforced:
    - quota (<= 6 total, <= 3 per week);
    - SATURATED-REPOS;
    - canonical-org exclusivity PR-DIFF;
    - the six-check;
    - rejected/ feature-class dedup;
    - derivative (the new lane must not reuse our earlier subsystem, kernel files or feature class).
- **Do not redo hunt #35's verdicts:**
  - Cwerg is HANDOFF.
  - featurevisor, lyon, mwparserfromhell, pysmt, ir-sim and scikit-rf are DEAD. MetPy is WEAK.
  - Its signature-account-dead list and its "why not audited" list stand.
  - rust-minidump and turmoil are reserved as Cwerg's fallbacks and are not returned.
- **Interpretation recorded (documented default, no human to ask).**
  - The standing rule says every LEDGER repo is taken. The human direction names two ledger repos
    (pict, MACS) as in scope.
  - I read the ledger rule as protecting IN-FLIGHT work. I therefore treated as eligible the ledger
    rows whose problem is FINISHED and archived in `approved-problems/`: pict, MACS, bayesopt,
    csbindgen, libspatialindex, piscsi, pyfakefs, pyocd, siliconcompiler and teavm.
  - Excluded: in-flight rows and every `problems/` folder (Cwerg, grmtools, asdf, riff, ray-optics,
    hayro), DEAD ledger rows (stremio-core, dyn4j, vrp, openglobus), and CLAIMED rows not archived
    as approved (oxipng, messageformat).
- **Requirement 0 (platform picker):** not checkable here. OWED.
- **Softening:** misses=1 (< 2), so the 2026-09-09-B rules apply as written. No star or issue window
  was widened. Relaxations taken: none, apart from the ledger interpretation above.
- **No fresh GitHub sweep:** the human said to stay in the accepted pool, and hunt #36 measured
  discovery as exhausted.
- **Disk:** 9.9G free at start and fell to 5.4G mid-hunt. The MACS agent's Cython build and other
  sessions both used space. I sent both build-capable agents a no-new-builds alert. 9.5G free at the end.

## Stage 0-bis: pool enumeration
The accepted pool is 101 distinct repos, built from `approved-problems/*/meta.md` Repository lines,
URL grep, and folder-name mapping for the 57 folders without frontmatter.
- Minus hunt #35's 48 screened repos, minus in-flight and reserved rows, 53 unscreened accepted
  repos remained (`todo_h37.txt`).
- I screened them with hunt #35's screener (canonical slug, default-branch CI, 90/365-day commits,
  open PRs, PR authors, signature hits).
- The 10 finished-ledger repos were screened separately.

### The 53 older accepted repos: every one keeps a recorded kill; nothing revived
| Kill (re-measured today) | Repos |
|---|---|
| 2+ signature accounts or a swarm | cantools (7), petl (4), pvlib (4), pyparsing (4), agate (6), calamine (4), scikit-bio (4), numbat (3), afero (4), h5py (4), gojq (3), mp4ff (2), enmime (2), ezdxf (2), mpmath (2), PcapPlusPlus (2 + 4/6 quota) |
| One signature account plus a recorded lane or repo kill | datasketches-java (MaxFreedomPollard + swarm row), beartype (binggao1230 + roadmap), python-control (binggao1230 + marko1olo swarm row), sparse (binggao1230 + swarm), scikit-fem (binggao1230 + B2-SKFEM batch-mined), verde (youdie006 + red main), laspy (sapunyangkut + 0 commits/90d), yara-x (king-tero perf burst), causal-learn (SAY-5 + Requirement 7 rotten baseline) |
| Corpse, dormant, or no CI | GQL, lifelines, mtail, tablesaw, sqlsync, pyamg (0 commits/90d); avr8js, go-astits, techan, avo (4 or fewer/90d plus recorded kills); dyon (**zero CI runs** despite 26 commits/90d: Requirement 7); amaranth-stream (★0 sub-repo) |
| Capability-consuming or spec-knowable | cadence, moov-io/ach, iwe, tinywasm, awkward, smoltcp (RFC-defined, 26 open PRs, ★4607), railwayapp/cli (company product, 40 open PRs), toydb (teaching, SQL), barcode (named symbologies) |
| Other recorded kills | amaranth (RFC-gated), maker.js (spent after box joinery), chempy (lint CI red, absorbed into sibling packages), kira (B2-KIRA DO-NOT-PICK), go-workflows (copilot sweep) |

### The 10 finished-ledger repos (never re-mined before): lane audits
| Repo | ★ | Screen |
|---|---|---|
| macs3-project/MACS | 785 | CI green; 41 commits/90d (taoliu; summit, pileup V2, anndata, HMMR); `cindykrafft` x1 (bdgdiff) |
| microsoft/pict | 1471 | CI green; 24 commits/12mo; copilot PRs are CI fixes only |
| PiSCSI/piscsi | 610 | CI green; 100+ commits/90d, all rdmark |
| pyocd/pyOCD | 1467 | Nightly green; 54 open PRs; `seam0814` x1 (tools/StubProbe) |
| pytest-dev/pyfakefs | 753 | green (one intermittent macOS job); 0 signature |
| bayesopt, csbindgen, libspatialindex, siliconcompiler, teavm | - | all green; 0 signature (libspatialindex's red rows are PR runs; fixed by #312) |

Five parallel lane-audit subagents covered the 10 repos, following the brief `AGENT_BRIEF_h37.md`
(gates 1-9 plus the Stage 6 guard).

| Repo (earlier pick) | Verdict | Best second lane / killer |
|---|---|---|
| **MACS** (callpeak `--circular`) | **VIABLE, RANK 1** | callvar pair-aware fragment evidence plus phase blocks. Dossier below |
| **pyocd** (sequence expression kernel) | **VIABLE, fallback 1** | DWT watchpoint planner plus hit attribution (~260). Covered below |
| **pyfakefs** (block/inode accounting) | **VIABLE, fallback 2** | advisory locks (flock / fcntl record + OFD / lockf) plus open-file-description lifetime (~305). Covered below |
| csbindgen (struct layout fidelity) | VIABLE, reserve | typed const-expression evaluation feeding C# consts and enum discriminants (~305; 230-330 honest). Gate 1 on base: `A = 1<<0` enum discriminants silently renumbered, non-literal consts dropped, u64 > i64::MAX panics generation. Wall: `collect_const` is filter-gated and runs per file, so collection and emission must split. Risk: the "compute the right value" law (TOO-EASY jsondiff/mq), since models know Rust arithmetic. Ranked below the three above for that reason |
| libspatialindex (TPR temporal kNN) | VIABLE-borderline, reserve | MVR-tree history pruning below a horizon with page reuse (185-270). Gate 1: `MVRTree::deleteNode` is never called and `m_roots` only grows. Walls: dead-ness kept only in parent entries, shared version-copy children, persisted header stats. hobu's 09-25..27 leak sweep overlaps `mvrtree/*.cc` (note). LOC borderline |
| pict (negative values) | WEAK | `$` expected-result parameters. Half-built in `cli/` and `api/model.cpp:465` with a TODO. Gate 1 reproduced (`std::out_of_range` with sub-models, a dropped required pair, a wrong `/s` count), but ~150 eff with no genuine coupled lever, and the semantics are author-invented (FP load). #121/#130/#54/#58 are magnets; #110 "No." |
| piscsi (image reservations) | DEAD | Every non-kernel lane is rdmark's live work (#1773/#1777/#1779), a spec-named magnet (#599 multicast, #1047 CD-R, #535 CUE with "use a library"), a scsi2pi superset (tape, cache), or a post-pass (scsimon decoding) |
| teavm (method summaries) | WEAK | API-level incremental-cache invalidation (~220-310). Maintainer cautious (#1021, #9); Gradle-ABI/Zinc name; one-insight collapse risk. Other lanes sit on public branches (points-to, new-decompiler-2, js-code-splitting) or are live (c-fiber) |
| siliconcompiler (flist round trip) | DEAD | 1500 commits in 5 months. Scheduler, schema, caching, issues and remote are all live lanes. The checklist criteria language is ~150-200 eff, a standalone evaluator (Q3) |
| bayesopt (search-space migration) | DEAD | Library of 4,043 lines whose stateful core our pick already threads. Stopping criteria published (PR #591); events removed in v3 (#557); batch/constraints/types are named methods or missing arms; the ConstantLiar bug lead was absorbed into our approved solution |

## RANK 1 dossier: macs3-project/MACS, callvar fragment evidence plus haplotype blocks

- **URL / stars / licence:** https://github.com/macs3-project/MACS, ★785, BSD-3-Clause (read by our
  approved pick's audit).
- **Language:** Python + Cython (`cython.cclass` pure-Python mode). Docker is proven: our approved
  macs-circular image. See memory note "Editable install on Cython repos" (seed `build/lib`, wrap
  `bin/macs3`).
- **Activity / CI:** 134 commits/12mo, 41 in 90 days. Build and Test is green on main. Clone HEAD
  was c5443190 (the 3.0.5 release line). Our approved BASE is 760ff63b, and 0 callvar commits
  landed since.
- **Quota:** 1 of 6 (macs-circular-chromosomes, approved 2026-09-29). This would be the 2nd, and the
  1st MACS sub this week besides that one.
- **Competitors:** `cindykrafft` only.
  - Merged #739 is in bdgdiff.
  - Her fork branches touch callpeak_cmd.py/Prob.py (callvar uses only `binomial_cdf`) and the
    filterdup dedup lane.
  - Outside this lane, so a note. No AI-sweep marks.
- **Capability (repo-model phrasing).** Add a pair-aware mode to `macs3 callvar`.
  - The two reads of a pair become ONE fragment observation per site. Overlapping mates that agree
    count once at the higher base quality; mates that disagree count zero.
  - This flows through allele counts, strand counts, the four BIC models, GQ and PL.
  - Within each peak, heterozygous calls are then linked into blocks by fragments that span two
    sites: GT becomes `0|1` / `1|0` / `1|2`, and FORMAT gains `PS`.
  - Each block gets an allele-specific binding test using MACS's own heter_AS vs heter_noAS BIC
    models on per-haplotype fragment counts, for treatment and control.
- **Files:**
  - IO/BAM.py (BAMaccessor);
  - Signal/{ReadAlignment, RACollection, UnitigRACollection, PosReadsInfo, PeakVariants, VariantStat}.py;
  - Commands/callvar_cmd.py;
  - bin/macs3.

  That is three packages and 8-9 files.
- **Self-collision / derivative.**
  - None of callpeak's circular-topology kernel is touched (PeakDetect, CallPeakUnit, PileupV2,
    PeakModel, Parser.py).
  - BAMaccessor is a different reader from Parser's BAMParser.
  - The feature class is variant evidence/phasing, not coordinate topology.
  - Derivative risk: MEDIUM. "Read-backed phasing" is outsider-nameable, and WhatsHap (MIT) and
    phASER ship it.
  - Mitigation: the hard part is fragment identity through MACS's own pipeline (Cython state
    tuples, pool pickling, the fermi unitig path, `fix_indels`). The block test uses MACS's BIC
    models. Phrase meta.md on callvar's model and keep BOTH halves in scope; phasing alone would be
    a post-pass.
- **Gate 1 (the agent reproduced it on base; I verified T1/T3 from source at c5443190):**
  - `callvar` on the repo fixture (CTCF PE chr22) gives 16 rows, all `0/1`, no PS. md5 was identical
    in 3 runs and equal to `test/standard_results_callvar/PEsample.vcf`.
  - A read-name probe shows real fragment links that base reports as independent calls:
    17373045/17373048 (10+5 C-G vs 4 A-T), and 17652406/17652461.
  - `PosReadsInfo.add_T`/`add_C` take `read_index` and discard it (`PosReadsInfo.py:218-270`,
    verified).
- **Missing machinery:** nothing records which read or fragment carried which allele, and there is
  no mate, fragment, phase or block code (grepped).
- **Eff-LOC sketch per decision point:**

  | Decision point | eff |
  |---|---|
  | Fragment grouping, read path | 30 |
  | Fragment grouping, unitig path | 30 |
  | Per-fragment allele table plus pickling | 35 |
  | Variant state plus `fix_indels` carry | 45 |
  | Block construction plus PS | 55 |
  | Block allele-specific test | 40 |
  | VCF | 25 |
  | CLI / wiring | 25 |

  That is ~285. MACS sketches have run 40-64% low before (circular: 190 on paper, 312 in the spike),
  so expect 300-380.
- **Trap seams:**

  | Pattern | Present | Evidence |
  |---|---|---|
  | F-47 discarded identity | yes | `add_T`/`add_C` drop `read_index`. Every site is computed in `mp.Pool` workers even at `-m 1`. `Variant` pickles an explicit state tuple (`PeakVariants.py:113-175`), and the classes are `cython.cclass`, so a new attribute raises AttributeError and a field missing from the tuple comes back at its default |
  | F-41 / F-9 two creation paths | yes | Indel peaks are re-called from fermi unitigs. `UnitigRACollection.get_PosReadsInfo_ref_pos` (:289) passes a per-unitig index (with a shadowed loop variable). `get_variant_bq_by_ref_pos` returns no read identity, and `remap_RAs_w_unitigs` drops reads not on a unitig. A read-path-only fix fails only on indel peaks; the fixture has one (chr22:17392174) |
  | F-39 inherited helper bug | yes (verified) | `fix_indels` tests `self.d_Variants[p0].top1isreference` without calling it (`PeakVariants.py:351`, `:375`; defined as a `cython.ccall` method at :239), so it is always truthy. Unphased `0/1` hides it; phase orientation exposes it |
  | F-13 discard-unit granularity | yes | `BAM.py:798-809` keeps both mates but discards mate fields, and only the read name survives. `remove_outliers` drops the top 5% of reads by edit count, which are exactly the het-linking reads |
  | F-10 cross-product | yes | fermi off/auto/on x control yes/no x overlapping mates x SNV/indel x 1-2-site blocks |
  | F-64-like upstream filter | yes | fragment counts decide which sites survive the top2 zeroing in `update_top_alleles`, so the phased set depends on the counting unit |

- **Exclusivity / six-check:**
  - PRs in all states searched for phase/phasing, haplotype, allelic, variant, VCF, SAPPER,
    PosReadsInfo, fix_indels, fermi, indel, genotype, read pair, mate, fragment, overlapping, read
    name, SNP and callvar. Hits were #426/#430/#432 (original callvar/fermi), #576, #727 and
    #668/#690/#712/#689 (FRAG/hmmratac); none implements this.
  - The only open PR is #740 (yevshin), outside the lane.
  - feat/macs3/callvar2 is merged (0 ahead). No fork branch pushed since 2025-06 touches callvar.
    SAPPER upstream has no phasing.
  - Issues #643, #443, #462 and #679 were read: no decline, no "implemented" closure.
- **Lane density:** 0 commits on any callvar file in 12 months (last 2024-10-22). Hot areas are
  summit 8, HMMR 7, pileup 6, anndata 6. Cold.
- **Latent bug noted:** a peak listed twice produces duplicate VCF rows.
- **Test surface:** callvar has no pytest coverage (only the shell `test/cmdlinetest`). The builder
  needs a synthetic BAM + BAI + MD fixture writer; the macs-circular `mkbam.py` covers BAM, and a
  BAI writer is owed. The repo's chr22 PE fixture can serve as the real-data anchor.

### Stage 6 death-class guard (run by me on RANK 1): PASS, with flagged risks
1. **One shared kernel feeding several surfaces:** YES. The per-fragment allele table feeds counts,
   strand counts, the BIC models, GT/GQ/PL, top2 zeroing (which decides the phased set), blocks, PS
   and the block AS test.
2. **Interdependent traps:** YES, pairwise.
   - T1 (state tuple) x T4 (fragment unit): the fragment table only matters if it survives pickling.
   - T1 x T2: both creation paths must fill the same table.
   - T2 x T3: both reshape indel-peak variants, and `fix_indels` copies through T1's state.
   - The counting unit changes which sites survive and so which blocks exist.
   - Misdirecting: an indel-peak failure looks like a phasing bug, and the cause is the unitig path;
     a default-valued field after pickling looks like a counting bug.
3. **Standalone new file?** NO, as long as the fragment-count half stays in scope. Reads, the
   unitig path, Cython state and the VCF writer are all existing code. Phasing ALONE would fail
   this, so the builder must never drop the counting half.
4. **TOO-EASY Pre-Pick Guard:**
   - #1 (single rule at many sites): risk. "Group by read name" appears at two chokepoints, but
     pickling, `fix_indels`, overlap-quality rules and block linking are separate mechanisms.
   - #2 (single-subsystem transform): one command, but IO + Signal + Commands with three hidden walls.
   - #3 (hardness from an unstated spec): no. The block-linking and tie rules must be stated in
     full; the walls are code-side.
   - #4 (port): MEDIUM. Read-backed phasing is a known technique, but the hard part is MACS
     integration, not the algorithm.
   - #5 (survives being spelled out): yes.

   Verdict: PASS.
5. **Owed at scope-lock:**
   - a thin end-to-end spike confirming >= 250 human-eff with both halves;
   - a probe that a read-path-only solution fails the indel-peak cells;
   - the BAI writer;
   - the meta.md block/tie rules;
   - Requirement 0.

## Fallback 1: pyocd/pyOCD, DWT watchpoint planner plus hit attribution
- **Capability:** a watch request `(addr, len, type)` is planned onto DWT comparators (v1 aligned
  mask blocks bounded by the probed max mask; v2 single or linked base/limit pair) with all-or-nothing
  allocation. Removal, listing and the halt-time "which watchpoint fired" answer go through the
  plan, ending in the GDB stop reply `watch:` / `rwatch:` / `awatch:`.
- **Files:** coresight/dwt.py, coresight/cortex_m.py, gdbserver/context_facade.py + gdbserver.py,
  commands/commands.py. Quota 1/6.
- **Gate 1:** verified by me in the source at develop 3078bf1. `set_watchpoint` assigns `watch.func`
  before the size/mask checks (`dwt.py:141-150`), which leaves phantom slots. Unaligned requests
  program COMP=addr unaligned. DWTv2 accepts sizes 1/2/4 only. `get_t_response`
  (context_facade.py:179) never names a watchpoint.
- **Size:** ~260 eff.
- **Traps:**
  - F-13/F-47: request vs comparator identity.
  - F-39: rollback vs the assign-before-validate leak.
  - F-15/F-9: MATCHED clears on read while DFSR is sticky, so a lazy attribution loses the field on
    the `?` re-query.
  - F-10: the DWT version cross-product.
- **Exclusivity:** re-run by me (watchpoint, DWT, comparator, rwatch, awatch, stop reply/reason).
  Only historic merged PRs (#81, #748, #1377) turned up. Open #2024 (RISC-V) overlaps
  `get_t_response` as plumbing only; re-check at submit.
- **Risks:** Guard #4 MEDIUM (ARM DWT and GDB RSP are known). The three DWT register behaviours must
  be stated in meta.md. The tests need a fake AP.

## Fallback 2: pytest-dev/pyfakefs, advisory locks plus open-file-description lifetime
- **Capability:** `fcntl.flock`, `fcntl.fcntl` (F_SETLK/F_SETLKW/F_GETLK + F_OFD_*), `fcntl.lockf`
  and `os.lockf` share one per-file lock table with per-owner-kind conflict and release rules, and
  `dup`/`dup2` get a real shared description.
- **Gate 1 (agent probe vs real Linux):**
  - no conflicts at all today;
  - GETLK echoes the query;
  - `dup` + `close` + `read` raises ValueError (`fake_file.py:871-895`);
  - `os.lockf` falls through to the real OS (`fake_os.py:1460`).
- **Size:** ~305 eff. Quota 1/6.
- **Philosophy:** #645 (2021) chose the no-op "not sure which part shall be emulated", which leans
  welcome.
- **Risks:**
  - The real OS in the container is an oracle agents can experiment against. Our earlier pyfakefs
    batch read 5/10, so there is a too-easy lean.
  - POSIX is nameable.
  - struct flock is host ABI.

## Clones and scratch
- **Kept:** `worktrees/pyocd-h37-pf` (381M), `pyfakefs-h37-pf`, `csbindgen-h37-sb`,
  `libspatialindex-h37-tl`, `pict-h37-pp`.
- **Deleted:** MACS (the agent removed it after its Cython build, per the disk alert), teavm,
  piscsi, siliconcompiler, bayesopt.
- No build output remains.

## Result: CANDIDATE, macs3-project/MACS, callvar fragment evidence plus haplotype blocks
- **Fallbacks:**
  - pyocd/pyOCD (DWT watchpoint planner + attribution);
  - pytest-dev/pyfakefs (advisory locks + description lifetime);
  - reserves: csbindgen const evaluation, libspatialindex MVR pruning.
- **OWED:**
  - Requirement 0 picker;
  - the thin spike >= 250 human-eff with both halves;
  - a read-path-only negative probe on the indel peak;
  - the BAI fixture writer;
  - the precheck derivative check vs our macs-circular and any foreign MACS subs;
  - a PR-DIFF re-check at submit.
