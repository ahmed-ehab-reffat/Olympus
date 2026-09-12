# False-positive audit - OpenPNM Robin boundary conditions

Status: **complete for immutable version 2 on 2026-08-01**.

Pin: `86d9855f7799a5523dd9e579ba94693d3caa27ec`

All trials used the digest-pinned Python 3.13.11 Dockerfile and
`docker run --network none`. The supported full-suite command excludes the
optional Netgen STL file and deselects the optional Pardiso solver test, both of
which fail identically on pristine ARM and are unrelated to this feature.

## Immutable artifact identities

| Artifact | SHA-256 |
|---|---|
| `Dockerfile` | `2617a1e4da599b407473db73b16090a8521f121338f4bafd4cb7714490e685b5` |
| `meta.md` | `d194cc1513d9825eaf3d8ac73e1316e2a420a4107ee67c953da8451cd630092f` |
| `test.patch` | `d5175fd63e1b41936dd8b304a2d1ace322d007cbcfe225862d6cc08064b89450` |
| `solution.patch` | `9fa5a57948198af7378fa19d6a74865feb3ecd76d346d3b70435f197f4ba9dbf` |

Verified local image manifest:
`sha256:f1c3b3eb9e0e93a12081d1f660c951cfaf2bce6b16a0a4f4c00b0783b0fe9c62`.

## Requirement map

| Participant-facing requirement | Strongest behavioral oracle |
|---|---|
| Robin exchange uses the external/current difference and a positive finite coefficient | Exact steady scalar, unlike vector, and analytic transient solutions |
| Scalar or exactly one value/coefficient per selected pore | Vector solution plus both mismatched-length rejection cases |
| Add, overwrite, remove, clear, atomicity, and BC conflicts | Lifecycle and failed-overlap state test |
| Reactive source mutual exclusion in both operation orders | Two focused Robin/source tests plus existing value/rate source regressions |
| Disconnected components are constrained | Two-component Robin-only topology solve |
| Base and reactive parity | Reactive exact solution |
| No stale accumulated contributions | Repeated run and overwrite solution test |

## Mutation results

| ID | Plausible incorrect implementation | Focused result | Isolation / broad result |
|---|---|---|---|
| M1 | Add only `h*x_inf` to the RHS, treating Robin as a fixed rate | 9/15 | Six failures span steady, reactive, topology, repeat, and transient behavior |
| M2 | Promote Robin ambient values to Dirichlet values | 10/15 | Five algebra/pipeline failures |
| M3 | Accept zero, negative, infinite, and NaN coefficients at set time | 11/15 | The four coefficient parameter cases fail |
| M4 | Write Robin ambient state before generic conflict validation | 6/15 | Atomic lifecycle and downstream solves fail; no survivor |
| M5 | Remove/clear ambient values while retaining coefficients | 14/15 | Only lifecycle cleanup fails, providing distinct isolation |
| M6 | Omit Robin pores from topology anchors | 14/15 | Only the disconnected-component probe fails |
| M7 | Revert reactive BC-mask accumulation to last assignment | 15/15 | Focused survivor, but base is 35/37: existing reactive and transient value/source regressions fail. It is rejected by the required regression lane without a new fixture |
| M8 | Suppress Robin assembly for transient algorithm classes | 14/15 | Only analytic transient relaxation fails |
| M9 | Mutate cached pure matrix state while also updating the working matrix | 12/15 | Reactive, repeated-run, and transient cases fail |
| M10-v1 | Silently resize mismatched value or coefficient vectors | 13/13 focused, 37/37 base, 776 supported full suite | Actionable survivor; the public scalar/per-pore contract was not enforced |
| M10-v2 | Same silent-resize implementation against revised tests | 13/15 | Both mismatch directions fail and the other 13 tests remain passing |

## Actionable survivor and revision

M10-v1 was a compiling, repository-plausible false positive grounded in the
public input contract. It passed the complete attempted version-1 oracle, so a
single parameterized discriminator was added. It rejects a value vector longer
than the selected pore set and, independently, a coefficient vector longer than
that set. Each case also verifies that failed validation leaves both logical
halves unset. This is one input-shape/atomicity boundary, not arbitrary vector
permutations.

The prompt already said inputs are scalar or per-pore, so it did not change.
Changing `test.patch` created immutable version 2 and restarted the audit at
0/10. No version-1 result is counted as calibration evidence.

## Rejected and artificial follow-ups

- Additional negative coefficient magnitudes and NaN placements repeat M3.
- Pore-order permutations repeat the exact vector solution without a new
  semantic boundary.
- Private property names, sparse storage format, exception wording, and helper
  structure are not tested.
- Optional solver choices, Netgen output, timing, and matrix-cache identity are
  outside the public feature. M9 is checked through repeated public results.
- M7 needs no focused duplicate because the genuine base lane already rejects
  it in two independent existing algorithm families.

## Final exact-version verification

- pristine supported suite: 763 passed, 10 skipped, 1 deselected;
- test patch only: base 37/37 passed; new 0/15 passed with nonzero status and
  well-formed JUnit;
- test plus solution: base 37/37 and new 15/15 passed;
- test plus solution supported suite: 778 passed, 10 skipped, 1 deselected;
- M10-v2: 13/15, failing only the two new mismatch cases;
- `git diff --check`: passed.

No direct OpenPNM solver patches exist to replay. The trajectory search and its
absence are recorded in `DESIGN.md`; no unrelated patch was substituted. The
attempted mutation set has no survivor across the exact version-2 focused and
base lanes. This closes the mandatory false-positive gate for this immutable
version, not the possibility of all future false positives.
