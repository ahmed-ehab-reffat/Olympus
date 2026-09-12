---
Repository: https://github.com/icedland/iced
Issue: N/A
Commit: 8cfc5f57c08fd2e80a4cec9d3d9d36f642b2de31
Language: Rust
Category: enhancement
Title: Deduplicate shared pointer-data slots in the block encoder's long-branch trampoline
---

# Deduplicate shared pointer-data slots in the block encoder's long-branch trampoline

Extend the block encoder's long-branch trampoline so branches that target the same address share one pointer-data slot instead of each getting their own. When `BlockEncoder::encode`/`encode_slice` relocates a block whose 64-bit branch is too far from its target to use a near jump, it falls back to an indirect jump through an 8-byte pointer stored right after the code. Every branch needing this fallback currently gets its own 8-byte slot, even when two or more branches jump to the exact same place, wasting output space and adding a redundant relocation entry per branch.

Two long-form branches share one pointer-data slot whenever they resolve to the same final target, whether that target is another instruction being relocated in the same call to `encode_slice`, or a fixed external address outside the relocated block. Sharing is scoped to one call to `encode_slice`; branches in different, independently relocated blocks never share a slot even with the same target address, since each block's pointer data sits next to its own code. A branch that ends up using the short or near form never joins a shared slot, and never affects the contents of a slot that other branches in the same block share.

A shared slot stays in the output as long as at least one assigned branch still needs the long form once the branch-shortening pass converges; it drops out only once none of them do, exactly as an unshared slot already does. `reloc_infos` holds exactly one entry per distinct shared slot in the output, never one per branch using it, and the stored value is the actual resolved target address.
