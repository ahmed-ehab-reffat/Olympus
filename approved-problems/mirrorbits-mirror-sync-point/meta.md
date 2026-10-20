---
Repository: https://github.com/videolabs/mirrorbits
Issue: N/A
Commit: 9061cc3e06a00c04cd92965dae46850f2785a91b
Language: Go
Category: feature-request
Title: Add source generations and mirror sync points to scans
---

# Add source generations and mirror sync points to scans

Add sync points to mirror scans: the newest source state a mirror's listing is consistent with.

The first `ScanSource` starts source generation 1, and each later one that adds, removes, or changes the size or modification time of a file advances it by one. The new `SourceHistory` setting is how many recent generations we remember, read again at every source or mirror scan. A file version current in none of them is forgotten for good, even if the setting is raised later.

A listed file matches a version with the same size and modification time, compared at the protocol's precision. It is consistent with the generations where a matching version was current. Listed files matching nothing are no evidence. A remembered path missing from the listing means the mirror is at a generation without it. The exception is a path at or under an entry that a partial rsync transfer couldn't read: a directory it couldn't open (`rsync: opendir "..."`) or an entry it couldn't stat (`rsync: readlink_stat("..." (in <module>))`), both also seen as `rsync: [sender] ...`. Such a path is no evidence, and the mirror keeps serving it. The sync generation is the newest remembered generation consistent with all evidence, else 0.

`ScanResult` and the stored `Mirror` get `SyncGeneration` and `SourceGeneration`. You can assume every rsync mirror URL points at a module root and `FixTimezoneOffsets` stays off.
