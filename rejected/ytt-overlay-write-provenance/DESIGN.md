# DESIGN.md — ytt-overlay-write-provenance  (WORK IN PROGRESS — Phases 1-3 only)

Status: repo understanding + Phase 2 prior art + seam audit COMPLETE. Capability shape has one
open question (see § OPEN). Sections 1-14 are NOT yet written; do not treat this as a finished design.

## Phase 1 — Repo understanding (5/5)

**Architecture in one paragraph.** ytt renders YAML by compiling each `.yml` file into a Starlark
program (`yamltemplate` -> `template`), evaluating it to a `yamlmeta` document tree, and then
running a sequence of tree-to-tree operations over that model. `yamlmeta` (11720 LOC) is the shared
data model: Document / Map / MapItem / Array / ArrayItem nodes carrying positions and annotations.
`schema` (2669) builds a parallel `Type` tree from schema files and both ASSIGNS types onto data
value nodes and CHECKS them. `yttlibrary/overlay` (2399) is the overlay kernel: a recursive
tree-merge driven by `@overlay/*` annotations. `workspace` (2433) orchestrates: build the schema by
overlaying schema documents, build the data values by overlaying data-values documents onto the
schema defaults, evaluate templates, then post-process the output by applying overlay documents in
sorted file order.

**Five top-level subsystems + boundaries.**
1. `files` / `cmd` — input marshalling, file marks, output. 2. `yamlmeta` — the AST + type-check
plumbing + YAML round-trip. 3. `template` / `yamltemplate` / `texttemplate` — compile to Starlark,
evaluate, attach annotations. 4. `schema` + `validations` — the Type tree, assignment, checking,
OpenAPI export. 5. `workspace` — the pipeline driver (schema pre-processing, data-values
pre-processing, library execution, overlay post-processing).

**Three high-entanglement zones.**
1. **`overlay.Op.Apply`** — one kernel, FOUR call sites, THREE calling conventions:
   `data_values_schema_pre_processing.go:138` (`ExactMatch: true`),
   `data_values_pre_processing.go:161` (`ExactMatch: true`),
   `overlay_post_processing.go:55` (`ExactMatch` false, Left is an ARRAY of docsets, looped in
   sorted file order), `yttlibrary/overlay/api.go:55` (`overlay.apply()` from Starlark, chained).
2. **The `schema.Type` tree** — three independent evaluators over one model: `assign.go`
   (AssignTypeTo), `check.go` (CheckType), `openapi.go` (emit an OpenAPI v3 document).
3. **Library nesting** — `library_execution.go` threads schema envelopes and data-values envelopes
   into child libraries; `library.get()` / `with_data_values()` re-enter the same pipeline.

**Test framework + location.** Go stdlib `testing`. Two conventions: table-driven Go tests
co-located per package (`pkg/cmd/template/*_test.go` drive the whole CLI through
`cmdtpl.NewOptions()`), and `.tpltest` golden files under `pkg/yamltemplate/filetests/`.

**Formatting template cited.** `pkg/cmd/template/cmd_overlays_test.go` — builds
`files.NewSortedFiles(...)`, runs `opts.RunWithFiles`, compares `out.Files[0].Bytes()` to an
expected string. This is the behavioural, through-the-CLI style new tests should match.

## Phase 2 — Prior art (CLEAR)

Canonical org confirmed `carvel-dev/ytt` (no redirect). Searches run, all states, issues AND PRs:
`overlay diff`, `generate overlay`, `derive overlay`, `diff`, `patch`, `invert`, `conflict`,
`which overlay`, `provenance`, `trace`, `debug overlay`, `order`, `last write`, `overwrite`,
`double write`, `collision`, `audit`. No issue or PR asks for overlay conflict detection,
provenance, or overlay derivation. Maintainer-philosophy scan over all overlay issues returned only
#103 (a schema issue, different lane). No closed-with-implemented hits.

Gate 7b, every open PR's file list enumerated: only #1008 (`overlay/api.go` +1/-1, a builtin name
string in `NotOp`) and #1002 (`match_annotation_expects_kwarg.go` +5/-1, an int-overflow guard)
touch the package at all. Neither touches `op.go` / `map.go` / `array.go` / `document.go`.
Plumbing overlap, no capability overlap -> conjunctive exclusivity test PASSES.

Base commit is HEAD, so no post-base drift is possible and the swarm's merged fixes are all IN base.

## Phase 3 — Gate 1 reproduced on base

Built `./cmd/ytt` at base. Two overlay files, both `#@overlay/match by=overlay.subset({"kind":"Deployment"})`,
both setting `spec.replicas`:

    -f base.yml -f a.yml -f b.yml   ->  replicas: 9   exit 0
    -f base.yml -f b.yml -f a.yml   ->  replicas: 5   exit 0

Silent last-write-wins. No warning, no accounting, and the emitted value flips purely with `-f`
order. Behavioural F2P gap confirmed through the real entry point.

## Phase 3 — Death-class guard on the locked capability

| Guard | Verdict |
|---|---|
| 1. single guard/rule at many sites (uniform-wrap)? | ⚠️ **AT RISK** — see OPEN below |
| 2. single-subsystem fully-specified transform? | PASS — 4 surfaces, 3 calling conventions |
| 3. hardness depends on the spec NOT stating something? | PASS — contract is the policy, fix is the Apply-boundary lifetime |
| 4. port of a spec the model knows? | PASS — no external standard names ytt overlay provenance |
| 5. survives full specification? | PASS, conditional on OPEN |

Recogniser/post-pass class: PASS. This threads through the existing recursion; it is not a
standalone module beside it. (The overlay DERIVER idea was rejected at hunt time for exactly that.)
Missing-arm-of-a-dispatch: PASS. Not an arm; `op.go`'s switch is untouched.

## The wall (what makes it more than threading)

`Op.Apply` calls `removeOverlayAnns(leftObj)` at the end of EVERY Apply, and
`overlay_post_processing.go` calls Apply once **per overlay file** in a loop. ytt's only node-tagging
mechanism is annotations (`template.NewAnnotations(node)`), so the natural implementation of
"remember which overlay wrote this node" is an annotation — which is stripped between loop
iterations. Conflicts WITHIN one overlay document would be detected; conflicts ACROSS overlay files
would be silently missed. The symptom reads as a matcher bug, not an annotation-lifetime bug.

Shared state must additionally survive 13 `item.DeepCopy()` sites, the replace-vs-merge subtree
distinction, insert/append (new nodes with no left counterpart), and remove.

Arsenal: **S3** (baseline preservation through a shared chokepoint) lead, **A1** (cross-section
refactor of shared write machinery) support. F-ids: F-9 (cross-stage drop — the provenance is
computed in the kernel and discarded at the Apply boundary), F-10 (cross-product: op kind x
container kind x surface).

## OPEN — the one question before Sections 1-14

`TOO-EASY.md` § Difficulty-Rigor Protocol: *"the two-axis model selects FOR mechanical smoothness
(a capability that threads cleanly through stages) — which is the OPPOSITE of an integration wall.
'Threads cleanly' = too-easy."*

Threading a provenance parameter through a recursion is, in isolation, exactly that smooth thread.
The design is only safe if the `removeOverlayAnns` / per-file-loop lifetime wall above carries the
band rather than the threading. That has NOT been reproduced yet — HARDENING 3a.4 requires writing
the natural-but-wrong implementation and watching it fail with a misdirecting symptom BEFORE
authoring tests.

## Wall probe result (2026-09-08) — PARTIALLY REFUTED, read before building

Traced the lifetime by reading the code rather than assuming:

- `overlay_post_processing.go:55` does call `Op.Apply()` **once per overlay DOCUMENT**, nested inside
  a loop over files in `SortFilesInLibrary` order. Confirmed.
- `Op.Apply()` ends with `removeOverlayAnns(leftObj)`, and `NodeAnnotations.DeleteNs`
  (`pkg/template/annotations.go:62`) deletes **only keys prefixed `overlay/`**.
- `yamlmeta.convertToAST` (`pkg/yamlmeta/convert.go:108`) **preserves node identity** for every AST
  type — it mutates `typedVal` in place and returns the same pointers.

So node identity and non-`overlay/` annotations DO survive across the per-file loop. The wall fires
only if the implementer parks provenance in the `overlay/` namespace; parking it anywhere else walks
straight through. **That is a namespace coin-flip, not a reliable band-carrier** — precisely the L20
single-seam bimodality failure (`customasm`: 0/13 -> 90% -> 20% -> 57% -> 9%).

**Consequence: the locked capability needs a second, orthogonal mechanism before it is authorable.**
Do not proceed to Sections 1-14 on the annotation-lifetime wall alone.

### Candidate second mechanisms (none yet reproduced)

1. **The `ExactMatch` asymmetry.** Schema and data-values pre-processing run `ExactMatch: true`;
   post-processing and `overlay.apply()` run it false. A conflict policy must mean something
   different on each, and the two `true` surfaces feed the schema that the third surface's output is
   checked against. Cross-surface, not a thread.
2. **`overlay/insert` index shift.** `remove` and `insert` move array indices, so "the same node"
   is not stable across two overlays that both touch one array. Any provenance keyed on position is
   wrong; keyed on identity it is right. Open issue #308 (`insert` inserts out of order) is live
   evidence the repo's own ordering here is subtle. This is a genuine algorithmic core, not wiring.
3. **`expects=` / `when=` interaction.** A `when=`-guarded overlay's applicability is data-dependent,
   so whether two overlays conflict is not statically decidable — the policy has to be defined over
   what actually fired. Couples the new rule to `match_annotation_expects_kwarg.go`.

**Next action: pick a second mechanism, then reproduce BOTH.**

**Superseded next action: Write the annotation-based provenance implementation (the one a
strong agent produces), confirm it detects same-file conflicts and silently misses cross-file ones.
If it does NOT misdirect, the capability needs a second orthogonal mechanism or a pivot.

---

## Trap reproduction, round 2 (2026-09-08) — MECHANISM #2 FOUND, THEN REFUTED

Followed the `overlay/insert` lead into the node model and found a much better candidate than the
annotation namespace, then killed it with the base suite.

**What the code actually gives you.** `pkg/yttlibrary/overlay/array.go` has genuinely different
per-op node semantics, and the repo says so itself. `replaceArrayItem` carries the comment
*"left side fields are not preserved. probably need to rethink how to merge left and right once
those fields are needed."*

| op | node identity |
|---|---|
| `mergeArrayItem` | PRESERVED (`Items[i].SetValue(...)` on the left node) — and falls back to `appendArrayItem` when nothing matched |
| `replaceArrayItem` | DESTROYED (`Items[i] = newItem.DeepCopy()`) |
| `removeArrayItem` | nil-then-prune; every later index shifts |
| `insertArrayItem` | rebuilds the slice; left pointers kept, indices shift |
| `appendArrayItem` | new `DeepCopy()` node |

**The candidate wall.** `yamlmeta.Node` exposes `GetMeta(name)` / `SetMeta(name, data)` — the repo's
own documented per-node side channel, already used by `pkg/schema/yamlmeta.go` (stores the schema
`Type`) and `pkg/validations/yamlmeta.go`. It is the obvious, idiomatic place a solver would park
provenance. And **`DeepCopy()` silently drops `meta` on all six node types** (`deep_copy.go` copies
`Comments`, `Position`, `annotations`, `injected` — never `meta`). Overlay performs 13 `DeepCopy()`
calls. Provenance would survive `merge` and vanish through `replace` / `insert` / `append`, with no
error — reading as "conflict detection is flaky on some ops", never as "DeepCopy drops meta".

**Why it is nonetheless REFUTED as the lead trap.** Patched `deep_copy.go` to carry `meta` forward
through all six constructors and ran the full suite: **`go test ./pkg/...` fully green, zero
failures.** So the correct fix regresses nothing, which means there is no S3 baseline-preservation
half — the whole wall is the single insight *"meta does not survive DeepCopy."* One insight, one
fix site. That is Pre-Pick Guard #1 (a single mechanism discharging every site) and the L20
single-seam bimodality signature. (Probe reverted; `git diff --stat` clean, `go build ./...` OK.)

## VERDICT ON THIS CAPABILITY — pivot required

Both candidate walls collapsed the same way, and the collapse is a property of the CAPABILITY, not
of the two mechanisms:

- annotation namespace -> one insight ("use a namespace other than `overlay/`")
- `meta` through `DeepCopy` -> one insight ("meta does not survive DeepCopy")

**Provenance/bookkeeping is inherently plumbing, and its difficulty concentrates in a single
storage-location decision.** That is exactly the "threads cleanly = too-easy" anti-selector in
`TOO-EASY.md` § Difficulty-Rigor Protocol. Adding a third mechanism in the same lane would very
likely collapse identically; the doctrine's instruction for this situation is explicit — *pivot the
FEATURE, not the wording*.

**What is NOT lost.** Every repo-level asset stands and is reusable by the next ytt pick: all ten
gates discharged, base commit fixed at HEAD, green deterministic baseline, Docker pattern known,
Phase 1 understanding written above, and the per-op node-semantics table plus the `meta`/`DeepCopy`
asymmetry are now documented trap MATERIAL for a capability that has an algorithm of its own.

**Next action: return to Phase 3 with a fresh candidate set in this repo** — 5-7 candidates scored,
each required to name an algorithm the repo does not already contain (Stage 3b absorption test) and
to survive the death-class guard. Do NOT author the provenance capability.
