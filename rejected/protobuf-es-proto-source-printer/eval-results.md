# eval-results.md - protobuf-es-proto-source-printer

No platform batch yet (slice awaiting precheck).

## Local validation (factory SLICE, 2026-10-06)

| Check | Result |
|---|---|
| Reference size | 459 human-effective / 645 raw / 2 files (`effective_loc_check.py`) |
| New tests | 9; base 9/9 fail (TypeError, real ids), solution 9/9 pass |
| Base mode | 3405 testcases, 0 failures, 1 repo skip, with and without the solution |
| Clean room | uid 1000, 0, 4242, `--network none`, cold-built image: identical |
| Cold build | 225 s (`docker build --no-cache`) |
| Hunter spike as written | 4/9 (crash on imports, nested-type order, message trailing comment, `import option` feature) |
| Mutants on reference | M1 no custom-option decoding: 2 fail; M5 group syntax from `delimitedEncoding`: 1 fail; M6 bytes option as UTF-8: 1 fail; no leading dot: 1 fail |
