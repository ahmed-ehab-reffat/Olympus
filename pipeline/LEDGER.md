# Olympus factory ledger

Owned by the `/olympus-factory` loop, so do not edit rows by hand: to change something, write to
`INBOX.md` instead. Statuses: HUNTED, SLICING, AWAITING-PRECHECK, PRECHECK-CLEAN, BUILDING, READY, CLAIMED, DEAD.

| Slug | Repo | Status | Updated | Next / notes |
|---|---|---|---|---|
| libspatialindex-tpr-temporal-knn | libspatialindex/libspatialindex | BUILDING | 2026-09-19 | TPR-tree kNN + temporal self-join via one interval min-distance kernel (moving query vs moving MBR). Log REPO-HUNT-2026-09-19-G. Base 494d966f; clone worktrees/_hunt/e_storage/libspatialindex. FALLBACKS: walles/riff (moved-block numbering); macs3-project/MACS (q-value/segmentation; #613 magnet). PICKER: eligible, licence-not-recognized warning (2026-09-19) -> verified MIT: GitHub NOASSERTION only because COPYING opens with the pre-1.8.0 LGPL history note; 95/96 src+include files carry the MIT header, rand48.cc is a permissive Birgmeier notice, vendored gtest BSD-3, no GPL text anywhere (grep hits were __GNUC__/GNUInstallDirs). Precedent: pandapower/grmtools/laspy approved at NOASSERTION. Builder must record this in feedback.md. OWED: >=250 eff spike (TPR alone 165-230, MVR hist kNN is breadth reserve), six-check + PR-DIFF, fixed small inputs (#247), Docker + 3x baseline. |
| csbindgen-struct-layout-fidelity | Cysharp/csbindgen | CLAIMED | 2026-09-19 | Human session (R9, pending Solution Quality re-check). Loop never touches it. |
| oxipng-apng-frame-optimization | oxipng/oxipng | CLAIMED | 2026-09-19 | Human session (R0, awaiting picker + precheck). Loop never touches it. |
| messageformat-mf2-to-mf1 | messageformat/messageformat | CLAIMED | 2026-09-19 | Human is working on it in their own session; loop never touches it. Was: messageToMF1 + sparse-variant messageToFluent (selection-kernel nesting trap). Log REPO-HUNT-2026-09-19-F. FALLBACKS: macs3-project/MACS (q-value/segmentation; magnet #613); libspatialindex/libspatialindex (temporal kNN). OWED: picker check, six-check, >=250 eff spike, plural locale agreement. Delete stray mf2/icu-messageformat-1/src/zz-probe.test.ts before authoring. |

## Log

- 2026-09-19 factory start. Ledger empty, inbox empty, disk / 12G, docker 22G free. problems/csbindgen-struct-layout-fidelity has no row, so it belongs to a human session and stays untouched. Hunter #1 launched (misses=0).
- 2026-09-19 hunter #1 CANDIDATE messageformat/messageformat (misses reset to 0). Disk gate FAILS: / 9.1G free (<10G), so no builder launched; human notified once. Hunter #2 launched.
- 2026-09-19 messageformat/messageformat -> CLAIMED (user said in session they are already working on it). Fallbacks not promoted (claim is not a DEAD). 0 HUNTED; hunter #2 still running.
- 2026-09-19 problems/ audit: all 3 folders are human sessions -> recorded CLAIMED (csbindgen, oxipng, messageformat slug messageformat-mf2-to-mf1). No name/repo overlap with approved-problems/ or rejected/. Root disk 8.8G free, builders still gated.
- 2026-09-19 hunter #2 CANDIDATE libspatialindex/libspatialindex (promoted fallback; misses stay 0). Disk gate still FAILS (/ 9.0G), no builder; already notified. Hunter #3 launched (dependents/org-siblings axis).
- 2026-09-19 libspatialindex picker: eligible with licence warning; licence verified MIT at base 494d966f (see row). Row stays HUNTED for SLICE.
- 2026-09-19 disk gate passes (/ 11G, docker 20G). SLICE builder launched on libspatialindex/libspatialindex. Hunter #3 still running.
- 2026-09-19 SLICE-READY libspatialindex-tpr-temporal-knn: 214 human-eff (FINISH plans all-shape range queries +~40, MVR hist kNN as reserve), 11 new tests, base 27/27, 3x identical, 8/8 mutations killed. Human notified: precheck upload owed. No HUNTED rows, so builder idle; hunter #3 running.
- 2026-09-19 hunter #3 NO-CANDIDATE (log REPO-HUNT-2026-09-19-H; corpus-neighbourhood axis exhausted; starlark-rust narrowing dead). Misses=1. Hunter #4 launched (created:-year + size:>5000 engine sweep). Builder idle: nothing PRECHECK-CLEAN or HUNTED. Disk / 11G.
- 2026-09-19 inbox: libspatialindex-tpr-temporal-knn clean (precheck PASSED, no warnings; said in session). -> PRECHECK-CLEAN -> BUILDING, FINISH builder launched. Disk / 11G, docker 21G. Hunter #4 running.
- 2026-09-19 hunter #4 and FINISH builder both hit the API usage limit (HTTP 429), not a worker failure, so it is not counted as a retry. Builder made no file changes (folder unchanged since the slice). Hunter resumed. Builder held: disk gate fails (/ 9.7G < 10G); row back to PRECHECK-CLEAN until the gate clears.
- 2026-09-19 disk poll false-cleared (df -B1G rounds 9.6G up to 10); real / free 9867M < 10240M. Builder still held; poll re-armed with MB precision.
- 2026-09-19 STOP (user said stop). Disk poll stopped; nothing new will be launched. Hunter #4 left to finish; its result will be recorded only.
- 2026-09-20 hunter #4 stopped with no result block after the rate-limit resume (no REPO-HUNT-...-I log written). Factory is STOPPED, so it is not relaunched; partial sweep scratch left in worktrees/_hunt/i_size/. Misses stay 1.
- 2026-09-20 factory restarted. STOP absent, inbox empty, disk / 10G (10185M) docker 21G. FINISH builder relaunched on libspatialindex-tpr-temporal-knn (folder untouched since the slice). Hunter #5 launched at misses=1, told to reuse the killed hunter's scratch in worktrees/_hunt/i_size/.
