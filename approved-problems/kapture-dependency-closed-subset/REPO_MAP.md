# Repository map — kapture dependency-closed dataset subset

Repository pin: `8225b77d0657e6a3eb1ffc941d009100b792fb25`.

| Surface | Relevant paths | Role in the task |
|---|---|---|
| Root model | `kapture/core/Kapture.py` | Public aggregate of sensors, rigs, trajectories, nine record families, features, matches, points, and observations. |
| Selection keys | `kapture/core/Records.py`, `Trajectories.py`, `Rigs.py` | Timestamp/sensor keys, physical sensor IDs, nested rig membership, and poses. |
| Reconstruction graph | `ImageFeatures.py`, `Matches.py`, `Points3d.py`, `Observations.py` | Image membership, binary relations, point rows, observation references, and public remap boundary. |
| CSV round trip | `kapture/io/csv.py` | `kapture_from_dir`, `kapture_to_dir`, metadata path maps, dependent loading, writers, and tar-handler discovery. |
| Payload I/O and ownership | `kapture/io/features.py`, `records.py`, `binary.py`, `tar.py`, `structure.py` | Record/ordinary/tar payload paths and readers; `structure.py` demonstrates why whole-root cleanup cannot preserve unrelated nested files. |
| Existing orchestration | `kapture/algo/merge_keep_ids.py`, `merge_reconstruction.py`, `tools/kapture_merge.py` | Repository-native library/tool split, destination cleanup, payload copying, tar-aware source reads, and point-offset precedent. |
| Registration | `pyproject.toml` | Existing installed command entry points. |
| Regression suite | `tests/test_core.py`, `test_io_csv.py`, `test_io_features.py`, `test_io_records.py`, `test_tar.py`, `test_colmap.py` | Public nested-rig, metadata, payload, tar, point/observation, and full-suite behavior. |

Expected participant-owned production paths are a new module under
`kapture/algo/`, a new tool under `tools/`, and command registration in
`pyproject.toml`. Hidden tests must remain additive and may not edit those paths.
