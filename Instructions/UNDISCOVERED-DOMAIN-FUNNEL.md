# Undiscovered-Domain Discovery Funnel

A repeatable sourcing method for finding hard-complex repos in domains we have NEVER mined — the antidote to Query 3's adjacency bias ("find repos similar to {approved}"). Brainstormed + approved 2026-06-27.

## The problem it fixes

Query 3 sources repos SIMILAR to our approved pool, so we keep re-mining the same families (interpreters/VMs, SQL engines, parsers/CSS, codegen, spreadsheet, geometry, version-solver, abstract-interp). "Similar-to-approved" is structurally incapable of reaching undiscovered topics. Worse: when we DO list new domains, the list comes from MODEL RECALL, which is itself the adjacency bias (we recall what we know). To go over-and-beyond, the domain enumeration must come from an EXTERNAL source, and shallow/saturated domains must be filtered BEFORE sinking per-repo recon.

## The funnel (4 stages)

### 1. ENUMERATE from an EXTERNAL source (bias-break — the core novelty)
Do NOT brainstorm domains from memory. Pull the candidate domain list from outside the model:
- arXiv `cs.*` subject categories (cs.PL / DB / DS / CG / CR / DC / LO / SC / MS / NA / SY / GR / CE ...) — each maps to an algorithm domain.
- ACM CCS topic tree; "papers-with-code" task categories.
- Handbook / textbook tables-of-contents (CLRS, AoCP, Handbook of Computational Geometry, Numerical Recipes, Hacker's Delight, Handbook of Floating-Point Arithmetic, ...) — each chapter = a domain whose canonical algorithm is non-obvious.
- GitHub Topics + dependency-graph mining (repos that DEPEND ON a known-hard engine = a sibling domain) + "README cites a paper" repos (externally-defined-spec signal).

### 2. DOMAIN DEPTH-LAW-YIELD SCORE (cheap pre-screen, before any clone/recon)
Rate each enumerated domain 0-2 on five axes; keep high scorers, drop the rest WITHOUT recon:
- **canonical != obvious** — the naive/textbook approach is subtly WRONG (robustness / numerical stability / ordering / concurrency / optimality). i.e. the agent must DERIVE, not RECALL. (0 = textbook-memorized like sort/BFS/RGB-HSL; 2 = must-derive like robust geometric predicates / affine-gap traceback / reverse-mode accumulation.)
- **externally-defined** — a paper / RFC / standard / reference-test-vectors pins correctness (FAIR oracle). (2 = cited paper or RFC with test data.)
- **stateful-engine shape** — the domain produces ENGINES (VM / solver / planner / simulator / codec / tape), not stateless transforms or pure-function libraries. (forced-representation lives in engines.)
- **under-saturated** — niche, NOT a faithful port of a famous spec/library (java.time / Box2D / zlib-decoder / scipy-formula = saturated). Less training data = real knowledge gap. ⭐ SUB-CHECK (added 2026-06-27, color-science): a domain can be under-saturated in TRAINING yet REFERENCE-GRADE in its mature libs (color libs AUTHORED CIEDE2000/gamut/adaptation correctly = already-correct, same death as martinez/fjall). ASK: does the mature gate-passing lib already implement the canonical algorithm CORRECTLY? If yes -> no base-wrong; only COVERAGE-EXTENSION survives, which then risks (a) leaked-reference (a reference impl exists elsewhere = pattern-followable) or (b) compression-to-Mars (dense math). Score this before recon.
- **NOT in our mined pool** — orthogonal to the approved families above.
Drop: shallow-transform domains, faithful-port domains, textbook-RECALL domains, non-software domains, already-mined domains.

### 2b. PIPELINE-ARCH LOC-YIELD SCREEN (the SECOND axis — added 2026-06-27b)
Stage 2's depth-score is the HARDNESS axis ONLY (canonical≠obvious = pass-rate ≤20%). It does NOT predict LOC. Proven: 6 deep picks build-measured to Mars in one session (petgraph 114, kysely 190, piccolo 363, ichiban, OLM, SPARTA) — all were correctness-GAP picks (guard/validate/transform/fix-one-algorithm) whose correct fix is SMALL even when the bug is deep. Olympus needs BOTH axes (the PRODUCT, not either alone):
- **AXIS-LOC (eff ≥450):** does the repo have a PIPELINE ARCHITECTURE — ≥3 sequential stages each with its own data structures (lex→parse→IR→opt→exec)? And does the candidate pick a CAPABILITY-ADD (new operator / mode / IR-pass / node-type) that must thread ≥3 of those stages? The cross-stage WIRING is the eff-LOC. (Necessary, NOT sufficient.)
- **AXIS-HARD (pass ≤20%):** the existing stage-2 depth-score (must-DERIVE) + the capability-add embeds ≥3 INTERDEPENDENT+MISDIRECTING traps.
- **Olympus WIN = pipeline-arch × capability-add × deep-domain × traps-embedded.** Failure modes this catches: pipeline+SHALLOW = big-LOC EASY reject (>20%); deep+PURE-FN-LIBRARY = genuinely hard but MARS-LOC (alignment/diff/color/graph-algo libs — one module, capability = one function = small). Score the repo's architecture-shape (pipeline vs pure-fn-library) BEFORE recon; a pure-fn-library domain caps at hard-Mars regardless of depth.
- ⭐⭐ THE REUSE-VS-NEW LOC LAW (added 2026-06-27b — built on 3 fresh build-measures + 6 priors; the decisive AXIS-LOC refinement): pipeline-arch × capability-add is NECESSARY BUT STILL COMPRESSES TO MARS if the capability REUSES existing internal scaffolding. Proven: taffy intrinsic-sizing build-measured to MARS ~249 (the keyword machinery — tags/constructors/predicates/serde — ALREADY existed in CompactLength, the "add" was thin re-exposure); jaq `?//` to MARS ~290 (reused pattern()/cons-list/try_catch); same as kysely/petgraph/piccolo. opa reduce/fold SURVIVED to OLYMPUS ~500-540 because its three LOAD-BEARING stages (parser backtracking / ordered-fold eval / accumulator type-fixpoint) are GENUINELY-NEW and do NOT compress onto the existing comprehension scaffolding. RULE: Olympus eff-LOC requires the capability to force GENUINELY-NEW machinery in its LOAD-BEARING stages, OR be a FAMILY of N related capabilities (count multiplies — glaredb 775/518 = a family of new aggregates/set-ops). A single capability threaded through a well-factored codebase = Mars however deep. ⭐ PRE-BUILD CHECK: grep the repo internals — does the core mechanism already EXIST (just unwired to the public surface)? If yes → it compresses → Mars. The reuse-vs-new classification of a BUILD-MEASURED slice is the LOC oracle; recon's stage-by-stage estimate is NOT (it assumes new code per stage; reality reuses). ALWAYS build-measure a slice and classify each stage reuse-vs-new before claiming Olympus.

### 3. GATE-PASS per surviving domain
- Default (C): does a >=500-star, permissive (MIT/BSD/Apache/MPL/Boost; NOT GPL/AGPL/LGPL), active-<12mo, supported-language (TS/JS/Py/Go/Rust/JVM/C++), PURE-language (no thin C-binding), offline-`--network none`-buildable repo exist in the domain?
- Escape hatch (B): if the method surfaces a clearly-legitimate sub-500-star depth-rich repo, FLAG it for user approval rather than auto-dropping (the depth-richest niche domains often live under the star-gate; geometry boolean-op libs are the canonical example).
- Bias domain selection toward TARGET-BIG-DEPTH-RICH: prefer undiscovered domains whose BIG repos are genuinely deep (proven once: statrs 806-star yielded depth-law picks), so we satisfy the star-gate without dropping to saturated big-popular repos.

### 4. PER-REPO — the existing pipeline, unchanged
reproduce-or-cite (run the entrypoint or definitive code-cite; NEVER "appears missing") -> cold-AND-deep (the deep algo lives in COLD code, Section-9 by commit dates) -> BUILD-MEASURE a real slice (>=450 Olympus / >=100 Mars; recon projections lie, 5x-confirmed this session) -> dedup (all dirs by feature class) -> SMOKE-BATCH (the only difficulty oracle).

## Saturation traps specific to new domains (flag in stage 2)
- Faithful DECODER / spec-port = idiomatic==canonical==correct (target the ENCODER / the non-obvious layer instead — compression decoder vs encoder-optimal-parse).
- Textbook core (naive Needleman-Wunsch, plain Myers-LCS, RGB<->HSL, forward-mode dual-numbers) = saturated; target the must-DERIVE layer (affine-gap, 3-way-merge, gamut-mapping, reverse-mode accumulation).
- Security-sensitive domains (crypto protocol state machines) = viable depth-law but flag the offline-testability + sensitivity.
- ML-framework-envelope (autodiff inside pytorch/jax/burn) = too big to build offline + the engine is buried; target a FOCUSED library where the engine IS the repo.
- ⭐ f2p ARCHITECTURE FILTER (added 2026-06-27b, generalizes the participle law): prefer INTERPRETERS / string-driven engines. Their programs are RUNTIME strings, so a new-syntax/new-construct feature gives AUTOMATIC clean f2p (test compiles on base, parse/eval fails at runtime, passes on solution). Serde/string-deserialization paths (e.g. taffy CSS keyword via serde) = same. COMPILE-TIME MACRO DSLs (e.g. crepe/ascent proc-macros) = BLOCKED: new macro syntax fails at compile time on base → `[build failed]` → platform can't classify per-test f2p (the participle trap, no runtime-string escape). Any pick whose public surface is NEW EXPORTED SYMBOLS has the same problem — ride the feature on an EXISTING-API surface that compiles on base and fails at runtime.

## First run (2026-06-27) — preview domains scored high (orthogonal, cited-paper, gate-plausible)
sequence-alignment (Gotoh affine-gap) · diff/merge (3-way + structural-tree-diff) · color-science (CSS-Color-4 gamut-mapping + CIEDE2000) · autodiff (reverse-mode tape accumulation) · compression-encoder (optimal-parse + entropy-canonical) · Knuth-Plass line-breaking · GIS routing/projection (contraction-hierarchies) · quant (ISDA day-count + curve-bootstrap) · canonical-serialization (CBOR/DER/deterministic-proto). Repo-hunt fired on the top 5; results -> FEATURE-BACKLOG.md.

## Relation to existing queries
Complements, does not replace: Query 3 (find-similar-repos) stays for adjacency top-ups; this funnel is the go-BEYOND path. After a repo passes the funnel, use Query 4/10 (invent-from-architecture, BOTH passes) + the per-repo pipeline. See `feedback_invent_never_issue_mine`, `lesson_codebase_brainstorm_beats_issue_mining`, and FEATURE-BACKLOG.md SOURCING STRATEGY.
