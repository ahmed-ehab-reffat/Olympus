# OpenPNM Robin boundary-condition problem design

Status: **closed after immutable version 2 failed the local calibration pre-filter**.

## Frozen candidate

- Repository: `PMEAL/OpenPNM`
- Pin: `86d9855f7799a5523dd9e579ba94693d3caa27ec`
- Language: Python
- Task type: feature request
- Scope: static finite Robin boundary conditions for scalar steady, reactive,
  and transient transport

## Trajectory-informed startup gate

The root `PROBLEM_DESIGN.md` gate was repeated for promotion. Searches covered
`problems/README.md`, `candidates/CANDIDATES.md`, `candidates/SUCCESSES.md`,
candidate records, problem records, and archives for OpenPNM, pore networks,
Robin/mixed/third-kind/convective boundary conditions, sparse transport,
reactive transport, and transient transport. No prior OpenPNM problem or direct
transport trajectory exists.

The candidate-stage disposable trial is the direct repository evidence: its
reference crossed BC lifecycle, sparse assembly, topology validation, reactive
source exclusion, and transient execution, passing 11 focused tests and the
complete 774-test unit suite. It is not a solver trajectory and is not treated
as calibration evidence.

Representative direct solver categories are unavailable: there is no OpenPNM
legitimate pass, near-pass, or broad failure. The gate therefore uses repository
behavior plus the previously inspected Calamine pass and broad failure only as
general evidence that inherited paths must be observed and that a solver's own
tests plus the baseline can miss native semantics. No Calamine implementation
detail is transferred into this task.

## Public behavior and discriminator ledger

| Evidence | Plausible incorrect shortcut | Public invariant | Black-box oracle | Distinct boundary and anti-overfit rationale |
|---|---|---|---|---|
| Rate BCs edit the RHS while value BCs eliminate rows and columns | Model Robin as a fixed rate or value | Exchange depends on both the unknown pore value and the external value | Exact finite-coefficient one-dimensional solutions at unlike coefficients | Matrix/RHS coupling; distinguishes Robin semantics rather than storage |
| Existing BC APIs support add, overwrite, remove, clear, and mutual exclusion | Store ambient value and coefficient non-atomically | A Robin condition is one logical BC throughout its lifecycle | Failed overlap, overwrite, selective removal, and clear-all state followed by solves | Public lifecycle; accepts any coherent representation |
| Connectivity validation recognizes constrained components | Assemble connected examples only | A valid positive Robin condition anchors its disconnected component | Two disconnected components constrained only by Robin conditions | Topology boundary, not another algebra fixture |
| Reactive source exclusion iterates BC kinds | Add Robin state without coordinating source conflicts | Sources and every BC kind remain mutually exclusive | Both operation orders plus ordinary value/rate regressions | Independent reactive coordination seam |
| Transient algorithms reuse transport assembly during integration | Patch only a steady run path | Static Robin exchange drives transient relaxation | Single-volume analytic exponential relaxation | Distinct execution pipeline |
| Transport caches pure matrices and rebuilds working state | Mutate cached pure state or accumulate the diagonal across updates | Repeated runs and changed Robin data behave from the current condition only | Re-run after coefficient/value changes and compare to a fresh algorithm | Cache/rebuild boundary, not private cache inspection |

Every planned discriminator is participant-facing, observable through public
algorithm behavior, and supported by repository architecture. Tests must not
require particular property names for private coefficient storage, helper
structure, sparse format, or exception wording.

## Candidate reference architecture

The disposable reference adds paired Robin state and public lifecycle methods,
adds the linear exchange contribution to the working matrix and RHS, recognizes
valid Robin anchors during topology validation, and accumulates all BC masks
when checking reactive sources. It changes two production files. This is one
legitimate architecture, not a required implementation.

## Promotion gates

The exact-version environment, four patch states, artifact hashes, and
false-positive audit are complete. Platform calibration remains at 0/10 and
must not start because the local pre-filter rejected the task.

## Promotion evidence recorded on 2026-08-01

The upstream audit is clean and the pin remains the current `dev` head. The
provisional prompt, test patch, and solution patch have been created. In an
isolated worktree-bound environment, test-only passed 37/37 adjacent tests and
failed all 13 focused tests; test plus solution passed both lanes at 37/37 and
13/13. The candidate's resolved environment also passed 774 unit tests with 12
skips.

The stale upstream lock was replaced at the problem-environment boundary by a
digest-pinned Python 3.13.11 image and fully pinned known-good dependencies.
With networking disabled, pristine passes 763 supported unit tests, test-only
passes 37/37 base and fails 13/13 new, and the reference passes 37/37 base,
13/13 new, and 776 supported unit tests. The two omitted upstream lanes require
optional Netgen and Pardiso backends and fail identically on pristine ARM.

The environment gate is closed. Version 1's silent-vector-resize survivor
passed 13/13 focused, 37/37 base, and 776 supported full-suite tests. Version 2
adds one public input-shape discriminator covering both mismatch directions.
The survivor then scores 13/15, the reference passes 15/15 and 778 supported
unit tests, and the other nine repository-grounded mutants are rejected by the
focused or genuine base lane. Exact hashes and isolation are recorded in
`FALSE_POSITIVE_AUDIT.md`.

## Local calibration evidence and terminal decision

After reading `CALIBRATION_STRATEGY.md`, two independent cold frontier attempts
were run against only the public version-2 prompt in detached worktrees at the
pinned commit. Hidden tests and the reference solution were applied only after
each solver exited. Full trajectories, solver patches, and grading logs are
preserved under `estimate_trajectories/`.

| Run | Solver architecture | Production patch | Focused | Base | Outcome |
|---|---|---:|---:|---:|---|
| `run_gpt-5.6-sol_1` | Paired Robin state in `Transport`, working matrix/RHS contribution, topology anchor, reactive conflict repair; also added its own public tests | 2 production files, 101 raw changed lines | 15/15 | 39/39 | clean solve |
| `run_gpt-5.6-sol_2` | Same paired-state and assembly architecture with a smaller reactive conflict repair | 2 production files, 82 raw changed lines | 15/15 | 37/37 | clean solve |

The 2/2 clean solve rate triggers the mandatory local hardening decision. The
trajectory review, however, exposes no fair hardening lever: both solutions
covered every distinct ledger family, and their shared architecture follows
the existing BC representation and transport assembly. The observed median raw
production churn is 91.5 lines, already below the 200 strict-effective-LOC
platform floor before comments, blanks, or mechanical lines are excluded.

Static Robin BC support is therefore an honest but compact OpenPNM change. More
fixtures would repeat existing discriminators, while adding nonlinear,
time-varying, serialization, or unrelated transport behavior would create a
different task rather than close a public gap found in these trajectories. The
problem is closed as too easy and too small; it must not receive platform runs
or artificial hardening.
