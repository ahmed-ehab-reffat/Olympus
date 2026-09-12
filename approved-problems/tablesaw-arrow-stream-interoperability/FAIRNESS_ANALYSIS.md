# Exact-version fairness analysis

Verdict: **pass** on 2026-08-19 for pin
`e36c3ff3c9e21026f4a04590a5319edfc27f5c84` and the exact hashes recorded in
`ENVIRONMENT.md`. This audit was restarted after the prompt, tests, and
reference changed; no prior verdict is carried forward.

## Rejection-predicate audit

| Predicate | Public or repository grounding | Verdict |
|---|---|---|
| public `ArrowReadOptions` and `ArrowWriteOptions` builders exist | explicit prompt | fair |
| both option classes accept File inputs/outputs | explicit prompt and sibling option-builder surface | fair |
| options interoperate through `Table.read()` and `Table.write()` | explicit observable prompt; no internal interface declaration is tested | fair |
| inherited read option preserves the selected table name | stable `ReadOptions`/sibling-reader behavior discoverable in the repository | fair |
| `arrow` and `arrows` resolve through generic file dispatch | explicit prompt | fair |
| caller-owned output remains open | explicit prompt and repository stream-ownership convention | fair |
| `batchSize` rejects zero/negative and bounds every nonempty batch | explicit prompt | fair |
| output batch boundaries preserve logical row order, values, and missingness | explicit prompt | fair |
| every input batch and row order is consumed | explicit prompt | fair |
| supported scalar families preserve values and validity | explicit contract and stable Tablesaw/Arrow APIs | fair |
| valid `false` is nonmissing | explicit validity rule | fair |
| UTF-8 logical equality | explicit requirement and stable charset semantics | fair |
| direct/dictionary text, null indices, and null dictionary values | explicit prompt and standard Arrow dictionary semantics | fair |
| every standard signed/unsigned integer dictionary index type | explicit prompt; physical indices are not unsupported unsigned logical columns | fair |
| direct and encoded UTF-8 coexist in either order | explicit prompt and logical schema-order semantics | fair |
| exact temporal representability in supported units | explicit millisecond-precision contract | fair |
| timezone-free local timestamp versus timezone-bearing instant | explicit prompt and Arrow timestamp semantics | fair |
| valid empty/minimum/NaN collision rejects; infinities survive | explicit prompt plus discoverable Tablesaw sentinels and IEEE behavior | fair |
| unsupported neighboring types, one-day violations, and range/construction failures reject | enumerated supported surface and public domain contract | fair |
| rejection class plus literal field identity | explicit diagnostic contract; wording remains free | fair |
| same-reader recovery after early or late conversion failure | explicit lifecycle contract | fair |

All invalid-input checks assert `IllegalArgumentException` and the fixture's
logical field name only. They do not require selected words such as “lossy,”
“range,” or “unsupported,” a vector-class name, or a payload rendering.

## Implementation-freedom checks

The batch oracle loads all standard Arrow batches and accepts any positive
partition whose rows do not exceed the configured maximum. It does not require
the reference's default size or its `2,2,1` partition. An exact legitimate
variant emitting one row per batch passes 28/28.

The external writer oracle asks Arrow for each field's public temporal type and
unit, decodes DAY/MILLISECOND dates and all four time/timestamp units, compares
logical values, requires only the public timezone-free/timezone-bearing split,
and ignores the instant timezone spelling. An exact alternate writer using
DateMilli, TimeMicro, local TimestampMicro, and instant TimestampNano with
`Etc/UTC` passes 28/28. Thus the earlier exact-vector and literal-`UTC` defect
is not present.

Dictionary fixtures are valid streams produced by Arrow Java public vectors,
`DictionaryEncoding`, `MapDictionaryProvider`, and `ArrowStreamWriter`.
Assertions observe only Tablesaw schema order, logical values, row order, and
missingness. They do not prescribe dictionary IDs, eager decoding,
`DictionaryEncoder`, column-add order, adapter layout, or batch construction.

## Reflection, compile lane, wrapper, and malformed input

The required option classes and builder overloads are reached reflectively so
the pristine repository can compile and fail as JUnit behavior instead of causing an
environment-level compile failure. Reflection checks only names and signatures
explicitly required by the prompt, then invokes the ordinary public Tablesaw
API; it does not inspect implemented interfaces, fields, helpers, bytecode, or
private layout. The File overloads are named explicitly in the prompt, so
checking their public signatures is behavioral API coverage rather than an
internal-architecture prescription. Missing public surface becomes an
assertion failure, not a startup error.

The Maven lane uses only repository dependencies. `test.sh` copies the
read-only tree to private writable storage, selects a named baseline or feature
class, preserves Maven status, and emits Surefire XML. It imposes no
architecture-sensitive file layout beyond the submitted public test node.
There is no timeout, subprocess deadline, elapsed-time predicate, random
malformed IPC, invalid UTF-8, allocator count, close-order assertion, host
charset dependency, or exact diagnostic prose.

## Architecture replay and verdict

The adapter-based reference and both materially different variants pass 28/28.
All five independent run6 direct-dispatch implementations still pass the prior
24 behaviors; they are rejected only for the newly public option, registry,
and batching surface, not their internal Arrow organization. Nine targeted
mutants pass the baseline and fail public behavioral discriminators; the two
File-specific mutants fail only the File method. The exact
pristine and reference trees pass the complete offline 11-module reactor.

Observed compatibility is **0/5**, matching the start forecast. The end fresh
expectation remains **2--4/10**, within the required 1--5/10 band. It is a
forecast, not calibration; this exact version remains **0/10 fresh runs**.
Any artifact change invalidates this verdict.
