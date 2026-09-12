# surrealkv merge-operator -- eval results

## Deliverables
Reference solution + F2P complete, validated in docker rust:1.
- solution.patch: 5 source files (iter.rs, lib.rs, merge.rs, snapshot.rs, transaction.rs), 483 human-effective
  LOC (hook), raw 646, zero comments, no warnings. Self-describing multi-op operand (Add/Min/Max, `[op][u64 LE]`)
  + read-path fold (get/get_at/scan fwd+bwd/history) + op-aware compaction partial/full merge + MVCC snapshot-
  boundary. Existing suite 1025/1025 stable (10/10 with the cache fast-path + retries=2).
- test.patch: 18 in-crate F2P tests (src/test/merge_fold_behavior.rs, feature `merge_op_tests`), PUBLIC API only
  (`grep crate::merge` empty), proptest model oracle (BTreeMap Put/Merge(op,val)/Delete). cargo-nextest JUnit +
  `retries=2` + named build-failure fallback + stale-junit rm guard.
- meta.md (API-heavy, ASCII). Dockerfile olympus-base + cargo-nextest 0.9.78 (reused verbatim from surrealkv-73).

## Fingerprint (deliverables final, 2026-07-01 ~23:00; removed merge_at hidden-requirement surface)
Fingerprint: sol=f474b2a0fbca53a316e0591cac97819b9696f03e test=1d563c2ba8023d10fb37c8fbb85426475fcde6a8 meta=bf3467ed17579fb45efb248336306ae1596035dc docker=b5846446ff5530031296d808e8289a678f86c450 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
merge_at surface removal (2026-07-01, ~23:00): round-3 added merge_at/merge_with_options as NEW public Transaction
methods and the tests called tx.merge_at -> hidden requirement (meta documents only `merge`; an agent implementing
just `merge` fails to COMPILE the tests). Removed both methods entirely from transaction.rs; `merge` restored to the
plain COMMIT_TIME form (the real fixes -- timestamp-based get_at selection, per-group compaction timestamps, VLog
resolution -- operate on whatever ts an operand already carries and do NOT depend on merge_at). Tests now stamp
operands via the repo's existing MockLogicalClock injected through Options.clock (pub(crate)): open_versioned_clock /
open_versioned_compaction_clock return (Tree, Arc<MockLogicalClock>); a test-only `merge_at` helper does
clock.set_time(ts) then a PLAIN tx.merge (COMMIT_TIME entries are stamped clock.now() at commit, transaction.rs:871),
so operands commit at explicit/backwards ts (40 then 30; 10/20/30) with NO new public API. Verified: COMMIT_TIME->clock
stamping path confirmed; MockLogicalClock non-monotonic so backwards ts works. get_at_selects_by_timestamp_not_commit_order
still uses the EXISTING set_at. All 4 scenarios preserved; FIX2 per-group compaction test re-confirmed RED pre-fix
(base 100 vs 110) with the clock rewrite. grep -nE 'merge_at|merge_with_options' src/ -> ONLY the test-helper wrapper
(no tx.merge_at, none in solution.patch -- CONFIRMED). Build clean no warnings; feature 25/25; base nextest ci 1025
passed (1 flaky auto-retried, cache microbench); grep crate::merge empty; zero comments. eff LOC 560->547 (methods
removed). transaction.rs 175->159 stat.

Full offline + non-root 6-cell (2026-07-01, deliverable Dockerfile, fresh git-archive of BASE per cell, --network=none
--user 1000:1000): ALL GREEN. (1) SOL new 25/0; (2) SOL base 1025/0; (3) BASE new build-fail->fallback 25/25 (both new
names present); (4) BASE base 1025/0; (5) stale-junit guard base 1025->new 25/0 (no leak); (6) 5th cell BASE+test only,
NO feature: cargo build --all-targets exit 0 clean (with_vlog/compactor change source-compatible with existing
CompactionIterator::new callsites), nextest ci --lib 1025 passed. test.sh NEW_TESTS == the 25 live nextest names (exact
diff). Deliverables final on sol=f474b2a0 -- ready for Solution Quality post-check re-run + fresh Nova eval.
Timestamp-correctness fixes (2026-07-01, ~22:00): Solution Quality FAILED a 3rd time (two regressions from the
round-2 shortcuts). FIX 1 (get_at selects by TIMESTAMP not seq): round-2 rewrite sorted visible versions by
descending seq and returned the newest COMMIT. Restored the repo's original timestamp-selection: collect
(ts, seq, kind, value), sort ascending by (ts, seq), the DOMINANT version = greatest ts <= query (repo's original
best_timestamp pattern); non-merge dominant returned exactly; merge dominant folds base (newest non-merge with
ts<=query) + all merge operands after it (already oldest-first, fold applies oldest-first). Uses the existing
selection semantics, no seq-sort shortcut. FIX 2 (per-group compaction timestamps): iter.rs stamped every synthesized
merge group with the global newest ts. Added merge::partial_fold_stamped (the existing partial_fold grouping extended
to carry per-operand (seq,ts) and tag each combined group with the newest seq/ts among its members); fold_merge_runs
now collects operands as (seq, ts, value) and emits each group with ITS group ts. FIX 3 (history fold resolves VLog):
decode_history_value returned Vec::new() for VLog pointers; replaced with HistoryIterator::resolve_history_value using
the existing ValueLocation::resolve_value against the iterator's VLog (threaded via with_vlog from core.vlog, same
abstraction as the compaction resolve_encoded fix); removed the dead free fn. Added merge_at/merge_with_options on
Transaction (mirrors set_at/set_with_options) so operands can carry explicit timestamps. +4 observable tests (25 total):
get_at_selects_by_timestamp_not_commit_order, get_at_merge_selects_by_timestamp, get_at_per_group_timestamps_survive_compaction,
history_folds_vlog_backed_values. Each of the 3 fixes CONFIRMED red pre-fix (FIX1: seq-sort returns 200 not 100;
FIX2: global-ts returns base 100 not 110 at ts15; FIX3: VLog-empty history drops the 8). eff LOC 530->560. Build clean
no warnings; feature suite 25/25; base nextest ci 1025 passed/2 skipped (non-merge get_at 7/7 green -> no regression);
grep crate::merge empty; zero comments in added lines.

## Fingerprint (deliverables final, 2026-07-01 ~20:00; updated after VERSIONED-dimension GAP fixes)
Fingerprint: sol=cb454991597b448b69374b0c5e2c09b0c4fd1026 test=c2cc80ead43a8bd7a569d908a43a260e92ec7bb0 meta=bf3467ed17579fb45efb248336306ae1596035dc docker=b5846446ff5530031296d808e8289a678f86c450 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
GAP fixes (2026-07-01, ~20:00): Solution Quality post-check FAILED on two untested VERSIONED-dimension reference
gaps. GAP 1 (get_at time-travel broken after compaction): iter.rs `fold_merge_runs` collapsed a bottom-level merge
run to a single Set at the newest merge ts, destroying intermediate versions get_at needs. Fix: guard the collapse
with `&& !self.enable_versioning` so versioned bottom-level compaction keeps the base + op-aware grouped operands as
distinct Merge versions (distinct seqs, emitted newest-seq-first to satisfy the SSTable descending-seq writer);
non-versioned path still collapses. Under versioning ALL values live in VLog (threshold 0 mandatory), so
`fold_merge_runs` now resolves each operand/base via a new `resolve_encoded` (ValueLocation::resolve_value with the
compactor's VLog, threaded in via a non-signature-breaking `with_vlog` builder so the 5 existing
CompactionIterator::new callsites still compile); removed the now-dead `decode_inline`. GAP 2 (history folding
guarded by !include_tombstones): DETERMINED include_tombstones=true is INTERNAL-only -- sole caller is
Snapshot::get_at, which enumerates raw versions and does its OWN per-timestamp fold; folding there would break
get_at. So the guard is CORRECT, NO code change; public `history` (default include_tombstones=false) already folds
and meta already scopes to that. ACTION: leave raw for the tombstone path; added a meta clause making the
versioned-compaction-preserves-versions behavior discoverable. +1 observable test (get_at_after_compaction_versioned:
set_at(k,5,ts10)+merge add10+merge min8, flush+force_compact, get_at(k,15)==5 [base only] and get_at(k,u64::MAX)==8
[full fold]; fails on the pre-fix collapse) => 21 tests. eff LOC 525->530. Non-versioned compaction tests
(same_op_combine/mixed_op_survives/non_bottom_compaction) stay green. Build clean no warnings; feature suite 21/21;
nextest ci full lib 1025 passed/2 skipped. Re-run post-checks expected clean. Superseded prior batch fingerprint:
sol=ea952cdfb5e76b9a7c39f9bae2e356e7d025453a test=994a4f4200461353bba42d483c0cc544c2b9b64b meta=2f334e0cc07d3a7fc9014f4ab15944e0be894f9d docker=b5846446ff5530031296d808e8289a678f86c450 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
BATCH-1 fix (2026-07-01): relaxed the 2 history tests (subset{5,8}+contains 8, both directions) + meta clause
("operands folded into the run's value rather than surfaced individually") to remove the base-suppression hidden
requirement (Run #3 FAIL_AMBIGUOUS_TASK). solution.patch UNCHANGED (sol hash identical). test+meta changed. 20/20
+ 1025 base pass; solution byte-identical. 4-cell mechanics unchanged (same 20 test names/count, solution+docker
unchanged, SOL new re-validated 20/0). RE-EVAL against THIS fingerprint expected >=1 pass. This is the older/
superseded fingerprint of BATCH 1: sol=ea952cd test=476f636 meta=82aa232 (that batch ran pre-fix).
Post-check fixes (2026-07-01): Test Fairness FAIL (history multiplicity hidden requirement) + Solution Quality
FAIL (txn-history RYOW gap + compaction non-bottom base loss). Fixed: meta pins history=single folded entry incl
RYOW; reference folds uncommitted merge run in txn history + preserves base in non-bottom compaction (+ downstream
retention has_merge guard). +2 observable tests (ryow_history_uncommitted, non_bottom_compaction_preserves_base)
=> 20 tests. eff LOC 483->525. 1025 base stable. Re-run post-checks expected clean.
Precheck edits (2026-07-01): meta trimmed (removed order-sensitivity restatement + "without corrupting/result unchanged" tautologies; KEPT read-path enumeration as a de-trap + bypass paragraph prepared); dropped white-box count_physical_versions (redundant with get==6); Dockerfile +`cargo build --workspace --tests` precompile. solution.patch UNCHANGED. Re-validated: docker build OK (cargo-build step 35s), 4-cell GREEN (SOL new 18/0 in 26s, SOL base 1025/0, BASE new fallback 18/18, BASE base 1025/0), base stable with retries. meta 246 words.

## 4-cell validation (2026-07-01) -- GREEN on the deliverable Dockerfile (olympus-base, offline, non-root)
olympus-base:latest pulled (no substitution); cargo-nextest 0.9.78 installed; cargo fetch ok. Each cell: fresh
git-archive of BASE, `git apply`, `docker run --network=none --user 1000:1000`.
| Cell | Patches | Mode | exit | tests | failures |
|------|---------|------|------|-------|----------|
| SOL new   | solution+test | new  | 0 | 21   | 0  |
| SOL base  | solution+test | base | 0 | 1025 | 0  |
| BASE new  | test only     | new  | 1 | 21   | 21 (fallback, exact names incl get_at_after_compaction_versioned) |
| BASE base | test only     | base | 0 | 1025 | 0  |
(Re-validated 2026-07-01 ~20:00 after the VERSIONED-dimension GAP fixes: 21 tests, Dockerfile unchanged -> image cache-hit, precompile layer rebuilt 90s.)
Stale-junit guard: base-then-new -> new reports 21/21 (rm fix works). 5th cell (CRITICAL -- solution now touches
compactor.rs): `cargo build --all-targets` on BASE+test (no feature) compiles CLEAN (with_vlog builder kept the 5
existing CompactionIterator::new callsites source-compatible) + `cargo nextest run --lib` 1025/0. 5th cell (before_p2p): `cargo build
--all-targets` + `cargo nextest run --lib` on BASE+test (no feature) compile + 1025/0. Offline+non-root clean.
Cache microbenchmark did NOT surface this run (clean 1025/1025 every cell); retries=2 remains as safety net.

## Eval batches
### BATCH 1 (Nova, 2026-07-01) -- fingerprint sol=ea952cd test=476f636 meta=82aa232 docker=b584644 base=15c3540 -- 0/4 PASS (1 empty)
| Run | Verdict | Msgs | Files | LOC | Failed | Fair? |
|-----|---------|------|-------|-----|--------|-------|
| 1 | FAIL_MISSED_REQUIREMENT | 162 | 6 | 466 | 2 history | FAIR (18/20, didn't fold history) |
| 2 | FAIL_REGRESSION | 193 | 5 | 666 | 49 base + 9 new | FAIR (broke baseline + incomplete compaction) |
| 3 | FAIL_AMBIGUOUS_TASK | 163 | 5 | 684 | 2 history | UNFAIR (folded history but kept base [8,5] vs demanded [8]) |
| 4 | (empty/aborted) | - | - | - | - | no data |
READ: 0/4 statistically fine at ~10% (P(0 in 3)=0.73); msgs 162-193 => solver-median clears >100 easily (scope
strong). Difficulty concentrated in HISTORY -- agents ace get/get_at/range/compaction/MVCC (18/20), only stumble
on history. Run #3 = fixable near-pass: the base-suppression was a hidden requirement the earlier Test-Fairness
check missed. FIX: relaxed the 2 history tests + meta to verify operands are FOLDED (subset{base,fold} + contains
fold) without pinning base/multiplicity/order -> Run#3-type ([8,5]) passes, Run#1 (unfolded/raw) still fails. NO
reference change (reference [8] passes). Re-eval expected >=1 pass. New fingerprint after relaxation TBD.

## Per-agent table (superseded by BATCH 1 above)

## Eval batch #4 (fresh Nova/Orion, 8 runs) -- fingerprint sol=f474b2a0 test=1d563c2b meta=bf3467ed docker=b5846446 base=15c3540f
Ran on the merge_at-removed 25-test build (pre-de-trap meta bf3467ed). 0/8 PASSED -> SOLVABILITY FLOOR BREACHED.
Per-run failure map (from Agents Eval.txt; failingQA in the json export is empty):
- #1 Orion  Missed  253 msg 6f 998L  23/25  fails: history_fold_fwd_bwd, ryow_history_uncommitted  (HISTORY ONLY)
- #2 Orion  Missed  259 msg 9f 736L  23/25  fails: history_fold_fwd_bwd, ryow_history_uncommitted  (HISTORY ONLY)
- #3 Nova   Missed  227 msg 7f 616L  20/25  fails: get_at x2, history, ryow, compaction-per-group
- #4 Nova   Missed  174 msg 6f 603L  22/25  fails: get_at x2, history
- #5 Nova   Regress 192 msg 6f 595L  base 9 FAIL (iterator direction-switch) + new 5  (REGRESSION)
- #6 Nova   Regress 167 msg 6f 411L  base cache 1 FAIL (range-read cache) + new 3 (get_at x2, history)
- #7 Nova   Missed  164 msg 5f 653L  20/25  fails: get_at, ryow-range, history
- #8 Nova   Missed  177 msg 6f 470L  22/25  fails: get_at x2, history
All fair: agent_blame_unfair=false, description_clear=true, tests_deterministic=true, difficulty=challenging, EVERY run.
Message counts 164-259 (would-be solver-median ~256, both Orion) -- FAR above the 100 floor. LOC 411-998, files 5-9.

DIAGNOSIS: deterministic UNIVERSAL miss on HISTORY (all 8 runs, incl. the strongest agent Orion, surface the
intermediate per-operand accumulator 15 instead of collapsing the consecutive merge run to the folded value 8).
Classic 0%-trap: the fails are fair + the difficulty is real, but a universal-miss on a documented behavior breaches
the (non-bypassable) solvability floor. get_at-timestamp (5 Nova runs), RYOW-range (2), compaction-per-group (1),
and the iterator/cache regressions (2) are SCATTERED (different Nova runs miss different things) = legitimate difficulty.
Both Orion runs solved everything EXCEPT history (23/25).

FIX (de-trap history ONLY; playbook: "make the universal-miss requirement DISCOVERABLE -- a fair clarification, not
difficulty-easing"): meta history clause rewritten to name the surface explicitly -- a maximal run of consecutive merge
operands collapses to ONE history entry (the run's folded value), the intermediate accumulator after each operand is
never surfaced, a regular put stays its own entry -- plus the exact tested example (put 5, add 10, min 8 -> history 5
and folded 8, never 15). Tests UNCHANGED (history_fold_fwd_bwd / ryow_history_uncommitted already assert subset{5,8} +
contains 8 -- perfect symmetry). solution/test/docker/base bytes UNCHANGED -> no rebuild.
PREDICTED: both Orion runs (history-only miss) -> PASS (solvability MET); Nova stays blocked by get_at (NOT de-trapped)
-> difficulty ceiling holds (~2/10, in band). get_at is left as fair scattered difficulty (evals: inferable from the
existing get_at timestamp-selection code; Orion preserved it, Nova regressed it -- exactly the difficulty we want).
NEW fingerprint (meta de-trap only): sol=f474b2a0 test=1d563c2b meta=b8e1bc96 docker=b5846446 base=15c3540f

## Eval batch #5 (fresh 10-run, ON the history-de-trap meta b8e1bc96) -- 0/10, get_at is the new single wall
FRESH (failure profile SHIFTED off history -> proves it ran on b8e1bc96). 0/10, but structure changed decisively:
the history de-trap WORKED (history dropped out as primary blocker), and get_at-timestamp-selection emerged as THE
single universal wall (9/10, incl. both Orion).
- #1 Orion  Missed  437 msg 6f 1071L  get_at x2 + baseline cache regression -> FAIL
- #2 Orion  Regress 435 msg 7f  946L  baseline PASS, new 23/25 fails ONLY get_at x2  <-- ALL-ELSE-CLEAN NEAR-PASS
- #3 Nova   Integr  174 msg 5f  645L  built merge(key, op, value) 3-arg -> tests don't compile (agent API error)
- #4 Nova   Regress 165 msg 6f  731L  baseline regression (iterator) + get_at + history panic
- #5 Nova   Regress 179 msg 6f  680L  baseline regression (history_limit_backward) + absent_base panic + get_at + model_equiv
- #6 Nova   Regress 161 msg 6f  739L  baseline regression (history RYOW decode) + get_at x2
- #7 Nova   Missed  208 msg 6f  628L  broad 17/25 (scan/ryow/get_at/compaction)
- #8 Nova   Missed  267 msg 7f  618L  get_at x2 + ryow_uncommitted + ryow_history_uncommitted
- #9 Nova   Missed  183 msg 6f  703L  get_at x2 + ryow_history_uncommitted
- #10 Nova  Missed  192 msg 5f  643L  get_at x2 + ryow_history_uncommitted
All fair (agent_blame_unfair=false, description_clear=true, difficulty=challenging every run). msgs 161-437.

KEY: Run #2 (Orion) is baseline-clean and fails ONLY the 2 get_at tests -> it solved ryow, scans, history, compaction.
So get_at is the SINGLE lever from 0/10 to a real 25/25 pass. NOT a treadmill: a run exists that clears all-but-get_at,
so de-trapping get_at yields a genuine pass (there is no 3rd wall behind it for Orion #2).

FIX (de-trap get_at ONLY): every agent rewrites Snapshot::get_at to thread merge folding and REGRESSES the existing
greatest-timestamp-<=-query base selection, returning by commit/seq order (evals: "removed logic that tracked
best_timestamp", "left Some(200) right Some(100)"). Meta get_at clause rewritten to name the surface: "selects the
as-of value by user timestamp, never by commit or sequence order: the base is the regular put with the greatest
timestamp at or below the query ... when a value committed later carries an older timestamp, the greatest-timestamp
value at or below the query still wins." Tests UNCHANGED (get_at_selects_by_timestamp_not_commit_order:
put 100@ts40, put 200@ts30 -> get_at(45)=100, get_at(35)=200 -- exact symmetry). solution/test/docker/base UNCHANGED.

PREDICTED EXACTLY 1/10: only Orion #2 (get_at-only miss, baseline clean) flips to PASS. Every other run keeps a
non-get_at blocker -- Orion #1 baseline cache regression; Nova: baseline regressions (#4,5,6), wrong signature (#3),
broad miss (#7), ryow_uncommitted/ryow_history_uncommitted (#8,9,10) -- so all 9 stay FAIL. ryow + baseline-regression
remain the Nova wall = fair scattered difficulty. Solver-median (1 solver, Orion #2): 435 msg / 7 files / 946 LOC,
all floors cleared with large margin. get_at is the LAST de-trap lever (Orion #2 clears everything else).
NEW fingerprint (get_at de-trap, meta-only): sol=f474b2a0 test=1d563c2b meta=617bca8c docker=b5846446 base=15c3540f

## Fingerprint (current build, 2026-07-01; get_at de-trap, pending re-eval)
Fingerprint: sol=f474b2a0fbca53a316e0591cac97819b9696f03e test=1d563c2ba8023d10fb37c8fbb85426475fcde6a8 meta=617bca8ccb0412636c6d9b366d92dd74a689d5de docker=b5846446ff5530031296d808e8289a678f86c450 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c

## Local validation batch (post human-reviewer revision) 2026-07-02 02:35
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=52c8e4f9468710af0ec5e94c90bd59d9bb123422 meta=5511e98e00ac7142f66adf2c338f15fc398d0cb8 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
Not a platform eval batch -- local 6-cell + suite validation of the reviewer-revision deliverables.
- feature suite (merge_op_tests): 28 passed / 0 failed (incl strengthened T1 assert_eq!{5,8}, new T2/T3/T4)
- baseline nextest --lib: 1025 passed / 0 failed / 2 skipped (S3 get_at tie-break: no regression)
- 6-cell offline+non-root (uid 1000, --network=none): SOL new 28/0 rc0; SOL base 1025/0 rc0;
  BASE new fallback(28)/rc1; BASE base 1025/0 rc0; stale-junit guard OK; 5th cell all-targets clean + --lib 1025.
- eff-LOC 560 (>=430); no added comments; no merge_at in solution; crate::merge absent from tests.

## Eval batch (revised build sol=1e9c2665 meta=5511e98e) -> 3/10 TOO EASY -> hardened (2026-07-02)
Reviewer-revision build ran 3/10 PASS (runs #4,#7,#8) = 30%, over the ~10% target. Fails scattered/healthy: 3 REGRESSION
(VLog value-resolution, delete/tombstone UnexpectedEof, version/history iteration) + 4 MISSED (history fold, RYOW
timestamped reads, delete-as-zero-base, VLog-backed operands in history). Pass rate rose because the reviewer
clarifications + my get_at de-trap wording made the spec highly discoverable.
HARDEN (meta-only, no reference change -> no treadmill, no reviewer conflict; re-hardens the proven get_at wall):
removed the get_at spoon-feeds "never by commit or sequence order" + the worked non-monotonic restatement, and the
"like the existing set" signature hint. KEPT every tested/reviewer-mandated behavior stated (get_at greatest-ts
requirement, {5,8} put-stays-separate, regular_key_untouched, retention) so no hidden requirement / no 0%-trap (the
requirement is still clearly stated -> careful agents pass, sloppy commit-order agents fail = scattered). Also satisfies
the description_conciseness HIGH + one MEDIUM. meta 445->402 words, ASCII.
NEW fingerprint: sol=1e9c2665 test=52c8e4f9 meta=21b1a5b6 docker=f9cdffb5 base=15c3540f
PREDICTED: 3/10 -> ~1-2/10 (re-tightening get_at flips passers who relied on the spoon-fed ordering). If still >2/10
after re-eval, escalate to ONE orthogonal compounding edge (higher effort/treadmill risk).
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=52c8e4f9468710af0ec5e94c90bd59d9bb123422 meta=21b1a5b6d35a3eb631e17a0f5b8e7c0688a1d4d2 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c

## Fingerprint (current build, 2026-07-02; round-2 reviewer test additions, re-eval pending)
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=0a0f7505079e2535f863a6804397050beacadefb meta=21b1a5b6d35a3eb631e17a0f5b8e7c0688a1d4d2 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
