# Upstream audit - Biopython mmCIF biological assemblies

Audit date: 2026-08-11. Frozen pin:
`c9489604d1d9607602ca9199a3852c1219ed330f`.

All-state issue/PR searches covered `biological assembly mmCIF`,
`oper_expression`, `pdbx_struct_assembly_gen`, assembly materialization,
biomolecule transforms, and likely public function names. Fetched refs, full
history, source, tests, documentation, changelog, and recent branches were also
searched.

There is no equivalent structure materializer. Closed
[PR #3986](https://github.com/biopython/biopython/pull/3986) and
[issue #1875](https://github.com/biopython/biopython/issues/1875) add/request
downloading pre-generated biological-assembly files; they do not interpret
mmCIF operator expressions or transform a parsed `Structure`. Exact
`oper_expression` issue/PR search returned zero results.

Third-party scripts demonstrate that simple mmCIF assembly expansion is known,
but none is a Biopython implementation or fixes the public multi-model,
disorder, identity, and source-isolation contract proposed here. They must not
be copied into a reference solution.

Verdict: no unresolved upstream owner. Graph-materialization similarity remains
a local design risk, not an ownership cap.

