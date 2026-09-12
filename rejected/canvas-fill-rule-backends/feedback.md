# feedback.md — canvas-fill-rule-backends

## Strategic summary

tdewolff/canvas defines four fill rules (`NonZero`, `EvenOdd`, `Positive`, `Negative`) and
implements all four in the core (`FillRule.Fills`, `Path.Settle`), but every output backend
collapses them to the two-value SVG/PDF binary, each differently. Lead pattern F-9 (cross-stage
resolution drop).

## Gate status

| Gate | State | Evidence |
|---|---|---|
| 1 behavioral-f2p-gap | CONFIRMED | Probe 2026-08-07 via public API; CW square + Positive: core says empty, PDF emits `f`, SVG omits fill-rule, PS emits `fill`, rasterizer inks 256/0 px |
| 2 saturation | PASS | not in SATURATED-REPOS.md; quota 0/6 |
| 5 cold-not-live | PASS | 3 open PRs, none on the fill-emission path; roadmap #74 does not list fill rules |
| 7b exclusivity | PASS | canonical org resolves to itself; PR search all states, 0 hits on the lane |
| 8 defined-behavior | PASS | repo's own doc `path.go:26` defines all four; `canvas.go:478` concedes "support is limited" |
| 9 flakiness (repo) | PASS | scoped suite 3/3 identical, sub-second |
| 10 repo-quota | PASS | 0/6 |
| LOC floor | ⚠️ AT RISK | sketch ~213 meaningful vs 200 floor; contingency lever in DESIGN.md § 7 |
| Docker | OWED | no local Docker on this workstation |

## Attempt history

### R0 (2026-08-07) — design
DESIGN.md complete. Gate 1 confirmed by measurement, not by trusting the in-repo
`// TODO: test for all renderers` marker. Main open risk is the effective-LOC floor.

### R1 (2026-08-07) — IMPLEMENTED, then SHELVED at the long-horizon LOC floor

Solution implemented across all 7 planned files and **verified correct**: the scoped suite stays
green (baseline preserved byte-for-byte for the two native rules), and the Gate-1 probe now reports
`Positive` inking 0 px where base inked 256, with `Negative` emitting reoriented geometry.

**Measured effective LOC: 44** (raw 65, Counter-1 56) against a **200 floor**.

DESIGN.md § 7 sketched +325 raw / 213 meaningful. The real implementation is **65 raw / 44
meaningful** — the estimate was 5x too high, and the § 7 contingency levers (clip-rule parsing,
Canvas replay) are worth ~25 more, nowhere near closing a 156-LOC gap.

**Root cause: machinery absorption.** canvas already owns `Path.Settle`, so the correct fix at each
backend is 2-6 lines (compute a `fillData`, guard `sameAlpha` on `FillRule.Native()`, swap one
variable). The estimate assumed "restructure the emission"; the repo's own primitives meant there
was nothing to restructure. Same profile as taffy / golang-geo / jd / comrak / kcl.

Not padding to reach the floor — that is the documented dead-code revert path.
