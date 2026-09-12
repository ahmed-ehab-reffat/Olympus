# SUMMARY - umoci forward hardlink extraction

Status: **rejected for convergence scope on 2026-08-15; calibration 0/10**.

Repository: `opencontainers/umoci`

Pin: `f5d1219acaf67127ebacf6306776d3ff465735ea`

Production language: Go

Task type: bug fix

The seed correctly fixes same-layer tar hardlinks whose entries precede their
targets, including chains, symlink inodes, replacement order, and lower targets
that are replaced later in the current layer. The repository and official-base
offline environment are eligible.

It is not suitable as an Olympus long-horizon problem. A complete prototype
passes six focused outcomes and the full ordinary Go package suite while
changing one production file at only 54 raw and 48 strict effective additions.
The source FIXME and closed issue 29 already identify delayed link creation, so
alternative implementations converge on the same small `oci/layer` state seam.

No `meta.md`, `test.patch`, `solution.patch`, hidden test, solver run, or
calibration batch was created. Do not pad the task with cross-layer policy,
overlayfs, writing, unrelated whiteouts, or more malformed fixtures.
