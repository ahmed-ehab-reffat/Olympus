# Repo hunt 2026-09-10-B — second pass after DFU was authored: pool re-mine + a 44-topic sweep on uncovered axes

Follows `REPO-HUNT-2026-09-10.md` (same day), whose RANK 1 (Mojang/DataFixerUpper) is already authored
as `problems/datafixerupper-derived-recursion`. This pass had to find the NEXT target, so it (a) closed
the owed audit on that session's RANK 2, (b) re-mined the proven pool with the mechanical un-triaged
diff, and (c) swept 44 topics chosen to avoid every axis the 09-09 / 09-09-B / 09-10 sweeps had used
(emulator, bytecode, jit, decompiler, dwarf, linker, package-manager, sat/smt, planning, pathfinding,
physics, audio, midi, music-notation, unicode, opentype, pdf, ebook, subtitles, compression, archive,
filesystem, disk-image, regex, diff, merge, template-engine, spreadsheet, ocr, image-processing,
raytracing, geodesy, timezone, scheduling, workflow-engine, rules-engine, state-machine, codec, ...).
255 rows, dead-list filtered to 165 known slugs.

**Headline: casid/jte is RANK 1 — a template COMPILER whose core is cold (3 small parser fixes in 12
months) inside a repo that is otherwise live and green, with one parser kernel feeding two code
generators and a runtime escaping policy. Zero prior submissions, zero ledger history, competitor-clean.**

The session's most expensive finding is a kill: **onekey-sec/unblob**, which passed every gate up to
and including the seam audit and a reproduced behavioural gap, is **exclusivity-dead** — a CLOSED PR
publishes the fix diff for exactly the central capability.

---

## RANK 1 — casid/jte (Java, Apache-2.0) ★1136 — the template compiler core

- **URL / stars:** https://github.com/casid/jte — ★1136
- **Language:** Java 17 (+ a Kotlin backend module); Maven (`mvnw`), pure JVM, no native deps
- **Domain:** compiled template engine — its own template language, compiled to Java or Kotlin source, then javac'd
- **License:** Apache-2.0 (read `LICENSE`; single licence, nothing vendored)
- **Open issues:** 87 total tracker, answerable, real core requests with maintainer replies
- **Last commit:** 2026-09-01 — real code
- **Quota:** **0 of 6.** Never submitted against, never appears in `SATURATED-REPOS.md` or any hunt log
- **Requirement 7: CLEARED** — `.github/workflows/maven.yml` = "Test all JDKs on all OSes", **success on `main` 2026-09-01**

### Why it ranks: one kernel, several surfaces (Phase-3 guard #1)

`jte/src/main/java/gg/jte/compiler/TemplateParser.java` (1245 LOC) is a hand-written mode-stack state
machine carrying `Deque<HtmlTag> htmlStack` + `currentHtmlTag` and modes
`Text / Content / Raw / Param / Import / Comment / HtmlComment / CssComment / JsComment / JsBlockComment`.
Everything downstream consumes what that kernel decided, and nothing downstream can recover it:

| Surface | File | LOC |
|---|---|---|
| Java backend | `jte/…/compiler/java/JavaCodeGenerator.java` | 663 |
| **Kotlin backend** | `jte-kotlin/…/compiler/kotlin/KotlinCodeGenerator.java` | 691 |
| Runtime escaping policy | `jte-runtime/…/html/OwaspHtmlTemplateOutput.java` + `html/escape/Escape.java` | 138 + 105 |
| Compile driver / line mapping | `compiler/TemplateCompiler.java`, `CodeBuilder.java` | 344 + 191 |

**Two code generators over one visitor interface is the parity seam that has already worked twice for
us** (customasm py/cc, Cwerg backend parity): a capability has to land identically in both, which
forces cross-package work and gives interdependence for free.

### Trap seams (`failure-patterns.md`)

| Pattern | Present | Evidence |
|---|---|---|
| F-1 convergent-architecture wall | **yes** | `TemplateParser` emits visitor callbacks; the HTML/mode context is destroyed before either generator runs |
| F-7 context-exclusion completeness | **yes** | `isCommentAllowed()` / `isHtmlCommentAllowed()` / `isParamOrImportAllowed()` — "not inside X" decided across 5+ comment and raw modes, `TemplateParser.java:107-153` |
| F-9 cross-stage resolution drop | **yes** | the parser resolves HTML tag/attribute context; the runtime escaping policy re-derives its own notion of context in `OwaspHtmlTemplateOutput` |
| F-10 capability cross-product | **yes** | two form axes already exist: backend (Java / Kotlin) x context (text / attribute / script / css / comment / raw) |
| F-18 token-form parity gap | **yes** | four comment spellings (`<%-- --%>`, `<!-- -->`, `/* */` in css, `//` and `/* */` in js) all funnel through `extractComment` |

### Gate 8 — maintainer philosophy, READ (this narrows the lane, do not skip it)

- **`<script>`-block template calls are philosophically CLOSED.** [#437](https://github.com/casid/jte/issues/437)
  (open, 9 comments): users push back on the "Template calls in `<script>` blocks are not allowed"
  compile error, and maintainer `kelunik` holds the line — *"Of course, but the likelihood is very high.
  If you don't share an example, we can't suggest alternatives."* A pick that relaxes this contradicts
  the maintainer. **AVOID.**
- **The HTML attribute / policy lane is OPEN and welcomed.** [#540](https://github.com/casid/jte/issues/540)
  "Dynamic HTML attributes?" — `edward3h`: *"The interesting part of rendering attributes is whether you
  can make it play nicely with the context JTE uses for HTML escaping. I don't know the answer to that."*
  `sgruendel`: *"Leaving this open, could still look into adding this as a direct jte feature."* No design
  published, no PR — Stage 2d's BEST CASE. Note PR #256 "Support Dynamic Html Attribute Names" is already
  merged, so attribute NAMES are done; the escaping-context question is what is open.
- Also open and uncommented: [#428](https://github.com/casid/jte/issues/428) "Localized text is always
  trusted content" (XSS via `LocalizationSupport`), #479 and #441 (HTML comment removal).
- These INFORM that the lane is live; per `RULES.md` they must never BIND the spec.

### Gate 7b — EXCLUSIVITY: CLEAR on this lane

Canonical org confirmed `casid/jte` (no redirect). `gh search prs` across all states for `escape`,
`escaping`, `css context`, `url attribute`, `javascript escaping`, `contextual`, `style attribute`,
`srcdoc`: **nothing implements a context model.** The only relevant merged PR is #227 "Replace owasp java
encoder with faster implementation", which produced the CURRENT `Escape` class — that is the base state,
not the capability. #330 / #329 are single-character escaping bug fixes.

### ⭐ The seam, located to the line (this is what makes the pick)

The parser computes rich structure, the VISITOR INTERFACE narrows it to two Strings, and the runtime then
re-derives context from those two Strings with string heuristics.

- `jte/…/compiler/TemplateParser.java` — `public static class HtmlTag implements gg.jte.html.HtmlTag`
  holds `attributes`, **`isScript`**, **`isStyle`**, `bodyIgnored`, `innerTagsIgnored`,
  `attributeStartIndex`, `stringLiteralQuote`, plus `getCurrentAttribute()` /
  `isCurrentAttributeComplete()` / `isCurrentAttributeQuote()`.
- `jte/…/compiler/TemplateParserVisitor.java` — but the escaping path is
  `onHtmlTagBodyCodePart(int, String, String tagName)` and
  `onHtmlTagAttributeCodePart(int, String, String tagName, String attributeName)`. **Two Strings.**
  Meanwhile `onInterceptHtmlTagOpened(int, TemplateParser.HtmlTag)` passes the object INTACT — the same
  parser state reaches the interceptor whole and reaches the output as two strings.
- Both generators then emit a string literal: `JavaCodeGenerator:311` and `KotlinCodeGenerator:340`
  `jteOutput.setContext("<tag>", null)`.
- `jte-runtime/…/html/OwaspHtmlTemplateOutput.java` re-derives:
  `writeTagBodyUserContent` is `if ("script".equals(tagName))` -> JS escape, **else HTML-content escape**;
  `writeTagAttributeUserContent` is `if ("a" + "href" + startsWith "javascript:")` -> drop, then
  `if (attributeName.startsWith("on"))` -> JS-attribute escape, else HTML-attribute escape.

**The behavioural consequence is one line pair:** the parser computes `isStyle` and the runtime never
receives it, so `<style>${x}</style>` gets `&`/`<`/`>` escaping (`Escape.htmlContent`) — which is not a CSS
escape at all. `Escape` has `htmlContent` / `htmlAttribute` / `javaScriptBlock` / `javaScriptAttribute` and
**no CSS context and no URI context**; the `javascript:` check is hardcoded to `a`+`href` only.

**F-21 is present in its measured form** (5/10 on datafixerupper, sole near-miss failure): `HtmlTag` is
`interface { String getName(); }` and `HtmlAttribute` is `{ getName, getQuotes, isBoolean, isEmpty }`,
while every `HtmlPolicy` implementation gets the interface and the real state lives in the concrete
`TemplateParser.HtmlTag`. The shortcut is a downcast.

### Absorption test — PASSED, with the algorithm named

**Name the algorithm the repo does not contain:** a per-context escaping model — resolving each
interpolation site to a typed output context (element body / RCDATA / raw-text / attribute value / URI /
CSS / event handler) from the parser's own tag+attribute state, carrying that context across the visitor
boundary into both backends, and escaping per context including URI-scheme validation. jte has the
parse-time state and four flat escape functions; it has no context model, no CSS escaper, no URI escaper,
and no way for a `HtmlPolicy` to see structure.

**eff-LOC sketch (Counter 2), owed confirmation from the hook after implementation:**

| Piece | eff LOC |
|---|---|
| widen the visitor contract + emission in BOTH generators (forced parity) | 90 |
| context model + resolution from parser state | 70 |
| `HtmlTemplateOutput` / `OwaspHtmlTemplateOutput` rewrite | 80 |
| CSS-context and URI-context escapers (incl. scheme validation) | 90 |
| `HtmlPolicy` / `HtmlTag` interface widening + policy updates | 50 |
| compile-time validation for the new contexts | 40 |
| **total** | **~380-420 eff across 6-9 files, 3 modules (`jte`, `jte-kotlin`, `jte-runtime`)** |

Above the 200 floor with real buffer, >= 2 files, and cross-module by construction.

### Phase-3 death-class guard

1. **One kernel, several surfaces?** YES — the parser's tag/attribute state feeds the Java backend, the
   Kotlin backend, the runtime escaping policy, the compile-time `HtmlPolicy`, and the interceptor.
2. **Interdependent traps?** YES — widening the visitor contract forces both backends to agree (fixing one
   backend leaves the other emitting the old context and the shared runtime then mis-escapes), and
   widening `HtmlTag` for the policy path changes what the escaping path sees.
3. **Standalone new file + minimal wiring?** NO — the capability is a contract change at a stage boundary
   that four consumers cross.
4. **`TOO-EASY.md` Guard #2 (single-subsystem fully-specified transform)?** Spans 3 Maven modules.

### ⚠️ The one real risk on THIS thesis: derivative

An outsider can name it — *"adds context-aware escaping (CSS, URI) to a template engine"* — and
**contextual autoescaping has canonical implementations** (Go's `html/template`, Closure Templates). That
is Stage 2b row 1, MEDIUM under the 2026-09-09-B softening: mitigate, do not abandon. Mitigations, and
they must actually be applied:
- phrase `meta.md` entirely on jte's own model (the visitor contract, `setContext`, `HtmlPolicy`,
  `HtmlTag`, the two backends), never on "contextual autoescaping";
- make the F-10 cross-product cells (backend x context) carry the tests, so behaviour is jte-specific;
- re-run the PR-DIFF check at submit.

**Two lower-derivative fallback theses in the same repo**, if the risk is judged too high:
- **(B) Give `HtmlPolicy` the parser's structure.** Pure F-21: the compile-time policy interface sees only
  a tag name, so cross-cutting rules (ancestry, sibling attributes, quoting) are inexpressible. Names
  nothing external. Smaller — needs a coupled second lever to clear the floor.
- **(C) `@template` call resolution and parameter binding across both backends** — named params, defaults,
  varargs, `Content` params, resolved at compile time in `TemplateCompiler` and emitted twice. jte's own
  model end to end.

### ⭐ Gate 1 / Gate 6 — BEHAVIOURAL F2P GAP, REPRODUCED ON BASE (public API, no reflection)

`TemplateEngine.create(DirectoryCodeResolver, classDir, ContentType.Html)`, three templates, one value.

```
STYLE body  : <style>.a { color: red; background: url('javascript:alert(1)') }</style>
SCRIPT body : <script>var a = red; background: url(\'javascript:alert(1)\');</script>
URI attrs   : <iframe src="javascript:alert(1)"></iframe><a href="">x</a>
```

Three gaps, and each one is proved by the repo's own behaviour on the neighbouring axis:

1. **`<style>` body gets `Escape.htmlContent`** (`&`, `<`, `>` only) — no CSS escaping exists. The parser
   computed `isStyle` at `TemplateParser.java:1134` and it never reaches the output.
2. **The same value in `<script>` gets `Escape.javaScriptBlock`** (note the `\'`). The context machinery
   exists; it stops at the single hardcoded `"script".equals(tagName)`.
3. **`iframe/src` passes `javascript:` through, while `a/href` is correctly blanked** — the scheme guard in
   `writeTagAttributeUserContent` is hardcoded to `"a"` + `"href"`.

This is the fair shape: the repo already does the right thing on one axis of each pair, so the contract can
be stated as "extend what you already do" rather than as new invented policy.

### Gate 9 — DETERMINISM: CLEAN

`mvn -pl jte-runtime,jte,jte-kotlin -am test`, three runs:
**tests=1207 failures=0 errors=0 skipped=0, identical every run.** No flaky baseline. JDK 21 host,
`<java.version>17</java.version>`. First run ~5 min (in-process kotlinc dominates), later runs faster.

### Still owed before scope-lock

Closed in this session: Requirement 7, **Gate 1 + Gate 6 (reproduced on base)**, Gate 8 (philosophy),
Gate 7b (exclusivity), **Gate 9 (determinism, 3x clean)**, Stage 3b (absorption + eff-LOC sketch), the
Phase-3 death-class guard, Stage 2b/2b-bis/2c. What remains:

1. **Docker.** Pattern B `olympus-base-jvm`. This repo is **Maven**, not Gradle, so the memory note
   "drop Gradle from the runtime" needs re-deriving: warm `~/.m2` at BUILD time with
   `-Dmaven.repo.local` pointed inside the image, then run offline. Decide whether base mode scopes to
   `jte-runtime,jte,jte-kotlin` (excluding the Spring-starter and hot-reload modules) and DOCUMENT WHY —
   scoping out the modules the solution touches would be the L31 anti-pattern, but the Spring starters and
   `test/jte-hotreload-test` are neither touched nor relevant.
2. **Local Maven repo lives at `.toolchains/m2repo`** (project disk, per the disk-discipline memory), not
   `~/.m2`. Pass `-Dmaven.repo.local=` on every invocation.

---

## ⛔ RANK 1 REVERSED 2026-09-10-B (same day) — jte's HTML-output lane is MAINTAINER-DECLINED

**The escaping/policy thesis above is DEAD at author Phase 2 (Gate 8), and jte is downgraded to
AVOID.** Everything mechanical in the dossier still stands — the repo is clean, the harness is built
and Docker-validated, the gap is real and reproduced. The capability class is the problem.

**Issue [#387](https://github.com/casid/jte/issues/387) "Allow the developer to choose the escaping
strategy"** (OPEN since 2024-10-01) is exactly this lane, quotes the exact
`attributeName.startsWith("on")` line the thesis targets, and both maintainers decline it:

- `kelunik`: *"Interpolation of user data directly into JS expressions is something that easily
  results in XSS, so we don't really plan to support **context dependent escaping** for JS."*
- `casid` (owner): *"the whole idea of output escaping in jte is, that the user does not need to do
  it manually... The `OwaspHtmlTemplateOutput` is just one implementation of `HtmlTemplateOutput`.
  In theory, it would be possible to create an `HtmlTemplateOutput` that is aware of Alpine or
  HTMX..."* — i.e. extending contexts is the USER's job, not core's.

That is three declines in one lane: #437 (template calls in `<script>`), #387 (context-dependent
escaping / pluggable strategy), #252 (*"is there a javascript inlining in jte such as thymeleaf
got?"*, closed). The reporter of #387 himself cites Thymeleaf's `th:inline="script"`, confirming the
derivative read as well.

### Why the hunt-stage Gate 8 pass missed it

The hunt read #437, #428, #540, #479 and #441 and concluded "the HTML-attribute/escaping lane is
welcomed". **#387 never surfaced, because its title carries none of the feature's nouns** — no
"css", no "style", no "context", no "escape-context". It appears only under the query `xss`.

**Lesson (new): run the Gate 8 issue search on the CAPABILITY CLASS in the maintainer's vocabulary,
not in your feature's nouns.** A maintainer writes down a refusal in the words of the USER who asked,
which are the words of the problem ("xss", "strategy", "choose", "allow me to"), not the words of
your design ("css context", "uri scheme"). Search the problem vocabulary and the ADJACENT framings,
and read every hit in the lane even when the title looks unrelated.

### Residual verdict on jte

The mechanically-excellent parts are unchanged and the harness is reusable if anyone returns. But the
one deep, coupled, genuinely hard surface in the repo IS the HTML parser/policy/escaping machinery,
and that whole direction is declined. What remains is small: `BinaryContent` (52 LOC) +
`Utf8ByteOutput` (94), `trimControlStructures`, hot-reload/precompile plumbing. The `jte` module is
3789 LOC and `jte-runtime` 2410 in total, so an invented lane outside the HTML machinery is very
unlikely to carry >= 200 effective LOC. **jte -> AVOID.** Not licence- or competitor-dead;
capability-declined in the only lane worth authoring.

---

## The expensive kill — onekey-sec/unblob (Python, MIT) ★2552: EXCLUSIVITY-DEAD

Worth recording in full because it cleared more gates than anything else this session.

Cleared: MIT, ★2552, pushed 2026-09-08, CI green, **competitor-clean** (`qkaiser` maintainer,
`elektrischermoench` handler contributor, and `bunlongheng` — profiled, real name, 144 repos, coherent
web-dev footprint, NOT a signature account), core files cold (`processing.py` 9 commits/24mo, last
2026-02-09; `finder.py` 4; `extractor.py` 3), real domain (firmware carving), and a genuine
**behavioural gap found in the source**: `remove_inner_chunks` handles only full containment
(`models.py:164 contains`), so partially overlapping chunks survive, and `calculate_unknown_chunks`
then computes `next.start_offset - chunk.end_offset` on them and constructs an inverted `UnknownChunk`.
`grep -rniE "overlap|intersect"` returns **nothing** in the whole package.

**Killed by Stage 2b exclusivity:**

- Issue [#232](https://github.com/onekey-sec/unblob/issues/232) "valid chunk can overlap the next valid
  chunk" (2022-02-04, closed) — the BODY contains two complete solution sketches in code, including the
  exact resize rule, and the maintainer's own verdict on which to prefer.
- PR [#234](https://github.com/onekey-sec/unblob/pull/234) "Fix overlapping valid chunks." — **CLOSED,
  unmerged, +17/-0 in `unblob/processing.py`**, introducing `fix_chunk_overlaps`. That is the central
  capability with a published diff in the same core file. The rule is binary and state-independent:
  ANY state, including closed and unmerged, is a hard scope-gate reject.

Remaining unblob lanes are thin: handlers are missing-arm/absorbed, reporting/metadata was just shipped
by the maintainer (`16-metadata-reporting`, merged 2026-09-08), extraction-path safety is `qkaiser`'s
active lane. The whole python package is 4973 LOC, so the LOC floor is a live risk on any invented lane.
**Verdict: SHELVED, not dead** — a genuinely invented lane could still work, but the obvious one is gone.

---

## Killed this session, with the gate that killed them

| Repo | ★ | Gate | Evidence |
|---|---|---|---|
| opensheetmusicdisplay | 1958 | **2b-bis competitor swarm** | `isc` x5, `gifflet` x2, `ymxlx`, `dotkebi` x2, `youdie006`, `ishinomaru` x3, `recrack` — house-style capability-shaped one-bug fixes: "fix(Unison): Carry the hidden unison exception to the notehead and the tuplet", "fix(Lyrics): re-link lyric word chains split across voices", "fix(Ties): match tied notes by sounding pitch instead of letter name", "fix(layout): align voices when a note's type and dots disagree with its duration". This engine is being mined hard |
| dimforge/parry | 867 | **capability-consuming, every lane** | maintainer `sebcrozet` shipping "have most shape queries return the SubShapeId", "parallel incremental BVH + alternative sweep toi", "fix ambiguities in cuboid-cuboid SAT"; outside contributors adding voxel query traits, compound pseudo normals, analytic ray-capsule, oriented polylines; `marknefedov` filed 3 perf PRs in one day. Same org as rapier, same pattern |
| Vineflower/vineflower | 2352 | **capability-consuming in the only lane a decompiler has** | 6 skilled regulars (`Kroppeb` 13, `coehlrich` 13, `sschr15` 9, `aoqia194` 6) continuously fixing structuring/variables/switches/finally/generics/Kotlin. Not competitors — Minecraft-ecosystem regulars — but they consume the correctness-gap class continuously. Also JLS-named capabilities = derivative risk. NOT dead, just poor lane availability |
| simpeg/simpeg | 674 | **continuous maintainer correctness sweep + published-method capability class** | 09-10's RANK 2, audit now closed: the 12mo stream is "Fix bug in VRM effects on EM1D", "Fix bug in IP effects on EM1D", "Fix bug in apparent conductivity", "Fix return of get_indices_block", "Fix bug with duplicated current in LineCurrent.Mejs" — the f2p class, swept across every lane, plus a v0.26 deprecation wave (moving baseline) and a mature directives/regularization framework (absorption). DOWNGRADED from RANK 2 |
| ostafen/digler | 1461 | **reference-toolchain prior art + thin activity** | file carving; PhotoRec/TestDisk is the domain's reference tool and ships signature carving, filesystem-aware recovery and fragment reassembly. Solo maintainer, only 2 outside PRs ever, 2 code PRs in 2026. Small repo -> LOC risk |
| gimli-rs/gimli · fxamacker/cbor · harfbuzz/ttf-parser · ical4j · libriscv · libjxl · simple-binary-encoding · wasmi | 792-3505 | spec-named capability class | DWARF / CBOR RFC 8949 / TrueType / RFC 5545 / RISC-V / JPEG XL / SBE / Wasm — the capability IS the standard, and each has a reference toolchain |
| dlclark/regexp2 | 1187 | **port law** | a port of the .NET regex engine; inherits .NET's entire feature list as prior art |
| dartsim/dart · simbody · CoolProp-adjacent C++ | 1204-2548 | **vendored-licence risk / AI-sweep** | Eigen (MPL/LGPL) under vendored dirs kills the repo; simbody additionally shows "Running Copilot Code Review" on `master` |
| rellic · binsync · CreuSAT · cocotb-adjacent | 538-746 | harness-infeasible | need LLVM, IDA/Ghidra, or a proof toolchain in the image |
| bufbuild/protobuf-es | 1661 | **lane-limited, NOT dead** | see below |

## bufbuild/protobuf-es — re-triaged, held as a MEDIUM lead

Proven repo (`approved-problems/protobuf-es-serialization`), quota 1/6, Apache-2.0, CI green (ci/bun/deno),
**competitor-clean** (`timostamm` maintainer, `ajeetdsouza` = the zoxide author, `anuraaga`, all real).
Two lanes examined:

- **Codec / serialization: DEAD.** `ajeetdsouza` ran a ~10-PR performance campaign through August, and the
  maintainer's own stream is a correctness sweep in exactly our f2p class ("Reject overlong varints and
  malformed wire-format tags", "Apply recursion limit to BinaryReader.skip", "Reject duplicate keys when
  parsing JSON", "Fix open enum range checks", "Resolve utf8_validation feature"). Plus the
  protobuf-conformance corpus is a corpus-wide invariant test, and it is our own approved pick's subsystem.
- **protoplugin codegen: COLD but partly absorbed.** Per-file 24mo commits are 2-7 (`safe-identifier.ts` 2,
  `jsdoc.ts` 2, `import-path.ts` 3, `source-code-info.ts` 4, `names.ts` 5, `generated-file.ts` 5). But
  `names.ts` already carries collision avoidance (`idealDescName(desc, i)` escalating over `allNames(file)`),
  so the obvious naming capability is absorbed, and `import-path.ts` / `map-imports.ts` is the maintainer's
  live lane (#1528 on 2026-09-08, #1515 on 2026-08-24). `generated-file.ts` (19.8KB, the import-tracking
  emitter) is the one unexamined piece worth a read next time.

## Method notes worth keeping

1. **⭐ Run Stage 2b exclusivity BEFORE the seam audit, not after.** unblob's kill cost the full seam
   audit, a clone and a source read, and it was two `gh search` calls away at the start. The trigger to
   search is the CAPABILITY NAME the gap suggests ("overlap"), and the search must cover CLOSED issues and
   CLOSED PRs — the killing artifact here was a closed, unmerged, 17-line PR from 2022.
2. **A gap that greps clean in the source can still be publicly solved.** `grep -rniE "overlap|intersect"`
   returning nothing across the package read as absorption-clear and was, for the CODE. Prior art lives in
   the tracker and the PR queue, and four years of silence in the code is exactly what a closed fix PR
   leaves behind.
3. **The un-triaged-pool diff is worth running every session, but it saturates.** Today it returned two
   rows (`bufbuild/protobuf-es`, `vivisect/vivisect`) against 58 pool repos, versus a whole RANK 1 this
   morning. Use the basename form (`grep -qi "\b$(basename $r)\b"`), not the `owner/repo` form — the
   `owner/repo` form falsely reported 10 un-triaged repos because the logs cite bare repo names.
4. **Topic sweeps still work and still return zero LLM-infra rows.** 44 topics -> 255 rows -> ~15 genuinely
   new engineering repos. The kill rate is the problem, not the sourcing: 2b-bis and the spec-named class
   between them accounted for most of the deaths.
5. **A quiet PR queue plus a busy repo is the signal to look for.** jte surfaced because its stream is 27
   dependabot PRs around a compiler core that took three small fixes in a year, in a repo whose CI is green
   and whose maintainer answers issues at length. That is the opposite of the rapier failure mode and it is
   what "cold lane in a live repo" actually looks like in the PR lens.
