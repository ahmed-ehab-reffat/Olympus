---
Repository: https://github.com/onthegomap/planetiler
Issue: https://github.com/onthegomap/planetiler/issues/1148
Commit: 546486f63c00d56b9f697b5c4659aa40e30e6e5c
Language: Java
Category: feature-request
Title: Add schema composition to the configurable YAML profile loader
---

# Add schema composition to the configurable YAML profile loader

Add schema composition to the configurable YAML profiles in planetiler-custommap, so one schema file can build on others instead of repeating them.

A schema lists the schemas it builds on under `extends`, as one path or a list, each relative to the file that declares it. A name that is not a file is looked up among the bundled sample schemas, with or without the `/samples/` prefix.

`SchemaConfig.load` composes automatically. A new static `SchemaConfig.load(List<Path>)` overload composes the listed files as if the last one extended the earlier ones in order, resolving each name the same way, so a list of one behaves like loading that file alone. `--schema` accepts a comma-separated list handled like that overload. A new static `SchemaConfig.files(Path)` returns the files contributing to the schema at that path as absolute normalized paths, parents first and the root last, leaving out bundled samples, and the validator watches those files together with every local `examples` file they name.

Files contribute depth first in the listed order, and a file reached more than once contributes once at its first position. A cycle is a `ParseException` naming every file in it, and a missing parent or listed file is a `ParseException` naming that path. A schema loaded from a string has no file to resolve against, so a relative path there that does not name a bundled sample is a `ParseException` naming that path, while an absolute path resolves as usual.

Merging works per field:

- `schema_name`, `schema_description`, `attribution`, `version` and `is_overlay`: the last file that sets the field wins, and an unset field never erases an inherited value, even where the accessor would substitute a default.
- `sources` merge by id, a later definition replacing the earlier one entirely, and `tag_mappings` merge per key.
- `args` merge per name. A bare value stands for that argument's `default` in whichever file gives it, a later mapping overrides only the keys it gives, and every argument is settled together after composition, so a default may refer to an argument another file defines.
- `layers` merge by id. A layer with an inherited id keeps that position, its features are appended after the inherited ones, and its `buffer` and `tile_post_process` replace the inherited ones only when set. New ids are appended in order.
- A layer entry that sets `remove` to true and gives no other field drops the inherited layer together with its position. Removing an id that the earlier files did not contribute, or setting `remove` to true alongside any other field, is a `ParseException` naming the layer.
- `examples` are concatenated in contribution order, each file's `examples` path resolving relative to that file and nowhere else, and the composed schema carries them inline so the validator checks them against the composed profile.
- `definitions` are never inherited.

A file without `extends` keeps its `examples` reference untouched.
