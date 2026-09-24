---
Repository: https://github.com/microsoft/pict
Issue: N/A
Commit: ab76c2548f551fcb46314e58653a1bd1172f3a72
Language: C++
Category: feature-request
Title: Add negative values to the PICT engine and C API
---

# Add negative values to the PICT engine and C API

Add negative (out-of-range) values to the generation engine and its C API. Like the existing functions, each new function is declared in `pictapi.h` and listed in the exports of `api/pict.def`.

Add `PICT_RET_CODE PictSetNegativeValue(PICT_HANDLE parameter, PICT_VALUE valueIndex)`, which marks one value of a parameter negative. It returns `PICT_SUCCESS`, or a new code `PICT_INVALID_VALUE` (`0xc0000003`) when the index is past the parameter's last value or when the value is the only one of that parameter that is not negative.

`PictGenerate` then follows these rules. A row holds at most one negative value. Rows without a negative value cover every combination of non-negative values that the model's orders require. Each negative value is combined with non-negative values exactly as a non-negative value would be: every combination the orders require that includes that negative value, with all of its other values non-negative, appears in some row. The rules hold at every level of a model tree: inside a child model at the child's order, between the parameters and child models of a model at that model's order, and in trees nested more than one level deep. Exclusions still hold in every row, including exclusions between parameters of one child model and exclusions between parameters of different models of the tree. A seed with one negative value appears in a row; a seed with two or more negative values is not honoured. If the exclusions leave some parameter with no value that is not negative, `PictGenerate` returns `PICT_GENERATION_ERROR`.

`PictGenerate` can be called again on the same task, for example after marking more values negative. Each call replaces the rows with the ones for the model as it stands, and calling it again with nothing changed returns the same rows in the same order. `PictDeleteModel` on the root still frees the whole tree with every parameter in it, whether or not the task was generated.

Add `PICT_HANDLE PictGetResultParameter(PICT_HANDLE task, size_t column)`, which returns the parameter whose values fill that column of the rows from the last `PictGenerate` call, or a null handle for a column past the last one. After generation, `PictGetTotalParameterCount` returns the number of columns.

The command-line tool keeps its `~` syntax and its output format, and gets the same guarantees, including with sub-models and with seed files.
