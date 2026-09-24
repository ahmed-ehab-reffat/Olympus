# macs-circular-chromosomes - eval results

No platform batch yet. Local validation numbers are logged below.

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
