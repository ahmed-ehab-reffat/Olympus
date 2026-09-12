# Biopython mmCIF biological-assembly materialization - candidate summary

Status: **rejected and retired 2026-08-14**.

The earlier Phase A verdict is superseded. It used `python:3.13-bookworm`
rather than an Olympus-approved base image and did not validate the required
`WORKDIR /app` evaluator layout. Olympus also did not recognize the upstream
`LicenseRef-Biopython-License-Agreement`; no permitted-license confirmation
was obtained. This candidate must not be submitted or returned to the
shortlist on the strength of the recorded local runs.

- Repository: [`biopython/biopython`](https://github.com/biopython/biopython)
- Pin: `c9489604d1d9607602ca9199a3852c1219ed330f` (2026-08-06)
- Production language: Python
- Task type: feature request
- Final rating: **3/10 (hard-gate rejection)**

## Candidate

Add a public `Bio.PDB` operation that materializes a selected biological
assembly from mmCIF `_pdbx_struct_assembly_gen` and
`_pdbx_struct_oper_list` data. It must evaluate lists, ranges, and Cartesian
products of operators; select the named asymmetric units; compose transforms
in the specified order; expand every model and disordered atom; allocate
deterministic collision-free output identities; and leave the source structure
unchanged.

Biopython already parses mmCIF structures and exposes the raw categories, while
its MMTF path models biological transforms. No equivalent mmCIF structure
materializer exists.

## Why it survived

- Exact searches for biological-assembly materialization and
  `oper_expression` found no issue, PR, branch, or implementation. PR #3986
  only downloads assembly files.
- Existing mmCIF fixtures supply repository-native operator and assembly data;
  coordinates can be calculated directly from their public matrices.
- Single-operator, first-model, shallow-copy, identity-collision, wrong-product
  order, and disorder-flattening implementations are behaviorally distinct.

## Main risk

This resembles graph copy/materialization. Promotion requires a prototype to
show that operator grammar, transform composition, multi-model/disorder
ownership, and output identity remain independent work rather than one generic
deep-copy visitor. The prompt must not prescribe a private chain-ID encoding.
