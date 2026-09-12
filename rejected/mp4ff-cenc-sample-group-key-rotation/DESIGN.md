# Design - mp4ff CENC sample-group key rotation

Status: `rejected at the upstream-ownership gate on 2026-08-15;
calibration 0/10`.

Repository: `Eyevinn/mp4ff` at
`745651cf1e4bd8d7bcb7f8f78fd66e26389ef05b`.

Primary language and license: Go / MIT.

Task type under evaluation: feature request.

## Candidate public contract

The proposed task would extend the existing KID-aware fragment decryption API
to honor fragment-local Common Encryption `seig` sample groups. It would expand
the `sbgp` run-length mapping over every fragment sample, resolve the referenced
`sgpd` entries, use each selected entry's KID and encryption parameters, and
retain the track-level `tenc` defaults for group zero. Invalid references,
mapping/sample-count mismatches, and missing required keys would fail before
in-place sample data was partly changed.

The repository makes this behavior technically coherent:

- `SbgpBox` preserves every `(sampleCount, groupDescriptionIndex)` run;
- `SgpdBox` decodes multiple `SeigSampleGroupEntry` values, including KID, IV,
  constant-IV, and pattern fields;
- `TrafBox.ParseReadSenc` currently rejects more than one `sbgp` entry and only
  accepts fragment-local description `65537`;
- `Fragment.GetFullSamples` already produces the sample order across all
  `trun` boxes; and
- `DecryptFragmentWithKeys` selects one `tenc.DefaultKID` key and one `TencBox`
  parameter set before decrypting the whole fragment in place.

Array expansion, streaming run iteration, a prevalidated sample plan, and a
transactional scratch copy would all be legitimate implementation choices. No
test or public contract may prescribe one of them.

## Trajectory-informed design gate

The local search covered `problems/README.md`, `candidates/CANDIDATES.md`,
`candidates/SUCCESSES.md`, the dated candidate reports, and `problems/`,
`candidates/`, `archive/`, and `Work/` for `mp4ff`, ISO BMFF, CENC, `seig`,
`sbgp`, `sgpd`, sample groups, KIDs, key rotation, fragmented media, per-sample
state, and in-place validation. No prior mp4ff problem or solver trajectory
exists.

The closest compact records read were:

- `metadata-extractor-cmov/{DESIGN,SUMMARY,LEVELS,ERRORS,RUNS}.md`, which shows
  multiple legitimate media-parser architectures and single-boundary
  near-passes after successful recursive decoding;
- `pcapplusplus-pcapng-filtered-copy/{DESIGN,SUMMARY,LEVELS,RUNS}.md`, where
  section state, filter timing, and nested option framing produced genuinely
  different failure families;
- `openexr-multipart-image-io/{DESIGN,SUMMARY}.md`, where four part-class
  families and independent ownership/header paths supported substantive
  implementations; and
- `candidates/aircompressor-lz4-linked-blocks/DESIGN.md`, whose many fixtures
  collapsed to one history-lower-bound seam and caused a pre-authoring
  rejection.

Representative raw records were inspected directly. The saved trajectory JSON
for the metadata-extractor runs contains only the outer harness messages, so
the evaluator result, solution patch, run record, and logs were used together
as architecture evidence. The PcapPlusPlus archive manifest and exact members
were inspected through a temporary extraction.

| Evidence role | Problem / raw record | Outcome | Solver architecture and decisive behavior |
|---|---|---|---|
| Legitimate pass | metadata-extractor `agent-runs3/Nova_Nova_3/{trajectory.json,eval-result.json,solution-patch.patch,run.txt,test-log.txt}` | 314/314 base and 32/32 focused | A shared decoder was integrated at the reader boundary, with authoritative child/container bounds and reader-owned error routing. It added 316 strict production lines across seven files and propagated header accounting into the later metadata leaf. |
| Near-pass | metadata-extractor `agent-runs3/Nova_Nova_1/{trajectory.json,eval-result.json,solution-patch.patch,run.txt,test-log.txt}` | 314/314 base and 31/32 focused | A separate handler-leaf design implemented the main decompression, framing, and recovery contract in 339 strict production lines but failed to propagate extended-header accounting into one QuickTime `ftyp` consumer. This supports testing cross-owner parameter propagation rather than a preferred helper layout. |
| Broad failure | metadata-extractor solver run unavailable | No Level 3 solver failed broadly; pristine skipped the feature | The missing category is recorded as unavailable. Pristine is useful only as the fail-to-pass control, not as solver architecture evidence. |
| Legitimate pass | PcapPlusPlus archive `agent-runs4/Nova_Nova_6/{trajectory.json,eval-result.json,solution-patch.patch,run.txt}` | L5 14/14 and later L6 replay 16/16 | The implementation coordinated section-local state and temporary publication, but parsed retained EPB options only after the filter decision. |
| Near-pass | PcapPlusPlus archive `agent-runs4/Nova_Nova_1/{trajectory.json,eval-result.json,solution-patch.patch,run.txt}` | L5 14/14 and later L6 replay 15/16 | Its complete scanner validated packet options eagerly. The main operation worked, but one semantic timing choice rejected malformed bytes belonging only to a discarded packet. |
| Broad failure | PcapPlusPlus archive `agent-runs4/Nova_Nova_10/{trajectory.json,eval-result.json,solution-patch.patch,run.txt}` | 69/69 base, L5 9/14 and L6 replay 11/16 | Over-strict section-boundary handling and a separate Decryption Secrets option-layout mistake caused independent valid-input failures. Several fixtures shared one branch and therefore did not count as several discriminators. |

The applicable lesson is that a viable media-format task needs independently
owned mapping, parameter-resolution, parsing, key-selection, and mutation-timing
decisions. More `sbgp` run shapes alone would be coverage of one loop. The
repository initially appeared to offer the required separate decisions, but
the upstream audit below terminates the seed before tests or a prototype.

## Retired discriminator ledger

These entries were evaluated before the ownership result. They explain why the
task was technically coherent; they are not authorization to create hidden
tests for this rejected seed.

| Repository or trajectory evidence | Generalized shortcut | Fair public invariant | Black-box oracle | Boundary / failure family | Status and anti-overfit rationale |
|---|---|---|---|---|---|
| `ParseReadSenc` reads only the first `sbgp` run. | Apply one group to the whole fragment. | Every run covers its declared number of consecutive fragment samples. | Decrypt distinguishable samples spanning two or more runs and compare complete output. | Sample-to-group expansion | Retired by ownership; an iterator or expanded plan could both pass. |
| `SgpdBox` already decodes several fragment-local descriptions. | Resolve only entry one or treat the encoded index as a slice index. | Every nonzero mapping resolves its referenced fragment-local `seig` entry. | Use two entries with different KIDs and reverse their mapping order. | Group-index resolution | Retired by ownership; observes decoded output and deterministic errors only. |
| Current key lookup reads only `tenc.DefaultKID`. | Select one key per track or fragment. | A mapped `seig` KID selects the key for each covered sample. | Provide distinct keys and plaintext markers for adjacent mapped samples. | Per-sample key selection | This is the exact public follow-up named by the maintainer and cannot be used. |
| `SencBox` currently stores one IV size and `decryptSamplesInPlace` passes one `TencBox`. | Rotate keys while retaining one global IV/constant-IV/pattern configuration. | Each sample uses the selected entry's complete public encryption parameters. | Mix repository-supported IV and pattern modes across mapped samples. | Auxiliary-record parsing and cipher parameters | Retired; would permit preplanning, streaming parsing, or equivalent reparse designs. |
| `sbgp` group zero is not a description reference. | Reject zero or reuse the preceding override. | Group zero falls back to the track-level `tenc` defaults. | Place zero between two override runs and compare all plaintext. | Override/default state transition | Retired; one transition oracle is enough, not many zero-position permutations. |
| `GetFullSamples` flattens all fragment `trun` boxes. | Restart the group mapping at each `trun`. | The `sbgp` run domain is the fragment's sample sequence. | Let one run cross a `trun` boundary. | Fragment sample enumeration | Retired; tests a repository-owned boundary, not an internal collection shape. |
| Decryption mutates sample buffers in place. | Discover a late bad reference or missing key after earlier samples changed. | Structural/key validation fails without partial in-place decryption. | Snapshot sample bytes, put the defect in a late run, call the public API, and compare all bytes. | Validation/commit timing | Retired; scratch output, a complete plan, or rollback could all pass. |
| Legacy callers and single-key tests already pass. | Require sample groups or KID maps for every encrypted fragment. | Existing single-key and single-entry behavior remains compatible. | Replay current repository encryption/decryption tests and a group-free fragment. | Backward compatibility | Retired as ordinary regression coverage, not a new difficulty family. |

## Upstream ownership and provenance gate

The preliminary candidate query was too narrow: searching the combined phrase
`key rotation seig` returned no exact issue or pull request, but it missed the
discussion on the merged change that created the relevant API.

Merged [PR #490](https://github.com/Eyevinn/mp4ff/pull/490),
`feat: enhance key handling to support kid:key pairs and improve decryption
logic`, added `DecryptSegmentWithKeys`, `DecryptFragmentWithKeys`, the KID map,
strict missing-key behavior, and the command-line `kid:key` surface. Its author
states that large parts were produced with AI assistance. During merge review,
the maintainer explicitly wrote that the implementation reads a KID from
`tenc`, not when it is overridden by a `seig` sample-group entry, and "may need
to be enhanced later."

Merged [PR #495](https://github.com/Eyevinn/mp4ff/pull/495) and release
[PR #502](https://github.com/Eyevinn/mp4ff/pull/502) then published the same
limitation: `seig` sample-group overrides are not yet supported. Adjacent
[PR #494](https://github.com/Eyevinn/mp4ff/pull/494) implemented the exact
authoritative parsing priority `seig` then `tenc` then heuristic for SENC IV
size. The pin also contains `CLAUDE.md`, and recent sample-group PRs #509,
#510, and #515 disclose Claude-generated code. The decisive concern is local,
not a claim that the whole repository is unusable: the proposed task is the
named continuation of a recent AI-assisted API change.

There is still no open issue titled "key rotation" and no completed rotation
implementation on the default branch. That absence does not restore novelty.
A solver can recover the central requirement, owning API, selection order, and
intended follow-up directly from the merged PR discussion and changelog.
`UPSTREAM_AUDIT.md` records the exact searches and links.

## Environment and implementation status

The exact pin was cloned and inspected, but the task failed the earlier
ownership gate. The mandatory environment gate was therefore not started: no
Dockerfile was authored, no Phase A or Phase B verdict was claimed, and no
prototype, mutation, gap, fairness, false-positive, solver, or calibration run
was performed. This follows the repository practice of stopping before costly
execution once an exact public owner caps a seed.

## Design verdict

Reject this task at **4/10 current; 8/10 preliminary** for an exact public,
AI-assisted follow-up. The proposed behavior is coherent and likely
substantive, but the API it extends was introduced by AI-assisted PR #490 and
the maintainer explicitly identified `seig` KID overrides as its later
enhancement. The changelog makes the same missing behavior searchable.

No `meta.md`, `test.patch`, `solution.patch`, `solution_approach.md`,
Dockerfile, hidden test, reference patch, or calibration batch was created.
Do not cosmetically rescope the same work as multiple `sbgp` runs, per-sample
KIDs, or CENC key rotation. Reconsider mp4ff only through a materially different
subsystem and behavior after a fresh ownership and trajectory gate.
