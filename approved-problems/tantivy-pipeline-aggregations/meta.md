---
Repository: https://github.com/quickwit-oss/tantivy
Language: Rust
Issue: N/A
Commit: 1e859fd78d71986a7d53bc096b0fd27bfa91aec2
Title: Add Elasticsearch pipeline aggregations to the aggregation finalization engine
---
# Add Elasticsearch pipeline aggregations to the aggregation finalization engine

Extend the aggregation engine with Elasticsearch-compatible pipeline aggregations, evaluated after every other aggregation is finalized. Pipeline aggregations read no fast field; each consumes the output of another aggregation named by a `buckets_path`. A value reference inside a path is a sub-aggregation name (a single-value metric resolves to its value, and a multi-value metric is addressed as `name.property`), or the specials `_count` (a bucket's document count) and `_key` (its numeric key).

Sibling pipelines reduce a sibling multi-bucket aggregation, addressed as `aggregation>value`, into one metric placed beside it: `avg_bucket`, `sum_bucket`, `min_bucket`, and `max_bucket` serialize as a single `value`, while `stats_bucket` reports `count`, `sum`, `min`, `max`, and `avg`. Reducing an empty set of values yields zero for `sum` and null for the others.

Serial pipelines walk the parent's buckets in the order it emits them: `cumulative_sum` is a running total that treats a gap as zero and emits a value for every bucket; `derivative` is the current value minus the previous and emits nothing for the first bucket; `moving_avg` averages, for each bucket, the non-missing values among the `window` buckets that end at and include it by position, so a bucket still receives a value when its own value is missing as long as another bucket in that window has one.

`bucket_script` and `bucket_selector` evaluate a `script` over a map of named values. The script language has numeric literals, the variable names, the arithmetic operators `+ - * / %`, unary minus, parentheses, the comparisons `== != < <= > >=`, and `&& ||`, where comparisons and boolean operators yield one or zero; precedence runs from unary minus, through `* / %`, `+ -`, comparisons, `&&`, to `||`. `bucket_script` writes the result as a `value`; `bucket_selector` drops buckets whose result is zero.

A `gap_policy` of `skip` (the default) excludes a missing value, `insert_zeros` substitutes zero, and a value another pipeline left missing is itself a gap. Every per-bucket pipeline (`cumulative_sum`, `derivative`, `moving_avg`, `bucket_script`, `bucket_selector`) applies to a non-keyed `histogram`, `date_histogram`, `range`, or `terms` parent; one declared without such a parent, including at the request root, is an error. Within a level the per-bucket pipelines run before the sibling pipelines and in dependency order so one may read another's output (a cycle is an error), while sibling pipelines that do not reference each other are independent and their evaluation order is not observable. A `bucket_selector` removes its buckets after the value-producing per-bucket pipelines have run, so those values reflect every bucket while a sibling pipeline reducing the same parent sees only the buckets the selector kept.
