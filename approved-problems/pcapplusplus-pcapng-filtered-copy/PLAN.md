# PLAN - L6 PcapPlusPlus PCAPNG filtered copy

Status: `completed; exact L6 accepted on 2026-08-01`.

1. Retire L5 at 7/10 because its exact unhinted batch exceeds the 50% cap.
2. Preserve the fair L5 contract, including major-version compatibility and
   the 14 existing scenario entities.
3. Enforce the exact `const` API by calling through a const reader reference.
4. State and test successful replacement when source and destination use the
   same path spelling, with a DSB-free fixture that isolates publication.
5. Add `DiscardedPacketOptions`: validate a rejected EPB's fixed fields and
   packet bounds without parsing its unretained option area.
6. Move reference EPB option validation after a successful filter match.
7. Replay all ten L5 solutions. Accept the observed 2/10 projection: five
   former passes fail only the new validation-order boundary, two still pass,
   and the three existing failures retain independent DSB/multi-section gaps.
8. Verify all patch states, both patch orders, the complete upstream
   inventories, clang-format, Dockerfile prefix, and Python 3.8 conversion.
9. Run and record the exact 33-active-mutant false-positive audit.
10. Freeze the hashes in `DESIGN.md` and the L6 verification record. Any
    further artifact edit abandons this version and restarts calibration at
    0/10.
