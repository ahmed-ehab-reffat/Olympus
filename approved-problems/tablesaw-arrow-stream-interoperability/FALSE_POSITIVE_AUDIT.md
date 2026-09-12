# Exact-version false-positive audit

Verdict: **pass** on 2026-08-19 for:

- pin `e36c3ff3c9e21026f4a04590a5319edfc27f5c84`
- meta `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda`
- tests `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83`
- reference `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588`
- Dockerfile `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba`

`GAP_ANALYSIS.md` maps every participant-facing requirement to its strongest
behavioral test across type family, direction, entry mode, producer mode,
lifecycle, value state, and resource boundary. Exact composition proves
pristine base pass, pristine failure in all 28 feature methods with zero error
nodes, and reference base/feature pass. Both complete 11-module reactors pass
offline as a non-root UID.

## New hardening cells

The run6 evidence showed five of five independent agents solved the preceding
24-behavior version. Their shared omission was not another Arrow scalar edge:
none implemented Tablesaw's normal option flow, option classes, registry
extensions, caller-owned stream lifecycle, or configurable bounded batching.
Repository sibling formats establish those as normal, discoverable module
architecture.

The redesign and this coverage correction add five behavioral methods:

| Public behavior | Strongest method | Admission evidence |
|---|---|---|
| direct UTF-8 and dictionary UTF-8 coexist in either schema order | `directAndDictionaryUtf8CoexistInEitherSchemaOrder` | explicit prompt gap; homogeneous-text-schema mutant fails only this method |
| option-based binary stream I/O, preserved table name, caller stream ownership, bounded multi-batch values/nulls/order | `standardIoOptionsPreserveValuesAcrossConfiguredBatchBoundaries` | sibling-format APIs plus four independently isolated shortcuts |
| File builders for both option classes | `fileOptionBuildersWorkThroughNormalTableIo` | explicit public overloads plus independent missing-reader and missing-writer mutants |
| generic `.arrow` and `.arrows` reader/writer resolution | `arrowExtensionsResolveThroughTablesawRegistries` | explicit prompt and missing-alias mutant |
| positive batch maximum | `arrowWriterBatchSizeMustBePositive` | explicit prompt and nonvalidating-builder mutant |

The direct/dictionary text method is retained as completeness coverage, not a
difficulty claim: run6 solutions already handle it generically. The four
option/registry/batching methods are the redesign discriminators; every run6
patch passes the other 24 methods and fails exactly those four.

## Mutation matrix

Each mutant is a single plausible shortcut derived from repository architecture
or reviewed solver patterns. Every mutant compiles and passes all three
pre-existing Arrow tests.

| Incorrect implementation | Feature result | Distinct public defect |
|---|---|---|
| ignore `batchSize` and emit the table in one batch | 26/28; stream and File methods fail | configured maximum ignored in both entry modes |
| honor batch counts but restart every batch at source row zero | 26/28; stream and File methods fail | row/value order corrupt across boundaries |
| close the supplied output stream | 27/28; only stream integration fails | caller ownership violated |
| implement option class but omit writer option registration | 26/28; stream and File methods fail | standard `usingOptions` dispatch absent |
| register `arrow` but omit `arrows` | 27/28; only extension method fails | one explicit alias absent |
| store zero/negative batch sizes without validation | 27/28; only positivity method fails | invalid public option accepted |
| assume a schema with encoded text has no direct UTF-8 field | 27/28; only mixed-text method fails | coexisting text modes corrupt |
| retain stream reading but omit the public File-read option overload | 27/28; only File method fails | requested File input surface absent |
| retain stream writing but omit the public File-write option overload | 27/28; only File method fails | requested File output surface absent |

The one-row legitimate writer passes 28/28, so the batch mutants are not being
killed by an exact partition. The alternate temporal writer also passes 28/28,
so the new integration oracle did not reintroduce exact vector or timezone
label requirements.

No actionable targeted mutant survives. Therefore there is no focused survivor
to promote to another full-suite run. The exact reference still passed the
complete 11-module suite; the untouched complete suite also passed. A
zero-survivor result is evidence only for this attempted mutation set.

The first File-overload mutations merely changed the methods to private. That
also broke the reference's legacy helper calls and failed production
compilation, so those attempts were quarantined rather than counted. The
admitted forms preserve the legacy path through `Source`/`Destination`, compile,
pass baseline, and omit only the public File option surface.

## Solver compatibility replay

All five run6 patches apply before the final test patch without conflicts,
compile offline as UID 10001, and execute all 28 methods. Each produces 24
passes and the same four option/registry/batching failures, with no compiler,
startup, timeout, or JUnit errors. Observed compatibility is **0/5**, matching
the forecast and demonstrating that the redesign changes the required
architecture rather than adding another fixture to a behavior they already
implemented.

## Rejected or artificial candidates

- Implementing particular internal reader/writer interfaces, exact temporal
  vector classes, exact timezone labels, default batch size,
  exact batch count/partition, dictionary ID, decoder placement, registry
  implementation mechanism, allocator counts, and close order are private
  choices.
- More schema permutations or more values within a dictionary width do not add
  another semantic boundary.
- Random malformed IPC, invalid UTF-8, arbitrary nested types, and output
  dictionary encoding are outside the stated valid-producer surface.
- A schema-only completion test still requires an unstated deadline against
  pristine and remains excluded.
- Exact packed-year endpoints and the final in-day millisecond remain excluded
  where they fail the mandatory pristine fail-to-pass admission rule.

The end fresh-calibration expectation is **2--4/10**, inside the accepted
1--5/10 band. Fresh calibration remains **0/10** until a new exact-version
batch is run. Any artifact change requires a new audit.
