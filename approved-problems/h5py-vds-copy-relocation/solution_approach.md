# Solution approach - h5py VDS copy relocation

Keep the existing `H5Ocopy` path as the default. When the new option is active,
resolve the source object through the same public path/object normalization,
validate that it is a direct virtual dataset, and reject reference expansion
before creating anything in the destination.

Build a fresh virtual dataset creation property list. Copy the persistent
dataset properties that remain meaningful for a VDS, then reproduce every
virtual mapping while resolving its source path from the original VDS file and
expressing that path from the destination file. Absolute mapping names can be
retained verbatim. A `.` mapping resolves to the original VDS file itself.

Explicit source selections can be reused without accessing their source files.
For an all-source mapping, reopen the named source dataset and use its live
dataspace because HDF5 does not retain that extent in the reopened VDS property
list. Create the replacement dataset anonymously, copy ordinary attributes
unless `without_attrs` is set, and publish the requested hard link only after
all mapping and attribute work succeeds. This preserves the no-partial-link
failure boundary without prescribing a temporary-link naming convention.
