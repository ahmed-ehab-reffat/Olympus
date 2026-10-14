# DESIGN.md - teavm-incremental-fact-reuse (SHELVED at the measure-first spike)

Status: DEAD before scope-lock, machinery-absorbed UNDER-FLOOR. Kept as the record of the spike. No tests,
no meta.md. Phases 3-5 were not completed because the LOC gate (PICK-FILTER Gate 4 / hunt Gate 7) failed
first, as the factory brief asks ("measure-first full-scope spike ... kill early under 200").

## 1. Lane (from hunt h53)
Reuse cached method bodies across incremental builds while the facts they were compiled against still
hold: the member-level API of each class the entry names, the method's own body, every class on the
resolution path of a member it names, and (AST entries) whether called methods are async. Plugin-registered
dependencies and `setNoCache` keep their body-level meaning; disk caches persist the same records.

## 2. Phase 1 repo understanding (done)
- Architecture: bytecode -> `ClassHolderSource` -> `DependencyAnalyzer` (whose `DependencyClassSource` runs
  class transformers and `ReferenceResolver`, so its programs are already resolved) -> optimizer (eager
  pipeline, or the lazy SIMPLE pipeline with a program supplier per method) -> backend (`Renderer` for JS,
  `ClassGenerator` for C) decompiling each method to an AST. `ProgramCache` caches optimized programs,
  `MethodNodeCache` caches ASTs (regular and async), both keyed by `MethodReference` with a `String[]` of
  class-name dependencies checked against a `CacheStatus`.
- Subsystems: `cache/` (in-memory and disk caches, IO, status), `dependency/` (analysis, ReferenceResolver),
  `vm/TeaVM` (pipelines and the program-cache gates), `backend/javascript/rendering/Renderer` (AST cache, async
  split), `backend/c/generate/ClassGenerator` (C AST cache), `model/util/AsyncProgramSplitter`.
- Entanglement zones: the `isStaleMethod` gate at 5 sites; `AnnotationAwareCacheStatus` (plugin deps, parent
  propagation); the async split set computed per build in `Renderer.render`.
- Tests: `tests/src/test/java/org/teavm/incremental/IncrementalTest.java` (JUnit 5, Rhino, three builds:
  old / refreshed / new, captures recompiled methods). Template for new data packages:
  `tests/src/test/java/org/teavm/incremental/data/simple/`.

## 3. Absorption table (measured spike, hook 192 human-effective / 247 raw / 11 files)

| Hunt decision point | Hunt price | Spike | Why |
|---|---|---|---|
| D1 resolution path recorded in ReferenceResolver | 30-45 | 0 | the body fingerprint is taken over the RESOLVED input program from `dependencyAnalyzer.getClassSource()`; a changed resolution changes the fingerprint |
| D2 API fingerprint | 20-35 | ~25 | members, modifiers, annotations, parent, interfaces, sorted and digested |
| D3 own-body fingerprint + gate removal at 4 sites | 35-50 | ~30 | `ListingBuilder` text digest; 5 sites incl. the C backend |
| D4 two dependency kinds x 4 cache formats | 60-90 | ~8 | facts are `key=value` strings through the existing `Supplier<String[]>` channel; disk caches already persist it; each cache swaps `isStaleClass` for `isStaleDependency` |
| D5 async facts + Renderer wiring | 35-55 | ~25 | one split-point signature per async entry via a newly exposed `AsyncProgramSplitter.isSplitPoint` |
| D6 status rework (API vs body, interface loop, cycle memo) | 25-40 | ~14 | method gate = noCache + plugin deps; two base bugs fixed in a few lines |
| helper class plumbing (fact encoding, validator) | - | ~45 | |
| **Total** | **205-315** | **192** | 0.74x of the hunt's midpoint |

A lean passer would be smaller still: no C-backend site, string facts without a helper class.

## 4. Trap thesis status
The hunt's T2 (resolution path) is not a trap under the natural cache key; T1 (precision vs async) is
discharged by the split signature; T3 (gate removal vs plugin deps) is a 5-line status rule. Only F-10 cells
(change kind x route x cache) would remain, with nothing load-bearing behind them.

## 5. Base bugs found (for a future lane)
- `DiskMethodNodeCache.flush` writes regular AST entries to the `-async` file name and never creates the
  parent directory, so regular AST entries never reload from disk.
- `AnnotationAwareCacheStatus.computeClassStatus` re-checks `getParent()` once per interface instead of the
  interface; an UNDECIDED hit inside a plugin-dependency cycle is memoised as FRESH.
- `ProgramDependencyExtractor`/`AstDependencyExtractor` record only the declaring class after resolution
  (harmless once the cache keys on the resolved body).
