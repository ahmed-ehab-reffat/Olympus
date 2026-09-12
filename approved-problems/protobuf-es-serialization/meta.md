---
Repository: https://github.com/bufbuild/protobuf-es
Issue: N/A
Commit: 9d5f11ee4aa45cb73a721fbb29c8c4ecc8eeb39c
Language: TypeScript
Title: Add structured serialization failure reporting across all formats
---

# Add structured serialization failure reporting across all formats

Add `SerializationError`, exported from `@bufbuild/protobuf`, reporting `format` (`binary`, `json`, `text`), `operation` (`read`, `write`), root `schema`, `path`, and `cause`. It extends `Error` without overriding `name`. Failures between fields, including malformed trailing bytes after earlier fields or extensions, are reported on the containing message; at the root, the path is empty.

The path points to the field or element being examined when the error is raised, including required-field checks and getter failures, using `Path` vocabulary for fields, extensions, repeated indexes, and map keys of any declared key type. Sibling calls share no path state. Delegated embedded serialization retains outer format, operation, schema, and path instead, setting the inner error as `cause`. Paths round-trip through `pathToString` and `parsePath`, except a repeated extension element's index segment, which is not guaranteed to reparse.

Behavior applies to fresh reads, merge reads, and writes in binary, JSON, text, `sizeDelimitedEncode`, and `sizeDelimitedDecodeStream`. Framed body failures retain paths; framing or size-limit errors produce empty paths. Pre-failure stream items remain yielded. Failed merge reads are atomic, leaving target state untouched including extensions.
