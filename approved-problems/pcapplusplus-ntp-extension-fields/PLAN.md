# PLAN - PcapPlusPlus NTPv4 extension fields

Status: `version-3 prompt, reference, and Docker verified; false-positive re-audit pending;
calibration 0/10`.

1. [complete] Preserve base commit
   `8ac4366c4184f096973ef4a0ca084559935828d0` and the candidate audit hashes.
2. [complete] Freeze the maintainer-facing API and byte contract from `DESIGN.md` without
   exposing a private partition/scanner architecture.
3. [complete] Add a separate deterministic Packet++ test executable plus a two-mode
   `test.sh` that emits JUnit XML and runs fully offline.
4. [complete] Verify test-only state: complete existing Packet++ baseline passes and every
   named new entity fails behaviorally or at the required missing API.
5. [complete] Generate a production-only `solution.patch` from the repository-shaped
   reference; keep prototype tests out of the reference patch.
6. [complete] Verify both patch orders and all four states: base, tests only, solution
   only, and tests plus solution.
7. [complete] Run exact formatter/tidy/diff checks and focused ASan/UBSan.
8. [complete] Perform the exact immutable prompt/test/reference false-positive audit,
   record actionable and rejected survivors, and freeze artifact hashes.
9. [complete] Update `SUMMARY.md`, `LEVELS.md`, `RUNS.md`, `ERRORS.md`, repository indexes,
   and candidate handoff records.
10. [complete] Do not start or recommend solver calibration in this plan. Any artifact
    edit after the final audit creates a fresh version requiring all local
    gates and false-positive checks again.
11. [complete] Replace the validator-incompatible specialized C++ base with the
    permitted generic Olympus base, install CMake explicitly, build the exact
    Dockerfile, and replay the ordinary test-only and combined lanes.
12. [pending] Re-run the required false-positive audit before approving version
    3 or starting calibration. This check was intentionally not run during the
    revisions at the operator's direction.
13. [complete] Apply the platform review: remove redundant compatibility prose,
    specify return types/header visibility/failure signaling, make borrowed-view
    purge non-destructive, and replay the unchanged ordinary test matrix.
