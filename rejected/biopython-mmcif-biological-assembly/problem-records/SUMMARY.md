# Biopython mmCIF biological assembly - retirement summary

Status: **rejected and retired 2026-08-14; calibration 0/10**.

The package is not eligible for submission. Its Dockerfile violates the
published Olympus environment contract: it starts from an unapproved base
image and uses `/opt/biopython-source` rather than `WORKDIR /app`. Consequently
the recorded environment, gap, fairness, and false-positive pass verdicts are
invalid. Olympus also did not recognize the repository's
`LicenseRef-Biopython-License-Agreement`, and no permitted-license confirmation
was obtained.

- Repository: `biopython/biopython`
- Pin: `c9489604d1d9607602ca9199a3852c1219ed330f`
- Task: public materialization of a selected PDBx/mmCIF biological assembly
- Candidate rating: **7/10**, escalated at the user's request

The proposed reference crosses expression parsing, non-commuting affine
composition, row/asym selection, model preservation, recursive disorder
ownership, collision-free output identity, and pre-copy validation. A pristine
Docker image passed all 514 official offline tests as UID 10001. Exact evaluator
composition passed 11/11 base tests and 30/30 focused tests on the reference;
the pristine tree failed all 30 focused cases behaviorally. Gap, fairness, and
false-positive verdicts appeared to pass in that non-platform environment, and
all 25 isolated mutants were killed. Ten
meaningful former survivors also pass the complete 515-test pre-existing suite.

No local or platform solver calibration started, and no run is counted. The
four submission artifacts are preserved unchanged as a rejected audit snapshot
and must not be submitted or calibrated. Reconsideration requires explicit
license approval, correction to an approved Olympus base and `/app`, and every
gate rerun from zero on the new immutable version.
