# Verification and mutation audit

Run the exact environment gate before behavioral analysis:

```sh
scripts/environment_gate.sh \
  --problem problems/openexr-multipart-image-io \
  --repo /path/to/clean/openexr-c101ab74 \
  --compatible-patch problems/openexr-multipart-image-io/verify/replays-v9/agent-runs6-1.patch \
  --compatible-patch problems/openexr-multipart-image-io/verify/replays-v9/agent-runs6-2.patch \
  --compatible-patch problems/openexr-multipart-image-io/verify/replays-v9/agent-runs6-3.patch \
  --compatible-patch problems/openexr-multipart-image-io/verify/replays-v9/agent-runs6-4.patch \
  --compatible-patch problems/openexr-multipart-image-io/verify/replays-v9/agent-runs6-5.patch
```

The run-6 files are source-only compatibility injections, not known-good v9 patches. They verify clean hidden-test composition without assigning a behavioral result to implementations that predate `rewriteImages()`.

Prepare a disposable exact-pin tree with `solution.patch` and `test.patch` applied, configure a writable build root, then run:

```sh
problems/openexr-multipart-image-io/verify/mutations.sh \
  /path/to/reference-tree \
  /path/to/writable-results-root \
  olympus-openexr-multipart:v5-0812
```

The script changes only disposable `ImfImageIO.h` and `ImfImageIO.cpp`, builds offline as UID/GID 10001, runs the named discriminator for each mutant, escalates survivors to all focused tests, and restores both sources under a trap.

Immutable-v17 result: 76 production mutants, 75 behaviorally incorrect
variants killed, one equivalent duplicate-validation delegation survivor, and
zero actionable survivors. The unsupported-source name-match shortcut is
killed by `RewriteValidation`; the prior named-typeless and normalization
shortcuts remain killed. The equivalent survivor passes 14/14 focused and all
127 pre-existing tests in 380.09 seconds. `test.patch` hash:
`4974070a9c5250e5a53bc1f1470b44eaf6cf404ce69110d13951a34db6fbf444`.
Script hash:
`9d2d3eefff60b2e9b94a1df9e063ad6f7e6469629f3b08c78840a69e951113cd`.
