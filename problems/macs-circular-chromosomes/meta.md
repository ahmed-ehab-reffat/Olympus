---
Repository: https://github.com/macs3-project/MACS
Issue: N/A
Commit: 760ff63b958f79cc82abc8c1a9847705cd99c907
Language: Python
Category: feature-request
Title: Add circular chromosome support to MACS3 callpeak
---

# Add circular chromosome support to MACS3 callpeak

Add a `--circular` option to `macs3 callpeak` that takes a comma-separated list of chromosome names and treats those chromosomes as circular, the way bacterial genomes, plasmids and chrM really are. Today every chromosome is linear: fragments, local lambda windows and peaks are cut at position 0 and at the chromosome length, so a binding site that straddles the origin of a circular genome is split in two or lost.

On a circular chromosome nothing stops at the ends. Treatment fragments, the control windows behind the local lambda, significant regions and the gaps allowed between them all continue across the origin, and every position of the chromosome counts towards the genome-wide score statistics, which includes the q-value table and the cutoff analysis. A local lambda window longer than the chromosome goes around it as many times as its length requires, so every control read inside it counts once per lap. Chromosome lengths come from the BAM headers, so `--circular` works with `-f BAM` and `-f BAMPE`. Callpeak exits with an error for any other format, for a name missing from the header of any treatment or control file, and for a name whose length differs between those headers. A name every header lists is accepted even when no read maps to it, and such a chromosome is skipped like any other chromosome without reads. In BAMPE mode, a pair on a circular chromosome whose reverse-strand read lies before its forward-strand mate is one fragment that runs from the forward read across the origin to the end of the reverse read. Aligners do not flag such a pair as proper, and it must still be used.

A peak that crosses the origin is reported once, with its start inside the chromosome and its end past the chromosome length. Summit positions in the summits file and the xls are reported on the chromosome, bedGraph intervals stay within it, and peaks are listed in order of start. Results must not depend on where the origin lies: rotating every read of a circular chromosome by the same offset rotates every peak, summit and track position by that offset and leaves every score, count and the fragment length unchanged. Chromosomes not named in `--circular` keep their ends: their fragments and windows are still cut at 0 and at their length.
