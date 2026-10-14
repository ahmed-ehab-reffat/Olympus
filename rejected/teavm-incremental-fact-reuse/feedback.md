# teavm-incremental-fact-reuse - feedback

Status: DEAD 2026-10-05 (machinery-absorbed UNDER-FLOOR at the measure-first spike, 192 < 200). Shelved to rejected/. Factory MODE=SLICE. Repo konsoletyper/teavm, base 11a50bc0.
Lane: reuse cached method bodies across incremental builds while the facts they were compiled against still hold
(hunt h53, REPO-HUNT-2026-10-05-E). Second teavm lane; disjoint from approved-problems/teavm-method-summaries.

## Decisions made without the human (factory run)
- Requirement 7 (latest master Build failed on `test (wasm-gc)` only, js leg green): recorded, NOT decided here. OWED to the human.

## Attempt history

### 2026-10-05 measure-first spike (before DESIGN.md scope-lock)
Full lane written end to end in the clone (worktrees/teavm-incr): `CacheFacts` (class API fingerprint over
members/modifiers/annotations/hierarchy, program fingerprint via ListingBuilder, fact strings, per-lookup
validator), `CacheStatus.isStaleDependency` default, AnnotationAwareCacheStatus rework (method gate =
noCache + plugin deps only; interface-loop fix; UNDECIDED-memo fix), program cache at BOTH TeaVM sites
(eager + lazy), regular and async AST caches in the JS Renderer (async split signature through a newly
exposed `AsyncProgramSplitter.isSplitPoint`), the C backend AST site, in-memory and disk caches (disk AST
file-name and mkdirs fixes).

Hook (`effective_loc_check.py`): **192 human-effective**, 247 raw, 11 files, padding-floor 67. 102 of the
192 are the one new helper class; 10 are moved splitter code.

Why the hunt priced 205-315 and the lane measures 192:
- D1 (resolution path, priced 30-45) is absorbed: the cache key hashes the RESOLVED input program that
  `dependencyAnalyzer.getClassSource()` hands out, so a changed resolution changes the body fingerprint. No
  ReferenceResolver change is needed at all.
- D4 (two dependency kinds x 4 cache formats, priced 60-90) is absorbed: facts travel through the existing
  `Supplier<String[]>` dependency channel that both disk caches already persist. Each cache needs one
  token changed (`isStaleClass` -> `isStaleDependency`).
- D5 (async facts, priced 35-55) is absorbed by the splitter's own decision function: one split-point
  signature per async entry.
- D3/D6 are a gate swap at five sites plus ~15 lines of status logic.
A lean passer would land well under the reference (string-encoded facts, no C site).

### Verdict
DEAD. 192 human-effective for the full lane against the 200 floor (design target 250-300), so no honest
scope reaches it without padding. Fallback tried in the same run: pyOCD lane K (FALLBACKS[0]), spike 132
human-effective, also DEAD (see rejected/pyocd-deferred-register-memory-writes/). Recorded in
Instructions/TOO-EASY.md (case study + Machinery-absorbed row). Not an exclusivity/dedupe death, so no
SATURATED-REPOS.md row.

Not run because the lane died first: SIX-CHECK, PR-DIFF exclusivity re-check, base health 3x of
`org.teavm.incremental.*`, the two base-bug probes, tests, meta.md. The spike was written and measured with
the hook but not executed; correctness fixes would move it by a handful of lines, not by 60.
Requirement 7 (master Build failed on `test (wasm-gc)` only) stays unrecorded as a decision: moot.

Dockerfile here is an unvalidated DRAFT: the one build attempt (2026-10-05, 11m36s) failed at
`:tests:collectTestLibs` with "Entry core-0.17.0-SNAPSHOT.jar is a duplicate" (the init-script Copy needs
`duplicatesStrategy = DuplicatesStrategy.EXCLUDE`). No image was produced, so nothing to remove. Note for a
future teavm tests-module lane: the Gradle configure + jar phase alone took ~11 minutes cold.
