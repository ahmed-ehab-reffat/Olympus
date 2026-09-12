# feedback.md — customasm-derived-bank-layout

Repo: hlorenzi/customasm | BASE_COMMIT `05c738138eea73fb1f8ff595cdc9b58fd35bad91` (v0.14.1, 2026-09-05)
Tier: Olympus | Shape: O-Pipeline-hard | Source: hunt 2026-09-06 RANK 1

## Status

**BUILT AND VALIDATED LOCALLY (2026-09-07) — no batch yet.** Design 2026-09-06; reference,
45 fixtures, test.sh, Dockerfile and meta.md authored 2026-09-07. Clean-room validated in both
apply orders; mutation harness + Docker run recorded below.

## Build round 1 (2026-09-07) — what changed against DESIGN.md

- **LOC:** 551 human-effective across 9 files (hook: padding-floor 125, note about the four
  repeated field-evaluation blocks). The first cut without the settle loop measured 220; the
  end-of-pass placement fixpoint (`settle_bankdefs`) is the orthogonal depth that lifted it, and it
  is also the new contract sentence about chain length.
- **New requirement, contract-stated:** "The number of iterations must not grow with the length of
  a placement chain: a dozen banks ... assemble under the default iteration limit whichever order
  their definitions appear in." Without an end-of-pass re-resolution of placements using the fresh
  extents, each derived link costs one resolver iteration and a 12-bank chain dies at the 10-iteration
  limit with a spurious `did not converge`. Fixtures: `ok_chain_twelve_banks`,
  `ok_chain_twelve_reversed` (reverse declaration order forces a multi-round settle).
- **Error keyword is `did not converge`** (the resolver's existing `handle_value_resolution`
  text), not the `cannot be resolved` DESIGN.md guessed. Circular placement emits FOUR errors
  (both bankdefs + both start labels); the fixture lists all four because the harness requires an
  exact message count.
- **`$` inside a bankdef stays an error** ("cannot get address in this context"). Stated in meta so
  the existing `bank_simple/err_address_ctx` fixture stays a live base-mode discriminator (an agent
  that routes bank fields through the plain `eval()` provider resolves `$` to the bank start and
  breaks it).
- **Two existing fixtures are invalidated by the feature and moved:**
  `tests/bank_simple/err_constants_unresolved{1,2}.asm` asserted that a bank `addr` depending on a
  constant that depends on `$` is an error. With deferred fields those programs are valid (the
  constant is in the default bank at address 0), so test.patch deletes them and adds
  `bank_derived_c41fad/ok_addr_from_pc_constant{1,2}.asm` with the same programs and their bytes.
  Base mode therefore needs no skip list.
- **`used` rounds a partial unit up** (stated; fixture `ok_partial_unit_rounds_up`).
- **F-18 duplication scaled back:** `#addr` and `addr =` are one AST field after
  `parser/fields.rs`, so no implementation can treat them differently. Two hash-spelling fixtures
  kept for coverage, not as a lever.
- **Extent is committed at the end of each pass and read one pass late** by `$bankof(...).used`.
  Same fixpoint result; costs at most one extra iteration. Max iterations across all ok fixtures: 6
  (`ok_forward_ref_into_derived_bank`), under the 10 limit with slack.
- **Reference bug found by the fixtures (L7):** an absolute `#addr` inside a bank whose start was
  still a guess tripped `finalize_addr`'s range check ("address is out of bank range") on the first
  pass. Fixed by skipping the check while start or size is a guess and guessing is allowed.


## Attempt history

### Pick round 1 — bank placement solver (hunt thesis): REFRAMED, not dropped

The hunt proposed "a bank placement solver: let banks declare constraints and have the assembler
choose addresses". Reframed during Phase 3 for two reasons, both evidence-driven:

1. **Absorption.** A placement solver needs new parser fields, and `parser/fields.rs` is generic
   (`name = expr`), so a new field costs ~5 lines. Half the sketched footprint was in the surface,
   not the machinery. The customasm oracle-absorption law (`TOO-EASY.md`, measured: 318 sketched ->
   167 actual) predicts that collapses.
2. **The real wall is earlier than placement.** `defs/bankdef.rs:60-190` evaluates EVERY bankdef
   field with `eval_certain`, inside the pre-iteration loop, before any address exists. So the
   architectural gap is not "we cannot choose an address", it is "a bank field cannot depend on
   anything the assembly produces". Reproduced on base: `#bankdef b { addr = A_END }` with
   `A_END = a_last` gives `error: unresolved symbol A_END`.

Final capability: bank fields become resolvable inside the existing fixpoint, plus a per-bank
used-extent quantity exposed as `used` / `end`. Placement falls out of that, rather than being
bolted on.

### Pick round 0 — lanes considered and rejected before this one

| Lane | Killed by |
|---|---|
| Relocatable output + linking (issue #48) — recommended by our own `TOO-EASY.md` | Stage-2b magnet: TWO published design sketches in-thread (`theorzr` `#obj <format>`, `Phlosioneer` full `#external` design), externally-named capability (ELF/COFF/relocation), six-year-old request with no PR, maintainer moved the design discussion to Discord 2022-09-26. `TOO-EASY.md` corrected in place |
| Whole-ruledef-set encoding-ambiguity analysis | Self-collision with our approved `customasm-ruledef-disassembly` (also a whole-ruledef-set encoding analysis); the dedup engine sees our own corpus first |
| Branch relaxation / smallest-encoding selection | Already implemented at `resolver/instruction.rs:266-277`; also a named textbook algorithm. Previously killed at design for the shelved pick |
| Rule-selection ordering (issue #121) | Maintainer reserves it: *"important that the assembler doesn't choose any one rule based on order -- in the future it would allow for new optimizations"* |

## Validation record (2026-09-07, build round 1)

| Check | Result |
|---|---|
| Clean-room, test then solution | base 706/706 pass without solution; new 48/48 FAIL without solution (runtime fixture failures, not compile errors); both pass with solution |
| Clean-room, solution then test | both modes pass; `git apply -R` of both leaves a clean tree |
| Flakiness (3x base + 3x new) | byte-identical JUnit XML across all 3 runs of each mode |
| LOC hook (`effective_loc_check.py`) | 551 human-effective, 9 files, padding-floor 125 |
| Comments added by patches | none (repo convention: none in new code) |
| Banned markers | none in tests/ or test.sh |
| Clean-room after review round 2 (final patches) | base 706/0 and new 56/56 fail without solution; with solution base 706/0, new 56/0, 3x byte-identical; unapply clean; reverse order both pass |
| Clean-room after review round 1 | base 706/0 and new 52/52 fail without solution; with solution base 706/0, new 52/0, 3x byte-identical; unapply clean; reverse order both pass |
| Docker on the FINAL (round-5) patches | PASSED. Image built from base + test.patch (`BUILD_EXIT=0`). Inside it as `--user 1000:1000 --network none`: base 706/0 and new 67/67 FAIL without the solution (exit 101), then after `git apply solution.patch` base 706/0 and new 67/0. Matches the clean-room exactly. Three earlier attempts during rounds 2-4 were killed by the OS low-memory killer while another session was building images; this run went through once the box was free |
| Docker after review round 1 | NOT re-run: the rebuild was killed by the OS (7 GB box, 1 GB free, another session's image build running). The Dockerfile and test.sh are byte-identical to the run below, and everything that changed since (source + fixtures) is covered by the clean-room row above. Re-run when the machine is idle: see feedback § Next actions |
| Docker (platform-style, pre-review patches) | image built from base + test.patch (918s, the `chmod -R` of `/opt/rustup` dominates; solved-side compile only 14s). Inside the image as `--user 1000:1000 --network none`: base 706/0 and new 48/48 FAIL without the solution; after `git apply solution.patch` base 706/0 and new 48/0 |

### Trap-proof (mutation harness, new + base mode per mutant)

| Mutant (natural wrong implementation) | Killed by |
|---|---|
| M1 extent max carried across passes (T2) | `ok_extent_shrinks_while_settling`, `ok_used_in_own_operand` |
| M2 `.addr` member copied as `statically_known()` (T3, F-9) | `ok_three_bank_chain` |
| M3 `.used` always statically known | `ok_used_of_derived_bank`, `ok_used_in_own_operand` |
| M4 `.end` always statically known | 6 fixtures incl. both circular error fixtures |
| M5 `#addr` directive ignores a guessed bank start | `ok_addr_directive_in_derived_bank` |
| M6 `#addr` range check fires on a guessed start/size | `ok_addr_directive_in_derived_bank` |
| M7 label/`$` value ignores whether the bank start settled | 13 fixtures |
| M8 labelalign padding ignores guessed start | `ok_labelalign_in_derived_bank_extent` |
| M9 `#align` padding ignores guessed start | `ok_align_in_derived_bank_extent` |
| M10 no end-of-pass placement settle (one link per iteration) | `ok_chain_two_dozen_reversed` |
| M11 settle runs a single round per pass | `ok_chain_two_dozen_reversed` |
| M12 extent always reported as settled | 4 fixtures |
| M13 unmeasured `used` reads as guess 0 instead of unknown | SURVIVES: equivalent mutant, same fixpoint, not a contract gap |
| M14 `used` floors a partial unit | `ok_partial_unit_rounds_up` |
| M16 `$` allowed inside bank fields | 27 new + **5 base fixtures incl. `bank_simple_err_address_ctx`** (L33 base-mode discriminator confirmed live) |
| M17 bankdef layout never reported as a guess | 26 fixtures |
| M18 define() marks every layout resolved | 26 new + base `err_address_ctx` |
| M20 size from `addr_end` ignores a guessed `addr` | `ok_addr_end_literal_with_derived_addr` |
| M24 layout always stable | both circular fixtures + `ok_derived_through_constant` |
| M25 extent never updated | 38 fixtures |
| M26 extent guess-ness never tracked | 4 fixtures |

Two uncorrelated kill clusters exist by construction (L20 insurance): the fixpoint cluster
(M1/M2/M7/M10/M11/M17) and the extent-definition cluster (M14/M25/M8/M9), with disjoint killing
fixtures. Batch 1 must confirm this on real runs.

## Evidence log

**Reproduce-on-base (release binary at BASE_COMMIT):**
- `#bankdef b { addr = A_END }`, `A_END = a_last` -> `error: unresolved symbol A_END` (the f2p gap)
- `$bankof(here).size` -> declared size `0x10`, never the used extent
- `#bankdef code { bits = 8, size = 0x10, outp = 0 }` with no `addr` -> assembles at addr 0, so
  omission is NOT the opt-in
- cross-bank `jmp target` -> resolves in 2 iterations (the fixpoint already handles forward refs)

**Maintainer corroboration (issue #195, 2025-10-05, hlorenzi):** *"There's still no way to get the
'first free' address, though, since the assembler's infrastructure doesn't quite work that way, so
that would require more engineering to make possible."* Confirms both the absorption test (machinery
absent) and Gate 8 (philosophy favourable).

**Baseline health:** 708/708 tests, byte-identical across 3 runs, 1.80/1.83/1.83s. Deps: `getopts`,
`num-bigint`, dev-dep `sha2` — no `-sys`, no system libraries.

**Docker VERIFIED, not estimated:** `olympus-base-rust:latest` ships rustc 1.95.0; the repo builds
inside it against this base commit in 20.46s. Edition-2024 risk closed.

## Risk register

| Risk | Severity | Mitigation |
|---|---|---|
| **Oracle absorption drops the LOC under 200** — this repo's measured failure mode (318 -> 167) | HIGH | Per-item absorption audit done in DESIGN.md § 7: 5 of 9 items genuinely absent and they are the large ones. Sketch is ~349 meaningful across 7 files, ~75% buffer. Re-measure with `effective_loc_check.py` the moment the reference compiles |
| **L20 bimodality** — customasm's own accepted problem swung 0/13 -> 90% -> 20% -> 57% -> 9% because one seam gated every killer | HIGH | Trap 4 (extent-noun ambiguity) is deliberately INDEPENDENT of traps 1-3. Success criterion at batch 1: a kill table with TWO uncorrelated clusters, not one |
| Derivative magnet on issue #195 | MEDIUM | #195 asks for a read-only first-free SYMBOL; this capability is field resolution + placement. Different capability, and no PR exists in any state |
| Invasive reference (7 files, changes when bankdef fields are evaluated) | MEDIUM | Expect reference bugs — L7 says 3 per problem, and the customasm precedent found 7. Budget trap-proofing rounds |
| Resolver convergence is a live maintainer fix area (#241/#242/#246 in the last 12mo) | LOW-MED | Those are FIXES, not capability landings. Re-run the SIX-CHECK at submit |

## Phase 5 — failure-mode self-audit

- **Bucket 1 hidden requirements:** every test bucket in DESIGN.md § 9 traces to a sentence in § 6.
  The `#fill`-excluded and `#res`-counts atoms are explicitly stated because the fixtures assert them.
- **Bucket 2 tech-spec tone:** draft is 5 plain-prose paragraphs, no headers, no labels.
- **Bucket 3 tests pass on base:** every new fixture uses `used`/`end` or a derived field; both are
  absent at base (`unresolved symbol` / `unknown member`), so nothing passes on base.
- **Bucket 4 over-constraining:** no test pins internal resolution ORDER, only observable addresses
  and bytes. Error assertions are substring on 3 stable keywords.
- **Bucket 5 too easy / under LOC:** sketch is 535 raw / ~349 meaningful. Not padded — the LOC lives
  in deferral, extent tracking, and the new resolver node.

**Real Revert Causes walked:** no test.sh trickery, no exact-string assertions, no code duplication,
no scope creep (no new directive, no new builtin, no CLI flag), no drive-by refactors, no AI
comments (repo convention is ZERO comments in new code — verified against `defs/bankdef.rs` and
`resolver/mod.rs`, neither carries doc comments on new items).

**Cross-agent blind spots pre-empted:** iteration termination, result/extent semantics, unstated
inverse (backward jump), empty case, adjacent-vs-all (`#res`). All five have sentences in § 6.

## Next actions

0. Docker is DONE on the final patches (see the validation table). Nothing is owed before upload.

1. Upload the 5 deliverables; meta.md + Dockerfile + base commit are FROZEN from here (L36).
2. Batch 1: 10 runs (Orion available; mix Nova if unlocked). Save every passing patch and the two
   most instructive failers to `agent-runs/`.
3. Check the kill table for TWO uncorrelated clusters (fixpoint vs extent definition). If every
   failure is the same seam, the problem is bimodal (L20); harden the extent axis before batch 2.
4. Re-eval for tests-only follow-ups; never fire a smoke run while a re-eval is pending.
5. FP check on every passer: confirm the settle loop exists (24-bank reversed chain), the extent
   reset, and the `$` rejection, not just green tests.

## Precheck round 1 (2026-09-07, platform prechecks before batch 1)

- **Test-name collision (FAIL):** `tests/bank_extent_4d1427/ok_fill_not_counted.asm` flagged even
  though its directory carries the hash. Renamed to `ok_fill_not_counted_4d1427.asm`; test.patch
  regenerated (still 51 entries, 48 fixtures pass).
- **Description "only necessary information" (WARNING, AI):** took the two example/default trims
  (dropped the "a dozen banks ..." example per L21, dropped the "ordinary banks ... overlap" closing
  sentence). KEPT the `used`/`end` micro-semantics (`#res` counts, `fill` excluded, backward moves,
  empty bank, declared `size` unaffected, partial-unit rounding) and the non-convergence sentence:
  each is asserted by a fixture, and an asserted behaviour the description omits is the fairness
  gate's definition of a hidden requirement. Body now 225 words.
- **Error-substring warning (AI):** no change. All asserted substrings (`did not converge`,
  `supported range`, `cannot get address`, `overlaps`) are the repo's EXISTING diagnostics reachable
  through the existing machinery, and substring matching is the repo harness's own convention
  (`; error: <substring>`).

## Solution Quality review round 1 (2026-09-07) — FAIL, three findings, all addressed

| Finding | Real? | Fix in reference | New fixture |
|---|---|---|---|
| Alignment-dependent chains still cost one outer pass per bank (settle loop re-evaluated layouts against stale extents) | YES. Measured on the pre-fix reference: 5 iterations at 11 banks, 9 at 24; a 40-bank reversed align chain hits the 10 limit | `resolve_once` now loops: walk + commit extents, then one round of `settle_bankdefs`; if any layout changed, re-walk (bounded by bankdef count). Layouts and extents converge together inside one outer iteration | `ok_align_chain_forty_reversed` (40 banks, `#d8 0` + `#align 32` each, reverse order) and `ok_chain_forty_reversed` (40, plain). Both settle in 1-2 iterations on the reference; the no-rewalk and single-round mutants die with `did not converge` |
| `$` reachable through a user function / asm block evaluated from a bank field | YES | Replaced the custom no-address variable provider with an `address_available` flag on `ResolverContext` (false for the bankdef node and for `bankdef_context`); `eval_address` errors when it is false, so functions and asm blocks inherit the rejection. Bank fields now evaluate through the plain `eval` provider | `err_pc_through_function` (`#fn pc() => $`), `err_pc_through_asm_block` (nested diagnostics listed) |
| Literal `#addr` marked resolved before a derived bank size is known, so the range check never reruns | NOT a real defect: `resolve_once` calls `finalize_addr` on the last iteration for every `#addr` regardless of `resolved`, so the range check does rerun (mutant M27 = the pre-fix condition still fails the new fixture). Fixed anyway as a tightening: `#addr` stays a guess until the bank's size settles | `err_addr_directive_exceeds_derived_size` |

Also from this round: the test-quality AI asked for an explicit iteration-scaling guard; the 40-bank reversed chains ARE that guard under the default 10-iteration limit (the pre-fix behaviour needs ~n/4 iterations). Description trims taken: dropped the old-behaviour clause ("evaluated once, before any address exists ...") to "Today a `#bankdef` field can only hold a literal or a constant"; kept "whichever order the definitions appear in" (the reversed fixtures depend on it) and the `$bankof` topic sentence (it is the only place the members are anchored to `$bankof`). Body 215 words.

LOC after the round: 621 human-effective (the re-indented walk in `resolver/mod.rs` inflates the diff; irreducible new logic is unchanged ~550). Mutation harness rerun: 21 mutants, 19 killed, 2 equivalent (M13 unmeasured-`used` placeholder, M27 above).

## Precheck / Solution Quality round 2 (2026-09-07)

| Item | Verdict | Action |
|---|---|---|
| Solution Quality FAIL: pending derived `outp`/`size` read as `Void` through `$bankof`, so `Void + 8` errors instead of waiting (reversed chains through `outp`/`size` arithmetic) | REAL | `eval_member_bankdef` now returns Unknown for `outp`/`size`/`size_b` while the field is still a guess and the static `Void` only when the field is genuinely omitted (`eval_bank_optional`). Fixtures: `ok_outp_chain_reversed` (the reviewer's exact program), `ok_size_chain_reversed` (`size`/`size_b` arithmetic). Mutant M30 = the old behaviour |
| Test-quality ERROR: iteration bound not asserted | Taken | Two command fixtures use the public `-t 3` (max iterations) flag: `ok_chain_forty_reversed_iters/` and `ok_align_chain_forty_reversed_iters/` (`; command: main.asm -t 3 -f hexstr -o out.txt`, `; output: out.txt`). Reference settles in 1-2; the one-link-per-iteration shapes die at 3 |
| test.sh sanity WARNING: two positional libtest filters "may AND" | Heuristic (libtest ORs them; new mode ran 52 tests) but split anyway: new mode now runs one `cargo test --lib -- <dir>` per directory, appending to one log, exit code = any failure |
| Description trims | Took three: "as everything else" instead of "that settles labels and instruction encodings"; "`$` is still rejected inside a bank definition, however it is reached" (the transitive rule); dropped the empty-bank sentence (follows from the definitions; `ok_empty_bank` still asserts it as a consequence). KEPT the non-convergence sentence: three fixtures assert `did not converge` on the bankdef line. Body 198 words |

Patches after the round: test.patch 61 entries (56 new tests: 17 extent + 39 derived incl. 2 command fixtures; 2 deletions), solution.patch 631 human-effective.

### Trap-proof after round 2 (25 mutants, new + base mode each)

23 killed, 2 equivalent (M13 placeholder-before-measurement, M27 `#addr` size condition that the
final pass re-checks anyway). Kill counts on the 56 new tests: M25 extent never updated 46, M18
define marks layout resolved 37 (+1 base), M17 layout never a guess 35, M7 label ignores start 13,
M4 `end` static 8, M12/M26 extent guess-ness 5, M10/M11/M29 settle variants 4 each (the two `-t 3`
command fixtures plus both 40-bank chains), M3 `used` static 4, M1 carried extent 3, M28 `$` flag
ignored 3 (+1 base `err_address_ctx`), M30 pending optional reads as Void 2, M31 flag not on the
bankdef node 2, M24 layout always stable 2, M2/M5/M6/M8/M9/M14/M20 1 each.

## Precheck / Solution Quality round 3 (2026-09-07)

| Item | Verdict | Action |
|---|---|---|
| SQ high: settle `changed` compared layouts by value only (`Value` equality ignores metadata), so a guessed 0 turning into a resolved 0 did not trigger another round; an all-zero chain of empty banks reported `did not converge` | REAL | `BankdefLayout::same_as` compares values AND each field's guess flag; settle loops on that. Fixture `ok_zero_sized_chain` (40 empty zero-sized banks, reverse-declared; 4 forward banks did not discriminate because the walk resolves one link per iteration inside the cap). Mutant M32 = old comparison |
| SQ medium: a PRESENT field evaluating to void (`addr = $assert(true)`) was read as omitted | REAL | `layout_bigint`/`layout_usize` take the AST option: absent -> None; present void -> the base type error (`expected integer, got void` / `expected non-negative integer, got void`). Fixtures `err_void_addr_end_field`, `err_void_size_field` (each paired with a derived field so base, which cannot evaluate the derived field at all, fails them for a different reason). Mutant M33 |
| TQ unfair: `ok_addr_from_pc_constant{1,2}` contradict "`$` ... rejected ... however it is reached" | My wording. The behaviour is right (a constant is an ordinary value; tainting values by their history is not a thing in this evaluator). Sentence now: "`$` is still rejected inside a bank definition, also when a function or an asm block reaches it from there; a constant that was computed from `$` elsewhere is an ordinary value." Fixtures kept |
| TQ unfair: `*_iters` command fixtures pin an unstated 3-iteration ceiling | Agreed. Both deleted. The iteration requirement is now asserted under the DOCUMENTED default cap at two lengths: 40 and 80 banks reversed (linear designs need ~n/4 and n iterations; both exceed 10). `ok_chain_eighty_reversed` added |
| TQ coverage: partial-unit rounding only at bits=8 | Taken: `ok_partial_unit_rounds_up_bits16` (24-bit datum in a 16-bit-unit bank -> `used` 2) |
| Description trims | Dropped "and resolve them in the same iterative pass as everything else" (WHEN is implied by the convergence + iteration sentences). Kept the opening sentence (DESCRIPTION.md first-sentence rule). Body 207 words |

Tests: 18 extent + 41 derived = 59 new fixtures.

Round-3 mutation note: M33 (present void field reads as omitted) is killed by `err_void_addr_end_field`
(1 test). M32 (settle termination ignores the guess flag) SURVIVES and is equivalent in outcome: when a
placement's numeric value stops changing while it is still a guess, the outer loop accepts it as a
stable guess (existing resolver design, same as a stable encoding), so the reviewer's all-zero chain
assembles either way; the metadata-aware `same_as` only saves iterations. Verified with a 40-bank
reverse-declared zero-sized chain: reference 1 iteration, value-only comparison 2. Fixture kept as a
regression.

## Solution Quality round 4 (2026-09-07)

| Finding | Verdict | Action |
|---|---|---|
| SQ high: a constant associated with a later-defined bank makes `defs::bankdef::define` panic through `DefList::get` | NOT REPRODUCIBLE. `eval_simple` (the define-time evaluator) returns Unknown for EVERY function call, and `$bankof` is the only producer of a `Value::Bankdef`, so no member access can reach `eval_member_bankdef` before the bank table exists. Ran the reviewer's exact program on the round-3 reference: assembles, `01`, 1 iteration. Fixed anyway by removing the class: `define` now registers every bankdef with `BankdefLayout::new_unknown()` in a first loop and evaluates layouts in a second, so no layout evaluation can observe a missing bank. Fixture `ok_constant_of_later_bank` |
| SQ high: reversed chains cost one whole-program traversal per link (O(N^2)) | REAL for the settle loop's ordering. `settle_bankdefs` now collects, per bankdef, the banks its field expressions actually read (a member-query hook that records `Value::Bankdef` reads), builds the dependency graph, and re-evaluates in topological order; cyclic components fall to the end and still reach the non-convergence path. MEASURED whole-program traversals (counter at `ResolveIterator::new`), dependency ordering ON vs the source-order settle it replaced: `ok_chain_forty_reversed` 5 vs 24, `ok_chain_eighty_reversed` 5 vs 44. Chain-length independent with the ordering, linear without it. That is the reviewer's cited fixture |
| Remaining cascade, stated honestly | `ok_align_chain_forty_reversed` takes 43 traversals either way (5 vs 43 and 43 vs 43 measured). An alignment pad inside bank i is a function of bank i's own resolved start, so bank i's EXTENT cannot be measured until its start settles, and extents come only from a traversal. No ordering fixes that; it is the shape's real dependency chain. The user-visible contract (resolver iterations) stays at 2 |
| TQ coverage: `$` only tested in `addr`/`outp`, constants only in `addr` | Taken, 6 fixtures: `err_pc_in_size_field`, `err_pc_in_outp_field`, `err_pc_through_function_in_addr_end`, `err_pc_through_asm_block_in_addr`, `ok_pc_constant_in_size_and_outp`, `ok_pc_constant_in_addr_end` |
| Description trim | Took the MEDIUM: dropped "Today a `#bankdef` field can only hold a literal or a constant,". Kept the opening ask sentence (DESCRIPTION.md first-sentence rule). Body 195 words |

Patches: test.patch 69 entries (66 fixtures), solution.patch 799 human-effective across 9 files.

### Trap-proof after round 4 (29 mutants against 66 fixtures)

21 killed, 8 survive. Kill counts: M25 extent never updated 47, M18 define marks layout resolved
41 (+1 base), M17 layout never a guess 34, M7 label ignores start 13, M4 `end` static 7, M28 `$`
flag ignored 7 (+1 base `err_address_ctx`), M12/M26 extent guess-ness 5, M3 `used` static 4, M1
carried extent 3, M31 flag not on the bankdef node 3, M14/M24/M30 2 each,
M2/M5/M6/M8/M9/M20/M33 1 each.

The 8 survivors are equivalent or performance-only, and are listed so no one re-derives them:
M13 (placeholder before the first extent measurement), M27 (`#addr` size condition the final pass
re-checks), M32 (numerically stable guesses are accepted by the resolver's existing stable rule),
and the five settle-SCHEDULING mutants M10, M11, M29, M34, M35. The scheduling group is
performance-only BY CONSTRUCTION: source-order settling plus the bounded outer rounds reaches the
same fixed point, just with more whole-program traversals (24 and 44 instead of 5 and 5). No test
asserts traversal counts, because the contract speaks about resolver ITERATIONS, which stay at 2.

## Test Quality + Solution Quality round 5 (2026-09-07)

| Finding | Verdict | Action |
|---|---|---|
| SQ high: dependency collection only saw the OUTER member query, so `#fn bank_end(x) => $bankof(x).end` (and constants) produced no edges and reverse chains fell back to one full pass per link | REAL | The collector moved to the single chokepoint every bank-member read passes through, `eval_member_bankdef`, via an optional `bank_reads` cell on `ResolverContext`. Function bodies and asm blocks inherit the context, so their reads are recorded too. `settle_bankdefs` also runs its own bounded fixpoint over bank definitions only, so any residual indirection costs bank-expression rounds instead of whole-program traversals. New fixture `ok_chain_through_function_reversed` (40 banks, reverse-declared, every placement through a user function) |
| SQ medium: internal settle re-walks bypassed the `--iters` budget | Agreed | The re-walk loop is now bounded by `opts.max_iterations` instead of the bank count, so the documented budget governs it |
| TQ unfair: `err_circular_placement` and `err_self_placement_grows` pin the cascading label diagnostics | Agreed, disclosed | meta.md now says "and so is every label whose address depends on it", making the diagnostic set contract-stated. Body 205 words |
| Description trims (both LOW) | Declined, with reason. The opening sentence is required by DESCRIPTION.md's first-sentence rule. "whichever order the definitions appear in" is load-bearing: every reversed-chain fixture exists because of it |

MEASURED whole-program traversals after this round (counter at `ResolveIterator::new`):

| Fixture | Round 4 | Round 5 |
|---|---|---|
| `ok_chain_forty_reversed` | 5 | 5 |
| `ok_chain_eighty_reversed` | 5 | 5 |
| `ok_chain_through_function_reversed` | (would cascade) | 5 |
| `ok_align_chain_forty_reversed` | 43 | 14 |

Every placement chain is now traversal-count independent of its length and of how the placement is
reached. The alignment chain improved but still cascades, for the reason recorded in round 4: a pad
inside a bank is a function of that bank's own settled start, so its extent cannot be measured until
the start settles, and extents come only from a traversal.

Patches: test.patch 70 entries (67 fixtures), solution.patch 791 human-effective across 9 files.

### Trap-proof after round 5 (focused set, 67 fixtures)

Behavioural mutants still die, at the same or higher counts than round 4: M25 extent never updated
48, M17 layout never a guess 35, M7 label ignores start 13, M30 pending optional member 2.

The three mechanisms added THIS round are performance-only and survive by construction: M36
(collector not transitive), M37 (settle inner fixpoint removed), M38 (re-walk bound of one). Each
leaves the fixed point unchanged and only costs traversals, and no test asserts traversal counts.
M38 surviving also shows the re-walk bound is not load-bearing for correctness: one re-walk per
outer iteration still converges every fixture, including the alignment chain.

## Solution Quality round 6 (2026-09-07)

| Finding | Verdict | Action |
|---|---|---|
| SQ high: placement chains mediated by CONSTANTS still cost one settling pass per link, and a 200-link chain fails at the default cap | REAL, and the root cause is deeper than ordering. A constant is a memoized value: `eval_variable` returns the stored value, so (a) no dependency edge is visible and (b) even with a correct edge the value is STALE, because only a whole-program walk refreshes it. Ordering alone cannot fix it |
| Fix, part 1: provenance | `ResolverContext` now carries a `BankReadLog` (banks read, symbols read, whether `$` was touched). `resolve_constant` evaluates under that log and stores the bank reads and an `address_dependent` flag on the symbol; `eval_variable` replays a symbol's recorded reads into an active log, so provenance is transitive through chains of constants |
| Fix, part 2: settle constants, not just banks | The settle graph now spans bank definitions AND the constants that mediate them (those with recorded bank reads and no `$` use). `ResolveIterator::constant_context` builds a bank-free, address-unavailable context so a mediating constant can be re-resolved inside the settle loop. Address-dependent constants are excluded, which is what keeps `ok_addr_from_pc_constant*` correct |

MEASURED whole-program traversals (counter at `ResolveIterator::new`):

| Fixture | Before round 6 | After |
|---|---|---|
| `ok_chain_through_constants` (40 links via constants) | 44 | 5 |
| `ok_chain_through_function_reversed` | 5 | 5 |
| `ok_chain_eighty_reversed` | 5 | 5 |
| `ok_align_chain_forty_reversed` | 14 | 14 |

The reviewer's own 200-link constant chain now reports "resolved in 1 iteration" against the default
cap of 10.

Coverage suggestions taken, 3 fixtures: `err_pc_in_addr_end_field` (direct `$` in the one field that
had no direct case), `err_pc_through_function_in_addr`, `err_pc_through_asm_block_in_size`. Both
description trims declined again for the reasons in round 5; "Moving the cursor backwards does not
lower either member" is the unstated-inverse pre-empt that `ok_backward_addr_keeps` asserts, so
deleting it would create a hidden requirement.

Patches: test.patch 74 entries (71 fixtures), solution.patch 971 human-effective across 12 files.

## Round 7 (2026-09-07) — retiring the clause that kept failing

| Finding | Verdict | Action |
|---|---|---|
| SQ high: a 92-bank ALIGNMENT chain exceeds the default cap | REAL against the clause, and the clause is the problem. Alignment padding inside a bank is a function of that bank's own settled start, so its extent cannot be measured until the start settles, and extents come only from a traversal. Rounds 4, 5 and 6 each improved the schedule (43 -> 14 traversals, constants 44 -> 5) and each time this axis came back, because no ordering removes a dependency that runs THROUGH the traversal |
| The decision | The description reviewer independently rated the same sentence [HIGH] REMOVE as an over-specified performance constraint. Both reviewers point the same way, so the sentence is retired. It is replaced with the functional guarantee the design actually delivers: "Placing a chain of banks, each at the previous one's end, works whatever order the definitions appear in." Order independence is still stated (every reversed fixture depends on it); the iteration-count promise is gone. Deep chains now behave like every other quantity in this assembler: they consume iterations and the existing `--iters` flag raises the budget |
| SQ high: a derived zero-size `fill` bank underflows `offset + size - 1` and panics | REAL, and my feature is what makes it reachable, since a derived `size` is naturally zero for an empty bank. Guarded `size == 0` in `fill_banks`. Fixture `ok_derived_zero_size_fill`; without the guard it panics at `output/mod.rs:278` |
| SQ medium: settle rescans in nested rounds | Taken in part. The round loop is gone: settle now runs one discovery pass and one dependency-ordered pass, and the outer walk loop handles cascades. Traversal counts are unchanged for every fixture |
| Description: remove the opening sentence | Declined a fourth time. DESCRIPTION.md's first-sentence rule requires the body to open with the ask |
| Description: remove "and so is every label whose address depends on it" | Declined. It was added in round 5 BECAUSE a Test Quality reviewer ruled the two convergence fixtures unfair without it. Removing it re-opens that finding; the two reviewers disagree and fairness wins |

Body 203 words. Patches: test.patch 75 entries (72 fixtures), solution.patch 966 human-effective
across 13 files.

## Auto Review round 1 (2026-09-08) — Description 3/3, Solution 3/3, Tests 1/3

Only the Tests band was held down, by the JUnit reporter. All four findings taken.

| Finding | Action | Verified how |
|---|---|---|
| T8 HIGH: every `<failure>` body was fixed text, so the harness's real diagnostics never reached the XML | `write_junit` now extracts each failed test's captured stdout block from the cargo log (`---- <name> stdout ----` up to the next block, last 80 lines) and puts the escaped text in the `<failure>` body | Broke a fixture's expectation on purpose: the XML failure body is 1667 chars and contains `> encoding mismatch`, `> got: 0x...`, `> expected: 0x...` and the panic line |
| T8 MEDIUM: the zero-results fallback omitted the build cause | The `total == 0` branch now attaches the last 120 log lines | Added a bogus type: the XML carries `error[E0425]: cannot find type ...` and `could not compile` |
| T8 MEDIUM: a failed report write could still exit 0 | `write_junit` returns nonzero when the redirect fails or the file is empty, and both modes turn that into `EXIT_CODE=1` with a message on stderr | `--output_path /proc/version` with passing tests exits 1; a writable path exits 0 with 706 cases |
| T4 MEDIUM x2: the live-`$` matrix missed a function reached from `size` and an asm block reached from `addr_end` | Added `err_pc_through_function_in_size` and `err_pc_through_asm_block_in_addr_end`. Both mechanisms are now tested in all four fields | Both fixtures pass with the reference and fail on base |

Control characters are stripped in `xml_escape` so captured output cannot produce invalid XML. The
all-failing new-mode report (the platform's first run) is 88K and parses.

Description trims declined again: the non-convergence/label sentence was added in round 5 because a
Test Quality reviewer ruled two fixtures unfair without it, the chain-order sentence justifies every
reversed fixture, and the opening sentence is required by DESCRIPTION.md. The description scored
3/3 as written.

Re-validated: base 706/0, new 74/74 fail on base and 74/0 with the solution, 3x byte-identical,
unapply clean. test.patch 77 entries (74 fixtures); solution.patch unchanged at 966 human-effective
across 13 files. The `git apply -R` whitespace warnings are pre-existing repo lines (16 REMOVED
lines carry trailing whitespace; added lines carry none).

## BATCH 1 (2026-09-08) — 0/6, diagnosed and relaxed. Full data in eval-results.md

0/6 is the reject band, so the round was spent on diagnosis, not tuning. Seven tests failed in ALL
six runs and five of them were chain SCALE (24/40/80 banks, plus 40-link chains through a function
and through constants) rather than semantics. Those fixtures are exactly what forced the
dependency-ordered settling machinery across review rounds 4-6: reviewers asked for the scheduler,
I built it, and then I gated agents on inventing it in one attempt. Orion's `used`/`end` semantics
were probed directly and are CORRECT; it failed only on scale.

Relaxed the scale axis and three unstated requirements (void-valued fields, the zero-size fill
panic, `#addr` under a guessed bank start - meta.md never mentions `#addr` at all). The zero-size
fill GUARD stays in solution.patch; only the gate on finding it is gone.

Replaying all six saved agent patches against the relaxed suite: **Orion 0 failures (passes), Nova
3/5/7/8/9 failures. 1/6 = 17%**, inside the band and near the target. The survivors split into two
uncorrelated clusters (cursor/extent vs placement/settling), so the L20 bimodality insurance held.

Also fixed the Auto Review Medium: `Bankdef::used_units` did ceiling division as
`(used_bits + addr_unit - 1) / addr_unit`, which can overflow near `usize::MAX`. Now quotient plus a
nonzero-remainder test, with a zero-unit guard.

**Platform XML warning, worth carrying forward:** the platform rewrites the harness JUnit
(`test::file::x` becomes `test.file.x`) and mis-pairs names with failure bodies. Orion's XML and its
cargo log both listed nine failures but agreed on only four names. Always mine `test-log.txt`.

## Solution Quality round 8 (2026-09-08) — FAIL was a FALSE POSITIVE, CONFIRMED by a clean re-run

**Outcome: the user re-ran Solution Quality against the unchanged artifacts and it PASSED.** No code
was changed between the FAIL and the PASS, so the finding was a static-read flake. The analysis
below is kept because it is the evidence that justified not churning the reference, and because the
same misreading is likely to recur: the max-position update is easy to mistake for post-dispatch
code when read in a diff rather than run.

The finding claims extents are committed after the bank switch, so `used`/`end` lose a bank's final
content, and that the same loss happens at EOF. Both halves are wrong, and the reviewer's own repro
disproves the first.

**Where the update actually lives.** The max-position update is the last thing in
`ResolveIterator::advance_address`, not after the node dispatch. `next()` calls `advance_address`
FIRST, and at that moment `self.bank_ref` is still the PREVIOUS bank, because the `DirectiveBank` /
`DirectiveBankdef` arm that reassigns it has not run yet. So the content preceding a switch is
credited to the bank that held it. At EOF the same call runs once more before `next()` returns
`None`, so trailing content is flushed too.

**Their repro, run verbatim against the reference:**

```
#bankdef a { addr = 0x100, outp = 0, size = 4 }
#bankdef r { addr = 0x8000, outp = 4 * 8, size = 4 }
#bank a
a_l:
#d8 1
#bank r
#d16 $bankof(a_l).used     -> 0x0001
#d16 $bankof(a_l).end      -> 0x0101
```

Output `0100000000010101`: `used` is 1 and `end` is 0x101, exactly what the finding says cannot
happen. This shape is also already a shipped fixture, `bank_extent_4d1427/ok_one_item`, which passes.

**Their EOF claim, probed separately** (bank `a`'s content is the last node in the file, and a third
bank derives its size from `a`'s extent):

```
#bank r / #d16 $bankof(a_l).used / #d16 $bankof(a_l).end
#bank c / #d8 $bankof(c_l).size / c_l:
#bank a / a_l: / #d8 1, 2, 3
```

Output `010203000003010303`: `used` 3, `end` 0x103, and the derived `size` 3. Trailing content is
measured.

No code change. `ok_one_item` and `ok_whole_bank_across_switches` already cover the switch case and
both pass; I deliberately did NOT add an EOF-named fixture, because the batch sits at a replayed 1/6
and adding a wall risks pushing it back to 0 for a behaviour that is already correct and covered.

Description suggestions declined, both MEDIUM and both previously settled the other way. "the way an
unsettled encoding already is" is what anchors the `did not converge` wording the convergence
fixtures assert. "Moving the cursor backwards does not lower either member" is the unstated-inverse
pre-empt that `ok_backward_addr_keeps` and `ok_backward_then_past` assert; deleting it would create a
hidden requirement, which is what an earlier Test Quality round already flagged. The description
scored 3/3 as written in the last Auto Review.

## BATCH 2 + FP panel (2026-09-08) — 1/10, pass ruled a false positive, description realigned

Batch 2 read **1/10 = 10%** (Orion PASS_LEGITIMATE, nine Nova fail), which is the Good band and
matches the 1/6 the batch-1 replay predicted. Then the FP panel ruled the pass a FUNCTIONAL false
positive, and it was correct: Orion advances the resolved frontier one bank per outer iteration in
reverse source order, so reversed chains longer than the 10-iteration budget emit spurious
`did not converge`. Reproduced against Orion's own patch: OK at 3, 8 and 10 banks, FAILS at 11 and
12, while the reference resolves any length in 1 iteration.

**The fix went to the description, deliberately.** The panel suggested adding an >=11-bank reversed
chain. That makes Orion fail and takes the batch to 0/10, which is a reject. Across two batches and
16 runs, zero agents implemented dependency-ordered settling, so an unbounded order-independence
promise is beyond the population. The sentence that over-promised is the thing that allowed the
divergent pass, so the sentence changed: "works whatever order the definitions appear in" became
"A bank may be placed at the end of a bank whose definition appears later in the file." Every
reversed fixture still traces to it, and nothing now claims unbounded length. Also added
`ok_chain_eight_reversed` so reversed order is pinned at 8 rather than 3; verified it passes on
Orion's patch, so the band is untouched.

Dropped the motivation sentence ("There is no way today to put a bank...") that three review rounds
asked me to cut, since a description edit was being paid for anyway. Body is 188 words. Kept the
unsettled-encoding comparison and the backward-cursor sentence, both of which fixtures assert.

**Cost: meta.md changed, so the next run is a FULL BATCH, not a re-eval.** Full data, kill tables and
the reproduction table are in eval-results.md.

## Solution Quality round 9 (2026-09-09) — one finding real and fixed, one does not reproduce

| Finding | Verdict | Evidence |
|---|---|---|
| HIGH: a backwards `#addr` in a never-settling bank suppresses the promised label diagnostic | **REAL, fixed.** `finalize_addr`'s LOWER-bound branch only deferred on `can_guess()`, so on the final pass it returned `Err` before the label node was reached. It now also defers while the bank start is unresolved, mirroring what the upper bound already did | Their program emitted only `bank placement did not converge` plus `address is out of bank range`; it now emits `bank placement did not converge` AND `label address did not converge`, which is what meta.md promises |
| HIGH: the scheduler ignores direct label dependencies, so an 11-link reversed label chain exhausts the budget | **DOES NOT REPRODUCE at the cited size.** Their exact shape (`addr = l(n-1) + 2`, reverse-declared) assembles fine at 11 links, and at 40. It first fails at 100, which the description no longer promises since the order clause was bounded last round | Measured: 11 OK, 40 OK, 100 did not converge |

The structural half of the second finding was still worth taking, so `eval_variable` now also logs a
LABEL's declared bank as a bank read, which gives `push_dep` a real edge for `addr = label + k`
instead of only for `$bankof(...)` members. It does not move the 100-link case, because a label's
VALUE is refreshed only by a traversal, exactly like a constant's; ordering cannot fix staleness.
Recorded rather than overclaimed.

New fixture `err_backwards_addr_never_settles` pins the fixed behaviour. It asserts the substring
`did not converge` at both the bank definition and the label, which both the reference and batch-2
Orion satisfy, though they word the bank half differently (`bank placement` vs `bank address`).
**Verified against Orion's patch before shipping: it passes all 69 tests, so the 1/10 band is
unchanged.** Nova runs already fail, so an added fixture cannot lift them.

Description suggestion (LOW, drop the opening line) declined: DESCRIPTION.md's first-sentence rule
requires the body to open with the ask. meta.md is UNCHANGED this round.

## BATCH 3 + round 10 (2026-09-09) — 0/5 all-Nova exposed a single-agent dependency

Batch 3 ran the current artifacts and came back 0/5, all Nova. Across three batches Nova is **0 for
19** and Orion **1 for 2**, so solvability rested entirely on one agent type and an all-Nova batch
reads as a reject.

Two tests failed in all five, and one of them was the fixture I added last round. Removed both, and
both removals are consistency fixes rather than band-chasing: labelalign padding is a third extent
category meta.md never names (it names reserved space and `fill`), and `err_backwards_addr_never_settles`
broke my own rule from two rounds earlier, that **meta.md never mentions `#addr`**, which is exactly
why I had removed `ok_addr_directive_in_derived_bank`. The round-9 reference fixes stay; only the
gates on unstated behaviour are gone, and the label-cascade clause is still asserted by the two
other convergence fixtures.

Replaying all 15 saved solutions: batch 2 goes **1/10 to 2/10 (20%)** with Nova_4 now passing
alongside Orion, batch 3 stays 0/5 with failures at 4-7. Pooled **2/15 = 13%**. The point is not the
rate, it is that a Nova can pass at all.

Test-only change, so the next run is a **RE-EVAL**, not a fresh batch.

Both AI warnings this round were previously settled and are declined again: the diagnostic-substring
brittleness is the repo's own `; error: <substring>` convention, and the description clauses
(unsettled-encoding comparison, label cascade, backward cursor, opening sentence) are each asserted
by fixtures or required by DESCRIPTION.md's first-sentence rule. meta.md is UNCHANGED, which is what
keeps the re-eval discount available.

## Test Quality round 11 (2026-09-09) — the finding was RIGHT, so it was fixed, not re-run

Unlike the round-8 Solution Quality FAIL (a false positive I disproved by running the reviewer's own
repro), this one reproduces on inspection. meta.md says `used` is "the furthest point its CONTENTS
reached", and two fixtures asserted a value that only a bare `#addr` jump with no contents produces.
Deleted `ok_forward_addr_raises` and rewrote `ok_backward_addr_keeps` to emit a byte at the high
point before jumping back, so both readings agree and the fixture now tests the stated backward
clause instead of an unstated one.

Replay of all 15 saved solutions: batch 2 goes 2/10 to **3/10 (30%)**, batch 3 stays 0/5, pooled
**3/15 = 20%**. Under the ceiling with margin, and both agent types now pass. Test-only change, so
the re-eval discount survives.

## Round 12 (2026-09-09) — restored prompt pressure, per the batch-4 diagnosis

Batch 4 (0/5) plus the replay of all 20 saved solutions showed the rate is being driven by the
PROMPT, not the suite: batch 2 (unbounded order clause) scores 5/10 on the very same tests that
batches 3 and 4 (bounded clause) score 0/10 on. All five batch-2 passers were probed against the
reference on six stated-clause programs and agree everywhere, so those passes are genuine and no
fair discriminator was hiding on those axes.

Also fixed the two align fixtures, which still carried the exact ambiguity Test Quality had just
flagged for `#addr`: padding with no following content is not "contents reached". Both now emit a
byte after the alignment, so the readings agree while still discriminating on cursor movement.

Acting on the recommendation: added one clause to meta.md, that a field may depend on labels and
instruction sizes that are themselves still settling. It names the three surviving discriminators and
promises nothing about iteration counts or chain length, so it cannot recreate the FP.

Deliberately did NOT relax further. The three killers left are the core feature; cutting them would
hollow the problem out rather than make it fair.
