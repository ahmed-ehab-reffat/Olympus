# eval-results — lyon-stroke-to-fill

No agent batches run yet (smoke batch deferred per user). Local + real-Docker validation only.

## Real Docker validation (2026-07-25) — non-root, offline, both patch orders (pre-FP-check, 35 tests; re-run at host level post-FP-check, 38 tests, same shape)

| Stage | base | new |
|---|---|---|
| clean checkout (no patches) | builds OK | n/a |
| + test.patch only | 185 pass, 0 fail | build-fail fallback, 1 failing testcase, exit 101 (correct) |
| + solution.patch | 185 pass, 0 fail | 38 pass, 0 fail |
| reverse order (solution then test) | 185 pass, 0 fail | 38 pass, 0 fail |

Two real environment bugs found and fixed via actual `docker build` + `docker run --network none --user 1000:1000` (host-only `cargo test` did not catch either):
1. `cargo build --workspace` pulled in unrelated heavy GPU example crates (`examples/wgpu`, wayland/x11rb deps) since they are explicit workspace members. Fixed: scope to `cargo build -p lyon_tessellation --tests`.
2. Non-root user could not `git apply` (create `test.sh`) inside the container — `/app` was root-owned from `COPY`. Fixed: `chmod -R a+rwX /app` (not just `/app/target`, and not `/root`).

## Local (host cargo) validation log (2026-07-25, post-FP-check)

| Check | Result |
|---|---|
| base (no solution) | 185 pass, exit 0 |
| new (no solution) | build-fail fallback, exit 101 |
| base (solution) | 185 pass, exit 0 |
| new (solution) | 38 pass, exit 0 |
| both apply orders | identical, green |
| reverse-apply | clean both patches |
| new determinism | 3x identical (38 pass) |
| LOC | Counter-1 342, Counter-2 human-effective 250 (exactly at floor) |

## FP check (2026-07-25) — bidirectional alignment, full detail in feedback.md

4 real gaps closed (PathSlice untested, start/end cap always-identical, zero-length-square untested, zero/negative line_width untested) + 2 unfair hidden-requirement tests removed (undisclosed `stroke_to_fill_events` free function now private, exact-vertex-count implementation-detail test). Net 35 -> 38 tests.

## Mutation proof (every wall discriminates, FINAL 38-test suite)

| Mutant (wrong impl) | Tests failed |
|---|---|
| naive quad-only (no joins, no caps) | 8 |
| region-correct but overlapping (no dissolve) | 5 (even-odd walls) |
| miter never clamped | 3 |
| closed-loop interior filled | 3 (annulus walls) |
| shared `compute_normal` scale-inversion (S3) | 2 (pre-existing, unrelated base tests) |
| NaN/Infinity `line_width` guard reverted | 2 |
| broken `PathSlice` impl (no-op) | 1 |
| start/end cap confused | 1 |
| zero-length Square routed to Round | 1 |
| `is_finite`-only guard (drops `>0.0`) | 1 (negative width) |
| skip `.flattened(tol)` entirely | 1 (tolerance clause) |

All failure sets pairwise disjoint across every mutant tried (zero overlap) — confirmed orthogonal.

## Discriminator map (test -> requirement)

- even-odd walls (backtracking / self-crossing / inner-corner / area-agree) -> output is SIMPLE (dissolve).
- miter walls -> miter_limit fallback + MiterClip + below-one clamp.
- cap walls -> butt/square/round + zero-length disc/square, start/end independence.
- annulus walls -> closed subpath: no caps, interior empty, correct winding.
- curve wall -> flatten within tolerance.
- PathSlice wall -> both `Path` and `PathSlice` impls behave identically.
- NaN/Infinity/zero/negative wall -> `line_width` not positive-finite -> empty path.
- S3 wall (compute_normal) -> shared machinery correctness, caught by BASE tests only, not new tests.

## Pending

- Nova/Orion/Vega batch (10+) for pass-rate confirmation. Projection ~10-25%, lead wall = dissolve.
