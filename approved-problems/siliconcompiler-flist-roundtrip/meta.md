---
Repository: https://github.com/siliconcompiler/siliconcompiler
Issue: N/A
Commit: 6d3fea2a8d2f458f2ed0513d7fdaf043e4aa90f6
Language: Python
Category: feature-request
Title: Add a fileset graph round trip to the flist reader and writer
---

# Add a fileset graph round trip to the flist reader and writer

Add a way to write a Verilog file list that keeps the whole fileset graph and to read that list back into the same graph.

`write_fileset` takes a new `hierarchy` argument, defaulting to false and leaving the existing output unchanged. Under true, each group, meaning one design together with one of its filesets, is preceded by a comment line reading `// sc-fileset` followed by the design name and the fileset name. Immediately after each `sc-fileset` marker, emit one `// sc-depfileset` line, then the design name and fileset name, for each dependency edge the walk traversed from that group. `write_fileset` already takes a `depalias` mapping, keyed by a design name and fileset name pair and giving a replacement design object and fileset name. Apply it before recording each dependency edge. Write the edge under the replacement's name and fileset, and emit the replacement as that dependency's group. Groups stay in the existing order, every dependency ahead of the design that uses it. Under true the writer does not deduplicate: write every entry of every group as an active line, including an entry repeated within a group and one an earlier group already wrote.

A marked group carries the whole fileset, one part per line, in this order. The top module comes first as `-top` and the name. Then the include directories as `+incdir+` and the path, and the library directories as `-y` and the path. Then the defines as `+define+` and the definition, and the undefines as `+undefine+` and the name. Then the parameters, sorted by name, each written as `-G` immediately followed by the name, an equals sign and the value with no space anywhere, as in `-GWIDTH=8`. Then the library names as `-v` and the name. The files come last, grouped by file type name, and each run is preceded by a comment line reading `// sc-filetype` and that type's name. An empty part is left out.

`read_fileset` reads a marked list back. Lines before the first `sc-fileset` line go into the fileset named by its `fileset` argument. A group naming the design being read into is merged into that design under the fileset the marker names. Every other design name becomes a dependency, built once and reused across its groups, and each `sc-depfileset` line becomes a dependency fileset reference on the group that carries it. After parsing, add a dependency fileset reference from the fileset named by the `fileset` argument for each group that is not the reading design's own and that no `sc-depfileset` line references. A file takes the type named by the last `sc-filetype` line, and otherwise the type its extension implies.

The reader accepts every spelling above in any list, marked or not. A line of `-f` and a path, or of `-F` and a path, reads that list in place. Resolve an included-list path relative to the current list's path base. For `-f`, resolve the relative paths inside the pulled-in list against the directory the including list resolves its own against. For `-F`, resolve them against the pulled-in list's own directory. Do not read a list that is already open. A pulled-in list starts out with the group and the file type in effect where it is pulled in, and a group or a file type it opens applies only within it, so the list that pulled it in carries on with its own.

For each group, register a data root for each directory that holds one of its include paths, library directories or files, unless an existing root already contains that directory. The existing roots are the ones this read has already registered for the same design, and any root the design had before the read that was registered with a local directory path. A directory is inside a root only when that root is one of its parents, so a sibling whose name merely starts with a root's name gets a root of its own. Every path is recorded against a root that contains it, so no recorded path has to climb out of its root.
