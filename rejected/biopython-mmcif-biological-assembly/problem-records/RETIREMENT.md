# Retirement record - Biopython mmCIF biological assembly

Status: **rejected and retired 2026-08-14**.

## Terminal reasons

1. The submitted `Dockerfile` begins with
   `python:3.13-bookworm@sha256:...`, not one of the Olympus base images allowed
   by `instructions/06-dockerfile.md` and platform validation.
2. It sets `WORKDIR /opt/biopython-source`; Olympus applies patches and runs the
   evaluator from `/app`.
3. The Phase A and Phase B runs therefore proved a different environment. Per
   `ENVIRONMENT_GATE.md`, the environment verdict and all dependent gap,
   fairness, and false-positive verdicts are invalid.
4. The pinned repository declares
   `LicenseRef-Biopython-License-Agreement`. Olympus reported that license as
   unrecognized, and no explicit confirmation that it is permitted was
   obtained. License eligibility is unresolved, not passed.

## Disposition

- No solver calibration started; the final count is `0/10`.
- No solver run is counted as a failure or success.
- `meta.md`, `test.patch`, `solution.patch`, and `Dockerfile` remain unchanged
  as the rejected version's audit snapshot. They must not be submitted.
- Historical test and mutation results remain available, but none carries a
  current gate verdict.

This problem is closed rather than repaired because license eligibility is a
hard unresolved gate. Reconsideration requires explicit Olympus approval of
the license, a compliant Dockerfile using an approved base and `WORKDIR /app`,
and a complete restart of all exact-version gates and calibration at `0/10`.
