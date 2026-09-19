# Repo hunt 2026-09-16-B - the two remaining STRUCTURAL gaps swept, both empty; discovery is now the binding constraint, not screening

Second hunt of the day, run after `customasm-exact-fractional-values` was built and parked on its
core-slice precheck. The earlier session had concluded that the cached 500-6000 star band was mined
out for the obvious shapes. This session tested that claim by sweeping the two slices the band
**structurally could not contain**, and by re-reading the ledger for candidates recorded as
gate-passing but never authored.

## What was swept, and what it yielded

| Axis | Why the cached band could not contain it | Fetched | Engine-shaped after filtering | Authorable |
|---|---|---|---|---|
| **Languages GitHub does not classify as ours** (Jupyter Notebook, Cython, TeX, CMake, Shell, HTML, Makefile) | the band was built with `language:` filters for the 7 supported languages plus C, so a repo whose PRIMARY language is a notebook or a build file is invisible to it even when the package inside is pure Python | 1,464 | 25 | **0** |
| **Stars above 6000** | the band was fetched as `stars:500..6000`; the platform floor is 500 with NO ceiling, so this slice was never queried at all | 3,299 + 181 C++ | 120 (79 in the 6k-15k slice) | **0** |

Both are now cached as `worktrees/_hunt/band_misc.jsonl` and `band_hi.jsonl`. **Do not re-fetch
either.** The dead list was rebuilt and unioned to 3,147 slugs as `deadlist_v3.txt`.

**Why the misclassification axis failed, which is worth knowing before anyone tries it again.** The
idea was sound - a language-filtered search has a real blind spot, and every rival author shares it -
but the repos in that blind spot are there for a reason. A repo whose primary language is TeX or a
notebook is a paper companion, a workflow, or a course, not an engine. The single genuine hit was
`arviz-devs/arviz` (Apache-2.0, 1852 stars, classified TeX, actually Python), and its capabilities
are named published statistics (effective sample size, split R-hat, Pareto-smoothed importance
sampling), which is the spec-knowable death class.

**Why the high-star axis failed, exactly as the kill list predicts.** The 6k-15k slice reads:
brotli, showdown, deck.gl, litestream, shiki, tvm, PapaParse, trino, gopherjs, rspack, zookeeper,
quiche, quic-go, JoltPhysics, numba, turf, datafusion, closure-compiler, graphhopper, cvxpy,
openh264, yaml-cpp. Above 15k it is rust, svelte, ripgrep, typst, babel, polars, swc, tree-sitter,
antlr, rust-analyzer, RustPython. The C++ slice is ClickHouse, duckdb, flatbuffers, fmt, simdjson,
foundationdb, mujoco, draco. Every one is either famous infrastructure, a named external standard, or
both. The kill list's ">5000 stars with a famous spec" rule is confirmed rather than refined.

## The ledger already holds the answer for its own "live" entries

Six repos are recorded in `SATURATED-REPOS.md` as "NOT saturated, NOT blocked, repo gates ALL PASS".
All six were re-read this session and **none is a fresh candidate**: rust-bio, jd, tdewolff/canvas,
fusesoc, allsorts and thermo each carry a written finding that the REPO passes and the FEATURE space
is dead, usually by absorption or by an external standard. `carvel-dev/ytt` is marked DO-NOT-PICK;
choco-solver and geometry-central are "still pickable" with their obvious lanes already sized and
rejected. That phrasing is doing its job - it stopped this session re-deriving five dead picks per
repo - but it also means the ledger has no unspent credit in it.

## wirefilter, audited and parked with a reason

Carried from this morning as the best-shaped unused repo: MIT, 1158 stars, 17 PR-free issues, 49
commits/12mo, competitor-free, 5 of 6 quota free, and an 18.3k-LOC filter-language compiler with
exactly the architecture the approved corpus rewards (lex -> parse -> typed AST -> scheme registry ->
compiled filter -> execution context). Audited the half our approved `wirefilter-dynamic-operands`
did not consume:

- `functions/` is **framework-absorbed**. The machinery is rich - a `FunctionDefinition` trait with
  `check_param`/`return_type`/`arg_count`/`compile`, a `FunctionParam` that distinguishes a constant
  argument from a variable one, `FunctionArgKind`, optional and variadic parameters, a type-erased
  `FunctionDefinitionContext` - but exactly ONE concrete function ships (`concat`). "Add functions"
  is the missing-arm shape by construction: the framework does the work, which is why the arms are
  small.
- The other tempting lane, folding a call whose arguments are all literals at compile time, is a
  post-pass over the public AST, which is the recogniser death class.
- Our approved sub already took expressions-as-operands, comparisons over collections, computed
  indices, map and array equality and the mapping semantics, i.e. most of `field_expr.rs` (3,353
  lines), `index_expr.rs` and `logical_expr.rs`.

Verdict: keep the repo on file for its shape and quota, but the two obvious remaining lanes are dead
and a third has not been found.

## The strategic finding, with today's evidence on both sides

Across the two hunts today the cold-start path produced **zero** authorable picks from roughly 5,000
freshly fetched repos and about 30 audited candidates, while the proven-pool path produced one
scope-locked, built and validated submission on the first serious attempt.

- **Cold start, 0 for 2 at the absorption gate:** ott-jax/ott and pymatting both cleared every
  mechanical gate and died because their remaining capabilities were absorbed by machinery the repo
  already owned.
- **Proven pool, 1 for 1:** customasm had three prior submissions, a known-good Docker and test
  harness, a measured fixture format, and quota to spare. The pick took a subsystem class none of the
  three prior submissions touched, cleared the absorption test on evidence (`grep` for float types
  across the whole source returns nothing), and measured 404 effective lines on the core slice alone.

**The constraint has moved.** Screening is no longer the bottleneck - the searchable universe is
swept and the filters work. Discovery is. The productive question is not "which repo is clean" but
"which repo that we already know hosts a capability we have not taken".

**Recommended order of work for the next authoring session:**

1. **Expand `customasm-exact-fractional-values` once its precheck is clean.** It is built, validated
   and 404 effective lines already; the arithmetic operators, emission rules, resolver integration
   and cross-product cells are specified in its DESIGN.md and should carry it past 600.
2. **Then a second customasm pick** if quota allows - after this one the repo sits at 4 of 6, and the
   expression evaluator, diagnostics and output-format surfaces are all untouched by our four.
3. **Only then a cold start**, and if so, sketch the RANK 1 candidate's named lane in effective LOC
   against its own abstract base class BEFORE writing the dossier. That check is what both of
   today's cold-start deaths lacked, and it costs ten minutes.
