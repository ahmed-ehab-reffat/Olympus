# Repo hunt 2026-09-19-F — factory hunter #1 (CONSECUTIVE_MISSES=0); messageformat re-verified as RANK 1

This was the first `olympus-factory` hunt. The ledger was empty. `problems/` held csbindgen (a human
session) and oxipng, so both repos are taken. The gates are the skill as written, including the
2026-09-09-B softening already in SKILL.md. The extra BRIEF-0919-D softenings were NOT applied
because the miss count is 0. No star or issue windows were widened.

Order followed: proven pool (0-bis), then the cached band and dossiers, then two fresh niche sweeps
(bio and fab, brief `worktrees/_hunt/agents/BRIEF-0919-F.md`).

| Step | Result |
|---|---|
| 0-bis proven pool | Pool rebuilt from meta.md frontmatter; every repo sits at 1-3 subs. Lanes were already recorded dead or spent in `SATURATED-REPOS.md` B3-decies..duodecies: kira, Cwerg #3, pcapplusplus, makerjs, rmk, h5py, openexr, worldengine. The ir-sim events lane is ours; its other lanes (planners, sensors, maps) are unaudited, which is a lead only. No new pool lane was found this run |
| Cached band | `unshown_0919.txt` was re-filtered against `deadlist_v9`: 314 rows remain, all app, web, ML or tooling junk (as 09-19 found). Nothing engine-shaped is worth screening |
| Cached dossiers | messageformat (09-19-D RANK 1) is not in the ledger and has no `problems/` folder, so it is free. It was re-verified below. oxipng is now taken |
| Sweep bio | 54 slugs. macs3-project/MACS is a FALLBACK (magnet, see below). goatools is dead (topGO ports queued publicly); fastp is dead (CI is only a smoke test). Dossier `agents/bio-0919F.md` |
| Sweep fab | 62 slugs, no survivor. Permissive repos above 500 stars are textbook robotics catalogues, unbuildable ROS/Bazel stacks, or have red CI; the G-code/CAM tools are copyleft or under 500 stars (rayforge 279 is worth rechecking). mink HQP is about 150 eff with named-algorithm siblings. FastAccelStepper's README puts coordinated planning out of scope. Dossier `agents/fab-0919F.md` |

## RANK 1 — messageformat/messageformat (TypeScript 94%, MIT root + Apache-2.0 mf2 packages, ★1770)

- **Mechanics, re-checked today:**
  - Languages: TS 709,971 bytes and JS 46,989.
  - Default-branch runs are all `success` (Node.js, CodeQL, Docs; last 2026-04-26).
  - 42 commits in 12 months, all by `eemeli`; last code commit 2026-04-26 (xliff). No AI marks or trailers.
  - PR authors carry zero signature hits.
  - Quota is 0/6. No record in `SATURATED-REPOS.md` § A/A0.
- **Base:** `0ffba11d49b1aa4579497ccec7fb9ec3c082e709`. Clone at `worktrees/messageformat` with node_modules (304M). An untracked `mf2/icu-messageformat-1/src/zz-probe.test.ts` is left over from the 09-19-D probe; delete it before authoring.
- **Lane:** add `messageToMF1` to `@messageformat/icu-messageformat-1`. It turns an MF2 message into ICU MF1 source that this repo's MF1 compiler formats exactly as MF2 formats the message, for every input in a given locale. Coupled second lever on the same kernel: `messageToFluent` must reproduce the same selection for sparse variant lists.
- **Missing algorithm:** compile a sparse multi-selector variant list into a nested single-selector tree that reproduces `mf2/messageformat/src/select-pattern.ts:31-72`. That means backtracking: drop the previous selector's best key and restart when no candidate remains. The tree needs:
  - per-selector classes: exact `=N`, locale plural categories, `*`;
  - an `other` or default in every select;
  - offset and `#` scope, where a nested plural steals `#`, so the nesting order is constrained;
  - context-dependent MF1 escaping, where `#` is quoted only inside plural bodies;
  - argType/argStyle recovery from the `mf1:*` attributes;
  - rejection of inexpressible input.

  The repo has NO MF1 printer (`mf1/packages/parser` is lexer + parser only).
- **F2P reproduced on base today (vitest probe, deleted):**
  - The package exports only `MF1Functions, mf1ToMessage, mf1ToMessageData, mf1Validate`.
  - For `.input {$a :number} .input {$b :string} .match $a $b / 1 x {{A}} / one * {{B}} / * x {{C}} / * * {{D}}` in en, MF2 gives A/B/C/D for (1,x)/(1,y)/(2,x)/(2,y).
  - `messageToFluent` emits `[1] { $b -> [x] A }` with no default. `@fluent/syntax` re-parses the serialized message as `Junk`, and B is unreachable for (1,y).
  - The in-repo precedent (`message-to-fluent.ts:52-91`, consecutive-prefix grouping) is exactly the naive nesting. That makes it a misdirecting F-39-style template.
- **Size:** decision-point sketch:
  - declaration analysis: 35
  - class enumeration: 30
  - MF2-equivalent selection: 45
  - order-constrained tree build and collapse: 50
  - pattern emission with escaping and function recovery: 90
  - fluent default and kernel reuse: 40
  - errors: 20

  Total is about 310 eff (295-385 range) over 3-5 files in 2-3 packages. The leanest passer uses the MF2 runtime as a selection oracle (marker patterns) and lands around 230-260: that discharges the backtracking but not the class enumeration, `#`/offset ordering or escaping.
- **Exclusivity, re-run today:**
  - All 4 open PRs enumerated by file list: #471 resource parser, #399 language server, #362/#329 in mf1/core. None touch the lane.
  - Issue/PR searches: `mf1 export`, `to MF1`, `stringify`, `MF2 to MF1`, `convert MessageFormat 2`, `sparse variants`, `fluent default variant`, `messageToFluent`. Nothing relevant.
  - GitHub code search for `mf2ToMf1`, `messageToMF1`, `stringifyMF1` and `mf2-to-mf1`: 0 hits.
  - Newest forks are clean.
  - `messageToIcu` hits `k0d13/saykit` (★7). It is a nested-tree to ICU stringifier with `#` scope and escaping, so it is partial emitter prior art. It has no sparse-selector compilation, so the kernel is not there.
- **Death-class guard (Stage 6):** PASS with a caveat.
  1. One kernel (the variant table turned into per-selector classes with MF2-equivalent fallback) feeds both the MF1 and Fluent emitters. Its nesting-order choice constrains `#`/offset mapping and escaping context in the MF1 emitter.
  2. The traps interlock through that ordering decision.
  3. It is a new file, but it carries a new algorithm rather than a recogniser. The nearest approved shape is customasm-ruledef-disassembly, an inversion approved at 10%.
  4. Pre-Pick Guard 1-5: not a uniform wrap; the transform spans 2-3 packages; the MF2 selection is stated in the spec and in repo code, so nothing hinges on an unstated rule; not a port; the difficulty survives full spelling-out.

  Caveat: the kin-openapi "mechanical inverse" row. The forward converter only emits DENSE messages, so the inverse of the dense case IS mechanical. Tests must weight sparse and backtracking cells.
- **Risks:**
  1. Locale-data FP: the MF1 runtime uses make-plural and MF2 uses Intl.PluralRules. Keep cells on locales and integers where both agree, and state the equivalence contract.
  2. The direction is outsider-nameable: phrase meta.md on the repo model and re-run exclusivity at submit.
  3. The description is heavy (API, locale argument, error cases).
  4. Too-easy risk if the oracle shortcut plus a strong emitter clears everything. Harden with `#`/offset ordering and escaping cross-product cells (F-10).
- **Owed:** Requirement 0 picker check, the Gate 8 six-check at scope lock, and a reference spike to confirm ≥250 human-eff.

## FALLBACKS
1. **macs3-project/MACS** (Python, BSD-3, ★784).
   - Lane: a genome blacklist threaded through callpeak's statistics: lambda_bg genome size, the bp-ranked q-value table, cutoff analysis, gap-aware segmentation, and summit clipping. Second lever: the bdgpeakcall/bdgbroadcall/bdgcmp mask.
   - 215-265 eff, and an 80-line shortcut fails four cell classes. CI green; pytest 104 pass 3x.
   - ⚠️ Magnet: issue #613 "Is there a way to specify blacklisted regions" has been open since 2024-01-18 with 0 comments and asks for exactly this nameable feature, which is the Stage 2b reject row. The ENCODE-blacklist concept is outsider-nameable.
   - Size sits at the floor, and a Cython rebuild takes about 4.7 min per iteration. Use only if the lane can be phrased as the q-value/segmentation accounting rather than "add --blacklist".
   - Clone: `worktrees/_hunt/f_bio/MACS`.
2. **libspatialindex/libspatialindex** (09-19-E): temporal kNN on MVR/TPR trees, ~215-295 eff, missing-arm shape.
3. **nkaz001/hftbacktest** (09-19-D): stop orders, nameable, maintainer silent.

## Tooling
- `agents/BRIEF-0919-F.md` (the skill-as-written gate list for miss count 0).
- Screened slugs: `agents/{bio,fab}-0919F.screened.txt`. Add both to the next dead list (v10).
- Disk: root is down to ~9G free after the sweeps.

## Next hunt
If messageformat dies at the picker or the spike, spike MACS in its q-value/segmentation framing
first, or audit ir-sim's planner/sensor lanes (proven pool). Fresh niches are near-exhausted.
Rayforge (★279) is worth rechecking at 500.
