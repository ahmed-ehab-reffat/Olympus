# Solution approach - structured defined-name metadata

The implementation makes structured records the shared metadata representation
while retaining the old tuple vector as a compatibility projection. This keeps
the new public API simple and leaves existing formula parsers free to consume
the tuple form they already expect.

## Public and shared metadata

`src/lib.rs` adds the owned `DefinedName` record, including the optional
comment and the publish and workbook-parameter flags, the `DefinedNameScope`
enum, private structured storage on `Metadata`, and the default
`Reader::defined_names_metadata()` accessor. The existing `defined_names()`
method and its return type do not change.

## Format readers

`src/xlsx/mod.rs` reads `localSheetId` as the zero-based local owner, treats an
absent owner as workbook scope, and reads the OOXML booleans and comment. It
matches built-in state against the eight standardized SpreadsheetML names
instead of treating every `_xlnm.` spelling as built in. XML decoding
preserves escaped comment text and the distinction between an absent and empty
attribute. It then derives the compatibility tuples from the structured
records.

`src/xls.rs` reads the `Lbl` option flags and owning `itab`. BIFF uses zero for
workbook scope and positive one-based sheet indexes, so local owners are
converted to zero based. Publish and workbook-parameter state comes from bits
13 and 14. A following `NameCmt` is correlated with the preceding `Lbl`, and
its length-prefixed strings honor each compressed/Unicode option byte. The
owner remains separate from formula-token sheet references. Once formula
rendering is complete, the old tuple projection remains the input to worksheet
formula parsing.

`src/xlsb/mod.rs` reads the `BrtName` flag word and owner. The all-ones owner is
workbook scope; other owners are already zero based. Bits 15 and 16 provide the
new flags. The parser advances over the formula token and auxiliary payloads,
then decodes the trailing nullable wide comment without collapsing a present
empty string into null. It appends both forms in record order so later numeric
name references keep the same indexes.

`src/ods.rs` changes named-expression parsing to return structured records.
Top-level containers receive workbook scope, while a container encountered
inside a table receives that table's zero-based sheet index. ODF has no honest
equivalent for the five optional properties, so all are absent. The legacy
tuple projection is filtered to workbook-scoped records after content parsing,
preserving the pinned behavior that did not expose table-local names.

## Compatibility

No formula text is normalized and no structured records are sorted or
deduplicated. Excel tuple access and indexed formula parsing therefore remain
observable as before while the new API exposes same-spelled scoped records.
Readers without defined names retain empty vectors, and worksheet reads do not
rebuild or reorder the metadata.
