# Runs — ezdxf XREF object collections

Current version: `v7 accepted and archived 2026-08-16`.

Acceptance status: `user-confirmed`. The saved version-7 calibration batch
ended at 0/5 and is preserved as evidence rather than presented as a pass.

## Superseded calibration evidence

Version 2 solved 0/8. Every clean run treated XREF/NUM prefixes as
conflict-only, so version 3 removed unconditional free-key renaming.

Version 3 solved 0/5. Four implementations transferred the soft-owned leaf but
omitted an empty nested soft management dictionary, so version 4 removed that
cell. All these runs used clean baseline lanes. They remain design evidence and
cannot be credited to version 7.

## Version-7 exact replays

Five representative raw patches were composed implementation-first and
verifier-second, then run offline from read-only mounts as UID/GID 10001.

| Patch | Exact complete base lane | Feature | Role |
|---|---:|---:|---|
| `agent-runs1/Nova_Nova_4` | 7,850 passed, 97 skipped, 1 xfailed | 35/36 | passes all four v7 additions; earlier KEEP redirect only |
| `agent-runs2/Nova_Nova_2` | 7,842 passed, 97 skipped, 1 xfailed | 31/36 | path-plan architecture; passes all v7 additions |
| `agent-runs2/Nova_Nova_5` | 7,846 passed, 97 skipped, 1 xfailed | 28/36 | independent DWD/reuse/KEEP architecture |
| `agent-runs2/Nova_Nova_1` | 7,847 passed, 97 skipped, 1 xfailed | 26/36 | resource-tracking architecture with public lifecycle misses |
| `agent-runs2/Nova_Nova_4` | 7,849 passed, 97 skipped, 1 xfailed | 24/36 | independent dictionary reuse; placement/mapping misses |

Differing base totals reflect tests carried by solver patches. Every exact base
lane passed. These are replay evidence, not version-7 calibration runs.

## Saved version-7 platform batch

| Run | Baseline | Feature | Main remaining behavior |
|---|---|---:|---|
| `Nova_Nova_1` | pass | 29/36 | matching-dictionary reuse, KEEP cleanup, hard-dictionary persistence |
| `Nova_Nova_2` | pass | 32/36 | queue append, soft entries, copied default dictionary, KEEP cleanup |
| `Nova_Nova_3` | pass | 35/36 | KEEP hard-owned-descendant cleanup |
| `Nova_Nova_4` | pass | 34/36 | KEEP cleanup and embedded unknown-object mapping |
| `Nova_Nova_5` | pass | 34/36 | reused default dictionary and KEEP cleanup |

The batch stopped at 0/5. Every run missed the explicit KEEP-conflict cleanup
boundary, while the other failures differed. The user subsequently confirmed
platform acceptance on 2026-08-16. That external disposition does not convert
these five failures into solver passes.

Raw batches 1 through 3 are preserved as ZIP archives under
`archive/ezdxf-xref-object-collections/`; the duplicate extracted directories
were removed after ZIP integrity and byte-parity checks.
