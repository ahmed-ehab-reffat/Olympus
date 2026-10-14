# REPO-HUNT-2026-10-06-B (hunter #60, CONSECUTIVE_MISSES=0)

Worker: olympus-hunter (unattended).
Result: **CANDIDATE JFryy/qq: avro and parquet writers infer a typed, nested schema from every record, and the readers return exact values. Written sketch: 350 human-effective over 3 files.**

Scratch: `worktrees/_hunt/s_1006h60/`.
- `qq/` is a clone at base `0c67cdf02ab857913472b53e3e2b7e64308108a5` (main HEAD, 2026-10-02). The sketch is applied as uncommitted edits.
- `sketch_qq_typed-binary-schema_h60.patch` is the sketch diff. It has not been built or run: root disk was 6.5G free, under the 8G build gate.
- The six lane-audit dossiers are `dossier_<repo>_h60.md`. Brief: `AGENT_BRIEF_h60.md`.

## Standing inputs and defaults taken
- The 2026-10-05 user rules were applied as written:
  - lane-only exclusion;
  - a verdict-only dead list, with lane rows expiring after 60 days;
  - Requirement 7 kills only on a failing test workflow in the lane, or when there is no test workflow at all;
  - a ~505 star margin;
  - a 220 written/spiked return bar;
  - the Stage 6 Q3 waiver only above ~300 with an internal wall;
  - the repo submission count is reported, never gated.
- **Not relaxed:** the maintainer-roadmap magnet rule, the AI-sweep, velocity and signature rules, licence, language, activity and exclusivity.
- **Softening:** misses = 0, so no relaxation was taken. The star and issue windows were not widened.
- **Requirement 0 (platform picker):** OWED.
- **Excluded lanes:**
  - pint value ranges (HUNTED), plus its reserved fallbacks rain and dstask;
  - pianoplayer repeat unfolding (SLICING), plus its reserved fallbacks kas and dovi_tool;
  - protobuf-es printer, gonum/plot, commafeed, aptly publish history, ray-optics module inlining (HANDOFF);
  - every CLAIMED row;
  - the dead lanes: teavm fact reuse, pyOCD deferred writes, aerich squash, sqlalchemy-continuum squash.
- **Disk:** `/` had 6.5-6.6G free and a builder was running. No builds, venvs or module downloads. Clones were shallow or blob-less, and every DEAD clone was deleted.

## Fallbacks of the last ~15 logs (read first, per hunter #59's hint)
- **Still reserved** (their primary is still active): kas and dovi_tool (behind pianoplayer, SLICING); rain and dstask (behind pint, HUNTED). Not touched.
- **Lapsed** (protobuf-es was handed over). Both re-judged and not returned:
  - **protobuf-es descriptor validator:** ~250 on paper and a standalone file. Its wall is protoc's linker rules, which an outsider can name, so the Q3 waiver cannot apply below or above 300. bufbuild/protocompile (Go) is a full public implementation of the same checks.
  - **hayro revision history:** #54 sketched ~190 and expected 120-190, which is under the bar.
- Every other fallback in the window is DEAD, WEAK-without-spike, or on the do-not-return list (lebab, purgecss, bazel-remote, ipyflow, devpi, tylax/pokerkit star floor, wfdb, lektor, kuva).

## Stage 0-bis: proven pool
Two-minute check, as #59 advised. Every pool repo still carries a lane or repo verdict under 60 days old (hunts #53-#59). No verdict has expired, so none was re-audited. The proven pool produced nothing.

## Stage 0: cached index, two re-cuts (no fetch)
1. **Low-activity cut:** 3-14 commits in 12 months, the h58 domain vocabulary, and no mention in any markdown.
   - h58 had cut at >= 15 commits, so this slice had never been read.
   - 961 rows, read by eye.
   - Yield: rust-vfs, plus a long tail of finished libraries (tiny-js, fengari, planck.js, java-diff-utils, ifcplusplus, geobuf). None was worth an audit except as a note.
2. **Persisted-format / solo cut:** 15-200 commits, one author with >= 75% of recent commits, format/codec/reader/writer/engine vocabulary, never mentioned. 426 rows.
   - Yield: sprite-dicing, XlsxWriter, durdraw, ofdrw, edisyn, qsim, qq, placemark.
3. **Topic lens over the band** (topics not in `used_topics.txt`, repos never mentioned): 12.5k rows. Domain topics were thin and mostly apps (simulation 41, robotics 63, compiler 28, geospatial 25). This re-read the same rows and added only durdraw and pyRANSAC-3D.

## Fresh sweep 1 (of 2 allowed): newly crossed the 500-star floor
- `gh api search/repositories` for 7 languages x 9 permissive licences, stars 505..700, pushed in the last 12 months (`newband_h60.py`). 5,242 rows fetched.
- **325 were not in any cached band file**: repos that crossed 500 after the 2026-09-14 band fetch.
- About 85% are 2026 AI/agent/LLM repos.
- Domain rows: pcodec/pcodec (★505), pliron-org/pliron (★506), Rhoban/bam, malonge/RagTag, LukasNiessen/ArchUnitPython, fasouto/termaid, QuantClimate/GPJax, CubeCoders/Jet, Themaister/pyrowave, p-ranav/csv2 and alpaca, juxt/allium, J-F-Liu/pom.
- Screened out:
  - GPJax: Claude PR-review agent plus scattershot one-off accounts;
  - ArchUnitPython: Copilot commits and a port of ArchUnit;
  - termaid: Mermaid, a spec magnet;
  - RagTag: 3 commits in 12 months;
  - allium: an LLM harness plugin;
  - Jet: a new maintainer burst on textbook rasteriser features;
  - pyrowave: GPU-only;
  - Rhoban/bam: Requirement 7 (below).

**Fresh sweep 2 was not spent.** The cache already holds the whole 500-6000 band, so a topic or keyword fetch only re-surfaces cached rows. The topic lens above was run offline instead.

## Mechanical kills (repo-scope rows written to judged.tsv)
| Repo | Kill |
|---|---|
| Rhoban/bam (★534) | Req 7. The only workflow, `run_uv.yml`, runs `uv sync` on pushes to a non-existent `master` branch. There are no tests |
| ofdrw/ofdrw (★1880) | Req 7. Only deploy/release workflows, which run `mvn deploy -DskipTests` |
| eclab/edisyn (★721) | Req 7. No `.github/workflows` at all |
| durdraw/durdraw (★1834) | Req 7. Only dependency-graph and pages runs; `test/` is never run |
| jmcnamara/XlsxWriter (★3979) | Two signature accounts (santhreal, binggao1230) in the last 100 PRs |
| django-import-export (★3336) | Two signature accounts (SAY-5, binggao1230) in the 12-month commits |

Lane notes (not repo kills):
- parse: SAY-5 x1;
- remarshal: binggao1230 x1 plus 12 Claude co-author commits;
- pliron: multi-contributor MLIR port with maintainer-authored issues #170/#118/#115/#38 and analyses landing weekly;
- rust-vfs: the stable CI leg has failed on master since 2026-08-06; its overlay lanes are the afero class.

## Lane audits (3 parallel subagents, 6 repos, brief `AGENT_BRIEF_h60.md`)
Our submission count is 0 for all six. The platform submission count is unknown for all six (OWED at the picker).

| Repo | Verdict | Best lane, and what killed it |
|---|---|---|
| **JFryy/qq** (★739, Go) | **VIABLE, RANK 1** | Typed avro/parquet schema, **350 written**. Detail below |
| pcodec/pcodec (★505, Rust) | WEAK | Split a standalone file without re-encoding, **215 written**. The leanest passer is a ~120-150 re-encode with the original ChunkMeta. 155 of the lines are in one new file (Q3 applies under 300). Overturns 09-18-B's repo-level "capability-consuming" verdict: it is a lane verdict, and the repo now has 505 stars |
| elringus/sprite-dicing (★1536, Rust) | DEAD | Secondary layers (open issue #49, a magnet) **108 written**: one `plane()` accessor carries it. Mirror dedup ~80. Incremental re-dice ~140 (`layout.rs` occupy/insert_rect absorbs it). Restore is a standalone file (Q3) |
| quantumlib/qsim (★702, C++) | DEAD | Classical control is maintainer PR #1093 (+1463). Final-state measurements **132 written**, a copy of the existing sample path. MPS lanes are maintainer issues #439/#440/#492. qsimh is being removed (#772) |
| placemark/placemark (★1464, TS) | DEAD | Dissolve is maintainer issue #23. Folder round trip and ordered paste are < 100 and absorbed by `solveRootItems`/`flattenRoot`. The format lanes are outsider-named, with cribs |
| durdraw/durdraw | DEAD (repo) | Req 7 |

## RANK 1: JFryy/qq, typed binary record schema

### Mechanical (2026-10-06)
| Check | Result |
|---|---|
| Repo | JFryy/qq (canonical, no move), ★739, MIT (single LICENSE, no vendored dirs), Go ~90% |
| Activity | Real code commits 2026-10-01/02 (#64, #65, #66, #72). 27 commits/12mo: JFryy 21, Konfekt 1, dependabot 5. No Co-authored-by agent trailers |
| Requirement 7 | "Go Build Make Test" (`go test -v ./...` + `make test`) succeeded on main 2026-10-01 and 2026-10-02 |
| Signature accounts | One: ChrisJr404, PR #61 (auto input detection, open). It is outside the lane, so it is a note. edsilegxrepo (6 PRs, not on the list, real-developer profile) owns the key-order and no-auto-convert lanes through PR #55/#56 |
| Open PRs | #55 key order, #56 no-auto-convert, #57, #61 auto-detect. None touches avro, parquet or schema code |
| Exclusivity | PR/issue search in all states for parquet, avro, schema, arrow, typed, type inference and nested. In-lane hits: none. #72 (merged) sorted parquet column order and fixed JSON-family int precision; #67 is described under Risks. Branches: main only |
| Our submission count | 0 |
| Platform submission count | Unknown, OWED at the picker |
| Toolchain | go 1.25.0. All dependencies are pure Go (arrow/go v16, hamba/avro v2.31.0, gojq, hcl), with no `import "C"`. Docker is Pattern B, `olympus-base-go`, with `go mod download` at build |

### Lane
Today, both binary record writers build their schema from the first record only, and neither keeps types:
- **Parquet writer:** every column is `arrow.BinaryTypes.String`, and values are written with `fmt.Sprintf("%v")` (parquet.go:43, :67). Keys that appear only in later records are dropped. Nested values become Go `map[x:1]` text. A single object errors.
- **Avro writer:** it round-trips through JSON into `[]map[string]any` (avro.go:43-55), so every int becomes float64 and the `long` arm never fires. The schema comes from records[0] (:62), so a null there gives `["null","string"]` and a later number fails to encode. Nested values are stored as JSON-text strings (:94).
- **Readers:** both round-trip through JSON again (avro.go:34-38, parquet.go:163). Parquet struct and list columns fall to `%v` (parquet.go:149).

The lane adds a shared shape-inference kernel over all records:
- null or a missing key makes a field nullable;
- int and float merge to double;
- any other mix becomes JSON text;
- nested objects become records, and arrays become lists merged over all their elements.

It also rewrites both writers and both readers to emit and return exact values: ints, nested records and lists.

### Gate 1 (static; runtime probe OWED, Go build skipped for disk)
1. json to parquet to json of `[{"a":1,"b":true}]` gives `{"a":"1","b":"true"}`.
2. `[{"a":null},{"a":5}]` to avro fails to encode 5.
3. `[{"a":1},{"a":2,"b":"x"}]` through avro drops `b`.
4. `{"o":{"x":1},"l":[1,2]}` through avro returns `"o":"{\"x\":1}"`.
5. `{"n":9007199254740993}` through avro is rounded.

### Written sketch (`sketch_qq_typed-binary-schema_h60.patch`)
Re-measured by the hunter: raw 433, **human-effective 350**, padding-floor 24.

| File | human-eff | What |
|---|---|---|
| codec/util/shape.go (new) | 157 | Records, InferShape/mergeShapes, Conform, numeric conversion |
| codec/avro/avro.go | 100 | schema emission with unique record names and nullable unions, union wrapping, schema-driven unwrap on read |
| codec/parquet/parquet.go | 93 | arrow type mapping, recursive builder append, recursive read |

- **Padding-floor 24.** It comes from the numeric type-switch arms (`toInt64`/`toFloat64`, ~25 lines). Without them the patch is still ~320. The hunter read shape.go: it is real merge and conformance logic, not padding.
- **Second lever (not in the 350).** A binary record format written from a jq program that emits several objects should give one file. Today `cli/qq.go:275-301` marshals each result separately. About +25.

### Traps (interdependent; they share the shape kernel and the two codec pairs)
1. **The writer drops int-ness before inference sees it** (avro.go:43-55, F-9). Adding a `long` rule never fires, and the failing test reads "double". Fixing only the writer still fails read-back, because both readers round-trip through JSON again (F-2).
2. **The hamba map-union convention** (hamba/avro codec_union.go:59-84 and :150-170; a copy is in `hamba_union_qq_h60.go`).
   - In a `["null", record]` field, a `map[string]any` value is taken as a union wrapper. The encoder then fails with "unknown union type <user key>", and the error names a user key instead of the nullability cause. This is misdirecting.
   - Decode mirrors it: nullable nested records come back as `{"Record1": {...}}`, so the reader must unwrap by schema. A real one-key object is not a wrapper.
3. **Merge rules drive conversion and wrapping** (F-10 cell: nullable × nested × list × int/float merge).
   - An int+float merge forces ints to float64 in double columns, and the arrow and hamba builders reject an int there.
   - Null-first and missing keys decide nullability, which decides whether trap 2 applies.
   - Avro record names must be unique, or the schema fails to parse on the second nested record.
4. **Existing tests pin today's behaviour** (F-12). `codec/parquet/parquet_test.go` asserts string values ("1", "true", "95.5") and must be updated in test.patch, with meta stating typed output. `TestAvroRoundTrip` (float64 scores) must keep passing.

### Stage 6 death-class guard
| Question | Answer |
|---|---|
| Q1: one shared kernel feeding several surfaces? | **YES.** InferShape/Conform feed the avro writer, the parquet writer and both readers. A local fix to one cell regresses another: nullable scalars versus nullable nested records under the hamba convention, and int/double merge versus builder type checks |
| Q2: interdependent traps? | **YES.** Trap 1 couples writer and readers. Trap 3's nullability decides trap 2. Fixing a writer alone leaves the read-back failing |
| Q3: standalone file? | **NO.** 193 of the 350 lines rewrite the existing Marshal/Unmarshal paths of two codecs. It is not a post-pass over a public stream. The waiver is not needed (it would hold anyway at 350, but the inference idea is outsider-nameable) |
| Guard 1 (uniform wrap) | No. Inference, conformance, avro emission with union wrapping, and two readers are separate mechanisms |
| Guard 2 (single-subsystem transform) | Borderline. Everything is in the codec layer, but there are at least two hidden integration walls (hamba union convention, the repo's JSON normalisation in writers and readers) beyond the stated merge rules |
| Guard 3 (depends on an unstated rule) | No. Every merge rule can be stated in about 200 words; the walls are in the library and the repo |
| Guard 4 (spec port) | MEDIUM. Schema inference from records is a known idea (pyarrow `from_pylist`, Spark). See the sibling check |
| Guard 5 (survives spelling-out) | YES. Spelling out the merge rules does not reveal the hamba wrapper or the writer/reader JSON round trips |

**Verdict: PASS with risks.**

### Derivative, magnet and sibling checks
- **Siblings:** yq, dasel, gojq and miller have no parquet/avro writer. arrow-go's `arreflect` infers only from static Go types, and only in v18 (qq pins v16). loicalleyne/bodkin (★19, Apache-2.0) infers arrow schemas from maps. It covers part of the parquet half; it is not in qq's module graph and has no avro or read-back part. **MEDIUM risk:** the builder should weight tests on avro and the read path, not on arrow inference.
- **Magnet:** the outsider summary ("infer a typed schema for parquet/avro output in a jq-like converter") is intelligible, so the risk is MEDIUM by nameability. No issue asks for it, and there is no maintainer-authored roadmap issue for it (#67 is described under Risks).
- **Self-collision:** no parquet, avro or schema-inference task exists in approved-problems/, problems/, rejected/ or LEDGER. The jq-like class is dasel's (heavily mined by others), but this is a different repo and a codec-internal capability.

### Risks for the builder
1. **R1: #67, a maintainer cleanup list** (JFryy, 2026-10-02, open), has the bullet "avro converts through float64 internally ... integers above 2^53 lose precision".
   - That is a sub-cell of traps 1 and 4, not the lane. #67 has no schema inference, nested types or parquet typing.
   - Keep the base at `0c67cdf0`, and keep avro int precision a minor cell. If JFryy fixes that bullet before the slice, re-freeze and expect to lose ~15-20 eff.
2. **R2: maintainer codec-fidelity sweep.** On 2026-10-02 the maintainer filed five review issues (#67-#71) and closed three the same day with #72. Parquet's all-string output belongs to the same "silent data loss" class but is not listed.
   - Lane-density risk on a short horizon: slice soon, and re-run the six-check and the commit stream at slice and at submit.
3. **R3:** this changes an existing tested behaviour (parquet string values), so meta must state typed output plainly.
4. **R4:** the bodkin partial crib. Guard 4 is MEDIUM.
5. **Owed at slice:** runtime Gate 1, F2P, 3x determinism (the suite is `go test ./...` plus `make test` shell fixtures, and `tests/test.sh` skips parquet/avro cross-format fixtures), offline Docker with `go mod download`, and the picker.

## Fallbacks
1. **pcodec/pcodec, split without re-encoding** (215 written, WEAK). Only if the human accepts a 210-220 lane with a ~120-150 leanest passer and a Q3 concern (155 lines in one new file). The base is `7ee69462`, and the stars sit exactly at 505.
2. None other. sprite-dicing, qsim and placemark are DEAD at < 200 written or on magnets.

## Verdict rows appended to `worktrees/_hunt/judged.tsv`
17 rows. The backup before the append is `s_1006h60/judged.bak_h60`.
- Repo-scope rows: durdraw, Rhoban/bam, ofdrw, edisyn (Req 7); XlsxWriter, django-import-export (two signature accounts each).
- Lane-scope rows: qq (CANDIDATE, plus the dead lanes), pcodec (WEAK, plus the dead lanes), sprite-dicing, qsim, placemark, pliron, rust-vfs, parse, remarshal.

`sig_accounts.txt` is unchanged. edsilegxrepo and enomado were profiled: both are real-developer profiles, so neither was added.

## What the next hunt should change
1. **The newly-crossed-500 sweep is cheap and it worked.** This hunt's candidate (qq was in the band but never read) and two of the six audited repos came from re-cuts and from the 505-700 fresh band. Re-run `s_1006h60/newband_h60.py` about monthly and diff it against the band files. Most of the yield is AI repos, but 5-10 domain rows appear each time.
2. **Persisted-format, solo-maintainer cuts beat vocabulary cuts.** Of 8 repos screened, 4 died on Req 7 and 2 on signature accounts. Run the workflow check (`gh api .../contents/.github/workflows` plus default-branch runs) before reading source; it is two calls.
3. **The proven pool stays under fresh verdicts until ~2026-11-01.**
