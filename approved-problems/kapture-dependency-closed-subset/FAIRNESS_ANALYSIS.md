# Fairness analysis — kapture dependency-closed dataset subset, immutable v8

Verdict: `pass`.

Repository: `naver/kapture @ 8225b77d0657e6a3eb1ffc941d009100b792fb25`.

Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.

## Rejection-predicate provenance

| Predicate | Provenance | Implementation freedom | Verdict |
|---|---|---|---|
| API, selectors, graph closure, payload modes, return, and CLI | exact public prompt plus public model/readers | scans, indexes, pruning, reconstruction, copy strategies unrestricted | fair |
| same normalized source/output, including force | explicit identical-path rejection | normalization mechanism and exact message unrestricted | fair |
| absent/existing transactional failure | explicit transactional clause | preflight, staging, rollback, journal, backup accepted | fair |
| stale managed record/feature/match/tar paths are retired | explicit v8 successful-replacement clause and public path helpers | cleanup order and algorithm unrestricted | fair |
| unrelated nested files survive force | explicit v8 any-depth preservation clause | copy-overlay, preservation set, inverse overlay, merge accepted | fair |
| base, executable harness, and JUnit | evaluator contract | no product timeout imposed | fair |

## Ownership fixture

The destination is created through public kapture writers and payload helpers.
The test records four exact old managed paths before replacement: one referenced
camera payload, one ordinary descriptor payload, one match payload, and one
tar-backed keypoint archive. The forced replacement selects a different subset
and source producer mode, so none of those paths belongs to the new dataset.
Their absence follows the public stale-data clause rather than an unstated
minimal-tree policy.

Five byte-distinct unrelated files are placed at the root and inside the
standard record, tar-keypoint, ordinary-descriptor, and match directories.
They are not metadata, not model-referenced payloads, and do not use kapture
payload names. The test requires only their path and bytes to survive. Empty
directories and all other unreferenced paths are unconstrained.

## Transaction and identity fixtures

- A missing retained lidar payload proves that a fresh failure leaves no
  destination.
- A retained descriptor path replaced by a directory creates a public late
  materialization failure without prescribing decoding; any ordinary exception
  is accepted and the existing destination hash must remain unchanged.
- `source/.` is passed with `force=True`; identical locations must still be
  rejected before the source can become replacement state.

No exact error prose, malformed random bytes, private helper, temporary name,
filesystem call order, directory minimization, CSV order, tar member order, or
archive byte identity is asserted.

## Legitimate architecture replay

| Architecture | Distinct publication plan | Result |
|---|---|---:|
| `solution.patch` | copy old tree, delete an explicit old-owned path set, overlay staged subset, backup/commit | 181 passed, 5 skipped; 13/13 |
| `verify/architecture-b.patch` | start from staged subset, copy only old unowned files, backup/commit | 181 passed, 5 skipped; 13/13 |
| `agent-runs2/Nova_Nova_5` | repository-recognized selective cleanup in copied output | 181 passed, 5 skipped; 13/13 |

Runs 1–4 remain legitimate v7 implementations but violate the newly explicit
v8 any-depth preservation rule; each passes 12/13 and fails only that node.
Every logically distinct final rejection predicate is public,
repository-grounded, or part of the evaluator contract. No unresolved fairness
uncertainty remains.

