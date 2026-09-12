# Environment verification - OpenPNM Robin boundary conditions

Status: **frozen Linux offline lane verified on 2026-08-01**.

Base image: `python:3.13.11-slim-bookworm` at
`sha256:20080e807bfc404f8450b185cf0fc95d553462673598549613735f70a5b4d5d0`.

Verified image manifest:
`sha256:f1c3b3eb9e0e93a12081d1f660c951cfaf2bce6b16a0a4f4c00b0783b0fe9c62`.

## Frozen packaging resolution

The committed `uv.lock` is stale relative to `pyproject.toml`, so the
Dockerfile does not use it. It pins Python 3.13.11, the base-image digest, and
every resolved runtime/test package, then installs the participant checkout
with dependency resolution disabled. `pyamg` lacks a CPython 3.13 ARM wheel,
so `build-essential` compiles the pinned 5.3.0 source distribution.

The final image was built from a pristine checkout. Every verification command
then used `docker run --network none`:

- pristine supported unit suite: 763 passed, 10 skipped, 1 deselected;
- test patch only: base 37/37 passed; new 0/15 passed with process status 1 and
  well-formed JUnit XML;
- test plus solution: base 37/37 and new 15/15 passed;
- test plus solution supported unit suite: 778 passed, 10 skipped, 1 deselected.

The broad command excludes `tests/unit/io/STLTest.py`, which requires optional
Netgen, and deselects `test_pardiso_spsolve`, whose optional Linux Pardiso
backend is unavailable on ARM. Both fail identically on the pristine image and
are unrelated to the changed transport/source files. The complete adjacent
transport lane remains in `test.sh base`.

Dockerfile SHA-256:
`2617a1e4da599b407473db73b16090a8521f121338f4bafd4cb7714490e685b5`.
