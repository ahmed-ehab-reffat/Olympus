---
Title: Build a hierarchy of the annotated features of a sequence
Repository: https://github.com/scikit-bio/scikit-bio
Language: Python
Issue: feature-hierarchy
Commit: debee6216a72e21bd99897efec60a1cf20298392
---

# Build a hierarchy of the annotated features of a sequence

Add a `hierarchy()` method to `IntervalMetadata` returning a new `skbio.metadata.FeatureModel`, and the same method to every object carrying interval metadata, which the model remembers as its sequence. `skbio.metadata.Feature` is the type of one feature. The model is built from the interval features like this:

- Interval features sharing an `ID` are one feature whose bounds are all of theirs, ascending, overlapping or touching ones joined, a joined span open only where its own two ends are.
- They must agree on `type` and `strand` or the build raises `ValueError`. Any strand but "-" is the plus strand.
- An interval without an `ID` is its own feature, `id` `None`.
- `Parent` lists identifiers, comma separated; the feature is a child of each named by any of its intervals, once only. An absent one, or a feature that is its own ancestor, raises `ValueError`. Neither building the model nor that check is limited by how deep the chain of parents runs.
- `roots`, `parents`, `children` and every other listing run by their first span's start, then their last span's end, then their identifier, an absent one counting as empty.

Support `len(model)`, `model[identifier]` raising `KeyError` when missing, and `roots`. A feature carries `id`, `type`, `strand`, `phase`, `bounds`, `parents` and `children`, plus:

- `spans`, the bounds of its direct children when it has any and its own otherwise, joined and ascending.
- `length`, the positions those spans cover, and `introns`, the gaps between them.
- `partial`, whether the 5' and 3' ends are unknown, as a fuzzy outermost bound means.
- `utrs`, the spans before and after the part the `CDS` features below cover, each ascending, two empty ones without any.

Transcription order runs over the spans upward by coordinate on the plus strand, downward on the minus, and the sequence is read through:

- `spliced(sequence=None)`, joining the spans by ascending coordinate, keeping the type of the sequence, and reverse complementing the result on the minus strand, falling back on the model's sequence and raising `ValueError` when it has none.
- `protein(sequence=None, genetic_code=1)`, skipping `phase` bases, dropping a trailing partial codon and translating with that NCBI table. `phase` comes from the interval whose span is first in transcription order, zero when absent.
- `parts`, restating the spans in transcription order, each as its two coordinates then the bases to skip in it to reach the first codon beginning there.
- `position(coordinate)`, a coordinate's offset inside the feature or `None`, and `coordinate(position)`, its inverse, raising `IndexError` outside.
- `codon(index)`, a codon's three coordinates in transcription order counting from the phase, raising `IndexError` where no whole codon sits.
- `residue(coordinate)`, the codon index a coordinate belongs to and its place of 0, 1 or 2, or `None` when it is outside, inside the phase or in a trailing partial codon.

`summary()` returns a data frame of `id`, `type`, `strand`, `start`, `end`, `spans`, `length`, `coding`, `parents` and `children`, read off the spans: their first and last coordinate, their number, the positions covered, those the `CDS` features below cover or its own length when it is one, the parent identifiers in alphabetical order, comma joined, and the child count.

`check()` reports structural problems in columns `id` and `problem`, one row per problem, ordered by feature and then problem name:

- `parent_span`, a bound inside no single bound of a parent, and `strand`, a parent on the other strand.
- `codon_length`, a `CDS` partial at neither end whose length less its phase is not a multiple of three.
- `phase_conflict`, a stated span phase other than the one following from the spans before it, joining having absorbed any other stated phase.
- `cds_outside_exon`, a `CDS` bound inside none of the exons beside it, reported only where it has some.
- `sibling_overlap`, bounds sharing a position with a sibling of the same type.

`to_interval_metadata(derived=False)` returns a new `IntervalMetadata` of the same upper bound, leaving the source untouched, one interval per bound of every feature, carrying `type`, `strand`, an `ID` where there is one, a `Parent` of the identifiers in alphabetical order, comma joined, and for a `CDS` the phase of that span. Derived ones add an interval per intron and per untranslated span of every identified feature, typed "intron", "five_prime_UTR" or "three_prime_UTR", parented on it.

`extract(start, end)` returns an `IntervalMetadata` of that region, measured from its start, keeping the features reaching into it with bounds clipped, dropping parents that did not survive, recomputing a clipped `CDS` span's phase for the bases lost off its 5' end. An empty region, a start below zero or an end past the sequence raises `ValueError`. `reverse()` needs an upper bound, raising `ValueError` without one, and returns interval metadata of that bound holding the mirrored features of the reverse complement, on the other strand, each span keeping the phase `parts` gives it. Every interval written off a bound keeps its openness, derived ones closed, `reverse()` swapping a span's two ends with its coordinates and a bound that `extract()` clips turning open on the side it lost.
