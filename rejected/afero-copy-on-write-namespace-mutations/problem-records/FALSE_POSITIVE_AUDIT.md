# False-positive audit — Afero copy-on-write namespace mutations, version 3

Verdict: `pass`.

Repository pin: `768f1fb0e5535b77d90e44c531aacd652aabd96a`.
The exact environment, gap, and fairness gates passed before this approval.

Immutable artifacts:

- prompt: `7c54baa9a4250d090542bc73a866b8c9f87dd869a13b8791768a5a260ff4af8a`;
- test patch: `0d882efc4555640ebeba57de65c64de300690ba5c1b1047ffeaeb4a1201b4cd1`;
- reference: `65939f4dc645bb3407d00b8a644e521b3a38e0b42ebbc97074fbb31debbf90a1`;
- Dockerfile: `33c69a5c4ac80b747abb40dcd63c8fbbb29f96476ea1b8189fc14af7d66fc72f`;
- mandatory redirect replay:
  `1889804c3febd969a054e5c3f08aff0a5d3330bdec039eada6a266189f7d18ae`.

## Requirement map

| Participant-facing behavior | Strongest discriminator |
|---|---|
| successful exact removal hides lower state from lookup and enumeration | overlapping/base-only/layer-only file and empty-directory checks, including paged iteration |
| missing and non-empty `Remove` preserve ordinary semantics | second removal plus independent merged and base-only non-empty directories |
| `RemoveAll` removes the full logical subtree and absent removal is nil | mixed lower/upper subtree followed by exact recreation; absent path call |
| recreated directories remain opaque while new contents work | `Mkdir` and `MkdirAll` lifecycles with stale lower children |
| rename moves complete base-only, layer-only, overlapping, and merged sources | file and nested-directory moves across all producer modes |
| replacement removes stale destination state | distinct base and layer children at directory destination plus an overlapping file destination |
| content, modes, deletion state, and opacity survive repeated moves | two-renames lifecycle with removed and recreated descendants and `0750`/`0600` modes |
| cleaned spellings share one state | OS-backed remove and rename through `..` and `.` aliases |
| errors do not expose partial pre-commit views | early fault and second-rename fault, each accepting either full success or unchanged error |
| base and internal bookkeeping remain untouched/invisible | direct base reads and exact public directory sets throughout |
| existing support remains intact | complete 176-case root-module lane |

## Isolated mutation ledger

Each mutant starts from the exact reference and changes one logical decision.
Every run compiles the full tagged package set and executes the seven focused
testcases offline as UID/GID 10001.

| Mutant | Plausible shortcut | Focused result | Strongest failure |
|---|---|---:|---|
| `layer_remove` | delegate `Remove` to the upper backend | 4/7 | lower names remain/reject base-only removal |
| `layer_rename` | delegate `Rename` to the upper backend | 1/7 | base/merged sources and old lower names are wrong |
| `clear_opaque` | clear both exact and opaque state on recreation | 5/7 | stale lower children return |
| `no_dest_opaque` | omit opacity at a replaced directory | 6/7 | stale lower destination child remains |
| `no_source_hide` | publish destination without hiding lower source | 1/7 | source paths reappear |
| `raw_paths` | index namespace state by uncleaned caller strings | 6/7 | OS alias lookup sees the lower file |
| `no_mode` | materialize with fixed `0777`/`0666` permissions | 6/7 | repeated base-only rename reports wrong modes |
| `remove_missing_nil` | make missing `Remove` idempotent | 6/7 | required not-exist error is lost |
| `remove_nonempty` | skip logical-directory emptiness validation | 6/7 | non-empty removal succeeds |
| `rename_rollback` | do not restore destination after a later rename fault | 6/7 | error path loses staged destination entries |

No actionable mutant survives its strongest focused discriminator, so no killed
mutant was escalated to the full suite.

## Survivors and rejection analysis

Two compiling variants pass all 7/7 focused tests and the complete pre-existing
suite at 176/176 with one skip:

1. `late_remove` records a lower hide before attempting removal of an existing
   upper shadow. If the upper removal reports an error without deleting the
   entry, the upper entry still defines the entire public view. The state timing
   is unobservable, and requiring a private ordering would be unfair.
2. `recreate_file` retains an exact lower tombstone after a new upper file is
   created at that name. The new upper file is visible and the old lower file is
   hidden exactly as required. Clearing a private tombstone is not a public
   obligation.

Both are rejected as observationally equivalent implementations, not actionable
false positives. A proposed backend that mutates and then returns an error, a
specific marker filename, extra path spelling permutations, and persistent or
concurrent state were likewise rejected as artificial, private, redundant, or
out of scope.

## Revision and replay history

The initial focused suite exposed weak independent cells rather than being
approved immediately. Version 2 added missing-remove, exact file recreation,
`MkdirAll` opacity, modes, and repeated rename. Version 3 added layer-only
removal/rename, a mixed `RemoveAll`, base-only non-empty removal, base-only file
rename, and a later-stage rollback probe. Each test-patch revision invalidated
the environment verdict; the final Phase A/B gate restarted from the untouched
pin and passed.

On the final hash, pristine fails behaviorally in all 7/7 focused testcases and
has no startup errors. The eager reference and lazy redirect replay each pass
176/176 base cases with one skip and 7/7 focused cases. The reference and
redirect combined trees are `df3a8a2ae2cb3ceef4091404d7a744793663c75d`
and `5b9d2f7a6c81d46650236908661b9c8e29d30953`, respectively.

The zero actionable survivors verdict is evidence for this repository- and
trajectory-supported mutation set, not proof that false positives are
impossible. Calibration remains 0/10; no solver run was counted.
