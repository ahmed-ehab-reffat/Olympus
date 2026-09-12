# Solution approach - section-aware PCAPNG filtered copy

The implementation adds one source-compatible method to
`PcapNgFileReaderDevice` and uses the reader's existing BPF state. It does not
change the ordinary packet reader/writer path or expose LightPcapNg records.

## Section scanner

The method reads the plain input file before opening the destination, then
walks its PCAPNG blocks in physical order. A Section Header Block establishes
the current byte order, validates the supported major version as 1, preserves
the minor version, resets the local interface vector, and starts new finite-length accounting. Every
block's leading and trailing length is validated using that section's byte
order.

Interface Description Blocks append their link type and snapshot length to the
current section-local vector. Their reserved field is ignored as required for
readers, and the original block is retained unchanged. Because all IDBs are
retained in order, Interface IDs never need rewriting.

## Retained-block framing

Before retaining a standardized block, the scanner validates its public inner
framing. Options are walked as block-bounded Type-Length-Value fields with
32-bit padding. A list may end at the block boundary without an explicit
end-of-options marker; when a marker is present, it must be the final field.
Name Resolution records are walked with the same padded-length rule until their
required terminator, after which their options are validated. Decryption
Secrets data is bounded and padded before its option area begins.

The scan is structural only. It does not interpret or rewrite option payloads,
so copyable and do-not-copy Custom Options inside a retained block remain
byte-for-byte unchanged.

## Packet selection

Enhanced Packet Blocks validate their local Interface ID, captured/original
lengths, and packet bounds. The existing BPF wrapper evaluates their captured
bytes with the referenced interface's link type. The option area is validated
only when the EPB matches and will be retained; a rejected EPB is omitted
without interpreting its discarded options. Simple Packet Blocks use local
Interface ID 0 and its snapshot length. The wrapper's established empty filter
behavior matches every packet, including before a filter is set and after it is
cleared. A matching packet block is copied as raw bytes; a non-matching block
is omitted.

Copying accepted blocks instead of reconstructing packets preserves raw
timestamp ticks, padding, comments, and every known or unknown option without
normalization.

## Other blocks and output

Interface Statistics Blocks validate their section-local interface reference.
Standardized do-not-copy Custom Blocks are omitted. Every other supported
non-packet or unknown block—including local-use block types—is copied as raw
bytes without interpreting its opaque payload, preserving padding, options,
and retained order.

Finite section lengths are rewritten to the number of retained bytes following
their SHB. Unspecified lengths remain `-1`. Obsolete Packet Blocks are rejected
because copying them would bypass filtering and the current public reader does
not support them.

Only after the complete source validates does the method open and truncate the
destination. Because the input is consumed first, the same path can safely be
used as source and destination. Output I/O errors follow existing file-device
logging and return `false`. The reader's LightPcapNg handle and current packet
position are never touched, so the operation behaves identically before open,
while open, and after close.

The reference adds 254 raw production lines across the public declaration and
implementation, of which 232 are non-comment, non-blank additions under the
strict package counter.
