# Hunt miss diagnosis (2026-10-05)

Scope: 48 hunt logs (09-20 to 10-05), LEDGER, hunter contract, hunt skill, PICK-FILTER, SATURATED-REPOS, TOO-EASY, `approved-problems/`. Hunters #34-#55 ran 22 times and returned 10 candidates and 12 misses. Three of the 10 came from repos we had already shipped (Cwerg, MACS, teavm). Five of the discovery picks or their fallbacks then died under the LOC floor at slice.

## 1. Kill-reason tally

Keyword pass over 405 DEAD/WEAK verdict rows; rows carry 2-3 reasons, 79 matched none, bulk-filter drops not counted.

| Kill reason | Rows | Hard platform rule? |
|---|---|---|
| Maintainer firehose / roadmap / "capability-consuming" | ~72 | No |
| LOC sketch / absorbed / no seam | ~71 | Floor is real; the sketch is a guess |
| Maintainer AI sweep (trailers, `ai=N`, Copilot/Claude commits) | ~66 | No |
| Public PR diff / magnet / dormant PR queue | ~61 | Yes when the diff covers the lane |
| Named spec / famous / port / language surface | ~47 | Partly (derivative record) |
| Signature / competitor accounts, bursts | ~46 | No |
| Activity / corpse | ~44 | Yes |
| Requirement 7 CI | ~37 | No (base must pass; CI is a proxy) |
| App / framework / catalogue | ~32 | No |
| "Already judged / stays dead" | ~26 | No |
| Derivative / self-collision | ~24 | Yes, lane-level |
| Licence | ~19 | Yes |
| Docker / build / language share | ~18 | Partly |
| Star floor (incl. a self-imposed ~520 buffer) | ~11 | 500 only |

## 2. Gates that kill more than their evidence justifies

| Gate | Hunt kills | Platform rejections it ever caused | Verdict |
|---|---|---|---|
| Firehose / maintainer activity outside the lane | ~72 | None. neva (600 commits/12mo) and piscsi were accepted; piscsi's second lane then died for "rdmark commits in every subsystem" | Over-strict; breaks corrected Gate 5 and softening (4) |
| AI-sweep marks | ~66 | None | Self-imposed; whole repos still die on trailer counts despite the 09-23 "lane-scoped" ruling |
| Signature accounts | ~46 | None traced. sfepy screened clean yet had 25 platform subs, so the screen does not measure saturation | Self-imposed; its two-accounts-anywhere threshold is repo-level |
| Requirement 7 | ~37 | None. causal-learn's real problem was failing in-lane tests, which Gate 9 catches | Over-applied (govulncheck, one Windows leg, "intermittent Build") |
| <=6 per repo (Gate 10) | Indirect | None. dasel 9, cliffy 7 and yaegi 7 were all submitted; sfepy at 25 got "proceed at your own risk" | A warning that PICK-FILTER and SATURATED B call a hard cap; contradicts the ~12/repo peer norm |
| Derivative / exclusivity | ~85 combined | About 16 real rejections (gluon, koto, lol-html, orb, dyn4j, openglobus, pyfakefs-locks, nickel, ...) | Justified, but every one was **lane**-level. sfepy's 25 subs overlapped ours by only 1.9% |

The approved set agrees: 129 accepts include second lanes in ray-optics, grmtools, featurevisor, python-control, starlark-go, yara-x, customasm and others. No record shows a repo itself being the problem.

## 3. The "already seen" mechanism retires repos permanently

Yes, in three ways:

- **Hunter contract, item 2:** "Every repo listed in LEDGER, in any status, is taken." A repo whose row died for LOC (aerich, vega, vrp) or is CLAIMED is blocked in every subsystem. The user's override at misses=4 (#53) produced the only candidate of #49-#55.
- **The dead-list counts mentions, not verdicts.** The sweep filter excludes "every owner/repo ever mentioned"; it grew from 15k to 74.6k slugs. 09-23-E found 1,122 rows dead-listed only because a sweep displayed them; 10-05-C found 9,171 never-read rows dropped since #44.
- **Lane reasons are recorded as repo verdicts.** ("Stays DEAD: repo-wide", SATURATED B3-bis..tredecies, the "two tracker lanes dead" stop rule). None expire; the one time-decay pass (#38) covered 30 repos.

## 4. The LOC-floor deaths share one shape

| Pick | Paper | Measured | Primitive that absorbed it |
|---|---|---|---|
| aerich squash | ~250 | 157 | ledger pk, MODELS_STATE |
| continuum squash | n/a | 146 | transaction tables |
| healthchecks lateness | ~240 | 194 | `get_grace_start`, flip replay |
| vega keyed reconcile | n/a | 123 | `ChangeSet`/`Collect` |
| vrp clustering roundtrip | n/a | 155 | `restore()` recomputes schedules |

All are **"carry state through / make X survive Y"** lanes over a mature kernel: traps reproduced on base, but each fix was 1-2 lines, and all were returned on paper estimates. Hunt-time spikes (riff 440, grmtools 362, asdf 362, MACS 312) all cleared, and lanes adding a **new** table/module/kernel outgrew paper (micasa 270 to 487, commafeed 240 to 335).

Tell: the lane adds no new persistent structure AND each reproduced trap's minimal fix is <= 3 lines. Then spike before returning.

## 5. Ranked changes (no hard platform rule touched)

| # | Change | Risk |
|---|---|---|
| 1 | Hunter contract item 2: exclude only the **lane/subsystem** in a LEDGER row, not the repo. Make "second, different-subsystem lane on shipped/claimed repos" a permanent Stage 0-bis default, checked against <=3/week | Low |
| 2 | Restate Gate 10 everywhere (PICK-FILTER, SATURATED B header, skill Stage 2, CLAUDE.md) as a warning: >6 of ours is a ranking penalty. Only A0 (reserved) and A (platform "heavily over-used") are repo-dead | Low |
| 3 | Split the dead-list into **judged** (slug, lane, reason, date) and **displayed**. Exclude only judged rows with a repo-level hard reason (licence, language, activity, stars, reserved, global-saturated). Lane verdicts expire after 60 days | Low |
| 4 | ~45 min hunt-time spike on any lane matching the section 4 tell; return it if the spike measures >= 220. Drop the flat ">= 250 on paper" bar (~49 WEAK rows sit at 200-249) | Low |
| 5 | AI marks and commit velocity: a lane verdict only when the commits/PRs close the intended capability. Never kill on repo-wide counts | Medium (Gate 1/6 still catch an erased F2P gap) |
| 6 | Signature accounts: a note unless a PR falls inside the intended lane. Drop the "two accounts anywhere" reject | Medium (derivative check stays the real gate) |
| 7 | Requirement 7: reject only on a failing **test** workflow on the default branch that touches the lane. Otherwise pick a green base or exclude unrelated tests with a reason | Low |
| 8 | Drop the ~520 star buffer to a ~505 margin (tylax 501 and pokerkit 502 sit waiting) | Low |
