# Summary — ezdxf XREF object collections

Status: **accepted and archived 2026-08-16; user-confirmed**.

Repository: `mozman/ezdxf` at
`b3eb37b942acb4c7e2d2487706e614aa29b7f9b2`.

Language: Python. Task type: enhancement. Difficulty: **7/10**.

The task adds queued transfer of named non-graphical objects. It reconstructs
dictionary ancestry, preserves keys and ownership, resolves direct and
hard-resource conflicts, maps the complete stated handle ranges, merges
matching dictionaries, and preserves defaults without cross-document links or
unused copies.

The trajectory-driven easing remains: soft-owned dictionaries transfer
non-dictionary entries, but no nested soft management container is required.
Version 7 keeps that scope and fixes two identity boundaries. A child already
copied inline with a hard-owned dictionary cannot be copied again through a
sibling hard reference or an earlier direct selection. Valid group-1005 XDATA
on an unknown non-graphical object is also mapped and preserved through reload.
The public description is reorganized into shorter maintainer-style sections
without changing behavior.

| Gate | Version-7 result |
|---|---|
| exact environment | pass; approved base, `/app`, offline/read-only UID 10001 |
| pristine/reference feature | 36 behavioral failures / 36 passed |
| complete reference base | 7,842 passed, 97 skipped, 1 xfailed |
| reference diff | 4 production files, 471 additions / 17 removals |
| mutation audit | 34/34 attempted mutants killed; no survivor |
| gap / fairness / false-positive | pass / pass / pass |
| representative replays | 35/36, 31/36, 28/36, 26/36, 24/36; all exact base lanes pass |
| saved version-7 batch | 0/5; focused results 29/36, 32/36, 35/36, 34/36, 34/36; every baseline passed |
| disposition | platform acceptance user-confirmed 2026-08-16 |

The task excludes external XREF traversal, unfinished CAD formats, graphical
copying, malformed vendor data, exact handles or generated keys, and private
implementation rules.

Canonical artifacts and compact verification records remain in this directory.
Raw solver bundles and preliminary candidate records are preserved under
`archive/ezdxf-xref-object-collections/`.
