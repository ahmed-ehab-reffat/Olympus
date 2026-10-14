---
Repository: https://github.com/pyocd/pyOCD
Issue: N/A
Commit: 3078bf177cb4d8afc78d4300a459f3c38c5ef238
Language: Python
Category: feature-request
Title: Add range watchpoints and hit reporting to the Cortex-M DWT
---

# Add range watchpoints and hit reporting to the Cortex-M DWT

Add range watchpoints to the Cortex-M DWT. GDB stop replies name the watchpoint that triggered the stop.

A watchpoint is set for exactly the address range from address to address + length - 1 and its watchpoint type. If length is less than 1, `set_watchpoint` returns False without setting a comparator. Minimize comparator use. On DWT v1, comparators can monitor an aligned power-of-two range up to that comparator's own MASK limit (read back after writing 31). On DWT v2, comparators can monitor 1, 2, or 4 aligned bytes, or other ranges using a free pair (an even comparator n specifies the start address, n + 1 the end address using MATCH 0b0111) or, if no pair is free, aligned 1, 2, and 4 byte pieces.

Placement is binary: a watchpoint that doesn't fit returns False and does nothing; a failed register write disables the comparators already written for it and raises that exception. Adding the same watchpoint again succeeds and has no effect. Watchpoints never share comparators. `remove_watchpoint(addr, size, type)` removes all matching watchpoints; None for size or type matches any value.

MATCHED (FUNCTION bit 24) resets when read and appears in one or both comparators of a linked pair; DFSR.DWTTRAP remains set until cleared by a write.

When a watchpoint interrupts the CPU, `GDBDebugContextFacade.get_t_response()` inserts `watch:`, `rwatch:`, or `awatch:` (write, read, or access) and the watchpoint's set address in hexadecimal, plus a semicolon. If several match, only the one set first is named. This output does not change during the interrupt, even if watchpoints are set or deleted. Resuming, stepping, and resetting through `CortexM.reset()` begin a new execution session. An interrupt lists only hits from the session that ended in it.

In the commander, `watch` and `rmwatch` accept any size. `watch` with an ELF data object name and no size watches the entire object; otherwise 4 bytes. `lswatch` first displays `N hardware watchpoint comparators available` (N free) then lists watchpoints in creation order. Hits are reported as `write watchpoint at 0x20000010` (read, write, or access; eight hex digits): `status` appends ` (stopped by <hit>)` to that core's line; `continue` displays `Device is halted; stopped by <hit>` if the core is halted again; and `step COUNT` displays `Stopped by <hit>` and stops.
