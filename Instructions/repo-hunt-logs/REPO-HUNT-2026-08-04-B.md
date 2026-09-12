# Repo hunt 2026-08-04-B — second sweep after allsorts died at Gate A

Prior state: `REPO-HUNT-2026-08-04.md` left the pipeline EMPTY. allsorts (RANK 1) was killed by the
Gate-A kill-test (stale `#[ignore]` markers, no behavioural f2p gap) and tork was killed on a
mechanical gate (live Postgres needed by the packages carrying its seam).

This sweep deliberately avoided every domain already swept (fonts, geometry, bio, geospatial, audio
DSP, workflow, routing, assemblers, markdown, CSS selectors, spreadsheets, units, typesetting,
structural diff, log processing, CAD) and went at authorization/policy, build systems, e-graphs,
ZK circuits, and RDF.

**Result: no clean RANK 1.** One CONDITIONAL candidate (cerbos), everything else rejected on a
mechanical gate. Details below so the next sweep does not re-derive them.

---

## CONDITIONAL RANK 1 — cerbos/cerbos — ★4521

- **URL:** https://github.com/cerbos/cerbos | **Apache-2.0** | **Go, pure** (no `import "C"` anywhere;
  generated protobuf is CHECKED IN at `api/genpb`, so no codegen at build time)
- **Last commit:** 2026-08-03 · **open issues 55 · open PRs 6** (issue window RELAXED from 100-1000)
- **Local dedup:** ZERO hits across `Instructions/`, `problems/`, `rejected/`, `approved-problems/`,
  every prior REPO-HUNT. Quota 0/6. Not in `SATURATED-REPOS.md`.
- **Architecture:** `internal/parser` -> `internal/compile` (variables/constants, 642+359 LOC) ->
  `internal/ruletable` (index + `ruletable.go` 1002) -> TWO evaluators: `check.go` (797, full
  evaluation) and `plan.go` (409) + `internal/ruletable/planner/` (3131 LOC, partial evaluation into
  a query-plan AST). Conditions ride `internal/conditions` + `internal/evaluator` (CEL).
- **Test surface:** YAML fixture directories under `internal/test/testdata/{engine,compile,planner,
  engine_lenient_scope_search,engine_strict_scope_search,...}` — behavioural, table-driven, cheap to
  extend, no mocks.

**Trap seams**

| Pattern | Present | Evidence |
|---|---|---|
| F-9 cross-stage resolution drop | **yes (lead)** | `internal/compile/variables.go` resolves variables/constants at compile time; `ruletable/check.go:579 evaluateVariables` re-resolves at eval time. Both placements look reasonable = the exact neva ambiguity |
| S5/S6 dual evaluator of one model | **yes (strongest)** | `Check` (full) and `Plan` (partial -> `planner.QpN` AST) evaluate the SAME rule table. Divergence between them is repo-internal and cannot be named externally |
| F-10 cross-product | **yes** | axes: scope depth (scoped policies + `LenientScopeSearch`) x policy kind (principal vs resource) x role kind (direct vs derived) x action wildcard |
| F-2 bidirectional | partial | derived roles are both an input to and an output of rule matching (`withEffectiveDerivedRoles`) |
| F-1 architecture wall | unknown | needs a batch's passing patches to identify — cannot be pre-scored |

**Stage 2b derivative risk: LOW.** The one-line summary of the best thesis ("make the query planner
agree with check on scoped derived roles") cannot be written without cerbos' own nouns. Zanzibar-style
naming does not apply here — cerbos' model is its own (scopes, derived roles, scopePermissions,
output expressions).

**THE CONDITION (why this is not RANK 1 outright).** PR **#3312 "Strict evaluation mode"** (maintainer
`dbuduev`, opened 2026-08-04) touches `internal/ruletable/check.go` +46/-11, `plan.go` +21/-2,
`planner/planner.go` +19/-15, `internal/evaluator/{cel_errors,conf,evaluator}.go` — i.e. **exactly the
core files any check-vs-plan parity pick would touch.** Core-dir velocity confirms it is warm, not
cold: `internal/engine` 26 and `internal/compile` 20 commits in the trailing 12 months.

Verdict: the STRONGEST thesis (check/plan parity) is exclusivity-dead against #3312 by the bright-line
overlay test. cerbos survives only if a pick can be found whose footprint sits in `internal/compile`
+ `internal/ruletable/ruletable.go` + `index/` and NOT in check.go/plan.go/planner.go. Do a Gate-A
kill-test before any further investment.

**Second risk:** `go.mod` requires **go 1.25.11** and `go.work` requires **1.26.4**; PR #3236 is an
in-flight go1.26 bump. Confirm `olympus-base-go` carries a new enough toolchain before authoring.

---

## REJECTED this sweep, with reasons

| Repo | ★ | Reason |
|---|---|---|
| **moonrepo/moon** | 4029 | **Gate 5 dead — the whole core is a live workstream.** Trailing-12mo commits: `crates/config` 100+ (API cap), `crates/action-graph` 51, `crates/project-graph` 37, `crates/task-graph` 11. MIT/Rust/own-vocabulary otherwise fine. |
| **egraphs-good/egglog** | 806 | **Gate 5 dead.** `src/ast` 100+ commits in 12mo (API cap) plus 27 open PRs against 92 issues — a research repo under continuous refactor. Deep and non-nameable, so worth revisiting only if the core ever cools. |
| **thought-machine/please** | 2604 | Core dirs LOOK cold (`src/core` 10, `src/build` 5, `src/graph` 0 commits/12mo) but PR **#3565 "Refactor build_target to remove most of dependency resolution"** rewrites `src/core/build_target.go` **+201/-270** plus `src/build/incrementality.go` — the heart of the graph, i.e. the only interesting pick. 28 open PRs, 97 commits/12mo. Also self-hosting (builds itself with `plz`), which is a real Docker/base-mode cost. |
| **noir-lang/noir** | 1382 | **791 open issues+PRs.** Aztec-team firehose; exclusivity is unmanageable. |
| **oxigraph/oxigraph** | 1795 | SPARQL/RDF — every capability is W3C-named = Stage 2b HIGH derivative + saturated reference. |
| **Consensys/gnark** | 1729 | ZK proof systems are externally named (Groth16/PLONK) and the non-named part is heavy field math; deprioritised, not fully audited. |
| **openfga/openfga** (5543), **dimforge/rapier** (5603) | — | Over the 5000-star preference; both otherwise plausible (openfga = Zanzibar-named though; rapier = own solver vocabulary). Revisit only if the star window is relaxed and the relaxation is recorded. |
| **holo, hyperqueue, uvm, madsim, CreuSAT, smartcore, Clarabel** | — | Already rejected in `REPO-HUNT-2026-08-04.md`. |

---

## Method notes (cost paid this sweep)

1. **`gh search repos` is near-useless for niche engines.** Multi-word domain phrases ("dependency
   resolver", "constraint solver", "type checker", "wasm interpreter") returned ZERO or one result
   across both languages, while the same domains have obvious well-known repos. The index matches
   name/description/topics only. **Name candidates from domain knowledge and verify them with
   `gh api repos/O/R`** — that is what produced every candidate above. Also note
   `gh search repos --json licenseInfo` is INVALID; the field is `license`.
2. **`gh pr view` is ~10x slower than `gh api repos/O/R/pulls/N/files`** and will blow a 2-minute
   tool timeout on a 28-PR queue. Use the API form, and run the enumeration in the background.
3. **A `--depth N` clone makes `git log --since` lie.** `git log --since=12.months` on a depth-60
   cerbos clone reported 25 Go commits; the API reports the core dirs alone at 20-26. Use
   `gh api repos/O/R/commits?path=...&since=...` for per-directory velocity, never a shallow clone.

## Owed before authoring cerbos (`PICK-FILTER.md`)

Gate 1 behavioral-f2p-gap · Gate 5 per-FILE cold check against PR #3312's footprint · Gate 6
reproduce-on-base · Gate 7b exclusivity (canonical org, read the DIFF) · Gate 8 defined-behavior +
maintainer philosophy (cerbos publishes extensive docs under `docs/modules/` — a spec contradiction
there is an automatic reject) · Gate 9 flakiness 3x · Gate B (≥200 effective with no scope lever).
