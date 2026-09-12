# Tablesaw Arrow stream interoperability run record

Status: **accepted by the platform and archived 2026-08-20**.

These saved batches belong to earlier immutable versions. Their evaluator
verdicts are historical evidence and are not fresh calibration of the accepted
four-artifact package.

| Bundle | Runs | Saved evaluator verdicts | Final-version interpretation |
|---|---:|---|---|
| `agent-runs1.zip` | 10 | 10 legitimate passes | Initial version was too easy; triggered redesign. |
| `agent-runs2.zip` | 5 | 5 legitimate passes | Historical hardening batch; superseded. |
| `agent-runs3.zip` | 10 | 9 legitimate passes, 1 missed requirement | Supplied temporal, validity, and lifecycle discriminator evidence. |
| `agent-runs4.zip` | 5 | 5 legitimate passes | Historical correction batch; superseded. |
| `agent-runs5.zip` | 5 | 5 legitimate passes | Preceded the final architecture redesign. |
| `agent-runs6.zip` | 5 | 5 legitimate passes | Solved the prior 24-behavior version; final compatibility replay is 0/5. |

For the accepted version, every run-6 patch applies and compiles, passes all 24
earlier methods, and fails the four option/registry/batching methods. The
observed compatibility result is therefore 0/5. The expected fresh solve rate
was 2--4/10; no fresh exact-version solver batch was run, so calibration remains
0/10. Detailed trajectory analysis and discriminator rationale remain in
`DESIGN.md`; the raw ZIPs are in the cold archive.
