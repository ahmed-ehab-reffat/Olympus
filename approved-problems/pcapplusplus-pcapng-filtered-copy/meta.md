Title: Preserve PCAPNG sections during filtered file copies

Add `PcapNgFileReaderDevice::copyFiltered(const std::string& outputFileName) const`. This method uses the reader's current packet filter to write a plain, uncompressed PCAPNG copy containing only matching Enhanced and Simple Packet Blocks. It is independent of whether the reader is open, does not change its current read position, and returns `false` when the input cannot be validated or the output cannot be written.

If `outputFileName` names the input file itself, a successful call replaces it with the filtered result.

Preserve every section, its byte order, and all Interface Description Blocks in their original order. Interface IDs remain local to their owning section. Apply the filter to an Enhanced Packet Block using its referenced interface and to a Simple Packet Block using its implicit Interface ID 0. Copy each accepted packet block byte-for-byte.

Copy retained non-packet blocks byte-for-byte in their original relative order, including Name Resolution, Interface Statistics, Decryption Secrets, copyable Custom Blocks, and unknown block types. Omit complete do-not-copy Custom Blocks whose block type is `0x40000BAD`; options inside otherwise retained blocks are not interpreted or removed.

When filtering shortens a section with a finite declared length, update that Section Header Block's length to the number of retained bytes following the header. Preserve an unspecified section length of `-1`. Validate block framing and trailing lengths, option and Name Resolution record framing in retained standardized blocks, section boundaries and byte-order magic, supported major section version, relevant section-local interface references, and packet lengths before replacing the destination. Obsolete Packet Blocks are unsupported and make the operation fail rather than being copied without filtering.

When reading options, treat the end of the owning block as a valid end of the option list even when no explicit end-of-options marker is present.
