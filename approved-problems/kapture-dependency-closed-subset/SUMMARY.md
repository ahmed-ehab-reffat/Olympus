# Summary — kapture dependency-closed dataset subset

Status: `accepted by the platform and archived 2026-08-19; immutable v8`.

- Repository: `naver/kapture`
- Pin: `8225b77d0657e6a3eb1ffc941d009100b792fb25`
- Version ID: `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`
- V7 observed fresh result: 5/5
- V8 fresh expectation: 2–4/10

The user confirmed platform acceptance on 2026-08-19. Acceptance is an
external result; fresh exact-v8 calibration remained 0/10 at closeout.

V8 retains reverse image-seeded dependency closure and transactional saved
materialization, then makes forced replacement ownership exact. Old kapture
metadata and record/ordinary-feature/match/tar payloads absent from the new
dataset are retired, while unrelated files survive even inside standard record
and feature directories. The CLI paragraph was tightened without changing its
exact PEP 621/module contract.

The exact no-cache gate passes offline as non-root. The reconstruction reference
and an independent inverse-overlay architecture each pass 181 base tests with
five skips and all 13 focused nodes. All 39 attempted mutants are killed.

The pre-change compatibility forecast was 1/5 and replay observed 1/5: runs
1–4 fail only nested unrelated-file preservation, while run 5 passes 13/13;
all five remain 181/five on base. This confirms the discriminator but does not
count as fresh v8 calibration. A new exact-version batch must start at 0/10.
