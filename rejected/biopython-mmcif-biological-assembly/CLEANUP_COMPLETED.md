# Cleanup completed

Cleanup completed on 2026-08-14 after archive validation.

## Removed active locations

- `problems/biopython-mmcif-biological-assembly` moved to
  `archive/biopython-mmcif-biological-assembly/problem-records`.
- `candidates/biopython-mmcif-biological-assembly` moved to
  `archive/biopython-mmcif-biological-assembly/candidate-records`.
- `Work/biopython-mmcif-biological-assembly`, a 360 MB disposable checkout
  containing 8,161 files and 725 directories, moved to the macOS Trash. It can
  be recovered from Trash until the user empties it.

Before cleanup, the working checkout's complete production diff matched the
archived `solution.patch` byte-for-byte, its complete evaluator diff matched
the archived `test.patch` byte-for-byte, and the baseline clone was clean. No
unique implementation or test change was discarded.

## Removed Docker resources

- image `olympus-biopython-mmcif:immutable`
  (`sha256:51e2639a04ad70ee206858551b1843758e925fe66c255c1aaf548fb16cb40c3f`);
- image `olympus-biopython-mmcif:final`
  (`sha256:b7427bd840a23fa6f6828bf1232fba8e95ca221699b612151ba36c5058ef37bc`);
- image `olympus-biopython-mmcif:phase-a`
  (`sha256:48c3ffc804782f66d8c640eb3671e8a4d77e41e394bdee980f96842d8ea83873`);
  and
- volume `olympus_biopython_work_0811`.

No Biopython task container existed. Shared base images, unrelated Docker
resources, and global caches were not pruned. The removed images and dependency
volume are disposable; images can be rebuilt from the archived Dockerfile and
repository pin, while the volume's cache contents are not recoverable.
