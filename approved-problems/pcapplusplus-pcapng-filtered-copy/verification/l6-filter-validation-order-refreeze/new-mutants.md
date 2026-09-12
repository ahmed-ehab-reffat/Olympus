# L6 isolated mutants

Stable active mutants 1-25 and 27-31 were restored one at a time from the
exact L6 reference. All 30 rebuilt and returned nonzero from the focused
suite. Historical ID 26 remains retired because accepting a nonzero SHB minor
version is correct under the repository-supported policy.

Three L6 additions came directly from public requirements and `agent-runs4/`:

1. `nonconst_only_api` removes `const` from both declaration and definition.
   The production `Pcap++` target builds, while `PcapNgCopyTest` fails to
   compile at the const-reference call in `StructureAndFiltering`.
2. `reject_identical_path` returns `false` when the output spelling equals the
   reader input spelling. It builds and fails only `InPlaceReplacement`.
3. `validate_discarded_epb_options` restores L5's overstrict validation order
   by parsing EPB options before honoring a negative filter result. It builds
   and fails only `DiscardedPacketOptions`.

The same-path fixture deliberately contains no DSB, so it does not reproduce
the established DSB-options failure. The discarded-options fixture has valid
outer framing, fixed EPB fields, interface reference, packet lengths, and
packet-data bounds; only the option area of a UDP EPB rejected by the active
TCP filter is malformed. The exact reference passes all 16 after restoration.
