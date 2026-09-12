# Repo hunt 2026-09-10-D — JOSS (3200 papers), named engines, JVM gap-axis; 0 authorable, 1 new LAW

Fourth and fifth sweeps of the day, run after `datafixerupper-optics` was implemented, measured at
**88 effective LOC** and shelved. Axes: the full JOSS corpus (2 pulls, ~3,200 published papers ->
1,147 + 2,051 unique GitHub repos), a named domain-engine list, the proven pool, the owner axis
(other repos by our 47 approved-repo owners), and a JVM-specific sweep motivated by competitor-footprint
evidence.

**Result: no authorable candidate.** The product of the day is a new pick-time law plus a much sharper
picture of WHY the search is not converging.

---

## ⭐ NEW LAW — FRAMEWORK-MATURITY is a pick-time gate, and it is the one that killed the day's best repo

`rejected/datafixerupper-optics` passed EVERY gate this workspace has — mechanical, Requirement 7,
competitor profiling, Gate 8, exclusivity file-overlay, lane density, self-collision, determinism,
Docker — and had its behavioural gap **reproduced on base**. It was implemented in full, worked to
contract, and broke no existing test. It measured **88 human-effective LOC against a 200 floor.**

Three estimates, all wrong the same way: sketch ~320 -> after spiking the largest file ~120-165 -> after
adding a genuinely forced consumer layer ~260-300 -> **actual 88**.

The cause: in a framework-mature subsystem every piece is a thin call-through. The consumer layer
predicted at 60-140 lines was **29** (three `if (TypedOptic.instanceOf(bounds, token))` guards reusing
existing `getAll`/`updateCap`); each merge site was **6 lines**, because `Sum.mergeOptics`,
`ListTraversal`, `Optics.toTraversal` and `TypedOptic.compose` already existed.

**The tell is visible at pick time and reads backwards.** "The repo already does the right thing on the
neighbouring axis" is a fairness gift AND proof that the machinery exists. Add to Stage 3b:

> Name the DATA STRUCTURE or PASS the repo has no analogue of. If the capability composes existing
> primitives, it will land under the floor no matter how many files it touches. Both DFU picks that
> shipped added machinery the repo lacked entirely (a new codec type; a reference graph + cycle
> detection + a two-phase build). The one that rode existing optics collapsed.

**Method change:** in a mature framework, do not spike one file and re-estimate. Implement the THINNEST
end-to-end version and run `effective_loc_check.py` BEFORE writing any tests.

---

## Killed this session

| Repo | ★ | Gate | Evidence |
|---|---|---|---|
| **xoolive/traffic** | 512 | **Requirement 7** | the `tests` workflow is FAILING on master (scheduled run 2026-09-06), `docs` too; deps include `onnxruntime`, `rs1090` (Rust ext), `pyopensky`, `py7zr` -> Docker infeasible. Otherwise the best domain-engine shape in JOSS (air-traffic processing, non-textbook algorithms, 10 issues) |
| **sharkdp/numbat** | 2683 | **already in the ledger** | "contested (3 subs + 3 competitors) — maintainer + `Ryan-D-Gast` hold every language lane via open PRs (#836 complex, #802 modules, #800/#847 struct methods, #795 adaptive RK); `ChrisJr404` (recorded signature) filed Aug 2026". Caught by the pool-reads-`rejected/` gate before any API spend |
| **i-net-software/JWebAssembly** | 1052 | **capability-consuming core + CI** | 53 commits/12mo, ALL by the solo maintainer and ALL in the core type manager (WASM-GC migration: struct types, block types, recursive type groups, exception tags). "Build with Java 11" FAILING on master. The cpp-peglib pattern: an empty PR queue because the maintainer does everything himself |
| **bytedance/appshark** | 1753 | winding down | 7 commits/12mo and they are REMOVALS ("remove ui, because it has path traversal vulnerability", "dont provide jadx because of compliance reason") |
| **yinwang0/pysonar2** | 1423 | **recency-dead** | **0 code commits in 12 months**; last real code 2022-05 |
| JOSS bulk (53 survivors of ~3,200 papers) | — | published-method class | emcee (MCMC), PyWavelets, kepler-mapper (Mapper), sysidentpy (NARMAX), pymatting, opt_einsum, sbi/bayesflow/GPJax/foolbox/neurodiffeq (ML), manif + ginkgo (named mathematics), geemap/leafmap/earthpy/pyvista/pyvisa (wrappers over GEE/VTK/VISA), jsPsych (framework), mne-python (506 issues) |
| JVM sweep (30 rows) | — | mixed | commonmark-java (spec + our markdown history), j2cl/NullAway (Google/Uber velocity), MyPerf4J (6 commits/12mo), Trail-Sense (Android), sedona/ofbiz (Apache scale), TexasHoldemSolverJava (CFR = published) |

Previously killed today, for the record: jte, protobuf-es, unblob, opensheetmusicdisplay, parry,
Vineflower, simpeg, digler, PyBaMM, beartype, ezdxf, go-astits, trustfall, cpp-peglib, brigadier, mesa,
anndata, extendr.

---

## Why the search is not converging — the structural finding

Across five sweeps today (~250 topics, ~3,200 JOSS papers, the proven pool, the owner axis, a JVM axis),
every mechanically-clean repo died to exactly one of four causes:

1. **Competitor swarm** — three signature accounts mapped and ~20 repos contested. `youdie006` alone
   (422 repos) covers jet, Crow, **mp4ff**, gonja, brotli, go-mysql-server, kin-openapi, jsonata, md4c,
   phonenumbers, osmd, ezdxf. Plus `binggao1230` (9 open PRs on PyBaMM incl. the target lane) and
   `ChrisJr404`.
2. **Maintainer sweeps the correctness gap class themselves** — anndata, cpp-peglib, simpeg,
   protobuf-es, JWebAssembly, mesa. This is invisible to the PR-queue probe when the maintainer pushes
   directly, and it consumes precisely the f2p surface.
3. **Maintainer-declined capability class** — jte (3 declines), protobuf-es ("very conservative adding
   new options"), beartype (the tracker IS the roadmap).
4. **Framework-maturity** — the new law above. Where 1-3 do NOT apply, the repo tends to be so
   well-factored that capabilities collapse below the LOC floor.

**The JVM gap-axis hypothesis was worth testing and did not pay.** Every competitor footprint mapped
today is Python/Go/JS, and DFU (Java) is competitor-clean — but the JVM sweep returned only
capability-consuming or spec-named repos. The competitor absence is real; the authorable surface is not
obviously larger.

## Reusable assets produced today

- `rejected/datafixerupper-optics/solution-partial.patch` — a working, tested implementation (6 files,
  base 52/52 x3) should anyone want the product-focus behaviour as part of a larger DFU pick.
- A verified DFU environment: Dockerfile, `javac + JUnitCore` harness, determinism baseline.
- Three competitor accounts mapped, four cleared as genuine (`aabills`, `philocalyst`, `posita`,
  `bunlongheng`).
