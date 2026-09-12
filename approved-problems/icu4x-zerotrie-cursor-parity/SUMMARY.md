# ICU4X ZeroTrie cursor parity

Status: **accepted and archived 2026-08-17; user-confirmed platform success**

Repository: `unicode-org/icu4x`

Pinned commit: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

Production language: Rust

Task type: enhancement

The task completes stepwise byte cursors and exact-state suffix views across
PerfectHash, ExtendedCapacity, and runtime `ZeroTrie`. Its public contract
includes format-aware probing, sticky failure, UTF-8 formatting, allocation-
free event traversal, reversible exact iteration, and source-independent owned
suffixes. Level 17 presents that contract in 320 words over five maintainer-
style paragraphs.

Run11 solved Level 16 at 6/10. Its successful implementations span independent
cursor-heavy and reader-heavy architectures. The failures omitted erased
iteration or owned bytes, or mishandled partial-span state and iterator size.
That batch is predecessor evidence only; Level 17 is a new immutable version.

The admitted hardening closes three distinct public gaps. Core cursor/suffix
operations are now allocation-tested with all features as well as no default
features. Callback errors must stop visitation immediately. Suffix tries from
the existing SimpleAscii and ASCII-ignore-case cursors now expose the same
exact `len` and fallible `ByteTrieEvent` walk, checked at root, partial,
taken-value, and failed states against their existing iterator output.

An eager alloc-feature `len` mutant passes all 60 pre-existing tests and 15/16
focused nodes, failing only the all-feature heap counter. A traversal that
remembers the first error but keeps invoking the callback also passes 60/60
plus 15/16 and fails only the exact callback-count assertion. Run11 Nova 5 and
Nova 10 independently implement the new legacy surface and pass every node;
four other Level 16 successes omit part of it.

The exact no-cache gate passes offline with read-only source as UID/GID 10001:

- pristine: 60/60 existing and 0/16 focused;
- reference: 60/60 existing and 16/16 focused;
- run11 Nova 5 and Nova 10: each 60/60 existing and 16/16 focused;
- baseline/reference focused JUnit identities match; and
- run11 Nova 2 and Nova 7 compose cleanly before verifier injection.

The verifier contains 16 named nodes and 18 unique randomized test-only paths.
Both patches apply cleanly; `test.sh` supports `base` and `new`, installs
nothing, and preserves an early Cargo diagnostic in XML-valid fallback JUnit.
Exact environment, gap, fairness, false-positive, collision, and patch-shape
audits pass.

Expected result after hardening: **1-3 successful solvers out of 10 fresh
attempts, centered on 2/10**. This is the defensible forecast from 2/6
compatibility among run11 successes; fresh Level 17 calibration starts at
**0/10**.

The platform accepted this immutable package on 2026-08-17. Acceptance is the
controlling external outcome; no new Level 17 solver batch was run, so the
fresh calibration count remains 0/10 and the forecast remains historical.
Raw solver bundles and cleanup/recovery evidence are preserved under
`archive/icu4x-zerotrie-cursor-parity/`.

Frozen identifiers:

- `meta.md`: `4ee0a417a12d6e2dc89d3a74225b625699a631367b99ed95daf03f82c61f195d`
- `test.patch`: `1f434f99cc7735f9b1fa3bd0a665868626a98e1a9d085b80cca0e93accff27db`
- `solution.patch`: `8c57616dca3cd605da4ae12fd408ed378e8190c594f525904f862ac720326b04`
- `Dockerfile`: `cdbc067192383faded762238f1ef8ab7ffc7da887109e4d3db8a4c0062552abb`
- replay manifest: `64091afc6de600a35fc8b0245b0b7659b3f726ca5e4d463fff7753fde792d75d`
- no-cache image index: `sha256:9bf98566c7cab2c37a900bdf3521448a5c80188c96b6399798fa85de20f54b55`
