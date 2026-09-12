# Repo hunt 2026-08-02 (session B) — unusual-domain sweep after the objdiff death

Second sweep of the day. The morning run (`REPO-HUNT-2026-08-02.md`) killed objdiff on its open-PR
queue; this run went wider into domains no prior hunt had touched (units/dimensional analysis,
log-mining DSLs, bioinformatics, audio DSP, CAD/SDF, eBPF, formatters, lexer generators, Datalog).

Search space: Go + Rust, 500-5000 stars, permissive license, 57 keyword/topic queries, ~380 repos
seen, 12 finalists verified mechanically, 5 cloned and audited.

**Headline: the best structural find of the sweep (google/mtail) died on a check no earlier hunt
had needed — a 4k-star upstream that is an abandoned mirror of a 29-star live fork.** See § DEAD.

Relaxations recorded: the **100-1000 open-issue gate was relaxed** for every finalist (niche Go/Rust
engines run 5-92 issues). No other hard requirement was relaxed.

---

### sharkdp/numbat — ★2621 — RANK 1

- **URL / stars:** https://github.com/sharkdp/numbat — ★2621
- **Language:** Rust (pure; no `-sys` crates in the `numbat` crate; exchange-rate networking is
  isolated in the separate `numbat-exchange-rates` crate and is not on the test path)
- **Domain:** statically typed scientific-computation language with first-class physical dimensions
- **Open issues without PRs:** 92 (29 open PRs)
- **License:** Apache-2.0 + MIT dual (both `LICENSE-APACHE` and `LICENSE-MIT` read; allowlisted)
- **Last commit:** 2026-03-13
- **Test framework / organisation:** `numbat/tests/{interpreter,example_snapshots,prelude_and_examples}.rs`
  plus insta snapshots. Behavioural through the public API: tests feed a **program string** and
  assert the printed result / error. Zero mocks. `examples/tests/*.nbt` is a second, program-level
  suite the repo runs as one test. Ideal substrate for a test patch.
- **Baseline determinism:** 2 runs identical. 175 + 52 + 1 + 5 pass; **one deterministic failure**,
  `prelude_and_examples::numbat_tests_are_executed_successfully`, caused by a missing tz database in
  this sandbox (`US/Eastern` unparsed). Not flaky - env-dependent. The Dockerfile must install
  `tzdata`, or base mode scopes that one test out with the reason documented. Verify in-image before
  scope-lock.
- **Docker:** Pattern A (`olympus-base-rust` + chmod/symlink). Workspace of 5 crates, builds offline
  once vendored, no system deps beyond tzdata.
- **Architecture:** tokenizer -> parser -> prefix_transformer -> name_resolution -> typechecker
  (HM-style constraint solver over **rational** dimension exponents) -> bytecode_interpreter -> vm,
  with a `Registry`/`UnitRegistry` layer shared by both the type level and the runtime.

**TRAP SEAMS (failure-patterns.md):**
| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | yes | `numbat/src/bytecode_interpreter.rs` compiles the typed AST to bytecode; the typed dimension is gone by the time `vm.rs` runs, so runtime unit decisions must be baked at compile time |
| F-2 bidirectional seam | yes | `typechecker/constraints.rs:85 solve()` + `substitutions.rs` - substitution application mutates the whole constraint set, so satisfying one constraint re-writes others (`ConstraintSet::apply`) |
| F-3 second-axis carve-out | partial | `decorator.rs` (aliases, `@aliases`/`@name`) x prefix admissibility in `prefix_parser.rs` - a unit is exempt from prefixing on one axis and from aliasing on another |
| F-4 ownership trap | no | plain owned values; no `Rc<RefCell<_>>` graph |
| F-5 transitive pass-through | yes | derived dimensions/units resolve transitively through `Registry::get_base_representation_for_name` (`registry.rs:156`) - a derived entry defined in terms of another derived entry |
| F-8 named-algorithm override | yes | the domain borders SI/dimensional analysis, but numbat deliberately diverges (rational exponents, `Ratio<i128>` in `arithmetic.rs:5`, its own simplification policy). Keep the famous name as misdirection, never as the scope |
| F-9 cross-stage resolution drop | **yes (strong)** | the typechecker resolves a dimension to a `BaseRepresentation`, then `unit.rs:281 to_base_unit_representation()` **re-derives** the base form + conversion factor at runtime, and `unit.rs:309` compares two independently re-derived factors. One root cause here breaks every unit-facing capability at once |
| F-10 capability cross-product | **yes** | axis 1 multiplicity: `Product<Factor, CANONICALIZE>` (`product.rs:19`) is unity / single-factor / multi-factor. axis 2 polarity: exponent sign (numerator vs inverted, `product.rs:208 invert`) and **integer vs rational** exponent. The cross-product cell (multi-factor x rational-negative exponent) is exactly the F-10 shape |

**Gate 5 detail (the thing to respect here).** The repo is NOT uniformly cold. Warm, avoid as the
anchor: `typechecker/` 27 commits/12mo, `vm.rs` 20, `bytecode_interpreter.rs` 15, `parser.rs` 12.
Cold, and where the seams above actually live: `product.rs` **0**, `name_resolution.rs` **0**,
`prefix.rs` 1, `arithmetic.rs` 2, `decorator.rs` 2, `registry.rs` 3, `unit_registry.rs` 3,
`unit.rs` 4, `dimension.rs` 5. **`quantity.rs` is contested** - open PRs #877, #875 and #874 all
rewrite `full_simplify` unit-group handling. Do not anchor a pick on unit simplification.

**Best Olympus feature types (cross-subsystem):**
1. Dimension/unit-registry algebra reaching the runtime: something whose correct form requires the
   `Registry` base-representation to survive into `unit.rs` conversion rather than being re-derived
   (spans registry + unit + typechecker boundary + bytecode_interpreter). This is the F-9 thesis.
2. Rational-exponent completeness: capabilities that only misbehave in the multi-factor x
   negative/rational-exponent cell (spans `product.rs` + `registry.rs` + pretty-printing).
3. Prefix/alias admissibility as a cross-cutting rule (spans `prefix_parser.rs`, `decorator.rs`,
   `name_resolution.rs`, the unit registry) - an exemption spanning two collections (F-3).

**Estimated complexity:** 250-450 effective LOC across 4-8 files, 1 crate + CLI surface. The
algebraic core is small and dense, so estimate the minimal golden by sketch before committing
(the taffy/golang-geo lesson applies).

**Why it matches:** unusual domain (units and dimensional analysis) that no prior hunt or approved
problem touches, a genuinely coupled algebraic core shared by the type level and the runtime, an
excellent program-string-in test substrate, and a documented language book so Gate 8
(defined-behavior) is easy to satisfy fairly.

**Risks:** (a) the typechecker and VM are warm, so the pick must be anchored in the cold
registry/unit/product layer; (b) `quantity.rs` simplification is contested by three open PRs;
(c) sharkdp is a high-visibility maintainer, so Stage 2b applies - do not pick anything a physics
or SI document could name on its own ("add complex numbers", "add bitwise ops", "add unit X" are
all magnets and two of them are already open PRs); (d) tzdata dependency in the baseline suite.

---

### tdewolff/canvas — ★1825 — RANK 2

- **URL / stars:** https://github.com/tdewolff/canvas — ★1825
- **Language:** Go (pure; no cgo in the core paths)
- **Domain:** 2D vector graphics - path algebra, stroking, dashing, text layout, multiple output backends
- **Open issues without PRs:** 21 (3 open PRs)
- **License:** MIT
- **Last commit:** 2026-07-14
- **Test framework / organisation:** table-driven Go tests on paths and text; behavioural through the
  public API. Not audited for mocks in depth.
- **Baseline determinism:** **NOT RUN** - audited from the tree only. Owed before scope-lock.
- **Docker:** Pattern B (`olympus-base-go`).
- **Architecture:** path construction -> flatten/stroke/dash -> boolean ops (Bentley-Ottmann) ->
  text layout/shaping -> rasterizer / PDF / SVG backends. A real multi-stage pipeline.

**TRAP SEAMS:** F-1 yes (flattening destroys curve structure before the backends see it);
F-9 plausible (text layout resolves metrics that the PDF/SVG writers re-resolve); F-6 yes (stroke
vs dash vs boolean-op ordering is unstated); F-4 no.

**Gate 5 detail:** cold - `font/` 0 commits/12mo, `pdf.go` 0, `rasterizer.go` 0. Warm and to be
avoided - `path_intersection.go` 22 (plus open PR #382 rewriting the Bentley-Ottmann vertex walk),
`text.go` 9, `path.go` 8.

**Why it matches:** the cold backends sit downstream of a warm core, which is the right shape for an
F-9 pick that spans the boundary without touching the contested file.

**Risks:** Stage 2b is the live risk - SVG, PDF and CSS all NAME the behaviours here, and we already
own `approved-problems/lyon-arcs-join` plus `rejected/lyon-stroke-to-fill` in the adjacent
vector-graphics space. A pick must be defined by canvas's own model, not by a spec. Determinism run
still owed.

---

### typstyle-rs/typstyle — ★870 — RANK 3

- **URL / stars:** https://github.com/typstyle-rs/typstyle — ★870
- **Language:** Rust (depends on `typst-syntax`, which is pure Rust)
- **Domain:** code formatter for Typst - Wadler-style pretty-printer
- **Open issues without PRs:** 27 (5 open PRs) - **last commit 2026-07-28, 24 commits/90d**
- **License:** Apache-2.0
- **Baseline determinism / seam audit:** **NOT RUN.** Listed as a live lead, not a cleared candidate.
- **Why it is on the list:** a pretty-printer's layout algebra is globally coupled by construction -
  a break decision inside one group changes whether every ancestor and sibling fits, which is the
  L1/L2 coupling this hunt looks for, and formatter output is trivially assertable.
- **Risks:** repo-wide velocity is real (24 commits/90d on 870 stars means the maintainer is on it);
  per-subsystem coldness not yet measured. Audit Gate 5 first.

---

## DEAD this sweep (do not re-derive)

**google/mtail — ★4024, Apache-2.0 — the expensive one. NEW REJECT CLASS.**

Everything read like the best target of the sweep. `internal/runtime/compiler/{parser,ast,checker,
codegen,opt,symbol,types}` -> `code` (bytecode) -> `vm`, a real Hindley-Milner unification type
system (`types/types.go:359 Unify`, type variables with `SetInstance` mutation, occurs check, a
`LeastUpperBound` coercion lattice) and - unusually - **regex capture-group type inference**
(`types.go:539 InferCaprefType` reads the parsed regex AST to decide Int/Float/String). Textbook
F-9 confirmed: `codegen.go:86-99` and `:236-250` re-derive the value type off the `Dimension`
operator's last argument and dispatch opcodes through a type-keyed table at `:373`. Behavioural
table-driven tests that take a DSL program string. Apache-2.0, 23 deps, no cgo, `docs/Language.md`
gives externally-defined behaviour for Gate 8. Baseline **3/3 deterministic** in Docker.
Per-directory history said the entire compiler was frozen: **0 commits in 12 months** in every one
of checker / codegen / types / parser / ast / opt / vm / code, inside a repo whose tailer was still
being worked on. That is the "cold target inside a live repo" profile this skill hunts for.

It is dead anyway. Issue **#929 "This repo is obsolete, please follow `jaqx0r/mtail` instead"**:
*"No mtail maintainers have write access to this repository anymore."* Development moved to
**jaqx0r/mtail**, which has **504 commits in the last 12 months, 34 of them in
`internal/runtime/compiler` and 16 in `internal/runtime/vm`** - including feature work squarely in
the type checker (`add defined() builtin to test if a capture group was matched`, `fix(checker):
allow chained match expressions with numbered caprefs`, `feat: Add time-native types to the
runtime`, `refactor: Store the indices of the capture groups instead of strings`). The compiler is
not cold; it is the hottest area upstream. The coldness reading was an artifact of measuring a
corpse.

And it cannot be re-homed: the live fork carries **29 stars**, far under the 500 hard floor.

⭐ **The class, which is new and is not the Section D mirror case:** a repo can fail
COLD-NOT-LIVE *invisibly* when the starred upstream is an abandoned mirror of a low-star live fork.
Unlike a Codeberg/Gerrit mirror, nothing about the repo metadata says so - `archived:false`,
`pushed_at` recent enough to clear the 12-month gate, 4k stars, Google org. The tell was in the
issue list. **Add to the mechanical checks: scan open issue TITLES for "obsolete" / "moved" /
"fork" / "no longer maintained" before the seam audit, and if the repo is a well-known project with
suspiciously frozen core directories, look for a fork with more recent activity
(`gh api repos/O/R/forks --sort=newest`).** Frozen core + live periphery is ambiguous: it means
either a genuine cold seam (neva, rust-minidump) or a dead upstream. Distinguish the two before
auditing seams, not after.

| Repo | ★ | Why dead |
|---|---|---|
| google/mtail | 4024 | Abandoned upstream; live fork `jaqx0r/mtail` (29★) does 34 compiler commits/12mo. See above |
| maciejhirsz/logos | 3540 | Gate 5. Warm everywhere in the codegen crate: `graph` 26 commits/12mo, `generator` 39, `parser` 26, `lib.rs` 26. Only the thin runtime `logos/src` is cold |
| onflow/cadence | 548 | Firehose. 362 commits/90d; 12mo: `interpreter` 785, `bbq` 535, `sema` 367, `parser` 236. Nothing cold worth 250 LOC |
| deadsy/sdfx | 625 | Stage 2c. 12 open PRs, and #87-#94 are one author's "Lipschitz X" series blanketing `sdf/sdf3.go` + `render/*` - the core |
| qmonnet/rbpf | 1122 | Stage 2b. The capability space IS the eBPF ISA spec - a named external standard, so authors converge. PR #152 also rewrites `assembler`/`asm_parser` + adds two JIT backends |
| nadavrot/layout | 740 | Recency. Last commit 2025-05-22 (>12mo). Genuinely attractive otherwise (Sugiyama layered graph layout is deeply coupled) - it will resurface in sweeps |
| jf-tech/omniparser | 1084 | Recency. Last commit 2025-02-21 |
| chaosprint/glicol | 2992 | Recency. Last commit 2025-01-23 |
| michaelmacinnis/oh | 1383 | Recency. Last commit 2023-09-14 |
| CSML-by-Clevy/csml-engine | 720 | Recency. Last commit 2023-06-28 |
| afnanenayet/diffsitter | 2393 | tree-sitter grammars pull C - Docker/offline cost |
| wooorm/markdown-rs | 1555 | CommonMark port = saturated-reference-port death class, and pulldown-cmark is already ours |
| koto-lang/koto, refaktor/rye, abs-lang/abs, goruby, duckscript | 586-882 | Clean general-purpose embedded VM = the author-obvious class THE PATTERN names. rye is also a 100-commit/90d firehose |
| AmrDeveloper/GQL, araddon/qlbridge, PaesslerAG/gval | 814-3510 | SQL/expression-evaluator class - author-obvious, sqlglot-adjacent |
| rust-bio, noodles, seqkit | 713-1821 | L2: feature sets are independent per-format/per-algorithm modules; caps ~67% pass regardless of rule count |
| tafia/calamine | 2374 | Reader-only, per-format independent modules (L2) |

## Handoff

RANK 1 (numbat) still owes, before a line of authoring: Gate 1 behavioral-f2p-gap, Gate 5 against
the **exact** target files (the cold list above, not the repo), Gate 6 reproduce-on-base, Gate 7b
canonical-org PR-diff exclusivity, Gate 8 defined-behavior + the CLAUDE.md six-check, and an
in-image tzdata determinism run. Stage 2b is the one to take most seriously here: write the
one-line summary the dedup engine would emit, and if a physics textbook could have named the
capability, pick something else.
