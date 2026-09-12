# DESIGN.md — goblin-macho-chained-fixups

## 1. Title
Add Mach-O chained-fixups import resolution to goblin

## 2. Shape classification
- Shape: O-Composite-add (new capability spanning the load-command recognition stage and the
  public import-resolution API, no existing enum variant to extend — closest historical Olympus
  shape per `SHAPES.md`, though this sub predates the 2026-07 tier merge and is authored against
  the current one-tier floor, not the historical Olympus 450-LOC/8-35-file band).
- Definition: a new feature that must integrate with an existing dispatch point (`MachO::imports()`,
  already populated by the legacy `BindInterpreter` path) without an existing enum arm to slot into
  — the load-command recognition already exists (`CommandVariant::DyldChainedFixups`, added in PR
  #240, 2020) but nothing downstream consumes it (`mod.rs`'s load-command loop falls through to
  `_ => ()`), so this is greenfield machinery wired into one live integration point.
- Pass rate target: current sprint ceiling is <=40% (one tier). Given the trap stack below (F-9
  merge-with-legacy-path, F-13 three-tier discard granularity, F-10 pointer-format x import-format
  cross-product, plus genuinely unfamiliar bit-packed struct decoding), target the harder end,
  15-30%.
- Best agent: unknown without a live batch — no eval access on this workstation. Architecturally
  closest to Vega/Orion territory (multi-stage new-module authoring with one integration point),
  per `AGENTS.md` profiles.
- Dominant verdict (predicted): MISSED_REQUIREMENT (unsupported-format handling, rebase-vs-bind
  discrimination) and INTEGRATION_ERROR (failing to merge with the legacy path, or double-counting).
- Solver/our LOC ratio: unknown, no precedent for this shape in `approved-problems/`.

## 3. Public API surface
- `mach::chained_fixups::ChainedFixupsInterpreter<'a>` — struct, constructed from the raw file
  bytes and the `LC_DYLD_CHAINED_FIXUPS` load command's `LinkeditDataCommand` (offset + size).
- `ChainedFixupsInterpreter::new(bytes: &'a [u8], command: &load_command::LinkeditDataCommand) -> Self`
- `ChainedFixupsInterpreter::imports(&self, libs: &[&'a str], segments: &[segment::Segment<'a>], ctx: container::Ctx) -> error::Result<Vec<imports::Import<'a>>>`
  — same call shape as the existing `BindInterpreter::imports`, returns the SAME `imports::Import`
  type, so the two sources merge into one `Vec` at the call site.
- `MachO::imports()` (existing, modified): concatenates the legacy `BindInterpreter` result (if any)
  with the new `ChainedFixupsInterpreter` result (if any). A binary with neither yields `[]`
  (unchanged base behavior); a binary with only chained fixups yields the resolved chained imports
  (the fixed gap); a binary with both (rare in practice, but not forbidden by the format) yields the
  concatenation of both, legacy entries first.
- Pointer-format constants (module-level `pub const`, matching the existing `bind_opcodes.rs`
  convention of raw `u16`/`u32` constants rather than a Rust `enum`): `DYLD_CHAINED_PTR_ARM64E`,
  `DYLD_CHAINED_PTR_64`, `DYLD_CHAINED_PTR_64_OFFSET`.
- Import-format constants: `DYLD_CHAINED_IMPORT`, `DYLD_CHAINED_IMPORT_ADDEND`.

## 4. Canonical output form
- **Scope boundary (stated in meta.md as the feature's boundary, not hidden):** two pointer formats
  are supported — `DYLD_CHAINED_PTR_ARM64E` (both the unauthenticated and pointer-authenticated
  sub-encodings) and `DYLD_CHAINED_PTR_64` / `DYLD_CHAINED_PTR_64_OFFSET`. Two import-table formats
  are supported — `DYLD_CHAINED_IMPORT` (plain) and `DYLD_CHAINED_IMPORT_ADDEND` (carries a signed
  addend). Any other pointer format or import format, and a compressed (`symbols_format != 0`)
  symbols pool, is unsupported and returns `error::Error::Malformed` naming the unsupported value —
  never a silent empty result and never a panic.
- **Rebase-vs-bind discrimination:** a chain entry with `bind == 0` is a rebase (an ordinary pointer
  fixup, not a symbol import). The chain walk MUST still follow rebase entries' `next` field to reach
  later bind entries in the same chain — a rebase entry is walked over, never emitted as an `Import`.
- **Chain-walk order:** within one page, entries are visited in the order the `next` field chains
  them, starting from `page_start`. Pages are visited in ascending `page_start[]` index order.
  Segments are visited in ascending segment index (load-command order, matching
  `dyld_chained_starts_in_image.seg_info_offset[]`). The `Vec<Import>` returned by
  `ChainedFixupsInterpreter::imports` preserves this order.
- **A page whose `page_start` equals `DYLD_CHAINED_PTR_START_NONE` (0xFFFF) carries no fixups and
  is skipped entirely** — not an error, not a zero-length walk that still emits something.
- **Terminal condition:** a chain entry with `next == 0` is the last entry in its chain; walking
  stops after processing that entry (do not read past it as if `next` pointed to itself).
- **Import fields:** `name` and `dylib` resolve through the same `libs` slice indexing the legacy
  path already uses (`libs[lib_ordinal as usize]`); `addend` is the import-table entry's signed
  addend for `DYLD_CHAINED_IMPORT_ADDEND`, or `0` for `DYLD_CHAINED_IMPORT`; `is_weak` reflects the
  import-table entry's `weak_import` bit (not the pointer's `auth` bit, which is unrelated);
  `address` is `segment.vmaddr + page_byte_offset`; `offset` is `segment.fileoff + page_byte_offset`.
  `is_lazy` is always `false` (chained fixups has no lazy/eager distinction the way the legacy
  bind-opcode stream does).
- **Empty input:** a binary whose `LC_DYLD_CHAINED_FIXUPS` command has `imports_count == 0`, or
  whose every segment has no fixups (`seg_info_offset[i] == 0` for all `i`), yields `Ok(vec![])`.

## 5. Blind-spot pre-empts
- **Pipeline placement / silent fallthrough:** "Mach-O binaries that declare imports through
  `LC_DYLD_CHAINED_FIXUPS` instead of the legacy `LC_DYLD_INFO`/`LC_DYLD_INFO_ONLY` bind-opcode
  stream currently make `imports()` return an empty list even though the binary genuinely imports
  symbols." (states the gap plainly, does not hand the fix)
- **Two accumulate paths, not one replacing the other:** "The two import sources are independent and
  additive: a binary may carry either, and `imports()` must report whichever are present without
  dropping the legacy path's results." (pre-empts the natural mistake of REPLACING the legacy call
  instead of merging with it)
- **Discard-unit granularity (rebase != no-op, rebase != import):** "A chain entry that is not a
  bind (a rebase) still occupies a position in the chain and must be traversed to reach later
  entries; it contributes nothing to the import list." (pre-empts silently stopping the walk on the
  first non-bind entry, and pre-empts treating a rebase as an import)
- **Cross-product, not "the union":** "Both a pointer-format axis and an import-table-format axis
  vary independently across binaries; a binary using `DYLD_CHAINED_PTR_ARM64E` may use either
  import-table format, and a binary using `DYLD_CHAINED_PTR_64` may equally use either." (pre-empts
  an agent hardcoding one axis's handling assuming it is fixed by the other)

## 6. Description draft (meta.md body, plain prose target ~190 words)

See `meta.md` in this folder (word count checked at generation time).

## 7. File footprint

| Action | Path | Current LOC | Raw delta (est) | Meaningful (est) | Reason |
|---|---|---|---|---|---|
| NEW | src/mach/chained_fixups.rs | — | +330 to +420 | +260 to +340 | header/starts-in-image/starts-in-segment structs, pointer-format bit decode (2 families x rebase/bind), import-table decode (2 formats), chain walk, merge-ready `imports()` |
| MODIFY | src/mach/mod.rs | 649 | +25 to +40 | +20 to +32 | `pub mod chained_fixups;`, new `MachO` field, match arm for `CommandVariant::DyldChainedFixups`, `imports()` merges both sources |

TOTAL (est): ~355-460 raw / ~280-370 meaningful across 2 files (1 new + 1 modified). Clears the
current >=200 effective-LOC / >=2-files floor with a buffer; measure exactly once implemented
(no local Counter-2 hook in this workspace per `CLAUDE.md` staleness correction — use the inline
Counter-2-style stripper: strip blank/comment-only/brace-or-punctuation-only lines and count what
remains).

## 8. Solution outline — pure-function helpers

- `parse_fixups_header(bytes, offset, le) -> FixupsHeader` — reads the 7-field header, validates
  `fixups_version == 0` and `symbols_format == 0` (uncompressed; else `Malformed`).
  ← canonical form §4 (unsupported format -> Malformed, never silent)
- `parse_starts_in_image(bytes, blob_start, header, le) -> Vec<Option<u32>>` — per-segment
  `seg_info_offset`, `None` where `0` (no fixups in that segment).
  ← §4 empty-segment skip
- `parse_starts_in_segment(bytes, blob_start, seg_info_off, le) -> StartsInSegment` — page_size,
  pointer_format, segment_offset, page_count, page_start array.
- `decode_arm64e_entry(raw: u64) -> ChainEntry` / `decode_ptr64_entry(raw: u64, is_offset_variant: bool) -> ChainEntry`
  — pure bit-extraction into a small `ChainEntry { bind: bool, next: u32, ordinal_or_target: u64, addend_or_zero: i64 }`
  enum-free intermediate; each maps one pointer-format family to a uniform shape.
  ← canonical form §4 rebase-vs-bind discrimination, ARM64E's 4 sub-shapes (unauth/auth x rebase/bind)
- `resolve_import(entry, libs, segment, page_byte_offset, imports_table, imports_format, symbols_pool) -> Import`
  ← canonical form §4 Import field mapping
- `walk_chain(segment_data, page_start, stride, decode_fn) -> impl Iterator<Item = ChainEntry>`
  — the fixpoint-style loop: `let mut offset = page_start; loop { let entry = decode_fn(read_u64(offset)); yield entry; if entry.next == 0 { break; } offset += entry.next * stride; }`
  ← §4 terminal condition; matches the repo's own "iterate until fixpoint" idiom
  (`imports.rs::BindInterpreter::run`'s `while offset < location.end` loop is the closest existing
  precedent in this file, though its termination condition is buffer-end, not a chain sentinel).
- `ChainedFixupsInterpreter::imports()` — top-level orchestration: header -> starts_in_image -> for
  each `Some(seg_info_off)`, starts_in_segment -> for each page where `page_start != NONE`, walk the
  chain against `segments[seg_index].data` and collect binds into one `Vec<Import>`.

## 9. Test file outline
Path: `tests/mach_chained_fixups_<hex6>.rs` (new file, hex suffix per `CLAUDE.md` banned-marker rule)

Block 1 — Imports: `goblin::mach::{Mach, MachO}`, a local fixture-builder module.
Block 2 — Builder helpers (10-20 one-liners): `mach_header(ncmds, sizeofcmds)`, `segment_cmd(...)`,
  `dylib_cmd(name)`, `linkedit_data_cmd(cmd, off, size)`, `fixups_header(...)`,
  `starts_in_image(...)`, `starts_in_segment(...)`, `chained_import_entry(...)`,
  `arm64e_bind_word(ordinal, addend, next)`, `arm64e_auth_bind_word(...)`, `arm64e_rebase_word(...)`,
  `ptr64_bind_word(...)`, `ptr64_rebase_word(...)`, `assemble_binary(...)` (stitches load commands +
  segment data + blob into one byte `Vec`).
Block 3 — Assertion helpers: `imports_of(bytes) -> Vec<Import>`, `assert_single_import(imports,
  name, dylib, addend, is_weak)`.
Block 4 — Tests by requirement bucket:
  - **base gap regression** (1): the exact Gate-1 fixture — binary with ONLY chained fixups,
    `LC_DYLD_INFO` absent — `imports()` is non-empty and matches the expected single import
    (this is the test that fails on base for the right reason: base returns `[]`).
  - **pointer-format x import-format cross-product** (4, F-10 §11b): {ARM64E, PTR_64} x
    {DYLD_CHAINED_IMPORT, DYLD_CHAINED_IMPORT_ADDEND} — all four cells, each asserting the resolved
    name/dylib/addend.
  - **ARM64E auth variants** (2): auth-bind resolves the same ordinal as unauth-bind (addend forced
    to 0); auth-rebase is walked-over, not emitted.
  - **PTR_64_OFFSET vs PTR_64** (1): same bind encoding, confirms both pointer-format IDs decode
    through the same PTR_64-family path.
  - **rebase-then-bind chain** (F-13, 2): a 2-entry chain where entry 0 is a rebase and entry 1 is a
    bind reachable only by following `next` — import list has exactly 1 entry, not 0 (agent stopped
    at the rebase) and not 2 (agent emitted the rebase as an import too). This is the F-13 discard-
    unit-granularity discriminator: the "discard" is the rebase entry, and getting its extent wrong
    either over-discards (stops the walk) or under-discards (emits it).
  - **multi-page, one page has no fixups** (1): `page_start[1] == DYLD_CHAINED_PTR_START_NONE` -
    page 0's binds are still returned, page 1 contributes nothing (not an error).
  - **terminal condition, single-entry chain** (F-14-adjacent N-1 fixture, 1): `next == 0` on the
    FIRST entry - exactly one import, confirms the walk does not loop or read past the terminator.
  - **legacy-path merge** (F-9, 2): (a) a binary with ONLY legacy `LC_DYLD_INFO_ONLY` bind opcodes
    and no chained fixups still returns the legacy import (regression guard: merge must not have
    broken the untouched path); (b) a binary with BOTH a legacy bind-opcode stream AND chained
    fixups returns the concatenation of both, legacy first (the actual interdependence test - an
    agent who REPLACES rather than MERGES fails this one specifically, and MUST NOT be caught by
    (a) alone, since (a) passes under a simple `if let Some(chained) = ...; else legacy` reading too).
  - **unsupported format errors, not silent/panic** (2): `imports_format` outside {1,2} yields
    `Err(Malformed(..))` containing the format code as a substring; `symbols_format == 1`
    (compressed) yields `Err(Malformed(..))`.
  - **empty binary** (1): `imports_count == 0` -> `Ok(vec![])`.

Test count anchor: ~17 tests, ~330-420 test-body LOC (builder helpers amortize across all of them).

5-axis coverage check:
  - Every described atom in meta.md: yes (bucket list above traces 1:1 to §4/§5 sentences)
  - Every public API surface: `ChainedFixupsInterpreter::new`/`imports`, `MachO::imports` merge
  - Every solution branch: unsupported-format branches, rebase branch, bind branch (both pointer
    families x both auth states), page-none-skip branch, chain-terminal branch
  - Standard edge cases: empty (imports_count=0), single entry (terminal N-1), boundary
    (page_start=NONE), the negative-of-merge (legacy-only still works)
  - Stated inverse: legacy-only vs chained-only vs both (the merge requirement's inverse pair)

## 10. Forced trait bounds / generics / kwargs
None — no closures, no generics beyond the existing lifetime `'a` threading `BindInterpreter`
already establishes as the repo's convention for this subsystem. `scroll::Pread`/`SizeWith` derive
on the new structs, matching every other load-command-adjacent struct in the crate (see
`LinkeditDataCommand`, `DyldInfoCommand` in `load_command.rs` for the derive-attribute convention
to copy).

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (§5/§6) | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | Replace legacy `BindInterpreter::imports()` call instead of merging with it | F-9 | S3 baseline-preservation through shared chokepoint | integration correctness at the `MachO::imports()` chokepoint | #3 (both land in the same accumulator) | `imports()` today has an `if let Some(interpreter) = ... else Ok(vec![])` shape; the natural edit is to add a parallel `if`/`else` for the new source and an agent who does not re-read the existing branch structure produces an if/else-if that silently drops one source when both commands are present (rare in practice, but the merge-both test forces it) | §5 "the two import sources are independent and additive" | legacy-path-merge (b): both-present binary |
| 2 | Emit rebase entries as imports, or stop the chain walk at the first rebase | F-13 | S2 composition (chain-walk-continues x rebase-is-not-an-import are two separately-documented rules whose composition is the actual requirement) | discard-unit granularity within the per-page chain | #3 (a broken walk also breaks the merge test's chained-only half) | the natural reading of "walk the chain" and "bind entries are imports" in isolation is each individually easy; getting BOTH right on the same entry (walk past it AND don't emit it) is the compound requirement | §4 rebase-vs-bind discrimination + §5 discard-unit-granularity sentence | rebase-then-bind chain (2 tests) |
| 3 | Hardcode one pointer-format's bit layout assuming the other axis is fixed (e.g. only implement DYLD_CHAINED_PTR_64's single-shape bind, or only ARM64E's unauth-bind) | F-10 | A9-adjacent (exact-fit-passing arithmetic — an agent who tests only the shape their own fixture uses will not self-discover the missing cell) | pointer-format x import-format cross-product | #1 (a partial implementation also fails the both-present merge test if the missing cell is exercised there) | agents typically build and self-test against ONE constructed example; without an explicit off-diagonal test, a solution that only handles the fixture's exact pointer-format/import-format pairing passes its own smoke test | §4 "two pointer formats... two import-table formats... vary independently" | cross-product (4 tests, §11b below) |

Every trap names a real F-id. Traps 2 and 3 sit on different axes (discard-granularity vs
format-cross-product) and both are interdependent with trap 1 through the shared `imports()`
accumulator — an incomplete or mis-merged implementation on any one trap tends to also fail the
both-present merge test, which is deliberately the least escapable discriminator in the suite.

## 11b. Capability cross-product matrix (F-10)

| | DYLD_CHAINED_IMPORT | DYLD_CHAINED_IMPORT_ADDEND |
|---|---|---|
| **DYLD_CHAINED_PTR_ARM64E** | test: arm64e_bind_plain_import | test: arm64e_bind_addend_import ← off-diagonal |
| **DYLD_CHAINED_PTR_64 / 64_OFFSET** | test: ptr64_bind_plain_import ← off-diagonal | test: ptr64_bind_addend_import |

Both off-diagonal cells are in the test bucket list (§9, cross-product bucket, 4 tests total — the
table's four cells). Predicted failure mode: an agent who built and self-tested against one cell
(most likely PTR_64 + DYLD_CHAINED_IMPORT, the simplest combination) over-fires by reusing that
cell's addend-is-always-zero assumption on the ADDEND format, or under-fires by never reading the
`addend` field at all for ARM64E (which the auth-bind sub-shape genuinely lacks, but auth is a
pointer-format sub-detail, not an import-table-format axis value, so this is a fair, distinct trap
from the cross-product cells themselves).

Scope audit: `imports_count` is a whole-image count (not per-segment); `page_start[]` is scoped to
one segment's pages (not the whole image); `next` is scoped to one chain (chains from different
pages/segments never interleave). All three extents are stated in §4 to avoid an F-11-style
ambiguous-scope reading.

Format-noun audit (L24): "chain" = the linked sequence of pointer slots within ONE page, following
`next` (stated in §4's chain-walk-order sentence: "Pages are visited... Segments are visited...").
"Entry" = one 8-byte slot, whether rebase or bind. Neither noun's extent is left to natural-language
inference.

Tolerance-fixture audit (L25): the terminal-condition test (§9) is the N-1 fixture — a single-entry
chain where `next == 0` on the FIRST entry, asserting exactly one import and no attempt to read
past the terminator. There is no "allow one, stop at the second" rule in this design (chained
fixups has no arming/firing threshold), so this audit item does not add a distinct requirement
beyond the terminal-condition test already planned.

Wrong Logic % constraint: estimated <25% — the traps are integration/discard/cross-product
failures (MISSED_REQUIREMENT / INTEGRATION_ERROR flavored), not subtle numerical-correctness bugs
in an otherwise-right algorithm. If a live batch shows Wrong Logic >=25%, that signals the bit-
extraction itself is the dominant failure mode, which would be a legitimate (not unfair) hard
result given how unforgiving packed-bitfield arithmetic is to get byte-exact.

## 12. Tier + category decision
- Tier: Olympus (one tier, 2026-07 sprint).
- Sub-rank estimate: Good (clears floor with buffer, multi-format cross-product, genuine new
  subsystem) pending an actual batch — no eval access to confirm.
- Category: **feature-request** (net-new public API and net-new capability; title verb "Add" is
  consistent).

## 13. Predicted Nova/Orion/Vega pass rate
- Predicted: 15-30%.
- Reasoning: three interdependent+misdirecting traps (F-9 merge, F-13 discard-granularity, F-10
  cross-product) stacked on top of a domain (packed-bitfield binary format decoding) with no
  in-repo template to copy from (the one loose analog, `BindInterpreter`, is structurally
  different enough not to be copy-pasteable — confirmed by direct comparison: linear opcode stream
  with a single mutable accumulator, vs a three-tier indexed structure with per-pointer-format bit
  decode). Per the TOO-EASY.md "spec-knowable predicate domain" law, the risk is that a strong
  model has enough training exposure to Apple's `dyld`/LLVM's `MachOObjectFile.cpp` chained-fixups
  parsers to reproduce the bit layout close to verbatim — this is a real risk this design cannot
  fully rule out without a batch, which is exactly why the merge/discard/cross-product traps are
  built as SEPARATE, interdependent requirements layered on top of correct bit decoding rather than
  relying on the bit decoding itself as the only source of difficulty.
- Sanity check: predicted pass rate <=40% ceiling; if a real batch shows 0%, the most likely first
  cut is relaxing the ARM64E auth-variant requirement (§4) to unauth-only, which removes one
  sub-axis without touching the three named traps.

## 14. Quality-gate checklist
- [x] Repo understanding: 5/5 (architecture, subsystems, entanglement zones, test framework +
      convention, cited test file — `tests/macho.rs`)
- [x] Existing PR / publicly-solved check: 0 hits for "chained fixups"/"chained_fixups"/
      "dyld_chained"/"DYLD_CHAINED_FIXUPS" against all PR/issue states (see hunt dossier
      `REPO-HUNT-2026-08-15.md` + re-verified at design time); the ONE hit (PR #240, merged 2020)
      only recognizes the load command as a generic offset+size stub and explicitly says so in its
      own PR body ("no additional structure definitions were necessary") — confirmed by reading the
      body, not just the title, per Phase 2's non-negotiable rule.
- [x] Closest approved problem opened for scaffolding: no exact shape match in
      `approved-problems/` (binary-format parsing is a new domain for this workspace); used
      `rust-minidump-stack-containment`'s F-13 two-tier framing and `pulldown-cmark-gfm-autolinks`'
      F-9 merge-with-existing-path framing as structural references instead.
- [x] Title: verb-led, 8 words, names specific subsystem ("Mach-O chained-fixups import
      resolution")
- [x] Shape declared (O-Composite-add, historical label, current floor governs)
- [x] Public API surface lists every name tests will assert
- [x] Canonical output form spelled out (scope boundary, rebase/bind, chain order, terminal
      condition, Import field mapping, empty input)
- [x] 0 codebase-inferable requirements relied upon (everything in §4/§5 is stated)
- [x] Description draft word count — 207 words (meta.md body), target ~190, hard cap 500
- [x] File footprint sketched against real source (mod.rs read in full for the integration point;
      no invented file)
- [x] Raw/meaningful LOC estimated to clear >=200 effective / >=2 files with buffer
- [x] Solution outline: pure-function helpers, one per canonical-form requirement
- [x] No fixpoint loop needed (chain walk has a hard terminal condition, not an iterate-to-fixpoint
      one) — the walk_chain loop is documented as the closest analog to the repo's iterate idiom
- [x] Test file outline: 4-block layout, scenario-encoded names, hex-suffixed filename
- [x] 5-axis test coverage planned
- [x] Forced trait bounds documented (none beyond existing lifetime/derive conventions)
- [x] 3 named traps, each with F-id, pre-empt sentence, catching test
- [x] Traps sit on different axes (chokepoint-merge / discard-granularity / format-cross-product),
      trap 1 interdependent with both 2 and 3 through the shared accumulator
- [x] §11b cross-product matrix filled in, both off-diagonal cells tested
- [x] Format-noun extents stated (chain, entry, imports_count scope)
- [x] Tolerance/N-1 fixture present (terminal-condition single-entry test) — no arming/firing rule
      in this domain beyond that
- [x] Predicted Wrong Logic <25%
- [x] Predicted pass rate <=40% ceiling (15-30% target)
- [x] Category matches description (feature-request / "Add")
- [x] Not pattern-followable (no 3+ existing same-shape functions; the one analog is structurally
      different, confirmed by direct comparison in §8)
- [x] Not in `RULES.md § Features already used` (new domain for this workspace)

## Why this is not a duplicate
No prior submission in `approved-problems/`, `problems/`, `rejected/`, or
`Instructions/SATURATED-REPOS.md` touches binary-format parsing (ELF/Mach-O/PE) at all — nearest
neighbors by domain are `customasm-ruledef-disassembly` (a user-defined ASSEMBLY LANGUAGE
disassembler for a toy ISA, unrelated subsystem and unrelated format) and
`rust-minidump-stack-containment` (crash-dump stack UNWINDING, not object-file symbol import
resolution). Differentiator: this pick's capability is entirely internal to Apple's `dyld`
chained-fixups on-disk format and goblin's own `Segment`/`libs`/`Import` types — it cannot be
described without those repo-specific nouns, unlike a named external standard (CSS selector, SQL
clause, RFC) that independent authors would converge on identically.

## Predicted iteration cycles: 2 (target 1, accept up to 3)
The unresolved risk (spec-knowable predicate domain, §13) is the reason for the 2-cycle estimate
rather than 1: if a first batch reads high, the most likely fix is narrowing the pointer-format
scope (drop ARM64E auth variants) rather than a structural redesign, which is a 1-round fix, not a
rebuild.
