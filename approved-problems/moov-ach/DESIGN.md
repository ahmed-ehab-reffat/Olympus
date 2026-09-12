# DESIGN - moov-io/ach ApplyCorrections L4b

## 1. Calibration target

Six Nova runs solved L1 through L3 legitimately. Nova 5 and 6 both used an
immutable ordinary-entry index, ordered forward mutation, a one-entry rollback
snapshot, refusal collection, and a final offset/control rebuild. Nova 5 added IAT
targets without being asked; neither run built persistent inverse history or
validated C05 through the target's concrete batch rules.

L4 then produced 0 solves in Nova 7-12. All six failed the same IAT C05
service-class interpretation, while Nova 10 passed the other 118 tests and five
runs separately failed offsets. L4a therefore changes no behavior: it states the
directional service-class rule explicitly and retains all C+H+V+O tests.

Nova 13 passed 120/120 and Nova 14 passed 118/120. Panel review then proved Nova
13 was a false positive: its custom parser accepted incomplete C03/C06/C07 data
which the repository's `ParseCorrectedData` rejects. L4b closes that fair coverage
gap, adds direct C06 forward assertions, and fixes Refused/Undo service classes in
the reference without changing the task behavior.

## 2. Axes

### C - executable history

Every acceptance records the selected target fields immediately before mutation.
After all forward work, Undo emits those records in reverse acceptance order using
the target's final DFI. Applying Undo must restore stated receiver fields and
controls; its own Undo is redo. This requires persistent journal state, delayed
identity resolution, canonical composite inverse data, and fresh COR traces.

### H - bounded heterogeneous targets

One immutable index contains ordinary and IAT receiver entries. Ordinary targets
support the normal C01-C07/C09 layouts except C08. IAT targets support only C02 or
C08 routing, C05 transaction code, and C09 Addenda15 ReceiverIDNumber. The bound is
a fairness rule: valid IAT account and name values can exceed ordinary corrected
data layouts and therefore cannot always be inverted.

### V - concrete tentative validation

C05 is applied tentatively and checked through the target batch's own transaction,
amount, addenda, and SEC rules with staged controls and a covering service class.
Failure restores the target and becomes C69 before offset feasibility. ACK, ATX,
DNE, and ENR make globally known but locally illegal transaction codes observable.

## 3. Reference architecture

The golden implementation has four separable parts:

1. `correction.go` builds immutable ordinary/IAT keys, classifies notifications,
   sequences rollback gates, rebalances offsets, and rebuilds receiver controls.
2. `correction_target.go` encapsulates ordinary/IAT state capture, mutation,
   restoration, compatibility, concrete batch staging, and inverse encoding.
3. `correction_undo.go` resolves final DFI values and builds the reverse COR file.
4. `correction_refused.go` builds the carried L3 refusal artifact.

The source correction files are never staging storage. In particular, an undo
entry must replace the shallow-copied Addenda98 before generating its new trace;
otherwise `SetTraceNumber` aliases and mutates the source notification.
Refused and Undo batches share `createCorrectionBatch`, which chooses a covering
service class from their copied entry directions before `BatchCOR.Create`.

## 4. Shallow implementation ladder

| Plausible shortcut | Observable failure |
|---|---|
| Keep the L3 result and add an empty `Undo` field | accepted calls have no executable inverse |
| Emit inverse records online | a routing chain names an intermediate DFI |
| Use post-state as inverse data | Undo is an accepted no-op and cannot restore |
| Emit inverses in forward order | repeated same-target corrections restore the wrong state |
| Omit one C03/C06/C07 component | isolated inverse and full redo diverge |
| Reuse source traces | Undo validation or Addenda synchronization fails; source may mutate |
| Index ordinary entries only | every bounded IAT behavior becomes C61/C62 |
| Treat IAT like ordinary | unsafe codes apply or C08 is rejected everywhere |
| Mutate Addenda10 instead of Addenda15 for C09 | receiver identification remains stale |
| Rebuild only ordinary controls | IAT batch/file hashes disagree with entries |
| Use `StandardTransactionCode` as V | ACK/ATX/DNE/ENR accept locally illegal C05 values |
| Discover V at final rebuild | processing returns an error after mutating instead of a C69 refusal |
| Restore the entry but not history | a later same-target acceptance captures the wrong pre-state |
| Parse composite data field-by-field | incomplete C03/C06/C07 is accepted instead of C65 |
| Apply only one C06 component | account or transaction remains stale despite acceptance |
| Validate outputs under a copied source service class | mixed-direction Refused or Undo construction fails |
| Implement any one or two axes | three-axis interactions still fail |

## 5. Public fixtures and oracle

All fixtures use exported constructors and a fixed file date/time. Ordinary PPD
fixtures carry credit/debit offsets named `OFFSET`. IAT fixtures construct all
mandatory Addenda10 through Addenda16. Specialized fixtures mirror upstream public
examples for ACK, ATX, DNE, and ENR.

The oracle is public repository behavior: `ParseCorrectedData`, `InvalidEntries`,
`Batch.Create`, `IATBatch.Create`, `File.Create`, `Validate`, `Writer`, and
`Reader`. Tests assert public fields and controls, never error text or a private
helper. The reflection adapter discovers `ApplyCorrections` without naming
`CorrectionResult`, so the test package compiles at the base commit and every
named test fails through `FailNow`.

## 6. Description-to-test ledger

| ID | Atomic public requirement | Representative named tests |
|---|---|---|
| M01 | `CorrectionResult` has Refused and Undo; the method mutates the receiver | `AccountNumber`, `MixedResultHasRefusedAndUndo` |
| M02 | Only ordinary supplied entries are notification sources, processed in argument/entry order | `NotificationsInsideIATSourceAreIgnored`, `UndoReversesAcrossFiles` |
| M03 | No notification returns nil; otherwise empty children are nil | `ResultIsNilWhenThereAreNoNotifications`, `AllRefusedResultHasNoUndo`, `NilWhenNothingRefused` |
| M04 | Match by call-start trace and DFI even after routing changes | `AsSentChainAcrossFiles`, `RoutingChainUndoUsesFinalDFI`, `IATMatchesAsSentRoutingAcrossChain` |
| M05 | Targets include ordinary and IAT entries | ordinary field tests; all `IATC*` tests |
| M06 | Ordinary C01-C07/C09 change only selected fields and routing check digit | `EveryCorrectedField`, `RoutingAndAccountNumber`, `AccountNumberAndTransactionCode`, inverse tests |
| M07 | IAT supports only C02/C08, C05, and C09 Addenda15 | `IATC02ChangesRouting`, `IATC08ChangesRouting`, `IATC05ChangesTransactionCode`, `IATC09ChangesReceiverIDNumber` |
| M08 | C08 ordinary and ordinary-only IAT codes are C65 | `C08OnOrdinaryTargetIsC65`, `IATC01IsC65`, `IATUnsupportedCodeBeatsBadRouting` |
| M09 | Every notification independently applies or is refused and later work continues | `RefusalDoesNotStopALaterOneOnTheSameEntry`, `ENRRefusalRollsBackBeforeLaterAcceptance` |
| M10 | C65 parse/no field, including incomplete composite data, precedes C61/C62/type/routing/transaction checks | `UnreadableDataBeatsBadInstitution`, `IncompleteRoutingAndAccountDataIsC65`, `IncompleteCompositeDataIsC65` |
| M11 | Unknown DFI is C61; unknown trace in known DFI is C62 | `UnknownInstitutionIsC61`, `KnownInstitutionUnknownTraceIsC62` |
| M12 | Ordinary OFFSET targets are C62 before routing checks | `OffsetEntryCannotBeCorrectedIsC62`, `OffsetTargetBeatsBadRoutingNumber` |
| M13 | Target incompatibility is C65 before routing/transaction checks | `IATUnsupportedCodeBeatsBadRouting`, `OrdinaryC08RefusalLeavesRoutingUnchanged` |
| M14 | Bad routing is C67 and precedes transaction checks | `UnusableRoutingNumberIsC67`, `BadRoutingNumberBeatsBadTransactionCode` |
| M15 | Concrete transaction/amount/addenda/SEC failure is C69 with rollback | ACK/ATX/DNE/ENR reject tests; `ENRRefusalRollsBackBeforeLaterAcceptance` |
| M16 | Valid concrete alternatives still apply | ACK/ATX/DNE accept tests; `PrenoteCodeOntoZeroAmountEntryApplies` |
| M17 | Offset feasibility sees earlier acceptances and failure is C69 | forward/reverse offset-feasibility tests; `OffsetAcceptanceVRefusalAndIATRedo` |
| M18 | Existing offsets retain identity and balance from the opposite direction | credit/debit/both-offset rebalance and count tests |
| M19 | Refused has one ordered COR batch per source file with stated header provenance | `OneBatchPerSourceFileInArgumentOrder`, refused header tests |
| M20 | Refused entries copy source fields and carry the refusal code plus the notification's original values; `OriginalTraceField()` exposes the padded trace | `RefusedEntryCopiesTheNotificationEntry`, `RefusedAddendaCarriesTheOriginalNotification`, `TraceSequenceNumberIsTheLastSevenOfTheNotificationTrace` |
| M21 | Undo uses receiver header and the last acceptance's source header | `UndoHeaderComesFromLastAcceptance` |
| M22 | Undo contains acceptances only, including no-ops, in reverse order | `RefusalIsExcludedFromUndo`, ordinary/IAT accepted-no-op tests, `UndoReversesAcrossFiles` |
| M23 | Undo entries are zero NOC records with fresh synchronized ascending traces | `UndoUsesFreshSynchronizedTraces` |
| M24 | Each inverse keeps its code and uses call-start trace plus final post-call DFI | `RoutingChainUndoUsesFinalDFI`, `IATMatchesAsSentRoutingAcrossChain` |
| M25 | Inverse data captures immediate pre-state, including every composite field | eight `UndoC*EncodesPrior*` tests; `UndoOfUndoReproducesPostForwardState` |
| M26 | Applying Undo restores ordinary/IAT fields, offsets, hashes, totals, and counts | `UndoRestoresOffsetsAndControls`, `IATUndoRestoresAllSupportedFields` |
| M27 | Undo of Undo is redo and reproduces post-forward state | ordinary/IAT redo tests; `OffsetAcceptanceVRefusalAndIATRedo` |
| M28 | Both outputs and changed receiver batches/files have built controls | refused controls test; IAT controls/round-trip; offset control tests |
| M29 | Use CreditsOnly for only credits, DebitsOnly for only debits, and MixedDebitsAndCredits for both; preserve an existing mixed class | directional, mixed-preservation, and Refused/Undo covering-class tests |
| M30 | Correction inputs remain unchanged and notifications are not added | two source-immutability tests; `CorrectionEntriesAreNotAdded` |

`unmapped_meta_clauses = 0`

`unstated_test_requirements = 0`

## 7. Verification policy

The final suite has 125 named entities. The pristine four gates require 1534/1534
baseline passes, 125/125 real base failures with zero errors, 125/125 solution
passes, then 1534/1534 baseline passes again. Entity census, 41 mutation gates,
gofmt, targeted vet, ASCII/leak scans, patch apply/whitespace checks, and byte-equal
reference patches follow. Dockerfile is unchanged.
