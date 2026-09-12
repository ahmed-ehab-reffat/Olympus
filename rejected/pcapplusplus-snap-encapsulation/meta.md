Title: Add IEEE 802.2 SNAP encapsulation support

Add a `SNAP` protocol type and a `SnapLayer` for the five-byte IEEE 802.2 Subnetwork Access Protocol header. Expose the packed `snap_header` with a three-byte OUI and a network-order 16-bit protocol identifier. `SnapLayer(uint32_t oui, uint16_t protocolId)` creates a header, using the low 24 bits of `oui`.

Expose `snap_header* getSnapHeader() const`, `uint32_t getOui() const`, `void setOui(uint32_t oui)`, `uint16_t getProtocolId() const`, `void setProtocolId(uint16_t protocolId)`, and `static bool isDataValid(const uint8_t* data, size_t dataLen)`. The getters and setters use host-order integers while the encoded header remains in network byte order. Data is valid when it is non-null and contains the complete five-byte header.

An LLC payload is SNAP only when DSAP and SSAP are both `0xaa`, the control byte is `0x03`, and the complete SNAP header is present. Near signatures and truncated headers remain ordinary LLC payload.

For OUI zero, interpret the protocol identifier as an EtherType and use the existing parsers for IPv4, IPv6, ARP, VLAN (`0x8100` and `0x88a8`), PPPoE discovery, PPPoE session, MPLS, and Wake-on-LAN. If the selected parser rejects the payload, keep it as a `PayloadLayer`. Other identifiers and nonzero OUIs remain opaque payload after the SNAP header, even when their numeric identifier matches a supported EtherType.

For Cisco OUI `0x00000c` and protocol identifier `0x010b`, pass valid BPDU payloads to the existing STP parser. Other Cisco identifiers and the same identifier under another OUI remain payload.

`computeCalculateFields()` sets OUI zero and the corresponding protocol identifier for the supported standard next layers. For an STP next layer it sets Cisco OUI `0x00000c` and protocol identifier `0x010b`. Unknown next layers leave the encoded values unchanged.
