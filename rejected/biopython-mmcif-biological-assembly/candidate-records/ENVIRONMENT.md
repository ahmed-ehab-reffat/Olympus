# Environment gate - Biopython mmCIF biological assemblies

Verdict: **invalid and superseded; candidate retired 2026-08-14**.

The run below is retained as historical evidence only. It used
`python:3.13-bookworm`, which is not one of the permitted Olympus base images,
and it did not prove operation from the required `WORKDIR /app`. It therefore
cannot satisfy `ENVIRONMENT_GATE.md`, cannot support any downstream verdict,
and must not be counted as a passing Phase A run. The upstream custom license
identifier was also not recognized by Olympus and remains unconfirmed.

- Image: `python:3.13-bookworm`, immutable ID
  `sha256:62eafe52c91cad83c2c74e630bfde917da8c253673e695665d454def84fc9a13`
- Dependency warm-up: repository dev group installed into named volume
  `olympus_biopython_work_0811`
- Exact offline runtime: `--network none --user 12345:12345`
- Official command: `Tests/run_tests.py --offline`
- Result: **514 tests passed** in 68.292 seconds.

An earlier raw-pytest/missing-setuptools attempt was quarantined as a harness
error and was not treated as a repository failure. No valid Olympus Phase A or
Phase B result exists for this candidate.
