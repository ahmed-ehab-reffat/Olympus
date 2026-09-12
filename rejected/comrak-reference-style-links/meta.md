---
Repository: https://github.com/kivikakk/comrak
Issue: N/A
Commit: 835e68ea438868fdd2ee8e53683b26cd73d5f67d
Language: Rust
Category: feature-request
Title: Add reference-style link and image output to the CommonMark renderer
---
# Add reference-style link and image output to the CommonMark renderer

Add a `reference_links` render option that makes CommonMark output write links and images in
reference style. Today every link is written inline as `[text](destination)`, which is hard to read
when destinations are long. With the option on, each link becomes `[text][label]` and each image
`![alt][label]`, and the destinations are gathered into a block of definitions placed after all
other document content. Rewriting a document this way does not change what it means: the result
parses to the same thing the original did. The option is off by default and changes nothing when
off. A `--reference-links` command line flag selects it too, alongside
`--reference-link-style`.

Two links refer to the same target only when both destination and title match exactly. Links and
images draw their labels from one shared pool. Autolinks and any link or image with an empty destination are not written in reference style
at all: they keep their current inline form and take no label, which is settled before any label is
handed out.

A companion `reference_link_style` option chooses how labels are spelled, through the
`ReferenceLinkStyle` values `Numeric` and `Text`. `Numeric`, the default, labels targets with decimal numbers from 1 in the order they
first appear, counting a link that encloses other content from where it starts. `Text` instead derives the label from the link or image text: letters and
digits are kept and lowercased, every run of other characters becomes a single dash, and leading
and trailing dashes are dropped. Text that yields nothing usable takes the lowest unused number
instead. Labels are compared the way CommonMark compares them, ignoring case and treating runs of
whitespace as equal, and when two different targets would take the same label the later ones get
`-2`, `-3` and so on. Every definition in a document has a distinct label.

Each definition occupies one line, in ascending order of assignment, written as the label followed
by the destination and then the title in double quotes when there is one. A destination containing
spaces or parentheses is wrapped in angle brackets, and any angle bracket or backslash inside it is
backslash escaped, as is any double quote or backslash inside a title. Definitions are never
wrapped and never indented, whatever the wrap width is and whatever the link appeared inside.

Where a link or image text is already the same as its label under that comparison, the shorter
forms CommonMark allows are used: the label is left out entirely, unless the very next thing in the
document begins with a bracket or parenthesis, in which case an empty `[]` is kept so the two
cannot be read as one reference. A link or image whose text contains another link or image keeps
the full form, since a shortened one would not read back as the same document.
