# Exact-version gap analysis

Verdict: **pass** on 2026-08-19 for pin
`e36c3ff3c9e21026f4a04590a5319edfc27f5c84` and artifact hashes:

- meta `9d0a55d07ab6008e661537e55c209ad7986765f3f2db1d20dc58fbe545d9edda`
- tests `86fec7eab6211ca038a617f7e178815b2a42a4866a4a4b6d91d3a041ca8cbc83`
- reference `7f1eb0788491006d18fe4c0ba2a873a7251b2cba73edb724fd19c8310ed9e588`
- Dockerfile `4825c81a115e455df5493271c0a97685abfb2c1e257ace5e7eea92fdb9f823ba`

The exact verifier has 28 methods. The reference passes 28/28. Every method
fails pristine behaviorally with zero compile, startup, timeout, or JUnit error
nodes. Both complete 11-module reactors pass offline as UID/GID 10001.

## Atomic public-requirement map

| Public requirement | Strongest behavioral coverage |
|---|---|
| Arrow option classes work through normal Tablesaw I/O | stream and File option methods invoke `Table.read/write().usingOptions`; no internal interface declaration is asserted |
| binary input and output streams | the same method writes to a tracking stream and reads from an independent byte stream |
| `ArrowReadOptions.builder(File)` | `fileOptionBuildersWorkThroughNormalTableIo` reads an independently validated Arrow file through the normal option API |
| `ArrowWriteOptions.builder(File)` | the same method writes through the File builder, then consumes every batch with standard Arrow Java |
| caller-provided output remains open | the same method observes close state and writes again after completion |
| `arrow` and `arrows` extension dispatch | `arrowExtensionsResolveThroughTablesawRegistries` performs generic `Table` file writes and reads through both suffixes |
| legacy Arrow file entry points | all retained reader tests use `ArrowReader(File/Path)`; the three pre-existing writer tests cover `ArrowWriter.write(Table, File)` |
| positive configurable maximum record-batch size | integration method observes every emitted nonempty batch at or below two; `arrowWriterBatchSizeMustBePositive` rejects zero and negative values |
| batch boundaries preserve order, values, and nulls | integration method aggregates five rows across multiple batches and compares both columns |
| consume populated and zero-row batches in order | `independentStreamPreservesEveryPopulatedAndZeroRowBatch` |
| preserve Arrow validity for every supported family | `readsEverySupportedPrimitiveAndRepresentableTemporalVariant` plus boolean/floating collision methods |
| direct UTF-8 and non-ASCII text | supported-family method and mixed-text method |
| dictionary UTF-8 with null index | `readsDictionaryEncodedUtf8WithIndexValidity` |
| every standard signed/unsigned integer dictionary index | `readsDictionaryEncodedUtf8WithUnsignedIndexValidity` constructs all eight vector classes |
| null dictionary value and valid empty dictionary value | `dictionaryValueNullRemainsMissing` |
| direct and dictionary UTF-8 coexist in either schema order | `directAndDictionaryUtf8CoexistInEitherSchemaOrder` uses both orders, nulls, and multiple batches |
| populated direct non-text field before dictionary text | `mixedDirectAndDictionaryFieldsRemainRowAligned` |
| signed 64/32/16 values and nulls | supported-family method |
| Date DAY/MILLISECOND | supported-family, exact-negative, fine-loss, intermediate-loss, and range methods |
| Time SECOND/MILLI/MICRO/NANO | supported-family, negative, fine-loss, intermediate-loss, and one-day methods |
| timezone-free timestamps in all four units | supported-family, exact-negative, fine-loss, range, and construction methods |
| timezone-bearing timestamps in all four units and arbitrary labels | supported-family methods plus logical writer decoding |
| exact millisecond representability for both signs | exact-negative, negative-remainder, fine-loss, and intermediate-loss methods |
| valid empty/minimum/NaN must reject rather than collapse | `rejectsValidPayloadsThatAliasTablesawMissingSentinels` and `rejectsEveryUnrepresentableStateWithoutSilentlyChangingValidity` |
| floating infinities remain valid | `acceptsValidFloatingPointInfinitiesAcrossBatches` and external writer consumption |
| unsupported neighboring integer, Float2, and List types reject | neighboring-integer, half-float, and reusable-unsupported methods |
| every rejection is `IllegalArgumentException` naming its field | rejection helpers assert class and literal field identity only |
| failed reader remains usable after early and late failure | `unsupportedTypeFailureHasContextAndLeavesTheSourceReusable` and `lateConversionFailureLeavesReaderReusableAfterSourceReplacement` |
| standard Arrow consumer observes nullable writer output | `writerUsesArrowValidityAndExternallyReadableValuesForEverySupportedColumn` |
| writer false remains a valid value | `writerKeepsFalseBooleanValid` |
| writer temporal representation is free | external consumer decodes logical values from any supported exact unit and ignores instant timezone spelling |

## Cross-product audit

- **Families:** direct/dictionary string, signed integers, date, time, local
  timestamp, instant, boolean, Float4, and Float8 are distinct branches.
- **Directions:** independently produced Arrow-to-Tablesaw and
  Tablesaw-to-standard-Arrow streams remain separate from paired round trips.
- **Entry modes:** legacy File/Path helpers, generic extension dispatch, and
  option dispatch through File, InputStream, and OutputStream are exercised.
- **Producer/schema modes:** direct vectors, dictionary vectors, all eight
  index representations, direct-text/dictionary-text in both orders, a
  populated direct integer before encoded text, and arbitrary output batching
  are covered.
- **Lifecycle states:** normal multi-batch, zero-row transitions, early
  failure, failure after prior rows, retry, source replacement, caller-owned
  output reuse, and repeated success are distinct cells.
- **Value states:** ordinary, null, false, empty/minimum/NaN collision,
  infinity, exact negative temporal value, lossy remainder, construction
  overflow, and unsupported neighboring type are distinct.
- **Resource boundaries:** public stream ownership and reader reuse are
  observable; allocator counts, close order, and private helper state are not.

Date, time, timezone-free timestamp, and instant cells are not grouped because
Arrow and Tablesaw dispatch them independently. Dictionary widths share one
logical method but instantiate each physical index family. Direct-text plus
encoded-text is separate from direct-integer plus encoded-text because the
former challenges two competing string construction paths.

## Targeted incorrect implementations

Nine plausible shortcuts each pass all three pre-existing Arrow tests and fail
the focused verifier: ignored batch maximum, reset batch offset, closed caller
stream, absent option registration, absent `arrows` alias, accepted nonpositive
batch size, the homogeneous-text-schema assumption, and independently omitted
File behavior for the read and write options.
Their exact isolating methods are recorded in `ENVIRONMENT.md` and
`FALSE_POSITIVE_AUDIT.md`.

The one-row and alternate-temporal legitimate writers pass 28/28. All five
run6 implementations pass the old 24 behaviors but fail the same four public
option/registry/batching methods, so the new center of gravity is not duplicate
scalar coverage.

No remaining uncovered cell is simultaneously public, repository-grounded,
behaviorally distinct, reference-passing, mutant-failing, and pristine-failing.
More schema permutations, exact batch partitions, default batch size, temporal
vector classes, timezone spelling, malformed IPC, allocator bookkeeping, or
deadlines would be duplicate or unfair. This verdict is exact-version only.
