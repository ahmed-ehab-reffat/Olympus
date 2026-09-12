Implement the feature in a dedicated `Bio.PDB` module and re-export the public
function from the package initializer.

First validate the three assembly-generation columns and all operator columns
as complete, equal-length sequences. Parse each selected expression into
operation-ID groups, expand ascending numeric ranges, and take the Cartesian
product. Represent each operator as a homogeneous affine matrix; multiplying
the listed group matrices from left to right makes the rightmost transform act
on coordinates first.

Build and validate the complete generation plan before copying anything. This
catches absent assemblies, missing chains in any model, malformed expressions,
unknown or duplicate operators, and invalid numeric components without touching
the source.

For each source model, recursively copy every selected chain, restore explicit
disorder-wrapper selections, allocate a unique deterministic string ID, and
transform every leaf atom. Traversing disorder wrappers explicitly is important:
ordinary entity forwarding can otherwise transform only the selected residue
alternative. Construct fresh output models with the source IDs, serial numbers,
and metadata, and retain the source structure's public identity and header.
