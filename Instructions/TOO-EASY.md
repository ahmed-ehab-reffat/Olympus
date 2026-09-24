# TOO-EASY — Shelved-for-Too-Easy Submissions & Dead Difficulty Classes

Catalog of picks that were authored, batched, and SHELVED because they could not be made hard enough at any fair tier. Each entry records the repo, the pick, what was attempted, the batch results, and the ROOT CAUSE so the same death class is not re-picked. A too-easy sub is not a wording failure; it is a pick-class failure. The fix is never another reskin of the same feature, it is a different feature.

> **Read at pick time** (alongside `PICK-FILTER.md` 8 gates). Before scope-locking ANY candidate, check it against the Death-Class Taxonomy below. A candidate that matches a dead class is rejected before authoring, not after three batches.

> **Where the artifacts live:** every sub catalogued here has its folder quarantined in `rejected/<repo>-<slug>` (moved via `git mv` when shelved). The folders are kept intact (meta.md / test.patch / solution.patch / feedback.md) for reference only - NOT submissions. **Dedup at pick time MUST grep `rejected/` too** (alongside `problems/`, `diamond-problems/`, `Olympus-Approved/`). This file is the human-readable index of what is in `rejected/` and WHY. See `../CLAUDE.md § HARD RULE - Too-Easy / Trivial Shelving`.

> **The 10-run batch is the only difficulty oracle.** Every sub here PASSED local validation, looked hard on paper, and only revealed itself as too-easy on a real Nova/Orion/Castor batch. Predictions and local sims do NOT catch this class. The cost of each entry below was 1-3 wasted batches.

---

## Death-Class Taxonomy (check every candidate against this table)

| Dead class | Tell at pick time | Why it is always too-easy | Killed |
|---|---|---|---|
| **Membership / validation / reject contract** | "reject invalid X across the family", "return a defined result instead of panicking" | One guard at N sites = uniform-wrap (~100%); the only real bugs are self-revealing panics the agent finds by testing; fairness forces stating the contract, which directs the agent straight to the fix | petgraph-node-validation |
| **Single-subsystem mechanical transform** | predicate-injection, scope-rewrite, AST-reindex, one-plugin transformer | A well-specified deterministic transform has no retry-resistant FAIR wall; Nova transcribes the spec; needs >=2 hidden-integration walls (findmyway law), a single-subsystem transform has zero | kysely-row-level-scope |
| **Difficulty-from-misdirection** | "the trap is that the obvious approach is subtly wrong" | To be FAIR the meta must spell the canonical form (sort/displacement/order), and spelling it neutralizes the misdirection; fair + hard cannot coexist for a misdirection-only pick | ironcalc-range-displacement |
| **Uniform-wrap** | one local rule applied at many sites; "wrap every X with Y" | One mechanism discharges all walls; ~50% per the model, single-shot-fixed by a smart agent | cel-exhaustive-eval |
| **Saturated-reference port** | java.time / stdlib / SVGO / a popular spec the agent already knows | The agent has the reference semantics memorized; every "new" test is a base-passer or trivially derivable | js-joda-parse-resolver |
| **Correlated-seam transcription** | detailed-spec feature; the hard part has many surface forms (roles x nesting x leaf) but ONE native-helper / architectural decision clears them all | the variants funnel through a shared chokepoint = perfectly correlated; stacking more variants cannot lower the rate; an "acceptable" earlier rate is usually an unfair biter holding it down | participle-precedence |
| **Famous-language-feature lane** (DERIVATIVE, generalises the row above) | a feature every language of this family eventually grows (guards, or-patterns, ranges, exhaustiveness, `@`-bindings, string interpolation, destructuring) in a small ML/scripting language, WHETHER OR NOT the tracker mentions it | the row above blames the ISSUE; the real magnet is the feature's FAME. Dropping the issue-backed half and picking an unticketed sibling in the same lane does NOT help: every author handed the repo looks at the same five things, and their submissions are invisible to any GitHub query. A clean SIX-CHECK is not evidence here | gluon-match-alternatives (dedupe `duplicate` 0.92 against 3 other gluon pattern submissions, after deliberately dropping issue #9 to dodge the narrower class); koto-nested-bindings (overlap `Blocker`, 52.8% of authored lines against an ACCEPTED task, no batch ever run - the hunt rated this class MEDIUM and cleared it on two mitigations, one of which authoring later deleted) |
| **Maintainer-invited, PR-free lane in a competitor-visited repo** (DERIVATIVE — the numeric-library twin of the two rows above) | a scientific / numerical library where the maintainer has said "should be possible, not supported" in 2-3 issues or a discussion, the subsystem is cold, no PR exists, and the repo already shows one merged competitor-signature PR or a prior submission of ours | every hunt signal that ranks the lane first (cold code, invited feature, no PR, reproducible crash on base) is equally visible to every other author, and the platform pipeline is the only place their picks live. Three foreign scikit-fem submissions landed within eleven minutes on 2026-09-06; GitHub queries return clean on all of them. The dedupe compares the CORE (the generalised mapping); bolt-ons (orientation, smoothing, trace tags, guards) are rated incremental by default | scikit-fem-embedded-meshes (dedupe `derivative` 0.79 / conf 0.90, three days after a rival's identical lane; shelved after full authoring + Docker validation) |
| **Repo publishes a support matrix** (DERIVATIVE — the sharpest form of the famous-feature rows above) | the target repo's README/docs carry a conformance or support TABLE of the standard it implements, with rows marked "Planned" / "Partially done" / an empty checkbox (CSS property tables, supported-opcode lists, spec-conformance checklists, "what works" matrices) | the table IS a public, pre-ranked, pre-filtered pick list. Every author handed the repo reads the same rows, and the "Planned" rows are exactly the authorable ones (defined behavior, absent implementation, maintainer-blessed). Collision odds are maximal and GitHub queries cannot see the collision, because the rivals' picks live only in the submission pipeline. **A roadmap row is NOT the maintainer-wants-it mitigation it looks like** — it is the strongest collision tell in the taxonomy, and reading it as fairness comfort inverts the signal | dropflow-min-max-sizing (overlap `Blocker`, 204/290 authored lines = 70.3% against an OLDER same-repo submission; the README's CSS table marked `max-height, max-width, min-height, min-width` as "Planned" and the audit logged that as a *mitigation*) |
| **Maintainer roadmap issue in a small proven repo** (DERIVATIVE — the tracker twin of the support-matrix row) | a small repo whose open issues are the maintainer's own terse to-do list ("implement X", "add opcode Y"), none commented, none with a PR; we already have an accepted pick from the same list | the list is short and every author who opens the repo reads all of it, so each open item is a first-come lane. An accepted pick from item N says nothing about item M: the pipeline holds rivals the SIX-CHECK cannot see. A scope gate that PASSED on the core slice is no protection either — the later re-run compared against an older candidate the first one never surfaced. Being a SUPERSET of the rival (more targets, a second implementation, parity) is read as elaboration, not a new core | cwerg-memory-passed-parameters (overlap `Blocker` after a clean first scope gate; 72/163 rival lines = 44.2%, 72/347 ours = 20.7%; rival = C++-only a64/x64 signature-rewrite pass for issue #3, ours = push/pop lowering on a32/a64/x64 in Python and C++. Same repo list as the ACCEPTED cwerg-bcopy-bzero-lowering, issue #45) |
| **Reverse direction of a one-way converter** (DERIVATIVE, the converter-package twin of the support-matrix row) | a package converts format A to format B only (its README says so, its API is `aToB` / `aToBData`), and the pick is the missing `bToA`, however much selection, escaping or locale machinery the reverse genuinely needs | the reverse of an existing converter is the first thing every author reads off the package's own export list, and it is fully specified by the forward direction plus the round-trip law, so independent authors converge on the same core pipeline (resolve expressions, nest selectors, convert patterns, escape, serialize). Traps, coupled bug fixes and locale depth are rated "additions around that shared core". The hunt gate that softens "outsider-nameable" to a mitigation (09-09-B item 6) does NOT hold for this shape | messageformat-mf2-to-mf1 (overlap `Blocker`, 270/354 authored lines = 76.3% against TWO older candidates that each independently hold the MF2-to-MF1 core; killed at the core-slice precheck, no batch) |
| **Open-but-unimplemented feature request** (DERIVATIVE) | a repo issue asking for a well-known language/spec feature, OPEN for years, zero comments, no PR | the SIX-CHECK reads clean precisely because nobody upstream engaged; but every problem author sees the same issue and picks it, so the prior art lives in the submission pipeline where GitHub queries cannot see it. Uncommented + unimplemented + famous = maximum collision odds | lol-html-sibling-combinators (dedupe `duplicate` 0.91); weasyprint-page-floats (overlap `Blocker`, 156/254 discounted lines = 61.4% and 103/254 = 40.6% against TWO older same-repo submissions, issue #259 open since 2016; rejected after 19 review rounds and one batch) |
| **Scope-lever-doubles-the-collision-surface** (DERIVATIVE) | a pick that needs a SECOND feature bolted on to clear the LOC floor | the dedup engine matches on the CORE task; a bolted-on second feature does not differentiate, it just adds a second independent chance to collide with different prior art. Extras "change scope but not the central lesson" | orb-ring-role-preservation (dedupe `derivative` 0.70; core AND lever AND API each hit different prior art) |
| **Spec-knowable predicate domain** | the feature's semantics are fixed by an RFC / standard the agent can DERIVE from first principles (IP-CIDR containment, date arithmetic, unicode classes, checksum families), and the only remaining work is threading it through the host language | distinct from saturated-reference-port: the agent has not memorised a library, it can simply RE-DERIVE the whole spec, so no fair test can ever split correct implementations. Difficulty collapses onto the WIRING (new enum variant through exhaustive matches, reporters, parser ordering), which is derivable from the repo's own existing variants. A differential harness will find NO fair discriminator | cfn-guard-cidr-operator (5/10 then 6/10 across two batches) |
| **Textbook SQL-standard feature** (DERIVATIVE **or** TOO-EASY — same tell, two death mechanisms) | a named standard-SQL feature in a SQL engine: GROUPING SETS/ROLLUP/CUBE, window fns, CTE/recursive CTE, EXCEPT/INTERSECT, LATERAL, MERGE, PIVOT | the SQL standard fixes both the behavior AND the obvious data model, so independent AUTHORS converge on a near-identical feature core -> platform similarity/dedupe compares the CORE -> >0.90 DERIVATIVE flag (repo coldness does NOT protect; it guards maintainer/issue dedup, not another author picking the same famous feature). The SAME convergence also happens one level down: independent AGENTS solving it converge on the identical implementation because they already know the standard's semantics cold, so contract-stated fairness traps get satisfied as a side effect of implementing the well-known algorithm correctly -> TOO-EASY even with zero prior-art collision. Either way, no packaging change clears it | kitesql-grouping-sets (precheck 93.6%, derivative); gql-window-cumulative-rank (89% aggregate across 5 batches, too-easy — thoroughness-gate convergence, not a dedupe collision) |
| **New value kind in a generic evaluator** (TOO-EASY even when LOC clears — the difficulty twin of the row below) | add a new kind of VALUE (fractions, decimals, a new numeric or scalar type) to an expression evaluator whose symbols, resolver, user functions, conditionals and macro/ruledef arguments all store values generically, plus builtins whose math the description has to state exactly | the generic storage carries the new variant through every other stage for free, so the only real work is the arm itself and a formula the spec must write out to be fair. LOC can be plentiful (a whole rational module) and still no trap exists: a differential harness finds no stage that quietly mishandles the new kind. Any lever whose WRONG version breaks the existing suite is self-revealing, because agents run that suite | customasm-exact-fractional-values (8/8 then 7/8 across two batches, 368 human-eff; 35 fair probes x 16 saved solutions found zero divergence outside the stated formula) |
| **Machinery-absorbed capability** (UNDER-FLOOR, not too-easy) | the repo already owns a primitive that does the hard half of your capability (`Settle`, a generic walker, a resolver, a complete interface, an enum that already IS the identity key you need) and your fix is "call it at N sites" or "add a lookup in front of it" | the correct implementation is a 2-6 line call-through per site, so the whole feature lands far under the 200 effective-LOC floor no matter how many sites there are. Site COUNT does not buy LOC: N thin call-throughs is still thin, and genuine bolt-on companion features that route through the SAME absorbed primitive inherit its thinness rather than escaping it. Estimating "restructure the emission" before checking what the primitive already does overshoots by 3-5x, and trap-seam RICHNESS (F-9/F-10/F-18 all present) does not substitute for missing SIZE | canvas-fill-rule-backends (44 eff vs 200 floor; DESIGN.md sketched 213); iced-x86-pointer-data-dedup (126 eff after 2 genuine expansion rounds vs 200 floor; DESIGN.md sketched 180-220); vrp-initial-clustering-roundtrip (155 eff slice, 168 with every genuine extra; hunt sketched ~260; the loader's `restore()` recomputes all schedules) |
| **Textbook numerical algorithm already implemented in a SIBLING library** (EXCLUSIVITY, cross-repo) | the capability's hard core is a named textbook algorithm (arc-length/Crisfield continuation, and by extension Newmark, return mapping, Gauss-Kronrod, CQC, ...), and ANY public repo in the same language and domain has a working implementation, even with a different data model | the scope gate searches public code ACROSS repos and rules the pick not exclusive when the corrector/root-selection/loop can be cribbed, leaving "primarily integration and policy/status work". Checking only the target repo, its tracker and its parent/reference toolchain is not enough. **Pick-time check:** search GitHub code for the algorithm's signature formula in the language (`gh search code '<formula or function name>' --language=python`) and in the 3-5 nearest sibling libraries (sfepy -> jax-fem, scikit-fem, dolfinx, GetFEM, FEniCS, pyiron). One working hit = dead | sfepy-arc-length-continuation (JAX-FEM `solver.py:595` arc-length engine, 7/15 cases) |
| **Repo is a PORT of a reference tool** (EXCLUSIVITY, repo-level — the strongest form of the row below) | the target repo vendors, ports or reimplements a canonical reference tool (pandapower vendors 69 PYPOWER files carrying PSERC's MATPOWER copyright; 25 more reference MATPOWER) | a port **inherits its parent's ENTIRE feature list as prior art**, so every capability the parent ships is dead in the child — and worse, the child's internal data structures are usually the parent's, so a solver can port the parent's implementation almost line-for-line (saturated-reference-port on top of the scope-gate reject). **Check this ONCE at repo level, not per capability**, and treat the parent's function list as a blocklist | pandapower continuation power flow (MATPOWER ships the whole `runcpf` + `cpf_*` family) |
| **Sibling-ecosystem-tool implements the core algorithm** (EXCLUSIVITY / publicly-solved) | your target library parses/emits one half of a widely standardized binary or text format (SPIR-V, DWARF, ELF, WASM, a bytecode ISA, a protocol wire format) and there exists a separate, often reference-maintainer-published, tool for that SAME format that already performs the algorithm you are about to add | the same-repo GitHub PR/issue search (`CLAUDE.md § Exclusivity`) only ever looks inside the target repo; it cannot see a public implementation living in a DIFFERENT project. Format-standard ecosystems always grow a canonical toolchain (Khronos's SPIRV-Tools/SPIRV-Cross for SPIR-V, `llvm-dwarfdump`/`gimli` for DWARF, `wabt`/`binaryen` for WASM) that agents can be assumed to have seen; if that toolchain already ships your feature's core algorithm as a named pass or function, the Scope Gate rejects on sight, quoting its source, regardless of how much of the target repo's OWN history is clean | rspirv-decoration-group-resolution (SPIRV-Tools' `--flatten-decoration` optimizer pass performs the identical two-pass group-to-concrete-decoration expansion) |
| **Invariant-upkeep clause of a larger feature** (DERIVATIVE, the sub-requirement twin of the rows above) | the pick makes an index or cache that a subsystem already owns stay correct under insert/remove/move (incremental quadtree or R-tree maintenance, count and parent-pointer repair, split/collapse cleanup, cache invalidation), where base keeps it right only after a bulk build | any rival feature on the same subsystem (dynamic entities, live updates, streaming edits) has to add exactly this upkeep as one of its clauses, and it converges: the invariants are fixed by the bulk build, so split, count repair, the duplicate-position guard and pointer upkeep come out line for line the same. The gate reads a clause promoted to a standalone task as the rival's core, and new read-only accessors and stricter invariant tests count as elaboration. A clean SIX-CHECK says nothing, because the rival lives in the pipeline | openglobus-entitycollections-tree-maintenance (overlap `Blocker` at the core slice, 92/197 authored lines = 46.7%, 92/338 = 27.2% of the rival; shelved before picker or batch) |
| **Maintainer-staged plan in a popular issue** (DERIVATIVE, set-level) | a busy, user-bumped issue where the maintainer publicly splits the feature into numbered stages ("1. read/write, 2. recompress, 3. reductions, 4. cropping/dedup"), the first stages shipped and the rest open with no PR | each remaining stage is its own pre-sized pick, so different rival authors take different stages. Building the union does not escape: the gate treats "stitches two older major implementation blocks" as a **set-level derivative** even when no single rival covers half. The welcome and the plan clear Gate 8 and mark the lane at the same time (hunt Stage 2d's worst case) | oxipng-apng-frame-optimization (overlap `Blocker` x3 at the core slice: 181/407 discounted lines = 44.5% against an older APNG-wide reduction submission, 199/407 = 48.9% against an older canvas/cropping one, set-level union ruled derivative; issue #551, open since 2023-08) |
| **Container completion of a just-shipped per-element API** (DERIVATIVE, the release-notes twin of the roadmap rows) | the latest release added an interface to the ELEMENTS of an aggregate (`Copyable` on `Body`/`Joint`, serialisation on nodes, equality on items) and the aggregate that owns them (`World`, the graph, the collection) is the one obvious class left without it; the pick is "do it for the container", however much hidden state (caches, warm-start, broadphase trees, time history) the container really needs | the gap is printed in the changelog, so every author who reads the release lands on it, and the container's state is fixed by the engine, so independent authors copy the same fields in the same places. A stricter contract on top (bit-identical continuation, same event order, placement rules) is judged "tightens determinism and generalizes placement", i.e. elaboration. Zero open issues and a clean exclusivity sweep say nothing: the rival lives in the pipeline | dyn4j-world-copy (overlap `Blocker` at the core slice, 157/297 rival lines = 52.9%, 157/492 ours = 31.9%; hunt had rated it a MEDIUM magnet and leaned on the bit-identity contract as the mitigation) |
| **Reintroduces a capability the maintainer REMOVED** (PUBLICLY-SOLVED, unfixable) | the repo used to ship the capability and a release deliberately dropped it: a changelog/release note saying "X is no longer ...", "removed X", "dropped support for X", often next to a friendly "if you need X, let me know" | the scope gate treats the repo's OWN history as prior art: the removing commit and the release record prove the capability was public, and it rules reintroduction unfixable "regardless of whether the modern implementation uses a new ... mechanism". Corpus overlap, dedupe and every PR/issue query read clean, because the prior art is the repo's past, not a rival. **The invitation beside the removal is not a welcome, it is the removal record.** Pick-time check: grep the changelog and release notes for `no longer`, `removed`, `dropped`, `deprecated` and run `git log -S` on the capability's old API names before scoping | kira-frame-accurate-start-times (precheck `publicly-solved` Blocker on commit 4c29057a and `changelog.md` L102-L124 "Clocks are no longer sample accurate"; 0/206 corpus overlap; killed at the core slice) |
| **Substrate-repair contract** (UNSOLVABLE-UNDER-REVIEW, the opposite failure to every row above) | the correct fix must REPAIR facts the host already records (decoder flags, recorded code flow, a cached IR, a symbol table), and some load-bearing fixture needs an instruction/node that base's substrate never records | agents build on the recorded substrate and do not repair it, so every fixture that depends on a dropped successor fails ~90%+ while its walker-layer twin costs a few runs. Stating the repair makes the test fair and lethal; leaving it unstated makes it an FP hole or a review finding, and a general soundness sentence keeps it in scope even after its specific clause is deleted. **Pick-time test: for each fixture, does base already record what the assertion walks?** | vivisect-noret-propagation (166 runs / 2 genuine passes; every candidate answer to the final review measured 0/21; Solution 3/3 Clean at shelving) |
| **Mock-harness type wall** (UNAUTHORABLE, repo-level) | the repo's test double for its IO/env boundary returns PRE-BUILT typed values and resolves them by EXACT type (`Box<dyn Any>::downcast`, a TypeId/class registry, a mock keyed on the return type) so no deserialization runs in tests, and the pick needs that boundary type to change shape | the capability's input only exists on the wire, so widening the boundary type makes every existing handler fail the exact-type cast at once. `solution.patch` may not repair test files; `test.patch` cannot, because the repair must differ between the base and solution trees; and the SOLVER sees the breakage with no patch to explain it, so ~100% of runs either edit repo tests (`PASS_CHEATED`) or edit the harness and make test.patch conflict. The same property blocks the inverse move: a new test cannot inject wire metadata either. **Pick-time check (one grep): open the test env/mock, look for a cast keyed on the fetched type, and count the sites that build the old type.** Pair it with the serde/golden-token and exhaustive-struct-literal question for every type the pick must extend | stremio-core-resource-freshness (30 `Box::new(ResourceResponse…)` sites in 15 test files against `TestEnv::fetch`'s `downcast::<OUT>()`; killed at scope-lock, no code written) |


### ⭐⭐⭐ RECOGNISER / POST-PASS-OVER-THE-PUBLIC-STREAM (added 2026-09-01-C — killed lyon T1 at the Phase-3 guard, AFTER it had cleared all 10 PICK-FILTER gates)

**Tell at pick time:** the capability consumes the repo's public event/AST/token stream and returns a
value. "Recognise / detect / classify / extract X from a path, an AST, a token stream." It is the
INVERSE-shaped sibling of S-C, and it is the shape that reads most attractively at hunt time because
the gap is easy to demonstrate and the trap material is easy to enumerate.

**Why it is dead.** `failure-patterns.md § 5` lists it verbatim as an anti-target — *"anything a
post-pass over the public event/AST stream can do end to end"* — and it trips Pre-Pick Guard #2
(single-subsystem, fully-specified transform: needs >=2 hidden-integration walls, and a standalone
recogniser has zero). The skill's Phase-3 Step C reject *"solvable by a standalone new file with
minimal wiring"* is the same finding from the other direction. Critically, its traps are
**INDEPENDENT case-analysis details, not interdependent ones**: fixing the curve-form handling does
not surface the winding bug, which does not surface the clamp bug. That is L2/L3 dead — a smart
agent single-shot-fixes each one.

**The case (lyon, nical/lyon, 2026-09-01).** `to_rounded_rectangle` / `to_ellipse` in
`lyon_algorithms`, inverting the path builder's own `add_rounded_rectangle` / `add_circle` /
`add_ellipse` emitters, alongside the existing `to_axis_aligned_rectangle` (rect.rs, ~170 eff,
sharp rects only). It cleared **every mechanical gate**, unusually well:

- Gate 1 reproduced on base: `to_axis_aligned_rectangle(rounded_rect)` returns `None`.
- Gate 5: `rect.rs` has **2 commits ever**; the whole repo has **zero open PRs**.
- Gate 7b: every feature-class search empty against live positives; the PR that added rect.rs
  (#768, body "Inspired from skia.", zero comments) is sharp-rects-only.
- Gate 8 positive: nical calls `lyon_algorithms` the home for path utilities.
- Gate 9: 158 tests, 3 byte-identical runs. Gate 10: 3 of 6 quota.
- Sibling-ecosystem check passed for a MECHANICAL reason: Skia's `isRRect`/`isOval` read flags
  cached at construction, so only `isRect` walks the verbs and nical had already ported that one;
  lyon's `Path` carries no such flag (`grep -rniE "is_rect|is_oval|shape_hint|cached_shape"
  crates/path/` = 0), so the shortcut is structurally unavailable.
- Trap material was MEASURED on base, not predicted: `add_circle` emits 4 cubics with
  `CONSTANT_FACTOR = 0.55191505` while `add_ellipse(r,r)` emits 8 quadratics (one circle, two
  public-API emissions — a real F-18 parity cell); the ellipse form does not close exactly
  (50.000004 vs 50.0); radii clamping is four sequential pairwise clamps so round-trip is a fixpoint
  oracle; an asymmetric case emits a **zero-length** `Line { from: (50,0), to: (50,0) }`; zero-radius
  corners emit no curve and the OLD recogniser already accepts an all-zero rounded rect; winding
  flips both the start point and the corner order.

**None of that saved it.** Every gate in `PICK-FILTER.md` and every trap in the F-catalogue can pass
while the pick is still structurally a standalone post-pass. ⭐ **The gates measure whether the pick
is AVAILABLE; they do not measure whether it is COUPLED.** Difficulty structure is a separate axis
and it is checked in Phase 3, not in the hunt.

**LAW.** A recogniser over a public stream is dead at Olympus however rich its case analysis, because
(a) it is a standalone module with no integration wall, and (b) its traps are independent, so they
are single-shot-fixed rather than compounding. Do not rescue it by bolting on a consumer — that is
the scope-lever-doubles-the-collision-surface class one row up. **Pivot the FEATURE.** What survives
instead: one shared kernel driving many surfaces, where a local fix to one surface REGRESSES another.

**Corollary for the hunt.** `olympus-hunt` ranks on repo cleanliness (cold lane, no open PRs, no
competitor). That correctly finds where you are ALLOWED to author, and says nothing about whether the
capability is globally coupled. Run the Phase-3 guard on the hunt's RANK 1 before believing it.

### ⭐⭐⭐ MISSING-ARM-OF-A-DISPATCH (added 2026-09-01 — the pick-time TELL for machinery-absorbed; 2 repos killed back-to-back)

Sharper, EARLIER tell than the existing "Machinery-absorbed capability" row. That row asks whether
the repo owns a primitive that does the hard half — a question you can only answer after reading the
primitive. This one is visible at pick time from the SHAPE of the capability:

**⚠️ CORRECTED same day by the corpus extraction in `CAPABILITY-SHAPES.md` — the rule as first
written was too strong.** `icu4x-zerotrie-cursor-parity` and `calamine-defined-names` are both
missing-arm picks and both were APPROVED. The discriminator is not the phrasing, it is **whether the
arms share machinery**: if the surrounding engine is GENERIC it absorbs the new arm (dead); if the
engine is a facade over per-arm implementations each needing different traversal/parser/solver work,
the arm is real content (alive — see `CAPABILITY-SHAPES.md § S-I`). Read the rest of this entry with
that qualifier.

**If the capability can be phrased as "add the missing X arm to a thing that already handles A, B and
C" AND the machinery behind A, B and C is shared, it is absorbed by construction.** The framework around the dispatch is what does the work; that
is exactly WHY the arm is small, and why nobody has bothered to add it. Sites where this shows up:
kind-dispatch `if/else if` chains on a type tag, plugin/policy registries, visitor interfaces,
`register*Handler` callback tables, per-variable-kind or per-node-kind switches.

**Measured back-to-back, both killed at Phase 2/3 before any code:**
- **geometry-central** (`MutationManager`): propagate constraint flags through every mutation kind,
  not just edge split. `MeshData` already owns the expand/permute/delete callbacks, so only value
  semantics were missing. Clean arms totalled well under 200 eff LOC.
- **choco-solver** (search machinery): make `GraphVar` first-class where `IntVar`/`SetVar`/`RealVar`
  already are. Real, citable gaps — `GraphVar.getDomainSize()` throws
  `UnsupportedOperationException`, `GeneralizedMinDomVarSelector` throws `"unrocognised variable
  kind"` on GRAPH, `NogoodFromRestarts.asLit()` handles `IntDecision`/`SetDecision` only,
  `Literalizer` has `BoolLit`/`IntEqLit`/`IntLeLit`/`SetInLit` and no graph literal. Every arm sized
  against its existing Set twin: `SetRandomNeighbor` 40 eff, `MaxDelta`/`MinDelta` 22 each,
  `SetInLit` 58. **Clean-arm total ~130 eff LOC vs the 200 floor**, and the two arms big enough to
  matter were both contested (`Solution` claimed by maintainer in #1053 "I can take time to do it";
  the `Literalizer`/nogood arm sits in the LCG lane, `sat/MiniSat.java` + `ArrayClause.java` +
  `SatDecorator.java` all under open PRs).

**⭐ The hunt-heuristic error this exposes.** Ranking candidates on *cold + large + no open PRs*
selects for **FINISHED** subsystems. A lane is cold precisely because it is done, and a done lane's
remaining gaps are the ones too small for the maintainer to have bothered with. Both picks above were
top-ranked by that heuristic and both were absorbed.

**What the approved corpus actually looks like** (checked against `approved-problems/README.md`,
2026-09-01): the accepted picks are net-new capabilities requiring an ALGORITHM the repo does not
contain — calyx "whole-program dataflow pass, cross-subsystem" (925 eff), customasm "decode assembled
bytes back to instructions using the repo's own ruledefs" (493 eff, an INVERSION of the assembler),
acoular "image-source path enumeration with occlusion, wired into the steering vector, four source
models and the time-domain beamformer" (438 eff), neva "generalise the array-bypass so every form an
ordinary connection supports works for it too" (6 files / 4 subsystems), rust-minidump "a trust-
accounting layer for the stack walker". None of them is a missing arm; in every case the LOC lives in
NEW domain logic and the difficulty lives in integrating it.

### ⭐ SHARPENED 2026-09-01-C after a THIRD absorption death (thermo) — NEW CONTENT vs NEW CASE

"Name the algorithm" was still too weak: on thermo I named one (multicomponent solid-liquid
equilibrium), it was genuinely absent, the lane was unclaimed, and the pick was STILL absorbed. The
guard at `flash_vln.py:168` (`raise ValueError("Solids are not supported in this model")`) reads like
a hard F2P gap; monkeypatching it away in a container showed the flasher constructs fine and then
silently reports `skip_solids=True`, returning one liquid phase for water/methanol at 200 K. The
multiphase engine is already phase-AGNOSTIC — `sequential_substitution_NP` only calls
`phase.to_TP_zs()` / `phase.lnphis_at_zs()`; Michelsen stability testing is composition-based; the
solid phase model `GibbsExcessSolid` is 32 lines reusing the liquid one — so the work was wiring
solids into the candidate-phase set, not new mathematics.

**The sharper test: does the capability introduce new DOMAIN CONTENT, or a new CASE of content the
engine already handles generically?**

- **NEW CASE (dead):** another phase type for a phase-agnostic flash; another variable kind for a
  kind-dispatch; another node type for a generic visitor; another backend for an existing interface.
  A generic engine absorbs new cases by design — that is what "generic" means.
- **NEW CONTENT (alive, and what the whole approved corpus is):** a physical effect the repo does not
  model (acoular's specular reflection with occlusion), an inversion of an existing direction
  (customasm decoding assembled bytes back to instructions), an analysis that did not exist (calyx's
  whole-program dataflow pass), a property the format must now preserve (gluon's comment-preserving
  idempotent formatter), a new mode over shared state (afero's deletion-tracking union filesystem).

**The three-strike pattern.** geometry-central (missing arm of a callback table), choco-solver
(missing arm of a variable-kind dispatch), thermo (missing case of a phase-agnostic engine). All
three had rich seams, cold lanes, clean exclusivity and a citable throw/refusal. **A `raise
NotImplementedError` / `ValueError("X not supported")` is a MAGNET FOR THIS MISTAKE**: it looks like
proof of a gap, and it is usually proof that the surrounding engine is generic enough that nobody
needed the case.

**Cheapest decisive probe, ~1 hour:** delete the guard and nothing else, then run the feature. If it
constructs and silently no-ops (or nearly works), the engine is generic and the pick is wiring. Do
this BEFORE the seam audit, not after.

---

**Pick-time test to apply:** name the algorithm the capability needs that the repo does not already
contain — an enumeration, an analysis, an inversion, a reconstruction, a solver. If the honest answer
is "none, it reuses what is there and plugs it into one more slot", the pick is dead at the LOC floor
regardless of how good its trap seams look. Seam richness does NOT substitute for missing SIZE.

---

**The unifying law (3x confirmed: petgraph, kysely, ironcalc):** difficulty and fairness pull in opposite directions for a single-subsystem, well-specified feature. The fairness gate forces you to state the contract / canonical form / rule; stating it hands the agent the answer. Genuine hardness must come from depth that SURVIVES full specification (cross-subsystem integration timing, a genuinely-new load-bearing algorithm, an interdependent multi-stage pipeline), never from a trap that only works while the spec hides something.

---

## vrp-initial-clustering-roundtrip (Rust, SHELVED 2026-09-23 - machinery-absorbed UNDER-FLOOR, killed at the core slice)

**Repo:** reinterpretcat/vrp (508 stars, base `e49bee0e`), hunt RANK 1 of
`repo-hunt-logs/REPO-HUNT-2026-09-23-I.md`. **Lane:** make pragmatic initial solutions work for
vicinity-clustered problems: `read_init_solution` reads back the clustered stops (parking, commute) the
writer emits, and the solver maps a supplied initial individual onto the clustered job registry that
`VicinityClustering::pre_process` swaps in (the F-9 stage boundary at `rosomaxa/src/evolution/simulator.rs:63`).

**Everything the hunt measured was true.** Both gaps reproduced at base: the reader refuses the solver's
own clustered output ("commute property in initial solution is not supported"), and an unclustered
initial solution comes back fully unclustered after 0 or 200 generations. SIX-CHECK, exclusivity and
fork-branch scans were clean; the one-day 2021 commute passthrough was never released.

**Killed by size, measured on a working slice.** Reader inversion of clustered stops + open-shift start
fix + translation of initial individuals + a defaulted rosomaxa hook: **155 human-effective**, 8 tests
green. Required breaks (the only other genuine reader gap) prototyped to **168** in total. The hunter
sketched ~260. Every item the sketch priced as work was absorbed: `Commute::to_domain` already parses
the writer's commute; `get_extra_time` already undoes break extension; `InsertionContext::restore`
recomputes every schedule, so the translation needs no schedule arithmetic at all; the hook is six lines.
The one piece of real extra depth (required breaks inside a clustered stop) is blocked by a pre-existing
writer quirk (members written as served during the break), so stating a read-back law over it would pin
a base bug.

**Law.** A lane whose correctness is checked by a recompute-on-load engine (here: `restore()` rebuilding
schedules) only needs to get IDENTITY right, not arithmetic. Before sketching LOC for a "read back /
translate into the internal model" lane, check what the loader recomputes; every recomputed field is a
line item that costs nothing. Also: a 0-generation solve with one initial solution is a deterministic
end-to-end oracle in this repo, which is worth reusing on any future vrp lane.

Artifacts: `rejected/vrp-initial-clustering-roundtrip/` (DESIGN.md, meta.md draft, both patches,
Dockerfile, fixtures in test.patch). Tooling and probes: `worktrees/_vrp_probe/`.

## messageformat-mf2-to-mf1 (TypeScript, SHELVED 2026-09-19 - DERIVATIVE, overlap `Blocker` 270/354 = 76.3%)

**Pick:** `messageToMF1(locale, msg)` in `@messageformat/icu-messageformat-1` (MF2 data model to ICU
MF1 source, round-trip equal under `mf1ToMessage` for sparse variant lists, locale-valid plural
keys), plus two pre-existing bugs found while building the round trip: `mf1ToMessageData` produced
empty variants when a nested statement listed fewer cases than its siblings (a=p, b=x gave `""`
where `@messageformat/core` gives `B`), and MF2 `selectPattern` looped forever when backtracking
reached a selector already on its catch-all (3+ selectors). Hunt 09-19-D RANK 1.

**Verdict (core-slice precheck, Step 4b):** *"270 of 354 authored subject lines (76.3%) re-deliver
an older MF2-to-MF1 converter core already present independently in each of two older candidates
... resolving MF2 expressions and declarations, nesting sparse selectors, converting patterns,
escaping text, and serializing MF1. The subject's locale-sensitive synthesis and two selection
repairs are additions around that shared core."*

**Why the audit could not see it.** Exclusivity was clean on every instrument outside the platform:
PRs/issues in all states on the canonical org, `git log --all -S` for the API names, changelogs, all
branches, GitHub code search (one 0-star naive PGS-to-MF1 serializer, logged as a risk). The hunt
log itself had flagged the lane as "outsider-nameable (reverse of mf1ToMessage)" and kept it on the
softened-gate reading that nameability is a mitigation. Two rivals had already taken it.

**What went right.** The precheck law was followed this time: the slice (287 human-eff, 10 tests,
clean-room Docker) went up before the full suite, the generated corpus or any hardening round, so
the Blocker cost one authoring session and no batch, where dropflow and koto cost full cycles.

**Salvage.** None as a standalone pick: the two bug fixes are ~27 human-eff together and the
reverse converter they were bundled with is the consumed core. The repro facts are recorded in the
problem's `feedback.md` under `rejected/` in case a different lane in this repo needs them.

**Law:** when a package's own export list shows a one-way converter, the reverse direction is a
shared pick, not an invented one. Treat "outsider-nameable" as fatal for this shape and precheck it
before anything else, exactly as done here.

**Repo verdict:** messageformat's MF2-to-MF1 lane is CONSUMED (two older candidates). Other
converter directions in the same monorepo (Fluent, XLIFF) carry the same reverse-direction magnet.

## kira-frame-accurate-start-times (Rust, SHELVED 2026-09-18 - PUBLICLY-SOLVED, removed capability)

Core slice (173 eff, 25 tests, clean-room and Docker green) making static and streaming sounds start
on the exact frame their clock time or delay is reached inside an internal buffer. Precheck:
`publicly-solved` Blocker. kira 0.10 replaced per-frame processing with buffered processing (commit
4c29057a) and its changelog says "Clocks are no longer sample accurate ... if you find yourself needing
sample-accurate clocks, let me know!". The gate: "reintroduction of a capability maintainers removed
[is] unfixable, regardless of whether the modern implementation uses a new buffered-compatible
mechanism." Overlap with other submissions was 0 of 206 lines.

**What went wrong in the method.** The hunt quoted the changelog paragraph as a maintainer-welcomed
lane (Stage 2d), and authoring found two public maintainer branches with the old per-frame design and
filed them as mitigable prior art because they were never PRs. Both readings were wrong for the same
reason: the evidence showed the capability had EXISTED in this repo, and the gate counts the repo's own
past as public prior art.

**Law.** A lane that restores something a release removed is dead at pick time, whatever the new
mechanism and however warm the maintainer's note. Check the changelog for removals before reading it
for invitations.

## customasm-exact-fractional-values (Rust, SHELVED 2026-09-18 - 8/8 then 7/8, GENERIC-EVALUATOR ABSORPTION)

**Repo:** hlorenzi/customasm (base a45db8ff). Feature: exact base-10 fractional literals held as
reduced rationals, plus `$whole`, `$fract`, `$exponent`, `$mantissa` (normalize, round the remainder
to N bits ties-to-even, carry into the exponent), exact `==`/`!=` across fractions and integers, and
in round 2 exact `+ - * /` on fractional and mixed operands with integer division still truncating.
Fully authored and validated: 368 human-eff over 10 files, 61 tests, clean-room green, flake-free,
three Auto Review rounds cleared (Description 3/3, Solution 3/3 at the end).

**Batches.** Batch 1 (50 tests): **8/8 Nova pass**, median 61 requests, FP clean. Batch 2 (61 tests,
arithmetic lever): **7/8**. The single kill in 16 runs was a transcription error in the stated
normalization formula (remainder not divided by 2^e for values >= 1). The arithmetic lever killed 0.

**Why the arithmetic lever died.** Its natural wrong version (a promotion arm placed ahead of the
integer arms) breaks 103 EXISTING tests at once. Agents run the base suite, so that failure is the
loudest signal in the workspace, not a misdirecting one. Law: a trap whose wrong version reds the
existing suite is self-revealing; it can only be counted as fairness, never as difficulty.

**Why nothing else could work — measured, not argued.** Two differential harnesses over all 16 saved
solutions on clean BASE checkouts:
- 25 cross-stage probes (symbols, forward references, chains that change type between resolver
  passes, `#fn`, `#if`/`#else`, `#const`, `$` and label arithmetic, local labels, `#ruledef` operands
  single/negative/two-argument/forward/cascaded, `#subruledef`, a width taken from a later symbol):
  **0 divergence** from the reference among batch-2 solutions. customasm stores every value
  generically, so the new variant flows through every stage without any agent touching it.
- 10 kernel edge probes checked against an independent Python oracle (1e-30 and 1e30 magnitudes,
  carries at negative exponents, a carry from a negative value, an exact tie and a just-above-tie at
  60 bits, a 200-bit mantissa of 0.1, ties produced by arithmetic): **every passer matched**. The
  only divergence was the run that already failed.

The formula is the one remaining seam, and it cannot be hidden: Auto Review asked for the
normalization sentence to be made MORE explicit, and it was.

**Tell at pick time.** "Add a new kind of value to an evaluator" is the missing-arm shape; check
whether the evaluator's surroundings store values generically (a `Value` enum threaded through
symbol tables, the resolver and macro arguments). If they do, the arm is absorbed and the task is
the formula, which fairness forces you to state. The pick cleared the LOC floor, so the
machinery-absorbed row (an UNDER-FLOOR death) did not catch it; the new taxonomy row above does.
Artifacts in `rejected/customasm-exact-fractional-values` (fully validated; reference only).

## sfepy-arc-length-continuation (Python, SHELVED 2026-09-17 - PUBLICLY-SOLVED, scope gate Blocker)

Core slice (205 eff, 15 tests, clean-room green) of a `ts.arc_length` solver. Scope gate: publicly
solved by JAX-FEM (`deepmodeling/jax-fem` `jax_fem/solver.py:595`, commit ee8c06e), which ships the
arc-length corrector, quadratic root and alignment choice, continuation loop, step cap and exact-target
polish, covering 7 of 15 graded cases. Corpus overlap was only 1.9% against the older sfepy task, so the
platform's "25 submissions by 6 contributors" reuse warning was NOT the problem.

**Law.** Every GitHub gate in the hunt (canonical-org PR search, issues, source grep, port check, reference
toolchain) looked at sfepy or its domain's reference tool. None looked at SIBLING libraries in the same
language. For a named textbook numerical algorithm, a sibling library's implementation is prior art even
with a different data model, because the gate treats the numerics as the hard part and the sfepy wiring
as integration. Pick capabilities whose hard part is the TARGET REPO'S OWN MODEL, and run a
cross-repo code search for the algorithm's signature before building.

## weasyprint-page-floats (Python, SHELVED 2026-09-15 - DERIVATIVE, overlap 61.4% + 40.6%)

**Pick:** Kozea/WeasyPrint issue #259 (CSS Page Floats, `float: top | bottom`), open since 2016, never
implemented upstream. Olympus, full authoring arc: 19 review rounds, one 10-Nova batch (0/9 graded pass at
full scope, 501 eff), then narrowed to page floats only (301 eff, 75 tests, clean-room validated, Solution
Quality 3/3 comprehensiveness) before the reject.

**Reject:** overlap `Blocker` x2. An older same-repo submission covers 156/254 discounted subject lines
(61.4%; 156/303 of its own work), a second covers 103/254 (40.6%; 103/231). Both implement the same engine:
page-edge float collection, placement, stacking, fit-deferral and page re-layout. Upstream never shipped or
declined page floats; Vivliostyle `page-floats.ts` (31/75 cases) and PagedJS fragmentainers `page-float.js`
(4/75) were logged as partial public precursors only. The reviewer said policy and integration differences
(narrowed rules, nested multicol, flex/grid handling) "do not restore corpus novelty".

**ROOT CAUSE:** the open-but-unimplemented row again. A famous, years-old, maintainer-tagged layout feature in
a popular Python PDF engine is the first thing every author handed WeasyPrint looks at. The SIX-CHECK was
clean (no PR, no decline, no post-base commit) and could not see the two rival submissions, which live only
in the pipeline. Narrowing the scope made it worse on paper: cutting column floats and integrations removed
our own distinct lines and left the shared core as a larger share of what remained.

**Reusable law:** when the pick IS a named spec module the target engine lacks (CSS Page Floats, Regions,
Exclusions, GCPM features), assume another author already holds its core. Scope cuts after an overlap flag
cannot help, because the dedupe measures the core. Decide exclusivity before authoring, not after the batch.

**What was salvaged:**
- `rejected/weasyprint-page-floats/` keeps the narrowed artifacts and batch-1 runs; the full-scope version
  and the clean-room cell harness live in `worktrees/weasyprint-tools/` (`full-scope-backup/`, `cell.sh`,
  `gen_patches.py`), which is git-ignored.
- Measured failure shape for re-layout traps: 8/9 Nova runs deferred a late-found page float to the next page
  instead of laying the current page out again (F-1 shape), and 45 tests died in every run.
- The WeasyPrint `tests/draw` suite fails locally without HarfBuzz-Subset ("1 errors logged"); only the
  container result counts for that repo.

## gluon-match-alternatives (Rust, SHELVED 2026-08-07 - DERIVATIVE, AI dedupe `duplicate` 0.92)

Not too easy. Fully built, hardened, reviewed, locally green (426 base / 91 new, 3x deterministic,
277 effective LOC, 16 files). Killed by the dedupe engine against FIVE prior candidates, three of
them gluon pattern-matching submissions by other authors.

| Candidate | Verdict | Sim | What it was |
|---|---|---|---|
| 1 | **duplicate** 0.92 | 0.774 | gluon guards + or-patterns, same external semantics |
| 5 | **derivative** 0.87 | 0.698 | gluon guards + or-patterns + range patterns |
| 3 | adjacent 0.82 | 0.726 | gluon guards (parenthesised guard syntax) |
| 4 | adjacent 0.78 | 0.705 | Rune or-patterns + ranges + @-bindings |
| 2 | distinct 0.90 | 0.753 | or-pattern AST node only, different repo |

**The judge's own words:** "Differences are internal representation and staging, not behavior, so
they teach the same debugging lesson."

## Why the differences could not be worked

All five listed "meaningful differences" are exactly what `CLAUDE.md § Derivative / Similarity
Warning Response` names as anti-patterns:

- `Alternative.guard: Option<Expr>` vs `Pattern::Guarded(pat, expr)` -- internal representation.
- `@`-over-or distributed at parse time vs at codegen -- staging.
- A dedicated `OrPatternBindingMismatch` vs a generic `TypeError::Message` -- API surface rename.
- Layout: closing the `If` context on `->` vs never opening one -- internal.
- `translate_guarded` vs threading guards through `Equation` -- internal.

None is a behavioral difference. Reworking any of them is the "rename the API surface" and
"reword meta.md" anti-pattern, and contesting a dedupe verdict on staging grounds burns reviewer
credibility the same way contesting an exclusivity reject does.

## ROOT CAUSE -- the magnet is the FEATURE'S FAME, not the issue tracker

This pick was chosen specifically to DODGE a derivative magnet. The ancestor
(`rejected/gluon-match-guards`) bundled exhaustiveness checking, which is gluon issue #9: open
since 2015, zero comments, no PR, famous feature -- the textbook
"Open-but-unimplemented feature request" death class. I dropped exhaustiveness for exactly that
reason and pivoted to guards + binding or-patterns, which have **no gluon issue at all**.

It made no difference. Three other authors had already submitted gluon pattern-matching work.

**The refinement this entry exists to record:** the death class is stated in terms of an open
issue, and that framing is too narrow. The magnet is not the issue, it is the FEATURE being a
famous one every language eventually grows. Guards, or-patterns, ranges, exhaustiveness and
`@`-bindings are the five things every author looks at when handed a small ML-family language,
whether or not the tracker mentions them. A clean SIX-CHECK proves nothing here, because prior art
lives in the submission pipeline where no GitHub query can see it.

**Operational rule:** before authoring a language feature, ask "would a competent author handed
this repo and told to add a language feature arrive here?" If yes, the lane is contested no matter
what the issue tracker says. Prefer subsystems nobody frames as a language feature: optimizer
passes, dataflow, name resolution internals, tooling output.

## What was salvaged

Two genuine gluon bugs found while building it, both real and both would have shipped:

1. `cargo build --workspace` (what the Dockerfile runs) failed on `repl/src/repl.rs`.
2. `w @ (A n | (B n | D n))` panicked with `ICE: Or-pattern survived pattern expansion`.

Plus the Dockerfile survey (all six approved Rust references) that produced the version-pinned
`cargo2junit`, `--locked`, and `chmod -R a+rwX /opt/cargo /opt/rustup /app` shape, and the finding
that `olympus-base-rust` keeps its toolchain in `/opt/cargo`, not `/root/.cargo`.

Keep for reference only. Do not submit. Do not re-pick anything in gluon's pattern-matching lane.

---

## koto-nested-bindings (Rust, SHELVED 2026-09-10 - DERIVATIVE, 258/489 lines = 52.8% overlap)

**Killed by:** platform overlap check, verdict `Drop` / `Blocker`, against an OLDER **accepted** Koto
task by another author that "already supplies the central nested/rest binding machinery for
assignment, `let`, and `for`". 258 of our 489 authored lines correspond (52.8%). The report adds:
"The new extraction policy, middle-rest behavior, and catch/export integrations extend that core but
do not establish an exclusive task." No upstream or repo-scope blocker was found - the SIX-CHECK,
the exclusivity PR-DIFF check and every repo gate were clean and stayed clean. **No batch was ever
run; the kill landed at precheck.**

**What was built:** nested tuple patterns and rest captures at every binding site (plain assignment,
`let`, `for` args, `catch` args) through one compiler kernel `compile_unpack_targets` with iterator
semantics and null-fill, plus a new `IterUnpackRest {result, iterator, keep}` op threaded through
op/instruction/reader/vm, parser binding arms, an expression-list rest hook and tuple-target
validation. 358 human-effective LOC across 6 files (parser / bytecode / runtime), 51 tests, 13/15
mutations killed with both survivors deleted as redundant, Docker validated (base 1099 pass x3, new
51 fail-on-base / pass x3), workspace suite green. Artifact quality was not the problem.

**ROOT CAUSE 1 - the death class was already in this file and named the exact feature.** The
`Famous-language-feature lane` row of the taxonomy above lists "destructuring" verbatim, in "a small
ML/scripting language", "WHETHER OR NOT the tracker mentions it", and warns that a clean SIX-CHECK is
not evidence there. koto is a small scripting language and the pick was nested destructuring. The
hunt's Gate 8 did see it - the dossier reads `Derivative: "nested destructuring" is nameable
(JS/Python) - MEDIUM` - and cleared it on two mitigations instead of treating a named dead class as a
kill.

**ROOT CAUSE 2 - both mitigations were void, and one was deleted during authoring.**
- *"Mitigate by phrasing on koto's own model (`BindingContext`, temp-tuple vs iterator RHS, null-fill
  contract)."* Phrasing is not a mitigation. The dedupe compares IMPLEMENTED SURFACES; every judge in
  this class (numbat, skfem, gluon, orb, now koto) uses the same sentence about extras being
  incremental to a shared core. A description rewrite cannot move a 52.8% line correspondence.
- *"Mitigate by the middle-rest lever, which no mainstream language has in that exact form."* That
  lever was **dropped in round 2** because middle-position rest in `match` / function args superseded
  the repo's own `compile_failures::match_ellipsis_out_of_position` test (L31). The one differentiator
  the hunt had banked on was removed, and the derivative risk was never re-assessed. It stayed MEDIUM
  on paper while the artifact had become the bare famous-feature core.

**ROOT CAUSE 3 - the precheck law from the day before was not applied.** `scikit-fem-embedded-meshes`
died the previous day and produced the law "upload meta.md + the first compiling core slice to the
platform precheck BEFORE any hardening". koto's round-1 kernel (`compile_unpack_targets` + assignment
/ `let` / `for`) IS the 258 corresponding lines. Precheck at that point would have fired the same
Blocker before round 2's lever surgery, the mutation sweep, the Docker build and the 3x flakiness
gate. Precheck fires no batch and costs no tokens.

**Reusable laws:**
1. A candidate matching a named row of the Death-Class Taxonomy is REJECTED at pick time, not
   mitigated. "MEDIUM, mitigate by X" against a dead class is how the class keeps killing picks.
2. If authoring DROPS the differentiator the hunt named as the derivative mitigation, the pick has
   reverted to the bare dead class. Stop and precheck at that commit, or drop the pick.
3. Rephrasing on the repo's own vocabulary is never a derivative mitigation. Only a different
   load-bearing core is.
4. `Drop` / `Blocker` on line-correspondence is not contestable. 52.8% of authored lines matching an
   ACCEPTED task means the exclusivity is spent, and every bolt-on is incremental by construction.

**Do not re-author.** Not the `catch` binding site alone, not the export walk, not the iterator /
null-fill extraction policy as its own pick, not middle-position rest. The binding-pattern capability
in koto is consumed by an accepted task. Repo lane ledger: `SATURATED-REPOS.md § B2-KOTO`.

---

## scikit-fem-embedded-meshes (Python, SHELVED 2026-09-10 - DERIVATIVE, AI dedupe 0.79 / 90% conf)

**Killed by:** platform LLM dedupe, verdict `derivative`, against an OLDER submission by another
author implementing the same capability in the same repo, authored 2026-09-06 04:34 UTC. Our hunt
scope-locked the lane on 2026-09-09 and the artifact was finished on 2026-09-10. Four other
candidates (MeshHybrid, curved second-order meshes, wedge multifacet assembly, our own approved
hanging-nodes) all came back `distinct` at 0.61-0.66; the local dedup against our corpus was accurate
and, as with numbat, could not see the pipeline.

**What was built:** meshes embedded in a higher-dimensional ambient space. Rectangular Jacobians in
both mappings (Gram-determinant measure, pseudo-inverse gradients, ambient-shaped `F`/`invF`),
`is_valid` accepting extra rows, `from_meshio`/`load` keeping non-zero trailing coordinates,
finders through inverse mapping with closest-inside-candidate selection, orientation propagation
by neighbour chains (simplex + quad, Moebius raises), induced normals `n` in `CellBasis`, tangential
`smoothed`, `trace` default type + boundary-tag subdomains, `ElementGlobal` guard. 241 effective LOC,
11 files, 81 tests, 23/23 mutations killed, Docker validated 3x. Test Fairness pass returned OK on
leakage, behaviour focus and sanity. Artifact quality was not the problem.

**The prior art shares EVERY core surface.** The judge's list: ambient x refdim `A`/`B`, Gram
measure for non-square `J`, pseudo-inverse so gradients become tangential, isoparametric `F`/`DF`/
`invF` in ambient shape, `is_valid`, `trace` keeping coordinates, `element_finder` on embedded lines
and triangles, the trailing-zero strip rule, `CellBasis.normals` (quarter-turn / cross product). The
rival ALSO ships `MeshLine2`, meshio `line3` and higher-order trace. Our five differences (tangent-
space smoothing, `ElementGlobal` guard, quad `orientation`/`oriented` + BFS propagation, finder
selection, trace tags) were rated "incremental to the shared core and do not change the primary
lesson". That is the numbat verdict word for word.

**ROOT CAUSE - the hunt's ranking signals ARE the collision signals.** The dossier ranked this lane
first on: `skfem/mapping` 0 commits / 12 months; no PR ever; maintainer invited it in #1076, #1121
and D#1039 with no design; Gate 1 reproduced a crash on base. Each of those is a reason a rival
author picks the same lane, and the repo was already marked competitor-visited (one merged
competitor-signature PR). The 2026-09-09-B gate softening let the pick through on exactly this
profile; the softening was correct for maintainer-owned risk and blind to pipeline risk. The
gluon law ("the magnet is the feature's fame") holds for numerical libraries too: surfaces in
space, hybrid meshes, curved geometry and wedges are the four things every author looks at when
handed an FEM library, and three of them were taken in one sitting.

**What would have caught it earlier, for free.** The mapping-only slice (round 1, 135 effective
LOC) already contained every one of the nine shared surfaces. Uploading THAT slice to the platform
for precheck would have fired the plagiarism step before rounds 2-3 (the LOC expansion), the
mutation sweep, the Docker build and the 3x flakiness gate. Precheck does not fire a batch and
costs no tokens.

**Reusable laws:**
1. Run the platform precheck (upload meta.md + the first compiling reference patch + a stub
   test.patch) as soon as the CORE slice exists, before any hardening or LOC expansion. The dedupe
   matches on the core, so the core is all it needs.
2. In a repo with any competitor signature, "maintainer invited it + no PR + cold subsystem" is a
   race you have probably already lost; rank such lanes BELOW an uninvited one, not above.
3. Do not contest. The rival is older, ships a superset of the core, and the judge names bolt-ons
   incremental by default.

**Do not re-author.** Not as a curve-only slice, not with Laplace-Beltrami operators on top, not
with a different orientation algorithm. The embedded-manifold capability in scikit-fem is consumed,
and the repo itself is now on the AVOID list (`SATURATED-REPOS.md § B2-SKFEM`).

---

## numbat-const-exponents (Rust, SHELVED 2026-08-06 - DERIVATIVE, AI dedupe 0.74 / 89% conf)

**Killed by:** platform AI Dedupe, verdict `derivative`, against an OLDER submission by another
author implementing the same capability in the same repo.

**What was built:** compile-time constant expressions as dimension exponents - a `DimensionExponent`
AST replacing the concrete `Exponent` in `TypeExpression::Power`, a parser for identifiers/unary
minus/parens/arithmetic with literal folding, a `ConstantEnvironment` in the typechecker populated on
let-binding, `evaluate_const_expr` gaining that environment, registry error surface extended. 257
effective LOC, 10 files, 34 tests, base 227 green, flakiness 3/3, four reproduced traps. Artifact
quality was NOT the problem - the Test Fairness pass returned OK on leakage, behaviour focus and
sanity.

**The prior art shares EVERY core surface.** The judge's own list: Power carrying an exponent AST;
the dedicated exponent parser with identifiers and precedence; `evaluate_const_expr` taking a
constants environment; the typechecker constants map; the registry exponent-error surface; and the
same test behaviour `let x=2; a^x`. My five differences (evaluate in the registry vs the typechecker,
`InvalidExponent` vs `UnresolvedExponent`, rebinding-removal policy, pretty-print fallback, an exact
decimal-to-rational path) were rated INCREMENTAL, not a distinct behavioural slice.

**⭐ ROOT CAUSE - an in-source TODO is a MAGNET, not repo-internal knowledge.** The pick came from
`// TODO: if we add ("constexpr") constants later, it would be great to support those in exponents.`
sitting in numbat's own typechecker test file, plus a dedicated fixture
(`examples/typecheck_error/unsupported_const_eval_expr_variable.nbt`) whose entire purpose is
asserting the capability does not exist. I reasoned explicitly that an in-source TODO carries LOWER
magnet risk than a public issue because it is "repo-internal knowledge". **That reasoning is wrong
and this entry exists to reverse it.** A TODO in a popular repo's test suite is MORE of a magnet than
an issue, because every author hunting the "restricted form to generalize" shape greps the codebase
for exactly these markers and finds it the same way. A maintainer who writes "it would be great to
support X" has published a specification of the next feature, and a matching negative fixture is a
second, louder signpost.

**What the self-collision check got RIGHT, and why it was still insufficient.** Comparing against our
own approved `numbat-parse-unit-expressions` showed zero file overlap, and the dedupe agreed - it
scored that pair 0.58 and DISTINCT. The check was accurate. It simply cannot see the other authors in
the pipeline, which is where the collision was. Local dedup can only ever falsify, never confirm.

**Reusable laws:**
1. Treat an in-source TODO, a `// not supported yet`, or a negative fixture asserting a capability is
   absent as a HIGH magnet signal - the same class as a public feature request, not a lower one.
2. Gate-8 evidence and collision risk move TOGETHER, never in opposition. Anything that proves the
   maintainer wants a feature also proves other authors can see that they want it.
3. Do not contest an incremental-differences derivative verdict. The judge names architectural
   placement and error naming as incremental BY DEFAULT.

**Do not re-author.** Not a typechecker-resolution variant, not a different error taxonomy, not with
exactness added. The whole compile-time-exponent capability in numbat is consumed.

## comrak-reference-style-links (Rust, SHELVED 2026-08-05 — DERIVATIVE, scope gate)

**Killed by:** platform Scope Gate, verdict `overlap`, blocking on an OLDER ACCEPTED submission in
the pipeline that implements the same capability in the same repo and the same file.

**What was built:** an opt-in `reference_links` render option on comrak's CommonMark renderer —
links/images emitted as `[text][label]` / `![alt][label]`, a document-wide label registry, a trailing
definitions block, `ReferenceLinkStyle::{Numeric,Text}`, CLI flags. 214 effective LOC, 5 files, 58
tests, 650 base green, flakiness 3/3, six reproduced traps on six axes with a measured
interdependence cycle. Artifact quality was NOT the problem.

**The prior art is a SUPERSET.** The older accepted task shares `src/cm.rs` link/image rewriting, the
definitions block, the Options/Render + CLI wiring, label ordering, autolink handling and the
round-trip requirement — then goes FURTHER, extending the parser/AST (`Ast`, `inlines`, `refmap`) to
preserve source reference definitions and their full/collapsed/shortcut forms. Our submission was the
same core with a SMALLER integration layer plus a label-policy selector. The gate's words: "Numeric
versus text labels is a policy swap atop that same machinery, not a genuinely divergent behavioral
class."

**ROOT CAUSE — the magnet test was run on the SUBSYSTEM instead of the CAPABILITY.** At pick time the
risk was noted ("reference-style links ARE a CommonMark concept... magnet risk") and rated MODERATE,
because comrak's *renderer* was a fresh subsystem next to our two pulldown-cmark *parser* picks. That
reasoning is invalid. The one-line summary — "add an opt-in CommonMark rendering mode that emits
links as reference-style Markdown instead of inline destinations" — is fully intelligible to someone
who has never seen comrak, which is the magnet definition. **A fresh subsystem does not cure a
spec-named capability.** Reference-style links are named by the CommonMark spec itself, so every
author reading that spec converges on the same feature.

**Second contributing cause — a maintainer-welcomed lane is DOUBLE-EDGED.** The pick came from
comrak issue #740, where the owner wrote "I'd be happy for this feature to be implemented and would
welcome PR(s)". That cleared Gate 8 (maintainer philosophy) and simultaneously MAXIMISED pipeline
collision risk: a publicly blessed, still-unimplemented, spec-named feature is precisely the
derivative magnet, and every other author sees the same issue. Gate 8 clearance and collision risk
point in OPPOSITE directions on the same evidence.

**Reusable law:** run the one-line-summary magnet test on the CAPABILITY NAME. If the capability is
named by an external spec, a manual, or a well-known tool's feature list, it is a magnet no matter
which subsystem implements it and no matter how novel the internal machinery is. Changing subsystem
changes the DIFFICULTY story, never the COLLISION story. The only cure is a capability whose name
cannot be written without repo-specific nouns.

**Do not re-author.** Not the numeric/text variant, not a "different escaping policy" variant, not a
source-form-preserving variant (that IS the prior art). The whole reference-style-output capability
in comrak is consumed.

**Post-mortem mining of the rest of comrak (same day), so the repo is not re-mined blindly:**

- **`render.width` wrapping lane — COLD BUT SOUND, no gap.** 0 commits in 12 months, comrak's own
  model, no external spec defines markdown re-wrapping: the ideal profile on paper. Measured it
  properly instead of assuming. Every real document round-trips at width 0 and appears to "break" at
  every non-zero width, but under a whitespace-normalised comparison that collapses to 1/20, and that
  one traced to artifacts in the probe itself (a bisect that split a fenced code block, plus trailing
  space inside `<code>`). **The lane is cold because the code is correct, not because it is
  neglected.** Do not build a wrapping-invariant problem here.
- **Lane heat at 300 commits/12mo:** sourcepos 10, attributes 7, table 5, typst 3 (a new output
  target, actively developed), extensions 3, xml 2, wrap/width 0, plugins/adapters 0,
  anchorizer/header-ids 0.
- ⭐ **The scope-gate rejection proves ANOTHER AUTHOR HAS AN ACCEPTED comrak TASK.** The pipeline
  contains comrak work we cannot see and cannot enumerate. That raises the collision prior for EVERY
  future comrak pick, on top of the fact that most remaining capabilities are extensions, which are
  spec-named and therefore magnets. Treat comrak as contested, not fresh.


## petgraph-node-validation (Rust, SHELVED 2026-07-01)

**Repo:** petgraph/petgraph - the standard Rust graph library (~2.8k stars). `petgraph::algo` family (dijkstra, astar, bellman_ford, spfa, k_shortest_path, ford_fulkerson, dinics, dominators, steiner_tree, etc.).

**Pick:** establish one defined outcome for a non-member node id across the algo family - never panic, never fabricate a result rooted at a missing node; return the function's natural empty/identity result. Plus: stay correct for VALID ids on a sparse-index `StableGraph` after removals. Tracked issue #976 (open, cold).

**Tier attempted:** pitched Olympus, build-measured to 117 eff LOC / 11 files -> downgraded to Mars.

**Batches:** three, all too-easy. (1) 7/7 PASS on the bare membership contract. (2) re-batch after adding holey-StableGraph valid-node correctness traps - still too-easy. (3) 100% after de-prescribing the meta (not naming the 3 buggy functions). Also flagged **AI-Dedupe 90% DERIVATIVE** (prior art owns the reject-invalid-across-algo-family contract).

**Why too-easy (root cause):**
1. The membership half is an intrinsic **uniform-wrap**: every agent adds an `IntoNodeIdentifiers` bound + a `node_identifiers().any(|n| n == id)` guard + a per-site early return. One mechanism, N sites, ~100%.
2. The only genuine-difficulty surface was **3 count-vs-bound holey-StableGraph bugs**, all SELF-REVEALING PANICS (`k_shortest_path` counter sized by `node_count()`, `ford_fulkerson` edge_to by `node_count()`, `dinics` flows by `edge_count()`). A panic points at its own line. Confirmed from source: there is no 4th bug site (dominators uses a post-order HashMap, floyd/iso reject StableGraph at compile, everything else already sizes by `node_bound`).
3. **Fairness kills the trap.** The audit-gap misdirection ("agent never thinks to test a holey graph") only works if the spec hides the requirement. But fairness demands the meta state "the family must stay correct on a StableGraph after removals", and that sentence directs a competent agent to test holey graphs - which surfaces the panics. R2 (add traps), R3 (reframe), R4 (de-prescribe) all failed to escape this.

**Lesson:** a membership / validation / reject contract is a dead difficulty class. Do NOT re-pick it on any repo. "Reject invalid ids across an algo family" is also a SATURATED one-shot per repo - once a prior sub takes it, the next is derivative. Same death as [[kysely-row-level-scope]] and [[ironcalc-range-displacement]] below.

---

## participle-precedence (Go, SHELVED 2026-07-01)

**Repo:** alecthomas/participle - reflection / struct-tag PEG parser for Go (~1.1k stars). Native operator-precedence via a `prec` struct tag (infix left/right/nonassoc, prefix, postfix, ternary) building a synthesized Left/Op/Right/Mid tree.

**Tier attempted:** Olympus (463 eff, 6 files). Derivative-differentiated from 2 prior participle-precedence subs via postfix + ternary + the `Mid` AST shape.

**Batches:** ~11 rounds. Headline: a 10-run Nova batch landed **8/10 PASS = 80%** (cap 20%). Earlier rounds read 40% (12-run) and looked borderline-acceptable - but those were UNFAIRNESS ARTIFACTS (root cause 3), not real difficulty.

**Why too-easy (root cause) - 10-trace mechanical analysis:**
1. **Detailed-spec TRANSCRIPTION.** The meta hands over the full field contract (untagged Left/Op/Right/Mid, the tag grammar, associativity rules, canonical output trees). All 10 traces locked the precedence-climbing algorithm first-draft-correct in ~2 min of reading, zero algorithmic thrash. The algorithm is dictation, not a wall.
2. **The one hard seam is a SINGLE CORRELATED DECISION.** The only thing that bit (2/10) was synthesized-node capture/position injection (Pos/EndPos/Tokens + leaf-capture propagation). But it is cleared by ONE architectural choice - reuse participle's native `maybeInject*` helpers + thread one start cursor + flush deferred captures - and that single choice clears EVERY variant (infix/prefix/postfix/ternary/nested/leaf) at once, because they all funnel through the same native chokepoint. The variants are perfectly CORRELATED: an agent who makes the choice passes all; one who does not fails all. Stacking more position/capture variants cannot lower the rate - they are the same decision. (Two robust impl routes - generic leftmost-cursor + `ctx.Range`, OR per-role child-Tokens concat - both clear all roles for free.)
3. **The "acceptable" earlier rates were unfairness artifacts.** The 40% batch was propped up by an under-documented `prec:""` empty-set biter (5/6 real fails). Fairness REQUIRES documenting "an empty operator set is a Build error"; documenting it converted the biter into a transcribable checklist item -> biter died -> the TRUE fair rate (~80%) surfaced. Every earlier round that looked hard was hiding behind an unfair/under-specified trap; each fair fix RAISED the rate (40 -> 80).

**Lesson (NEW death class - correlated-seam transcription):** a feature whose hard variants funnel through a SHARED chokepoint (one native helper / one architectural decision) is a dead difficulty class even when it is NOT a literal uniform-wrap. The tell: the hard seam has many surface forms (4 operator roles x nesting x leaf) but ONE fix clears them all. Stacking variants does nothing - they are correlated. To be hard, a feature needs UNCORRELATED traps (different agents fail for different reasons; no single decision clears them). **Corollary (the unfair-biter mirage):** a pass rate that looks acceptable only because an UNFAIR or under-documented biter is holding it down is NOT real difficulty - fairness will remove that biter and the true (higher) rate surfaces. Confirmed: 40 -> 80 the moment empty-prec was fairly documented. When a batch looks borderline, check whether the failures trace to a documented requirement or to a spec gap; gap-failures are fake difficulty.

**Contrast (the successful pivot - same repo, different subsystem):** participle DOES carry a hard FAIR trap, but in the disjunction engine, not the precedence node. The greedy `||` longest-match alternation feature ([[../problems/participle-longest-match]]) has an UNCORRELATED leak wall: the obvious Branch-based greedy impl leaks captures from rejected alternatives into the shared parent struct (build-PROVEN live + non-free + fixable), and that wall does NOT funnel through the same decision as the longest-selection logic - so it is genuinely interdependent where precedence's seam was correlated. (Single-subsystem still caps it at Mars by LOC, but it is hard where precedence was not.)

---

## kysely-row-level-scope (TypeScript, SHELVED 2026-06-30)

**Repo:** kysely - type-safe SQL query builder for TypeScript (~11k stars). `OperationNodeTransformer` plugin layer.

**Pick:** `RowLevelScopePlugin` - a predicate-injection transformer that rewrites queries to add a scope/tenant WHERE predicate (and an equivalent write-scope guard on insert/update).

**Tier attempted:** pitched Olympus, build-measured to 285 eff -> the AST reindexes parameters for free, so honest LOC stayed Mars-sized.

**Batches:** three, all too-easy: 100% -> 100% -> 80% (cap 30%). The only two non-passing runs both failed on an UNDOCUMENTED intra-`ON` / update predicate-ORDER detail - i.e. `description_clear: false`, a FAIRNESS gap, not real difficulty. Also failed Task-Quality (one plugin + one export fails the Olympus system-level gate) and build-measure (285 < 450 floor).

**Why too-easy (root cause):** a single-subsystem predicate-injection / scope-transformer plugin is a **mechanical, fully-specified AST transform**. Nova transcribes the spec. There is no retry-resistant FAIR wall: the difficulty would have to come from a hidden detail, but hiding it makes the problem unfair (and the batch flagged exactly that). The findmyway law applies: a mechanical transform needs >=2 hidden-integration walls that compound to land Hard; a single-subsystem transform has zero.

**Lesson:** scope-transformer / predicate-injection / AST-reindex plugins are the mechanical-transform ceiling - fair-but-too-easy for BOTH tiers. The artifacts were kept only as reference for the kysely offline harness (DummyDriver compile-only, f2p via an `as any` namespace cast).

---

## ironcalc-range-displacement (Rust, SHELVED)

**Repo:** ironcalc - a spreadsheet engine in Rust. Formula reference adjustment on row/column insert/delete (range displacement).

**Pick:** adjust formula references correctly when rows/columns are inserted or deleted (a reference inside a displaced range shifts; one straddling a boundary clamps or errors).

**Why too-easy (root cause):** the intended difficulty was a misdirecting trap (the obvious displacement rule is subtly wrong at boundaries). But to be FAIR the meta must spell out the exact canonical displacement form (what shifts, what clamps, what errors), and spelling it out neutralizes the misdirection entirely. There is no cold-AND-deep zone in ironcalc: the parts that are cold are shallow, the parts that are deep are already specified by spreadsheet convention the agent knows.

**RE-VERIFIED 2026-08-05 — the repo-level verdict HOLDS; do not re-open ironcalc.** Re-audited on the
theory that the shelved pick was only one CLASS and the repo still had open lanes. It does not. `base/`
is 116k Rust LOC (nothing like an absorption profile) and `user_model/` genuinely IS IronCalc's own
model rather than Excel-defined — but every lane is closed: (a) `functions/` is Excel semantics =
spec-knowable/memorised dead class, and carries 4+ open PRs (#1325 T.DIST, #1165 YEARFRAC/DATEDIF,
#584 FACT/lngamma, #825 range clamping); (b) `expressions/` is the shelved pick's own area plus Excel
convention, with #826 and #777 on the lexer and #1262 on static_analysis; (c) **`user_model/` — the one
non-Excel lane — has live capability PRs on `common.rs`: #1258 "feat(base): add `UserModel::set_user_inputs`
for batched single-undo write" (+86 src, +190 undo tests), #1290 frozen-pane structural-edit diff tracking,
#373 newSheet return values.** So the undo/action model (the P1 algebraic-law candidate: `undo(do(x)) == x`)
is exactly where the maintainers are working. 20 open PRs total, ★4071 (penalty band). ⭐ Meta-lesson: a
repo-level verdict recorded in this file is EVIDENCE, not a note about one pick — re-opening it cost a
re-audit that confirmed the original finding.

**Lesson (DEFINITIVE):** difficulty-from-misdirecting-traps cannot be both FAIR and hard. The fairness gate forces spelling the canonical form, which kills the trap. Pick genuine-algorithmic-depth that stays hard when FULLY specified, not a trap that depends on the spec hiding something.

---

## cel-exhaustive-eval (Go, PIVOTED too-easy)

**Repo:** cel-go - Google's CEL expression language for Go.

**Pick:** an exhaustive-evaluation mode (evaluate all branches rather than short-circuiting).

**Why too-easy (root cause):** uniform-wrap - one local rule applied at every evaluation site. ~50% per the difficulty model, single-shot-fixed. The public API signatures were a fairness floor, not a difficulty lever (specifying them does not add hardness, omitting them only adds unfairness). 3rd confirmation of the uniform-wrap dead class.

**Lesson:** a uniform-wrap (one mechanism at N sites) is a dead Diamond/Olympus class. Need a non-collapsing SECOND mechanism that an agent cannot discharge with the same edit.

---

## js-joda-parse-resolver (JS, SHELVED too-easy every tier)

**Repo:** js-joda - a JavaScript port of Java's `java.time`.

**Pick:** the parse resolver (resolving parsed field values into a date/time per the java.time resolution rules).

**Why too-easy (root cause):** a saturated-reference port. Agents have the `java.time` resolution semantics effectively memorized, so the feature is reconstructable from training knowledge regardless of how the meta is written. Every "new" test risks being a base-passer or trivially derivable from the reference spec.

**Lesson:** saturated-reference ports (java.time / stdlib equivalents / SVGO / any popular spec the agent already knows) are too-easy at every tier. The PICK-FILTER saturation gate exists for exactly this; do not pick a port of a spec the model has seen thousands of times.

---

## symengine ImageSet + WHOLE-REPO CAS verdict (C++, SHELVED too-easy 2026-07-02)

**Repo:** symengine/symengine - a C++ symbolic-algebra (CAS) kernel, MIT, 1379 stars, LOW platform sub-count (niche, not over-used).

**Pick journey (3 cold subsystems, 3 death classes):**
1. diff-family (issue #1696, abs/sign/max/min diff): correct full solution = **44 eff LOC** (the existing `fdiff` template does the work) -> under Mars floor = too-small/triviality.
2. series expansion (#859): generic backend already complete via `SeriesBase` CRTP; gaps thin/messy/FLAKY (zeta series HANGS) -> not viable.
3. sets/ImageSet (contains + intersection + fix a stack-overflow): built + correct (149 eff LOC), but SMOKE-BATCH killed it.

**Why ImageSet too-easy (SMOKE-BATCH, 3/3 clean INDEPENDENT solvers):** ImageSet membership/intersection in symengine = SymPy's documented `ImageSet` semantics + textbook Chinese-remainder (two arithmetic progressions -> gcd_ext + lcm). 3 fully-isolated cold Sonnet solvers each nailed the ENTIRE feature (linear-coeff contains + `base->contains` delegation, CRT, bounded-interval enumeration, the recursion-fix reverse-dispatch) with DISTINCT code, ZERO struggle; two hand-verified the CRT, all flagged the base-golden regression themselves. NOT ONE of the hoped-for traps (Naturals lower-bound membership, the infinite-recursion crash) tripped any solver - membership fell out FREE via delegation to `base->contains`, and the recursion fix was the natural reverse-dispatch. = saturated-reference-port (SymPy) + no retry-resistant wall.

**⭐⭐ REPO-LEVEL LAW: a CAS kernel is a whole-repo saturated-reference.** Every cold algorithmic feature in a computer-algebra library (differentiation rules, series coefficients, set algebra, simplification, solvers, special functions) is TEXTBOOK and/or documented in SymPy/Mathematica, which are in every strong model's training. So the WHOLE repo is saturated-reference: features are either RECALL (too-easy) or already-implemented or flaky. symengine (and any SymPy/Sage/Mathematica-shaped library) is NOT a viable hard-fair authoring target. Do NOT re-pick symengine or CAS kernels for difficulty. (Same spirit as js-joda = java.time port, but repo-wide, not one feature.)

**⭐⭐ PROCESS LAW: SMOKE-BATCH solvers MUST run in ISOLATED copies (git worktree per solver).** First ImageSet smoke-batch put 3 agents in ONE shared worktree; they edited the same file concurrently and "converged with the concurrent writer" (identical var names proved cross-contamination) -> the independence signal was VOID. Re-ran with `git worktree add --detach <scratch>/smokeN <BASE>` per solver = true independence. Never share a working copy across concurrent smoke solvers.

---

## ⭐⭐⭐ The Difficulty-Rigor Protocol (added 2026-07-01 - after 4 authored subs all came back too-easy)

**Root cause of the repeated too-easy:** difficulty was PREDICTED (a recon agent's "~5-15% pass" guess), never MEASURED. We built an elaborate build-measure pipeline for LOC but ZERO measurement for difficulty, then substituted "recon-says-hard + survived-build-measure" for "is hard." LOC and difficulty are ORTHOGONAL (CLAUDE.md). A pick that survives build-measure says NOTHING about whether agents pass it. Recon agents model a NAIVE solver and assume the trap bites; real Nova/Castor are smart, transcribe the fair spec, and single-shot a single-subsystem trap.

**The fix - difficulty gets the same rigor as LOC:**
1. **Death-Class Pre-Pick Guard = mandatory, free, BEFORE authoring** (the 5 questions below). Rejects membership/validation, mechanical-transform, misdirection-only, uniform-wrap, saturated-port instantly. petgraph + kysely were NAMED dead classes authored anyway = 6 wasted batches.
2. **SMOKE-BATCH = the difficulty-twin of build-measure, mandatory before authoring proper.** Fire 3-5 strong COLD solvers (opus/sonnet, Query-13 sim) on the real meta + repo. **The sim can ONLY REJECT, never approve** (TOO-EASY line 9: local sims miss things both ways). Single-shot by the sim → DEAD, kill for free. Sim struggles → necessary-not-sufficient → the platform 10-run batch remains the ONLY approver.
3. **Per-trap retry-resistance test:** for each named trap ask "does a SMART agent reading the FULL FAIR spec still miss it?" If fairness must REVEAL it to be fair → it is dead, do not count it (the ironcalc law). Only traps that survive full specification count.

**⭐ THE SELECTOR (what actually makes a pick hard AND fair - the thing the two-axis LOC model missed):** the difficulty must be a **repo-specific cross-subsystem INTEGRATION wall** - an emergent interaction of THIS codebase that the agent discovers only by FAILING, that survives being fully + fairly specified. Evidence from the in-band approveds: glaredb ordered-agg 2/12 (obvious global-sort BREAKS on glaredb's hash-distinct → dedup-after-sort in agg state); piccolo to-be-closed 2/10 (generic-for-4th-value hits its OWN opcode/compiler path = a 2nd subsystem). You can fully describe the BEHAVIOR and the agent STILL fails, because the wall is an emergent property of the repo's architecture, NOT a rule the spec hides. **The two-axis model selects FOR mechanical smoothness (a capability that threads cleanly through stages) - which is the OPPOSITE of an integration wall.** "Threads cleanly" = too-easy. Hunt for picks that hit a wall, not picks that thread.

**Decision rule:** difficulty must come from (a) a repo-specific integration the spec cannot pin without writing the solution, or (b) a genuinely-new load-bearing algorithm the agent must derive AND that has a second independent subsystem path. Single-subsystem + fully-specifiable = dead, every time, regardless of LOC or recon-predicted trap-count.

### ⭐⭐⭐ SMOKE-BATCH WIN + "SURFACE-DIVERSITY != WALL-COUNT" + "CORRECT-IN-REPO-REFERENCE = CHOKEPOINT" (added 2026-07-01, go-mysql-server collation-dedup)

FIRST time the difficulty-rigor protocol PREVENTED a too-easy sub pre-authoring (cost: 4 local solvers, not a paid platform batch). go-mysql-server collation-aware-dedup was recon-nominated WALL-BEARING-OLYMPUS (reproduced wrong output, cleared all 5 death-class guards, cold, ~450-600 eff, clean f2p, right-repo-profile). The mandatory SMOKE-BATCH (4 cold opus solvers, spec-only) killed it: 2/2 (then confirmed) solved it CLEANLY at "moderate" difficulty via the SAME unifying insight, full suite green.

Two lessons the recon could not see (recon is difficulty-blind - only the smoke-batch reveals these):
1. **SURFACE-DIVERSITY != WALL-COUNT.** Recon counted 4 structurally-different dedup mechanisms (node-hash / xxhash / string-map / set-op-iter) as 4 independent walls. But all 4 traced to ONE root omission (dedup paths call the shared `hash.HashOf` with a `nil` schema, so strings fall through to byte-wise instead of the collation weight-string branch) and ONE fix-insight ("pass the schema everywhere"). N mechanisms that share a root cause / fix-insight = a CHOKEPOINT = uniform-wrap in disguise = the piccolo/kysely bimodal death. TEST at recon: do the N sites share a single fix-insight? If yes -> chokepoint -> too-easy. Recon cannot answer this reliably; the smoke-batch is the oracle.
2. **"MAKE X CONSISTENT WITH EXISTING-CORRECT Y" = CHOKEPOINT PICK.** The spec was "make dedup behave like GROUP BY (already collation-correct)." When a CORRECT REFERENCE BEHAVIOR already exists in-repo, that reference's mechanism IS the answer - the agent finds Y (GROUP BY's `groupingKey` passing a typed schema), reads how it works, and replicates it across the sites. Near-pattern-followable. Also: the "depth" I feared (coercibility over expressions) came FREE because the agent reused the engine's own `GetCoercibility`/`GeneralizeTypes` - a second in-repo correct reference. PICK-RULE: reject "make X consistent with existing-correct Y" specs; the fix is "do what Y does." Genuine walls have NO correct in-repo sibling to copy (contrast opa reduce/fold: no existing fold to replicate).

Net: the smoke-batch is now PROVEN to pay for itself. Run it on EVERY recon-nominated wall before authoring. See [[feedback_measure_difficulty_not_predict]].

### ⭐⭐ THE HOT/COLD INVERSION + RIGHT-REPO-PROFILE (added 2026-07-01, from a 3-engine wall-hunt: salsa + datafusion DEAD, go-mysql-server WIN)

Integration walls ANTI-CORRELATE with coldness: the deep cross-subsystem interactions are exactly where active maintainers work, so wall-bearing zones tend to be hot/maintainer-owned. In a MATURE, popular, fast-moving engine the inversion is TOTAL:
- the wrong-results correctness walls are RED-HOT (touched days before base, map to open issues / in-flight PRs = the "active+visible+hard = maintainer-owned" SIX-CHECK reject; ships between base and submit) - salsa (every wall = open issue #847/#1061-with-test-written, files 16-29 commits/12mo) and datafusion (outer-join pushdown soundness, decorrelation - all hot);
- what is left COLD is already-CORRECT - only performance optimizations remain (union equivalence, monotonic ordering), which have NO fail-on-base wrong-results f2p (only brittle plan-shape assertions), are single-mechanism uniform-wraps, and sit under 450.

So the biggest/most-active engines (datafusion 16k-star daily, salsa 2.9k-star daily) are the WORST place to hunt a cold-AND-wall-bearing pick. **The RIGHT profile = a DEEP-but-not-frantic engine where a wrong-results wall is still COLD because maintainer attention is elsewhere** - exactly the approved-pool profile (glaredb/gluesql/piccolo) and confirmed by go-mysql-server (dolt): its SQL analyzer/optimizer walls are cold because the team works on dolt's storage/versioning, the SQL engine is a means-to-an-end. PICK-RULE: hunt walls in deep engines whose CORE PURPOSE is something ELSE (the wall-subsystem is infrastructure they depend on but do not actively churn), or in small-team deep engines; never in the flagship fast-moving engine of the domain.

### ⭐⭐⭐ DERIVATIVE-SUBSET + EXHAUSTED-VEIN (added 2026-07-03, frostdb ordering: 3 features, 0 shippable -> rejected/frostdb-order-by)

frostdb (polarsignals, the platform's OWN approved-example repo) was hunted for a Mars/Olympus across THREE query-engine features; all three died, each on a different wall. The composite lesson is bigger than any one kill: a compact, heavily-mined repo has no clean fresh pick left, and you can burn a full authoring cycle proving it feature-by-feature.

1. **ORDER BY + top-k** (built end-to-end, 267 eff, fully local-validated, elegant f2p) -> DERIVATIVE 90%/82% vs TWO OLDER EXTERNAL subs. **LAW: a SUBSET cannot be de-derivatived by "adding meaningful differences."** Both siblings added the same LogicalPlan.OrderBy/Sort node + blocking physical operator after the synchronizer + LIMIT-after-sort + null placement, threaded through builder + sqlparse; they ALSO had OFFSET, computed/aggregate/ordinal sort keys, boolean, configurable NullsFirst, limit-pushdown, DISTINCT composition. We were a strict subset. Adding what they have INCREASES overlap; the only escape is a different trap/subsystem/category. Dedup is behavior+structure based, not text. The clever f2p mechanic (frostdb sqlparse never walks SelectStmt.OrderBy -> the clause parses but is silently dropped -> compile-on-base entry via ExperimentalParse+Execute) is a KEEPER pattern for OTHER repos, but it does not save a taken feature.

2. **Ordered-merge direction/type fix** (built, validated, dedup-CLEAR because different surfaces: arrowutils/merge.go + ordered_synchronizer + ordered_aggregate, no ORDER BY node) -> **78 eff, SUB-FLOOR (Mars 100).** The genuine correctness fix (OrderedSynchronizer builds SortingColumn{Index:i} with default direction -> ordered agg over a DESCENDING sort column returns ASCENDING groups; MergeRecords.compare panics on float/bool) is intrinsically tiny. Only route to 100+ was adding more type cases = pattern-follow padding = refused. LAW: dedup-clear does NOT rescue sub-floor; a clean small bug fix is still too small.

3. **var_pop/var_samp aggregation** (non-obvious, dedup-safe, f2p-confirmed, real parallel-merge trap) -> **FEASIBILITY WALL.** The one genuinely good candidate: naive VarianceAggregation in the chooseAggregationFunction switch is multi-branch-WRONG (variance-of-partial-variances at the final merge stage); only AVG-style decomposition through resolveAggregation into sum(x)/sum(x*x)/count(x) + a float formula merges correctly across parallel branches. But it crashes nil-deref: sum(x*x) needs x*x PRE-projected, resolveAggregation only emits POST-projections, and the sqlparse pre-projector only sees variance(v)'s inner v. Fixing needs pre-projection injection into the SHARED builder.Aggregate path (serves AVG + every aggregation) = regression-risky. Buildable as ~150+ eff Mars WITH that plumbing but not worth it in a fought-at-every-turn repo.

**META-LAW: skip the flagship approved-example repo for a fresh pick.** frostdb is THE platform example -> heavily mined -> the OBVIOUS features (ORDER BY taken 2x externally, plus OFFSET/HAVING/count-distinct/expressions likely in the pool) are derivative-risk, and its compact query surface leaves only tiny or pre-projection-blocked features. Not on SATURATED-REPOS.md (repo quota fine) but the query SURFACE is tapped. Same class as js-joda (saturated port). Before hunting an approved-example / flagship repo, assume its obvious wins are already in the dedup pool and its surface is compact; prefer a deep engine whose CORE PURPOSE is something else (the HOT/COLD + right-repo-profile law above).

### ⭐⭐ PROVENANCE / BOOKKEEPING CAPABILITIES COLLAPSE TO ONE STORAGE INSIGHT (added 2026-09-08, ytt-overlay-write-provenance, killed at trap reproduction before any test was written)

**Tell at pick time:** the capability is "record / track / attribute / report WHICH producer wrote
each piece of the result" — provenance, authorship, conflict accounting, write logs, blame. It reads
beautifully at seam-audit time because it necessarily threads through every code path the producer
touches, which LOOKS like maximal coupling.

**Why it is dead.** The threading is not the difficulty; the difficulty is one decision — *where do I
park the per-node state so it survives?* Once the solver picks a surviving location, every site falls
out mechanically. That is Pre-Pick Guard #1 (a single mechanism discharging every site) wearing a
cross-subsystem costume, and it produces the L20 single-seam bimodal pass rate rather than a band.
It is also the exact shape the Difficulty-Rigor Protocol warns about: *"the two-axis model selects
FOR mechanical smoothness (a capability that threads cleanly through stages) - which is the OPPOSITE
of an integration wall."*

**The case (carvel-dev/ytt, 2026-09-08).** ytt's overlay kernel `Op.Apply` is a genuinely strong
seam: FOUR call sites with THREE calling conventions (schema pre-processing and data-values
pre-processing at `ExactMatch: true`; post-processing with an ARRAY of docsets looped in sorted file
order; `overlay.apply()` chained from Starlark), 13 `item.DeepCopy()` sites, a `removeOverlayAnns`
sweep at the end of every Apply, and five array ops with genuinely different node-identity semantics
(`merge` preserves the left pointer and falls back to `append`; `replace` does
`Items[i] = newItem.DeepCopy()` under an in-repo comment admitting *"left side fields are not
preserved"*; `remove`/`insert` shift every later index). Gate 1 reproduced cleanly on base: two
overlays writing `spec.replicas` give silent last-write-wins, exit 0, and the value flips with `-f`
order. **All ten PICK-FILTER gates passed.** Two candidate walls were then reproduced and BOTH died:

1. *Annotation lifetime.* `removeOverlayAnns` runs at the end of every Apply and post-processing
   loops Apply once per overlay document — but `NodeAnnotations.DeleteNs` deletes only the
   `overlay/` prefix, and `convertToAST` preserves node identity in place. Any other namespace walks
   through. One insight: "don't use the `overlay/` namespace."
2. *`meta` through `DeepCopy`.* Much better on paper: `yamlmeta.Node` exposes `GetMeta`/`SetMeta` —
   the repo's own documented side channel, already used by `pkg/schema` (the schema `Type`) and
   `pkg/validations` — and `DeepCopy()` drops `meta` on all six node types while copying `Comments`,
   `Position`, `annotations` and `injected`. Silent, misdirecting, and idiomatic to fall into.
   **Killed by the base suite:** patching all six constructors to carry `meta` forward left
   `go test ./pkg/...` fully green, so the correct fix regresses nothing and there is no S3
   baseline-preservation half. One insight: "meta does not survive DeepCopy."

**LAW.** A capability whose product is BOOKKEEPING ABOUT the work rather than the work itself has its
difficulty concentrated in a single storage decision, however many subsystems it threads. Do not
count "it touches every path" as coupling — ask instead what ALGORITHM the capability computes. If
the honest answer is "it remembers things", it is dead. **Corollary, and the cheap check:** the
Stage-3b absorption test ("name the algorithm the repo does not already contain") catches this at
pick time. "Provenance tracking" is not an algorithm.

**What survives.** The repo-level work is fully reusable — gates, base commit, green baseline, Docker
pattern, seam map. Only the CAPABILITY was wrong. Pivot the feature, keep the repo.

### ⭐⭐⭐ GENERIC-INTERNALS + STANDARDS-DEFINED-EXTERNALS = NO AUTHORABLE MIDDLE (added 2026-09-08, carvel-dev/ytt, 8 candidates / 2 reproduced deaths / 0 shippable)

**Sharper, repo-level form of "framework maturity is the enemy".** That corollary says prefer a real
DOMAIN over a well-factored framework. This says WHY a certain repo profile is a guaranteed zero, and
it is checkable before you score a single candidate:

**A repo is unauthorable when (a) its internals are GENERIC and complete — a tree engine, a type
tree, a visitor, a matcher algebra — so anything layered on them is a call-through under the LOC
floor; AND (b) everything those internals do NOT cover is fixed by an EXTERNAL STANDARD, so it is a
derivative magnet.** The two conditions squeeze from opposite sides and leave no middle. Neither
condition alone is fatal; together they are.

**The case (carvel-dev/ytt, 2026-09-08).** Mechanically one of the cleanest targets audited:
Apache-2.0, pure Go, `vendor/` committed so Docker is offline-trivial, `test-all.yml` green,
`go test ./pkg/...` deterministic 3/3, zero subs against a 6-quota, and a genuinely rich seam map
(one overlay kernel with FOUR call sites and THREE calling conventions; F-2/F-6/F-7/F-9 all present
with file:line evidence). **All ten PICK-FILTER gates passed.** Eight candidates were then scored:

- **Six died at screening.** YAML scalar round-trip (#889/#821/#822) = the YAML resolution spec.
  JSON Schema export (#898) = a named standard, and PR#901 already exists. `@schema/type one_of` =
  maintainer-owned (#400's closure comments name it as their plan). The whole validations lane =
  maintainer-owned (#724 is an OPEN maintainer-authored proposal with a published design PR).
  Validations-under-`any=True` = missing arm. Overlay order-independence = undecidable with
  data-dependent `when=`/`by=<fn>` matchers, so no fair contract can pin it.
- **Lane 1 (overlay write-provenance) died at reproduction** — bookkeeping; see the PROVENANCE
  entry above.
- **Lane 2 (library schema-override compatibility) died at the absorption experiment**, and it is
  the instructive one because it passed everything else. Gate 1 reproduced cleanly: a parent doing
  `library.get("mylib").with_data_values_schema({"port": "not-a-number"})` against a child declaring
  `port: 8080` emits `port: not-a-number` at exit 0. A measured F-20 sibling asymmetry sat right
  beside it (`with_data_values` type-checks; `with_data_values_schema` does not, and only 2 repo
  tests touch it, neither asserting the permissive behaviour). The absorption test even LOOKED clean:
  `grep` for any `Equals|Compatible|AssignableFrom|Subsumes` on `Type` returned **zero**, so
  Type-vs-Type comparison genuinely did not exist. Sketch: "recursive comparator over 8 type kinds
  with variance rules, 250-400 eff." **Reality: 32 raw / ~25 effective lines, catching every cell** —
  because a schema document IS its own default values, so you materialize the override's defaults and
  hand them to the EXISTING `AssignType` + `CheckNode`. The comparator never needs writing.

**LAW.** *"No function performs this comparison"* is NOT an absorption clearance. Ask instead whether
the repo can REACH the answer by composing primitives it already owns — here, by converting the
problem into one the existing checker already solves. The grep tests for a NAME; absorption is about
REACHABILITY. **The cheap check: before sketching LOC, spend ten minutes trying to solve the
capability with existing primitives only.** If you can, the sketch is fiction. Third instance of a
sketch overshooting by ~10x (canvas-fill-rule-backends 213 -> 44; iced-x86 180-220 -> 126; ytt
250-400 -> 25).

**Corollary for the hunt.** Mechanical excellence and seam richness measure AVAILABILITY, not depth,
and a repo can score top on both while being structurally unauthorable. Both of ytt's reproduced
deaths were invisible to all ten gates and to the whole F-catalogue.

## Pre-Pick Guard (run before scope-locking)

1. **Is the difficulty a single guard/rule applied at many sites?** -> uniform-wrap, dead. Need a 2nd non-collapsing mechanism.
2. **Is it a single-subsystem, fully-specified transform** (inject / rewrite / reindex / validate / reject)? -> mechanical-transform ceiling, dead. Needs >=2 hidden-integration walls; a single subsystem has none.
3. **Does the hardness depend on the spec NOT stating something?** -> fairness will force you to state it, killing the trap. Dead.
4. **Is it a port of a spec the model knows** (java.time, stdlib, a popular library)? -> saturated, dead.
5. **Can the genuine-difficulty surface survive being fully spelled out in the meta?** If NO -> dead. If YES (cross-subsystem integration timing, a genuinely-new load-bearing algorithm, an interdependent multi-stage pipeline) -> proceed to the PICK-FILTER 8 gates.

If a candidate trips 1-4, do not author it. Pivot the FEATURE, not the wording.

### ⭐⭐ SINGLE-INSIGHT REINDEX TRANSFORM (added 2026-07-04, jsondiff factorized-array round-trip -> rejected/jsondiff-array-rebase)

wI2L/jsondiff (Go, RFC-6902 patch generator), Mars. Fix the broken factorized array-diff so `Factorize()`+`LCS()` reorder patches round-trip (base emits move ops with frozen/wrong indices). Built end-to-end, validated (87 f2p cases, 190 eff, deterministic), hardened over 6 rounds. Nova batch: R1 ~100% -> R4 (de-prescriptivized meta + 76 cases) ~89% -> R6 (moves-only invariant) ~80%. Never reached <=30%.

ROOT CAUSE = the whole feature is ONE insight: "simulate the patch applying and compute correct sequential indices." Every case (block rotation, copy, nested, invertible, duplicates, mixed-op move+copy+remove+add) collapses to that single insight. A correct ~30-line "simulate as you go" clears all of them, and Nova (now ~Castor-level) writes it. Textbook uniform-wrap / mechanical-transform ceiling (pre-pick guards #1 + #2).

Three escape-closures were tried and each only moved the needle ~10 points:
- De-prescriptivize the meta (deleted the seam sentence "move shifts both endpoints, account for those shifts") - Tighten-First Rule 7. ~100 -> ~89%.
- Moves-only invariant on pure permutations (a reorder adds/removes nothing, so assert every op is a move) - closes the validate-then-fallback-to-add/remove escape ([[lesson_roundtrip_only_too_weak_assert_optimization]]). ~89 -> ~80%.
- Reverse round-trip wall (`Invert().apply(tgt)==src`) - passes once generation is correct (Invert has no independent bug).

WHY NO SECOND INSIGHT EXISTS (proven, not assumed):
- Multi-level interacting rebase is impossible in the diff model: an outer array element either MOVES intact (inner unchanged) or CHANGES in place (not a move) - never both, so "outer reorder shifting inner-op prefixes" never arises. Probed: nested outer+inner reorders round-trip on BASE (not even f2p) because reordered outer objects differ -> resolve to per-position content changes, not moves.
- The options are FILTERS on the same move bug, not new insights: `Rationalize` decides keep-vs-collapse (keeps moves for large arrays, collapses small - same bug either way), `Ignores` skips paths, `Invertible` adds test ops, `Equivalent` returns empty by design. None require new reasoning.
- The one second-insight candidate, `Ignores`-aware index accounting, is UNFAIR: "ignore index /2 during a reorder" is semantically ill-defined (index 2 holds different elements src vs tgt), no deterministic documented behavior -> ambiguous canonical form (ironcalc law).

LAW: a correctness fix whose ENTIRE difficulty is "compute the right indices/output" (reindex, rebase, relabel, renumber) is single-insight - one correct simulation discharges every case, so it caps at Mars-medium (~40-60%) and cannot fairly reach <=30%. Same class as kysely (predicate-injection reindex, 100->80% abandoned), ironcalc (range-displacement reindex), petgraph (membership validation). Add to the pre-pick guard: if the fix is "the transform is correct once the indices are right," it is a reindex transform - dead for <=30%. jsondiff repo quota is fine; the DIFF-GENERATOR SURFACE is single-insight. Keeper pattern for elsewhere: the moves-only / assert-the-optimization-happened invariant that kills validate-then-fallback.

### ⭐⭐⭐ SHALLOW STRING-BUILTIN DOMAIN CEILING (added 2026-07-05, mq-charsplit -> too-easy, real Nova 9/10)

harehare/mq (Rust markdown query lang), Mars. Feature: make index/rindex CHARACTER-based (Unicode scalar, agree with len/slice/get) + optional zero-based OCCURRENCE-selector 3rd arg (negative counts from opposite end) + literal split + new count/chars + markdown-node overloads + mq-check type-checker ternary overloads + fix the semver.mq stdlib regression the literal-split introduces. Cross-crate (mq-lang eval + mq-check + stdlib .mq), 4 files, human-eff 134, 60 f2p cases, fully validated.

Hardened THREE times, each measured: offset-3rd-arg (2/2 Sonnet probes one-shot) -> occurrence-3rd-arg + count/index interdependence invariant + empty-split=chars misdirection (2/2) -> cross-crate mq-check wall + semver.mq stdlib regression (2/2). Then a REAL 10-run Nova batch: TOO_EASY, pass_rate 0.90, confidence 0.92 (9/10 solved all 60 hidden tests; the only miss was a fair negative-occurrence boundary index(s,x,-count)=first).

ROOT CAUSE = string-positional builtins are a SHALLOW, TRANSPARENT domain. The proven Nova blind spots for strings (UTF-8 byte-vs-char, ASCII-vs-multibyte narrow-guard, occurrence off-by-one; Instructions research) ARE the right traps and I stacked all three interdependent + misdirecting, but Nova (now ~Castor) implements string ops CORRECTLY. There is no "obvious impl is wrong" surface: .chars()/.find()/str::split are mutually consistent and correct, so any FAIR spec (canonical form spelled out) is one-shot. The one genuinely-hard Unicode trap (grapheme clusters vs scalars) CONTRADICTS mq's scalar len/slice/get -> unfair/incoherent, so it is out.

LAW: a feature whose entire surface is string position / length / split / count / char-extraction builtins caps far above the Mars band (real Nova ~90%), REGARDLESS of cross-crate span, occurrence semantics, type-checker integration, or stdlib-regression breadth. Adding files/crates raises LOC and completeness, NOT difficulty. Same family as the reindex-transform ceiling: the difficulty is "compute the right value," and one correct implementation discharges every case. Pre-pick guard addition: if the tested surface is string builtins (index/rindex/split/slice/count/chars/find/replace/case), it is shallow-transparent -> dead for <=30%. Difficulty for Mars/Olympus on a language repo lives in the DEEP subsystems (optimizer pass-ordering, macro hygiene/capture, HM type inference), where the pipeline-placement / scope-capture / inference-narrowness Nova blind spots bite.

KEEPERS (reusable, moved into mq-charsplit's test.sh):
- BASELINE NODE-ID BRITTLENESS FIX: base mode must NOT run parameterized rstest suites that agent solutions extend (per AGENTS.md "update related tests"). rstest names cases positionally, so an inserted #[case] RENUMBERS every later case and the node-id-keyed verifier reports "base tests were missing from the JUnit XML (exit code 0)" despite cargo exit 0. This hit ALL 10 runs (6 FAIL_TEST_BROKEN). FIX: scope base mode to stable, agent-untouched modules (cargo test --lib --skip <feature-area-test-modules> + property/proptest suites, whose names are stable), so no tracked baseline node-id lives in the edited area. Same family as lessons-learned.md:1085 (DETRAND proto.String() name flake) - the fix is stable baseline identities.
- STDLIB .mq REGRESSION COVERAGE: a runtime-semantics change (regex->literal split) can silently break a .mq stdlib module (semver.mq used split(v,"\.") regex-escaped). cargo test does NOT run the .mq suite (mq-test binary does). Run it in base mode via `cargo run -p mq-test -- builtin_tests.mq module_tests.mq`; mq-test halt(1)s on any .mq failure so exit code is reliable (no emoji parsing); inject one stable synthetic testcase into the JUnit.

---

## kitesql-grouping-sets (Rust, SHELVED 2026-07-07 - DERIVATIVE, precheck plagiarism FAIL 93.6%)

**Repo:** KipData/KiteSQL (~726 stars, cold niche Rust SQL engine). Aggregate pipeline: binder + planner + optimizer + execution.

**Pick:** OLYMPUS. Add GROUP BY GROUPING SETS / ROLLUP / CUBE + the GROUPING()/GROUPING_ID function. Built end-to-end, 7-subsystem span, dedicated GroupingSetsAggExecutor, 4 interdependent+misdirecting walls, f2p 8/8, C1=452. Locally clean.

**Killed:** platform PRECHECK, before any batch. Plagiarism check FAIL at **93.6% similarity** (threshold 0.90) vs an OLDER submission; AI-Dedupe **Duplicate 89-90% conf** vs TWO older KiteSQL grouping-sets submissions. The prior art implements the identical feature core: `grouping_sets: Vec<Vec<usize>>` on the aggregate op, an `AggKind::Grouping` / grouping AST node, per-set aggregation with NULL-fill for rolled-up columns, GROUPING() computed from set membership, ROLLUP=prefixes / CUBE=powerset / GROUPING SETS=listed with cross-product for multiple elements. My "differences" (dedicated physical operator vs HashAgg extension, multi-arg GROUPING+GROUPING_ID, aggregate-in-grouping-term guard, aggregates-before-groupby column order) were ALL judged INCREMENTAL - they do not touch the shared FEATURE CORE, so they do not clear a high-conf feature-core flag (same DEDUPE LAW as gms-view-dml / gogeom-de9im-relate).

**Root cause (new death class): TEXTBOOK SQL-STANDARD FEATURE.** GROUPING SETS/ROLLUP/CUBE/GROUPING is a canonical, spec-defined SQL feature. Multiple authors independently implement the SAME canonical semantics with the SAME natural data model (indices into distinct group-by exprs) - convergence is near-total because the SQL standard fixes the behavior AND the obvious Rust representation. A cold repo does NOT protect against this: coldness protects against maintainer-shipped / issue-mined dedup, NOT against another AUTHOR picking the same famous feature. The similarity is behavioral+structural, not textual, so rewording meta / swapping the executor shape / adding GROUPING_ID cannot move it below 0.90.

**LAW:** for a SQL engine, a named standard-SQL feature (GROUPING SETS, window functions, CTE/recursive CTE, set-ops EXCEPT/INTERSECT, LATERAL, MERGE, PIVOT) is HIGH derivative risk regardless of repo coldness - the canonical semantics + canonical data model make independent implementations near-identical on the feature core. Before authoring a standard-SQL feature, assume a prior author already did it and that the platform similarity/dedupe check compares FEATURE CORE (op field + AST node + executor behavior), which no packaging change clears. Prefer an INVENTED / repo-specific semantic wrinkle (a non-standard extension, a correctness bug in an existing path) over a textbook feature. Confirmed-taken KiteSQL classes: GROUPING SETS/ROLLUP/CUBE (2 prior subs). Do NOT re-pick.

## gql-row-comparison (SHELVED DERIVATIVE 2026-07-07)
Repo AmrDeveloper/GQL. Row-value ordered comparison (`< <= > >=` + `<=>` + 3-valued NULL + membership). Built end-to-end, Counter-2 133, 27 tests, fully validated. AI-dedupe = **Derivative 90%** vs an OLDER SUPERSET candidate that already implements row ordering + null-safe eq + ANY/ALL + IN/NOT IN + BETWEEN + IS DISTINCT FROM + MIN/MAX-on-rows + ORDER-BY-total-order.
ROOT CAUSE / LAW: **you cannot out-add a superset.** Row-value comparison is a textbook SQL surface; independent authors converge on the identical lexicographic-3-valued CORE, which drives the high-confidence flag. Adding more row features (I added group membership for LOC) CONVERGES toward the superset, not away. Same death class as kitesql GROUPING SETS (93.6%) and gms view-DML. To beat: change TRAP CATEGORY / pivot FEATURE, not add. Pivoted (same repo) to gql-null-semantics (aggregate + comparison NULL bug-fix = different trap category, non-convergent, bug-flavored). In rejected/gql-row-comparison.

## gql-null-semantics (SHELVED DERIVATIVE 2026-07-08, in rejected/)
Repo AmrDeveloper/GQL. SQL three-valued NULL logic (comparisons/AND-OR/BETWEEN/filter + aggregate NULL: COUNT non-null, AVG float/fractional/divisor-fix, MIN/MAX seed, empty->NULL, group_concat, bool_and/or). Built + hardened across 5 rounds (89%->60% pass via type-layer wall + `<=>` null-safe exception + BETWEEN panic + HAVING interdependence; 40 tests, Counter-2 123).
AI-dedupe = **Derivative 90%** vs an OLDER same-repo GQL 3VL-NULL submission (broader on operator-propagation: arithmetic/unary/contains/like/regex/bitwise/cast/index/slice/IN/ANY-ALL). ⭐⭐⭐LAW REAFFIRMED (2nd GQL derivative): additive differentiation moved dedup 88%->90% (WORSE) - `<=>`/float/COUNT/type-layer are "additive slices around a shared core." CANNOT OUT-ADD A SUPERSET. The structural conflict: DIFFICULTY needs the comparison/type-layer/3VL core (= Candidate 1's core); DIVERGENCE needs to avoid it. Can't be both.
⭐⭐⭐GQL EXHAUSTED for non-derivative Mars: popular SQL engine, mainstream features (comparison/grouping/null/aggregate) all have prior art + converge. row-comparison + null-semantics both derivative; array-ops sub-floor (24 C2). DO NOT re-pick GQL SQL-feature problems. HARDENING LESSONS worth keeping: type-layer-is-the-wall (agents fix evaluator, miss parser/type adverts); `<=>` exception = interdependent trap (one guard, opposite requirements); STOOLAP multi-path de-prescriptivize.

**UPDATE 2026-08-21 — extend to window functions (3rd GQL shelve, this time too-easy not derivative, see `gql-window-cumulative-rank` below).** RANK/DENSE_RANK/PERCENT_RANK/CUME_DIST hit the SAME wall from a different direction: not a dedupe collision this time, but full agent convergence (89% aggregate pass across 5 batches) even after a genuine, contract-stated, fix-hidden trap (named-window resolution order) and an evidence-based F-10/F-9/F-1 lever search that found nothing further. **GQL EXHAUSTION now covers comparison/grouping/null/aggregate/window** — every textbook-SQL feature class tried in this repo has died, by two different mechanisms (derivative collision for comparison/null, thoroughness-gate convergence for window). Treat the repo as DEAD for any named-SQL-standard-feature pick regardless of which specific feature is untried; the pattern is the repo (mainstream SQL engine, agents already know the target semantics cold) not the individual feature.

## gql-window-cumulative-rank (Rust, SHELVED 2026-08-21 - TOO-EASY, thoroughness-gate convergence)

**Repo:** AmrDeveloper/GQL (base `3a76cfe`, third GQL shelve — see `gql-row-comparison` and
`gql-null-semantics` above). Feature: ordered cumulative window frames plus `RANK`/`DENSE_RANK`/
`PERCENT_RANK`/`CUME_DIST`. Fully authored + validated: 264 human-effective LOC across 5 files,
31 tests, 9 rounds of iteration, DESIGN.md shape O-Pipeline-hard with 4 named traps. A real
fairness bug was caught and fixed mid-flight (meta.md's `CUME_DIST` sentence described an
absolute value comparison while the correct, standard-SQL solution behavior is scan-order-relative
under `DESC` — wording fixed, no solution code changed).

**Killed:** FIVE platform batches, aggregate **17/19 pass (89%)**: batch 1 4/4, batch 2 2/2, batch
3 2/2, batch 4 7/9 (the only batch with real failures), batch 5 2/2. Round 2's hardening (5 new
F-10 cross-product tests: multi-expression tie-breaking, DESC ordering, partitioned cumulative
aggregate, RANK/DENSE_RANK argument-arity) moved the rate 0 points against the real Batch-1
patches, confirmed by differential replay, not prediction. Round 3 added the PERCENT_RANK/CUME_DIST
whole-partition-exception lever (the only genuinely new solution-code requirement added after
launch) — this produced the ONE real, contract-stated, fix-hidden trap this problem ever had
(named-window resolution order, discovered as a side effect of the Auto Review S1 finding, not
designed in from the start), which caught 2/9 in batch 4 and nobody elsewhere. Round 8 then ran
the full evidence-based lever search (F-10 cross-product cells -> F-9 cross-stage resolution drop
-> F-1 convergent-architecture wall) against real passing/failing patches and the parser's actual
control flow, not mutation guesses, and found every remaining axis already convergent: the
PERCENT_RANK/CUME_DIST formula (5 passing agents read in full, identical implementations), the
named-window x whole-partition-exception combination (all 7 passers generalized their fix to the
full 4-function set via a shared helper, not special-cased), and the cumulative-frame dispatch
mechanism itself (two passers restructured the dispatch code in genuinely different ways and
landed on identical output).

**Root cause / LAW (THOROUGHNESS-GATE CONVERGENCE, same family as go-geom-distance and
fundsp-feedback-edge, textbook-SQL variant):** `RANK`/`DENSE_RANK`/`PERCENT_RANK`/`CUME_DIST` are
named, standard SQL window functions with widely known, precisely fixed semantics — an agent does
not need to derive anything novel, it already knows what the answer looks like before reading the
meta. The fairness gate then forces the meta to state that semantics precisely (rank position,
tie-skip behavior, whole-partition size for the two distribution functions, ordering direction),
which is exactly the information an agent already has memorized. The result is a single shared
architecture (cumulative-frame dispatch + a signature-based order-key-required helper) that every
independent agent reaches on the FIRST attempt, and every "wall" you can state in the contract gets
satisfied as a side effect of implementing the well-known algorithm correctly — the SAME mechanism
`gql-null-semantics`'s "GQL EXHAUSTED" note already named for comparison/grouping/null/aggregate,
now confirmed for window functions too. The one exception (named-window resolution order) survived
specifically because it is NOT part of the window-function algorithm itself — it is a parser
plumbing bug (validate-before-resolve) orthogonal to what RANK computes, which is exactly why it
discriminated where the SQL-semantics traps did not.

**Tell at pick time:** if the feature is a NAMED item from the SQL standard's own vocabulary
(window function family, GROUPING SETS, CTE, EXCEPT/INTERSECT, MERGE, PIVOT — see the Death-Class
Taxonomy row above) in a SQL-flavored query engine, assume convergence regardless of how novel the
repo's OWN prior art looks; the agent's prior knowledge of the SQL standard is the oracle, not the
repo. A genuine cross-subsystem trap (like the named-window one found here) can still exist, but it
will be PLUMBING-shaped (parser/resolver ordering, cross-package validation-vs-emission splits),
never semantics-shaped, and one plumbing trap alone is not enough to clear the ceiling on a
feature this well-known. Cost: 9 authoring/hardening rounds + 5 batches (19 agent runs). Artifacts
in `rejected/gql-window-cumulative-rank` (fully validated; reference only, including the real
`CUME_DIST`/`DESC` fairness-wording lesson, worth reusing if any future SQL-window-function pick
is attempted anywhere).

## rhai-spread-operator (Rust, SHELVED 2026-07-11 - DERIVATIVE, precheck plagiarism 82-88%)

**Repo:** rhaiscript/rhai (~5.5k stars, active embedded scripting engine). Feature: `...` spread operator across array literals, map literals, and function-call arguments; prefix+postfix; any iterable source (array/range/blob/string/registered-iterator); compile-time constant folding; call-arity re-hash. Built end-to-end, 6 files, Counter-2 261, f2p 48/48, base 126tc/0 regressions, fully validated.

**Killed:** platform AI-Dedupe **Derivative** across TWO rounds vs an OLDER pipeline Rhai spread+destructuring submission (another author). R1 = 88%, R2 (after strengthening) = 82%. My differences (prefix+postfix vs prefix-only, any-iterable-via-iterator-protocol vs array-only, compile-time const-fold, no destructuring surface, custom/fallible-iterable tests, left-to-right eval-order) LOWERED confidence 88%->82% but did NOT flip the verdict - the shared FEATURE CORE (Expr::Spread + parser in array/map/call + eval splice/merge + call-arity re-hash by post-expansion arity) is inherent to "spread operator" and drives the flag.

**Root cause / LAW (reaffirms DEDUPE LAW a 3rd time, now for a LANG repo):** additive differentiation cannot clear a feature-core twin - the difficulty core (splice + arity re-hash) IS the shared core, so DIFFICULTY and DIVERGENCE conflict (same structural bind as gql-null-semantics, gql-row-comparison, kitesql). **GitHub SIX-CHECK is BLIND to pipeline collisions** ([[lesson_platform_similarity_blind_spot]]): #684 (destructuring) open + no spread PR on GitHub, yet the platform had a prior-author spread submission the SIX-CHECK cannot see. Coldness/recency checks do not protect against another author picking the same famous language feature.

**rhai syntax-sugar space CONFIRMED-SATURATED in the pipeline** (from the 5 dedup candidates): spread operator (2+ subs), destructuring/rest-patterns in let/const/for (3+ subs), tuple type + tuple destructuring. Do NOT re-pick any collection/binding SYNTAX feature in rhai. For a non-derivative rhai Olympus, pivot to a DEEP ENGINE subsystem with an INVENTED semantic wrinkle / correctness bug (numeric coercion, operator dispatch, switch semantics, optimizer correctness, closure capture), NOT new collection syntax. Artifacts in rejected/rhai-spread-operator (fully validated; reference only).

## lol-html-sibling-combinators (Rust, SHELVED 2026-08-01 - DERIVATIVE, AI-Dedupe verdict `duplicate` 0.80 sim / 0.91 conf)

**Repo:** cloudflare/lol-html (~2k stars, streaming HTML rewriter). Feature: the `+` / `~` sibling
combinators plus `:is()` / `:where()` compound selector lists in the compiled streaming selector VM.
Built end-to-end and fully validated: 9 files, Counter-2 292, 66 f2p tests, base 185tc / 0
regressions, 5x flakiness clean, 0 compiler warnings, Docker offline + non-root green, and all 8
natural-but-wrong implementations reproduced and measured.

**Killed:** platform AI-Dedupe returned overall **duplicate** on the FIRST check. Candidate 1
(older, another author) implements the SAME two capabilities at the SAME five surfaces -
`parser.rs` (accept NextSibling/LaterSibling + `parse_is_and_where`), `ast.rs` (sibling branch
vectors on `AstNode`), `program.rs` (sibling jump ranges on `ExecutionBranch`), `mod.rs` (sibling
jump execution + bailout pointer), `stack.rs` (parent/root sibling continuation sets). The engine
named my only differences as "internal strategy for matches-any and minor plumbing variations,
which do not change observable behavior or scope". Candidates 2 and 3 (both older, both
`similar_idea`) independently cover `:is()`/`:where()` in the same VM, one of them going FURTHER
(combinator-bearing alternatives, ancestor hoisting, complex `:not()` on the subject via probe IDs
and ConditionalMatch).

**Root cause / LAW (reaffirms the DEDUPE LAW):** BOTH capabilities were individually taken and
their combination was exactly the prior submission. There was no additive escape - dropping
`:is()` leaves candidate 1's sibling work; dropping siblings leaves three prior `:is()` subs, one
of which is a strict superset ("you cannot out-add a superset"). The GitHub SIX-CHECK was CLEAN
and stayed clean: issues #67 (adjacent sibling) and #300 (`:is()`/`:where()`) are both OPEN with
ZERO comments and NO PR. **Two open, uncommented, unimplemented feature requests are a MAGNET, not
a moat** - they are exactly what every other author picks first, and the SIX-CHECK cannot see the
prior-author pipeline. An unimplemented open issue with no discussion is now a derivative-RISK
signal, not a green light.

**lol-html `src/selectors_vm/` is CONFIRMED-CONTESTED** (>=3 prior subs from the dedup candidates).
Do NOT re-pick ANY selector-syntax feature there - the remaining unimplemented forms
(`:nth-child(An+B of S)`, namespaced selectors, `:empty`) touch the same parser/ast/compiler/stack
surfaces and would flag the same way. `:has()` and the `:last-child`/`:only-child` family are
separately dead: maintainer declined `:has()` on issue #145 because streaming cannot look forward.
A non-derivative lol-html pick must leave the selector matcher entirely (rewriter /
rewritable_units / transform_stream / parser state machine). Artifacts in
`rejected/lol-html-sibling-combinators` (fully validated; reference only).

## dyon-secret-arithmetic (Rust, SHELVED 2026-07-14 - LOC-CEILING sub-floor, Gate 4)

**Repo:** PistonDevelopers/dyon (~1.9k stars, original scripting lang). Feature: make the `secrets`
provenance feature survive the numeric pipeline - `sec[f64]` arithmetic (`+ - * / % ^`), `sum`/`prod`
provenance vectors, both-secret concat, compound-assign. Implemented the full 4-wall design end-to-end;
compiles clean (cargo check rc=0), mechanism verified.

**Killed:** LOC build-measure, BEFORE any batch. Hook `human-effective = 79` (Olympus floor 250),
padding-floor = 25 (breadth-flagged). Root cause = **the provenance machinery ALREADY EXISTS**:
dyon's `min`/`max`/`any`/`all` loops and comparison operators already carry `Secret(_)` provenance
(module.rs registers the `less` ext overload `(Secret(F64),F64)->Secret(Bool)`; min/max runtime push
the winning index as secret). Threading it through arithmetic is 2 ext-overloads/operator in module.rs
(the exact `less` model) + a symmetric secret-concat in dyon_std + a conditional `sec[f64]` type +
provenance-vector in for_n. Every per-site change is 1-3 lines and REPEATS across 6 operators (amortized
breadth). Maximal coherent expansion (unary math sqrt/abs/ln/exp, bool-secret logic, canonical merge)
tops ~150-190.

**Root cause / LAW (LOC-CEILING, PICK-FILTER Gate 4):** a feature that THREADS AN EXISTING CAPABILITY
through more call sites is surgical (~1-3 LOC x N sites = amortized breadth), NOT a genuinely-large
missing core - sub-floor every tier, and Gate 4 explicitly discounts the additive bundling used to
inflate it. The tell at pick time: the subsystem you extend ALREADY implements the feature for a
sibling construct (here: secrets already flow through loops+compare). Durable Olympus = a genuinely-
LARGE MISSING core (a whole new operator/algorithm/capability the engine cannot do at all), not a
"also make X carry it" extension. Confirmed cost: measured 79 eff before wasting an eval batch. Do NOT
re-pick. Mechanism notes preserved in rejected/dyon-secret-arithmetic/feedback.md. Pivoted to gluesql
joined-DML (write-side DML = a genuinely-new executor capability).

## iced-x86-pointer-data-dedup (Rust, SHELVED 2026-08-22 - machinery-absorbed sub-floor, Gate 4)

**Repo:** icedland/iced (x86/x64 disassembler/assembler, ~3.5k stars). Feature: deduplicate the
`BlockEncoder`'s 64-bit long-branch trampoline pointer-data slots so two or more relocated branches
targeting the same final address (another relocated instruction, or a fixed external address) share
one 8-byte slot instead of each allocating their own. Fully built end-to-end: `TargetInstr::dedup_key`
+ a keyed lookup on `Block` + reference-counted release, 7 new tests covering both target forms and
the no-over-merge negatives, `test.sh` cargo2junit Dockerfile, meta.md, all locally validated (clean
apply/unapply both orders from BASE_COMMIT, base/new both correct, 3x flakiness identical).

**Killed:** LOC gate, pre-submit, after TWO genuine scope-expansion rounds. First measurement 60
effective (Counter 1) across 6 files. Root cause = the repo's own `TargetInstr` enum
(`Uninitialized|Instruction(usize)|Address(u64)|IsOwner`) already carries the exact identity a dedup
key needs, and the existing `Rc<RefCell<BlockData>>` handle is already shared-pointer-shaped - the
fix is "look up a key before allocating, refcount the release" = ~35 real lines in `block.rs` + a
1-line call-site update x4. Expansion round 1 (a `pointer_data_sharer_counts` field on
`BlockEncoderResult`) added 9 lines. Expansion round 2 (a full `pointer_data_indices` per-instruction
field, correctly requiring an `Instr` trait signature change across all 7 impls plus a genuine
allocation-index -> final-reloc-position remap since an instruction's encode-time index does not
equal its final position once an earlier slot can be excluded) still only reached 126 effective
across 10 files - both expansions were real, tested, non-padding, and still insufficient.

**The dead end that confirmed no further real expansion existed:** the design's second trap (shared-
slot correctness under reference-counted release) could not be exercised by any reasonably-sized
fixture. Proof, not a failed search: `correct_diff` (block_enc/instr/mod.rs) only applies the
convergence (`gained`) adjustment when the target is in the SAME block; for every target class
eligible for the release code path (external-address or cross-block instruction targets) the
Long/Near/Short determination is invariant to iteration count in any construction not requiring an
artificially deep, multi-level shrink-dependency chain before the target. FP mutation testing
confirmed this empirically: unconditionally invalidating on any release call (removing the reference
count) passed all 133 tests.

**Root cause / LAW (MACHINERY-ABSORBED, PICK-FILTER Gate 4 - second confirmed instance, see
canvas-fill-rule-backends above):** a repo whose existing internal representation already has the
exact shape a capability needs (here, an enum that IS the dedup key; a generic `Settle`/walker/
resolver there) turns "add capability X" into "add a lookup", and lookups don't clear 200 effective
no matter how many correct, real, non-padding companion features you bolt onto the SAME chokepoint -
every companion feature routes through the same already-absorbed primitive, so it inherits the
thinness rather than escaping it. The tell at pick time: can you name the missing machinery in ONE
sentence, or does the natural fix read as "call the existing X differently"? If the latter, the LOC
ceiling is real regardless of how rich the seam looked in the hunt-stage trap audit (F-9/F-18/F-10
were all genuinely present here and still weren't enough - trap RICHNESS does not substitute for
missing SIZE). Confirmed cost: a full author-through-local-validation cycle (Dockerfile, 7 tests, 3
mutation checks, 2 expansion rounds) before the LOC gate caught it - should have been caught at the
DESIGN.md sketch stage per `HARDENING.md`'s "sketch the DIFFERENT before ranking" rule; the design
sketch here (180-220 estimated) overshot the eventual 126 by nearly 2x, matching the canvas-
fill-rule-backends precedent's 213-estimated-vs-44-actual overshoot pattern almost exactly. Do NOT
re-pick this feature class in iced-x86 or any repo whose core type already models the target
identity a dedup/sharing feature would key on. Full account: rejected/iced-x86-pointer-data-dedup/
feedback.md.

## async-graphql-overlapping-fields (Rust, SHELVED 2026-07-16 - DERIVATIVE 88%, spec-convergent twin, DEDUPE LAW)

**Repo:** async-graphql/async-graphql (~3.7k stars, original GraphQL server engine). Feature: complete the
`OverlappingFieldsCanBeMerged` validation rule to enforce GraphQL spec 5.3.2 - recursive subselection
merging + mutual-exclusivity from possible-types intersection + SameResponseShape (applies even to
mutually-exclusive fields) + PairSet fragment-cycle memoization. Full submission authored + LOCALLY
VALIDATED end-to-end: 312 human-eff LOC, 2 files, 24 tests / 12 F2P, both apply orders + reverse-apply
clean, 3x flakiness deterministic, base 268-pass zero-regression, SIX-CHECK clean (issue #943 is the
band-aid this completes, not a maintainer decline; no completing PR). Technically the MORE COMPLETE
version (registry-driven `type_overlap` vs priors' object-only heuristic).

**Killed:** platform AI-dedupe returned **Derivative | 88% | Candidate 1** (verdict "derivative") +
Candidate 2 78% ("similar_idea"/Adjacent). Both priors are OLDER. Candidate 1 = validation-only twin
(same 4 algorithm pieces, same "conflict" messages, same PairSet). Candidate 2 = the execution-side
field-merge angle (groups fields by response-key at resolution + nested "subfields ... conflict"
aggregation). AI verdict on my registry-overlap divergence: "narrows scope but doesn't change the core
exercise ... a trimmed variant of the same task."

**Root cause / LAW (reaffirms DEDUPE LAW / CANNOT-OUT-ADD-A-SUPERSET a 4th time, now for a spec-defined
validation rule):** a GraphQL-spec-defined feature is SPEC-CONVERGENT - 5.3.2 + graphql-js define ONE
algorithm, so every correct author writes the same 4 pieces; differentiation on the same feature is
structurally impossible (same bind as gql-null-semantics, gql-row-comparison, kitesql, rhai-spread).
Worse, BOTH natural angles were already taken: the VALIDATION angle (reject query = Candidate 1) AND the
EXECUTION angle (merge fields by response-key = Candidate 2). When both the validate-side and the
execute-side of a topic are occupied, the topic is fully saturated - adding the execution consequence
makes you MORE like the other twin, not less. **GitHub SIX-CHECK is BLIND to these prior submissions**
([[lesson_platform_similarity_blind_spot]]): no PR/issue on async-graphql for this rule, #943 looks like
an open invitation, yet TWO prior-author submissions existed that only the platform dedupe can see.

**In-repo pivot also dead:** async-graphql is a MATURE engine - empirically ruled out 4 candidate
subsystems for a second clean Olympus f2p: validation siblings (complete/Mars-shallow), look_ahead
(@skip/@include already pre-pruned by `remove_skipped_selection` before resolvers run), input coercion
(Vec::parse already does single-value->list), null propagation (spec-6.4.4-CORRECT: probed - nullable
list element error nulls just that element, `[T!]` element error bubbles the whole field). LAW: a mature
well-maintained engine has FEW genuine f2p gaps; the rare one (overlapping-fields) gets taken first.
Confirmed cost: full authoring cycle + local validation, killed at platform dedupe (SIX-CHECK could not
have caught it). Do NOT re-pick this rule OR the execution field-merge angle. Artifacts in
rejected/async-graphql-overlapping-fields (fully validated; reference only).

## go-geom-distance (Go, SHELVED 2026-07-16 - 100% pass x2 batches, POINTWISE-DECOUPLED LAW)

**Repo:** twpayne/go-geom (base 4deaa45c, same as approved polygonize). Feature: JTS DistanceOp +
DiscreteHausdorffDistance port - GeometryDistance/NearestPoints/IsWithinDistance/PointDistance +
Hausdorff family + geojson consumer. Fully authored + validated: 263 human-eff, 4 files/2 pkgs, 73
tests, all pre-checks eventually green (Solution Quality NaN-guard fix, Test Fairness value-pin fix).

**Killed:** TWO consecutive platform batches at 100% pass. Round 1 harden = tighten meta + add 15
interdependent/misdirecting tests (containment chokepoint + nearest-point consistency walls,
test.patch 397->567) - rate did NOT move. Diagnosis confirmed structural, not calibration.

**Root cause / LAW (POINTWISE-DECOUPLED = THOROUGHNESS GATE, no forcible interdependency):** distance
measurement is a pointwise reduction over a facet set - min-distance, nearest-points,
within-distance, Hausdorff are INDEPENDENT reductions with no shared mutable/ordered state. Every
fair test is passed by the obvious brute-force O(n*m) facet loop + containment check; "walls" reduce
to ONE fix at ONE chokepoint (pointWithinPolygon), and every failing assertion self-reveals its rule.
You cannot force a spatial-index/traversal bug (that would be HOW, not WHAT), so no local fix ever
regresses another path. The tell at pick time: the feature's sub-operations can each be implemented
independently by a per-item loop with no cross-item consistency constraint -> thoroughness gate,
~90-100% pass, dead at every tier. Contrast: the SAME repo's polygonize (noding -> ring orientation
-> hole assignment, global consistency) approved at 30%; the pivot go-geom-simplify (vertex removal
under a GLOBAL no-crossing invariant, mutation-coupled) is the fix-class. Durable law: pick
GLOBALLY-COUPLED algorithms (a local decision constrained by a whole-geometry invariant, stateful
pipelines, order-dependent mutation), never pointwise measurements/predicates, no matter how
algorithm-flavored they look. Cost: full authoring + 4 revision rounds + 2 wasted batches. Artifacts
in rejected/go-geom-distance (fully validated; reference only).

## fundsp-feedback-edge (Rust, SHELVED 2026-07-17 - 100/90/100/100 across 4 batches, ARCHITECTURE-CO-SOLVE + DERIVABLE-WIRING LAW)

**Repo:** SamiPerttu/fundsp (base 5595840, audio-DSP graph engine). Feature: first-class one-sample
(later N-sample ring) feedback edges in the dynamic Net graph - connect_feedback/_delay,
cycle-rule opt-in, byte-identical tick/process/chunked, reset/allocate clearing, combinator +
remove + crossfade + backend/commit integration, Tarjan region + weighted-Dijkstra loop_delay
introspection. Fully authored + validated: 336 human-eff, 2 files, 68 tests (1315-line test.patch),
6 hardening rounds (R1-R6), 4 mutation-proven walls, all pre-checks green after fairness repair.

**Killed:** FOUR platform batches: 100% -> 90% -> 100% -> 100%. Escalation ladder tried in order:
(R3) 4 interdependent walls per Section-1 star categories, trap-proven 8/47 against the prior
passing solution; (R4) Rule-7 de-enumeration + machinery walls (push-order, crossfade-in-loop,
remove x commit); (R5) coupled sub-feature reshape (N-sample delay rings) with 4 mutation-proven
walls; (R6) fairness-forced continuity rule. Nothing moved the rate; solves got FASTER
(80min -> 15-24min).

**Root cause / LAW (CORRECT-ARCHITECTURE-ABSORBS-ALL-COMPOSITIONS, wiring variant of
POINTWISE-DECOUPLED):** the feature has exactly ONE natural architecture (edge flag + per-edge
delay state + shared per-sample step path + id-matched migrate) and the meta+repo jointly force it:
the repo's own FeedbackUnit exhibits ring+index+dual-path, the combinators exhibit edge rewiring,
migrate exhibits state carry. Once an agent adopts that architecture - and every passer did -
every wall (composition, chunk-straddle, push-order, ring continuity) is satisfied AS A SIDE
EFFECT. Mutation proofs only certify tests discriminate against WRONG implementations; they say
nothing about whether agents ever WRITE the wrong one. The op-set interactions
(stack/pipe/bus/branch/chain/remove/crossfade/commit/set_source) are independently fixable
behaviors with no cross-regression = a thoroughness gate, and steroid-era Nova clears thoroughness
gates at 100%. The fairness gate completes the kill loop: every wall here is wiring on NOVEL
semantics, novel semantics must be STATED (de-prescription floor), and stated wiring is
transcribed. The tell at pick time: if the repo contains an ORACLE (a sibling unit/helper that
already implements the feature's core mechanism), the difficulty budget is capped at
transcription + thoroughness regardless of how many "subsystems" the wiring touches. Contrast the
survivors: difficulty must live where the OBVIOUS implementation is WRONG (glaredb DISTINCT path,
stoolap hash buckets) or in irreducible COMPOSITION depth of the domain math (go-geom collinear x
containment, zen bound-transforms) - trivial pass/mul recurrences have no such depth by
construction. Cost: 6 authoring rounds + 4 batches (40 Nova runs). Artifacts in
rejected/fundsp-feedback-edge (fully validated; reference only).

## customasm-asm-block-expr-substitution (Rust, SHELVED 2026-07-30 - LOC-CEILING, ORACLE-ABSORPTION)

**Repo:** hlorenzi/customasm (~1052 stars, Apache-2.0, assembler for user-defined instruction
sets). Cold: 34 commits in 12 months, 0 in the trailing 90 days. Not saturated, no quota use.

**Pick:** widen the brace substitution inside `asm { }` blocks from a single bare name to a full
expression, evaluated at the right point in the block's fixpoint so it can see the block's own
labels and the program counter.

**Built end-to-end and fully validated.** 691/691 base tests green, 32 new fixtures (28 fail on
base), both apply orders plus reverse-apply clean, flakiness deterministic with byte-identical
JUnit XML across 3 runs, zero compiler warnings, zero comments, no scope creep, SIX-CHECK and
exclusivity clean. It is a GOOD problem. It is not a shippable one.

**Killed by the long-horizon floor, measured after building:** Counter 2 = **167 effective across
1 file**, against the 200 / 2-file floor. Counter 1 = 206, so the platform auto-block would not
have fired; the human count is the binding one and it was short.

**⭐⭐⭐ ROOT CAUSE / NEW LAW - ORACLE-ABSORPTION COLLAPSES THE LOC SKETCH.** The design-time
footprint sketched **~318 meaningful across 5 files**. Reality was 167 across 1. Every piece
costed as independent work was absorbed by machinery that already existed:

| Piece | Sketched | Actual | Absorbed by |
|---|---|---|---|
| `$` / pc threading | 24 | ~0 | `inner_ctx` already carried the per-instruction position |
| Nested `asm` blocks in expressions | 36 | **0** | `Expr::Asm` is already an `expr::Expr` variant and already evaluates |
| Guess propagation | 42 | ~20 | `handle_value_resolution` + `ResolutionState::merge` already existed |
| Error span mapping | 27 | **0** | the walker is already built with the original file handle and line offset |

This is the **fundsp ORACLE law arriving on the LOC axis instead of the difficulty axis.**
fundsp's version: "if the repo contains an ORACLE that already implements the feature's core
mechanism, the difficulty budget is capped at transcription." The LOC corollary: **the same oracle
caps the SIZE budget.** A feature that plugs into a mature, well-factored resolver/evaluator stack
will come in far under any sketch, because the sketch prices sub-tasks as if the surrounding
machinery did not exist.

**PICK-TIME TEST (cheap, do this before authoring):** for each line item in the footprint sketch,
ask "does the repo already do this for a sibling construct?" Count only the items where the answer
is NO. Here, 4 of 8 line items were already-solved, and they were exactly the ones inflating the
estimate to clear the floor. Same family as dyon-secret-arithmetic (LOC-CEILING, provenance
machinery already existed) and golang/geo (Hausdorff sketched 330, measured 49) - but the tell
here is sharper: it was not one existing helper, it was the whole surrounding stack.

**What was explicitly NOT done:** pad. The tempting lever was `#d` data directives inside asm
blocks to reach 200. That is the participle `Greedy()` scope-creep failure and HARDENING 3d's
"never pad LOC with public API". A ~170-LOC feature stays a ~170-LOC feature.

**KEEPERS (reusable elsewhere, all validated):**
- **Rule-7 de-enumeration with a base-verified fairness proof.** The meta went 285 -> 176 words by
  replacing an enumeration (block labels / later labels / program counter / nested blocks) with one
  principle: "it sees the same names an instruction written in that position would see." The proof
  that this is fair rather than hidden: the UNMODIFIED base binary already resolves a forward label
  and `$` for an *unbraced* operand in the same position, so the principle is confirmable by the
  solver against base behavior. **De-enumeration is legal exactly when base behavior demonstrates
  the general principle** - run that check before de-enumerating.
- **No-substring-pin fix via empty excerpt.** customasm's fixture harness matches error kind + line
  with an empty excerpt after the line number, so a rejection test can assert "fails here" without
  pinning invented message wording (HARDENING 3d, data-forge law).
- **customasm's harness runs EVERY fixture twice** (`src/test/file.rs:190`), variant `00` and `11`
  of `optimize_instruction_matching` / `optimize_statically_known`. Every fixture is a free S5
  dual-path consistency check and failures name the VARIANT, not the cause. Strong free difficulty
  in any customasm pick.

**Repo verdict: customasm is NOT dead.** The repo is cold, clean, pure-Rust (3 deps), has a 691-test
0.26s suite, and carries a real fixpoint resolver. Only THIS pick is sub-floor. A pick with genuine
size (relocatable output + linking, informed by issue #48) would reuse this work as one component.
Artifacts in `rejected/customasm-asm-block-expr-substitution` (fully validated; reference only).

⚠️ **CORRECTION 2026-09-06 — the "#48 linking" recommendation above is DEMOTED, do not take it at
face value.** The RANK-time tracker probe (`repo-hunt-logs/REPO-HUNT-2026-09-06.md`) read issue #48's
BODY and comments and found it is a Stage-2b magnet: **two published design sketches** in the thread
(`theorzr`'s `#obj <format>` block, and `Phlosioneer`'s full `#external` upper-bound/alignment design
of 2022-08-30), an externally-named capability (ELF / COFF / relocation), a six-year-old request with
no PR (the "old invitation is a queue" profile), and a maintainer who moved the design discussion to
**Discord** on 2022-09-26, so philosophy is forming where the SIX-CHECK cannot see it.
**⭐ The generalisable lesson: a lane recommended in our OWN docs is a lead, not a cleared lane — it
still owes the tracker probe, exactly like an issue title does.**
The better customasm lane, measured the same session: a **bank PLACEMENT SOLVER**. Absorption probes
over all 20,660 LOC return ZERO hits for `free_space|placement|place_|allocat|bin_pack|layout`;
`#bankdef` takes only explicit constants (`addr`, `addr_end`, `size`, `outp`, ...) and
`util/overlap_checker.rs` merely VALIDATES a hand-written memory map afterwards. No issue asks for it
(#195 wants read-only `firstfree` symbols only). It is interdependent with the existing fixpoint by
construction, since variable-size encodings mean a bank's size is unknown until encodings settle
while encodings depend on addresses that depend on placement.

## cfn-guard-cidr-operator (Rust, SHELVED 2026-08-04 - 5/10 then 6/10 across two batches, SPEC-KNOWABLE PREDICATE LAW)

**Repo:** aws-cloudformation/cloudformation-guard (base 57bbdbf, Apache-2.0). Feature: IP/CIDR
comparison operators for the Guard language - `in_cidr`, `cidr_overlaps`, `is_cidr`, `is_ip`, then
`covered_by` added as a hardening lever. Fully authored + validated across 4 rounds: 384 human-eff
LOC / 8 files, 38 tests, f2p 38-on-solution / 0-on-base, base 287-green, deterministic 3x.
Pivot target from `cfn-guard-arithmetic` (shelved DERIVATIVE), so the repo has now cost two picks.

**Killed:** batch 1 = 5/10 (50%), batch 3 = 6/10 (60%) after a full hardening round. Both over the
40% cap. The rate went UP while the artifact got more correct.

**Root cause / LAW (SPEC-KNOWABLE PREDICATE DOMAIN):** CIDR containment and overlap are fixed by an
RFC and are DERIVABLE from first principles by any competent solver - mask the host bits, compare
the network. This is NOT saturated-reference-port (the agent has not memorised a library); it is
worse, because the agent can re-derive the entire specification correctly every time. A differential
harness run over 20+ fair probes against all 6 passers found **no fair test that splits them**:
single-host-uncovered, final-address-uncovered, unsorted union, overlapping ranges, mid-gap,
duplicates, IPv6 /0, adjacency-touch, mixed-family, empty-rhs, top-of-space overflow. Every passer
handled every probe. The passers were in fact MORE correct than the reference, which had 3 real bugs
(a `>=` in the union sweep, two missing reporter match arms, a u128 overflow at the top of the
address space) that the harness surfaced.

**Why the hardening lever failed.** `covered_by` (a target range covered by the UNION of a list of
CIDRs, where no single element contains it) was chosen precisely because the naive pairwise reading
is wrong and the fix is an interval sweep. It was correctly identified as a must-derive trap - and it
still did not move the rate, because "derive an interval sweep" is exactly the kind of thing a
competent solver derives. **A trap whose fix is a standard algorithm the solver can re-derive is not
a trap.**

**Where the difficulty actually lived, and why that does not help:** all 4 failing agents on the
final batch failed on WIRING (threading a new `CmpOperator` variant through exhaustive matches, both
reporters, and the parser's keyword-ordering constraint), not on semantics - 3 INTEGRATION_ERROR + 2
MISSED_REQUIREMENT on batch 1. D-new wiring difficulty is derivable from the repo's own existing
variants, so it is a coin flip on thoroughness, not a wall. Compare the fundsp DERIVABLE-WIRING law.

**The tell at pick time:** ask whether a competent solver with no repo knowledge could write the
predicate correctly from the standard alone. If yes, the only remaining difficulty is wiring, and the
pick caps out around 50-60% no matter how many edge cases the suite carries. Domains to treat as
spec-knowable: IP/CIDR, date-time arithmetic, unicode classes, checksums, base-N encodings, sorting
orders, set algebra. Contrast the approved calyx/neva picks, where the required behaviour is a
property of the REPO'S OWN model and cannot be derived from any external document.

**Also confirms REFERENCE-UNCHANGED:** when the differential harness finds no fair discriminator, the
measured rate IS the ceiling. Do not spend another round; shelve. Cost here was 4 authoring rounds
and 2 batches after the first result already showed 50%. Artifacts in
`rejected/cfn-guard-cidr-operator` (fully validated; reference only).

## canvas-fill-rule-backends (Go, SHELVED 2026-08-07 - UNDER-FLOOR at 44 effective LOC)

Not too easy, not derivative, not unfair. **Built end to end and verified correct**, then killed by
the long-horizon LOC floor. Recorded because every gate that normally kills a pick PASSED.

| Gate | Result |
|---|---|
| 1 behavioral-f2p-gap | CONFIRMED by running the public API, not inferred from a marker |
| 2 / 10 saturation + quota | PASS (0/6, not in SATURATED-REPOS) |
| 5 cold-not-live | PASS (3 open PRs, none on the fill-emission path) |
| 7b exclusivity | PASS (canonical org, all states, 0 hits) |
| 8 defined-behavior | PASS (repo's OWN doc `path.go:26` defines all four rules) |
| 9 flakiness | PASS (3/3 identical, sub-second) |
| **LOC floor** | **FAIL - 44 effective vs 200** |

**The gap was real and the fix was correct.** `FillRule` has four values; `Fills` and `Settle`
implement all four; six emitters honor two. A clockwise square under `Positive` must paint nothing
and PDF emitted `f`, SVG omitted the attribute, PS emitted `fill`, the rasterizer inked 256 of an
expected 0 px - and the rasterizer disagreed with the vector backends as well (it maps non-native
rules to the EvenOdd answer, they map to NonZero). After the fix: 0 px, native rules byte-identical,
whole suite green.

## ROOT CAUSE - the primitive had already done the work

`Path.Settle(fillRule)` already resolves any path under any of the four rules into a
non-overlapping, correctly-oriented equivalent. So "honor the rule" at a backend is:

```go
fillData := data
if !style.FillRule.Native() {
    fillData = path.FillGeometry(style.FillRule).Transform(m).ToPDF()
}
```

Three lines. Times six backends, plus a two-line helper, equals 44 effective LOC. **Multiplying
sites does not multiply LOC when each site is a call-through.**

**The estimation error to internalise:** DESIGN.md § 7 sketched "+70 raw, restructure the 4 PDF fill
sites and split the combined `B` operator." The actual PDF change was **+13 raw**, because splitting
`B` is one extra `&& style.FillRule.Native()` conjunct on the existing `sameAlpha` guard - the
existing `else` branch already emitted fill and stroke separately. I sketched the WORK; the repo had
already factored it. `PICK-FILTER` Gate 4 says sketch the hardest files in real code - the sharper
form is **sketch the DIFF, and before estimating any site, read what the existing branch structure
already does.**

**Operational rule:** at pick time, name the primitive your capability would call. If one exists and
your feature is "call it correctly in N places", the pick is under-floor before you write a line -
site count will not save it.

---

## Rejected-pick ledger — too-easy/under-floor/shelved reasons (Olympus1 + Olympus3 rejected/, consolidated 2026-08-20)

Compiled from the `rejected/` problem folders themselves (meta.md/feedback.md/REJECTED.md/SHELVED.md/
etc), not a prose log. One line per pick: `repo/feature — reason`. This is a separate, additive flat
list, not new taxonomy rows - it does not replace or renumber the Death-Class Taxonomy or the
case-study sections above. Entries whose repo name already appears in `SATURATED-REPOS.md`'s "Merged
dead-pick ledger" section were skipped as duplicates during consolidation.

- canvas-fill-rule-backends — shelved under LOC floor: 44 effective LOC vs 200 floor (213 sketched)
- cfn-guard-cidr-operator — too easy: measured 60% pass rate exceeds the <=40% ceiling; CIDR/covered_by logic is maximally knowable, no fair test can lower it (genuine ceiling)
- customasm-exact-fractional-values — too easy: 8/8 then 7/8 Nova across two batches; new value kind absorbed by a generic evaluator, differential harness found no fair discriminator outside the stated formula
- customasm-asm-block-expr-substitution — blocked on two hard gates: effective LOC 167 (need 200), 1 file (need 2)
- geo-hausdorff-distance — shelved under-floor: ~49 effective LOC vs floor
- taffy-last-baseline — shelved as a flexbox-only derivative probe, 52 eff LOC by design, below the 250 floor; full grid+baseline-groups build never completed
- taffy-visibility-collapse — cleared the derivative check but too easy: naive ~120-line solution is spec-correct, fails the >=250 LOC floor
- augurs-offline-changepoint — too easy (Nova 10/10 = 100% pass); named documented algorithm family (PELT/BinSeg/Dynp) with a public reference (ruptures) reduces to pure transcription
- casbin-effect-conflict-detector — shelved LOC-compact: correct algorithm only 93 human-effective LOC, far under the 250 floor; irreducible logic too compact to widen fairly
- dicom-rs-palette-color — dead on 4 independent structural failures (Verify FAIL, Test Fairness FAIL, LOC, env), shelved pre-submit
- doit-directory-deps — shelved under-floor: 102 human-effective LOC / 3 files vs the 250 floor; focused lib, the cohesive hard feature is irreducibly small
- go-feature-flag-experiment-layers — under LOC floor: 310 human-effective vs the 400 Olympus auto-block; structurally Mars-sized, not Olympus
- hickory-edns-options — shelved: breadth not distinct-decoder depth; uniform decoders amortize under the padding floor regardless of count
- iris-arithmetic-cube-components — 252 human-effective clears the 250 sprint floor but sits well under the 430-450 design target; seam is irreducible, cannot reach target without padding
- jet-loop-control-switch — shelved: R1 solvability sim showed 8/8 agents solve it = too easy, no fair pivot
- kin-openapi-param-serialize — shelved too-easy + under-floor: 235 eff LOC; mechanical inverse of an existing decoder, fully transcribable
- pynite-semirigid-connections — quarantined: compact-engine LOC wall, estimated max ~150-250 human-eff, no fair broadening reaches the floor
- s2-polyline-linemerge — shelved (too easy)
- salsa-cycle-backdating — correct golden fix only ~68 effective LOC, fails the >=250 floor; surgical bug fix too small for the Olympus tier
- peggy-left-recursion — reference spike correct but under the LOC floor; scope-expansion left incomplete when abandoned
- rspirv-decoration-group-resolution — REJECTED at platform Scope Gate, publicly-solved (not a batch/LOC shelve): Khronos SPIRV-Tools' `--flatten-decoration` optimizer pass already performs the identical group-to-concrete-decoration two-pass algorithm for both whole-object and member targets; fully authored, hardened, and locally validated (47 tests, 215 human-effective LOC, all patch/regression/flakiness checks clean) before the gate caught it — the same-repo `gh pr/issue` collision search never looks at sibling-ecosystem reference tools, see the new Death-Class Taxonomy row above

---

## dropflow-min-max-sizing (TypeScript, SHELVED 2026-09-11 - DERIVATIVE, overlap `Blocker` 204/290 = 70.3%)

**Pick:** CSS `min-width` / `max-width` / `min-height` / `max-height` threaded through chearon/dropflow's
parser, style cascade, block inline box model, float/inline-block shrink-to-fit, intrinsic
contributions, replaced-box ratio sizing (CSS2 10.4) and margin collapsing. 257 hand-written
effective LOC across 4 files, 92 tests, clean-room Docker validated. **No batch was ever run.**

**Verdict:** platform plagiarism step flagged an OLDER same-repo candidate; the LLM comparison stage
returned `Duplicate` at 90% confidence, and the precheck returned an overlap **Blocker**: *"204 of 290
discounted authored solution lines correspond (70.3%), including the task's primary min/max sizing
engine. Olympus tasks must not re-deliver an older candidate's main implementation challenge;
elaborating that engine with integrations and edge cases does not restore exclusivity."*

The cited rival diff shares the four declaration parsers, the re-resolve-margins-after-clamping
helper in the block inline box model, the shrink-to-fit clamp, and a ratio-preserving
`getConstrainedSize` on the replaced box. The platform's own "meaningful differences" list credited
us with margin-collapsing changes, contribution clamping and a different block-size clamp site -
then rated them incremental, exactly as the derivative rule says it will.

**ROOT CAUSE 1 - a published support matrix was read as a mitigation instead of a collision tell.**
dropflow's README carries a CSS property table; the row
`max-height, max-width, min-height, min-width | em, px, %, cm etc, auto | 🚧 Planned` sat directly
above the `position: absolute` row that PR #34 was at that moment implementing. The submit-time audit
FOUND that row, and logged it as evidence the lane was *maintainer-wanted* (softened hunt gate 6:
outsider-nameable is a mitigation, not a reject). That is backwards. A roadmap table is the single
most shared pick list a repo can publish: it enumerates, ranks and pre-qualifies the authorable
lanes for every author who opens the repo. The correct reading of "Planned" is *someone else has
already picked this*, and PR #34 was the proof standing right next to it - a rival had already taken
the adjacent row.

**ROOT CAUSE 2 - the whole exclusivity audit could only see GitHub.** The submit-time SIX-CHECK was
run properly and came back genuinely clean: canonical org resolved, PRs searched by feature class in
all states (only #34, whose diff was pulled and confirmed to touch zero min/max machinery), 31 issues
read with no refusal and no min/max request, base commit confirmed still master HEAD, all four side
branches diffed. **Every one of those queries was incapable of seeing the thing that killed the
pick**, because the rival's work exists only inside the platform's submission pipeline. A clean
SIX-CHECK is not exclusivity evidence for a famous-spec-feature lane - it never was.

**ROOT CAUSE 3 - the precheck law was not applied, for the THIRD consecutive time.**
`feedback_precheck_at_first_slice` ("upload the core slice to the platform before hardening; the
dedupe matches on the CORE and precheck is free") was written after scikit-fem, ignored by koto, and
ignored again here. The dropflow core slice - the four parsers plus the clamp kernel plus the
re-resolved inline box model - existed and passed tests before any of the margin-collapsing,
contribution, replaced-ratio or percent-definiteness work was written. Uploading it then would have
returned this identical Blocker for free. Instead the pick absorbed a full authoring cycle plus a
submit-time audit round (exclusivity re-run, a genuine reference-bug fix, 3 added tests, two harness
hardenings, a full clean-room Docker matrix) on an artifact that was already dead.

**Law:** for any feature named by the standard a repo exists to implement, exclusivity cannot be
established from outside the platform. Precheck the core slice BEFORE writing the differentiating
scope - and treat a repo's own support/roadmap table as the rival author's pick list, not as
permission.

**Repo verdict:** dropflow's min/max sizing capability is CONSUMED. `position: absolute` is
exclusivity-dead to public PR #34. The remaining README "Planned" rows (`display: table`,
`transform`, `position: fixed`) are the same shared pick list and carry the same collision risk.
Treat chearon/dropflow as AVOID.

## vivisect-noret-propagation (Python, SHELVED 2026-09-13 - UNSOLVABLE-UNDER-REVIEW, 166 runs / 2 genuine passes)

**Pick:** fix vivisect's no-return analysis so a terminal path counts as proof only when it genuinely
cannot fall back out, and propagate no-return across the call graph to a fixed point
(`noret.py`, new `noretprop.py`, `_cb_noflow` xref preservation in `base.py`, explicit trap flags in
the i386/amd64/ARM/Thumb/AArch64 decoders, `propagateNoReturn` / immediate `addNoReturnVa`). Final
artifact: 58 tests, 390 human-effective LOC across 14 files, clean-room Docker validated, 3x
deterministic. 114 rounds.

**Verdict:** the OPPOSITE of too-easy, shelved here because this file indexes `rejected/`. **166 real
platform runs, 2 genuine passes**, both in batches 1-2 when the suite was 16 and 26 tests. Every
apparent pass after that was adjudicated a false positive or carried a defect a reviewer then caught
(batch 14 Nova #6, batch 18 Nova #9, batch 21 Nova #8, round-111 replay Vega #1). The final Auto
Review scored Solution 3/3 Clean and Tests 1/3 on three coverage Highs, and every candidate answer to
those Highs measured **0/21** on two fresh populations.

**ROOT CAUSE 1 - the sound contract requires repairing the substrate, and agents build on it instead.**
vivisect's own disassembly drops the successor after three instruction shapes: a store of the program
counter (`str pc` decodes as NOFALL|BRANCH), a conditional call once its target is declared no-return
(codeflow's `_cb_noflow` suppresses the fallthrough even for IF_COND), and x86 `into` (IF_NOFALL). The
reference repairs all three in the decoders and codeflow. Agents walk the RECORDED instructions
(`getLocations`) and, across twenty-one batches, essentially never edit `envi/`. Measured on 21 fresh
runs: every test whose fixture depends on a dropped successor fails 15-20/21 (d5 `into; ret` 20/21,
predicated call declared first 19/21), while the walker-layer twins of the same demands cost 2-6/21.
The differential that proved it: hand each failing agent the successor base disassembly drops, re-grade,
and 6 of 10 store-trap failures flip to pass.

**ROOT CAUSE 2 - both review panels read the repairs as required, so there is no fair narrowing.**
Round 111 cut the store axis together with its meta.md clause; Solution Quality failed round 112 on the
same bug, grounded in a sentence that survived the cut ("A transfer is not evidence merely because its
decode flags say it cannot fall through"). Round 114's Auto Review demanded location assertions that
only a disassembly repair can satisfy, and the FP panel's "four candidate-only failures" on Nova #8
were exactly those disassembly-dependent probes. A general soundness sentence ("every path through it
reaches something that settles it") keeps every dropped-successor case in scope: **deleting a specific
clause never deletes the requirement.** Stating the repair makes the test fair and lethal; leaving it
unstated makes it an FP hole or a review finding.

**ROOT CAUSE 3 - every hardening round was correct and the product was zero.** Scope grew 16 -> 135
tests, was cut to 38, rebuilt to 83, cut to 44, and grew again as each (real) review finding added one
more architecture-sensitive conjunct. Four scope-downs, 0 genuine passes in the last 144 runs. Batch 19
measured it directly: cutting any single axis stayed 0/13; the near-miss tests differed run to run
(each agent solved a different ~90%).

**Reusable law - SUBSTRATE-REPAIR CONTRACT.** A capability whose correct implementation must repair the
host's own recorded facts (decoder flags, recorded code flow, a cached IR) is not shippable when agents
build on the recorded substrate rather than repairing it. Pick-time test: for every fixture the design
needs, ask whether base ALREADY records the instruction/node the assertion depends on. If a
load-bearing fixture needs something the substrate drops, and a review-grade reading of the contract
implies it, the pick is dead - there is no wording that is both fair and solvable.

**What was salvaged:**
- The replay harness (`rejected/vivisect-noret-propagation/agent-runs/replay.sh`, `refplay.sh`)
  reproduced platform grading exactly three times; re-grading saved solutions against a candidate suite
  is the cheapest pre-batch steer available.
- "Give the agent the missing substrate fact, then re-grade" is the fastest discriminator between a
  description defect and real agent difficulty (round 113). Use it before any hardening or cutting.
- Wording moves AWARENESS but not substrate repair: the store clause took explicit store handling from
  ~4/13 agents to 11/11, while the store-trap pass rate barely moved.
- Two measurement failures to never repeat: round 103 stripped `print` lines from a scratch test copy
  and deleted the calls under test; round 111 checked "no test needs byte re-reading" at 56 tests and did
  not re-check when round 112 restored tests that did.

## cwerg-memory-passed-parameters (C++/Python, SHELVED 2026-09-19 - DERIVATIVE, overlap `Blocker` 72/163 rival lines = 44.2%)

**Pick:** robertmuth/Cwerg issue #3 (maintainer roadmap): functions with more parameters than the
target has argument registers, overflow passed through a caller-owned stack region whose address
travels in the next free GPR. a32/a64/x64, Python spec and C++ port under byte-identical assembly.
17 files, 349 human-effective LOC, 8 golden programs / 42 new cases, clean-room validated 3x.

**Timeline:** first scope gate PASSED (0/310 overlap against two same-path candidates, one of them
our own accepted bcopy pick) -> Auto Review R1 revision (Tests 1/3, Solution 1/3) -> R2 Approved
with notes -> batch 1 **0/11** (8 Nova, 1 Orion, 2 Vega) -> R3 test-only fixes, local replay of all
11 solutions projected **1/11** -> scope gate re-run: **Blocker**, *"older candidate already
implements the same overflow-parameter caller-memory engine... adding Python, a32, parity, and
broader edge coverage is a port/integration elaboration rather than a separate core task."* Not
contestable. The same report's adjacency panel called the two "similar ideas rather than duplicates"
(the rival rewrites IR signatures in a unit pass, C++ only, a64/x64); the Blocker still bound.

**ROOT CAUSE - a roadmap issue is a shared pick list.** Cwerg's open issues are the maintainer's
own terse to-do list, uncommented, no PRs. The hunt rated the magnet MEDIUM and leaned on the
precedent that #45 (bcopy/bzero, same list) had been accepted. That precedent only proves #45 was
free when we took it. Every author who opens the repo reads the same 24 lines.

**ROOT CAUSE 2 - a passed scope gate is not a permanent verdict.** The core-slice precheck compared
against the candidates it surfaced at that moment; the re-run, after two revision rounds and a paid
batch, surfaced an older one. Budget for the gate to be re-evaluated at every submission.

**LAW:** in a small repo whose tracker is a maintainer roadmap, treat each open roadmap item exactly
like a "Planned" row in a support matrix: presumptively claimed. An invented lane built from the
source tree's own seams (as the hunt skill already allows after tracker lanes die) is the safer
pick in such a repo. Being a superset of a rival's core never restores exclusivity.

**What was worth keeping (reusable for any future Cwerg lane):**
- Ten pre-existing Cwerg defects mapped and reproduced on base (feedback.md in the rejected folder):
  a32 forward narrow-param calls, a32/a64 no-spill local allocator ceilings, a32 Python global
  allocator ignoring float param registers, x64 conv into spilled/same register, py/cc S16/U16
  widening order, C++ EXTERN-redefinition parse bug, C++ 63-param off-by-one, x64 C++ 8th float
  register (xmm8) miscompile, a32 C++ float-constant immediates, C++ accepting out-of-range consts.
- Batch evidence: the fair walls that killed were xmm8 (6/11, agents copied C++'s 8 float regs),
  the C++ 64-parameter parse (9/11), the x64 spill clobber of the incoming address, and a32 C++
  float constants. Three fixture shapes were unfair (pre-existing allocator ceilings, forward
  narrow calls) and were removed in R3.
- Tooling: `worktrees/_cwerg_mpp/` (model-driven golden generator, mutation battery, per-agent
  replay harness against saved runs).

## dinit-depends-any-groups (C++, SHELVED 2026-09-19 - machinery-absorbed sub-floor, before any batch)

davmac314/dinit (service manager), hunt RANK 1 (REPO-HUNT-2026-09-19 Part 2). Lane: `depends-any = a b c`
dependency groups (dependent starts on the first STARTED member, fails only when every member failed,
stopped/restarted/forced down with a member only when that member is the group's last STARTED one;
pins, gentle-stop check, reload, dinit-check). Picker check passed. Full reference built in ~2 hours:
8 files, **145 raw / 105 human-effective**, all 139 base tests green, 10 core tests.

**The traps were real.** Four natural wrong designs, each killed by exactly its own discriminator:
failure rule reading sibling states (the prop queue is LIFO, so a pinned-stopped member listed LAST
fails before its siblings' queued starts run), a STOPPING sibling counted as up (dependent orphaned
after a common dependency stops), the dependent stopped from the member's `stopped()` (member
reaches STOPPED first), and groups merged across lines.

**Root cause / LAW (MACHINERY-ABSORBED, third instance after kcl and iced-x86).** The audit sketched
315-340 eff by listing every surface the contract touches (start, failure, stop, restart, force,
stop ordering, pins, control, reload, checker). Every one of those surfaces already routes through
ONE per-link decision (`is_hard()` in `stop_dependents`, the `failed_to_start` switch, the pin
loops), so the whole kernel was three predicates, one switch arm and four call-site swaps. **A
surface count is not a LOC estimate when the surfaces share a chokepoint.** The same property that
made the traps interdependent (one shared kernel) made the diff small. Hunt Stage 3b must sketch
against the CHOKEPOINT, not the surface list: count the distinct decision points the new semantic
changes, not the behaviours it affects.

Evidence kept: `rejected/dinit-depends-any-groups/DESIGN.md` (trap table), reference diff +
`src/tests/anydeptests_88f904.cc` in `worktrees/dinit`. The traps (LIFO prop-queue failure timing,
STOPPING-sibling classification) are reusable on any dinit lane that is big enough.

## oxipng-apng-frame-optimization (Rust, SHELVED 2026-09-19 - DERIVATIVE, set-level overlap `Blocker` at the core slice)

**Pick:** oxipng/oxipng (hunt 2026-09-19-E, best of sweep). APNG joint reductions (one IHDR/PLTE/tRNS
decided over the default image and every frame, after cropping) plus frame cropping to the minimal
rectangle that keeps both the displayed canvas and the canvas left for the next frame (dispose/blend
kept, BACKGROUND frames keep the visible pixels they clear), exact delay-merging of frames that change
nothing, acTL rewrite, `frame_reduction` option / `--nf`, timeline-comparing `sanity-checks` validator.
Reference 342 human-eff / 7 files, 40 tests, clean room 3x, 12-mutation sweep all killed.

**Reject (core-slice precheck, no batch):** three overlap Blockers. An older submission holds the
"animation-wide color, bit-depth, palette, and frame re-encoding core" (181/407 discounted lines =
44.5%, 65.8% of the rival's own lines); another holds "canvas simulation and changed-region cropping"
(199/407 = 48.9%, ruled Medium on its own because the frame planners diverge); the union verdict:
*"The submission stitches two older major implementation blocks; its merge/delay and integration
residue does not make the recycled primary engines incidental."*

**ROOT CAUSE:** the hunt flagged it correctly and the pick went ahead anyway. Issue #551 is busy and
user-bumped, and andrews05 published the staged plan in it (stages 3 and 4 = exactly this lane). The
dossier recorded that as Stage 2d's "welcomed, spec-named, long-lived" worst case; the pick proceeded
on the strength of size (310-455 eff) and a clean GitHub exclusivity sweep, which cannot see the
pipeline.

**LAW (set-level derivative):** a pick that COMBINES two stages of a publicly staged plan is dead if
each stage exists as a separate older submission, even when neither covers half of yours. Bolting the
second stage on to "dilute" the first does not help; the gate unions the rivals. A maintainer's
numbered roadmap inside an issue is a support matrix with the rows pre-sized.

**What worked:** Step 4b. The core-slice precheck killed it before any batch, at the cost of one
session. Evidence kept in `rejected/oxipng-apng-frame-optimization/` (DESIGN.md trap table, tests) and
branch `spike` in `worktrees/oxipng`. Reusable: the dispose-aware minimal-rect rule and the
state-equality merge rule are good traps for any animation format lane that is not already taken.

## stremio-core-resource-freshness (Rust, SHELVED 2026-09-21 - UNAUTHORABLE-HARNESS, killed at scope-lock with no code written)

**Repo:** Stremio/stremio-core (MIT, Rust 99.8%, 2411 stars, base `b3062f7f`), hunt RANK 1 of
`repo-hunt-logs/REPO-HUNT-2026-09-21-B.md`. **Lane:** honour the addon protocol's per-response
freshness directives - `ResourceResponseCache { cache_max_age, stale_revalidate, stale_error }`,
a struct the repo parses and then throws away - inside the shared `ResourceLoadable` kernel that
feeds eleven model surfaces.

**Everything the hunt measured was true.** `ResourceResponseCache` really is dead state (three grep
hits, all in its own file, two and a half years after the +76/-0 PR that added it). The three latent
kernel bugs are all real at base: all four result handlers gate on
`matches!(resource.content, Some(Loadable::Loading))` while every current caller sets `Loading`
first, so the `_ => Effects::none().unchanged()` arm is dead code; `resources_update`'s dedup
`find(|r| r.request == request && r.content.is_some() && !force)` returns before any timestamp
comparison; and `resource_vector_content_from_result` maps empty to `Err(EmptyContent)` while its
scalar twin has no such branch. The repo even ships a settable clock (`src/unit_tests/env.rs:27`),
which is exactly what a TTL feature needs to clear the flakiness gate.

**ROOT CAUSE - the mock fetch harness casts by exact type, so no wire type can change shape.**
The directives only exist on the wire, so reaching the kernel means changing the `OUT` type of
`Env::fetch` for addon resources. `TestEnv::fetch` (`src/unit_tests/env.rs:112-124`) never
deserializes anything: handlers return `Box<dyn Any + Send>` holding a pre-built value and it does
`resp.downcast::<OUT>().unwrap_or_else(|_| panic!(...))`. `downcast` matches on exact `TypeId`, so
asking for `ResourceResponseCache` panics every handler that boxes a `ResourceResponse` -
**30 sites across 15 test files**. `solution.patch` may not repair them (test files);
`test.patch` cannot either, because the repair has to differ between the base tree
(`OUT = ResourceResponse`) and the solution tree. A tolerant adapter inside `TestEnv::fetch` does
compile and pass in BOTH trees, but it lives under `src/` outside test.patch's remit and, decisively,
the SOLVER never sees it: every agent that widens the transport type watches 30 repo tests panic and
then either edits repo tests (`PASS_CHEATED`, L31/L78) or edits the harness and makes test.patch
conflict. Contamination is ~100% of runs and measures nothing. The same property blocks the inverse
move: because no deserialization runs in tests, a NEW test cannot inject wire metadata either.

**Every re-source of the freshness windows is blocked too**, which is what makes this a repo verdict
rather than a lane verdict: a field on `Manifest` breaks 36 exhaustive `Manifest { … }` literals in
the test tree (none use `..Default::default()`); a field on `ManifestBehaviorHints` breaks
`src/unit_tests/serde/manifest_behavior_hints.rs`, which pins the token stream including `len: 5`;
a field on `ResourceLoadable` breaks the one exhaustive literal at
`src/unit_tests/meta_details/live_tv.rs:58-61` and nothing can keep that literal compiling in both
trees; an 8th `Ctx::new` argument breaks ~20 call sites; and windows taken from repo constants drop
the protocol tie and collapse the pick to a nameable "TTL cache".

**Repo verdict: Stremio/stremio-core is AVOID for an Olympus-sized pick**, despite being
mechanically excellent (MIT, pure Rust, committed `Cargo.lock`, one rev-pinned git dep, 282 lib +
18 doc tests deterministic in 0.12s, settable clock, 0 of 6 quota). Three properties squeeze from
different sides: (1) `src/unit_tests/serde/` token-pins ~48 of the public types, so extending almost
any of them reds a test only the agent can repair; (2) the mock fetch harness above makes every wire
type immovable; (3) the runtime is a generic `Effects` / `Env` / `Loadable` engine, so new cases are
absorbed - probed on a second lane, chunking `AggrRequest::CatalogsFiltered`'s id batches past the
addon's `options_limit` measures ~30 effective LOC, because `ResourceRequest` equality already lets
the kernel hold N entries per addon and `update_notification_items` already scans every catalog.

**Reusable law (new taxonomy row - MOCK-HARNESS TYPE WALL).** Before scope-locking any pick whose
capability rides a wire, boundary or IO type, open the repo's test double for that boundary. If it
returns PRE-BUILT typed values and resolves them by exact type (`Box<dyn Any>::downcast`, a
`TypeId`/class registry, a `Mock` keyed on the return type) rather than by parsing bytes, then the
boundary type is FROZEN: it cannot widen without breaking every existing handler, and neither patch
can repair that fairly. Count the handler construction sites at pick time - it is one grep - and pair
the check with the older serde/golden-token question. The cheap version of both: `grep -rn "downcast\|isinstance\|mock" <test-env-file>` and `grep -rc "<Type> {" <test tree>`.

Artifacts: `rejected/stremio-core-resource-freshness/` (BASE_COMMIT.txt + feedback.md with the full
citation set). No code, no Docker build, no batch.

## openglobus-entitycollections-tree-maintenance (TypeScript, SHELVED 2026-09-22 - DERIVATIVE, overlap `Blocker` 92/197 = 46.7%)

**Pick:** openglobus/openglobus (Apache-2.0, 936 stars, base `61757dbc`), hunt RANK 1 of
REPO-HUNT-2026-09-21. Incremental insert/remove upkeep for the `Vector` layer's entity collections
tree (Earth: mercator/north/south; Equi: west/east): descend to the right leaf, re-arm
`nodeCapacity`, repair counts on remove, collapse emptied nodes, keep `_nodePtr` right, plus a
same-position split guard. New API `Vector.getEntityCollectionsTreeStrategy()`,
`EntityCollectionsTreeStrategy.removeEntity()` and `.getRootNodes()`. Factory SLICE: 152
human-effective LOC across 7 files, 28 tests, clean room 3x identical, 7/7 mutants killed.

**Timeline:** SLICE handed off 2026-09-21 -> core-slice precheck -> overlap **Blocker**:
*"re-deliver the older candidate's incremental entity-tree rebucketing, removal/count repair,
same-position split guard, node-pointer maintenance, and cleanup engine ... turns a
repository-specific maintenance clause already implemented by the older candidate into the primary
standalone task."* Stopped before the picker spend and before any batch.

**ROOT CAUSE - the lane was a clause of someone else's feature.** The hunt checked for a rival
doing *this* task. The rival did a bigger task on the same subsystem (entities that change after the
bulk build), and keeping the tree correct was one of its clauses. Any feature that makes entities
dynamic needs the same upkeep, and the bulk build fixes every invariant, so independent authors write
the same split, count-repair and collapse code. Even our own "unattended" choice, the duplicate-
position guard, was forced by the contract, so the rival has it too.

**LAW:** before scope-locking a "keep the index correct incrementally" pick, ask which bigger
features on that subsystem would have to include it (live updates, moves, streaming, undo). If one
of those is an obvious author pick, the upkeep lane is presumptively claimed. Additive accessors and
stricter invariant coverage never differentiate a recycled core.

**Repo verdict:** openglobus `Vector` / `EntityCollectionsTreeStrategy` / `EntityCollectionNode` /
`Entity` setters are covered by a prior pipeline submission. The DESIGN.md sec 15 FINISH scope
(cross-tree re-homing, setter wiring, deferred queue, `_renderingNodes` hygiene) is the same engine,
so it is dead too. Other openglobus subsystems were not surveyed.

Artifacts: `rejected/openglobus-entitycollections-tree-maintenance/` (full slice + DESIGN.md).

## dyn4j-world-copy (Java, SHELVED 2026-09-24 - DERIVATIVE, overlap `Blocker` 157/297 rival lines = 52.9%)

**Pick:** dyn4j/dyn4j (BSD-3-Clause, 538 stars, base `bcf942ad`, release 6.0.0), hunt RANK 1 of
REPO-HUNT-2026-09-23-J. `World.copy()`: a deep copy of a live physics world that is independent both
ways and steps bit-identically with the original (broadphase tree, contacts + warm-start impulses,
constraint graph, CCD data, time step, accumulated time), `World implements Copyable`, `CopyException`
for a non-overriding subclass. Factory SLICE: 225 honest human-effective LOC across 12 files in 4
packages, 10 tests, clean room 3 uids 3x identical (2385 base tests).

**Timeline:** SLICE handed off 2026-09-23 -> core-slice precheck 2026-09-24 -> overlap **Blocker**:
*"The older task already makes live physics worlds copyable with independent bodies, fixtures,
joints, broadphase caches, contacts, warm-start state, and time history. The subject tightens
determinism and generalizes placement but re-delivers that primary implementation challenge."*
157/492 discounted subject lines (31.9%), 157/297 candidate lines (52.9%). Upstream and scope checks
clean. Stopped before the picker spend and before any batch.

**ROOT CAUSE - the lane was printed in the changelog.** 6.0.0 (#293) put `Copyable` on bodies and
joints and left `World` out. The hunt saw it ("the obvious next step after #293's Copyable program",
MEDIUM magnet) and cleared it on the repo-model contract: bit-identical continuation, warm-start and
broadphase order, independence both ways. The judge read all of that as tightening, because the
container's state is fixed by the engine, so any rival copying a world copies the same caches in the
same places. Zero open issues and a clean PR/fork/code sweep were the expected readings for a lane
whose rivals live only in the pipeline.

**LAW:** when a release adds an interface to the elements of an aggregate and leaves the aggregate
out, the aggregate is a claimed lane; do not scope-lock it on a stricter contract. The only
mitigations that ever worked for a nameable lane were a different CORE, never a tighter version of
the same one (same law as koto-nested-bindings, scikit-fem-embedded-meshes).

**Repo verdict:** dyn4j world-level copy / snapshot / clone / rollback / prediction-by-copy is held
by a prior pipeline submission. The DESIGN.md FINISH scope (brute-force + Sap broadphase copies,
listener and collision-data cells, CCD tree) is the same engine, so it is dead too. Other dyn4j
subsystems were not surveyed.

Artifacts: `rejected/dyn4j-world-copy/` (full slice + DESIGN.md). Clones `worktrees/dyn4j`,
`worktrees/dyn4j-cleanroom`, `worktrees/dyn4j-probe` (41M total).
