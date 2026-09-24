# DESIGN.md - macs-circular-chromosomes

## 0. Phase 1 - repo understanding

**Architecture (one paragraph).** MACS3 is a ChIP-seq/ATAC-seq peak caller written in Cython pure-Python
mode (`.py` files compiled to extensions at install). `macs3 callpeak` (bin/macs3 ->
`Commands/callpeak_cmd.py`) parses reads into tracks (`IO/Parser.py`: BAM/BAMPE/BED/... ->
`Signal/FixWidthTrack.FWTrack` for single-end cuts, `Signal/PairedEndTrack.PETrackI` for fragments),
optionally estimates the fragment length `d` from paired strand peaks (`Signal/PeakModel.py`), then
`Signal/PeakDetect.py` sets scaling and hands everything to `Signal/CallPeakUnit.CallerFromAlignments`.
The caller builds, per chromosome, a treatment pileup and a control lambda (max of the d/slocal/llocal
window pileups and the genome background) through the kernels in `Signal/PileupV2.py`, pairs them into
one `[pos, treat, ctrl]` chokepoint array, builds the genome-wide p->q table from ALL chromosomes
(`__cal_pvalue_qvalue_table` / `__pre_computes` for `--cutoff-analysis`), segments above-cutoff runs into
narrow peaks (optionally sub-peak summits) or broad two-level regions, and writes `IO/PeakIO.py`
outputs (narrowPeak, xls, summits.bed, broadPeak, gappedPeak) and the bedGraph tracks.

**Subsystems.** (1) IO parsers (`IO/Parser.py`), (2) tracks + pileup kernels (`FixWidthTrack`,
`PairedEndTrack`, `PileupV2`), (3) peak model (`PeakModel`), (4) scoring + segmentation
(`CallPeakUnit`, `PeakDetect`), (5) output (`PeakIO`, command writers) plus option validation
(`Utilities/OptValidator.py`, bin/macs3 argparse).

**High-entanglement zones.** `pileup_treat_ctrl_a_chromosome` (feeds pqtable, cutoff analysis,
narrow, summits, broad lvl1/lvl2, bedGraph); `fix_coordinates` clipping inside
`pileup_from_PN_shifted` (treatment SE + every control window); the segmentation loops (narrow,
cutoff analysis, broad lvl1, broad lvl2) that all special-case `above_cutoff_startpos[0] = 0`.

**Tests.** pytest under `test/` (113 pass / 4 skip in the container, ~100 s) plus the shell
`test/cmdlinetest` regression (not used in base mode: long, output-diff based). Formatting template:
`test/test_CallPeakUnit.py`, `test/test_PeakModel.py` (plain functions, fixtures built in code).

## 1. Title
Add circular chromosome support to MACS3 callpeak

## 2. Shape classification
- Shape: O-Pipeline-hard (new topology threaded through parse -> model -> pileup -> pqtable ->
  segmentation -> output; the "algorithm" is making every stage origin-free).
- Pass target: <= 40% ceiling, design aim 15-30%.
- Dominant verdict predicted: MISSED_REQUIREMENT on law cells (q-values / cutoff analysis / tracks).

## 3. Public API surface
- `macs3 callpeak --circular NAME[,NAME...]` (argparse option, default empty).
- Errors: `--circular` with a non-BAM/BAMPE format; a name absent from the BAM header.
- Output conventions: origin-crossing peak start in [0, L), end > L; summit positions (summits.bed,
  xls abs_summit) in [0, L); narrowPeak col 10 offset relative to start; bedGraph intervals in [0, L).

## 4. Canonical output form
- Peaks within a chromosome sorted by start; the origin-crossing peak is last.
- Law: rotating the reads of a circular chromosome by R rotates positions by R mod L and leaves every
  score, count (cutoff analysis) and the fragment length unchanged.
- Every position of a circular chromosome is scored (pileups cover [0, L); the pqtable total N = L).

## 5. Blind-spot pre-empts
Pipeline placement ("every position counts towards the genome-wide statistics, which includes the
q-value table and the cutoff analysis"); canonical form (start inside, end past length, summit on the
chromosome); ordering ("listed in order of start").

## 6. Description draft
See `meta.md` (329 words body).

## 7. File footprint (measured, reference = rebased spike + tail extension)
| File | human-eff |
|---|---|
| Signal/CallPeakUnit.py (rotation of runs in narrow / cutoff / broad lvl1 / lvl2, origin offset, lvl1 lift, summit padding without clip) | 119 |
| IO/Parser.py (BAMPE origin pairs) | 56 |
| Signal/PileupV2.py (wrap kernel, extension to L) | 56 |
| Signal/PeakModel.py (rotation to widest tag gap) | 26 |
| callpeak_cmd.py, PeakIO.py, FixWidthTrack.py, PairedEndTrack.py, PeakDetect.py, OptValidator.py, bin/macs3 | 69 |
| **Total (hook)** | **326 human-eff, 402 raw, 11 files** |

## 8. Solution outline
- `wrap_circular_ranges` (PileupV2): fold every range to start in [0, L), split at L.
- `extend_to_rlength`: pileups of circular chromosomes end at L (the tail after the last fragment is
  scored). This is the hidden part of the whole-chromosome rule.
- `__rotate_circular_regions`: before segmentation, move the run that wraps the origin to the front in
  negative coordinates (all four segmentation loops).
- `__origin_offset`: shift a peak starting before 0 back by +L at every `peaks.add`.
- `__lift_lvl1_across_origin`: bring lvl1 peaks into the frame of an origin-spanning lvl2 region.
- `bampe_origin_pair_parse`: reverse read before its forward mate on a circular chromosome ->
  fragment `[mate, read_end + L)`.
- `PeakModel.__chrom_locations`: rotate tags so the widest tag-free gap is the origin.
- `PeakIO._chrom_summit`: summits mod L in summits.bed and xls.

## 9. Test outline (slice: 16 tests in `test/test_circular_chromosomes_c4ea93.py`)
In-test BAM writer (gzip + BAM records, no pysam); seeded synthetic fixtures; every run through
`bin/macs3 callpeak` as a subprocess. Buckets: origin site = one narrow peak (convention + order);
rotation law (narrow x3 offsets, call-summits, broad + gappedPeak, bedGraph, cutoff analysis, BAMPE
incl. `# d`); independent per-base oracles (treatment pileup SE, control lambda windows, BAMPE
fragment pileup); linear chromosome keeps its ends (-p cutoff so genome-wide q changes do not
matter); errors (BED format, unknown name) paired with a positive run so they fail on base.
FINISH adds: model cells (plasmid fixture, >= 100 origin sites across many circular contigs),
`--call-summits` x BAMPE, broad x BAMPE, dense-control cell against the rotate-to-gap architecture,
multi-chromosome genome-wide q law, read1/read2 mate order x origin, `--nolambda`, `--SPMR`, pad-and-fold
mutant proof.

## 10. Forced bounds
CLI only; no new Python API is asserted.

## 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| 1 | pileup ends at last fragment, tail after it not scored -> N depends on origin | F-1/F-47 (discarded extent) | S3 chokepoint | pqtable total | 2, 4 (same chokepoint) | law tests with an empty treatment stretch at the cut (tail mutant killed 6/16) |
| 2 | pad-and-fold duplicates the origin neighbourhood -> double counted in pqtable, interior q move | F-9 | S3 | genome-wide statistics | 1 | law tests, interior peaks (FINISH: build the mutant) |
| 3 | segmentation / summit padding clip at 0 (#749 `max(start-10,0)`) on rotated frame | F-10 | S2 | output stage | 4 | call-summits law |
| 4 | broad two-level linkage across origin (lvl1 inside wrapped lvl2) | F-10 | S2 | broad | 3 | broad law + gappedPeak blocks |
| 5 | BAMPE origin pair dropped as improper; `d` average excludes it | F-14-ish / F-10 | A-tier | parser | 1 | BAMPE pileup oracle, `# d` law |
| 6 | rotate-to-gap architecture jump (linear call in a rotated frame) | architecture jump | S4 | windows | - | control lambda oracle (llocal 10 kb wraps); FINISH dense-control cell |
| 7 | linear chromosomes change (wrap applied globally) | F-20 | S2 | scope | - | linear keeps ends |

## 11b. Cross-product matrix (F-10)
Axes: {narrow, summits, broad, cutoff analysis, bedGraph} x {SE, BAMPE} x {origin site, interior site,
empty stretch at the cut}. Slice covers the SE row + BAMPE narrow/tracks; FINISH fills BAMPE x
{summits, broad, cutoff} and model x {SE}.

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. The law is one sentence with a combinatorial instance space (P1); the tail and double-count
cells are not visible without running the rotation yourself.

## 14. Gates (run 2026-09-24, base 760ff63b)
- PICK-FILTER 1 (behavioural F2P): base splits/loses the origin site, half-height bedGraph; new tests
  14-16/16 fail on base (all 16 after positive halves were added to the error tests). PASS.
- Gate 5 (cold capability): no PR/commit builds circular topology; #749 (summit padding, merged
  today) is in base. PASS.
- Gate 6 (reproduce on base): reproduced through the CLI in the container. PASS.
- Gate 7b / exclusivity PR-DIFF: canonical `macs3-project/MACS`; PR + issue searches (circular,
  plasmid, chrM, mitochondria, origin, wrap, bacteria(l), topology, "chromosome end", "genome end",
  "linear chromosome", circ): no PR in the lane; hits #749 (merged, summit padding, different
  capability, diff read: CallPeakUnit/ScoreTrack padding only), #600 docs. Hunter fork scan (157
  heads) clean. PASS.
- Gate 8 (defined behaviour / philosophy): no maintainer statement for or against; #353/#692
  bacterial threads are usage questions; circular topology is defined by the data. PASS.
- SIX-CHECK 1-6: literal/namespace/philosophy/closed-implemented scans empty; base = main HEAD so
  base..main overlap empty; capability absent at HEAD (no `--circular` option). PASS.
- Outsider-nameable risk ("circular genome support"): MEDIUM, mitigated per 2026-09-09-B rule 6
  (meta phrased on MACS's own model; F-10 cells; PR-DIFF at submit). Core-slice precheck OWED.

## Why this is not a duplicate
No peak-calling or bioinformatics-pipeline problem in approved-problems/, problems/, rejected/.
Closest shapes: sfepy / worldengine (scientific Python, integration-shaped band) - different domain
and different trap class (topology law vs rollback/accounting).

Predicted iteration cycles: 3.
