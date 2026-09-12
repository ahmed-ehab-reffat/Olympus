# REPO_MAP - PcapPlusPlus PCAPNG filtered-copy seams

## Public C++ packet path

`Pcap++/header/PcapFileDevice.h` defines `IFileReaderDevice`, its existing
`setFilter()` vocabulary, `PcapNgFileReaderDevice`, and
`PcapNgFileWriterDevice`. The reader can return `RawPacket` plus one packet
comment. It does not expose section boundaries, raw timestamp ticks, Interface
IDs/IDBs, arbitrary packet options, or non-packet blocks.

In `Pcap++/src/PcapFileDevice.cpp`:

```text
PcapNgFileReaderDevice::open
  -> light_pcapng_open_read
  -> metadata copied from LightPcapNg extended-file info

PcapNgFileReaderDevice::getNextPacket[Internal]
  -> light_get_next_packet
  -> RawPacket(timestamp converted to timespec, packet bytes, link type)
  -> BPF match

PcapNgFileWriterDevice::writePacket
  -> light_write_packet
  -> C++ boundary supplies interface_id = 0
  -> LightPcapNg chooses/synthesizes IDBs and EPBs
```

`PcapSplitter` already demonstrates the repository-native file/filter loop,
but each output is a new `PcapNgFileWriterDevice`. It is the closest baseline,
not a format-preserving implementation.

Reader/writer objects own their Light handles, close them in destructors, and
are non-copyable. BPF state belongs to the device; no global callback is
needed. `BpfFilterWrapper::matches()` explicitly accepts every packet when its
stored filter string is empty, and `IFilterableDevice::clearFilter()` restores
that state.

## Bundled LightPcapNg

| Location | Relevant behavior |
|---|---|
| `light_pcapng.h`, `light_pcapng_ext.h` | Raw record/list read/write, opaque block inspection, extended packet reader/writer |
| `light_internal.h`, `light_pcapng.c`, `light_io.c`, `light_internal.c` | Known-block decoding, raw block storage, linked-list ownership, length serialization; record reader has a byte-order TODO and interprets known fields in host order |
| `light_manipulate.c` | `light_subcapture()` copies a root plus predicate-selected list nodes, then validates; it is the strongest tempting shortcut |
| `light_pcapng_ext.c` | Builds file metadata from the first SHB, accumulates interfaces across the file, scales timestamps, returns comments, and synthesizes writer interfaces |
| `light_special.h` | Defines SHB, IDB, EPB, SPB and private custom structures, but not standardized `0x00000BAD` / `0x40000BAD` policy |
| `current_commit.git` | Records standalone upstream snapshot `33296580096f83a9f17ebe7ea3d2c79977a24471` |

Unknown blocks generally survive in the whole-list representation as raw
bodies. However, the current list parser cannot safely traverse the audit's
opposite-endian second section. `light_subcapture()` also treats its root as
one capture-wide section and its section-length calculation includes the SHB,
contrary to the pinned draft. Extending this route completely would be a
material C change.

The Section Header parser stores both major and minor version fields in
`light_pcapng_file_info`, and the writer reuses both values. It does not reject
minor versions other than zero. The filtered-copy contract therefore validates
the supported major version and preserves the minor field rather than imposing
an exclusive 1.0 reader policy.

No new C API is needed for the smaller successful route: C++ can read the file
bytes directly, use existing `BpfFilterWrapper`, and write retained raw blocks.
This avoids leaking LightPcapNg types or relying on a C callback lifetime.

## Tests and build

`Tests/Pcap++Test/Tests/FileTests.cpp` covers PCAPNG reader/writer factory
selection, packet round trips, comments and capture metadata, multiple link
types/interfaces, micro/nanosecond precision, append, BPF filters, and optional
Zstd. Existing top-level PCAPNG fixtures are single-section captures and do
not test raw structure preservation or mixed section byte order.

The test runner marks offline-safe cases with `no_network`; PCAPNG cases also
have the `pcapng` tag. In this runner, `-n -t pcapng` selects the union rather
than the intersection. The full CMake test target builds Packet++ and Pcap++
tests. Root `AGENTS.md` requires C++14, Doxygen public API documentation,
RAII, and clang-format 19.1.6.

## Public API alternatives

| Alternative | Surface and filter | Ownership/lifecycle | Result |
|---|---|---|---|
| Specialized reader operation | Add `bool PcapNgFileReaderDevice::copyFiltered(const std::string&) const`; caller configures existing BPF with `setFilter()` | Device owns filter expression/state; method opens its own input/output streams, is independent of `open()` and current read position, validates before destination truncation | Selected for cheapest-complete prototype; one additive method, no C types |
| Public block/event model | Add C++ section/block reader, opaque blocks, packet variants, and writer/visitor callbacks | Would need new variant ownership, callback/error rules, and section-aware writer lifecycle | Rejected as unjustified generalization; repository has no public block clients |
| C++ wrapper over Light whole-list/subcapture | Add one high-level method and adapt Light predicate/list serialization | C list owns records; callback requires C-compatible state; parser must become section/endian safe | Smaller wrapper, but complete behavior materially requires unsupported vendored C |

The specialized method preserves source compatibility because it is additive.
It uses the existing BPF expression rather than introducing a callback or
packet-edit API. A packet is either copied byte-for-byte or omitted. EPB uses
its local IDB link type; SPB uses local IDB 0 and snap length. Unknown blocks
remain opaque, including locally assigned block types. Reader-side validation
also ignores the IDB reserved field while raw copying preserves its bytes.

The prototype contract is plain uncompressed input/output only. It validates
the entire input before opening the destination, logs and returns `false` for
input or output errors, and does not promise atomic destination replacement.
It can overwrite the same path safely because input bytes are fully resident
before writing. EPB fixed fields and packet-data bounds are needed to invoke
the filter safely; its option area is only part of retained standardized-block
validation after a positive match. No current file-device caller changes
behavior.

## Ownership and history boundary

The proposed public and implementation files are PcapPlusPlus-owned C++ under
the root Unlicense. LightPcapNg is an MIT vendored C dependency. Its standalone
origin, later PcapPlusPlus fork, and independent active fork are mapped in
`UPSTREAM_AUDIT.md`; none supplies this feature. The language boundary is
nevertheless decisive against using a LightPcapNg repair as the expected
solution.
