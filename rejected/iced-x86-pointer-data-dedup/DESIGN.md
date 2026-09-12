# DESIGN.md — iced-x86-pointer-data-dedup

## 1. Title

Deduplicate shared pointer-data slots in the block encoder's long-branch trampoline

## 2. Shape classification

- Shape: **O-Composite-extend** (SHAPES.md § Pattern 11-13) — extends an existing aggregation
  (`Block`'s pointer-data allocation/layout/write pipeline) so that it is consulted correctly by
  every one of its existing callers (four separate `Instr` implementations), rather than adding a
  net-new subsystem.
- Pass rate target: ≤20% (current sprint ceiling ≤40%; targeting the hard end since the design has
  two independent, interdependent, misdirecting traps — see § 11)
- Best agent: Mixed / Vega-leaning (heavy multi-file refactor of an existing mechanism)
- Dominant verdict: MISSED_REQUIREMENT (partial dedup — one `TargetInstr` form handled, the other
  forgotten) and REGRESSION (naive invalidation breaks a sibling that still needs the shared slot)
- Solver/our LOC ratio: not yet measured (no shape precedent for this exact repo); estimate 1.3-1.6x
  based on comparable O-Composite-extend cross-file refactors

## 3. Public API surface

No new public types or functions. This is a pure internal-machinery change: the observable
public surface (`BlockEncoder::encode` / `encode_slice`, `BlockEncoderResult`, `RelocInfo`) is
unchanged in shape. What changes is the *content* of two existing public fields on
`BlockEncoderResult`, for inputs that trigger the new behavior:

- `code_buffer: Vec<u8>` — shorter, because a shared 8-byte pointer slot is written once instead
  of once per branch that targets it.
- `reloc_infos: Vec<RelocInfo>` — fewer entries, exactly one `RelocInfo` per *distinct* final
  target address that required a long-branch trampoline, never one per branch instruction.

No behavior of `new_instruction_offsets` or `constant_offsets` changes; those are keyed to
instructions, not to the pointer-data slots those instructions may share.

## 4. Canonical output form

- **Sharing key**: two long-form branches share one 8-byte pointer-data slot if and only if they
  resolve to the same final target — either the same relocated instruction (by its final address
  after the fix-up loop converges) or the same fixed external address. Branches with different
  targets never share a slot, even if those targets happen to be numerically close.
- **Slot lifetime**: a shared slot stays part of the final output as long as at least one branch
  that was assigned to it still needs the long (indirect-pointer) form when the block encoder
  finishes converging. If every branch that was assigned to a slot no longer needs the long form
  (all of them shrank to the short or near form instead), the slot is dropped entirely, exactly as
  an unshared slot already is today.
- **Reloc ordering**: `reloc_infos` order for the deduplicated slots follows the same rule already
  used for the existing (unshared) slots — allocation order of first use, not sorted by address.
  (Existing tests already sort `reloc_infos` before comparing, so this does not need to be a new
  documented rule — it inherits the existing convention.)
- **Empty/degenerate input**: a block with zero long-form branches, or one where every long-form
  branch has a distinct target, behaves exactly as before (one slot per branch) — deduplication
  only changes output when two or more branches share a target.

## 5. Blind-spot pre-empts

- **Two representations of "target," one rule**: a branch's final target is represented internally
  either as a reference to one of the instructions being relocated, or as a fixed external address.
  State explicitly in meta.md: "Two long branches share a slot whenever they resolve to the same
  final target, whether that target is another instruction being relocated in the same call or a
  fixed external address." This pre-empts the common miss of only deduplicating the
  relocated-instruction case (the more visible one in test fixtures) and forgetting the
  fixed-address case.
- **Shared state, partial release**: state explicitly: "A shared slot is only removed from the
  output once none of the branches that were assigned to it still need it." This pre-empts the
  natural (wrong) instinct to reuse the *existing* per-branch invalidation flag verbatim, which
  would drop a slot the moment any single sharer stops needing it, even while another sharer still
  relies on it.

## 6. Description draft (meta.md, plain prose)

Draft (word count target ~150-180, well under the 200 recommended cap):

> Extend the block encoder's long-branch trampoline to share pointer-data storage between branches
> that target the same address. When `BlockEncoder::encode`/`encode_slice` relocates a block whose
> 64-bit branch is too far from its target to use a near jump, it currently falls back to an
> indirect jump through an 8-byte pointer stored right after the code. Today every branch that
> needs this fallback gets its own 8-byte slot, even when two or more branches jump to the exact
> same place, which wastes output space and adds a redundant relocation entry per branch.
>
> Two long-form branches should share one pointer-data slot whenever they resolve to the same
> final target, whether that target is another instruction being relocated in the same call to
> `encode_slice`, or a fixed external address outside the relocated block. A shared slot stays in
> the output as long as at least one of the branches assigned to it still needs the long form once
> the encoder's branch-shortening pass has converged; it is only dropped once none of them do,
> exactly as an unshared slot already is. `reloc_infos` must contain exactly one entry per distinct
> shared slot that ends up in the output, never one per branch that uses it.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Meaningful (x0.65) | Reason |
|---|---|---|---|---|---|
| MODIFY | src/rust/iced-x86/src/block_enc/block.rs | 145 | +75 | 49 | Add target-keyed lookup table on `Block`; change `alloc_pointer_location` to accept the branch's `TargetInstr` and return a shared `Rc<RefCell<BlockData>>` on a repeat key; track per-slot live-sharer count so invalidation only fires when the last sharer drops out |
| MODIFY | src/rust/iced-x86/src/block_enc/instr/simple_br_instr.rs | 318 | +10 | 6.5 | Pass `&self.target_instr` into `alloc_pointer_location`; use the shared-count-aware release call instead of the unconditional `is_valid = false` when shrinking away from Long |
| MODIFY | src/rust/iced-x86/src/block_enc/instr/jcc_instr.rs | 255 | +10 | 6.5 | Same call-site update as simple_br_instr.rs |
| MODIFY | src/rust/iced-x86/src/block_enc/instr/jmp_instr.rs | 162 | +10 | 6.5 | Same call-site update |
| MODIFY | src/rust/iced-x86/src/block_enc/instr/call_instr.rs | 103 | +10 | 6.5 | Same call-site update |
| MODIFY | src/rust/iced-x86/src/block_enc/instr/mod.rs | 365 | +20 | 13 | `TargetInstr` needs a small hashable/comparable key extraction helper shared by all four call sites (avoid duplicating the match-on-variant logic four times) |

TOTAL raw: 135, meaningful (x0.65 sketch): ~88 across 6 files.

**This sketch is under the 200-effective floor as a x0.65 raw estimate**, which the doctrine
flags explicitly (raw x0.65 is a rough sketch, not the gate). The real driver of meaningful LOC
here is the `block.rs` lookup/lifetime-tracking logic and its test-visible correctness (the
shared-count bookkeeping is exactly the kind of logic that does NOT compress well under the
blank/comment/brace strip, since it is almost entirely branching logic, not boilerplate). Expect
the real figure to land closer to 130-160 meaningful in block.rs alone once the lifetime-tracking
state machine is fully written out, putting the total in the 180-220 meaningful range — at or
slightly under the current 200 floor.

**Scope-lever if the real implementation lands under 200 meaningful (decide during Step 4, not
now):** extend the same shared-slot mechanism to also cover the RIP-relative memory-operand
spill path in `ip_relmem_instr.rs` (128 LOC, currently NOT using `alloc_pointer_location` — it has
its own, separate out-of-range fallback for RIP-relative memory operands). Confirmed at design time
that this file does NOT currently share the `pointer_data` mechanism, so extending dedup to it is a
genuine, orthogonal expansion of scope rather than a restatement of the same fix, and it adds a
real third axis (memory-operand spill vs. branch-target spill) if needed. Left out of the base
design to keep the trap set legible; add only if Step 4's actual diff comes in under 200 meaningful.

## 8. Solution outline — pure-function helpers

- `TargetInstr::dedup_key(&self) -> Option<TargetKey>` (new, in `instr/mod.rs`) — returns `None`
  for `Uninitialized`/`IsOwner` (never shareable), `Some(TargetKey::Instr(idx))` for
  `Instruction(idx)`, `Some(TargetKey::Addr(addr))` for `Address(addr)`. ← description requirement
  "whether that target is another instruction ... or a fixed external address"
- `Block::alloc_pointer_location(&mut self, target: &TargetInstr) -> Rc<RefCell<BlockData>>`
  (rewritten) — looks up `target.dedup_key()` in a new `pointer_data_by_key: Vec<(TargetKey,
  Rc<RefCell<BlockData>>)>` (small, linear scan is fine given the tiny slot counts in one block);
  on a hit, increments a live-sharer counter on the existing entry and returns the clone; on a
  miss (or `dedup_key() == None`), allocates fresh, and only pushes into `data_vec` (the vec that
  actually gets laid out and written) on the fresh-allocation path. ← description requirement
  "share one pointer-data slot whenever they resolve to the same final target"
- `Block::release_pointer_location(&mut self, data: &Rc<RefCell<BlockData>>)` (new) — decrements
  the slot's live-sharer counter; sets `is_valid = false` only when the counter reaches zero.
  Replaces the current `pointer_data.borrow_mut().is_valid = false;` call sites in all four
  `Instr` impls when an instruction shrinks away from the Long form. ← description requirement
  "only dropped once none of them do"
- `BlockData` gains a `sharer_count: u32` field (or the tracking lives in `Block`'s lookup table —
  either is fine; the constraint is that `is_valid` must not flip to `false` while any sharer is
  still counting on the slot).

No fixpoint loop is added — the *existing* fixpoint loop in `block_enc.rs::encode2` is unchanged
and is exactly where the alloc/release calls fire (during `try_optimize`), so the shared-count
bookkeeping happens naturally across its existing iterations without a new loop structure.

## 9. Test file outline

Path: `src/rust/iced-x86/src/block_enc/tests/pointer_data_dedup.rs` (new file, added to
`tests/mod.rs`'s `mod` list — matches the existing one-file-per-feature-area convention visible in
that directory: `misc.rs`, `br8_64.rs`, etc.)

Block 1 — Imports: `use crate::block_enc::tests::*;` (matches `misc.rs`)
Block 2 — none needed; this feature has no new builder-helper types, it reuses the existing
`encode_test` helper from `tests/mod.rs` (bitness, orig bytes, new rip, expected new bytes, options,
decoder options, expected instruction offsets, expected reloc infos) exactly as every other file in
this directory already does.
Block 3 — none needed (no new assertion helpers; `encode_test`'s built-in `assert_eq!` on
`code_buffer` and sorted `reloc_infos` is already the exact-byte, exact-reloc-count assertion this
feature needs).
Block 4 — tests grouped by requirement bucket:

- **Bucket "same relocated-instruction target shares a slot"**: two (and, separately, three) far
  64-bit branches inside one relocated block that both/all target the same later instruction in
  that same block; assert `reloc_infos` has exactly one `Offset64` entry (not two/three), and the
  encoded byte length matches hand-computed length for one shared 8-byte slot, not N slots.
- **Bucket "same fixed external address shares a slot"** (the off-diagonal cell per § 11b): two far
  branches whose target is a fixed address *outside* the relocated block (not one of the moved
  instructions) — same numeric target on both. Assert the same single-slot sharing as above. This
  is the case a partial (Instruction-only) dedup implementation will fail.
- **Bucket "different targets never share"**: two far branches with two *different* targets (both
  relocated-instruction form, and separately both fixed-address form) — assert two distinct
  `Offset64` reloc entries and two 8-byte slots, i.e. dedup must not over-merge.
- **Bucket "partial release keeps the slot"**: three branches share one target; construct the block
  so that after the fixpoint pass converges, one of the three branches has shrunk to the Near form
  (no longer needs the shared slot) while the other two still need Long. Assert the slot is still
  present exactly once (not dropped) and the two remaining Long branches still encode a correct
  indirect jump through it. This is the N-1-style discriminator for the trap in § 11 row 1 — the
  fixture where ALL sharers drop out (next bucket) passes under both the correct and the naive
  "invalidate on any drop" reading, so it does not by itself prove the fix is right; this one does.
- **Bucket "full release drops the slot"**: same setup, but construct it so ALL branches sharing a
  target shrink away from Long. Assert the slot disappears from the output entirely (matches
  today's behavior for a single unshared branch that shrinks away).
- **Bucket "mixed sharing groups"**: four far branches, two-and-two split across two distinct
  targets in the same block. Assert exactly two `Offset64` reloc entries (not four, not one), each
  slot holding the correct one of the two target addresses.
- Edge cases: a single long-form branch (no sharing possible — must behave identically to current
  output, byte-for-byte); zero long-form branches (untouched path, existing `misc.rs` coverage
  already exercises this, no new test needed).

Test count anchor: ~14-18 granular `#[test]` fns across the buckets above (2-3 bitness/shape
variants per bucket is normal for this test file's existing convention of one test per concrete
byte sequence).

5-axis coverage check:
- ✓ Every described atom in meta.md (sharing key has two forms; slot lifetime has partial vs. full
  release; reloc count is exactly one per distinct slot)
- ✓ Public API surface (`code_buffer`, `reloc_infos` on `BlockEncoderResult`, both exercised)
- ✓ Every solution branch (dedup hit for `Instruction`, dedup hit for `Address`, dedup miss/no-key
  for `IsOwner`/`Uninitialized` implicitly via the "different targets never share" bucket using
  ordinary near/short branches that never touch the pointer-data path at all)
- ✓ Standard edge cases: single-branch (boundary of "no sharing possible"), the N-1 partial-release
  fixture (boundary of "not all sharers gone yet")
- ✓ Stated inverse: "different targets never share" is the direct negative of the sharing rule

## 10. Forced trait bounds / generics

`Block::alloc_pointer_location`'s new parameter is `&TargetInstr`, an existing `pub(super)` enum —
no new generic bounds. `TargetKey` (the dedup-key helper type) needs `Eq`/`Hash` or, if a linear
`Vec` scan is used instead of a `HashMap` (reasonable given per-block slot counts are always small),
just `PartialEq` — a linear scan avoids introducing a hashing requirement onto `u64` addresses and
`usize` indices that doesn't otherwise exist in this file, matching the repo's existing preference
for small `Vec`-based lookups over `alloc::collections::HashMap` at this size class-crate is
`no_std` + `alloc` only, so reaching for `std::collections::HashMap` is not an option anyway.

## 11. Predicted trap matrix

| # | Trap | F-id | Arsenal class | Axis it measures | Interdependent with | Why agents hit it | Pre-empt sentence (in § 6) | Test that catches it |
|---|---|---|---|---|---|---|---|---|
| 1 | Naive invalidation drops a still-needed shared slot the moment any ONE sharer shrinks away from Long, instead of only when the LAST sharer does | new (candidate) | S1 speculative-state isolation / S5 dual-path consistency | shared-mutable-state lifetime correctness | #2 (both live in the same `alloc_pointer_location`/release rewrite; getting #2 right without a correct release-counting scheme is what makes #1 hard to dodge by accident) | The existing code's `is_valid = false` is a single unconditional flag-flip per-instruction; making it reference-counted is a non-obvious generalization, and the failure is silent (an `IcedError::new("Internal error")` panic-style bail deep in `BlockData::address()`, not a compile error) — it fails on the specific 3-branches-with-1-dropout fixture, not the simpler 2-branches-both-dropout one | "A shared slot is only removed... once none of the branches... still need it" | "partial release keeps the slot" bucket (the N-1 fixture; the "full release drops the slot" fixture alone would NOT catch this) |
| 2 | Dedup implemented only for `TargetInstr::Instruction(idx)` (the salient, in-block case visible in most natural test fixtures), `TargetInstr::Address(addr)` (external target) left unmerged | new (candidate) | A-tier orthogonal fair-wall (reuse-missing-arm) | representational-form parity (two spellings of "target") | — (independent of #1; a fix can get #1 right and still miss this) | Agents pattern-match the dedup key off the most visible/common case exercised by existing repo tests (branches targeting labels inside the moved block); the `Address` variant is used for cross-block/external targets, which is less prominent in the existing test suite's fixtures | "whether that target is another instruction ... or a fixed external address" | "same fixed external address shares a slot" bucket |

Both rows verified against CONTRACT-STATED/FIX-HIDDEN: § 6 states the sharing rule and the
lifetime rule in full generality (both target forms; partial-vs-full release) without naming the
`TargetInstr` enum, `Rc`/`RefCell`, or any internal field — the fix location and mechanism are not
handed to the agent, only the externally observable contract (`reloc_infos` count, `code_buffer`
size, correctness of the remaining Long-form branches).

## 11b. Capability cross-product matrix (F-10)

Two axes stated in § 6: **target representation** (relocated-instruction vs. fixed-external-address)
x **release completeness** (partial drop-out vs. full drop-out).

| | partial release (some sharers still need Long) | full release (no sharers still need Long) |
|---|---|---|
| **instruction-form target** | test: "partial release keeps the slot" (3 sharers, 1 shrinks) | test: "full release drops the slot" (all shrink) |
| **address-form target** | off-diagonal: covered implicitly by using an address-form target in the mixed-sharing-groups bucket alongside a partial-release scenario — **add as an explicit dedicated test**, not left implicit, since this is exactly the cell the doctrine flags as highest-value | test: "same fixed external address shares a slot" already exercises full-group behavior when none shrink further |

The address-form x partial-release cell is the one genuinely empty off-diagonal cell — flagged
explicitly here so Step 3 (test authoring) does not silently drop it the way an implicit-only
covering test would.

Scope audit: "long branch" as used in § 6 always means the fully-synthesized three-instruction
trampoline form (`InstrKind::Long`), never the Near form's two-instruction trampoline — the Near
form never allocates pointer-data at all, so no ambiguity exists here to pre-empt.

Format-noun audit: "slot" in § 6 always means one `BlockData` (one 8-byte storage location plus
its `RelocInfo`) — never the surrounding trampoline code bytes. No amendment-row-style extent
ambiguity applies (this is not a two-tier format).

Tolerance-fixture audit: not applicable — there is no "allow one, stop at the second" counting
rule in this feature; the N-1 fixture role here is filled by the "partial release keeps the slot"
bucket, already called out above as the true discriminator versus the "full release" fixture.

Wrong Logic % constraint: predicted well under 25% — this is a correctness-of-a-well-specified-
lifetime-rule feature (O-Composite-extend), not a subtle-algorithm-correctness feature.

## 12. Tier + category decision

- Tier: Olympus (single tier, 2026-07 sprint)
- Sub-rank target: Okay-to-Good (shape precedent unavailable for this repo; LOC lands near the
  200 floor per § 7, file count (6) and trap count (2, both interdependent-adjacent) support Good)
- Category: **enhancement** — this rewrites/extends the existing pointer-data allocation behavior
  of `BlockEncoder`; it does not add a new public type, function, or option. Title verb "Extend"
  matches.

## 13. Predicted Nova pass rate

- Predicted: 15-25%
- Reasoning: two orthogonal, non-collapsing traps (shared-lifetime correctness or the
  representational-form-parity gap or both) against a codebase-cold, non-ISA-spec, no-existing-PR
  feature area. Neither trap alone is likely to hit 50%+ (both require reading `TargetInstr`'s
  actual enum shape and the existing `is_valid` invalidation call sites closely, in four different
  files, before writing anything) but agents that get the mechanism broadly right (some dedup
  happening) but miss one axis will pass most of the "obvious" tests and fail the two dedicated
  discriminator buckets (partial-release N-1, and address-form sharing) — landing meaningfully
  under 50% without being at 0%, since the core "look up by key before allocating fresh" idea is a
  reachable, describable mechanism from § 6 alone.
- Sanity check: within the ≤40% sprint ceiling; not 0% (the core mechanism is directly describable
  from the stated contract, so at least a careful agent that gets both axes right should pass).

## 14. Quality-gate checklist

- [x] Repo understanding: 5/5 (architecture, subsystems, entanglement zones, test framework +
      conventional location, existing test file cited as template — all demonstrated above)
- [x] Existing PR check: 0 hits for "pointer data", "pointer-data", "long branch dedup",
      "shared slot" against icedland/iced (spot-checked during candidate search; the only nearby
      hit, PR #643, is a distinct capability — instrumentation offset reporting — confirmed by
      reading its diff, which touches only C#/Java/JS binding option enums, not
      `src/rust/iced-x86/src/block_enc/block.rs` or any of the four `Instr` impl files)
- [x] Closest approved problem: none in this repo/family; scaffolding taken directly from the
      repo's own `block_enc/tests/mod.rs::encode_test` convention instead
- [x] Title: verb-led, 8 words, names specific subsystem (block encoder's long-branch trampoline)
- [x] Shape declared: O-Composite-extend
- [x] Public API surface: none new; documented exactly which existing public fields change content
- [x] Canonical output form spelled out (§ 4: sharing key, slot lifetime, reloc ordering, empty case)
- [x] 0 codebase-inferable requirements beyond the two stated rules (both stated explicitly in § 6)
- [x] Description draft: ~170 words, well under 200 recommended / 500 hard cap
- [x] Description draft: no headers, no formulaic labels, no Box<>, no code-instead-of-prose
- [x] File footprint sketched against real source files with real current LOC counts
- [x] Raw/meaningful LOC: sketch lands 180-220 meaningful (near floor; scope lever identified and
      held in reserve rather than pre-emptively used, per doctrine)
- [x] Solution outline: helper per description requirement (3 new/rewritten functions, each
      mapped to a specific sentence in § 6)
- [x] No fixpoint loop needed (reuses existing one); noted explicitly why
- [x] Test file outline: matches repo's own one-file-per-area, `encode_test`-based convention;
      scenario-encoded bucket names
- [x] 5-axis test coverage planned
- [x] Forced bounds documented (§ 10) — none beyond existing types; `no_std`+`alloc` constraint
      noted (linear-scan lookup, not `HashMap`)
- [x] 2 named traps, each with pre-empt sentence + catching test, both F-id-candidate-flagged since
      neither has prior measured evidence in `failure-patterns.md` (new repo/family)
- [x] Traps sit on different axes (lifetime-correctness vs. representational-form-parity) and are
      interdependent (both live in the same rewritten alloc/release pair)
- [x] § 11b cross-product matrix filled in; one genuinely-empty off-diagonal cell identified and
      called out for explicit (not implicit) test coverage
- [x] Form-parity audit (F-18-flavored): instruction-form vs. address-form target both tested at
      every relevant position
- [x] Format-noun / tolerance-fixture audits: confirmed not applicable, reasons stated
- [x] Predicted Wrong Logic <25%
- [x] Predicted Nova pass rate 15-25%, under the ≤40% ceiling
- [x] Category matches description: enhancement
- [x] Feature is NOT pattern-followable (no 3+ existing examples of this exact shape in the repo)
- [x] Feature is NOT in RULES § Features already used (new repo to this workspace)

---

**Why this is not a duplicate**: this workspace has no prior submission against `icedland/iced` or
any x86-encoding-adjacent repo (checked `problems/`, `rejected/`, `approved-problems/` — zero hits
for "iced" or "x86" or "disassembl*"/"assembl*"). The only related public PR (#643) targets a
different capability (reporting instruction offsets for rewritten instructions to instrumentation
callers) and touches none of the six files this design touches.

**Predicted iteration cycles: 2** (target 1, accept up to 3) — the two-axis trap design is precise
enough to ship close to first draft, but the shared-lifetime bookkeeping in `block.rs` is exactly
the kind of logic likely to need one round of test-fairness review to confirm the N-1 partial-
release fixture is unambiguous and that the address-form off-diagonal cell test is airtight.
