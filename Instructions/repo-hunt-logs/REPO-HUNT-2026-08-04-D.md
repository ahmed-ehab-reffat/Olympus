# Repo hunt 2026-08-04-D — hunting the APPROVED-SET profile (and a calibration correction)

Method change: instead of sourcing by domain keyword, derive the profile from the five ACCEPTED
problems and search for repos matching it. This produced both a candidate and a correction to a gate
I had been applying wrongly all day.

---

## The approved set, measured

| Problem | Repo | ★ | Open PRs | Commits/12mo | Domain |
|---|---|---|---|---|---|
| calyx-unused-port-elimination | calyxir/calyx | 607 | 11 | 109 | HDL compiler |
| pulldown-cmark-gfm-autolinks | pulldown-cmark | 2666 | 17 | 111 | markdown parser |
| lyon-arcs-join | nical/lyon | 2593 | 0 | 33 | 2D tessellator |
| neva-array-bypass-generalization | nevalang/neva | 1077 | 2 | **600** | dataflow language |
| customasm-ruledef-disassembly | hlorenzi/customasm | 1052 | 4 | 34 | custom-ISA assembler |

**Profile:** 607-2666 stars (all under 3k), 0-17 open PRs, deep multi-stage engine in an unusual
domain, 4 Rust / 1 Go. Picks span 2-7 files across 2-4 subsystems.

## ⭐⭐⭐ THE CORRECTION — file velocity is NOT a reject criterion

I rejected cerbos, moon, nilaway, rapier and mvdan/sh at least partly on commit velocity. The
approved set says that gate is wrong:

- **neva did 600 commits in 12 months** — more than mvdan/sh's 383 — and produced an ACCEPTED problem.
- The neva pick's own files were **hot at base**: `analyzer/network.go` **33** commits in the
  preceding 12 months, `desugarer/network.go` **34**, `irgen/network.go` **15**. I rejected cerbos at
  20-26 and nilaway at 37.
- The pulldown-cmark pick touched `parse.rs` (100+ commits) and `lib.rs` (**52**).

Gate 5's own wording is "live maintainer workstreams + **features being shipped now**", and every one
of its kill examples is a CAPABILITY collision (jedi ~60% shipped, OPA in-flight), never file churn.

**The corrected gate:** overlay CAPABILITIES, not file lists. Is anyone — maintainer commit, merged
PR, or open/draft PR — building the capability you intend to add? A busy file whose capability space
is untouched is fine; a cold file whose capability just shipped is dead. Recorded in
`PICK-FILTER.md § Gate 5`.

**What this does NOT rehabilitate:** picks whose capability genuinely collided (rapier's quarantine +
persistent islands, both landed 2026-08-02; nilaway's function-variables and type-conversion PRs;
openfga's magnet issue). And mvdan/sh still fails on capability CLASSES (zsh live, bash-parity
saturated-reference, formatter swept), not on its 383 commits.

---

## RANK 1 — veryl-lang/veryl — ★995 — the calyx analogue

- **License:** dual **MIT / Apache-2.0** (both files read and verified) · **Rust, pure**
- **127 open issues** (inside the 100-1000 window without relaxation) · **7 open PRs** · pushed 2026-08-04
- **Local dedup: ZERO hits** across `Instructions/`, `problems/`, `rejected/`, `approved-problems/`
  and every prior REPO-HUNT. Quota 0/6.
- **Domain:** a hardware description language that compiles to SystemVerilog — the same class as our
  strongest approved problem (calyx, which held 10-40% across 13 batches).

**Architecture — a real multi-stage pipeline with TWO backends over one IR:**

```
parser -> symbol_table -> conv (AST->IR) -> analyzer passes (pass1, post_pass1, pass2, post_pass2)
                                              |
                                              +-> emitter    (SystemVerilog codegen, 7045 LOC)
                                              +-> simulator  (68k LOC) + cosim
```

Handwritten core (generated files are confined to `metadata/`): `analyzer/value.rs` 5399,
`symbol_table.rs` 3944, `conv/declaration.rs` 2911, `handlers/create_symbol_table.rs` 2738,
`ir/{op,expression,comptime,statement,variable}.rs`, `emitter.rs` 7045.

**Trap seams**

| Pattern | Present | Evidence |
|---|---|---|
| S6 two evaluators of one model | **yes (lead)** | `emitter` and `simulator` both consume the analyzer's IR and side tables (`attribute_table`, `connect_operation_table`, `definition_table`). They must agree on the semantics of the same Veryl source |
| F-9 cross-stage resolution drop | **yes** | `emitter/expaneded_modport.rs` expands modport connections at EMIT time from tables the analyzer built — the classic validate-here / emit-there ambiguity |
| F-2 bidirectional seam | **plausible** | modports and interfaces: a port is both a provider and a consumer of a connection |
| F-1 architecture wall | unknown | cannot be scored before a batch |

**Test surface — excellent.** `analyze(code: &str) -> Vec<AnalyzerError>` takes a source string and
returns diagnostics: 207 analyzer tests, 65 emitter, 48 IR. Behavioural, table-driven, trivially
extensible. Watch one thing: the harness calls `symbol_table::clear()` on global mutable state, so
determinism under parallel test execution needs the mandatory 3x check.

**Capability space (both streams, per the corrected gate).** In flight: a big open PR rebuilding
combinational analysis on sparse-region MemorySSA, a for-loop-bounds diagnostic, and a stream of
analyzer fixes (ifdef scoping, `multiple_assignment` on disjoint dynamic writes, import visibility,
duplicate enum variants, array-literal function arguments) plus a new `$prop` namespace. The
DIAGNOSTIC space is being actively worked; the emitter/simulator PARITY space is not.

**Candidate seam family (not yet scope-locked).** The simulator carries an explicit
`unsupported_description` diagnostic — "this description is not supported by the simulator" — i.e. a
documented capability frontier that the emitter does not share. That asymmetry is repo-internal and
un-nameable externally, which is exactly the Stage-2b profile we want.

**The risk to resolve before scope-lock:** "make X consistent with the already-correct sibling Y" is a
DEAD class in `HARDENING.md` (Y is the answer key). If the emitter's handling of a construct is a
usable template for the simulator, that pick is dead. A viable pick needs the two backends to require
genuinely DIFFERENT machinery, or needs to live in the analyzer where both backends then depend on it.

**Open feasibility question (measuring now):** the workspace is large (parser 93k, simulator 68k,
migrator 89k LOC). `cargo build --workspace` was started at 23:43; if a cold build is slow, the
Dockerfile needs `olympus-base-rust` plus a scoped test target rather than the whole workspace.

---

## RANK 2 — kivikakk/comrak — ★1666 — **SHELVED 2026-08-05 (viable fallback, not rejected)**

Audit complete and green on every mechanical gate (see the head-to-head below): licence read in full,
26s build, 649+203 tests, determinism 3/3. Shelved ONLY on collision risk against our own two markdown
submissions. Clone kept at `worktrees/comrak` so this audit is not repeated. **Revisit if** veryl fails
Gate 1, or if a comrak pick can be found that is NOT extension-shaped (the renderer-parity surface
across html/commonmark/xml is the place to look, since that is comrak's own model rather than a spec).

- **3 open PRs, 9 open issues** (issue window RELAXED — a very lean tracker), zero dedup hits, quota 0/6
- BSD-style license — the text reads "All rights reserved. Redistribution and use in source and binary
  forms..." and must be READ IN FULL for rider conditions before investing (`RULES.md`: a BSD text
  with extra conditions is a HARD disqualifier).
- Same class as an ACCEPTED problem (pulldown-cmark GFM autolinks, 40% in band), which cuts both ways:
  the shape is proven, and the shape is also where a derivative check would look first.
- CommonMark/GFM are external specs, but the approved pulldown-cmark problem shows a spec-named
  markdown pick CAN work when an F-1 architecture wall carries the difficulty.

## Also checked, not shortlisted

| Repo | ★ | Reason |
|---|---|---|
| linebender/kurbo | 982 | 34 open PRs; already surfaced in `REPO-HUNT-2026-08-02-C.md` |
| dora-rs/dora | 3865 | 75 open PRs — queue too heavy to audit |
| TimelyDataflow/differential-dataflow | 2994 | 31 open PRs |
| pop-os/cosmic-text | 2119 | 23 open PRs |
| tremor-rs/tremor-runtime | 932 | RECENCY-DEAD: last push 2025-07-27 |
| spade-lang/spade (71), dalance/sv-parser (479) | — | under the 500-star floor |

## Owed before authoring veryl

Gate 1 behavioural-f2p-gap · Gate 5 by CAPABILITY against the MemorySSA PR and the analyzer fix
stream · Gate 6 reproduce-on-base through the real CLI · Gate 7b exclusivity (read diffs) · Gate 8
maintainer philosophy (veryl publishes a full language book) · Gate 9 flakiness 3x, watching the
global-table `clear()` pattern · Gate B >=200 effective · Docker build-time budget.

---

## HEAD-TO-HEAD: veryl vs comrak (run 2026-08-04, both measured locally)

| Gate | veryl-lang/veryl | kivikakk/comrak |
|---|---|---|
| License | dual MIT / Apache-2.0 | BSD-2-Clause + vendored cmark BSD-2 + two MIT (houdini/sundown) — ALL read, all in the allowlist, no riders |
| Stars / tracker | 995 · **127 issues** · 7 open PRs | 1666 · 9 issues (window relaxed) · 3 open PRs |
| Language purity | Rust, pure | Rust, pure |
| **Cold build + test** | **134s**, 1.8G target (scoped to `veryl-analyzer` + `veryl-emitter`) | **26s**, 974M target (whole crate) |
| Warm test run | 1.6s | 0.8s |
| Test surface | 414 analyzer + 65 emitter; `analyze(code: &str) -> Vec<AnalyzerError>` | 649 lib + 203 spec; 46 test files |
| **Determinism (Gate 9)** | **PASS 3/3 identical** | **PASS 3/3 identical** |
| Handwritten core | analyzer 80k (value 5399, symbol_table 3944, conv, ir/, handlers/), emitter 7045 | ~29k excluding the 19k re2c-generated `scanners.rs`: parser/mod 2951, inlines 2721, html 1861, cm 1394 |
| Multi-evaluator seam | emitter + simulator + cosim over one analyzer IR | **html + commonmark + xml renderers over one AST** |
| F-10 axes | modport x direction, generics x comptime | **22+ extension flags x 3 renderers** |
| Capability space in flight | analyzer DIAGNOSTICS (MemorySSA rebuild PR, for-loop bounds, ifdef scoping, import visibility); emitter/simulator PARITY untouched | "[WIP] grid tables", "Enable custom code blocks", an Escaped-node commonmark bug |
| **Stage 2b derivative** | **LOW** — the seam is statable only in veryl's own nouns (its IR, its modport expansion, its simulator frontier) | **HIGH** — see below |

**Verdict: veryl RANK 1, comrak RANK 2 (conditional).**

comrak wins decisively on feasibility (26s vs 134s, 3M vs 32M clone, simpler Docker) and its shape is
proven-approvable. It loses on the axis that has killed more picks this week than any other:

1. **Self-collision.** We already have an ACCEPTED `pulldown-cmark-gfm-autolinks` and an IN-FLIGHT
   `problems/pulldown-cmark-abbreviations`. A comrak pick would be "add markdown extension X to a Rust
   CommonMark parser" — the same feature CLASS as both, from the same author pipeline. The dedup engine
   compares behavioural and structural overlap, and this is exactly the `orb` / `lol-html` shape.
2. **Every comrak capability is spec-named.** CommonMark, GFM and the extension list are external
   specs = Stage-2b magnet + saturated reference. The pulldown-cmark approval survived that only
   because an F-1 architecture wall carried the difficulty — and that wall (a post-pass over
   `Event::Text` cannot see pre-emphasis source) is specific to pulldown's architecture AND is now
   published in our own approved set.

veryl's capability space is the opposite: repo-internal, large (modports, clock domains, comptime,
generics, two backends), and the maintainers are busy in a DIFFERENT part of it (diagnostics).

**comrak stays viable as a fallback** if veryl fails Gate 1, but any comrak pick must be checkable
against our own two markdown submissions first, and must not be an extension-shaped feature.

## Disk note (2026-08-04)

This sweep filled the disk. `cargo` target directories are the entire cost: gluon 5.3G, numbat 2.1G,
veryl 1.8G, comrak 974M against a 437M project. **Delete `worktrees/*/target` after every measurement**
— the clone is 3-32M, the target is 100x that. Local Docker validation is NOT available in this
environment, so Dockerfile feasibility stays an estimate (both candidates are Pattern A
`olympus-base-rust`; veryl's 134s cold build is the only real cost).

---

## veryl Gate-A / Phase-2 log (2026-08-05) — three candidates, three capability collisions

The repo still passes every gate. These are PICK-level kills, recorded so they are not re-derived.

**Candidate 1 — aggregate (struct/union/enum) type inference for `let`/`var`. DEAD on Phase 2.**
Gate 1 reproduced cleanly first: `var q; q = p;` with a struct `p` yields `TypeInferenceNotSupported`
while the scalar control passes, and the cause is documented in the source — `to_sv_type_name()`
returns `Option<&'static str>` (builtins only), so `emit_inferred_type` would fall back to a 1-bit
`logic`. The seam looked ideal (the analyzer resolves the type; the emitter must materialize a
declaration with NO AST node to print from, so it needs `namespace_string` + generic-instance
mangling — genuinely different machinery from the declared path, not a sibling to copy).
**Killed by the PR search:** [#2785 MERGED] *"fix(analyzer): reject struct/union/enum type inference
instead of emitting a 1-bit logic declaration"* — the rejection is a deliberate, recent maintainer
decision, and the inferred-declaration lane is being actively completed around it: [#2478] type
inference support, [#2700] keep the signed qualifier, [#2701] keep unpacked array dims, [#2901] keep
array dims parametric. Five merged PRs in one narrow lane. Reversing #2785 is both a capability
collision and a Gate-8 contradiction of a merged maintainer decision.

**Candidate 2 — emitter/simulator parity (the original RANK-1 thesis). DEAD on Gate 5.**
The simulator is the single hottest area in the repo (58 of 600 commits/12mo) and the work is deep:
Cranelift JIT codegen, AOT-C whole-comb coverage, wide-op optimization, `case` lowering, watch
tooling. The `unsupported_description` frontier is being pushed forward continuously.

**Candidate 3 — clock-domain (CDC) laundering. DEAD on Gate 5.**
A dedicated maintainer branch series: `fix/cdc-condition-gate`, `fix/cdc-concat-lhs`,
`fix/cdc-const-index`, `fix/cdc-lhs-select`, `fix/cdc-interface-inst`, `fix/cdc-signed-launder`,
`fix/cdc-array-literal-element` — 19 commits/12mo systematically closing exactly this gap class.

**Lanes not yet checked (the remaining candidate space):** formatter (7 commits), comptime (6),
attributes (4), namespace (3), languageserver (0), aligner/pretty. Modport is moderate (interface
parameter overrides through modport ports, modport type check).

⭐ **The pattern worth noting:** the corrected Gate 5 says file velocity is fine and only capability
collision kills. veryl is the case where that gate does real work in BOTH directions — it cleared the
repo (600 commits/12mo, same as accepted neva) and then killed three consecutive picks on capability
grounds. Three-for-three is a signal about this repo's lane density, not bad luck: a 600-commit/12mo
repo with an active contributor base consumes capability lanes fast.

**Candidate 4 — formatter / aligner (the coldest lane, 7 commits/12mo). DEAD on Gate 1 (covered).**
The most attractive lane on paper: `crates/formatter` (3462 LOC) plus `crates/aligner` (365) is
veryl's OWN model with no external spec, so Stage 2b is as low as it gets, and the harness is ideal
(`format(metadata, code) -> String` with exact `assert_eq!`, 51 tests). The aligner is genuinely
globally-coupled — `PadKind::{Always, IfBreak, IfFlat}` with a merge lattice, where whether padding
is visible depends on whether the whole GROUP breaks.

It is already covered. `crates/tests/src/lib.rs § mod formatter` runs `format_file` over the entire
94-file corpus and asserts `input == formatted`, i.e. every checked-in testcase is a formatter FIXED
POINT — a corpus-wide idempotency check. And the formatter source carries scar-tissue comments from
idempotency fights already fought: *"consecutive single-line insts share a group and the forced break
emits cross-inst padding (non-idempotent)"* (line 608) and *"Auto-finish would split the EXPRESSION
group on source-line gaps, breaking idempotency (pass 2 sees merged keys)"* (line 1149). The obvious
gap-finder (format-twice over the corpus) is the maintainer's existing CI check.

## veryl verdict after four candidates

The REPO passes every gate and its measurements stand (licence, 414+65 tests, determinism 3/3, 134s
build). Four capability lanes checked, four dead — three on active maintainer workstreams, one on
existing coverage. This is not bad luck: **600 commits/12mo with an active contributor base plus
corpus-wide fixed-point tests means capability lanes are consumed as fast as they can be found.**
Remaining unchecked: comptime (6 commits), attributes (4), namespace (3), languageserver (0),
modport (moderate) — but attributes and namespace both had feature commits in the last 30 days
(ifdef scope leak, `$prop` namespace), so the cold list is shorter than the commit counts suggest.

**Recommendation: stop drilling veryl.** It is a legitimate target whose lanes are taken; a fifth
candidate is a coin flip on the same odds. Prefer the shelved comrak (audited green, renderer-parity
surface is its own model) or park sourcing and batch what is already built.

---

## Scientific-domain sweep (2026-08-06) — numbat RANK 1, Clarabel.rs REJECTED

Brief: relax the repo filters, accept a hot repo, invent a feature, prefer the lyon/numbat flavour.

**The structure being reused (from all three approved picks):** take a construct the repo supports
only in a RESTRICTED form and generalize it to the repo's own full model. neva: array-bypass `[*]`
gains every form an ordinary connection has. numbat: `parse` goes from `<number> [unit]` to a whole
unit grammar. This shape is repo-internal by construction, so it survives the capability-level magnet
test, and it carries LOC without padding.

### RANK 1 — sharkdp/numbat — computed and named dimension exponents

Measured on a fresh build, not assumed:

| exponent form | value level `2 m^…` | type level `Length^…` |
|---|---|---|
| literal `2` | works | works |
| rational `(1/2)` | works | works |
| arithmetic `(1+1)` | **works** | rejected, will not parse |
| named constant `n` | rejected ("variable") | rejected |

Two independent restrictions, and the source states the limit itself: *"Evaluates a limited set of
expressions at compile time."* Missing machinery is real, not a call-through:
`evaluate_const_expr(expr)` takes **no environment**, so named constants are structurally
unreachable; the type-level exponent parser has no expression parser at all.

Seams: `to_rational_exponent(exponent_f64: f64)` routes every exponent through an f64 round-trip
while dimension exponents must stay EXACT rationals or type equality silently breaks (HARDENING
already records a measured numbat kill in this area, A12, 5/11); and the value/type split is two
separate code paths that must agree on one grammar (S5 dual-path).

Gates: typechecker/dimension/parser lanes 0 commits by subject in 12mo; HEAD 5 months cold with
contributor PRs queued; no PR implements computed or named exponents; quota 1/6; licence and
determinism inherited from the approved run; 26s build; clone 5.7M.

Residual risk, stated honestly: this is our SECOND "extend a restricted grammar in numbat" pick.
Subsystems differ completely (runtime string-parsing builtin vs compile-time exponent evaluation in
the typechecker) but the shape rhymes. Mitigation is to centre the submission on the TYPE SYSTEM
(exact rational arithmetic, a const-eval environment, type equality) rather than on grammar breadth.

### REJECTED — oxfordcontrol/Clarabel.rs (★585, Apache-2.0, conic interior-point solver)

Attractive on paper: pure-Rust default dependencies (BLAS/LAPACK sit behind the optional `sdp`
feature, so a non-SDP pick builds offline), 22 open issues, an own-model cone system, and the
restricted-form shape appears to be everywhere (supported cone types, termination modes).

**Killed by the corrected Requirement 6 — read the commit SUBJECTS, not the count.** Two commits in
12 months on the default branch, and they are *"julia sync fix"* and *"update example"*. **Zero real
code commits in a year.** Last substantive work was v0.11.1 on 2025-06-11, 14 months ago, while 10
PRs sit unmerged — including substantial features (warm start #219, arbitrary-precision SDP #224,
KKT refinement #230/#231). This is the bunster corpse pattern recorded in `olympus-hunt` yesterday,
and it will trip the platform's >=500-star active-maintenance precheck.

Three further independent strikes, any one of which would have been disqualifying on its own:
1. **Magnet.** Every capability is named by convex-optimization literature — warm start, cone types,
   presolve, scaling, iterative refinement. "Add warm start to a conic solver" is intelligible to
   anyone in the field. This is exactly the class that killed comrak-reference-style-links.
2. **Port derivative.** Clarabel.jl and Clarabel.cpp are sibling implementations by the same author,
   and the one recent commit is literally *"julia sync fix"* — features flow between ports, so
   anything missing in `.rs` is portable rather than invented.
3. **Flakiness (Gate 9).** A numerical interior-point solver with tolerance-based convergence tests;
   the open issues are largely `NumericalError` reports. High risk of a non-deterministic baseline.
