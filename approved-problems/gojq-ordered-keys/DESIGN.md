# DESIGN — gojq opt-in object key-order preservation

## 1. Title

Keep the key order of objects read from JSON

## 2. Repo / tier / gates

| item | value |
|---|---|
| repo | itchyny/gojq (Go, MIT, 3786 stars, 11.6k non-test LOC) |
| base commit | 2e210b5c28122b106d4cd1fade3ac9dad0482026 (2026-07-20) |
| tier | Olympus |
| prior submissions of ours on this repo | none |

Gate results:

1. **BEHAVIORAL-F2P-GAP** — PASS. gojq decodes objects into `map[string]any`, so key order is
   destroyed at parse time and every output is sorted. Nothing composes it: no filter can recover
   an order the value never carried, and `keys_unsorted` does not exist.
2. **SATURATION** — the semantics are jq's, so KNOWING is free; the difficulty is entirely the
   representation change and its interaction with the backtracking VM.
3. **UNIFORM-WRAP** — PASS. Three separate decisions regress each other: where order lives, how
   the fork stack copies it, and which operations must stay order-blind.
4. **LOC-CEILING** — PASS. There is no ordered value type; 18 `case map[string]any` sites plus the
   decoder, the encoder, comparison, and the object builtins all have to grow a second case.
5. **COLD-NOT-LIVE** — PASS. Three pull requests in the repository's history, none in this area.
6. **REPRODUCE-ON-BASE** — PASS: `echo '{"b":1,"a":2}' | gojq .` prints `{"a":2,"b":1}`.
7. **DEDUP** — no gojq submission of ours in any directory; the feature class (value
   representation + ordering) is not in `problems/`, `rejected/` or `Aprroved/`.
7b. **EXCLUSIVITY** — no PR or issue on the repository about key order.
8. **DEFINED-BEHAVIOR** — jq defines the semantics. The maintainer's README says he would
   implement it once the standard library has an ordered map; this submission makes it opt-in so
   the default and the existing behavior are untouched, which is what that reservation is about.
9. **NO-FLAKY-REPO** — PASS. `go test ./...` green offline in `olympus-base-go` in 1.5s.
10. **REPO-QUOTA** — zero of ours; 3.8k stars but one of several jq engines rather than the
    obvious host for a whole category.

## 3. The gap

`gojq` parses JSON with `encoding/json` into `map[string]any` and sorts keys on output. From the
README: "gojq does not keep the order of object keys ... Due to this limitation, gojq does not
have `keys_unsorted` function and `--sort-keys` (`-S`) option."

## 4. The contract (what the description states)

1. With the option on, an object read from JSON text keeps the key order of the text, and output
   prints keys in that order. Without it nothing changes.
2. Order belongs to the value, not to the stream: it survives every filter the object passes
   through, including into and out of arrays, function arguments and variables.
3. A key created by the program is appended; assigning to a key that already exists keeps its
   position.
4. `a + b` keeps a's order and appends the keys only b has, in b's order; `a * b` merges deeply by
   the same rule.
5. Removing a key leaves the order of the rest alone.
6. `to_entries` yields entries in order, `from_entries` builds in the order it is given.
7. `keys` sorts; `keys_unsorted` gives the object's own order, or the sorted order when it keeps
   none.
7b. The object's order is also the order its members are visited in, so anything which walks it or
   turns it into a stream of paths reaches them in that order.
8. Key order is invisible to everything else: two objects with the same keys and values are the
   same value.
9. `--sort-keys` prints keys sorted whatever order the value carries.

Statements 1-9 are the fairness floor. None of them says where the order is stored, how the
backtracking stack has to copy it, or which of the engine's existing paths mutate objects in
place.

## 5. Why it is hard (trap matrix)

| # | trap | class | why it misdirects |
|---|---|---|---|
| 1 | the VM restores fork points that share value references, so an ordered object whose key slice is appended to in place leaks a key into a rejected alternative | S1 | only shows up under generators and alternatives; simple filters pass |
| 2 | order is observable in output but must be invisible to `==`, `<`, `sort`, `unique`, `group_by`, `contains` | S2 | an order-sensitive comparison breaks base tests far away from the feature |
| 3 | the default representation stays `map[string]any`, so both representations must behave identically everywhere except output | S5 | dual-path: fixing one path leaves the other wrong |
| 4 | every object-producing builtin has to maintain order: `+`, `*`, `del`, `delpaths`, `setpath`, `to_entries`, `from_entries`, `with_entries`, `add`, `getpath`, `tojson` | S4 | the general rule is one sentence; the instances are not enumerated |
| 5 | merge order (left order, new right keys appended) composed with deep merge and with `setpath` on an existing key | S2 | there is exactly one correct composition and several tempting wrong ones |
| 6 | the existing suite is the regression net for the representation change | S3 | failures land in base tests about unrelated builtins |

## 6. F2P surface (the platform-classification risk, handled)

New exported library symbols would make the new test file fail to compile at the base commit,
which the platform reports as a build failure rather than per-test results. The tests therefore
drive the feature through the CLI exactly as `cli/cli_test.go` does: construct the package-private
`cli` struct with in/out/err streams and call `run(args)`. Both exist at the base commit, so the
test file compiles there and every test fails at run time on the unknown flag instead.

## 7. Solution outline (forced ordering)

1. an ordered object type with copy-on-write key handling,
2. ordered JSON and YAML decoding behind the option,
3. the encoder, including `--sort-keys`,
4. the 18 `case map[string]any` sites: compare, type, preview, operator, execute, func,
5. the object builtins and `keys_unsorted`,
6. the flag and its plumbing through the CLI.

## 8. Built

| item | value |
|---|---|
| effective LOC | 555 human-effective, 768 raw, 17 files |
| new tests | 256, all failing at base and passing with the solution |
| oracle | jq 1.7 in the base image; 50-program differential plus 10 fork-point probes |
| mutation proof | 16 mutations, every one killing tests (see `eval-results.md`) |
| review rounds | 1: description trimmed, visiting-order rule added, five coverage suggestions taken. 2: three more coverage suggestions taken. 3: description trimmed to 320 words. 4: YAML output defect found and fixed. 5: library-level host-map coverage. 6: streaming and deep-merge breadth. 7: with_entries renaming and nested auxiliary decoders. 8: solution-quality nits, error assertions loosened, description at 287 words. 9: sorting across arrays and for non-ASCII keys. 10: truncated-input defect found and fixed, colored output. 11: helper bug fixed, library tests through gojq.Marshal. 12: collation assertions made differential. 13: description at 275 words. 14: malformed fromjson and jsonargs, description at 277. 15: description at 240. 16: mixed-representation merges. 17: dropped one unfair mixed-merge test. 18: description at 208 words, doc-comment placement fixed. 19: escaped duplicate keys, cross-run library reuse. 20: batch 1 fixes, name collision and two axes removed. 21: batch 2, one clause added for the object-created-by-assignment case. 22: coupled tests dropped, description at 190 words. 23: nested assignment creation and the stderr paths. 24: -S scoped to results. 25: YAML boundary documented order-agnostically. 26: description at 182 words. 27: orderless fallback generalised. 28: false-positive review, malformed-input and default-leak holes closed. 29: halt_error and partial-output paths. 30: -S made consistent across diagnostics, layouts covered by key sequence. 31: opening scope corrected. 32: second false positive, cross-compile isolation covered. 33: toolchain floor verified. 34: batch 3 at 0 of 4, two solvability sentences. 35: latent builtin-object axis removed. 36: YAML axis removed, two coverage suggestions refused. 37: four description items refused, one on a false premise. 38: builtin-result scope stated |

Two carve-outs, neither claimed by the description: YAML *input* keeps no order (the yaml package in
use carries order only through its node type), and a plain Go map handed to the library API has no
order to keep. YAML *output* does keep it, through a mapping node.

The Dockerfile works around the repository's own `.dockerignore`, which excludes every test file
from an image built from it; see `eval-results.md`.
