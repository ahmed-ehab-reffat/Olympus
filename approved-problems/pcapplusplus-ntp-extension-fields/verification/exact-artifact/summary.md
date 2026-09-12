# Exact artifact verification

Current artifact: version 3, prompt, reference, and Docker verified 2026-08-05;
false-positive audit pending.

The Dockerfile SHA-256 is
`d1826f3a2c937f82b79e0b7df5cc1900cd15e0b6ded46421d8ec8740a91e453c`,
it begins with `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`, and it built
as local image
`sha256:5b274844ecd2b43b4deb7fddf1b60360ac35d90d46f1d613fd5f28eb29e0a343`
from generic base digest
`sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.
The version-3 `meta.md` SHA-256 is
`50e8dc4238809c5cf864184ffeb27991502d2665c706cb18310df69222893d90`;
the unchanged `test.patch` is
`1b5626e2737bfbd02c1a6ede7a517d371723e0e17cb675a120445162d5ccf3f0`;
and the ownership-hardened `solution.patch` is
`09cc9d02c28fc3145079a65bc243708cb70c99d3cb8c99db988af9f5553c0ff3`.
Test-only passes the base lane and produces all fourteen expected named new
failures; combined passes the base lane and 14/14 new cases. No false-positive
or mutation run was performed for version 3 at the operator's direction, so it
is not approved for submission.

## Historical version 1

Immutable problem version 1 was frozen 2026-08-05 and is now superseded.

The final freeze includes a comment-only correction to the reference's
class-level extension-field documentation. All results below were rerun after
that correction.

Upstream pin: `8ac4366c4184f096973ef4a0ca084559935828d0`.

Artifact hashes:

- Dockerfile: `67ea356a0f1b1906657878680c5c8e7ae13d8e819bf062d8042c6b3b0afc8471`
- meta.md: `f068bad563efad7c350ecc5db712eb1799612ad0b3a1c42fe77af9d55fd572d2`
- test.patch: `1b5626e2737bfbd02c1a6ede7a517d371723e0e17cb675a120445162d5ccf3f0`
- solution.patch: `b26901f5a3f3f191ff1172c1b55ebe7ff05487e7c31879b5dda8ee879eb43c20`
- mutation driver: `9c381ff2b0fe357c4b68ecc4d210c6e0fce968107a5235389cbb8b9b75872687`
- mutation results: `77b81ccf2028e430ebd03fe2e169ea9dcaa633540c492995f8b0a910db7d6f35`

Patch matrix:

- test only: base 259/259 pass; new 0/14 pass with fourteen named failures;
- solution only: base 259/259 pass;
- combined: base 259/259 pass; new 14/14 pass;
- mutation-restored reference: base 259/259 pass; new 14/14 pass.

Mutation result: 32 behaviorally distinct mutants killed by the new lane; one
four-byte Crypto-NAK private-state mutant passes new and base but is publicly
equivalent. See `mutation-results.txt` and `FALSE_POSITIVE_AUDIT.md`.

The Dockerfile built offline as image
`sha256:6ba9b0b1787465844bc0319d2142ccb1b4a59406cacfa13a609c24522783e0dc`.
Both the test-only and combined matrices pass with patch injection into that
built image.
