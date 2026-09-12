# amaranth-stream-width-converter — eval results

No PLATFORM runs yet. Local validation ALL GREEN (see feedback.md): 8 elements fuzz-verified correct (600/400/200/200 trials, 0 mismatches); the obvious data-loss bug fails 73/80 fuzz configs (discriminating); 17 new tests FAIL on base (elements absent) / PASS on solution; 530 base regression tests pass (formal/sby tests excluded with reason); human-effective 279 (>250 floor). Predicted ~10-30%. Imitator probe pending (must NOT one-shot).

| Batch | Agent | Verdict | Files | LOC | Notes |
|-------|-------|---------|-------|-----|-------|
| local-imitator | Sonnet (meta-only) | pending | - | - | clean-base difficulty probe |
