# feedback.md — iced-x86-pointer-data-dedup

## Status
**SHELVED 2026-08-22 — machinery-absorbed, under the 200-effective-LOC floor.** Fully built,
tested, and locally validated (Dockerfile, test.patch, solution.patch, meta.md all produced and
verified), then shelved at the pre-submit LOC gate rather than submitted. See "Round 1 — Full
build + LOC gate" below for the full account. Kept in `rejected/` per the too-easy shelving rule;
see `Instructions/TOO-EASY.md` for the death-class writeup.

## Attempt history

### Round 0 — Design
- Repo: icedland/iced (Rust, MIT, pure, no CGO/-sys deps)
- Candidate search: 3 repos evaluated before scope-lock.
  - tombi-toml/tombi — rejected. Target gap (linter ordering rules not respecting schema-level
    order overrides) sits in a lane with a dozen+ recent merged PRs (#1830, #1741, #1748, #1750).
  - It4innovations/hyperqueue — rejected. Two dead lanes found: core MILP scheduler under active
    rewrite (#1080 + ongoing #1116-1129), and the resource-capacity/task_max_count gap is consumed
    directly by the currently-open PR #1129 rewriting scheduler/batches.rs.
  - icedland/iced — selected. Near-zero recent commit/PR activity in block_enc; the one nearby
    open PR (#643) targets a distinct capability (instrumentation offset reporting) confirmed via
    diff read, no file overlap.
- Feature: deduplicate pointer-data slots in BlockEncoder's 64-bit long-branch trampoline when
  multiple relocated branches share a final target. See DESIGN.md for full spec.

### Round 1 — Full build + LOC gate
- Implemented the dedup mechanism exactly per DESIGN.md: `Block::alloc_pointer_location` keyed by
  a new `TargetKey` (Instruction-index or fixed-address), reference-counted release via
  `Block::release_pointer_location`, call-site updates across all 4 pointer-data-using `Instr`
  impls (call/jcc/jmp/simple_br). Compiled clean, all 126 pre-existing `block_enc` tests passed
  unchanged.
- Wrote 7 new tests (`block_enc/tests/pointer_data_dedup_0ae544.rs`, hex-suffixed per the banned-
  marker rule) covering both target forms (relocated-instruction and fixed-external-address),
  cross-block sharing, no-over-merge negatives, a single-branch baseline, and a boundary case
  where a near-form branch sharing the same numeric target does not join the slot. All byte
  fixtures generated via a throwaway `cargo run --example` harness using the patched encoder as
  oracle (verified independently against hand-derived expected reloc counts, not trusted blindly).
- **First LOC measurement: 60 effective (Counter 1) across 6 files.** Far under the 200 floor.
  Confirmed via the pre-submit `grep`-based check in `CLAUDE.md`.
- **FP mutation testing (mandatory gate) surfaced a real coverage gap early:** mutating
  `release_pointer_location` to unconditionally invalidate (removing the reference count entirely)
  passed all 133 tests. Root cause, confirmed by exhaustive code-path analysis: the release path
  (a slot allocated then later found not to need Long form) is only reachable for `Address`-form or
  cross-block `Instruction`-form targets, and `correct_diff` (block_enc/instr/mod.rs:60-67) only
  applies the `gained` convergence adjustment when `is_in_block` is true — meaning these targets'
  Long/Near/Short determination is decided once in the first optimize() pass and never changes
  across the remaining iterations in any construction not requiring an artificially deep,
  multi-level shrink-dependency chain before the target. Two more mutations (disable each half of
  `TargetKey`, and an "always merge regardless of key" over-merge) WERE correctly caught — the
  form-parity trap is solid; the reference-counting trap is not exercisable with a
  reasonably-sized fixture in this codebase.
- **Two genuine, tested scope expansions attempted to close the LOC gap** (both real, both kept in
  the final diff, neither sufficient alone):
  1. `pointer_data_sharer_counts: Vec<u32>` on `BlockEncoderResult`, parallel to `reloc_infos`.
  2. `pointer_data_indices: Vec<Option<u32>>` — per-instruction correlation to a slot's final
     `reloc_infos` position, requiring a genuine second piece of machinery (`BlockData::index` +
     `Block::remap_pointer_data_index`) since an instruction's *encode-time* raw allocation index
     does not equal its *final* position once earlier slots can be excluded — the `Instr` trait
     signature itself had to change (`Result<(ConstantOffsets, bool), IcedError>` ->
     `Result<(ConstantOffsets, bool, Option<u32>), IcedError>`) across all 7 `Instr` impls
     (call/jcc/jmp/simple_br/simple/xbegin/ip_relmem), correctly caught a real design bug along the
     way (initially gated the new field on the wrong `BlockEncoderOptions` flag, which would have
     silently reported `None` for every entry when only `RETURN_NEW_INSTRUCTION_OFFSETS` was set
     without `RETURN_RELOC_INFOS`).
  - **Final measurement after both expansions: 126 effective (Counter 1) across 10 files.** Still
    under 200, and Counter 2 (the actual gate, strips imports/braces/punctuation on top of
    blank/comment) would read lower still.
- **Decision: shelved rather than pad further.** A third expansion angle (constructing a fixture
  that actually exercises the reference-counted release path, which would have both closed the FP
  gap above and organically added LOC) was analyzed in depth and confirmed structurally
  unreachable without disproportionate, fragile engineering (see the mutation-testing bullet).
  Every other considered angle (a new `BlockEncoderOptions` bit — blocked, that enum is
  generator-managed per `.claude/rules/generated-artifacts.md`; extending the currently-unsupported
  `IpRelMemOpInstr::Long` case — real but high-risk register-allocation semantics, not verifiable
  without deep additional study) was rejected as either off-limits or too risky to ship without
  much more validation time than remained. Padding with dead code or speculative guards was ruled
  out per `CLAUDE.md`'s explicit prohibition. Per `CLAUDE.md`'s too-easy shelving rule, this class
  (repo's existing architecture already provides the exact right shape) is recorded in
  `Instructions/TOO-EASY.md` as a machinery-absorbed case and the folder moved to `rejected/`.

## Deliverables (kept for reference, NOT a submission)
All 5 files are complete and were locally validated end-to-end before the shelving decision:
apply/unapply in both orders from a clean BASE_COMMIT checkout, `base`/`new` test.sh modes both
correct (614/7 testcases respectively), 3x determinism check identical, 3 FP mutations run (2
caught, 1 not — see above). The only unresolved gate is the LOC floor.
