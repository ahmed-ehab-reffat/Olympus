# ERRORS - umoci forward hardlink extraction

## Terminal scope finding

The seed initially appeared to contain several fair discriminators: dependency
chains, link-to-symlink identity, stale pending destinations, layered-root
targets, hierarchy replacement, unresolved cycles, and path confinement.

The complete prototype showed that these outcomes all reuse one small state
machine around the existing `UnpackLayer` loop. The repository already owns
the filesystem operations, sanitization, overwrite behavior, metadata rules,
and per-entry extraction. The missing logic is only pending-header bookkeeping
and fixed-point completion.

Adding more fixtures would strengthen correctness but not implementation depth.
Adding writer behavior, cross-layer policy, overlayfs semantics, or transactional
rollback would change the task. The correct response is rejection, not scope
padding.

## Environment note

The first prototype test attempt ran as UID/GID 10001 with default tar header
owners of zero and failed at `lchown`. This was a test-fixture error, not a
repository or platform blocker. The fixture was corrected to use the executing
UID/GID; the focused and complete lanes then passed. No failed environment run
was counted as solution evidence.
