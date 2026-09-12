# Website-flagged issues — geo/Polygonize submission

Reviewed: 2026-07-18. Source: `problems.md` (platform review output).
Ordered by severity. **The plagiarism/similarity flag is the most important and
dangerous** — it can invalidate the whole submission regardless of the other fixes.

| # | Check | Status | Severity | Blocking? |
|---|-------|--------|----------|-----------|
| 1 | Similarity vs existing submissions (plagiarism) | WARNING | **CRITICAL** | Yes (idea-level) |
| 2 | Description valid UTF-8 / ASCII-only | **FAILED** | High | Yes |
| 3 | Tests cover required behavior | **FAILED** | High | Yes |
| 4 | Test file names collide with defaults | **FAILED** | High | Yes |
| 5 | Description looks AI-generated (em-dashes) | WARNING | Medium | Soft |
| 6 | Description only-necessary-info | WARNING | Medium (1 HIGH item) | Soft-blocking |
| 7 | Problem/tests alignment (crate-root re-export) | WARNING | Low | Soft |
| 8 | Test runner JUnit path mismatch | WARNING | Low | Soft |
| 9 | Dockerfile: tool version not pinned | WARNING | Low | Soft |
| 10 | Dockerfile: build whole workspace | WARNING | Low | Soft |

---

## 1. Plagiarism / similarity — CRITICAL
> "Your submission shares the same idea and structural approach as an existing
> submission." (runs only when the prior plagiarism step found candidates)

The task (Polygonize — build polygons from lines) duplicates the idea + structural
approach of an existing Olympus submission. Verifying the target repo had no PR/issue
was **not sufficient**: the similarity check compares against the whole submission
archive. Textbook geometry algorithms are heavily represented there.

**Fix:** change the *idea*, not the wording. Pick a less-obvious task in a
less-saturated repo/domain. Rewording or restructuring the same behavior will not
clear an idea+structure similarity flag.

## 2. Description must be ASCII — FAILED
Non-ASCII `—` (U+2014, em-dash) at byte position ~426. **Fix:** replace all
em-dashes with ASCII (`,` `.` or `-`); ensure the whole description is ASCII.

## 3. Tests miss required interface coverage — FAILED
Spec requires `Polygonize` for `LineString`, `Line`, `MultiLineString`,
`GeometryCollection`, `Geometry`, but tests only call `polygonize()` on
`MultiLineString` and `GeometryCollection`. A solution could omit the `LineString`,
`Line`, and `Geometry` impls and still pass. **Fix:** add direct tests:
(a) `LineString` forming a closed ring -> 1 polygon; (b) single `Line` -> reported
as a dangle, no polygons; (c) `Geometry::MultiLineString` / `Geometry::GeometryCollection`
-> expected polygons. Optional: nested `GeometryCollection` for recursion depth.

## 4. Predictable test file name — FAILED
`geo/tests/polygonize.rs` collides with the implementer's likely path. **Fix:**
rename with a random hash, e.g. `geo/tests/polygonize_<hex6>.rs`
(`openssl rand -hex 3`), and update `test.sh` to run `--test polygonize_<hex6>`.
Do NOT use `shipd`/`datacurve`, or any quest words.

## 5. AI-formatting heuristic (em-dashes) — WARNING
4 em-dash connectives (2.6/200 words) read as an AI tell. Resolved by fix #2 (drop
em-dashes) plus generally natural wording.

## 6. Description carries unnecessary info — WARNING (1 HIGH)
- [HIGH] Delete the parenthetical listing where lines are collected from
  ("including those held in a MultiLineString ... recursing through nested
  collections") — redundant with "every Line and LineString" + the impl list.
- [MED] Remove the "square + diagonal -> two triangles" example.
- [MED] Remove "Every input line ends up either ... in dangles, or in cut_edges."
- [LOW] Remove "removing such a line may expose further lines that then also dangle."
- [LOW] Trim "(points, polygons, and so on)".

## 7. Crate-root re-export not stated — WARNING
Tests import `geo::Polygonize`; the description doesn't state the trait must be
re-exported at the crate root. **Fix:** state that `Polygonize` is available at
`geo::Polygonize` (public re-export).

## 8. JUnit path mismatch — WARNING
Reviewer flagged `.config/nextest.toml` (`path = "junit.xml"`) vs `test.sh` copying
`target/nextest/default/junit.xml`. In practice nextest writes the relative path
under `target/nextest/<profile>/`, so these align and the local run copied real XML
— but make it robust: copy from the exact configured location or read the path back,
so a real run never emits the fallback failure XML.

## 9. Dockerfile: pin tool version — WARNING
`cargo install cargo-nextest --locked` is unpinned. **Fix:**
`cargo install cargo-nextest --version <X.Y.Z> --locked`.

## 10. Dockerfile: build whole workspace — WARNING
`cargo build -p geo --tests` caches only one crate. **Fix:** `cargo build --workspace`
(or `--all`) to warm every workspace crate for the offline run.

---

### Priority order to act
1. **#1 plagiarism** — decide whether to re-target the task; nothing else matters if this stands.
2. #2, #3, #4 — hard FAILs; must fix before resubmit.
3. #6 (HIGH item), #7 — blocking-ish; fix.
4. #5, #8, #9, #10 — warnings; fix to be clean.
