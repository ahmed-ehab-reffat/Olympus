# Environment viability — Tablesaw Arrow stream interoperability

Verdict: **pass** on 2026-08-19 for repository pin
`e36c3ff3c9e21026f4a04590a5319edfc27f5c84` and the exact immutable artifacts:

- meta: `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda`
- tests: `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83`
- reference: `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588`
- Dockerfile: `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba`

## Phase A — untouched build and offline runtime

The submitted recipe uses
`public.ecr.aws/d3j8x8q7/olympus-base-jvm:latest`, resolved to
`sha256:95a2911ffba3923dd92f7f03b0abbd803993ceb8d895d74ad23272d86e099999`.
The final `--no-cache --platform linux/amd64` build exported:

- image/manifest list: `sha256:5af66133c89230cb93cebc89ed347c03889aa8aea74a899e9f4d711ade8cb80c`
- manifest: `sha256:436413e36b185fe74719f88e6e402434b31ffe23b06258aa65d17a6a4d09022f`
- config: `sha256:9d44e106fd834723a170ca214eed8c7c4b1a2be84cb3d8db2a19d3a05b6fde3a`
- attestation: `sha256:f327d0e97135aa273267c8a9f0c80d1a832e3a7742c570c56d20ac2aacf76e18`

The build completed the full 11-module Maven `install` lifecycle with tests
skipped but production and test compilation enabled, resolved the Surefire
provider and launcher, and removed remote-repository markers from the offline
cache. The untouched repository was then copied from a read-only mount and ran
with `--network none`, UID/GID 10001, a private HOME, and `mvn -o`. Its
pre-existing Arrow writer lane passed 3/3, establishing offline startup and
arbitrary-UID viability.

The literal complete untouched 11-module `mvn -o -B test` reactor also passed
under those constraints in 2:05. The exact reference plus verifier complete
reactor passed in 2:04.

## Phase B — exact evaluator composition

Fresh trees were composed in the evaluator order: clean pin, implementation
patch when present, then `test.patch`. Every patch passed `git apply --check`
and every composed tree passed `git diff --check`. The submitted `test.sh` ran
from a read-only input mount through a private writable copy, offline as UID
10001.

| Lane | Exact result |
|---|---|
| pristine / base | pass, 3/3 |
| pristine / new | expected behavioral rejection, 28/28 failures and 0 errors |
| reference / base | pass, 3/3 |
| reference / new | pass, 28/28 |

Pristine and reference feature reports contain the same 28 testcase names.
There are no compiler, startup, timeout, or JUnit error nodes. The harness has
no timeout predicate and preserves Maven status in its Surefire XML wrapper.
The exact reference passes `git-code-format:validate-code-format` offline,
including both production and verifier Java sources.

## Compatibility and legitimate variation

All five `agent-runs6` solution patches compose cleanly before the final test
patch. Each exact feature lane compiles, passes the previous 24 behaviors, and
fails only:

- `standardIoOptionsPreserveValuesAcrossConfiguredBatchBoundaries`;
- `fileOptionBuildersWorkThroughNormalTableIo`;
- `arrowExtensionsResolveThroughTablesawRegistries`; and
- `arrowWriterBatchSizeMustBePositive`.

Observed compatibility is therefore **0/5**, exactly matching the pre-change
forecast. This is a compatibility replay, not fresh calibration.

A materially different legitimate writer that emits one-row record batches
even when the configured maximum is two passes 28/28. A second variant using
DateMilli, TimeMicro, TimestampMicro, TimestampNanoTZ, and `Etc/UTC` also passes
28/28. These results preserve batching and temporal representation freedom.

## Mutation isolation

Nine single-shortcut mutants compile and pass all three pre-existing Arrow
tests. No mutant survives the 28 feature methods:

| Mutant | Failing method or methods |
|---|---|
| ignore configured maximum and emit one full-table batch | stream integration and File-option methods |
| restart every output batch at source row zero | stream integration and File-option methods |
| close a caller-provided output stream | `standardIoOptionsPreserveValuesAcrossConfiguredBatchBoundaries` |
| omit option-class writer registration | stream integration and File-option methods |
| omit the `arrows` extension | `arrowExtensionsResolveThroughTablesawRegistries` |
| accept nonpositive batch sizes | `arrowWriterBatchSizeMustBePositive` |
| assume direct and dictionary UTF-8 cannot coexist | `directAndDictionaryUtf8CoexistInEitherSchemaOrder` |
| omit public `ArrowReadOptions.builder(File)` behavior while retaining legacy helpers | `fileOptionBuildersWorkThroughNormalTableIo` |
| omit public `ArrowWriteOptions.builder(File)` behavior while retaining legacy helpers | `fileOptionBuildersWorkThroughNormalTableIo` |

No targeted mutant survives the focused verifier. This is evidence for the
attempted mutation set, not proof that every possible false positive is gone.
The batch-size, row-offset, and option-registration mutants also fail the File
method because that independent entry mode traverses the same public writer
behavior; the two File-overload mutants isolate the added requirement itself.

## Quarantined superseded versions

Two otherwise behaviorally passing artifact sets were invalidated and are not
credited. The first failed production-source format validation; the second
fixed production formatting but failed verifier-source format validation.
Both triggered a fresh no-cache image build and complete Phase A/Phase B restart.
Older environment and calibration evidence remains superseded as documented in
`DESIGN.md`.

Two first-attempt File mutants were also quarantined because hiding the overload
without adapting legacy helper calls caused production compilation failure.
Their corrected compiling forms pass baseline and fail only the File method.

Any submission-artifact, dependency, repository-pin, or evaluator-injection
change invalidates this verdict. The final exact version has **0/10 fresh
calibration runs**.
