# Rewrite a parsed message without disturbing what was not edited

Writing a parsed message back out reorders and re-cases headers, drops its transfer encoding and re-encodes untouched content. Add a way to edit one and write it back.

`Rewrite` writes a message back out, from a part or an envelope, the same on every call, with any part or header unchanged since parsing written byte for byte. Asked of a part it writes that part and what lies under it, and no more. Any line it writes itself, separator or header field, ends the way that message's lines end.

`Replace` takes the decoded bytes to stand in a part's place, and that part alone is encoded afresh with the transfer encoding its header names, so decoding it again returns what was put in. Where it names none, the encoding building a message would choose is used and a `Content-Transfer-Encoding` header added, so content that needs no encoding is written as it is. A replaced part whose type names a character set points at UTF-8.

A part detaches with `Remove`, keeping no link to where it was. A part goes in after the existing children with `AppendChild`, or ahead of a sibling with `InsertBefore`, which is given that sibling before the part going in. Removing every child leaves the multipart with its two markers and nothing between.

`SetHeader` replaces a field where it stands, or adds it at the end of the block when absent. `DeleteHeader` drops a field with the lines continuing it. Field names match without regard to case; where a field repeats, `SetHeader` leaves one where the first stood and `DeleteHeader` drops all. A name `SetHeader` writes is spelled the way this package spells header names; its value is written as given. A `Content-Type` it writes is what the part reports afterwards, and what a multipart is framed with. A multipart whose new `Content-Type` names no boundary keeps the one it has.

Each reports an error, and one that does leaves the message exactly as it was. The errors: replacing the content of a multipart, or of a part naming an encoding this package cannot write; removing the root; adding to a part that is not multipart; naming a sibling that is not a child; an empty or unwritable field name; a value that would not stay on its one line; a `Content-Type` that does not read as a type and a subtype, or that would change whether a part is a multipart.

A rebuilt multipart keeps the bytes before its first marker and after its closing one. It keeps the boundary it has unless something it is about to emit opens a line with that marker; then it takes one that opens no line of what is emitted, and its `Content-Type` names it. Where the rewrite changes a `Content-Type` parameter, every other parameter keeps its value.
