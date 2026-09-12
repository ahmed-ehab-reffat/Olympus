# Run index - Calamine structured defined names

Status: accepted on 2026-08-01.

Raw solver material is archived in
`archive/calamine-defined-names/agent-runs.tar.gz`. The archive contains 34 run
directories, 33 completed evaluations, one incomplete run, and the three
original uploaded ZIP bundles. Results below belong to different immutable
problem versions and must not be combined into one calibration rate.

| Collection | Version | Completed runs | Recorded result | Decisive lesson |
|---|---|---:|---|---|
| `agent-runs1` | Level 1 scope/hidden/built-in API | 10 | 9 legitimate passes, 1 near-pass | Cross-format breadth alone was too easy. Successful patches had a median platform LOC of 284 even though the strict reference was 128 lines; the one failure read the XLSB owner one byte early. |
| `agent-runs2` | Level 2 exact trait and compatibility checks | 5 | 5 legitimate passes | Interface precision and the permissive ODS legacy envelope closed false positives but did not materially increase difficulty. |
| `agent-runs3` | Early Level 3 comments and high flags | 2 | 0 passes; both 5/6 | One solver missed XLS high flags and one reused those masks for XLSB, proving that non-aligned native bits formed a distinct boundary. |
| `agent-runs4` | Hardened Level 3 native metadata | 11, plus 1 incomplete run | 3 legitimate passes, 8 focused failures | Six failures reused XLS masks for XLSB and five mishandled XLS comments. The three successful patches added 418-481 lines, confirming substantial implementation without padding. |
| `agents-run5` | Citation-based format guidance | 1 | 0 passes | The implementation reached most formats but missed XLS ownership/comments. Its XLSX prefix classifier exposed a separate finite-set false positive. |
| `agent-runs6` | Citation-only fairness revision | 4 | 0 passes; scores 5/6, 3/6, 4/6, and 3/6 | Microsoft specification requests returned HTTP 403 or empty documents. Solvers then guessed owner fields, comment framing, or high-bit masks, demonstrating that citations alone were not a fair offline substitute. |

## Accepted artifact

The platform accepted the later self-contained revision on 2026-08-01, as
confirmed by the user. It restores only the minimum binary field facts needed
offline, enumerates the finite XLSX built-in set, preserves the two defensible
ODS legacy projections, and keeps every assertion black-box. No new formal
ten-run calibration batch was completed for this final prompt; platform
acceptance is recorded as the outcome rather than retroactively combining the
historical batches.

- Base commit: `0a24c2a9f1e38c0932c1299e633270dc730db505`
- Prompt: 383 words
- Reference: 273 additions and 23 deletions, or 241 strict effective
  production additions across five files
- Focused suite: 6/6
- Wrapper regression lane: 205/205
- Complete suite: 44 unit tests, 161 passing and 1 ignored integration test,
  and 67 doctests
- False-positive audit: fourteen isolated Level 3 mutants, with no survivor in
  the attempted set

## Reusable lessons

- Measure successful solver patches instead of padding a compact reference;
  the Level 1 reference was small while the successful-patch median cleared the
  200-line platform threshold.
- Independent formats are coverage breadth, not necessarily difficulty. The
  harder boundary came from genuinely different data flow: a separate BIFF
  comment record, a trailing BIFF12 nullable value, and non-aligned high bits.
- An exact external citation is not self-contained when the solve environment
  cannot retrieve it. Publish the smallest interoperable field map needed for
  observable behavior, without prescribing helpers or storage.
- Preserve legitimate compatibility interpretations. ODS workbook-only and
  all-record tuple projections both survived because the repository did not
  establish one new policy.
- Add a discriminator only for a public, plausible shortcut supported by
  trajectories or a compiling mutant. Repeated format fixtures are not new
  discriminators by themselves.

Use this file for ordinary navigation. Restore the archive only when inspecting
a representative solver architecture, evaluator decision, or historical
fixture failure.
