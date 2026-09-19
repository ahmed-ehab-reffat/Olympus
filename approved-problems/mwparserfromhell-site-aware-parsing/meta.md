---
Repository: https://github.com/earwig/mwparserfromhell
Issue: N/A
Commit: 343bfee5f1eb35ae9b9238df5f83d6b9a5638af1
Language: Python
Category: feature-request
Title: Add site-aware parsing of linktrails, namespaces and recognised tags
---

# Add site-aware parsing of linktrails, namespaces and recognised tags

Add a `SiteInfo` profile that tells the parser about the wiki its text comes from, and make parsing honour it.

`SiteInfo(linktrail="", namespaces=None, tags=None)`, exported from the package top level, carries three settings. `linktrail` is a string holding every character that may form a link trail. `namespaces` maps namespace names, canonical names and aliases alike, to their numeric ids; 6 is the file namespace and 14 the category namespace. `tags` lists the tag names the wiki recognises, and None means every tag. `mwparserfromhell.parse` and `Parser.parse` take the profile through a `site` keyword.

With a profile, the longest run of linktrail characters immediately after a wikilink becomes part of that link. `Wikilink.trail` holds it as a string, empty when absent, settable with None stored as the empty string, and accepted as a `trail` keyword by the `Wikilink` constructor; the node renders it after the closing brackets, `strip_code` keeps it, and no separate text node remains. A link that embeds a file or assigns a category, meaning a title in namespace 6 or 14 without a leading colon, takes no trail and the characters stay text. `Wikilink.namespace` reports the id of the plain-text prefix before the first colon of the title, ignoring a leading colon, letter case, surrounding whitespace and the difference between spaces and underscores. An unknown prefix means 0, and parsing without namespace information means None. Reassigning the title updates it.

An XML-style tag whose name is not recognised, compared without regard to case, is plain text in both its opening and closing forms, wherever it appears. Wiki markup that yields Tag nodes, such as the quote marks for italics and bold, list markers, horizontal rules and tables, is unaffected by `tags`.

The C tokenizer and the pure-Python tokenizer must produce identical trees.
