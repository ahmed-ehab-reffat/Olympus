# Upstream audit - mp4ff CENC sample-group key rotation

Audit date: 2026-08-15.

Repository: `https://github.com/Eyevinn/mp4ff`.

Pin: `745651cf1e4bd8d7bcb7f8f78fd66e26389ef05b` (`master`, committed
2026-08-11).

Status: `rejected-public-AI-assisted-follow-up`.

## Eligibility and repository state

GitHub's repository API reported 652 stars, 123 forks, Go as the primary
language, MIT licensing, an unarchived public repository, and `master` as the
default branch. The clone resolved the pinned commit as both local and remote
default-branch head. The repository has Discussions enabled.

No issue, pull request, discussion, branch, fork, or external request was
created or modified during this audit.

## Search surfaces

The audit searched the exact source, tests, changelog, fetched history, and all
GitHub issue/pull-request states for `seig`, `sbgp`, `sgpd`, `sample group`,
`key rotation`, `KID`, `ParseReadSenc`, and KID-aware decryption. It inspected
the relevant PR body, comments, reviews, release notes, and commits rather than
relying on an exact-title search.

The exact phrase `key rotation` returns no mp4ff issue or pull request. The
broader `seig` search returns the decisive records below.

## Decisive public ownership

| Item | State and evidence | Ownership consequence |
|---|---|---|
| [PR #490](https://github.com/Eyevinn/mp4ff/pull/490) | Merged 2026-04-06. Added repeated `kid:key`, `DecryptSegmentWithKeys`, `DecryptFragmentWithKeys`, track-KID lookup, and strict missing-key handling. The author disclosed that large parts were produced with AI assistance. | Creates the exact API and key-selection seam the candidate would extend. |
| [PR #490 maintainer comment](https://github.com/Eyevinn/mp4ff/pull/490#issuecomment-4194558288) | The maintainer states that the change reads the KID from `tenc`, not when a `seig` sample-group entry overrides it, and says this may need later enhancement. | Publicly names the candidate's central missing behavior and intended continuation. |
| [PR #495](https://github.com/Eyevinn/mp4ff/pull/495) | Merged documentation change recording that KID lookup only reads `tenc` and does not support `seig` overrides. | Makes the limitation durable and directly searchable in history. |
| [PR #502](https://github.com/Eyevinn/mp4ff/pull/502) | Merged v0.52 release notes repeat that `seig` sample-group overrides are not yet supported. | Publishes the exact gap as released product scope. |
| [PR #494](https://github.com/Eyevinn/mp4ff/pull/494) | Merged adjacent work establishes SENC IV-size priority as `seig`, then `tenc`, then heuristic. | Supplies nearby parsing architecture and confirms that `seig` is the authoritative override source. |

The default branch contains no completed sample-level key-rotation
implementation. That does not clear the seed: exact upstream ownership includes
an explicit planned follow-up, not only an open implementation PR.

## Localized agent provenance

PR #490's disclosure is sufficient for the rejection. Additional localized
evidence strengthens it:

- current `CLAUDE.md` describes the repository architecture and dual decode
  paths for Claude Code;
- sample-group PRs #509 and #510 disclose Claude-generated code; and
- PR #515 discloses Claude-generated code across the current MV-HEVC tool and
  its `sbgp`/`sgpd` construction.

This audit does not blacklist Eyevinn/mp4ff. It rejects the proposed task
because the exact API, gap, override source, and follow-up direction are public
inside an AI-assisted implementation neighborhood.

## Ownership verdict

The candidate rating is capped at **4/10 current** and its status is
`rejected-public-AI-assisted-follow-up`. The original 8/10 shortlist verdict
resulted from an under-broad exact phrase query and is superseded. Do not
reframe the same continuation as multi-run SENC parsing, per-sample KID
selection, or CENC rotation. A materially unrelated mp4ff subsystem may be
screened independently.
