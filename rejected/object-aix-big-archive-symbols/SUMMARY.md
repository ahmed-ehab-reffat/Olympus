# `object` AIX big-archive symbol iteration - escalation summary

Status: **rejected for convergence scope on 2026-08-14; calibration 0/10**.

- Repository: `gimli-rs/object`
- Pin: `400e64fbcb03fddb4b1ae8aef1868976ab999acc`
- Fixture pin: `fe8da208d4013ec3691311915fdc7d71436c0d1e`
- Language: Rust
- Task type: enhancement
- Candidate rating: **7/10 initial; 6/10 after convergence trial**

The task is correct, rare, unowned, and fully reproducible: complete
`ArchiveFile::symbols()` for both optional AIX big-archive global tables with
8-byte big-endian count/offset parsing, deterministic 32-then-64 iteration,
exact NUL-name cardinality, member-offset interoperability, present-empty
semantics, and checked malformed input.

It is not suitable as an Olympus long-horizon problem. Two complete,
independently structured spikes both converge on `src/read/archive.rs`:

- range-backed validation at `symbols()` time: 96 additions / 27 deletions;
- borrowed table descriptors validated at archive-parse time: 116 additions /
  15 deletions.

Each passes its three focused scenarios and the complete offline workspace,
for 104 tests/doctests including the focused additions. The difference in
validation timing and iterator state rules out one accidental reference-shape
artifact; both still use one production file and the same two existing seams.
Hidden-test breadth cannot create another implementation boundary.

The approved Olympus Rust base built successfully after correcting the pinned
test runner from incompatible 0.9.140 to 0.9.128. The pristine image passed 91
executable tests and 10 doctests offline as UID/GID 10001 against a read-only
checkout. This proves environment viability only; no evaluator composition was
created because the design stopped before submission artifacts.

No hidden patch, reference patch, public prompt artifact, false-positive/gap/
fairness audit, local solver run, platform solver run, or calibration batch was
started. Do not pad this task with archive writing, z/OS, XCOFF payload parsing,
or extra malformed fixtures. Reconsider `gimli-rs/object` only through a
materially different cross-subsystem task.
