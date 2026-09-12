Title: Reconstruct and relocate existing virtual dataset layouts

Add `VirtualLayout.from_dataset(dataset)` so an existing virtual dataset can be reconstructed as an independent, reusable layout after its file is closed. The resulting layout must reproduce the virtual dataset's mappings and creation behavior when passed to `create_virtual_dataset()`, including its dtype, current and maximum shape, fill value, allocation and fill timing, object timestamp tracking, and attribute creation-order and phase-change settings. Callers must be able to extend it through normal layout assignment. Reject inputs that are not virtual datasets.

Add `VirtualLayout.relocated(filename, *, source_filename=None)`, returning an independent layout targeted at another VDS file while preserving which source files every mapping resolves to. Rebase ordinary relative names, make `.` refer back to the original VDS file, and retain absolute names unchanged. Layouts originally constructed without a target filename require `source_filename` to establish the old resolution base.

Explicit source selections must remain reconstructable when their source files do not yet exist. For a whole-source mapping, use that particular source dataset's current dataspace and fail if it cannot be read.

Integrate the same behavior into a new `relocate_vds=False` option on `Group.copy()`. Relocation is limited to a directly selected virtual dataset. Reject groups, named datatypes, ordinary datasets, and the combination with `expand_refs=True` without publishing the requested destination link.
