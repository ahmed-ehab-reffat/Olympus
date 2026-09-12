---
Repository: https://github.com/AmrDeveloper/GQL
Issue: N/A
Commit: 3a76cfee02a00ee6ce20eeac6447573b34f25d86
Language: Rust
Category: feature-request
Title: Extend window function evaluation with ordered cumulative frames
---

# Extend window function evaluation with ordered cumulative frames

Add ordered cumulative frame evaluation to GQL's window function engine, plus four new window
functions built on it: `RANK`, `DENSE_RANK`, `PERCENT_RANK`, and `CUME_DIST`.

When a window definition's `OVER(...)` includes an `ORDER BY` clause, every window function in that
call must instead be evaluated cumulatively, with the sole exception of `PERCENT_RANK` and
`CUME_DIST` described below: the row at position `i` in the ordered partition is evaluated against
the sub-frame containing only rows `0` through `i` of that ordered partition, not the whole
partition. Rows in the result stay in that ordered sequence; result rows are not restored to their
pre-partition order. Ties in the ordering key do not merge into one sub-frame boundary; the
sub-frame always extends strictly by row position. When no `ORDER BY` clause is present, every
function keeps evaluating against the whole partition.

All four take no arguments and require an `ORDER BY` clause, reporting a parse error when it is
missing. `RANK` and `DENSE_RANK` compute each row's rank from its position among the ordering key's
values within the partition. Rows whose ordering key is equal receive the same rank. `RANK` then
skips ahead by the number of tied rows for the next distinct value. `DENSE_RANK` never skips. When a
window orders by more than one expression, two rows tie only when every expression evaluates equal
between them.

`PERCENT_RANK` and `CUME_DIST` need the size of the whole ordered partition to compute their result,
not just the rows up to the current one. `PERCENT_RANK` returns `(rank - 1) / (n - 1)`, where `rank`
is the row's `RANK` value and `n` is the number of rows in the partition; a partition with a single
row returns `0`. `CUME_DIST` returns, for each row, the count of partition rows at or before its own
position in the ordered sequence, including every row tied with it, divided by `n`. Both formulas
follow the ordering direction the query specifies; reversing `ASC` to `DESC` reverses which row gets
which value, the same way it reverses `RANK`.
