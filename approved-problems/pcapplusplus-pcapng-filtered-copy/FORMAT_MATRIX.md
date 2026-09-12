# FORMAT_MATRIX - section-aware PCAPNG filtered copy

## Pinned primary specification

Primary format authority:
[`draft-ietf-opsawg-pcapng-05`](https://www.ietf.org/archive/id/draft-ietf-opsawg-pcapng-05.txt),
17 March 2026, SHA-256
`43f522a9c61057cb93887f99f78ecd36290d1911a920578947322fd20459022d`.

Every block has a type, a total length repeated at the end, and 32-bit
alignment. Numeric fields and option code/length pairs follow the owning
section's byte order. Options are 16-bit type/length/value records padded to a
32-bit boundary. Writers emit `opt_endofopt`, but readers must also accept an
option list whose final padded field reaches the block boundary. Unknown block
types are skippable. A new SHB may switch byte order and resets the Interface
ID namespace.

The investigated contract is keep/drop only. Every accepted packet block and
every retained non-packet block is copied byte-for-byte, including padding and
unknown options, except that a finite SHB section-length field is recomputed
after drops. Block order among retained blocks is unchanged.

## Block decisions

| Block / scope | Endian, options, and references | Pinned implementation behavior | Investigated output decision |
|---|---|---|---|
| Section Header Block / section | Byte-Order Magic establishes byte order; major/minor version fields and signed 64-bit section length are endian-sensitive; length excludes the SHB; `-1` is unspecified; SHB options follow | High-level writer synthesizes one little-endian section; Light reader stores both version fields and does not reject arbitrary minor values | Require supported major version 1; retain every SHB, minor value, byte order, options, and `-1`; if finite, rewrite only its length to the retained content byte count |
| Interface Description Block / section-local interface | Link type, snap length, and option headers are endian-sensitive; the reserved field is ignored by readers; physical order assigns IDs starting at 0 per section; options include name, description, filter, `if_tsresol`, `if_tsoffset`, and unknowns | Public reader exposes packet link type and aggregate metadata, not raw IDBs/options; writer groups/synthesizes IDBs | Ignore the reserved field while validating, but retain every IDB byte-for-byte and in order. Because no IDB is pruned, IDs do not change and no remapping work is honest |
| Enhanced Packet Block / packet | Interface ID is local to section; timestamp high/low are raw ticks under the IDB resolution/offset; captured/original lengths, padding, and option TLVs are endian-sensitive; options include comment, flags, hash, drop count, packet ID, queue, verdict, and unknowns | Reader converts timestamp and exposes only packet/comment; writer fixes interface ID at the C++ boundary and rebuilds the block | Validate local reference and lengths, apply existing BPF to captured bytes using that IDB's link type, then copy the entire block unchanged or omit it |
| Simple Packet Block / packet | Implicitly uses local Interface ID 0; original length and IDB snap length determine captured bytes; no timestamp/options | Light exposes it as a packet but does not provide section-safe mixed-endian handling | Require local IDB 0, apply BPF using its link type and snap length, and copy or omit the whole block |
| Name Resolution Block / section | Records and option TLVs are endian-sensitive; padded records end with the required zero-type/zero-length terminator | Public packet reader skips it; Light can keep it only as a raw/known record | Validate bounded padded records through the terminator and bounded options, then retain byte-for-byte and in relative order |
| Interface Statistics Block / interface | Interface ID is section-local; timestamp/options are endian-sensitive | Public reader skips it; Light's aggregate interface handling does not reset safely across sections | Validate the local ID exists, then retain the whole block byte-for-byte and in order |
| Decryption Secrets Block / section | Secrets type/length and option TLVs are endian-sensitive; padded secrets payload is opaque | Public reader skips it; current bundled parser does not offer a preservation API at C++ level | Bound and pad the secrets area, validate following option framing, then retain byte-for-byte and in order |
| Custom Option inside a retained standard block | Copyable codes 2988/2989 and do-not-copy codes 19372/19373 contain a PEN plus opaque data | Public packet APIs do not preserve the containing raw block | Apply only ordinary TLV boundary validation; retain either policy byte-for-byte without interpreting or removing it |
| Copyable Custom Block `0x00000BAD` / section | PEN is endian-sensitive; remaining custom data is private and opaque | Not named by bundled LightPcapNg; a generic raw branch can retain it | Retain the complete block byte-for-byte and in order |
| Do-not-copy Custom Block `0x40000BAD` / section | Same opaque layout, but the type is standardized to prohibit copying by a rewriting application | Not distinguished by bundled LightPcapNg | Omit the complete block |
| Unknown ordinary block / section | Only framing is known; payload must not be byte-swapped or interpreted | Light often represents it as a raw block; public C++ packet APIs skip it | Retain the complete block byte-for-byte and in order |
| Local-use block / section | A type with the high-order bit set is locally assigned; other readers have no payload schema | A solver may recognize a private-looking numeric type accidentally | Treat it as an unknown opaque block: validate only outer framing and retain it byte-for-byte |
| Obsolete Packet Block type 2 / packet | Refers to a local interface and has legacy drop-count/length fields | Current public reader and writer do not support it | Explicitly reject the input as unsupported; do not silently preserve an unfiltered packet |
| Multiple sections / file | Every SHB resets byte order and local Interface IDs; sections may independently use finite or unspecified length | Current Light extended metadata/interface state is first-section/file-oriented | Reset byte order, IDBs, finite-length validation, and output-length accounting at each SHB |

## Public scope and exclusions

- Retain all IDBs. Interface pruning, compaction, and remapping are excluded.
- Packets can only be kept or dropped. Editing, replacement, anonymization,
  merging, and timestamp normalization are excluded.
- Accepted blocks are byte-preserved; semantic reconstruction is not an
  alternative promise.
- Standardized do-not-copy **Custom Blocks** are removed. Raw retained blocks
  keep all their options unchanged; the operation does not interpret or strip
  do-not-copy Custom Options embedded in otherwise retained blocks. Promotion
  would have to state this distinction publicly.
- Plain, uncompressed PCAPNG only. Zstd input/output and generalized repair
  are excluded.
- Block framing, SHB byte-order/major-version/finite length, packet lengths,
  EPB/ISB local references, SPB IDB 0, and public option/NRB-record boundaries
  in retained standardized blocks must be structurally valid. Private payloads
  and unknown options are deliberately not semantically validated.
- Validation completes before opening/truncating the destination. Atomic
  publication is not promised; an output I/O failure follows existing
  file-device behavior.

## Semantic families versus fixture volume

There are thirteen meaningful implementation decisions:

1. section reset and finite-length accounting;
2. IDB collection plus local packet/statistics reference validation;
3. EPB/SPB BPF keep/drop;
4. raw-copy default with the one standardized complete-block do-not-copy
   exception;
5. block-bounded, padded option and NRB-record framing in retained standardized
   blocks;
6. block-end completion as a valid option-list endpoint;
7. evaluation through the reader's actual current BPF expression;
8. the empty/default BPF state matching every packet;
9. reader-side opacity for the IDB reserved field; and
10. opaque treatment of local-use block payloads;
11. const-qualified public API compatibility;
12. safe publication when input and output have the same path spelling; and
13. option validation after packet selection, so only retained EPB option
    areas are interpreted.

Opaque payload preservation, Custom Option policy, and accepted packet fidelity
still fall out of decision 4. Decision 5 adds structural validation only; it
does not turn each option code or payload into a separate semantic decision.

L3 makes two previously collapsed acceptance decisions observable: block-end
termination is a valid option-list endpoint, and the current BPF expression is
not fixed to the historical `tcp` fixture. Its malformed probes also cover
the distinct SPB length equation and every standardized option-area entry
point used by the retained block families.

L4 states decision 6 explicitly and makes decisions 8–10 observable. The
empty-filter case closes a public state edge without differentiating the three
reviewed solvers. The IDB and local-use cases provide separate opacity
boundaries and do not define semantics for reserved or private bytes.

L6 makes decisions 11–13 observable. Decisions 11 and 12 close review gaps but
all ten L5 patches already satisfy them. Decision 13 is the trajectory-backed
split: a rejected EPB still needs safe fixed-field and packet-data bounds, but
its unretained option bytes are not parsed. The same-path fixture is DSB-free,
so it does not duplicate the existing secrets-option failure family.
