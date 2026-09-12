# surrealkv merge operator -- Olympus submission (pivot from surrealkv-73 range tombstones)

Repository: https://github.com/surrealdb/surrealkv  (Language: Rust)
Base commit: 490052928e4a12e3cf6650b70c2b2f448f63adf2

## Why this exists (pivot from delete_range)
surrealkv-73 (delete_range / MVCC range tombstones) passed every static gate + 4-cell GREEN, then the platform
dedup flagged it DERIVATIVE (sim 0.775, conf 0.9) vs a sibling that already did MVCC range tombstones in an LSM.
Per [[olympus-similarity-not-bypassable]] a superset is inherently derivative + a true feature-dup is human-
reverted even after a bypass. User chose to PIVOT to a disjoint surrealkv feature. delete_range is shelved as
patches in problems/surrealkv-73/ (the reusable harness + architecture reference); worktree reset to clean base.

## Candidate research (disjoint surrealkv features)
Open issues harvested (curl): only #73 (range delete, ours) is a mergeable engine feature; #61 encryption / #48
OPFS out of scope; VLog GC (#350/#338/#354) + commit-conflict (#372/#378) + savepoints (#74-77) are maintainer-
OWNED or DONE. Pool dedup: only LSM problems are surrealkv-73 (pivoting) + risinglight (Task 3, snapshot
isolation + savepoints). Verdicts: MERGE OPERATOR = CLEAR; compaction filter = CLEAR but deletion-adjacent (risk);
savepoints = OVERLAP risinglight (reject); VLog GC = maintainer-reserved (reject); WriteBatch = no engineering
lever, transcribable (reject); column families = 2500+ LOC, no backing (reject).

## CHOSEN: MERGE OPERATOR (RocksDB-style read-modify-write)
- Disjoint: accumulate-and-fold values vs hide-a-span. Shares only the generic kind-byte plumbing.
- Mergeable: `InternalKeyKind::Merge = 3` is a wired-but-unimplemented reserved placeholder (lib.rs:712,756;
  batch/WAL/memtable already round-trip it, batch_tests.rs:337-451) -- zero semantics in get/scan/compaction
  (a latest Merge falls through as a plain PUT, older operands wrongly dropped). No competing PR/issue.
- The ~10% surface (NOT transcribable): (a) compaction-time PARTIAL merge (fold the contiguous operand run down
  to but not across the newest base PUT, emit a folded result; naive drops operands as superseded); (b) MVCC
  snapshot-boundary folding (operands above a live snapshot must not fold into its read/get_at); (c) read-path
  fold across get/get_at/scan/history. Naive returns the last raw operand instead of the fold.
- Footprint: 5 independent subsystems (transaction/RYOW, snapshot read-fold, iter compaction-fold, options,
  memtable/batch reuse), ~500-800 eff LOC. Reuses the validated Dockerfile/test.sh/nextest/F2P harness.

## SOLVABILITY CONSTRAINT (vet before build)
The fold is configurable -> a user `MergeOperator` trait or an agent-named config enum the tests must reference
would compile-couple the F2P = 0% solvable (the delete_range internal-API trap). MUST drive the fold through a
STABLE runtime API: `Transaction::merge(key, operand)` + existing get/scan/get_at/history, fold semantic FIXED or
SELF-DESCRIBING (operand-bytes/single documented rule), no agent-typed config. Design pass in flight to lock this
down (fold-semantic options: u64-add counter / byte-append / self-describing operands).

## Status
Worktree clean base, Merge=3 placeholder confirmed, folder scaffolded (BASE_COMMIT + Dockerfile copied). NEXT:
vet the design report (esp. the no-typed-config-coupling constraint), then build reference solution -> F2P ->
meta -> 4-cell -> eval, reusing the surrealkv-73 harness pattern.

## DESIGN APPROVED (solvability vetted) -- building reference solution
API: `Transaction::merge<K,V: IntoBytes>(key, operand)` positional (mirrors set/delete), reuses Merge=3 plumbing,
agent adds SEMANTICS ONLY. NO trait, NO Options config -> nothing the F2P compile-couples to (constraint #1 MET).
Fold: FIXED u64 counter-add (8-byte LE), value = base + Sum(operands); PUT sets base, Delete resets to 0, fold
applies only when the dominant visible version is a Merge (regular keys untouched). Tests use only valid 8-byte
operands (no malformed-operand fairness surface). Canonical UInt64AddOperator = mergeable for the reserved slot.
Surface (genuine, not transcribable): (a) compaction PARTIAL/FULL fold of the operand run down-to-not-across the
newest base (naive treats latest Merge as PUT + drops older -> corrupt sum after compaction); (b) MVCC snapshot-
boundary (operands above a live snapshot not folded into its read/get_at; compaction not collapsing across a
boundary); (c) read-path fold across get/get_at/scan/history. Footprint 5 subsystems (transaction/snapshot/iter/
new src/merge.rs/memtable+batch), ~470 eff. F2P: feature `merge_op_tests`, in-crate src/test/merge_fold_behavior.rs
(non-guessable), PUBLIC API ONLY (no crate::merge:: imports -- the delete_range solvability lesson), proptest
model oracle (BTreeMap Put/Merge/Delete read_at). Harness reused from surrealkv-73 verbatim.

## FOLD DECISION: u64-add -> SELF-DESCRIBING MULTI-OP (2026-06-30)
u64-add reference built + validated (9/9 smoke, 1025 base) but capped at 428 eff WITH every in-design surface
(HistoryIterator fwd+bwd fold + get_at/history/range RYOW + full compaction partial/full + saturating overflow) --
a mild structural LOC trap (the fold kernel "decode 8 bytes, sum" is too thin; the rest would be padding). Cache
flake FIXED: non-merge fast-path (single is_merge at return site, no per-scan-key decode) + retries=2 in nextest ci
profile -> 10/10 = 1025 (1 run flaky-but-passed-on-retry).
SWITCHED to multi-op operand `[op_byte][8-byte LE u64]` (0=Add/1=Min/2=Max). NEW genuine surface = op-AWARE
partial merge: contiguous SAME-op runs combine (Add+Add->Add(sum), Min+Min->Min, Max+Max->Max) but MIXED-op runs
stay SEPARATE + ORDER-PRESERVED (Add then Min != one op; fold applies oldest->newest, order-sensitive). Naive
collapses mixed ops / reorders -> wrong. Estimate ~490-520 eff (comfortable >=480 margin), NO dep, mergeable
(RocksDB built-in operator shape), reuses 100% of the 6-surface fold plumbing. JSON merge-patch REJECTED (serde_json
dep into a dep-light engine + RFC7396 is a transcribable spec = cel-rust trap + recursive-merge fairness fragility).
Solvability still clean: self-describing operand bytes, no trait/config; tests use only valid 9-byte operands.

## DELIVERABLES COMPLETE + 4-CELL GREEN + FINGERPRINTED (2026-07-01) -- READY FOR EVAL
All 5 deliverables + 2 tracking files final. solution.patch: 5 source files, 483 human-effective LOC (hook,
clears 430 with margin) / raw 646 / zero comments / no warnings. test.patch: 18 public-API in-crate tests +
proptest model oracle + nextest fallback + retries=2 + stale-junit rm. meta.md 273 words (API-heavy, ASCII).
Dockerfile olympus-base + cargo-nextest 0.9.78 (+CMD bash). 4-cell GREEN on the deliverable Dockerfile (offline +
non-root): SOL new 18/0, SOL base 1025/0, BASE new fallback 18/18, BASE base 1025/0; stale-junit guard + 5th
all-targets-base cell + offline/non-root all pass; cache flake did not surface (clean 1025), retries=2 safety net.
Fingerprint: sol=46f2acd test=5b97a3f meta=a939fd0 docker=1c7e9b5 base=15c3540.
STATIC Olympus gates ALL met (5+2 deliverables, 483>=430 eff, 5>=3 files, native-nextest JUnit + per-test
fallback, zero comments/no warnings, frontmatter+273w, olympus-base+WORKDIR/app+cargo-nextest, dedup-CLEAR vs the
range-tombstone sibling -- disjoint fold-values feature). DYNAMIC gates PENDING the Nova batch: solvability >=1/10,
~10% ceiling, solver-MEDIAN messages >100. Bypass-eligible precheck notes carried from surrealkv-73: white-box
count_physical_versions/pinned_reader (the only way to verify documented MVCC-as-of + compaction-survival) +
meta operand-format detail (necessary data contract, not over-spec).

## POST-CHECKS (2026-07-01): Test Fairness FAIL + Solution Quality FAIL -> FIXING (binding, not bypass-eligible)
Required post-checks caught real issues (prechecks were ignorable; these are NOT):
- TEST FAIRNESS FAIL (1/18): history_fold_fwd_bwd pins history multiplicity (one collapsed entry) that the meta
  never stated; repo history normally returns all versions, so per-commit-folded was an equally-valid read =
  hidden requirement. FIX: meta now states "history reports a key's merge run as a SINGLE folded entry... RYOW
  applies to history too."
- SOLUTION QUALITY FAIL (Comprehensiveness 1/3): reference has 2 real gaps the 18 tests didn't catch -- (1) txn-
  local history RYOW: history_with_options takes entry_list.last() per key, doesn't fold MULTIPLE uncommitted
  merge operands (meta requires RYOW on every read path incl history); (2) compaction non-bottom-level branch
  consumes the base but re-emits only grouped Merge operands, NOT the base -> non-bottom compaction can drop the
  base. (VLog/decode-inline silent-empty flagged but moot -- merge values always 8/9B inline.)
FIXES delegated: (1) fold uncommitted merge run into one history entry + test ryow_history_uncommitted; (2) non-
bottom branch preserves base, full-merge only at bottom + test non_bottom_compaction_preserves_base; re-validate
(20 tests, 1025 base, 4-cell) + re-fingerprint. These ADD LOC (over the current 483). LESSON: history+fold is a
multiplicity-ambiguous read path; the post-check Solution-Quality code review finds untested spec gaps the F2P
green run hides.

## BATCH-1 FAIRNESS FIX WORKED + POST-CHECK ROUND 2 (2026-07-01)
Test Fairness now PASSES (history relaxation removed the base-suppression hidden requirement -> "Clean (skipped)").
Solution Quality FAIL again (round 2) -- 2 NEW untested versioned-dimension gaps found by code review:
- GAP 1 (get_at after compaction): fold_merge_runs collapses a bottom-level merge run into one Set at the newest
  ts, discarding base+intermediate -> get_at(intermediate ts) after compaction in VERSIONED mode loses the value.
  FIX: gate the collapse on !versioning; in versioned mode keep base+grouped operands as versions so get_at folds
  <= ts. Test get_at_after_compaction_versioned (get_at(15)=5 base, get_at(100)=8 fold).
- GAP 2 (history include_tombstones): folding guarded by !include_tombstones -> raw mode surfaces operands.
  FIX: determine public-vs-internal; fold if public (test), else scope the meta to the default mode.
User directive: FAILURES must be fixed; WARNINGS (Dockerfile + description-conciseness) bypass/ignore.
PATTERN NOTE: merge fold vs versioned time-travel (history, get_at) is a recurring gap source; the seq-based/
current reads are solid but every timestamp/version interaction needs care. If a 3rd SQ gap surfaces, reconsider
scope. (delete_range-shelved harness reused throughout.)

## SOLUTION QUALITY ROUND 3 (2026-07-01) -- versioned/timestamp/VLog, PARTLY REGRESSIONS from round 2
3rd SQ FAIL, all versioned-dimension; two are shortcuts introduced by the round-2 fix:
- get_at selection by descending seq_num (returns newest COMMIT) instead of greatest TIMESTAMP <= ts -> wrong when
  commit-order != ts-order. (regression from the round-2 get_at rewrite)
- compaction stamps every synthesized merge group with the newest merge ts -> get_at can't reconstruct intermediate
  as-of after compaction. (round-2 preserved operands but flattened timestamps)
- decode_history_value returns Vec::new() for VLog pointers instead of resolving via Core::resolve_value ->
  history-after-flush on VLog data drops values. (shortcut, not the existing abstraction)
FIX delegated PROPERLY (no shortcuts): timestamp-based get_at selection (restore repo pattern + fold); per-group
timestamps in compaction; VLog resolution in history fold; +3 tests, each fails pre-fix, 1025 must stay green.
TREADMILL FLAG (told user): merge fold is DEEPLY coupled to the versioned/timestamp/VLog machinery; every SQ round
finds another corner (RYOW-history -> non-bottom base -> get_at-after-compaction -> get_at-seq-vs-ts + compaction-ts
+ history-VLog). The DIFFICULTY (history/versioned reads, the eval's differentiator) is inseparable from the GAPS.
If a 4th SQ gap surfaces, RECONSIDER the feature/scope rather than chasing more -- this is diminishing returns and
the subagent has been shortcutting under the depth. Lesson for future: a fold/merge feature on a timestamp+VLog
versioned store is a Solution-Quality treadmill; screen for it at SELECTION.

## MERGE_AT HIDDEN-REQUIREMENT CLEANUP (2026-07-01) -- the "one clean attempt"
Round-3 fixes correct BUT introduced merge_at/merge_with_options as NEW public methods the tests call -> hidden
requirement (meta only documents `merge`; agent implementing just merge fails to compile the tests) = solvability
risk. User chose "do what's best" -> option 1 (push through cleanly): REMOVE merge_at/merge_with_options from the
solution; control the merge operands' timestamps in the tests via the existing MockLogicalClock (set clock=ts,
then merge -> operand stamped ts; backwards clock gives commit-order != ts-order) -- NO new public API, feature
stays exactly `merge`. The reference's real fixes (ts-select get_at, per-group compaction ts, VLog resolution)
don't depend on merge_at. Re-validate + re-fingerprint, then re-run post-checks.
TREADMILL WATCH: this is the LAST clean attempt. If the post-check re-run surfaces a 4th versioned-dimension gap,
PIVOT (the merge-on-versioned-store is structurally SQ-treadmill-prone; difficulty inseparable from gaps). Screen
fold/merge-on-timestamp+VLog-versioned-store features OUT at SELECTION in future.

## Eval batch #4 -> HISTORY de-trap (2026-07-01)
0/8 solvable = solvability floor BREACHED, BUT this is a de-trappable 0%-trap, NOT the treadmill/pivot case:
the reference solution is validated (6-cell green, oracle-correct) and message counts are excellent (164-259,
solver-median ~256 >> 100). The breach is a deterministic UNIVERSAL miss on the HISTORY surface -- all 8 runs
(incl. both Orion, the strongest agent) surface the intermediate per-operand accumulator (15) instead of collapsing
the consecutive merge run to the folded value (8). Both Orion runs solved everything else (23/25, history-only miss).
DECISION: de-trap history ONLY (playbook: make the universal-miss requirement discoverable = a fair clarification, not
difficulty-easing) -- meta now names the collapse surface explicitly + the exact tested example. Tests unchanged
(already subset{5,8}+contains 8). Leaves get_at-timestamp (5 Nova runs), RYOW-range (2), compaction-per-group (1),
and the iterator/cache baseline regressions (2) as SCATTERED fair difficulty -> Nova stays blocked, ~2/10 predicted.
This is the standard final-calibration step, so the earlier "treadmill watch -> pivot" trigger does NOT fire: the
solution is done and correct; batch #4 is a CALIBRATION signal (universal-miss), which has a known in-place fix.
Re-eval on meta=b8e1bc96 (meta-only change; no rebuild).

## Eval batch #5 -> get_at de-trap (2026-07-01)
History de-trap confirmed working (batch #5 failure profile shifted OFF history). New single universal wall =
get_at timestamp-vs-commit-order selection (9/10). Run #2 (Orion) is baseline-clean, fails ONLY the 2 get_at tests
(23/25) = the all-else-clean near-pass -> proves get_at is the last lever, not a treadmill. De-trapped get_at in meta
(greatest-timestamp-<=-query base selection, never commit/seq order). Predicted EXACTLY 1/10 (Orion #2 flips; all 9
others hold on ryow/baseline-regression/signature/broad blockers). Re-eval on meta=617bca8c (meta-only; no rebuild).

## Human-reviewer revision applied (2026-07-02 02:35)
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=52c8e4f9468710af0ec5e94c90bd59d9bb123422 meta=5511e98e00ac7142f66adf2c338f15fc398d0cb8 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
Applied reviewer spec S1-S6, T1-T4, O1-O5, META. Summary:
- S1: history now emits the base put as its OWN entry PLUS the folded merge-run entry (two entries, both
  committed fold_forward_run + backward newest_is_merge path AND RYOW write-set path via removing the
  merge_fold_keys blanket suppression). Empirically history_fold_fwd_bwd and ryow_history_uncommitted both
  yield exactly {5,8} (assert_eq! now passes).
- S2: partial_fold_stamped keeps distinct-timestamp same-op operands as SEPARATE groups (combine only when
  same op AND same ts); get_at reconstructs the intermediate after compaction.
- S3: get_at equal-ts tie-break restored to smallest-seq-among-greatest-ts (dom_idx = first index at greatest
  ts in (ts,seq)-asc sort; operands bounded to ..=dom_idx). Baseline 1025 green (nextest) -> no get_at regression.
- S4a: collapsed apply/combine duplicate helpers (kept apply). S4b: encode_base made private fn.
- S6: retention documented in meta (one sentence), retention logic unchanged.
- T1: 3 history tests strengthened to assert_eq!{5,8} / added contains(&5). T2/T3/T4 added. O5 prefix rename.
- O1 (Docker sev-4): symlink loop -> `install -m 0755` (root-owned 0755 cargo, not agent-writable);
  chmod reconciled to READABLE-not-writable: `chmod a+rx /root && chmod -R a+rX "$CARGO_HOME" "$RUSTUP_HOME"
  && chmod -R a+rwX /app`. a+rX did NOT break the offline non-root build (target/ under /app stays writable);
  no CARGO_HOME relocation needed. O2: --output_path=VALUE arg form. O3: <testsuites/> stub after mkdir.
- Validation: build clean 0 warnings; feature suite 28/28 (incl T1/T2/T3/T4); baseline 1025/0 via nextest;
  eff-LOC 560; grep crate::merge empty; 0 added comments in sol+test; no merge_at in solution.
- 6-cell offline (--network=none --user 1000:1000) all green: SOL new 28/0 rc0; SOL base 1025/0 rc0;
  BASE new build-fail->fallback 28 names rc1; BASE base 1025/0 rc0; stale-junit stub overwrite verified;
  5th cell BASE+test no-feature cargo build --all-targets clean + nextest --lib 1025.

## Reviewer revision applied (2026-07-02) -- 13/15 exact + 2 documented deviations
Applied all surrealkv reviewer items (S1,S2,S3,S4a,S4b,S6,T1,T2,T3,T4,O2,O3,O5) exactly; either/or items took the
reviewer's preferred branch (S2 keep-separate, S6 document, S3 preserve+confirm). Validated: build clean, feature 28/28,
baseline 1025, 6-cell offline+non-root green, eff LOC 560. New fingerprint sol=1e9c2665 test=52c8e4f9 meta=5511e98e
docker=f9cdffb5 base=15c3540f.
DEVIATION 1 (O1 chmod): reviewer said "drop CARGO_HOME/RUSTUP_HOME from the chmod". Literal drop leaves /root/.cargo &
/root/.rustup unreadable by uid 1000 -> offline non-root build FAILS (toolchain + prefetched registry live there). Used
`chmod -R a+rX "$CARGO_HOME" "$RUSTUP_HOME"` (read-only, not writable) instead: meets the security intent (nothing
world-writable, cargo not agent-replaceable; binaries copied via install -m 0755) while keeping the build working.
Validated as uid 1000 offline.
DEVIATION 2 (O4, reviewer-optional): did NOT move the [features] merge_op_tests hunk to solution.patch. Reviewer marked
it "low priority, move if you want". Declined: a Cargo feature defined only in solution.patch forces the agent to add an
undocumented feature for the F2P test to compile = compile-coupling unfairness. Kept in test.patch (isolation works:
base passes no --features, new passes it, patches disjoint).
EXCLUDED: feedback-file lines 22-38 are a DIFFERENT task's review (Go graph lib: go test/pagerank/betweenness/max-flow),
not surrealkv -- none applied.
NOTE: all 4 deliverables changed + tests stricter ({5,8} enforced + 3 new edges) -> pass rate will move; re-eval required
to reconfirm >=1 pass / ~10% / solver-median >100.

## Pre-checks (2026-07-02, on revised build sol=1e9c2665) -- 3 WARNINGS, all bypassed/ignored, no deliverable change
1. Dockerfile Cargo.lock reproducibility WARNING: false positive, surrealkv commits Cargo.lock; IGNORE.
2. problem_and_tests quality WARNING (pinned_reader touches tree.core.seq_num / commit_pipeline.set_seq_num for the
   MVCC pinned-snapshot setup): those are EXISTING surrealkv fields (present at BASE, not agent-provided) so no
   compile-coupling / hidden requirement; assertions stay behavioral; human reviewer did not object. IGNORE (rewriting
   risks perturbing mvcc_as_of).
3. description_conciseness HIGH (request_changes): BYPASS -- applying it would DELETE tested + human-reviewer-mandated
   behavior ({5,8} put-stays-separate example, get_at timestamp clause -> now assert_eq!{5,8} + get_at tests) =>
   hidden requirements = Test-Fairness reject. Keeping description<->test alignment overrides the conciseness suggestion
   (documented necessary-info trap). Bypass paragraph recorded. No deliverable edits.

## SECOND-round reviewer feedback applied (2026-07-02) -- TEST-ONLY, Tests 2/3 Minor -> addressed
Round-2 review: Description 3/3 Clean, Solution & Code 3/3 Clean, Tests 2/3 Minor (first-round revision succeeded).
All asks are test additions; solution/meta/Dockerfile UNCHANGED (sol=1e9c2665 meta=21b1a5b6 docker=f9cdffb5). Reference
required NO change (3/3) -- every new assertion passes against it.
- R2-1 (main): mvcc_as_of pinned-snapshot fixture extended to ALL 4 read paths -- s0 excludes the later add(1000) on
  get_at(20)/fwd scan[20]/bwd scan[20]/history(has 20 not 1020); live tree reflects 1020 on all four.
- R2-2 (main): absent_base_zero extended to get_at + both scans (fold-onto-0; versioned tree add7 -> get_at/scan = 7).
- R2-3a: delete_resets_then_merge extended to get_at/scan/history (all = 3; put 5 + delete superseded, history {3}).
- R2-3b: added order-preserving hist_vec helper; history_fold_fwd_bwd now asserts exact fwd order [8,5] AND bwd == reversed
  (catches a wrong-direction backward iterator that a BTreeSet would hide).
- R2-3c: model_equivalence pinned to a deterministic proptest RNG seed (TestRng::deterministic_rng, failure_persistence None).
28 feature tests (assertions added within existing tests, no new fn -> NEW_TESTS unchanged). Build clean, 28/28 feature,
1025 baseline, zero comments, full offline+non-root 6-cell GREEN, F2P names aligned. NEW test.patch=0a0f7505.
NOTE: test.patch changed -> fingerprint moved; a re-eval on sol=1e9c2665 test=0a0f7505 meta=21b1a5b6 now covers BOTH the
get_at meta-hardening AND these round-2 tests (both push difficulty up slightly -> helps the ~10% target).

## JUnit precheck FAIL fixed (2026-07-02) -- test.sh only, on the reverted build
User chose fix. Re-applied ONLY the JUnit find-discovery fix (no coverage tests): test.sh now uses
`find target/nextest -name junit.xml` (stale guard + both copy blocks) instead of the hardcoded path the checker misread.
Dockerfile Cargo.lock WARNING ignored (committed lockfile); description_conciseness request_changes BYPASSED (human 3/3).
solution/meta/docker byte-identical (sol=1e9c2665 meta=21b1a5b6 docker=f9cdffb5); 28 tests; zero coverage tests; zero
comments; full offline+non-root 6-cell GREEN (Cell 1 copies the REAL junit via find, Cell 5 stale-guard clean).
NEW test.patch=57eb875b.
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=57eb875b73f502cb862ac268ce9faa21aa2ac9f8 meta=21b1a5b6d35a3eb631e17a0f5b8e7c0688a1d4d2 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c

## Advisory coverage suggestions -- selective (2026-07-02): applied ONLY #2 (byte shape)
3 new advisory coverage suggestions; user asked to apply only what's actually needed.
- #1 Operand validation -> SKIP: reference does not reject malformed operands at write time (fold tolerates unknown
  opcode via `_ => acc` and length checks); asserting rejection + pinning error semantics would reopen the 3/3 solution
  AND meta and is a hidden-requirement risk. Not warranted for an advisory item.
- #3 Same-tx put barrier -> SKIP: the put-barrier rule is already covered by later_put_replaces (committed); uncommitted
  variant is derivable + advisory (and was reverted before).
- #2 Returned byte shape -> APPLIED: meta promises reads return an 8-byte LE u64 but tests only read_u64 the first 8 bytes.
  Added folded_reads_are_8_bytes (versioned put(5)+add(10)+min(8)) asserting len()==8 on get/get_at/scan_fwd/scan_bwd and
  every history entry (empirically 8 on all paths against the 3/3 reference; no solution change). 29 feature tests.
solution/meta/docker byte-identical (sol=1e9c2665 meta=21b1a5b6 docker=f9cdffb5); zero comments; JUnit find-fix retained;
full offline+non-root 6-cell GREEN. NEW test.patch=2b31cb42.
Fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=2b31cb42b5c3b4be5dbae26556e10126ceef20df meta=21b1a5b6d35a3eb631e17a0f5b8e7c0688a1d4d2 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c

## APPROVED — human reviewer (surrealkv merge operator, Rust)
Human reviewer APPROVED: Problem Description 3/3 Clean, Solution & Code 3/3 Clean, Tests 2/3 Minor (non-blocking).
Final eval: 1/10 PASS_LEGITIMATE (Orion solver, 245 msgs / 1106 LOC / 9 files) = exactly 10%; solver-median messages
245 >> 100 floor; 9 fails scattered (7 missed-requirement, 2 regression). All Olympus gates met on the approved build.
Approved deliverables fingerprint: sol=1e9c2665a477550caac7683d8c5d8d7dec9670d9 test=2b31cb42b5c3b4be5dbae26556e10126ceef20df meta=21b1a5b6d35a3eb631e17a0f5b8e7c0688a1d4d2 docker=f9cdffb5d309ba94c8048b183b1e18bb6aae4e58 base=15c3540f15c46ee6a8b47097331881db9b6f0d6c
Feature = read-modify-write merge operator completing surrealkv's reserved InternalKeyKind::Merge placeholder: 9-byte
self-describing operand (op 0=add/1=min/2=max + u64 LE), folded onto the base across every read path (get, timestamped
get_at, fwd/rev scans, version history with put-stays-own-entry + run-collapse), RYOW incl history, MVCC snapshot
boundary, and versioned compaction that preserves per-operation groups so get_at reconstructs intermediates.
Reviewer's 3 non-blocking Tests suggestions (interleaved put/run/put/run history; get_at with put+merge sharing a
timestamp; min on absent/deleted base) were NOT applied post-approval (advisory, approval already granted).
Reviewer revision history: round-1 required the {5,8} two-entry history semantics (put stays its own entry beside the
folded run) + strict assert_eq tests + Dockerfile/test.sh hardening; round-2 (Tests Minor) added snapshot-isolation
across all 4 read paths, absent-base on get_at/scans, delete-on-all-paths, an ordered (Vec) history assertion, and a
pinned proptest seed. Final adds: JUnit find-discovery in test.sh + a folded-reads-are-8-bytes coverage test.
