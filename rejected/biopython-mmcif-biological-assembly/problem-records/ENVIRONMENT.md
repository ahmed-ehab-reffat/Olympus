# Environment gate - Biopython mmCIF biological assembly

Status: **invalid and superseded; package retired 2026-08-14**.

The recorded runs below used `python:3.13-bookworm` and an image layout rooted
at `/opt/biopython-source`. Olympus requires one of its published base images
and `WORKDIR /app`. The run therefore did not reproduce the platform
environment and cannot establish Phase A or Phase B. Under
`ENVIRONMENT_GATE.md`, every downstream behavioral verdict is invalid and no
solver result may be counted. The custom upstream license identifier also
remains unconfirmed by Olympus.

Everything below is preserved as quarantined historical evidence, not as a
passing gate result.

## Immutable input

- Repository: `biopython/biopython @ c9489604d1d9607602ca9199a3852c1219ed330f`
- `meta.md`: `50b9d93fa9c87397a9fdd4b3350f1d18b413316d4d879053567bf12ffb45b9a7`
- `test.patch`: `a2df8d2ea209f4b903f6dc7a23db2554507aa8053f0da6e6c2cde5a7160004f3`
- `solution.patch`: `849cd80349f976d8e35092c6b9c4ae3b1a53431dddd9d7f1a649dcfb4db565c8`
- `Dockerfile`: `3998a8e2e610aad537817b0280b60fd9b875f8e4ba60427a3090156be6d09bf1`
- Base image: `python:3.13-bookworm@sha256:62eafe52c91cad83c2c74e630bfde917da8c253673e695665d454def84fc9a13`

## Phase A - untouched repository image

- Host free-space preflight: 56,629,416 KiB available, above the required
  12 GiB threshold.
- Context: clean `git archive` of the exact pin, excluding `.git`, untracked
  files, candidate records, and author artifacts.
- Build: `docker build --pull --no-cache`; pass. Final validation image ID:
  `sha256:51e2639a04ad70ee206858551b1843758e925fe66c255c1aaf548fb16cb40c3f`.
- Runtime: `--network none --user 10001:10001`; source mounted read-only,
  copied by that UID to private `/tmp`, and extensions built offline there.
- Official discovery: `python Tests/run_tests.py --offline`; **514 tests
  passed** in 56.780 seconds. Optional network, service, executable, and
  Python-package surfaces skipped through normal repository discovery.
- The exact reference without the hidden test file passed the resulting
  **515-test** complete suite in 57.566 seconds (the added module contributes
  one docstring discovery).
- Required Python, compiler, setuptools, wheel, pytest, NumPy, fixtures, and
  package metadata were readable and executable offline.

## Phase B - exact evaluator composition

`scripts/environment_gate.sh` rebuilt a clean untouched image (transient
manifest-list digest
`sha256:5e18496012024d3044608e59eb0f692bc90919bf22fca6060cc2e34aa676a2cf`)
and reproduced evaluator order with three-way verifier injection and no
unmerged paths:

| Tree | Base lane | Feature lane | Verdict |
| --- | --- | --- | --- |
| pristine + `test.patch` | 11/11 pass | 30/30 real behavioral failures | expected |
| pristine + `solution.patch` + `test.patch` | 11/11 pass | 30/30 pass | pass |

Baseline and reference feature JUnit files contain the same 30 testcase
identities. `test.patch` owns only
`Tests/test_PDB_MMCIFAssembly_e1c4.py` and `test.sh`; `solution.patch` owns only
`Bio/PDB/MMCIFAssembly.py` and `Bio/PDB/__init__.py`. The path sets are
disjoint. No Biopython assembly solver patch exists locally, so there is no
representative domain patch to replay or omit.

## Quarantined attempts and superseded versions

The initial recovered partial clone attempted to fetch a missing promisor
object before Docker; a diagnostic editable-environment run resolved imports
to a mismatched tree and encountered write assumptions. Both are setup failures
and contribute no solution evidence. Two earlier artifact versions passed
their then-current gates but were invalidated when the prompt/tests changed.
Mutation runs performed immediately after one such change were explicitly
quarantined and replayed only after the fresh exact-version gate passed.

Historical result: **invalid local pass**. The base image and working directory
already contradict the Olympus contract, so this record never established a
valid platform environment verdict.
