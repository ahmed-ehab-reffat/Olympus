# ERRORS - image-png static Adam7 encoding

Resolved review findings:

- The first interlaced stream reference used the encoder's earlier filter and
  ignored `StreamWriter::set_filter`. Both complete architectures and the
  focused suite now preserve the public override.
- The first independent packed-row oracle compared unused final-byte bits to
  zero. It now masks semantically unused output bits and separately proves that
  nonzero source-row padding is never interpreted as pixels.
- A round-trip-only MinEntropy test admitted an Adaptive substitution. That
  mutation passed the full upstream suite, so a pass-local comparison with the
  existing public non-interlaced MinEntropy writer was added. The mutation now
  fails only that test.
- Static sequence validation was initially indirect. Its enabled first/second
  image lifecycle now has a direct public probe.
- A post-format mutation replay initially committed only modified production
  files and omitted the additive test nodes. The missing-target result was
  quarantined and never counted. The exact mutation base now commits all five
  composed files, and the audit helper aborts on missing tests, compilation
  failures, or other startup failures.

Current risks to keep visible:

- the seven-pass transform is standardized and may converge to a compact
  single-file implementation;
- supporting ordinary row-major input through `StreamWriter` may require
  complete buffering and must not be paired with an unstated memory bound;
- open APNG PRs touch adjacent encoder/decoder lifecycle code, so APNG behavior
  is excluded; and
- compressed byte identity is not stable across legitimate backends and must
  not become a hidden oracle.

All submission-artifact corrections triggered fresh exact-version environment
gates. The current L1 hashes, audits, and mandatory replay are internally
consistent.
