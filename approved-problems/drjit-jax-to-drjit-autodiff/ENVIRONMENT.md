# Environment verification - Dr.Jit JAX-to-Dr.Jit autodiff

Status: `post-vmap hardening plus Python-scalar contract correction passes Phase A/B; all executable results are unchanged, all five retained solvers complete their base lanes, and the initialized-submodule platform replay passes`.

Repository: `mitsuba-renderer/drjit` at `c0798bb752172e8ced661443cf308dc3a19d678c`. Artifact identity is the four-hash set recorded in `DESIGN.md`.

## Quarantined blockers

External evaluation rejected the predecessor before tests. Its image builder appended `pip install --system`, which the base image's pip does not support, and static review separately rejected `python -m pip install ...` in `test.sh`. This was an environment failure, not a solver result. The affected batch was quarantined, no run counted, and calibration restarted at 0/10.

The next platform build supplied initialized `ext/drjit-core` and `ext/nanobind` submodules. Their `.git` pointer files collided when full cloned repositories, containing `.git` directories, were copied over them. This was another pre-test environment failure. That run was quarantined and did not count toward calibration.

The first editable-install revision exposed scikit-build's redirecting finder to the evaluator overlay. Baseline tests imported `/app` instead of the private composed runtime and collected unsupported CUDA variants. A plain path-file normalization still left the redirecting hook active. Both runs were quarantined as environment failures. The final harness disables site initialization only for evaluator lanes, and the editable build is independently normalized and checked for ordinary solver use.

The next exact image passed the focused lanes, but the requested full
`python -m pytest tests` run aborted in
`tests/test_arithmetic.py::test_minmax_nan`. LLVM 16 reported the AArch64 host
as CPU `generic` with `+neon,+fp-armv8,+crypto,+lse,+crc`; because this list was
nonempty, Dr.Jit's AArch64 fallback did not add `+fullfp16`. LLVM then failed to
select a vector half-precision `fminimum` and aborted the interpreter. This was
an environment blocker, so the run was quarantined and calibration remained
0/10.

The following exact image made bare `python -m pytest` recurse into
`ext/nanobind` because `pyproject.toml`, which carried the repository's
`norecursedirs = ["ext"]` setting, had been moved after installation. Pytest
reported 22 vendored-extension collection errors. The separately requested
native test build then reused the editable install's scikit-build cache at
`/app/build/cp312-cp312-linux_*` and aborted in `test_call_ext` with a nanobind
fatal condition. A fresh cache removed the abort but enabled unavailable CUDA
variants unless the CPU-only backend choices were retained. These were
environment blockers, not failed implementations; the affected run remained
quarantined and calibration stayed at 0/10.

## Final image design

The submitted image starts from the approved Python base and uses only `WORKDIR /app`. CUDA, Metal, and OptiX are disabled; the CPU LLVM backend remains enabled. Exact source dependencies are fetched only during image build:

- drjit-core `8574d491f9e8657ebf19b60dd624249ab8771cc4`
- nanobind `86e5626728fc282637a6c338597120913dded1bb`

Every Python package named in the Dockerfile has an exact version and pip runs with `--no-deps`. CMake first builds the pristine CPU runtime into `/opt/drjit-runtime`. The project is then installed with `pip -e .` using the same CPU-only CMake definitions. Its compiled files and generated configuration are placed beside the live `/app/drjit` sources. The duplicate site-package tree is removed, and a plain path file exposes `/app` without forcibly outranking an explicit build-tree `PYTHONPATH`. The image moves `/app/pyproject.toml` to `/opt/drjit-pyproject.toml` only after that install, so the platform's appended conditional installer sees neither `pyproject.toml` nor `requirements.txt` and does not invoke its invalid `pip --system` branch.

Because moving `pyproject.toml` also removes upstream pytest configuration, the
image writes an equivalent `pytest.ini` that excludes vendored `ext` and
generated `build` trees from bare repository-root discovery. It also discards
the scikit-build cache produced by the editable install and configures a clean
Release/Ninja cache at the same conventional platform path with CUDA, Metal,
and OptiX disabled and LLVM enabled. Solvers can therefore run the source suite
directly or enable native tests in the conventional cache without mixing
stable-ABI build state or silently enabling an unavailable backend.

Before dependency copies, the Dockerfile removes only `/app/ext/drjit-core` and `/app/ext/nanobind`, then recreates them from the exact clones. This accepts both uninitialized and initialized build contexts without mixing Git pointer files with cloned repository metadata.

The staged drjit-core receives one host-viability correction before CMake runs.
When and only when LLVM reports an AArch64 triple, CPU `generic`, and no
`+fullfp16`, the Dockerfile preserves the reported feature list and appends
`+fullfp16`. Other architectures, identified ARM CPUs, and ARM targets already
reporting the feature are unchanged. LLVM 16 accepts the resulting target and
the former `Float16` minimum reproducer passes all nine parametrizations.

The harness performs no build or package installation. For each lane it copies `/opt/drjit-runtime` to a private temporary directory and overlays the candidate's `drjit` Python package. Python starts with site initialization disabled and receives the private runtime followed by the installed dependency directory on `PYTHONPATH`. This isolates evaluator composition from the editable hook while keeping the compiled ABI fixed and exposing participant changes across the Python package, including `drjit/interop.py`.

Runner modes and runtime-overlay details are intentionally documented only in this internal environment record. They are not part of the public problem description or its implementation requirements.

## Phase A

The untouched repository image built from a no-`.git` context and started
offline as arbitrary UID/GID `10001:10001`. The current no-cache build exported
config `sha256:e9b140f26b9f5c10d6b2fbfdb5170552a2fd70330c7355e2d373309d8d4c955c`,
payload manifest
`sha256:c1508bcd0824bb6eba0c654f1e1e74056b70a740f520a5d53dbd134d6402151b`,
attestation
`sha256:910e371ba03102301e3e906acb5f0fa2c9da6f10a9ca0934ae5c667704cf9c68`,
and manifest list
`sha256:5661fccdd3a3b9c1969dc2ad43060f8c9e558bf803092449ffa8de9d6e7d431c`.
The retained clean-cache image has the same submitted Dockerfile and runtime
inputs and was used only for the separate mutation and platform-context
replays.

| Field | Result |
|---|---|
| Runtime network | `none` |
| Python | `3.12.13` |
| Dr.Jit | `1.5.0` |
| JAX / JAXlib | `0.11.1` / `0.11.1` |
| NumPy | `2.5.2` |
| LLVM backend | active |
| Base discovery | 147 cases in `tests/test_wrap.py` |
| Ordinary import origin | `/app/drjit/interop.py` |
| Bare repository-root pytest | 8,324 passed, 1,246 skipped, 6 xfailed |
| Native build-tree pytest | 8,530 passed, 1,040 skipped, 6 xfailed |

## Phase B - final immutable version

The exact gate treated all five historical patches as representative
near-failure injection checks because none implements the newly public batching
surface. A separate exact behavioral replay then ran both lanes for all five.
The only submission change in this version is the Python-scalar clarification
in `meta.md`; nevertheless, the image and every composition lane were rerun.

| Composition | Base lane | New lane | Expected |
|---|---:|---:|---|
| pristine repository + test patch | 84 passed, 63 skipped | 22 failed | yes |
| pristine + solution patch + test patch | 84 passed, 63 skipped | 22 passed | yes |
| historical solver 1 + test patch | 85 passed, 63 skipped | 9 failed, 13 passed | expected rejection |
| historical solver 2 + test patch | 86 passed, 63 skipped | 8 failed, 14 passed | expected rejection |
| historical solver 3 + test patch | 84 passed, 63 skipped | 9 failed, 13 passed | expected rejection |
| historical solver 4 + test patch | 86 passed, 63 skipped | 7 failed, 15 passed | expected rejection |
| historical solver 5 + test patch | 85 passed, 63 skipped | 8 failed, 14 passed | expected rejection |

Every lane ran offline and non-root, emitted real JUnit in the gate, and used
the same feature testcase identities. No package install, network resolution,
patch conflict, hybrid tree, missing test, permission error, or startup
placeholder occurred. All five expected historical failures are behavioral:
none implements the newly public JAX batching boundary, and four also retain
their prior alias-cotangent failure.

## Initialized-submodule platform replay

Both top-level submodules and their recursive submodules were initialized in the build context, preserving the `.git` pointer files that caused the reported collision. The exact reported command was also appended after the submitted build:

```text
if [ -f pyproject.toml ]; then pip install --system -e . || pip install --system .;
elif [ -f requirements.txt ]; then pip install --system -r requirements.txt; fi
```

The dependency copy completed with exit 0. The initialized-submodule image
exported config
`sha256:5215fd7f2a9ea1c3fa396af0b0f8f045cc0f2d287d0a69fe0af48699584056f2`
and manifest list
`sha256:aabf9801de8f251b327fb8e60c4c9d2feac37103b0d0b1ce49b2669cd3534c9a`.
The appended conditional did not invoke pip because both conditions were false;
its layer completed with exit 0 and exported config
`sha256:e6a7602b377385b9f74a4162e013e680984d56cd67a226a25191566e0271c67f`
and manifest list
`sha256:2744514994327d33a8543e5967090930acaf43aada209365bc6c4f1267152b60`.

Ordinary Python launched from `/tmp` imported `drjit.interop` from
`/app/drjit/interop.py`. Running `python -m pytest tests/test_wrap.py` from
`/app` as UID 10001 produced 84 passed and 63 skipped. The current test patch
was replayed again in both the initialized-submodule image and its appended-
installer derivative: pristine failed 22/22, while the reference produced 84
passed and 63 skipped in the base lane and 22/22 in the feature lane. This
proves both live source visibility and current evaluator compatibility.

## Bare and native build-tree suites

The unchanged submitted Docker image previously ran bare `python -m pytest`
from `/app` offline. Pytest used `/app/pytest.ini`, collected 9,576 repository
cases without entering vendored or generated trees, and completed with 8,324
passed, 1,246 skipped, and 6 xfailed. The current correction changes only the
public description; it does not alter the image, source overlay,
evaluator-injected tests, or untouched source suite.

The exact reported native workflow was also replayed offline using the matching
AArch64 platform directory (the external report used the corresponding x86_64
name):

```text
cmake -S /app -B /app/build/cp312-cp312-linux_aarch64 -DDRJIT_ENABLE_TESTS=ON
cmake --build /app/build/cp312-cp312-linux_aarch64
PYTHONPATH=/app/build/cp312-cp312-linux_aarch64 python -m pytest /app/build/cp312-cp312-linux_aarch64/tests
```

CMake preserved the preconfigured LLVM-only backend, compiled all 138 targets,
and pytest completed with 8,530 passed, 1,040 skipped, and 6 xfailed. The
freshly built `call_ext` module loaded normally; neither the nanobind abort nor
the unavailable-CUDA failures recurred.

## Verdict

Pass for the immutable artifact hashes in `DESIGN.md`. Any change to the four submission artifacts, repository pin, dependency graph, or evaluator injection path invalidates this record and requires Phase A, Phase B, and the initialized-submodule appended-install replay again.
