# Submission — `Polygonize` for `georust/geo`

**Status: complete and locally verified.** All four gate states pass.

## Target
- Repo: `https://github.com/georust/geo` (Rust, MIT/Apache-2.0, 1,895★, active)
- Production language: Rust
- Task type: feature request
- Base commit: `771d1bf8d4cd8ad9b27b589b8a485d0aac2e5cba`
- Feature: a `Polygonize` trait that builds polygons from a geometry's lines
  (the JTS `Polygonizer` operation) — reported missing, no PR.

## Artifacts (in this folder)
| File | What |
|------|------|
| `meta.md` | Problem description (the text the solver sees) |
| `test.patch` | `test.sh` + `.config/nextest.toml` + `geo/tests/polygonize.rs` |
| `solution.patch` | `algorithm/polygonize/{mod,graph,assemble}.rs` + registration |
| `Dockerfile` | `olympus-base-rust`, installs nextest, warms build offline |

## Verification (from pristine base `771d1bf8`)
| State | Result |
|-------|--------|
| test.patch only → `./test.sh base` | **PASS** (1113 passed, 2 skipped) |
| test.patch only → `./test.sh new` | **FAIL** (exit 101, `unresolved import geo::Polygonize`) |
| + solution.patch → `./test.sh new` | **PASS** (9/9) |
| + solution.patch → `./test.sh base` | **PASS** (1113 passed) |

Both patches `git apply --check` cleanly. `cargo clippy` clean. Leak scan clean.

## Discriminators (from the prompt bank)
1. **Engine-authoritative evaluation** — polygons come from a real planar-graph
   engine (tight-turn face tracing, bridge/dangle removal, shell/hole nesting).
   Naive shortcuts fail: wrapping only already-closed rings misses regions formed
   by combined edges (square+diagonal → 2 triangles); ignoring nesting mishandles
   the hole case; ignoring dangles/bridges pollutes the output.
2. **Pipeline re-entry** — lines nested in `GeometryCollection`/`Geometry` are
   collected recursively; a flat-`MultiLineString`-only reading misses them.

## Effective LOC (honest count)
- Strict (no comments/blanks/lone-braces): **277**
- SLOC (no comments/blanks, incl. braces): **359**
- Raw added lines (solution.patch): **458**

This lands **near** the 400 target on SLOC and above it on raw diff, but the
strict count is ~277. If a hard ≥400 *strict* is required, the clean way to cross
it is to make the trait **generic over the coordinate type** (`T: GeoFloat`),
which is the idiomatic geo pattern and adds ~40–60 genuine lines — say the word.

## Notes
- `geo-polygonize/` supersedes the earlier `geo-line-merge/` design (LineMerge was
  verified-clean but only ~110 LOC; Polygonize was chosen for complexity + LOC).
- Determinism: exact-f64 node identity, integer fixtures, results asserted via
  polygon counts/areas/hole-counts (order & winding never pinned).
