# Summary - mp4ff CENC sample-group key rotation

Status: **rejected at the upstream-ownership gate on 2026-08-15;
calibration 0/10**.

Repository: `Eyevinn/mp4ff`.

Pin: `745651cf1e4bd8d7bcb7f8f78fd66e26389ef05b`.

Production language: Go.

Task type: feature request.

The candidate was technically coherent: mp4ff already decodes `sbgp`, `sgpd`,
and `seig`, but `TrafBox.ParseReadSenc` accepts only one group run and one
fragment-local description, while `DecryptFragmentWithKeys` selects the
track-level `tenc.DefaultKID` once for the entire fragment. A complete rotation
path would coordinate sample-run expansion, description lookup, variable
encryption parameters, KID-key selection, group-zero fallback, cross-`trun`
sample order, and validation before in-place changes.

It cannot become an Olympus problem because that exact central enhancement is
publicly owned. Merged PR #490 introduced the KID-aware APIs with an explicit
AI-assistance disclosure. In the merge discussion, the maintainer identified
the missing `seig` KID override and said it might be enhanced later. PR #495
and the v0.52 release PR #502 repeat that `seig` overrides are not yet
supported; adjacent PR #494 implements `seig`-first IV-size selection.

The earlier shortlist search looked only for an exact combined key-rotation
phrase and missed this PR discussion. The escalation audit corrects that
record. No environment gate, prototype, prompt, hidden test, reference patch,
solver run, or calibration batch was started after the terminal ownership
result. Reconsider mp4ff only through a materially different subsystem and
behavior.
