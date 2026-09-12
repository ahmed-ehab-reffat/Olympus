# DESIGN — taffy last-baseline alignment for flex items

## Status
MINIMAL DERIVATIVE PROBE (flexbox-only, ~52 eff LOC). Pre-commit: run the platform
derivative check, then harden (add grid + separate first/last baseline groups) to clear
the >=250 passing-LOC long-horizon floor. See "Deferred hardening".

## 1. Title
Add last-baseline alignment for flex items (`AlignItems::LAST_BASELINE`)

## 2. Shape
O-Composite-add (new alignment keyword + LayoutOutput data-model extension + flex/grid
compute). Best agent (full): Vega/Orion. Predicted full-version pass well under 40%.

## 3. Repo / gates
- DioxusLabs/taffy @ bb351fcc056c93dbb967292acc4242a5d1c46b3c
- MIT, 3287 stars, active (2026-07-15)
- COLD + EXCLUSIVE: no `LastBaseline`/`last_baseline` in code except grid_item.rs:59 TODO
  "Support last baseline". First-baseline is MERGED (#325 flex, #344 grid) = distinct.
  No open PR implements last-baseline.
- Dedup-clean. Domain engine (layout).

## 4. Public API surface
- `AlignItemsKeyword::LastBaseline` + `AlignItems::LAST_BASELINE` const; parses from `last baseline`.
- `LayoutOutput.last_baselines: Point<Option<f32>>` (new field alongside `first_baselines`).

## 5. Behavioral contract (probe scope)
- Flex container `align-items: last baseline` shifts participating items so their LAST
  baselines coincide at the group's furthest last baseline (mirror of first-baseline).
- Item last baseline derived from its LAST flex line; container reports its own last
  baseline from its last line -> propagates through nested containers.
- Leaf / single-line item: last baseline == first baseline (modes agree).
- Wrapped multi-line item: first != last -> the two modes place it differently.
- Line with < 2 participating items unchanged.

## 6. WHY it is hard (naive fails)
A naive impl (add the keyword, route it through the existing FIRST-baseline paths) makes
`last baseline` behave identically to `baseline`. It only diverges for an item whose first
and last baselines differ (a nested wrap container). The golden test asserts the ordering
FLIP, which the naive version cannot produce. Misdirecting: "baseline" machinery is right
there to reuse; the gap is the LayoutOutput last-baseline plumbing + last-line derivation.

## 7. File footprint (probe)
MODIFY (solution.patch, 6 source files):
- src/style/alignment.rs  -- LastBaseline variant + LAST_BASELINE const + parse + serde + names
- src/tree/layout.rs      -- LayoutOutput.last_baselines field + HIDDEN + constructor default
- src/compute/leaf.rs     -- 2 LayoutOutput literals (last_baselines: NONE)
- src/compute/block.rs    -- 1 LayoutOutput literal
- src/compute/flexbox.rs  -- last-baseline read in calculate_children_base_lines + align arm + container last-baseline output
- src/compute/grid/alignment.rs -- compile arm (LastBaseline treated as start; grid deferred)
TEST (test.patch):
- test.sh (100755) -- base/new modes, cargo2junit, `--cfg taffy_probe_lb` gate
- tests/last_baseline_7d5e99.rs -- 5 hand-written black-box tests (gated), assert item positions

## 8. Golden result (validated locally)
GP flex-row align-items {baseline|last baseline}; A leaf 20x30; B wraps two 40x20 leaves.
- baseline:      A.y=0,  B.y=10
- last baseline: A.y=10, B.y=0   (ordering FLIPS)

## 9. Deferred hardening (for the committed Olympus build)
- Grid last-baseline: grid_item.rs `last_baseline: Option<f32>`, grid/mod.rs last-row baseline
  output, grid/alignment.rs + track_sizing.rs two-group handling (~40-60 LOC).
- Separate first vs last baseline GROUPS when a container mixes `baseline` and `last baseline`
  via per-item align-self (spec: last-baseline group anchors to cross-END). Adds real logic + a
  discriminating trap. (~30-50 LOC.)
- Column-axis / RTL coverage; more fixtures.
- Target: >=250 eff passing LOC, <=40% pass.

## 10. Probe LOC
~52 eff (flexbox only). Deliberately sub-floor; the grid + groups work above lifts it >=250.
