NEXT (human): Requirement 0 picker check + upload this slice to the platform precheck, then write the verdict in pipeline/INBOX.md

# asdf-conversion-free-lazy-tree - feedback

## Status (2026-09-26, factory MODE=SLICE)
SLICE-READY. Core slice built and validated in a Docker clean room. No differentiating scope added
(no private-block / version / cross-file / storage-override / multi-type / to_info cells yet).

- Repo asdf-format/asdf (canonical, 567 stars, BSD-3, Python), base `376790c2` (main HEAD).
- Solution: 6 files, human-effective 367 (hook), raw 443, padding-floor 300.
  `_pass_through.py` new 253, `search.py` 43, `_node_info.py` 38, `_asdf.py` 26, `_display.py` 4,
  `yamlutil.py` 3.
- Tests: 11 new (`asdf/_tests/test_lazy_untouched_11b889.py`), 11/11 fail on base, 11/11 pass with
  the solution. Base mode: 2196 cases (2194 pass + 2 xfail) unchanged.
- meta.md draft: 460 words (body incl. title), ASCII, frontmatter.

## Source
Hunt #33 (`Instructions/repo-hunt-logs/REPO-HUNT-2026-09-26.md`): composite of lane 1 (lazy_tree
pass-through write, measured 176 alone = dead) and issue #1795 (info/search without conversion,
195 alone) on one shared raw-or-converted kernel. The two halves are one capability: a conversion
forced by search/info must go through the tree so the writer sees it (probes P4/P5/P7 fail with
lane 1 alone).

## Scope-lock gates (all PASS, details in DESIGN.md)
- PICK-FILTER 1 (behavioural F2P): base raises through a converter nothing asked for in
  info/search, re-tags every custom object on write_to/update, converts on update.
- 5 cold, 6 reproduce on base (15 spike probes re-run against a fresh clone: all fail on base,
  all pass on the solution), 7b exclusivity PR-DIFF clean, 8 defined behaviour (maintainer #1795).
- SIX-CHECK clean. binggao1230 (#2058 `_node_info.py` recursion, #2069) re-checked by diff: no
  conversion logic, NOTE only.
- Quota 0/6.

## Risks carried into FINISH (from the hunt, still open)
- Spec load: meta has ~10 behaviour sentences. T4 (conversion through the tree), T2 (alias
  identity), T3 (chain-wide filter order), T1 (`_serial_write` copy), T6 (update renumbering)
  survive being stated; T5/T7 (ndarray info / declared type) are transcribed, count as FP insurance.
- Q3: 253 of 367 lines are one new module wired into ~12 sites in 5 files. It is the kernel the
  existing walkers call, not a post-pass.
- ~40% class overlap on the write half with approved enmime-preserving-edits; meta frames ONE
  capability.
- The dedupe is the real unknown: the core is the kernel itself, so this slice IS what the
  precheck must see.

## Decisions made unattended (conservative choices)
- Slug `asdf-conversion-free-lazy-tree`.
- The slice solution is the spike prototype (it is exactly the core kernel), cleaned up: separate
  `from ._pass_through import ...` (no multi-line import churn), `_lazy_tree_version` /
  `_lazy_tree_private_blocks` initialised in `AsdfFile.__init__`, the `PassThrough` created
  explicitly in `_write_tree` (the yamlutil walker only reads it), and the `open(lazy_tree=...)`
  docstring updated to the new behaviour. No towncrier `changes/` fragment (no PR number; docs
  are outside solution.patch).
- `Issue: N/A` in the frontmatter: the pick is an invented composite; #1795 informs only half of
  it and is a vague "consider investigating", so it is not linked as the binding spec.
- Docstrings kept on the new module's public helpers (the repo docstrings its source); no inline
  comments; test bodies comment-free.
- Test doubles use a raising `from_yaml_tree` and tag versions (behavioural) instead of call
  counters.
- test.sh sets `USER` when unset: `asdf/_tests/test_api.py` calls `getpass.getuser()` at import,
  which raises KeyError for a uid with no passwd entry (1000 and 4242 in the image).

## Attempt history
- 2026-09-26: folder created, DESIGN.md, slice built, Docker clean room green (uid 1000, 0, 4242,
  `--network none`), patches generated.
