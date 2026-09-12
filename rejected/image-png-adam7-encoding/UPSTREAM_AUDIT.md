# Upstream audit - image-png static Adam7 encoding

Audit date: 2026-08-15.

Original verdict: **no exact implementation owner found at the pinned
repository head**. Superseding disposition: **terminal external prior-work
rejection reported on 2026-08-15**.

## Eligibility

| Fact | Value | Primary source |
|---|---|---|
| Repository | `image-rs/image-png` | <https://github.com/image-rs/image-png> |
| Default branch / head | `master` / `721fd56651038c51bb3a6c2eabe9ab11b086db6e` | <https://github.com/image-rs/image-png/commit/721fd56651038c51bb3a6c2eabe9ab11b086db6e> |
| Pin date / subject | 2026-08-06 / merge PR #711 | local Git and GitHub |
| Stars / forks | 512 / 170 | GitHub repository API, 2026-08-15 |
| Production language | Rust | source tree and GitHub repository API |
| License | `MIT OR Apache-2.0` | `Cargo.toml`, `LICENSE-MIT`, `LICENSE-APACHE` |
| Activity | unarchived; last push 2026-08-06 | GitHub repository API |
| Regression suite | Cargo unit, integration, doctest, corpus, and fuzz targets | `Cargo.toml`, `src`, `tests`, `fuzz` |

The repository passes the current hard gates, although its star count is close
to the 500 minimum. No contribution policy restricting assisted development was
found. The latest 500 default-branch commit messages contain no explicit
ChatGPT, Claude, Copilot, Gemini, or generated-with coauthor marker.

## Exact source and history result

The pin is also the current remote default-branch head. Source, tests, docs,
all fetched refs, branch names, and Git history were searched for Adam7,
interlace/interlaced encoding, encoder pass extraction, `info.interlaced`,
`InterlacedEncodingUnsupported`, `Adam7Iterator`, packed pass rows, and the
slice/stream writer paths.

The only encoder-side history is merged
[PR #681](https://github.com/image-rs/image-png/pull/681), commit
`d825ac3`. It demonstrates that `Info::interlaced` previously advertised Adam7
while writing ordinary rows, then replaces corrupt output with an explicit
error. Its body and commit message say proper Adam7 encoding is a separate
feature and contain no implementation of that feature.

Decoder-side Adam7 history implements geometry, expansion, progressive output,
overflow fixes, and benchmarks. It supplies reusable repository concepts but
does not extract encoder pass rows. No remote branch name or fetched ref
advertises an encoder implementation.

## Issue, pull-request, discussion, release, and branch searches

| Surface | Queries / states | Result |
|---|---|---|
| Issues and PRs | `Adam7 encoding`, `interlaced encoding`, `encoder interlaced`, `interlace encoder`; open and closed | Only PR #681 is exact; it implements rejection, not encoding. No exact issue owns the feature. |
| Open PRs | full current inventory plus titles/diffs for #703, #707, and #708 | #703 is interlaced APNG decoding; #707 changes first-row filter allocation; #708 repairs non-interlaced streaming APNG frame state. None emits static Adam7 pass data. |
| Discussions | repository discussions and web/GitHub search with the same terms | Decoder performance discussion #416 is adjacent; no static encoder design or implementation found. |
| Code / tests | pin, all fetched refs, and `git log -S`/`--grep` | Static encoding remains rejected; decoder geometry and corpus fixtures exist. |
| Changelog / releases | all `CHANGES.md` Adam7/interlace entries and tags | Unreleased notes identify Adam7 encoding as not implemented; earlier entries concern decoding. |
| Fork lead | PR #681 head and linked history | The contributor branch contains the rejection patch only; no abandoned encoding patch is linked. |

Direct search links:

- <https://github.com/image-rs/image-png/issues?q=is%3Aissue+Adam7+encoding>
- <https://github.com/image-rs/image-png/pulls?q=is%3Apr+Adam7+encoding>
- <https://github.com/image-rs/image-png/issues?q=interlaced+encoding>
- <https://github.com/image-rs/image-png/discussions?discussions_q=Adam7+encoding>

## Maintainer alignment and scope boundary

PR #681 was approved and merged quickly, and its public explanation explicitly
separates corruption prevention from a future correct Adam7 encoder. That is
positive alignment, not an ownership claim or maintainer decline.

Active PR #708 changes `StreamWriter` for APNG, and #703 changes interlaced APNG
decoding. The selected problem therefore covers static PNGs only. It must not
define frame-rectangle, default-image, blend, disposal, or APNG sequence policy.
The hidden patch must use additive test paths so those adjacent production PRs
remain evaluator-composable at the selected pin.

## Local history and similarity

No local image-png or Adam7 problem exists. The nearest writer problem,
TwelveMonkeys SGI, is terminal after an external similarity rejection and must
not be reused; its planar orientation, SGI RLE tables, Java ImageIO discovery,
and 16-bit atom rules are materially different from PNG pass extraction,
row-filter state, DEFLATE, and Rust producer modes.

OpenEXR and tifffile cover multipart and recovery behavior rather than this
encoder transform. Adam7 itself is standardized and benchmarked, so similarity
risk remains moderate. The problem is viable only if the repository-specific
slice/stream integration, packed samples, filtering, compression branches, and
publication lifecycle produce measured depth beyond a textbook seven-pass
loop.

## Historical verdict and superseding disposition

The original local verdict was `proceed`: no issue, PR, branch, discussion,
release, or linked fork found by that exact-pin screen implemented the feature.
The package subsequently passed Phase A and two complete disposable prototypes.

On 2026-08-15, external review reported that the problem had already been done.
That broader prior-work finding supersedes this repository-local audit. The
final disposition is terminal rejection and archive; no further ownership
search, redesign, submission, or calibration is authorized for this task.
