# DESIGN.md — cwerg-compact-pointer-unions

Base: robertmuth/Cwerg 3bc94f7c1c26834f98c614aef51b5aa7370615d9 (master HEAD, 2026-06-19; same base as
cwerg-bcopy-bzero-lowering and cwerg-fe-address-constants). Lane from hunt #63.

## Phase 1 — Repo understanding

**Architecture (one paragraph).** Cwerg is a compiler in two twin implementations under an
identical-output convention: a Python reference (`FE/*.py`, `BE/**/*.py`) and a C++ port
(`FE/*.cc`, `BE/**/*.cc`). The front end parses Cwerg source (`.cw`), symbolizes, typifies into a
`TypeCorpus` of canonical types (sizes, alignments and IR register kinds fixed per target by
`TargetArchConfig`), partially evaluates constants, then lowers in phases (`compiler.py` / `compiler.cc`):
initial lowering (implicit conversions, `is` and tagged-union `==` desugaring, checked-narrow
simplification), optimize (Expr3 gone), constant pooling, span then union elimination
(`canonicalize_span`, `canonicalize_union`: every tagged union becomes a `{tag, union}` record),
large-arg rewriting, legalize, and IR emission (`emit_ir`). The backend (`BE/`) turns IR into
x64/a64/a32 ELF executables run under qemu.

**Five subsystems + boundaries.**
1. Parser / macro / symbolizer (`parse`, `macro`, `symbolize`) — AST in.
2. Typing (`typify`, `type_corpus`, `cwast.CanonType`) — canonical types, layout and register kinds per target.
3. Constant evaluation (`eval`) — `x_eval`, static_assert, compile-time `is`.
4. Desugaring passes (`canonicalize*`, `controlflow`, `optimize`) — the phase pipeline in `compiler.*`.
5. IR emission (`emit_ir`) + backend (`BE/`).

**High-entanglement zones.**
1. Union canonicalization: `canonicalize.FunDesugarExprIs` / `FunDesugarTaggedUnionComparisons` /
   `canonicalize_union.FunSimplifyTaggedExprNarrow` create `ExprUnionTag` / `ExprUnionUntagged` /
   unchecked `ExprNarrow`, which `ReplaceUnions` then lowers against the replacement record.
2. Type replacement identity: `CanonType.LinkReplacementType` sets `replacement.original_type`, and
   `get_original_typeid` walks it (issue #44: a shared replacement type cannot map back).
3. Layout vs. lowering: `type_corpus` fixes sizes/offsets at typify time; the replacement record is
   built much later; if they disagree, record fields silently overlap.

**Test framework.** Programs `FE/LangTest/*_test.cw`, `FE/TestData/*_test.cw`, `FE/Lib/*_test.cw` use
`import test` (`test\AssertEq#`, `test\Success#`); `FE/Makefile_py` / `Makefile_cc` compile with
`compiler.py` / `compiler.exe`, assemble with the codegen tools and run (qemu for arm). `Makefile_cc`
"assimilation" diffs py vs cc IR. Template: `FE/LangTest/sum_tagged_test.cw`.

## Phase 2 — Existing-PR / publicly-solved check

Canonical org: `gh api repos/robertmuth/Cwerg -q .full_name` = robertmuth/Cwerg (no move).
Searches (PR + issue, state all): union, optimize_union_tag, nullable, niche, optional pointer, tagged
union size, union representation, union optimization, compact union, null pointer. Hits: #31 (closed,
union==member compare, shipped long ago), #44 (closed, "Desugar ExprWrap/ExprUnwrap ... get rid of
DefEnum and DefType" — maintainer comment explains a shared replacement type cannot map back to the
original for union tags; it is the identity wall this pick rides, not this capability), #56 (open,
"no real checks" for auto-init pointers; adjacent, not this capability). 9 PRs ever (CI, typos, a Go
FE stub), none touching unions; only branch is master. `gh search code optimize_union_tag` finds only
Cwerg. History: be870a21 (2024-02) disabled the flag to make the linked-list example work; the 2024
tree had only the sizing hack and no lowering, so this is a disabled half-feature, not a removed
capability (named in the precheck reasoning). base..HEAD = 0 commits (base is HEAD).

## Phase 3 — Candidates (lane fixed by the hunt; alternatives recorded in the hunt dossier)

| Candidate | One-line behavior | Shape | Files | Raw | Meaningful | Pred. Nova | Verdict |
|---|---|---|---|---|---|---|---|
| **Compact pointer unions (picked)** | union of one pointer + zero-size members is one word; every union op still works | O-Composite-extend (twin FE) | 9 | ~400 slice, ~550 full | 317 slice (hook) | 0 | PICK |
| Checked indexing + ptr_dec | emit documented bound checks | A1 | 4 | 64 | ~55 | high | dead (<200) |
| Different-size union widening | replace NYI assert | C | 2 | ~20 | ~15 | high | dead |
| BE clmul | lower NYI opcode | O-Pipeline | many | n/a | n/a | n/a | derivative of bcopy |

Step A (TOO-EASY guard): not uniform-wrap (one representation, five interacting conversion families
plus layout and emitter cells); not a single-subsystem mechanical transform (typing layout,
replacement identity, two lowering stages, global data emission, twin FE); hardness does not depend on
hiding anything (every rule below survives being stated); not a memorized spec port (Rust niche /
Zig `?*T` name the idea, but Cwerg's desugaring is bespoke and the multi-error-code case has no null
niche analogue); globally coupled (one representation consumed by every union operation).
Gate 1 caveat (value-vs-cost): base output is correct, only larger. Size is a language observable
(`size_of`, `offset_of`, `static_assert`, record layout), the design doc (`FE/Docs/design_choices.md:210`)
promises it, and two repo tests comment the target size. Recorded as a risk.

Step B (arsenal): S4 machinery-riding integration (every union operation the engine already has must
keep working through the new representation) led, with S3 baseline preservation through a shared
chokepoint (`ReplaceUnions` / `type_corpus` are shared by regular unions) and S6 (layout computed by
`type_corpus` vs. representation chosen by `canonicalize_union`: two evaluators of one fact).

## Phase 4 — Design

### 1. Title
Add one-word compact tagged unions to the Cwerg front ends

### 2. Shape classification
- Shape: O-Composite-extend over twin front ends (closest accepted: cwerg-fe-address-constants).
- Best agent: Orion (long-horizon twin edits).
- Dominant verdict expected: INTEGRATION_ERROR / WRONG_LOGIC (runtime trap, segfault, assert in a pass
  the agent did not write).

### 3. Public API surface
No new syntax or API. Observable surface: `size_of`, `offset_of`, `is`, `union_tag`, `==`/`!=` with a
member, `narrow_as` (checked/unchecked), `trylet`, implicit widening, global initializers, the
`-arch x64|a64|a32` outputs of `FE/compiler.py` and `build/compiler.exe`.

### 4. Canonical output form
- Compact union: tagged, members = exactly one pointer (or wrapped pointer) + >= 1 zero-size members
  (void / wrapped void); size = alignment = pointer size on every target.
- Every other union: unchanged layout (tag + payload; zero-only unions stay one typeid).
- `union_tag` returns the typeid of the held member (unchanged semantics).
- Program output identical between py and cc front ends on every target.

### 5. Blind-spot pre-empts
- Parallel-API: "The Python and C++ front ends must behave the same way."
- Pipeline placement: not stated (the agent must find where layout and lowering meet).
- Wrapped pointer counts as the pointer member (F-18 spelling): stated once.

### 6. Description draft
See meta.md (draft in feedback.md until FINISH; not part of the slice gate).

### 7. File footprint (measured, slice)
| Action | Path | Raw | Human-eff |
|---|---|---|---|
| MODIFY | FE/canonicalize_union.py | +148 | 117 |
| MODIFY | FE/canonicalize_union.cc | +223 | 181 |
| MODIFY | FE/type_corpus.{py,cc,h} | +18 | 14 |
| MODIFY | FE/compiler.{py,cc}, FE/canonicalize_union.h, FE/canonicalize.h | +5 | 5 |
TOTAL slice: raw 394 / human-effective 317 across 9 files (hook). Padding floor 120 (twin mirror;
address-constants had the same profile at slice and was accepted at 365).

### 8. Solution outline (reference)
- `type_corpus`: flags on for STD targets; register hack moved after the untagged check and made to
  unwrap wrapped pointers, so sizing and register kind agree (`IsCompactUnion` = tagged + pointer reg).
- Replacement: a fresh per-union record `xcompact_<name> { bits: untagged(members..., uint) }` (fresh
  type, so `LinkReplacementType` identity stays unique; a shared `uint`/`^T` replacement corrupts
  `original_type`, issue #44).
- Encoding: pointer member stored as is; zero-size member stored as its typeid (< 2^16; lowest data
  address on a32 is 0x31a24, x64 0x411d8c).
- `_MakeCompactTag`: `let b = narrow!(x.bits, uint); if b < 65536 return as(b, typeid); return typeid(ptr)`.
- `_MakeCompactFromMember`, `_MakeCompactFromUnion` (compact / zero-only / regular sources),
  `_MakeUnionFromCompact` (into regular unions), `ExprUnionUntagged` -> `x.bits` (narrow to member reuses
  the untagged-union path, zero-size members included in `bits`).
- Global data: pointer member widens into `bits` as `ExprWiden(ExprAddrOf)`, which the existing data
  emitter already relocates (no emitter change needed in the reference).
- C++ mirror in `canonicalize_union.cc`, `ReplaceUnions(mod, tc)`.

### 9. Test outline
New programs `FE/UnionTest/<name>_755373_test.cw`, each compiled by py and cc for x64/a64/a32 and
run, plus py/cc output parity per target (9 cases per program). Each program carries a size
`static_assert` so it fails on base; with the asserts removed every program runs green on BASE with
regular unions (verified), so every runtime check is baseline behaviour the contract preserves.
- `layout`: sizes/offsets of compact, multi-error, wrapped-pointer, nested-union, non-compact
  (two pointers, pointer + wrapped u16) unions; records/arrays; linked list via trylet; guard field after
  a wrapped-pointer compact field (silent-overlap discriminator).
- `ops`: is / union_tag / == / != / checked narrow / trylet with error binding / write through narrowed
  pointer / params and results.
- `convert`: compact <-> regular (Wide) <-> zero-only (Errs) <-> compact superset (Any) <-> Maybe.
- `globals`: compact globals initialized with addresses and error values, constant tables, records
  with compact fields in global data (emitter cell).
- Existing `sizeof_test.cw` and `linked_list_gen_test.cw` updated to the new sizes; run in new mode,
  excluded from base mode (their asserts pin the layout this feature changes).

### 10. Forced bounds
None (no new signatures). `ReplaceUnions` gains a `TypeCorpus` parameter in both twins (internal).

### 11. Predicted trap matrix
| # | Trap | F-id | Arsenal | Axis | Interdependent with | Why agents hit it | Pre-empt sentence | Catching test |
|---|---|---|---|---|---|---|---|---|
| 1 | Flip-the-flag silent overlap: sizing says one word, representation still `{tag, union}` (reproduced: flag-only build traps at runtime in ll/compact probes) | F-9 / F-1 | S6 | layout vs lowering stage | #2, #3 | the flag looks like the whole feature | "occupies a single pointer word" | every program (runtime), layout guard field |
| 2 | Wrapped pointer member: `type_corpus` sizing unwraps, the register hack does not; a predicate keyed on `is_ptr()` sizes one word and lowers two (reproduced on the hunter sketch: runtime segfault) | F-18 (spelling) | S6 | member spelling | #1 | the natural predicate copies the register hack | "a wrapped type whose underlying type is a pointer counts as the pointer member" | layout `Held` + guard |
| 3 | Global data emitter: a natural `bitcast(ptr, uint)` encoding reaches `_EmitInitializerRecursively` with no `ExprBitCast` arm (reproduced on the sketch: unhandled node assert) | F-77 | S3/S4 | value kind in global data | #4 | locals work, so the encoding looks done | "Globals ... can be initialized with member values including addresses of globals" | globals |
| 4 | Replacement identity: replacing the union by a shared type (`uint`, `^T`) rewires that type's `original_type`; later tags of unrelated unions carry the wrong typeid (issue #44 wall) | F-2 / F-75 family | S3 | type identity | #3 (encoding choice) | the one-word type "is" a pointer/uint | none needed (implementation choice) | ops/convert tags (unmeasured guess) |
| 5 | Several zero-size members: a null-only niche (Rust style) cannot hold `union(e1, e2, ^T)` | F-10 | S2 | multiplicity of zero members | #6 | Rust/Zig prior | "one or more zero-sized types" | ops (three errors), convert |
| 6 | Conversion matrix: compact <-> regular (tag recompute + payload), compact -> zero-only (tag only), compact <-> compact (re-encode if index-based) | F-10 | S2 | conversion direction x kind | #5 | each direction is a different emitter shape | "converting values in either direction between a compact union and any other union..." | convert |
| 7 | Twin parity: Python and C++ both, three targets | F-31 | S5 | implementation twin | all | the C++ ReplaceUnions has no TypeCorpus; orphan-node checker | "The Python and C++ front ends must behave the same way" | every cc case + output parity |

### 11b. Cross-product matrix
| | pointer member held | zero-size member held |
|---|---|---|
| local / param / result | ops, convert | ops, convert |
| record field / array element | layout, globals | layout, globals |
| global data initializer | globals (`ra`, table, links) | globals (`rl`, `rm`, table) |
| conversion to regular union | convert (Wide) | convert (Wide) |
| conversion to zero-only union | n/a (checked narrow traps) | convert (Errs) |
FINISH adds: wrapped pointer x global initializer, wrapped pointer x conversion, compact x
`union_delta` from trylet in a loop, compact field of a record passed by value through calls.

### 12. Tier + category
Olympus, feature-request ("Add ...").

### 13. Predicted per-agent result
Nova 0/8 (twin implementation + three hidden walls; address-constants Nova avg 995k sequence length on
the same reading surface). Orion ~1/4 (the walls are discoverable by running the repo's own tests and
flipping the flag; the emitter and wrapped-pointer cells decide).

### 14. Quality-gate checklist
- [x] Repo understanding 5/5
- [x] Existing PR check: 0 capability hits (commands above)
- [x] Closest approved opened (cwerg-fe-address-constants, harness reused)
- [x] Title verb-led
- [x] Canonical form stated
- [x] 0 codebase-inferable requirements beyond "every union operation keeps working"
- [x] File footprint measured (hook 317)
- [x] Traps on different axes, #1/#2/#3 interdependent through the layout/representation predicate
- [x] Cross-product matrix filled (FINISH extends)
- [x] Domain caps listed (L60): real-object pointers, union globals initialized, call results stored
      before union conversion (base regular unions assert otherwise), no 64-bit union members on a32
      (base a32 backend cannot copy them)
- [ ] Meta humanizer pass (FINISH)

## Phase 5 — Self-audit
- Hidden requirements: every runtime assertion is base behaviour of regular unions (verified by running
  the programs on base without the size asserts); the only new rule is the size.
- Tests pass on base: no — every program has a size `static_assert`; updated sizeof/linked_list fail on base.
- Over-constraint: no IR text pinned; encoding free (typeid, index, or null niche all allowed if correct).
- Too easy risk: Gate 1 value-vs-cost; Orion may clear all walls by flipping the flag and fixing what
  the repo's suite shows. Hardening levers for FINISH: wrapped-pointer x global/conversion cells,
  py/cc IR parity (repo assimilation convention, reference already IR-identical on the probes).

Why this is not a duplicate: cwerg-fe-address-constants changes `eval` / `canonicalize_span` /
`emit_ir` data emission for address constants; cwerg-bcopy-bzero-lowering is a backend opcode
lowering. This pick changes the union representation in `type_corpus` + `canonicalize_union` and
reuses the existing emitter unchanged.

Predicted iteration cycles: 3.
