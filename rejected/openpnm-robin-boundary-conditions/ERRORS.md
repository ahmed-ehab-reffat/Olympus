# Errors and corrections - OpenPNM Robin boundary conditions

## 2026-08-01 editable-environment contamination

The first test-only replay unexpectedly passed 13/13 because the reused virtual
environment contained an editable install pointing to the disposable reference
tree. That result was rejected immediately. A new virtual environment was
created inside the clean verification worktree, its imported `openpnm.__file__`
was checked, and the test-only lane then failed all 13 tests as intended.

## 2026-08-01 clone materialization failures

Two clone attempts initialized Git metadata without materializing usable refs.
No source was overwritten. A detached worktree was created from the already
verified candidate repository instead. These clone attempts are environment
noise, not semantic candidate failures.

## 2026-08-01 dependency drift

The frozen pin's committed lock is stale. An unconstrained fresh environment
passes the focused lanes but fails 29 complete-suite tests for unrelated NumPy
and optional-IPython compatibility. This was resolved with a digest-pinned
Python 3.13.11 image and the known-good dependency set. The supported pristine
suite now passes with only the documented optional Netgen and Pardiso lanes
excluded; the exact task wrapper runs unchanged.
