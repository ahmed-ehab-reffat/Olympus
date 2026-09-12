# Environment gate - `object` AIX big-archive symbols

Status: `Phase A pass; Phase B not applicable after scope rejection`.

Immutable Phase A version:

- Repository: `gimli-rs/object@400e64fbcb03fddb4b1ae8aef1868976ab999acc`
- Fixture submodule: `fe8da208d4013ec3691311915fdc7d71436c0d1e`
- Prompt: not yet authored
- Test patch: not yet authored
- Solution patch: not yet authored
- Dockerfile: `12e120af5468e7c339f697f9d6c16a43207f931c0bbb92d545ba4626b266e7ea`

## Phase A - pristine image

- Host-space preflight: 143,337,272 KiB free, above the required 12 GiB.
- Docker daemon: available, server 29.2.1.
- Untouched-context build:
  `docker build --pull --no-cache -f problems/object-aix-big-archive-symbols/Dockerfile -t olympus-object-aix-phase-a Work/object-aix-big-archive-symbols-audit/source`.
- Approved base: `public.ecr.aws/d3j8x8q7/olympus-base-rust:latest` at build-time digest
  `sha256:211a2e3aeff24b410f2c982723e9314992833f4633c764217eab87552f1d1477`.
- Built image ID:
  `sha256:b831bf13a37aa45bca0e66a7c37a2779ad6032f1fdedfe6e2f9a53d2eaf3dd2e`.
- Offline arbitrary UID: `10001:10001`, network disabled, repository mounted
  read-only at `/workspace`, writable target under `/tmp`, and temporary home.
- Tool check: Rust `1.90.0` and `cargo-nextest 0.9.128` both executed as that
  UID from the image's read-only tool cache.
- Command:
  `cargo +1.90.0 test --workspace --features all --locked --offline`.
- Result: pass. The complete workspace discovered and passed 91 executable
  tests plus 10 doctests (101 total), including the fixture-submodule lane.
- Network, root ownership, writable source, and runtime dependency resolution
  were not required.

The first no-cache build attempt is quarantined: it stopped before repository
compilation because `cargo-nextest 0.9.140` requires Rust 1.91. The Dockerfile
was corrected to 0.9.128 and the entire pristine gate restarted. No partial
result from that image is counted.

## Phase B - evaluator composition

Not run. The mandatory convergence trial rejected the task before `meta.md`,
`test.patch`, or `solution.patch` existed. Phase A does not authorize a solver
run or submission; it is retained only as repository-environment evidence.

## Verdict

Phase A is `pass`. There is no environment verdict for a submission version
because no submission version was authored. The scope rejection is terminal
for this task shape.
