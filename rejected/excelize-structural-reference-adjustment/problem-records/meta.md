Title: Keep worksheet metadata aligned during structural edits

Fix `InsertRows`, `RemoveRow`, `InsertCols`, and `RemoveCol` so classic comments, manual page breaks, and classic worksheet protected ranges continue to describe the same logical cells after each structural edit. The result must remain correct after writing and reopening the workbook.

For classic comments, update both the comment cell reference and its corresponding VML `Note` attachment and anchor. Preserve comment identity when a sheet has several comments. Remove a comment whose attached row or column is deleted, shift comments after the deleted position, and do not treat other VML object types as comments.

For manual page breaks, shift zero-based row or column break IDs at and after an insertion. On deletion, remove a break at the deleted boundary and shift later breaks. Keep `count` and `manualBreakCount` consistent with the saved collection.

For each classic worksheet protected range, adjust every space-separated area in its `sqref`. An insertion before an area shifts it; an insertion inside it expands it. A deletion before an area shifts it, a deletion inside it trims it, and a consumed single-cell area disappears. Remove the protected-range element only when none of its areas survives, and preserve its other attributes. Extension-list protected ranges, threaded comments, macros, and non-comment legacy controls are outside this task.
