# LEVELS - PcapPlusPlus TLS stream reassembly

Calibration batches are bound to one immutable artifact version. Results below
are historical evidence and are not carried into the revised version.

## Abandoned version: `agent-runs1`

Artifact identifiers at the time of the five-run Nova batch:

- `meta.md`: `4770a1187684766160bdf89379aa1a8fffc2a489ebf48212172164b81a05d57b`
- `test.patch`: `3a36fb7acd45f9072bc6fcafeddf91a08749127c3065c3e65c308901f56c6e5a`
- `solution.patch`: `912013a4eaba9100df9448aeb29806b7aa968e1390aecf5b0b26afb19e3e1b28`
- `Dockerfile`: `db856366a98e81addef3565da1710d827a35344bf66af2109be2052a480d25e6`

The saved records identify the solver as Nova but do not encode a separate
level label.

| Run | Original evaluator outcome | Trajectory-informed interpretation |
|---|---|---|
| `Nova_Nova_1` | `FAIL_MISSED_REQUIREMENT` | all focused tests passed, but the exact-limit split-prefix bug was real |
| `Nova_Nova_2` | `PASS_LEGITIMATE` | legitimate |
| `Nova_Nova_3` | `FAIL_TEST_MISMATCH` | copyability mismatch was unfair; after repair, replay also exposes the exact-limit bug |
| `Nova_Nova_4` | `PASS_LEGITIMATE` | legitimate |
| `Nova_Nova_5` | `PASS_LEGITIMATE` | legitimate |

The description and hidden tests were changed after this evidence. Under the
immutable-batch rule, this batch is abandoned and none of its five runs counts
toward calibration of the revised problem.

## Abandoned version: `agent-runs2`

Artifact identifiers at the time of the second five-run Nova batch:

- `meta.md`: `15ba9aa095af8fbbef018f23e1c0b159866f888721ca1eab4b5fa3eb5e6ed4b0`
- `test.patch`: `314fa30c1204cdd3df4a5e2a9ff81196ec06107a384c096b9b3f2b2fa0f39cd4`
- `solution.patch`: `912013a4eaba9100df9448aeb29806b7aa968e1390aecf5b0b26afb19e3e1b28`
- `Dockerfile`: `db856366a98e81addef3565da1710d827a35344bf66af2109be2052a480d25e6`

All five baselines passed. All five focused targets failed at the same
compile-time integration seam: the solutions returned raw integer wire types
where the hidden API expected Packet++ SSL types. The description and hidden
tests were revised after reviewing the raw trajectories, so this 0/5 batch is
abandoned and contributes no run to the current version.

## Current version

- `meta.md`: `1f1bede4ecb0f6a9e88e5121e9bcb7f1148b9acc16c2e14861b89016edda262e`
- `test.patch`: `27ed90ce46b01ec084237a7bc357b8519b381fd6417ae5e9d47d6b6d3142d347`
- `solution.patch`: `0486854afd97a761ae1bbd04e6f25777eb3da6593958c709b8cefe26d399d245`
- `Dockerfile`: `db856366a98e81addef3565da1710d827a35344bf66af2109be2052a480d25e6`
- Calibration status: `0/10`

The final verification reran ten exact saved solvers, five interface-normalized
second-batch diagnostics, 59 isolated mutants, the four-lane package matrix,
the 259-test Packet++ regression, and an independent buffered-rejection
implementation. These are verification evidence only. No cold solver was run
for this version.

## Platform outcome

The platform accepted the exact current version on 2026-08-08. This is a
user-confirmed outcome. Acceptance does not retroactively convert either
abandoned batch into final-version calibration; the local final-version count
remains 0/10.
