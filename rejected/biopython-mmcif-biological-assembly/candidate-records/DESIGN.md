# DESIGN - Biopython mmCIF biological-assembly materialization

Status: `rejected and retired 2026-08-14; historical design record only`.

## Retirement notice

This candidate is terminally retired from the shortlist. Its environment work
used a non-Olympus base image and therefore did not establish platform
viability. The upstream custom license identifier was also not recognized by
Olympus and was never confirmed as permitted. The design evidence below is
preserved for audit history, not as an approval or a basis for calibration.

## Startup evidence

`PROBLEM_DESIGN.md` was read before design. Searches covered `candidates/`,
`problems/`, and `archive/` for Biopython, mmCIF, biological assemblies,
operator expressions, coordinate transforms, graph extraction, identity
allocation, and deep copying. The 2026-07-30 Biopython screen was found and
read; it identified this seam but stopped before a full environment and exact
upstream audit because of graph-materialization similarity.

Raw accepted and near-pass Statig trajectories under
`archive/statig-local-transitions/` were inspected for stable-identity behavior
across mutation. Calamine trajectories were inspected for independent native
branches and PcapPlusPlus records for the one-parser/many-fixtures trap. The
design consequence is that chain identity, model/disorder ownership, operator
grammar, and transform composition must be independently observable; arbitrary
chain-label spelling is not a discriminator.

Repository inspection confirmed raw mmCIF assembly/operator categories in the
fixture corpus, `MMCIFParser` structure construction, disordered entity
classes, and biological transform modeling in the MMTF path. No source or test
artifact was changed during the gate.

## Provisional public contract

Expose a `Bio.PDB` function that accepts parsed mmCIF assembly metadata, a
source `Structure`, and an assembly ID, returning a new `Structure`. Evaluate
the public operator-expression grammar and apply the selected operations to
every applicable model/entity. Output identities must be deterministic and
collision-free but their exact encoding remains implementation-defined.

## Trajectory-informed discriminator ledger

| Repository signal | Plausible shortcut | Fair public invariant | Black-box oracle |
|---|---|---|---|
| Expressions contain lists/ranges/products | Split only on commas | Every listed combination appears once | Asymmetric matrices with a Cartesian product |
| Matrix composition order is meaningful | Apply products in reverse order | Coordinates match ordered affine composition | Non-commuting rotation and translation |
| Structures can have multiple models | Expand model zero only | Every model is expanded with its own coordinates | Two models with distinct source coordinates |
| Chains/residues/atoms may be disordered | Flatten or lose alternatives | Public disorder/occupancy/altloc state survives | Existing disordered fixture subtree |
| Operators may duplicate one asym ID | Reuse the original chain ID/object | Copies are distinct and addressable without collision | Multiple transforms of one chain, mutate one copy |
| Source entities are mutable | Transform in place | Source coordinates and hierarchy remain unchanged | Snapshot source before/after materialization |
| Missing assembly/asym/operator references are possible | Silently drop bad rows | Invalid public references fail deterministically | Minimal malformed category dictionaries |

## Cheapest-solution and verdict

The cheapest solution is a small expression parser plus deep-copy/transform
pipeline. Whether this clears the architecture-convergence gate depends on the
prototype: if entity copying inherits all model/disorder/identity behavior, the
task must be rejected rather than padded. Current rating is 7/10.
