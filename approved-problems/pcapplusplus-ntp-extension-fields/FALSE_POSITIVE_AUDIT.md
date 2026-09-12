# False-positive audit — PcapPlusPlus NTP extension fields

Status: **historical: complete for superseded immutable version 1 on
2026-08-05; not run for current version 3**.

This audit approves the exact participant-facing contract and patches listed
below as a locally verified problem package. It does not substitute for solver
calibration; calibration remains 0/10.

Version 3 includes the allowed-base Docker correction plus a clarified prompt
and ownership-hardened reference:

- first line: `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest`;
- Dockerfile SHA-256:
  `d1826f3a2c937f82b79e0b7df5cc1900cd15e0b6ded46421d8ec8740a91e453c`;
- `meta.md` SHA-256:
  `50e8dc4238809c5cf864184ffeb27991502d2665c706cb18310df69222893d90`;
- `test.patch` SHA-256 (unchanged):
  `1b5626e2737bfbd02c1a6ede7a517d371723e0e17cb675a120445162d5ccf3f0`;
- `solution.patch` SHA-256:
  `09cc9d02c28fc3145079a65bc243708cb70c99d3cb8c99db988af9f5553c0ff3`;
- resolved base digest:
  `sha256:ac31e95cbaf2ba43e73fdbe8d688addafe7ca6076372523679d35fe1d82dce1f`.

The ordinary clean image build, test-only lanes, and combined lanes pass their
expected outcomes for version 3. The operator explicitly directed that no
false-positive check be run for this correction. Consequently, the remainder
of this document is retained as version-1 evidence only and does not approve
version 3.

## Immutable version

| Input | Identity |
|---|---|
| Upstream pin | `8ac4366c4184f096973ef4a0ca084559935828d0` |
| Base image | `public.ecr.aws/d3j8x8q7/olympus-base-cpp@sha256:ce073a8809812fc472187ad4b9bd24dd1794f009a440b66ea6cbdc2d0fab9321` |
| `Dockerfile` | `67ea356a0f1b1906657878680c5c8e7ae13d8e819bf062d8042c6b3b0afc8471` |
| `meta.md` | `f068bad563efad7c350ecc5db712eb1799612ad0b3a1c42fe77af9d55fd572d2` |
| `test.patch` | `1b5626e2737bfbd02c1a6ede7a517d371723e0e17cb675a120445162d5ccf3f0` |
| `solution.patch` | `b26901f5a3f3f191ff1172c1b55ebe7ff05487e7c31879b5dda8ee879eb43c20` |
| Reference header | `00d71b30735b8706506a000a4498706ae3d490958abfbede21f365c4e7bdafdc` |
| Reference source | `e62238ca12069313421355c5afcf529e5cc16a9bc7cb3ee4858a28d63ebdb843` |
| Hidden C++ test | `ca2617c9d13c2241d0419c2bd7ec36d4ea7c7e13dc3eaba54a55d4349516eb7d` |
| Mutation driver | `9c381ff2b0fe357c4b68ecc4d210c6e0fce968107a5235389cbb8b9b75872687` |
| Mutation result ledger | `77b81ccf2028e430ebd03fe2e169ea9dcaa633540c492995f8b0a910db7d6f35` |

The exact Dockerfile built offline as local image
`sha256:6ba9b0b1787465844bc0319d2142ccb1b4a59406cacfa13a609c24522783e0dc`.
All post-image source builds and tests used Docker `--network none`.
The final solution re-freeze changed only the stale class-level Doxygen sentence
that said extension fields were unsupported. The patch matrix, mutation audit,
formatting, and focused sanitizer run were repeated from zero afterward.

## Participant requirement map

| Participant-facing requirement | Strongest behavioral test |
|---|---|
| Public record view, builder, and layer method surface | The dedicated target compiles every named type and method across all fourteen cases |
| Borrowed views and separately owned builder records | `BuilderEncoding` checks build/purge/null state; `CopyAndViewValidation` checks deep-copy independence and rejects a foreign cursor |
| Network-order type and inclusive encoded length | `OrderedOpaqueFields`, `BuilderEncoding`, and `MaximumFieldLength` inspect exact type, total size, data size, and boundary bytes |
| Opaque unknown/private/NTS values, order, and duplicates | `OrderedOpaqueFields` uses private and registered/NTS-like types; `DuplicateFields` preserves two equal types with distinct bodies and removes only the first |
| Minimum, word alignment, remaining bound, and final-list closure | `MalformedAlignment`, `MalformedBounds`, and `ListClosure` distinguish strict rejection, 16-byte non-final fields, and a 28-byte final field |
| Field-free and post-field 4/20/24-byte authentication partition | `SupportedAuthentication`, `ExtensionShapedAuthentication`, and `AuthenticatedEditAtomicity` cover exact tails, including extension-shaped key words |
| Existing key/digest byte representation | `SupportedAuthentication`, `ExtensionShapedAuthentication`, and `VersionAndClassifierCompatibility` compare native existing-return values and exact digest hex |
| Builder zero-padding, reuse, null rejection, and 65,532-byte ceiling | `BuilderEncoding` and `MaximumFieldLength` inspect minimum/aligned padding, reuse a builder, reject null/non-empty and oversized input, and append the maximum |
| Append, insert-before-first, absent-target append, remove-first, and remove-all | `DetachedEditing`, `DuplicateFields`, and `ListClosure` check exact order, idempotence, missing cases, and closure-preserving refusal |
| Atomic refusal on authenticated or malformed tails | `AuthenticatedEditAtomicity` snapshots five auth layouts; `MalformedAlignment` snapshots bytes across all four edit operations |
| Attached and detached resize behavior | `DetachedEditing` exercises independent storage; `AttachedEditing` appends and removes in IPv4/UDP, then checks packet, UDP, and IP lengths/checksums |
| NTPv3 and classifier compatibility | `VersionAndClassifierCompatibility` preserves v3 authentication, refuses a v3 extension-like tail, and retains the 48-byte-minimum/49-byte-valid classifier |
| Copy independence and traversal cursor ownership | `CopyAndViewValidation` mutates a copy without changing the original and rejects a view borrowed from another layer |

No assertion depends on the reference's `TailInfo`, scanner loop, allocation
layout, logging, or private classification state. A solver may pre-index,
serialize/rebuild, scan lazily, or use another internal representation.

## Plausible implementation modes and mutant construction

The mutant set comes from four evidence sources: the pinned implementation's
legacy exact-total authentication checks; repository record-view/builder and
attached-resize conventions; the candidate's two different complete
architectures and first mutation audit; and the saved same-repository
trajectories' greedy parsing, overvalidation, and mixed-state shortcuts.

Thirty-three transformations compiled against the exact reference. They cover
independent parser, authentication, builder, ownership, compatibility, and edit
modes rather than permutations of type codes or fixtures.

| Mutant family | Exact result / isolating case |
|---|---|
| Require authentication to be the whole tail | killed by `SupportedAuthentication` |
| Greedily parse extension-shaped authentication | killed by `ExtensionShapedAuthentication` and closure checks |
| Ignore Crypto-NAK in private partition state | passes new and full suites; behaviorally equivalent, discussed below |
| Require every field to be 28 bytes | killed by ordered 16+28 and authenticated short-prefix cases |
| Accept a 16-byte final field | killed by `ListClosure` |
| Treat encoded length as value length | killed by duplicate/auth/closure/edit/copy/maximum cases |
| Round a non-aligned length | killed by declared-30/actual-32 `MalformedAlignment` |
| Omit declared-length remaining bound | killed by `MalformedBounds` |
| Whitelist field types | killed by `OrderedOpaqueFields` |
| Collapse consecutive duplicate types | killed by `DuplicateFields` |
| Read the first extension word as key ID | killed by `SupportedAuthentication` |
| Append instead of insert before the first target | killed by `DetachedEditing` |
| Preserve stale authentication while appending | killed by `AuthenticatedEditAtomicity` |
| Resize four bytes before returning authenticated failure | killed by length and byte snapshots in `AuthenticatedEditAtomicity` |
| Support detached edits only | killed by `AttachedEditing` |
| Normalize key IDs to host order | killed by v4 and v3 compatibility cases |
| Discard NTPv3 authentication | killed by `VersionAndClassifierCompatibility` |
| Tighten `isDataValid()` to aligned totals | killed by the 49-byte classifier case |
| Fill builder padding with nonzero bytes | killed by `BuilderEncoding` |
| Omit the 16-byte builder minimum | killed by builder and detached-edit cases |
| Accept 65,529 caller bytes | killed by `MaximumFieldLength` (the mutant process faults on its wrapped encoded length) |
| Return raw-endian type | killed by ordered/builder/edit cases |
| Return raw-endian length | killed across parsing, building, editing, and maximum cases |
| Remove all duplicates for one type | killed by `DuplicateFields` |
| Fail rather than append when insert target is absent | killed by `DetachedEditing` |
| Return false for empty remove-all | killed by idempotent `DetachedEditing` |
| Treat a malformed tail as field-free for append | killed by malformed-tail edit snapshots |
| Rebase and accept a foreign traversal cursor | killed by `CopyAndViewValidation` |
| Remove a final field leaving a short predecessor | killed by `ListClosure` |
| Parse extension-like tails for NTPv3 | killed by `VersionAndClassifierCompatibility` |
| Trim trailing zero bytes from exposed field data | killed by `BuilderEncoding` |
| Delete a built record without nulling its view | killed by `BuilderEncoding` |
| Allow authenticated removal while refusing append | killed by `AuthenticatedEditAtomicity` |

Every transformation is hash-checked so a no-op cannot be counted. All 32
behaviorally distinct mutants fail the new lane. No actionable mutant reaches
the pre-existing suite in the final run.

## Survivors, probes, and rejected predicates

The final run has one survivor: removing four-byte Crypto-NAK from the parser's
private authentication-length state. Through the frozen public API, recognized
and unrecognized four-byte tails both enumerate no fields, return no key or
digest, reject all edits, preserve bytes, and remain accepted by the legacy
classifier. A new public status API would exist only to expose the reference's
private partition. The survivor is therefore rejected as behaviorally
equivalent, not actionable. It passes the complete 259-case regression suite.

Two audit iterations caused justified test changes before version 1 was frozen:

1. A corrupt inclusive-length mutant could hang the maximum case after walking
   beyond the encoded span. Each CTest identity now has a ten-second timeout;
   this changes harness termination, not required implementation behavior.
2. The first alignment fixture declared 18 bytes in a 32-byte tail. A rounding
   mutant rounded to 20 and was rejected later for an unrelated remainder, so
   the test did not isolate rounding. Declared 30 in actual 32 bytes passes a
   round-up parser and fails the reference rule directly. The revised probe
   passes the reference and kills only the intended permissive family.

Earlier requirement mapping also added byte-atomic malformed edits, attached
removal, an extension-shaped terminal after an existing field, and an NTPv3
extension-like tail. Each is tied to a distinct public clause. No test was
added for type permutations, arbitrary predicates, private parser state, or a
specific helper architecture.

## Full-suite, replay, and tool results

The final exact patch matrix is:

| State | Base lane | New lane |
|---|---:|---:|
| `test.patch` only | 259/259 pass | 0/14 pass; fourteen named compile failures |
| `solution.patch` only | 259/259 pass | not present |
| both patches | 259/259 pass | 14/14 pass |
| restored reference after mutations | 259/259 pass | 14/14 pass |

The equivalent Crypto-NAK survivor is the only mutant run through the complete
suite and passes 259/259, as expected. An earlier pre-freeze round-up survivor
also passed the complete suite, which is why the isolated alignment probe was
necessary rather than relying on regressions.

No prior NTP solver patch exists locally, and the user requested no cold solver
runs. The archived PcapPlusPlus PCAPNG patches cannot compile against this
Packet++ API and were used only for the startup design gate. The candidate's
copied/indexed prototype deliberately used a different provisional public API,
so it is architecture evidence rather than a legitimate patch for the frozen
compilation contract. The exact reference was replayed from a fresh checkout
in test-only, solution-only, combined, mutation-restored, and built-image
states.

Formatting with clang-format 21.1.5, `git diff --check`, Python syntax, Bash
syntax, and focused clang-tidy checks all pass. ASan+UBSan passes all 14 new
cases. The complete suite passes with ASan; halting UBSan stops in a pre-existing
unrelated `IgmpLayer.cpp` misaligned access before reaching NTP, while nonhalting
UBSan completes 259/259. No NTP sanitizer diagnostic appears.

## Historical version-1 verdict

No actionable false-positive survivor remains for immutable version 1. This is
evidence for the attempted repository- and trajectory-supported mutation set,
not a claim that false positives are impossible. Any change to `meta.md`,
`test.patch`, `solution.patch`, `Dockerfile`, or reference behavior invalidates
this approval and requires a new audit from zero. The Dockerfile has changed,
so that invalidation has occurred; version 3 is audit-pending.
