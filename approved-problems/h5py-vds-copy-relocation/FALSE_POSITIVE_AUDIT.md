# False-positive audit - h5py VDS layout reconstruction and relocation

Status: `exact current-extent-corrected artifact audited; 44/44 active mutants
killed; no survivor`.

## Immutable version

| Artifact | SHA-256 |
|---|---|
| `meta.md` | `34e302790597695901fe26db04bf210aed995e5ac972f5f0462a733722e5af72` |
| `test.patch` | `aa79f055fceafbce32c9cd8b42965da64247b4ccd4346c1e852d237c0a5783cf` |
| `solution.patch` | `3e23b41bc59915c3da584cb261d4bfd60cebe7597832c53416e54830c0afa4f0` |
| `Dockerfile` | `c16323de8d648c33ca71130a59b978bb81de1ecdead2f6ea04620a077e4c5af7` |
| mutation runner | `2cf33cd620c8a4324a6a65bd4dc5171bde84859aeafc881446d97241595b45ae` |
| mutation README | `bfef8ee31fb96c4e18fae4363a26c81a343c6e01954eb48b48ba7f9e3a61113e` |
| source pin | `2412db7ab71c52f3937e8cf6b966cbb189b7c2b3` |
| image | `sha256:f093210f23730cf9fc3c2f15606ceb30c20dc059308578521c9bce5898db8a4c` |

The reference changes two production files: 88 additions/3 deletions in
`h5py/_hl/group.py` and 199 additions/6 deletions in `h5py/_hl/vds.py`.
The local strict nonblank/noncomment count is 249 production additions. The old
reference measured 100 locally and 91 on the platform, so the conservative
platform-ratio forecast is about 227 effective LOC. This is a scope forecast,
not a substitute for a successful-solver median.

## Participant requirement to strongest behavioral oracle

| Public requirement | Strongest focused oracle |
|---|---|
| `VirtualLayout.from_dataset(dataset)` exists with the declared form | `test_virtual_layout_reconstruction_api_signatures` |
| Only a virtual dataset is reconstructable | three `test_from_dataset_rejects_nonvirtual_inputs` entities plus the empty-VDS acceptance probe |
| The returned layout is independent of the source object's lifetime | `test_reconstructed_layout_is_reusable_and_extendable_after_close` |
| A reconstructed layout is reusable | the same test creates two VDS objects from one closed-source layout |
| A reconstructed layout remains extendable through normal assignment | the same test adds a second mapping after the source closes |
| Direct layout reconstruction retains the explicitly listed creation properties | `test_reconstructed_layout_preserves_creation_behavior`, which resizes the VDS itself before reconstruction and checks mapped/fill reads, live current/max shape, allocation/fill timing, timestamp tracking, and attribute creation-order/phase-change settings after the source closes |
| `relocated(filename, *, source_filename=None)` is public and keyword-only | signature test |
| Relocation returns an independent layout | mixed-filename test creates the original and relocated layouts in different files |
| Relative, `.`, and absolute mappings are handled per mapping | mixed-filename layout and Group-copy tests |
| Every layout without an original target needs an explicit old base | `test_targetless_layout_relocation_uses_explicit_resolution_base`, covering relative and absolute-only mappings |
| Explicit mappings do not open absent sources and retain source-selection geometry | layout-level relative/absolute missing-source test uses offset/strided selections with decoy data; Group-copy equivalents cover the integration surface |
| Every whole-source mapping uses its own current source dataset space | layout-level heterogeneous-source test plus current-extent failure probes |
| An unreadable whole-source mapping fails | layout missing-dataset probe and Group-copy missing-file/dataset probes |
| `Group.copy(..., relocate_vds=False)` is opt-in | exact-default and omitted-option legacy-resolution tests |
| Copy relocation accepts only a direct VDS and rejects `expand_refs` | cross-file and same-file parameterized scope/option probes |
| Rejection/failure does not publish a destination link | missing whole-source and scope/option sentinel probes |
| Existing source addressing and same-file forms remain valid | non-root Group-relative path and same-file direct-VDS probes |
| Existing copy metadata/attribute semantics remain observable | selection/unlimited, attributes/`without_attrs`, and nondefault DCPL tests |
| A direct zero-mapping VDS remains valid | layout reconstruction/relocation and Group-copy empty-VDS probes |

Concrete exception classes and messages are intentionally unconstrained. A
positive control rewrote all new high-level `TypeError`/`ValueError` paths
to `RuntimeError`; all 41 focused entities still passed.

The direct creation-property oracle is now backed by an explicit public
contract. The earlier version's generic "creation behavior" wording did not
fairly support exact low-level fields; `meta.md` now names each relevant family
before the getter comparisons were restored. Both source-DCPL reuse and a
complete explicit reconstruction satisfy the test, so it does not prescribe
one implementation.

An isolated direct-surface mutant deliberately resets only the reconstructed
layout's phase-change thresholds while restoring them in the separate copy
integration path. It passed the predecessor focused suite 41/41 and fails only
the strengthened direct logical test at 40/41. This demonstrates that the
existing `Group.copy` property test did not cover the independently public
`VirtualLayout.from_dataset()` surface.

The direct explicit-source oracle now uses nontrivial offset/strided selections
and creates the absent sources only after reconstruction. A direct-only mutant
replaces each explicit source space with a zero-based contiguous range of the
same point count while preserving copy integration. It passed the predecessor
41/41 and fails only the strengthened logical group at 40/41, demonstrating
that the old fixture tested source-I/O avoidance but not mapping geometry.

The creation-behavior oracle also resizes the VDS itself with
`DatasetID.set_extent` before reconstruction. At that point its live shape is
larger than its still-stale mapping virtual-space extent. A mutant that derives
the layout shape from that mapping passes the predecessor 41/41 and fails only
the strengthened test at 40/41. This separates the VDS's current extent from
both mapping bounds and mapped-source `SEL_ALL` extent handling.

The targetless precondition is also mapping-independent. The strengthened
oracle requires an explicit `source_filename` for an absolute-only targetless
layout, matching the prompt's unconditional layout-level rule. The accepted
reference checks this before classifying mappings. An isolated mutant which
waives the precondition only when every mapping is absolute passed the
predecessor focused suite 41/41 and fails the corrected logical group at 40/41.

## Plausible incorrect implementations

The set is derived from the ten prior direct-copy trajectories, the two
demonstrated prior passing architectures, repository behavior, heterogeneous
mapping boundaries, and the new reusable-layout lifecycle. Mutants 1-30 replay
the exact previous failure families against the redesigned implementation.
Mutants 31-44 target distinct new public boundaries.

| # | Mutant | Focused result | Distinct violated behavior |
|---:|---|---:|---|
| 1 | `native_mapping_names` | 28/41 | no rebasing |
| 2 | `dot_unchanged` | 36/41 | cross-file same-file source |
| 3 | `absolute_normalized` | 40/41 | absolute spelling |
| 4 | `cwd_relative_base` | 31/41 | VDS-relative resolution |
| 5 | `explicit_requires_source` | 37/41 | explicit missing-source metadata |
| 6 | `one_dimensional_all` | 37/41 | whole-source live space |
| 7 | `first_mapping_only` | 33/41 | mapping completeness |
| 8 | `whole_virtual_space` | 30/41 | virtual selections |
| 9 | `drop_fill_value` | 36/41 | fill behavior |
| 10 | `drop_attributes` | 39/41 | ordinary attributes |
| 11 | `ignore_without_attrs` | 40/41 | attribute omission |
| 12 | `fixed_maxshape` | 39/41 | unlimited/maxshape |
| 13 | `path_source_rejected` | 26/41 | public source addressing |
| 14 | `allow_non_vds_native` | 35/41 | direct-VDS scope |
| 15 | `allow_named_datatype_native` | 39/41 | named-type scope |
| 16 | `allow_expand_refs` | 39/41 | incompatible option |
| 17 | `implicit_vds_relocation` | 40/41 | false-default gating |
| 18 | `cross_file_only_validation` | 37/41 | same-file validation |
| 19 | `reject_same_file_vds` | 40/41 | valid same-file VDS |
| 20 | `relocate_default_none` | 40/41 | exact public default |
| 21 | `first_relative_mapping_only` | 35/41 | per-relative-record rebasing |
| 22 | `absolute_explicit_requires_source` | 39/41 | absolute explicit metadata |
| 23 | `declared_all_extent` | 40/41 | current extent |
| 24 | `missing_dataset_uses_mapped_extent` | 39/41 | named dataset readability |
| 25 | `reject_empty_vds_copy` | 40/41 | empty direct VDS |
| 26 | `group_relative_from_root` | 40/41 | receiver-relative source path |
| 27 | `first_filename_kind_for_all` | 39/41 | heterogeneous filename dispatch |
| 28 | `first_selection_kind_for_all` | 40/41 | heterogeneous selection dispatch |
| 29 | `reuse_first_all_source_space` | 39/41 | per-source whole spaces |
| 30 | `reset_attr_phase_change` | 39/41 | shared layout/copy creation property |
| 31 | `lazy_source_lifetime` | 38/41 | source-independent layout lifetime |
| 32 | `one_shot_layout` | 40/41 | layout reuse |
| 33 | `reset_clone_properties` | 35/41 | reconstructed creation behavior |
| 34 | `relocated_in_place` | 39/41 | independent relocation result |
| 35 | `targetless_ignores_base` | 40/41 | explicit old resolution base |
| 36 | `targetless_assumes_target` | 40/41 | missing-base rejection |
| 37 | `nonextendable_clone` | 40/41 | normal layout composition |
| 38 | `reject_empty_layout` | 39/41 | empty VDS reconstruction |
| 39 | `positional_source_filename` | 40/41 | keyword-only API |
| 40 | `relocated_shares_dcpl` | 33/41 | independent property-list ownership |
| 41 | `targetless_absolute_skips_base` | 40/41 | mapping-independent targetless-base precondition |
| 42 | `direct_clone_omits_phase_change` | 40/41 | direct layout creation-property fidelity |
| 43 | `direct_explicit_selection_contiguous` | 40/41 | direct explicit source-selection geometry |
| 44 | `mapping_extent_instead_of_current_vds` | 40/41 | resized VDS current extent |

All mutations changed production bytes, passed `git diff --check`, and were
run in isolated, offline containers. Every mutant was killed by the focused
suite, so there was no focused survivor to run through the complete pre-existing
suite. A zero-survivor result is evidence only for this attempted set.

## Saved solver replay

The supplied runs target the abandoned 29-entity copy-only contract and cannot
count as calibration for this redesign. Representative exact replays establish
that the new tests require the new public component:

| Prior trajectory | Redesigned focused score | Interpretation |
|---|---:|---|
| Nova 8 legitimate old pass | 29/41 | all 12 new layout entities fail |
| Nova 10 second old pass | 28/41 | old creation-property miss plus 12 layout failures |
| Nova 6 broadest old near-pass | 27/41 | old two misses plus 12 layout failures |

This is the expected behavior for a materially new public contract, not evidence
that the redesign is unsolvable. No cold solver was run.

## Exact matrix and regression results

| State | Selected base | Focused |
|---|---:|---:|
| pristine | 138/138 | 41/41 fail/error |
| test patch only | 138/138 | 41/41 fail/error |
| solution patch only | 138/138 | not installed |
| test then solution | 138/138 | 41/41 pass |
| solution then test | 138/138 | 41/41 pass |
| out-of-tree combined | - | 41/41 pass |

The solution-only complete pre-existing suite passes offline and unprivileged:
842 passed, 60 skipped, and 3 subtests passed. Both canonical patches pass
`git apply --check` in both orders. The Docker image was rebuilt previously
from an empty local image/cache state and remains runnable.

## Verdict

The false-positive gate is closed for this exact redesigned artifact. The
reference now has a credible two-production-file, above-200 scope forecast,
while all prior copy-only solvers fail the independent layout API. The problem
is still at 0/10: platform difficulty, at least one successful redesigned
solver, the median successful production files/LOC/messages, and holistic
review remain unestablished. No calibration result from the abandoned version
carries forward.
