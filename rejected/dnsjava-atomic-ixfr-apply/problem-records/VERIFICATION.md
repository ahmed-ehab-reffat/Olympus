# Verification - dnsjava atomic IXFR application

Repository pin: `06a0599933114f36efe59667cd80ee0246a1a882`.

## Exact result

The cold image built from the untouched checkout and ran offline as UID/GID
10001. Phase A passed **1,739 tests with 0 failures, 0 errors, and 29 skips**.

| Exact composed tree | Base | Feature |
|---|---:|---:|
| pristine | 121/121 | 0/17, all named failures, 0 errors |
| reference | 121/121 | 17/17 |
| legitimate trial A | 121/121 | 17/17 |
| legitimate trial B | 121/121 | 17/17 |
| direct in-place trial C | 121/121 | 6 failures, 1 error |

Every tree has exact base and feature testcase-name parity. The reference plus
hidden tests passes Spotless and the complete **1,756-test** combined tree with
29 skips and no failure/error.

## Static and mutation checks

- `git apply --numstat solution.patch`: 119 additions in
  `src/main/java/org/xbill/DNS/Zone.java`.
- `git apply --numstat test.patch`: 733 additions in the randomized JUnit file
  and 73 additions in `test.sh`.
- `git diff --check`: pass in all five exact composition trees.
- Three isolated final discriminators each reject exactly one compiling
  predecessor survivor.
- The broad direct-loop shortcut passes the selected existing lane and fails
  behaviorally in the feature lane.

The Docker content-store incident belongs only to a superseded draft batch. It
was quarantined before results were interpreted, the daemon was repaired, the
image was rebuilt without cache, and all exact gates above restarted from zero.

## Verdict

Environment, reference, gap, fairness, false-positive, formatting, patch
composition, and full regression verification pass for the hashes in
`ARTIFACTS.sha256`. Solver calibration has not begun.
