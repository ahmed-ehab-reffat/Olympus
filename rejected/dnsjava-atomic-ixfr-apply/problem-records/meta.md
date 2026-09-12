Title: Apply incremental zone transfers atomically

Add a public `void Zone.applyIXFR(ZoneTransferIn transfer)` operation that runs
the supplied transfer and applies an IXFR response to the existing zone as one
atomic update. The transfer must name the same origin as the zone. An up-to-date
response is a no-op; reject an AXFR response or fallback without changing the
zone.

Validate the complete IXFR chain before publishing it. It must begin at the
zone's current SOA serial, every delta's delete and add sections must begin with
the corresponding apex SOA and agree with its declared start and end serials,
adjacent deltas must be continuous, and serial advancement must follow RFC 1982.
Apply each delta's deletions before its additions. Every record must use the
zone's class and lie within its origin, and every requested deletion must match
a record present in the staged state. The final records must form a valid zone
with exactly one apex SOA and at least one apex NS record.

On success, SOA and NS accessors, exact and wildcard lookups, ordinary and
signed RRsets, iteration, and master-file output must all reflect the final
record set. Do not mutate the transfer's delta lists or records. If transfer,
validation, or application fails, preserve the complete observable pre-call
state. An individual read performed concurrently with application may observe
the complete old or complete new value, but never a partially applied RRset;
this does not require separate read calls or weakly consistent iterators to
share one generation.
