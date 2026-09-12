# Repo hunt 2026-08-04-C — first sweep under the RELAXED 10000-star ceiling

Star ceiling relaxed from 5000 to 10000 (user decision 2026-08-04). Updated in
`.claude/skills/olympus-hunt/SKILL.md` (Requirement 1, the discovery sweep, the kill list),
`Instructions/PICK-FILTER.md § Gate 10`, `Instructions/RULES.md § Repository Requirements`.
cerbos is SHELVED at the user's instruction and is not carried forward here.

**Headline: the relaxation bought less than expected.** The 5000-10000 band is dominated by exactly
the author-obvious class `SATURATED-REPOS.md § A` warns about — the sweep returned gopher-lua (6960),
otto (8451), yaegi (8355, our own cap), boa (7432), dasel (8007, our cap), pest (5373, near cap),
wazero (6311), datafusion (9086). Submission count tracks author-obviousness, not stars, so raising
the ceiling mostly raises the derivative risk. The two candidates worth anything this round came from
the 1000-5000 band anyway.

---

## openfga/openfga — ★5543 — **DEAD at the Gate-A kill-test (run 2026-08-04, after this file's first draft)**

Ranked leading candidate on architecture, then killed by three independent findings. Recorded in
full below because the seam analysis stands and is worth reusing if the repo ever changes.

**Kill 1 — the parity thesis is a Stage-2b MAGNET.** [#1567 "Check / ListObjects API
inconsistency"](https://github.com/openfga/openfga/issues/1567) has been OPEN since 2024-04-23 with
**zero comments** and no PR. That is the lol-html profile verbatim: open + uncommented +
unimplemented + obvious = maximum collision odds, because the SIX-CHECK reads clean precisely since
nobody upstream engaged, while every problem author auditing this repo lands on the same issue. The
check-vs-list-objects gap is also the single most obvious pick in the entire codebase.

**Kill 2 — the baseline is FLAKY in the seam package, admitted by the maintainers.** Two open
maintainer-filed issues: [#3197](https://github.com/openfga/openfga/issues/3197)
(`TestUnionCheckFuncReducer` in `internal/graph` fails when the process is CPU-starved for >10ms)
and [#3214](https://github.com/openfga/openfga/issues/3214) (`TestV2CheckMetadata` races on context
cancellation). Gate 9 makes a flaky baseline a mandatory reject unless base mode is scoped with a
documented reason — and here the flaky tests sit INSIDE the package a parity pick must touch, so
scoping them out would discard exactly the regression coverage that matters.

**Kill 3 — the cold packages cannot carry a substitute pick.**

| Cold package | LOC | Why it fails |
|---|---|---|
| `internal/planner` | 699 | Thompson-sampling dispatch heuristic over a `sync.Map`. Randomised AND concurrent = the worst possible f2p surface; it is a performance heuristic, not a behaviour |
| `internal/condition` | ~1100 | Adding a condition parameter type is pattern-followable: **10 already exist** (bool, string, int, uint, double, duration, timestamp, ipaddress, list, map) = triviality filter RED. The one substantial type, `ipaddress`, is the SPEC-KNOWABLE PREDICATE class just shelved with cfn-guard |
| `pkg/typesystem` | 1669 + 254 | Model validation is a rule list (L2 pointwise). Also carries `// TODO: Deprecate once userset refactor is complete` = a second live refactor |

**The seam analysis, retained for reuse.** (Everything below was correct; it just cannot be reached.)

- **Apache-2.0 · Go · pure** · pushed 2026-08-03 · **141 open issues** (in the 100-1000 window, no
  relaxation needed) · zero local dedup hits · quota 0/6
- **Architecture:** `pkg/typesystem` (model validation + the weighted relationship graph) ->
  `internal/graph` (check resolution, cycle detection, dispatch) -> `pkg/server/commands/*`
  (ListObjects / Expand / **ReverseExpand**) + `internal/condition` (CEL conditions) +
  `internal/planner`.

**Trap seams**

| Pattern | Present | Evidence |
|---|---|---|
| S6 two evaluators of one model | **yes (lead)** | `internal/graph` resolves Check top-down; `commands/reverseexpand` resolves ListObjects bottom-up. Both must agree on the same authorization model — divergence is repo-internal and un-nameable externally |
| F-2 bidirectional seam | **yes** | userset rewrites: a relation is both grantor and grantee (tuple-to-userset), which is the producer-AND-consumer precondition verbatim |
| F-10 cross-product | **yes** | axes: operator (union / intersection / exclusion) x direction (check vs list-objects) x source (direct tuple / TTU / computed userset) x contextual-vs-stored tuples |
| F-9 cross-stage drop | **plausible** | `pkg/typesystem` computes relation references and edge weights; the graph resolver re-derives at eval time |

**Open PR queue is peripheral, unlike every other candidate this week.** #3238 touches one
reverse-expand file (+5/-5), #3237 a cmd validator, #3236 one config constant, #3230 logging,
#3243 dependabot. Nothing blankets the core. **This was the one gate openfga passed** — and it is
why the repo looked like the week's best candidate until the kill-test ran.

**The original CONDITION (superseded by the kills above).** Core velocity is high in exactly the two
packages carrying the lead seam:
`internal/graph` **37** and `commands/reverseexpand` **42** commits in the trailing 12 months (they
are mid-flight on weighted-graph ListObjects optimisations). The COLD corners are
`internal/planner` (8), `internal/condition` (9), `pkg/typesystem` (13). A viable pick has to live
in the cold corners while still exercising the check/list-objects parity seam — that is a narrow
target and it needs a Gate-A kill-test before any investment.

**Second risk:** Zanzibar is a named paper, so a pick phrased as "implement Zanzibar's X" is a
Stage-2b magnet. The pick must be phrased in openfga's own nouns (weighted edges, contextual tuples,
condition context merging).

---

## dimforge/rapier — ★5603 — **DEAD (Gate 5).** Rejected, corrected to live, then killed properly

Three verdicts on one repo in one day. The final one is evidence-backed; the first two were each
based on checking the wrong thing.

**v1 REJECT (wrong on both claims).** "31 open PRs blanket the core" + "no `tests/` directory".

**v2 LIVE (right facts, wrong conclusion).** The corrections were real and stand:
* The open PR queue IS maintenance, not capability work — "Fix SIMD joint constraints", "fix wheel
  impulse scaling", "fix aliasing UB", "Fix tangent impulse being NaN", "add getter for `contact_id`".
* The test surface IS excellent. The `tests/` check was run at the repo ROOT, but rapier is a Cargo
  WORKSPACE, so tests live per-crate: `crates/rapier3d/tests/` holds 30 integration files plus 55 lib
  tests, `assert_eq!`/`assert!` dominated (181/168 vs 5 `assert_relative_eq!`), driven through the
  real public API. **Gate 9 measured: `cargo test -p rapier3d` 3x, identical, zero failures.**

**v3 DEAD — Gate 5, live maintainer workstream.** The PR queue reflects only OUTSIDE contributions.
`commits?since=` tells the real story: on **2026-08-02** the maintainer shipped `v0.35.0-beta.0`
carrying **intra-island parallelism, box2d-style CCD, unified SIMD/non-SIMD code paths, NaN-quarantine
containment, non-Sync event handlers and hooks, a broad-phase rework for large static worlds**, plus a
brand-new determinism/snapshot/parity test suite. **14 commits since 2026-08-01, ZERO with a `(#NNN)`
suffix** — every one a direct push, structurally invisible to `gh pr list`.

That is Gate 5's literal wording ("reject live maintainer workstreams + features being shipped now"),
and it is the worst possible timing: the base commit would be a beta tip mid-release-cycle, so the
post-base six-check risk is maximal.

Two of the invented-capability candidates found during the audit were already gone:
`physics_pipeline/quarantine.rs` (NaN containment, a perfect Stage-2b-clean rapier-internal noun) and
`island_manager/persistent.rs` — **both created 2026-08-02, two days before the audit**, and
quarantine already ships 11 behavioural tests.

⭐ THE LESSON, and it cost three verdicts: **liveness has two streams and the cheap one is the
incomplete one.** For a repo whose maintainer holds commit rights, the open-PR queue shows the
community's bug fixes while the maintainer's entire feature program lands as direct pushes. Read
`commits?since=` and treat a `feat:` line with no PR number as the strongest liveness signal there is.

## REJECTED this sweep

| Repo | ★ | Reason |
|---|---|---|
| **uber-go/nilaway** | 3879 | The best NEW seam found this week and it is Gate-5 dead. Producer/consumer duality at scale (286 `ProducingAnnotationTrigger`/`ConsumingAnnotationTrigger` references = F-2 verbatim), a real cross-package inference fixed point, `analysistest` golden-file testdata = ideal f2p surface, 16k LOC in `assertion/`. **But the maintainers are mid-rewrite:** the last 6 months are a continuous `struct-init-v2` workstream — `structfieldeffects/effects.go` 20 touches, `assertiontree/structinitv2.go` 12, `structfieldeffects/analyzer.go` 10, plus `backprop.go` and `root_assertion_node.go`. 91 Go commits/12mo. Only `inference/` (8 commits, 1.7k LOC) is cold and it is coupled to what v2 is changing. **Revisit when struct-init-v2 lands** — this is the highest-quality shelved repo on the list. |
| **dominikh/go-tools** (staticcheck) | 6845 | Not audited past the mechanical gates: the check corpus is an add-a-rule architecture (L2 pointwise / triviality filter). The SSA/IR layer underneath is deep but is shared with `golang.org/x/tools`, so exclusivity is murky. |
| **wazero** (6311), **gopher-lua** (6960), **otto** (8451), **boa** (7432), **datafusion** (9086), **go-mysql-server** (2646), **go-jsonnet** (1843) | — | The author-obvious class: clean general-purpose VMs, SQL engines, spec-defined runtimes (WASM, jsonnet). `SATURATED-REPOS.md § A` THE PATTERN. Reject on sight regardless of star count. |
| **zizmor** | 5975 | GitHub Actions audits are independent rules = L2 pointwise, caps ~67% pass. |
| **quickwit** (11454), **wgpu** (17728), **rerun** (11246), **vector** (22293, MPL-2.0) | — | Over the relaxed ceiling and/or non-permissive. |
| **sourcegraph/zoekt** | 1806 | 3 open issues = no surface; 15 open PRs against it. |

---

## What the relaxation actually changed

Two candidates became admissible that were previously out of window: **openfga** (5543) and
**rapier** (5603). rapier died on its PR queue; openfga died at the Gate-A kill-test (magnet issue +
flaky baseline in the seam package + no viable cold-package substitute). **The relaxation
net-yielded ZERO authorable targets.** That is the finding: at 500-5000 the blocker was saturation,
and at 5000-10000 it is the same blocker plus more prior art. Widening the window does not fix a
sourcing problem whose real cause is that the good seams are all either owned, hot, or obvious. Everything else
the wider window surfaced was already dead on the author-obviousness pattern.

Recommendation: keep the 10000 ceiling, but treat 5000-10000 as a PENALTY band exactly as the
updated Gate 10 now says — verify the platform sub-count on the "Learn more" page BEFORE authoring
anything in it, because high-star repos saturate globally first (opa 11.9k -> 60 subs).

## Owed before authoring openfga (`PICK-FILTER.md`)

Gate 1 behavioral-f2p-gap in a COLD package · Gate 5 per-FILE (the pick must avoid `internal/graph`
and `reverseexpand` hot paths) · Gate 6 reproduce-on-base through the real API · Gate 7b exclusivity
· Gate 8 maintainer philosophy (openfga publishes an extensive spec + docs site; a contradiction
there is an automatic reject) · Gate 9 flakiness 3x on the memory datastore · Gate B (≥200 effective
with no scope lever).
