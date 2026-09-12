# DESIGN - dnsjava atomic IXFR application

Status: `rejected as previously implemented; archived; calibration closed at 0/10`.

Repository: `dnsjava/dnsjava` at
`06a0599933114f36efe59667cd80ee0246a1a882`.

Task type: `enhancement`.

## Public contract and repository evidence

The public operation is frozen as
`void Zone.applyIXFR(ZoneTransferIn transfer)`, with the checked failures already
used by the transfer and zone constructors. It runs a stored-result transfer for
the same origin. A current response is a no-op and an AXFR response is rejected.
For an IXFR response it validates the complete oldest-to-newest chain against
the zone's current SOA, applies every delete before every add, and publishes one
complete final zone. Failed transfer, validation, or application leaves the zone
unchanged; the transfer's exposed delta lists remain unchanged.

Serial continuity follows the repository's `Serial` RFC 1982 helper. Each delta
is framed by its deleted and added apex SOAs, records must have the zone's class
and lie within its origin, a requested deletion must exist in the staged state,
and the final records must satisfy the same SOA/NS invariants as a newly
constructed `Zone`. On success all ordinary Zone observations—SOA/NS accessors,
exact and wildcard lookup, RRsets and RRSIGs, iteration, and master-file
serialization—represent that final record set. One read performed concurrently
with the operation may see the complete old or complete final value, never an
intermediate RRset; separate calls are not promised one shared generation.

These obligations join mature repository surfaces rather than inventing a new
format. `ZoneTransferIn.BasicHandler` already materializes ordered public
`Delta` objects, the parser already distinguishes current/IXFR/AXFR responses,
`Zone.fromXFR` accepts only AXFR construction, `Zone.validate()` establishes the
apex invariants, and `Zone` documents a read/write-lock thread-safety model.
Staging containers, copy-on-write, wholesale map replacement, validation order,
and exception wording remain implementation choices.

## Trajectory-informed design gate

Before artifact authoring, `PROBLEM_DESIGN.md` was reread and searches were
repeated across `problems/README.md`, both candidate registries,
`candidates/SUCCESSES.md`, the dnsjava candidate record, and problem/archive
folders for dnsjava, IXFR, zone transfer, RFC 1982/1995, transactional update,
rollback, staged publication, and reader atomicity. There is no prior dnsjava
problem or solver trajectory.

The closest raw history is the archived transactional 3D Tiles publication
problem. Its manifest plus representative `eval-result.json`, `run.txt`,
solution patch, and agent messages were inspected directly. The existing
dnsjava disposable trials are additional repository-specific evidence.

| Evidence role | Problem / run / trial | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | `3d-tiles-atomic-output`, `agent-runs/Nova_Nova_3` | 30/30 focused, 869/869 baseline | Built and validated a complete candidate before one publish boundary, with backup/restore and owned cleanup; 394 additions and 33 deletions in two production files. It establishes staging as legitimate without prescribing a private representation. |
| Near-pass | `3d-tiles-atomic-output`, `agent-runs/Nova_Nova_2` | 26/30 focused, 869/869 baseline | Independently staged and published atomically but violated the repository's adjacent public error convention. Atomic rollback does not subsume transfer modes, input ownership, or zone validity. |
| Broad behavioral failure | unavailable | retained run 1 failed before behavioral execution because required tooling was absent | The environment failure is recorded as unavailable and is not used as behavioral evidence. |
| Repository-specific legitimate A | disposable staged-list implementation | 5/5 focused, 1,744 complete tests | One production file and 110 additions; reconstructed a validated candidate `Zone`, preserved caller lists, and published under one write lock. |
| Repository-specific legitimate B | disposable canonical-map implementation | 3/3 focused, 1,742 complete tests | One production file and 114 additions; used a distinct `TreeMap<Record, Record>` candidate and passed the same state/rollback/reader families. |
| Repository-specific shortcut | disposable per-record mutant | atomicity probe failed on all four Surefire attempts | A 22-addition loop through public add/remove methods exposed cardinalities 1,480, 1,460, 1,482, and 1,436 during a 1,500-record update. |

RFC 1995 was read as primary domain evidence. It orders each difference as
deletions then additions, sequences differences oldest to newest, and requires
the older version to be replaced only after every difference is successfully
processed. It does not prescribe dnsjava's staged representation.

## Discriminator ledger

| Observed behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| IXFR responses may contain several deltas. | Apply only the last pair. | Every oldest-to-newest delta contributes to the final zone. | A first delta adds a record retained through a later delta. | Chain replay | Accepts any representation and replay loop. |
| `Serial` implements cyclic arithmetic. | Compare serials as ordinary signed or unsigned integers. | Valid wraparound chains apply under RFC 1982. | Apply `0xFFFFFFFF` to `1`. | Serial domain | Uses the repository helper's public semantics. |
| BasicHandler frames delete/add sections with SOAs. | Trust mutable start/end fields or the final SOA alone. | Declared serials, apex SOAs, and adjacent boundaries agree with the current zone. | Mutated boundary or out-of-sync wire response fails before publication. | Transfer framing | Checks response semantics, not parser internals. |
| Zone mutations ignore absent deletes. | Reuse permissive remove behavior. | IXFR divergence is rejected and leaves the exact old zone. | A middle deletion absent from staged state fails after an earlier valid deletion. | Divergence/rollback | The strict policy is explicit; TTL-insensitive Record equality remains accepted. |
| The per-record mutant exposed partial RRsets. | Validate first but publish record by record. | One concurrent exact lookup sees one complete generation. | A controlled large-RRset lookup observes only complete old/final content. | Publication/read boundary | Does not require iterators, cross-call snapshots, or one lock architecture. |
| Zone caches SOA, NS, origin node, and wildcard state. | Replace base records but leave derived state stale. | All ordinary read surfaces equal a freshly built final zone. | Replace SOA/NS, add wildcard, then compare accessors and lookups. | Derived-state rebuild | Semantic observations accept any cache strategy. |
| RRSIG joins its covered RRset. | Treat signatures as unrelated types or drop them during staging. | Signed RRsets replay data and signatures together. | Delete/add a signed RRset and inspect covered lookup/iteration. | RRset representation | Follows existing `RRset` behavior. |
| Delta lists remain publicly accessible. | Consume, clear, sort, or rewrite caller lists. | Applying does not mutate the response lists or records. | Snapshot parsed deltas before and after apply. | Input ownership | Allows internal copies, maps, or reconstructed zones. |
| The parser distinguishes current and AXFR fallback. | Treat null deltas as success or install AXFR implicitly. | Current is unchanged; AXFR is rejected unchanged. | Exercise both real response modes and serialize state around the call. | Producer mode | The prompt explicitly chooses the method's scope. |
| `Zone.validate()` requires apex SOA and NS. | Publish before final validation. | Invalid final zones never become visible. | Delete the last apex NS and verify rejection plus rollback. | Final validity | Reuses the repository's constructor invariant. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Public method and matching origin | Reflective public-signature check plus foreign-origin rejection | missing/fail | pass | existing public `Zone` mutation and transfer constructor conventions |
| Complete multi-delta application | Parsed two-delta response updates all state surfaces | missing/fail | pass | RFC 1995 and BasicHandler order |
| RFC 1982 serial chain | Wraparound transfer | missing/fail | pass | repository `Serial` helper |
| Current/AXFR modes | Current no-op and fallback rejection | missing/fail | pass | existing `ZoneTransferIn` mode APIs |
| Exact staged deletes and rollback | Missing delete after valid prior work | missing/fail | pass | explicit prompt policy and Record equality |
| Final validity and record ownership | Last-NS deletion and out-of-zone/class additions | missing/fail | pass | `Zone.validate()`, `Name.subdomain`, `getDClass()` |
| RRset/RRSIG and derived state | Signed-data change plus SOA/NS/wildcard queries | missing/fail | pass | existing RRset and Zone lookup semantics |
| Caller ownership | Before/after delta-list equality | missing/fail | pass | public `Delta` list exposure |
| Reader atomicity | Controlled single exact lookup during application | missing/fail | pass | documented Zone thread safety and public lookup copy |

## Environment and harness preflight

- The pristine frozen pin passed 1,739 Maven tests with 29 skips offline as UID
  12345 in `maven:3.9.11-eclipse-temurin-17`.
- Two temporary implementations and the direct-loop mutant executed in that
  same dependency cache and network-disabled runtime.
- The submitted Dockerfile builds the untouched checkout, populates Maven's
  dependency cache during image construction, removes root-owned build output,
  and makes the copied tree writable for an arbitrary runtime UID.
- Feature tests live at the additive random-suffix path
  `ZoneIXFRApply0db94eTest.java`. Calls use reflection so pristine execution
  reaches all named JUnit tests instead of failing compilation on the absent
  API. `test.sh` selects either four directly relevant existing classes or the
  feature class and aggregates Surefire XML.

## Exact-version closure

The final suite contains seventeen named black-box cases. Four probes were
admitted after the exact coverage audit because they cross independently
implemented public boundaries: transfer-receive rollback, delete-side class
validation, delete-before-equivalent-add ordering, and add-side reader
atomicity. A proposed demand that a foreign-origin transfer be rejected before
`run()` was removed because the prompt specifies rejection and rollback, not
validation order. Current responses are likewise required to run at least once,
not exactly once.

Three focused mutants passed the predecessor thirteen-test set and failed only
their new final discriminator: reversed delete/add order, skipped delete-side
class validation, and destructive cleanup after a transfer exception. Their
mutation diff hashes are `3f83089ae5aa`, `5b98069a32bd`, and `d7daa8320d8d`.
The 22-addition in-place trial failed both delete- and add-side atomicity probes
and five other semantic cases while still passing all 121 selected existing
tests. Both legitimate staged architectures passed all 17 final cases and the
121-test base lane.

The final artifacts are bound by `ARTIFACTS.sha256`. Cold Phase A, exact Phase
B, the 1,756-test combined suite, gap analysis, fairness analysis, and the
false-positive audit all pass. No solver calibration run has been made or
counted.

## Design verdict

The exact version was locally valid, but the user later reported a platform
rejection because the feature had already been implemented before. That
external outcome supersedes the earlier local ownership/design approval. Close
the task at 0/10; do not calibrate, resubmit, reword, or add artificial behavior
to rescue it. The technical evidence remains archived for duplicate detection.
