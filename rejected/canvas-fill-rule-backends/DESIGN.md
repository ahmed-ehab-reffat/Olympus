# DESIGN.md — canvas-fill-rule-backends

Repo: https://github.com/tdewolff/canvas · BASE_COMMIT `8e86b9abb917f7cd49a2b23c43df1c6b66393539`
Language: Go · License MIT · ★1825 · quota 0/6

---

## 1. Title

**Fix fill rule handling across the renderer backends**

(7 words, verb-led, names the subsystem. Category = `enhancement`: `FillRule`, `Style.FillRule` and
`Context.SetFillRule` all already exist and are documented; the emitters honor only two of the four
values. This completes existing documented behavior rather than adding a new concept.)

## 2. Shape classification

- **Shape:** O-Composite-extend (refactor an existing resolution across packages) with an
  O-Algorithm-correctness flavour on the stroke-composition cell.
- **Span:** core path package + 5 renderer packages + the SVG parser = 7 files, 6 packages.
- **Pass rate target:** <=40% ceiling (2026-07 sprint). Predicted 10-30%, see § 13.
- **Dominant verdict predicted:** REGRESSION (existing golden tests) then MISSED_REQUIREMENT.
- **Best agent:** Orion (long-horizon, cross-package restructure); Nova likely to single-point-fix.

## 3. Public API surface

Names the tests will assert. Everything below except the two new symbols already exists on base.

- `canvas.FillRule` — existing enum: `NonZero`, `EvenOdd`, `Positive`, `Negative`.
- `canvas.FillRule.Fills(windings int) bool` — existing, already correct for all four.
- `canvas.Style.FillRule` — existing public field.
- `canvas.Context.SetFillRule(rule FillRule)` — existing.
- `canvas.Path.Settle(fillRule FillRule) *Path` — existing; resolves a path to a non-overlapping
  equivalent under the given rule.
- **NEW** `canvas.FillRule.Native() bool` — reports whether an output format can express the rule
  directly. `NonZero` and `EvenOdd` are native; `Positive` and `Negative` are not.
- **NEW** `canvas.Path.FillGeometry(fillRule FillRule) *Path` — returns the path a renderer should
  emit so that filling the result under `NonZero` paints exactly the region `fillRule` selects on
  the receiver. Returns the receiver unchanged when the rule is native.

## 4. Canonical output form

- **Native rules are emitted natively, byte-for-byte as today.** `NonZero` emits no rule marker;
  `EvenOdd` emits the format's even-odd form (`f*` / `eofill` / `fill-rule="evenodd"`). The emitted
  path data for these two is unchanged from base. This is the baseline-preservation contract.
- **Non-native rules are pre-resolved**, then emitted with the format's nonzero form.
- **Stroke geometry is always taken from the path as given**, never from the pre-resolved fill
  geometry.
- **A stroke outline is never subject to the fill rule.** When a backend converts a stroke to a
  filled outline (unsupported joiner/non-similarity transform), that outline fills under `NonZero`.
- **Empty result:** a rule selecting no region emits no paint operation for the fill.
- SVG parser: `fill-rule` accepts `nonzero` and `evenodd`; any other value leaves the inherited
  value unchanged. The attribute inherits through groups like the other presentation attributes.

## 5. Blind-spot pre-empts

| Blind spot | Sentence going into meta.md |
|---|---|
| Baseline preservation | "Output for the two rules the formats express directly must not change." |
| Compound order | "The stroke is always taken from the path as given." |
| Unstated inverse | "A stroke that a backend turns into a filled outline is not subject to the fill rule." |
| Falsy-on-invalid | "An unrecognised `fill-rule` value leaves the inherited rule unchanged." |

Codebase-inferable requirements: **1** (that `Path.Settle` is the in-repo mechanism for resolving
overlap — demonstrated at `path_stroke.go:652`). Within the <=1 budget.

## 6. Description draft

See `meta.md`. Target <=200 words, plain prose, no headers.

Opening sentence (states the ask, not the current behavior):
> Extend every renderer backend to honor all four fill rules the path model defines.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (x0.65) | Reason |
|---|---|---|---|---|---|
| MODIFY | `path.go` | 2592 | +55 | 36 | `Native()`, `FillGeometry()` |
| MODIFY | `renderers/pdf/pdf.go` | 1936(pkg) | +70 | 46 | 4 fill sites; split the `B`/`b` combined operator |
| MODIFY | `renderers/svg/svg.go` | 697 | +50 | 33 | 3 sites; stop applying the rule to the stroke outline |
| MODIFY | `renderers/ps/ps.go` | ~430 | +40 | 26 | `gsave`/`grestore` fill+stroke split |
| MODIFY | `renderers/tex/tex.go` | ~300 | +35 | 23 | no `FillRule` handling at all today |
| MODIFY | `renderers/rasterizer/rasterizer.go` | 271 | +30 | 20 | 2-state `SetWinding` cannot express 4 rules |
| MODIFY | `svg.go` (parser) | 1532 | +45 | 29 | parse + inherit `fill-rule` |
| **TOTAL** | **7 files, 6 packages** | | **+325** | **~213** | |

⚠️ **LOC is the live risk and the reason this section carries a contingency.** The x0.65 sketch
lands at ~213 against a 200 floor — inside the floor but with no buffer, and the skill requires
designing to ~300. `htmlcanvas` is excluded on purpose (`//go:build js`, untestable here).

**Contingency lever, ranked, to be taken only if the measured Counter-2 count lands under 280:**
1. Extend the SVG parser work to `clip-rule` parsing + inheritance (same attribute family, real).
2. Honor the fill rule in `Canvas.RenderPath`'s recorded replay path and in `renderers.Renderer`.
3. Only then reconsider scope.

Padding with public API is explicitly forbidden (participle `Greedy()` precedent) — every lever
above is genuine behavior with its own tests.

## 8. Solution outline — pure-function helpers

- `FillRule.Native() bool` — one branch per rule; requirement: "the two rules the formats express
  directly".
- `Path.FillGeometry(fillRule) *Path` — returns receiver when native, else `p.Settle(fillRule)`.
  Requirement: "otherwise the renderer resolves the path first".
- Per backend, a small local `fillPathFor(style)` that calls `FillGeometry` once and is used ONLY
  for the fill emission, never for the stroke.

No fixpoint loop; no recursion. The interdependence is structural (shared path data), not iterative.

## 9. Test file outline

Path: `renderers/fillrule_<hex>_test.go` (new package-external test) plus additions in
`fill_rule_<hex>_test.go` at repo root for the core helpers, and `svg_parse_<hex>_test.go`.
Filenames use `openssl rand -hex 3`; no `shipd`/`datacurve` substrings.

Block 1 imports · Block 2 builders (CW square, CCW square, nested CW, self-crossing bowtie,
figure-eight) · Block 3 assertion helpers (emitted-string contains/not-contains; inked-pixel count)
· Block 4 tests by bucket:

- **core** (`Fills` already correct; `Native`, `FillGeometry` per rule, receiver-unchanged for native)
- **per backend x per rule** — pdf, ps, svg, tex, rasterizer x 4 rules
- **baseline preservation** — NonZero and EvenOdd emit byte-identical output to base
- **composition (F-10 off-diagonal)** — non-native rule x fill+stroke, per backend
- **stroke outline** — unsupported joiner x non-native rule: outline not rule-subjected
- **round-trip (F-2)** — parse SVG with `fill-rule="evenodd"`, render to SVG, rule survives
- **edge** — empty path, rule selecting nothing, unrecognised attribute value

Decomposed per ATOM, including the negatives: native rules do NOT change output; the stroke does
NOT change when the fill is pre-resolved; the outline is NOT rule-subjected.

## 10. Forced signatures

`FillGeometry` must return `*Path` (not mutate) because `RenderPath` receives a borrowed `*Path`
the caller may reuse — mutating it corrupts the recording `Canvas` replay. Tests assert the
receiver is unchanged after the call.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Emitters drop the two non-native rules; core resolves all four | **F-9** | S6 | resolution placement | rides #2,#3,#4 | The core is correct, so the bug looks like it is not there; each emitter re-decides independently | "honor all four" | per-backend x rule |
| 2 | "Always settle" regresses existing golden output for NonZero/EvenOdd | **F-13-adjacent / S3** | S3 | baseline preservation | #1 | Uniform pre-resolve is the tidy fix and reds pdf/ps/svg base tests | "Output for the two rules the formats express directly must not change" | base golden tests |
| 3 | Pre-resolved fill geometry leaks into the stroke via the shared path emission (`B`, `gsave`, `writePath`) | **F-10** | S2 | composition (rule x paint) | #1,#2 | PDF `B` paints fill+stroke from ONE path; splitting it is invasive | "The stroke is always taken from the path as given" | off-diagonal cell |
| 4 | Stroke-to-fill outline wrongly inherits the user's rule (a live base bug at `svg.go:297`) | **F-6** | A8 | polarity/scope inversion | #3 | "Thread the rule everywhere" is the natural reading and makes this worse | "not subject to the fill rule" | unsupported-joiner test |
| 5 | Emitter writes `fill-rule` the parser cannot read back | **F-2** | S5 | round-trip | #1 | Producer and consumer live in different packages | parser sentence | round-trip test |

Axes are distinct (placement / preservation / composition / scope-inversion / round-trip) and traps
1-3 are mutually interdependent through the shared path emission.

**CONTRACT-STATED / FIX-HIDDEN check.** Each meta sentence states the contract without handing the
fix: "honor all four rules" does not say to pre-resolve geometry; "the stroke is taken from the path
as given" does not say to split the `B` operator; "output for native rules must not change" does not
say which rules are native per format. ✅

## 11b. Capability cross-product matrix (F-10)

Axis 1 = fill rule {native (NonZero, EvenOdd) | non-native (Positive, Negative)}.
Axis 2 = paint composition {fill only | fill+stroke | stroke with unsupported joiner}.

| | fill only | fill+stroke | stroke unsupported |
|---|---|---|---|
| **native rule** | base behavior unchanged | base behavior unchanged | ← off-diagonal: outline not rule-subjected |
| **non-native rule** | the headline case | ← **off-diagonal, the band decider** | ← off-diagonal |

Both non-native off-diagonal cells get tests in every vector backend. Predicted failure mode is
OVER-application (the resolved geometry reaching the stroke), consistent with F-10's over-firing
signature.

**Format-noun audit (L24):** "path" is the format noun. Extent stated explicitly — the fill
geometry and the stroke source are named separately so "the path" is never ambiguous.

**L21 example audit:** the meta states the native/non-native split as a rule; it does NOT list which
rules are native per format (that would hand trap #2).

## 12. Tier + category

- Tier: **Olympus** (one tier).
- Category: **enhancement** — the enum, the `Style` field and the `Context` setter all exist and are
  documented; the emitters are incomplete. Title verb "Fix" matches.

## 13. Predicted pass rate

**Predicted 10-30%.** Reasoning: trap #1 alone is a ~50% single wall, but #2 (baseline regression)
and #3 (stroke composition) are interdependent with it and neither is visible from the failing
assertion. Against that, the gap is discoverable — an agent that reads `FillRule.Fills` sees all
four rules immediately, and `Settle` is right there as the mechanism. Risk direction is TOO EASY,
not unsolvable. If a batch reads >40%, the first lever is the off-diagonal stroke cell per backend
(§ 11b), not more rules.

## 14. Quality-gate checklist

- [x] Repo understanding 5/5 (architecture, subsystems, entanglement, test framework, template file)
- [x] Exclusivity: canonical org resolved (`tdewolff/canvas`, no move); PR search on
      coordinate/clip/dash/hatch/tiling/linebreak/fill lanes = 0 open hits; 3 open PRs are
      `path_intersection.go` #382, `svg.go` #326, `font/system.go` #271 — none touches the fill-rule
      emission path
- [x] Roadmap #74 checked — fill rules are NOT a roadmap item; every unchecked roadmap lane avoided
- [x] Gate 1 CONFIRMED by running the public API (see `REPO-HUNT-2026-08-07.md`)
- [x] Gate 8: behavior defined by the repo's OWN doc comment (`path.go:26`), and
      `canvas.go:478` concedes "support is limited"
- [x] Title verb-led, names subsystem
- [x] Canonical form spelled out
- [x] <=1 codebase-inferable requirement
- [x] Traps name F-ids, sit on different axes, >=1 interdependent
- [x] § 11b cross-product filled, off-diagonals have tests
- [x] Not pattern-followable (each backend differs structurally)
- [x] Not a death class — see audit below
- [ ] ⚠️ **LOC floor: sketched ~213 meaningful, floor 200, target 280+. Contingency lever named in
      § 7. MUST be re-measured after implementation.**
- [ ] Docker: OWED to the platform (no local Docker)
- [ ] Flakiness 3x: owed after tests exist

### Death-class audit (TOO-EASY.md)

- **Uniform-wrap?** This was the main risk and is answered by trap #2: "always pre-resolve" is the
  uniform fix and it REGRESSES the existing golden tests, because native rules must keep their
  native emission. The correct implementation is conditional per rule AND per paint composition, so
  one mechanism does not discharge all sites.
- **Membership/validation?** No — it is an emission-fidelity gap, not a guard.
- **Saturated-reference port?** No. `Positive`/`Negative` are **canvas's own model**; no external
  spec names them (SVG and PDF define only nonzero and even-odd). This is the LOW-collision shape.
- **Difficulty-from-misdirection?** No — the difficulty survives full specification: stating all
  four contracts still leaves the emitter restructure to do.
- **Spec-knowable predicate domain?** No — the winding semantics are trivial; the work is wiring.
- **Pointwise-decoupled?** No — the fill and stroke emissions share one path emission per backend.

### Why this is not a duplicate

Nearest self-collision: `approved-problems/lyon-arcs-join` (stroke joins) and
`lyon-fill-internal-vertices` (fill tessellation interior), plus `rejected/lyon-stroke-to-fill`. All
three are Rust tessellator-internal geometry. This problem touches no tessellation and no join
geometry — it is emission fidelity across output formats, in Go. `path_stroke.go` is deliberately
NOT in the file footprint.

**Predicted iteration cycles: 3.**
