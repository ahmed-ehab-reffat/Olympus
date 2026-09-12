# pydicom fileset-replace prototype preservation

Recorded: 2026-07-30

## Repository

- URL: `https://github.com/pydicom/pydicom.git`
- Pinned commit: `dd9f032d15ac5265e1903d1102d19ceb51182506`
- Preserved checkout: `work/pydicom-fileset-replace/probe`
- Patch: `prototype.patch`
- Patch SHA-256: `552e71bcb70c938d0a3441beaad8db64d781f9cf02fa4b7291f9852bb31fdcca`

## Preserved state

The binary-capable patch captures the complete non-ignored dirty state:

- modified `src/pydicom/fileset.py`; and
- 100 insertions and 6 deletions.

The candidate was rejected at the design gate. Its prototype findings remain
documented in `problems/pydicom-fileset-replace/DESIGN.md`; this patch preserves
the exact implementation that produced those findings.

The checkout remains in place at the user's request.

## Recovery

```sh
git clone https://github.com/pydicom/pydicom.git work/pydicom-fileset-replace/recovered
git -C work/pydicom-fileset-replace/recovered checkout dd9f032d15ac5265e1903d1102d19ceb51182506
git -C work/pydicom-fileset-replace/recovered apply ../../../archive/pydicom-fileset-replace/prototype.patch
```
