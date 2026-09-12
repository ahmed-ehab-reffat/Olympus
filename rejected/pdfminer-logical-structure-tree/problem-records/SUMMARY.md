# SUMMARY - pdfminer.six logical structure tree

**Status: locally verified; calibration pending.**

## Target

| Field | Value |
|---|---|
| Repository | `pdfminer/pdfminer.six` |
| Repository URL | `https://github.com/pdfminer/pdfminer.six` |
| Base commit | `a18de2a9c479b4c847538500017b449ddaec177e` |
| Production language | Python |
| License | MIT |
| Task type | feature request |
| Task | Extract an ordered semantic tagged-PDF structure tree and associate page/Form content references with actual layout objects. |
| Platform state | not submitted; fresh calibration 0/10 |

## Canonical artifacts

| Artifact | Current fact |
|---|---|
| `meta.md` | public API, graph, context, association, and safe-malformation contract; SHA-256 `3eaebbc7…` |
| `test.patch` | additive `test.sh` plus 14 deterministic tests; SHA-256 `f564861a…` |
| `solution.patch` | six production files, 492 additions / 18 deletions, about 439 strict-effective additions; SHA-256 `faac3cf4…` |
| `Dockerfile` | approved Python base; exact no-cache offline arbitrary-UID gate passes; SHA-256 `071e5599…` |
| `solution_approach.md` | reference architecture and scope boundaries |

## Verification

| Gate | Expected | Latest result |
|---|---|---|
| test patch, baseline | pass | 249/249 |
| test patch, feature | fail behaviorally | 0/14; 14 failures, zero errors |
| test and solution, feature | pass | 14/14 |
| test and solution, baseline | pass | 249/249 |
| complete combined tree | pass | 263/263 plus Ruff and mypy |
| mutation or shortcut probes | no surviving required mutation | five predecessor survivors isolated at 13/14; no final survivor in attempted set |
| exact environment/gap/fairness/false-positive gates | pass | all pass for immutable v1 |

## Current decision

Promote as calibrated-candidate Level 1. The reference crosses the document,
graph parser, number tree, interpreter, device, Form lifecycle, and layout
surfaces without padding. Exact-version forecast is 1-3/10, inside the accepted
band, but no independent pdfminer.six solver has run. The one next action is the
calibration strategy's local pre-filter: run one or two frontier solvers against
these immutable hashes and harden before upload only if both solve cleanly.

## Outcome

Open. Fresh calibration remains 0/10; passing reference and mutation runs are
not solver calibration.
