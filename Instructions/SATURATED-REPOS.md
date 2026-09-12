# SATURATED-REPOS — do-not-pick blocklist (repo-level)

Repos to AVOID at pick time because of over-use / quota exhaustion. Check this file BEFORE scope-locking any repo (`PICK-FILTER.md § Gate 10 REPO-QUOTA`). This is repo-level saturation; for dead DIFFICULTY classes (uniform-wrap, saturated-port, membership-contract, etc.) see `TOO-EASY.md` instead.

## ⚠️ THIS FILE HOLDS TWO DIFFERENT KINDS OF ENTRY — do not grep it as one blocklist

- **REPO-DEAD (sections A, B, C, D, E):** the REPO is unpickable — platform saturation, our 6-cap,
  no commits in 12mo, off-GitHub development, dead upstream. A hit here is a hard reject.
- **LANE-LEDGER (section B2, and B1/B3 partially):** the repo is **ALIVE and still pickable**; a
  specific FEATURE LANE or SUBSYSTEM is dead. A hit here is **NOT a reject** — it is a briefing.
  Read the entry's *untouched surface* note and pick a different lane.

**Why this split exists (added 2026-08-07):** the hunt skill said "reject on any hit against
SATURATED-REPOS.md" while four entries in B2 literally begin "NOT saturated, NOT blocked" — one of
them (customasm) is a repo we have an **APPROVED** problem in. The mechanical grep was quietly
retiring good repos on the strength of one dead feature. Killing a repo for a failing FEATURE is a
category error: it shrinks the searchable universe permanently and throws away the licence, build,
determinism and dev-dep measurements the entry already paid for. Those measurements are the entry's
main value on a re-visit.

Every LANE-LEDGER entry should carry: what died, WHY (which gate), what is **untouched**, and a
**REVISIT condition**.

Two reject reasons live in the REPO-DEAD half:
- **GLOBAL-SATURATED** — the platform itself flags the repo as heavily over-used (all authors combined). It warns at submit and applies EXTRA review scrutiny; tasks are far more likely to be duplicate / low-novelty. Treat as effectively unpickable.
- **OUR-CAP-REACHED** — we have already shipped ≥6 submissions for the repo (our per-author 6-cap). The platform warns at submit. Do not add more.

Caps recap (admin 2026): ≤6 per repo per author, ≤3 per repo per week, global ≤50 per repo across the whole quest. Detail: `RULES.md § Repository Requirements` + `CLAUDE.md § RULE UPDATE 2026-06-26`.

---

## A. GLOBAL-SATURATED (platform-flagged over-used — all authors)

| Repo | Subs (platform) | Stars | Note |
|---|---|---|---|
| [deepnoodle-ai/risor](https://github.com/risor-io/risor) | **78** | 902 | Platform-confirmed 2026-07-02. The MOST over-used seen AND the LOWEST-star (902) — proves submission-count is UNCORRELATED with stars. Do NOT author risor. |
| [tobymao/sqlglot](https://github.com/tobymao/sqlglot) | 62 | 9373 | Platform-confirmed 2026-07-02. Do NOT author sqlglot. |
| [open-policy-agent/opa](https://github.com/open-policy-agent/opa) | 60 | 11900 | Platform: "heavily over-used ... strongly recommend choosing a different repository." UNSUBMITTABLE — killed a fully-validated Olympus build. Do NOT author opa. |
| [dop251/goja](https://github.com/dop251/goja) | 57 | 6976 | Platform-confirmed 2026-07-02. Do NOT author goja. |
| [cue-lang/cue](https://github.com/cue-lang/cue) | recon-saturated | 6175 | Recon-DEAD 2026-07-10 (not platform-count, our gate): 6.2k household config-lang (>5k presumed-saturated) + **develops on GerritHub → the mandatory SIX-CHECK is structurally BLIND** (`gh pr list --state merged` returns empty; merges are direct pushes with `Reviewed-on: review.gerrithub.io`) + maintainer FIREHOSE (75 `internal/core/adt` commits in 90d) actively closing the incomplete-corner gap-class an f2p would target. ⭐ GERRIT-DEV = SIX-CHECK-BLIND is a new do-not-pick signal (any Gerrit/mailing-list-dev repo: cue, some Go-team repos). Do NOT author cue. |
| [rhaiscript/rhai](https://github.com/rhaiscript/rhai) | derivative-saturated | 5474 | Recon-DEAD 2026-07-11 (not platform-count, our gate): a clean general-purpose embedded scripting-engine VM = the EXACT author-obvious class THE PATTERN names (goja/gopher-lua/risor/tengo/expr/cel). Confirmed via a fully-validated spread-operator Olympus (261eff/48 tests) killed **DERIVATIVE across 2 rounds (88%→82%)** vs a prior-author pipeline twin the GitHub SIX-CHECK could not see. The 5 dedup candidates prove the whole SYNTAX-SUGAR space is taken: spread (2+), destructuring/rest-patterns in let/const/for (3+), tuple type. Pipeline operator `\|>` is maintainer **wontfix** (PR #1061 CLOSED, issue #1062 CLOSED). Remaining deep gaps are shallow (mixed-numeric only `sort()` rejects; max/min/contains/dedup/eq already coerce) or pattern-adjacent (switch value-binding ~ destructuring). Do NOT author rhai syntax/collection features; a non-derivative pick would need an INVENTED deep-engine wrinkle (optimizer/dispatch/closure correctness bug) AND still carries the invisible pipeline-collision risk of any author-obvious VM. Prefer an obscure-domain deep engine instead. |

**Presumed-saturated (famous, NOT yet platform-verified — check before investing):** dgraph-io/badger (15.7k★), dream-num/univer (13.3k★), gopher-lua (6.9k★), apache/calcite (5.1k★ — the flagship JVM SQL query planner = textbook "SQL-tool class" author-obviousness, same class as sqlglot 62-DEAD; ALSO a prior build-verified structural-law collapse for gap-fills — verify platform sub-count before investing), and any household-name clean VM / SQL tool / policy-config lang.

When the platform shows a "this repository is heavily over-used" warning for a repo you were about to pick, ADD IT HERE (repo + sub-count + stars + the warning text) and pick a different repo.

### ⭐⭐⭐ THE PATTERN (2026-07-02, from goja 57 / sqlglot 62 / opa 60 / risor 78): submission-count is UNCORRELATED with stars. It tracks AUTHOR-OBVIOUSNESS.
risor (902★) is the most over-used repo seen — the star-proxy is FALSE. The over-used set = what a coding-problem author reaches for FIRST: clean general-purpose language VMs (goja/gopher-lua/risor/tengo/expr/cel), SQL parsers/transpilers/tools (sqlglot), policy/config langs (opa). These saturate regardless of stars because everyone independently picks them. **PREFER OBSCURE-to-problem-authors repos** = deep engines in UNUSUAL domains (bioinformatics / compression-codecs / structural-diff / numerical / computational-geometry / SAT-SMT-solvers / quant-finance / units / obscure DSLs), NOT the famous clean VM/SQL/config repo. Feature CLASSES transfer across repos; when a class dies on repo quota, re-home it on an obscure non-over-used repo. The ONLY oracle for sub-count is the platform "Learn more" page — verify before authoring. Full lesson: memory `lesson_repo_submission_cap`.

---

## B. OUR-CAP-REACHED (≥6 of our own submissions — do NOT add more)

| Repo | Our subs | 
|---|---|
| dasel | 9 |
| cliffy | 7 |
| yaegi | 7 |

### B1. CONTESTED-SUBSYSTEM (a prior author owns a whole subsystem — avoid that subsystem)

| Repo | Contested subsystem | Evidence |
|---|---|---|
| [open2b/scriggo](https://github.com/open2b/scriggo) | **Go LANGUAGE core** (checker/emitter/VM) | Platform derivative-verdict 2026-07-21: a prior sub is a broad "recent-Go-language-completion" upgrade covering **range-over-int + range-over-func iterators + min/max/clear builtins + labeled break/continue + per-iteration loop-var semantics**. Killed `rejected/scriggo-range-iterators` (fully built + Docker-validated) as DERIVATIVE. Any missing-Go-language-feature pick in scriggo (interfaces/methods/generics next) is HIGH derivative risk — the same author is actively completing the language. Scriggo's TEMPLATE engine (auto-escaping contexts / render-show pipeline / macro-render / markdown-conversion) is a DIFFERENT surface and may be open, but treat the language core as contested. |

| [m4b/goblin](https://github.com/m4b/goblin) | **`src/mach/` import/fixup resolution (`imports()`, `bind_opcodes`, chained-fixups)** | Scope Gate reject 2026-08-20 (`goblin-macho-chained-fixups`, `derivative`, "narrower derivative of older accepted candidate"): a prior accepted submission already implements `LC_DYLD_CHAINED_FIXUPS` parsing at `goblin::mach::chained_fixups` — the pointer-chain walker, import-table decoder, bind resolution, and `MachO::imports()` integration — on the exact same files. Fully built + validated (18 tests, 3x deterministic, correct fail-to-pass on base) before the reject landed; not curable by rewording, since the entire pick IS the chained-fixups core. |
| [cloudflare/lol-html](https://github.com/cloudflare/lol-html) | **`src/selectors_vm/` (the CSS selector matcher)** | AI-Dedupe 2026-08-01: `duplicate` 0.80/0.91 conf against an older same-author-pipeline sub implementing the SAME `+`/`~` + `:is()`/`:where()` work at the SAME five files. TWO more older subs (`similar_idea` 0.76 / 0.73) independently add `:is()`/`:where()` to the same VM, one going further with combinator-bearing alternatives, ancestor hoisting and complex `:not()`. Killed `rejected/lol-html-sibling-combinators` (fully built + validated: 292 eff, 66 f2p, 8 traps reproduced). At least 3 prior authors own this subsystem. The remaining unimplemented selector forms (`:nth-child(of S)`, namespaced selectors, `:empty`) touch the same parser/ast/compiler/stack surfaces and will flag the same way; `:has()` + `:last-child`/`:only-child` are maintainer-declined or streaming-impossible (issue #145). The REPO is otherwise fine and uncontested outside this subsystem - rewriter / rewritable_units / transform_stream / parser state machine are open. |

| [paulmach/orb](https://github.com/paulmach/orb) | **the geometry core: ring winding, validity, antimeridian, `encoding/mvt`, `clip`, `planar`, `geo`** | AI-Dedupe 2026-08-02: verdict **`derivative`** on `problems/orb-ring-role-preservation` (fully built + validated: 247 eff, 41 tests, 3 traps trap-proofed, clean-room green). **FIVE older candidates, all orb**, and between them they own nearly every interesting surface: (1) `Rewind`/`Reverse`/`Valid` + `geojson.Rewind` + planar/spherical containment, signed area, centroid, decomposition (0.74 similar_idea); (2) **`encoding/mvt` ring-winding role preservation — the SAME core task**, plus grid-aware winding after quantization, consecutive-position dedup, `Layer.ValidateWinding`/`FixWinding`, layer extent/version defaults (0.70 **derivative**, the verdict driver); (3) `clip/smartclip` polygon reconstruction (0.67); (4) `geo.CutAtAntimeridian` + `BoundAtAntimeridian` integrated across clip/tilecover/`maptile.At`/mvt projection — **the same antimeridian feature I used as a scope lever**, sharing 3 behaviors verbatim (0.63); (5) `planar` boolean ops Union/Intersection/Difference/SymmetricDifference (0.63). ⭐ ALL THREE of my components (mvt winding, Orient API, antimeridian) collided independently — the extras did not save it, exactly as the rule predicts. **Untouched surfaces only:** `simplify/` (647), `quadtree/` (647), `resample/` (138), `encoding/{wkb,ewkb,wkt}`. The repo is otherwise excellent (MIT, cold, 1 open PR, deterministic) which is why this needs recording: the blocker is prior-author saturation invisible to every GitHub query. Treat orb geometry/winding/antimeridian/mvt as DEAD. |
| [encounter/objdiff](https://github.com/encounter/objdiff) | **the whole of `objdiff-core`** | Hunt 2026-08-02: enumerated ALL 12 open PRs and their file footprints. They blanket every core file: #385 `diff/mod.rs` +103; #381 `diff/code.rs` +38/-44 AND `diff/data.rs` +24/-21 AND `diff/mod.rs` +43; #384 + #368 `obj/read.rs` + `obj/mod.rs`; #383 `arch/arm.rs` + `arch/mod.rs` + `obj/mod.rs`; #373 `arch/x86.rs`. **There is no cold file in objdiff-core.** Worse, PR #358 "Find similar functions" (+181 new `jobs/find_similar.rs`, +43 `diff/mod.rs`) IS the content-based unmatched-symbol matching capability I was about to invent - publicly solved, caught only by enumerating PR file lists. Everything else about the repo was excellent (Stage 2b derivative risk LOW, deterministic baseline, `Object: Default` makes programmatic tests trivial), which is why this needs recording: the blocker is exclusivity/liveness, not quality. **RE-CHECKED 2026-08-06 — the revisit condition FIRED AND THE REPO IS MORE DEAD, NOT LESS.** The queue did drain (12 open PRs -> 8, and `diff/mod.rs`, `diff/code.rs`, `diff/data.rs` now carry NO open PR) — but it drained by **MERGING**: #358 "Find similar functions", #385 "Indicate when symbols are in the wrong order", #381 relocation-name diffing and #384 Metrowerks alignment ALL merged on **2026-08-05**, and the `diff/` commit stream shows four capability landings that same day. The remaining 8 PRs are architecture backends (`arch/x86.rs` #257/#368/#373, `arch/arm.rs` #383) plus `obj/read.rs`. So the invent-able space SHRANK by four features while the queue got shorter. ⭐⭐ **"Revisit when the PR queue drains" is a TRAP as a revisit condition** — a queue shortens either by closing (space opens) or by merging (space closes), and only the commit stream tells you which. Re-check the commit stream, never the PR count, and diff the MERGED set against your intended capability. |

### B2. LANE-LEDGER / ABSORPTION — ⚠️ **NOT A BLOCKLIST. These repos are still pickable.**

Mature well-factored engines where a specific capability lane died on the LOC floor (the repo's own
primitives absorb the feature). The repo is fine; the LANE is dead. Read the entry, note the
untouched surface, and pick elsewhere in the same repo if the seams are good. Do NOT auto-reject.

| Repo | Evidence | Lesson |
|---|---|---|
| [DioxusLabs/taffy](https://github.com/DioxusLabs/taffy) | 2026-07-21: THREE consecutive picks came up short. `rejected/taffy-visibility-collapse` = TOO EASY (naive ~120-line solution is spec-correct; strut/two-pass observably equivalent). `rejected/taffy-last-baseline` = TOO SMALL (genuinely hard, cross-subsystem flex+grid, cold, but the whole last-baseline family caps ~150-200 LOC / ~140 human-eff — cannot reach 250). Grid baseline alignment I planned to bundle turned out ALREADY IMPLEMENTED (via `baseline_shim`; the "treat as start" TODO comment is stale). | taffy is a tightly-factored layout engine: individual missing CSS behaviors are compact (30-120 LOC). ⭐ META-LESSON: on ANY mature well-factored engine, ESTIMATE the minimal-golden LOC (skeleton/slice) BEFORE building — recon agents over-estimate ("approaches 250") and mis-read stale TODOs as gaps. Verify irreducible-breadth empirically, not from a TODO comment. |
| [google/starlark-go](https://github.com/google/starlark-go) | 2026-07-22: MINIMALIST-PHILOSOPHY-HOSTILE. Deliberately-minimal config language; maintainers DECLINE language-syntax additions: list.sort() declined (bazelbuild/starlark#174 'no significant benefit'), del deliberately unsupported (PR#321), for-else/try-except/setattr proposals sit unaccepted. Also: a starred-unpacking build was DERIVATIVE of a prior sub. Accepted space = stdlib-module fns / Go embedding API / correctness fixes (small, pattern-followable). | Do NOT author language-syntax Olympus features here. Any Python-feature addition is a deliberate omission = philosophy reject. |
| [oasdiff/oasdiff](https://github.com/oasdiff/oasdiff) | 2026-07-22: PATTERN-FOLLOWABLE across every substantial surface. checker/ = 294 template rule files; diff/ = ~50 template `*_diff.go` files; flatten/allof merge_allof.go is 1611 lines but = ~15 near-identical `resolveX`/`mergeX` per-keyword functions (a template, not one algorithm). Remaining gaps (if/then/else, dependentSchemas, unevaluatedProperties) are the OPEN issues the maintainer is actively closing (#1097/#878/#886 = firehose/derivative) AND each is another resolveX copy. | An add-a-case architecture: every substantial feature is 'follow the existing 15 cases'. Triviality-filter DEAD (3+ identical examples) + Commandment #6 unsalvageable. |
| [golang/geo](https://github.com/golang/geo) | 2026-07-22: mature C++ s2geometry PORT. Verified 2 picks under-floor: Hausdorff = **49 eff** (reuses `ClosestEdgeQuery`+`MinDistanceToPointTarget`+`IncludeInteriors`); PolylineSimplifier consumer ALREADY present (`Polyline.SubsampleVertices`) + engine is a thin wrap over existing `s1.Interval`. Only ≥250 features (`InitToSimplified`/boolean-ops) sit on incomplete `S2Builder` graph (huge+REGRESSION-risk) and collide with open PR #275. | Unported pieces are either tiny (primitive-backed) or huge (builder-dependent). MEASURE minimal-golden LOC by sketch+compile BEFORE building; a 330-eff estimate was really 49. |

| [rust-bio/rust-bio](https://github.com/rust-bio/rust-bio) | 2026-08-02: NOT saturated, NOT blocked, and the REPO GATES ALL PASS — recorded so the next scientific hunt does not re-derive five dead picks. MIT, ★1821, 20 src commits/12mo, pure Rust, deterministic baseline (486 unit + 2 integration + 168 doctests, 3 identical runs, 48s build), zero exclusivity hits on every feature class searched. **The problem is the FEATURE space, not the repo: every gap checked was either absorbed by well-factored machinery or named by an external standard.** Measured: (1) `seq_analysis::orf` six-frame/reverse-strand — DEAD by ARCHITECTURE-JUMP (revcomp + rerun the existing forward finder + map coords + sort is correct and cannot be fairly forbidden, since "single streaming pass" is a HOW) **and** saturated-reference-port (EMBOSS getorf / Biopython are memorized); (2) `myers::long` alignment traceback — NOT A GAP, `LongTracebackHandler` already exists (long.rs:402); (3) myers text-side partial ambiguity — TOO SMALL, peq construction is ~20 LOC per path, feature lands ~50 eff (taffy absorption profile); (4) `pairwise` two-piece/convex gap costs — big enough (the `TracebackCell` u16 bit-packing at mod.rs:1030 is a genuine S3+S5 shared chokepoint that would be FORCED to widen to u32, touching both `pairwise` and `banded`) but the capability is EXTERNALLY NAMED (Gotoh convex gaps / minimap2) = Stage-2b derivative HIGH; (5) making `banded` consistent with `pairwise` — DEAD class, "make X consistent with existing-CORRECT sibling Y" (Y is the answer key, HARDENING.md § 2 DEAD list). | Mature well-factored scientific library, same profile as taffy and golang/geo above. ⭐ Two GENUINE assets remain if someone finds a large non-named capability: the repo DOCUMENTS a deliberate divergence from Edlib's traceback tie-break (substitution > insertion > deletion, vs Edlib's insertion > deletion > substitution, myers/mod.rs:24-26) = native F-8 that is FAIR to require because the repo states it; and there are two real S5 dual-path seams (`myers::simple` vs `myers::long` block-carry helpers; `pairwise` vs `pairwise::banded`). NOT swept: `io/`, `data_structures/`, `stats/bayesian`. Do not re-pick the five above. |
| [cockroachdb/apd](https://github.com/cockroachdb/apd) | 2026-08-05: **VENDORED-ANSWER-KEY + sub-floor.** ★801, Apache-2.0, pure Go (`math/big`, one dep), **1 open PR**, cold 4.5mo with real code commits, quota 0/6, niche (decimal libs are NOT the author-obvious VM/SQL class). Genuinely good coupling on paper: `Context{Precision, MaxExponent, MinExponent, Rounding, Traps}` threads through every operation and the `Condition` flags (Inexact/Rounded/Subnormal/Overflow/Underflow/Clamped) accumulate across a computation, giving F-10 (rounding modes x operations x flags), F-6 (rounding vs flag-set ordering) and A10 numerical-stability seams. **Two kills:** (1) the repo VENDORS the full General Decimal Arithmetic `.decTest` conformance suite in `testdata/` (abs, add, divide, exp, ln, log10, power, quantize, remainder, ...) and runs it from `gda_test.go` — for anything the GDA spec covers, **the official answer key ships inside the repo**, which is the HARDENING DEAD entry "make X consistent with existing-CORRECT sibling Y" with Y in-tree; invent OUTSIDE the spec and the behavior is no longer externally defined. (2) 4,594 non-test Go LOC, with `context.go` (1297) already implementing the operation set generically over rounding + conditions, so a new operation plugs in — the jd absorption profile. | ⭐ Check `testdata/` for a vendored CONFORMANCE SUITE at hunt time. A repo that ships the reference spec's own test vectors has the answer key in-tree for every spec-covered capability, which is invisible to the star/license/velocity/PR gates and only shows up when you `ls` the test data. |
| [ron-rs/ron](https://github.com/ron-rs/ron) | 2026-08-05: **EXCLUSIVITY-DEAD — the open-PR queue is capability-consuming and blankets every core file** (fourth confirmation of the objdiff law). ★3981, Apache-2.0, pure Rust, **`[dev-dependencies]` are 100% pure** (base64/bytes/option_set/serde/serde_bytes/serde_json/typetag — Docker-clean, unlike fundsp), `cargo test` green, code stream genuinely COLD (5 commits/120d, all small fixes). Excellent seams: a real three-way pipeline (`parse.rs` 1982 / `ser/mod.rs` 1665 / `de/mod.rs` 1465), an S6/S5 dual-path (serde streaming `de/mod.rs` vs the `Value` reflection model `de/value.rs`+`value/`), F-2 round-trip the repo already tests by name, F-10 across `extensions.rs` x representations, and the format spec is the repo's OWN (Gate 8 satisfied with NO external-magnet risk — a rare and valuable property). ~50 issue-numbered integration tests = ideal f2p surface. **The kill: 11 open PRs and they cover parse.rs, de/mod.rs, de/value.rs, ser/mod.rs, ser/value.rs AND extensions.rs, and they are FEATURE PRs, not maintenance** — #593 "Add arbitrary identifier extension" (a new `extensions.rs` flag threaded through parse+ser), #328 "Add `Value::Struct` variant and preserve struct names", #551 "`PrettyConfig::braced_structs`" (new syntax form through parse+de+ser), #578 "make value roundtrip", #605 number-range inf/NaN round-trip, #554 unquoted hex strings, #616 parser hot paths. Every capability class an author would invent here is already public. | ⭐ A COLD COMMIT STREAM DOES NOT IMPLY AN OPEN CAPABILITY SPACE. ron's maintainer commits almost nothing, while contributors have queued up the entire invent-able surface in PRs. Enumerate open-PR file lists AND classify them by KIND before scoring core velocity — the commit stream said "ideal", the PR queue said "dead". |
| [yassinebenaid/bunster](https://github.com/yassinebenaid/bunster) | 2026-08-05: **ABANDONED — a docs-only commit stream faking activity.** ★2675, BSD-3-Clause, shell-to-Go compiler with a real multi-stage pipeline, 15 open issues, only 2 open PRs (both peripheral), niche non-author-obvious domain. Reads like an ideal target and is used as an ANCHOR example in the olympus-hunt skill, which is why this needs recording. **12-month commit stream is 8 commits and ALL EIGHT are docs/README typo fixes** (`fix(docs): correct stderr redirection typos`, `Update README.md`, `Remove brew tap step`); the last real code change predates the 12-month window. Every fork is stars-0 and stale, so this is not the live-fork case, it is simply dead. Will trip the platform's >=500-star + active-maintenance precheck. | ⭐ Read commit SUBJECTS, never the count or `pushed_at`. A `docs:`/`chore:`-only stream reads as ALIVE through every count-based query. Added to `olympus-hunt` Requirement 6. |
| [SamiPerttu/fundsp](https://github.com/SamiPerttu/fundsp) | 2026-08-05: **DOCKER-INFEASIBLE — dead on `[dev-dependencies]`, not on quality.** ★1180, MIT/Apache-2.0, 31.3k src LOC across 50+ modules (clears the ~30k repo-fit proxy, unlike jd), a real S5 dual-path seam (`AudioNode` static/typenum-arity vs `AudioUnit` dynamic vs `Net` graph), unusual non-author-obvious domain, 54 commits/12mo, 3 peripheral open PRs. Everything about the repo reads authorable. **The kill: `cargo test` cannot run without system C libraries.** The `[dev-dependencies]` block carries `cpal` + `midir` (-> `alsa-sys`, needs `libasound2-dev`), `plotters` (-> `yeslogic-fontconfig-sys`, needs `libfontconfig1-dev`) and `eframe` (X11/wayland stack). **Cargo builds the ENTIRE dev-dependency graph for ANY test target — verified locally that even `cargo test --lib --no-run` fails on both `alsa-sys` and `yeslogic-fontconfig-sys`.** `olympus-base-rust` will not carry those headers, and installing them needs network at build time, which the Dockerfile rules forbid. The only workaround is editing `Cargo.toml` to strip dev-deps, which is a build-config change reviewers flag (and L11 is precisely about a Cargo.toml dev-dep escaping patch scope). Secondary concerns, never reached: float-tolerance assertions and typenum-generic channel arity make behavioral tests awkward; the Jan-2026 commit burst was capability-consuming (convolution engine, resampling, sequencer inputs, node-tree introspection). | ⭐ NEW MECHANICAL GATE: for Rust, read `[dev-dependencies]` at HUNT time, not at Docker time. A pure-Rust `[dependencies]` block proves nothing — audio (`cpal`/`midir`/`rodio`), GUI (`eframe`/`winit`), and plotting (`plotters`) dev-deps drag in `-sys` crates that make the whole repo untestable in our base images. Added to `olympus-hunt` Requirement 5. |
| [josephburnett/jd](https://github.com/josephburnett/jd) | 2026-08-05: NOT saturated, NOT blocked, quota 0/6, and every REPO gate passes — recorded so the next hunt does not re-derive the finding. MIT (read in full), pure Go, 2 deps, ★2291, core cold since 2026-03-01, no open PR on any core diff file, baseline deterministic 3/3 in 9s (only constant failure is `internal/web/ui` importing `syscall/js` off-wasm). Seams are real and citable: F-9 (`newPathSetKeys` path.go:26 resolves identity at diff time; `Patch` receives no options), F-2 (doc-stated diff/patch round-trip invariant node.go:35-42), F-10 (5 container walkers x strict/merge strategy), F-6, F-3, F-8. **It dies on the FEATURE space, not the repo — the taffy / golang-geo / rust-bio absorption profile.** Two independent kills: (1) **repo-fit LOC proxy**: 6.8k total LOC, ~4.5k core, ONE Go package — far under PICK-FILTER's ~30k floor, and the `JsonNode` interface (10 implementors, `diff`/`patch`/`equals`/`hashCode` all already generic) means every candidate capability is a plug-in, not new machinery. Feb-2026 saw a Claude-assisted 100%-coverage + published-`spec/` sweep, so the cheap gaps are closed. (2) **PROBED and found NO behavioral f2p gap** at the hypothesised asymmetry: `patch()` takes no `*options` (patch_common.go:26) and its equality check calls the public `Equals` with zero options (patch_common.go:57), which looked like a live cross-stage drop — but four probes (precision round-trip, SET permutation, nested-set-inside-removed-value, SET+keys reparse) ALL behave correctly, because jd's design deliberately embeds semantics in the PATH (`{}` set, `[]` multiset, `{"id":..}` set-keys) and `pathAhead.next()` re-derives the options at each level. The architecture is self-consistent; there is nothing observably wrong to fix. **Remaining candidates are all externally-named (Stage 2b magnets):** wildcard/recursive-descent PathOptions (glob; note `PathAllKeys`/`PathAllValues` are declared at path.go:11,16 and never constructed — vestigial, so the author intended it), diff reversal (`patch -R`), three-way merge (git), multi-document YAML (#43, external spec), case-insensitive keys (#123, plug-in ~80 LOC). **Also do NOT pick issue #82** (set-key path indexing) — the owner published the fix location (`appendIndex`), the fix, and the test gap in the comments. | A small, fully-generic, spec-published library: the walkers are complete, so capabilities plug in below the floor. ⭐ Confirms the rule that a cold core + great seams + clean exclusivity is NOT sufficient — measure the MISSING MACHINERY before ranking a repo, and treat a sub-10k-LOC single-package repo as presumed-absorbing. |
| [tdewolff/canvas](https://github.com/tdewolff/canvas) | 2026-08-07: NOT saturated, NOT blocked, quota 0/6, and EVERY repo gate passes - recorded so the next geometry sweep does not re-derive it. MIT (read in full), Go, ★1825, 20 open issues, only 3 open PRs (none on the fill-emission path), scoped suite deterministic 3/3 in under a second, ~37k LOC. **Gate 1 was CONFIRMED BY MEASUREMENT, not inferred:** `FillRule` has four values (`NonZero`/`EvenOdd`/`Positive`/`Negative`), `path.go:26` documents all four as user-facing, `FillRule.Fills` and `Path.Settle` implement all four - and every emitter collapses them to the SVG/PDF two-value binary, each differently (`rasterizer.go:110` `SetWinding(fr == NonZero)` flips Positive to the EvenOdd answer; pdf/ps/svg fall back to NonZero; `htmlcanvas`/`tex` ignore `FillRule` entirely). A clockwise square under `Positive` must paint nothing and all four backends painted it. **It dies on the LOC floor: the complete, correct, suite-green implementation across 7 files measured 44 effective LOC against the 200 floor** (raw 65). DESIGN.md sketched 213 meaningful; reality was 5x lower. Cause is MACHINERY ABSORPTION - `Path.Settle` already resolves any fill rule to a non-overlapping equivalent, so the correct per-backend fix is 2-6 lines (compute a `fillData`, guard the combined `B` operator on `FillRule.Native()`, swap one variable). There is nothing to build because the repo already built it. Artifacts kept at `rejected/canvas-fill-rule-backends/`. **REPO STATUS: ALIVE AND RECOMMENDED — only the fill-rule LANE is dead.** REVISIT: any lane needing machinery the repo does NOT own. **Untouched large surface: the `Renderer` interface has NO clipping at all** (`Size`/`RenderPath`/`RenderText`/`RenderImage` only), so clip-path support is genuinely new machinery across the protocol and all six backends (PDF `W`/`W*`, PS `clip`/`eoclip`, SVG `<clipPath>`, rasterizer masking), with open bugs #314/#348 (`Clip` vs `coordSystem`) as live Gate-1 evidence. Also untouched: the SVG parser reads `fill`/`stroke-*`/`transform` but NOT `fill-rule` (F-2 round-trip seam); `text/linebreak.go` Knuth vs Greedy dual path (S5). | ⭐ The repo is otherwise an excellent target and the fill-rule gap is REAL - do not re-pick it, but do not write the repo off either. Untouched larger surface: **the `Renderer` interface has no clipping at all** (`Size`/`RenderPath`/`RenderText`/`RenderImage` only), so clip-path support would be genuinely NEW machinery across the protocol and every backend (PDF `W`/`W*`, PS `clip`/`eoclip`, SVG `<clipPath>`, rasterizer masking) - plus open bugs #314/#348 on `Clip` vs `coordSystem` are live Gate-1 evidence. Also note the SVG parser reads `fill`/`stroke-*`/`transform` but NOT `fill-rule`, an F-2 round-trip seam. ⚠️ `go.mod` pulls glfw/fyne/gioui/go-webp/go-avif but ONLY `renderers/{fyne,gio,opengl}` and `examples/` import them; the core and the other backends build and test with no system headers. |
| [hlorenzi/customasm](https://github.com/hlorenzi/customasm) | 2026-07-30: NOT saturated and NOT blocked - listed here only so the next hunt does not re-derive the finding. `rejected/customasm-asm-block-expr-substitution` was built + fully validated then died at the long-horizon floor (167 eff / 1 file vs 200 / 2). Cause was ORACLE-ABSORPTION: the mature resolver/evaluator stack absorbed 4 of 8 sketched line items, so a 318-LOC sketch measured 167. | The REPO is a good target (cold, pure-Rust, 3 deps, 691-test 0.26s suite, real fixpoint resolver, harness runs every fixture under 2 optimization variants for free S5 coverage). Only small picks die. Pick something with a genuinely LARGE missing core (relocatable output + linking, issue #48), not an extension that plugs into the existing resolver. Full case study in TOO-EASY.md. |
| [tamasfe/taplo](https://github.com/tamasfe/taplo) | 2026-08-23: **PLATFORM-INVISIBLE DERIVATIVE — the whole "structural insert/remove via DOM `Rewrite` API" capability lane is taken by an older/parallel same-repo submission we cannot see locally.** `rejected/taplo-dom-structural-edit` was built end to end (298 eff LOC, 36 tests, all 5 claimed traps confirmed by real mutation-sweep, clean local apply/reverse/flakiness validation, zero local self-collision hits in `problems/`/`rejected/`/`approved-problems/`/`diamond-problems/`) and rejected at platform review as `overlap`: an older candidate already covers `insert_entry`/`remove_entry`/`insert_array_value`/`remove_array_value` PLUS inline-table-member insert/remove, dotted-key path CREATION (auto-vivifying intermediate tables), table-removal-cascade (removing a table drops everything it holds), and empties-a-table-keeps-the-header semantics — a strict superset of this pick's scope. Quoted from the reviewer: "Setting a missing one creates it in the innermost table on its path, after its last entry, before nested headers, indented like the line above. Leftover steps become a dotted key... Removing drops the entry's line with the comments directly above it, keeps the header of a table it empties, and takes a member's or element's separator; removing a table drops all it holds." Also already noted: `taplo-reorder-comment-preservation` (comment preservation during key reorder) is separately dead, publicly-solved upstream. | ⭐ Two dead lanes now cover BOTH halves of taplo's DOM mutation surface (comment-preserving reorder AND structural insert/remove) — a third pick in "edit the DOM and preserve formatting" is very likely to re-collide even though our OWN dedup checks (Stage 2b, local dirs, GitHub SIX-CHECK) all read clean, because the collision lives in the platform's cross-author submission pipeline, which this workspace cannot query. `Rewrite` in taplo is now a used-up subsystem for Olympus purposes; if re-picking this repo, target the FORMATTER, LINTER, SCHEMA VALIDATOR, or LSP subsystems instead of `dom::rewrite`/`dom::mod`, and expect that even those may already be taken — the derivative-magnet risk applies with equal force to any "obvious next capability" on a small, well-scoped public API cluster like taplo's `Rewrite`, regardless of how cold the file looked in our own commit/PR audit. |

| [olofk/fusesoc](https://github.com/olofk/fusesoc) | 2026-08-07-C (first PYTHON sweep): NOT saturated, NOT blocked, quota 0/6 — recorded so the next Python hunt does not re-derive it. BSD-2-Clause, ★1444, obscure FPGA/ASIC build-abstraction domain (not the author-obvious class), 74 commits/12mo, **G-PY2 CLEAN** (no numpy/scipy/lxml/pandas anywhere — deps are edalize/pyparsing/pyyaml/pydantic/simplesat/fastjsonschema/argcomplete). Real staged pipeline on paper: CAPI2 core files -> dependency resolution -> flow/target/parameter/fileset resolution -> backend generation, with a genuine two-tier `_append` inheritance form at `fusesoc/capi2/inheritance.py` (F-13 shape). **Two kills:** (1) **6,545 total Python LOC** — the jd profile, far under the ~30k repo-fit proxy; (2) **the machinery that would carry a pick lives in OTHER REPOS** — the SAT dependency solver is the separate `simplesat` package, the backend generators are the separate `edalize` package, so fusesoc itself is glue. Also open PR #778 already owns the `..._append` merge lane and #734 the runtime-validation lane. | ⭐ NEW PYTHON LAW: machinery absorption in Python happens at the **REPO boundary**, not inside a file. Python's packaging culture pushes heavy engines into separate installable distributions, so a repo can present a full pipeline in its module tree while importing every hard part. At hunt time, check total LOC AND read the dependency list for siblings that own the algorithms. Prefer monorepo-style engines over composable single-purpose libraries. |

Near cap (headroom, in parens): expr (1 left), pest (1 left), katex (2 left), knex (2 left). Recount at pick time across `Olympus-Approved/Feature-Requests/<repo>/`, `problems/`, `diamond-problems/`, `rejected/` before relying on these numbers.

---

### B2-CAUSALLEARN. py-why/causal-learn — LANE LEDGER (repo alive; ROTTEN TEST BASELINE, no test CI)

We hold an approved sub (`causal-learn-mec-enumeration`) so the repo is proven, MIT, ★1681, 56
commits/12mo, 61 real issues, only 2 open PRs, no competitor accounts.

**⛔ BLOCKER — the test baseline is broken and nothing upstream guards it.** Its only GitHub workflow
is `codespell.yml`; **no CI runs the test suite**, and runtime deps are unpinned. Measured in
`olympus-base-python`, 3 identical runs: **5 deterministic failures** —
`TestFCI::test_continuous_dataset`, `TestFCI::test_bnlearn_discrete_datasets`,
`TestBackgroundKnowledge::{test_pc_with_background_knowledge, test_mvpc_with_background_knowledge,
test_skeleton_discovery}`. Also **`TestPC` alone exceeds 600s**, which breaks the 3-5x flakiness
requirement and likely the platform harness.

**What died on it:** an S-F *orientation-provenance* capability (record which rule oriented each edge,
with its witness, across Meek R1-R4 on CPDAGs and FCI's 12 rules on PAGs plus background knowledge).
It had cleared everything else — absorption verified locally (the rules mutate the graph in place and
return a bool; zero provenance hits), NOT a TETRAD port (5 attribution files vs pandapower's 69),
TETRAD verified by clone to lack the capability (`Edge.Property` is PAG markup, `EdgeTypeProbability`
is bootstrap confidence, only `sepsetProvenanceDump` exists as a debug dump), Phase 2 clean, and zero
self-collision with the MEC pick (which added three standalone `utils/` files). The failing tests sit
in the capability's own lane, so they could not be excluded from base mode without the L31
anti-pattern.

**REVISIT when** upstream adds test CI and the FCI/background-knowledge failures are fixed. The S-F
provenance thesis stays valid and is written up in
`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-01-B.md`.

### B2-PANDAPOWER. e2nIEE/pandapower — LANE LEDGER (repo ALIVE, 1 approved sub; but MATPOWER's feature list is off-limits WHOLESALE)

**NOT saturated, NOT blocked**, and we hold an approved sub (`pandapower-reliability-assessment`,
823 raw / **557 human-effective across 14 files** — a good calibration point for any future
pandapower pick). BSD-3-Clause **verified by reading LICENSE** (GitHub says `NOASSERTION` only
because of the multi-line Kassel/Fraunhofer copyright block; there are no rider conditions). ★1252,
pushed 2026-09-01, 125 real open issues, no competitor accounts (`KS-HTK` checked and cleared — 24
repos, real identity, pandapower-focused).

**⛔ REPO-LEVEL DISQUALIFIER: pandapower is a PORT.** `pandapower/pypower/` vendors **69 files**
carrying `Copyright (c) 1996-2015 PSERC` (MATPOWER's copyright holder), and 25 further files
reference MATPOWER. pandapower's numerical core and its internal `ppc` case format ARE MATPOWER's.
**It therefore inherits MATPOWER's entire function list as prior art** — any capability MATPOWER
ships is both a Scope-Gate reject (`TOO-EASY.md` sibling-ecosystem row) and a saturated-reference-port
(a solver can transliterate the `.m` files onto the identical arrays).

**Killed by this: continuation power flow / voltage stability.** It had otherwise cleared
everything — absorption verified locally (`continuation`/`voltage_stability`/`loadability`/`harmonic`
= 0 files; the `cpf` hits were `dcpf`), Phase 2 clean (nobody has requested it), LOC sketched at
445-675 effective against the 557 calibration, and a genuine repo-specific integration wall
(`_run_ac_pf_with_qlims_enforced` snapshots and RESTORES `bus[:, [PD, QD]]` at
`pf/run_newton_raphson_pf.py:184,195,218`, silently reverting a continuation's own load scaling).
Then MATPOWER turned out to ship the complete family: `runcpf.m`, `cpf_predictor`, `cpf_corrector`,
`cpf_tangent`, `cpf_p` + `cpf_p_jac` (the parameterization switch — my identified crux),
`cpf_nose_event` (+cb), and **`cpf_qlim_event` (+cb)** — generator Q-limits during continuation,
which was to be my interdependent trap. Every design element, pre-implemented in the reference tool.

**BEFORE any future pandapower pick:** list MATPOWER's `lib/` function families and treat them as a
blocklist. What remains authorable is what pandapower added ON TOP of MATPOWER — the pandas-based
`net` model, `network_schema`, `groups`, `diagnostic`, `converter`, `grid_equivalents`,
`timeseries`/`control`, `protection`, `topology` — not its numerical core.

⚠️ **Shortcut to design against in any pandapower pick:** `timeseries/` + `ConstControl` + the
first-class `scaling` column (`build_bus.py:643-684`) let a solver fake many parametric analyses by
sweeping `runpp` until it stops converging. Same shape as `rejected/calyx-cider-checkpoints`.

### B2-THERMO. CalebBell/thermo — LANE LEDGER (⛔ DO-NOT-PICK as of 2026-09-08: solids lane empirically dead, last live gap now a public PR)

**NOT saturated, NOT blocked.** MIT (verified by reading LICENSE.txt), Python, 784 stars, 146
commits/12mo, **only 3 open PRs and 10 real issues** — the leanest queue seen in three hunts. Deps
`fluids`/`chemicals`/`scipy`/`pandas`, no C toolchain. Obscure domain (chemical-engineering
thermodynamics). All ten open issue bodies read: no magnet.

**DEAD LANE — solids in multiphase flash. Killed by an EXPERIMENT, not by reading.**
`thermo/flash/flash_vln.py:168` refuses solids outright:
```python
if solids:
    raise ValueError("Solids are not supported in this model")
```
That reads like a hard behavioural F2P gap for multicomponent solid-liquid equilibrium, and the lane
is genuinely unclaimed (ZERO commits matching solid/SLE/freeze/sublimation/eutectic/crystall across
146 commits in 12 months). It is nevertheless **machinery-absorbed**, proved by monkeypatching the
guard away and running a real flash in `olympus-base-python`:

- `FlashVLN` **constructs fine** with a `GibbsExcessSolid` — the guard is cosmetic.
- But it reports `skip_solids = True`, and water/methanol at 1 bar returns **one liquid phase at
  200 K**, far below freezing. Solids are silently ignored.

So the missing work is wiring solids into the candidate-phase set (`_finish_initialization` flags,
`phases_at`, the Gibbs comparison, stability testing, phase identification) — **not a new algorithm.**
The pieces are all present and already phase-agnostic: `sequential_substitution_NP` only ever calls
`phase.to_TP_zs()` / `phase.lnphis_at_zs()` and knows nothing of gas/liquid/solid; Michelsen stability
testing is composition-based; `identify_sort_phases` already takes a `skip_solids` argument;
`flash_utils.py` already carries 37 solid references incl. `TSF_pure_newton`/`PSF_pure_newton`; and
the solid phase model **`GibbsExcessSolid` is 32 lines**, a thin subclass of `GibbsExcessLiquid`
swapping vapour pressure for sublimation pressure.

The only residual difficulty is numerical convergence at the solid-liquid interface — which the
maintainer already flags in the PURE case (`flash_pure_vls.py:561`, "The solid-liquid interface is
NOT working well..."). That is a **mandatory-Gate-9 flakiness hazard** and is not something an agent
can be fairly graded on. Both branches lose: wire it and it is under-floor; solve the convergence and
the difficulty is numerical tuning.

**⚠️ DOCKER FOOTGUN (real, would bite anyone).** `thermo/Phase Change/DDBST_UNIFAC_assignments.sqlite`
is committed as a **0-byte placeholder**; the PyPI wheel ships it populated but a git checkout does
not. Without it `ChemicalConstantsPackage.from_IDs` dies with `sqlite3.OperationalError: no such
table: DDBST`. Regenerate during the image build (network is available there):
`pip install sqlalchemy && cd dev && python dump_UNIFAC_assignments_to_sqlite.py` -> 2.6 MB.

**⚠️ CONTESTED — see `feedback_pr_author_profiling`.** `steps-re` (anonymous, 2 followers) has two
thermo PRs (#187 `stream.py` zero-division, #182 multi-liquid selection in pure-component flash) and
a footprint across thermo, biotite, scikit-bio (a repo we hold an approved problem in), sunpy, lmfit,
PyDMD, ProDy, scanpy and more. Another problem author is mining this repo.

**UPDATE 2026-09-08 — the last live gap is now PUBLIC. Treat thermo as DO-NOT-PICK.** PR #186
(OPEN, 2026-07-31, `binggao1230`) implements solid-solid transitions in
`element_standard_state_integral`, activating Mn/Ti/Be/S against NIST-JANAF and unblocking
H2S/SO2/SO3/H2SO4/CS2/TiO2 in `standard_state_ideal_gas_formation` — the single most citable
behavioural F2P gap left in the repo (its body cites the abandoned `elif ele == "S"` branch and the
six `# TODO`-commented data entries). `steps-re` also has #187 open. The remaining tracker is
data-quality bugs only (#5 Fe2O3, #180 melamine Tb, #148 rhol_60Fs, #179 UFIP SMARTS). Repo also
quiet since 2026-07-13.

**REVISIT when:** a pick introduces new DOMAIN CONTENT (a model, an effect, an analysis, an
inversion), not a new CASE of content the generic flash machinery already covers.

### B2-YTT. carvel-dev/ytt — ⛔ DO-NOT-PICK as of 2026-09-08 (mechanically excellent, capability-absorbed: 2 lanes reproduced-and-killed, 6 screened out)

**NOT saturated by us (0 subs), NOT blocked. Audited 2026-09-08** (`repo-hunt-logs/REPO-HUNT-2026-09-08.md`).
Apache-2.0, Go, ★1876, pure (no cgo), `vendor/` committed so Docker Pattern B is trivial and offline.
`test-all.yml` green on `develop`; `go test ./pkg/...` deterministic 3/3, ~40s warm. All six
mechanical gates plus Gate 7 CI PASS.

**Seams are the best of the three referred repos.** overlay is used BOTH to build the schema
(`pkg/workspace/data_values_schema_pre_processing.go:137`) AND to post-process output
(`overlay_post_processing.go`) = F-2 producer/consumer duality. Three ordering-sensitive stages with
the ordering stated only in a comment (`:30` "Ensure files are in assigned order so that overlays
will be applied correctly") = F-6. schema carries 143 resolve/default sites against template 25 /
validations 6 = F-9. 111 skip/exclude sites = F-7.

**⛔ COMPETITOR SWARM at ~70% of the non-bot PR stream** — far past the ~1/3 alarm in
`feedback_competitor_swarm_fraction`. Since 2026-07: #1008 builtin-name-in-errors
(`MaxFreedomPollard`, created 2026-03, 181 repos, bio "Into evolving agentic AI"), #1007 self-reference
stack overflow, #1005 output-file exec bit (`ChrisJr404`, 610 forks), #1002 oversized `expects=` panic
(`arpitjain099`, 455 forks), #1000 UTF-8 BOM (`vsolano9`, 58 repos ALL under an `AgentPostmortem`
agent-eval org), #998 filenames in Starlark errors (`snowyukitty`, created 2026-03, 79 scattershot
forks), #996 debug-dump-when-off. **ytt's entire robustness / error-reporting / panic-surface gap
class is publicly filed.**

**DEAD LANES:** (a) anything robustness / error-message / panic-surface shaped — publicly filed above;
(b) the SCHEMA lane — `ytt-schema-open-maps` already burned a submission at derivative 90%;
(c) Starlark LANGUAGE features — we hold 3 `google/starlark-go` subs, derivative on sight.

**REMAINS OPEN:** an INVENTED capability in the overlay / data-values / library-execution semantics,
riding the F-2 + F-6 + F-9 stack above. Nothing in the tracker; the tracker is the magnet.

**⛔ VERDICT 2026-09-08 after a full Phase-3 pass: DO NOT AUTHOR HERE.** Eight candidates; two
carried to trap reproduction and BOTH died, six rejected at screening (YAML round-trip and JSON
Schema export are magnets — PR#901 already exists; `@schema/type one_of` is maintainer-owned per
#400's closure comments; the whole validations lane is maintainer-owned per #724, an OPEN
maintainer-authored proposal with a published design PR; validations-under-`any=True` is a missing
arm; overlay order-independence cannot be fairly specified because `when=`/`by=<fn>` matchers are
data-dependent).

- **Lane 1, overlay write-provenance** -> bookkeeping; both candidate walls collapsed to a single
  storage insight. New death class in `TOO-EASY.md`. Artifacts in `rejected/ytt-overlay-write-provenance/`.
- **Lane 2, library schema-override compatibility** -> looked outstanding (Gate 1 reproduced: a
  parent overriding a child library's `port: 8080` with `"not-a-number"` emits it silently at exit 0;
  a measured F-20 sibling asymmetry, since `with_data_values` type-checks and
  `with_data_values_schema` does not; absorption apparently clear, since the repo has ZERO
  Type-vs-Type comparison). **Killed by the absorption experiment: the convergent architecture —
  materialize the override schema's defaults and run the existing `AssignType`/`CheckNode` — is 32
  raw / ~25 effective lines and CAUGHT EVERY CELL.** A schema document is its own default values, so
  the Type-vs-Type comparator never needs writing. Also a textbook "make X consistent with
  existing-correct sibling Y" chokepoint. Artifacts in `rejected/ytt-library-schema-compatibility/`.

**ROOT CAUSE (the reusable finding).** ytt is a mature, well-factored FRAMEWORK: its overlay engine,
`Type` tree, `AssignType`/`CheckNode`/`DefaultDataValues`, annotation and matcher machinery are all
generic and complete, so anything layered on them is a call-through under the LOC floor. Everything
it does NOT abstract is governed by an external standard (YAML resolution, JSON Schema, OpenAPI) and
is a derivative magnet. Generic internals + standards-defined externals = no authorable middle. This
is `TOO-EASY.md`'s "framework maturity is the enemy" corollary, measured.

⚠️ **The mechanical excellence is a trap here.** Apache-2.0, pure Go, `vendor/` committed, green
deterministic baseline, `test-all.yml` passing, zero subs against quota, rich F-2/F-6/F-7/F-9 seam
map — all real, and all of it measures AVAILABILITY, not depth. Do not let a future sweep re-rank
this repo on those signals.

⚠️ **Flakiness landmine if anyone does return:** `pkg/cmd/template/schema_consumer_test.go:2554`
`getYttRandSource` seeds from `time.Now().UnixNano()` unless `YTT_SEED` is set, driving a
100-iteration fuzz over random ints/strings/floats; the test prints reproduce-with-this-seed
instructions, i.e. its authors expect failures. Base mode must pin `YTT_SEED`.

**SCOPE-LOCKED 2026-09-08 — overlay write-provenance + conflict policy.** All 10 PICK-FILTER gates
discharged at base `6a94bf4ab733aededf7811ac7d398e59b767c9a6` (= HEAD, so no post-base drift is
possible). Gate 1/6 repro through the real CLI: two overlay files both matching the same document and
both writing `spec.replicas` produce **silent last-write-wins, exit 0, no warning**, and the emitted
value flips (9 vs 5) purely with `-f` order. Gate 7b: only #1008 (`overlay/api.go +1/-1`, a builtin
name string) and #1002 (`match_annotation_expects_kwarg.go +5/-1`, an int-overflow guard) touch the
package at all — plumbing, not core machinery, so the conjunctive exclusivity test passes. SIX-CHECK
clean on provenance / conflict / last-write / double-write. **DEAD ends recorded while scoping:** an
overlay DERIVER (diff two docsets, emit an overlay) is Phase-3 dead — a standalone post-pass over a
public AST, the lyon recogniser class verbatim; a move/rename OP is missing-arm absorption against
`op.go`'s kind-dispatch switch.

**Residual risk that no query can discharge:** the swarm plus a known other author working this repo.
The lane avoids their footprint (all nine swarm PRs are error-message / panic / IO fixes) but the
pipeline stays invisible.

### B2-LYON. nical/lyon — LANE LEDGER (3 of 6 quota used, tracker MINED OUT by our own picks)

**Audited 2026-09-08.** Dual MIT/Apache, Rust, ★2598, 0 open PRs, 18 issues, 40 fix-only commits/12mo,
CI green. Mechanically pristine and the mechanical measurements are already paid for.

**We took the top three tracker issues ourselves:** #868 arcs join -> `lyon-arcs-join` (APPROVED),
#871 internal vertices -> `lyon-fill-internal-vertices` (APPROVED 1/10), #564 stroke-to-fill ->
`lyon-stroke-to-fill` (REJECTED, external-oracle exclusivity). What is left is magnets (#494 boolean
path ops, #826 clip-path — Clipper2 / `SkPathOps` / paper.js all ship these) or under-floor (#877
closest point on a cubic, #890 hatching offset, #915 stroke advancement UV). `lyon_algorithms` shape
recognition is separately DEAD at the Phase-3 guard (`TOO-EASY.md § RECOGNISER / POST-PASS`).

**⚠️ Our approved arcs-join capability is now a PUBLIC 6,300-line diff.** PR #965/#964 (`SonyStone`,
2026-09-04, CLOSED) "Add SVG 2 arcs joins with optional rounded miter clipping": `stroke.rs +1306/-53`,
`stroke_arcs.rs +2060`, `stroke_arcs_mesh.rs +1597`, `stroke_round_clip.rs +438`,
`stroke_arcs/svg2.rs +392`. The body restates our meta.md's fallback semantics and ends with a
scope-exclusion list. Account: 39 repos, 7 followers, no name/bio, forks only lyon. Harmless to the
accepted sub; kills the stroke-join family on exclusivity and proves someone else works this repo.

**Maintainer is mid robustness sweep** (#961 non-finite recursion hazards, #962 arc recursion bounds,
#966 merge-vertex error recovery) — that lane is being consumed too.

**REMAINS OPEN:** only an invented capability in `geom` (8794 LOC / 16 commits) or `path` (7430 / 11),
off-tracker, clearing the recogniser death class. Quota says 3 left; lane inventory says ~0.

### B2-CHOCO. chocoteam/choco-solver — LANE LEDGER (repo ALIVE and still pickable; delta + graph lanes sized and rejected)

**NOT saturated, NOT blocked.** BSD-3-Clause, Java 17, 776 stars, 139 commits/12mo (101 non-chore).
Zero Java problems in the approved set, so self-collision is nil. **Build verified 2026-09-01 in
`olympus-base-jvm`:** `mvn -B -pl solver -am -DskipTests package` = BUILD SUCCESS in 12m09s — but ONLY
after `git submodule update --init`: `solver/src/main/java/cpp` is a submodule
(`chocoteam/cpp-integration`) supplying `Connector`/`Message` for `CPProfiler.java`, and without it
the build dies with `cannot find symbol: class Connector`. Any Dockerfile's `COPY . .` must be fed a
clone with submodules checked out. Tests are TestNG, 304 test files / 821 main, group-tagged
`1s`(~2231)/`10s`/`checker`/`ibex`; surefire default runs `1s,10s,checker`. **Gate 9 NOT measured** —
45 unseeded `new Random()` in tests plus a randomised `checker` group make it a real open question.

**DEAD LANE 1 — delta monitors.** Exclusivity is CLEAN (no open PR or issue proposes any
delta capability; the 15+ delta issues #72/#130/#298/#323/#352/#837/#1122/#146/#518/#151 are all
CLOSED and fixed — a 12-year bug-swept lane). It dies on SIZE: the whole `variables/delta` package is
**1303 LOC across 21 files**. Nothing confined to it reaches the 200 floor.

**DEAD LANE 2 — graph variables.** Looks perfect on the hunt heuristic and is not authorable.
`solver/constraints/graph` is **8140 LOC over 57 files with ZERO open PRs**, `util/objects/graphs`
2635 LOC / 0 PRs, `GraphDelta.java` untouched since 2022-01-06, almost no issue traffic and no open
magnet. Issue #1053 even names the seam: *"we forgot to integrate this when we migrated choco-graph
into choco-solver."* Real, citable F2P gaps exist — see the MISSING-ARM-OF-A-DISPATCH entry in
`TOO-EASY.md` for the full list with file citations. **It is machinery-absorbed:** PR #790 already
built the graph search machinery (`GraphDecision`, `GraphStrategy`, `GraphDecisionOperator`,
`GraphEdgeSelector`, `GraphNodeSelector`, `GraphLexEdge`, `GraphRandomEdge`, `GraphLexNode`,
`GraphRandomNode`, `GraphEdgesOnly`, `GraphNodeOrEdgeSelector`, `GraphNodeThenEdges`,
`GraphNodeThenNeighbors`, `GraphCostBasedSearch` all exist), so each remaining arm is a thin
call-through sized by its Set twin — clean-arm total ~130 eff LOC. The two arms large enough to close
the gap are both contested: `Solution` (maintainer Dimitri claimed #1053 with "It should not be
difficult to allow this, I can take time to do it") and the nogood/`Literalizer` arm (the LCG lane —
`sat/MiniSat.java`, `sat/ArrayClause.java`, `sat/SatDecorator.java` all under open PRs #1234/#1236,
plus a `feat-lcg` branch family).

**ALSO CONTESTED (open PR queue, capability-consuming — measured 2026-09-01):** set expressions
(#1171), expression rewrite rules (#983), bitset IntVar API (#1150), half-reified propagators (#1241),
knapsack (#1238), scheduling/Task (#1237), black-box search (#1069), LCG (#1234/#1236). Also HOT by
commit stream: `PropagationEngine`, variable `view`.

**COLD but MAGNET:** `constraints/nary/automata` (4751 LOC, 0 open PRs, last real commit 2022-01-06) —
`regular`/`costRegular`/`multiCostRegular` are Global Constraint Catalogue names, so this is the
`TOO-EASY.md` textbook-standard-feature derivative class. Do not pick it.

**REVISIT when:** a pick is a NET-NEW ALGORITHM riding choco's propagation fixpoint (F-2 is the
repo's real asset — a bidirectional constraint graph with a genuine fixed point), NOT a missing arm
of a variable-kind dispatch. The build/submodule/test-group measurements above are a paid-for head
start.

### B2-GC. nmwsharp/geometry-central — LANE LEDGER (repo ALIVE and still pickable; two lanes dead)

**NOT saturated, NOT blocked.** MIT, C++17, 1335 stars, 44.8k LOC, 21 non-chore commits/12mo.
Measured 2026-09-01 in `olympus-base-cpp`: **builds clean, 201 tests pass 3/3 identical, native gtest
JUnit** — every mechanical gate and Gate 9 CLEARED. Full dossier:
`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-01.md`. Those measurements are a paid-for head start
on any revisit; do not repeat them.

**DEAD LANE 1 — mutation / user-data-through-mutation (`mutation_manager.cpp`, `manifold_surface_mesh.cpp`).**
Killed at olympus-author Phase 2, before any code. Three independent hits:
- [#47](https://github.com/nmwsharp/geometry-central/issues/47) "CornerData seems to not update
  correctly during mutation" — OPEN, **zero comments, since 2020**. Textbook
  open-but-unimplemented derivative MAGNET (`TOO-EASY.md` row): reads clean precisely because nobody
  engaged, which is what makes every author pick it.
- [#134](https://github.com/nmwsharp/geometry-central/issues/134) "collapseEdgeTriangular loses
  halfedge data" — publishes the loss mechanism as an **ASCII diagram** naming the exact lost
  halfedge and why the obvious repair violates the implicit-sibling property.
- [PR #135](https://github.com/nmwsharp/geometry-central/pull/135) — a public partial SOLUTION
  (`EdgeCollapseFixupCallback`, +41/-1 and +23/-1 on `manifold_surface_mesh.{h,cpp}`).

**Why the clean-looking sub-arm dies too.** The tempting escape is "propagate the MutationManager's
own constraint flags (`splittableEdges`/`collapsibleEdges`/`flippableEdges`/`repositionableVertices`)
across every mutation kind, not just edge split" — a genuine gap the source itself flags
(`mutation_manager.cpp:112` `// TODO: work out sane policies for updating after other operations?`),
untouched since 2022-04-01, under no open PR, and needing repo-internal nouns to state (so the
magnet test PASSES). It still dies, on the LOC floor via its own hard core: `collapseEdgeTriangular`
(`manifold_surface_mesh.cpp:1203-1206`) calls **`deleteEdgeBundle` three times** — `e`,
`heB1.edge()`, `heA2.edge()` — so propagating a flag across a collapse requires deciding which
SURVIVING edge inherits which DELETED edge's flag. That is #134's element-identity problem verbatim.
Strip the collapse arm to dodge it and what remains (flip + face-split propagation) is thin
`register*Handlers` plumbing far under the 200 effective-LOC floor: **machinery-absorbed**
(`MeshData` already owns the expand/permute/delete callbacks, so the buffer plumbing is free and only
the value semantics are missing).

**DEAD LANE 2 — intrinsic triangulations / common subdivision.** Four open PRs sit on the core files:
[#249](https://github.com/nmwsharp/geometry-central/pull/249) `intrinsic_triangulation.cpp`,
[#252](https://github.com/nmwsharp/geometry-central/pull/252) `common_subdivision.cpp` +
`intrinsic_triangulation_test.cpp`, [#254](https://github.com/nmwsharp/geometry-central/pull/254)
`flip_geodesics.cpp`, plus issue #246 on `delaunayRefine`. Capability-consuming in the lane.

**UNTOUCHED surface** (verified against the full open-PR file set, 2026-09-01 — no open PR touches
any of these): `surface_mesh.cpp` (1951), `exact_geodesics.cpp` (1384), `normal_coordinates.cpp`
(1229), `signed_heat_method.cpp` (1033), `direction_fields.cpp` (1004),
`signpost_intrinsic_triangulation.cpp` (913), `embed_convex.cpp` (768), `stripe_patterns.cpp` (559),
`remeshing.cpp` (429). Note `signpost_*` inherits from `intrinsic_triangulation.cpp`, which IS under
#249.

**REVISIT when:** #47/#134/#135 are closed or merged (the mutation lane's prior art becomes shipped
behaviour rather than an open magnet), OR for a pick in the untouched list above that does not route
through element-identity-across-collapse.

**Two false alarms recorded so the next visit does not re-spend them:** (1) the `mutation_manager`
and `int-tri-updates` BRANCHES look like a Stage-2c `fix/<topic>-*` family but are stale 2021
leftovers already merged, **313 and 297 commits behind master** — check `compare/master...<branch>`
before treating a branch name as a live workstream. (2) `docker pull olympus-base-cpp` fails with
`failed commit on ref "layer-sha256:..."` until `docker system prune -f`; it is local containerd
ingest state, not the registry.

### B2-ACOULAR. acoular/acoular — LANE LEDGER (repo ALIVE, 1 approved sub; the moving-source-in-flow lane is ABSORBED)

Probed 2026-09-01-C at olympus-author Phase 3, before any code. Repo stays pickable (BSD-3, ~650 stars,
no competitor account, green CI, 441 pytest-regtest snapshots, pure Python + numba, Dockerfile reusable
verbatim from our approved pick).

**DEAD LANE — moving sources / trajectory beamformers in a flowing medium. ~35-45 effective LOC, a 4-5x
shortfall against the 200 floor.** The retarded-time equation in a uniform flow is exactly
`apparent_r(x_s(te), x_m)/c = t - te`, and `UniformFlowEnvironment.apparent_r`
(`environments.py:290-333`) already solves that quadratic in closed form for an ARBITRARY source
position, with no time dependence — so it is already valid at any candidate emission position. The
Newton loops (`sources.py:1121-1130`, and byte-identical bodies at `:1383-1394` and `:1707-1718`) read
the environment only as `c0 = self.env.c`; swapping the one Euclidean distance line for the existing
helper is a 3-5 line edit, copy-pasted across three sites, two of which are literal duplicates.
`GeneralFlowEnvironment.apparent_r` (`:828-882`) likewise maps any 3-D point to a travel time and caches
per mic. **And the beamformer half is already flow-aware**: `BeamformerTimeTraj.result:418` computes its
delays from `self.steer.env.apparent_r`, not from a Euclidean distance, so the hoped-for source-to-
beamformer round-trip coupling does not exist — fixing the source alone makes the pair consistent, with
no regression to trip. The only genuinely bidirectional piece is the `conv_amp` `(1-Mr)` definition on
each side: one trap, self-revealing, ~8 lines.

**Also self-colliding.** Our approved `acoular-reflecting-panels` already rewrote the moving-source
emission-time solve (against a mirrored trajectory), and already touches `conv_amp`, `trajectory`,
`sources.py`, `tbeamform.py`, `tfastfuncs.py` and `fbeamform.py`. A second pick changing the emission-time
solve plus `conv_amp` plus the trajectory beamformer is the same capability class with a different
physical cause.

**Other lanes probed and rejected in the same pass:** microphone/source DIRECTIVITY is exclusivity-dead
(closed draft PR #536, `directivity.py` +337, `microphones.py` +8); `IntegratorSectorTime` Sector-object
support is a missing dispatch arm (~120 eff, absorbed); periodic/arc-length trajectories are a one-liner
(`splprep(per=1)`); frequency-dependent `Calib` is absorbed by `Filter`. Time-varying partitioned
convolution for a source moving through an impulse-response field (`PointSourceConvolve` +
`TimeConvolve`) was the RANK-2 thesis and is NOT probed — it remains the repo's best remaining lead, with
a defined-behaviour risk (the kernel interpolation law is author-chosen).

**⚠️ SECOND DEAD LANE, found 2026-09-04 — the whole rotating-machinery / virtual-rotating-array
subsystem is DEPRECATED.** `Trigger` (`tprocess.py:340`), `SpatialInterpolator` (`:756`),
`SpatialInterpolatorRotation` (`:1344`) and `SpatialInterpolatorConstantRotation` (`:1418`) all carry
`# pragma: no cover`, and `AngleTracker` (`:582`) raises a `DeprecationWarning` announcing removal in
version 27.01. It reads like a rich untouched physical lane (trigger/tacho signals, angle tracking,
array interpolation onto a rotating frame) and is scheduled for deletion — authoring into it is a
Gate-8 reject. Also measured the same day: the RANK-2 `TimeConvolve` lead is PARTLY absorbed —
`tprocess.py:2713` already implements uniformly-partitioned overlap-save with cached frequency-domain
kernel blocks, so only the IR-field model and the position-dependent kernel interpolation law are new,
and that law is author-chosen (state it fully in `meta.md` or it fails Gate 8).

**Untouched surface if revisiting:** `tbeamform` time-domain beamforming proper, `signals.py`,
`calib.py`/`microphones.py`, `tools/` metrics, `spectra.py`. ⚠️ AVOID `fbeamform.py` CMF/SBL (a TU Berlin
student is shipping there, PRs #667/#617) and `environments.py` (ours).

⚠️ **Harness rule for any future acoular pick:** `tests/regression/test_generator.py` auto-snapshots EVERY
`Generator` subclass via `case_default`. A NEW Generator subclass with a `source` trait enters that case
with no snapshot and reds base mode. Add default-off traits to EXISTING classes instead; the 441
snapshots then pin default behaviour bit-for-bit and give S3 baseline preservation for free.

### B2-SKFEM. kinnala/scikit-fem — LANE LEDGER (repo ALIVE, 1 approved sub, quota 5 left; **COMPETITOR-SWARMED as of 2026-09-10 — treat as AVOID**)

- **DEAD LANE — embedded manifolds (SHELVED 2026-09-10, `rejected/scikit-fem-embedded-meshes`,
  dedupe `derivative` 0.79 / conf 0.90):** meshes whose point array has more rows than the reference
  dimension. Another author submitted the SAME capability on 2026-09-06 (rectangular Jacobians, Gram
  measure, pinv gradients, CellBasis normals, finders, strip rule, PLUS MeshLine2 / line3 / higher-order
  trace). Our hunt ranked it 1 on 2026-09-09 because `skfem/mapping` was cold, no PR existed and the
  maintainer had invited it (#1076, #1121, D#1039) — every one of those signals is what drew the other
  author there first. Entry: `TOO-EASY.md § scikit-fem-embedded-meshes`.
- **COMPETITOR-OWNED LANES (visible only through the dedupe report, all by other authors):** hybrid
  tri+quad meshes with shared DOF numbering (`MeshHybrid`, `HybridBasis`, 2026-09-06); curved
  second-order mesh lifecycle (geometry-preserving refine, curved trace/join, `invF_free`, level-set
  snapping, iso finders for tri2/quad2/tet2/hex2, 2026-09-06); wedge elements + multifacet boundary
  assembly (2026-07-12). Three of these landed within eleven minutes of each other: one author is
  batch-mining this repo. With our hanging-nodes pick that is FIVE known submissions, and the mesh /
  mapping / basis layers are all taken.
- **DEAD LANE — wedge facet assembly (#743):** missing arm; maintainer published the two-`FacetBasis`
  design in 2021 and `RefWedge.facets` already fakes triangle facets with a repeated index.
- **AVOID:** EdgeBasis / edge affine mapping (open PR #1172), `ElementConstant` (#999),
  sparsity-pattern caching (#1197, maintainer experimenting), hex/tet hanging nodes (derivative of our
  own approved pick).

### B2-KOTO. koto-lang/koto — LANE LEDGER (⛔ DO-NOT-PICK as of 2026-09-10: the binding-pattern lane is held by an ACCEPTED foreign task; the rest of the language is finished)

- **DEAD LANE — nested / rest binding patterns (SHELVED 2026-09-10, `rejected/koto-nested-bindings`,
  platform overlap `Drop` / `Blocker`, 258 of 489 authored lines = 52.8%):** nested tuple patterns and
  rest captures in assignment / `let` / `for` / `catch`. An OLDER **accepted** Koto task by another
  author already supplies the central nested/rest binding machinery for assignment, `let` and `for`.
  Our extraction policy (iterator semantics + null-fill), middle-rest behaviour and catch/export
  integrations were rated extensions of that core. Every upstream gate was clean and stayed clean -
  the collision is invisible to GitHub. Entry: `TOO-EASY.md § koto-nested-bindings`.
- **DEAD LANE — generic type hints:** maintainer declined in a comment on closed #298.
- **DEAD LANE — bitwise ops (#37), tuple `+=` (#394):** maintainer-declined.
- **The rest of the language is FINISHED** (the PASS-1 verdict of `repo-hunt-logs/REPO-HUNT-2026-09-09-B.md`,
  reversed at PASS 3 only for the binding lane that is now dead). `async` is "planned" and is a
  subsystem, not a pick. Map destructuring (#475) shipped. Solo maintainer `irh`, contributor-friendly
  lanes.
- **Structural warning:** koto is a small scripting language, so it sits squarely in the
  `Famous-language-feature lane` death class (`TOO-EASY.md` taxonomy). Anything of the form
  "destructuring / guards / or-patterns / ranges / exhaustiveness / string interpolation" here is a
  collision magnet regardless of what the tracker says. Do not re-enter this repo on a pattern-matching
  or binding-syntax lane.

### B2-DROPFLOW. chearon/dropflow — LANE LEDGER (⛔ DO-NOT-PICK as of 2026-09-11: the repo PUBLISHES its pick list as a CSS support table, and the two deepest rows are already taken)

- **DEAD LANE — min/max sizing constraints (SHELVED 2026-09-11, `rejected/dropflow-min-max-sizing`,
  platform overlap `Blocker`, 204 of 290 authored lines = 70.3%, LLM comparison `Duplicate` 90% conf):**
  `min-width` / `max-width` / `min-height` / `max-height` across parser, style cascade, block inline box
  model, shrink-to-fit, intrinsic contributions, replaced-box ratio sizing and margin collapsing. An
  OLDER same-repo submission by another author already delivers the four declaration parsers, the
  re-resolve-margins-after-clamping helper, the shrink-to-fit clamp and a ratio-preserving
  `getConstrainedSize`. Our margin-collapsing exemption, contribution clamping and percent-definiteness
  rules were explicitly rated incremental. **No batch was ever run.** Entry:
  `TOO-EASY.md § dropflow-min-max-sizing`.
- **DEAD LANE — `position: absolute` (EXCLUSIVITY, public):** PR #34 `implement position: absolute`
  (OPEN, not a draft) ships a 306+/27- `layout-flow.ts` + 97+ `layout-box.ts` + 54+ `style.ts` diff with
  its own `position-absolute.spec.js`. Publicly solved; the scope gate rejects on sight.
- **Structural warning — the README IS the rival author's pick list.** dropflow ships a CSS property
  support table marking each property ✅ Works / 🏗 Partially done / 🚧 Planned. Every author who opens
  this repo reads the same table, and the 🚧 rows are exactly the authorable lanes (defined behavior,
  absent implementation, maintainer-blessed). The two richest rows are now consumed — by a rival
  submission (min/max) and by a public PR (`position: absolute`) — which is what a shared pick list
  looks like from the inside. The remaining 🚧 rows (`display: table`, `transform`, `position: fixed`)
  carry the identical collision risk, and `writing-mode` is marked 🏗 Partially done. Do not re-enter
  this repo on any row of that table. See the `Repo publishes a support matrix` row in the
  `TOO-EASY.md` taxonomy.
- **Mechanicals (all fine, and all irrelevant to why it died):** MIT, 1368 stars, solo maintainer
  `chearon`, base commit still master HEAD, 444-test mocha suite deterministic 5/5, quota 1/6 used,
  Docker builds and runs. The repo is healthy; the lane supply is what is exhausted.

### B2-CALYX. calyxir/calyx — LANE LEDGER (repo ALIVE, 2 subs, quota 4 left; FOUR lanes dead in one pass — read the structural warning before spending another hour here)

Probed 2026-09-05 at olympus-author Phase 2, before any code. Every REPO gate passes and passed
again on re-check: MIT, 611 stars, `Test`/`fud2 tests`/`Format` CI green, no competitor PR authors,
quota 2/6, 30.5k-LOC optimizer with 48 passes and 22 analyses, and a 925-effective-LOC approved pick
(`calyx-unused-port-elimination`) proving the repo carries Olympus-scale scope. The compiler core is
genuinely COLD — `calyx/ir` 3, `calyx/backend` 4, `calyx/opt` 16, `calyx/frontend` 13 commits per 13
months, and most of those are dependabot or profiler instrumentation.

**Four candidate lanes, four different deaths, none of them visible from the source tree:**

1. **Static components + combinational groups** (`calyx/opt/src/passes/simplify_with_control.rs:279`
   errors with *"Static Component {} has combinational groups which is not supported"*). **DEAD on
   maintainer philosophy.** Issue [#1785](https://github.com/calyxir/calyx/issues/1785):
   *"`static if` in Calyx should have a port but should not have a comb group: those are disallowed
   in a static domain."* The issue ALSO publishes the intended workaround design (hoist the comb
   group's assignments into the continuous-assignment stanza), i.e. a public solution sketch. The
   adjacent lane is live too: issue #2595 + **MERGED PR #2596** "Experimental pass to reduce cycle
   inefficiencies of `if` with combinational group" (2025-12).
2. **FIRRTL backend `@external` memories** (`calyx/backend/src/firrtl.rs:118` panics *"FIRRTL backend
   only works on ref, not @external!"*). **DEAD by design, not by omission** — the adjacent comment
   says *"The FIRRTL compiler cannot read/write memories, so we must use ref"*, i.e. a downstream
   toolchain limitation. Also under the maintainer roadmap [#1805](https://github.com/calyxir/calyx/issues/1805)
   "Tasks for Calyx-to-FIRRTL backend", and the whole lane is 4 golden tests.
3. **Statistics / resource-and-area accounting pass (S-F).** **SHIPPED.** Issue #1184 "Calyx Level
   Statistics Pass" is CLOSED, implemented by PR #1372, and the code is in-tree as
   `calyx/backend/src/resources.rs` (280 LOC) + `primitive_uses.rs` (110 LOC).
4. **Resource-budgeted cell sharing / cost model (S-G).** **Maintainer-claimed AND partly shipped.**
   Issue [#2021](https://github.com/calyxir/calyx/issues/2021): maintainer `calebmkim` replies *"I
   think I could take this on"* and points at the existing `-x cell-share:bounds=x,y,z` heuristic,
   which is real (`calyx/opt/src/passes/cell_share.rs:78-170`).

**⭐⭐⭐ THE STRUCTURAL WARNING — why a fifth candidate is a coin flip at the same odds.** calyx is an
ACADEMIC repo whose maintainers PUBLICLY ENUMERATE AND TRIAGE THEIR OWN GAPS: 163 open issues plus at
least four long-lived roadmap trackers (#1397 "To-Do Tasks for Static Groups", #1805 FIRRTL tasks,
#2207 "Rethinking Static Compilation", #2297 "First Class FSMs"), and a habit of maintainers claiming
lanes in comments. **Every gap findable by reading the source is already named, claimed, shipped, or
declared a non-goal.** This is the veryl 4-for-4 pattern with a nameable cause.

**⚠️ The generalisable law: the hunt's COLDNESS signal INVERTS for a repo with a public gap-tracking
culture.** `olympus-hunt` ranks on cold-core + live-repo + no-competitor, and calyx scores top on all
three. But in an academic compiler with a triaged tracker, a cold core means *finished and reviewed*,
not *unexplored* — the same trap `TOO-EASY.md § MISSING-ARM-OF-A-DISPATCH` records ("ranking on cold +
large + no open PRs selects for FINISHED subsystems"), one level up: it selects for finished REPOS.
**Before ranking any repo whose maintainers keep roadmap issues, sample 3-4 candidate lanes against
the TRACKER first — that is the real gate here, not the commit stream.**

**If revisiting anyway:** do NOT read the source for holes; that method is 0-for-4. Invent a
capability first, then filter it against all 163 issues. And respect the self-collision bound — our
approved pick is a whole-program dataflow pass over ports/cells with a fixpoint, so no further global
dataflow/dead-code pass, and `rejected/calyx-cider-checkpoints` burns the interpreter-state lane.

### B2-FRESH-2026-09-05. Fresh-domain sweep (optics / rocketry / kinematics) — first corpus entry for these domains

Swept with the corrected TRACKER-FIRST method (see B2-CALYX). Domains chosen because the corpus has
never touched them: optics, rocketry, kinematics, FDTD, photogrammetry.

| Repo | ★ | Verdict |
|---|---|---|
| [optiland/optiland](https://github.com/optiland/optiland) | 962 | **DEAD — feature-complete + reference-tool exposure.** MIT, CI green, genuine optics contributors (FSU Jena optical design, a 2014 account), no competitor signature. But the tracker being EMPTY on polarization/coherence/freeform/apodization does NOT mean absent: code search shows polarization is fully implemented (`optiland/rays/polarization_state.py`, `core/jones.py`, `analysis/jones_pupil.py`, `coatings/` Fresnel — 97 hits), plus non-sequential tracing, Huygens PSF/MTF, tolerancing (55), vignetting (23), apodization (30), GRIN (65). Its own issue #710 is *"validate Optiland against Zemax OpticStudio, CODE V, or another trusted tool"* — the package is an open reimplementation of the commercial optical-design feature list, so every capability is a named Zemax/CODE V feature (the pandapower/MATPOWER class, one step weaker because nothing is vendored). Also 8+ open PRs on core ray/backend numerics and a live JOSS review generating churn. |
| [flaport/fdtd](https://github.com/flaport/fdtd) | 717 | **RECENCY-DEAD** — `pushed:2025-09-22`, 0 commits in 180 days, last CI 2025-09-22. |
| [vccimaging/DeepLens](https://github.com/vccimaging/DeepLens) | 712 | Apache-2.0, 0 open issues, 100 commits/180d — but CI is dependabot graph-updates only (no test workflow visible), i.e. Requirement 7 unmet. Not probed further. |
| [Phylliade/ikpy](https://github.com/Phylliade/ikpy) | 1032 | Apache-2.0, 22 issues, 22 commits/180d, CI green, no open PRs. **Unprobed** — the nearest un-swept fresh-domain candidate if rocketry falls through. |
| [RocketPy-Team/RocketPy](https://github.com/RocketPy-Team/RocketPy) | 1057 | **ALIVE — best fresh candidate of the sweep. See the lane table below.** |

**RocketPy lane ledger (MIT, ★1057, 49 open issues, 100 commits/180d, CI `Scheduled Tests` green):**

- **Multi-stage / staging — EXCLUSIVITY-DEAD.** Open PR [#1155](https://github.com/RocketPy-Team/RocketPy/pull/1155) "ENH : Multistage mission architecture implementation", plus the team's own issue #662 "Full support for multi-stage rockets", #716 "2-stage Acceptance Test", #45 "Multi-stage example", and closed PR #913.
- **Fin flutter — ABSORBED.** `FinFlutterAnalysis` already lives in `rocketpy/utilities.py`; closed PR #873, issue #367.
- **Propellant sloshing — GENUINELY EMPTY AND THE BEST LEAD FOUND.** Zero code hits, zero issues, zero PRs for slosh/sloshing/aeroelastic. **The architectural evidence is what makes it real:** `Tank` exposes `center_of_mass`, `inertia`, `liquid_center_of_mass`, `liquid_inertia` as `@funcify_method` — time-indexed `Function` objects discretised BEFORE the flight integrates. Slosh is a state-dependent degree of freedom driven by the vehicle's lateral-acceleration history, so **the existing mass-property path structurally cannot express it** (the comrak "missing machinery" test, passed). That makes it an F-1 convergent-architecture wall: the natural patch point (`Tank`) sits upstream of where the information is destroyed. Couples tank -> motor -> rocket inertia/CG -> the 6-DOF ODE -> Monte Carlo.
- **PR-author profiling: CLEAN.** `thc1006` (real name, 301 followers, CNCF Ambassador, k8s footprint), `ViniciusCMB` (mech-eng student, Serra-Rocketry team), `aitorperezgrau-sys` (rocketry-only hobbyist). No scatter signature.
- **Gate 5 heat (12mo):** `motors/tank.py` **2**, `motors/liquid_motor.py` **0** (cold, and they are the core of the pick); `simulation/flight.py` **34**, `rocket/rocket.py` **24** (warm).
- ⚠️ **Risks to settle before scope-lock:** `flight.py` is 4626 lines and carries a four-year-old open architectural wishlist [#276](https://github.com/RocketPy-Team/RocketPy/issues/276) "Flight Class Overhaul" that explicitly lists staging among planned events, so adding ODE state there is invasive and brushes a declared intent; the pendulum/mass-spring slosh analogue is textbook (NASA SP-106), so the difficulty must live in the INTEGRATION or it collapses to spec-knowable wiring; `netCDF4` is a hard C-extension dependency and `requests`-based weather fetching means base mode must be scoped to non-network tests with a documented reason.
- ⚠️ **Cloning:** `git clone --depth 20` fails here with `fatal: fetch-pack: invalid index-pack output` for both RocketPy and optiland. Use a tarball (`gh api repos/O/R/tarball/<sha>`) or a tuned clone before authoring.

### B2-TIPPECANOE. felt/tippecanoe — LANE LEDGER (repo ALIVE, 0 subs, SCOPE-LOCKED 2026-09-12 — do not re-audit, read the dossier)

Full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-12.md`. C++17, BSD-2, ★1600, 0 of 6 quota,
base `4f2621186acfec33b63ddf636f665623c0fef2dd`.

**Everything mechanical is already paid for:**
- `olympus-base-cpp` already ships `libsqlite3-dev` + `zlib`, the repo's only system deps, so the
  Dockerfile is `FROM / COPY . . / RUN make -j / CMD bash`. Built in 61s; `make test` passes
  **offline** in 75s (`All tests passed (10946 assertions in 19 test cases)`).
- Determinism 3x: no test flips; only the interleaved order of two stderr warnings in
  `parallel-test`. Do NOT run two containers of the same image at once — that is what makes the
  logs look nondeterministic.
- Requirement 6: `mapbox/tippecanoe`'s own README points at felt/ as the active fork; mapbox's
  12-month commits are a CODEOWNERS file and a doc patch.

**LANE TAKEN (2026-09-12):** `tile-join` size-limit recourses — the README's own
"it doesn't have any of tippecanoe's recourses if the new tiles are bigger than the 500K tile
limit" gap at `tile-join.cpp:884`. Gap reproduced on base in the platform image. Gate 8 positive
(`e-n-f` on #357: "Tile-join **unfortunately** quietly drops too-large tiles"). Exclusivity clear.

**LANES TO AVOID if picking again here:**
- anything in `tile.cpp`: variable-depth pyramids and `--drop-by-attribute-as-needed` are the
  maintainer's active programme (#384/#385/#397/#399/#407).
- the capabilities already sitting in `e-n-f`'s 8 open PRs: MLT input/output (#405), tile-join
  `--use-attribute-for-id` (#416), error/throw refactors (#413/#414), the float formatter (#418),
  H3 indexing (#320), `--drop-sparsest-as-needed` (#255), duplicate-location distinction (#333/#349),
  binning by ID (#321), prefilter worker processes (#389).
- **NOTE:** `youdie006` (recorded signature account, ~16 repos) holds a fork and filed one README
  link fix (#400). One doc-only visit, outside the lane — a note, not a reject.

### B3. LIVE-CORE (Gate 5 — the target subsystem is an active maintainer workstream)

Recorded at hunt 2026-08-04-B (`REPO-HUNT-2026-08-04-B.md`). All three pass license / stars /
activity / dedup and have genuinely good seams; they die on core velocity or on an open PR that
blankets the only interesting pick. Measure with `gh api repos/O/R/commits?path=DIR&since=...`,
never `git log --since` on a shallow clone.

| Repo | ★ | Evidence |
|---|---|---|
| [moonrepo/moon](https://github.com/moonrepo/moon) | 4029 | Trailing-12mo commits: `crates/config` 100+ (API page cap), `crates/action-graph` 51, `crates/project-graph` 37, `crates/task-graph` 11. MIT, Rust, own vocabulary (project/task/action graph) — the seam is real, the core is simply never cold. |
| [egraphs-good/egglog](https://github.com/egraphs-good/egglog) | 806 | `src/ast` 100+ commits/12mo, 27 open PRs vs 92 issues. Research repo under continuous refactor. Deep and NON-nameable (rulesets, subsume, containers, e-class analyses), so worth a revisit if the core ever cools. |
| [thought-machine/please](https://github.com/thought-machine/please) | 2604 | Core dirs read cold (`src/core` 10, `src/build` 5, `src/graph` 0 commits/12mo) but PR **#3565** rewrites `src/core/build_target.go` **+201/-270** plus `src/build/incrementality.go` — the dependency-resolution/incrementality heart, i.e. the only pick worth having. 28 open PRs. Also self-hosting (builds itself with `plz`) = real Docker + base-mode cost. |

| [openfga/openfga](https://github.com/openfga/openfga) | 5543 | Hunt 2026-08-04-C, killed at Gate A. The ARCHITECTURE is excellent and the open PR queue is genuinely peripheral (the only candidate that week to pass the queue gate) — S6 dual evaluator (`internal/graph` resolves Check top-down, `commands/reverseexpand` resolves ListObjects bottom-up over the same model), F-2 (tuple-to-userset makes a relation both grantor and grantee), clean F-10 axes. **Three independent kills:** (1) the parity thesis is a Stage-2b MAGNET — [#1567 "Check / ListObjects API inconsistency"](https://github.com/openfga/openfga/issues/1567) OPEN since 2024-04-23 with ZERO comments and no PR, the lol-html profile verbatim, and it is the most obvious pick in the repo; (2) **flaky baseline INSIDE the seam package, maintainer-filed** — [#3197](https://github.com/openfga/openfga/issues/3197) (`TestUnionCheckFuncReducer` in `internal/graph`, fails when CPU-starved >10ms) and [#3214](https://github.com/openfga/openfga/issues/3214) (context-cancellation race), so Gate 9 scoping would discard the exact regression coverage a parity pick needs; (3) the cold packages carry no substitute — `internal/planner` is Thompson sampling over a `sync.Map` (randomised + concurrent = worst f2p surface), `internal/condition` has 10 existing param types = pattern-followable RED and its one deep type (`ipaddress`) is the spec-knowable-predicate dead class, `pkg/typesystem` is a validation rule list (L2) carrying its own `// TODO: Deprecate once userset refactor is complete`. Also hot where it matters: `internal/graph` 37, `reverseexpand` 42 commits/12mo. |
| [mvdan/sh](https://github.com/mvdan/sh) | 8941 | From-scratch pick pass 2026-08-04. **Zero open PRs — and that is not coldness, it is a solo maintainer merging directly** (the rapier lesson, confirmed: **383 commits in 12 months** over a ~19k-LOC repo). Per-area velocity: `syntax/` **229**, `interp/` **108**, `expand/` 42, `syntax/printer.go` **32**, typedjson 18, pattern 15, walk 9, simplify 6. The only genuinely cold files are `fileutil` (84 LOC, 1 commit/yr) and `syntax/quote.go` (184 LOC, last touched 2025-12) — both far under the LOC floor. **The commit stream is literally the f2p-gap class being closed weekly**: "reject more unsupported zsh syntax rather than panicking", "reject a missing parameter name rather than panicking", "fix several wrong Node.End positions", "make SplitBraces reject malformed sequence expansions", each paired with its own test case. **Every available capability class is dead:** (a) **zsh** is an explicit live workstream — 78 zsh commits/12mo and the doc comment says "experimental and incomplete for now. See issue #120", i.e. a famous tracking issue = Stage-2b magnet; (b) **bash parity** (FUNCNAME/caller/traps/getopts/select) is the SPEC-KNOWABLE / saturated-reference-port class — bash is the memorised reference; (c) **shfmt formatter edge cases**, the one genuinely own-model surface, are being closed at 32 commits/yr on a single 1645-line file; (d) the small own-model packages (typedjson, pattern, quote) are both warm AND sub-floor. Note `problems/sh-callstack-introspection` (built, unbatched, ~211 human-eff) is class (b). |
| [uber-go/nilaway](https://github.com/uber-go/nilaway) | 3879 | Hunt 2026-08-04-C. **The best NEW seam found that week, and Gate-5 dead.** F-2 verbatim (286 `ProducingAnnotationTrigger`/`ConsumingAnnotationTrigger` refs — nilability producers and consumers), a real cross-package inference fixed point, `analysistest` golden testdata = ideal f2p surface, 16k LOC in `assertion/`. Killed by an in-flight maintainer rewrite: the trailing 6 months are one continuous **`struct-init-v2`** workstream (`structfieldeffects/effects.go` 20 touches, `assertiontree/structinitv2.go` 12, `structfieldeffects/analyzer.go` 10, plus `backprop.go` + `root_assertion_node.go`), 91 Go commits/12mo. Only `inference/` is cold (8 commits, 1.7k LOC) and it is coupled to what v2 changes. ⭐ **REVISIT when struct-init-v2 lands** — highest-quality shelved repo on this list. |

⭐ LESSON (third confirmation of the objdiff law): **cold directories do not clear Gate 5 on their
own.** please's core had 15 commits in a year and was still exclusivity-dead, because one open PR
carried the entire interesting surface. Enumerate open-PR file lists BEFORE scoring core velocity.

⭐⭐ COUNTER-LESSON, and the correction that rescued a repo (2026-08-04): **a busy PR queue is not
automatically exclusivity-death — classify the queue by KIND before rejecting.** The exclusivity
HARD RULE in `CLAUDE.md` is CONJUNCTIVE: a PR kills your pick when its diff touches your core files
**AND** implements the core machinery of your CENTRAL capability. Gate 5's own kill examples (jedi
~60% shipped, OPA in-flight, risor match-churn) are all FEATURE-shipping cases, not file-churn ones.
So the real question is whether the maintainers are **consuming the invent-able capability space** or
merely **maintaining** it:

| Heat kind | Tell | Verdict |
|---|---|---|
| **Capability-consuming** | Either stream adds named capabilities: egglog (packed join nodes, demand-driven scheduling, custom UF-backed tables), moon (VCS provider API, remote graph cache, Jujutsu), nilaway (function variables, type conversions, struct-init-v2), **rapier (direct-push `feat:` wave, invisible to the PR queue)** | DEAD — whatever you invent, they may already be building it, and the SIX-CHECK only sees it once public |
| **Maintenance** | BOTH streams are fixes, UB/soundness, perf, small getters and flags | Provisionally ALIVE for an INVENTED capability — file overlap without capability overlap |

⭐⭐⭐ **CHECK BOTH STREAMS — the open-PR queue reflects only OUTSIDE contributions.** A maintainer
with commit rights lands features as direct pushes that no `gh pr list` query will ever show. rapier
is the measured case and it fooled this exact gate within an hour of the gate being written: 31 open
PRs, all maintenance ("fix wheel impulse scaling", "fix aliasing UB", "add getter for `contact_id`")
= reads ALIVE; meanwhile `commits?since=` shows `v0.35.0-beta.0` shipping **intra-island parallelism,
box2d-style CCD, unified SIMD/non-SIMD paths, NaN-quarantine containment, non-Sync event handlers and
a broad-phase rework — 14 commits on 2026-08-02, ZERO carrying a `(#NNN)` PR suffix.** The tell for a
direct push is the missing PR number on the commit subject line.

```bash
gh api "repos/OWNER/REPO/commits?since=<90d>T00:00:00Z&per_page=100" \
  -q '.[]|"\(.commit.author.date[0:10])  \(.commit.message|split("\n")[0])"'   # feat: without (#N) = direct push
```

Residual risk even when both streams read clean: there is **no recorded case of a pure
file-overlap-without-capability-overlap reject**, so the conjunctive reading is reasoned from the rule
text, not measured. Prefer picks whose core-machinery files carry no open PR; accept overlap only in
plumbing; re-run the SIX-CHECK at SUBMIT time.


### B3-bis. 2026-09-01-C proven-pool triage — dead / contested entries (full dossiers: `repo-hunt-logs/REPO-HUNT-2026-09-01-C.md`)

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [mmcloughlin/avo](https://github.com/mmcloughlin/avo) | 2988 | **CORPSE (Requirement 6)** | 14 commits/12mo, ALL `cadobot` metadata bumps; last human commit 2024-12-23; 20 open PRs unreviewed since 2019. Our `avo-register-spilling` is approved but the repo cannot take a second pick. |
| [explodingcamera/tinywasm](https://github.com/explodingcamera/tinywasm) | 587 | LIVE-CORE (single-author rewrite) | 149 commits on unreleased `next` (0.11.0-pre), every crate hot, nightly-pinned toolchain, 2 open issues. Spec-proposal ladder (EH, typed refs, GC, SIMD, memory64) fully consumed. Re-check after a stable release. |
| [fatiando/verde](https://github.com/fatiando/verde) | 666 | **RED BASELINE** + competitor | CI red on `main` since 2026-08-04 (issue #558, sklearn>=1.9 breaks undamped `Spline`; fix #559 unmerged, filed by competitor-signature `youdie006`). Authorable only with sklearn pinned <1.9, away from spline/tiling. |
| [CamDavidsonPilon/lifelines](https://github.com/CamDavidsonPilon/lifelines) | 2607 | dormant + rival authors | No merge since 2026-03-07, 18 commits/yr all direct pushes, 21 open PRs incl. two whole fitters (#1689 Fine-Gray, #1690 Royston-Parmar). `hass-nation`/`Qayad-Ali` (2026-06) look like rival authors in fitters/statistics. |
| [Eyevinn/mp4ff](https://github.com/Eyevinn/mp4ff) | 653 | capability-consuming + competitor | ~11 feat/month (maintainer + nchitkara-xai); defrag PRs #557/#560/#561 + issue #548 make our own `mp4ff-progressive-writer` exclusivity-dead; `ChrisJr404` sweeping. Only vvc/bits/subtitle boxes/cmd tools cold. |
| [sharkdp/numbat](https://github.com/sharkdp/numbat) | 2675 | contested (3 subs + 3 competitors) | Maintainer + Ryan-D-Gast hold every language lane via open PRs (#836 complex, #802 modules, #800/#847 struct methods, #795 adaptive RK); `Jorge-Polanco-Roque`, `ChrisJr404`, `nagendramohan` filed Aug 2026. Cold residue: prefix_*.rs (#746), list.rs, cli output format (#842/#763). |
| [pyamg/pyamg](https://github.com/pyamg/pyamg) | 653 | stale-PR-blanketed | 9 capability PR diffs public for years on classical/air, relaxation (#455/#388), krylov (#393), amg_core (#465); idle since 2026-03-30. Only aggregation/, strength.py, graph.py, multilevel.py uncontested. |
| [moov-io/ach](https://github.com/moov-io/ach) | 560 | contested | #1724 (+2149 LOC v2 structured validation) public; `karpovantonme` + `SashaMIT` sweeping bug-fix lanes; adamdecaf ships weekly. Cold: segment-file config/dir.go, file_flattener, SEC batch rules. |
| scikit-rf / PlasmaPy / MetPy / mpmath / QuantEcon | - | competitor-visited | see the account table in the hunt log; PlasmaPy has MERGED competitor PRs (steps-re #3327, Mohit-Ak #3325/#3328). Avoid the lanes they touched. |

⭐ LESSON (2026-09-01-C): **a real name does not clear a PR author.** `binggao1230` was read as genuine the day before; the events feed shows ~30 surgical fixes in 12 days across unrelated niche libs incl. four of our corpus repos. Scatter is the discriminator, identity is not.

### B3-ter. 2026-09-04 proven-pool re-mine — dead / contested entries (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-04.md`)

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [jtablesaw/tablesaw](https://github.com/jtablesaw/tablesaw) | 3764 | **CORPSE (Requirement 6)** | Exactly ONE commit in 400 days and it is a dependabot jackson bump (2026-03-02). 16 open PRs unmerged. Our `tablesaw-arrow-stream-interoperability` is approved but the repo cannot take a second pick. |
| [wokwi/avr8js](https://github.com/wokwi/avr8js) | 840 | near-corpse | 12mo stream is ONE real feature commit (`feat(timer): ATtiny Timer/Counter1`, 2026-02-14), one typo fix and dependabot; 6 of 7 open PRs are dependabot. Upstream is the open core of a commercial simulator, so also carries dead-upstream risk. |
| [microsoft/maker.js](https://github.com/microsoft/maker.js) | 2023 | near-corpse | 12mo stream is dependabot/CI plus ~4 real code commits, all security or packaging (prototype-pollution fix, fontkit support, eval removal). Open PRs stale since 2020-2024. |
| [surrealdb/surrealkv](https://github.com/surrealdb/surrealkv) | 551 | **LANE-LEDGER — repo alive, retention lane ABSORBED** | Version retention is already implemented INCLUDING the snapshot-visibility-before-retention interaction that was the intended F-3 carve-out: `src/iter.rs:653-941` (`retention_period_ns`, discard rules, "Before applying retention rules, we check snapshot visibility"), `src/commit.rs` GC threshold + `kept_since` clamp, `src/snapshot.rs:101`. Repo is otherwise fine (Apache-2.0, 10 commits/180d, quota 1/6, 74k LOC with ~30k of tests) — pick a different lane, and note the maintainer's own fix stream sits in compaction/iterators/snapshots. |
| [mozman/ezdxf](https://github.com/mozman/ezdxf) | 1432 | competitor-visited | BOTH recorded competitor signatures have merged PRs here: `binggao1230` and `youdie006`. Repo otherwise excellent (MIT, 2 approved subs, 1 open PR, huge CAD surface) — treat invisible-derivative risk as elevated and stay far from the lanes they touched. |
| [kinnala/scikit-fem](https://github.com/kinnala/scikit-fem) | 655 | competitor-visited | `binggao1230` merged. Otherwise close to ideal: BSD-3, 12 commits/180d, 10 open issues, responsive solo maintainer, 4 open PRs. |
| [pyRiemann/pyRiemann](https://github.com/pyRiemann/pyRiemann) | 775 | competitor-visited + contested | `binggao1230` present; `adityasingh2400` filed three transfer-learning PRs on one day (#479/#481/#483); maintainer `qbarthelemy` consuming the HPD generalisation lane (#463). |
| [amaranth-lang/amaranth](https://github.com/amaranth-lang/amaranth) | 2078 | **RFC-GATED (Gate 8 hazard)** | The capability space is governed by the amaranth RFC process, not by the tracker — open PRs implement RFC 41 (`lib.fixed`) and RFC 74 (structured VCD). An INVENTED capability with no accepted RFC contradicts maintainer philosophy by construction. Core is otherwise cold (16 commits/180d). |
| [pysmt/pysmt](https://github.com/pysmt/pysmt) | 638 | theory lanes exclusivity-dead | Public open-PR diffs blanket every theory extension: Strings/regex (#260, #568, #781, #831), Floating-Point (#632), Nonlinear (#533, #844), Modulo (#814), floordiv/mod (#476). Some have been open since 2016 — stale, but the DIFF is published, which is what the scope gate reads. |
| [obi1kenobi/trustfall](https://github.com/obi1kenobi/trustfall) | 2883 | maintainer holds the lanes | `obi1kenobi`'s own open PRs cover the interesting surface: #617 `@transform` on properties, #605 custom scalars/filters/transforms, #83 unlimited-depth directly-optimal recursion. Our `rejected/trustfall-prefix-candidates` already burned the optimisation/candidate lane. |
| [softdevteam/grmtools](https://github.com/softdevteam/grmtools) | 575 | sibling-tool dead on the obvious pick | Clean maintainers (`ratmice`/`ltratt`, 2 open PRs, dual MIT/Apache — gh reports NOASSERTION, read the files). But the natural S-F pick, LR conflict counterexamples, is publicly solved: bison ships `-Wcounterexamples`, and `lark-counterexamples` is already cited as canonical prior art in our own `KNOWLEDGE.md`. |
| mdeloof/statig · boombuler/barcode · orbitinghail/sqlsync | 797 / 1561 / 2912 | unverified dormancy | 0 commits in trailing 180 days. Run the real last-COMMIT check before considering any of them. |

⭐ LESSON (calyx, 2026-09-04): **a MOVED crate path reads as a corpse.** `gh api repos/O/R/commits?path=X`
returns an empty array for a path that no longer exists, with no error. calyx scored 0 commits across
its ENTIRE compiler (`calyx-ir`, `calyx-opt`, `calyx-frontend`, `calyx-backend`) until the tree was
re-listed and the crates turned out to have moved to `calyx/ir`, `calyx/opt`, ... Re-resolve the tree
before believing any per-path heat number, the same way you re-resolve the canonical org before
believing a PR search.

⭐ LESSON (acoular, 2026-09-04): **`# pragma: no cover` plus a `DeprecationWarning` is a lane-death
signal as strong as an open PR, and it is free to check.** acoular's whole rotating-machinery
subsystem (`Trigger`, `SpatialInterpolator`, `SpatialInterpolatorRotation`,
`SpatialInterpolatorConstantRotation`, `AngleTracker` — announced for removal in 27.01) reads like a
rich untouched physical lane and is scheduled for deletion. Grep the target subsystem for both markers
before the seam audit.

### B3-quater. 2026-09-06 proven-pool re-mine — dead / contested entries (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-06.md`)

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [python-control/python-control](https://github.com/python-control/python-control) | 2077 | **COMPETITOR-SWARMED** | `marko1olo` filed 12+ surgical one-bug `fix:` PRs Jun-Aug 2026 across xferfcn / timeresp / mateqn / LQE / root-locus / Nyquist; `binggao1230` merged; `kwlee2025cpp` + `maxtaran2010` alongside. The maintainers merged "DOC: follow NumPy policy for contributions that use AI" — they have noticed. We hold 2 approved subs; treat the remaining gap surface as mined. |
| [wireservice/agate](https://github.com/wireservice/agate) | 1198 | **COMPETITOR-SWARMED** | `ChrisJr404` AND `binggao1230` (x2), plus `heejaechang`, `santhreal` (3 PRs one day), `uttam12331`, `chuenchen309`, `Sanjays2402` — all on aggregations / null handling / ordering. |
| [pydata/sparse](https://github.com/pydata/sparse) | 667 | **COMPETITOR-SWARMED** | `binggao1230` merged; `patnr` x2, `rautaditya2606`, `Abineshabee`, `thodson-usgs`. The entire 2026 non-dependabot commit stream is one-bug `fix:` PRs — the f2p gap class being closed monthly by rivals. |
| [tdewolff/canvas](https://github.com/tdewolff/canvas) | 1837 | **RED BASELINE (Requirement 7)** | `Go` workflow FAILS on master (2026-08-29, 2026-09-01) — job `build`, step "Tests with coverage". Also needs `Install OpenGL` (system deps). Otherwise attractive: 4 open PRs, 43 commits/180d, MIT, large real pipeline. PR authors are GENUINE (`anaelorlinski` = Clipper2 / clipper2-go / go-text.typesetting, owns the Bentley-Ottmann lane; `aldernero`, `j-modernc-org`, `Mitsutan`). REVISIT if master goes green. |
| [jblindsay/whitebox-tools](https://github.com/jblindsay/whitebox-tools) | 1199 | Requirement 7 | No CI runs at all. |
| [pySTEPS/pysteps](https://github.com/pySTEPS/pysteps) | 583 | Requirement 7 | `Test pysteps` failure 2026-08-17. |
| [reinterpretcat/vrp](https://github.com/reinterpretcat/vrp) | 504 | Requirement 7 | Every workflow run is `action_required` and there are zero successful runs across all branches — the suite has never been observed passing. ⚠️ `action_required` is "no evidence", not neutral. |
| [sdcoffey/techan](https://github.com/sdcoffey/techan) | 909 | **gap-consuming branch family** | The whole 12mo stream is `codex/*` branches: the maintainer is AI-sweeping the exact bug class an f2p targets (trendline slope on sparse windows, short stop-loss basis, warm-up before cache expansion, indicator cache invalidation). |
| [rust-minidump/rust-minidump](https://github.com/rust-minidump/rust-minidump) | 510 | self-collision + live core | PR queue is benign (11/20 dependabot), but the commit stream is a live bitflip-heuristics + CFI/ARM64-unwind workstream and PR #1162 adds a configurable `UnwindStrategy` — the same unwinder our approved `rust-minidump-stack-containment` consumed. Both major lanes (unwinder, Breakpad CFI) taken. |
| [haraldk/TwelveMonkeys](https://github.com/haraldk/TwelveMonkeys) | 2144 | **derivative CLASS dead** | `rejected/twelvemonkeys-sgi-writer` was rejected by the external plagiarism/similarity gate on 2026-08-01. "Add the missing ImageIO reader/writer for format X" IS the repo's value proposition, so it is the author-obvious shape. Its own closure record demands "a materially different subsystem and behavior" plus a fresh similarity audit. |
| [abema/go-mp4](https://github.com/abema/go-mp4) | 546 | **cross-repo overlap** | `rejected/go-mp4-sample-locations` rejected 2026-07-23 for cross-repository task overlap against our own mp4ff picks. Mechanically ideal otherwise (0 open PRs, green `Test` on master, 14 commits/180d) — the blocker is our own corpus. |
| [kaleidawave/ezno](https://github.com/kaleidawave/ezno) · [google/mtail](https://github.com/google/mtail) | 2734 / 4027 | **near-corpse** | 0 commits in trailing 180 days each (mtail pushed 2026-03-19 with 17 open PRs). We hold 2 approved mtail subs; the repo cannot take a third. |
| [naver/kapture](https://github.com/naver/kapture) | 542 | dormant + no tracker | Last push 2026-04-17; 0 open issues AND 0 open PRs, so Gate 8 and Stage 2d are structurally unverifiable. |
| [laspy/laspy](https://github.com/laspy/laspy) | 505 | dormant | 4 commits/180d, pushed 2026-05-30, NOASSERTION licence. |
| [servo/rust-url](https://github.com/servo/rust-url) · [tamasfe/taplo](https://github.com/tamasfe/taplo) | 1572 / 2384 | PR-blanketed | 59 and 41 open PRs respectively. |
| [PMEAL/OpenPNM](https://github.com/PMEAL/OpenPNM) | 537 | **LANE LEDGER — repo ALIVE** | `rejected/openpnm-robin-boundary-conditions` closed because version 2 **failed the local calibration pre-filter (too easy)** — a dead PICK, not a dead repo. MIT, 33 commits/180d, 4 open PRs, `Nightly` green on `dev`. Fresh obscure domain (percolation / multiphase transport). ⚠️ `binggao1230` has a merged PR; avoid the numpy-compat and plotting lanes. Not seam-audited yet. |
| [asticode/go-astits](https://github.com/asticode/go-astits) | 617 | **LANE LEDGER — repo ALIVE, analyzer lane consumed** | Coldest survivor in the pool (4 commits/180d, 3 open PRs, `Test` green, clean DVB-specialist contributors). But our approved `astits-stream-analyzer` consumed the analyzer / PCR-timing / statistics lane across demuxer + muxer + packet; it is a FLAT SINGLE PACKAGE (no stage boundary, so F-9 is unavailable); `descriptor.go` is 78KB of descriptor table (pattern-followable RED); and `roundtrip_test.go` already asserts a corpus round-trip invariant. LOC floor is the live risk. |

⭐ LESSON (2026-09-06): **the competitor swarm has scaled from a signature to a wave.** Three pool
repos in one session are saturated with one-bug `fix:` PRs from mutually unrelated fresh accounts,
with `binggao1230` merged in ALL THREE. Stop looking for a single scatter account: count the
fraction of the 12-month PR stream that is surgical one-bug fixes from accounts with no domain
footprint, and above roughly a third treat the repo's whole gap surface as mined.

⭐ LESSON (2026-09-06): **a prior rejection's REASON decides whether the repo survives it.** OpenPNM
died on local calibration (too easy) so the repo lives; TwelveMonkeys died on the plagiarism gate and
go-mp4 on cross-repo overlap, so those repos' natural pick SHAPES are dead. Read the closure record
before re-mining anything in `rejected/`.

⭐ LESSON (2026-09-06): **cold GitHub keyword sweeps are now near-worthless.** Every domain keyword
(`mesh`, `compression`, `cryptography`, `kinematics`, `codec`, `routing`, `scheduling`) returns an
LLM/AI-infrastructure result set — `Mesh-LLM`, `llm-compressor`, `KVCache-Factory`,
`solace-agent-mesh`. The star-ranked head of GitHub has been colonised and the obscure scientific
repos this hunt wants no longer surface in a star-sorted keyword search. Spend the budget on
Requirement 7 + PR-author profiling over the proven pool instead.

### B3-quinquies. 2026-09-09 proven-pool re-mine + first VFX/media + structural sweep (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-09.md`)

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [AcademySoftwareFoundation/OpenTimelineIO](https://github.com/AcademySoftwareFoundation/OpenTimelineIO) | 1976 | **SHELVED — repo ALIVE, every lane occupied/blocked/absorbed** (audited in full 2026-09-09) | Apache-2.0 (⚠️ `CMakeLists.txt:22` says "Modified Apache 2.0 License" — STALE metadata, `LICENSE.txt` is stock Apache-2.0, licence PASSES), 27 commits/180d, quota 0/6, **Stage 2b-bis totally CLEAN** (all PR authors are named VFX-industry people). Core C++ is 13,519 LOC and cold (per-file 12mo 1-5, lifetime 7-26) — the FINISHED-subsystem signal. **Docker VERIFIED**: builds green in `olympus-base-cpp` (194s, 3.5GB) with 4 submodules + a nested one pre-vendored at pinned SHAs (drjit pattern); recipe at `repo-hunt-logs/artifacts/otio-cpp-build-VERIFIED.Dockerfile`. Baseline deterministic 3/3 (10/10 ctest) BUT `test_bundle` alone is **761s** and suite wall-clock swings 363/464/635s. ⛔ Lanes: flatten/trim/timewarp occupied by #1466 + #842 + #1818; edit algorithms carry a **631-line published design doc** (#719) incl. a transactional `EditEvent` sketch; instancing (#1997) is **absorbed to a compile flag** — `OTIO_INSTANCING_SUPPORT` is never defined while the READ path ships unconditionally; linked clips (#343) is an 8-year welcomed queue named by vendor vocabulary (Resolve `Link Group ID`, Premiere `LinkID`); C++ version families (#1636) is philosophy-blocked (`ssteinbach`: "reluctant to add this to the C++ core"); media refs/transitions/subtitles/bindings/typing/diff all carry published diffs. **Re-check after the six open PRs land or close — merging them RELEASES the timewarp kernel.** Clone kept at `worktrees/OpenTimelineIO`. |
| [nevalang/neva](https://github.com/nevalang/neva) | 1079 | **LANE LEDGER — repo ALIVE, whole compiler HOT** | MIT, quota 1/6, `test`+`lint`+`fuzz` green, solo maintainer `emil14`, **zero competitor signature**. ⛔ 12mo heat: `parser` 89, `analyzer` 100, `desugarer` 50, `irgen` 41, `backend` 73, `runtime` 100, `std` 100. Our approved `neva-array-bypass-generalization` consumed analyzer+desugarer+irgen; typesystem is the maintainer's CURRENT workstream (subtype diagnostics, type-recursion termination, portable resolved type descriptor, open PR #1182 bind-type compiler bridge) and he runs a documented AI-assisted "papercut" sweep. ⚠️ The `olympus-hunt` Stage 0-bis table's "desugarer 0, irgen 0, typesystem 0, interp 0" for neva is STALE and partly a moved-path artefact — `internal/interpreter` and `internal/compiler/sourcecode` do not exist. |
| [PMEAL/OpenPNM](https://github.com/PMEAL/OpenPNM) | 537 | **LANE LEDGER — repo ALIVE, two best lanes prior-art-dead** | MIT, 4 open PRs, `Nightly` green, 12mo stream is version bumps + numpy-2 compat + plots (zero capability commits = ideal cold profile). ⛔ Imbibition / cooperative pore filling / snap-off is dead: **`openpnm/algorithms/MixedInvasionPercolation.py` exists at tag `v2.8.2` at 36,540 bytes** (+ `Porosimetry.py` 8,324), and sibling `PMEAL/porespy` has 22 `imbibition` code hits. ⛔ Residual-NWP is dead: `_invasion_percolation.py:83` raises `NotImplementedError` under `# pragma: no cover` with the **implementation sitting commented out** at lines 80-106 / 221-235 / 340-342. Remaining: transport/conductance (4 open PRs #2740/#2849/#2880/#2254) and `models/` (9,920 LOC formula registry, pattern-followable RED). Clone kept at `worktrees/OpenPNM`. |
| [onflow/cadence](https://github.com/onflow/cadence) | 548 | **capability-consuming, BOTH streams** | ~20 `[Compiler] ...` maintainer commits building a new compiler/VM; 18 open PRs blanket the language surface (#4483 exhaustive switch, #3059 type bounds, #2463 generic functions, #3055 `Sqrt`, #2626 `reverseInPlace`, #2760 WebAssembly API, #3509 AST comment retention, #3618 language spec). |
| [apache/datasketches-java](https://github.com/apache/datasketches-java) | 958 | **COMPETITOR-SWARMED** | `jaideeppyne` mines the whole datasketches family (`-cpp`/`-go`/`-java`/`-rust`) plus arrow-rs, datafusion, opendal, trivy, `hyperium/h2`, expr-lang, typeguard, anyio, bigcache. `MaxFreedomPollard` (created 2026-03-31, 181 fork repos, bio "Into evolving agentic AI") filed here AND on ytt. Plus `PerumalsamyR`, `Fengzdadi`, `freakyzoidberg`; maintainer `leerho` ships capabilities weekly. |
| [tafia/calamine](https://github.com/tafia/calamine) | 2416 | **COMPETITOR-SWARMED (worst recorded)** | `sjvrensburg` filed SIX surgical PRs in three days in our exact house style; plus `ChrisJr404`, `binggao1230`, `youdie006`, `krickert` (5 in one week), `Butch78`, `Svector-anu`, `TaoGuerreiro`, `Nitjsefnie`, `momomuchu`, `dayongxie`. |
| [jhillyerd/enmime](https://github.com/jhillyerd/enmime) | 517 | **COMPETITOR-SWARMED + maintainer capabilities** | `ChrisJr404` x2 filing CAPABILITY PRs (MarshalJSON, `Part.DeleteChild`) and `binggao1230` (mediatype dedup). Maintainer shipping `MaxMIMEParts`, `ContentTransferEncoding`, `EnvelopeFromPart` refactor. |
| [JWock82/Pynite](https://github.com/JWock82/Pynite) | 738 | **COMPETITOR + maintainer AI-sweep** | `binggao1230` x3 (instability via solution residual, inactive-member deflection, quad/plate reports); `app/copilot-swe-agent` commits sweep the same class; maintainer mid-build on pushover + nonlinear end forces. First structural-engineering entry in the corpus, and it is already mined. |
| [cschleiden/go-workflows](https://github.com/cschleiden/go-workflows) | 524 | **maintainer AI-sweep + published capability diffs** | `app/copilot-swe-agent` is a first-class contributor closing the exact f2p class (signal payload precision, `waitGroup.Wait()` hang, tester pending futures, `workflow.Cause`). Published diffs: versioning #424, valkey #460, LISTEN/NOTIFY #458/#488, adaptive polling #491, tester perf #492. We hold 1 approved sub; the remaining surface is thin. |
| [Phylliade/ikpy](https://github.com/Phylliade/ikpy) | 1033 | **absorption + maintainer capability stream** | Recorded as "unprobed" in B2-FRESH-2026-09-05; now probed. Mechanically ideal (0 open PRs, CI green) but IK is a `scipy.optimize` wrapper, and the 12mo stream is the maintainer adding a JAX backend, an MJCF parser and optimizer knobs, with `Checkpoint before follow-up message` AI-agent commits. |
| [bjodah/chempy](https://github.com/bjodah/chempy) | 658 | near-dormant + absorbed | ~4 non-symmetry commits in 2026; sole live lane is `weisscharlesj`'s group-theory/SALC subsystem; the numeric machinery lives in sibling packages (`pyodesys`, `pyneqsys`, `sym`). |
| [robbievanleeuwen/section-properties](https://github.com/robbievanleeuwen/section-properties) | 553 | near-corpse + C dep | 3 commits/180d, trailing 180d is docs/deps only; `cytriangle`/`triangle` C meshing dependency. |
| PyBaMM · openmc · simpeg · gonum | 1655 / 1095 / 673 / 8426 | PR-blanketed / Requirement 7 | 86 / 132 / 36 / 31 open PRs; openmc + gonum also NOASSERTION or `action_required` CI. |
| OpenColorIO · OpenSubdiv · gtsam · timefold-solver · jenetics | 2105 / 3071 / 3674 / 1779 / 908 | Requirement 7 / licence / live core | OpenColorIO `Wheel` failing + 30 PRs; **OpenSubdiv has zero CI runs** and a Pixar rider on Apache; gtsam NOASSERTION + Boost/Eigen; timefold and jenetics both 100 commits/180d. |
| [PistonDevelopers/dyon](https://github.com/PistonDevelopers/dyon) · [erikgrinaker/toydb](https://github.com/erikgrinaker/toydb) | 1916 / 7279 | **Requirement 7 / teaching repo** | dyon has **zero CI runs** despite 0 open PRs and 22 commits/180d. toydb is an explicit learning project with 6 commits/180d, 0 issues, 0 PRs. |
| [iwe-org/iwe](https://github.com/iwe-org/iwe) | 1631 | Gate 8 unverifiable | 100 commits/180d with 0 open issues AND 0 open PRs — maintainer philosophy and Stage 2d are structurally unprobeable (the kapture class). |

| [robertmuth/Cwerg](https://github.com/robertmuth/Cwerg) | 704 | **★ AUTHORABLE — RANK 1 of 2026-09-09, scope-locked to `bcopy`/`bzero` backend lowering (issue #45/#29)** | Apache-2.0 (file read), Python reference + C++ port with a suite-enforced identical-output rule (`codegen_parity`). 0 open PRs, 9 PRs ever (typos/CI), zero swarm, zero AI-sweep marks, tracker = maintainer's own roadmap. IR accepts `bcopy`/`bzero`; every backend's isel maps them to the no-pattern sentinel; nothing else in the tree or history touches them. Base failure reproduced through the real CLI on all three targets. Docker VERIFIED (`repo-hunt-logs/artifacts/cwerg-build-VERIFIED.Dockerfile`); py suites 3/3 identical, C++ BE chain passes through Elf 3/3 (ApiDemo needs an ARM cross-compiler; C++ FE needs GCC 13 -> scope both out with reasons). Clone at `worktrees/Cwerg`. Derivative risk MEDIUM (outsider-nameable capability, obscure repo). Quota 0/6. |
| [alembic/alembic](https://github.com/alembic/alembic) (ASWF, VFX — NOT sqlalchemy's alembic) | 1173 | **FINISHED LIBRARY (Stage 3b class)** | BSD-3, competitor-clean, Imath-only deps, CI green — and dead: every layer 0-5 commits/12mo because development ended ~2018; all 35 open issues are build/Maya/Arnold noise (zero core requests); the layering lane's inversions ship as `bin/AbcDiff` / `AbcStitcher` / `AbcConvert`. Clone at `worktrees/alembic-vfx`. |
| Alloy · stateright · dragonboat · rez · HiGHS · ojAlgo · OpenMDAO · NuRaft · Clipper2 · geogram · spoon · pyomo · verible · javaparser · trimesh · SALib | - | pass-2 sweep 2026-09-09 | recency-dead (stateright, dragonboat), PR-blanketed (rez 97, pyomo 40, verible 41, spoon 21), red CI (OpenMDAO, javaparser, trimesh, Clipper2), Gate-8-unverifiable firehose (ojAlgo 0/0), named-algorithm (NuRaft, Clipper2, SALib), solo firehose (geogram, HiGHS). Details: `repo-hunt-logs/REPO-HUNT-2026-09-09.md § PASS 2`. |

⭐ LESSON (OpenPNM, 2026-09-09): **a repo's OWN earlier major version is prior art.** The
"ports inherit the parent's feature list" law (pandapower/MATPOWER) has a same-repo form: a v2 -> v3
REWRITE inherits its own v2 feature list. OpenPNM v3 greps clean for imbibition / snap-off /
cooperative filling, and `MixedInvasionPercolation.py` has been sitting at tag `v2.8.2` at 36 KB the
whole time, with the sibling tool `porespy` carrying imbibition too. **List the tags and check the
previous major for your capability before sketching LOC.** One `gh api contents?ref=<tag>` call.

⭐ LESSON (2026-09-09): **maintainers now AI-sweep their own gap surface, and it has a fingerprint.**
techan's `codex/*` branch family was recorded as a one-off; this session found the same behaviour
under four marks — `app/copilot-swe-agent` as commit author (go-workflows, Pynite),
`Checkpoint before follow-up message` commits (ikpy), and a documented AI-assisted "papercut" sweep
programme (neva). A maintainer running an agent over their own tracker continuously closes the
surgical-correctness gap class, which IS the f2p surface. Grep the commit stream for
`copilot|codex|Checkpoint before|papercut|AI-assisted` at Stage 2c and treat a hit like a
`fix/<topic>-*` branch family.

⭐ LESSON (2026-09-09): **the competitor swarm has reached the FRESH domains.** 2026-09-06 found
three swarmed Python scientific repos; this session found `binggao1230` on structural engineering
(Pynite) and a six-PR-in-three-days account on a Rust spreadsheet parser (calamine), with
`MaxFreedomPollard` linking ytt to Apache datasketches. Picking an untouched DOMAIN no longer buys
distance from the swarm — only an untouched CAPABILITY does.

⭐ NEW COMPETITOR SIGNATURES (2026-09-09): `sjvrensburg` (calamine, 6 PRs/3 days, our house style),
`MaxFreedomPollard` (ytt + datasketches-java; 181 fork repos, bio "Into evolving agentic AI",
created 2026-03-31), `jaideeppyne` (whole apache/datasketches family + arrow-rs, datafusion, opendal,
trivy, hyperium/h2, expr-lang, typeguard, anyio, bigcache), `denisaditya0` (go-workflows, 2 PRs one day).

⭐ LESSON (2026-09-09, OTIO + OpenPNM in one session): **a never-defined `#ifdef` is the C/C++ form of
commented-out code — an absorption kill AND a solver scaffold.** OpenPNM's residual lane died on a
commented-out `_set_residual` implementation; OTIO's instancing lane died on `OTIO_INSTANCING_SUPPORT`,
a macro defined nowhere in the tree while the matching READ path (`deserialization.cpp:360,617,637`)
ships unconditionally. Both read as a clean f2p gap from outside and are a flag flip from inside. Add
to Stage 3b: grep the candidate lane for `#ifdef`/`#if 0` guards whose macro is never defined, and for
large commented-out blocks, BEFORE sketching LOC.

⭐ LESSON (alembic, 2026-09-09): **a tracker with zero CORE requests is the cheapest finished-subsystem tell** — one `gh issue list` before any clone; if every open issue is build/plugin noise, the cold layers are cold because they are done.

⭐ LESSON (2026-09-09): **the Stage 2d welcomed-lane regex produces verdict-inverting false positives.**
`We should probably discuss` matched OTIO #1636 as maintainer-welcomed; the body says the opposite
(`ssteinbach`: "I'd be reluctant to add this to the C++ core"). The magnet test already requires reading
issue BODIES rather than titles — the WELCOME test needs the same discipline, and skipping it means
authoring straight into a declared philosophy objection.

### B3-sexies. 2026-09-09-B three topic-search sweeps, ~190 topics, 35 screened (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-09-B.md`)

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [pmp-library/pmp-library](https://github.com/pmp-library/pmp-library) | 1505 | **⛔ LICENCE-DEAD (vendored)** | Own licence plain MIT, CI green daily, competitor-CLEAN, cold algorithm lanes (remeshing/subdivision/hole_filling/smoothing/geodesics 0 commits/12mo) and a maintainer-reproduced unfixed remeshing fold-over (#158) — but `external/eigen-5.0.1` is MPL-2.0 (+ LGPL files) and `external/glfw-3.5.1` is zlib; RULES.md: one non-allowed vendored licence = whole-repo reject. Kernel-hook lanes also maintainer-declined (#141/#159), UV lane on a public fork branch, size-field remeshing PR #232 open. |
| [koto-lang/koto](https://github.com/koto-lang/koto) | 882 | **⛔ DO-NOT-PICK as of 2026-09-10 (was RANK 2 AUTHORABLE): the nested/rest binding lane was authored and killed by the platform overlap check - `Blocker`, 258/489 lines = 52.8% against an ACCEPTED foreign task. See § B2-KOTO and `TOO-EASY.md § koto-nested-bindings`** | Repo gates all pass and still pass (MIT, solo `irh`, CI green, 3x deterministic over 69 suites, competitor-clean upstream) - which is exactly the point: the prior art lives in the submission pipeline, not on GitHub. Generic type hints declined (#298), bitwise ops (#37) and tuple `+=` (#394) declined, async "planned" (a subsystem). |
| alecthomas/participle · CloudyKit/jet · LCAV/pyroomacoustics · twpayne/go-geom | 3882 / 1403 / 1936 / 973 | **COMPETITOR-VISITED** | **NEW signature `SAY-5`** (panic-to-error one-liners: participle #458, jet #232), **NEW `Pastalikek65`** (14 PRs on participle), `MaxFreedomPollard` (participle), `ChrisJr404` + `youdie006` (jet), `binggao1230` (pyroomacoustics x2, go-geom x1). participle also at quota. |
| tlaplus/tlaplus · potassco/clingo · pubkey/event-reduce · maroba/findiff · fjall-rs/fjall | 3040 / 830 / 755 / 509 / 2313 | **maintainer AI-sweep** | `app/copilot-swe-agent` PRs (tlaplus, clingo); `Copilot` 16 commits + CI failing (event-reduce); `claude` commit author (findiff); "with Claude" subjects (fjall). |
| mattwparas/steel · uiua-lang/uiua · cycfi/q · hcoles/pitest · Jon-Becker/heimdall-rs · sqlancer/sqlancer | 2572 / 2162 / 1424 / 1863 / 1608 / 1753 | **capability-consuming firehose** (steel RE-AUDITED lane-by-lane 2026-09-10 under the softened gate: numeric tower and dynamic-wind FINISHED, contracts/match are Racket-spec magnets, the reader/port state-isolation lane is real but is contributor-OWNED (`m4rch3n1ng`, nine port PRs 2025-08..2026-03) on top of the maintainer's own TODO and open bug #693 — DEAD; see hunt log § PASS 4) | steel: JIT + cross-module inlining + serialization + reader macros in 6 months, 18 open PRs over `compiler/` and `steel_vm/`; uiua 100/180d; q 99/100 owner commits with 0 issues + 0 PRs; pitest 81/90; heimdall 30/30; sqlancer 100/180d + `ci` failing. |
| atopile · Algebrite · lotusdb · adsb_deku · VROOM · argmin · laika · particles · BoomFilters · Orca · lexy · biwascheme | — | **Requirement 6/7 (corpse or failing CI)** | 0 commits/180d on the default branch and/or failing test workflow for each; biwascheme dependabot-only and already derivative-dead. |
| mlivesu/cinolib · dyn4j/dyn4j · cpmech/gosl · jhasse/poly2tri · AngusJohnson/Clipper2 · vtil-project/VTIL-Core | 1110 / 538 / 1877 / 518 / 2474 / 1585 | **no test suite / finished / C deps** | cinolib has NO `tests/` (CI compiles examples only); dyn4j and gosl 0 open issues; poly2tri 2 commits; Clipper2 4 trivial commits + failing C++ CI; VTIL needs capstone/keystone. |

⭐ LESSON (pmp-library, 2026-09-09-B): **run `ls external/*/ third_party/*/ | grep -iE 'licen|copying'` at Stage 1 for every C++ repo.** Eigen (MPL-2.0 + LGPL files) and GLFW (zlib) are vendored by most geometry / robotics / FEM C++ repos, neither is on the allowlist, and RULES.md counts vendored subdirs. The seam audit and a container build were spent before the licence was read.

### B3-septies. 2026-09-10 proven-pool re-mine + 3 topic sweeps (~130 fresh topics) (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-10.md`)

**Session outcome: RANK 1 = `Mojang/DataFixerUpper`, the `datafixers` type-rewrite engine (NOT the
serialization codec DSL). Gap reproduced on base twice; see the hunt log.** Everything below is dead
or downgraded.

| Repo | ★ | Class | Evidence |
|---|---|---|---|
| [cantools/cantools](https://github.com/cantools/cantools) | 2283 | **COMPETITOR-SWARMED + capability-consuming** | `ChrisJr404` + `binggao1230` (recorded signatures) plus `Poseidonas`, `NotAFlightRisk`, `friessssss`, `nishantshah0`, `klow68` filing one-bug fixes over ~1/3 of the stream; `andlaus` is 12 parts into a whole-DBC-core cleanup series (#808-#833). |
| [Fields2Cover/Fields2Cover](https://github.com/Fields2Cover/Fields2Cover) | 887 | **COMPETITOR (near-certain rival author)** | **NEW signature `u33549`** — 9 PRs Aug-Sep 2026 on one niche coverage-path engine, titles in our own house style ("Order swaths per cell, and let the orderers produce a connected route", "Report which cell gives each corridor, and let callers ask for a fair split", "Carve a corridor between decomposed cells, and fix three silent failures"). |
| [petl-developers/petl](https://github.com/petl-developers/petl) | 1317 | **COMPETITOR-SWARMED** | `binggao1230` x4 + `ChrisJr404` x1, plus `be-student`, `dylanpulver`, `santhreal`, `sarathfrancis90`, `akashmalbari`, `UdayPate`, `CharveeSaraiya`, `jayhemnani9910`, `muhammadbadar1998`. We already hold 1 sub. |
| [scikit-hep/awkward](https://github.com/scikit-hep/awkward) | 976 | **Requirement 7 + swarm** | `CI` and `Build wheels` FAILING on `main` (2026-09-10); `TaiSakuma` x7 plus `aashirvad08`, `SidheshwarSarangal`, `Soumoditya`, `kmohrman` in the out-of-bounds / spec-drift genre. |
| [colour-science/colour](https://github.com/colour-science/colour) | 2648 | **capability-consuming + spec-named by construction** | `thomasmansencal` continuously implements published models (Wilkie et al. 2021 sky model, CIE Standard General Sky, Munsell Renotation, TLCI-2012). The repo's feature list IS a list of named standards. |
| [pydoit/doit](https://github.com/pydoit/doit) | 2083 | dormant queue + L2 shape | open PRs mostly 2021-2022 unmerged; 2 `app/copilot-swe-agent` docs PRs (a NOTE, not a kill); task-runner features are independent rules. |
| [deadpool-rs/deadpool](https://github.com/deadpool-rs/deadpool) | 1332 | thin domain | connection pooling, absorption/LOC risk; `ChrisJr404` present x1. |
| CoolProp · SPlisHSPlasH · PositionBasedDynamics · stan-dev/math · pinocchio · libpointmatcher · point-cloud-utils | 1069-3725 | **C++ vendored-Eigen licence risk / reference-tool prior art** | all vendor or require Eigen (pmp-library lesson); CoolProp is also thermo-adjacent with REFPROP as the reference toolchain. |
| Qiskit/rustworkx · apache/commons-math · Axect/Peroxide · PyKrige · java-diff-utils · mp-units | 509-1753 | textbook / spec-named capability class | the pick would be named by the algorithm or the standard. |
| cocotb · glasgow · gdsfactory · siliconcompiler · OpenLane · librelane · edalize · hls4ml · openFPGALoader | 538-2497 | tool-harness | tests need a simulator, EDA binaries, klayout or hardware. |
| ariel-os · probe-rs · GP2040-CE · lucidgloves · trice · adsb_deku · rustsbi · octox | 727-3422 | needs hardware, or corpse | |
| [simpeg/simpeg](https://github.com/simpeg/simpeg) | 674 | **NOT dead — RANK 2, lane audit owed** | MIT, CI green on default, 70 commits/12mo, no signature account. Caveats: mid-deprecation-wave for v0.26.0 (moving baseline) and `jcapriot` active in the natural-source EM lane. |
| [pantor/ruckig](https://github.com/pantor/ruckig) | 1366 | **NOT dead — RANK 3, one structural blocker** | MIT, 38 commits/12mo, 5 open PRs, CI green, competitor-clean. Ships a closed-source **Pro** edition, so the biggest missing capabilities are the paid ones: unseeable prior art AND a Gate-8 philosophy problem. Authorable only provably outside the Pro feature list; `3rdparty/` licence check still owed. |

⭐ LESSON A (DataFixerUpper, 2026-09-10): **a repo with no `.github/workflows` is not automatically a
Requirement-7 reject — look for another CI system in the tree.** DFU removed its GitHub PR check in
Oct 2025; `.ado/build.yml` runs `gradle build test publish` on every branch and PR under JDK 17, and
`gh run list` cannot see it. Confirm by building and running the suite yourself (owed at Stage 3
anyway): 52/52, 3x identical, in under a minute with plain `javac` and 8 Maven-Central jars.

⭐ LESSON B (2026-09-10): **diff the proven pool against the ledger MECHANICALLY before every sweep.**
Sessions since 09-01 have triaged the pool repo-by-repo and marked each done once one lane died, so a
pool repo that was never triaged at all becomes invisible. DataFixerUpper — the session's RANK 1 —
was the only Java repo in the pool and had never been screened. One loop finds them:
`for f in approved-problems/*/meta.md problems/*/meta.md; do grep -m1 -i '^Repository:' "$f"; done | sed 's|.*github.com/||; s|/*$||' | sort -u | while read r; do grep -qi "$r" Instructions/SATURATED-REPOS.md || echo "UN-MINED: $r"; done`

⭐ LESSON C (2026-09-10): **Stage 2b-bis competitor profiling is now the top killer, ahead of
absorption** — five of seven mechanically-clean sweep survivors died to it, and two recorded accounts
(`ChrisJr404`, `binggao1230`) turned up on three unrelated repos each. Run the profiler BEFORE the
seam audit. The tell is the PR TITLES read as a set, not the account age: a stranger filing nine
capability-shaped PRs in five weeks on one niche engine is mining it (`u33549`).

⭐ LESSON D (2026-09-10): **`eda` is a poisoned search topic** — it returns exploratory-data-analysis
repos, not electronic design automation. Use `verilog` / `fpga` / `netlist` / `hdl`.

### B3-octies. 2026-09-10-B second pass: pool re-mine + 44-topic sweep on uncovered axes (full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-10-B.md`)

Ran after the same day's RANK 1 (DataFixerUpper) was authored. RANK 1 out of this pass is
**casid/jte** (Java, Apache-2.0, 1136 stars, quota 0/6, never previously triaged) — see the dossier.

| Repo | Verdict | Why |
|---|---|---|
| **pybamm-team/PyBaMM** | ⭐ **RE-OPENED 2026-09-10-E under the softened gates — MECHANICALLY THE BEST UNUSED REPO WE HAVE; no capability found yet** | Supersedes the 09-10-C competitor-swarm kill, which was a repo verdict where the rule says LANE verdict. Verified: BSD-3, ★1657, **quota 0/6**, CI GREEN on `main`, zero AI-sweep marks in 300 commits, **Docker CONFIRMED WORKING** (`pip install pybamm` in `olympus-base-python` solves an SPM in-container). Core lanes are COLD: discretisations 4 commits/12mo, spatial_methods 3, meshes 5, geometry 2, submodels 2 each. **Computed free-lane map: 229 of 343 source files are touched by an open PR, leaving 114 FREE** — including the whole `spatial_methods/` package except `finite_volume.py` (`spatial_method.py` 513, `spectral_volume.py` 678, `scikit_finite_element.py` 552, `scikit_finite_element_3d.py` 686), plus `parameters/bpx.py` 588, `parameters/parameter_store.py` 547, `simulation/base_simulation.py` 821, `solvers/processed_variable_computed.py` 741. **Swarm footprint to stay away from:** expression_tree (13 PR-files), solvers (10), lithium_ion models (11), experiment/step (7), plotting (7) — `binggao1230` x9 (recorded signature), `medha-14` x8, `Rishab87` x4. **Capabilities checked and REJECTED so far:** flux boundary conditions (#5523) is exclusivity-dead via **open PR #5524** touching `base_model.py`+`finite_volume.py`; FEM `evaluate_at`/`delta_function` are absorbed (thin wrappers over `skfem` `probes`/`asm`); spectral-volume boundary reconstruction is absorbed (`cv_boundary_reconstruction_matrix` already exists and is used by `gradient`) and its inheritance is a DOCUMENTED design decision. **LANE AUDIT NOW COMPLETE (2026-09-10-E) — every free lane examined, all dead:** `spatial_methods` free but absorbed (FEM `evaluate_at`/`delta_function` are thin `skfem` `probes`/`asm` wrappers; SV boundary reconstruction already exists as `cv_boundary_reconstruction_matrix` and its inheritance is a documented design decision); `processed_variable_computed.py` free but its sibling `processed_variable.py` carries a +368 open PR and a one-file pick cannot clear >=2 files; `base_processed_variable.py` is a 28-line ABC; `parameter_store.py` is a store/diff/search class = the bookkeeping death class; `base_simulation.py` is orchestration whose live parts (ESOH fingerprints, experiment stepping) sit in the swarm lane; **`meshes/` and `geometry/` are 100% PR-covered (every file)**. ⚠️ **The 09-09 "PR-blanketed" verdict was RIGHT and this re-opening over-corrected:** 86 open PRs cover **229 of 343 source files (67%)**, and the 114 free files are periphery (parameter data, orchestration, single methods), not load-bearing lanes. **Verdict: mechanically excellent, no authorable capability. Re-check only if the PR queue drains.** |
| **xoolive/traffic** | ⛔ Requirement 7 (2026-09-10-D) | ★512 MIT, best domain-engine shape found in JOSS, but the `tests` workflow FAILS on master (scheduled, 2026-09-06) and deps (`onnxruntime`, `rs1090`, `pyopensky`, `py7zr`) make Docker infeasible |
| **i-net-software/JWebAssembly** | ⛔ capability-consuming core (2026-09-10-D) | ★1052 Apache-2.0, 0 open PRs — but 53 commits/12mo ALL by the solo maintainer in the core type manager (WASM-GC: struct/block/recursive types, exception tags), and "Build with Java 11" failing on master. Empty queue because he does everything himself (the cpp-peglib pattern) |
| **bytedance/appshark** · **yinwang0/pysonar2** | ⛔ winding down / recency-dead (2026-09-10-D) | appshark: 7 commits/12mo, all REMOVALS. pysonar2: **0 code commits in 12 months**, last real code 2022-05 |
| **JOSS corpus (~3,200 papers, 53 survivors)** | ⛔ published-method class (2026-09-10-D) | Research software is published methods BY DEFINITION — emcee, PyWavelets, kepler-mapper, NARMAX, Mapper, manif (Lie theory), ginkgo (numerical LA), plus ML packages and wrappers (geemap/pyvista/pyvisa). The axis is worth one pass and is now spent |
| **obi1kenobi/trustfall** | ⛔ **EXCLUSIVITY-DEAD at the repo level (re-confirmed 2026-09-10-C)** | Passes every other gate and looks superb: Apache-2.0 ★2882, CI green on `main`, competitor-clean, maintainer in MAINTENANCE mode (153 commits/12mo of cargo-update/clippy/security), core COLD (`interpreter` 3, `frontend` 1, `ir` 2, `graphql_query` 1, `schema.rs` untouched since 2022) yet BIG (`execution.rs` 61KB, `frontend/mod.rs` 50KB), Gate 8 POSITIVE (*"It's a feature I'd love to add in the future though!"*), derivative LOW (capabilities are its own `@fold`/`@recurse`/`@tag`/`@optional` directives). **Killed by draft PR #617** "Allow `@transform` directive to be applied to properties" — OPEN since 2024-06-11, **+19053/-2812 across 602 files**, rewriting `frontend/mod.rs` +895, `interpreter/execution.rs` +471, `ir/mod.rs` +236, `graphql_query/directives.rs` +245, new `interpreter/transformation.rs` +297 and `hints/*`. Every directive-semantics lane with LOC mass overlays those files. Prior verdict already on disk: `rejected/trustfall-prefix-candidates/feedback.md` ("Net: trustfall has no clean Olympus for us"; the other lane, prefix-narrowing, is 64 eff LOC = sub-floor) |
| **asticode/go-astits** | ⛔ **DEAD (2026-09-10-C)** — reference-toolchain prior art | ★617 MIT Go, Requirement 7 clears, **competitor-CLEAN** (all real video-domain devs: `tmm1` 3104 followers, `eric` Eric Lindvall, `thiagopnts`). The five open issues form one coherent lane — demuxer RECOVERY policy (mid-stream join #71, corrupt PES length #35, multi-table PMT #25, 192-byte Bluray #67) — which MPEG-TS does not specify. Killed by the repo's own commit `fix(packet_pool): align discontinuity detection with FFmpeg behavior`: FFmpeg's `libavformat/mpegts.c` is the reference for all of it and matching FFmpeg is the repo's stated convention. Also LOC-risky — 78KB of 212KB non-test Go is a flat `descriptor.go` DVB table |
| **COMPETITOR ACCOUNT `youdie006`** (contests every repo listed) | ⛔ **CONTESTED — treat all as competitor-visited** | Created 2024-05-09, **422 public repos**, 32 followers, name "KBS", no bio. One-bug capability-shaped PRs across mutually unrelated niche permissive parsing/format libraries: `CloudyKit/jet`, `CrowCpp/Crow`, **`Eyevinn/mp4ff`** (our corpus), `NikolaLohinski/gonja`, `andybalholm/brotli`, `console-rs/console`, `dolthub/go-mysql-server`, `getkin/kin-openapi`, `hjson/hjson-go`, `jsonata-js/jsonata`, `kaptinlin/jsonschema`, `mattn/go-runewidth`, `mity/md4c`, `nyaruka/phonenumbers`, `opensheetmusicdisplay`, `mozman/ezdxf`. Third recorded signature after `binggao1230` and `ChrisJr404`; second to overlap our corpus. Full dossier: `repo-hunt-logs/REPO-HUNT-2026-09-10-C.md` |
| **beartype/beartype** | ⛔ **AVOID (2026-09-10-C)** — solo-maintainer roadmap + PEP-named capability space | ★3493 MIT Python, CI green on `main`, competitor-clean. Dead anyway: all 104 open issues are `[Feature Request]`/`[Docos]` written in `leycec`'s own voice and commented by him — the tracker IS the maintainer's public roadmap and already enumerates every extension point (#53 deep type-checking, #391 dataclass fields, #589 generators, #644 class-var defaults, #626 forward refs). Capability space is PEPs, externally named by construction. Codebase is famously comment-dense and idiosyncratic (style tax) |
| **mozman/ezdxf** | ⛔ **CONTESTED (2026-09-10-C)** | `youdie006` (above) plus `origami7`, `eXponenta`, `haluk-pointr`, `eeshsaxena` — several thin accounts at 2-3 PRs each on a 21-issue/2-PR tracker |
| **pybamm-team/PyBaMM** | ⛔ **DEAD as of 2026-09-10-C — COMPETITOR SWARM (third kill; supersedes the 08-07-D "revisit if the wave lands" note)** | The 08-07-D note said the shape was excellent (symbolic model -> discretisation -> solver is a real compiler pipeline) and to revisit if the unstructured-mesh wave landed. It landed (#5687/#5688 MERGED) and the repo is mechanically BETTER than before: BSD-3, ★1657, **CI green on `main`** (the 09-09 Requirement-7 doubt was wrong — the failing runs are `event=pull_request` on PR branches), zero AI-sweep marks in 300 commits, and a tracker full of open uncommented CORE bugs in the expression-tree/discretisation lane. **Killed on Stage 2b-bis instead.** `binggao1230` — a RECORDED signature account (also on cantools and petl) — holds **NINE open PRs**, and they are capability-shaped f2p work, one of them squarely in the target lane: *"Fix #4930: discretise `Variable.reference` / `scale` so r/x in initial concentration don't leak"*, *"Fix #5018: exclude internal 'start time' InputParameter from termination check"*, *"Fix #2484: include unsaved cycles in solve_time / integration_time"*, *"Let CRate accept callables for its default duration"*. Alongside: `medha-14` 8, `Rishab87` 4, `mleot` 3, `martin1cifuentes` 3, `AIMindCrafter` 2, `vidipsingh` 2, `swastim01` 2, plus `repowazdogz-droid` (new account, 1 follower, footprint spans cedar-spec / cvc5 / **pandapower** / common_cells / PyBaMM — AI-evals researcher, forks-then-fixes pattern, recorded below). All three softened reject thresholds are met at once: a recorded signature account, a burst, and a signature PR inside the intended lane |
| **bufbuild/protobuf-es** | ⛔ **NOT AUTHORABLE as of 2026-09-10-B (re-screened at author Phase 2)** — was MEDIUM, now parked | Four lanes, all closed. (1) **Codec/serialization**: `ajeetdsouza` 10-PR perf campaign + the maintainer's own correctness sweep + the conformance corpus + it is our approved pick's subsystem. (2) **Naming/imports in protoplugin**: ABSORBED — `names.ts` already escalates `idealDescName(desc, i)` over `allNames(file)`, and `processImports` in `generated-file.ts` already does collision detection with `$N` aliasing, type-only-vs-value grouping and path rewriting. (3) **New codegen options**: maintainer philosophy — `timostamm` on #1319, *"we're very conservative adding new options to the plugin because supporting them isn't free"*, which covers most of the tracker. (4) **The two substantial capabilities are pre-designed or ported**: #1031 ES-Maps-for-map-fields has a published implementation plan from `sbarfurth` (*"a new kind of option that propagates from `protoplugin` to `protobuf`... `create` will need to know what kind of code was generated... `createZeroField`"*), and #1153 custom field mapping is answered by `timostamm` pointing at gogo/protobuf, which ships it — external reference implementation, and it is the umbrella for 6 other issues (the maintainer's roadmap). Repo remains clean and quota is 1/6 if a genuinely invented lane ever appears |
| **casid/jte** | ⛔ **AVOID as of 2026-09-10-B — RANK 1 REVERSED at author Phase 2** | Mechanically excellent (Apache-2.0, 1136 stars, quota 0/6, competitor-clean, CI green, cold compiler core, gap reproduced on base, harness built and Docker-validated at 1207 tests). Killed on Gate 8: the HTML-output escaping/policy lane is DECLINED THREE TIMES -- #387 `kelunik` "we don't really plan to support context dependent escaping for JS" and owner `casid` "the `OwaspHtmlTemplateOutput` is just one implementation... it would be possible to create an `HtmlTemplateOutput` that is aware of Alpine or HTMX" (i.e. user's job, not core's); #437 template calls in `<script>` declined; #252 JS inlining closed. That machinery is the ONLY deep coupled surface in the repo -- what remains (`BinaryContent` 52 LOC, `Utf8ByteOutput` 94, trimControlStructures, hot-reload plumbing) cannot carry 200 eff LOC against a 3789-LOC core module |
| **onekey-sec/unblob** | **SHELVED — lead lane EXCLUSIVITY-DEAD** | Cleared everything else: MIT, 2552 stars, CI green, competitor-clean, core cold (`processing.py` 9 commits/24mo), and a real behavioural gap (partially overlapping chunks survive `remove_inner_chunks`, which handles only full containment, and then `calculate_unknown_chunks` builds an inverted `UnknownChunk`). Killed by closed issue #232, whose BODY carries two complete code solutions, and **closed PR #234 "Fix overlapping valid chunks." (+17/-0 in `processing.py`, `fix_chunk_overlaps`)**. Closed and unmerged is still a hard scope-gate reject. Other lanes thin: handlers are absorbed missing-arms, reporting shipped 2026-09-08, extraction-path safety is the maintainer's live lane, whole package is 4973 LOC |
| **opensheetmusicdisplay** | **DEAD — competitor swarm** | `isc` x5, `gifflet` x2, `ymxlx`, `dotkebi` x2, `youdie006`, `ishinomaru` x3, `recrack` filing house-style capability-shaped one-bug fixes ("Carry the hidden unison exception to the notehead and the tuplet", "re-link lyric word chains split across voices", "match tied notes by sounding pitch instead of letter name") |
| **dimforge/parry** | **DEAD — capability-consuming, every lane** | `sebcrozet` shipping SubShapeId-returning queries, parallel incremental BVH, cuboid-cuboid SAT fixes; outsiders adding voxel query traits, compound pseudo normals, analytic ray-capsule. Same org and same pattern as rapier (§ B3) |
| **Vineflower/vineflower** | **AVOID — poor lane availability** | Not a competitor problem (6 Minecraft-ecosystem regulars: `Kroppeb` 13, `coehlrich` 13, `sschr15` 9, `aoqia194` 6) but they sweep the decompiler correctness-gap class continuously across structuring, variables, switches, finally, generics and Kotlin. Capabilities are JLS-named -> derivative risk |
| **simpeg/simpeg** | **DOWNGRADED from 09-10 RANK 2** | Audit closed: the 12mo stream is the f2p class swept across every lane ("Fix bug in VRM effects on EM1D", "Fix bug in IP effects on EM1D", "Fix bug in apparent conductivity"), plus a v0.26 deprecation wave (moving baseline) and a mature directives/regularization framework (absorption). Published-method capability class |
| **ostafen/digler** | **LOW** | File carving; PhotoRec/TestDisk is the reference toolchain and ships every recovery capability. Solo maintainer, 2 outside PRs ever, 2 code PRs in 2026, small repo -> LOC risk |
| **bufbuild/protobuf-es** | **MEDIUM — lane-limited, NOT dead** | Proven repo, quota 1/6, competitor-clean, CI green. Codec lane DEAD (`ajeetdsouza` 10-PR perf campaign + maintainer correctness sweep + the conformance corpus + it is our approved pick's subsystem). protoplugin codegen is cold (2-7 commits/24mo per file) but `names.ts` already carries collision avoidance (absorbed) and `import-path.ts`/`map-imports.ts` is the live lane. `generated-file.ts` (19.8KB import-tracking emitter) is the one unread piece |
| gimli-rs/gimli, fxamacker/cbor, harfbuzz/ttf-parser, ical4j, libriscv, libjxl, aeron-io/simple-binary-encoding, wasmi-labs/wasmi | spec-named class | DWARF / CBOR RFC 8949 / TrueType / RFC 5545 / RISC-V / JPEG XL / SBE / Wasm — the capability IS the standard and each has a reference toolchain |
| dlclark/regexp2 | port law | a port of the .NET regex engine; inherits its whole feature list as prior art |
| dartsim/dart, simbody/simbody | vendored-licence risk / AI-sweep | Eigen (MPL/LGPL) under vendored dirs; simbody also shows "Running Copilot Code Review" on `master` |
| lifting-bits/rellic, binsync, CreuSAT | harness-infeasible | need LLVM, IDA/Ghidra, or a proof toolchain inside the image |

## C. RECENCY-DEAD (no commits in trailing 12 months — fails the activity gate)

Repo compliance can PASS on stars + license + "active maintenance" wording yet still FAIL the hard
recency gate (>=1 SOURCE commit in the last 12 months). GitHub "pushed" timestamps count tags / CI /
metadata pushes and lie about source activity. Verify at pick time with the ACTUAL commit date, not
the pushed date: `git log -1 --format=%ci origin/HEAD`.

| Repo | Latest commit | Stars | Note |
|---|---|---|---|
| [mun-lang/mun](https://github.com/mun-lang/mun) | 2025-05-06 (`91ad6da`) | 2.1k | SHELVED 2026-07-16. 0 commits in trailing 12mo (verified `git log --since`). Compliance line said "active maintenance" + "pushed 2026-06" but the pushed date was a non-source push; last real commit is 14 months stale. Killed a fully-authored + locally-validated Olympus (`rejected/mun-literal-bounds`, 272eff / 28 tests, all green) at the recency gate. Do NOT author mun. |
| [bebop/poly](https://github.com/bebop/poly) | 2024-10-21 | 732 | REJECTED at hunt 2026-08-02 (`REPO-HUNT-2026-08-02-SCIENTIFIC.md`). **0 `.go` commits in the trailing 12mo.** GitHub shows activity on 2026-07-31 (a README edit) and 2026-06-09 (a CI linter bump); the last SOURCE commit is 2024-10-21. Third instance of the mun / ichiban-prolog lie. Highly attractive otherwise — MIT, Go, synthetic-biology toolkit with Zuker RNA folding, codon optimisation, primer thermodynamics and assembly simulation, i.e. exactly the obscure-deep-science domain the hunt doctrine asks for — so it WILL resurface in scientific sweeps. Do NOT author. |
| [jblindsay/whitebox-tools](https://github.com/jblindsay/whitebox-tools) | 2025-02-07 | 1183 | REJECTED at hunt 2026-08-02. 0 `.rs` commits in the trailing 12mo; latest repo activity is a 2026-05-26 merge of a docs patch. MIT geospatial-analysis platform. Do NOT author. |
| [ichiban/prolog](https://github.com/ichiban/prolog) | 2024-10-15 | 725 | REJECTED at hunt 2026-07-31 (`REPO-HUNT-2026-07-31.md`). GitHub `pushed_at` reads 2026-07-29 but `repos/.../commits` shows the last real commit is 2024-10-15 = 0 commits in the trailing 12mo. Same lie as mun. Otherwise attractive (MIT, Go, ISO Prolog unification = a genuine bidirectional seam), so it will keep resurfacing in sweeps. Do NOT author. |

| [ikawaha/kagome](https://github.com/ikawaha/kagome) | no analyzer commit in 12mo | 976 | REJECTED at hunt 2026-08-07-B. `pushed:2026-07-30` and **63 commits in the trailing 12mo**, so it clears every count-based check — but only **3 are non-chore**, and those are a demo-UI redesign (#387), an FFI usage example (#381) and a README fix. Every other commit is dependabot/CI. Zero commits touch the analyzer. The bunster profile: read commit SUBJECTS, never the count. Otherwise very attractive (MIT, pure Go, self-contained Viterbi lattice + user dictionary + tokenize modes, obscure domain, 0 open issues), so it WILL resurface in Go sweeps. Do NOT author. |
| [sminez/penrose](https://github.com/sminez/penrose) | 2026-01-15 | 1349 | REJECTED at hunt 2026-08-07-B on **Docker feasibility first, activity second**. The linux `[dev-dependencies]` entry `penrose_ui` pulls `yeslogic-fontconfig-sys` (libfontconfig1-dev) and `x11` (xft/xlib), and cargo builds the whole dev-dep graph for ANY test target — so no test target is offline-buildable. Same failure mode as fundsp. Also 1 commit in all of 2026. Recorded because the SEAMS are genuinely good and will tempt a future sweep: `src/pure/` is a 4.5k-LOC pure data model (StackSet/Workspace/Screen/diff) with a mock X connection and quickcheck tests, and the LayoutTransformer message-routing chain is a textbook F-5 pass-through. Dead on mechanics, not design. Do NOT author unless the dev-dep graph changes. |

⭐ LESSON: run the recency check with the real last-COMMIT date BEFORE authoring, not the pushed date. A dormant repo can carry a recent "pushed" badge (dependabot, tag, CI) while its source has been frozen for over a year. `mun-literal-bounds` was authored end-to-end before the gate caught it.

⭐ LESSON (kagome, 2026-08-07-B): the corpse test is not "are there commits in 12mo", it is "are there commits IN THE CODE". A repo with dependabot enabled generates 50-60 commits a year on its own and passes every count-based gate. Filter the subjects (`grep -viE 'chore|ci|docs|bump|deps'`) before believing a velocity number.

---

| [nadavrot/layout](https://github.com/nadavrot/layout) | 2025-05-22 | 740 | REJECTED at hunt 2026-08-02B. Sugiyama layered graph layout (rank -> order -> coordinate -> spline) is genuinely coupled and MIT/pure-Rust, so it looks like a top pick every sweep. Last commit is >12mo. Do NOT author unless it revives. |
| [jf-tech/omniparser](https://github.com/jf-tech/omniparser) | 2025-02-21 | 1084 | REJECTED at hunt 2026-08-02B. Also 0 open issues. |
| [chaosprint/glicol](https://github.com/chaosprint/glicol) | 2025-01-23 | 2992 | REJECTED at hunt 2026-08-02B. Graph-oriented audio DSP language, attractive shape, dormant. |
| [michaelmacinnis/oh](https://github.com/michaelmacinnis/oh) | 2023-09-14 | 1383 | REJECTED at hunt 2026-08-02B. |
| [CSML-by-Clevy/csml-engine](https://github.com/CSML-by-Clevy/csml-engine) | 2023-06-28 | 720 | REJECTED at hunt 2026-08-02B. |

## D. MIRROR-DEV (SIX-CHECK-BLIND — development happens off GitHub)

Same disqualifier as the Gerrit-dev case recorded against `cue` in Section A: if the GitHub repo is
a MIRROR, then `gh pr list` / `gh issue list` return an empty or partial history and the mandatory
maintainer-philosophy + exclusivity SIX-CHECK cannot run at all. Check `gh api repos/O/R -q
'.description, .homepage'` for "mirror" wording or a non-GitHub homepage before investing.

| Repo | Real home | Note |
|---|---|---|
| [ricosjp/truck](https://github.com/ricosjp/truck) | GitLab (ricos internal / gitlab.io) | REJECTED at hunt 2026-08-02 — and it had been **RANK 3 in `REPO-HUNT-2026-08-01.md`**, i.e. one step from being authored. GitHub carries no "mirror" wording, so the Section-D description check does NOT catch it. What catches it: `.gitlab-ci.yml` in the tree, 11 of the last 30 commits are GitLab-style `Merge branch 'X' into 'master'`, and active branches cite issue numbers the GitHub tracker does not have (`221-least-square-bspline` vs GitHub issues topping out at #128). The real issue tracker + MR queue are on GitLab, so the mandatory SIX-CHECK and the exclusivity PR-diff check cannot run. Everything else was excellent (Apache-2.0, 1524 stars, pure-Rust 15-crate CAD kernel, 71k LOC, geotrait -> geometry -> topology -> modeling -> shapeops -> stepio pipeline, committed 2026-07-31). Do NOT author. ⭐ Add the **branch-name-vs-issue-number check** to the mirror probe: if a branch references an issue number higher than the repo's max GitHub issue, development lives elsewhere. |
| [NLnetLabs/roto](https://github.com/NLnetLabs/roto) | codeberg.org/NLnetLabs/roto | REJECTED at hunt 2026-07-31. Description literally starts "(Codeberg mirror)". Passed every other gate well (BSD-3-Clause, 551 stars, 53 commits/90d, statically-typed compiled embedded routing DSL with a real parser -> typecheck -> lower -> IR pipeline), which is exactly why it needs recording — it looks like a top pick until you check where development lives. Do NOT author. |

⭐ LESSON: run the mirror check in the same breath as the canonical-org resolution. A mirror is not
a moved repo — resolving the redirect will NOT save you, because the history is not on GitHub at all.

## E. DEAD-UPSTREAM / LIVE-FORK (the starred repo is a corpse; the real work is in a low-star fork)

Distinct from Section D. In a MIRROR-DEV case the history is not on GitHub at all. Here it IS on
GitHub — just under a different owner — so the trap is subtler: the starred repo reads
`archived:false`, carries a `pushed_at` recent enough to clear the 12-month gate, and its core
directories look **beautifully cold**. That coldness is a corpse, not a seam. Meanwhile the fork is
doing feature work in exactly those files, and it fails the 500-star floor so the pick cannot be
re-homed.

| Repo | Real home | Note |
|---|---|---|
| [google/mtail](https://github.com/google/mtail) ★4024 | [jaqx0r/mtail](https://github.com/jaqx0r/mtail) ★29 | REJECTED at hunt 2026-08-02B after a full seam audit. Issue [#929](https://github.com/google/mtail/issues/929): "No `mtail` maintainers have write access to this repository anymore." google/mtail shows **0 commits in 12mo across the ENTIRE compiler** (checker/codegen/types/parser/ast/opt/vm/code) while the tailer stayed busy — the exact "cold target inside a live repo" profile. The live fork has **504 commits/12mo, 34 in `internal/runtime/compiler`, 16 in `internal/runtime/vm`**, including checker feature work (`defined()` builtin, chained match expressions with numbered caprefs, time-native runtime types). The compiler is the HOTTEST area upstream. Fork is 29 stars = under the hard floor, so it cannot be re-homed. Everything else was excellent (real HM unification type system with regex capture-group type inference, textbook F-9 in codegen, behavioural table-driven tests, 3/3 deterministic, Apache-2.0, no cgo) — which is why it is recorded. Do NOT author mtail. |

⭐ LESSON: **frozen core + live periphery is AMBIGUOUS.** It means either a genuine cold seam (neva,
rust-minidump) or a dead upstream. Disambiguate BEFORE the seam audit, not after:

```bash
# 1. Scan open issue TITLES for the tell (costs one call)
gh issue list -R OWNER/REPO --state all --limit 60 --json number,title \
  -q '.[] | select(.title | test("obsolete|moved|no longer maintained|fork|abandoned|deprecat"; "i")) | "#\(.number) \(.title)"'
# 2. If the core dirs look suspiciously frozen, look for a livelier fork
gh api "repos/OWNER/REPO/forks?sort=newest&per_page=10" -q '.[] | "\(.full_name) ★\(.stargazers_count) pushed:\(.pushed_at[0:10])"'
```

## How to use

1. At pick time, if the candidate repo appears in Section A, C, D or E → DEAD, pick another repo.
2. If it appears in Section B proper (or a fresh recount puts it at ≥6) → DEAD for new subs.
2b. **If it appears ONLY in B1/B2/B3 → NOT dead.** Those are lane ledgers. Read which subsystem or
   capability lane died and whether a REVISIT condition has fired, then pick a DIFFERENT lane in the
   same repo. A repo with a dead lane and good seams is a cheaper target than a fresh one, because
   its licence / determinism / dev-dep / Docker measurements are already paid for.
3. Stars is NOT the gate (risor 902★ = 78 subs). Bias hunts toward OBSCURE-to-problem-authors repos = deep engines in UNUSUAL domains, NOT the famous clean VM / SQL tool / config-lang everyone picks (those saturate regardless of stars). Verify the platform sub-count on the "Learn more" page BEFORE investing authoring effort — it is the only oracle. Check both famous AND niche-star candidates.
4. Whenever you SEE a platform over-use warning, record the repo in Section A (with sub-count + stars) so it is never re-authored.

| [yeslogic/allsorts](https://github.com/yeslogic/allsorts) | 2026-08-04: NOT saturated, NOT blocked, repo gates ALL PASS - recorded so the next Rust sweep does not re-derive it. Apache-2.0, ★801, 1 open PR, 29 issues, pure Rust once built `--no-default-features --features flate2_rust` (the DEFAULT feature `flate2_zlib` pulls C zlib), 776 tests green in 84s, deterministic. **Killed on Gate A / Gate 1: the apparent gap is fool's gold.** `tests/aots/testcases.rs` carries ~35 `#[ignore]`d OpenType conformance cases whose reasons read "cursive anchor positioning is not yet implemented", "mark positioning is not yet implemented", "vertical advance is not yet implemented", and all 35 DO fail today (`cargo test --test aots -- --ignored` = 0 passed / 35 failed). Both claims are false. `src/gpos.rs` implements every lookup type (PairPos, CursivePos, MarkBasePos, MarkLigPos, MarkMarkPos) and **`src/glyph_position.rs` (619 lines) is a complete multi-pass resolver** - cursive-chain pass, then mark pass, direction-aware, vertical-aware. The AOTS harness (`tests/aots.rs:255`) hand-rolls its own position loop that only understands `Placement::Distance` and never constructs `GlyphLayout`, so the symbolic `Placement::{MarkAnchor, MarkOverprint, CursiveAnchor}` variants resolve to nothing. The tests fail for HARNESS reasons; the library is correct through its public API, so there is no behavioural f2p gap. | ⭐ Third instance of the STALE-MARKER law (taffy's stale grid-baseline TODO, calyx's defensive `unreachable!`, now allsorts' stale `#[ignore]` reasons): **an in-repo marker claiming a feature is missing is a candidate GENERATOR, never a validator.** Run the feature through the public API before believing it. ⭐ Also a font-domain law: allsorts defers positioning to a SYMBOLIC placement model that the consumer resolves, so the naive pick ("implement mark/cursive attachment") is already done, while the pick that is genuinely large (subsetting GSUB/GPOS with glyph-id remapping - `subset_ttf` writes no layout table at all) is exactly the Stage-2b MAGNET: nameable by anyone, and what hb-subset/fontTools already do. Remaining open issues are all spec-named magnets (#95 Universal Shaping Engine, #116 COLR paint variations, #96 cmap 14). **Genuine assets if someone returns:** `src/scripts/indic.rs:1585-1610` documents, with worked examples, that allsorts deliberately mimics **Uniscribe rather than HarfBuzz** for base-consonant fallback - a native F-8 that is FAIR because the repo states it. |

---

## Merged dead-pick ledger (from a sibling workspace's TOO-EASY.md, consolidated 2026-08-20)

Despite living in a file named `TOO-EASY.md` in the sibling workspace, that file was NOT a
death-class taxonomy like this file — it was a chronological ledger of individual rejected/shelved
PICKS (specific repo+feature attempts), each with a one-line-able reason. Compacted here as a flat
list, one line per pick: `repo/feature — reason (date)`. Full case-study prose (root cause, reusable
law, artifact paths) is NOT reproduced; treat each line as a dedup/pattern-recognition lead, not a
complete writeup. This ledger is a separate, additive list — it does not replace or renumber
anything in Sections A-E above.

- pyparsing-incremental-streaming — derivative 90%, same-repo prior art (feed/status/finish session already shipped) (2026-07-30)
- cadence-mapped-accessor-functions — publicly-solved / maintainer-removed capability (`auth(mapping ...)` was deleted upstream) (2026-07-29)
- trustfall-folded-tags — old/already-done problem, user flagged (2026-07-29)
- fonttools-math-variations — old/already-done problem, user flagged (2026-07-29)
- mvdan-sh-file-descriptors — repo over-used at submit (2026-07-29)
- zoekt-window-scoped-queries — duplicate, user flagged (2026-07-29)
- prompt-toolkit-multiple-cursors — repo blocked at submit (2026-07-28)
- fjall-durable-checkpoints — derivative 78%, same-repo prior art (2026-07-28)
- redb-retained-tables — publicly-solved, omnibus-PR title hid the collision (2026-07-27)
- ytt-schema-open-maps — derivative 90% (2026-07-27)
- redb-merge-operator — too-easy, pointwise-decoupled bolt-on dead class (2026-07-26)
- turf-antimeridian-split — publicly-solved / exclusivity, external-oracle red flag (2026-07-25)
- scriggo-range-iterators — too-easy, documented-spec transcription dead class (2026-07-25)
- comfy-table cell spanning — killed at pick time, maintainer wontfix + public PR (2026-07-29)
- hecs change tracking / entity relationships — killed at pick time, existing capability + userspace philosophy (2026-07-29)
- numbat-dimensional-ranges — too-easy, pointwise-decoupled dead class (2026-07-22)
- gluon-string-interpolation — publicly-solved / exclusivity (2026-07-20)
- etree-xml-canonicalization — derivative (2026-07-21)
- noodles-md-nm-tags — derivative (2026-07-21)
- taplo-reorder-comment-preservation — publicly-solved / maintainer-rejected (2026-07-21)
- hayagriva-csl-flipflop — LOC-short / fresh-LOC wall (2026-07-21)
- quickxml-dtd-entity-expansion — too-easy (2026-07-21)
- bento-bloblang-recurrence — derivative, Scope Gate (2026-07-22)
- differential-dataflow-topk-total — too-easy, delegatable-oracle (2026-07-22)
- trimesh-manifold-editing — derivative (2026-07-22)
- sling-uritemplate — derivative, Scope Gate (2026-07-23)
- gomoney-reconciliation — activity-gate, GitHub compliance failure (2026-07-23)
- nickel-comprehensions — too-easy + too-small (2026-07-24)
- let-go-reactive-cells — derivative, Scope Gate (2026-07-24)
- pmcal-trading-time-engine — derivative, Scope Gate (2026-07-25)
- msgp-canonical-encoding — LOC-wall, Go delegates to primitives (2026-07-25)
- libpnet-sctp-chunk-layer — too-easy, documented-spec transcription ceiling (2026-07-25)
- proj4js-interrupted-homolosine — documented-spec port, short edge tail (2026-07-25)
- goyaml-flow-collections — LOC-wall, localized parser bug (2026-07-25)
- lopdf-function-eval — duplicate (2026-07-25)
- rust-bio-genetic-code-translation — too-easy, KNOWING wall (Nova solved 3/3) (2026-07-25)
- risinglight-zonemap-statistics — Env Quality unbuildable / platform-infra issue, NOT too-easy (2026-07-25)
- gix-note-lookup — too-easy (2026-07-26)
- gix-interpret-trailers — publicly-solved (2026-07-26)
- tstl-async-generators — shelved pre-implementation, dedup adjacency (2026-07-26)
- prolog-coroutining — stale default branch, new pick-gate trigger (2026-07-26)
- rbpf-isa-v4 — too-easy, documented-spec implementation class (Nova 4/6 = 67%) (2026-07-27)
- tinywasm-typed-function-references — derivative, Scope Gate, cross-repo spec-proposal collision class (2026-07-27)
- mapcidr-allocation — too-easy, fairness-ratchet class (2026-07-27)
- scriggo-dynamic-render — maintainer-declined, rejected before any code written (2026-07-27)
- slatedb-secondary-indexes — cold-not-live at pick time (2026-07-27)
- orb-geofence-visits — too-easy, rules-as-difficulty class, second confirmation (2026-07-27)
- grex-counterexamples — publicly-solved, Scope Gate, bounded-limit PR-listing class (2026-08-03)
- gopcua-monitored-item-filters — already-covered pick, author call (2026-08-03)
- lalrpop-operator-precedence — shelved, clean-engine LOC ceiling (2026-07-27)
- pyomo-nonsmooth-to-linear — derivative (2026-08-07)

## Rejected-pick ledger — repo/derivative/exclusivity reasons (Olympus1 + Olympus3 rejected/, consolidated 2026-08-20)

Compiled from the `rejected/` problem folders themselves (meta.md/feedback.md/REJECTED.md/etc), not
a prose log. One line per pick: `repo/feature — reason`. Entries whose repo name already appears in
the "Merged dead-pick ledger" section above were skipped as duplicates during consolidation.

- cfn-guard-arithmetic — derivative 0.865 vs a prior same-repo cfn-guard arithmetic-superset submission, shelved
- lyon-stroke-to-fill — publicly-solved: maintainer publicly pointed to a working external reference implementation for StrokeToFill (new exclusivity-reject class: external-oracle hand-off, not just an in-repo PR)
- starlark-go-inplace-mutation — maintainer-philosophy: starlark-go maintainers decline language-syntax additions (list.sort() DECLINED #174, del deliberately unsupported #321); poor Olympus target for language features
- augurs-dtw-barycenter-kmeans — derivative (0.79 sim / 0.8 conf) vs a prior augurs DTW/KMeans submission; shared core, cannot out-add extra algorithms to escape it
- babel-rbnf-spellout — derivative (78% conf, 0.724 sim) vs an older cross-author RBNF/plural-ranges submission; babel treated as saturated for this family
- biwascheme-syntax-rules — derivative 91.5% (>90% threshold), hard reject; R7RS/RFC/SMT-LIB/SQL-standard features are high derivative risk even in obscure repos
- culori-cam16-appearance — publicly-solved (folder-tagged PUBLICLY-SOLVED)
- ezdxf-crop-entities — derivative (folder-tagged DERIVATIVE-SHAPE)
- fend-unit-matrix-algebra — derivative (0.90 conf, 0.78 sim) vs an older same-repo fend-matrix submission; matrix/linear-algebra is an author-obvious feature family on a calculator repo
- ivy-axis-operators — derivative (82% conf) vs older prior art that already added the bracketed [k] axis indicator to ivy; core feature class taken
- koto-generic-type-hints — publicly-solved/maintainer-declined: maintainer explicitly declined generic type hints in a comment on closed issue #298 (closed-issue-with-decline-comment trap)
- minify-css-source-maps — rejected at the platform Scope Gate (publicly-solved)
- montydb-expr — terminal reject (round 7), Scope Gate: derivative
- openpnm-imbibition-residual — publicly-solved (folder-tagged PUBLICLY-SOLVED)
- pdfcpu-annotation-extraction — user flagged pdfcpu as an already-used (old) repo
- pynite-response-spectrum — derivative (folder-tagged DERIVATIVE)
- python-control-descriptor-systems — old/already-used repo, user flagged (folder-tagged OLD-REPO)
- quantecon-average-reward-dp — old/already-used repo, user flagged (folder-tagged OLD-REPO)
- section-properties-thin-walled — user identified this as an old pick (repo already used elsewhere in the workspace)
- stonesoup-multiple-model-tracking — publicly-solved (folder-tagged PUBLICLY-SOLVED)
- aioquic-http3-priorities — shelved by the user: the task is an old/already-done problem
- aerosandbox-area-rule — language-gate/quota disqualification (folder-tagged LANGUAGE-GATE)
- cantools-bus-latency — shelved: a concurrent session was authoring an overlapping cantools timing feature (bus_load/simulate_schedule/response_times) in the same timing domain
- customasm-section-placement — reused repo: customasm already carries an approved #for submission, breaking the standing brand-new-repo preference; discontinued at the user's direction before implementation
- goblin-macho-chained-fixups — derivative, Scope Gate reject (2026-08-20): "narrower derivative of older accepted candidate", which already implements the same `LC_DYLD_CHAINED_FIXUPS` parser at `goblin::mach::chained_fixups`, import-table decoder, pointer-chain walker, bind-to-import resolution, and `MachO::imports()` integration on the same files (`src/mach/chained_fixups.rs` new + `src/mach/mod.rs` integration) — this submission "can be produced largely by trimming that implementation." Full solution + 18-test suite built, validated (3x deterministic, 16/18 fail-to-pass on base), and description-hardened before the reject landed; not curable by rewording or adding a trap, since the entire pick IS the chained-fixups core. Treat goblin Mach-O chained-fixups / `imports()` as DEAD; a future goblin pick needs a different subsystem (elf/, pe/, archive/) or a different Mach-O capability untouched by this core (not exports/bind/chained-fixups).
