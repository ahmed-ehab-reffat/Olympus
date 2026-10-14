# macs-callvar-fragment-phasing - eval results

No platform batch yet (slice stage).

## Local validation

| Date | Check | Result |
|---|---|---|
| 2026-09-29 | docker build --no-cache (cold, olympus-base-python) | 4m49s |
| 2026-09-29 | clean room uid 1000, --network none, test.patch only: base | 117 passed, 4 skipped (rc 0) |
| 2026-09-29 | same, new | 8 failed of 8 (rc 1, unknown option --pair-aware) |
| 2026-09-29 | + solution.patch: new | 8 passed (rc 0), extensions rebuilt in place, `macs3 callvar --help` shows --pair-aware |
| 2026-09-29 | + solution.patch: base | 117 passed, 4 skipped (rc 0) |
| 2026-09-29 | new mode as root | 8 passed |
| 2026-09-29 | hook human-effective (solution.patch) | 289 (raw 306), 6 files |
| 2026-09-29 | mutant: unitig path per-read | indel-peak test fails; -F on output unphased, per-read depth |
| 2026-09-29 | mutant: Variant state tuple without new fields | 8/8 fail |
| 2026-09-30 | rebuilt image (macs-cv-val), clean room --network none, test.patch only: new | 10 failed of 10 |
| 2026-09-30 | + OLD solution.patch: new | 9 passed, 1 failed (uncalled-allele test: BAS/BAR) |
| 2026-09-30 | + fixed solution.patch: new / base, uid 1000 x2, 0, 4242 | 10/10 and 121 cases (117 + 4 skipped), identical all 4 runs |
| 2026-09-30 | hook human-effective | 291 (raw 308), 6 files |
| 2026-09-30 | round 4 tests (14): test.patch only | 14 failed of 14 |
| 2026-09-30 | + solution.patch, uid 1000 / 0 / 4242 | 14/14 new, 121 base cases, identical all 3 |
| 2026-09-30 | mutants: tie joins / no control votes / 1/2 swapped / no mate drop | each kills its new test only (no mate drop also kills mates_that_disagree) |
| 2026-10-01 | Auto Review round (17 tests): test.patch only | 17 failed of 17 |
| 2026-10-01 | + solution.patch (8 files incl. docs), uid 1000 / 0 / 4242 | 17/17 new, 121 base cases, identical all 3 |
| 2026-10-01 | mutants: mate first-q, block first/last/min q, no heter_unsure, third-as-high | each fails only its target test |
| 2026-10-01 | simulated extension build failure | rc 1, all 17 cases carry the build log |
| 2026-10-01 | hook human-effective | 309 (docs add 18) |
| 2026-10-01 | Auto Review round 2 (20 tests): test.patch only | 20 failed of 20 |
| 2026-10-01 | + solution.patch (unchanged), uid 1000 / 0 / 4242 | 20/20 new, 121 base cases, identical all 3 |
| 2026-10-01 | mutants: PS from predecessor, two-call block model, phase every non-0/0 call | each fails only its target test |
| 2026-10-01 | Test Quality fix (insertion cardinality pin removed): test.patch only | 20 failed of 20 |
| 2026-10-01 | + solution.patch, uid 1000 / 0 / 4242 | 20/20 new, 121 base cases, identical all 3 |
| 2026-10-01 | mutant: unitig path per-read | still fails the unitig test |

Flakiness: 3 identical runs of new + base on the final patches (2026-10-01, round 3).

## Batch 1 (2026-10-01, 10x Nova, Auto Review APPROVED: description 3/3, tests 2/3, solution 3/3)

Pass rate 9/10 = 90% (ceiling 50%): TOO EASY. Median 97 tool calls (floor 40).

| Run | Verdict | Tool calls | +lines | Files | Failed tests | Note |
|---|---|---|---|---|---|---|
| Nova #10 (dir 1) | PASS | 85 | 520 | 7 | - | added own test file |
| Nova #9 (dir 2) | PASS | 102 | 444 | 6 | - | |
| Nova #8 (dir 3) | FAIL_MISSED_REQUIREMENT | 75 | 534 | 8 | block_reports_allele_specific_model_and_ratio, uncalled_allele_keeps_fragment_out_of_both_haplotypes, three_call_block_is_annotated_as_one_block | block haplotypes use unphased low/high side, ignores flips |
| Nova #7 (dir 4) | PASS | 83 | 532 | 8 | - | |
| Nova #6 (dir 5) | PASS | 114 | 411 | 7 | - | |
| Nova #5 (dir 6) | PASS | 93 | 512 | 7 | - | |
| Nova #4 (dir 7) | PASS | 108 | 529 | 7 | - | new module PairAware.py |
| Nova #3 (dir 8) | PASS | 101 | 557 | 8 | - | |
| Nova #2 (dir 9) | PASS | 90 | 606 | 8 | - | |
| Nova #1 (dir 10) | PASS | 119 | 517 | 6 | - | |

## Harden round 1 validation (2026-10-01)

| Check | Result |
|---|---|
| test.patch only, new | 25 failed of 25 |
| + solution.patch, uid 1000 / 0 / 4242 | 25/25 new, 121 base cases, identical all 3 |
| batch-1 solutions + adjacent reference vs new suite | each fails the 2 non-adjacent tests (runs 3, 8 also their earlier kills) |
| mutant: strongest earlier link instead of nearest | fails only call_joins_its_nearest_linked_call |
| hook human-effective | 314 |

## Batch 2 (2026-10-01, 10x Nova, nearest-earlier linking meta, 25 tests; Auto Review APPROVED, tests 2/3 for -Q)

Pass rate 6/10 = 60% (ceiling 50%): still TOO EASY. Median ~97 tool calls.

| Run | Verdict | Calls | +lines | Failed | Cause |
|---|---|---|---|---|---|
| Nova #10 (dir 1) | FAIL | 83 | 632 | 6 (3 block-model + 3 linking) | block haplotypes ignore phase orientation (GT/PS correct) |
| Nova #9 (dir 2) | PASS | 99 | 592 | - | |
| Nova #8 (dir 3) | PASS | 113 | 598 | - | |
| Nova #7 (dir 4) | FAIL | 78 | 552 | 16 | phased GT written as bases (A\|C) |
| Nova #6 (dir 5) | PASS | 80 | 528 | - | |
| Nova #5 (dir 6) | FAIL | 80 | 565 | 6 | same orientation defect as #10 |
| Nova #4 (dir 7) | PASS | 103 | 607 | - | |
| Nova #3 (dir 8) | PASS | 105 | 502 | - | |
| Nova #2 (dir 9) | PASS | 96 | 637 | - | |
| Nova #1 (dir 10) | FAIL | 91 | 472 | 1 | renamed BICHOMOMINOR (agent regression) |

Probes (old set + 6 linking probes + -Q 30 at 29/30/31) vs the 6 passers: ZERO divergence. The
linking rule killed nobody independently (runs 1 and 6 match the reference GT/PS on every probe).

## Harden round 2 validation (2026-10-02)

| Check | Result |
|---|---|
| test.patch only, new | 28 failed of 28 |
| + solution.patch, uid 1000 / 0 / 4242 | 28/28 new, 121 base cases, identical all 3 |
| mutants: read-level dedup / no dedup / cross-file copies / inclusive -Q | 2 / 2 / 1 / 1 target tests fail, nothing else |
| hook human-effective | 335 |
| meta.md | 377 words, ASCII |

## Auto Review fix validation (2026-10-03, 31 tests)

| Check | Result |
|---|---|
| test.patch only, new | 31 failed of 31 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 31/31 new, 121 base cases, identical all 3 |
| mutant: duplicate key without CIGAR | fails only duplicate_key_includes_the_cigar |

## Batch 3 (2026-10-03, 10x Nova on the 399-word meta, graded in re-eval 1 with 32 tests)

| Run | Verdict | Calls | +lines | Failed |
|---|---|---|---|---|
| Nova #10 (dir 1) | PASS, FP-VOIDED | 135 | 579 | - (orients a joining site from the block's last-added member, not its parent) |
| Nova #9 (dir 2) | FAIL | 142 | 569 | peak-end key only |
| Nova #8 (dir 3) | FAIL | 112 | 465 | peak-end key only |
| Nova #7 (dir 4) | FAIL | 95 | 509 | peak-end key only |
| Nova #6 (dir 5) | FAIL | 90 | 514 | 7 (BAS orientation family + peak-end) |
| Nova #5 (dir 6) | FAIL | 101 | 657 | 8 (BAS + all duplicate tests + peak-end) |
| Nova #4 (dir 7) | FAIL | 96 | 570 | 7 (BAS orientation family + peak-end) |
| Nova #3 (dir 8) | FAIL | 105 | 496 | peak-end key only |
| Nova #2 (dir 9) | FAIL | 125 | 641 | 17 (phasing broadly) |
| Nova #1 (dir 10) | FAIL | 129 | 598 | peak-end key only |

Replay over these 10 solutions (local, Docker):
- + call_takes_its_order_from_the_call_it_joined (FP fix): 0/10; run 1 fails only the new test.
- same minus the peak-end test: 5/10 (dirs 2, 3, 4, 8, 10), none has the parent bug.

## Batch 4 (2026-10-04, 10x Nova, 399-word meta with peak-end cap, 32 tests)

Pass rate 7/10 = 70% (ceiling 50%): TOO EASY.

| Run | Verdict | Calls | +lines | Failed |
|---|---|---|---|---|
| Nova #10 (dir 1) | PASS | 132 | 634 | - |
| Nova #9 (dir 2) | PASS | 121 | 655 | - |
| Nova #8 (dir 3) | FAIL | 84 | 601 | 18 (phasing broadly) |
| Nova #7 (dir 4) | PASS | 70 | 560 | - |
| Nova #6 (dir 5) | FAIL | 91 | 557 | 6 (BAS orientation family) |
| Nova #5 (dir 6) | PASS | 116 | 535 | - |
| Nova #4 (dir 7) | PASS | 64 | 692 | - |
| Nova #3 (dir 8) | PASS | 78 | 653 | - |
| Nova #2 (dir 9) | FAIL | 95 | 593 | 3 (BAS orientation + nearest) |
| Nova #1 (dir 10) | PASS | 68 | 602 | - |

## Round after batch 4 (2026-10-04): two stated gaps, 34 tests

| Check | Result |
|---|---|
| test.patch only, new | 34 failed of 34 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 34/34 new, 121 base cases, identical all 3 |
| replay of batch-4 solutions | 5/10 pass (dirs 1, 2, 4, 7, 10); new kills: dir 6 (disagreeing mates), dir 8 (copy order under -F on) |
| meta.md | 395 words, ASCII |

## Auto Review fix validation (2026-10-04, 36 tests)

| Check | Result |
|---|---|
| test.patch only, new | 36 failed of 36 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 36/36 new, 121 base cases, identical all 3 |
| mutants: recall call per-read / keep-last copies / first-site haplotype | each fails its target test |
| replay of batch-4 solutions | 5/10 pass (dirs 1, 2, 4, 7, 10); dir 6 = disagreeing mates, dir 8 = reference-biased recall per-read |

## Auto Review fix validation (2026-10-04, 38 tests, half-open peak rule)

| Check | Result |
|---|---|
| test.patch only, new | 38 failed of 38 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 38/38 new, 121 base cases, identical all 3 |
| mutant: unitig path keeps first qualifying observation per name | fails only mate_resolution_is_the_same_on_unitigs |
| replay of batch-4 solutions | 5/10 (dirs 1, 2, 4, 7, 10); the restored peak-end test and the unitig test catch none of them |
| meta.md | 397 words, ASCII |

## Auto Review fix validation (2026-10-04, 39 tests, control-side coverage)

| Check | Result |
|---|---|
| test.patch only, new | 39 failed of 39 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 39/39 new, 121 base cases, identical all 3 |
| mutants: unitig control per read / control keeps first observation | each fails only control_mates_resolve_the_same_in_every_mode |
| replay of batch-4 solutions | 5/10 (dirs 1, 2, 4, 7, 10), unchanged |

## Auto Review fix validation (2026-10-04, 40 tests, --max-ar in the block model)

| Check | Result |
|---|---|
| test.patch only, new | 40 failed of 40 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 40/40 new, 121 base cases, identical all 3 |
| mutant: block model called with 0.95 | fails only block_model_uses_the_max_ar_bound |
| replay of batch-4 solutions | 5/10 (dirs 1, 2, 4, 7, 10), unchanged |
| meta.md | 399 words, ASCII |

## Batch 6 (2026-10-05, 10x Nova on the 399-word meta with --max-ar, 40 tests)

Wrapper 5/10 (dirs 1, 2, 5, 9, 10); FP panel voided 4 (dirs 5, 10 and two of 1/2/9) -> 1/10 legitimate.
Failures: dir 3 (21, phasing broadly), dir 4 (control_outlier_drops_only_its_own_mate), dir 6
(call_takes_its_order_from_the_call_it_joined), dir 7 (unitig/ref-biased recall x3), dir 8 (11).

## FP-fix round validation (2026-10-05, 44 tests, meta 393 words)

| Check | Result |
|---|---|
| test.patch only, new | 44 failed of 44 |
| + solution.patch (unitig deletion coverage by alignment interval), uid 1000 / 0 / 4242 | 44/44 new, 121 base cases, identical all 3 |
| mutants: unsorted copy key / unitig deletion without coverage | each fails only its target test |
| replay of batch-6 solutions | 0/10 (dirs 1, 2, 9: deletion test only; dir 5: outlier pool + order + deletion; dir 10: mate-order key) |

## Batch 7 (2026-10-05, 10x Nova, graded in re-eval 1 with 44 tests)

Wrapper 3/10 (dirs 2, 6, 10); FP panel voided 2 (indel calls never phased: VCF REF/ALT strings
compared to single-position observations) -> 1/10 legitimate.
Failures: dirs 1, 3, 4, 5, 8 fail the same 21 tests = only the FIRST site of each block phased,
later block sites left 0/1. Root cause: meta trim "sites outside blocks keep the / genotype" ->
"other sites keep the / genotype" (read as the block's other sites). dir 9: GT as bases (A|C).
dir 7: uncalled allele dropped instead of excluding the fragment (1 test).

## Batch-7 fix validation (2026-10-05, 46 tests, meta 397 words)

| Check | Result |
|---|---|
| test.patch only, new | 46 failed of 46 |
| + solution.patch (unchanged), uid 1000 / 0 / 4242 | 46/46 new, 121 base cases, identical all 3 |
| mutant: no half-open filter | fails both peak-end tests |
| replay of batch-7 passers (dirs 2, 6, 10) | all fail deletion_phases_with_a_linked_snv (now stated in meta) |

## Batch 8 (2026-10-06, 10x Nova on the 397-word meta, graded in re-eval 1 with 46 tests)

Wrapper 1/10 (dir 2), FP-voided (unitig path filters read list by span but zips against unfiltered
quality arrays; stub probe with a repeated sequence) -> 0/10 legitimate.
Single-test near-misses: dir 1 (deletion phasing), dir 3 (mate-order key), dir 5 (uncalled allele),
dir 7 (low_quality_mate_is_ignored: reimplemented outlier percentile, also dirs 6/9).
Others: dir 4 (2), dir 6 (21), dir 8 (12), dir 9 (6), dir 10 (4).

## Scope-down validation (2026-10-06, 46 tests, meta 388 words)

| Check | Result |
|---|---|
| test.patch only, new | 46 failed of 46 |
| + solution.patch (fermi forced off under --pair-aware), uid 1000 / 0 / 4242 | 46/46 new, 121 base cases, identical all 3 |
| mutant: assembly left on under --pair-aware | fails 7 tests (every -F on/auto test) |
| hook human-effective | 314 (7 files) |

## Batch 9 (2026-10-08, 10x Nova on the scoped 388-word meta: fermi skipped under --pair-aware)

| Run | Verdict | Calls | +lines | Failed |
|---|---|---|---|---|
| Nova #10 (dir 1) | PASS, FP genuine | 94 | 544 | - |
| Nova #9 (dir 2) | PASS, FP-VOIDED (-D 0 treated as unlimited) | 65 | 639 | - |
| Nova #8 (dir 3) | FAIL | 84 | 664 | uncalled allele, deletion phasing |
| Nova #7 (dir 4) | PASS, FP genuine | 53 | 442 | - |
| Nova #6 (dir 5) | FAIL | 76 | 637 | 4 (BAS built per site, not block-wide best quality) |
| Nova #5 (dir 6) | FAIL | 67 | 546 | 21 |
| Nova #4 (dir 7) | PASS, FP genuine | 62 | 561 | - |
| Nova #3 (dir 8) | FAIL | 79 | 449 | same 4 as dir 5 |
| Nova #2 (dir 9) | FAIL | 64 | 653 | same 4 |
| Nova #1 (dir 10) | FAIL | 74 | 630 | same 4 |

Wrapper 4/10, legitimate 3/10 (30%). Tests-only fix: test_zero_duplicate_limit_keeps_no_fragment
(-D 0 under --pair-aware gives no calls). Replay: only dir 2 fails it; dirs 1, 4, 7 pass 47/47.
Re-eval projection: 3/10 with an FP-clean pass set.

## Batch 10 (2026-10-09, NEW MODELS, after the admin revert; 5x Nova, current meta/tests/solution)

| Run | Verdict | Steps | Seq length | Failed |
|---|---|---|---|---|
| Nova #4 (dir Nova_Nova_1) | PASS_LEGITIMATE | 188 | 539,929 | - |
| Nova #3 (dir Nova_Nova_2) | PASS_LEGITIMATE | 214 | 545,948 | - |
| Nova #2 (dir Nova_Nova_3) | FAIL | 198 | 533,092 | uncalled_allele_keeps_fragment_out_of_both_haplotypes, zero_duplicate_limit_keeps_no_fragment |
| Nova #1 (dir Nova_Nova_4) | PASS_LEGITIMATE | 243 | 613,158 | - |
| Nova #4 (dir Nova_Nova_5, 2nd run labelled #4) | FAIL | 237 | 542,295 | zero_duplicate_limit_keeps_no_fragment |

Nova 3/5. New gate needs Nova 0/8: too easy. Nova avg sequence length 554,884 (> 256k, OK).
Local replay matches the platform exactly. Probe set (27 probes, probe_zz*.py) on the 3 passers vs
reference: zero divergence. Passers aggregate control block quality the same way as treatment
(max per fragment), so the control-quality coverage suggestion would kill nobody.

## Cross-peak round validation (2026-10-09, not yet batched)

| Check | Result |
|---|---|
| test.patch only, new | 54 failed of 54 |
| + solution.patch, uid 1000 / 0 / 4242 | 54/54 new, 121 base cases, identical all 3 |
| flakiness (3 more new-mode runs) | 54/54 each |
| batch-10 runs (all 5) + old per-peak reference | fail 7 cross-peak tests each |
| mutants: per-peak dedup / per-peak mate drop / pooled cutoff | killed (1 / 4 / 1 tests) |
| hook human-effective | 345 (7 files) |

## Batch 11 (2026-10-10, 7x Nova on the cross-peak meta, 54 tests)

| Run | Verdict | Steps | Seq length | Failed |
|---|---|---|---|---|
| Nova_Nova_1 | FAIL | 188 | 593,613 | deletion_phases_with_a_linked_snv (re-observes reads at shifted deletion coords) |
| Nova_Nova_2 | PASS_LEGITIMATE | 172 | 617,083 | - |
| Nova_Nova_3 | FAIL | 221 | 533,163 | uncalled_allele_keeps_fragment_out_of_both_haplotypes |
| Nova_Nova_4 | FAIL | 172 | 530,780 | uncalled_allele |
| Nova_Nova_5 | FAIL | 237 | 519,884 | uncalled_allele, zero_duplicate_limit |
| Nova_Nova_6 | FAIL | 206 | 597,177 | control_outlier_drops_only_its_own_mate (names pooled across files), 2 deletion tests (pv.refseq crash) |
| Nova_Nova_7 | FAIL | 134 | 619,995 | uncalled_allele |

Nova 1/7; avg seq length 573,099. Cross-peak tests killed nobody on their own (all 7 implemented the
chromosome pre-pass). Run 2 matches the reference on 27 probes and on every cross-peak filter rule;
its own re-observation helper returns "no allele" for a third base at a deletion site.
Tests-only lever: test_uncalled_base_at_a_deletion_keeps_fragment_off_both_haplotypes (deletion+SNV
block; 4 fragments carry S1 alt and a third base at DEL_POS -> neither haplotype). Replay: all 7 fail
it; run 2 fails only it. Re-eval projection: Nova 0/7.
Validation (55 tests): tests-only 55/55 fail; with solution 55/55 new + 121 base as uid 1000/0/4242;
two more flakiness runs 55/55.

## Batch 12 (2026-10-10, 8x fresh Nova, 55 tests incl. deletion uncalled-base)

| Run | Verdict | Steps | Seq length | Failed |
|---|---|---|---|---|
| Nova #8 (dir 1) | FAIL | 191 | 544,587 | 2 deletion tests (fix_indels KeyError), UA, UB |
| Nova #7 (dir 2) | FAIL | 190 | 622,969 | UA, UB |
| Nova #6 (dir 3) | FAIL | 217 | 539,109 | UA, UB |
| Nova #5 (dir 4) | FAIL | 204 | 522,246 | deletion_phases, duplicate_key_takes..every_peak, UA, UB, zero_duplicate_limit |
| Nova #4 (dir 5) | PASS_LEGITIMATE | 174 | 532,644 | - |
| Nova #3 (dir 6) | FAIL | 116 | 553,881 | UA, UB |
| Nova #2 (dir 7) | FAIL | 190 | 531,326 | UA, UB |
| Nova #1 (dir 8) | FAIL | 195 | 736,838 | UA, UB |

UA = uncalled_allele_keeps_fragment_out_of_both_haplotypes, UB = uncalled_base_at_a_deletion_keeps...
Nova 1/8; avg seq length 572,950. Run 5: 27 probes identical to the reference; passes the new
T3/T4 BAR test (treatment-only ratio). Divergence found: run 5 reads every deletion record's fragment
evidence from position p+1, right only when fix_indels shifted the record to p-1. A 1-base deletion
straight after a het SNV call stays at p (REF base, ALT *), and run 5 leaves it 0/1; the reference
phases it (probe_zz4 del1_after_snv). Tests added (tests-only):
test_block_ratio_counts_treatment_fragments_only (T3/T4 finding),
test_deletion_right_after_a_snv_call_joins_the_block.
Replay with 57 tests: batch 12 0/8 (dir 5 fails only deletion_right_after_a_snv_call_joins_the_block,
which also hits dirs 2 and 3); batch 11 0/7. Validation: tests-only 57/57 fail; with solution 57/57
new + 121 base as uid 1000/0/4242; two more flakiness runs 57/57.

## Batch 13 (2026-10-10): re-eval of batch 12 Nova x8 on 57 tests + Orion x6 fresh

| Run | Verdict | Failed tests |
|---|---|---|
| Nova #8..#1 (re-eval) | FAIL x8 | UA+UB on 7; run 5 only deletion_right_after_a_snv |
| Orion #2 (Orion_Nova_1) | FAIL | UA, deletion_right_after_a_snv |
| Orion #1 (Orion_Nova_2) | PASS, FP-flagged | own deletion normalizer: 2-3 bp REF truncated, gap-SNV deletion not shifted |
| Orion #4 (Orion_Nova_3) | FAIL | UA, UB |
| Orion #3 (Orion_Nova_4) | FAIL | deletion_right_after_a_snv |
| Orion #2 (Orion_Nova_5) | FAIL | deletion_right_after_a_snv |
| Orion #1 (Orion_Nova_6) | FAIL | deletion_right_after_a_snv |

Nova 0/8; Orion 1/6 before the FP void (0/6 after). Task Prompt Quality then FAILed on requirement
count, so the scope was cut (meta change, full batch needed). Replay of all 29 saved runs on the cut
37-test suite: every run fails, but the read-level filter tests fail all of them because they built the
old meta's whole-fragment filters (a description delta, not difficulty). Still meaningful: UA/UB kill the
same runs, deletion_right_after_a_snv the same runs, and the new deletion-record test hits all 6 Orion runs
plus batch-11 runs 1, 6 and batch-12 runs 1, 4.
Final cut validation (matrix20): tests-only 37/37 fail; with solution 37/37 new + 121 base as uid
1000/0/4242; two flakiness runs 37/37. Solution 7 files, 291 insertions, 265 human-effective.
Auto Review fixes (41 tests): the first version of test_control_mates_count_once_per_site killed all 29
saved runs off by one (DPC 20 vs 21) because a discordant control read carried 2 edits and hit the outlier
rule; rebuilt with a deterministic control fixture (no read over 1 edit, asserted). Final replay: the 4 new
tests kill 0 of 29 saved runs; mutant "control keyed by read index" fails both control tests. matrix22:
tests-only 41/41 fail; with solution 41/41 new + 121 base as uid 1000/0/4242; two flakiness runs 41/41.

## Batch 14 (2026-10-11): fresh 8 Nova + 4 Orion, 41 tests, cut meta

| Run | Verdict | Failed tests | Steps |
|---|---|---|---|
| Nova #1..#8 | FAIL x8 | the same 15 on every run: no fragment counting at all (overlapping/disagreeing/low-quality mates, -Q cutoff, best quality, control counting, outlier, -D, reference-biased, unpaired, insertion counts, deletion counts, flag-off) + UA + UB | 130-188 |
| Orion #4 (Orion_Orion_1) | PASS, FP genuine | - | |
| Orion #3 (Orion_Orion_2) | FAIL | UA, UB | |
| Orion #2 (Orion_Orion_3) | FAIL | UB | |
| Orion #1 (Orion_Orion_4) | PASS, FP genuine | - | |

Nova 0/8; Orion 2/4 (too easy). Both passers use the same resolver (first-seen on equal quality, strict
>), both carry fragment counting into the unitig/assembly path, both keep evidence per chromosome. Probes:
zz/zz2/zz3 (27), zz4 (6), zz7 block-scope (5): 0 divergence for both passers; only Orion #3 differs
(different insertion sequence at an insertion call). zz6 assembly probes: both passers identical to each
other, differ from a base-faithful reference only on a 2 bp deletion under -F auto/on (they skip unitig reads
whose position falls outside the read; base counts every read in the unitig). No fair test splits them.
The deletion-after-SNV test killed 4/6 Orion in batch 13 and 0/4 here: the records sentence added for the
batch-13 FP tells agents to reuse callvar's deletion records.
Final validation (matrix26): tests-only 43/43 fail; with solution 43/43 new + 121 base as uid 1000/0/4242; two flakiness runs 43/43. Installed.
Test Quality fix validation (matrix27): tests-only 44/44 fail; with solution 44/44 new + 121 base as uid 1000/0/4242; two flakiness runs 44/44. b14/b15 Orion replay unchanged (passers 44/44, failers UA/UB only). Installed.

## Batch 16 (2026-10-11): 4 Orion + 4 Vega, 44 tests, meta without the records sentence

| Run | Verdict | Failed tests |
|---|---|---|
| Orion #4, #3, #2 | PASS x3 (FP check pending) | - |
| Orion #1 | FAIL | UA |
| Vega #1..#4 | FAIL x4 | UA, UB (all drop third alleles before haplotype assignment, reusing the linkage filter) |

Orion 3/4 (too easy), Vega 0/4 (unsolvable on Vega). Deleting the records sentence did NOT bring the
deletion-after-SNV trap back: all 4 Orion reused fix_indels. Probes on the 3 passers (40 each): two identical
to the reference; Orion #4 differs only by anchoring gap deletions with the genome base (TCT/T vs base's
ACT/A), which Test Quality already ruled must not be pinned. No fair re-eval lever. The problem rests on one
trap (uncalled allele): Orion clears it ~60%, Vega 0%.
Strand-rule validation (matrix28): tests-only 45/45 fail; with solution 45/45 new + 121 base as uid 1000/0/4242; two flakiness runs 45/45. Installed.
Validation (matrix29): tests-only 48/48 fail; with solution 48/48 new + 121 base as uid 1000/0/4242; flakiness 48/48 x2; EOF blank line then stripped and re-checked 48/48. Installed.
Deletion-coverage fix validation (matrix30) clean; installed.

## Batch 17 (2026-10-11): 4 Orion, 48 tests, meta with the strand sentence

| Run | Folder | Verdict | Failed tests | FP panel |
|---|---|---|---|---|
| Orion #1 | Orion_Orion_4 | PASS | - | genuine |
| Orion #2 | Orion_Orion_3 | PASS | - | FALSE POSITIVE (crash on a peak without calls; read-2 strand when read 1 is outside all peaks) |
| Orion #3 | Orion_Orion_2 | PASS | - | genuine |
| Orion #4 | Orion_Orion_1 | FAIL | deletion_right_after_a_snv_call_joins_the_block | - |

Orion 3/4 on tests, 2/4 genuine. Approaches: #1, #3, #4 share a FragmentEvidence module (flag-based first-read
strand via 0x80/0x20, per-name collapse, chromosome phaser); #2 a PairAware module whose strand needs read 1 in the
collection. Nova runs: none saved for this batch.
Fix validation (matrix32): tests-only 51/51 fail; with solution 51/51 new + 121 base as uid 1000/0/4242; flakiness
51/51 x2. Replay of batch 17 on 51 tests: Orion #1 0 failures; #2 fails peak_without_calls + strand_outside_peaks;
#3 fails assembled_calls_count_one_molecule_per_read; #4 fails that and deletion_right_after_a_snv. Installed.

## Batch 18 (2026-10-13): 8 Nova (fresh) + re-eval of the batch-17 Orion runs, 51 tests

| Run | Verdict | Failed tests |
|---|---|---|
| Nova #1..#8 | FAIL x8 | all: uncalled_allele + uncalled_base_at_a_deletion; plus strand_outside_peaks (6), assembled_calls_count_one_molecule (5), deletion_right_after_a_snv (4), deletion_phases_with_local_assembly (2) |
| Orion #1 (re-eval) | PASS, FP genuine | - |
| Orion #2 (re-eval) | FAIL (regression) | peak_without_calls, strand_outside_peaks |
| Orion #3 (re-eval) | FAIL | assembled_calls_count_one_molecule_per_read |
| Orion #4 (re-eval) | FAIL | assembled_calls_count_one_molecule_per_read, deletion_right_after_a_snv |

Nova 0/8, Orion 1/4: gate met. Nova sequence length (max single step input+output): 269.0k-284.8k, mean ~276k (>256k).
Nova got much stronger than in b14 (3-5 failures each, down from 15); everything else is done right.
Auto Review: Revision Requested, Tests 1/3 (Description 3/3, Solution 3/3). Two High gaps: no assembled call with
overlapping treatment mates; no assembly fixture with control reads. Two Medium: opposing nonzero T/C link votes;
nonblock DP/GQ/PL values. Solution Quality PASS with a medium claiming the `< l_read - 1` guard drops terminal
called bases; it is false (the guard is only in the s == b'-' deletion branch), and Auto Review discarded the same lead.
Fix: 4 tests (55). Replay on 55: Orion #1 0 failures, the other runs keep their failures (Nova #8 also fails
assembled_control_fragments_vote_on_links) -> still Nova 0/8, Orion 1/4.
Validation (matrix33): tests-only 55/55 fail; with solution 55/55 new + 121 base as uid 1000/0/4242; flakiness 55/55 x2. Installed.

## Batch 19 (2026-10-13): re-eval of batch 18 on 55 tests — ACCEPTED

| Run (platform) | Verdict | Failed new | Failed tests | +LOC / files | seq len |
|---|---|---|---|---|---|
| Nova #8 | FAIL_MISSED_REQUIREMENT | 6/55 | UA, UB, del-after-SNV, del-local-assembly, strand-outside, assembled-control-votes | 911 / 9 | 521k |
| Nova #7 | FAIL_MISSED_REQUIREMENT | 3/55 | UA, UB, assembled-depth | 529 / 8 | 552k |
| Nova #6 | FAIL_MISSED_REQUIREMENT | 4/55 | UA, UB, strand-outside, assembled-depth | 515 / 8 | 540k |
| Nova #5 | FAIL_MISSED_REQUIREMENT | 4/55 | UA, UB, strand-outside, assembled-depth | 577 / 8 | 531k |
| Nova #4 | FAIL_MISSED_REQUIREMENT | 5/55 | UA, UB, del-after-SNV, strand-outside, assembled-depth | 684 / 9 | 521k |
| Nova #3 | FAIL_MISSED_REQUIREMENT | 5/55 | UA, UB, del-after-SNV, strand-outside, assembled-depth | 810 / 9 | 543k |
| Nova #2 | FAIL_MISSED_REQUIREMENT | 3/55 | UA, UB, strand-outside | 824 / 10 | 793k |
| Nova #1 | FAIL_MISSED_REQUIREMENT | 5/55 | UA, UB, del-after-SNV, del-local-assembly, strand-outside | 980 / 7 | 524k |
| Orion #4 | FAIL_MISSED_REQUIREMENT | 2/55 | del-after-SNV (BAR 1.00 vs 0.50), assembled-depth | 701 / 10 | - |
| Orion #3 | FAIL_MISSED_REQUIREMENT | 1/55 | assembled-depth (29 vs 30) | 694 / 10 | - |
| Orion #2 | FAIL_REGRESSION | 2/55 | quiet-peak (UnboundLocalError), strand-outside | 674 / 10 | - |
| Orion #1 | PASS_LEGITIMATE | 0/55 | - | 670 / 10 | - |

UA/UB = uncalled allele / uncalled base at a deletion kept off both haplotypes. Baseline 117/117 in every run.
Local replay of the saved patches (matrix33 era) matched every verdict.
