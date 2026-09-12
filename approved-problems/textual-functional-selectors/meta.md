---
Repository: https://github.com/Textualize/textual
Issue: N/A
Commit: 182277f69011ba0b9665a9a1b1b0c3e89630e913
Language: Python
Title: Add logical pseudo-classes and sibling combinators to Textual CSS
---
# Add logical pseudo-classes and sibling combinators to Textual CSS

Textual CSS selectors gain the logical pseudo-classes `:not()`, `:is()`, and `:where()`, the relational `:has()`, the sibling combinators `+` and `~`, and a positional nth family. They apply both when styling widgets through stylesheets and when matching them through `query`. A widget styled through any of these re-styles automatically when the widgets its selector depends on are mounted or removed.

The logical pseudo-classes take a comma-separated list of arguments, each a compound of simple selectors. `:is()` and `:where()` match when any argument matches; `:not()` matches when none does. `:has()` takes the same argument list and matches a widget when any of its descendants matches one of the arguments. For specificity, each positional pseudo-class counts like a class, `:not()`, `:is()`, and `:has()` add the specificity of their most specific argument, and `:where()` adds nothing. A functional pseudo-class nested in another, an empty argument list, and an invalid an+b expression are all rejected when the selector is parsed.

`A + B` matches a B whose immediately preceding displayed sibling matches A, and `A ~ B` matches a B with any preceding displayed sibling matching A.

The nth family is `:nth-child()`, `:nth-last-child()`, `:nth-of-type()`, and `:nth-last-of-type()`. Its forms take the CSS an+b expression, and positions count the parent's displayed children, so a child hidden with display none neither counts nor matches. The of-type forms count only siblings of the widget's own type. `:nth-child()` and `:nth-last-child()` - and only these two - accept `of` followed by the same argument list the logical pseudo-classes take; positions then count only the siblings matching one of the arguments, and the widget itself must be among them.
