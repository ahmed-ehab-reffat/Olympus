# eval-results.md — iwe-anchored-links

No agent batch has been run yet. This file tracks per-agent results once a batch runs.

## Local validation runs

| Run | Tree | Mode | Cases | Failures | Verdict |
| --- | --- | --- | --- | --- | --- |
| L1 | base + test.patch | base | 1871 | 0 | PASS (no test breaks the base tree) |
| L2 | base + test.patch | new | 176 | 176 | FAIL as required (liwe target does not compile without the feature, one JUnit node per test; the 6 CLI tests fail on their assertions) |
| L3 | base + test.patch + solution.patch | base | 1871 | 0 | PASS (no regressions) |
| L4 | base + test.patch + solution.patch | new | 176 | 0 | PASS |
| L5-L7 | as L3/L4, repeated 3x in the image | base + new | 1871 / 176 | 0 / 0 | deterministic, identical every run |
| L8 | image, `--network none`, uid 1000 | all four cells | as above | as above | reproduced in the platform image |
| L9 | image, vanilla repo, no patches | `cargo test --workspace` | 1871 | 0 | environment quality green offline |

## Per-agent results

Batch 1 (Auto Review working pool, 2026-08-02): 3 of 10 passed = 30%, inside the <=40% cap. Every failing run kept the 1871-test baseline green.

| Agent | Verdict | New tests | Failure reason |
| --- | --- | --- | --- |
| Nova x3 | PASS | 146/146 | end to end across parsing, graph APIs, expansion, refactors, stats |
| Nova x3 | FAIL | 143/146 | plain, piped and percent-escaped wiki links on `rename_header`: retargeting updated `Reference.url` but set `display_url` to None, and the tree renderer reads the wiki display target |
| Nova x2 | FAIL | 145/146 | fragment-only wiki link `[[#part-one]]` treated as a reference to an empty document key |
| Nova x2 | FAIL | 134-138/146 | wiki targets routed through the ordinary url model, missing the distinct wiki key-resolution and rendering paths; one also omitted `extract_all` relocation |
| Nova x1 | SCRATCHED | build failed | `resolve_anchor` returned `Option<impl NodePointer>`; target did not compile. Contract now pinned and tests decoupled, so this cannot recur |

Effort was 60-100 messages and 843-1219 added lines per run, with no leakage or trivial-solve evidence.
