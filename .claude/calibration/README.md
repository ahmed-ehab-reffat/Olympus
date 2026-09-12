# LOC-tool calibration anchor

This folder holds the single ground-truth data point that calibrates
[`../hooks/effective_loc_check.py`](../hooks/effective_loc_check.py). It is NOT an approved task and
NOT a reference to clone — it is a tooling asset that lives with the tool and travels with `.claude/`.

## The anchor

`sqlglot-window-functions.solution.patch` is the `solution.patch` of a REVERTED Olympus submission
(window-function execution in sqlglot). A human reviewer re-counted it and rejected it as under the
400 floor:

- raw added            = 393  (2 files)
- HUMAN effective count = ~346  (the reviewer's "effective LOC excluding repetitive/dead code")

This is the evidence behind the rule baked into the hook: a human counts close to the STRIP
(raw minus blank/comment/bracket/docstring lines), NOT an aggressive compression pass.

## Re-validate the hook (run any time the calibration is questioned)

```bash
python3 ../hooks/effective_loc_check.py sqlglot-window-functions.solution.patch
```

Expect `human-effective` to read ~332 — within ~4% of the 346 human truth. If it drifts far from
that, the strip method (`human_effective()`) has regressed and needs re-tuning against a fresh
ground-truth re-count.

## Why only this file

The LOC tool measures whatever `solution.patch` you point it at and never reads this folder at
runtime, so the rest of that submission (meta/tests/Dockerfile) is not needed here. The reject
*lesson* lives in the `olympus-loc-floor-trap` memory and `CLAUDE.md`; this folder keeps only the
measurable patch so the calibration claim stays auditable.
