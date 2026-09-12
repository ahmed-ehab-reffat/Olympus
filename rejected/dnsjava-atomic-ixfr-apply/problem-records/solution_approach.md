# Solution approach

Run the supplied transfer and reject response modes outside the method's public
scope. For IXFR, take the zone's write lock and copy every ordinary and signature
record into a private canonical record map.

Walk the deltas oldest to newest. For each one, verify that both sections begin
with the corresponding apex SOA, the framing SOAs agree with declared serials,
the start matches the currently staged serial, and `Serial.compare` reports
forward RFC 1982 progress. Validate class and origin for every record, remove
each requested deletion strictly from staged state, then add the new records.

Construct a fresh `Zone` from the final staged records. That reuses existing
SOA/NS validation and rebuilds the repository's cached origin, SOA, NS, wildcard,
RRset, and signature state. Only after construction succeeds, replace the live
zone's base and derived state while the same write lock is held. Do not modify
the transfer's lists or records. Because reception and all staging happen before
publication, every exception leaves the live zone unchanged, and a read-locking
lookup can observe only the complete old or final state.

The map, candidate `Zone`, and wholesale replacement are reference choices, not
participant requirements. An ordered-list candidate, immutable state object, or
another atomic publication mechanism is equally valid if it satisfies the
public behavior.
