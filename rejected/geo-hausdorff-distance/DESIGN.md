# DESIGN — geo-hausdorff-distance

## 1. Title
Add Hausdorff distance between shape indexes (golang/geo, s2 package)

## 2. Shape classification
**O-Algorithm-correctness** (subtle algorithm; WRONG_LOGIC-heavy). Secondary flavor of O-Composite-add (new query surface reusing edge_query / contains_point_query / distance_target layers). Target pass ~8-12%, best agent Mixed (Vega + Nova->Orion). Cross-subsystem within s2: query layer + edge-distance layer + interior-containment layer + s1 angle layer.

## 3. Why golang/geo / this pick (gates cleared)
- Not in workspace / rejected / approved (dedup grep empty). Canonical org golang/geo. Active (last commit 2026-07-13). Apache-2.0. Pure Go, no cgo.
- Exclusivity: open PRs #274 (PointIndex+ClosestPointQuery) and #275 (RegionIntersection) do NOT touch Hausdorff. `hausdorff.go` absent; no `HausdorffDistance*` symbol anywhere.
- Externally-defined oracle: C++ `S2HausdorffDistanceQuery` fixes the exact semantics (max-of-min, attained-at-vertex lemma, directed asymmetry, interior handling) so tests are fair without leaking an algorithm.
- Complexity test: difficulty is not "create a new file" — it is correctly REUSING existing internals (ClosestEdgeQuery + MinDistanceToPointTarget + IncludeInteriors) in a non-obvious way, plus modifying existing files (option plumbing, shape-vertex iteration helper).

## 4. Public API surface (fairness > naturalness — named in meta)
- `func DirectedHausdorffDistance(source, target *ShapeIndex, opts *HausdorffDistanceOptions) HausdorffDistanceResult`
- `func HausdorffDistance(a, b *ShapeIndex, opts *HausdorffDistanceOptions) HausdorffDistanceResult`
- `type HausdorffDistanceOptions struct { IncludeInteriors bool }` + `func NewHausdorffDistanceOptions() *HausdorffDistanceOptions` (default IncludeInteriors=true)
- `type HausdorffDistanceResult struct { ... }` with `func (r HausdorffDistanceResult) Distance() s1.Angle` and `func (r HausdorffDistanceResult) TargetPoint() Point`

## 5. Canonical output form / contract
- Directed = max over every vertex of every source shape of `ClosestEdgeQuery(target).Distance(pointTarget(v))`.
- Undirected = `max(directed(a,b), directed(b,a))` and its TargetPoint is the source vertex of whichever direction wins.
- Empty source (0 edges, 0 points): Distance() = negative angle sentinel (`s1.Angle(-1)`), TargetPoint unset (origin Point{}).
- Source nonempty, target empty: directed Distance() = `s1.InfAngle()` equivalent (ChordAngle Inf -> Angle), TargetPoint = the first source vertex.
- Geodesic distances via s1.ChordAngle internally, exposed as s1.Angle.

## 6. Blind-spot pre-empts (why the traps stay fair)
- Disclose the attained-at-vertex lemma (needed for solvability over an infinite point set) — keeps max-of-min, asymmetry, interiors as the live traps.
- State "greatest distance ... to the nearest point" (sup-of-inf) in prose, then the vertex reduction — pre-empts the min-of-min set-distance reflex without naming the loop.
- State IncludeInteriors default true and the false-branch behavior explicitly (unstated-inverse blind spot).
- State single-point shapes + degenerate edges contribute (coverage).

## 7. Predicted trap matrix (interdependent + misdirecting)
| # | Trap | Verdict | Interdependent with | Misdirection |
|---|---|---|---|---|
| 1 | min-of-min (set distance) instead of max-of-min | WRONG_LOGIC | interiors (interior vertex is often the max) | ClosestEdgeQuery.Distance() already returns THE closest — reads as "done"; symmetric test shapes coincide |
| 2 | one direction only / undirected != max | MISSED_REQUIREMENT | trap 1 | directed API looks complete |
| 3 | forget IncludeInteriors -> interior vertex reports boundary distance | MISSED_REQUIREMENT/WRONG_LOGIC | trap 1 (changes which vertex is max) | boundary distance is positive and plausible |
| 4 | TargetPoint returns closest-on-target instead of source vertex | WRONG_LOGIC | trap 2 | both are Points |
| 5 | empty/degenerate handling (sentinel vs Inf vs single point) | EXECUTION_ERROR/MISSED_REQ | — | edge-case |

Pass-rate math: 3 stacked interdependent+misdirecting traps (1,2,3) ~= 12%, plus edge-case traps -> target ~8-12%.

## 8. File footprint (Counter-2 human-effective estimate)
NEW:
- `s2/hausdorff.go` — options, result, DirectedHausdorffDistance, HausdorffDistance, source-vertex iterator, per-vertex closest query. ~230-280 eff.

MODIFIED (existing-file integration, not just imports):
- `s2/query_options.go` or `s2/edge_query.go` — reuse/adjust IncludeInteriors option wiring for the point-target path. ~15-30 eff.
- `s2/shapeutil.go` — add an exported/internal `visitSourceVertices(index, func(Point))` helper iterating shapes -> chains -> edges -> unique endpoints (also used by tests' reasoning). ~40-60 eff.
- `s2/distance_target.go` or `min_distance_targets.go` — small helper to build a point target with interior semantics toggle if needed. ~10-20 eff.
- `s2/doc.go` — one-line package doc entry (repo convention lists capabilities). ~2 eff.

Estimated meaningful (Counter 2): ~330-390 eff. **RISK: below the 450 floor.** Expansion levers (design in from day one, per SOLUTION.md — add before pass-rate is calibrated):
1. Add `MaxError` approximate-mode option + a brute-force vs indexed path (mirrors edge_query's UseBruteForce) — genuine +60-90 eff and a real correctness/consistency test axis.
2. Add `TargetEdge()`/closest-point-on-target accessor to the result (the point on the target achieving the min for the winning source vertex) — +30-40 eff, and it creates trap #4 legitimately.
3. Support `DirectedHausdorffDistance` against interior-only vs boundary consistently across polygon/polyline/point source types with explicit per-dimension tests — forces handling Dimension() in the vertex iterator (+30 eff).
With levers 1-3: ~440-500 eff, lands Olympus-Okay/Good.

## 9. Test strategy (see response body for full list)
Go, `TestHausdorff*` prefix (audit BASE_RUN regex — unique prefix, no collision). Table-driven, public-API only, exact `s1.Angle` assertions within an epsilon helper, both directions asserted separately (asymmetry), interior on/off pairs, empty/degenerate, multi-shape index, point/polyline/polygon source+target matrix. ~55-70 tests.

## 10. Tier + category
Olympus, category = feature-request ("Add ...").

## 11. Predicted Nova/Vega pass
~8-12%. WRONG_LOGIC >= 25% expected (traps 1,3,4). Best agent: Vega (multi-subsystem) or Nova->Orion.

## 12. Open risks
- LOC floor (see §8) — must land levers 1-3 to clear 450 human-effective; verify with `.claude/hooks/effective_loc_check.py`.
- meta.md at ~215 body words — trim toward <=200 (drop the motivation clause) before eval.
- Interior semantics for polyline/point source (no interior) must be stated so IncludeInteriors is a no-op there — else fairness flag.
