# Difficulty levels - OpenEXR multipart Image I/O

Target band: 1 to 5 solves in 10 completed platform runs.

| Revision | Main discriminator | Historical result | Current calibration |
|---|---|---|---:|
| v2 | heterogeneous filename multipart I/O | four passes, one verifier mismatch | superseded |
| v4 | positive deep header-window crop | five later passes | superseded |
| v5 | complete move-only traits | five of five passes | superseded |
| v6 | caller-owned streams and isolated named-part decoding | five of five passes | superseded |
| v7 | exact case-sensitive selection and fail-fast evaluator | five of five passes | superseded |
| v8 | non-ASCII UTF-8 filename I/O and guaranteed pre-test JUnit | five of five passes | superseded |
| v9 | hybrid selective rewrite: encode replacements while structurally preserving untouched parts | no contract-complete historical solver | 0/10 |
| v9.1 | fairness-only removal of invalid-save stream atomicity | no fresh solver; v9 behavior otherwise unchanged | 0/10 |
| v10 | full selective/rewrite header fidelity and unnamed structural rewrite | run-7 replay: four passes, one near-pass | superseded |
| v11 | bounded windowed named load with four-family outside-damage isolation | exact run-7 replay: zero of five pass | 0/10 |
| v11.1 | description-only cleanup; behavior unchanged | no fresh solver | 0/10 |
| v11.2 | description review cleanup; tested behavior unchanged | run 8: two passes, one near-pass, two broader failures | superseded |
| v12 | complete replacement-header equivalence between `rewriteImages()` and `saveImages()` | exact replay keeps both legitimate run-8 passes at 14/14 | 0/10 |
| v13 | destination-safe rewrite rejection and explicit ripmap window rejection | exact replay keeps both legitimate run-8 passes at 14/14 | 0/10 |
| v14 | apply every replacement and preserve a typeless legacy header exactly | run-8 replay: one 14/14 pass; former second pass is 13/14 | 0/10 |
| v15 | fairness-only freedom for raw or synthesized legacy load headers; exact typeless rewrite remains | run-8 replay: 14/14, 13/14, 12/14, and 6/14 controls | 0/10 |
| v16 | apply a matched replacement across the named typeless ordinary single-part fast path | run-8 replay: one 14/14 pass with 13/14, 12/14, and 6/14 controls | 0/10 |
| v17 | reject a replacement whose name exists only on an unsupported source part | all four run-8 controls pass the new predicate; focused scores remain 14/14, 13/14, 12/14, and 6/14 | 0/10 |

Revision v9 is the first redesign that crosses the shared architecture of all thirty historical solutions. Every prior solver eagerly decoded supported parts and none combined high-level replacement encoding with structural preservation of untouched compressed data. The final verifier kills decode-and-resave, strict unknown-type, and overload-asymmetric shortcuts.

Revision v10 closed fidelity gaps but did not change the shared eager selected-part
architecture: four run-7 solutions still passed. Revision v11 adds a public
bounded named-load seam. Its exact black-box verifier kills eager reads in flat
and deep scanline and tiled paths independently.

Run 8 provides a two-of-five result for v11.2, inside the target difficulty
band. Revisions v12 and v13 close verifier gaps without rejecting either
legitimate pass, but each artifact change resets calibration. The v13 solve
rate is therefore unmeasured at 0/10. Revision v14 exposes one former pass at
the explicit typeless-header boundary while retaining another independent
14/14 solution; its fresh solve rate is likewise unmeasured at 0/10.

Revision v15 corrects the returned-header oracle without relaxing the harder
serialized rewrite invariant. Both raw and synthesized load-header
architectures pass, all 73 incorrect mutants remain killed, and fresh
calibration restarts at 0/10 because `test.patch` changed.

Revision v16 crosses that legacy producer with matched rewrite state. It kills
the prior reference's raw-copy shortcut while retaining the independent run-8
14/14 implementation. All 74 incorrect mutants are killed, and fresh
calibration restarts at 0/10.

Revision v17 crosses source support classification with replacement matching.
It kills the match-before-filter shortcut while all four historical rewrite
architectures pass the new predicate. All 75 behaviorally incorrect mutants
are killed, and the artifact change restarts calibration at 0/10.
