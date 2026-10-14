---
Repository: https://github.com/macs3-project/MACS
Issue: N/A
Commit: c5443190e3edfeb301cc94acf450e2b2c026a223
Language: Python
Category: feature-request
Title: Add pair-aware fragment evidence and phasing to macs3 callvar
---

# Add pair-aware fragment evidence and phasing to macs3 callvar

Add a --pair-aware option to macs3 callvar to count sequenced DNA molecules instead of reads and phase heterozygous variants.

With this option, reads in a BAM file with the same name are one fragment, even across multiple peaks on the same chromosome. A fragment gives at most one observation at any given position; mates whose base quality at that position is not above -Q are excluded, and concordant mates count once, with the highest base quality of the two. Discordant mate reads are not counted and provide no allele at that position. For the SB strand counts, each fragment takes the strand of its first read in the pair, even at a position only its other read covers, and a read without a mate keeps its own strand. Option -D and the outlier filter exclude reads at each peak, as they would without this option, before reads are grouped into fragments.

Phasing is done over all 0/1 calls on each chromosome, indels included. A fragment with reads in two peaks is used to phase calls in both. Two positions are linked if the treatment and control fragments with a called allele at both positions are unevenly split between REF/REF or ALT/ALT pairs and mixed pairs. Positions are taken in order, with each position joining the closest earlier position it is linked with, in the same order or opposite order, depending on which group is larger. If it is linked with no earlier position, a new block is begun. Blocks must have at least two sites. The first site in a block will be 0|1. All sites within a block get FORMAT information GT:DP:GQ:PL:PS, where PS is the POS value of the first site in the block. Nonblock sites keep the / genotype and other FORMAT information.

A fragment is assigned to haplotype 1 of a block if all block-site alleles carried by the fragment are on the left side of the | in a block. A fragment is assigned to haplotype 2 of a block if all block-site alleles carried by the fragment are on the right side of the |. A fragment is assigned to neither haplotype otherwise. Two-decimal INFO BAR values are included for each block site to show the proportion of the block's assigned treatment fragments that are on haplotype 1.
