# False-positive audit - verified Railway deployment plans

Status: repeated on 2026-07-29 for canonical version 33. The prompt now states
that the globally sorted `"."` root record need not be first. The repaired
version-32 proxy, reference, and all behavioral assertions are unchanged.
Version 33 is at calibration 0/10. Earlier calibration and audits are retained
below as historical evidence only.

## Canonical version 33 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base tree | `1b864ae1475cd7b8dc7dabe5a337ddf615bc3e32` (upstream commit `4d49d9845a27a0947ab903b01789eb9f854414d8`) |
| `meta.md` | `6674edbce3495a8d3dfba725ba769b0fa8a633cc94054f55bee2b4049799f8cd` |
| `test.patch` | `850fa6491c50eb0e021a03340108eaf250706c323f5c1af3f4a8ca6580617851` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux reference image | arm64 `sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f` |

Version 33 changes one explanatory sentence in the public schema contract.
The sentence resolves the interaction between global UTF-8 ordering and the
archive-root marker without revealing the punctuation fixture or prescribing
root lookup. It was justified by eight independent version-32 trajectories:
all eight sorted globally and then treated the first record as the root; six
otherwise passed 23/24 focused tests. The hidden suite, reference, wrapper,
dependencies, and network fixture are byte-identical.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | `deployment_plan_write_is_offline_deterministic_and_self_excluding` writes twice, compares bytes, and observes a synchronized local proxy without opt-out variables. |
| Ordinary selection and source-root resolution | Controller parity covers ignore rules, links, modes, prefixes, and path-as-root; the CLI root entity covers linked, explicit-project-with-environment, token, environment-variable, nested, and positional-path modes. |
| Strict deterministic schema and global path order | Serializer and raw-reader entities cover exact fields, versions, sorted uniqueness, record metadata, digest rules, Unix modes, and punctuation that sorts before `"."`. |
| Root marker and safe path grammar | Prefix/path-as-root planning requires the selected root record independent of position; raw-reader fixtures cover absolute, leading-parent, embedded-parent, and non-UTF-8 archive paths. |
| Unsupported selected inputs return an error | Broken-link controller coverage and a directly selected Unix socket through the public command require failure without diagnostic or syscall constraints. |
| Stored controls, selection, metadata, and contents reconcile locally | Controller tests isolate `pathAsRoot`, `noGitignore`, added/removed/renamed paths, type, size, mode, and same-size content. |
| Reconciliation precedes authentication and every request | Public malformed, content, root, and option mismatch entities require local failure while the synchronized proxy remains untouched. |
| Successful apply uses the verified bytes | The valid-apply proxy changes the source after local reconciliation, captures `/up`, decodes the gzip tar, and requires the earlier verified bytes. |
| Plan flags conflict | Public parsing requires failure and zero requests, without one exit code or message format. |
| Compatibility API exists | Grader compilation imports only the documented controller module, four functions, and public plan types. |

### Plausible incorrect modes and fairness isolation

| Mode | Evidence | Exact result | Decision |
|---|---|---|---|
| Sort globally, then assume `entries[0]` is the selected root. | All four Nova and four Orion version-32 patches independently use this shortcut. | Every run preserves 474/474 baseline and fails the punctuation/root-order entity; four Orion runs are otherwise 23/24. | Actionable and already killed by one public source-selection/order boundary. The prompt now clarifies the invariant; no new fixture was added. |
| Verify locally, discard the returned archive, and rebuild through ordinary upload after remote resolution. | The existing uploader makes this the cheapest command-wiring shortcut. | Fresh network-disabled Linux replay: 474/474 baseline and 23/24 focused, failing only `deployment_plan_valid_apply_continues_after_local_verification`; uploaded bytes are `changed\n` rather than `content\n`. | Actionable false positive remains isolated by one command-boundary oracle. |
| Use `pread`, `mmap`, or another descriptor reader, or conservatively reject pathname replacement. | Prior fairness analysis showed that libc-`read(2)` synchronization excluded valid implementations. | No current test waits for a private syscall or requires replacement success. | Legitimate alternatives remain accepted. |
| Add apply-only permutations for broken links, unsupported objects, or non-UTF-8 names. | The eight reviewed patches share one source collector between write and apply, and existing apply type/path-set tests already cross that boundary. | No survivor supports a distinct new discriminator. | Rejected as duplicate fixtures rather than added adversarial predicates. |

The version-32 candidate JUnit files are an exact replay for the unchanged
grader and reference: each has 474 clean baseline cases, and every focused run
fails the same root-position boundary. Changing prose cannot alter those
binaries, so recompiling the identical patches would add no execution
evidence. The passing reference and the discard-and-rebuild mutant were
executed afresh for version 33.

### Exact validation

| Probe | Result |
|---|---:|
| Reference, network-disabled Linux `base` | 474/474 pass; zero failures/errors/skips |
| Reference, network-disabled Linux `new` | 24/24 pass; zero failures/errors/skips |
| Cargo fallback with nextest hidden | 24/24 pass; zero failures/errors/skips |
| Test patch without solution | exits 101; one JUnit failure, zero errors/skips, with unresolved `controllers::deploy_plan` diagnostics |
| Discard-and-rebuild mutant | 474/474 baseline; 23/24 focused, failing only the captured-upload-byte entity |
| Test then solution / solution then test | both apply, pass `git diff --check`, and reverse to the same clean base tree |
| Version-32 Nova/Orion evidence | all eight preserve 474/474; all eight fail root-position independence; four Orion runs are 23/24 |

The audit considered repository-natural branch seams, reviewed solver
shortcuts, boundary asymmetries, and independent I/O modes. No actionable
survivor remains in this bounded mutation set. This is evidence for the
attempted modes, not proof that false positives are impossible. Because the
prompt hash changed, every version-32 calibration result is historical and
version 33 starts at 0/10.

## Canonical version 31 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f` |
| `test.patch` | `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c` |
| `solution.patch` | `52cfd1502465ef484db613a95d0d41430a7a28da4ade565bac40d45108e7ac14` |
| `solution_approach.md` | `cd54d38e8ce2f6c5256de0a595e90940d35124a7115601ee8a857761f84b14bc` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

An external solution-verification pass accepted all 474 regressions and all 24
visible Linux focused entities, but synthesized additional
snapshot/atomic-replacement failures because the reference did not compare the
post-read pathname with the opened object. Version 31 hardens only the
reference: on Unix, device and inode identity must match before open, on the
descriptor, and on the followed pathname after reading. The portable fallback
rechecks the metadata fields available to the existing implementation.

The external synthesis does not justify restoring the four removed
libc-`read(2)` barriers. The public contract still permits descriptor
retention, `pread`, `mmap`, and safe rejection, and the version-30 tests remain
unchanged. Stable followed links continue to resolve to the same target
identity.

### Requirement and discriminator decision

The complete version-30 requirement-to-oracle map remains authoritative
because neither participant-facing text nor grader behavior changed. The only
new code is a conservative reference check. A temporary deterministic
reference-only probe verified that a same-size atomic replacement has a
different Unix identity while a stable followed symlink has the same identity.
That probe is not shipped and exposes no participant-facing implementation
seam.

### Exact validation and mutation isolation

| Probe | Result |
|---|---:|
| Hardened reference, macOS `base` | 474/474 pass; zero skipped |
| Hardened reference, macOS `new` | 23/23 pass |
| Cargo-test fallback with nextest hidden | 23/23 pass; generated JUnit has zero failures/errors/skips |
| Test patch without solution | exits 101; one diagnostic JUnit failure, zero errors/skips |
| Remove only the new pathname-identity check | 23/23 focused pass |
| Discard the verified body and rebuild through ordinary upload | 474/474 baseline; 22/23 focused, failing only the captured-upload-byte entity |
| Same-size replacement / stable followed-link helper probe | replacement differs; stable followed link matches |
| Test then solution / solution then test | both apply, pass whitespace checks, and reverse to a clean tree |
| Canonical solution regeneration | generated production diff SHA-256 exactly matches `solution.patch` |

The identity-free variant is deliberately accepted: it proves that version 31
does not turn the reference's conservative strategy into a hidden requirement.
The discard-and-rebuild shortcut remains the strongest actionable survivor and
is still isolated by one public black-box oracle after passing the full
pre-existing suite. No actionable survivor remains in the bounded version-31
set.

Docker Desktop did not answer its local socket during the version-31 recheck,
so a new Linux container lane was not claimed. Version 30's byte-identical
prompt and tests passed 24/24 in the network-disabled Linux image, and the new
Unix identity branch compiled and passed on macOS. The exact external verifier
feedback independently reports 474/474 baseline and all 24 visible Linux tests
passing before its synthesized solution analysis. Any artifact change
invalidates this record; version-31 calibration starts at 0/10.

## Canonical version 30 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `5ef4f164004f3856a96fe3737f4141c3b801963236016090bdc52dff0489fa3f` |
| `test.patch` | `5e898074a9f73e23e60105290fc211d848c6e386e6483fdd9a53ef8a69b1fb7c` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux reference base image used with exact source binds | arm64 `sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f` |

Version 30 changes the participant-facing snapshot contract and the grader as
one fairness correction. The description no longer requires detection of
size, mode, or modification-metadata changes at an undisclosed instant during
an in-progress read. The four entities that could reach their mutation only
through a C `LD_PRELOAD` hook for the libc `read` symbol are removed together
with the complete compiler/interposer/child-process harness. No test is marked
ignored. Linux now has 16 controller plus 8 CLI entities; macOS has 15 plus 8
because non-UTF-8 archive names remain Linux-only.

The reference retains stronger descriptor stability checks. Those checks are
permitted but are no longer required by hidden timing machinery. The public
verified-byte requirement remains independently enforced at the command
boundary: a local TLS fixture changes a source after local reconciliation,
captures the real `/up` request, decodes its gzip tar body, and requires the
pre-change verified bytes.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-30 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and zero auxiliary requests | The public write entity invokes planning twice without opt-out variables, compares exact plan bytes, and observes a synchronized proxy snapshot. |
| Ordinary source selection and local-root resolution | Controller parity covers ignore rules, links, modes, prefixes, and path-as-root; public CLI coverage exercises linked, explicit-project-with-environment, project-token, environment-variable, nested, and positional-path roots. |
| Strict deterministic JSON and root-marker/path grammar | Serializer plus raw reader fixtures cover exact fields, versions, globally sorted unique paths including punctuation before `"."`, relative paths, embedded parent components, kinds, sizes, digests, and Unix modes. |
| Selected inputs are supported regular files/directories | Broken-link controller coverage and a directly selected Unix socket through the public CLI require an error without constraining diagnostics or the open/read API. |
| Stored controls, selection, metadata, and content reconcile locally | Controller entities isolate `pathAsRoot`, `noGitignore`, added/removed/renamed paths, type, size, mode, and same-size content; public CLI mismatch cases require zero requests. |
| Reconciliation precedes authentication and remote activity | Malformed, content-mismatched, root-mismatched, and option-mismatched public apply fixtures observe the synchronized proxy and require local failure. |
| A valid apply resumes ordinary remote flow | The valid apply and positional-root entities require post-verification network continuation without pinning an exact request count. |
| Uploaded bytes are the verified bytes | The valid apply capture changes `app.txt` after verification and requires the actual uploaded tar entry to retain the verified old bytes. |
| Plan flags conflict | Public parsing requires unsuccessful invocations and zero requests, without one exit code or diagnostic wording. |
| Compatibility API exists | Grader compilation imports only the four documented functions and documented public plan types. |

### Plausible incorrect modes, legitimate alternatives, and isolation

| Implementation mode | Repository or trajectory basis | Exact version-30 result | Decision |
|---|---|---|---|
| Verify through `create_deploy_tarball_from_plan`, discard its bytes, and rebuild through ordinary upload after remote resolution. | Ordinary `up` already has a path-based archive builder, making this the cheapest command-wiring shortcut. | 474/474 baseline; 22/23 macOS focused. Only `deployment_plan_valid_apply_continues_after_local_verification` fails because the captured upload contains the post-verification bytes. | Actionable false positive remains killed by one distinct public oracle. |
| Remove all modification-time and Unix-mode stability comparisons around the content read while retaining opened-regular and byte-count checks. | This behavior is now allowed by the narrowed public contract. | 474/474 baseline and 23/23 macOS focused. | Legitimate alternative; intentionally accepted. |
| Read the descriptor with Unix `FileExt::read_at`/`pread` rather than `Read::read_to_end`/libc `read`. | Independent valid I/O mode identified by the fairness adjudication. | 23/23 macOS focused; no barrier timeout or private-symbol assertion exists. | Legitimate alternative; intentionally accepted. |
| Exact `agent-runs7/Nova_Nova_3` participant patch. | Representative raw solver trajectory using its own controller and command structure. | 474/474 baseline and 23/23 macOS focused; its 11 task-owned self-tests remain outside the regression filter. | Legitimate participant replay passes. |
| Omit strict reader validation, path-as-root positional forwarding, `noGitignore` forwarding, punctuation-before-root ordering, or target-specific source-root branches. | Prior isolated mutants and run-5 through run-8 trajectories. | Their unchanged dedicated version-29 oracles remain in version 30. | Still actionable; no discriminator was removed from these families. |

The attempted `pread` mode is not itself a required implementation. It is a
fairness probe demonstrating that the revised suite evaluates public outcomes
without waiting for one private symbol. Enumerating more intercepted syscalls,
adding a production-only test hook, using a probabilistic large-file writer,
or requiring privileged FUSE/ptrace coordination were rejected as
implementation-shaped or flaky.

### Exact validation

| Probe | Result |
|---|---:|
| Reference, macOS `base` | 474/474 pass; zero skipped testcases |
| Reference, macOS `new` | 23/23 pass |
| Reference, network-disabled Linux `new` with exact grader source | 24/24 pass |
| Cargo-test fallback with nextest hidden | 23/23 macOS tests pass; generated JUnit contains 23 cases, zero failures/errors/skips |
| Test patch without solution | exits 101; JUnit reports one failure, zero errors/skips, and preserves the unresolved `controllers::deploy_plan` diagnostic |
| Exact Nova 3 replay | 474/474 baseline and 23/23 focused pass |
| No-stability-check legitimate variant | 474/474 baseline and 23/23 focused pass |
| `pread` legitimate variant | 23/23 focused pass |
| Discard-and-rebuild mutant | 474/474 baseline; 22/23 focused, failing only the captured-upload-byte entity |
| Test then solution / solution then test | both apply, pass whitespace checks, reverse cleanly, and leave zero changed paths |
| Wrapper syntax and exact patch reproduction | pass; regenerated test diff hash equals the recorded `test.patch` hash |

The Linux base behavior and nextest path are unchanged from the exact
version-29 474/474 network-disabled run; the exact changed grader source was
nevertheless compiled and executed in the 24/24 Linux focused run. The
submission still assumes the Olympus Rust base image's existing `python3` and
`openssl` executables for the public upload-capture fixture. Both were present
and exercised successfully; no C compiler, `LD_PRELOAD`, `/proc` polling, or
large race payload remains.

No actionable survivor remains in the attempted version-30 mutation set. This
is bounded evidence for the reviewed modes, not proof against every possible
false positive. Any artifact change invalidates this record. Version-30
calibration begins at 0/10; no earlier result carries forward.

## Canonical version 29 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715` |
| `test.patch` | `d48876ff5cb1c73bec776eab3fb15e7f1adccc2941fb5a71288f7b7c6b6b23d4` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:84cff552b256bfff4cbc24ea529edf8e34a8468a8487d1f998a948e0251a092f` |

Version 29 changes two arguments in one existing process fixture. The
explicit-project write invocation now supplies the environment selector
ordinary `up` requires. Its assertions still require the current-directory
archive paths, exclude linked-parent paths, observe zero write requests, reach
the request boundary after unchanged apply reconciliation, and reject changed
inputs before any request.

### Fairness and false-positive decision

The removed expectation was not a useful discriminator: an implementation
that preserves ordinary selector validation was correct under the public
contract yet failed the fixture. Supplying the environment removes that false
negative without enabling a plausible wrong source-root implementation. A
solver that ignores explicit-project current-directory resolution still emits
the linked-parent path set or fails local reconciliation and is caught by the
same entity.

The complete version-28 requirement map remains applicable because no public
requirement or other oracle changed. Exact replay retains the blocked-manifest
assembly boundary and the discard-and-rebuild verified-body mutant. No new
mutant is justified by this fairness-only correction.

### Exact validation

| Probe | Result |
|---|---:|
| Network-disabled Linux reference `base` | 474/474 pass |
| Network-disabled Linux reference `new` | 28/28 pass |
| Isolated macOS reference `base` / `new` | 474/474 and 23/23 pass |
| Linux cargo-test fallback with nextest hidden | 20 controller plus 8 CLI tests pass |
| Test-only `new` | exits 101; fallback JUnit reports one failure with unresolved-controller diagnostics |
| Nova 6 manifest-overlap replay | 474 baseline pass; 25/28 focused, with the same three real defects |
| Discard-and-rebuild mutant | 474/474 baseline; 27/28 focused, failing only verified upload bytes |
| Both patch orders, reverse, whitespace, wrapper syntax | pass |

Any artifact change creates a new immutable version. Version-29 calibration
starts at 0/10; no result from version 28 carries forward.

## Canonical version 28 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715` |
| `test.patch` | `eaf6275a57d92f0dc2beec6ae24100d43645a3f8fd1ac191deafde32fb2c0e47` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:2cf635768bb6cecda709bae108d7f095cacae388fa1b345a39eb1111f18e834e` |

Version 28 changes only grader selection and assembly. It removes the
`deployment-plan-tests` Cargo feature and supplies the checked
`deployment_plan_tests` cfg from `test.sh` in the focused lane. The public
description, reference implementation, 28 Linux / 23 macOS behavioral census,
test names, and assertions are unchanged.

### Assembly and classification probes

| Probe | Exact result |
|---|---|
| Reference, network-disabled Linux `base` | 474/474 pass |
| Reference, network-disabled Linux `new` | 28/28 pass |
| Reference, macOS `base` / `new` | 474/474 and 23/23 pass |
| Cargo fallback with nextest hidden | 20 controller plus 8 CLI tests pass |
| Test patch without solution | exits 101 before discovery; fallback JUnit reports one failure and retains unresolved-module diagnostics |
| Test then solution / solution then test | both apply and pass whitespace checks |
| Reverse patch orders | both return cleanly to the pinned base |
| Nova 6 manifest-overlap replay | locked/offline metadata succeeds; 25/28 real feature tests pass |
| Discard-and-rebuild mutant | reaches 27/28 and is killed only by the verified public upload-body oracle |
| Representative Nova 3 replay | preserves the baseline and reaches 27/28; fails the later upload-body integration boundary, not assembly |

### Requirement map and mutation decision

The complete version-27 requirement-to-oracle map remains authoritative
because no participant-facing behavior changed. The exact-version audit
replayed the one assembly survivor and the strongest upload-boundary mutant.
Nova 6 proves that a plausible participant manifest edit now survives grader
assembly while its three independent public defects remain visible.
The discard-and-rebuild mutant proves that changing test selection did not
weaken the verified-byte discriminator.

The proposed opened-object type-race probe was rejected. All six run-8
implementations and the reference inspect metadata from the opened descriptor
and reject a non-regular object. No reviewed shortcut survives on this
boundary, while another `/proc`-synchronized replacement test would duplicate
the unsupported-input semantic family and increase platform fragility.

Any change to the prompt, tests, reference, explanation, Dockerfile, or wrapper
creates another immutable version and requires this audit again. Solver
calibration for version 28 starts at 0/10.

## Canonical version 27 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `47f4e4acd2eb5210f31d3ef933a9695bc5b844bf22b72d84a7e5254d36709715` |
| `test.patch` | `3654aef8c014b318a7c34f98ffa40c3c0157f9bacf5f8e4a1cc6e03dd1ab62ad` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `9dd90f00ef21df6fd8452d1cc74115d62b203a11a09fbbb8c84f6f86e0172880` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:7a6c1bf366e560afad8405c3a1eb94c0bd01f023a0d606c1b63cafcc2bc09e5e` |

Version 27 narrows one participant-facing snapshot boundary and strengthens
one existing public CLI entity. The reference production patch, API,
dependencies, wrapper, test names, and 28/23 Linux/macOS census are unchanged.
The description now requires rejection for metadata changes while an opened
file is read, not for the interval between kernel `open` and the first
descriptor sample. The valid-apply process test now captures and decodes the
real upload request body.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-27 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | The public write fixture invokes planning twice without network opt-outs, compares exact bytes, and observes the proxy through a synchronized listener snapshot. |
| Same source selection and local-root resolution as ordinary upload | Default/alternate-ignore, links, modes, linked/explicit/token/environment roots, punctuation-root ordering, and positional `PATH` plus `--path-as-root` exercise selection parity. |
| Globally sorted normalized paths and selected-root representation | Prefix/path-as-root planning requires `["-hello.txt", ".", "app.txt"]`; the public positional fixture independently requires a `"."`-rooted selected subdirectory. |
| Strict deterministic top-level and entry records | Serializer and sorted raw-reader cases cover fields, versions, ordering, uniqueness, kinds, sizes, digests, Unix modes, and malformed records. |
| Relative normalized UTF-8 paths with no parent component | The reader receives sorted raw JSON for absolute, leading-parent, and embedded-parent paths; the non-UTF-8 selector fixture covers archive-path encoding. |
| Selected inputs are regular and remain stable while read | The selected-socket fixture and deterministic Linux read barriers independently exercise unsupported kind, modification metadata, size, and Unix mode. |
| Apply reconciles stored controls, selection, metadata, and content before every request | Controller mismatches plus public malformed/content/root/option fixtures require local refusal. The positional public entity independently checks both `pathAsRoot` and `noGitignore` CLI wiring against synchronized request counts. |
| The public upload uses the locally verified bytes | A local TLS endpoint answers Railway's real project query, changes the source after local verification, captures `/up`, decodes its gzip tar body, and requires the pre-change verified `app.txt` bytes. |
| Atomic replacement never produces unverified archive bytes | The controller-level replacement entity accepts safe rejection and otherwise decodes the complete original descriptor snapshot. |
| Broken links and unsupported selected types return an error | Dedicated controller and public socket fixtures require only `Err` or unsuccessful status, not message text. |
| Plan flags conflict | The public parser entity requires unsuccessful parsing and zero requests without one exit code or diagnostic format. |
| Compatibility API exists | Grader compilation imports only the declared public plan types and four controller functions. |

### Plausible incorrect modes, alternatives, and isolation

The new command-boundary mutant performs complete local reconciliation through
`create_deploy_tarball_from_plan`, discards the returned bytes, and follows the
ordinary post-resolution tarball branch. This is a repository-natural
shortcut because the ordinary uploader already builds its body after project
and service lookup. It compiles and passes all 474 pre-existing tests and 27
of 28 focused tests. Only
`deployment_plan_valid_apply_continues_after_local_verification` fails: the
captured upload contains `changed\n` instead of the verified `content\n`.
This is a distinct command-to-network discriminator, not another
controller-level archive fixture.

Every `agent-runs6` and `agent-runs7` Nova candidate takes its first stability
sample from the opened descriptor and therefore accepted the former
open-to-first-metadata mutation. That design is now conforming: the mutation
precedes the first metadata sample and all subsequently read bytes. The old
pre-open-comparison omission is retired rather than relabeled as a surviving
incorrect implementation. Mid-read modification, size, and mode omissions
remain killed by their deterministic read barriers.

The exact `agent-runs7/Nova_Nova_3` patch is the representative legitimate
participant replay. It passes all 474 pre-existing tests, with its 11
task-owned self-tests excluded by the base filter, and all 28 version-27
focused entities. This turns a prior 27/28 result into a complete participant
pass while retaining the new upload-body guarantee. The unchanged reference
is the other legitimate implementation and passes every lane.

Additional source-mutation timings, alternate TLS implementations, request
counts, tar stream order, exact diagnostics, compression bytes, and internal
body-variable assertions were rejected as duplicate or implementation-shaped
probes. The upload test asserts only the public request archive's selected file
bytes after a deterministic post-verification mutation.

### Exact results and verdict

- baked network-disabled Linux reference image: 474/474 base and 28/28 new;
- Linux JUnit: zero failures, zero errors, and zero skipped testcases;
- macOS reference: 474/474 base and 23/23 new;
- test-only network-disabled Linux: exit 101; fallback JUnit reports one
  classified failure, zero errors/skips, and retains the unresolved
  `controllers::deploy_plan` compiler diagnostic;
- discard-and-rebuild mutant: 474/474 base and 27/28 new, failing only the
  strengthened valid-apply entity;
- exact `agent-runs7/Nova_Nova_3` replay: 474/474 base and 28/28 new;
- both patch orders, both full reverse checks, `git diff --check`, shell syntax,
  and default-toolchain formatting pass.

No actionable survivor remains in the attempted version-27 mutation set. This
is bounded evidence, not proof that false positives are impossible. Version
27 clears the exact false-positive gate and starts calibration at 0/10; no
result from an earlier immutable version carries forward.

## Canonical version 26 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `f22d253cee5821b686d6112f8c6a979c081349dc6676cd2ff07149d6562dfbae` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:5e5fd4b380bebeebd6f553a23ae7227f0b3e31fa3f6538b30bb4318017aafc7e` |

Version 26 changes only `test.patch` within the submission bundle; internal
design, audit, index, and handoff records were updated to identify the new
immutable version. It strengthens one existing public CLI entity and corrects
proxy and fallback reporting without changing the prompt, reference,
explanation, API, dependencies, test names, or 28/23 Linux/macOS census.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-26 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | The public write fixture invokes planning twice without network opt-outs, compares exact bytes, and observes the proxy through a synchronized listener snapshot. |
| Same source selection and local-root resolution as ordinary upload | Default/alternate-ignore, links, modes, linked/explicit/token/environment roots, punctuation-root ordering, and positional `PATH` plus `--path-as-root` exercise selection parity. |
| Globally sorted normalized paths and selected-root representation | Prefix/path-as-root planning requires `["-hello.txt", ".", "app.txt"]`; the public positional fixture independently requires a `"."`-rooted selected subdirectory. |
| Strict deterministic top-level and entry records | Serializer and sorted raw-reader cases cover fields, versions, ordering, uniqueness, kinds, sizes, digests, Unix modes, and malformed records. |
| Relative normalized UTF-8 paths with no parent component | The reader receives sorted raw JSON for absolute, leading-parent, and embedded-parent paths; the non-UTF-8 selector fixture covers archive-path encoding. |
| Opened regular inputs remain stable until snapshot completion | Selected-socket plus deterministic Linux open/read barriers independently exercise unsupported kind, modification metadata, size, and Unix mode. |
| Apply reconciles stored controls, selection, metadata, and content before every request | Controller mismatches plus public malformed/content/root/option fixtures require local refusal. The positional public entity independently checks both `pathAsRoot` and `noGitignore` CLI wiring against synchronized request counts. |
| Any produced archive contains the verified bytes | The deterministic atomic-replacement entity accepts safe rejection and otherwise decodes the complete original descriptor snapshot. |
| Broken links and unsupported selected types return an error | Dedicated controller and public socket fixtures require only `Err` or unsuccessful status, not message text. |
| Plan flags conflict | The public parser entity requires unsuccessful parsing and zero requests without one exit code or diagnostic format. |
| Compatibility API exists | Grader compilation imports only the declared public plan types and four controller functions. |

### Plausible incorrect modes and exact isolation

A version-26 command-wiring mutant leaves plan creation and the reusable
controller unchanged but passes `false` rather than `Args::no_gitignore` to
`create_deploy_tarball_from_plan` in the public `--from-plan` branch. This is a
plausible independent field-forwarding omission: it compiles, passes all 474
pre-existing tests and the other 22 macOS focused entities, including the
controller-level `no_gitignore` mismatch oracle, then fails only
`deployment_plan_cli_option_mismatch_fails_before_any_request`. The public
invocation reaches one request instead of failing locally.

The version-25 embedded-parent and positional-root mutants remain killed by
their existing entities. The two raw `agent-runs5` near-passes both forward
`no_gitignore`, so the new assertion does not manufacture an additional
failure family for those patches. Replaying `Nova_Nova_2` against the exact
version-26 grader produces 19/23 macOS passes and the same public root-marker
and pre-request failures already present in its historical result. The exact
reference is the representative legitimate replay and passes every lane.

The proxy correction has no candidate predicate: `count()` now sends a
snapshot command, the proxy thread drains all pending accepts, and a bounded
reply completes the observation. The fallback correction introduces no
synthetic entity. In `new` mode it reports the existing
`railwayapp::deployment_plan_cli::deployment_plan_write_is_offline_deterministic_and_self_excluding`
identity; in `base` mode it reports the existing
`railwayapp::bin/railway::cli_tests.backwards_compat.root_commands_exist`
identity. Nonzero no-JUnit runs are failures with escaped runner diagnostics.

Additional `--no-gitignore` argument orders, ignore-file spellings, proxy
delays, request-count minima, and exact diagnostics were rejected as duplicate
fixtures or private presentation requirements. No prompt, reference,
tar-stream ordering, trait, helper, or implementation-layout requirement was
added.

### Exact results and verdict

- network-disabled Linux reference: 474/474 base and 28/28 new;
- Linux base/new JUnit: zero failures, zero errors, and zero skipped testcases;
- macOS reference: 474/474 base and 23/23 new;
- test-only network-disabled Linux: exit 101; fallback JUnit reports one
  classified failure, zero errors/skips, and retains the unresolved
  `controllers::deploy_plan` compiler diagnostic;
- forced base-runner failure: the fallback uses the existing baseline identity
  and retains the missing-toolchain diagnostic;
- both patch orders, both full reverse checks, `git diff --check`, shell syntax,
  and default-toolchain formatting pass.

No actionable survivor remains in the attempted version-26 mutation set. This
is bounded evidence, not proof that false positives are impossible. Version 26
clears the exact false-positive gate and starts calibration at 0/10; no result
from an earlier immutable version carries forward.

## Canonical version 25 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `7de2674f9e78fb0a185ca3e36d538ca7ee2323ed6bd62a89325a440e23bc7c33` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 25 changes only `test.patch`. It strengthens two existing entities
without changing the public description, reference, explanation, API,
dependencies, wrapper, image, test names, or 28/23 Linux/macOS census.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-25 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | The public write fixture invokes planning twice without network opt-outs, compares exact bytes, and counts every proxy request. |
| Same source selection and local-root resolution as ordinary upload | Default/alternate-ignore, links, modes, linked/explicit/token/environment roots, punctuation-root ordering, and positional `PATH` plus `--path-as-root` exercise selection parity. |
| Globally sorted normalized paths and selected-root representation | Prefix/path-as-root planning requires `["-hello.txt", ".", "app.txt"]`; the public positional fixture independently requires a `"."`-rooted selected subdirectory. |
| Strict deterministic top-level and entry records | Serializer and sorted raw-reader cases cover fields, versions, ordering, uniqueness, kinds, sizes, digests, Unix modes, and malformed records. |
| Relative normalized UTF-8 paths with no parent component | The reader receives sorted raw JSON for absolute, leading-parent, and embedded-parent paths; the non-UTF-8 selector fixture covers archive-path encoding. |
| Opened regular inputs remain stable until snapshot completion | Selected-socket plus deterministic Linux open/read barriers independently exercise unsupported kind, modification metadata, size, and Unix mode. |
| Apply reconciles stored controls, selection, metadata, and content before every request | Controller mismatches plus public malformed/content/root/option fixtures require local refusal under a counting proxy; the positional fixture covers CLI forwarding and `pathAsRoot` mismatch. |
| Any produced archive contains the verified bytes | The deterministic atomic-replacement entity accepts safe rejection and otherwise decodes the complete original descriptor snapshot. |
| Broken links and unsupported selected types return an error | Dedicated controller and public socket fixtures require only `Err` or unsuccessful status, not message text. |
| Plan flags conflict | The public parser entity requires unsuccessful parsing and zero requests without one exit code or diagnostic format. |
| Compatibility API exists | Grader compilation imports only the declared public plan types and four controller functions. |

### Plausible incorrect modes and exact isolation

The current unsafe-path fixture originally allowed ordering validation to mask
path validation after replacing a file path. Each mutated document is now
re-sorted before reading. A prefix-only validator that rejects `/absolute` and
strings beginning with `../` but accepts `nested/../escape` compiles, passes
the other 22 macOS focused tests and all 474 baseline tests, then fails only
the unsafe-path entity because the public reader returns `Ok`.

A second mutant preserves the reusable controller and every existing source
selection helper but makes the offline CLI `path_as_root` branch select the
current directory instead of positional `Args.path`. It compiles, passes the
other 22 macOS focused tests and all 474 baseline tests, then fails only the
public CLI option entity: the plan contains `outside.txt` and a `selected/`
prefix instead of only `"."` and `app.txt`.

These are two distinct public seams: component-wide persisted-path validation
and command-to-controller positional-root forwarding. Neither is an argument
ordering permutation, alternate path spelling, private helper assertion,
exact diagnostic, or tar-stream-order requirement. Both `agent-runs5`
near-passes already implement these two behaviors and remain failures for
their independently covered root-marker, snapshot, request-ordering, and
target-resolution omissions.

### Exact results and verdict

- network-disabled Linux reference: 474/474 base and 28/28 new;
- Linux new JUnit: zero failures, zero errors, zero skipped testcases;
- macOS reference: 23/23 new;
- test-only network-disabled Linux: exit 101 with fallback JUnit preserving
  the unresolved `controllers::deploy_plan` diagnostic;
- both patch orders and reverse checks, `git diff --check`, and
  default-toolchain formatting: pass.

No attempted incorrect mode survives the complete focused suite, so no
survivor requires addition to the 474-test regression set. This is bounded
evidence for the attempted mutation set, not proof that every possible false
positive is excluded. Version 25 clears the exact false-positive gate and
starts calibration at 0/10.

## Canonical version 24 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `c678cf73834c743b3882ac7fd7c46d370f523bb550e1de6b7da3d3167b6f4e42` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 24 changes only `test.patch`. One existing source-selection entity now
includes `-hello.txt`, whose normalized path sorts before `"."`, and checks
planning plus ordinary and verified archive path sets. Prompt, reference,
explanation, public API, dependencies, wrapper, image, and 28/23 test census
are unchanged.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-24 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | The public write fixture invokes planning twice under a counting proxy and compares exact bytes. |
| Same source selection and local-root resolution as ordinary upload | Default/alternate-ignore, links, modes, linked/explicit/token/environment roots, and the `-hello.txt` root-position fixture exercise write/apply parity. |
| Globally sorted normalized paths plus the `"."` archive-root marker | The prefix/path-as-root entity requires `["-hello.txt", ".", "app.txt"]`; it does not assume the marker is first. |
| Exact top-level controls and deterministic strict records | Serializer and raw-reader entities cover fields, version, ordering, uniqueness, kinds, sizes, digests, Unix modes, and malformed records. |
| Safe relative paths | Prefix/path-as-root and unsafe-path reader entities cover root representation, absolute paths, and parent components. |
| Opened regular inputs remain stable through snapshot completion | Selected-socket plus deterministic Linux open/read barriers independently exercise unsupported kind, modification metadata, size, and Unix mode. |
| Apply reconciles controls, selection, metadata, and contents before every request | Controller mismatch entities and public malformed/content/option/root CLI fixtures require local refusal under a counting proxy. |
| Successful archives contain verified bytes | The deterministic atomic-replacement entity accepts local `Err`; on `Ok` it decodes and requires every old byte. |
| Broken links, unsupported inputs, and non-UTF-8 paths return an error | Dedicated controller and public CLI entities assert only failure, not diagnostic wording. |
| Plan flags conflict | The public parser entity requires unsuccessful parsing without one exit code or echoed-flag contract. |
| Required compatibility API exists | Grader compilation imports only the declared public plan types and four controller functions. |

### Exact false-positive isolation

The adjudicator's in-crate probe was reproduced with the available
`agent-runs4/Nova_Nova_2` implementation, whose validator contains the reported
error verbatim. Against only the strengthened
`deployment_plan_service_prefix_and_path_as_root_modes_are_preserved` entity,
the candidate compiles and fails at path-as-root planning:
`deploy plan root marker must be a directory`. The reference passes the same
entity on Linux and macOS.

Nova3, Nova4, Nova1, and Orion contain related first-entry root assumptions,
so the error is a plausible solver family. A positional-root mutant is killed
by the same entity. No punctuation variants were added: space, `!`, `#`, `+`,
and other pre-dot names exercise the same ordering boundary and would not add
a discriminator.

The version-23 pre-open, permissive-reader, verify-then-reopen, source-root,
late-network, metadata, missing-mode, and unsupported-input probes remain
unchanged. The only newly actionable survivor was root-marker position
dependence, and it is now killed. Exact error text, tar-stream sequence, public
Serde/equality traits, and mandatory success after atomic replacement remain
rejected as artificial or implementation-prescriptive additions.

### Exact results and verdict

- combined network-disabled Linux: 474/474 base and 28/28 new;
- combined macOS: 23/23 new;
- Linux and macOS new JUnit: zero failures, errors, or skipped new testcases;
- test-only Linux: exit 101 with the unresolved controller diagnostic retained
  in fallback JUnit;
- both patch orders and reverse checks, applied-tree whitespace checks, and
  formatting: pass.

No attempted incorrect mode survives the complete focused suite, so no new
survivor requires promotion to the 474-test regression suite. Version 24
clears the bounded exact false-positive gate and starts calibration at 0/10.

## Canonical version 23 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `858946bc4e4c6fc2bdfffda0def2d3fb910c967bed9735a1f8e9024f6f900d01` |
| `test.patch` | `6ae1bc174f136556136d3d041a3307fbe6b2a092f9e087f60c77c1a490b663e7` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 23 changes the prompt's subjective failure wording and strengthens two
existing test entities without increasing the 28/23 Linux/macOS census. Raw
persisted plans now cover missing and invalid-length regular-file digests and
an unknown entry kind. The Linux race fixtures replace descriptor polling and
64–128 MiB payloads with a synchronous test-only open/read barrier and 4 KiB
payloads. The atomic oracle continues to permit safe rejection or coherent old
bytes on success.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-23 behavioral oracle |
|---|---|
| Offline deterministic planning, self-exclusion, and no auxiliary request | The public write fixture invokes planning twice under a counting proxy and compares exact bytes. |
| Ordinary selection and source-root resolution | Default/alternate-ignore, prefix, link, mode, and public linked/explicit/token/environment fixtures exercise both write and apply. |
| Exact top-level controls and deterministic strict records | Serializer and raw-reader entities cover fields, version, ordering, uniqueness, kinds, sizes, digests, Unix modes, and malformed records. |
| Root marker and safe normalized paths | Prefix/path-as-root and unsafe-path reader entities require `"."`, relative paths, and no parent component. |
| Opened regular inputs remain stable through snapshot completion | Selected-socket plus deterministic Linux open/read barriers independently exercise unsupported kind, modification metadata, size, and Unix mode. |
| Apply reconciles controls, selection, metadata, and contents before every request | Controller mismatch entities and public malformed/content/option/root CLI fixtures require local refusal under a counting proxy. |
| Successful archives contain the verified bytes | The deterministic atomic-replacement entity accepts local `Err`; on `Ok` it decodes the payload and requires every old byte. |
| Broken links, unsupported inputs, and non-UTF-8 paths return an error | Dedicated controller and public CLI entities assert only `Err` or unsuccessful status, not diagnostic wording. |
| Plan flags conflict | The public parser entity requires only unsuccessful parsing, not one exit code or echoed flag list. |
| Required compatibility API exists | Grader compilation imports only the declared plan types and four controller functions. |

### Plausible incorrect modes and isolation

| Mutant or replay | Repository/trajectory basis | Focused result | Disposition |
|---|---|---|---|
| Remove pathname-before-open metadata comparisons. | `agent-runs4` Nova2, Nova6, and Nova7 independently compare only descriptor samples taken after open. | Compiles and fails the deterministic open-phase modification assertion. | Actionable false positive closed. |
| Replay exact `agent-runs4/Nova_Nova_2`. | It was a version-22 28/28 nominal pass despite never comparing its initial pathname sample to the opened descriptor. | Fails deterministically with result marker `O` where rejection marker `E` is required. | Representative failing solver replay; no scheduler dependence remains. |
| Omit reader-side plan validation while retaining strict serialization. | The review identified a direction asymmetry, and the API exposes separate reader and serializer operations. | Compiles and fails the raw malformed-record reader entity. | Actionable reader shortcut remains killed; the added digest/kind cases broaden the same public record family. |
| Verify descriptor bytes, then reopen the pathname for tar input. | Existing upload appends paths, making reuse of the old helper a plausible shortcut. | Compiles and fails the deterministic atomic-replacement payload assertion. | Actionable byte-integrity shortcut remains killed. |
| Reject atomic replacement after descriptor identity or change metadata differs. | The version-22 fairness report established this as a valid conservative design. | Reference and historical conservative replay are accepted by the `Err` branch. | Legitimate alternative retained, not a mutant. |

No attempted incorrect mode passes the complete focused suite, so there is no
new survivor to promote to the 474-test regression suite. Historical
root-policy, late-network, omitted metadata, missing-mode, unsupported-socket,
and permissive-reader mutants remain covered by unchanged entities and their
earlier exact audits.

There is no legitimate solver pass in `agent-runs4`: its three nominal passes
share the public open-window omission. The exact reference is the legitimate
implementation for version 23. The earlier conservative
`agent-runs3/Nova_Nova_1` replay passed version 22, but its local patch was a
macOS dataless placeholder when the v23 replay was attempted; it is retained
only as historical evidence and is not reported as a v23 execution.

Rejected additions remain exact error strings, tar-stream ordering, public
Serde or equality traits, repeated path permutations, mandatory success after
atomic replacement, and private production hooks. They either prescribe
presentation/architecture, duplicate an existing semantic family, or exceed
the public contract.

### Exact results and verdict

- combined network-disabled Linux: 474/474 base and 28/28 new;
- combined macOS: 23/23 new;
- new JUnit: 28 testcases, zero failures, zero errors, zero skipped new
  testcases;
- test-only Linux: exit 101, with fallback JUnit preserving the unresolved
  controller import;
- both patch orders and reverse checks, `git diff --check`, and
  default-toolchain formatting: pass.

Version 23 has no actionable survivor in the attempted mutation set and clears
the exact false-positive gate. This is bounded evidence, not proof that every
possible incorrect implementation is excluded. Calibration restarts at 0/10;
the version-22 3/10 batch is historical.

## Canonical version 22 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be` |
| `test.patch` | `c6639ff612ba5144e5dd2fc800e8f96d5d043cd4717df763495f46e74760eebc` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 22 changes only the atomic-replacement assertion and its test name.
The watcher still proves that the equal-size replacement occurred after the
selected descriptor was observed. The operation may now reject that change;
if it returns an archive, the decoded payload must still be the complete
pre-replacement snapshot. Prompt, reference, explanation, public API, test
count, wrapper, dependencies, and container are unchanged.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-22 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | The public write fixture writes twice under a counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and public linked/explicit/token/environment root fixtures cover ordinary-upload parity. |
| Strict deterministic plan records and safe paths | Serializer and raw-reader entities cover fields, version, order, uniqueness, kinds, sizes, digests, modes, relative paths, and parent traversal. |
| Declared compatibility interface without extra public traits | Test compilation imports only the four listed new controller functions and public plan types. |
| Stored controls, source set, metadata, and contents reconcile | Option, added/removed/renamed, type, size, mode, same-size-content, and changed explicit-project CLI entities require refusal. |
| Opened inputs are regular and stable through planning | The selected-socket fixture and three synchronized Linux entities independently exercise unsupported type, mtime, size, and mode. |
| Verified bytes become archive bytes | The synchronized atomic-replacement entity accepts safe rejection; on success it decodes the archive and requires every payload byte to come from the verified old descriptor snapshot. |
| Every local apply refusal precedes every request | Malformed, changed-content, stored-option, and changed explicit-project CLI entities require zero connections. |
| Successful local verification continues remotely | Generic valid apply plus linked, explicit-project, project-token, and environment-targeted root cases require positive post-verification network activity. |
| Plan flags conflict locally | Every conflict combination fails with zero requests; no exit code or diagnostic wording is inspected. |

### Fairness-correction mutation and replay audit

| Exact mode | Result |
|---|---|
| V22-M1 verify/hash buffered bytes, then reopen the selected pathname for tar input | Compiles; 27/28 focused tests pass and the revised atomic entity fails because the successful archive contains replacement bytes. |
| V22-L1 replay `agent-runs3/Nova_Nova_1`, which conservatively rejects the replacement after descriptor change metadata moves | Compiles and passes all 28 version-22 focused tests. This is the legitimate alternative that version 21 unfairly rejected. |
| V22-R1 restored reference | Passes both clean patch orders and every exact lane; on the atomic fixture it succeeds with the original verified payload. |

The changed oracle therefore admits both valid behaviors while still rejecting
the natural verify-then-reopen shortcut. An implementation that always rejects
plan application remains caught by the unchanged valid-archive and
post-verification-network entities. The version-21 raw-reader and four
source-root mutation deltas were re-inspected against their unchanged
assertions; the atomic edit does not touch those failure families, and no new
survivor was introduced.

An additional exact replay of `Nova_Nova_2` was attempted after the reference,
mutant, and legitimate replay completed. Docker's task-owned target volume
returned `Input/output error` while writing Cargo's query cache, so that
attempt produced no behavioral result and is excluded. Its known
open-to-first-metadata failure is exercised by an unchanged Linux entity and
is not used to establish the version-22 fairness verdict.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed, 0 failures, 0 errors |
| Reference, macOS `new` | 23 passed |
| Test-only Linux `new` | exits 101; fallback JUnit preserves the unresolved-controller diagnostic |
| Legitimate conservative trajectory replay, Linux `new` | 28 passed |
| Verify-then-reopen mutant, Linux `new` | 27 passed; revised atomic entity fails on replacement bytes |
| Patch order, reverse, format, shell, and applied-tree checks | pass |

Version 22 clears the exact false-positive gate and begins calibration at
0/10. No result from version 21 or an earlier version carries across the
changed test hash.

## Canonical version 21 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2ebfb74eadff3739fe6f3ee0af959644c7bdaf8d375f132c3d272a3e876363be` |
| `test.patch` | `fc7679b7296e78021877c22be6ad7276975cb96e274a1be0f2d38e8a70b17141` |
| `solution.patch` | `2123cdf03f7858c761923dfd1f85e24c84de2c5123f0a06d107e4f07be3e5889` |
| `solution_approach.md` | `f73af7a228cb5109460c04ef63739cf0f23b413a3da1a34aff14150f24284411` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 21 renames the compatibility heading, strengthens two existing test
entities, and corrects offline root selection for project-token and
environment-variable targeting. It adds no dependency, test entity, timing
fixture, schema field, or diagnostic contract.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-21 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | The public write fixture writes twice under a counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and public linked/explicit/token/environment root fixtures cover ordinary-upload parity. |
| Strict deterministic plan records and safe paths | Serializer and raw-reader entities cover fields, version, order, uniqueness, kinds, sizes, digests, modes, relative paths, and parent traversal. |
| Declared compatibility interface without extra public traits | Test compilation imports only the four listed new controller functions and public plan types. |
| Stored controls, source set, metadata, and contents reconcile | Option, added/removed/renamed, type, size, mode, same-size-content, and changed explicit-project CLI entities require refusal. |
| Opened inputs are regular and stable through planning | The selected-socket fixture and three synchronized Linux entities independently exercise unsupported type, mtime, size, and mode. |
| Verified bytes become archive bytes | The atomic-replacement entity replaces the pathname after the verified descriptor opens and requires the old verified bytes in the archive. |
| Every local apply refusal precedes every request | Malformed, changed-content, stored-option, and changed explicit-project CLI entities require zero connections. |
| Successful local verification continues remotely | Generic valid apply plus linked, explicit-project, project-token, and environment-targeted root cases require positive post-verification network activity. |
| Plan flags conflict locally | Every conflict combination fails with zero requests; no exit code or diagnostic wording is inspected. |

### Reviewer-correction mutation audit

| Exact mode | Result |
|---|---|
| V21-M1 omit `validate_plan` from raw plan reading while retaining serializer validation | Compiles; the raw reversed-entry assertion fails because `read_deploy_plan` accepts it. |
| V21-M2 use the current directory for every `--from-plan` invocation | Compiles; linked-child apply fails locally instead of reaching the remote boundary. |
| V21-M3 ignore project-token targeting when choosing the offline root | Compiles; project-token apply scans the linked ancestor and fails the current-directory assertion. |
| V21-M4 ignore environment-variable targeting when choosing the offline root | Compiles; environment-targeted apply scans the linked ancestor and fails the current-directory assertion. |
| V21-R1 restored reference | Byte-identical across both clean patch orders and passes all exact lanes. |

No actionable mutant survives the focused suite, so none advances to the
complete baseline. The complete baseline is nevertheless rerun on the exact
reference. The added cases are distinct parsing-direction and CLI-root
boundaries required by the public contract, not permutations of filenames or
private helper behavior.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed |
| Reference, macOS `new` | 23 passed |
| Test-only Linux `new` | exits 101; fallback JUnit preserves the unresolved-controller diagnostic |
| Permissive raw-reader mutant | fails the raw unsorted-plan assertion |
| Apply-always-current-directory mutant | fails linked-root local verification |
| Project-token root mutant | fails project-token local verification |
| Environment-target root mutant | fails environment-targeted local verification |
| Patch order, reverse, format, shell, and applied-tree checks | pass |

Version 21 clears the exact false-positive gate and begins calibration at
0/10. Version 20's reviewer-reported 1/10 result remains historical evidence
and does not carry across changed prompt, test, reference, and explanation
hashes.

## Canonical version 20 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `fd4947f855b8aca3684960fe39f978efb5e83a00ca63853c817f2467b0d8e6c5` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 20 changes only `meta.md`. Every test, reference, explanation,
container, wrapper, API, and production byte is identical to version 19.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-20 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | The public write fixture writes twice under a counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and linked-parent/explicit-project fixtures cover ordinary-upload parity. |
| Strict deterministic plan records and safe paths | Serializer and reader entities cover fields, version, order, uniqueness, kinds, sizes, digests, modes, relative paths, and parent traversal. |
| Declared grader interface without extra public traits | Test compilation imports only the four listed new controller functions and public plan types. |
| Stored controls, source set, metadata, and contents reconcile | Option, added/removed/renamed, type, size, mode, and same-size-content entities require refusal. |
| Opened inputs are regular and stable through planning | The selected-socket fixture and three synchronized Linux entities independently exercise unsupported type, mtime, size, and mode. |
| Verified bytes become archive bytes | The atomic-replacement entity replaces the pathname after the verified descriptor opens and requires the old verified bytes in the archive. |
| Broken links and unsupported inputs fail | Reusable broken-link checks and a public directly selected Unix socket require local failure. |
| Every local apply refusal precedes every request | Malformed, changed-content, and stored-option CLI entities require zero connections. |
| Successful verification continues remotely | Valid apply requires positive post-verification network activity. |
| Plan flags conflict locally | Every conflict combination fails with zero requests; no exit code or diagnostic wording is inspected. |

### Snapshot-clause mutation audit

The deleted sentence supplied an abstract description immediately before a
concrete, independently testable rule. Representative version-13 trajectories
already chose descriptor-backed reads; their meaningful snapshot failures were
omitted metadata dimensions or the wrong comparison interval.

| Exact mode | Result |
|---|---|
| V20-M1 omit both modification-state comparisons | Compiles; the mtime-only synchronized race fails because planning accepts the changed file. |
| V20-M2 omit both size comparisons and the descriptor byte-count check | Compiles; the size-only synchronized race fails because planning accepts the changed file. |
| V20-M3 omit both Unix-mode comparisons | Compiles; the mode-only synchronized race fails because planning accepts the changed file. |
| V20-R1 restored reference | Byte-identical to the clean solution-first application and passes all exact lanes. |

No actionable mutant survives the focused suite. No new probe was added:
each concrete requirement already owns a distinct discriminator, and adding a
second abstraction-level test would duplicate rather than improve coverage.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed |
| Reference, macOS `new` | 23 passed |
| Modification-check omission, mtime race | fails the changed-during-snapshot assertion |
| Size-check omission, size race | fails the changed-during-snapshot assertion |
| Mode-check omission, mode race | fails the changed-during-snapshot assertion |
| Patch order, reverse, format, shell, and applied-tree checks | pass |

Version 20 clears the exact false-positive gate and begins calibration at
0/10. Version 13's 2/10 result remains historical evidence and does not carry
across the changed prompt hash.

## Canonical version 19 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `4415e1706a5712107828028c4d060883ffc28e6e5d8932de90c62ba2c9c92c44` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 19 changes only `meta.md`. Every test, reference, explanation,
container, wrapper, API, and production byte is identical to version 18.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-19 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | The public write fixture writes twice under a counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and linked-parent/explicit-project fixtures cover ordinary-upload parity. |
| Strict deterministic plan records and safe paths | Serializer and reader entities cover fields, version, order, uniqueness, kinds, sizes, digests, modes, relative paths, and parent traversal. |
| Declared grader interface without extra public traits | Test compilation imports only the four listed new controller functions and public plan types. |
| Stored controls, source set, metadata, and contents reconcile | Option, added/removed/renamed, type, size, mode, and same-size-content entities require refusal. |
| Coherent descriptor-backed planning snapshot | Three serialized Linux entities independently change mtime, size, and mode after descriptor open. |
| Verified bytes become archive bytes | The atomic-replacement entity replaces the pathname after the verified descriptor opens and requires the old verified bytes in the archive. |
| Broken links and unsupported inputs fail | Reusable broken-link checks and a public directly selected Unix socket require local failure. |
| Every local apply refusal precedes every request | Malformed, changed-content, and stored-option CLI entities require zero connections. |
| Successful verification continues remotely | Valid apply requires positive post-verification network activity. |
| Plan flags conflict locally | Every conflict combination fails with zero requests; no exit code or diagnostic wording is inspected. |

### Prompt-deletion mutation audit

The removed sentence prohibited reopening a pathname and a second source scan.
Those are internal strategies, while the retained contract controls archived
bytes. The representative pass, near-pass, and broad-failure trajectories all
derived snapshot-byte buffering independently; their meaningful failures were
metadata timing and external-effect ordering.

| Exact mode | Result |
|---|---|
| V19-M1 verify buffered bytes, then reopen the pathname for tar input | Compiles and passes all 474 network-disabled Linux baseline tests; the atomic-replacement entity fails because replacement bytes enter the archive. |
| V19-R1 restored reference | Byte-identical to the clean solution-first application and passes all exact lanes. |

No actionable mutant survives the focused suite. No new test was added because
the existing byte-level oracle already distinguishes the plausible shortcut.
No scan-count, handle-identity, buffering, tar-construction, timing, or private
call-order rule remains participant-facing.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed |
| Reference, macOS `new` | 23 passed |
| Verify-then-reopen mutant, Linux `base` | 474 passed |
| Verify-then-reopen mutant, atomic-replacement entity | fails the archived-byte assertion |
| Patch order, reverse, format, shell, and applied-tree checks | pass |

Version 19 clears the exact false-positive gate and begins calibration at
0/10. Version 13's 2/10 result remains historical evidence and does not carry
across the changed prompt hash.

## Canonical version 18 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `dd0a8ea05ed813f74da325041962b655782a8209460ecbfd93e2fdcfd8fac838` |
| `test.patch` | `745ec28c8b350ae1d98dfbbb838eaccc6407a6cf85428fefa1fecbe23ac54737` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 18 changes one schema sentence and two existing test bodies. Reference,
explanation, Docker, wrapper, production footprint, and test census are
unchanged.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-18 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | `deployment_plan_write_is_offline_deterministic_and_self_excluding` writes twice under the counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and linked-parent/explicit-project fixtures cover ordinary upload parity. |
| Strict deterministic plan records | Serialization, parser, invalid-record, directory-metadata, missing-Unix-mode, unsupported-version, and unknown-entry-field branches cover fields, version, order, uniqueness, kinds, sizes, digests, and permission presence. |
| Safe normalized archive paths | The reader fixture separately rejects an absolute path and a parent-traversal path; the prompt now states both rules. |
| Declared grader interface without extra public traits | Test compilation imports the four listed new controller functions and public plan types. Fixtures serialize `DeployPlan` only through the declared serializer. |
| Persisted invocation controls match before apply effects | Reusable mismatch checks cover both stored controls; the public CLI mismatch probe requires zero connections. |
| Source set and metadata reconcile | Added/removed/renamed, type, size, Unix mode, and same-size content entities require refusal. |
| Coherent descriptor-backed planning snapshot | Three serialized Linux entities independently change mtime, size, and mode after descriptor open. |
| Verified bytes become archive bytes | The atomic-replacement entity requires the opened old bytes in the archive. |
| Broken links and unsupported selected inputs fail | Reusable broken-link checks and a public directly selected Unix socket require local failure; the CLI socket probe observes zero requests. |
| Every local apply refusal precedes every request | Malformed, changed-content, and stored-option public CLI entities require zero connections. |
| Successful verification continues remotely | Valid apply requires positive post-verification network activity. |
| Plan flags conflict locally | Every conflict combination must fail and make zero requests; no exit code or diagnostic wording is inspected. |

### Plausible incorrect implementations and compatibility probes

Repository evidence and `agent-runs3` support independent DTOs, parser-driven
or explicit conflict checks, path validators, descriptor-backed snapshots,
and late-auth shortcuts. The exact trials were:

| Mode | Exact result |
|---|---|
| V18-C1 remove public `Serialize` from `DeployPlan` and serialize through a private wire DTO | Compiles and passes the strict parser entity, proving the grader no longer imposes the trait. |
| V18-M1 remove unsupported-version validation | Compiles; the reader assertion fails. |
| V18-M2 admit absolute archive names | Compiles; the `/absolute` reader assertion fails. |
| V18-M3 admit parent traversal | Compiles; the `../escape` reader assertion fails. |
| V18-C2 emit a generic conflict diagnostic | Accepted by oracle inspection: the test reads only unsuccessful status and final proxy count. |

V18-M1 through M3 are killed in the focused suite, so no actionable survivor
reaches the complete baseline. The version-17 selection, snapshot, metadata,
archive-byte, unsupported-input, and pre-network mutation families retain
byte-identical probes. Representative raw trajectories remain useful evidence:
the reported pass, near-pass, and broad-failure designs all use reasonable
source-selection and conflict architectures, while their meaningful split is
still snapshot coherence and pre-network sequencing.

No probe was added for a Serde trait, exact conflict prose, exit code,
additional traversal spelling, separator convention, or private parser
mechanism. The only prompt clarification exposes the existing safety policy
used by two semantically distinct path cases.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed; JUnit 28 tests, 0 failures, 0 errors, no skipped testcase |
| Reference, macOS `new` | 23 passed |
| Test patch only, macOS `new` | exits 101; one classified fallback retains the unresolved-controller diagnostic |
| Patch order, reverse, format, shell, and applied-tree checks | pass |

The restored reference controller is byte-identical to the clean
solution-first application. No plausible incorrect exact-version mutant
survives, and the compatibility probes demonstrate that the two removed
constraints are genuinely absent.

Version 18 clears the exact false-positive gate and begins calibration at
0/10. Version 13's 2/10 result remains historical trajectory evidence and
does not carry across either changed artifact hash.

## Canonical version 17 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `e5bf0cacf57d9f9d486919224f43fc04684e99d82073d6a7792fe8171675ae79` |
| `test.patch` | `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 17 changes only `meta.md`. Tests, reference behavior, explanation,
container, wrapper, production footprint, and test census are byte-identical
to version 16.

### Requirement map and prompt-deletion audit

Every version-16 participant requirement and strongest oracle remains
unchanged. In particular, the schema paragraph still requires strict,
deterministic, versioned JSON; rejects unknown fields, unsupported versions,
invalid paths, malformed records, duplicates, and unsorted entries; and defines
entry metadata and digests. The function signatures communicate the four
grader integration points without repeating those behaviors.

| Exact mode | Result |
|---|---|
| V17-M1 accept unsupported versions while reading | The strict parser entity fails at the unsupported-version reader assertion. |
| V17-M2 accept unknown fields within entries | The strict parser entity fails at the nested unknown-field assertion. |
| V17-M3 serialize without validating | The strict parser entity fails when an unsupported constructed plan serializes successfully. |

All other mutants and trajectory replays are governed by byte-identical test
and reference artifacts and retain the version-16 outcomes. The reported pass,
near-pass, and broad-failure trajectories all implemented strict I/O from the
schema paragraph itself, independently of the deleted repetition.

### Validation and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed, 0 failures, 0 errors, 0 skips |
| Reference, macOS `new` | 23 passed |
| Test-only and patch-order gates | Byte-identical to version 16 and retain their green/classified outcomes |

The restored reference controller is byte-identical to the canonical version.
No requirement, oracle, interface signature, or implementation architecture
changed. Every shortcut tied to the deleted prose remains rejected by an
earlier public requirement.

Version 17 clears the exact false-positive gate and begins calibration at
0/10. The version-13 2/10 result remains trajectory evidence and does not
carry across the prompt hash change.

## Canonical version 16 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `c63130a29db775e2d34ff6349cfa1c6bebde708273eea732235c05c033b02046` |
| `test.patch` | `b9d5bdd33a89e702f25a75f7bfde4b9caddbf078a329cce9fa47312e3bda56aa` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 16 changes only the participant-facing prompt and the assertion body of
one existing CLI conflict entity. The reference, explanation, container,
production footprint, wrapper, test names/counts, and every other oracle are
byte-identical to version 15.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-16 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | The public write fixture writes twice under the counting proxy and compares exact plan bytes. |
| Ordinary selection, root representation, and local-root resolution | Selection fixtures cover ignores and links; the prefix/path-as-root entity requires the selected root and normalized `"."` at archive root; public linked-parent/explicit-project fixtures cover local resolution. |
| Strict deterministic plan records | Serialization, parser, invalid-record, directory-metadata, unsafe-path, and missing-Unix-mode branches cover fields, version, order, uniqueness, kinds, sizes, digests, paths, and permission presence. |
| Declared grader interface | Test compilation imports the four listed new controller functions and public plan types. Existing repository helpers are no longer participant-facing assumptions. |
| Persisted controls and source metadata reconcile | Reusable and public fixtures cover stored controls, path set, type, size, Unix mode, and same-size content. |
| Coherent descriptor-backed planning snapshot | Three serialized Linux entities independently change mtime, size, and mode after descriptor open. |
| Verified bytes become archive bytes | The atomic-replacement entity requires the opened old bytes in the archive. |
| Unsupported selected inputs fail | A directly selected Unix socket must fail locally with zero requests. |
| Every local apply refusal precedes every request | Malformed, changed-content, and option-mismatch public CLI entities require zero connections. |
| Successful verification and conflicts | Valid apply requires post-verification network activity. Conflict invocations must fail, identify their option names, and make zero requests; no exact status or phrase is required. |

### Executed mutants and trajectory replays

| Mode | Exact result |
|---|---|
| V16-M1 omit archive-root `"."` from path-as-root plans | Compiles; the existing prefix/path-as-root entity fails its plan-path comparison. |
| V16-M2 accept unsupported reader versions | Compiles; the parser entity fails at the unsupported-version read assertion. |
| V16-M3 accept unknown entry fields | Compiles; the parser entity fails at the nested unknown-field assertion. |
| V16-M4 reconcile persisted options after remote setup | `agent-runs3/Nova_Nova_5` compiles; the unchanged public mismatch entity observes two requests and fails. |
| V16-R1 `agent-runs3/Nova_Nova_1` | Compiles and passes the relaxed public conflict entity. |
| V16-R2 `agent-runs3/Nova_Nova_2` | Compiles and passes the relaxed public conflict entity. |

All version-14 snapshot, socket, Unix-mode, archive-byte, and pre-network
mutants remain killed by byte-identical test bodies. V16-M2 and V16-M3 repeat
the strict-reader modes against the exact current grader; V16-M1 isolates the
newly clarified root sentence. No exact-exit-code mutant exists because the
current oracle explicitly accepts every non-zero status.

### Validation, reporting, and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed, 0 failures, 0 errors, 0 skips |
| Reference, macOS `new` | 23 passed |
| Test patch only, Linux `new` | exits 101; one skipped synthetic fallback retains the compiler diagnostic |
| Historical pass and near-pass | relaxed conflict entity passes in both |

Both patches apply independently and together in either order and
reverse-check. The reference source restored after mutation is byte-identical
to the clean other-order application. Every actionable exact-version mutant
is rejected by a public requirement, and no redundant root spelling, exit
status, exact message, helper call, or parser implementation is required.

Version 16 clears the exact false-positive gate and begins calibration at
0/10. The version-13 2/10 result remains trajectory evidence and does not
carry across the changed hashes.

## Canonical version 15 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `2d90da444a11e28174359472310ab6ef1e9e040049753480bbe4f6779da18536` |
| `test.patch` | `9de6aaafeab48b579193eec31b3dc811c4327bc0898d92ea5ff4318eba3b1a57` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The patch application, reverse-check, formatting, whitespace, test-only, and
reference gates pass. Version 15 changes only the participant-facing prompt
and 11 lines inside one existing parser test; the reference, explanation,
container, production footprint, wrapper, test entity count, and all other
oracles are byte-identical to version 14.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-15 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | `deployment_plan_write_is_offline_deterministic_and_self_excluding` writes twice under the counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and public linked-parent/explicit-project fixtures cover ordinary upload parity. |
| Strict deterministic plan records | Serialization, parser, invalid-record, directory-metadata, unsafe-path, and missing-Unix-mode branches cover fields, version, order, uniqueness, kinds, sizes, digests, paths, and permission presence. The parser entity now explicitly rejects an unsupported version through `read_deploy_plan` and an unknown entry field. |
| Declared grader interface | Test compilation imports the listed `controllers::deploy_plan` types/functions and calls the existing upload comparison seam with the documented shapes. This is an interface assumption, not a behavioral discriminator. |
| Persisted invocation controls match at apply | The reusable mismatch fixture checks both controls; the public CLI mismatch fixture mutates `noGitignore` and requires zero connections. |
| Source set and metadata reconcile | Added/removed/renamed, type, size, mode, and same-size content entities require refusal. |
| Coherent descriptor-backed planning snapshot | Three serialized Linux entities independently change mtime, size while preserving mtime/mode, and mode while preserving mtime/size after the descriptor opens. |
| Verified bytes become archive bytes | The atomic-replacement entity requires the opened old bytes in the archive. |
| Unsupported selected inputs fail | A directly selected Unix socket must fail locally with zero requests. |
| Every local apply refusal precedes every request | Malformed, changed-content, and option-mismatch public CLI entities require zero connections. |
| Successful verification continues and conflicts parse locally | Valid apply requires positive post-verification network activity; all conflict combinations require parser exit 2 and zero connections. |

The minimal Test assumptions paragraph discloses only symbols that the grader
must compile against. The removed abstract “operations must be reusable”
sentence supplied no separate observable behavior. The exact function seams
remain justified by direct archive inspection and strict reader/serializer
tests that cannot be made reliable through a failed remote deployment.

### Executed mutants and trajectory replays

| Mode | Exact result |
|---|---|
| V15-M1 accept unsupported versions through the reader | Removing the version validation branch compiled; the parser entity failed at the new reader assertion. |
| V15-M2 accept unknown fields inside entries | Removing only entry-level `deny_unknown_fields` compiled; the parser entity failed at the new nested-field assertion. |
| V15-R1 `agent-runs3/Nova_Nova_1` | The historical reported pass compiles with the current grader and passes the strengthened parser entity. |
| V15-R2 `agent-runs3/Nova_Nova_2` | The representative snapshot near-pass also passes the strengthened parser entity. |

These replays show the new cases do not distinguish the historical pass from
the near-pass and do not create an additional difficulty family. The existing
version-14 five-mutant audit remains applicable to every byte-identical
behavioral oracle, while V15-M1 and V15-M2 isolate the two changed branches.
No plausible incorrect implementation from the reviewed trajectories survives
the focused suite, so no survivor reaches the complete baseline stage.

### Validation, reporting, and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 failures, 0 errors, 0 skips |
| Reference, network-disabled Linux `new` | 28 passed, 0 failures, 0 errors, 0 skips |
| Reference, macOS `new` | 23 passed |
| Test patch only, Linux `new` | exits 101; one skipped synthetic fallback contains the unresolved-module compiler diagnostic |
| Historical reported pass and near-pass | strengthened parser entity passes in both |

Both patches apply independently and together in either order and
reverse-check. The final restored reference source is byte-identical to the
source used for the complete run. Every actionable version-15 mutant is killed
by the public strict-reader contract, and no artificial extra-field location,
version value, serde detail, or error message was added.

Version 15 clears the exact false-positive gate and begins calibration at
0/10. The version-13 2/10 result remains valuable trajectory evidence, but no
run or solve rate carries across the changed prompt and grader hashes.

## Canonical version 14 exact audit

### Immutable version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `83a9c0968716b32e2a4c2560746efbc17d82684f79b127dfd328e965fd56ed80` |
| `test.patch` | `d1c6efb4aa1077913ecfb72ba69e6efc19ce9fc02017f609bf72786e710e5fc0` |
| `solution.patch` | `2499a8be7486e17646f62ddac30856a50999c2f213a5f9a8cda868b0811e657b` |
| `solution_approach.md` | `f882b76d665ca920926dffd6432fb9ce2bcdc19146eb1067ecd9e363fc5eec3f` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

The patches apply independently and together in both orders, reverse-check,
format, and pass applied-tree whitespace validation. The reference remains
dependency-neutral and measures 731 production additions and 96 deletions, or
635 strict effective additions across six files.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-14 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary request | `deployment_plan_write_is_offline_deterministic_and_self_excluding` writes twice under the counting proxy and compares exact plan bytes. |
| Ordinary selection and local-root resolution | Default/alternate-ignore, prefix, followed-link, broken-link, non-UTF-8, mode, and public linked-parent/explicit-project fixtures cover ordinary upload parity. |
| Strict deterministic plan records | Serialization, parser, invalid-record, directory-metadata, unsafe-path, and missing-Unix-mode branches cover fields, version, order, uniqueness, kinds, sizes, digests, paths, and permission presence. |
| Persisted invocation controls match at apply | The reusable mismatch fixture checks both controls; `deployment_plan_cli_option_mismatch_fails_before_any_request` mutates `noGitignore` and requires zero connections. |
| Source set and metadata reconcile | Added/removed/renamed, type, size, mode, and same-size content entities require refusal. |
| Coherent descriptor-backed planning snapshot | Three serialized Linux entities independently change mtime, size while preserving mtime/mode, and mode while preserving mtime/size after the descriptor opens. Each watcher has a 30-second deadline and an explicit untriggered assertion. |
| Verified bytes become archive bytes | The atomic-replacement entity requires the opened old bytes in the archive; its watcher is serialized, bounded, and reports when the intended event was not observed. |
| Unsupported selected inputs fail | `deployment_plan_write_rejects_unsupported_selected_socket` supplies a directly selected Unix socket and requires a local zero-request failure. |
| Every local apply refusal precedes every request | Malformed, changed-content, and option-mismatch public CLI entities use ordinary auxiliary-network defaults and require zero connections. |
| Successful verification continues and conflicts parse locally | The valid apply requires positive post-verification network activity; all three conflict combinations require parser exit 2 and zero connections. |

The final paragraph in the prompt describes reuse behaviorally. New version-14
probes go through the public CLI. Historical controller-level fixtures remain
for archive-byte and race observability; no additional private helper or error
text was introduced in this revision.

### Executed mutants and replay evidence

| Mode | Plausibility and exact result |
|---|---|
| V14-M1 accept Unix entries with no mode during strict read | Removing the new validation branch compiled; the strict reader entity failed at the mode-less file record. |
| V14-M2 silently skip unsupported selected objects | Replacing the unsupported-kind refusal with `continue` compiled; the public socket write succeeded and the new CLI entity failed. |
| V14-M3 ignore descriptor mode after the read | Removing only the final mode comparison compiled; the synchronized mode-only race failed because planning accepted it. |
| V14-M4 ignore final size and byte count | Removing only those two checks compiled; the synchronized size-only, mtime-preserving race failed because planning accepted it. |
| V14-M5 reconcile a persisted option after remote setup | The representative `agent-runs3/Nova_Nova_5` architecture compiled; the new public option-mismatch entity observed two proxy connections instead of zero. |
| V14-R1 `agent-runs3/Nova_Nova_1` | The historical v13 pass now runs 27/28 and fails only atomic replacement. It compares descriptor `ctime`; unlinking the old inode changes `ctime` even though its opened bytes remain valid. |
| V14-R2 `agent-runs3/Orion_Nova` | The second historical v13 pass also runs 27/28 and fails the same atomic-replacement invariant for the same independent `ctime` overcheck. |

The two replay failures are not caused by a new public requirement or a new
semantic discriminator. Version 13's official observed result remains 2/10,
but the old watcher sometimes missed the narrow descriptor phase and allowed
both `ctime`-checking implementations to pass. Serializing the memory-heavy
watchers made that pre-existing false positive visible. The reference atomic
entity passed five consecutive exact-image repetitions after the canonical
28/28 run.

No new test was added for a pathname “type change after open.” An opened
regular inode cannot change filesystem type, while replacing its pathname is
the explicitly allowed verified-snapshot case. The public contract therefore
requires regular type at open and separately checks size, mode, and
modification metadata through snapshot completion.

### Validation, reporting, and verdict

| Artifact state | Exact result |
|---|---:|
| Reference, network-disabled Linux `base` | 474 passed, 0 skipped |
| Reference, network-disabled Linux `new` | 28 passed, 0 failures, 0 errors, 0 skips |
| Reference, macOS `new` | 23 passed |
| Test patch only, Linux `new` | exits 101 at the absent solution-owned controller; one skipped synthetic `new.run` contains the XML-escaped compiler diagnostic |
| Forced missing-toolchain wrapper trial | exits 1; fallback JUnit contains the exact toolchain diagnostic instead of only a numeric status |

The fallback remains skipped in the test-only state so a compile-time absence
does not create an entity that exists in neither the p2p nor f2p set. Once the
reference is present, nextest supplies the real 28-entity JUnit and there are
no failures, errors, or skips.

Every actionable version-14 mutant was killed by one distinct public boundary;
no mutant reached the full-suite survivor stage. The reference complete suite
is green. Version 14 clears the exact false-positive gate and may begin a new
immutable calibration batch only after rereading the calibration protocol. It
starts at 0/10; the v13 2/10 result and all replays are historical evidence,
not carried runs.

## Canonical version 13 exact audit

Version 13 removes the redundant final Test Assumptions sentence that repeated
the strict schema, version, ordering, metadata, and digest requirements already
stated in the schema paragraph. The prompt hash is
`a820a076e28b7a9129a40d47a670ebb68a5ce4a12699eccaf007d3fc0989aa22`.
The base, `test.patch`, `solution.patch`, `solution_approach.md`, Dockerfile,
and Linux image are byte-identical to version 12.

The requirement-to-oracle map was repeated against the shortened prompt.
Strict parsing, unsupported-version rejection, normalized unique ordering,
directory metadata, file digests, and malformed-record rejection remain
explicit participant-facing requirements and retain their existing behavioral
oracles. The supplied legitimate pass and repaired near-pass both implemented
these rules without relying uniquely on the deleted repetition. No test is
added, removed, or weakened.

The plausible-mutant ledger is unchanged. In particular, the old reference
still survives or fails the same snapshot entity according to scheduling, so
the actionable timing survivor remains open. This prompt cleanup resets the
immutable version to calibration 0/10 but does not authorize calibration or
submission.

## Canonical version 12 exact audit

### Immutable problem version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `210c0849e50feb2ddb9ece2c63f80a38c026f5a9376c4c45fc2df9d92ec7f7be` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `be78e955fb5ccaf40357b6921c4253f32b00ec2d6b74d1cda6a3f8ec38fd2340` |
| `solution_approach.md` | `05ef56f662047b1c1f5f200540cd44d274bc17f14a7d804e46125591c96cf8e9` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |

### Trigger and requirement map

The external verifier reported one reference failure in the Linux
same-size snapshot entity. Five exact local runs of the old reference passed,
showing schedule sensitivity. The public contract now defines the interval
from descriptor opening through snapshot completion. All version-11
requirement-to-oracle rows remain unchanged except that the snapshot row maps
to this clarified interval.

### Executed trials

The version-12 reference captures metadata before opening, reads and digests
the descriptor bytes, then takes final descriptor metadata. The exact race
passed 20 consecutive image repetitions. The complete reference lanes are
474/474 Linux base, 24/24 Linux new, and 21/21 macOS new. The persisted Linux
new JUnit contains 24 testcases, `failures="0"`, `errors="0"`, and no
`<skipped>` element.

A pre-open-only mutant removed every final descriptor check. It compiled and
the existing immediate entity rejected it. A proposed 10 ms late-write branch
also rejected it, adding no distinct discriminator, so the branch was removed
under the anti-duplication rule.

The old version-11 reference remains an actionable scheduling survivor: it
takes final metadata before digesting, passed five local exact-image
repetitions, and failed the externally reported run. The current hidden test
therefore does not classify that plausible incorrect implementation
deterministically. No artificial hook, exact syscall sequence, timing
threshold, or descriptor-offset requirement was added merely to force a
stable failure.

### Verdict

Reference correctness and wrapper accounting pass. False-positive closure
does not: version 12 remains at 0/10 and is not approved to begin calibration
or submission until this survivor is resolved fairly or the temporal
discriminator is removed.

## Historical canonical version 11 exact audit

### Immutable problem version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `55df6607e9a306939ec5a6b51b7da24aa8c87bcc32d82b4f6531d9460665d577` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c` |
| `solution_approach.md` | `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Version 11 removes only the sentence explaining the linked-parent,
explicit-project, and environment consequences of ordinary upload root
resolution. The preceding participant-facing requirement still says planning
must use ordinary upload source selection and local source-root resolution.
The source-root process oracle therefore remains a direct black-box test of
the public contract, not an orphaned or private requirement.

The complete requirement-to-oracle map, executable mutation trials,
participant-patch replays, rejected artificial additions, and census in the
historical version-10 audit below were re-evaluated against the shorter
prompt. Every row remains supported. The executable artifacts are
byte-identical, so their exact results are unchanged: reference 474/474 base,
21/21 macOS new, and 24/24 network-disabled Linux new; the two recent
participant architectures remain 23/24 and the earlier near-pass remains
21/24. No plausible incorrect implementation survives the attempted set, and
no test depends solely on the removed explanation.

This prompt-only revision resets calibration to 0/10. It approves version 11
to begin calibration, not for submission.

## Historical canonical version 10 exact audit

### Immutable problem version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `96ff6ae0eb5c125f0b643a94f67e901e4d25c27488d8b314b5421bb082c93e9b` |
| `test.patch` | `440e3c1c6e7f7a48988f192650bbd272d554d95abf8df280438af4fe3b8e928c` |
| `solution.patch` | `135c2aef81648d28c7414af6fdc0b4a50e12b6876aa1465174e745dcf0770b0c` |
| `solution_approach.md` | `e659d30558fa1548f62b7c04035c7eefe95c3d69b8c1b8b874f198eac94b469b` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently, together in either order, and reverse-check
from the combined tree. The applied tree passes `cargo fmt --check` and
`git diff --check`. The reference patch has 720 additions and 96 deletions,
or 624 strict effective production additions across six files, with no new
dependency.

### Trigger, trajectories, and environment classification

Both `agent-runs2` Nova runs are legitimate complete version-9 solves: each
passes 474/474 upstream tests and 23/23 old grader tests. Their raw trajectory
step streams, patches, workspace diffs, logs, and JUnit files were inspected.
Missing `rg`, broad `find` warnings, and wrapper conflict recovery were
non-blocking; neither result is an environment failure. A 2/2 frontier solve
signal therefore required hardening.

Both implementations independently read an opened descriptor into memory,
compare only type, size, and Unix mode before and after the read, and then
derive the digest. A same-size in-place rewrite can change bytes and mtime
without changing those three observations. The new Linux probe replaces the
old truncation probe with that stronger branch of the same coherent-snapshot
requirement.

The trajectories also traced updater, telemetry, advisory, refresh, and
ordinary root-selection paths. Version 9's process fixture disabled all of
those auxiliary network sources, so it did not enforce the public
unconditional offline guarantee. Version 10 removes those opt-outs for write,
malformed apply, and changed-source apply. A separate public CLI entity covers
the ordinary linked-parent versus explicit-project local-root branches.

The initial version-10 Linux command mounted source read-only. All 474 base
tests passed, but nextest exited 110 while attempting to write
`/src/target/nextest/default/junit.xml`; consequently the chained grader lane
did not start. Re-running with only the JUnit destination writable produced
the authoritative 24/24 result. This was a verifier mount defect, not a
reference or dependency failure. A second prototype briefly compared ctime as
well as mtime; Linux atomic pathname replacement legitimately changes the old
inode's ctime, so that overbroad check conflicted with the verified-descriptor
oracle. The final requirement and implementation use modification time only.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-10 behavioral oracle |
|---|---|
| Deterministic, self-excluding offline write with no auxiliary requests | `deployment_plan_write_is_offline_deterministic_and_self_excluding` runs twice without CI, tracking, updater, or telemetry opt-outs, compares bytes and entries, and requires zero proxy connections. |
| Ordinary local-root resolution | `deployment_plan_cli_source_root_matches_link_and_explicit_project_resolution` writes from a linked child, then with explicit `--project` and no environment, and inspects the public manifests. |
| Strict deterministic schema | The serialization, parser, invalid-record, directory-metadata, and unsafe-path entities cover version, fields, controls, order, uniqueness, kinds, sizes, digests, modes, and relative normalized paths. |
| Ordinary selection and archive identity | Default, alternate-ignore, prefix/path-as-root, followed-link, broken-link, non-UTF-8, and mode fixtures compare the declared plan/archive behavior with ordinary upload without requiring tar stream order. |
| Saved-plan reconciliation | Added/removed/renamed, type/size, same-size content, option, and Unix-mode entities require local refusal. |
| One coherent regular-file planning snapshot | Linux `deployment_plan_creation_rejects_a_file_changed_during_snapshot` observes the opened descriptor, performs a 4 MiB in-place write inside a 128 MiB file, proves size and mode stayed equal while mtime changed, and requires refusal. |
| Verified bytes become archive bytes | Linux `deployment_plan_archive_uses_the_verified_snapshot_after_atomic_replacement` replaces the pathname after the verified descriptor opens and requires the old verified bytes in the archive. |
| Every local failure precedes every request | Malformed-plan and changed-content CLI entities run with ordinary auxiliary-network defaults and require zero proxy connections. |
| Successful verification continues | The valid apply entity retains opt-outs so a background request cannot satisfy it, and requires any positive post-verification request. |
| Public conflicts | Three spawned conflicting invocations require parser exit status 2 and zero connections. |

### Exact mutation and architecture trials

Nine actionable modes were executed against the exact version-10 tests.
M1-M6 are isolated reference mutations. M7-M9 are independently implemented
participant architectures and therefore provide stronger diversity than more
synthetic edits.

| Mutant | Plausibility and exact result |
|---|---|
| V10-M1 omit regular-file digest comparison | Metadata-only reconciliation compiled and failed only the same-size content-change probe used for this trial. |
| V10-M2 verify buffered bytes, then reopen the pathname for tar input | Delegation to the existing pathname archive API compiled and failed the Linux atomic-replacement payload assertion. |
| V10-M3 return success immediately after local verified-archive creation | A local-only apply compiled and failed the valid-apply continuation process probe. |
| V10-M4 accept unknown JSON fields | Removing serde's strict-field attributes compiled and failed the strict reader probe. |
| V10-M5 record `noGitignore` but always collect with Git ignores enabled | The selector shortcut compiled and failed the alternate-ignore parity probe. |
| V10-M6 suppress refresh but leave the background updater enabled | Removing only the local-plan read-only classification compiled; two writes made two proxy connections and failed the unconditional offline probe. |
| V10-M7 `agent-runs2/Nova_Nova_1` | Independent flate2/archive implementation passes 474/474 base with 11 task tests excluded and 23/24 grader tests; only same-size in-read modification is accepted. |
| V10-M8 `agent-runs2/Nova_Nova_2` | Independent gzp/buffered implementation passes 474/474 base with 7 task tests excluded and 23/24 grader tests; only the same coherent-snapshot branch fails. |
| V10-M9 earlier `agent-runs/Nova_Nova_2` near-pass | Passes 474/474 base with 13 task tests excluded and 21/24 grader tests. It misses the strengthened snapshot probe and the already-isolated root family: the prefix entity and new public explicit-project entity report that same root omission. |

The remaining version-9 mutation deltas were re-inspected against the exact
version-10 source. Their public oracles—self-exclusion, flag conflicts,
directory schema, unsafe paths, Unix-mode reconciliation, persisted controls,
and malformed-plan-before-request—are retained unchanged or strengthened.
No survivor arose from the revised boundaries. The exact executable sample
spans content, temporal archive consumption, remote continuation, schema,
selection, effects ordering, and three independent full implementations.

### Rejected or artificial additions

No test was added for atomic plan publication, rollback, exact tar sequence,
gzip bytes, compression choice, uid/gid/mtime archive headers, exact error
text, proxy call multiplicity, another ignore filename, or more path spellings.
Atomic destination publication would duplicate the separate 3D Tiles problem.
Memory limits would unfairly privilege the reference's buffer lifetime over
the legitimate all-payload planning strategy. The final mtime check deliberately
does not reject an atomic pathname replacement merely because unlinking the
old inode changes ctime.

### Exact validation and census

| Artifact state | Result |
|---|---:|
| Test patch only, network-disabled Linux `base` | 474 passed |
| Test patch only, Linux `new` | exits 101 at the absent declared API; fallback JUnit has one skipped `new.run`, zero failures, zero errors |
| Reference, macOS `base` | 474 passed |
| Reference, macOS `new` | 21 passed |
| Reference, network-disabled Linux `base` | 474 passed |
| Reference, network-disabled Linux `new` | 24 passed |
| `agent-runs2` Run 1, network-disabled Linux `base` / `new` | 474 passed / 23 passed, 1 failed |
| `agent-runs2` Run 2, network-disabled Linux `base` / `new` | 474 passed / 23 passed, 1 failed |
| Earlier near-pass, network-disabled Linux `base` / `new` | 474 passed / 21 passed, 3 failed across two semantic families |

The authoritative wrapper census is 474 p2p, 24 f2p, one skipped synthetic
fallback, and no unclassified entity. The attempted exact mutation set has no
actionable survivor. Version 10 is approved to begin a fresh immutable
calibration batch, but no version-9 solve or replay carries forward:
calibration is exactly 0/10 and the problem is not submission-ready.

## Historical canonical version 9 exact audit

### Immutable problem version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `bc682a86ed12764b43e6251586a62e4dd8366ad126c1828448aadb9f776c50c1` |
| `test.patch` | `26a8751b9ddf9abccf1975e0cde75db436807914d87482308ade93b2de56b741` |
| `solution.patch` | `be61c9cad6bb3c1c478ed1141d84e1418e63c7b65783b3fb78e4007137cc5c59` |
| `solution_approach.md` | `70ee500b728e09d24aae9655da168f324dc37b0d0cf813bb8042141ba9a30302` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Linux image | arm64 `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both canonical patches apply independently to the pinned base, apply together
in either order, pass `git diff --check`, and reverse-check from the combined
tree. `test.patch` no longer modifies `src/controllers/mod.rs`, so it applies
after both supplied participant patches without overwriting their required
`pub mod deploy_plan` export.

### Trigger and trajectory evidence

The two supplied Nova evaluations failed before testing because the wrapper's
merge fallback reset `src/controllers/mod.rs` to the test-patch state and
deleted each participant's module export. Corrected additive replays of
version 8 produced 21/21 for Run 1 and 14/21 for Run 2. The latter's seven
reported failures mostly repeated one omitted-root defect, and two fixtures
panicked because they assumed generated entry indices.

Both raw trajectories were inspected. Run 1 shared one source collector and
buffered descriptor-backed file content; Run 2 used an independent scanner and
explicit archive builder. Both correctly handled strict JSON, local-before-auth
flow, verified apply bytes, self-exclusion, and link/mode behavior. Run 1 still
accepted a file changed while its plan snapshot was being read. Run 2 included
a length-stability check but omitted the selected root directory. Those
independent misses became the new snapshot-formation and isolated source-root
oracles. Extra ignore names, path spellings, tar order, error prose, and network
call counts were rejected as repeated or artificial discriminators.

Both participants also added useful self-tests. Version-8 base mode would make
those post-agent-only entities unclassifiable, just as it previously did with
reference-only tests. Version 9 base mode excludes task-owned names containing
`deploy_plan`, `deployment_plan`, or `up_plan` in both runner paths. Nextest
enumerates zero such tests in the pinned 474-test baseline, 11 in Run 1, and 13
in Run 2. The repaired base lane therefore retains every upstream regression
while not penalizing solver-authored tests.

### Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest version-9 behavioral oracle |
|---|---|
| Offline, deterministic, self-excluding plan write | `deployment_plan_write_is_offline_deterministic_and_self_excluding` performs two fresh-process writes with expired isolated OAuth state, compares exact bytes, checks plan absence, and observes zero connections. |
| Strict deterministic schema and persisted controls | The serialization, parser, invalid-record, and unsafe-path entities check ordering, version, unknown fields, digest/directory shape, non-default controls, and normalized relative paths. |
| Ordinary source identity, including the selected root | `deployment_plan_service_prefix_and_path_as_root_modes_are_preserved` is the one exact root/prefix oracle. Other parity fixtures ignore only the already-isolated root while retaining file, non-root directory, ignore, link, and payload equality. |
| Ordinary ignore and followed-link behavior | The default, `--no-gitignore`, followed-link, broken-link, and non-UTF-8 entities cover independent selector and identity boundaries without repeating root failure. |
| Saved-plan reconciliation | Added/removed/renamed, type/size, same-size content, invocation-option, and Unix-mode entities require refusal through the declared controller seam. |
| One coherent regular-file plan snapshot | Linux `deployment_plan_creation_rejects_a_file_changed_during_snapshot` observes the opened descriptor, truncates and rewrites the same inode during the read, proves the mutation occurred, and requires planning to fail. |
| Verified bytes become archive bytes | Linux `deployment_plan_archive_uses_the_verified_snapshot_after_atomic_replacement` replaces the pathname after the verified descriptor opens and requires the archived payload to remain the verified bytes. |
| Every local failure precedes authentication/network | The malformed-plan and changed-content process entities use expired OAuth state and a counting proxy and require zero connections. |
| Successful verification continues remotely | The valid process entity requires any positive post-verification connection, with no exact call count. |
| Public flag conflicts | Three spawned conflicting invocations exit through parser status 2 and make no request. |

The malformed-record fixtures now create an explicit directory and locate file
entries by kind. They do not index a root-dependent generated layout. Run 2
therefore fails exactly one root-identity entity rather than cascading into
unrelated schema failures or panics.

### Exact mutation trials

Fourteen plausible incorrect modes compiled against this version. M1-M12 were
isolated mutations of the reference tree. M13 and M14 are the supplied
participant patches replayed under the repaired harness, which provides
stronger architecture diversity than another synthetic edit.

| Mutant | Plausibility and exact result |
|---|---|
| V9-M1 omit regular-file digest comparison | A metadata-only apply is the cheapest shallow verifier. It fails the same-size content-change entity. |
| V9-M2 verify buffered bytes, then reopen the pathname for tar input | Delegating archive creation back to the pathname is a natural integration shortcut. It fails the Linux atomic-replacement payload assertion. |
| V9-M3 return success immediately after local verified-archive creation | Planning/apply can be implemented as a local no-op. It fails the valid-apply continuation process oracle. |
| V9-M4 include the existing plan output during a rewrite | First write succeeds and hides the defect. The second process write differs and the self-exclusion entity fails. |
| V9-M5 accept unknown JSON fields | Default serde behavior is permissive. The strict reader entity accepts the injected field and fails. |
| V9-M6 omit parser-level plan-flag conflicts | The binary accepts and executes a conflicting invocation; the public conflict entity fails. |
| V9-M7 omit directory-specific size/digest validation | Reusing file validation for every entry kind is plausible. The explicit-directory serializer mutation is accepted and the schema entity fails. |
| V9-M8 accept absolute and parent-traversal archive paths | UTF-8 and ordering checks alone are insufficient. The reader accepts the representative unsafe paths and fails. |
| V9-M9 refresh OAuth before reading a `--from-plan` document | A solver can defer content reconciliation but leave parsing after refresh. The malformed-plan process makes one connection and fails the zero-request oracle. |
| V9-M10 omit Unix-mode comparison from both reconciliation layers | Preserving mode without checking drift is a natural partial implementation. The changed file/directory mode entity reaches success and fails. |
| V9-M11 hard-code top-level invocation controls | A serializer can persist defaults while runtime behavior appears correct. The non-default JSON assertions fail. |
| V9-M12 ignore `no_gitignore` during collection | Recording the option without selector plumbing excludes `git-ignored.txt`; the alternate-mode parity entity fails. |
| V9-M13 supplied Run 1 architecture without in-read stability validation | It passes all 474 upstream regressions after 11 task self-tests are excluded and passes 22/23 grader entities. Only coherent plan-snapshot formation fails. |
| V9-M14 supplied Run 2 architecture without the selected root entry | It passes all 474 upstream regressions after 13 task self-tests are excluded and passes 22/23 grader entities. Only the isolated root/prefix identity entity fails. |

Every synthetic mutant failed its strongest focused entity; no synthetic
survivor passed the complete grader. The two independently implemented
trajectory patches passed the complete pre-existing suite and all but one
grader entity each, then failed different public boundaries. No new test was
added for their private types, helper names, error strings, self-test names, or
tar order.

### Exact validation and census

| Artifact state | Result |
|---|---:|
| Test patch only, Linux `base` | 474 passed |
| Test patch only, Linux `new` | exits 101 at the absent solution API; fallback JUnit contains one skipped `new.run`, zero failures, zero errors |
| Reference, macOS `base` | 474 passed |
| Reference, macOS `new` | 20 passed |
| Reference, network-disabled Linux `base` | 474 passed |
| Reference, network-disabled Linux `new` | 23 passed |
| Run 1 replay, network-disabled Linux `base` | 474 passed; 11 task-owned self-tests excluded |
| Run 1 replay, network-disabled Linux `new` | 22 passed, 1 failed at snapshot formation |
| Run 2 replay, network-disabled Linux `base` | 474 passed; 13 task-owned self-tests excluded |
| Run 2 replay, network-disabled Linux `new` | 22 passed, 1 failed at root identity |

The authoritative reference wrapper census is 474 p2p, 23 f2p, one skipped
synthetic placeholder, and no unclassified entity. The two official run
results remain invalid environment failures and are not calibration. The
corrected replays are design and false-positive evidence only. Because version
9 changes prompt, grader, reference behavior, and explanation, calibration is
exactly 0/10 and no version-8 result carries forward.

## Historical canonical version 8 audit

## Immutable problem version

| Artifact | SHA-256 / identity |
|---|---|
| Railway base | `4d49d9845a27a0947ab903b01789eb9f854414d8` |
| `meta.md` | `05d61e4f9e1f207e8b08fbee86dfb811cfc07abf780bc4504fb467aa818b5935` |
| `test.patch` | `cd51d0d25782d0eb17c50bf57c7d4bc8d45250240bb43fadab587ba0157f21d2` |
| `solution.patch` | `3b1b56bdafa4b977627b41e97358b9cda0ea963c67bcaa2ee72b48d13c532bcc` |
| `solution_approach.md` | `d2f4839bb27af55191636345fabd90c2378fc10d80a46e3fbadd176db2cec0f0` |
| `Dockerfile` | `6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a` |
| Built Linux image | arm64 image ID `sha256:a159458d83e4feda25125fa9a78a45b7c60c171087b302d44181af803152cd63` |

Both patches apply independently to the pinned base, apply together in either
required order, pass `git diff --check`, and reverse-check cleanly from the
combined tree. Any change to a listed artifact invalidates this audit and
restarts calibration at 0/10.

## Evidence and method

The audit followed the worked procedure in
`problems/statig-local-transitions/false_postive trials.md`. It reused the
trajectory search and discriminator ledger already recorded in `DESIGN.md`,
then constructed shortcuts from Railway's collector/archive architecture, the
rejected 81-line immediate preview, the persisted-plan prototypes, and the
cross-cutting authentication path.

This exact audit was repeated after reviewer feedback added the declared
`controllers::deploy_plan` test seam to the prompt, removed all grader
dependencies on error-message substrings, and prefixed every grader function
with `deployment_plan_`. Both nextest and the cargo fallback enumerate all 19
macOS grader entities directly; the Linux lane enumerates 21.

It was repeated again after the prompt-only follow-up removed the names of the
existing upload helper and refresh-classification helper. Those deletions
changed no public behavior, grader byte, reference byte, or discriminator, but
created the prompt hash above.

The first 2026-07-27 grader revision removed the redundant complete-plan equality
assertion and the unit module that called private CLI helpers. It replaced
those helper assertions with spawned-process conflict checks and strengthened
the write/invalid-apply processes with isolated expired OAuth state, so an
eager top-level refresh is observable at the counting proxy. The exact
test-only, reference, Linux, patch-order, and mutation gates were repeated for
that test hash.

The next revision removed a redundant valid-success sentence from the prompt
and relaxed the valid-apply process oracle from two connections to any
positive connection count. It no longer assumes separate OAuth-refresh and
GraphQL requests. The old missing-refresh mutant is therefore artificial and
was removed. A valid-apply no-op replacement checks the narrower public
continuation boundary.

The preceding revision added direct schema-boundary coverage for persisted
top-level controls, directory record shape, malformed directory metadata, and
unsafe relative-archive paths. It also replaces the valid but
reviewer-confusing nextest expression `test(~deployment_plan_)` with its
equivalent default-contains form `test(deployment_plan_)`. In the current
replay, all 14 mutants failed an isolated focused probe; the
verify-then-reopen mutant also passed the complete 474-test host base suite
before failing its Linux atomic-replacement probe.

The version 7 revision changed only harness accounting and process fixtures. A
test-only `new` run still exits 101 when the declared solution API is absent,
but its synthetic fallback testcase is now skipped rather than reported as a
failure that disappears from the reference census. The offline write process
uses no remote selector. The invalid-apply process uses both project and
environment, proving that its failure is reconciliation-specific instead of
the pre-existing unpaired-selector validation. All 14 mutants were replayed
against this exact test hash. The eager-refresh mutant made two proxy requests
and failed the revised invalid-apply zero-request assertion.

The exact current revision removes nine reference-only self-tests from
`solution.patch` and makes four decoded tar-path comparisons
order-independent. Ordinary upload appends `ignore::WalkBuilder` results
without a documented sort, so exact tar member sequence is an artificial
constraint; plan JSON ordering remains exact. Removing the self-tests changes
no production behavior and makes the wrapper entity universe classifiable.
The resulting exact census is 474 common p2p entities, 21 Linux f2p grader
entities, one skipped synthetic fallback, and no unclassified entity. All 14
mutants below were replayed against the new patch hashes.

There are no Railway solver trajectories or participant patches to replay.
The available legitimate pass, near-pass, and shortcut evidence remains the
3D Tiles, Calyx, and RustPBX records named in `DESIGN.md`. The three Railway
prototype patches were treated as implementation predecessors, not as solver
runs.

## Requirement-to-strongest-oracle map

| Participant-facing requirement | Strongest exact-version behavioral test |
|---|---|
| `--write-plan` is offline | `deployment_plan_write_is_offline_deterministic_and_self_excluding` runs the binary with expired isolated OAuth state behind a counting proxy and requires zero connections. |
| Rewriting an in-tree plan is byte-identical and excludes itself | The same fresh-process test writes twice, compares exact JSON bytes, and confirms `plan.json` is absent from entries. |
| Planning uses ordinary source selection | `deployment_plan_default_selection_matches_ordinary_upload`, `deployment_plan_no_gitignore_keeps_railwayignore_and_builtin_exclusions`, `deployment_plan_service_prefix_and_path_as_root_modes_are_preserved`, and the followed-link parity test decode and compare archives. |
| JSON is strict, versioned, normalized, uniquely sorted, and well formed | The deterministic, unknown-field/version, unsorted/duplicate/invalid-record, and Linux non-UTF-8 tests exercise separate format boundaries. |
| Top-level controls are persisted with their actual values | `deployment_plan_serialization_is_byte_deterministic_and_sorted` serializes non-default settings and inspects `pathAsRoot=false` and `noGitignore=true` in the public JSON object. |
| The declared new controller API remains available | All controller grader entities compile through `controllers::deploy_plan`; ordinary-upload parity is checked behaviorally by comparing selected archive contents. No complete-plan equality or convenience trait is required by the grader. |
| Entries record upload-relevant bytes and metadata | `deployment_plan_verified_archive_uses_plan_paths_bytes_and_hashes` compares plan paths, sizes, SHA-256 values, and decoded archive bytes; the deterministic schema test requires generated directories to have size zero and no digest; the Unix mode test checks file and directory headers. |
| Directory records reject file-only metadata | `deployment_plan_parser_rejects_unsorted_duplicate_and_invalid_entry_records` and `deployment_plan_reader_rejects_directory_metadata_and_unsafe_paths` reject both directory digests and nonzero directory sizes through the two declared format boundaries. |
| Plan paths are normalized relative archive paths | `deployment_plan_reader_rejects_directory_metadata_and_unsafe_paths` rejects representative absolute and parent-traversal paths. |
| Added, removed, renamed, type-changed, or size-changed inputs fail | `deployment_plan_added_removed_and_renamed_inputs_are_rejected` and `deployment_plan_type_and_size_changes_are_rejected`. |
| Equal-size content changes fail | `deployment_plan_same_size_content_change_is_rejected` plus the spawned invalid-apply test. |
| Invocation controls must agree with the saved plan | `deployment_plan_invocation_option_mismatches_are_rejected`. |
| Broken links and unsupported identities fail consistently | `deployment_plan_broken_followed_links_are_rejected_in_both_modes` and `deployment_plan_non_utf8_archive_paths_are_rejected`. |
| Verified bytes, not a reopened pathname, become archive input | Linux `deployment_plan_archive_uses_the_verified_snapshot_after_atomic_replacement` swaps the path after the verified descriptor opens and checks the archived bytes. |
| Invalid apply finishes before authentication or a request | `deployment_plan_invalid_apply_fails_before_any_request` supplies expired isolated OAuth state and observes zero proxy connections through the real binary. |
| Successful reconciliation continues beyond local verification | `deployment_plan_valid_apply_continues_after_local_verification` supplies an isolated expired OAuth config and requires at least one counted connection, without prescribing authentication or transport call count. |
| Plan flags conflict with each other and `--new` | `deployment_plan_flag_conflicts_are_rejected_by_public_cli` checks exit status 2 from three spawned public invocations. |

The grader contains 19 named entities on macOS and 21 on Linux. The two
Linux-only entities cover non-UTF-8 path identity and exact snapshot
consumption; neither has a platform-independent equivalent.

## Mutation trials and isolation

All listed mutations compiled. Each actionable mutant changes a plausible
implementation mode, violates a public clause, and is rejected by a distinct
behavioral observation.

| Mutant | Plausibility | Exact result |
|---|---|---|
| M1 omit the digest comparison while retaining path/type/size checks | Metadata-only freshness is the cheapest shallow implementation. | The same-size controller rejection assertion fails without relying on error prose. |
| M2 verify one snapshot but reopen the pathname for tar input | A solver can validate correctly and still delegate packaging to the old path reader. | The complete 474-test host base suite survives; the Linux atomic-replacement entity fails its archived-byte assertion. |
| M3 return immediately after producing a valid verified archive | A solver can implement planning and reconciliation correctly but turn valid `--from-plan` into a local no-op. | The spawned valid-apply process completes without network continuation and fails the public process probe. |
| M4 coerce non-UTF-8 components with `to_string_lossy` | Persisting paths as `String` invites lossy conversion. | The Linux identity test receives success instead of a refusal and fails. |
| M5 omit Unix-mode checks in both reconciliation layers | Mode preservation is easy to implement without mode reconciliation. | The changed-mode fixture reaches archive success and fails the refusal assertion. |
| M6 persist `noGitignore` but always collect with Git ignores enabled | Option recording without selector plumbing is a natural defect. | The alternate-mode parity test cannot find `git-ignored.txt`. |
| M7 always use the selected project path as archive prefix | Correct files can be selected while workspace/service archive identity is lost. | The prefix test receives `.` / `app.txt` instead of `services/api/...`. |
| M8 omit plan-path exclusion only while writing | A first write succeeds, hiding the temporal defect. | The second fresh-process write includes `plan.json`; exact-byte equality fails. |
| M9 leave plan modes in top-level eager-refresh classification | The original prototype inherited this ordering. | The paired-selector invalid-apply process attempts two proxy connections before local reconciliation and fails the zero-request assertion. |
| M10 accept unknown top-level JSON fields | Serde's default permissiveness is an easy shortcut. | The strict-parser entity receives a valid plan and fails its refusal assertion. |
| M11 omit the public flag-conflict declarations | A solver can add both options without wiring parser-level conflicts. | The spawned binary accepts a conflicting invocation instead of exiting with status 2. |
| M12 hard-code `pathAsRoot=true` and `noGitignore=false` during serialization | A solver can honor invocation controls in memory but persist defaults in the interchange artifact. | The non-default JSON field assertions observe the wrong values. |
| M13 omit directory-specific metadata validation | Reusing regular-file record validation for all entry kinds is a natural schema shortcut. | The invalid-entry serializer accepts a directory digest instead of refusing it. |
| M14 accept absolute and parent-traversal plan paths | Sorting and UTF-8 validation alone do not make an archive path safe or relative. | The reader accepts `/absolute` or `../escape` and fails the unsafe-path refusal test. |

One partial M5 mutation removed only the later metadata comparison and passed
all host grader entities. It was rejected as non-actionable because the
earlier ordered-selection comparison still checked directory mode and the
public behavior remained correct. Removing directory-mode checks from both
independent implementation layers produced the meaningful mutant above and
was killed by the existing probe; no duplicate fixture was added.

The relaxed network-count oracle did not create an actionable survivor: M1,
M3, and M5-M14 failed their isolated host probes, while M2 and M4 compiled
against the exact Linux source/image environment and failed their isolated
platform probes. M2 passed the complete 474-test host base suite first.

A prior positive compatibility replay removed `Debug`, `PartialEq`, and `Eq`
from `DeployPlan` and its entry type, then removed only the reference
implementation's own private uses of those traits. All 18 then-current host
grader entities passed. The schema revision observes only public fields and
serialized bytes, so the hidden suite still imposes none of those undocumented
convenience bounds.

## Rejected and artificial mutants

No test was added for byte-identical gzip streams, tar member sequence,
timestamps, compression thread count, helper names, in-memory plan
representation, or tar-builder choice; those are not public. Link target
identity with identical bytes and
metadata was rejected because ordinary Railway upload also follows links and
the payload is unchanged. Additional malformed UTF-8 values, path spelling
permutations, ignore filenames, and arbitrary mode bits repeat existing
families. Canonical bundles, signatures, caches, remote deduplication,
rollback, atomic destination publication, and Windows-specific permission
semantics remain out of scope.

The prior missing-refresh mutant is also rejected as artificial for this
version. One post-verification request may be a conforming authenticated
transport; requiring a separate refresh request would restore the private call
count that this revision removes.

## Exact reference validation

| Check | Result |
|---|---:|
| Test patch on pinned base, `base` | 474 passed |
| Test patch on pinned base, `new` | exits 101 at missing `controllers::deploy_plan`; fallback JUnit has one skipped `new.run`, zero failures, and zero errors |
| Combined patches, macOS `base` | 474 passed |
| Combined patches, macOS `new` | 19 passed |
| Final Docker image build | pass with Rust 1.88.0 and cargo-nextest 0.9.100 |
| Final image, network disabled, `base` | 474 passed; JUnit reports 474/0 |
| Final image, network disabled, `new` | 21 passed; JUnit reports 21/0 |
| Format, patch whitespace, apply/reverse checks | pass |

The repeated Linux reference `new` run completed successfully; the
atomic-replacement entity accounted for 6.231 seconds. The
exact reference probe passed and the verify-then-reopen mutant failed directly.

## Conclusion

The attempted 14-mutant set has no actionable survivor. The grader now
distinguishes persistence, selector parity, strict format, source
reconciliation, top-level control persistence, directory-record validity,
relative path safety, content and Unix metadata integrity, exact snapshot
consumption, and both sides of the validation/auth/network ordering boundary
without pinning reference error prose, convenience traits, or internal CLI
helpers. The reusable controller seam required by the grader is explicitly
declared in the prompt; existing upload and refresh helpers are intentionally
not named.

Residual risk remains because no Railway solver trajectory, private submission
archive, or patched Windows run is available. Those facts must be carried into
review and calibration; they do not justify implementation-specific tests.
