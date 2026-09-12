# ERRORS - Calamine structured defined names

## Accepted residual limitations

- The final accepted prompt did not receive a fresh formal ten-run calibration
  batch. Level 1, Level 2, and the later exploratory batches belong to different
  immutable versions and must not be combined into a final solve rate.
- The accepted XLS fixture exercises a compressed ASCII `NameCmt` name and a
  non-ASCII UTF-16 comment, but not a non-ASCII comment decoded through a clear
  option bit and the workbook code page. This was identified after the accepted
  artifact froze; it is recorded rather than retroactively changing the suite.
- The private submission archive was unavailable during novelty review.
  Acceptance resolves the submitted problem outcome, not that historical
  limitation on prior-art evidence.

## Historical calibration findings

- Level 1 was too easy at 9/10 legitimate passes.
- Level 2 was also too easy: its first five working-pool agents all passed.
- The citation-only run-6 batch produced no pass, but Microsoft documentation
  returned HTTP 403 or empty documents. Its failures justified a self-contained
  field map rather than a claim that the task itself was unsolvable.

## Resolved design hazards

- Successful solver patches reached a median platform-reported sandbox LOC of
  284 without padding the 128-line strict reference. Raw production additions
  had a lower median of 153.
- Name ownership is not inferred from a formula's referenced sheet.
- BIFF's one-based owner and BIFF12's zero-based owner are handled separately.
- Binary built-in flags are not inferred from an `_xlnm`-looking spelling.
- ODS absence is represented as `None`, not an invented false flag.
- The exact `Reader` trait method is checked on concrete XLS, XLSX, XLSB, and
  ODS readers rather than only on the automatic wrapper.
- `Debug`, `PartialEq`, and `Clone` are stated and checked independently on
  both exported types.
- Local-scope assertions borrow `DefinedNameScope` explicitly. A no-`Copy`
  control passes, so the hidden suite does not impose an additional enum trait.
- ODS legacy tuples may remain workbook scoped or project all structured
  records; regression coverage accepts both exact ordered policies and rejects
  partial projections.
- Existing XLS/XLSX/XLSB tuple order and indexed formula consumers remain
  explicit regression safeguards.
- The runner searches both nextest report stores and emits a skipped compile
  placeholder, yielding zero unclassified wrapper entities.
- A BIFF8-only metadata implementation is rejected by the independent BIFF5
  owner and hidden probe.
- Empty workbooks are checked across concrete and automatic readers.
- Missing, empty, and non-empty comments are distinct; BIFF compressed and
  Unicode strings are exercised in one correlated record.
- XLS independently distinguishes a missing `NameCmt` from an explicitly
  present empty `NameCmt`.
- XLSB includes an `_xlnm`-looking name whose encoded built-in flag is clear,
  preventing spelling-based inference in that reader.
- XLSX includes all eight standardized built-in names plus nonstandard
  `_xlnm.UserDefined`, preventing both prefix-only over-acceptance and
  Print-Area-only under-acceptance.
- Publish and workbook-parameter masks differ between BIFF8 and BIFF12 and are
  checked independently.
- The 383-word public description states observable native metadata semantics,
  enumerates the standardized XLSX built-ins, and limits its binary field map
  to owner, flags, association, and comment framing needed for an offline
  implementation without prescribing storage or helper structure.
- Static workbook bytes are stored in neutral randomized `.txt` payloads.
  Every payload line has a literal `+`, so every added line appears with `++`
  in the unified diff, avoiding binary patch headers, binary-looking double
  extensions, and validators that inspect parsed hunk content.
- The hidden suite no longer selects an unstated ODS legacy projection: both
  coherent ordered policies pass.
- Equivalent OOXML boolean spelling and reversed ODS container-order probes
  remain excluded because they repeat existing failure families without a
  distinct discriminator.
