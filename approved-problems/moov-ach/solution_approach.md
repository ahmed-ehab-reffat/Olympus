# Solution Approach - ApplyCorrections C+H+V

## Public operation

`File.ApplyCorrections(corrections ...*File) (*CorrectionResult, error)` processes
ordinary Notification of Change entries in argument and entry order. Accepted
notifications mutate the receiver. `CorrectionResult.Refused` contains classified
refusals and `CorrectionResult.Undo` contains executable inverse notifications.

The implementation is split by responsibility:

| File | Responsibility |
|---|---|
| `correction.go` | ordered processing, immutable indexes, refusal precedence, offsets, and receiver controls |
| `correction_target.go` | typed ordinary/IAT targets, snapshots, application, rollback, concrete validation, and inverse encoding |
| `correction_undo.go` | reverse journal construction and final-DFI resolution |
| `correction_refused.go` | canonical refused-NOC construction |

## Immutable typed matching

`newCorrectionIndex` records every ordinary and IAT receiver entry by the
call-start `(OriginalTrace, OriginalDFI)` pair. It also records the DFI population
separately so C61 and C62 remain distinguishable. The index never follows a routing
change, while each target points at the live entry so later accepted changes see
the current state.

Correction sources are deliberately narrower: only `EntryDetail` records in
ordinary supplied batches are scanned. Supplied IAT batches cannot inject a
notification.

## Ordered classification and tentative commit

Parsing and classification follow the public precedence: C65 parse failure, C61
unknown DFI, C62 unknown trace or ordinary offset target, C65 unsupported target
representation, C67 routing, then C69 transaction validity. C08 has a bounded raw
routing parser and is accepted only for IAT targets.

Corrected data is read through `Addenda98.ParseCorrectedData`, so incomplete
C03/C06/C07 layouts are C65 rather than partial mutations. For an otherwise usable
notification, the target captures all selectable fields,
applies the proposal, and runs two rollback gates. C05 first checks the live
concrete batch: ordinary batches use their own `InvalidEntries` implementation with
a temporary covering service class, and IAT batches are cloned and rebuilt. Offset
feasibility then observes every earlier acceptance. Either failure restores the
captured state and records C69; processing continues.

## Rebuild and output artifacts

Changed ordinary batches rebalance existing offsets before `Batch.Create`.
Changed IAT batches also rebuild their controls. A non-mixed service class follows
the rebuilt entry directions: CreditsOnly, DebitsOnly, or MixedDebitsAndCredits;
an existing mixed class is preserved. A final `File.Create` rolls batch counts,
hashes, and amounts into file controls.

Each acceptance stores its source header, source notification, typed target, and
immediate pre-state. After all forward work, Undo walks that journal backwards.
Every inverse Addenda98 uses the original call-start trace, the target's final DFI,
and canonical corrected data for the captured fields. Fresh ascending entry traces
are synchronized with the new addenda. Because applying Undo repeats the same
algorithm, the Undo produced by that call is a redo.

Refusals retain their L3 construction: one COR batch per source file with
refusals, source-header provenance, copied notification fields, and fully built
batch and file controls. Refused and Undo batches derive a covering service class
from their copied entry directions before validation.

## Verification

The 125-test external package exercises ordinary fields, complete composite-data
parsing, refusal precedence,
offsets, every inverse layout, routing chains, source immutability, bounded IAT,
ACK/ATX/DNE/ENR validation, and three-axis undo/redo interactions. Reflection keeps
the package compilable at the base commit, where every real entity fails. The
41-mutation matrix includes both observed Nova recipes, C06 forward omissions,
partial parsing, output service classes, and every C/H/V partial or pairwise
composite.
