# REPO-HUNT 2026-09-23-L (hunter #25, CONSECUTIVE_MISSES=1)

Unattended olympus-factory hunt. CONSECUTIVE_MISSES=1 (< 2): no extra softening beyond the permanent
2026-09-09-B rules. Standing rulings: AI root file = ranking penalty; AI commits/trailers =
lane-scoped (SKILL 2b softened). Mandatory fork-branch exclusivity scan on every lane audit.
Mandatory honest absorption sketch (subtract reused helpers; return only if >= 250 human-eff).

Method (hunt #24 hint): INVENTED-LANE WORKSHOP inside gate-clean repos. Start with SciTools/cartopy
(outside greglucas' projection pipeline, PRs #2647/#2658): img_transform / regrid / mesh_projection,
geodesic, img_nest. Then other gate-clean repos killed only for "no lane"/"catalogue".

Requirement 0 (platform picker): OWED on any candidate (unattended run).

Excluded: every LEDGER repo (stremio-core, dyn4j, vrp, hayro, pict, BayesianOptimization, teavm,
piscsi, openglobus, pyOCD, siliconcompiler, pyfakefs, libspatialindex, csbindgen, oxipng,
messageformat), tokio-rs/turmoil, every problems/ folder repo, and hard-rule kills in 09-23-C..K.

Scratch: `worktrees/_hunt/s_0923h25/`.

## Stage 0-bis / cached index
Proven pool: re-judged in hunt #23 (J log, group P) and not re-derivable; no new approvals since
except csbindgen/pyfakefs/siliconcompiler (all LEDGER, excluded). Cached index: exhausted per K log
(78,844-slug seen union; two fresh sweeps returned 0 survivors). Not re-fetched this hunt.

## Workshop 1: SciTools/cartopy (clone s_0923h24/cartopy @ a41ff2f, 2026-09-16)
Open-PR enumeration (38 PRs, `s_0923h25/cartopy_openprs.txt`): projection pipeline held by
greglucas #2647/#2658/#2725, jackbenn #2651; tiles #2602 (dateline) and #1312 (wmts max zoom);
nothing open on img_nest, geodesic, img_transform/regrid, util.
- **img_nest (NestedImageCollection) coarse-level fallback mosaic** (invented: fill domain gaps
  from coarser collections, dedupe straddling children, skip-level ancestry, mixed pixel grids in
  `_merge_tiles`, pickled `_ancestry` second construction origin = F-9 origin seam). DEAD:
  `GeoAxes.add_image` marks the `image_for_domain` factory interface "XXX TODO: Needs deprecating"
  (Gate 8: capability in an interface the maintainers intend to retire); the module is one
  self-contained file (guard Q3/Q4: standalone mosaic function); honest sketch ~170 eff.
- **NestedImageCollection as a RasterSource** (modern interface, level choice by
  target_resolution, warp to requested projection). ABSORBED: `ogc_clients.WMTSRasterSource`
  already owns `_choose_matrix`, `_target_extents`, `_warped_located_image`; the adapter is
  ~90-110 eff after reuse.
- **geodesic.py** (direct/inverse/circle/geometry_length over pyproj.Geod): every plausible lane
  (area, npts densification, buffers) is a pyproj.Geod method = sibling absorption.
- **img_transform.regrid** (KDTree nearest): bilinear/conservative modes are named methods with
  siblings (pyresample, xESMF), as K recorded.
**cartopy verdict: no RANK-1 lane; kept as a repo, not a candidate.**

## Workshop 2: UDST/urbansim (other lanes than parcel_coverage; clone p_0921/urbansim @ 1a9a68e)
★547 BSD-3, README "Status: Active ... development of urban-simulation methods is welcome". The
maintainers' 3.3 revival sprint (2026-08-14..09-16) is closing legacy issues (transition linked
tables #243, developer pick-all-forms #194). 7.2k LOC total. Capacity-constrained location choice
(the natural invented lane over dcm.py unit_choice / group remove_alts / choice_mode axes) is
ABSORBED by the same-org sibling UDST/choicemodels `iterative_lottery_choices(alt_capacity,
chooser_size, max_iter)` (sibling-library death). Supply/demand and transition lanes are thin or in
the sprint. **DEAD for a second lane.**

## Workshop 3: cloudflare/wirefilter (MIT, ★1156, 1 approved sub = dynamic operands)
Live 2026-09-23: marmeladema/utkarshgupta137 commit stream (identifier validation, dotted byte
strings, quantifiers, map_each fast paths); CI green. Open PRs #197 (typed per-function parser
settings, parse.rs +292), #175, #174, #167, #155, #142, #98. #178 lazy fields: maintainer declined
+ public fork branch `virusdefender/wirefilter@lazy` = dead. Partial evaluation / residual filter
against a partially known ExecutionContext: every comparison whose LHS fields are set is decided by
compiling+executing it, then boolean folding = post-pass over the public AST (~150 eff, recogniser
death class). Deeper lanes delegated to a workshop agent (below).

## Parallel workshop agents (brief `s_0923h25/BRIEF-L.md`, dossiers `s_0923h25/agents/`)
Six gate-clean repos killed earlier only on lane grounds: wirefilter, softdevteam/grmtools,
onthegomap/planetiler, ricktu288/ray-optics, gkurt/tegaki, featurevisor/featurevisor. Each agent
must try >= 3 invented lanes with open-PR enumeration, fork-branch scan, signature accounts,
sibling check, honest absorption sketch (reused helpers subtracted, >= 250 human-eff) and the
Stage 6 guard.

### gkurt/tegaki (agent) — DEAD
Best invented lane, append-stable streaming timeline: text appended during playback must not re-time
ink that is already drawn. F2P reproduced: the i-dot of 'Hi' disappears when 'l' is appended.
Honest eff ~175, and it fails guard Q3/Q4 (#2, #3). The fork-branch scan killed every generator
lane: ayutaz Sigma-Lognormal pen dynamics; L0stInFades issue sweep (#27 accents, #31, #23);
tabbymarshlwio0-rgb 13k-line geometry-pipeline incl. junction routing, with claude/ and codex/
branches, created 2026-09-07 with 41 forks in two weeks = a signature account inside the lane. Other
lanes were absorbed at ~100-200 eff. Dossier `s_0923h25/agents/tegaki.md`.
### featurevisor/featurevisor (agent) — WEAK
Best invented lane: make exclusion groups actually exclusive. F2P reproduced on the real SDK: two
50% "mutually exclusive" group members overlap for 25% of users, a 10% rule inside a 50% slot
enables 51%, and the flag and variation paths disagree. Honest eff ~150 after reuse. Fails guard
Q4 #2, #4 (the Optimizely exclusion-group and GrowthBook namespace sibling model) and #5. Growing
it to repeated slots collides with our approved minimal-rebucketing region definition. Other lanes:
the maintainer's spec pins override layering; holdouts (#327) were declined; lint and test-coverage
lanes are post-passes; revision diff shipped (#429). The only clean fork/PR state is 0 open PRs. Seed
for a bug-fix lane only. Dossier `s_0923h25/agents/featurevisor.md`.
### cloudflare/wirefilter (agent) — DEAD
Best invented lane: group-preserving multi-level map-each with nested quantifiers. On base,
`any(all(x[*][*] == 1))` does not parse, and `[*][*]` flattens into one bool stream. Honest eff ~210
after reuse (MapEachIterator, QuantifierOp::reduce_bool_iter, the vec-combining arm), below 250.
Guard Q4 fails on #3/#5: the empty-group and ragged rules must be stated, and backward compatibility
forces a contextual rule. The maintainers are working in the map-each/quantifier evaluator right now
(#185/#187/#188). NEW 2026-09-23: maintainer PR #201 `dynamic-comparison-rhs` (+1306 field_expr.rs)
publishes the core of our approved wirefilter-dynamic-operands. The approved problem needs nothing,
but every operand-adjacent lane is now maintainer-held. Other lanes died too. Derived fields: a
cost, or inlining, and lazy+cache is public in the virusdefender:lazy and LRainner:feat-lazy-method-
with-cache forks. Match witness: post-pass, and spans are public in the ctf-rs and jonasbb forks.
Three-valued/null-coalescing: declined in #64. Float: closed PR #69. Scheme lineage: uniform wrap.
FFI hardening: swept by the scadastrangelove AI audit (#190-196) and arbelonson fix/195. Possible
signature account `arbelonson-source` (created 2026-03, ~46 niche forks incl. neva, fix/<issue>-
branches), recommended for sig_accounts.txt (not edited). Latent bug (bug-sized): Scheme serde
drops the nil-not-equal knob. Dossier `s_0923h25/agents/wirefilter.md`.
### softdevteam/grmtools (agent) — WEAK, best lane of the workshop so far
Invented lane: parser-side lexeme reinterpretation. `%fallback` (keyword -> ID) plus `%split`
(`>>` -> `>` `>`), tried only when the lexeme cannot be shifted from the state it is lookahead in,
and applied the same way inside CPCT+ recovery. One effective-token decision feeds lr / lr_upto /
lr_cactus and every CPCT+ repair site. A misdirecting trap is confirmed on real Pager tables: merged
states make naive per-state fallback fail, while stack-copy simulation accepts. F2P: base rejects
`%fallback` ("Unknown declaration"). Exclusivity is clean: 1 open PR (#667 codegen), 24 recent forks
compared, 0 signature accounts. Lemon's naive yyFallback is partial prior art (the naming is
MEDIUM). Honest eff ~240 (fallback alone ~150-170), so it sits in the 150-250 "needs a coupled
lever" band, with %split as that lever. Gate 8 risk: in open #612 (2025-11, the `>>` generics case)
ltratt calls lexer-parser interaction "amongst the horrors that Yacc allows ... I punted on it", and
recommends a two-`>` token plus a span check in action code as the workaround. That is not a
refusal, but it is not a welcome, and the capability answers an open issue (magnet row). Other
lanes, all dead: start rules (book recipe, #585 merged), bison precedence audit (port), completion
API (lr_upto absorbs), lex reachability (flex port), covering sentences (Menhir, #290), GLR
(siblings), lex {NAME} defs (our approved class), lossless CST (post-pass). Dossier
`s_0923h25/agents/grmtools.md`.
### onthegomap/planetiler (agent) — DEAD
Best invented lane: tile-consistent label-grid density limits for lines and polygons (#993). F2P
reproduced (polygons and lines get group=empty in all z1 tiles), but honest eff is ~160-180, and the
prior art is decisive: in-repo removal record PR #51 (merged 2022, later removed), plus closed PR
#996 with a public diff, maintainer e2e tests and msbarry's two-step design comment. Other lanes are
plumbing (<150), ports (osmium merge, geojson-vt lineMetrics, tippecanoe variable depth) or
post-passes. Our approved tippecanoe size-recourses class sits next to the density limits. The only
remaining lane is the old WEAK #298 directed line merge. Cleanup: planetiler-core/target and the
~/.m2 growth were deleted by the agent. Dossier `s_0923h25/agents/planetiler.md`.

### ricktu288/ray-optics (agent + my verification) — VIABLE -> RANK 1
Dossier `s_0923h25/agents/ray-optics.md`; F2P probe `agents/ray-optics-coherence-probe.test.js`.
- **Mechanical (re-checked live 2026-09-23):** ★1781, Apache-2.0, JS, 1 approved sub (quota 1/6).
  `Run Tests` (npm test, jest) green on every run through 09-18; `test/primitive` +
  `test/sceneObjs` = 62 suites / 1072 tests, identical 3x, headless. HEAD e55947e (2026-08-28).
  The maintainer's primitive-engine programme was merged 08-22 and has been quiet since.
- **Lane (invented): s-p coherence transport in the primitive engine.** The primitive contract
  carries two INCOHERENT powers per ray (`Simulator.js:30`: "assumed to be of no phase
  coherence"). Add the coherence term C = E_s conj(E_p) (reserved `C_0r`/`C_0i` DAG inputs, optional
  outputs) and carry it through every ray-producing stage. That covers signed Fresnel reflection,
  complex TIR phase, formula-surface default rule and clamp, GRIN scaling, detector pass-through,
  power-sampling amplification and WebGPU routing (declines -> CPU). The consumers are
  Polarizer / Retarder primitive surface types (with a legacy power-only projection), source
  polarization, and a Detector Stokes readout.
- **Discarded state (F-1/F-9), verified at source:** `cpuOutgoingRays.js:311-317`
  `writeRegionBoundary` squares the signed Fresnel ratios, which drops the sign. TIR emits unit
  power with no phase. `createOutputRay` rebuilds rays from powers only. The F-20 twist: the repo's
  signed p expression is the negative of the p amplitude in a right-handed (p, s, d) basis, so
  reusing it flips reflected S2/S3.
- **F2P (agent probe on base):** crossed +45/-45 formula polarizers pass 0.25 of the power
  (physics: 0), and a DAG reading C_0r evaluates to NaN, so the ray is silently dropped.
- **Honest absorption sketch:** the reference sketch is ~345 human-eff over 10-12 files. Reused
  helpers are createOutputRay/createInactiveRay, outputCrossesBoundary, the existing Fresnel terms,
  evaluateEffectiveMedium, setCommonInteractionInputs, createDagEvaluator, collectRayPowerQueue,
  createInitialRay, summarizePrimitiveWorkload, parseFormula, and LineObjMixin with BeamSplitter
  as the object template (BeamSplitter.js is 145 non-blank lines). The difficulty-carrying core is
  ~135-165. Polarizer (~70), Retarder (~75), sources (~35) and Stokes (~30) are template-shaped.
  With the 35-40% discount on the core, the total is **~270**. My own conservative recount is
  ~250-280. It is BORDERLINE: the builder must spike the core alone first.
- **Stage 6 guard (my run):** Q1 YES: one basis convention and transport rule feeds reflection,
  TIR, the formula default, the polarizer side flip and the Stokes readout. Q2 PARTLY:
  interdependent and misdirecting pairs are Fresnel sign vs mirror-surface negation, TIR phase sign
  vs retarder sign (a rhomb+retarder cancellation cell), and sampling amplification (a separate
  file) vs a detector reading. GRIN, validation and routing are independent. Q3 NO: coherence must
  ride each ray through the engine, and there is no public amplitude stream to post-process. Q4:
  #1 no (six distinct transforms); #2 no (contract + engine + sampling + routing + objects + detector,
  with hidden walls in stableRayPowerSampling and the smoothLineSegment carve-out); #3 the
  conventions (basis, C sign, amplitude formulas, TIR substitution) MUST be stated, ~120 words, and
  the integration walls survive that; #4 Jones/Fresnel is textbook, but the mapping onto this repo's
  P_s/P_p contract is repo-specific; #5 the integration walls survive full spelling. PASS with a
  caveat on #4.
- **Exclusivity:** open PRs 4, all dependabot/weblate. Feature-class search in all states is clean
  (discussion #250 Wollaston: the maintainer said custom surfaces handle it, meaning the s/p split
  only). Commit stream has 0 polarization/coherence commits. Forks: 66 pushed after creation.
  ssenhorst/wave-optics (claude/* branches) is a SCALAR wave engine, "There is no polarization", and
  does not touch simulationEngines/ or primitive/ (my profile: real name, 16 repos). No hit in the
  adx/deepswe list. PR authors Sabulanis (#371 spectrum visibility) and LoomZenithYonder (#355
  gallery) are both single-repo users, not signature accounts. Siblings: no JS 2D ray tracer with
  coherent polarization. `gh search repos` "polarization ray tracing" / "jones calculus" returns only
  Python notebooks. Self-collision: the approved pick touches only src/core/formula/*.
- **Risks:** (1) Convention text pushes meta.md toward the 500-word cap. Every sign needs a
  closed-form test. (2) Signs stack multiplicatively, so there is a real 0% risk: batch early. (3)
  The LOC floor leans on the template objects (a hook breadth flag is possible). Spike the core; if it
  is <150 human-eff the lane drops to WEAK. (4) ROADMAP: legacy sceneObjs become module instances
  in 2027. Implement Polarizer/Retarder as primitive surface types, with the legacy object giving a
  stated power-only projection. (5) "Polarization ray tracing" is outsider-nameable (MEDIUM):
  phrase meta.md on the P_s/P_p primitive contract and re-run PR-DIFF at submit. (6) Requirement 0
  (picker) is OWED, although the repo already carries an approved sub.

## Stage 6 guard on RANK 1
Run above (ray-optics lane P): passes Q1/Q3 and Q4 with a #4 caveat; Q2 partial but with three
misdirecting interdependent pairs. Handed over with the LOC-spike condition.

## Result: CANDIDATE ricktu288/ray-optics (s-p coherence transport)
Fallbacks: softdevteam/grmtools (%fallback + %split lexeme reinterpretation, ~240, WEAK: needs a
lever, Gate 8 tone in #612); featurevisor/featurevisor (exclusive groups bug-fix lane, ~150, WEAK).
Stale / new notes for the human (SATURATED-REPOS.md not edited): wirefilter maintainer PR #201
publishes our approved dynamic-operands core; candidate signature accounts `arbelonson-source`
(wirefilter, neva) and `tabbymarshlwio0-rgb` (tegaki, 41 forks in two weeks) for sig_accounts.txt.
Disk: / 17G free at the end. The agents' build output (wirefilter probe 430M, grmtools probe 162M,
planetiler target, ray-optics/tegaki node_modules) was deleted. Clones kept under s_0923h25/.
