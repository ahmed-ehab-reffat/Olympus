# Repo map - h5py/h5py

Last verified: 2026-08-08 at
`2412db7ab71c52f3937e8cf6b966cbb189b7c2b3`.

| Purpose | Entry point | Current verified count / constraint |
|---|---|---|
| Editable build | canonical Dockerfile | self-contained no-cache rebuild succeeds |
| Selected baseline | `./test.sh ... base` | 138 pre-existing cases |
| Focused behavior | `./test.sh ... new` | 41 generated-file entities |
| Complete suite | `python -m pytest h5py/tests --no-network` | 842 pass, 60 skip, 3 subtests |
| Public VDS docs | `docs/vds.rst` | reconstruction and relocation methods |
| Public copy docs | `docs/high/group.rst` | `relocate_vds` signature and restrictions |

`VirtualLayout` in `h5py/_hl/vds.py` owns prospective layouts, reconstruction
from a reopened VDS, live whole-source space recovery, independent property-list
ownership, composition, and filename retargeting. `Group.copy()` in
`h5py/_hl/group.py` owns copy addressing, validation, attribute transfer, and
atomic destination publication.

Critical black-box boundaries are layout lifetime/reuse, extension after
reconstruction, targetless old-base resolution, per-mapping filename and
selection dispatch, per-source live spaces, creation-property round trips,
receiver-relative copy paths, default gating, and failure before publication.
