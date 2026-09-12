# Verification — version 44

Repository pin: `65df15775026bad1189139613ee3d338139bec3d`.

## Artifact IDs

- `meta.md`: `b56baea0aeaa69afd2ddab1fce1bceb52999e595989d9dde6486eee2033e8d45`
- `test.patch`: `4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`
- `solution.patch`: `3e95163813741211b836a5d19d12cb795cd2ebc8126fc02b76e7a7b70ee38f65`
- `Dockerfile`: `be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`
- `solution_approach.md`: `c7abfa9a465db136c61415ab9b95f62df6fc5b49eca533b0d27315df896f84a2`
- replay manifest: `33ce99e576cd6b8f0d11a523891546cd27ee80124de69d3fc242d755aed45398`
- combined binary diff: `d7485ca96ca1b3870477a7e2f309de062e3cfbf06e3a2ad1927a9322bb0e3cfe`
- combined Git tree: `edc88a698c447f78958958a293fd9f98e229d515`

## Exact results

| Tree | Baseline | Focused |
|---|---:|---:|
| test-only | 538/538, 5 skipped | 0/14; behavioral failures, zero errors |
| reference | 538/538, 5 skipped | 14/14 |
| run-17 Nova 9 replay | archived 538/538 | 13/14; rejected only by profile/session test |
| omitted-steno-CCCD mutant | 538/538, 5 skipped | 13/14; rejected only by profile/subscription test |

The reference lanes pass 10/10 capacity-one steno, 2/2 capacity-three steno,
and 2/2 capacity-one no-steno. The exact CCCD mutant proves the added test is a
narrow integration discriminator; the actual solver replay proves the peer
activation behavior rejects an observed shortcut.

## Environment and structure

The fail-fast gate built the Dockerfile without cache from the untouched
checkout and ran all phases offline as UID/GID `10001:10001`. It verified
startup/JUnit status, exact testcase identity, dependencies and tools, source
permissions, participant/test path separation, and injection compatibility for
four representative historical patches. It ended `environment gate: PASS`.

`test.patch` applies cleanly and adds only randomized tests/configuration plus
`test.sh`. The wrapper supports `base` and `new`, is offline, and passes
`bash -n`. Both patch orders produce the same combined diff and Git tree. The
profile test discovers GATT report references dynamically and treats the saved
CCCD table opaquely.

Gap, fairness, false-positive, artifact, reference, feature-lane, patch-order,
and exact-version mutation checks pass. Version 44 starts calibration at 0/10;
run 17 is prior-version trajectory evidence and no cold solver was run.
