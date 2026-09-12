# DESIGN.md — python-control-analysis-points

## 1. Title

Add analysis points and loop transfer analysis to interconnected systems

Verb-led, 8 words, names the subsystem (`interconnect` / interconnected systems).

## 2. Shape classification

- Shape: **O-Composite-add** (new capability spanning the interconnection builder,
  the interconnection data model, the linear specialization, and a new analysis
  module) with an O-Algorithm-correctness core (the loop-opening kernel).
- Pass rate target: **<=40% cap; designed for the corpus mode of 1/10.**
- Best agent: Vega / Orion (long-horizon, multi-file wiring).
- Dominant verdict: MISSED_REQUIREMENT (fan-out branches, branch gains, other
  loops left closed) and REGRESSION (declaring points must not perturb the
  nominal system).

## 3. Public API surface (as delivered)

- `analysis_point(name, size=1) -> StateSpace` — unit-gain block carrying
  `name` on both sides; `interconnect` turns it into a point and, under
  implicit connection, it taps the signal it is named after.
- `interconnect(..., analysis_points=...)` — new keyword; a specification, a
  list of them, or a dict mapping point name to specification. Resolved among
  subsystem outputs first, then subsystem inputs.
- `sys.analysis_point_labels -> list[str]` — point names, declaration order.
- `sys.find_analysis_point(name) -> tuple | None` — ('output' | 'input',
  indices), or None when the name is unknown.
- `open_loop(sys, points=None, name=None)` — the loop-breaking kernel.
- `close_loop(sys, points=None, name=None)` — its inverse.
- `loop_transfer(sys, points=None, openings=None, name=None) -> StateSpace`
- `sensitivity(sys, points=None, openings=None, name=None)` — S = (I - L)^-1.
- `complementary_sensitivity(sys, points=None, openings=None, name=None)`
  — T = I - S.
- `io_transfer(sys, inputs=None, outputs=None, opened=None, name=None)` —
  inputs and outputs may also name subsystem signals, which are exposed as
  extra channels.
- `replace_point(sys, point, value=None, name=None)` — insert a scalar, a
  matrix, or an LTI system; `point` may be a dict for several at once.

## 4. Canonical output form

- Point order: declaration order (`analysis_points` order, then hoisted
  subsystem points in subsystem order).
- Channel order inside a point: the subsystem's own signal order.
- `open_loop` channel placement: nominal inputs first, then one injection
  input per point channel, in point order; likewise for outputs.
- Injection/measurement labels: `f"{point}_inj"` / `f"{point}_meas"` for a
  single-channel point, `f"{point}_inj[j]"` / `f"{point}_meas[j]"` otherwise.
- Contributed point names: subsystem name and point name joined by
  `config.defaults['iosys.state_name_delim']`.
- Sign convention: L is the raw around-the-loop transfer, so closing the loop
  imposes injection = measurement, giving S = (I - L)^-1 and S + T = I.
- Empty `points` (None) means every point of the system, in point order.
- A point whose signal feeds no internal connection yields L = 0.
- Declaring points leaves the nominal A, B, C, D, labels and dt unchanged.

## 5. Blind-spot pre-empts

- Result ordering: "channels appear in the order the points were listed".
- Adjacent-vs-all: "every internal connection fed by that signal is broken"
  (fan-out) versus "connections to the interconnection's own outputs are
  left in place".
- Rule resolution: "each broken connection keeps the gain it had".
- Unstated inverse: "all other loops stay closed".
- Iteration termination: not applicable (no fixpoint).
- Codebase-inferable requirements: 1 (the repo's `sys.sig` signal-spec
  grammar is reused for point specs).

## 6. Description draft

See `meta.md`. Dense prose, no headers, states: what a point is, where it can
be declared, the two declaration routes, what opening does (all branches, with
gains, other loops closed, external outputs untouched), the measurement, the
four transfer queries with their exact algebra, the augmented-channel order and
labels, hoisting of nested points, `replace_point`, and the errors.

## 7. File footprint

| Action | Path | Current LOC | Raw delta | Human-effective | Reason |
| --- | --- | --- | --- | --- | --- |
| NEW | control/loopan.py | — | +730 | 369 | point resolution, the opening kernel, close_loop, the four queries, replace_point, hoisting, the block factory |
| MODIFY | control/nlsys.py | 3026 | +125 | 88 | `analysis_points` keyword, spec parsing, the tap rule, labels, `__str__`, fixpoint bound |
| MODIFY | control/statesp.py | 2578 | +1 | 1 | LinearICSystem carries the points |
| MODIFY | control/__init__.py | — | +1 | 1 | export the new module |

TOTAL: 857 raw / **459 human-effective** across 3 modified + 1 new file
(measured with `.claude/hooks/effective_loc_check.py`).

## 8. Solution outline — helpers (as delivered)

- `InterconnectedSystem._parse_analysis_point_spec(spec)` -> (kind, indices,
  base name) <- "looked up among the subsystem outputs before the inputs"
- `_channels(sys, points)` -> ordered (name, offset, size, kind, index)
  <- "channels appear in the order the points were listed"
- `_undeclared(sys, name)` <- "also accepts a subsystem signal specification"
- `_channel_label(name, offset, size, suffix)` <- the label spelling rule
- `_rebuild(...)` <- builds an interconnection from explicit maps
- `open_loop` <- the kernel: zero the branch entries, add injection columns
  carrying the original gains, add measurement rows reading the signal
- `_hoist_analysis_points(syslist)` <- "a subsystem that carries points
  contributes them too"
- `_insert_block`, `_expose`, `_selection`, `_exposed_label`, `_relabel`,
  `_default_names`, `_resolve_signals`, `_points_of` support the rest.

No fixpoint loop is required. Recursion is one level deep per nesting level
and terminates because hoisting consumes the subsystem's own point list.

## 9. Test file outline

Path: `control/tests/loopan_<hash>_test.py`

Block 1 — imports (numpy, pytest, control as ct).
Block 2 — builder helpers: `simple_loop`, `named_loop`, `fanout_loop`,
`branch_gain_loop`, `two_loop`, `mimo_loop`, `inner_system`, `nested_loop`,
`disturbance_loop`, `output_tap_loop`, `block_loop`.
Block 3 — assertion helpers: `response`, `assert_same`, `assert_values`.
Block 4 — buckets. Delivered: 141 tests in `control/tests/loopan_b55c0a_test.py`, covering
declaration (both routes plus the block), point kind resolution, nominal
preservation, open_loop structure, loop_transfer (fan-out, branch gains, other
loops closed, MIMO, multi-point, discrete, undeclared specs), sensitivity and
its complement, io_transfer (opened loops, subsystem signals), openings,
nesting, close_loop round trips, replace_point (scalar, matrix, LTI, dict) and
the error paths.

5-axis coverage: every described behavior, every public name, every branch of
the kernel, edges (zero branches, single channel, multi-channel, nested,
discrete), and the stated inverse (external outputs unaffected).

## 10. Forced signatures

Python has no trait bounds; the forced contract is the exact signature and
return type of each public name (section 3) plus the label spellings
(section 4). All are stated in `meta.md` so no test can fail on a guess.

## 11. Predicted trap matrix

| # | Trap | Why agents hit it | Pre-empt sentence | Catching test |
| --- | --- | --- | --- | --- |
| 1 | Fan-out: only one branch broken | the map representation makes one row the obvious anchor | "every internal connection fed by that signal is broken" | `fanout_*` |
| 2 | Other loops opened too | "open loop" reads as remove all connections | "all other loops stay closed" | `two_loop_*` |
| 3 | Branch gain dropped on injection | injection is naturally wired with gain 1 | "each broken connection keeps the gain it had" | `gain_branch_*` |
| 4 | External output paths broken as well | the signal looks globally cut | "connections to the interconnection's own outputs stay" | `io_transfer_*` |
| 5 | Measurement wired to the injection | after injecting, the input value is the handy quantity | "the measurement reports the point's own signal" | `loop_transfer_*` |
| 6 | Nested points invisible | nesting needs hoisting, not a special case | "a point inside a subsystem is exposed as `sub.point`" | `nested_*` |
| 7 | Declaring points perturbs the nominal system | extra channels are easiest to add unconditionally | "declaring points leaves the system unchanged" | `test_nominal_*` |
| 8 | Public API without full numpydoc docstrings | the repo's own `docstrings_test.py` enforces it | repo convention (the 1 codebase-inferable requirement) | base suite |
| 9 | An input anchored point breaks one destination, an output anchored point breaks all | one map, two opening rules | "removes only the internal connections feeding that one input" | `test_input_point_*` |

Traps 1 and 2 are opposing (break every branch of this point, keep every other
loop) and are misdirecting: both surface as a wrong transfer function, never as
"you missed a branch".

## 12. Tier + category

- Tier: Olympus
- Sub-rank: Olympus-Good
- Category: feature-request (net-new public API)

## 13. Predicted pass rate

- Predicted: 10-25%. Mutation battery: 16 of 16 deliberate defects killed.
- Reasoning: the kernel is one shared engine feeding six public surfaces, so a
  local fix to one query regresses another; three of the seven traps only fire
  on topologies an agent does not naturally self-test (fan-out, non-unit branch
  gains, two loops); the nominal-preservation requirement opposes the natural
  implementation. Corpus levers stacked: one interdependent kernel (1),
  misdirecting traps (3), obvious-code-is-wrong edges (4), de-training via an
  obscure domain (5), multi-subsystem span (6).

## 14. Quality gate

- [x] Repo understanding: architecture, subsystems, entanglement zones, test
      framework (`pytest` under `control/tests`), template file
      (`control/tests/interconnect_test.py`)
- [x] Existing PR check: `gh pr list -R python-control/python-control --state all
      --search "analysis point" / "loop transfer" / "sensitivity function"` — no hit
- [x] Closest corpus problems opened (pyparsing-parse-enumeration,
      textual-functional-selectors)
- [x] Corpus hardness recipe: shared kernel, exact algebra oracle, 7 traps,
      obvious-code-is-wrong edges, every signature pinned, not a public spec
- [x] Title verb-led, shape declared, API surface complete
- [x] Canonical form spelled out
- [x] <=1 codebase-inferable requirement
- [x] File footprint against real files; LOC in band
- [x] 1+ helper per described behavior
- [x] Test outline, 5-axis coverage
- [x] Traps each with pre-empt and catching test
- [x] Category matches (feature-request)
- [x] Not pattern-followable; not in the used-feature list

## Why this is not a duplicate

Closest corpus entries: `quint-temporal-properties` (a second evaluation mode on
an existing engine, but a temporal-logic checker over traces) and
`smoltcp-icmp-errors-pmtu` (protocol behavior, unrelated mechanism). Nothing in
`Aprroved/`, `problems/` or `rejected/` touches control systems, block-diagram
interconnection, or loop transfer analysis; python-control appears in no local
worktree.

Predicted iteration cycles: 2.
