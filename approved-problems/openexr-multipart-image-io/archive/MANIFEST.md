# OpenEXR multipart Image I/O archive

Archived on 2026-08-15 after user-confirmed platform acceptance. Canonical
submission artifacts and compact design, run, fairness, gap, and verification
records remain under `problems/openexr-multipart-image-io/`. This archive holds
the raw solver bundles and preliminary candidate dossier.

## Canonical accepted artifacts

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `926a2b88ecda0bef5f6dc2ae93e88a74b290e560d72720bb601f0bee232e940f` |
| `test.patch` | `4974070a9c5250e5a53bc1f1470b44eaf6cf404ce69110d13951a34db6fbf444` |
| `solution.patch` | `55307ae4ff12f707973655c5cb26ce5f4ad4b51ebaa617164734725e2d9ce440` |
| `Dockerfile` | `fc0ce0068f5fa65c94986532de4a5c74bfb40e7305ac821e572e7c0be96a1d80` |
| `solution_approach.md` | `dd637bbd481bd84c30da436388457bfd31808452ac99c374c82792f846227a5d` |

Immutable revision v17 passes 14/14 focused and 127/127 pre-existing tests.
The 76-variant production audit kills all 75 behaviorally incorrect mutants;
the sole survivor delegates an equivalent duplicate-name rejection. Acceptance
does not change these frozen artifact identities.

## Raw solver evidence

| Archive | Historical batch | Members | SHA-256 |
|---|---|---:|---|
| `agent-runs1.zip` | v2 | 45 | `2cc6e8b528710474adbe2dbfa822847a4015d48ed352ed137975ccb8fb9edc6e` |
| `agent-runs2.zip` | v4 | 45 | `5346443ef6553a40de7622ccdc8b45060cad3515322f4d97f9bc1e1ec466c60c` |
| `agent-runs3.zip` | v5 | 45 | `9ff72c572e10c42dd1395d6e56a6bf611478abab7e320ebe6ccdf34d8c2da1a4` |
| `agent-runs4.zip` | v6 | 45 | `03223ef67da3cf1e94507148dfbd548da5e66552fa28d661eafcfe15aec9adc8` |
| `agent-runs5.zip` | v7 | 45 | `e1b61732e5d87b1c47bfa628f7a0a6b5f847c784790c97e043aa148d00ccd60e` |
| `agent-runs6.zip` | v8 | 45 | `5f619b0f14d7c2777e15e50697ef904eaae4b2b18c7139a95823addae72778a2` |
| `agent-runs7.zip` | v9.1 | 45 | `83e200d196b80f0d1b6f5c1797c5409357fecd836d50bc8a666396c2331a36cb` |
| `agent-runs8.zip` | v11.2 | 45 | `69ce12cb37052c94a222ac587efd25946f4df315dd4fd2ec97ff6d3b57a7bf27` |

All eight ZIPs pass `unzip -t`. Each was extracted and compared recursively
against its readable `agent-runsN/` source, excluding only `.DS_Store`; all
eight comparisons were byte-identical. The duplicate readable directories,
about 42 MB total, were removed only after that parity check.

Restore a batch from the Olympus root with, for example:

```sh
unzip archive/openexr-multipart-image-io/agent-runs8.zip \
  -d problems/openexr-multipart-image-io/agent-runs8
```

## Preliminary candidate records

| Artifact | SHA-256 |
|---|---|
| `candidate-records/DESIGN.md` | `ed4b9b85caaba04054c215c386f2049f12be47e2da5a75f314ad64220febbec6` |
| `candidate-records/ENVIRONMENT.md` | `7af2419c044560517e986baea51ebc6895db7e5c44d66de34bb40e87cc67904a` |
| `candidate-records/SUMMARY.md` | `81a1f3421755d35f0e8f6e56b54c63e044bce9c6453718dbbd8cd9e0dadf3ad9` |
| `candidate-records/UPSTREAM_AUDIT.md` | `cbf8cc63f97230a906576aed4ae758faa9881fad0caa849c8e28d4781a606c4e` |

These files moved from the active candidate namespace without content changes.

## Cleanup inventory

After archive integrity checks, closeout removed only OpenEXR-scoped disposable
state:

- stopped containers `openexr_v11_base1` through `openexr_v11_base5` and
  `olympus_openexr_deps_0811`;
- images `olympus-openexr-multipart:v5-0812`,
  `olympus-openexr-multipart:final-0811`,
  `olympus-openexr-multipart:exact-0811`, and
  `olympus-openexr-gate:0811`;
- three cache records whose descriptions contain the OpenEXR bootstrap build,
  totaling about 291 MB; the description filter left other projects' build
  cache untouched;
- volume `olympus_openexr_work_0811`, containing about 138 MB;
- 136 top-level `/private/tmp/openexr*` entries, totaling about 8.4 GB,
  including the final verification extraction;
- the OpenEXR subdirectories in the two candidate scratch batches, totaling
  about 172 MB;
- 35 `openexr-mutations.*` log directories under the user's temporary
  directory, totaling about 7 MB; and
- `.DS_Store` files inside the canonical problem folder.

Two `.DS_Store`-only OpenEXR temp directories were recreated during the first
post-cleanup audit and were removed in the final pass.

No OpenEXR path existed under the workspace `work/` namespace. Docker images
remain reconstructible from the accepted Dockerfile and pinned repository;
deleted caches, volumes, and temporary trees are intentionally not archived.
