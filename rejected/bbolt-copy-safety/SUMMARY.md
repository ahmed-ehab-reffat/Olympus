# Summary - bbolt snapshot-copy safety

Status: **rejected for fairness and convergence scope on 2026-08-15;
calibration 0/10**.

Repository: `etcd-io/bbolt`.

Pin: `0464afc4b2120d472bae971ac2934f947145418e`.

Production language: Go.

Task type: bug fix.

The source-alias defect is real and unowned. On the pristine pin,
`Tx.CopyFile` opens its destination with `O_TRUNC`; direct-path, hard-link, and
symbolic-link destinations that identify the live database each reduced a
131,072-byte source to 8,192 bytes before returning an error. The approved-base
Phase A passes offline as UID/GID 10001.

It is not suitable as an Olympus long-horizon problem. Two independently
structured repairs converge on `tx.go`: a pre-open `os.Stat` comparison uses 13
additions but bypasses `Options.OpenFile`, while the repository-compatible
open-then-compare prototype uses 15 additions and 1 deletion.
The latter delays truncation until the already-open source and destination have
passed the existing `sameFile` check. Its preserved `prototype.patch` has
SHA-256
`c08615dddf3c28e479d752ec8c92823e7ac8380dfe67d5f21e841f519642ee13`.
Both implementations pass direct, hard-link, and symbolic-link probes; the
preserved handle-based prototype also passes the repository's ordinary copy,
metadata-error, data-error, concurrent-copy, and overwritten-path tests under
both freelist modes.

The proposed metadata short-write extension cannot be an approved hidden
discriminator. A writer that returns `n < len(p)` with a nil error violates the
Go `io.Writer` contract. Even if that extra robustness were required, the
combined repair remains one production file at only 25 additions and 3
deletions. `Compact` supplies no separate supported boundary: passing one DB as
both source and destination creates the nested transaction shape the README
warns can deadlock, while separately opened aliases are governed by the
database lock. CLI alias handling would repeat the same file-identity decision.

No `meta.md`, `test.patch`, `solution.patch`, hidden test, Phase B, downstream
audit, solver run, or calibration batch was created. Do not pad this seed with
destination-publication guarantees, concurrent path replacement, compaction
policy, or malformed writers. Reconsider bbolt only through a materially
different subsystem and behavior.
