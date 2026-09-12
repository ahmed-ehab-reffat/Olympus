#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${ARTIFACT_DIR:-/artifacts}"
mutant="${1:?usage: mutations.sh MUTANT}"

git apply "$artifact_dir/test.patch"
git apply "$artifact_dir/solution.patch"

replace_exact() {
    local mutation_path="$1"
    local mutation_old="$2"
    local mutation_new="$3"
    MUTATION_PATH="$mutation_path" \
    MUTATION_OLD="$mutation_old" \
    MUTATION_NEW="$mutation_new" \
    python - <<'PY'
import os
from pathlib import Path

path = Path(os.environ["MUTATION_PATH"])
old = os.environ["MUTATION_OLD"]
new = os.environ["MUTATION_NEW"]
text = path.read_text()
count = text.count(old)
if count != 1:
    raise SystemExit(f"{path}: expected one mutation target, found {count}")
path.write_text(text.replace(old, new))
PY
}

mutation_before="$(sha256sum h5py/_hl/group.py h5py/_hl/vds.py)"

case "$mutant" in
    native_mapping_names)
        replace_exact h5py/_hl/vds.py \
'    resolved = _resolved_source_filename(filename, source_filename)
    target_dir = os.path.dirname(os.path.abspath(target_filename))
    return os.path.relpath(resolved, target_dir)' \
'    return filename'
        ;;
    dot_unchanged)
        replace_exact h5py/_hl/vds.py \
'def _relocated_source_filename(filename, source_filename, target_filename):
    """Spell a VDS source name relative to a new containing file."""
    if os.path.isabs(filename):' \
'def _relocated_source_filename(filename, source_filename, target_filename):
    """Spell a VDS source name relative to a new containing file."""
    if filename == ".":
        return filename
    if os.path.isabs(filename):'
        ;;
    absolute_normalized)
        replace_exact h5py/_hl/vds.py \
'    if os.path.isabs(filename):
        return filename

    if os.path.realpath(source_filename)' \
'    if os.path.isabs(filename):
        return os.path.normpath(filename)

    if os.path.realpath(source_filename)'
        ;;
    cwd_relative_base)
        replace_exact h5py/_hl/vds.py \
'        os.path.join(os.path.dirname(vds_filename), filename)' \
'        os.path.join(os.getcwd(), filename)'
        ;;
    explicit_requires_source)
        replace_exact h5py/_hl/vds.py \
'    if mapping.src_space.get_select_type() != h5s.SEL_ALL:
        return mapping.src_space' \
'    if mapping.src_space.get_select_type() != h5s.SEL_ALL:
        source_filename = _resolved_source_filename(
            mapping.file_name, dataset.file.filename
        )
        source_file_id = h5f.open(
            filename_encode(source_filename), h5f.ACC_RDONLY
        )
        source_file_id.close()
        return mapping.src_space'
        ;;
    one_dimensional_all)
        replace_exact h5py/_hl/vds.py \
'    source_filename = _resolved_source_filename(
        mapping.file_name, dataset.file.filename
    )' \
'    return h5s.create_simple((mapping.vspace.get_select_npoints(),))

    source_filename = _resolved_source_filename(
        mapping.file_name, dataset.file.filename
    )'
        ;;
    first_mapping_only)
        replace_exact h5py/_hl/vds.py \
'                for mapping in dataset.virtual_sources():' \
'                for mapping in dataset.virtual_sources()[:1]:'
        ;;
    whole_virtual_space)
        replace_exact h5py/_hl/vds.py \
'                            mapping.vspace,
                            filename_encode(mapping.file_name),' \
'                            dataset.id.get_space(),
                            filename_encode(mapping.file_name),'
        ;;
    drop_fill_value)
        replace_exact h5py/_hl/vds.py \
'
    if source.fill_value_defined() == h5d.FILL_VALUE_USER_DEFINED:
        fillvalue = np.zeros((1,), dtype=dtype)
        source.get_fill_value(fillvalue)
        target.set_fill_value(fillvalue)
' \
'
'
        ;;
    drop_attributes)
        replace_exact h5py/_hl/group.py \
'        if not without_attrs:
            _copy_dataset_attributes(source, relocated)' \
'        if False and not without_attrs:
            _copy_dataset_attributes(source, relocated)'
        ;;
    ignore_without_attrs)
        replace_exact h5py/_hl/group.py \
'        if not without_attrs:
            _copy_dataset_attributes(source, relocated)' \
'        if True:
            _copy_dataset_attributes(source, relocated)'
        ;;
    fixed_maxshape)
        replace_exact h5py/_hl/vds.py \
'            maxshape=dataset.maxshape,
            filename=source_filename,' \
'            maxshape=dataset.shape,
            filename=source_filename,'
        ;;
    path_source_rejected)
        replace_exact h5py/_hl/group.py \
'            if relocate_vds:
                if source_object is None:' \
'            if relocate_vds:
                if source_path != ".":
                    raise TypeError("dataset object required")
                if source_object is None:'
        ;;
    allow_non_vds_native)
        replace_exact h5py/_hl/group.py \
'                ):
                    raise TypeError(
                        "relocate_vds requires a virtual dataset source"
                    )' \
'                ):
                    h5o.copy(
                        source.id, self._e(source_path), dest.id,
                        self._e(dest_path), None, base.dlcpl,
                    )
                    return'
        ;;
    allow_named_datatype_native)
        replace_exact h5py/_hl/group.py \
'                if (
                    not isinstance(source_object, dataset.Dataset)' \
'                if isinstance(source_object, datatype.Datatype):
                    h5o.copy(
                        source.id, self._e(source_path), dest.id,
                        self._e(dest_path), None, base.dlcpl,
                    )
                    return
                if (
                    not isinstance(source_object, dataset.Dataset)'
        ;;
    allow_expand_refs)
        replace_exact h5py/_hl/group.py \
'                if expand_refs:
                    raise ValueError(' \
'                if False and expand_refs:
                    raise ValueError('
        ;;
    implicit_vds_relocation)
        replace_exact h5py/_hl/group.py \
'            if relocate_vds:
                if source_object is None:' \
'            if not relocate_vds and source_object is None:
                candidate = source[source_path]
                if (
                    isinstance(candidate, dataset.Dataset)
                    and candidate.is_virtual
                    and candidate.file.id != dest.file.id
                ):
                    relocate_vds = True
                    source_object = candidate
            if relocate_vds:
                if source_object is None:'
        ;;
    cross_file_only_validation)
        replace_exact h5py/_hl/group.py \
'            if relocate_vds:
                if source_object is None:' \
'            if relocate_vds and source.file.id == dest.file.id:
                relocate_vds = False
            if relocate_vds:
                if source_object is None:'
        ;;
    reject_same_file_vds)
        replace_exact h5py/_hl/group.py \
'                if expand_refs:
                    raise ValueError(
                        "relocate_vds cannot be combined with expand_refs"
                    )' \
'                if expand_refs:
                    raise ValueError(
                        "relocate_vds cannot be combined with expand_refs"
                    )
                if source_object.file.id == dest.file.id:
                    raise ValueError("relocate_vds requires different files")'
        ;;
    relocate_default_none)
        replace_exact h5py/_hl/group.py \
'             expand_refs=False, without_attrs=False, relocate_vds=False):' \
'             expand_refs=False, without_attrs=False, relocate_vds=None):'
        ;;
    first_relative_mapping_only)
        replace_exact h5py/_hl/vds.py \
'            for mapping in self._virtual_sources():
                try:
                    relocated_filename = _relocated_source_filename(' \
'            for mapping_index, mapping in enumerate(self._virtual_sources()):
                try:
                    relocated_filename = _relocated_source_filename('
        replace_exact h5py/_hl/vds.py \
'                        mapping.file_name, current_filename, filename
                    )
                    relocated.dcpl.set_virtual(' \
'                        mapping.file_name, current_filename, filename
                    )
                    if mapping_index > 0 and not os.path.isabs(mapping.file_name):
                        relocated_filename = mapping.file_name
                    relocated.dcpl.set_virtual('
        ;;
    absolute_explicit_requires_source)
        replace_exact h5py/_hl/vds.py \
'    if mapping.src_space.get_select_type() != h5s.SEL_ALL:
        return mapping.src_space' \
'    if mapping.src_space.get_select_type() != h5s.SEL_ALL:
        if os.path.isabs(mapping.file_name):
            source_file_id = h5f.open(
                filename_encode(mapping.file_name), h5f.ACC_RDONLY
            )
            source_file_id.close()
        return mapping.src_space'
        ;;
    declared_all_extent)
        replace_exact h5py/_hl/vds.py \
'            return source_dataset_id.get_space()' \
'            return h5s.create_simple(
                (mapping.vspace.get_select_npoints(),)
            )'
        ;;
    missing_dataset_uses_mapped_extent)
        replace_exact h5py/_hl/vds.py \
'        source_dataset_id = h5d.open(
            source_file_id, filename_encode(mapping.dset_name)
        )' \
'        try:
            source_dataset_id = h5d.open(
                source_file_id, filename_encode(mapping.dset_name)
            )
        except Exception:
            return h5s.create_simple(
                (mapping.vspace.get_select_npoints(),)
            )'
        ;;
    reject_empty_vds_copy)
        replace_exact h5py/_hl/group.py \
'                    or not source_object.is_virtual
                ):' \
'                    or not source_object.is_virtual
                    or not source_object.virtual_sources()
                ):'
        ;;
    group_relative_from_root)
        replace_exact h5py/_hl/group.py \
'                    source_object = source[source_path]' \
'                    source_object = source.file[source_path]'
        ;;
    first_filename_kind_for_all)
        replace_exact h5py/_hl/vds.py \
'                    relocated_filename = _relocated_source_filename(
                        mapping.file_name, current_filename, filename
                    )' \
'                    first_mapping = self._virtual_sources()[0]
                    if os.path.isabs(first_mapping.file_name):
                        relocated_filename = mapping.file_name
                    else:
                        relocated_filename = _relocated_source_filename(
                            mapping.file_name, current_filename, filename
                        )'
        ;;
    first_selection_kind_for_all)
        replace_exact h5py/_hl/vds.py \
'    if mapping.src_space.get_select_type() != h5s.SEL_ALL:
        return mapping.src_space' \
'    first_mapping = dataset.virtual_sources()[0]
    if first_mapping.src_space.get_select_type() != h5s.SEL_ALL:
        return mapping.src_space'
        ;;
    reuse_first_all_source_space)
        replace_exact h5py/_hl/vds.py \
'    source_filename = _resolved_source_filename(
        mapping.file_name, dataset.file.filename
    )' \
'    mapping = next(
        item for item in dataset.virtual_sources()
        if item.src_space.get_select_type() == h5s.SEL_ALL
    )
    source_filename = _resolved_source_filename(
        mapping.file_name, dataset.file.filename
    )'
        ;;
    reset_attr_phase_change)
        replace_exact h5py/_hl/vds.py \
'    target.set_attr_phase_change(*source.get_attr_phase_change())
' \
''
        ;;
    direct_clone_omits_phase_change)
        replace_exact h5py/_hl/vds.py \
'                _copy_creation_properties(
                    source_dcpl, layout.dcpl, dataset.dtype
                )

                for mapping in dataset.virtual_sources():' \
'                _copy_creation_properties(
                    source_dcpl, layout.dcpl, dataset.dtype
                )
                layout.dcpl.set_attr_phase_change(8, 6)

                for mapping in dataset.virtual_sources():'
        replace_exact h5py/_hl/group.py \
'    layout = VirtualLayout.from_dataset(source).relocated(
        destination.file.filename
    )' \
'    layout = VirtualLayout.from_dataset(source)
    source_dcpl = source.id.get_create_plist()
    try:
        layout.dcpl.set_attr_phase_change(
            *source_dcpl.get_attr_phase_change()
        )
    finally:
        source_dcpl.close()
    layout = layout.relocated(destination.file.filename)'
        ;;
    direct_explicit_selection_contiguous)
        replace_exact h5py/_hl/vds.py \
'                    source_space = _mapping_source_space(dataset, mapping)
                    try:
                        layout.dcpl.set_virtual(' \
'                    source_space = _mapping_source_space(dataset, mapping)
                    if (
                        not getattr(cls, "_preserve_copy_selections", False)
                        and source_space.get_select_type() != h5s.SEL_ALL
                    ):
                        point_count = source_space.get_select_npoints()
                        source_space.close()
                        source_space = h5s.create_simple((point_count,))
                    try:
                        layout.dcpl.set_virtual('
        replace_exact h5py/_hl/group.py \
'    layout = VirtualLayout.from_dataset(source).relocated(
        destination.file.filename
    )' \
'    VirtualLayout._preserve_copy_selections = True
    try:
        layout = VirtualLayout.from_dataset(source).relocated(
            destination.file.filename
        )
    finally:
        del VirtualLayout._preserve_copy_selections'
        ;;
    mapping_extent_instead_of_current_vds)
        replace_exact h5py/_hl/vds.py \
'        source_filename = dataset.file.filename
        layout = cls(
            dataset.shape,' \
'        source_filename = dataset.file.filename
        mappings = dataset.virtual_sources()
        layout_shape = (
            mappings[0].vspace.shape if mappings else dataset.shape
        )
        layout = cls(
            layout_shape,'
        ;;
    lazy_source_lifetime)
        replace_exact h5py/_hl/vds.py \
'        return layout

    def relocated' \
'        layout._source_dataset = dataset
        return layout

    def relocated'
        replace_exact h5py/_hl/vds.py \
'    def make_dataset(self, parent, name, fillvalue=None):
        """ Return a new low-level dataset identifier for a virtual dataset """
        dcpl = self._get_dcpl(parent.file.filename)' \
'    def make_dataset(self, parent, name, fillvalue=None):
        """ Return a new low-level dataset identifier for a virtual dataset """
        if hasattr(self, "_source_dataset") and not self._source_dataset:
            raise RuntimeError("source dataset is closed")
        dcpl = self._get_dcpl(parent.file.filename)'
        ;;
    one_shot_layout)
        replace_exact h5py/_hl/vds.py \
'            virt_dspace.close()
            dcpl.close()' \
'            virt_dspace.close()
            dcpl.close()
            self.dcpl.close()'
        ;;
    reset_clone_properties)
        replace_exact h5py/_hl/vds.py \
'                _copy_creation_properties(
                    source_dcpl, layout.dcpl, dataset.dtype
                )' \
'                pass'
        ;;
    relocated_in_place)
        replace_exact h5py/_hl/vds.py \
'        return relocated

    def _virtual_sources' \
'        self.dcpl = relocated.dcpl
        self._filename = filename
        return self

    def _virtual_sources'
        ;;
    targetless_ignores_base)
        replace_exact h5py/_hl/vds.py \
'            current_filename = os.fspath(source_filename)' \
'            current_filename = filename'
        ;;
    targetless_assumes_target)
        replace_exact h5py/_hl/vds.py \
'            if source_filename is None:
                raise ValueError(
                    "source_filename is required for a layout without a "
                    "target filename"
                )
            current_filename = os.fspath(source_filename)' \
'            if source_filename is None:
                current_filename = filename
            else:
                current_filename = os.fspath(source_filename)'
        ;;
    targetless_absolute_skips_base)
        replace_exact h5py/_hl/vds.py \
'            if source_filename is None:
                raise ValueError(
                    "source_filename is required for a layout without a "
                    "target filename"
                )
            current_filename = os.fspath(source_filename)' \
'            if source_filename is None:
                if all(
                    os.path.isabs(mapping.file_name)
                    for mapping in self._virtual_sources()
                ):
                    current_filename = filename
                else:
                    raise ValueError(
                        "source_filename is required for a layout without a "
                        "target filename"
                    )
            else:
                current_filename = os.fspath(source_filename)'
        ;;
    nonextendable_clone)
        replace_exact h5py/_hl/vds.py \
'        return layout

    def relocated' \
'        layout._reconstructed = True
        return layout

    def relocated'
        replace_exact h5py/_hl/vds.py \
'    def __setitem__(self, key, source):
        sel = select(self.shape, key, dataset=None)' \
'    def __setitem__(self, key, source):
        if getattr(self, "_reconstructed", False):
            raise RuntimeError("reconstructed layouts are sealed")
        sel = select(self.shape, key, dataset=None)'
        ;;
    reject_empty_layout)
        replace_exact h5py/_hl/vds.py \
'        if not isinstance(dataset, Dataset) or not dataset.is_virtual:
            raise TypeError("dataset must be a virtual Dataset")' \
'        if (
            not isinstance(dataset, Dataset)
            or not dataset.is_virtual
            or not dataset.virtual_sources()
        ):
            raise TypeError("dataset must be a mapped virtual Dataset")'
        ;;
    positional_source_filename)
        replace_exact h5py/_hl/vds.py \
'    def relocated(self, filename, *, source_filename=None):' \
'    def relocated(self, filename, source_filename=None):'
        ;;
    relocated_shares_dcpl)
        replace_exact h5py/_hl/vds.py \
'        try:
            _copy_creation_properties(self.dcpl, relocated.dcpl, self.dtype)' \
'        relocated.dcpl.close()
        relocated.dcpl = self.dcpl
        try:
            _copy_creation_properties(self.dcpl, relocated.dcpl, self.dtype)'
        ;;
    *)
        echo "unknown mutant: $mutant" >&2
        exit 2
        ;;
esac

mutation_after="$(sha256sum h5py/_hl/group.py h5py/_hl/vds.py)"
if [ "$mutation_before" = "$mutation_after" ]; then
    echo "mutation made no production change: $mutant" >&2
    exit 3
fi

git diff --check
./test.sh --output_path "/tmp/$mutant.xml" new
