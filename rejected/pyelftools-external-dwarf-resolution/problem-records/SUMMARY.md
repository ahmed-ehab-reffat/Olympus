# Summary - pyelftools external DWARF resolution

Status: **rejected for overlap and archived on 2026-08-20;
calibration 0/10**.

- Repository: `eliben/pyelftools`
- Pin: `e5fa2a4f3e665d082cfc453fd0877f5516200926`
- Production language: Python
- Task type evaluated: enhancement
- Rating: 4/10 current; 9/10 preliminary

The candidate would have completed external DWARF discovery through standard
debuglink locations, explicit debug roots, GNU build IDs, identity validation,
per-hop supplementary rebasing, no-follow behavior, and cycle termination.
The source has direct TODOs and incomplete loader propagation, so the task was
technically coherent.

It is not eligible. Open pyelftools issue #186 gives the exact conventional
`.build-id/xx/yyyy.debug` scenario and asks for separate-DWARF correlation; the
maintainer marked it unsupported and invited a pull request. Merged PR #596
implemented sibling `.gnu_debuglink` plus CRC validation but expressly left
build-ID linking unsupported. The issue remains open and the default branch is
still the pinned commit.

The escalation began with a 2-4/10 fresh solve forecast. Removing the owned
build-ID/debug-root center leaves a small one-module loader-rebasing and cycle
task, forecast 7-10/10 and outside the accepted 1-5/10 band. No exact problem
version exists, so neither estimate is an observed replay.

No environment gate, prompt, hidden test, reference patch, Dockerfile,
prototype, mutation, solver, or calibration run was started. Do not resubmit
this external-DWARF resolver task unchanged or cosmetically narrowed.
