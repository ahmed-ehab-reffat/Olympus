# Add trust accounting and walk termination reporting to the stack unwinder

Add a trust accounting layer to the stack unwinder, and a record of why each walk ended. The region
comes from the stack memory the walk was handed.

Add `StackRegion`, built with `StackRegion::new(base, end)` and queried by `contains`: the low
address is inside, the high address is not.

A frame found by scanning is a guess, so when its address falls where the module publishes unwind
information, raise it to `FrameTrust::CfiScan`, token `cfi_scan`, sitting between `Scan` and
`FramePointer`. Only scanned frames are candidates. If such a frame is then found off the stack, the
raised value, not the unwinder's original, is remembered as its claim.

Add `trust_degraded`, `claimed_trust` and `degrade_reason` to each frame. `claimed_trust` holds a
frame's trust before any reduction, so an unreduced frame reads the same as its current trust.

When a frame the unwinder produced and returned has a stack pointer outside the region, keep it in
place but record it at the weakest recovered trust and mark it reduced even when it was already
worth no more than that. `claimed_trust` holds its earlier value, and `degrade_reason` is a
`DegradeReason`, whose only cause is `OutsideStackRegion`, token `outside_stack_region`.

Walking a thread twice gives the same frames, termination and reduction count.

Stop the walk before recording a second reduced frame. Stop it as well once it has recorded 1024
frames, and report that as `FrameLimit`.

Add a way for a symbol file to declare that a range of code has no caller, written as `.ra: .undef`
in a CFI record. A return address rule in a later record replaces an earlier one rather than joining
it, whether the earlier was the INIT or another delta. A single record that declares no caller and
also computes one contradicts itself and is discarded, leaving the walk to unwind normally.

A walk reaching a declaration ends there even when another strategy could produce a frame, and this
outranks the region rules: a declared ending is clean, and nothing about it counts as reduced trust.

Add `WalkTermination` to record why a walk ended, with `Exhausted`, `LeftStackRegion`,
`NoStackMemory`, `FrameLimit` and `EndOfStack`, whose `as_str` tokens are `exhausted`,
`left_stack_region`, `no_stack_memory`, `frame_limit` and `end_of_stack`. Give it a human-readable
`description`. Its `is_truncated` is true only for `LeftStackRegion` and `FrameLimit`.

Expose it as `CallStack::termination`, and set `CallStackInfo::WalkTruncated` only when a walk was
cut short, so a walk that merely reduced a frame, ended at a declaration, or never had stack memory
stays `Ok`. A thread with no usable stack memory is not a containment failure.

Add `CallStack::is_truncated`, `degraded_frame_count`, `trusted_prefix_len` counting frames before
the first reduced one, and `degrade_reason_counts` tallying reasons by token.

Surface the termination and the per-frame reduction in the processed output and in the text
`CallStack::print` writes, each only where there is something to say: a walk that ended plainly and
reduced nothing carries neither. The text names the reduction by its reason token and by the frame's
claimed trust description. The processed output, whose threads are these call stacks, names the
walk-wide summaries `degraded_frame_count`, `trusted_prefix_len` and `degrade_reasons`, and carries
them only once some frame has been reduced.
