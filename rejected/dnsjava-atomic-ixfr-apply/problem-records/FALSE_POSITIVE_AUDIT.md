# Exact-version false-positive audit

Status: `pass; calibration 0/10`.

Repository pin: `06a0599933114f36efe59667cd80ee0246a1a882`.

Artifact binding: `meta.md` `1f5811dd46c`, `test.patch` `6056f8559e83`,
`solution.patch` `b48dd4dba68b`, and Dockerfile `df08c4461aa6`.

## Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| public method | `exposesTheRequestedPublicMethod` |
| complete chain and all derived reads | `appliesEveryDeltaAndRebuildsAllZoneViews` |
| RFC 1982 | `acceptsRfc1982SerialWraparound` |
| current/AXFR/origin modes | three dedicated unchanged-state cases |
| receive-failure rollback | `transferFailureLeavesTheCompleteZoneUntouched` |
| absent-delete rollback | `absentDeleteInALaterDeltaRollsBackEarlierWork` |
| final SOA/NS validity | `invalidFinalZoneRollsBackLastNameserverDeletion` |
| origin/class in both directions | add-side combined case plus delete-side wrong-class case |
| SOA framing and serial continuity | `rejectsMalformedBoundariesAndBrokenDeclaredSerials` |
| delete identity and ordering | TTL identity case plus equivalent delete-before-add case |
| caller ownership | `leavesParsedDeltaListsAndRecordsUntouched` |
| atomic remove/add publication | two deterministic concurrent exact-lookup cases |

## Plausible incorrect implementations

The initial suite already challenges last-delta-only replay, ordinary numeric
serial comparison, trusted mutable serial declarations, permissive absent
deletes, stale derived state, lost RRSIGs, input-list mutation, AXFR-as-empty,
publish-before-final-validation, and per-record publication. Trial C is the
repository-native shortcut: 22 additions calling existing public add/remove
methods. It passes the 121-test base lane but the final feature lane reports six
failures and one error, including both atomicity directions.

The final audit isolated three predecessor survivors:

| Mutant | Mutation hash | Predecessor 13 | Final 17 | Targeted result |
|---|---|---:|---:|---|
| apply additions before deletions | `3f83089ae5aa` | 13/13 | 16/17 | only `appliesDeletionsBeforeEquivalentAdditions` fails |
| validate delete names but omit delete classes | `5b98069a32bd` | 13/13 | 16/17 | only delete-side wrong-class case fails |
| clear live data after `transfer.run()` throws | `d7daa8320d8d` | 13/13 | 16/17 | only transfer-failure rollback case fails |

All three compile, run through the real wire fixture, and fail behavioral
assertions. None is killed by compiler failure, JUnit startup, anonymous hooks,
permissions, timeout, or environment setup. After the four admitted probes,
no mutant in the attempted public-defect set survives the current focused
suite, so there is no current survivor to escalate to the complete pre-existing
suite. The reference plus all hidden tests nevertheless passes the complete
combined 1,756-test tree; both alternate legitimate architectures pass every
scored lane.

## Rejected and artificial mutations

Null records, impossible empty handler deltas, extra section SOAs injected only
by mutating parser results, an already-staged out-of-zone deletion, fixed
exception messages, validation-order sentinels, container-type checks, and
iterator/cross-call snapshots were rejected as artificial or private. More
record types, delta counts, and serial permutations were rejected where they
reuse an already challenged semantic branch.

The early foreign-origin-before-run assertion was itself removed as a fairness
false positive. The direct trial's seven final failures are not counted as
seven isolated mutants; it is one broad shortcut replay. A zero-survivor result
is evidence only for this attempted mutation set, not proof that no false
positive can exist.

## Verdict

`Pass` for the exact artifacts. There are no actionable survivors in the
repository- and trajectory-grounded set, and every admitted probe contributes a
distinct public discriminator. Any artifact change restarts the audit from
zero.
