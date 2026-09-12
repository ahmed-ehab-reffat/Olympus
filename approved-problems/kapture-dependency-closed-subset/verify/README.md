# Verification helpers

`architecture-b.patch` is the mandatory independent deep-copy/prune and staged
commit replay. Its hash is pinned in `../ENVIRONMENT_REPLAYS.sha256`, so the
environment gate cannot omit it.

`mutants/` contains the exact v8 false-positive set: IDs 1–29, 31, and 32–40.
Mutant 30 was retired when the saved lifecycle was redesigned. V8 adds stale
managed-payload retention and whole-standard-root cleanup to the prior reverse
selection, transaction, packaging, and dependency-closure shortcuts.

After the exact environment gate passes, reproduce with:

```sh
./problems/kapture-dependency-closed-subset/verify/mutations.sh \
  Work/kapture-dependency-closed-subset/source IMAGE_TAG
```

The runner composes implementation then verifier patches, runs offline as
UID/GID 10001, and escalates any focused survivor to the complete base lane.
The immutable-v8 audit kills all 39 attempted mutants.
