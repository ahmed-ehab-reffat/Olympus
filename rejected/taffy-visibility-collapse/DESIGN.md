# DESIGN — taffy visibility:collapse for flex items

## Status
MINIMAL DERIVATIVE PROBE (pre-commit). Scoped to the representative core so the platform
similarity check can run before we invest in the full-difficulty build. If it clears as
non-derivative, harden to the full step-10 algorithm (see "Deferred hardening" below).

## 1. Title
Add visibility collapse for flex items (`visibility: Collapse`)

## 2. Shape
O-Composite-add (new style property spanning style + flexbox compute + tree plumbing).
Best agent (full version): Vega. Predicted full-version pass ~10-15%.
Probe version is Mars-difficulty (single behavioral axis) by design.

## 3. Repo / gates
- DioxusLabs/taffy @ bb351fcc056c93dbb967292acc4242a5d1c46b3c
- MIT (Cargo.toml `license = "MIT"`; GitHub NOASSERTION is a detector artifact), 3287 stars, active (2026-07-15)
- COLD + EXCLUSIVE: no PR in any state; issue #124 open, maintainer-tracked, spec-referenced, 0 comments (no leaked solution); TODO present on base at src/compute/flexbox.rs:352
- Dedup-clean across all workspace dirs
- Domain engine (layout) -> dodges the language-completion-author pattern that killed the scriggo pick

## 4. Public API surface
- New `Visibility` enum: `Visible` (default), `Collapse`. Exported at crate root + prelude.
- New `Style.visibility: Visibility` field + `CoreStyle::visibility()` getter (default `Visible`).

## 5. Behavioral contract (probe scope)
- Collapsed flex item has zero main size; the freed main-axis space is available to siblings,
  including when they flex-grow.
- Collapsed item is still laid out as a child (not removed, unlike `Display::None`).
- `Visible`, and any visibility on a non-flex child, leave layout unchanged.

## 6. Spec basis
CSS Flexbox Level 1, step 10 (algo-visibility): https://www.w3.org/TR/css-flexbox-1/#algo-visibility

## 7. File footprint
MODIFY (solution.patch):
- src/style/mod.rs      -- Visibility enum + parse + Display impl + CoreStyle getter + Style field + DEFAULT + &T delegate + defaults_match test literal
- src/prelude.rs        -- export Visibility
- src/compute/flexbox.rs-- FlexItem.collapsed field + set from visibility() + zero-main-axis loop
- tests/xml.rs          -- required-field addition to existing full Style literal (R5)

TEST (test.patch):
- test.sh (mode 100755) -- base/new modes, cargo2junit JUnit, `--cfg taffy_probe_vis` gate
- tests/visibility_collapse_892b99.rs -- 5 hand-written black-box tests (gated behind the cfg)

## 8. Interdependent + misdirecting traps (FULL version, not fully exercised by the probe)
- Zero main size BUT still contributes cross-axis strut (agents zero it entirely -> miss strut).
- Requires a SECOND layout pass / restart (agents do a single pass).
- Line cross size enlarged to the largest strut among its collapsed items.
- Collapsed final cross size == strut.

## 9. Deferred hardening (for the committed Olympus build, after derivative clears)
- Implement the strut: record each collapsed item's would-be cross size.
- Two-pass restart treating collapsed items as zero main size on the second pass.
- Enlarge each line's cross size to the largest strut among its collapsed items.
- Set collapsed item's final cross size = strut; interaction with grow/shrink free-space.
- Add cross-axis + multi-line + wrap fixtures; target Vega ~10-15%.

## 10. Probe LOC (intentionally sub-Olympus)
~90 effective. The full version targets >=450 via the strut + two-pass + cross-size machinery.
