# Solution approach - tifffile OME pyramid validation

Add the validator beside the other `TiffFile` lifecycle and read operations so
it can reuse the OME series, primary page chains, and existing `TiffPage`
parsing without adding a second TIFF parser.

Materialize the OME series first and collect primary IFD identities per owning
file. Record each companion's state, reopen it only while its primary chain and
mapped base plane are inspected, then restore its prior state whether validation
succeeds or fails. Walk every mapped base
plane and its raw tag-330 offsets. For each child, load only its IFD tags and
verify direct reachability, unique ownership, separation from the primary
chain, strictly descending area, base-relative XY reduction, and per-plane
level consistency. Treat
parse failures as an invalid result and apply the existing `assert_` convention
only after validation finishes.

In strict mode, derive the integer factor intervals compatible with independent
floor-or-ceiling division on each axis, then intersect those intervals across
every consecutive XY transition in one image series. This avoids work
proportional to page dimensions while retaining every locally ambiguous factor.
Separately check the reduced-image bit and unchanged axes/nonspatial shape.
Reset the factor ranges for each OME image series.

The implementation reads structure only. It does not decode pixel arrays,
validate XMLSchema, constrain encodings or require matching tile/strip layouts,
or open the file for writing.
