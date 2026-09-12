# LEVELS - go-mp4 sample locations

## History

| Level | Contract | Tests | Reference size | Live runs | Verdict |
|---|---|---:|---:|---:|---|
| L1 | Progressive and fragmented local sample offsets, times, sync status, table/default reconciliation, range validation, and no payload reads | 42 | 1 file / 230 effective LOC | 0 | **rejected: overlap** |

L1 is locally complete: both green gates, both compatibility gates, and all 12
mutations pass. The final coverage revision directly checks explicit fragment
bases, `moof` offsets, earliest composition summaries, both metadata/media
orders, and empty initialization tracks.

## Terminal decision

A submission-archive review found an existing task whose core work is the same:
enumerating progressive and fragmented MP4 samples with absolute offsets,
DTS/PTS, size, sync state, fragment-default resolution, data-cursor semantics,
and `mdat` validation. Differences in API presentation and extra `sdtp`,
edit-list, `sidx`, or soft-error behavior were judged incremental.

No calibration level should be launched. Adding those features here would make
the tasks more alike, while removing fragments or classic tables would merely
scope-trim the same core. Preserve L1 as repository research only and select a
different task concept for the next submission.
