# Upstream audit — ICU4X ZeroTrie cursor parity

Repository: `unicode-org/icu4x`

Pinned commit: `c0846c9000467f1292e6d6a0e98db6798cf6a417`

Initial audit date: 2026-08-14

Submission recheck: 2026-08-15

The repository is active, unarchived, has approximately 1,844 GitHub stars, and
uses the permissive Unicode-3.0 license. The pin is the then-current `main`
commit, `Add segmenter comparison benchmarks (#8141)`.

GitHub issue/PR searches covered `zerotrie cursor`, `ZeroTriePerfectHash
cursor`, `ZeroTrieExtendedCapacity cursor`, `cursor parity`, and all open
ZeroTrie/cursor issues and pull requests. Source and history searches covered
cursor support, stepping, probing, spans, PHF, extended capacity, and all
ZeroTrie commits.

The relevant merged history is:

- #4383 introduced the simple ASCII cursor for streaming lookup and longest
  prefix matching;
- #4725 and #4735 added indexed probing and sibling counts;
- #8242 added `get_with_write_fn` for the two existing ASCII cursor types; and
- #8224 added suffix-trie extraction for the existing ASCII cursor types.

No issue or pull request implements or requests cursor support for
`ZeroTriePerfectHash`, `ZeroTrieExtendedCapacity`, or runtime-dispatched
`ZeroTrie`. The closest open work is #8248 (optional `writeable` integrations),
#4408/#4561 (future type simplification/refactoring), and #7621 (provider
binding work that carried the already-merged ASCII suffix helper). None owns
binary span, PHF, extended-offset, or runtime-dispatched cursor traversal.

The exact gap is explicit in `reader.rs`: cursor stepping/probing asserts that
binary spans, PHF branches, and extended capacity are not implemented, while
ordinary lookup and allocating iteration already implement those layouts. This
is repository-native parity work rather than an external standard exercise.

Recent repository history does contain disclosed agent-assisted work and Gemini
co-authorship. The ZeroTrie cursor commits themselves are maintainer-authored,
and no public agent plan or contribution was found for this exact missing
surface. Recheck open work immediately before submission because this
repository and subsystem are active.

## Submission recheck

On 2026-08-15, `git ls-remote` still reported upstream `main` at the pinned
commit `c0846c9000467f1292e6d6a0e98db6798cf6a417`; there are no intervening
upstream commits to the ZeroTrie reader or cursor files.

Fresh GitHub API searches covered all open `zerotrie`, cursor-title,
`zerotrie cursor`, `ZeroTriePerfectHash cursor`, `ZeroTrieExtendedCapacity
cursor`, `cursor parity`, open ZeroTrie PRs, and open cursor PRs. The exact
queries found no issue or PR owning the requested typed/runtime cursor surface.
The sole result for `zerotrie cursor` remains #4393, a 2023 naming issue for
`as_borrowed`; there are zero open cursor-titled issues/PRs and zero results for
the two new typed cursor queries or cursor parity.

The 32 broad open ZeroTrie results still include #8248, #8244, #4408, #4034,
#7621, and unrelated consumers/optimizations. None adds binary-span, PHF,
extended-offset, or runtime-dispatched cursor traversal. The upstream ownership
verdict remains **pass** for this immutable escalation.
