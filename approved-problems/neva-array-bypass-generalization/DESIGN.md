# DESIGN — neva-array-bypass-generalization

## 1. Title

Generalize array-bypass connections across port directions and fan-out

## 2. Repo / base

- Repo: https://github.com/nevalang/neva (1076 stars, MIT, commit 2026-07-26)
- BASE_COMMIT: 939996ba4611ca6798026852cdb3b617a8bce84f
- Language: Go. Docker: Pattern B (`olympus-base-go`).
- Gates: repo cold in target subsystem (irgen/network.go last logic change pre-2026-04; analyzer/network.go bypass code untouched by the 2026-07 union work), zero prior subs in any of our dirs, no open PR touching array-bypass, issue #579 confirms the limitation family is real and unfixed (its comments contain no solution).

## 3. Shape

**O-Composite-add** — a new capability spanning analyzer -> desugarer -> irgen -> runtime wiring.
Target pass rate 10-20% (max 4/10 Nova, aiming 1-2). Best agent per SHAPES.md: Vega.

## 4. The gap (reproduced on base)

Array-bypass (`[*]`) today only works in ONE direction and ONE form: own-inport -> child-inport, 1 sender to 1 receiver.

| Form | Base behavior (verified with the built CLI) |
|---|---|
| `:data[*] -> child[*]` | works |
| `child[*] -> :res[*]` | **compiles, then panics at runtime**: `panic: fan_out: port 'data' is not array` |
| `a[*] -> b[*]` (node to node) | **compiles, then panics at runtime**, same message |
| `:data[*] -> [a[*], b[*]]` | rejected: `Array-bypass requires [*] on both sides of a single connection` |
| `[a[*], b[*]] -> c[*]` | rejected, same message |

Root cause: `irgen.processArrayBypassConnection` hardcodes the sender as the component's own inport (`nodeCtx.portsUsage.in`) and the receiver path as `<node>/in`, so any other direction emits connections for ports that were never registered in the receiving func's IO. The analyzer's `arrayBypassPorts` gate hardcodes 1 sender / 1 receiver.

This is the PICK-FILTER pass profile: a bug-flavored correctness gap in cold code, where base produces observably wrong output and the symptom misdirects (a panic naming an unrelated runtime func's port).

## 5. Feature contract (what meta.md must state)

1. A bypass links every used slot of the sender array port to the same-numbered slot of the receiver array port.
2. It works regardless of which side is the component's own port: own-inport to child-inport, child-outport to own-outport, and child to child.
3. Fan-out: `a[*] -> [b[*], c[*]]` delivers slot i to slot i of every receiver.
4. Fan-in: `[a[*], b[*]] -> c[*]` merges slot i of every sender into slot i of the receiver.
5. Slot count is anchored to the component's own array port as the parent used it. A bypass with no anchor is a compile error.
6. A non-array port on either side is a compile error naming the offending side.
7. Zero used slots produces no connections and no error.

De-enumerated per Rule 7: state the principle (2 covers every direction), never the case list.

## 6. Trap matrix

| # | Class | Trap | Misdirecting symptom |
|---|---|---|---|
| T1 | S6 two-evaluators | Analyzer gate and irgen expansion are separate paths. Fixing only the analyzer produces a program that compiles and panics inside an unrelated runtime func. | `panic: fan_in: port 'data' is not array` — points at the stdlib func, not at slot registration |
| T2 | S3 baseline preservation | Slot usage must be registered in `nodesPortsUsage` for the child node in the correct direction (in vs out). Registering the wrong side leaves the func IO short and the runtime panics elsewhere. | existing `array_inport_holes` / `order_dependend_with_arr_inport` e2e break |
| T3 | S4 machinery-riding | Fan-out/fan-in over bypass cannot reuse the desugarer's FanOut/FanIn node insertion, because slot counts are unknown until irgen. One synthetic func per slot is required. | wrong-arity IO or a single shared FanOut for all slots -> messages interleave across slots |
| T4 | A9 exact-fit / P3 shadow | Anchoring must propagate through a node-to-node bypass whose only anchor is another bypass. Agents test the anchored 2-slot case their impl already handles. | unanchored chain silently emits zero connections -> program hangs or drops messages |
| T5 | A8 polarity | Sender-side and receiver-side counts come from opposite usage maps (`in` vs `out`). The natural single-helper implementation reads one map for both. | count 0 for the outport direction -> no connections emitted, no error |

Every trap's CONTRACT is stated in meta (direction-agnostic principle, fan-in/fan-out, anchoring error, zero-slot rule) while the FIX (which usage map, where to register slots, per-slot synthetic funcs) stays a discovery.

## 7. File footprint (target)

| File | Change | eff LOC |
|---|---|---|
| internal/compiler/irgen/network.go | general slot resolution + per-direction emit + per-slot fan-out/fan-in funcs | ~200 |
| internal/compiler/analyzer/network.go | accept multi-sender/receiver bypass, per-side validation, anchoring check | ~130 |
| internal/compiler/desugarer/network.go | keep bypass connections out of normal fan-in/fan-out desugaring | ~40 |
| pkg/ast/flowast.go | bypass helpers | ~20 |
| Total | | ~390 |

## 8. Tests

- irgen unit tests on the produced IR (deterministic, no goroutines).
- analyzer unit tests for the new errors.
- e2e golden programs (exact stdout) for each direction and for fan-in/fan-out.
- base mode: full `go test ./internal/... ./pkg/...` plus the array-port e2e cases.
