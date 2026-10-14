# DESIGN.md - macs-callvar-fragment-phasing

## 1. Title
Add pair-aware fragment evidence and phasing to macs3 callvar

## 2. Shape classification
- Shape: O-Pipeline-hard (one option that must reach every stage of callvar: BAM reads, the read
  pileup path, the fermi-lite unitig re-call path, the worker pickling boundary, `fix_indels`, the
  VCF writer), with a new algorithm on top (block construction + block allele-specific test).
- Pass target: 20-35% (hard edge; only Orion is affordable, so keep one pass measurable).
- Dominant verdict predicted: INTEGRATION_ERROR (fragment identity lost at a stage boundary) and
  MISSED_REQUIREMENT (unitig path, control votes).

## 3. Public API surface
- `macs3 callvar --pair-aware` (new flag; off = byte-identical to today).
- VCF: FORMAT `PS` on phased rows (FORMAT becomes `GT:DP:GQ:PL:PS`), phased GT `0|1`, `1|0`,
  `1|2`, `2|1`; INFO `BAS` (block model: heter_AS / heter_noAS / heter_unsure) and `BAR` (haplotype-1
  share of treatment fragments, 2 decimals) on phased rows; header lines for PS, BAS, BAR.
- Nothing else is public. No Python API is named in meta (tests go through the CLI only).

## 4. Canonical output form
- Rows stay in position order, one row per call, as today.
- Unphased heterozygous calls keep `/` and the four-field FORMAT.
- PS = 1-based POS of the block's first call.
- First call of a block is written low|high (`0|1`, `1|2`); later calls follow the relation to the
  previous call.
- Ties: equal same-side/opposite-side vote = no join. Equal base qualities between agreeing mates:
  the mate with the smaller mapped start supplies strand and read-end status (forward mate if the
  starts are equal).

## 5. Blind-spot pre-empts
- "every -F mode, including peaks that are re-called from fermi-lite unitigs" (pipeline placement:
  both creation paths).
- "Fragments from the control file vote too" (rule resolution, second holder).
- "Without the flag the output is unchanged" (compatibility).

## 6. Description draft
See meta.md (drafted in full at slice time: rules R1-R5 below, each one sentence or two).
- R1 unit: reads that share a name within one BAM file are one fragment; a fragment contributes at
  most one observation per position; all read-counting quantities (DPT/DPC, DP1T..DP2C, SB, the
  read-end discount behind --altallele-count, the four BIC models, GT/GQ/PL, DP) count fragments.
- R2 combine: mates whose base fails -Q are ignored at that site; agreeing mates count once at the
  highest base quality, strand and read-end status from the mate that supplied it (tie rule above);
  disagreeing mates contribute nothing at that site.
- R2b outlier unit (added at the slice, found by the first fixture): when callvar's top-5% edit filter
  drops a read, its mate goes too. The percentile is still computed over reads. Without this rule the
  remaining mate of an outlier fragment counts alone, and the oracle could not be written without
  choosing one reading, so the choice is stated (L97).
- R3 every path: every -F mode, including unitig re-calls.
- R4 phasing: consecutive heterozygous calls of a peak are joined when the fragments (treatment and
  control) that carry a called allele at both do not split evenly between same side and opposite
  side; majority decides; blocks are maximal joined runs; GT/PS rules above.
- R5 block test: fragments assigned to haplotype 1 or 2 by the called alleles they carry in the
  block (inconsistent fragments dropped), quality = highest base quality among the block's calls;
  MACS's heterozygous allele-specific and non-allele-specific models on haplotype-1 vs haplotype-2
  qualities, treatment and control; BAS by the same 2-point BIC margin callvar uses; BAR.

## 7. File footprint (sketched against real files)
| Action | Path | Raw | Eff (est) | Reason |
|---|---|---|---|---|
| MODIFY | bin/macs3 | +3 | 3 | flag |
| MODIFY | MACS3/Commands/callvar_cmd.py | +40 | 30 | thread flag to both call paths + revisit path, phase, header |
| MODIFY | MACS3/Signal/PosReadsInfo.py | +120 | 90 | per-fragment pending table, combine rule, fragment allele table into Variant |
| MODIFY | MACS3/Signal/RACollection.py | +16 | 12 | read names on the read path, fragment-level outlier drop |
| MODIFY | MACS3/Signal/UnitigRACollection.py | +25 | 18 | read names out of get_variant_bq_by_ref_pos, grouping across unitigs |
| MODIFY | MACS3/Signal/PeakVariants.py | +150 | 110 | Variant state (tables, PS, block fields) through pickling and copy; phase(); block test; VCF |
| TOTAL | 6 files | ~350 | ~260 | spike to confirm >=250 human-eff |

## 8. Solution outline
- PosReadsInfo: `add_T/add_C` keep their signatures; in pair-aware mode they stage observations per
  fragment name; `resolve_fragments()` folds them into the existing dicts once per site (before
  `update_top_alleles`); the per-fragment (allele, bq) table survives for `toVariant`.
- `toVariant` stores per-fragment side index (0 = GT low allele, 1 = high) + bq, treatment and control.
- Variant: new fields in `__getstate__/__setstate__` (the pickling boundary of `mp.Pool` and
  `copy()` in `fix_indels`).
- PeakVariants.phase(): join consecutive het rows by votes, orient, PS, then block test via
  `CalModel_Heter_AS` / `CalModel_Heter_noAS`.
- UnitigCollection: names come back from `UnitigRAs.get_variant_bq_by_ref_pos`, staged under the
  same fragment table across unitigs.

## 9. Test outline
`test/test_callvar_fragments_38c44a.py`, CLI-level. Synthetic single-chromosome BAM + BAI + MD
writer (BGZF blocks with whole records, reg2bin bins + linear index, shared QNAME per pair, proper
flags and TLEN) against a seeded reference.
Buckets: compat (flag off = base output), fragment counting (overlap agree / disagree / Q-filtered
mate / non-overlapping mates), strand + read-end source, phasing (cis, trans, tie, control-only
link, homozygous call inside a block, two blocks in one peak), block test, every -F mode (off, on,
auto with an indel peak), worker count (-m 1 / -m 3).

## 10. Forced bounds
Cython pure-mode `cclass` attributes must be declared (a new attribute on an undeclared name raises
AttributeError at runtime). `Variant` is pickled in the worker pool even at `-m 1`.

## 11. Trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Test |
|---|---|---|---|---|---|---|
| 1 | Fragment identity dropped at the pickling boundary (Variant state tuple, `copy()` in fix_indels): phasing silently finds no links | F-47 | S4 | persistence | #2, #4 | any phasing test; deletion-shifted row |
| 2 | Unitig re-call path (second creation path) keeps per-read counting and no names | F-9 / F-41 | S6 | creation path | #1, #3 | fermi on / auto indel peak cells |
| 3 | Control fragments vote in linking and in the block test | F-10 holder cell | S2 | holder | #2 | control-only link |
| 4 | Read vs fragment unit in every counter (SB strand, read-end discount, DP) and in the outlier filter (drop the whole fragment) | F-13 | S4 | counting unit | #1 (which sites survive decides blocks) | overlap agree/disagree; tip mate; an outlier mate |
| 5 | fix_indels tests `top1isreference` as an attribute (always truthy) | F-39 | A-tier | inherited helper | #1 | FINISH scope: deletion rows |

## 11b. Cross-product (F-10)
| | read path (-F off) | unitig path (-F on / auto+indel) |
|---|---|---|
| treatment-only links | cis/trans | cis/trans |
| control link | control-only join | control-only join |
| overlapping mates | agree/disagree counts | agree/disagree counts |

## 12. Tier + category
Olympus, feature-request ("Add ...").

## 13. Predicted pass rate
20-35%. The counting rules and the phasing rule are transcribable; the band comes from the
pickling boundary, the unitig path and the control holder.

## 14. Quality gates
Phase 1-2 done (see feedback.md). SIX-CHECK and exclusivity clean. Slice built before any
differentiating scope.

## Why this is not a duplicate
Our macs-circular-chromosomes is callpeak coordinate topology (PeakDetect, CallPeakUnit, PileupV2,
PeakModel, Parser). This touches none of those files; it is callvar (IO/BAM accessor, Signal
variant classes, callvar_cmd).

Predicted iteration cycles: 3.
