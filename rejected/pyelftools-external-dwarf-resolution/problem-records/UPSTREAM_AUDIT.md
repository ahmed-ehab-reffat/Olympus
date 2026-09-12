# Upstream audit - pyelftools external DWARF resolution

Audit date: 2026-08-20.

Repository pin and current default branch:
`e5fa2a4f3e665d082cfc453fd0877f5516200926`.

## Searches

GitHub all-state issue/PR searches covered `build ID DWARF`, `debuglink root`,
`supplementary DWARF`, and `gnu_debugaltlink`. Local searches covered the pin's
TODOs, tests, note parsing, reachable history, and exact repository references
throughout the Olympus candidate/problem/archive indexes.

## Decisive ownership

- [Issue #186](https://github.com/eliben/pyelftools/issues/186), opened in
  2018 and still open, asks for separate-DWARF support using a stripped loader
  and the exact `/usr/lib/debug/.build-id/6f/...debug` convention. Maintainer
  Eli Bendersky replied that it was unsupported and invited pull requests.
- [Issue #594](https://github.com/eliben/pyelftools/issues/594) distinguishes
  external `.gnu_debuglink` DWARF from supplementary `.debug_sup` and
  `.gnu_debugaltlink` DWARF. It is closed by PR #596.
- [PR #596](https://github.com/eliben/pyelftools/pull/596), merged in 2025,
  added the current external-debuglink API and CRC validation. Its description
  expressly says GNU build-ID linking is not supported.

The pin preserves `# TODO: support linking by build ID` immediately before its
debuglink handling. It also warns that inheriting the original loader for an
external file may give a nested supplementary link the wrong directory.

## Conclusion

The original shortlist incorrectly treated PR #596 as adjacent baseline work
without recognizing that still-open issue #186 owns the exact remaining
build-ID/debug-root feature. That is terminal overlap. Per-hop rebasing and
cycle handling are plausible follow-on mechanics, but wrapping them around the
open request does not restore novelty, and alone they do not retain the
candidate's forecast depth.

Verdict: `rejected-upstream-overlap`.
