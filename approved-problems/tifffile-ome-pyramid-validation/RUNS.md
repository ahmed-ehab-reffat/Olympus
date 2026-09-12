# Runs - tifffile OME pyramid validation

## Predecessor Level 1 batch

Raw platform bundles are preserved in `agent-runs/Nova_Nova_1` through
`agent-runs/Nova_Nova_5`. Each evaluation, test log, source patch, workspace
diff, and ATIF trajectory was inspected during the Level 2 design gate.

| Run | Run ID | Predecessor focused result | Production patch | Outcome and replay evidence |
|---|---|---:|---:|---|
| Nova 1 | `rd757zgchcdc5xg2rd2engn5618bys56` | 25/26 | 1 file, 475 raw / 411 strict-effective lines | Near-pass: omitted a child's `NextIFD`. It replays at 34/36 on L2, retaining that failure and accepting equal-area levels. |
| Nova 2 | `rd7cde74rqbd8k5rmyjx8jf0d58bz9tk` | 26/26 | 1 file, 326 raw / 264 strict-effective lines | Legitimate L1 pass. It replays at 35/36 on L2, failing only strict equal-area ordering. |
| Nova 3 | `rd7fz60bq6rbz86531errfvwrh8bzky6` | 25/26 | 1 file, 367 raw / 317 strict-effective lines | Near-pass: omitted a child's `NextIFD`. It replays at 34/36 on L2, retaining that failure and accepting equal-area levels. |
| Nova 4 | `rd7a7kcqrfnfp10ba8ncx34ndd8bzd66` | 26/26 | 1 file, 550 raw / 477 strict-effective lines | Legitimate L1 pass. It replays at 35/36 on L2, failing only strict equal-area ordering. |
| Nova 5 | `rd7ej7m7p18a7gevw9ak50nwcx8bzys3` | 25/26 | 1 file, 346 raw / 271 strict-effective lines | Near-pass: read a later full-resolution frame through its keyframe. It replays at 34/36 on L2, retaining that failure and accepting equal-area levels. |

All runs recorded a 702/702 evaluator baseline. No broad failure is available:
every unsuccessful patch was a 25/26 near-pass, so none is relabeled to fill
that evidence role. The two successful implementations have a median of one
production file and 370.5 strict-effective production lines. The ATIF format
contains one final envelope and 59-89 embedded tool calls per run, but it does
not expose the platform agent-message metric; neither the four ATIF steps nor
tool-call counts are substituted for it.

This was a healthy preliminary 2/5 signal, not a completed ten-run batch. The
prompt, tests, and solution approach changed after trajectory review, so
`CALIBRATION_STRATEGY.md` requires the Level 1 batch to be abandoned. None of
these five results counts toward the revised artifact.

## Superseded Level 2 batch

No cold solver was launched during the Level 2 gap-closure work. Its record
remained 0/10 before the hidden suite changed again.

## Completed Level 3 batch

Raw platform bundles are preserved in `agent-runs2/Nova_Nova_1` through
`agent-runs2/Nova_Nova_10`. All ten contain the identical 655-line focused file
with SHA-256 `dc0b1d817ce0fa4eb17e9c1f102d7c48caba2e6e8b753931610a93ab385f4cff`
and the identical rendered prompt with SHA-256
`38a0eea5fae50f7ea9c91a0b26caf4ef6eac77d26e98381acfe76532c8e59b70`.
Those contents correspond to the frozen Level 3 `test.patch` and `meta.md`.

| Run | Run ID | Evaluator result | Focused | Production files / raw / strict-effective LOC | Distinct outcome |
|---|---|---|---:|---:|---|
| Nova 1 | `rd75vt7m8j02t92f6hwn78h6y58c0xrc` | failed, missed requirement | 36/38 | 1 / 501 / 418 | Treated cached `TiffFrame` objects as full pages and rejected two valid multi-series files. |
| Nova 2 | `rd76rwb09v3hjmheaeft5h76bx8c1aar` | legitimate pass | 38/38 | 1 / 504 / 448 | Complete low-level tag and OME mapping implementation. |
| Nova 3 | `rd734bk81y2mz8veg37zqp6jxh8c1f9n` | failed, missed requirement | 37/38 | 1 / 511 / 412 | Did not reject a child `NextIFD` outside the owner's direct tag-330 list. |
| Nova 4 | `rd7aw4s3fn6eh1gd5h0s0854nn8c1dvv` | legitimate pass | 38/38 | 1 / 391 / 326 | Complete series/page implementation with companion and parser cleanup. |
| Nova 5 | `rd709fwqw2zhbk9nkct9ac7f0s8c1emh` | failed, missed requirement | 37/38 | 1 / 551 / 459 | Repeated the direct-child `NextIFD` omission. |
| Nova 6 | `rd7fmxrp00qhr8b9trpvqe6yks8c0vxb` | failed, missed requirement | 36/38 | 1 / 411 / 336 | Its cleanup iterated an unset series list and leaked `TypeError` on malformed inputs. |
| Nova 7 | `rd779wp2zwq53jbmhz6n626p7h8c1k8b` | failed, unverified assumption | 27/38 | 1 / 356 / 270 | Assumed disabling frames replaced already cached `TiffFrame` entries, rejecting valid multi-plane pyramids. |
| Nova 8 | `rd7bqvfrb1pjrqh5wj7a6hscrd8c1008` | legitimate pass | 38/38 | 1 / 502 / 444 | Complete raw-IFD implementation with explicit tag parsing. |
| Nova 9 | `rd73hxg891nyg8mptd709c23rn8c11vs` | failed, missed requirement | 36/38 | 1 / 443 / 358 | Missed child `NextIFD` and hid a later base IFD's dimensions behind its keyframe. |
| Nova 10 | `rd77famsj72zgz22mhjxgmyprn8c1dnc` | legitimate pass | 38/38 | 1 / 492 / 413 | Complete series-oriented implementation without added repository tests. |

All ten evaluator baselines are 702/702, every environment assessment reports
no blocker, and each evaluator labels the description clear and tests
deterministic. Exact offline replay reproduced every focused result. The six
failures each violate an explicit public requirement and none fails the new
unreopenable-companion cases.

Level 3 therefore completes calibration at 4/10, inside the required 1-5 solve
band. The four successful patches have medians of one production file, 497 raw
added lines, and 428.5 strict-effective production lines. The ATIF schema again
does not expose the platform agent-message metric, so its four envelope steps
are not substituted for that measure.

Difficulty, solvability, and minimum-run gates pass. The successful median
fails the two-production-file long-horizon signal, and the message signal is
unavailable. A further artifact change would abandon this complete batch and
restart calibration at 0/10.

## Superseded Level 4 refreeze

The requested review fix changes `meta.md` and `test.patch`, so the completed
Level 3 batch is superseded for calibration purposes. Level 4 removes the
undefined “unrelated tag choices” promise and adds a separate legal bilevel
fixture with `NewSubFileType=5` children.

The exact 39-case file has SHA-256
`37039375061e8125c96c3651227d1b47396be7094e212100e0d7fddd09e4cacb`.
Pristine upstream fails 39/39, the reference passes 39/39 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 741 passed and 3,548 skipped. All 42 mutants are killed.

Every saved Level 3 patch accepts the new value-5 fixture. Their L4 replay
counts are 37, 39, 38, 39, 38, 37, 28, 39, 37, and 39. The same six public
implementation failures remain. These replays show that the review fix does
not introduce a false negative, but they are not cold runs for the new
artifact. Level 4 starts calibration at 0/10.

## Superseded Level 5 refreeze

The human-review coverage pass parametrizes the mixed-layout positive in both
directions. The exact 40-case file has SHA-256
`4eb95c1a639711cadb5190fa8f3374a0b0d4f34fa6624fc1af2aed24d65339f7`.
Pristine upstream fails 40/40, the reference passes 40/40 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 742 passed and 3,548 skipped.

All 43 mutants are killed. The new directional mutant accepts the predecessor's
tiled-base/stripped-child case, passes the other 38 focused cases and all 702
baseline tests, and fails only stripped-base/tiled-child. Every saved solver
patch accepts the new parameter; their Level 5 replay counts are 38, 40, 39,
40, 39, 38, 29, 40, 38, and 40. Level 5 starts calibration at 0/10.

## Superseded Level 6 refreeze

The next human-review pass adds child-to-child storage independence. The exact
41-case file has SHA-256
`90c96db8ec6e567acbbe961739ca4754ea72ecf26782a66e8e5d739c1ff9e1ac`.
Pristine upstream fails 41/41, the reference passes 41/41 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 743 passed and 3,548 skipped.

All 44 mutants are killed. The new homogeneous-children mutant passes all 40
Level 5 cases and the complete baseline, then fails only the mixed-sibling
parameter. Every saved solver patch accepts the parameter; their Level 6 replay
counts are 39, 41, 40, 41, 40, 39, 30, 41, 39, and 41. Level 6 starts at 0/10.

## Superseded Level 7 refreeze

The five-review-gap refreeze adds strict-only assertion routing, global
cross-series child ownership, rejection of an OME marker with no valid OME
series, independent legal tile dimensions, and strict ceiling division that
keeps an adjacent unit axis equal to one. The exact 46-case file has SHA-256
`e3b12282f4e98db885da7b36f15d0f038785d8684fe638f734a65fc2baed9601`.

Pristine upstream fails 46/46, the reference passes 46/46 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 748 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`4bf413c8bf3402a9af3da320654b7b668224f326be33d97d7aaf31ebfbceffe3`,
and `python setup.py build` succeeds on both architectures.

All 49 mutants are killed. Mutants 45-49 each pass the other 45 focused cases
and all 702 baseline tests, then fail only the corresponding new probe. The ten
saved Level 3 patches replay at 43, 45, 44, 45, 44, 44, 35, 46, 42, and 46.
Runs 8 and 10 remain complete passes; the other results expose public behavior
and are fairness evidence only. No cold solver was launched, so Level 7 starts
at 0/10.

## Superseded Level 8 refreeze

The fairness refreeze removes the undefined empty-series oracle and adds
explicit later-child checks for XY reduction, the reduced-image bit, page axes,
and nonspatial size. It also adds independent full-resolution ImageLength
coverage, a `TiffPage.segments` sentinel, and one valid pyramid combining
PackBits, LZW, Zstd, a short strip, and rectangular tiles. The exact 51-case
file has SHA-256
`972c1b065877b335b14b5ae148261640958d1b1580c57774a54f54489c65f468`.

Pristine upstream fails 51/51, the reference passes 51/51 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 753 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`53bc69c1b93ba92bec53112ab712e8dff3ade04de1548052c8a8c04f754034cd`,
and `python setup.py build` succeeds on both architectures.

All 57 actionable mutants are killed. Mutants 50-58 each pass the other 50
focused cases and all 702 baseline tests, then fail only their intended probe.
The withdrawn empty-series mutant passes 51/51 because that result is no longer
claimed by the hidden suite. The ten saved Level 3 patches replay at 49, 50,
49, 50, 49, 49, 40, 51, 47, and 51. Runs 8 and 10 remain complete passes. No
cold solver was launched, so Level 8 starts at 0/10.

## Completed Level 8 run-3 batch

The supplied `agent-runs3` collection contains ten substantive evaluated
implementations of the exact 51-case Level 8 artifact. Five are legitimate
passes and five miss public requirements, placing the batch at the upper edge
of the 1-5 solve band.

| Bundle | Run ID | Evaluator | Focused | Production files / raw / strict-effective LOC | Distinct outcome |
|---|---|---|---:|---:|---|
| 1 | `rd70zt4hkr3gj30d7qnxytsrp18c1jqt` | missed requirement | 47/51 | 1 / 351 / 289 | Missed direct child topology, per-IFD base shape, and a unit-axis strict case. |
| 2 | `rd74jrpv2vbthqdnp8b3yqke9s8c1vrh` | missed requirement | 47/51 | 1 / 484 / 410 | Parsed OME channel counts without accounting for SamplesPerPixel. |
| 3 | `rd722ph4fja982a90xb2q68y1h8c00a2` | missed requirement | 50/51 | 1 / 550 / 454 | Omitted the direct child `NextIFD` relationship check. |
| 5 | `rd7deetz8k27bfgns38vneb0gd8c1m98` | legitimate pass | 51/51 | 1 / 525 / 446 | Complete raw-mapping and per-IFD implementation. |
| 6 | `rd722y7xgq2e2e08v9bbstm6tn8c0mg1` | legitimate pass | 51/51 | 1 / 343 / 252 | Complete candidate-set implementation with repository tests. |
| 7 | `rd7080wx64bdw4y5zaqrxdme0n8c0gp3` | legitimate pass | 51/51 | 1 / 473 / 420 | Complete page-oriented implementation with repository tests. |
| 8 | `rd7edtwe2h450sa4zyq0562p5d8c17fe` | missed requirement | 46/51 | 1 / 477 / 416 | Missed direct child topology and mishandled RGB sample dimensions. |
| 9 | `rd73cczxzjdgt96w5swdqaavw18c143d` | legitimate pass | 51/51 | 1 / 431 / 353 | Complete interval-factor and companion implementation. |
| 12 | `rd76en6ct5zzn26k1e8y56hakx8c0bqm` | legitimate pass | 51/51 | 1 / 423 / 360 | Complete interval-factor and low-level IFD implementation. |
| 14 | `rd717rzkmg734xsbcycvjdp38n8c11zw` | missed requirement | 40/51 | 1 / 389 / 313 | Rejected valid multi-plane OME series through cached-frame handling. |

The five successes have medians of one production file, 431 raw production
additions, and 360 strict-effective production additions. The trajectory
format exposes four outer envelopes but not the platform agent-message metric,
so no message median is invented. The one-file median fails the long-horizon
file signal even though the LOC and 5/10 difficulty signals pass.

Four extra bundles are retained but excluded from that ten-run result. Runs 4
and 11 stop after the initial agent message, before a tool call, and contain no
solution patch. Runs 10 and 13 contain substantive patches but no evaluator
result; their focused logs report 48/51 and 50/51. All fourteen bundles finish
the 702-case evaluator baseline and the 51-case focused runner, so the two
empty-patch terminations are not repository or environment crashes.

## Superseded Level 9 refreeze

Level 9 adds one valid ambiguous odd-factor sequence and one malformed Pixels
relationship that raises `KeyError` in the repository's OME series builder.
The exact 53-case file has SHA-256
`361463a2b6bef61164b846a41e3fb7922049237997a72c54cb89ed015c027cb9`.

Pristine upstream fails 53/53, the reference passes 53/53 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 755 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`90b48713ce3f9b23f91c9a468fb119ed0ad0179b4742e36979471e4bb925a3c3`,
and `python setup.py build` succeeds on both architectures.

All 59 actionable mutants are killed, all 60 mutant trees pass the complete
pre-existing lane, and the withdrawn empty-series mutant passes 53/53. The ten
saved Level 3 patches replay at 51, 51, 50, 51, 50, 49, 42, 53, 48, and 53.
The ten substantive run-3 patches replay at 48, 49, 52, 53, 53, 53, 48, 53,
53, and 42 in bundle-number order; all five former passes accept both new
probes. No cold solver was launched. Because `test.patch` changed, the Level 8
5/10 batch is historical and Level 9 starts at 0/10.

## Withdrawn Level 10 refreeze

Level 10 removes the repository-internal explanation of the companion's closed
state and requires only reopening when necessary plus prior-state restoration.
It also fixes the reference's parent-local strict-factor bound and adds one
valid `6x6 -> 2x2 -> 1x1` positive. The exact 54-case file has SHA-256
`80bc662332c4780d33e8cea24e8899ab456c6759c7dc74af6b91ad492c0814f4`.

Pristine upstream fails 54/54, the reference passes 54/54 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 756 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`4452ffc22e3a37d65211f41a469de196169daabf1eb17cba4d5fa7710d8acf3a`,
and `python setup.py build` succeeds on both architectures.

All 60 actionable mutants are killed, all 61 mutation trees pass the complete
pre-existing lane, and the withdrawn empty-series mutant passes 54/54. The ten
saved Level 3 patches replay at 52, 51, 50, 51, 51, 49, 43, 53, 49, and 54.
All fourteen run-3 bundles replay at 49, 50, 52, 0, 53, 53, 54, 48, 53, 49,
0, 53, 52, and 42. Only run 7 among the five former Level 8 passes accepts the
new factor boundary; runs 5, 6, 9, and 12 fail only it. Every replayed tree
passes its pre-existing lane. No cold solver was launched, so Level 10 starts
at 0/10.

Fairness review subsequently rejected the new positive: the prompt relaxes
division for odd dimensions only, while its final `2x2 -> 1x1` transition used
ceiling division by a larger factor on even dimensions. The repository's
neighboring helper also rejects that factor domain. Level 10 is therefore
withdrawn at 0/10 rather than retained as a calibration target.

## Historical Level 11 refreeze

Level 11 removes the unfair test and matching reference expansion while
retaining the observable companion reopen-and-restore wording. The exact
951-line, 53-case file has SHA-256
`361463a2b6bef61164b846a41e3fb7922049237997a72c54cb89ed015c027cb9`.

Pristine upstream fails 53/53, the reference passes 53/53 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 755 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`90b48713ce3f9b23f91c9a468fb119ed0ad0179b4742e36979471e4bb925a3c3`.
Build, package, dependency, compilation, shell, and collection checks pass on
both architectures.

All 59 actionable mutants are killed, all 60 retained mutation trees pass the
complete pre-existing lane, and withdrawn mutant 47 passes 53/53. The ten
saved Level 3 patches replay at 51, 51, 50, 51, 50, 49, 42, 53, 48, and 53.
All fourteen run-3 bundles replay at 48, 49, 52, 0, 53, 53, 53, 48, 53, 49,
0, 53, 51, and 42. Every replayed tree passes its pre-existing lane. No cold
solver was launched, so Level 11 starts at 0/10.

## Historical Level 12 refreeze

Level 12 extends the missing-primary mapping test to a named companion whose
OME mapping selects IFD 1 even though the companion has one primary page. It
also replaces brute-force factor enumeration with arithmetic interval
intersection. The exact 963-line, 54-case file has SHA-256
`b140bdd5b9ce5090a465ee3842a65c1f51a06c2af68dc35864f2b58ec4be60a5`.

Pristine upstream fails 54/54, the reference passes 54/54 in both patch orders,
the bounded lane remains 702 passed and 3,548 skipped, and direct combined
pytest completes at 756 passed and 3,548 skipped on ARM64 and AMD64. Both
application orders produce complete-diff SHA-256
`aa5fa384706a8c86189fde58c2d91ac9a9dacc1789c0dcce497cfe364ad3e4cd`.
Build, package, dependency, compilation, shell, and collection checks pass on
both architectures.

All 60 actionable mutants are killed, all 61 retained mutation trees pass the
complete pre-existing lane, and withdrawn mutant 47 passes 54/54. The new
companion mutant passes 53/54 and the complete baseline. Arithmetic factor
results match the old enumeration across 189,225 combinations, while a
billion-pixel parent is represented by one interval.

The ten saved Level 3 patches replay at 52, 52, 51, 52, 51, 50, 43, 54, 49,
and 54. All fourteen run-3 bundles replay at 49, 50, 53, 0, 54, 54, 54, 49,
54, 50, 0, 54, 52, and 43. Every replayed tree passes its pre-existing lane.
No cold solver was launched, so Level 12 starts at 0/10.

## Current Level 13 refreeze

Level 13 guards the optional PackBits, LZW, and ZSTD fixture using
`pytest.importorskip('imagecodecs')` and the three encoder availability flags.
The exact 970-line, 54-case file has SHA-256
`ece4f2440fcbd37c65ce73a9b8fea40c1ae21c9784e0d135e353c3257a607a1f`.

With the frozen encoders, pristine upstream fails 54/54 and the reference
passes 54/54 in both patch orders. With `SKIP_CODECS=1`, the reference passes
53 runnable cases and skips only the codec fixture, while pristine upstream
fails the same 53 and skips the same fixture. ARM64 and AMD64 agree. Both
application orders produce complete-diff SHA-256
`c3b6b43afca13831f6d5edf8961973deffa48fa28f45b6cbb226905ec2c6e845`.

All 60 actionable mutants retain their focused failures, withdrawn mutant 47
passes 54/54, and all 61 retained mutation trees pass 702 pre-existing tests
with 3,548 skips. All Level 3 and run-3 replay scores are unchanged, and every
replayed tree passes its pre-existing lane. Direct combined pytest remains 756
passed and 3,548 skipped on both architectures; build, package, dependency,
compilation, shell, and collection checks pass. No cold solver was launched,
so Level 13 starts at 0/10.
