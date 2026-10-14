# DESIGN.md - vega-keyed-dataset-reconciliation (SHELVED at the measure-first spike)

## 1. Title
Add keyed reconciliation to whole-dataset replacement in Vega

## 2. Lane (hunt #39 fallback 1)
A data set declares `key: <field>`. Every whole-dataset replacement of it (view.data(name, values),
the `setdata` expression, runtime setState, signal-driven `values`/`url` through Load, and the init
preload) keeps the existing tuple for each matching key (same object and tuple id, fields updated in
place, emitted as MOD with the changed fields, fields no longer supplied deleted), removes keys that
are missing, inserts new keys, and gives the data set the order of the new array. Derived data sets,
aggregates and marks see modifications, not a full remove-and-add.

## 3. Phase 1 - repo understanding
- Architecture: vega-parser compiles a spec into a runtime dataflow spec; vega-runtime instantiates
  operators (vega-dataflow Operators/Transforms from vega-transforms etc.) and registers each data set
  by role (input/output/values/index:field); vega-view drives the dataflow and exposes the View API;
  vega-functions provides expression functions (setdata, data, indata). A data set is a pipeline
  [Load?] -> Collect(input) -> transforms -> [Collect] -> Sieve(values); derived data sets start with a
  Relay (derive copies when the pipeline modifies tuples).
- Subsystems: vega-dataflow (ChangeSet, Pulse, Dataflow), vega-transforms (Collect, Relay, Load,
  SortedList), vega-parser (parsers/data.js, DataScope), vega-runtime (context, state), vega-view (data,
  state), vega-functions (data.js), vega-schema.
- Entanglement zones: ChangeSet.pulse (every changeset surface); Collect (every data set input);
  Relay derive (every derived data set).
- Tests: tape, `packages/*/test/*-test.js`; View-level template `packages/vega-view/test/bind-test.js`
  (parse + View), transform-level template `packages/vega-transforms/test/collect-test.js`.

## 4. Phase 2 - exclusivity / six-check (2026-09-29)
- Canonical vega/vega (no move). Base b570ef375a28 = main HEAD; base..main is empty.
- PR search all states: key data, upsert, reconcile, keyed, tuple identity, preserve tuple, setdata,
  view.data, replace data, data key, diff data, identity, setState, Relay, changeset: no lane hit.
  #1951 (2019) added today's view.data replace; #2049 fixed Relay modified-field marking. All 20 open
  PRs listed by file: none touches the lane files.
- Issues read: #1799 (the replace API request), #1055, #357, #1260, #1318 (the add/remove cancel
  safeguard, jheer, deliberate for unkeyed changesets). No decline of keyed replacement.
- Prior-art ruling (v2.6.5 `upsert` trigger): distinct capability. v2 upsert matched ONE signal datum
  by a field predicate and modified-or-inserted it; it never removed missing keys, never kept order,
  never reconciled a whole array, and lived in a trigger. Whole replacement reconciliation is not a
  reintroduction of that removed feature, but its match-then-modify core overlaps, so the platform
  precheck would have been the only judge of the removal-record row. Moot: the lane died on size.

## 5. Measure-first spike (the decisive gate)
Full lane built in the real tree, all of D1-D5 from the dossier kept:
| Decision point | Where it landed | human-eff |
|---|---|---|
| D1 reconcile kernel (key map, null/duplicate policy, per-field diff incl. deleted fields, rem/add/mod) | Collect.js `reconcile` | ~45 |
| D2 last-supplied field snapshot (re-passed mutated object; delete only fields the user supplied, never transform outputs) | Collect.js `supplied`/`refresh`/`update` | ~25 |
| D3 order follows the new array, incl. derived data sets through Relay | Collect.js + Relay.js `order` | ~12 |
| D4 declaration + five surfaces | schema 3, parser 11, ChangeSet.replace 10, view/setdata/setState/preload/Load 1 each | ~30 |
| D5 Relay deletes fields the source dropped; Load holder | Relay.js 4; Load holder needs nothing (kernel ignores pulse.rem on replace) | ~5 |
| **Total (hook)** | 10 files, 168 raw | **123** |

Functional check in the built image (uid 1000, --network none): keyed replace keeps ids and objects,
deletes a dropped field in the root AND the derived set, derived set follows the new order, aggregate
updates, a re-passed object mutated in place propagates to formula and aggregate, setdata, two Load
reloads, setState all correct. Base suites unchanged: dataflow 125, transforms 4168, parser 143,
view 37, runtime 44, functions 205, vega 311 (canvas rebuilt), all pass.

## 6. Why the sketch overshot (machinery-absorbed)
The dossier priced five SURFACES and five decision points. The repo has one chokepoint: every
replacement surface pulses the input Collect, and `ChangeSet.pulse` runs synchronously against that
Collect's tuples. Marking the changeset as a replacement (one method) and reconciling inside Collect
absorbs all five surfaces (one line each), the Load holder (F-58 evaporates because the kernel ignores
Load's `rem`), and the add/remove cancel (F-47 evaporates because the replacement list carries the
re-passed objects). What remains is a ~70-line kernel plus plumbing. No genuine coupled lever adds
the ~130 missing lines: order through arbitrary derived pipelines (filter chains) is ~25, a signal key
~8, composite keys ~5. Keyed insert is the v2 upsert (prior art). Animation/transitions are the #641
magnet.

## 7. Verdict
DEAD: machinery-absorbed UNDER-FLOOR at the measure-first spike (123 human-eff vs the 250 proceed
gate and the 200 floor). The spike is kept as `solution.patch` for reference.
