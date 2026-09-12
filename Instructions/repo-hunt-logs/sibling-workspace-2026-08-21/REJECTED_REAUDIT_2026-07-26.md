# Rejected-repository re-audit

Date: 2026-07-26

## Outcome

The rejected and watchlist pool was re-audited from the repository gate
forward. One decision changed materially:
`fede1024/rust-rdkafka` now has a proven focused offline harness and should be
reopened for an exact task audit at **7/10**.

No other hard-gate rejection reversed. Several task rejections had been worded
correctly but are easy to misread as repository rejections. Calyx, pydicom,
ezdxf, OpenTimelineIO, OpenEXR, and several other repositories remain eligible
for a completely different task. Their rejected task identities must not be
rescued by padding, private implementation requirements, incremental API
changes, or invented policy.

### Status correction on 2026-07-27

This dated re-audit has now been executed and is no longer the live ordering.
Railway is an active canonical problem rather than an available candidate.
The reopened rust-rdkafka trial passed its environment gate but failed its
complete task-neighborhood audit. The subsequent fxamacker/cbor screen retained
repository eligibility but found no safe task and lowered it to 6/10. Current
ordering lives in `CANDIDATES.md`; CBOR evidence is in
`CBOR_AUDIT_2026-07-27.md`.

## Method and false-positive lens

The review began with `PROBLEM_DESIGN.md`, `candidates/SEARCH_INSTRUCTIONS.md`,
`candidates/CANDIDATES.md`, `problems/README.md`, and the Calyx and RustPBX
archive records. The Calyx redesign record includes the required
trajectory-informed discriminator ledger; RustPBX produced no solver
trajectories because it failed before problem design.

Current hard-gate facts were checked from GitHub metadata and exact
default-branch checkouts. Reversible environment and harness claims were
retested locally. No problem description, hidden test, reference patch, or
calibration artifact was created or changed.

The scope was the current rejected/watchlist registry plus archived recent
problem outcomes. Accepted repositories and unresolved active problems were
not treated as available merely because they appeared in older search history.

The false-positive rule used throughout was:

- preserve the cheapest legitimate implementation that satisfies public
  behavior;
- do not reject replay, transcripts, helper reuse, or a small implementation
  merely because they bypass a hoped-for private architecture;
- do not turn a small or derivative task into a large one by adding arbitrary
  limits, extra formats, distributed guarantees, or representation rules; and
- treat a different subsystem as a new candidate requiring a fresh upstream
  and archive audit, not as a continuation of the rejected task.

## Reversible hard gates

| Repository | Current evidence | Verdict | Honest reconsideration path |
|---|---|---|---|
| `fede1024/rust-rdkafka` | Pinned `3f54ff1dabe7`; committed `Cargo.lock`; Rust 1.74 minimum. All 18 library tests passed on the host. The same 18/18, including `mocking::tests::test_mockcluster`, passed in `rust:1.85-bookworm` with container networking disabled after a locked dependency warm. `MockCluster` exposes request-error injection, topic errors, leader/follower changes, broker down/up and latency, coordinator changes, and API-version control. | **Reopen at 7/10.** The old harness uncertainty is resolved for a focused task. The 21-file integration suite still mostly requires Kafka/Testcontainers, and no exact recovery task has cleared prior-art review yet. | Freeze this revision. Audit one concrete MockCluster-driven recovery or cleanup behavior. Reject it if the implementation collapses into a generic retry loop, if librdkafka already owns the behavior, or if public history already names it. |
| `CesiumGS/3d-tiles-tools` | Current head `4ca692eb16a9` still has no `package-lock.json`, `npm-shrinkwrap.json`, `pnpm-lock.yaml`, or `yarn.lock`. Root scripts still invoke undeclared `tsx` and `copyfiles`. | **Remain rejected, 3/10.** The platform lock/tool gate still fails before the earlier image timeout is considered. | Upstream must commit the lock and every invoked tool, then pass the pristine official-image/offline preflight. A locally generated lock is not a workaround. |
| `dfrg/swash` | Current head `7773843df0d6` has no test files, no `#[test]`, no `#[cfg(test)]`, and no reviewable font fixtures. | **Remain rejected, 4/10.** | Upstream must gain a real regression suite. Challenge-only tests cannot substitute for the required pre-existing harness. |
| `KolbyML/Manatan` | Current head `0100514fc685` and the preceding releases are documentation refreshes on the sole public branch. The frontend `test` command still prints `imagine`; CI still relies on downloaded application/native artifacts. | **Remain rejected, 4/10.** | Publish the complete implementation history, add a real regression runner, and prove an offline focused lane. Release notes are not a substitute for auditable source. |
| `graphite-project/whisper` | The exact default-branch head remains `94c3a611ecf4` from 2025-06-27. GitHub's newer repository-level `pushed_at` value reflects another ref, not a newer default-branch commit. | **Remain ineligible, 3/10.** | A new default-branch commit is required. The old coordinated-backfill seed must then receive a new audit; a tag/ref push is insufficient. |
| `harfbuzz/rustybuzz` | Exact default-branch head `51d99b83ae78` is dated 2025-06-09. | **Remain ineligible, 3/10.** | Active default-branch development must resume. |
| `webrecorder/warcio` | 462 stars. | **Remain ineligible, 3/10.** | Reach 500 stars, then audit a concrete streaming/archive task. |
| `saferwall/pe` | 394 stars. | **Remain ineligible, 3/10.** | Reach 500 stars; the PE domain remains attractive afterward. |
| `rusticata/x509-parser` | 273 stars; GitHub still reports `NOASSERTION` while the repository describes a dual permissive license. | **Remain ineligible, 3/10.** The star gate fails independently, so license resolution would not change the outcome. | Reach 500 stars and resolve license metadata before task work. |

## Hard policy gates with no current workaround

| Repository | Gate | Re-audit verdict |
|---|---|---|
| `chatmail/core` | MPL-2.0 | Still fails the allowed-permissive-license policy. A smaller task or a permissively licensed subdirectory does not make the core repository eligible. |
| `eval-exec/neomacs` | GPL-3.0-or-later | Still fails the license policy; its GPU/system-library harness is a secondary concern. |
| `miurahr/py7zr` | LGPL-2.1-or-later | Still fails the license policy. |
| `matsadler/magnus` | Meaningful Rust compilation and tests require the unsupported Ruby runtime. | Still fails the runtime policy. Testing only Rust wrappers would omit the behavior that makes the task real. |
| `mcu-tools/mcuboot` | Primary implementation and expected patch are C. | Still fails the supported-language policy. A thin supported-language wrapper would change the repository/task identity. |

These can change only when the platform policy or upstream licensing/runtime
facts change. Spending task-design effort on them now cannot produce an
eligible problem.

## Eligible repositories whose exact task must remain closed

| Repository | Why the task failed | What remains legitimately open |
|---|---|---|
| `calyxir/calyx` | Cycle checkpoints can store inputs plus a progress marker and replay. A one-way provider can be handled by storing its observed transcript, replaying without duplicate live reads, and continuing from the unread suffix. | Calyx is eligible, but checkpoint, restore, replay, rewind, and host-provider variants are closed. A new task must use a different public Cider/compiler boundary and must survive cheapest-history-reconstruction analysis. |
| `restsend/rustpbx` | `SipFlow` already implements the proposed diagnostic substrate. RWI already has action IDs, deduplication, and resume; the remaining race is a generic cache repair. Reload already has preflight, reloaders, and cluster aggregation; atomic cluster rollback would invent distributed policy. | RustPBX is eligible, but SipFlow, RWI dedup/resume, reload, DTMF/media-routing, trunk-registration, call-quality, and loose-routing neighborhoods are poor reuse targets. Only a source-level discovery in a genuinely different subsystem justifies reopening. |
| `pydicom/pydicom` | `FileSet.replace` was sound but its complete honest implementation measured 72 strict effective lines. | A different non-local DICOM operation with an early disposable scope spike. Do not broaden `replace` with unrelated record types or options. |
| `mozman/ezdxf` | Recursive XREF embedding passed its focused probe but measured 138 production lines. | A different CAD-specific operation that crosses real document/resource boundaries. Do not add formats or conflict modes merely to inflate XREF embedding. |
| `nipy/nibabel` | CIFTI subsetting reduces to existing axis-indexing machinery. | A different non-local neuroimaging operation with independent scope evidence. |
| `AcademySoftwareFoundation/OpenTimelineIO` | Arbitrary bundle deduplication cannot faithfully represent `ImageSequenceReference`, and the bundle implementation was newly merged. | A task outside bundle naming, collision handling, and image-sequence repackaging. |
| `AcademySoftwareFoundation/openexr` | Chunk-table repair composes public reconstruction and raw chunk-copy seams and sits beside explicit recovery issues. | A task outside reconstruction, repair, raw-copy, and metadata-rewrite seams. |
| `abema/go-mp4` | The per-sample classic/fragmented index overlapped an existing cross-repository archive task. Extra boxes, a CLI, or a different API would be incremental. | A materially different MP4 operation, not sample location/index/offset/DTS/PTS work. |
| `asdf-format/asdf` | Portable subtree/deep-copy behavior is adjacent to live issue #2103 and existing external-reference work. | A different ASDF subsystem after a fresh all-state audit. |
| `haraldk/TwelveMonkeys` | DDS arrays/cubemaps are the conspicuous next increment of the recent DX10 contribution. | An unrelated mature image plugin with no source TODO, issue, PR, or recent contribution advertising the gap. |
| `onekey-sec/unblob` | Recursive extraction limits directly implement public zip-bomb issue #210. | A task absent from public security guidance and the extraction-budget neighborhood. |
| `AcademySoftwareFoundation/MaterialX` | Transactional document import/upgrade repeated the workspace's failure-atomic publication shape. | A MaterialX-specific invariant with a different solver architecture. Archiving 3D Tiles lowers but does not erase similarity to the remaining transaction tasks. |
| `cantools/cantools` | Protected-container routing mostly composes E2E/SecOC helpers and relies on manufacturer-specific freshness policy. | A portable operation with a repository-owned public oracle and no vendor policy. |
| `yeslogic/allsorts` | The interesting subset gaps are enumerated in public issues. | A non-enumerated task in another font subsystem. |
| `facebookincubator/nimble` | Indexed pagination overlaps `NimbleIndexProjector`; the build is expensive. | A different storage operation with a clean oracle and a focused offline lane. |
| `georust/geo` | Polygonization failed archive similarity after an earlier line-merge design in the same graph-reconstruction neighborhood. | The repository remains eligible, but another named geometry/graph operation would carry severe local similarity risk. Only a materially different, non-textbook subsystem should be reconsidered. |

## Previously rejected but deliberately reopened

| Repository | Current status |
|---|---|
| `mdeloof/statig` | The local/external-transition seed was initially rejected for named statechart/archive convergence, then deliberately selected by the user with that risk preserved and accepted on 2026-07-26. Acceptance is recorded in `SUCCESSES.md`; it does not make another statechart task safe. |
| `algesten/str0m` | The remote-offer rollback seed was initially rejected at 151 production lines, then deliberately selected as a size exception. The immutable package later solved 10/10 legitimately through the same one-file preflight architecture and was archived on 2026-07-27. Raw runs and worktree recovery are under `archive/str0m-remote-renegotiation/`; do not harden or broaden it. |

## Saturation and fallback decisions

| Repository | Verdict |
|---|---|
| `veryl-lang/veryl` | Eligible and still a 7/10 watchlist repo, but not a missed ready task. Fast upstream movement, public source-map work, and Calyx-neighborhood similarity make the current seeds unsafe. |
| `genomoncology/biomcp` | Technically eligible but still rejected for agent-ticket saturation and incomplete visibility into the active work rail. A non-MCP subsystem discovered independently could reverse this, but no such seed exists. |
| `tsz-org/tsz` | Technically eligible but still rejected for extreme agent/parity saturation, heavy checker resources, and an unlocked JavaScript lane. |
| `fxamacker/cbor` | Refreshed at `f6a8c43d12cc` with a passing official-image offline suite, but no task survived. Path search has a ready public fork, streaming is maintainer-owned, and the remaining public seeds are generic codec/specification work. Retain only at 6/10 for a materially different source-level discovery. |
| `RoaringBitmap/roaring` | Remains a 6/10 fallback; only a non-textbook correctness seam can justify promotion. |

## Historical reopen order

This order is superseded as of 2026-07-27: Railway became the active problem,
rust-rdkafka failed its task audit, and CBOR failed to produce a selectable
task. It remains below as the record of the sequence that was actually
followed.

The 2026-07-26 ordering was:

1. `fede1024/rust-rdkafka` — the only gate reversal; begin with an exact
   MockCluster-driven task and full upstream/archive search.
2. `fxamacker/cbor` — already eligible, but require a repository-specific task
   outside canonicalization.
3. `pydicom/pydicom` or `mozman/ezdxf` — excellent harnesses and rare domains,
   but only for completely new operations with an early honest scope spike.
4. `calyxir/calyx` or `AcademySoftwareFoundation/OpenTimelineIO` — strong
   repositories, higher task-identity and similarity risk.
5. OpenEXR, TwelveMonkeys, unblob, ASDF, MaterialX, cantools, allsorts, nibabel,
   Nimble, and go-mp4 — eligible research pool, but each needs a new subsystem
   and has a more expensive or narrower path to a safe task.

The bottom line is not that the old pool was empty. It contained eligible
repositories whose first task failed. The only prior repository-level decision
that should change now is rust-rdkafka's harness status.
