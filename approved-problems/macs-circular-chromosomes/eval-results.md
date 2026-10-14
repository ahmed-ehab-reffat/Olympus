# macs-circular-chromosomes - eval results

## Batch 1 (2026-09-28): 10 Nova + 1 Vega, 50-test suite -> 0/11 PASS

Runs saved under agent-runs/1/. Baseline passed in all 11. Model requests per run 108-267 (median ~189).

| run | agent | new failed /50 | files | +lines | failed tests (short) | approach / cause |
|---|---|---|---|---|---|---|
| Nova #10 | Nova | 14 | 12 | 840 | WHOLE, TIE-n, TIE-b, MODEL, broad, 8 BAMPE, readless x2 | origin-only group join; BAMPE pairs by QNAME (fixture gave mates distinct names -> 0 fragments, ZeroDivisionError); readless chrM added to pscore_stat |
| Nova #9 | Nova | 6 | 11 | 704 | WHOLE, TIE-n, TIE-b, MODEL, subpeak, broad | origin-only join; no PeakModel change; subpeak summit offset / gapped blocks origin-dependent |
| Nova #8 | Nova | 21 | 10 | 587 | core 4 + narrow x3, split, broad, tracks, lambda, BAMPE, linear x2 | ValueError resizing arrays in circular pileup |
| Nova #7 | Nova | 15 | 11 | 611 | core 4 + broad, bdg, tracks, BAMPE, readless | zero-length bdg intervals at 0; QNAME pairing; BroadPeakIO AttributeError |
| Nova #6 | Nova | 15 | 11 | 574 | core 4 + narrow x3, split, subpeak, broad, cutoff x2, treat-only, readless | origin-only join |
| Nova #5 | Nova | 19 | 9 | 480 | core 4 + 13 BAMPE/pooled | float passed to range() in PE pileup (TypeError) |
| Nova #4 | Nova | 15 | 10 | 484 | core 4 + narrow x3, split, subpeak, broad, cutoff, long pairs, readless | origin-only join |
| Nova #3 | Nova | 12 | 12 | 953 | core 4 + subpeak, broad, BAMPE x5, readless | origin-only join; non-proper pairs not used consistently |
| Nova #2 | Nova | 4 | 12 | 1008 | WHOLE, TIE-n, TIE-b, MODEL | origin-only join; no PeakModel change (0 paired peaks, exit 1). Closest miss |
| Nova #1 | Nova | 12 | 10 | 763 | core 4 + BAMPE x7, readless | QNAME pairing -> 0 fragments |
| Vega #1 | Vega | 9 | 12 | 662 | WHOLE, TIE-n, TIE-b + 6 BAMPE | QNAME pairing (fixture); origin-only join. Only run that passed MODEL |

Kill counts: WHOLE 11, TIE-n 11, TIE-b 11, MODEL 10, broad 8, long BAMPE pairs 8, BAMPE pairs/peaks/second-file 7 each.
(Run folder names are reversed: folder Nova_Nova_1 = "Nova #10", Nova_Nova_9 = "Nova #2".)

### Local replay of the 11 saved solutions (2026-09-28)
Fixture bug found: write_bam named every record "r<i>", so the two mates of a pair had different
QNAMEs. Nova #10, #7, #1 and Vega paired mates by QNAME (legitimate) and parsed 0 fragments. After
giving mates a shared name, replaying the saved solution-patch.patch files on the 50-test suite:
Vega 3 fail (WHOLE, TIE-n, TIE-b only), Nova #2 4 (core), Nova #1 5, Nova #9 / #3 6, Nova #10 7,
Nova #7 13, #6/#4 15, #5 19, #8 21; reference 50/50. WHOLE + TIE-n + TIE-b fail 11/11 for one reason
(every agent cuts an all-round component at the origin) -> dropped (user decision). On the final
47-test suite: reference 47/47, Vega 47/47, Nova #2 fails only MODEL. Predicted re-eval: 1/11.


## Local validation

### 2026-09-24 SLICE (base 760ff63b, image factory-macs-circular-chromosomes, --network none)
Cold `docker build --no-cache`: 441 s (pip 106, COPY 12, git+simde+build_ext+chmod 196, export 119).
Clean room = image built from a pristine clone at base, patches applied inside the container.

| uid | test.sh base @base | test.sh new @base | test.sh base @solution | test.sh new @solution |
|---|---|---|---|---|
| 1000:1000 | rc 0, 113 pass / 4 skip / 0 fail (117) | rc 1, 16/16 fail | rc 0, 113 pass / 4 skip | rc 0, 16/16 pass |
| 0:0 | rc 0, 113 / 4 skip | rc 1, 16/16 fail | rc 0, 113 / 4 skip | rc 0, 16/16 pass |
| 4242:4242 (unmapped) | rc 0, 113 / 4 skip | rc 1, 16/16 fail | rc 0, 113 / 4 skip | rc 0, 16/16 pass |

`git status` in the image before patches: clean; after test.patch: only the two harness files.
Flakiness 3x: not run at SLICE (owed at FINISH); one run per uid above, identical counts.

Mutation (reference minus `extend_to_rlength`, i.e. the hunt spike's behaviour): 6/16 fail
(narrow law @5000, call-summits law, broad law, bedGraph law, cutoff-analysis law, BAMPE law).
Effective LOC hook: 326 human-eff, 402 raw, 11 files (padding-floor 268).
