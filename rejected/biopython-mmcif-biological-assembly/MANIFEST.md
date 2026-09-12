# Biopython mmCIF biological-assembly archive

Archived on 2026-08-14 after the package failed two hard Olympus eligibility
gates.

## Terminal decision

The exact biological-assembly task is closed. Its Dockerfile used an
unapproved base image and `/opt/biopython-source` instead of the required
`WORKDIR /app`, so the purported environment result and all dependent gate
verdicts are invalid. Olympus also did not recognize the repository's
`LicenseRef-Biopython-License-Agreement`, and permitted-license status was never
confirmed.

Do not submit, calibrate, reword, or add fixtures to rescue this archived
version. Reconsideration requires explicit Olympus license approval and a new
problem version that restarts every mandatory gate with a compliant base image
and `/app` evaluator layout.

## Preserved records

- `problem-records/` contains the frozen prompt, invalid Dockerfile,
  test/reference patches, artifact hashes, retirement record, design evidence,
  and the superseded environment, gap, fairness, and false-positive records.
- `candidate-records/` contains the preliminary design, upstream search,
  environment attempt, and candidate summary.

The four submission artifacts were moved without content changes. Their hashes
remain bound by `problem-records/ARTIFACTS.sha256` and are preserved only as a
rejected audit snapshot. No solver calibration began; the terminal count is
`0/10`.

## Cleanup

The active problem and candidate locations were removed by moving their records
into this archive. The disposable authoring checkout and task-specific Docker
resources were removed from active use. See `CLEANUP_COMPLETED.md` for the
resolved inventory and recovery details.
