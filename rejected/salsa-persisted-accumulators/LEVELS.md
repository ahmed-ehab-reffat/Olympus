# Calibration levels - Salsa persisted accumulator outputs

## Level 1 - exact escalated version

Status: **closed at 0/10 after prior-implementation rejection**

Repository pin: `81496d19d42c9d6f4bab876d1f2ac9941ec8992f`

- `meta.md`: `c8471d8bfe9ccb8857fbaf34e98c82ff7a4849bf6923a2a7735077c57dd65180`
- `test.patch`: `955efec5c24d26c967040847e6d31261db2c8e64e306fdf43135c7e7c2b8a0af`
- `solution.patch`: `3d241b5ed9c16334474ac02917757a51fc613932130ab62575a6ffe8d8af1201`
- `Dockerfile`: `ecb18013b3ce715be5e7907ac5736af9f7cd97f5e5b7751a8311d5ab54351f24`

The reference changes 11 production/manifest files with 235 additions and 28
deletions. This supports a provisional 7/10 scope estimate only; successful
solver trajectories must provide the actual message, architecture, file, and
effective-production-LOC evidence.

All exact-version environment, gap, fairness, and false-positive gates passed,
but the user reported that the idea was rejected because it had already been
implemented. No solver run was made or counted. This level is closed and must
not proceed to a local pre-filter or platform batch.

Any change to `meta.md`, `test.patch`, `solution.patch`, `Dockerfile`, the
dependency graph, repository pin, harness, or injection path abandons this
level, invalidates its audits, and resets calibration to 0/10. Results and
unused runs do not carry into a revised level. A materially different Salsa
task requires a new design and prior-implementation audit rather than another
level here.
