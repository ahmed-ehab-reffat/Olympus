# Environment - h5py VDS reconstruction and relocation

Status: `recreated from empty local image/cache and verified for redesign`.

| Component | Version / identity |
|---|---|
| Source pin | `2412db7ab71c52f3937e8cf6b966cbb189b7c2b3` |
| Base | `public.ecr.aws/d3j8x8q7/olympus-base:latest@sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f` |
| Rebuilt image | `sha256:f093210f23730cf9fc3c2f15606ceb30c20dc059308578521c9bce5898db8a4c` |
| Python / HDF5 | 3.12.13 / 1.10.8 |
| NumPy / Cython | 2.5.1 / 3.2.9 |
| pytest / pytest-mpi | 9.0.3 / 0.6 |

The image was previously recreated with `docker build --pull --no-cache` after
the local image and cache were deleted. The unchanged Dockerfile pins direct
apt/Python dependencies and installs h5py editably, so post-build source edits
are live from repository-root and out-of-tree pytest entry points.

All redesign verification ran with `--network none`: both patch orders, the
41-entity focused suite, 138 selected regressions, 44 isolated mutants, three
saved-solver replays, and the RuntimeError positive control. The solution-only
complete suite ran unprivileged as `nobody`: 842 passed, 60 skipped, and 3
subtests passed. Sphinx is not installed, so RST was patch-checked and inspected
but no documentation build is claimed.
