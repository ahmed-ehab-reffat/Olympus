# Solution approach

Represent an extension field as a small pointer view with optional shared
ownership, and let the builder hold a validated encoded byte vector. Layer
records have no owner and remain borrowed; `build()` attaches ownership to its
separate allocation. Purging a borrowed record only nulls that view, while
purging a built record releases its ownership without risking layer storage.
The builder computes the padded wire length once, stores type and length in
network order, copies the caller's bytes, and leaves the remaining bytes zeroed.

Centralize NTPv4 tail interpretation in one parser that returns validity, total
extension length, and supported authentication length. Resolve exact field-free
4-, 20-, and 24-byte tails as authentication first. Otherwise walk fields from
the fixed header, stop at a supported authentication remainder after at least
one field, validate every encoded boundary, and require a field-only list's
last record to be at least 28 bytes. Traversal and the existing key/digest
accessors then consume the same interpretation.

Implement insertion and removal with `extendLayer()` and `shortenLayer()` so
the same code works for detached and packet-attached layers. Validate the whole
tail and authentication state before resizing. For insertion, validate the
builder record and the final-field rule before changing storage. For removal,
find the first matching record and refuse removal of the last record when the
new predecessor would be an ambiguous short final field.

Keep layer views deliberately borrowed. Traversal checks that its cursor lies inside
the current layer's parsed extension range before computing the next record,
which rejects null and foreign-layer views. Copying remains the base layer's
deep copy, and mutations naturally invalidate old pointers, so callers
reacquire views after either operation.
