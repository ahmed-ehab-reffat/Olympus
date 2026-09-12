# UPSTREAM AUDIT - h5py VDS copy relocation

Audit date: 2026-08-07.

| Fact | Value | Primary source |
|---|---|---|
| Proposed base commit | `2412db7ab71c52f3937e8cf6b966cbb189b7c2b3` | local detached checkout |
| Repository | `h5py/h5py` | <https://github.com/h5py/h5py> |
| License | BSD-3-Clause | pinned `pyproject.toml` and `LICENSE` |

## Search ledger

The candidate audit searched open, closed, and merged issues and pull requests
for virtual dataset, VDS, copy, relocate, relative path, same file, external
source, `virtual_sources`, and `H5Ocopy`; enumerated open pull requests; checked
the HDF Forum; and inspected default-branch code/history. GitHub Discussions are
disabled for h5py.

No exact issue, pull request, or forum topic owns persistent VDS mapping
relocation during object copy.

Nearest work:

- issue #1546 and merged PR #1622 store `.` for same-file VDS sources and
  explicitly discuss the copy-to-another-file ambiguity;
- merged PR #1905 exposes property-list reconstruction and unlimited VDS
  selection behavior;
- issue #1305 concerns access-time virtual prefixes, not persistent repair;
- open issue #2690 concerns access modes/locking for external sources; and
- PRs #2662, #2884, and #2931 concern file-path attributes, external-path
  security documentation, and GIL release around native copy respectively.

## Maintainer alignment and scope

The additive direct-Dataset option fits `Group.copy()` and existing VDS
inspection/construction APIs. HDF5's documented relative-path resolution makes
the source-identity defect observable. The access-time virtual prefix cannot
make an independently opened copy preserve its original relationships.

Recursive relocation remains unsupported by upstream policy. If a copied group
contains both a VDS and the object named by `.`, following the copied object and
preserving the original file are both coherent; custom traversal would also
have to reproduce hard-link and reference-expansion semantics.

## Verdict

`proceed as an uncalibrated direct-feature experiment`: no exact upstream owner
was found and Level 1 is locally verified. Do not broaden into recursive group
semantics. The compact one-file reference remains a calibration risk rather
than an ownership defect.
