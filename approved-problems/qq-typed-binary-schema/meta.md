---
Repository: https://github.com/JFryy/qq
Issue: N/A
Commit: 321eba7b1db4f42f7bd351e020f8e0fae6b0c354
Language: Go
Category: feature-request
Title: Add typed nested schemas to the avro and parquet codecs
---

# Add typed nested schemas to the avro and parquet codecs

We want avro and parquet writers in qq to produce output records according to a single typed schema that covers all input records. We want avro and parquet readers in qq to return the written records unchanged as one array, except for columns with mixed types, as explained further below, and values provided by avro and parquet readers to behave the same as native JSON values with the same content in jq expressions.

The writers take a list of objects or a single input object and produce one output row per input object. Empty lists and any other input produce errors. The output columns include names for all fields in the input objects. Fields that are null or missing in one or more input objects are nullable in outputs, and a missing field produces a null value in outputs. All other fields in outputs are not nullable.

Booleans and strings keep their type, integer values are cast to 64-bit integers (long in avro, int64 in parquet), and floating-point values are cast to doubles, with the JSON value 2.0 counting as floating-point. Columns that contain both integer and floating-point values are cast to double columns. Object and array columns are cast to nested record (struct in parquet) and list columns, whose fields and items are typed according to the same rules using all values at those positions. Other mixed-value columns are cast to string columns holding the compact JSON representation of the original value, including string values, so the string "x" becomes "\"x\"". Keys can be any string. When avro does not accept a key as a field name, the file must still be valid avro and the readers must still return the original key. You can assume that objects always have at least one key-value pair.
