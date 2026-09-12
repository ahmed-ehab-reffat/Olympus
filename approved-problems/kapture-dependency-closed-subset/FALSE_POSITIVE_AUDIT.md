# False-positive audit — kapture dependency-closed dataset subset, immutable v8

Verdict: `pass`; zero survivors in the attempted set.

Repository: `naver/kapture @ 8225b77d0657e6a3eb1ffc941d009100b792fb25`.

Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.

## Method and requirement map

Every participant-facing requirement was mapped to its strongest black-box
node. Mutants came from separate repository record/I/O branches, reviewed v5
and v7 solver shortcuts, lifecycle quadrants, and the two independent reference
architectures. A probe was admitted only when public, reference-passing,
alternate-architecture-passing, pristine fail-to-pass, and targeted-mutant
failing.

| Requirement family | Strongest node |
|---|---|
| selection and dependency closure | interval, combined, image-seed nodes |
| independent copy, validation, absence | validation, sparse, deep-independence nodes |
| payload/storage/return/reopen | mixed-store node |
| force, normalized identity, no-force | existing-output node |
| transaction plus managed/unmanaged ownership | transactional node |
| callable/options/module/install | two CLI nodes |

## Final mutation result

The final set is IDs 1–29, 31, and 32–40: 39 plausible incorrect
implementations. Mutant 12 targets the independent deep-copy/prune architecture;
the others target the reconstruction reference. Every patch applies cleanly,
and every mutant is killed by the focused suite. No survivor qualified for a
complete-suite escalation.

New v8 mutants 39 and 40 model overlay-with-stale-payloads and recursive
standard-root cleanup. Both are killed only by the transaction/ownership node.
The first v8 run found mutant 21 surviving because the normalized alias lacked
force; the final force-enabled identity case kills it, and the entire stream was
rerun from the beginning. The ordered checksum stream produced by
`(cd problems/kapture-dependency-closed-subset && sha256sum verify/mutants/*.patch) | sha256sum`
is `65b97a44c769e730ba4dc3f09598da2eaae9a04dbf09d848c0812bdd329832d1`.

## Compatibility and rejected mutants

All five v7 fresh solutions pass the complete base lane. Runs 1–4 pass 12/13
focused nodes and fail only nested unrelated-file preservation; run 5 passes
13/13. The observed compatibility result is therefore 1/5, exactly matching
the pre-change forecast. It is not fresh v8 calibration.

Rejected candidates include exact tar/CSV bytes or order, minimal output trees,
empty-directory deletion, extension-based ownership of arbitrary unreferenced
files, private staging names, required `os.replace`, arbitrary malformed bytes,
geometry changes, and deadlines. They are unspecified, artificial, duplicate,
or architecture-prescriptive. A zero-survivor result establishes only the
attempted mutation set. Fresh v8 calibration remains 0/10.

