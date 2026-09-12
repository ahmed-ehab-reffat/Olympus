# DESIGN.md — ytt-library-schema-compatibility  (PHASE 3 — candidate scored, NOT yet scope-locked)

Repo: carvel-dev/ytt @ `6a94bf4ab733aededf7811ac7d398e59b767c9a6` (= HEAD).
Phase 1 repo understanding, Phase 2 repo-level prior art and all ten PICK-FILTER gates were completed
in the previous cycle and carry over unchanged; the full text is in
`rejected/ytt-overlay-write-provenance/DESIGN.md`. Only the CAPABILITY changed.

## Phase 3 — candidate table

| # | Candidate | Algorithm the repo lacks? | Magnet | Verdict |
|---|---|---|---|---|
| C1 | **Library schema-override compatibility** — an override supplied via `with_data_values_schema` must be compatible with the child library's own declared schema | **YES** — structural Type-vs-Type comparison over 8 type kinds with variance rules. `grep` for any `Equals/Compatible/AssignableFrom/Subsumes` on `Type` returns **zero**; `CheckType` only ever compares a Type against a NODE | LOW — unnameable without ytt nouns | **LEAD, with one real risk (below)** |
| C2 | Validations under an `any=True` subtree | No — `AnyType.AssignTypeTo` is a documented no-op; filling it is a missing arm | LOW | REJECT — missing-arm absorption, far under floor |
| C3 | `--data-value` path language extended to address array items | Weak — compiling a path to a matcher tree | LOW | HOLD — plausible but thin; ~150-250 eff, algorithm is shallow |
| C4 | YAML scalar round-trip fidelity (#889 quotes, #821 floats, #822 hex) | Yes, but it is the YAML 1.1/1.2 resolution spec | **HIGH** | REJECT — saturated-reference-port; the spec IS the answer key |
| C5 | JSON Schema export (#898) | No — mirrors `openapi.go` | **HIGH** | REJECT — named standard, and PR#901 "JSON schema export" already exists (CLOSED) |
| C6 | Overlay write-provenance / conflict policy | No — bookkeeping | LOW | **REJECTED** — see `rejected/ytt-overlay-write-provenance/`, new death class in TOO-EASY.md |
| C7 | Order-independence analysis of an overlay set | Yes, but data-dependent matchers (`when=`, `by=<fn>`) make it undecidable, so no fair contract can pin it | LOW | REJECT — cannot be fairly specified |
| C8 | `@schema/type one_of` | Yes | LOW | REJECT — **maintainer-owned**: #400's closure comments name `one_of` as their planned direction |

Also ruled out on maintainer ownership: the whole validations lane (#724 "Schema Validation v2" is an
OPEN maintainer-authored proposal with a published design PR — Stage 2d says a published plan is
prior art, not a gift).

## C1 — evidence

**Gate 1 reproduced on base, through the real CLI.** Child library declares `port: 8080` (int) and
`name: "svc"`. Root does
`library.get("mylib").with_data_values_schema({"port": "not-a-number"})`:

    port: not-a-number
    name: svc
    exit 0

The child's own templates now receive a string where the child's schema declared an int. Silent, no
warning.

**F-20 sibling-API asymmetry, measured.** Two sibling entry points on the same `libraryValue`:

| override | wrong TYPE | unknown KEY |
|---|---|---|
| `with_data_values({"port": "not-a-number"})` | **ERROR** "One or more data values were invalid" | ERROR |
| `with_data_values_schema({"port": "not-a-number"})` | **SILENTLY ACCEPTED** | ERROR "Expected number of matched nodes to be 1, but was 0" |

`with_data_values_schema` already rejects STRUCTURAL mismatches (unknown keys, courtesy of the
overlay's `ExactMatch: true`) but performs no TYPE compatibility check at all.

**Existing test coverage of the old behaviour: 2 hits, neither blocking.** `schema_consumer_test.go:2365`
adds a NEW key (`missing_ok=True`, additive, no type change); `:2526` uses a library with no schema of
its own, so there is nothing to conflict with. **No existing test asserts that an incompatible
override is accepted**, so the check can be added without regressing base. That absence is also the
F-20 precondition.

**Fan-out.** `datavalues.SchemaEnvelope` reaches the schema pre-processor from `library_module.go:168`
(Starlark `with_data_values_schema`), `library_execution.go:57` (`Schemas(overlays)`),
`template_loader.go:49` (threaded `librarySchemas`), `@library/ref`-annotated schema documents, and
nested libraries. `library_execution.go:298` already carries a sibling check over the same values
(`checkUnusedDVsOrSchemas`) — an in-repo precedent for validating envelopes at this boundary.

**Prior art CLEAR.** Searched `with_data_values_schema`, `schema override`, `library schema`,
`schema compatibility`, `schema type change`, `override schema type` across issues AND PRs, all
states, and read the bodies+comments of the three nearest hits (#563, #724, #400). Nothing requests
or implements override compatibility. No repo docs describe `with_data_values_schema` at all.

## ⚠️ The risk to resolve before scope-locking C1

`TOO-EASY.md`'s **first** death class is the membership/validation contract: *"reject invalid X across
the family ... one guard at N sites = uniform-wrap; fairness forces stating the contract, which
directs the agent straight to the fix"* (killed petgraph-node-validation). A compatibility check is,
on its face, a validation contract.

The counter-argument, which needs testing rather than asserting: the contract sentence ("an override
must be compatible with the library's declared schema") does NOT hand the VARIANCE RULES, and those
are where the work is — is widening to `any=True` allowed? is narrowing an int to `nullable` allowed?
does an override may add keys but not retype them? Each is a genuine design decision with a
defensible answer, and the agent has to get all of them right. But every rule stated for fairness is
also a rule that can be transcribed (the ironcalc law), so the honest question is whether ENOUGH
difficulty survives full specification.

**Next action (HARDENING 3a.4): write the natural-but-wrong comparator** — the one a strong agent
produces from the contract — and check whether it fails a discriminator with a MISDIRECTING symptom.
If the naive recursive comparison gets every variance cell right first try, C1 is the petgraph class
and must be rejected like C6 was.

## Artifact-level finding to carry into test.sh (independent of which capability wins)

⚠️ **The repo's baseline contains an UNSEEDED fuzz test.** `schema_consumer_test.go:2554`
`getYttRandSource` seeds from `time.Now().UnixNano()` unless `YTT_SEED` is set, and drives a
100-iteration fuzz over random ints/strings/floats asserting round-trip formatting. The test itself
prints "To reproduce this test failure, re-run with `export YTT_SEED=...`", i.e. its authors expect
failures. Three local full-suite runs were identical, but that is not proof for an unseeded fuzzer.
**`test.sh` base mode must export a fixed `YTT_SEED`**, and the choice must be documented — this is
the mandatory flakiness gate, not an optimisation.

## Variance-cell probe on base (2026-09-08) — the surface is INCONSISTENT, which is the opportunity

Ran eight override cells through the real CLI against a child library with its own schema:

| child schema | override | base behaviour |
|---|---|---|
| `port: 8080` (int) | `"str"` | **ACCEPTED silently** |
| `port: 8080` (int) | `1.5` (float) | **ACCEPTED silently** |
| `name: "svc"` (string) | `7` (int) | **ACCEPTED silently** |
| `port: 8080` (int) | `None` | ERROR |
| `xs: [1]` (array of int) | `[]` | ERROR |
| `xs: [1]` (array of int) | `["a"]` | ERROR `Expected map, but was string` |
| `m: {a: 1}` (map) | `5` | ERROR `Expected number of matched nodes to be 1, but was 0` |
| `v: 1` (scalar) | `{a: 1}` | ERROR `Expected map, but was integer` |

**Read.** SCALAR retyping is silently accepted; STRUCTURAL retyping errors — and it errors from the
OVERLAY engine, not the schema, so the messages are wrong for the situation ("Expected map, but was
string" for an array-item type mismatch; a match-count message for a map/scalar mismatch). There is
no coherent contract here, only whatever the overlay merge happened to do. That is a genuine,
repo-specific, messy correctness surface with an in-repo sibling (`with_data_values`) that behaves
coherently.

## ⚠️ The architecture-jump to design against (F-1)

A schema document IS its own default values, so an agent can skip Type-vs-Type comparison entirely:
materialize the override schema's defaults into a node and run the EXISTING `schema.CheckNode`
against the child's type. That reuses machinery the repo already has and would pass many cells.

This is good news and bad news. Good: it is a convergent architecture, so per F-1 the lever is to
find what it structurally cannot do — candidates are `any=True` subtrees (`AnyType.AssignTypeTo` is a
no-op that never descends, so a materialized node carries no type), `@schema/nullable` (a default of
`null` type-checks against anything nullable while saying nothing about the wrapped type), an EMPTY
array override (no item type to infer, so nothing to compare), and keys present in the child but
absent from the override (no node materializes, so nothing is checked). Bad: if the jump clears every
cell, the capability collapses to "call CheckNode" and is absorbed.

**This is now the decisive experiment, and it must be run before scope-lock:** implement the
default-materialization + `CheckNode` version, and check whether it passes or fails the four cells
above. If it passes all four, C1 is absorbed and should be rejected like C6. If it fails two or more
with misdirecting symptoms, C1 has both an F-1 wall and an F-20 sibling and is authorable.

---

## ABSORPTION EXPERIMENT (2026-09-08) — C1 IS DEAD

Implemented the convergent architecture in `data_values_schema_pre_processing.go`: materialize the
override schema's defaults (`datavalues.NewSchema(...).DefaultDataValues()`) and type-check them
against the accumulated schema with the repo's existing `AssignType` + `AssignSchemaValidations` +
`schema.CheckNode`. **32 raw added lines (~25 effective), reusing only existing primitives.**

| cell | convergent impl |
|---|---|
| int child <- string | **CAUGHT** |
| string child <- int | **CAUGHT** |
| int child <- float | **CAUGHT** |
| `@schema/nullable` child <- wrong type | **CAUGHT** |
| nested map, deep retype | **CAUGHT** |
| `any=True` child <- wrong-typed sub | already errors on base for other reasons |
| array-of-int child <- empty array | already errors on base for other reasons |

**Every cell the capability exists to fix is solved by a ~25-line call-through.** There is no wall for
the Type-vs-Type comparator to climb: the repo's own `CheckNode` machinery already does the whole job
once you notice a schema document IS its own default values.

Two independent death classes, both fatal:

1. **Machinery-absorbed capability** (`TOO-EASY.md`): ~25 effective LOC against a 200 floor. The
   sketch said "recursive comparator over 8 type kinds, 250-400 eff"; reality is a call-through.
   Third instance in this workspace of the sketch overshooting by an order of magnitude.
2. **"Make X consistent with existing-correct sibling Y" = CHOKEPOINT PICK.** `with_data_values`
   already type-checks via exactly this machinery, so the agent reads the correct in-repo reference
   and replicates it. Near-pattern-followable by construction.

(Probe reverted; `git diff --stat` empty, `go build ./...` OK.)

## VERDICT ON ytt AS A TARGET — STOP

Two capabilities reproduced and killed, six more rejected at screening. The hunt skill's own rule:
*"Two or more of your candidate lanes dead in the same repo -> lane density, not bad luck. A further
candidate is a coin flip at the same odds."*

**The root cause is a property of the repo, and it is the one `TOO-EASY.md` names explicitly:**
*"Framework maturity is the enemy: the better the abstraction, the smaller your diff. Prefer a repo
with a real DOMAIN ... over a mature, well-factored FRAMEWORK where every extension point is already
abstracted."* ytt is exactly that framework. Its overlay engine, its `Type` tree, `AssignType` /
`CheckNode` / `DefaultDataValues`, its annotation and matcher machinery are all generic and complete,
so any capability layered on them is a call-through. Everything it does NOT already abstract is
governed by an external standard (YAML resolution, JSON Schema, OpenAPI) and is therefore a magnet.

That combination — generic internals plus standards-defined externals — leaves no authorable middle.
Do not spend another cycle here. The mechanical excellence (Apache-2.0, pure Go, vendored deps, green
deterministic baseline, zero subs against quota) is real and is exactly what made this look
promising; it measures AVAILABILITY, not depth.
