# Environment verification — version 44

Verdict: **pass**.

The exact gate ran from untouched repository pin
`65df15775026bad1189139613ee3d338139bec3d` with:

- `meta.md`: `b56baea0aeaa69afd2ddab1fce1bceb52999e595989d9dde6486eee2033e8d45`
- `test.patch`: `4b765f8ff168113af8b20d6281bab3c873dfb7447b418d95f7046c115c41e322`
- `solution.patch`: `3e95163813741211b836a5d19d12cb795cd2ebc8126fc02b76e7a7b70ee38f65`
- `Dockerfile`: `be5ba947e4f49300ca28f74551e8f24c2763ed4e53fbfd2c6bf0a211e3c5bc9a`
- replay manifest: `33ce99e576cd6b8f0d11a523891546cd27ee80124de69d3fc242d755aed45398`

## Exact offline matrix

The Dockerfile was rebuilt without cache before applying either patch. Every
runtime command then used `--network none` and UID/GID `10001:10001`.

| Tree | Base | New |
|---|---:|---:|
| pristine + tests | 538/538, 5 skipped | 0/14; fourteen behavioral failures, zero errors |
| reference + tests | 538/538, 5 skipped | 14/14 |

The focused result partitions into 10/10 capacity-one steno, 2/2
capacity-three steno, and 2/2 capacity-one no-steno. Pristine and reference
JUnit testcase identities match in every lane. Required files, Cargo caches,
the pinned git dependency, nextest, and the generated runtime lock are readable
and executable by the evaluation UID without network access.

## Replay and fail-fast coverage

Version 44 expands the public behavior to BLE-profile activation and per-profile
Plover subscriptions. Older known-good patches are therefore no longer valid
must-pass behavior replays. The gate instead verifies injection-only composition
for run-16 Nova 2 and run-17 Nova 2, Nova 3, and Nova 10. All four patches apply
without verifier-path overlap or harness startup failure. No legacy result is
misreported as satisfying the expanded contract.

The gate also checks host storage before building, patch application, participant
and test path separation, arbitrary-UID readability, JUnit existence and
startup-error status, exact base inventory, and every focused lane. It ended
`environment gate: PASS`. Any artifact, repository pin, dependency image, or
replay-manifest change invalidates this verdict.
