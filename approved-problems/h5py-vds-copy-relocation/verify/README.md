# Focused mutation verifier

Run each mutation in an isolated container created from the pristine frozen
image. The script expects the problem directory mounted read-only at
`/artifacts`, applies the exact test and solution patches, makes one
repository-grounded incorrect change, and runs the complete focused file.

Example:

```sh
docker run --rm --network none \
  -v "$PWD/problems/h5py-vds-copy-relocation:/artifacts:ro" \
  olympus-h5py-vds-frozen \
  bash /artifacts/verify/mutations.sh absolute_normalized
```

The exact 44-mutant active set and results are recorded in
`FALSE_POSITIVE_AUDIT.md`.
