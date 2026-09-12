# Plan — kapture dependency-closed dataset subset

Status: `accepted by the platform and archived 2026-08-19; immutable v8`.

1. V7 trajectory/calibration review. **Complete:** all five fresh passes and
   their raw patches/trajectories were inspected.
2. V8 ownership discriminator gate. **Complete:** recorded in `DESIGN.md`
   before verifier changes; forecast 1/5 compatible and 2–4/10 fresh.
3. Public prompt, reference, alternate architecture, and verifier revision.
   **Complete.**
4. Exact no-cache offline/non-root environment gate. **Complete.**
5. Exact gap and fairness audits. **Complete:** both pass.
6. False-positive audit. **Complete:** one force/alias survivor closed; final
   result 39/39 killed after a full restart.
7. Compatibility replay. **Complete:** forecast 1/5, observed 1/5; all five
   pass base.
8. Freeze immutable hashes. **Complete:** version
   `08aaa4d7231bb1232f0bb29c4c2705ad7442fd0b7e7f4ef4e04f5a46fc9eeac2`.
9. Fresh solver calibration. **Closed without a new batch:** platform
   acceptance was user-confirmed on 2026-08-19; exact-v8 calibration remained
   0/10, with the historical expectation recorded as 2–4/10.

Any artifact revision restarts every gate and calibration from zero.
