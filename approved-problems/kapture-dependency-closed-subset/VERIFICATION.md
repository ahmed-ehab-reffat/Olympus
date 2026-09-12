# Verification — immutable v8

Repository: `naver/kapture @ 8225b77d0657e6a3eb1ffc941d009100b792fb25`.

Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.

- Final no-cache Phase A: 181 passed, five pre-existing skips, offline as
  UID/GID 10001.
- Pristine plus verifier: 181/five base; 0/13 focused with 13 failures and zero
  errors.
- Reference plus verifier: 181/five base; 13/13 focused.
- Mandatory independent architecture B: 181/five base; 13/13 focused.
- JUnit testcase identities match; `test.sh` is executable and writes XML in
  both modes.
- All 39 exact-version mutants are killed; no focused survivor exists.
- All five v7 fresh patches pass base. Runs 1–4 pass 12/13 focused; run 5
  passes 13/13. Observed compatibility is the forecasted 1/5.
- `git apply --check` passes for verifier, reference, architecture B, and every
  targeted mutant.
- The approved base digest is
  `sha256:6ddc78fc675e6cd3a63b60fc63d87eea35a479f503a44a89cf92923abe905dd8`;
  the final manifest-list digest is
  `sha256:0c46ce5b382b64f77cb4e18906e82d67f75187c066be5c0c7f51cbf1990cd6ff`.
- Exact gap, fairness, and false-positive verdicts pass.

Fresh v8 calibration is 0/10. The exact-version expectation is 2–4 successful
solvers out of ten; the 1/5 result above is compatibility replay only.

