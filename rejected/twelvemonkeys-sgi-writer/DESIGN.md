# Design — TwelveMonkeys SGI writer

Status: **closed — rejected for plagiarism/similarity on 2026-08-01**

Base commit: `41aaf3b1bc7fe8144b3bbd16c62d13a559feb7c5`

## Trajectory-informed startup gate

The gate was completed before the candidate prototype and rechecked before promotion. Searches covered `problems/README.md`, candidate indexes, `problems/`, `candidates/`, and `archive/` for TwelveMonkeys, SGI, ImageIO writers, missing reader/writer pairs, planar binary images, RLE, source selection, and binary table formats.

No SGI solver trajectory exists. Relevant compact records inspected were the rejected TwelveMonkeys DDS source-selection candidate, Gimli debug-names rejection records, and the Calamine and PcapPlusPlus design/run records. Representative raw evidence was inspected from the Calamine archive (one 77-step complete pass and one 85-step broad near-pass) and the PcapPlusPlus archive (a 10/11 near-pass with baseline success). These showed that shared format plumbing can collapse apparent breadth, while byte-level layout and framing boundaries can remain independent observable discriminators.

The candidate's complete implementation confirmed that SGI does not collapse like DDS. Its independent production mechanisms include provider/type negotiation, ImageIO source geometry, a fixed binary header, planar row orientation, RLE packet grammar at two atom widths, seek-back row tables, and a narrow reader interoperability repair.

## Discriminator ledger

| Plausible shortcut | Public invariant | Black-box oracle | Distinct boundary | Anti-overfit basis |
|---|---|---|---|---|
| Interleaved or top-down output | SGI stores bottom-up channel planes | Parse asymmetric raw payload samples | Physical raster layout | Permits streaming or buffered implementations |
| RGB/8-bit only | Gray, Gray+Alpha, RGB, and RGBA support unsigned 8/16-bit samples | Round-trip every channel/width mode and inspect header width | Type negotiation | Uses ordinary public ImageIO types |
| Nominal header with wrong selected geometry | Header describes the selected image | Parse header fields independently | Header semantics | Does not depend on the repository reader |
| Byte RLE for 16-bit rows | Atom width follows sample width | Independently parse two-byte controls and samples | Codec grammar | Supported by existing fixtures/spec evidence |
| Payload without valid row tables | Every channel-row has an absolute offset and exact length | Bounds-check and independently decode all table entries | File-level indexing | Allows any internal buffering strategy |
| Repeat-only or unbounded packets | Literal/repeat packets split at 127 and terminate rows | Mixed long literal/repeat source row | Packet segmentation | One asymmetric row covers semantic boundaries |
| Ignore ImageWriteParam offsets/bands | Standard selection precedes SGI encoding | Translated raster with unequal periods, offsets, and reordered bands | ImageIO coordinate arithmetic | Observes selected samples only |
| Concrete writer without SPI wiring | ImageIO discovers the writer normally | Registry lookup plus inherited writer contract | Provider integration | Public plugin behavior |
| Round-trip against matching bug | Bytes must be valid independently | Hand parser plus separate platform decoder evidence | Oracle independence | Prevents writer/reader agreement from hiding defects |

## Immutable verification

- Base commit: `41aaf3b1bc7fe8144b3bbd16c62d13a559feb7c5`
- `test.patch` SHA-256: `9a58a7298f94fca1fcba7c3a6690e170c4770e5a2429699fa2d8852290e342ad`
- `solution.patch` SHA-256: `cd3a619fe0bf21a39e9e44f4e8d7125f11dcbbb7e2caf5c6eba9a8a217c26fb4`
- Test patch applies cleanly at the base commit.
- Base lane on test-only tree: 91 tests, 0 failures, 2 skips.
- New lane on test-only tree: fails during compilation because writer behavior is absent.
- Base lane with solution: 91 tests, 0 failures, 2 skips.
- New lane with solution: 24 tests, 0 failures, 0 skips.
- `git diff --check`: clean.
- Docker preflight: the image builds on the pinned Maven 3.9.11/JDK 25 base; the build executes the existing SGI lane to cache Surefire's dynamically selected JUnit Platform provider. With `--network none`, the solved image passes the 91-test base lane and 24-test new lane.

## False-positive audit

Every participant-facing requirement maps to its strongest current behavioral check:

| Requirement | Strongest check |
|---|---|
| Discoverable SGI writer and valid ImageIO contract | Provider-discovery check plus inherited `ImageWriterAbstractTest` cases |
| 1–4 channels at 8/16 bits | All-channel/sample-width round trips and provider capability checks |
| Header and uncompressed planar bottom-up bytes | Independent header and exact payload parser |
| RLE tables and packet boundaries | Absolute offset/length inspection and independent decoder over a 300-sample mixed row |
| Two-byte 16-bit RLE atoms and interoperability | Atom high-byte assertion, independent decode, and repository-reader round trip |
| Region, subsampling offsets, band order, and raster input | Translated raster with asymmetric periods, nonzero offsets, and reordered bands |
| No reader regression | Complete 91-test pre-existing SGI lane |

Plausible incorrect modes were derived from the existing byte-oriented reader, conventional top-down raster traversal, the prior DDS selector convergence, and common inverse-codec shortcuts. Three isolated compiling mutants were replayed against the exact test patch:

| Mutant | Focused result | Disposition |
|---|---|---|
| Remove bottom-up row inversion | 4 writer assertions failed, including exact payload and round trips | Killed; distinct layout family |
| Emit one-byte controls for 16-bit RLE | atom-width assertion failed and a mode round trip errored | Killed; distinct codec-width family |
| Ignore subsampling offsets while retaining periods | translated selection payload failed | Killed; distinct coordinate family |

Additional reviewed shortcut modes—uncompressed-only writing, missing service registration, fixed RGB band order, guessed RLE table entries, and writer/reader round-trip agreement without valid bytes—are directly covered by separate current checks. None compiled and passed the focused suite, so there was no survivor to carry into the complete pre-existing lane. No artificial symmetry permutation or private implementation predicate was added. The correct implementation passed the full base lane after each mutation family was isolated in disposable worktrees.

The attempted mutation set has zero survivors. This is evidence for those plausible modes, not a claim that false positives are impossible. No test change resulted from the audit because every actionable mode already had a distinct public-behavior discriminator.

The Docker-only correction made during preflight changed no prompt, test, or reference behavior. The immutable patch hashes, requirement map, three isolated mutation outcomes, and host base/new results remain identical; the audit was rechecked after the correction and no new behavioral survivor or probe was introduced.

## Closure

The external plagiarism/similarity gate rejected this problem after promotion. No solver calibration was run. This outcome supersedes the earlier 7/10 candidate and promoted statuses despite the successful implementation, test, mutation, and offline-container checks.

The exact matching source or evaluator comparison was not provided in the closure instruction, so this record does not speculate about which prior task triggered the result. Treat the verdict as terminal for this task shape: do not attempt to evade it through prose changes, extra SGI modes, additional fixtures, or a neighboring reader/writer inversion.
