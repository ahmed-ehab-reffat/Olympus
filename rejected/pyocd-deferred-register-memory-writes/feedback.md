# pyocd-deferred-register-memory-writes - feedback

Status: DEAD 2026-10-05 (machinery-absorbed UNDER-FLOOR at the measure-first spike). Never a problems/ folder.
Factory SLICE run, tried as FALLBACKS[0] after teavm-incremental-fact-reuse died the same way.

Lane K from hunt h53 (`worktrees/_hunt/s_1005h53/dossier_pyocd_h53.md`): option `cache.write_back`;
`CachingDebugContext` holds core-register and cacheable-memory writes until PRE_RUN (own core: registers;
any core: memory), PRE_RESET (drop registers, commit memory), PRE_DISCONNECT, PRE_FLASH_ERASE/PROGRAM or
`flush()`; reads see pending values; each physical register written at most once per commit.

Spike (solution.patch, base develop ce6386fc, not executed): physical normal form with CFBP byte-lane and
XPSR psr_mask folds, D/S split and D composition from pending S halves, SP family committed then written
through, batched commit with reset-and-raise on failure, `_check_cache` commit/drop, memory dirty
IntervalTree coalesced with `merge_overlaps` and written from the cache tree, non-cacheable barrier on read
and write, `DebugContext.flush()` delegation (so an ElfReaderContext wrapper forwards it), commit at the top
of `BreakpointManager._pre_run_handler` (it subscribes before the context exists), option wiring.

Hook: **132 human-effective**, 150 raw, 7 files. Hunt priced ~237 (210-260).
Absorbed: the existing `_cache` dict serves overlay reads once the fold keeps it coherent; the interval tree
already holds written bytes, so the buffer is a dirty-range tree plus `_merge_data`; gdbserver flash and
detach are covered by the flash and run notifications. No honest scope reaches 200.

Not run because the lane died first: Gate 1 probe, SIX-CHECK, PR-DIFF re-check, venv/Docker, tests.
Quota note for later: this would have been a third pyOCD sub while pyocd-dwt-watchpoint-planner is in flight.
