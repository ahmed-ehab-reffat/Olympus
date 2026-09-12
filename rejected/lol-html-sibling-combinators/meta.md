# Add sibling combinator and selector list support to the matcher

Add the sibling combinators `+` and `~`, and the `:is()` and `:where()` selector lists, to the CSS selector matcher used by element content handlers. All four are rejected as unsupported today.

Two elements are siblings when they have the same parent element, and elements at the top level of a document are siblings of one another. `a + b` matches an element matching `b` whose immediately preceding element sibling matches `a`. `a ~ b` matches an element matching `b` that has any preceding element sibling matching `a`. Only elements separate elements, so text, comments and other content sitting between two elements do not affect whether they are siblings or which one comes immediately before the other.

A sibling relationship never crosses a parent boundary. An element is never a sibling of its own descendants, a match on the left side of a sibling combinator never reaches into the subtree of an element that follows it, and it never applies outside the element that encloses it. Elements that carry no content of their own, such as void elements and self closing foreign elements, take part in sibling relationships exactly like any other element, both as the left side of a combinator and as an element standing between two others.

`:is(...)` and `:where(...)` take a comma separated list of alternatives and match an element when any one alternative matches it; the two behave identically here. An element that satisfies a handler's selector in more than one way still matches it once. Each alternative is a compound selector. A combinator inside either of them is rejected with the same unsupported selector error that a combinator inside `:not(...)` already produces, and every construct the matcher rejects today keeps being rejected.

All of this composes with the selector syntax that already works and with itself: a selector list may appear on either side of any combinator, a negation may wrap a selector list, and the sibling combinators may be chained and mixed freely with the child and descendant combinators.
