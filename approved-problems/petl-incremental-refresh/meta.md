---
Repository: https://github.com/petl-developers/petl
Issue: N/A
Commit: aa03e269637d6b5abf21d71180cb37f687a2c7cb
Language: Python
Title: Add incremental refresh to petl table pipelines
---
# Add incremental refresh to petl table pipelines

Add a layer that keeps the result of a table expression materialized and brings it up to date from the rows its sources gain.

`etl.feed(header, rows=())` returns a source table with `append(row)`, `extend(rows)`, `discard(index)`, which drops the row at that position and leaves the other positions where they are, `discards()` for the positions dropped so far, `rows_from(index)` for the rows held from that position on, and `rows_read`, a count of the data rows it has handed out, by iteration or by `rows_from`.

`etl.incremental(table)`, also `table.incremental()`, walks an expression over feeds and returns a pipeline, itself a table yielding the header then the materialized rows. Building it works the expression out once; later changes become visible only once `refresh()` has run. A pipeline can stand where a feed does: one leaf node of kind `pipeline`, taking in what the inner output gained or lost since the outer pipeline last looked.

`refresh()` returns a record carrying `added`, the rows the output gained, `removed`, the rows it lost, `emitted`, a mapping from node id to the number of rows that node gained plus the rows it lost, every node in the plan, zero included. Gains and losses are multiset differences, so equal rows count one by one. `added` reports a row once for every copy the new output holds beyond the old one, taking those copies in the order the new output holds them, so the earliest copies are the ones reported and a later copy of a row already reported is passed over; `removed` reads the previous output the same way. The refreshed output has to equal, row for row and in order, what the same expression yields worked out from scratch.

A refresh takes in only what a feed gained or dropped since the last one, and a caller-supplied callable (a select predicate, an addfield value, a converter) reaches only the copies a refresh gained, each copy once, and an aggregation runs for each group the refresh changed. A refresh that raises leaves the pipeline as it was, and the next one does that work again.

Three things follow from that and are worth stating plainly. A node holds copies rather than values, so two equal rows each carry their own result and a copy that leaves takes its result with it. A node's input can lose rows as well as gain them, whether the loss comes from a discard, a window that slides, an outer join whose match arrives, or an inner pipeline. And a refresh that raises leaves the same gains and losses waiting for the one after it, wherever they came from.

`pipeline.checkpoint()` returns the state needed to resume: the plan text under `plan`, each node's state keyed by node id. It survives a JSON round trip unchanged. `etl.resume(table, checkpoint)`, also reachable as `table.resume(checkpoint)`, builds a pipeline over an expression carrying the same plan, picking up where the checkpoint left off without reading a feed or applying a callable. A checkpoint taken from a different plan raises `IncrementalError` mentioning the plan.

Supported are feeds, `cut`, `addfield`, `convert`, `select`, `cat`, `sort`, `distinct`, `head`, `join`, `leftjoin` and `aggregate`. Anything else, including a plain list of rows and a row slice that is not a `head`, raises `IncrementalError` naming the class. Node ids read `kind#n`, numbered from 1 in the order nodes are first reached by a post-order left to right walk; a table reached twice is one node whose rows are read once. `plan()` returns a string with one line per node in that order, `"<id>: <child ids joined by a comma and a space>"`, or `"<id>: -"` for a leaf.
