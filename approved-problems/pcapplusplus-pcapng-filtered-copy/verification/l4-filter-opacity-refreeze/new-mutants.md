# L4 isolated mutants

Mutants 1-28 are the exact L3 set recorded by
`../l3-option-termination-refreeze/run-mutants.sh`. They were rerun unchanged
against L4 and all compiled and returned nonzero from the focused suite.

The three L4 additions were applied one at a time to a freshly restored
reference:

1. `require_nonempty_filter`: expose the BPF wrapper's stored-expression state
   and return `false` from `copyFiltered()` when it is empty. It compiles and
   fails only `PcapNgCopy.DefaultAndClearedFilter`.
2. `reject_nonzero_idb_reserved`: add a reader-side check that the IDB reserved
   field is zero. It compiles and fails only
   `PcapNgCopy.ReservedFieldOpacity`.
3. `parse_local_use_payload`: recognize `0x80000001` and validate its opaque
   payload as if options began at byte 12. It compiles and fails only
   `PcapNgCopy.LocalUseOpacity`.

The per-mutant CTest logs and `mutation-results.txt` retain the exact results.
The reference was restored, rebuilt, and passed 14/14 after the loop.
