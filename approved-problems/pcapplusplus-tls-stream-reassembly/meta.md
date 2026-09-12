Title: Add TLS framing over reassembled TCP streams

Add a `TlsReassembly` wrapper around `TcpReassembly` that emits complete TLS records and plaintext handshake messages independently of TCP callback and TLS-record boundaries.

`TlsReassemblyConfiguration(size_t maxRecordPayloadSize = 18 * 1024, size_t maxHandshakeMessageSize = 0xffffff)` exposes both parameters as public fields with those names. `TlsRecordData` exposes type, version, full bytes, payload, connection, and precise timestamp; `TlsHandshakeData` exposes type, full bytes, payload, and connection. Full bytes include the five- or four-byte header, and unknown handshake types remain opaque. Name these getters `getRecordType()`, `getRecordVersion()`, `getHandshakeType()`, `getData()`, `getDataLength()`, `getPayload()`, `getPayloadLength()`, `getConnectionData()`, and `getTimeStampPrecise()` as applicable. The first three return `SSLRecordType`, `SSLVersion`, and `SSLHandshakeType`, respectively. Connection getters return `const ConnectionData&`, callback byte pointers remain valid during the callback, and a record's timestamp comes from the TCP callback that completes it.

`TlsReassemblyEvent` reports `TcpDataMissing`, `InvalidTlsData`, and `IncompleteDataOnConnectionEnd` through `getType()`, `getMissingByteCount()`, `getDiscardedByteCount()`, and `getConnectionData()`. The record, handshake, and event callbacks receive direction, callback data, and user cookie. The constructor takes the record callback and cookie first, followed by optional handshake, event, connection-start, and connection-end callbacks, then TCP and TLS configurations. Only the record callback is required.

Mirror `TcpReassembly` packet ingestion, connection management, status returns, and cleanup.

Recognize records by a five-byte header on any port: type 20 through 23, version `0x0300` through `0x0303`, and a network-order 16-bit payload length that is nonzero and no greater than the configured maximum. Discard bytes before a plausible header with `InvalidTlsData`, but retain an incomplete candidate header for later completion. Preserve exact record bytes and order across arbitrary TCP segmentation and coalescing, with independent state per connection direction.

For handshake records, join plaintext payloads and decode a one-byte type plus a network-order 24-bit payload length. Emit each complete message separately, including messages larger than 65,535 bytes; retain incomplete messages across later handshake records and intervening non-handshake records. Reject over-limit messages as `InvalidTlsData` without affecting another connection. Discard the complete declared message across later handshake records before looking for another handshake header. A rejected inner handshake does not suppress its complete TLS-record callback.

Treat configured limits literally. With a zero record maximum no nonempty record payload is valid; with a zero handshake maximum only a zero-length handshake payload is valid. Report captured bytes discarded because of either limit through `InvalidTlsData`.

When TCP reports a gap, emit `TcpDataMissing` with the numeric gap size even if no TLS bytes are buffered, discard and report the affected direction's partial record and handshake bytes, and resynchronize on later captured data. Do not derive invalid events or protocol messages from TCP's synthetic missing-data marker or by joining bytes across the gap.

On connection close, emit one `IncompleteDataOnConnectionEnd` event per affected direction with the combined discarded record and handshake bytes, release that connection's TLS state, then forward the connection-end callback.
