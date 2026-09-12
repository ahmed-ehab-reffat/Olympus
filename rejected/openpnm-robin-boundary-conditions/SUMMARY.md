# Summary - OpenPNM Robin boundary conditions

Status: **closed on 2026-08-01 after failing the local calibration pre-filter**.

The selected feature adds static Robin boundary conditions to OpenPNM scalar
transport. The frozen candidate trial passed 11 focused tests and the complete
774-test unit suite at `86d9855f7799a5523dd9e579ba94693d3caa27ec`.

The fresh upstream audit is clean and the pin remains the upstream `dev` head.
The provisional package has a public prompt, a 13-test focused lane, a 37-test
adjacent lane, and a 60-addition/2-deletion reference across two production
files. In an isolated worktree, test-only passes 37/37 and fails 13/13, while
test plus solution passes 37/37 and 13/13.

The stale upstream lock no longer blocks the task. The Dockerfile pins the
Python base by digest and freezes the known-good dependency set. With networking
disabled, pristine passes 763 supported unit tests; test-only passes 37/37 base
and fails 15/15 new with valid JUnit; the reference passes 37/37 base, 15/15
new, and 778 supported unit tests. Optional Netgen/STL and Pardiso tests are
excluded on ARM and fail identically at the pristine pin.

The exact-version false-positive audit tested ten plausible incorrect
implementations. Silent resizing survived version 1's focused, base, and full
suites, so version 2 added a single public input-shape discriminator and reset
the artifact to 0/10. The revised survivor fails only its two mismatch cases;
all other mutants are rejected by focused or genuine base tests.

Two independent cold `gpt-5.6-sol` attempts then solved immutable version 2
cleanly. Both passed 15/15 focused tests and their complete base lanes. Their
production patches changed only two files and had 101 and 82 lines of raw
production churn, with a median of 91.5, below the 200-effective-LOC
long-horizon floor even before strict exclusions. The task is therefore both
too consistently solvable at the local pre-filter and structurally too small.

The public contract is already complete for static Robin conditions. The two
successful implementations converged on the same repository-native seams and
did not reveal a missing behavioral invariant. Adding unrelated transport
features or representation-specific tests would be artificial padding, so this
problem is closed and must not be uploaded or given platform calibration runs.
Raw local trajectories remain in `estimate_trajectories/`; `LEVELS.md` and
`RUNS.md` record the terminal evidence.
