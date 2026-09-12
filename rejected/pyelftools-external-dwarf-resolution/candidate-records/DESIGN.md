# DESIGN - pyelftools-external-dwarf-resolution

Status: `rejected for overlap and archived on 2026-08-20;
calibration 0/10`.

Repository: `eliben/pyelftools` at
`e5fa2a4f3e665d082cfc453fd0877f5516200926` (2026-07-30).

Production language: Python.

Task type: enhancement.

## Solvability forecast

- Start of this design iteration: **2-4 successful solvers out of 10**, a
  fresh-calibration expectation inside the current accepted 1-5/10 band. This
  is based on the existing resolver seam, counterbalanced by three independent
  boundaries: search policy, per-hop identity validation, and nested relative
  resolution.
- End of this design iteration: **2-4/10**, still a fresh-calibration
  expectation, not an observed replay. The source audit removed the suspected
  lazy-stream lifetime problem because DWARF sections are copied into
  `BytesIO`, but confirmed that build-ID lookup and per-hop loader rebasing are
  separate missing behaviors. No solver run exists for this version.

## Public contract and repository evidence

Enhance `ELFFile.load_from_path()` and linked-DWARF retrieval into a complete,
repository-native external-debug resolver:

1. Preserve the current `.gnu_debuglink` behavior and CRC validation, while
   searching the documented same-directory, `.debug/`, and explicitly supplied
   debug-root locations instead of only one literal sibling path.
2. When the primary file has a GNU build ID and no usable in-file DWARF, allow
   explicitly supplied debug roots to resolve the conventional
   `.build-id/xx/yyyy.debug` path. Verify that the selected file has the same
   build ID before using it.
3. Resolve `.debug_sup` and `.gnu_debugaltlink` relative to the file containing
   that link, including a stripped primary -> external main debug file ->
   supplementary debug file chain. Do not inherit the original primary file's
   directory for every hop.
4. Preserve `follow_links=False` as a strict no-resolution mode. Missing
   candidates, identity mismatches, and cycles must fail deterministically and
   must not silently select unrelated DWARF.
5. Keep the custom `stream_loader` extension point viable. The task specifies
   observable candidate identity and per-hop resolution, not a particular
   resolver class, cache, ownership model, or filesystem layout beyond the
   public search roots.

Repository evidence is unusually direct. `get_dwarf_info()` already separates
`.gnu_debuglink` from supplementary DWARF, validates the debuglink CRC, and
contains `TODO: support linking by build ID`. Its own comment says that passing
the primary `stream_loader` to the external file is wrong when the next link is
relative to that external file. `DWARFInfo.parse_debugsupinfo()` already parses
the standard and GNU supplementary-link forms. The merged upstream PR #596
explicitly states that build-ID linking is not supported; it owns the current
baseline, not this completion of its remaining search and chaining behavior.

The cheapest credible implementation is a resolver context carried per opened
ELF, with candidate generation and identity checks shared by the three link
forms. Estimate: **220-380 production lines across 2-4 files**, low confidence.
Materializing each external file into memory is also legitimate if it preserves
all public behavior; tests must not prescribe retained file descriptors.

## Trajectory-informed design gate

Searches performed: `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, all candidate/problem/archive references for ELF,
DWARF, debug links, archive symbol indexes, binary resource resolution, and the
exact repository URL. Relevant compact records read were the archived h5py VDS
copy summary/design, Mido MIDI-range design/summary, Vineflower switch
design/summary, Object AIX summary, Statig summary, and accepted Tablesaw
summary/design. No pyelftools trajectory exists.

Representative raw evidence inspected:

| Evidence role | Problem / run | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | PcapPlusPlus filtered-copy Nova 1 and Nova 6 | 14/14 focused plus baseline | Two materially different implementations handled section-local state and producer modes; successful architecture must remain unconstrained. |
| Near-pass | h5py VDS relocation Nova 6 | 22/24 focused plus baseline | A broad implementation missed same-file identity and a distinct attribute family, showing why resource identity needs its own oracle. |
| Broad failure | PcapPlusPlus filtered-copy Nova 10 | 9/14 focused plus baseline | A 533-line implementation applied old-section boundaries to new sections and rejected legal option families; chained resources need per-hop state rather than one global base. |

The two PcapPlusPlus passing patches used roughly 406 and 532 production
additions; the broad failure used 533. The h5py near-pass used roughly 182
additions. These figures reject fixture count and reference LOC as standalone
difficulty evidence.

## Discriminator ledger

| Observed solver behavior | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Anti-overfit rationale |
|---|---|---|---|---|---|
| Near-pass missed same-file identity | Accept the first name match without proving resource identity | CRC/build ID must match the requesting ELF metadata | Put an earlier wrong candidate and a later valid candidate in the search path | identity validation | Any resolver architecture can enumerate, reject, and continue. |
| Broad failure reused an old section boundary | Resolve every nested reference relative to the root resource | Each relative link is based at the ELF that contains it | Primary -> debuglink file in a subdirectory -> supplementary sibling | chained resource context | Tests only final DIE/string resolution, not loader representation. |
| Broad failure rejected legal producer modes | Implement only literal sibling `.gnu_debuglink` | All advertised link/search modes have defined behavior | Exercise sibling, `.debug/`, explicit root, and build-ID candidates | producer/search family | Each mode corresponds to documented GNU behavior or an explicit API root. |
| Passing solvers used different architectures | Require a private resolver/cache structure | Custom loaders and filesystem loading remain behaviorally equivalent | Replay both loader-backed and path-backed chains | extension boundary | No class names, cache contents, or call counts are asserted. |
| Repository comment identifies recursion risk | Follow chains without visited identity | Cycles terminate deterministically | Two supplementary files that link back to one another | termination/cycle | Cycle detection may use paths, build IDs, or object identity. |

## Clause-to-test coverage

| Public requirement | Planned observable test | Base behavior | Reference behavior | Fairness evidence |
|---|---|---|---|---|
| Standard debuglink search | Valid DWARF exists only in `.debug/` and then an explicit root | fails to open | resolves expected CU/DIE | GNU separate-debug-file convention and current debuglink API |
| Build-ID resolution | Stripped primary plus matching build-ID debug file | no support | resolves only matching file | source TODO and PR #596 limitation |
| Per-hop relative base | External main debug file links to its own sibling supplement | resolves from wrong directory | resolves imported unit/string | source comment in `get_dwarf_info()` |
| Identity validation | Wrong earlier candidate and valid later candidate | aborts or misselects | rejects wrong identity and selects valid candidate | current CRC behavior and ELF build-ID note |
| No-follow and cycles | Disable links; separately provide a cyclic supplement graph | may recurse or open | no resolution / deterministic error | existing `follow_links` contract and stable termination semantics |
| Custom loader compatibility | In-memory loader supplies the same logical chain | only one-hop callback works | complete chain resolves | documented `stream_loader` extension point |

## Environment and harness preflight

- Eligibility observed 2026-08-20: public GitHub repository, 2.3k stars,
  public-domain license, active in the last year, pure Python.
- Existing harness: 55 top-level unit-test modules plus readelf comparison and
  example suites. Repository command: `make test`; focused commands can use
  `python test/run_all_unittests.py`.
- Fixtures can be generated during image construction with `gcc`, `objcopy`,
  and `dwz`, then committed to the immutable evaluator so runtime is offline.
- The untouched arbitrary-UID Docker gate has not been run. No mutation,
  fairness, gap, false-positive, or solver work is authorized by this record.

## Ownership and similarity audit

Dated 2026-08-20 searches covered build ID, debuglink, separate debug files,
supplementary DWARF, loader rebasing, checksums, and all issue/PR states visible
through GitHub search plus reachable history. PR #596 and issue #594 implement
and explain the present debuglink/supplement distinction. They explicitly leave
build-ID linking unsupported. No issue or PR was found implementing debug-root
search, per-hop rebasing, identity-aware nested chains, or cycle handling.

Local similarity risk is moderate: Object AIX exercised archive indexes and
PcapPlusPlus exercised a binary section graph. This candidate differs by
external resource discovery and identity-validated recursive resolution; tests
must not drift into general ELF parsing or archive indexing.

## Escalation correction

The preliminary ownership query missed open issue #186. That issue names the
exact conventional `.build-id/xx/yyyy.debug` use case and asks pyelftools to
correlate a stripped ELF with separate DWARF; the maintainer marked it
unsupported and invited a pull request. PR #596 implemented sibling
`.gnu_debuglink` behavior but explicitly excluded build-ID linking and did not
close #186.

This directly owns the candidate's central build-ID/debug-root requirement.
Removing it leaves per-hop loader rebasing and cycle bookkeeping concentrated
in one resolver module, forecast 7-10/10 and outside the accepted band. The
canonical escalation record is archived in `../problem-records/`.

## Design verdict

**Reject, 4/10 current; 9/10 preliminary.** No environment gate, prototype,
prompt, hidden tests, reference, Dockerfile, solver run, or calibration batch
was started. Do not cosmetically rescope the same work as build-ID discovery,
external debug roots, or separate-DWARF correlation.
