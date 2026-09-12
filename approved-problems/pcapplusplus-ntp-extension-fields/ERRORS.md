# Errors and limitations

- The host macOS environment does not provide CMake or clang-format on `PATH`.
  All authoritative build, test, and formatting checks therefore run inside
  the pinned Linux image.
- A CMake configure performed in a mounted git worktree can print non-fatal git
  metadata diagnostics because the `.git` file points to a host worktree path
  that does not exist inside the container. This does not affect compilation or
  tests.
- LeakSanitizer is disabled for the separate sanitizer check because the
  pre-existing MemPlumber-based test harness owns process-lifetime state that
  LeakSanitizer reports. AddressSanitizer and UndefinedBehaviorSanitizer remain
  enabled for memory and undefined-behavior checking.
- The public contract intentionally supports only the repository's existing
  4-, 20-, and 24-byte terminal authentication shapes. Longer negotiated MAC
  formats are outside this problem rather than silently inferred.
- A four-byte Crypto-NAK tail and an invalid four-byte opaque tail are
  indistinguishable through the frozen public API: both expose no extension,
  key, or digest and reject edits. The audit records an internal-classification
  mutant for this case as behaviorally equivalent, not actionable.

## Resolved during exact audit

- The promoted version-1 Dockerfile copied the earlier successful
  PcapPlusPlus problem's specialized `olympus-base-cpp` pattern and then pinned
  it by digest. That image worked locally but failed the current validator's
  literal first-line allowlist. Version 2 now starts with the allowed
  `FROM public.ecr.aws/d3j8x8q7/olympus-base:latest` and installs the missing
  CMake package explicitly. The exact image build and ordinary patch-state
  tests pass. Because this changes a submission artifact, version 1's
  false-positive approval is historical. The corrected Dockerfile is retained
  in version 3, which remains audit-pending.
- A platform verification used the pre-correction generic-base Dockerfile
  without a CMake install. Both test-only and combined runs stopped before
  compilation and were represented as one `Harness::Harness` failure; the
  report's fourteen scenario failures were therefore synthetic harness output,
  not executed NTP failures. Rebuilding the current Dockerfile exposes CMake
  3.25.1, passes the baseline in both patch states, produces fourteen expected
  missing-feature failures in test-only, and passes 14/14 in combined.

- The first exact alignment fixture declared 18 bytes in a 32-byte tail. A
  parser that rounded to 20 was still rejected by the leftover 12 bytes, so the
  fixture did not isolate rounding. The final fixture declares 30 in 32 bytes;
  a rounding parser accepts it while the required strict parser rejects it.
  All exact checks restarted after this test change.
- A deliberately corrupt inclusive-length mutant could walk past the maximum
  field and hang. Each new CTest entity now has a ten-second timeout. The
  invalid partial mutation logs were discarded and regenerated from zero; the
  retained ledger is reproducible with `verification/mutations.sh`.
- The complete ASan+UBSan run with `halt_on_error=1` stops in the existing
  `IgmpLayer.cpp` query-header code on an unrelated misaligned access. All
  fourteen NTP extension cases pass under both sanitizers. The complete suite
  passes 259/259 with ASan and nonhalting UBSan, with no NTP diagnostic.
- The first frozen reference left the class-level Doxygen statement that
  extension fields were unsupported. The final solution replaces that stale
  sentence with the opaque-record behavior. Although this was comment-only,
  the solution hash changed, so the complete patch matrix, all 33 mutations,
  formatting, and focused ASan+UBSan checks restarted and passed.
