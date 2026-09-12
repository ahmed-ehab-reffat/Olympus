# Levels — ezdxf XREF object collections

| Version | Main discriminator | Focused | Reference production diff | Solver evidence | State |
|---|---|---:|---:|---|---|
| candidate spike | generic named-object reconstruction | prototype | 4 files, 265 additions / 15 removals | none | promoted |
| v1 | validation, ownership, conflict, raw mapping, queueing | 26 | 4 files, 265 additions / 15 removals | none | superseded: unapproved base and `/src` |
| v2 | approved base/workdir; unconditional free-key XREF prefix | 26 | same as v1 | 0/8; every run missed free-key prefix | superseded after mandatory easing |
| v3 | conflict-only prefixes; isolated reachability; copied DWD persistence | 27 | 4 files, 291 additions / 15 removals | historical Nova replay 27/27; new platform batch 0/5 | superseded after mandatory easing and review |
| v4 | soft non-dictionary scope; complete pointer classes; KEEP subgraph cleanup | 27 | 4 files, 321 additions / 15 removals | four exact replays at 26/27, 25/27, 25/27, 24/27 | superseded after review |
| v5 | matching hard-dictionary reuse; resource-reached XREF/NUM conflicts | 30 | 4 files, 377 additions / 15 removals | five exact replays at 29/30, 27/30, 27/30, 24/30, 24/30 | superseded after review |
| v6 | generated collision depth; pointer endpoints; shared/default cleanup | 32 | 4 files, 453 additions / 16 removals | five exact replays at 31/32, 28/32, 27/32, 24/32, 24/32 | superseded after review |
| v7 | inline hard-owned identity; unknown-object XDATA; prose easing | 36 | 4 files, 471 additions / 17 removals | exact replays at 35/36 to 24/36; saved Nova batch 0/5 at 35/36 to 29/36 | accepted and archived 2026-08-16 |

Version 4 removed the soft-owned nested-management-container cell missed by
four of five clean v3 solvers, while retaining target-side isolation for soft
non-dictionary entries. Review-grounded tests independently cover omitted
pointer categories and discarded KEEP dependents. Version 5 added the distinct
matching-dictionary lifecycle and resource-reached conflict-policy producer.
Version 6 closes fixed generated names, inclusive endpoints, shared descendant
retention, and merged-default cleanup. Version 7 closes duplicate inline-child
copies from both hard-resource and child-first direct-selection producers and
maps valid unknown-object XDATA. All 34 attempted final mutants fail.

The accepted problem remains **7/10**. Difficulty comes from composing validation,
named ancestry, ownership, conflict redirection, raw resource graphs, and
persistence, not from the eased nested-container interpretation. The saved
version-7 Nova batch solved 0/5, although three runs reached 34/36 or 35/36 and
all baseline lanes passed. The user confirmed platform acceptance independently
of that incomplete calibration batch. The accepted artifacts are frozen.
