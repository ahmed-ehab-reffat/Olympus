Title: Expose structured defined-name metadata across spreadsheet formats

Add structured defined-name metadata to every Reader implementation for XLS, XLSX, XLSB, and ODS.

Export `DefinedName` and `DefinedNameScope` from the crate root with `Debug`, `PartialEq`, and `Clone`. `DefinedName` has public `String` fields `name` and `formula`, a public `scope`, public `Option<bool>` fields `hidden`, `built_in`, `published`, and `workbook_parameter`, and a public `Option<String>` field `comment`. `DefinedNameScope` has `Workbook` and `Worksheet(usize)` variants. Add `Reader::defined_names_metadata(&self)`, returning a slice of `DefinedName`.

Worksheet indexes are zero based and refer to the order returned by `sheets_metadata()`.

Return records in source encounter order without merging duplicate spellings from different scopes. Preserve each format's current formula string exactly. For XLS, XLSX, and XLSB, `hidden`, `built_in`, `published`, and `workbook_parameter` are `Some(false)` or `Some(true)` according to the source format. The standardized XLSX built-ins are `_xlnm.Print_Area`, `_xlnm.Print_Titles`, `_xlnm.Criteria`, `_xlnm._FilterDatabase`, `_xlnm.Extract`, `_xlnm.Consolidate_Area`, `_xlnm.Database`, and `_xlnm.Sheet_Title`; other names are not built in merely because they use the `_xlnm.` prefix. XLS and XLSB use their encoded built-in flags. Read comments from each Excel format's native defined-name metadata. A missing or null comment is `None`, while an explicitly present empty comment is `Some("")`. ODS has no equivalent properties for these five fields, so all of them are `None`.

Use each format's own owner and flag definitions; do not infer scope from the formula or binary flags from the name's spelling.

Binary offsets are relative to decoded record bodies. In XLS, `Lbl` (0x0018) stores 16-bit flags at bytes 0..2 and `itab` at bytes 8..10. `itab` is 0 for workbook scope and otherwise a one-based worksheet index. Flag masks are hidden 0x0001, built-in 0x0020, published 0x2000, and workbook parameter 0x4000.

An XLS `NameCmt` (0x0894) belongs to the preceding `Lbl`. Its name and comment character counts are at bytes 12..14 and 14..16, followed by the two strings. Each string begins with an option byte whose bit 0 selects UTF-16LE when set and the workbook's single-byte encoding otherwise.

In XLSB, `BrtName` (0x0027) stores 32-bit flags at bytes 0..4 and `itab` at bytes 5..9. `itab` is 0xffffffff for workbook scope and otherwise a zero-based worksheet index. Flag masks are hidden 0x00000001, built-in 0x00000020, published 0x00008000, and workbook parameter 0x00010000. The nullable comment follows the parsed formula and auxiliary payload. It is encoded as a 32-bit character count plus UTF-16LE characters; 0xffffffff means `None`, and zero means `Some("")`.
