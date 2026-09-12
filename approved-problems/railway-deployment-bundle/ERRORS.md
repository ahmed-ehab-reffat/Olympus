# Resolved findings and residual risks

## Version-31 external verifier synthesized a stricter reference probe

The version-30 bundle passed its 474 baseline and 24 visible Linux focused
tests, but an external solution verifier synthesized additional
snapshot/atomic-replacement failures. Its useful code finding was that
`read_file_snapshot` never compared the followed pathname after reading with
the object held by the descriptor.

Restoring the removed libc-`read(2)` hidden tests would repeat the fairness
failure. Version 31 instead hardens only the reference with Unix device/inode
identity checks before open and after read. The prompt and tests remain
unchanged. Removing the new check still passes 23/23 focused tests, while a
temporary reference probe distinguishes same-size replacement and accepts a
stable followed link. The stronger reference therefore addresses synthesized
solution analysis without prescribing one I/O mechanism to candidates.

One attempted replay from a reused worktree was excluded because its source
contained the plan flags while its stale built CLI rejected them. The
authoritative identity-free replay was isolated in the already verified
worktree and rebuilt from the exact source.

## Resolved during canonical packaging

### Agent runs were destroyed by the grader merge fallback

Both supplied official runs failed before tests because `test.patch` and both
participant patches edited `src/controllers/mod.rs`. The wrapper's merge
fallback restored the grader-owned version of that file and deleted the
participant's required `pub mod deploy_plan` export. The resulting unresolved
import made every reported behavioral failure synthetic.

Version 9 declares the feature-gated grader from `src/consts.rs` and imports
the controller through the crate root. The test patch no longer owns
`src/controllers/mod.rs`; it applies directly after both supplied patches.
Corrected replays reach all real tests.

### Solver-authored self-tests polluted wrapper accounting

Both agents added relevant unit tests. Base mode would execute those
post-agent-only entities, which belong to neither the pinned regression set nor
the grader fail-to-pass set. Version 9 excludes task-owned names containing
`deploy_plan`, `deployment_plan`, or `up_plan` from base mode in both nextest
and cargo fallback paths. The pinned baseline contains zero matches, while the
filter excludes 11 Run-1 and 13 Run-2 self-tests. All 474 upstream regressions
still run and pass for the reference and both replays.

### One root defect cascaded into seven apparent failures

Run 2 omitted the selected root directory. Four parity checks repeated that
same mismatch, while two schema fixtures panicked on assumed entry indices.
Version 9 keeps one exact root/prefix oracle, ignores only that already-isolated
root in unrelated parity comparisons, creates explicit directory fixtures,
and locates file records by kind. The repaired replay now reports one root
failure and 22 passes rather than seven failures from one cause.

### Planning could mix metadata and content snapshots

Both trajectories captured metadata before reading a regular file but lacked a
general before/after stability guarantee. Version 9 requires each planned
record to describe one coherent descriptor-backed snapshot. The reference
rechecks relevant descriptor metadata and byte length after reading. A
Linux-only `/proc/self/fd` probe changes the same inode during the read:
the reference refuses it, Run 1 accepts it, and Run 2 independently survives
that boundary while failing root identity.

### Grader-facing APIs were not declared

Reviewer feedback correctly found that controller tests compile against
`controllers::deploy_plan` even though the first prompt described only the CLI
contract. The first revision declared the minimal new module, types, and
functions, but briefly also named the existing upload and refresh helpers. A
follow-up prompt-only revision removed those discoverable internals. The
ordinary-upload parity and pre-authentication behavior remain public without
prescribing existing helper names. Redundant source-selection enumeration and
ordinary-mode prose were also removed.

The same review found exact error-message assertions and questioned the
grader-name selector. All message-substring assertions were replaced with
behavioral rejection or process-state checks, and every grader function now
starts with `deployment_plan_`. Nextest and cargo fallback each enumerate all
19 macOS entities directly; Linux enumerates 21. The artifact hashes,
reference validation, Docker image, and mutation audit were regenerated.

### Grader required convenience traits and private CLI helpers

A follow-up review found that whole-plan `assert_eq!` silently required
`Debug`, `PartialEq`, and `Eq`, while a unit module called `build_args` and
`command_needs_refresh`. These were grader conveniences, not participant-facing
requirements. The whole-plan comparison and private-helper module were
removed. Determinism remains byte-exact through `serialize_deploy_plan`, and a
trait-stripped compatible controller passes the focused suite.

Flag conflicts are now checked by spawning the binary and observing Clap exit
status 2. Offline write and invalid apply use expired isolated OAuth state
behind a counting proxy, so premature refresh fails through public process
behavior. The changed grader created canonical version 4; all validation and
the exact-version 11-mutant audit were rerun at calibration 0/10.

### Valid apply continuation initially overfit the request count

The first canonical draft proved zero requests for write and invalid apply, but
tested valid expired-OAuth continuation only with an external prototype
verifier. The missing-refresh mutant passed the full 481-test suite. A
spawned-process grader test then required both deferred refresh and the
ordinary remote request, encoding two connections.

That count was stronger than the public contract. Version 5 keeps the
spawned-process boundary but requires only one or more connections after valid
local verification. It does not distinguish refresh from transport activity.
The redundant success-continuation sentence was also removed from the prompt.
The old one-connection mutant is now rejected as artificial; a valid-apply
local no-op is the actionable continuation mutant. All exact-version gates
were rerun at calibration 0/10.

### Public schema clauses were only indirectly covered

A later review correctly observed that ordinary behavior exercised
`pathAsRoot`, `noGitignore`, directory records, and normalized paths without
directly covering every persisted-schema boundary. Version 6 serializes
non-default control values and inspects their public JSON names and values,
requires generated directories to have size zero and no digest, rejects
directory records carrying a digest or nonzero size, and rejects representative
absolute and parent-traversal paths.

Three plausible mutants isolate those distinct clauses: hard-coded top-level
defaults, missing directory-specific validation, and unsafe path acceptance.
All fail their strongest public probes. The complete exact-version
14-mutant audit and host/Linux reference lanes were rerun at calibration 0/10.

The accompanying nextest warning was not technically correct:
cargo-nextest documents `~string` as a contains matcher, and the old filter
selected every pre-revision grader entity. The runner nevertheless uses the
equivalent `test(deployment_plan_)` spelling now, and cargo-nextest 0.9.100
enumerates all 21 Linux entities.

### Synthetic wrapper failure was not classifiable

When the test patch ran without the solution, compilation failed before
nextest could enumerate the real feature-gated grader. The fallback emitted a
failing synthetic `new.run`, but that name does not exist in the reference
run, so it could be neither regression nor fail-to-pass behavior. The fallback
now emits `new.run` as skipped while preserving exit 101. This is runner
accounting only; all 19 macOS and 21 Linux behavioral tests remain unchanged.

### Offline write used an unfair selector combination

The process fixture supplied `--project` without `--environment`, even though
the existing `up` command requires those selectors together. Offline planning
does not need either selector, so the write test now supplies neither. The
invalid-apply test supplies both project and environment. This also removes
its prior ambiguity: if reconciliation were skipped, the invocation would
reach authentication and the counting proxy rather than fail at selector
preflight. The exact eager-refresh mutant made two requests and failed the
revised zero-request assertion.

### Reference-only tests were unclassifiable

Nine unit tests lived only in `solution.patch`. They passed with the reference
but had no test-only counterpart, so the wrapper could place them in neither
the regression nor fail-to-pass set. They duplicated the behavioral grader and
were removed from the reference patch. Production reference files are
otherwise unchanged. The exact current census is 474 p2p, 21 f2p, one skipped
synthetic fallback, and no unclassified entity.

### Tar member order was stronger than the public contract

Four assertions compared decoded tar path vectors in one exact sequence. The
prompt sorts plan entries, but ordinary upload directly appends
`ignore::WalkBuilder` results and exposes no tar-order guarantee. Those
assertions now normalize and sort both decoded path vectors. Exact sorted plan
entries, selected path sets, file bytes, SHA-256 values, Unix modes, archive
prefixes, and the atomic verified snapshot are still checked separately. No
new test was added for an artificial ordering mutant.

### Self-accounting `/proc/self/io` was not a stable snapshot oracle

An attempted deterministic reopen probe predicted `/proc/self/io` counters,
but compressor initialization performed unrelated reads before the source
snapshot. The experiment was discarded and never entered `test.patch`. The
canonical Linux probe instead watches `/proc/self/fd`, atomically replaces a
64 MiB pathname after the verified descriptor opens, and checks the archived
bytes. The exact revised reference passed and the direct verify-then-reopen
mutant failed.

### Partial directory-mode mutation was behaviorally equivalent

Removing only the late directory metadata check survived because the earlier
ordered selection comparison independently still checked directory mode. No
test was added. The complete plausible mutant removed directory-mode checking
from both layers and failed the existing directory-mode probe.

### Login shells hide the base image Cargo path

Invoking the image through `bash -lc` reset the inherited `/opt/cargo` path and
made the harness report that Cargo was unavailable. Direct execution of the
root `test.sh`, which matches the grader entry point, finds cargo-nextest and
passes. This was an invocation error, not a Dockerfile defect.

### The new trajectory batch is not an environment failure

Both `agent-runs2` Nova patches pass 474/474 version-9 base tests and all 23
version-9 grader tests. Missing `rg`, broad `find` permission warnings, and
wrapper conflict recovery were non-blocking. Their 2/2 complete solve signal
is real calibration evidence for version 9 and triggered version 10; it must
not be grouped with the earlier module-export merge failures.

Under version 10, both patches still pass every upstream test and 23/24 grader
entities. Each accepts a same-size, same-mode file whose mtime changes during
its descriptor read. The failure is an isolated public snapshot boundary, not
a toolchain, dependency, timeout, or verifier defect.

### A read-only source mount prevented JUnit publication

The first version-10 Linux command mounted `/src` read-only. The base lane
completed 474/474, then cargo-nextest exited 110 because
`.config/nextest.toml` resolves JUnit to `/src/target/nextest/default/junit.xml`.
The chained `new` command therefore never started. Re-running with the result
destination writable passed all 24 grader entities. The Docker image, source,
dependencies, and tests were unchanged; this was a verifier mount problem.

### Ctime was too broad for the descriptor stability check

An intermediate reference compared both mtime and ctime around the file read.
The Linux atomic-replacement probe then failed because replacing a pathname can
unlink the old still-open inode and update its ctime even though the descriptor
continues to expose one coherent byte snapshot. The final implementation
checks modification time only. The same-size in-place writer proves mtime
changed, while the independent pathname-replacement test still proves that
verified descriptor bytes are archived.

### Version-13 passes depended on missing the atomic descriptor window

The official `agent-runs3` batch reported two version-13 passes, for an
observed 2/10 solve rate. Complete version-14 replay showed that both
implementations independently include descriptor `ctime` in their stability
signature. Once the serialized watcher observes atomic replacement during the
opened snapshot, both reject a valid old descriptor and pass only 27/28.

This is neither a new semantic requirement nor an environment failure. The
public contract already required archiving the verified opened bytes without
reopening the pathname, and earlier design records already rejected `ctime` as
too broad. Version 13's 2/10 remains historical calibration; it cannot carry
into version 14. The reference atomic entity passes the final complete run and
five consecutive focused image repetitions.

### Fallback JUnit hid runner diagnostics

When compilation failed before nextest created per-test JUnit, the wrapper
previously emitted a skipped placeholder containing only the numeric exit
status. Version 14 captures combined runner output and XML-escapes it into the
placeholder's `system-out`. The placeholder remains skipped so it cannot
become an entity present in neither the p2p nor f2p set. Reference `new`
produces ordinary nextest JUnit with 28 real tests and no skips.

### Whole-repository Clippy is not a task-owned signal

Rust 1.97 `cargo clippy --all-targets -D warnings` reports 35 warnings in
untouched upstream modules. The pinned 1.88 host toolchain does not have the
Clippy component installed. Compilation, formatting, full tests, patch
application, and applied-tree whitespace checks pass; no upstream lint cleanup
was folded into this task.

## Residual risks

- Version 13 has an official observed 2/10 and version 20 has a
  reviewer-reported 1/10; both are superseded. Version 21 is a different
  immutable artifact at calibration 0/10, and no historical run carries
  forward.
- The patched artifact has not run in a Windows lane. Unix mode fields are
  intentionally absent on Windows; the pinned upstream base has green Windows
  CI.
- Private submission-archive similarity could not be searched because that
  source is unavailable.
- The Linux atomic-replacement discriminator depends on `/proc/self/fd` and is
  intentionally gated to Linux; Docker is the authoritative grader lane.

None of these residual risks authorizes an artifact edit during calibration.
Any edit requires a new immutable version, repeated gates, and calibration
reset to 0/10.

### Version-18 fairness and mount corrections

The evaluator found three overconstraints: a direct Serde call required
undeclared public `DeployPlan: Serialize`, two unsafe path cases lacked an
explicit public grammar, and conflict diagnostics had to echo every supplied
flag. Version 18 uses the declared serializer plus a JSON value for the reader
fixture, states relative/no-parent archive paths, and removes every conflict
message assertion.

The first exact-image launch also exposed a Docker mount-order limitation:
the runtime could not create `/src/target` beneath a read-only `/src` bind.
The container never started. Authoritative runs used the disposable worktree
writable with the isolated target volume and networking disabled; all 474 base
and 28 new Linux tests passed.

### Version-19 implementation-detail removal

The reviewer correctly identified the pathname-reopen and second-scan
prohibitions as internal architecture. Version 19 deletes them and retains the
public archived-byte identity requirement. The unchanged atomic-replacement
probe still rejects the plausible verify-then-reopen implementation after that
mutant passes the full baseline, so no behavioral protection was lost.

### Version-20 redundant snapshot abstraction

The reviewer correctly identified “Each regular-file record must describe one
coherent descriptor-backed snapshot” as redundant with the concrete sentence
that follows it. Version 20 deletes only that abstraction. The explicit
non-regular-on-open and size/mode/modification-change rejection conditions
remain.

The exact audit independently removed modification, size/byte-count, and mode
checks from the reference. Each matching synchronized Linux race failed, while
the restored reference remained byte-identical and passed 474/474 Linux base,
28/28 Linux new, and 23/23 macOS new.

### Version-21 reader and offline-root corrections

The reviewer rejected version 20 because raw reversed/duplicate records reached
only serializer validation, the CLI source-root entity stopped after
`--write-plan`, and the reference always consulted local links even when
ordinary `up` uses the current directory for project-token or environment
targeting. The description also retained the explicitly prohibited phrase
“Test assumptions.”

Version 21 renames that heading to “Compatibility,” sends raw reversed and
duplicate JSON through the public reader, reconciles linked,
explicit-project, token, and environment modes through `--from-plan`, and
aligns the reference root policy with `Configs`' ordinary targeting behavior.
Independent reader, linked-apply, token-root, and environment-root mutants all
fail focused assertions.

### Version-21 atomic replacement over-pinned success

The fairness verifier found that the atomic-replacement entity required
`create_deploy_tarball_from_plan` to succeed after a pathname swap. The public
contract guarantees byte identity for an archive that is produced, but it
does not prohibit a conservative implementation from detecting the
replacement and rejecting locally.

Version 22 keeps the synchronized replacement and explicit watcher assertion,
accepts `Err`, and checks the complete old payload only for `Ok`. The
historical legitimate conservative replay now passes 28/28. A
verify-then-reopen mutant still fails because it succeeds with replacement
bytes, proving that the distinct byte-integrity discriminator remains.

### A redundant replay exhausted task storage after version-22 success

The exact version-22 reference, test-only lane, archive-path mutant, macOS
lane, and legitimate trajectory replay completed first. A later redundant
near-pass replay then received `Input/output error` from its isolated Docker
target volume while Cargo wrote the query cache. The host had only about
486 MiB free because the disposable macOS target and several task-owned Docker
targets coexisted.

The 2.8 GiB macOS target inside the disposable worktree was removed, restoring
host space. The failed replay is excluded and is not reported as a solver
failure. No canonical source or submission artifact was removed or rewritten.

Under the same storage pressure, macOS marked the Olympus root Git metadata
and several unchanged cold files, including this problem's Dockerfile, as
dataless. Root-level `git status` is therefore temporarily unavailable. The
canonical patch checks used the still-local pinned Railway repository and
clean disposable worktrees; the Dockerfile was not edited, and its previously
recorded immutable hash remains the authoritative identity. Dataless files
were not overwritten to force hydration.

### The version-11 reference could finish metadata checking before digesting

The external verifier reported the same-size snapshot entity failing with the
reference applied, although five exact local repetitions passed. The
reference took final descriptor metadata before SHA-256 computation, leaving
a schedule-dependent open-descriptor window. Version 12 captures pathname
metadata before opening and takes final descriptor metadata only after
digesting.

The fixed race passed 20 consecutive image runs and the version-12 complete
new JUnit was 24 tests with zero failures, errors, or skips. That historical
audit kept the old reference open as a timing-dependent survivor. Version 14
supersedes it with bounded, serialized races and a repeated exact audit; its
complete new JUnit is 28/28.

### A disposable target cache exhausted host storage after canonical success

After the canonical 24/24 JUnit was published, a redundant stress relink filled
an 8.9 GiB task-owned target directory and reported `No space left on device`.
Only that cache was removed. Docker Desktop's stuck backend was restarted and
the exact image became available again. This did not invalidate or replace the
already-complete wrapper result.

### Version-23 subjective error wording

The reviewer correctly identified “must fail clearly” as subjective. Version
23 changes it to “must return an error.” No exact message, error category, or
presentation assertion was added.

### Version-23 reader direction gap

The raw reader already rejected unknown top-level fields, unsupported
versions, reversed records, and duplicates. Missing and invalid file digests
were still exercised through serialization, leaving a narrower persisted-input
asymmetry. Version 23 mutates valid JSON on disk to remove the digest, shorten
it, and replace the entry kind with an unknown value, then requires
`read_deploy_plan` to return `Err` for each. These cases stay inside the
existing strict-record entity.

### Version-23 polling races produced real false positives

The Linux races used `/proc/self/fd` polling and large payloads to make the
descriptor interval likely. `agent-runs4` demonstrated that this was not just
a theoretical flake: Nova2 and Nova7 passed while never comparing pre-open
pathname metadata with the first opened-descriptor sample.

Version 23 uses a test-only preload interposer as a synchronous black-box
barrier after kernel `open` or the first positive `read`. The mutation happens
while that call is blocked, so scheduling and payload size no longer choose the
semantic interval. An exact Nova2 replay now fails the open-phase assertion,
while the reference passes all 28 entities.

### Version-23 storage recovery

After Docker image cleanup restored host space, the canonical Dockerfile still
read as an empty macOS dataless placeholder even though its logical size was
455 bytes. The placeholder could not be hydrated or read by the patch tool. It
was removed by exact path and recreated with the previously recorded contents;
the restored file reproduces SHA-256
`6c2e35238edfec4656b585ad49ccc3a5ac920ff8425a0a08ea0185b8cd71685a`.
No Dockerfile behavior or immutable identity changed.

### Version-23 root-marker-position false positive

A supplied passing candidate validated `plan.entries[0]` as the selected root
directory. That is valid for ordinary prefixed plans because the parent path is
a strict prefix of its descendants, but it is invalid at archive root:
`-hello.txt` sorts before the `"."` root marker under the required global
UTF-8 ordering.

The adjudicator's probe and the exact Nova2 validator both fail with
`deploy plan root marker must be a directory`; ordinary upload and the
reference accept the same source. Version 24 adds this filename to the existing
prefix/path-as-root entity and compares normalized path sets. It does not
require tar order, reject other valid punctuation, or expose a private
validator. Other punctuation-leading names are deliberately not duplicated
because they exercise the same positional-root boundary.

### Version-27 open-phase overconstraint

All twelve implementations in `agent-runs6` and `agent-runs7` sampled
stability from the opened descriptor and failed only when the grader mutated
the file after kernel `open` but before that first sample. Two were otherwise
27/28. Since the first sample and all bytes read afterward consistently
described the mutated file, this was a reasonable snapshot boundary rather
than an invalid mixed record. Version 27 removes the `open` phase from the
metadata-mutation entity and states the concrete required interval as the
content read. Deterministic mid-read mtime, size, and mode mutations remain.

The exact `agent-runs7/Nova_Nova_3` replay now passes 474/474 base and 28/28
new. This resolves the recurring all-agents-one-test failure without weakening
the mid-read consistency requirement.

### Version-27 public upload body was previously unobserved

The valid CLI apply test previously asserted only that local reconciliation
was followed by a request. A command could discard the verified tarball and
rebuild through the ordinary upload branch after remote resolution. Version 27
captures the real `/up` body after a deterministic post-verification source
mutation and requires the archived file to contain the verified old bytes.

That discard-and-rebuild mutant passes all 474 regressions and 27/28 focused
tests, failing only the strengthened valid-apply entity. The reference passes
the baked network-disabled Linux 474/474 and 28/28 lanes and macOS 474/474 and
23/23 lanes.

### Version-28 Cargo-manifest assembly collision

All six `agent-runs8` trajectories encountered the wrapper's generic
three-way-merge fallback. Nova 6 added `libc` to both `Cargo.toml` and
`Cargo.lock`; fallback assembly reset the manifest to the grader copy while
leaving the candidate lockfile. Cargo then failed before discovery, and the
outer verifier expanded that one environment error into 502 synthetic test
failures.

Version 28 removes `Cargo.toml` from `test.patch`. Grader tests are selected by
a checked compiler cfg that `test.sh` appends to `RUSTFLAGS` only for `new`
mode. Replaying Nova 6 now preserves its dependency, succeeds at Cargo
metadata, and reaches the real 25/28 result. The reference remains 474/474
base and 28/28 new; the test census and behavioral assertions are unchanged.

The run-8 request for another opened-object type race was not adopted. Every
reviewed implementation, including the reference, validates the opened file
descriptor's type. No current survivor motivates another resource-heavy
Linux interposition test.

### Version-29 explicit-project selector overreach

The public source-root fixture required an explicit-project `--write-plan`
invocation without `--environment` to succeed. Neither the prompt nor ordinary
upload behavior grants that exception; pinned `railway up` rejects an explicit
project without an environment.

Version 29 supplies `--environment explicit-environment` to the write
invocation, matching the apply invocation. The fixture still proves
current-directory source selection, offline completion, successful local
reconciliation, and pre-request rejection after source changes. No behavior,
test entity, or reference code was added.

### Version-30 libc-read barrier was deterministic but unfair

The version-23 interposer removed scheduler luck for implementations using
Rust `Read`, but it synchronized only by intercepting the libc `read` symbol.
A conforming implementation using `pread`, `mmap`, io_uring, or another
descriptor-backed strategy never reached the hidden barrier and failed by
timeout before its semantic result was observed. Determinism for one private
mechanism was therefore not behavioral fairness.

Version 30 removes the entire C compiler/`LD_PRELOAD` child harness and all
four dependent entities. It also removes the matching mid-read
size/mode/modification requirement from the public description. The
command-level upload-capture test remains and still proves the public invariant
that bytes uploaded after reconciliation are the verified bytes. An actual
`FileExt::read_at`/`pread` reference variant passes all 23 macOS focused
entities, while the discard-and-rebuild command mutant still fails exactly one.

### Version-30 successful cargo fallback was reported as failure

When nextest was unavailable, `cargo test` could pass every focused entity but
`write_fallback_junit` always emitted one failing testcase, even for exit
status zero. The wrapper now parses each standard Cargo test result into JUnit.
The exact fallback reports 23 tests, zero failures, zero errors, and zero skips.
Pre-discovery compilation failure still produces one failure record with the
escaped diagnostic.

### Version-32 buffered CONNECT handoff caused an intermittent false failure

The upload-capture proxy parsed CONNECT through a buffered socket reader and
then passed the underlying descriptor to TLS. Read-ahead could consume part of
the client handshake, so the proxy closed the connection and the valid apply
reported `FETCH_ERROR`. Mere ready-file existence also raced the port write.

The fixture now reads CONNECT without buffering, closes each tunneled response,
and waits for a parsable port. The exact test subsequently passed the complete
Linux reference and all eight version-32 solver runs. Its source mutation and
uploaded-byte assertion were not weakened.

### Version-33 global ordering was repeatedly misread as root-first ordering

Eight independent implementations sorted plan entries and then required
`entries[0]` or `sources.first()` to be the root. A valid child such as the
existing punctuation-leading fixture sorts before `"."`, so ordinary source
selection was rejected even though the schema required global ordering.

The test was already fair and remains unchanged. The public description now
states directly that the root record participates in the same ordering and
need not be first. This addresses a uniform interpretation trap without
exposing the fixture or requiring one internal lookup strategy.
